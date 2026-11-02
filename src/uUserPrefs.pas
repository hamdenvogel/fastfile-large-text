unit uUserPrefs;

{ User-overridable preferences; defaults live in UnConsts, while allowed ranges
  and INI fallback/clamping are maintained here. }

interface

uses
  SysUtils;

const
  INI_SECTION_USER_PREFS = 'UserPrefs';

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
  MIN_SELECTED_LINES_ACTION_MAX = 1;
  MAX_SELECTED_LINES_ACTION_MAX = 10000;
  MIN_ANONYMIZE_MAX_LINES = 1;
  MAX_ANONYMIZE_MAX_LINES = 10000;
  MIN_MERGE_MAX_LINES = 1;
  MAX_MERGE_MAX_LINES = 10000;
  MIN_TRANSLATE_MAX_LINES = 1;
  MAX_TRANSLATE_MAX_LINES = 200;
  MIN_AGENT_SAMPLE_LINES = 20;
  MAX_AGENT_SAMPLE_LINES = 5000;
  MIN_PYTHON_MACRO_SAMPLE_LINES = 1;
  MAX_PYTHON_MACRO_SAMPLE_LINES = 100;

  MIN_EXPORT_CLIPBOARD_MAX_LINES = 10;
  MAX_EXPORT_CLIPBOARD_MAX_LINES = 20000;
  MIN_EXPORT_FILE_MAX_LINES = 1000;
  MAX_EXPORT_FILE_MAX_LINES = 2000000;
  MIN_INSERT_MAX_LINES = 1;
  MAX_INSERT_MAX_LINES = 100000;
  MIN_SPLIT_FILES_MAX = 2;
  MAX_SPLIT_FILES_MAX = 1000;
  MIN_SPLIT_PARTS_MAX = 2;
  MAX_SPLIT_PARTS_MAX = 1000;

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
    SelectedLinesActionMax: Integer;
    AnonymizeMaxLines: Integer;
    MergeMaxLines: Integer;
    TranslateMaxLines: Integer;
    AgentSampleLines: Integer;
    PythonMacroSampleLines: Integer;
    ExportClipboardMaxLines: Integer;
    ExportFileMaxLines: Integer;
    InsertMaxLines: Integer;
    SplitFilesMax: Integer;
    SplitPartsMax: Integer;
    ShowWorkflowWizard: Boolean;
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
function PrefSelectedLinesActionMax: Integer;
function PrefAnonymizeMaxLines: Integer;
function PrefMergeMaxLines: Integer;
function PrefTranslateMaxLines: Integer;
function PrefAgentSampleLines: Integer;
function PrefPythonMacroSampleLines: Integer;
function PrefExportClipboardMaxLines: Integer;
function PrefExportFileMaxLines: Integer;
function PrefInsertMaxLines: Integer;
function PrefSplitFilesMax: Integer;
function PrefSplitPartsMax: Integer;
function PrefShowWorkflowWizard: Boolean;
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
  V.SelectedLinesActionMax := DEF_SELECTED_LINES_ACTION_MAX;
  V.AnonymizeMaxLines := DEF_ANONYMIZE_MAX_LINES;
  V.MergeMaxLines := DEF_MERGE_MAX_LINES;
  V.TranslateMaxLines := DEF_TRANSLATE_MAX_LINES;
  V.AgentSampleLines := DEF_AGENT_SAMPLE_LINES;
  V.PythonMacroSampleLines := DEF_PYTHON_MACRO_SAMPLE_LINES;
  V.ExportClipboardMaxLines := DEF_EXPORT_CLIPBOARD_MAX_LINES;
  V.ExportFileMaxLines := DEF_EXPORT_FILE_MAX_LINES;
  V.InsertMaxLines := DEF_INSERT_MAX_LINES;
  V.SplitFilesMax := DEF_SPLIT_FILES_MAX;
  V.SplitPartsMax := DEF_SPLIT_PARTS_MAX;
  V.ShowWorkflowWizard := True;
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
  V.SelectedLinesActionMax := ClampUserPrefInt(V.SelectedLinesActionMax,
    MIN_SELECTED_LINES_ACTION_MAX, MAX_SELECTED_LINES_ACTION_MAX, DEF_SELECTED_LINES_ACTION_MAX);
  V.AnonymizeMaxLines := ClampUserPrefInt(V.AnonymizeMaxLines,
    MIN_ANONYMIZE_MAX_LINES, MAX_ANONYMIZE_MAX_LINES, DEF_ANONYMIZE_MAX_LINES);
  V.MergeMaxLines := ClampUserPrefInt(V.MergeMaxLines,
    MIN_MERGE_MAX_LINES, MAX_MERGE_MAX_LINES, DEF_MERGE_MAX_LINES);
  V.TranslateMaxLines := ClampUserPrefInt(V.TranslateMaxLines,
    MIN_TRANSLATE_MAX_LINES, MAX_TRANSLATE_MAX_LINES, DEF_TRANSLATE_MAX_LINES);
  V.AgentSampleLines := ClampUserPrefInt(V.AgentSampleLines,
    MIN_AGENT_SAMPLE_LINES, MAX_AGENT_SAMPLE_LINES, DEF_AGENT_SAMPLE_LINES);
  V.PythonMacroSampleLines := ClampUserPrefInt(V.PythonMacroSampleLines,
    MIN_PYTHON_MACRO_SAMPLE_LINES, MAX_PYTHON_MACRO_SAMPLE_LINES,
    DEF_PYTHON_MACRO_SAMPLE_LINES);
  V.ExportClipboardMaxLines := ClampUserPrefInt(V.ExportClipboardMaxLines,
    MIN_EXPORT_CLIPBOARD_MAX_LINES, MAX_EXPORT_CLIPBOARD_MAX_LINES, DEF_EXPORT_CLIPBOARD_MAX_LINES);
  V.ExportFileMaxLines := ClampUserPrefInt(V.ExportFileMaxLines,
    MIN_EXPORT_FILE_MAX_LINES, MAX_EXPORT_FILE_MAX_LINES, DEF_EXPORT_FILE_MAX_LINES);
  V.InsertMaxLines := ClampUserPrefInt(V.InsertMaxLines,
    MIN_INSERT_MAX_LINES, MAX_INSERT_MAX_LINES, DEF_INSERT_MAX_LINES);
  V.SplitFilesMax := ClampUserPrefInt(V.SplitFilesMax,
    MIN_SPLIT_FILES_MAX, MAX_SPLIT_FILES_MAX, DEF_SPLIT_FILES_MAX);
  V.SplitPartsMax := ClampUserPrefInt(V.SplitPartsMax,
    MIN_SPLIT_PARTS_MAX, MAX_SPLIT_PARTS_MAX, DEF_SPLIT_PARTS_MAX);
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
    GPrefs.SelectedLinesActionMax := ReadPrefInt(Ini, 'SelectedLinesActionMax',
      DEF_SELECTED_LINES_ACTION_MAX, MIN_SELECTED_LINES_ACTION_MAX, MAX_SELECTED_LINES_ACTION_MAX);
    GPrefs.AnonymizeMaxLines := ReadPrefInt(Ini, 'AnonymizeMaxLines',
      DEF_ANONYMIZE_MAX_LINES, MIN_ANONYMIZE_MAX_LINES, MAX_ANONYMIZE_MAX_LINES);
    GPrefs.MergeMaxLines := ReadPrefInt(Ini, 'MergeMaxLines',
      DEF_MERGE_MAX_LINES, MIN_MERGE_MAX_LINES, MAX_MERGE_MAX_LINES);
    GPrefs.TranslateMaxLines := ReadPrefInt(Ini, 'TranslateMaxLines',
      DEF_TRANSLATE_MAX_LINES, MIN_TRANSLATE_MAX_LINES, MAX_TRANSLATE_MAX_LINES);
    GPrefs.AgentSampleLines := ReadPrefInt(Ini, 'AgentSampleLines',
      DEF_AGENT_SAMPLE_LINES, MIN_AGENT_SAMPLE_LINES, MAX_AGENT_SAMPLE_LINES);
    GPrefs.PythonMacroSampleLines := ReadPrefInt(Ini, 'PythonMacroSampleLines',
      DEF_PYTHON_MACRO_SAMPLE_LINES, MIN_PYTHON_MACRO_SAMPLE_LINES,
      MAX_PYTHON_MACRO_SAMPLE_LINES);
    GPrefs.ExportClipboardMaxLines := ReadPrefInt(Ini, 'ExportClipboardMaxLines',
      DEF_EXPORT_CLIPBOARD_MAX_LINES, MIN_EXPORT_CLIPBOARD_MAX_LINES, MAX_EXPORT_CLIPBOARD_MAX_LINES);
    GPrefs.ExportFileMaxLines := ReadPrefInt(Ini, 'ExportFileMaxLines',
      DEF_EXPORT_FILE_MAX_LINES, MIN_EXPORT_FILE_MAX_LINES, MAX_EXPORT_FILE_MAX_LINES);
    GPrefs.InsertMaxLines := ReadPrefInt(Ini, 'InsertMaxLines',
      DEF_INSERT_MAX_LINES, MIN_INSERT_MAX_LINES, MAX_INSERT_MAX_LINES);
    GPrefs.SplitFilesMax := ReadPrefInt(Ini, 'SplitFilesMax',
      DEF_SPLIT_FILES_MAX, MIN_SPLIT_FILES_MAX, MAX_SPLIT_FILES_MAX);
    GPrefs.SplitPartsMax := ReadPrefInt(Ini, 'SplitPartsMax',
      DEF_SPLIT_PARTS_MAX, MIN_SPLIT_PARTS_MAX, MAX_SPLIT_PARTS_MAX);
    GPrefs.ShowWorkflowWizard := Ini.ReadBool(INI_SECTION_USER_PREFS,
      'ShowWorkflowWizard', True);
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
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'SelectedLinesActionMax', GPrefs.SelectedLinesActionMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'AnonymizeMaxLines', GPrefs.AnonymizeMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'MergeMaxLines', GPrefs.MergeMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'TranslateMaxLines', GPrefs.TranslateMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'AgentSampleLines', GPrefs.AgentSampleLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'PythonMacroSampleLines',
      GPrefs.PythonMacroSampleLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'ExportClipboardMaxLines', GPrefs.ExportClipboardMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'ExportFileMaxLines', GPrefs.ExportFileMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'InsertMaxLines', GPrefs.InsertMaxLines);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'SplitFilesMax', GPrefs.SplitFilesMax);
    Ini.WriteInteger(INI_SECTION_USER_PREFS, 'SplitPartsMax', GPrefs.SplitPartsMax);
    Ini.WriteBool(INI_SECTION_USER_PREFS, 'ShowWorkflowWizard', GPrefs.ShowWorkflowWizard);
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

function PrefSelectedLinesActionMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.SelectedLinesActionMax;
end;

function PrefAnonymizeMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.AnonymizeMaxLines;
end;

function PrefMergeMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.MergeMaxLines;
end;

function PrefTranslateMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.TranslateMaxLines;
end;

function PrefAgentSampleLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.AgentSampleLines;
end;

function PrefPythonMacroSampleLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.PythonMacroSampleLines;
end;

function PrefExportClipboardMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.ExportClipboardMaxLines;
end;

function PrefExportFileMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.ExportFileMaxLines;
end;

function PrefInsertMaxLines: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.InsertMaxLines;
end;

function PrefSplitFilesMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.SplitFilesMax;
end;

function PrefSplitPartsMax: Integer;
begin
  EnsureLoaded;
  Result := GPrefs.SplitPartsMax;
end;

function PrefShowWorkflowWizard: Boolean;
begin
  EnsureLoaded;
  Result := GPrefs.ShowWorkflowWizard;
end;

initialization
  ApplyDefaults(GPrefs);
  GLoaded := True;

end.
