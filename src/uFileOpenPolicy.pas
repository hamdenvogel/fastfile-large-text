unit uFileOpenPolicy;

{ Limiar GB indexado vs instant open; lista de ficheiros com fallback apos falha de indice. }

interface

uses
  Classes, SysUtils;

const
  MAX_GB_FILE_INDEXED_DEFAULT = 9999;
  MAX_GB_FILE_INDEXED_MIN = 1;
  MAX_GB_FILE_INDEXED_MAX = 9999;
  INI_KEY_MAX_GB_FILE_INDEXED = 'MaxGbFileIndexed';
  INI_KEY_INSTANT_FALLBACK_FILES = 'InstantFallbackFiles';

procedure LoadFileOpenPolicyFromIni(const AIniPath: string);
procedure SaveFileOpenPolicyToIni(const AIniPath: string);

function GetMaxGbFileIndexed: Integer;
procedure SetMaxGbFileIndexed(const AGb: Integer);
function MaxBytesFileIndexed: Int64;
function ValidateMaxGbFileIndexedInput(const S: string; out AGb: Integer;
  out AErrorMsg: string): Boolean;

function IsInstantFallbackFile(const APath: string): Boolean;
procedure AddInstantFallbackFile(const APath: string);
procedure RemoveInstantFallbackFile(const APath: string);

implementation

uses
  IniFiles, UnConsts;

var
  GMaxGbFileIndexed: Integer;
  GInstantFallbackFiles: TStringList;

function NormalizeFilePath(const APath: string): string;
begin
  Result := Trim(APath);
  if Result = '' then Exit;
  Result := ExpandFileName(Result);
  Result := AnsiLowerCase(Result);
end;

procedure EnsureFallbackList;
begin
  if GInstantFallbackFiles = nil then
  begin
    GInstantFallbackFiles := TStringList.Create;
    GInstantFallbackFiles.Sorted := True;
    GInstantFallbackFiles.Duplicates := dupIgnore;
  end;
end;

procedure ResetMaxGbToDefault;
begin
  GMaxGbFileIndexed := MAX_GB_FILE_INDEXED_DEFAULT;
end;

function ClampMaxGb(AGb: Integer): Integer;
begin
  Result := AGb;
  if Result < MAX_GB_FILE_INDEXED_MIN then
    Result := MAX_GB_FILE_INDEXED_MIN;
  if Result > MAX_GB_FILE_INDEXED_MAX then
    Result := MAX_GB_FILE_INDEXED_MAX;
end;

function ParseMaxGbFromIni(const S: string): Integer;
var
  N: Integer;
begin
  Result := MAX_GB_FILE_INDEXED_DEFAULT;
  if Trim(S) = '' then Exit;
  N := StrToIntDef(Trim(S), -1);
  if (N < MAX_GB_FILE_INDEXED_MIN) or (N > MAX_GB_FILE_INDEXED_MAX) then
    Exit;
  Result := N;
end;

procedure LoadFileOpenPolicyFromIni(const AIniPath: string);
var
  Ini: TIniFile;
  S, Part: string;
  P: Integer;
  NeedSave: Boolean;
begin
  ResetMaxGbToDefault;
  EnsureFallbackList;
  GInstantFallbackFiles.Clear;
  NeedSave := False;
  if (AIniPath = '') or (not FileExists(AIniPath)) then
  begin
    NeedSave := AIniPath <> '';
    if NeedSave then
      SaveFileOpenPolicyToIni(AIniPath);
    Exit;
  end;
  Ini := TIniFile.Create(AIniPath);
  try
    if not Ini.ValueExists(APPLICATION_NAME, INI_KEY_MAX_GB_FILE_INDEXED) then
      NeedSave := True
    else
    begin
      GMaxGbFileIndexed := ParseMaxGbFromIni(
        Ini.ReadString(APPLICATION_NAME, INI_KEY_MAX_GB_FILE_INDEXED, ''));
      if (GMaxGbFileIndexed < MAX_GB_FILE_INDEXED_MIN) or
         (GMaxGbFileIndexed > MAX_GB_FILE_INDEXED_MAX) then
      begin
        ResetMaxGbToDefault;
        NeedSave := True;
      end;
    end;
    S := Ini.ReadString(APPLICATION_NAME, INI_KEY_INSTANT_FALLBACK_FILES, '');
    while S <> '' do
    begin
      P := Pos('|', S);
      if P > 0 then
      begin
        Part := Copy(S, 1, P - 1);
        Delete(S, 1, P);
      end
      else
      begin
        Part := S;
        S := '';
      end;
      Part := NormalizeFilePath(Part);
      if Part <> '' then
        GInstantFallbackFiles.Add(Part);
    end;
  finally
    Ini.Free;
  end;
  if NeedSave then
    SaveFileOpenPolicyToIni(AIniPath);
