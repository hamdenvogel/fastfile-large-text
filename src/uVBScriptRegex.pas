unit uVBScriptRegex;

{
  VBScript.RegExp pattern normalization and compile check (shared by MainUnit and AI help).
}

interface

uses
  SysUtils;

function NormalizeRegexPatternForVBScript(const AInputPattern: String;
  out ANormalizedPattern: String; out AErrorMsg: String): Boolean;

{ True if the pattern normalizes and VBScript.RegExp accepts Pattern := ... }
function TryCompileVBScriptRegexPattern(const AInputPattern: String;
  out ANormalizedPattern: String; out AErrorMsg: String): Boolean;

implementation

uses
  Windows, ComObj, ActiveX, uI18n;

function NormalizeRegexPatternForVBScript(const AInputPattern: String;
  out ANormalizedPattern: String; out AErrorMsg: String): Boolean;
var
  S, Flags: String;
  i, SlashPos, BackslashCount, j: Integer;
  C: Char;
begin
  Result := False;
  AErrorMsg := '';
  ANormalizedPattern := Trim(AInputPattern);
  S := ANormalizedPattern;

  if S = '' then
  begin
    AErrorMsg := TrText('Pattern cannot be empty.');
    Exit;
  end;

  { Accept JS-style delimiters /.../gim and convert to VBScript.RegExp pattern text. }
  if (Length(S) >= 2) and (S[1] = '/') then
  begin
    SlashPos := 0;
    for i := Length(S) downto 2 do
      if S[i] = '/' then
      begin
        BackslashCount := 0;
        j := i - 1;
        while (j >= 1) and (S[j] = Chr(92)) do
        begin
          Inc(BackslashCount);
          Dec(j);
        end;
        if (BackslashCount mod 2) = 0 then
        begin
          SlashPos := i;
          Break;
        end;
      end;

    if SlashPos = 0 then
    begin
      AErrorMsg := TrText('Invalid Regex:') + ' ' + TrText('Missing closing "/" delimiter.');
      Exit;
    end;

    ANormalizedPattern := Copy(S, 2, SlashPos - 2);
    Flags := LowerCase(Copy(S, SlashPos + 1, MaxInt));
    for i := 1 to Length(Flags) do
    begin
      C := Flags[i];
      if not (C in ['g', 'i', 'm']) then
      begin
        AErrorMsg := TrText('Invalid Regex:') + ' ' + Format(TrText('Unsupported regex flag: %s'), [C]);
        Exit;
      end;
    end;
  end;

  Result := True;
end;

function TryCompileVBScriptRegexPattern(const AInputPattern: String;
  out ANormalizedPattern: String; out AErrorMsg: String): Boolean;
var
  RegObj: Variant;
  ComReady: Boolean;
begin
  Result := False;
  ANormalizedPattern := '';
  AErrorMsg := '';
  if not NormalizeRegexPatternForVBScript(AInputPattern, ANormalizedPattern, AErrorMsg) then
    Exit;

  ComReady := False;
  try
    CoInitialize(nil);
    ComReady := True;
    RegObj := CreateOleObject('VBScript.RegExp');
    RegObj.Pattern := ANormalizedPattern;
    RegObj.IgnoreCase := True;
    RegObj.Global := False;
    Result := True;
  except
    on E: Exception do
    begin
      AErrorMsg := TrText('Invalid Regex:') + ' ' + E.Message;
      Result := False;
    end;
  end;
  if ComReady then
    CoUninitialize;
end;

end.
