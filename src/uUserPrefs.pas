unit uUserPrefs;

{ User-overridable prefs (MRU sizes + line-hint limits). Defaults live in UnConsts /
  local consts; blank/invalid INI values fall back and are clamped. }

interface

uses
  SysUtils;

const
  INI_SECTION_USER_PREFS = 'UserPrefs';

  DEF_FILTER_RECENT_MAX = 20;
  DEF_ASSISTANT_RECENT_MAX = 20;
  DEF_OPEN_TABS_MRU_MAX = 12;
  DEF_LINE_HINT_SHOW_DELAY_MS = 400;
  DEF_LINE_HINT_MAX_CHARS = 4000;
  DEF_LINE_HINT_MAX_LINES = 32;
  { Caracteres de cada linha (antes/depois) gravados no historico da sessao. }
  DEF_HISTORY_LINE_EXCERPT_MAX = 4000;
  { Escala padrao da interface (PPI do skin); 0 = DPI do Windows. }
  DEF_UI_SCALE_PPI = 0;
  { Segundos para aceitar/rejeitar as edicoes propostas pelo Agente IA; depois sao descartadas. }
  DEF_AGENT_DECISION_SECONDS = 20;

  MIN_FILTER_RECENT_MAX = 5;
  MAX_FILTER_RECENT_MAX = 100;
  MIN_ASSISTANT_RECENT_MAX = 5;
  MAX_ASSISTANT_RECENT_MAX = 100;
  MIN_OPEN_TABS_MRU_MAX = 3;
  MAX_OPEN_TABS_MRU_MAX = 50;
  MIN_LINE_HINT_SHOW_DELAY_MS = 0;
  MAX_LINE_HINT_SHOW_DELAY_MS = 5000;
  MIN_LINE_HINT_MAX_CHARS = 200;
  MAX_LINE_HINT_MAX_CHARS = 50000;
  MIN_LINE_HINT_MAX_LINES = 5;
  MAX_LINE_HINT_MAX_LINES = 200;
  MIN_HISTORY_LINE_EXCERPT_MAX = 200;
  MAX_HISTORY_LINE_EXCERPT_MAX = 32000;
  MIN_UI_SCALE_PPI = 72;
  MAX_UI_SCALE_PPI = 288;
  MIN_AGENT_DECISION_SECONDS = 5;
  MAX_AGENT_DECISION_SECONDS = 600;

type
  TUserPrefValues = record
    FilterRecentMax: Integer;
    AssistantRecentMax: Integer;
    OpenTabsMruMax: Integer;
    LineHintShowDelayMs: Integer;
    LineHintMaxChars: Integer;
    LineHintMaxLines: Integer;
    HistoryLineExcerptMax: Integer;
    DefaultUIScalePPI: Integer;
    AgentDecisionSeconds: Integer;
  end;

procedure LoadUserPrefs(const AIniPath: string);
procedure SaveUserPrefs(const AIniPath: string);
procedure ResetUserPrefsToDefaults;

function GetUserPrefValues: TUserPrefValues;
procedure SetUserPrefValues(const V: TUserPrefValues);

function PrefFilterRecentMax: Integer;
function PrefAssistantRecentMax: Integer;
function PrefOpenTabsMruMax: Integer;
function PrefLineHintShowDelayMs: Integer;
function PrefLineHintMaxChars: Integer;
function PrefLineHintMaxLines: Integer;
function PrefHistoryLineExcerptMax: Integer;
function PrefDefaultUIScalePPI: Integer;
function PrefAgentDecisionSeconds: Integer;
function ClampUIScalePPI(AValue: Integer): Integer;

function ClampUserPrefInt(AValue, AMin, AMax, ADefault: Integer): Integer;

implementation

uses
  IniFiles, UnConsts;

var
  GPrefs: TUserPrefValues;
  GLoaded: Boolean = False;

function ClampUserPrefInt(AValue, AMin, AMax, ADefault: Integer): Integer;
begin
  if (AValue < AMin) or (AValue > AMax) then
    Result := ADefault
  else
    Result := AValue;
end;

function ClampUIScalePPI(AValue: Integer): Integer;
begin
  if (AValue < MIN_UI_SCALE_PPI) or (AValue > MAX_UI_SCALE_PPI) then
    Result := DEF_UI_SCALE_PPI
  else
    Result := AValue;
end;

