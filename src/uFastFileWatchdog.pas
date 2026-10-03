unit uFastFileWatchdog;

{ Detects UI hangs (no heartbeat), memory pressure, and requests cancel of
  background work. Cannot magically unblock a deadlock inside the VCL thread,
  but logs, alerts, and terminates cooperative worker threads. }

interface

uses
  SysUtils;

type
  { Must be safe to call from the watchdog thread: Terminate workers / set flags only.
    No VCL UI, no Synchronize, no WaitFor. }
  TFastFileWatchdogCancelProc = procedure;

procedure InstallFastFileWatchdog;
procedure UninstallFastFileWatchdog;

{ Call from the UI thread (OnIdle / timers / long loops). }
procedure FastFileWatchdogPulse;

{ Raise hang threshold while indexing / heavy UI work is expected. }
procedure FastFileWatchdogBeginHeavyOp(const AName: string = '');
procedure FastFileWatchdogEndHeavyOp;

procedure FastFileWatchdogSetCancelProc(AProc: TFastFileWatchdogCancelProc);
function FastFileWatchdogCancelRequested: Boolean;
procedure FastFileWatchdogClearCancelRequest;

implementation

uses
  Windows, Classes, Forms, ExtCtrls, SyncObjs, uFastFileAppGuard, uI18n;

const
  HEARTBEAT_MS = 750;
  CHECK_MS = 1500;
  HANG_NORMAL_MS = 45000;
  HANG_HEAVY_MS = 180000;
  HANG_ALERT_COOLDOWN_MS = 60000;

{$IFDEF WIN64}
  MEM_WARN_BYTES = UInt64(3) * 1024 * 1024 * 1024;
  MEM_CRIT_BYTES = UInt64(5) * 1024 * 1024 * 1024;
{$ELSE}
  MEM_WARN_BYTES = UInt64(1400) * 1024 * 1024;
  MEM_CRIT_BYTES = UInt64(1800) * 1024 * 1024;
{$ENDIF}
  MEM_ALERT_COOLDOWN_MS = 90000;

type
  TProcessMemoryCounters = record
    cb: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: SIZE_T;
    WorkingSetSize: SIZE_T;
    QuotaPeakPagedPoolUsage: SIZE_T;
    QuotaPagedPoolUsage: SIZE_T;
    QuotaPeakNonPagedPoolUsage: SIZE_T;
    QuotaNonPagedPoolUsage: SIZE_T;
    PagefileUsage: SIZE_T;
    PeakPagefileUsage: SIZE_T;
  end;
  PProcessMemoryCounters = ^TProcessMemoryCounters;

  TGetProcessMemoryInfo = function(Process: THandle; ppsmemCounters: PProcessMemoryCounters;
    cb: DWORD): BOOL; stdcall;

  TFastFileWatchdogThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TFastFileWatchdogHooks = class
  public
    procedure PulseTimerTick(Sender: TObject);
    procedure AppIdlePulse(Sender: TObject; var Done: Boolean);
  end;

var
  GInstalled: Boolean = False;
  GLastPulseTick: Cardinal = 0;
  GHeavyDepth: Integer = 0;
  GHeavyName: string = '';
  GCancelRequested: Integer = 0;
  GCancelProc: TFastFileWatchdogCancelProc = nil;
  GThread: TFastFileWatchdogThread = nil;
  GPulseTimer: TTimer = nil;
  GHooks: TFastFileWatchdogHooks = nil;
  GPrevOnIdle: TIdleEvent = nil;
  GLastHangAlertTick: Cardinal = 0;
  GLastMemAlertTick: Cardinal = 0;
  GPsapi: HMODULE = 0;
  GGetProcessMemoryInfo: TGetProcessMemoryInfo = nil;
  GLock: TCriticalSection = nil;

type
  TWatchdogText = (wtHangTitle, wtHangMessage, wtHangOperation, wtHangQuestion,
    wtMemTitle, wtMemCritical);

const
  cWatchdogTextKeys: array[TWatchdogText] of string = (
    'Watchdog.Hang.Title', 'Watchdog.Hang.Message', 'Watchdog.Hang.Operation',
    'Watchdog.Hang.Question', 'Watchdog.Memory.Title', 'Watchdog.Memory.Critical');
  cWatchdogTextDefaults: array[TWatchdogText] of string = (
    'FastFile - possible freeze',
    'FastFile: the interface has not responded for ~%u s.',
    'Operation: %s',
    'Try to cancel background work (Find/Filter/indexing)?',
    'FastFile - memory',
    'FastFile: critical memory usage (~%.0f MB). Cancel heavy work and free the cache?');

var
  { Translated on the UI thread only; the watchdog thread reads copies under GLock. }
  GTexts: array[TWatchdogText] of string;
  GTextsLang: Integer = -1;

procedure EnsureLock; forward;

procedure RefreshWatchdogTexts;
var
  T: TWatchdogText;
  Lang: Integer;
  S: string;
  Fresh: array[TWatchdogText] of string;
