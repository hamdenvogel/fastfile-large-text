unit ThreadFileLog;

interface

uses Windows, ThreadUtilities, Classes;

type
  PLogRequest = ^TLogRequest;
  TLogRequest = record
    LogText  : String;
    FileName : String;
  end;

  TThreadFileLog = class(TObject)
  private
    FThreadPool: TThreadPool;
    procedure HandleLogRequest(Data: Pointer; AThread: TThread);
  public
    constructor Create(); overload;
    constructor Create(const FileName, LogText: string); overload;
    destructor Destroy; override;
    procedure Log(const FileName, LogText: string);
  end;

  // Procedure global para chamarmos de qualquer lugar (ex: exceções) com uma única linha!
  procedure LogAsync(const FileName, LogText: string);

implementation

uses
  SysUtils;

(* Simple reuse of a logtofile function for example *)
procedure LogToFile(const FileName, LogString: String);
var
  F: TextFile;
begin
  AssignFile(F, FileName);

  if not FileExists(FileName) then
    Rewrite(F)
  else
    Append(F);

  try
    Writeln(F, LogString);
  finally
    CloseFile(F);
  end;
end;

constructor TThreadFileLog.Create();
begin
  FThreadPool := TThreadPool.Create(HandleLogRequest, 1);
end;

constructor TThreadFileLog.Create(const FileName, LogText: string);
begin
  FThreadPool := TThreadPool.Create(HandleLogRequest, 1);
  Self.Log(FileName, LogText);
end;

destructor TThreadFileLog.Destroy;
begin
  FThreadPool.Free;
  inherited;
end;

procedure TThreadFileLog.HandleLogRequest(Data: Pointer; AThread: TThread);
var
  Request: PLogRequest;
begin
  Request := Data;
  try
    LogToFile(Request^.FileName, Request^.LogText);
  finally
    Dispose(Request);
  end;
end;

procedure TThreadFileLog.Log(const FileName, LogText: string);
var
  Request: PLogRequest;
begin
  New(Request);
  Request^.LogText  := LogText;
  Request^.FileName := FileName;
  FThreadPool.Add(Request);
end;

var
  GlobalLogThread: TThreadFileLog;

procedure LogAsync(const FileName, LogText: string);
begin
  if GlobalLogThread = nil then
    GlobalLogThread := TThreadFileLog.Create;
  GlobalLogThread.Log(FileName, LogText);
end;

initialization
  GlobalLogThread := nil;

finalization
  if Assigned(GlobalLogThread) then
    GlobalLogThread.Free;

end.
