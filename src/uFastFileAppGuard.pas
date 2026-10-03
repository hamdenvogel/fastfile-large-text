unit uFastFileAppGuard;

{ Global VCL exception guard: log + safe MessageBox, no re-entrancy.
  Pair with uFastFileWatchdog for hangs / memory pressure without Exception. }

interface

uses
  SysUtils;

procedure InstallFastFileExceptionGuard;
procedure UninstallFastFileExceptionGuard;
procedure LogFastFileException(const AContext, AMessage: string);
procedure ReportFastFileException(const AContext: string; E: Exception;
  AShowDialog: Boolean = True);

implementation

uses
  Windows, Forms, Classes, Controls, uFastFilePaths;

type
  TFastFileExceptionHooks = class
  public
    procedure AppExceptionHandler(Sender: TObject; E: Exception);
  end;

var
  GInstalled: Boolean = False;
  GHandling: Boolean = False;
  GPrevOnException: TExceptionEvent = nil;
  GHooks: TFastFileExceptionHooks = nil;

function GuardLogPath: string;
begin
  try
    EnsureFastFileTempDir;
    Result := FastFileTempPath('fastfile_exceptions.log');
  except
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      'fastfile_exceptions.log';
  end;
end;

procedure LogFastFileException(const AContext, AMessage: string);
var
  Path, Line: string;
  F: TextFile;
begin
  try
    Path := GuardLogPath;
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' | ' +
      Trim(AContext) + ' | ' + StringReplace(AMessage, sLineBreak, ' / ',
      [rfReplaceAll]);
    AssignFile(F, Path);
    if FileExists(Path) then
      Append(F)
    else
      Rewrite(F);
    try
      WriteLn(F, Line);
    finally
      CloseFile(F);
    end;
  except
    { never raise from logger }
  end;
end;

procedure ShowGuardMessage(const ATitle, AText: string);
begin
  try
    MessageBox(0, PChar(AText), PChar(ATitle),
      MB_OK or MB_ICONERROR or MB_TOPMOST or MB_SETFOREGROUND);
  except
    { ignore }
  end;
end;

procedure ReportFastFileException(const AContext: string; E: Exception;
  AShowDialog: Boolean);
var
  Msg, Ctx: string;
begin
  if GHandling then Exit;
  GHandling := True;
  try
    Ctx := Trim(AContext);
    if E <> nil then
      Msg := E.ClassName + ': ' + E.Message
    else
      Msg := 'Unknown error';
    LogFastFileException(Ctx, Msg);
    if AShowDialog then
    begin
      if Ctx <> '' then
        ShowGuardMessage('FastFile', Ctx + sLineBreak + sLineBreak + Msg)
      else
        ShowGuardMessage('FastFile', Msg);
    end;
  finally
    GHandling := False;
  end;
end;

procedure TFastFileExceptionHooks.AppExceptionHandler(Sender: TObject; E: Exception);
var
  Ctx: string;
begin
  Ctx := 'Application.OnException';
  try
    if Sender is TComponent then
    begin
      if TComponent(Sender).Name <> '' then
        Ctx := Ctx + '.' + TComponent(Sender).Name
      else if Sender is TControl then
        Ctx := Ctx + '.' + Sender.ClassName;
    end
    else if Sender <> nil then
      Ctx := Ctx + '.' + Sender.ClassName;
  except
    Ctx := 'Application.OnException';
  end;
  ReportFastFileException(Ctx, E, True);
end;

procedure InstallFastFileExceptionGuard;
begin
  if GInstalled then Exit;
  if GHooks = nil then
    GHooks := TFastFileExceptionHooks.Create;
  GPrevOnException := Application.OnException;
  Application.OnException := GHooks.AppExceptionHandler;
  GInstalled := True;
end;

procedure UninstallFastFileExceptionGuard;
begin
  if not GInstalled then Exit;
  Application.OnException := GPrevOnException;
  GPrevOnException := nil;
  FreeAndNil(GHooks);
  GInstalled := False;
end;

initialization

finalization
  try
    UninstallFastFileExceptionGuard;
  except
  end;

end.