begin
  Lang := Ord(GetCurrentLanguage);
  if Lang = GTextsLang then Exit;
  for T := Low(TWatchdogText) to High(TWatchdogText) do
  begin
    try
      S := TrText(cWatchdogTextKeys[T]);
    except
      S := '';
    end;
    if (S = '') or (S = cWatchdogTextKeys[T]) then
      S := cWatchdogTextDefaults[T];
    Fresh[T] := S;
  end;
  EnsureLock;
  GLock.Enter;
  try
    for T := Low(TWatchdogText) to High(TWatchdogText) do
      GTexts[T] := Fresh[T];
    GTextsLang := Lang;
  finally
    GLock.Leave;
  end;
end;

function WatchdogText(T: TWatchdogText): string;
begin
  EnsureLock;
  GLock.Enter;
  try
    Result := GTexts[T];
  finally
    GLock.Leave;
  end;
  if Result = '' then
    Result := cWatchdogTextDefaults[T];
end;

function NowTick: Cardinal;
begin
  Result := GetTickCount;
end;

function TickElapsed(AFrom, ANow: Cardinal): Cardinal;
begin
  Result := ANow - AFrom;
end;

procedure EnsureLock;
begin
  if GLock = nil then
    GLock := TCriticalSection.Create;
end;

procedure FastFileWatchdogPulse;
begin
  GLastPulseTick := NowTick;
end;

procedure FastFileWatchdogBeginHeavyOp(const AName: string);
begin
  EnsureLock;
  GLock.Enter;
  try
    Inc(GHeavyDepth);
    if AName <> '' then
      GHeavyName := AName;
  finally
    GLock.Leave;
  end;
  FastFileWatchdogPulse;
end;

procedure FastFileWatchdogEndHeavyOp;
begin
  EnsureLock;
  GLock.Enter;
  try
    if GHeavyDepth > 0 then
      Dec(GHeavyDepth);
    if GHeavyDepth = 0 then
      GHeavyName := '';
  finally
    GLock.Leave;
  end;
  FastFileWatchdogPulse;
end;

procedure FastFileWatchdogSetCancelProc(AProc: TFastFileWatchdogCancelProc);
begin
  GCancelProc := AProc;
end;

function FastFileWatchdogCancelRequested: Boolean;
begin
  Result := GCancelRequested <> 0;
end;

procedure FastFileWatchdogClearCancelRequest;
begin
  InterlockedExchange(GCancelRequested, 0);
end;

procedure RequestCancelWorkers(const AReason: string);
begin
  InterlockedExchange(GCancelRequested, 1);
  LogFastFileException('Watchdog.Cancel', AReason);
  try
    if Assigned(GCancelProc) then
      GCancelProc();
  except
    on E: Exception do
      LogFastFileException('Watchdog.CancelProc', E.ClassName + ': ' + E.Message);
  end;
end;

function TryGetPrivateBytes(out ABytes: UInt64): Boolean;
var
  C: TProcessMemoryCounters;
begin
  Result := False;
  ABytes := 0;
  if not Assigned(GGetProcessMemoryInfo) then
  begin
    if GPsapi = 0 then
      GPsapi := LoadLibrary('psapi.dll');
    if GPsapi <> 0 then
      GGetProcessMemoryInfo := GetProcAddress(GPsapi, 'GetProcessMemoryInfo');
  end;
  if not Assigned(GGetProcessMemoryInfo) then Exit;
  FillChar(C, SizeOf(C), 0);
  C.cb := SizeOf(C);
  if not GGetProcessMemoryInfo(GetCurrentProcess, @C, C.cb) then Exit;
  ABytes := UInt64(C.PagefileUsage);
  if ABytes = 0 then
    ABytes := UInt64(C.WorkingSetSize);
  Result := True;
end;

procedure TrimWorkingSetSoft;
begin
  try
    SetProcessWorkingSetSize(GetCurrentProcess, SIZE_T(-1), SIZE_T(-1));
  except
  end;
end;

procedure AlertHang(AStallMs: Cardinal; const AHeavyName: string);
var
  Msg: string;
  R: Integer;
  Tick: Cardinal;
begin
  Tick := NowTick;
  if (GLastHangAlertTick <> 0) and
     (TickElapsed(GLastHangAlertTick, Tick) < HANG_ALERT_COOLDOWN_MS) then
    Exit;
  GLastHangAlertTick := Tick;

  try
    Msg := Format(WatchdogText(wtHangMessage), [AStallMs div 1000]);
  except
    Msg := Format(cWatchdogTextDefaults[wtHangMessage], [AStallMs div 1000]);
  end;
  if AHeavyName <> '' then
  try
    Msg := Msg + sLineBreak + Format(WatchdogText(wtHangOperation), [AHeavyName]);
  except
    Msg := Msg + sLineBreak + AHeavyName;
  end;
  Msg := Msg + sLineBreak + sLineBreak + WatchdogText(wtHangQuestion);
  LogFastFileException('Watchdog.UIHang', Msg);

  R := MessageBox(0, PChar(Msg), PChar(WatchdogText(wtHangTitle)),
    MB_YESNO or MB_ICONWARNING or MB_SYSTEMMODAL or MB_SETFOREGROUND or MB_TOPMOST);
  if R = IDYES then
    RequestCancelWorkers('UI hang user confirmed cancel');