procedure ApplyDefaults(var V: TUserPrefValues);
begin
  V.FilterRecentMax := DEF_FILTER_RECENT_MAX;
  V.AssistantRecentMax := DEF_ASSISTANT_RECENT_MAX;
  V.OpenTabsMruMax := OPEN_TABS_MRU_MAX;
  V.LineHintShowDelayMs := LINE_HINT_SHOW_DELAY_MS;
  V.LineHintMaxChars := LINE_HINT_MAX_CHARS;
  V.LineHintMaxLines := LINE_HINT_MAX_LINES;
  V.HistoryLineExcerptMax := DEF_HISTORY_LINE_EXCERPT_MAX;
  V.DefaultUIScalePPI := DEF_UI_SCALE_PPI;
  V.AgentDecisionSeconds := DEF_AGENT_DECISION_SECONDS;
end;

procedure ClampAll(var V: TUserPrefValues);
begin
  V.FilterRecentMax := ClampUserPrefInt(V.FilterRecentMax,
    MIN_FILTER_RECENT_MAX, MAX_FILTER_RECENT_MAX, DEF_FILTER_RECENT_MAX);
  V.AssistantRecentMax := ClampUserPrefInt(V.AssistantRecentMax,
    MIN_ASSISTANT_RECENT_MAX, MAX_ASSISTANT_RECENT_MAX, DEF_ASSISTANT_RECENT_MAX);
  V.OpenTabsMruMax := ClampUserPrefInt(V.OpenTabsMruMax,
    MIN_OPEN_TABS_MRU_MAX, MAX_OPEN_TABS_MRU_MAX, OPEN_TABS_MRU_MAX);
  V.LineHintShowDelayMs := ClampUserPrefInt(V.LineHintShowDelayMs,
    MIN_LINE_HINT_SHOW_DELAY_MS, MAX_LINE_HINT_SHOW_DELAY_MS, LINE_HINT_SHOW_DELAY_MS);
  V.LineHintMaxChars := ClampUserPrefInt(V.LineHintMaxChars,
    MIN_LINE_HINT_MAX_CHARS, MAX_LINE_HINT_MAX_CHARS, LINE_HINT_MAX_CHARS);
  V.LineHintMaxLines := ClampUserPrefInt(V.LineHintMaxLines,
    MIN_LINE_HINT_MAX_LINES, MAX_LINE_HINT_MAX_LINES, LINE_HINT_MAX_LINES);
  V.HistoryLineExcerptMax := ClampUserPrefInt(V.HistoryLineExcerptMax,
    MIN_HISTORY_LINE_EXCERPT_MAX, MAX_HISTORY_LINE_EXCERPT_MAX, DEF_HISTORY_LINE_EXCERPT_MAX);
  V.DefaultUIScalePPI := ClampUIScalePPI(V.DefaultUIScalePPI);
  V.AgentDecisionSeconds := ClampUserPrefInt(V.AgentDecisionSeconds,
    MIN_AGENT_DECISION_SECONDS, MAX_AGENT_DECISION_SECONDS, DEF_AGENT_DECISION_SECONDS);
end;

procedure EnsureLoaded;
begin
  if GLoaded then Exit;
  ApplyDefaults(GPrefs);
  GLoaded := True;
end;

procedure ResetUserPrefsToDefaults;
begin
  ApplyDefaults(GPrefs);
  ClampAll(GPrefs);
  GLoaded := True;
end;

function ReadPrefInt(Ini: TIniFile; const AKey: string; ADefault, AMin, AMax: Integer): Integer;
var
  S: string;
  N: Integer;
begin
  Result := ADefault;
  if Ini = nil then Exit;
  S := Trim(Ini.ReadString(INI_SECTION_USER_PREFS, AKey, ''));
  if S = '' then Exit;
  N := StrToIntDef(S, -MaxInt);
  if N = -MaxInt then Exit;
  Result := ClampUserPrefInt(N, AMin, AMax, ADefault);
end;

procedure LoadUserPrefs(const AIniPath: string);
var
  Ini: TIniFile;
