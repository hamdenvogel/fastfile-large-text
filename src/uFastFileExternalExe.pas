unit uFastFileExternalExe;

{
  Resolve and validate FastFile companion executables (ConsumerAI, ConsumerRAG,
  ScriptEngine, CodeCheck) built with PyInstaller --onefile.
}

interface

uses
  SysUtils;

function FastFileDeployExePath(const AExeFileName: string): string;
function FindValidExternalExecutable(const AExeFileName: string): string;
function IsValidPyInstallerOneFileExe(const APath: string): Boolean;
function IsValidDownloadedCompanionExe(const APath: string): Boolean;
function ExternalExeLooksLikeHtmlErrorPage(const APath: string): Boolean;

implementation

uses
  Classes,
  UnConsts,
  uFastFilePaths;

const
  { PyInstaller CArchive cookie: MEI + $0C $0B $0A $09 $08 $0B $0C (not CRLF). }
  PYI_COOKIE: AnsiString = 'MEI' + #12#11#10#9#8#11#12;
  MIN_PYINSTALLER_EXE_BYTES = 5 * 1024 * 1024;
  MIN_PE_DEPLOY_EXE_BYTES = 4 * 1024 * 1024;
  TAIL_SCAN_BYTES = 262144;

function FastFileDeployExePath(const AExeFileName: string): string;
begin
  Result := FastFileExeDirPath(AExeFileName);
end;

procedure AppendUniqueCandidatePath(ACandidates: TStrings; const APath: string);
var
  Expanded: string;
begin
  if APath = '' then
    Exit;
  Expanded := ExpandFileName(APath);
  if ACandidates.IndexOf(Expanded) < 0 then
    ACandidates.Add(Expanded);
end;

function CompanionExeCandidatePaths(const AExeFileName: string): TStringList;
var
  Base: string;
begin
  Result := TStringList.Create;
  Base := FastFileBaseDir;

  { Beside FastFile.exe — Build\Win64\ or Build\Win32\ after D10.4 migration. }
  AppendUniqueCandidatePath(Result, FastFileDeployExePath(AExeFileName));

  { Legacy D7 / build_exe_*.bat layout: src\Build\ConsumerAI.exe (parent of Win32/Win64). }
  AppendUniqueCandidatePath(Result, Base + '..' + PathDelim + AExeFileName);

  { PyInstaller output: src\data-lake-duckdb-main\dist\ (from Build\Win64\ = ..\..\). }
  AppendUniqueCandidatePath(Result,
    Base + '..' + PathDelim + '..' + PathDelim + DATALAKE_DIR + PathDelim +
    DATALAKE_DIST_DIR + PathDelim + AExeFileName);

  { Older relative guesses kept for IDE runs from unexpected working dirs. }
  AppendUniqueCandidatePath(Result,
    Base + '..' + PathDelim + DATALAKE_DIR + PathDelim + DATALAKE_DIST_DIR + PathDelim +
    AExeFileName);
  AppendUniqueCandidatePath(Result,
    Base + DATALAKE_DIR + PathDelim + DATALAKE_DIST_DIR + PathDelim + AExeFileName);
end;

function ExternalExeLooksLikeHtmlErrorPage(const APath: string): Boolean;
var
  FS: TFileStream;
  Head: array[0..511] of AnsiChar;
  N: Integer;
  S: AnsiString;
begin
  Result := False;
  if not FileExists(APath) then Exit;
  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < 16 then
    begin
      Result := True;
      Exit;
    end;
    N := SizeOf(Head);
    if FS.Size < N then
      N := FS.Size;
    FS.ReadBuffer(Head, N);
    SetLength(S, N);
    Move(Head[0], S[1], N);
    if (Pos('<!DOCTYPE', UpperCase(S)) > 0) or (Pos('<HTML', UpperCase(S)) > 0) or
       (Pos('<HEAD', UpperCase(S)) > 0) then
      Result := True;
  finally
    FS.Free;
  end;
end;

function IsValidPyInstallerOneFileExe(const APath: string): Boolean;
var
  FS: TFileStream;
  Head: array[0..1] of AnsiChar;
  Tail: array of AnsiChar;
  TailLen, ReadPos, I: Integer;
  TailAnsi: AnsiString;
begin
  Result := False;
  if (APath = '') or (not FileExists(APath)) then Exit;
  if ExternalExeLooksLikeHtmlErrorPage(APath) then Exit;

  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < MIN_PYINSTALLER_EXE_BYTES then Exit;
    FS.ReadBuffer(Head, SizeOf(Head));
    if (Head[0] <> 'M') or (Head[1] <> 'Z') then Exit;

    TailLen := TAIL_SCAN_BYTES;
    if FS.Size < TailLen then
      TailLen := FS.Size;
    SetLength(Tail, TailLen);
    ReadPos := FS.Size - TailLen;
    FS.Seek(ReadPos, soFromBeginning);
    FS.ReadBuffer(Tail[0], TailLen);
    SetLength(TailAnsi, TailLen);
    Move(Tail[0], TailAnsi[1], TailLen);

    for I := 1 to Length(TailAnsi) - Length(PYI_COOKIE) + 1 do
      if Copy(TailAnsi, I, Length(PYI_COOKIE)) = PYI_COOKIE then
      begin
        Result := True;
        Exit;
      end;
  finally
    FS.Free;
  end;
end;

function IsValidPeDeployCompanionExe(const APath: string): Boolean;
var
  FS: TFileStream;
  Head: array[0..1] of AnsiChar;
begin
  Result := False;
  if (APath = '') or (not FileExists(APath)) then Exit;
  if ExternalExeLooksLikeHtmlErrorPage(APath) then Exit;
  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < MIN_PE_DEPLOY_EXE_BYTES then Exit;
    FS.ReadBuffer(Head, SizeOf(Head));
    Result := (Head[0] = 'M') and (Head[1] = 'Z');
  finally
    FS.Free;
  end;
end;

function IsValidDownloadedCompanionExe(const APath: string): Boolean;
begin
  Result := IsValidPyInstallerOneFileExe(APath);
  if not Result then
    Result := IsValidPeDeployCompanionExe(APath);
end;

function ExternalExePathIsValid(const APath: string): Boolean;
begin
  Result := (APath <> '') and FileExists(APath) and IsValidDownloadedCompanionExe(APath);
end;

function FindValidExternalExecutable(const AExeFileName: string): string;
var
  Candidates: TStringList;
  I: Integer;
begin
  Result := '';
  Candidates := CompanionExeCandidatePaths(AExeFileName);
  try
    for I := 0 to Candidates.Count - 1 do
      if ExternalExePathIsValid(Candidates[I]) then
      begin
        Result := Candidates[I];
        Break;
      end;
  finally
    Candidates.Free;
  end;
end;

end.
