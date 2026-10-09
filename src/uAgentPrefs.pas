unit uAgentPrefs;

{
  Ask-files workspace preferences. Stored in ASkin.ini, section AgentWorkspace.
}

interface

uses
  Classes;

type
  TAgentPrefs = record
    IncludeSubdirs: Boolean;
    Mask: string;
    MaxDepth: Integer;
    MaxFiles: Integer;
    MaxReadLines: Integer;
    MaxSearchHits: Integer;
    { Session only, not stored: file open in the main form and its line index. }
    OpenPath: string;
    IndexPath: string;
  end;

  TAgentSession = record
    { 'F|path' or 'D|path' }
    Roots: TStringList;
    Included: TStringList;
    Prompt: string;
    Answer: string;
    Revised: string;
    Tab: Integer;
  end;

function DefaultAgentPrefs: TAgentPrefs;
function LoadAgentPrefs: TAgentPrefs;
procedure SaveAgentPrefs(const APrefs: TAgentPrefs);
function ClampAgentInt(AValue, AMin, AMax, ADefault: Integer): Integer;
{ Recent prompts, newest first. Stored in AGENT_SESSION_FILE (UTF-8, next to the exe). }
procedure LoadAgentRecent(AList: TStrings);
procedure SaveAgentRecent(AList: TStrings);
{ Moves APrompt to the top; drops duplicates (case, accents and spacing ignored). }
procedure RememberAgentPrompt(AList: TStrings; const APrompt: string);
{ Recent sources (files and folders, no trailing backslash), newest first. Same file as the prompts. }
procedure LoadAgentRootRecent(AList: TStrings);
procedure SaveAgentRootRecent(AList: TStrings);
procedure RememberAgentRoot(AList: TStrings; const APath: string);
{ What the workspace shows, restored on the next start. Caller frees Roots and Included. }
function LoadAgentSession: TAgentSession;
procedure SaveAgentSession(const ASession: TAgentSession);

const
  AGENT_INI_SECTION = 'AgentWorkspace';
  AGENT_SESSION_FILE = 'FastFileAgent.ini';
  AGENT_RECENT_SECTION = 'AgentRecent';
  AGENT_ROOTS_SECTION = 'AgentRoots';
  AGENT_ROOT_RECENT_SECTION = 'AgentRootsRecent';
  AGENT_INCLUDED_SECTION = 'AgentFilesFound';
  AGENT_STATE_SECTION = 'AgentState';
  AGENT_MAX_TURNS = 12;
  AGENT_TOOL_CHARS = 14000;
  AGENT_PROMPT_FILES = 80;
  AGENT_PREVIEW_BYTES = 32 * 1024 * 1024;

implementation

uses
  SysUtils, Math, IniFiles, Forms, UnConsts, uUserPrefs, uFastFileAssistantMap, uFastFilePaths;

function AgentIniPath: string; forward;

function RecentMax: Integer;
begin
  Result := PrefAssistantRecentMax;
  if Result < 1 then
    Result := 20;
end;