end;

procedure AlertMemory(ABytes: UInt64; ACritical: Boolean);
var
  Msg: string;
  R: Integer;
  Tick: Cardinal;
  Mb: Double;
begin
  Tick := NowTick;
  if (GLastMemAlertTick <> 0) and
     (TickElapsed(GLastMemAlertTick, Tick) < MEM_ALERT_COOLDOWN_MS) then
    Exit;
  GLastMemAlertTick := Tick;

  Mb := ABytes / (1024.0 * 1024.0);
  if ACritical then
  try
    Msg := Format(WatchdogText(wtMemCritical), [Mb]);
  except
    Msg := Format(cWatchdogTextDefaults[wtMemCritical], [Mb]);
  end
  else
    Msg := Format('FastFile: high memory usage (~%.0f MB). Trimming working cache.', [Mb]);
  LogFastFileException('Watchdog.Memory', Msg);

  if ACritical then
  begin
    R := MessageBox(0, PChar(Msg), PChar(WatchdogText(wtMemTitle)),
      MB_YESNO or MB_ICONWARNING or MB_SYSTEMMODAL or MB_SETFOREGROUND or MB_TOPMOST);
    if R = IDYES then
    begin
      RequestCancelWorkers('Memory critical user confirmed cancel');
      TrimWorkingSetSoft;
    end;
  end
  else
    TrimWorkingSetSoft;
end;

procedure TFastFileWatchdogThread.Execute;
var
  Last, Stall, Limit: Cardinal;
  HeavyDepth: Integer;
  HeavyName: string;
  Bytes: UInt64;
begin
  while not Terminated do
  begin
    Sleep(CHECK_MS);
    if Terminated then Break;

    Last := GLastPulseTick;
    if Last = 0 then
      Continue;

    Stall := TickElapsed(Last, NowTick);
    EnsureLock;
    GLock.Enter;
    try
      HeavyDepth := GHeavyDepth;
      HeavyName := GHeavyName;
    finally
      GLock.Leave;
    end;

    if HeavyDepth > 0 then
      Limit := HANG_HEAVY_MS
    else
      Limit := HANG_NORMAL_MS;

    if Stall >= Limit then
      AlertHang(Stall, HeavyName);

    if TryGetPrivateBytes(Bytes) then
    begin
      if Bytes >= MEM_CRIT_BYTES then
        AlertMemory(Bytes, True)
      else if Bytes >= MEM_WARN_BYTES then
        AlertMemory(Bytes, False);
    end;
  end;
end;

procedure TFastFileWatchdogHooks.AppIdlePulse(Sender: TObject; var Done: Boolean);
begin
  FastFileWatchdogPulse;
  if Assigned(GPrevOnIdle) then
    GPrevOnIdle(Sender, Done)
  else
    Done := True;
end;

procedure TFastFileWatchdogHooks.PulseTimerTick(Sender: TObject);
begin
  FastFileWatchdogPulse;
  RefreshWatchdogTexts;
end;

procedure InstallFastFileWatchdog;
begin
  if GInstalled then Exit;
  EnsureLock;
  FastFileWatchdogPulse;
  RefreshWatchdogTexts;
  if GHooks = nil then
    GHooks := TFastFileWatchdogHooks.Create;
  GPrevOnIdle := Application.OnIdle;
  Application.OnIdle := GHooks.AppIdlePulse;

  GPulseTimer := TTimer.Create(nil);
  GPulseTimer.Interval := HEARTBEAT_MS;
  GPulseTimer.OnTimer := GHooks.PulseTimerTick;
  GPulseTimer.Enabled := True;

  GThread := TFastFileWatchdogThread.Create(True);
  GThread.FreeOnTerminate := False;
  GThread.Priority := tpLower;
  GThread.Start;
  GInstalled := True;
  LogFastFileException('Watchdog', 'Installed');
end;

procedure UninstallFastFileWatchdog;
var
  T: TFastFileWatchdogThread;
begin
  if not GInstalled then Exit;
  GInstalled := False;
  try
    Application.OnIdle := GPrevOnIdle;
  except
  end;
  GPrevOnIdle := nil;

  if Assigned(GPulseTimer) then
  begin
    GPulseTimer.Enabled := False;
    FreeAndNil(GPulseTimer);
  end;
  FreeAndNil(GHooks);

  T := GThread;
  GThread := nil;
  if Assigned(T) then
  begin
    T.Terminate;
    T.WaitFor;
    T.Free;
  end;

  if GPsapi <> 0 then
  begin
    FreeLibrary(GPsapi);
    GPsapi := 0;
    GGetProcessMemoryInfo := nil;
  end;
end;

initialization
  EnsureLock;

finalization
  try
    UninstallFastFileWatchdog;
  except
  end;
  FreeAndNil(GLock);

end.