end;

procedure SaveFileOpenPolicyToIni(const AIniPath: string);
var
  Ini: TIniFile;
  S: string;
  I: Integer;
begin
  if AIniPath = '' then Exit;
  EnsureFallbackList;
  GMaxGbFileIndexed := ClampMaxGb(GMaxGbFileIndexed);
  Ini := TIniFile.Create(AIniPath);
  try
    Ini.WriteInteger(APPLICATION_NAME, INI_KEY_MAX_GB_FILE_INDEXED, GMaxGbFileIndexed);
    S := '';
    for I := 0 to GInstantFallbackFiles.Count - 1 do
    begin
      if S <> '' then
        S := S + '|';
      S := S + GInstantFallbackFiles[I];
    end;
    Ini.WriteString(APPLICATION_NAME, INI_KEY_INSTANT_FALLBACK_FILES, S);
  finally
    Ini.Free;
  end;
end;

function GetMaxGbFileIndexed: Integer;
begin
  if GMaxGbFileIndexed < MAX_GB_FILE_INDEXED_MIN then
    ResetMaxGbToDefault;
  Result := GMaxGbFileIndexed;
end;

procedure SetMaxGbFileIndexed(const AGb: Integer);
begin
  GMaxGbFileIndexed := ClampMaxGb(AGb);
end;

function MaxBytesFileIndexed: Int64;
begin
  Result := Int64(GetMaxGbFileIndexed) * 1024 * 1024 * 1024;
end;

function ValidateMaxGbFileIndexedInput(const S: string; out AGb: Integer;
  out AErrorMsg: string): Boolean;
begin
  Result := False;
  AGb := 0;
  AErrorMsg := '';
  if Trim(S) = '' then
  begin
    AErrorMsg := 'Open.MaxGbLimit.Empty';
    Exit;
  end;
  AGb := StrToIntDef(Trim(S), -1);
  if AGb < MAX_GB_FILE_INDEXED_MIN then
  begin
    AErrorMsg := 'Open.MaxGbLimit.TooSmall';
    Exit;
  end;
  if AGb > MAX_GB_FILE_INDEXED_MAX then
  begin
    AErrorMsg := 'Open.MaxGbLimit.TooLarge';
    Exit;
  end;
  Result := True;
end;

function IsInstantFallbackFile(const APath: string): Boolean;
var
  N: string;
begin
  Result := False;
  N := NormalizeFilePath(APath);
  if N = '' then Exit;
  EnsureFallbackList;
  Result := GInstantFallbackFiles.IndexOf(N) >= 0;
end;

procedure AddInstantFallbackFile(const APath: string);
var
  N: string;
begin
  N := NormalizeFilePath(APath);
  if N = '' then Exit;
  EnsureFallbackList;
  GInstantFallbackFiles.Add(N);
end;

procedure RemoveInstantFallbackFile(const APath: string);
var
  N: string;
  Idx: Integer;
begin
  N := NormalizeFilePath(APath);
  if N = '' then Exit;
  EnsureFallbackList;
  Idx := GInstantFallbackFiles.IndexOf(N);
  if Idx >= 0 then
    GInstantFallbackFiles.Delete(Idx);
end;

initialization

ResetMaxGbToDefault;

finalization

if GInstantFallbackFiles <> nil then
  FreeAndNil(GInstantFallbackFiles);

end.