function EncodeRecent(const S: string): string;
begin
  Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function DecodeRecent(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) and ((S[I + 1] = 'n') or (S[I + 1] = '\')) then
    begin
      if S[I + 1] = 'n' then
        Result := Result + #13#10
      else
        Result := Result + '\';
      Inc(I, 2);
    end
    else
    begin
      Result := Result + S[I];
      Inc(I);
    end;
  end;
end;

function RecentKey(const S: string): string;
var
  I: Integer;
  T: string;
begin
  T := Trim(S);
  for I := 1 to Length(T) do
    if CharInSet(T[I], [#9, #10, #13]) then
      T[I] := ' ';
  while Pos('  ', T) > 0 do
    T := StringReplace(T, '  ', ' ', [rfReplaceAll]);
  Result := LowerCase(FoldDiacriticsForMatch(T));
end;

{ TIniFile reads at most ~2 KB per value; answers and prompts can be longer. }
function OpenSessionIni: TMemIniFile;
begin
  Result := TMemIniFile.Create(FastFileExeDirPath(AGENT_SESSION_FILE), TEncoding.UTF8);
end;

procedure ReadList(Ini: TMemIniFile; const ASection, APrefix: string; AMax: Integer; AList: TStrings);
var
  I, N: Integer;
  S: string;
begin
  AList.Clear;
  N := Ini.ReadInteger(ASection, 'Count', 0);
  if N > AMax then
    N := AMax;
  for I := 0 to N - 1 do
  begin
    S := DecodeRecent(Ini.ReadString(ASection, APrefix + IntToStr(I), ''));
    if Trim(S) <> '' then
      AList.Add(S);
  end;
end;

procedure WriteList(Ini: TMemIniFile; const ASection, APrefix: string; AMax: Integer; AList: TStrings);
var
  I, N: Integer;
begin
  Ini.EraseSection(ASection);
  N := 0;
  if AList <> nil then
    N := AList.Count;
  if N > AMax then
    N := AMax;
  Ini.WriteInteger(ASection, 'Count', N);
  for I := 0 to N - 1 do
    Ini.WriteString(ASection, APrefix + IntToStr(I), EncodeRecent(AList[I]));
end;

procedure LoadAgentRecent(AList: TStrings);
var
  Ini: TMemIniFile;
begin
  try
    Ini := OpenSessionIni;
    try
      ReadList(Ini, AGENT_RECENT_SECTION, 'P', RecentMax, AList);
    finally
      Ini.Free;
    end;
  except
    AList.Clear;
  end;
end;

procedure SaveAgentRecent(AList: TStrings);
var
  Ini: TMemIniFile;
begin
  try
    Ini := OpenSessionIni;
    try
      WriteList(Ini, AGENT_RECENT_SECTION, 'P', RecentMax, AList);
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  except
  end;
end;

function LoadAgentSession: TAgentSession;
var
  Ini: TMemIniFile;
begin
  Result.Roots := TStringList.Create;
  Result.Included := TStringList.Create;
  Result.Prompt := '';
  Result.Answer := '';
  Result.Revised := '';
  Result.Tab := 0;
  try
    Ini := OpenSessionIni;
    try
      ReadList(Ini, AGENT_ROOTS_SECTION, 'R', 20000, Result.Roots);
      ReadList(Ini, AGENT_INCLUDED_SECTION, 'F', 20000, Result.Included);
      Result.Prompt := DecodeRecent(Ini.ReadString(AGENT_STATE_SECTION, 'Prompt', ''));
      Result.Answer := DecodeRecent(Ini.ReadString(AGENT_STATE_SECTION, 'Answer', ''));
      Result.Revised := DecodeRecent(Ini.ReadString(AGENT_STATE_SECTION, 'Revised', ''));
      Result.Tab := Ini.ReadInteger(AGENT_STATE_SECTION, 'Tab', 0);
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure SaveAgentSession(const ASession: TAgentSession);
var
  Ini: TMemIniFile;
begin
  try
    Ini := OpenSessionIni;
    try
      WriteList(Ini, AGENT_ROOTS_SECTION, 'R', 20000, ASession.Roots);
      WriteList(Ini, AGENT_INCLUDED_SECTION, 'F', 20000, ASession.Included);
      Ini.WriteString(AGENT_STATE_SECTION, 'Prompt', EncodeRecent(ASession.Prompt));
      Ini.WriteString(AGENT_STATE_SECTION, 'Answer', EncodeRecent(ASession.Answer));
      Ini.WriteString(AGENT_STATE_SECTION, 'Revised', EncodeRecent(ASession.Revised));
      Ini.WriteInteger(AGENT_STATE_SECTION, 'Tab', ASession.Tab);
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure RememberAgentPrompt(AList: TStrings; const APrompt: string);
var
  I: Integer;
  Key: string;
begin
  if Trim(APrompt) = '' then Exit;
  Key := RecentKey(APrompt);
  for I := AList.Count - 1 downto 0 do
    if RecentKey(AList[I]) = Key then
      AList.Delete(I);
  AList.Insert(0, Trim(APrompt));
  while AList.Count > RecentMax do
    AList.Delete(AList.Count - 1);
end;

function RootRecentMax: Integer;
begin
  Result := Max(RecentMax, 30);
end;

procedure LoadAgentRootRecent(AList: TStrings);
var
  Ini: TMemIniFile;
begin
  try
    Ini := OpenSessionIni;
    try
      ReadList(Ini, AGENT_ROOT_RECENT_SECTION, 'R', RootRecentMax, AList);
    finally
      Ini.Free;
    end;
  except
    AList.Clear;
  end;
end;

procedure SaveAgentRootRecent(AList: TStrings);
var
  Ini: TMemIniFile;
begin
  try
    Ini := OpenSessionIni;
    try
      WriteList(Ini, AGENT_ROOT_RECENT_SECTION, 'R', RootRecentMax, AList);
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure RememberAgentRoot(AList: TStrings; const APath: string);
var
  I: Integer;
  P: string;
begin
  P := ExcludeTrailingPathDelimiter(Trim(APath));
  if P = '' then Exit;
  for I := AList.Count - 1 downto 0 do
    if SameText(ExcludeTrailingPathDelimiter(AList[I]), P) then
      AList.Delete(I);
  AList.Insert(0, P);
  while AList.Count > RootRecentMax do
    AList.Delete(AList.Count - 1);
end;

function ClampAgentInt(AValue, AMin, AMax, ADefault: Integer): Integer;
begin
  if (AValue < AMin) or (AValue > AMax) then
    Result := ADefault
  else
    Result := AValue;
end;

function DefaultAgentPrefs: TAgentPrefs;
begin
  Result.IncludeSubdirs := True;
  Result.Mask := '*.txt;*.log;*.csv;*.json;*.xml;*.md;*.pas;*.py;*.js;*.ts;*.html;*.ini;*.sql';
  Result.MaxDepth := 8;
  Result.MaxFiles := 400;
  Result.MaxReadLines := 60;
  Result.MaxSearchHits := 25;
  Result.OpenPath := '';
  Result.IndexPath := '';
end;

function AgentIniPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + ASKIN_INI;
end;

function LoadAgentPrefs: TAgentPrefs;
var
  Ini: TIniFile;
  D: TAgentPrefs;
begin
  D := DefaultAgentPrefs;
  Result := D;
  Ini := TIniFile.Create(AgentIniPath);
  try
    Result.IncludeSubdirs := Ini.ReadBool(AGENT_INI_SECTION, 'IncludeSubdirs', D.IncludeSubdirs);
    Result.Mask := Trim(Ini.ReadString(AGENT_INI_SECTION, 'Mask', D.Mask));
    if Result.Mask = '' then
      Result.Mask := D.Mask;
    Result.MaxDepth := ClampAgentInt(Ini.ReadInteger(AGENT_INI_SECTION, 'MaxDepth', D.MaxDepth), 0, 32, D.MaxDepth);
    Result.MaxFiles := ClampAgentInt(Ini.ReadInteger(AGENT_INI_SECTION, 'MaxFiles', D.MaxFiles), 1, 20000, D.MaxFiles);
    Result.MaxReadLines := ClampAgentInt(Ini.ReadInteger(AGENT_INI_SECTION, 'MaxReadLines', D.MaxReadLines), 5, 200, D.MaxReadLines);
    Result.MaxSearchHits := ClampAgentInt(Ini.ReadInteger(AGENT_INI_SECTION, 'MaxSearchHits', D.MaxSearchHits), 1, 50, D.MaxSearchHits);
  finally
    Ini.Free;
  end;
end;

procedure SaveAgentPrefs(const APrefs: TAgentPrefs);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AgentIniPath);
  try
    Ini.WriteBool(AGENT_INI_SECTION, 'IncludeSubdirs', APrefs.IncludeSubdirs);
    Ini.WriteString(AGENT_INI_SECTION, 'Mask', APrefs.Mask);
    Ini.WriteInteger(AGENT_INI_SECTION, 'MaxDepth', APrefs.MaxDepth);
    Ini.WriteInteger(AGENT_INI_SECTION, 'MaxFiles', APrefs.MaxFiles);
    Ini.WriteInteger(AGENT_INI_SECTION, 'MaxReadLines', APrefs.MaxReadLines);
    Ini.WriteInteger(AGENT_INI_SECTION, 'MaxSearchHits', APrefs.MaxSearchHits);
  finally
    Ini.Free;
  end;
end;

end.