begin
  EnsureLoaded;
  ApplyDefaults(GPrefs);
  if (AIniPath = '') or (not FileExists(AIniPath)) then
  begin
    ClampAll(GPrefs);
    Exit;
  end;
  Ini := TIniFile.Create(AIniPath);
  try
    GPrefs.FilterRecentMax := ReadPrefInt(Ini, 'FilterRecentMax',
      DEF_FILTER_RECENT_MAX, MIN_FILTER_RECENT_MAX, MAX_FILTER_RECENT_MAX);
    GPrefs.AssistantRecentMax := ReadPrefInt(Ini, 'AssistantRecentMax',
      DEF_ASSISTANT_RECENT_MAX, MIN_ASSISTANT_RECENT_MAX, MAX_ASSISTANT_RECENT_MAX);
    GPrefs.OpenTabsMruMax := ReadPrefInt(Ini, 'OpenTabsMruMax',
      OPEN_TABS_MRU_MAX, MIN_OPEN_TABS_MRU_MAX, MAX_OPEN_TABS_MRU_MAX);
    GPrefs.LineHintShowDelayMs := ReadPrefInt(Ini, 'LineHintShowDelayMs',
      LINE_HINT_SHOW_DELAY_MS, MIN_LINE_HINT_SHOW_DELAY_MS, MAX_LINE_HINT_SHOW_DELAY_MS);
    GPrefs.LineHintMaxChars := ReadPrefInt(Ini, 'LineHintMaxChars',
      LINE_HINT_MAX_CHARS, MIN_LINE_HINT_MAX_CHARS, MAX_LINE_HINT_MAX_CHARS);
    GPrefs.LineHintMaxLines := ReadPrefInt(Ini, 'LineHintMaxLines',
      LINE_HINT_MAX_LINES, MIN_LINE_HINT_MAX_LINES, MAX_LINE_HINT_MAX_LINES);
    GPrefs.HistoryLineExcerptMax := ReadPrefInt(Ini, 'HistoryLineExcerptMax',
      DEF_HISTORY_LINE_EXCERPT_MAX, MIN_HISTORY_LINE_EXCERPT_MAX, MAX_HISTORY_LINE_EXCERPT_MAX);
    GPrefs.DefaultUIScalePPI := ClampUIScalePPI(ReadPrefInt(Ini, 'DefaultUIScalePPI',
      DEF_UI_SCALE_PPI, 0, MAX_UI_SCALE_PPI));
    GPrefs.AgentDecisionSeconds := ReadPrefInt(Ini, 'AgentDecisionSeconds',
      DEF_AGENT_DECISION_SECONDS, MIN_AGENT_DECISION_SECONDS, MAX_AGENT_DECISION_SECONDS);
  finally
    Ini.Free;
  end;
  ClampAll(GPrefs);
end;

procedure SaveUserPrefs(const AIniPath: string);
var
  Ini: TIniFile;
begin
  EnsureLoaded;
  ClampAll(GPrefs);
  if AIniPath = '' then Exit;
  Ini := TIniFile.Create(AIniPath);
  try
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'FilterRecentMax', GPrefs.FilterRecentMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'AssistantRecentMax', GPrefs.AssistantRecentMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'OpenTabsMruMax', GPrefs.OpenTabsMruMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'LineHintShowDelayMs', GPrefs.LineHintShowDelayMs);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'LineHintMaxChars', GPrefs.LineHintMaxChars);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'LineHintMaxLines', GPrefs.LineHintMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'HistoryLineExcerptMax', GPrefs.HistoryLineExcerptMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'DefaultUIScalePPI', GPrefs.DefaultUIScalePPI);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'AgentDecisionSeconds', GPrefs.AgentDecisionSeconds);
  finally
    Ini.Free;
  end;
end;

function GetUserPrefValues: TUserPrefValues;
begin
  EnsureLoaded;
  Result := GPrefs;
end;

procedure SetUserPrefValues(const V: TUserPrefValues);
begin
  GPrefs := V;
  ClampAll(GPrefs);
  GLoaded := True;
end;

function PrefFilterRecentMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.FilterRecentMax;
end;

function PrefAssistantRecentMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.AssistantRecentMax;
end;

function PrefOpenTabsMruMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.OpenTabsMruMax;
end;

function PrefLineHintShowDelayMs: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.LineHintShowDelayMs;
end;

function PrefLineHintMaxChars: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.LineHintMaxChars;
end;

function PrefLineHintMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.LineHintMaxLines;
end;

function PrefHistoryLineExcerptMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.HistoryLineExcerptMax;
end;

function PrefDefaultUIScalePPI: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.DefaultUIScalePPI;
end;

function PrefAgentDecisionSeconds: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.AgentDecisionSeconds;
end;

initialization
  ApplyDefaults(GPrefs);
  GLoaded := True;

end.
