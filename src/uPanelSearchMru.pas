unit uPanelSearchMru;
{ Shared MRU storage for panel search/filter strings (Find Occ, Filter, Bookmark).
  UI wiring (combo + ShowMruListPopup) stays in each bar; this owns list + INI. }

interface

uses
  SysUtils, Classes, StdCtrls, IniFiles, uUserPrefs;

type
  TPanelSearchMru = class
  private
    FItems: TStringList;
    FIniPath: string;
    FSection: string;
    procedure SetIniPath(const APath: string);
    procedure Deduplicate;
  public
    constructor Create(const ASection: string);
    destructor Destroy; override;
    property Items: TStringList read FItems;
    property IniPath: string read FIniPath write SetIniPath;
    property Section: string read FSection;
    procedure Load;
    procedure Save;
    procedure Remember(const APattern: string);
    procedure ClearAll;
    procedure RefreshCombo(ACombo: TComboBox; const AEmptyHint: string);
  end;

function PanelSearchMruEncode(const APattern: string): string;
function PanelSearchMruDecode(const AEncoded: string): string;

implementation

function PanelSearchMruEncode(const APattern: string): string;
begin
  Result := StringReplace(APattern, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function PanelSearchMruDecode(const AEncoded: string): string;
var
  i: Integer;
  S: string;
begin
  Result := '';
  S := AEncoded;
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = '\') and (i < Length(S)) then
    begin
      if S[i + 1] = 'n' then
      begin
        Result := Result + #13#10;
        Inc(i, 2);
      end
      else if S[i + 1] = '\' then
      begin
        Result := Result + '\';
        Inc(i, 2);
      end
      else
      begin
        Result := Result + S[i];
        Inc(i);
      end;
    end
    else
    begin
      Result := Result + S[i];
      Inc(i);
    end;
  end;
end;

constructor TPanelSearchMru.Create(const ASection: string);
begin
  inherited Create;
  FSection := ASection;
  if FSection = '' then
    FSection := 'SearchRecentPatterns';
  FIniPath := '';
  FItems := TStringList.Create;
  FItems.StrictDelimiter := True;
end;

destructor TPanelSearchMru.Destroy;
begin
  try
    Save;
  except
  end;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPanelSearchMru.SetIniPath(const APath: string);
begin
  if SameText(FIniPath, APath) then Exit;
  FIniPath := APath;
  Load;
end;

procedure TPanelSearchMru.Deduplicate;
var
  i, j: Integer;
  A, B: string;
begin
  if not Assigned(FItems) then Exit;
  i := 0;
  while i < FItems.Count do
  begin
    A := AnsiLowerCase(Trim(FItems[i]));
    j := i + 1;
    while j < FItems.Count do
    begin
      B := AnsiLowerCase(Trim(FItems[j]));
      if (A <> '') and (A = B) then
        FItems.Delete(j)
      else
        Inc(j);
    end;
    Inc(i);
  end;
  while FItems.Count > PrefFilterRecentMax do
    FItems.Delete(FItems.Count - 1);
end;

procedure TPanelSearchMru.Load;
var
  Ini: TIniFile;
  n, i: Integer;
  S: string;
begin
  if not Assigned(FItems) then Exit;
  FItems.Clear;
  if FIniPath = '' then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    n := Ini.ReadInteger(FSection, 'Count', 0);
    if n > PrefFilterRecentMax then
      n := PrefFilterRecentMax;
    for i := 0 to n - 1 do
    begin
      S := PanelSearchMruDecode(
        Ini.ReadString(FSection, 'P' + IntToStr(i), ''));
      if Trim(S) <> '' then
        FItems.Add(S);
    end;
  finally
    Ini.Free;
  end;
  Deduplicate;
  Save;
end;

procedure TPanelSearchMru.Save;
var
  Ini: TIniFile;
  i, n: Integer;
begin
  if (FIniPath = '') or (not Assigned(FItems)) then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    n := FItems.Count;
    if n > PrefFilterRecentMax then
      n := PrefFilterRecentMax;
    Ini.WriteInteger(FSection, 'Count', n);
    for i := 0 to PrefFilterRecentMax - 1 do
    begin
      if i < n then
        Ini.WriteString(FSection, 'P' + IntToStr(i),
          PanelSearchMruEncode(FItems[i]))
      else
        Ini.DeleteKey(FSection, 'P' + IntToStr(i));
    end;
  finally
    Ini.Free;
  end;
end;

procedure TPanelSearchMru.Remember(const APattern: string);
var
  S, Key: string;
  i: Integer;
begin
  S := Trim(APattern);
  if (S = '') or (not Assigned(FItems)) then Exit;
  Key := AnsiLowerCase(S);
  for i := FItems.Count - 1 downto 0 do
    if AnsiLowerCase(Trim(FItems[i])) = Key then
      FItems.Delete(i);
  FItems.Insert(0, S);
  while FItems.Count > PrefFilterRecentMax do
    FItems.Delete(FItems.Count - 1);
  Save;
end;

procedure TPanelSearchMru.ClearAll;
begin
  if not Assigned(FItems) then Exit;
  FItems.Clear;
  Save;
end;

procedure TPanelSearchMru.RefreshCombo(ACombo: TComboBox; const AEmptyHint: string);
begin
  if not Assigned(ACombo) or (not Assigned(FItems)) then Exit;
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    if FItems.Count = 0 then
    begin
      ACombo.Items.Add(AEmptyHint);
      ACombo.ItemIndex := 0;
      ACombo.Enabled := False;
      ACombo.DropDownCount := 1;
    end
    else
    begin
      ACombo.Items.Add('');
      ACombo.ItemIndex := -1;
      ACombo.Enabled := True;
      ACombo.DropDownCount := 1;
    end;
  finally
    ACombo.Items.EndUpdate;
  end;
end;

end.
