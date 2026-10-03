unit uFastFileAssistantHost;

{
  Callback bridge: MainUnit registers operational handlers so the assistant
  unit does not reference MainUnit (no circular uses, no source in prompts).
}

interface

uses
  SysUtils;

const
  ASSISTANT_MAX_CHAIN = 8;

type
  TAssistantChainStep = record
    ActionId: string;
    Path: string;
    Parts: Integer;
    TotalParts: Integer;
    PartFrom: Integer;
    PartTo: Integer;
    FilterText: string;
    ReplaceText: string;
    LineNo: Integer;
    MaxLines: Integer; { optional: max filtered/exported lines for compose/export }
    CaseSensitive: Boolean;
    ByteOffset: Int64;
  end;

  TFastFileAssistantHost = record
    OpenAndReadFile: procedure(const APath: string) of object;
    ShowTabRead: procedure of object;
    ShowTabRecent: procedure of object;
    ShowHelp: procedure of object;
    ShowFind: procedure of object;
    FindFirst: procedure(const AText: string; ACaseSensitive: Boolean) of object;
    EditLine: procedure(ALineNo: Integer) of object;
    OpenReplace: procedure of object;
    StartTail: procedure of object;
    ShowTabCompare: procedure of object;
    SplitEqualParts: procedure(const ASourcePath: string; AParts: Integer) of object;
    ExtractFileParts: procedure(const ASourcePath: string; ATotalParts, APartFrom, APartTo: Integer) of object;
    OpenFilterDialog: procedure of object;
    ApplyFilter: procedure(const APattern: string; ACaseSensitive: Boolean) of object;
    ClearFilter: procedure of object;
    ContinueFilter: procedure of object;
    CopyFiltered: procedure of object;
    { Up to AMaxLines complete matching lines (1-based numbered). Prefer active filter hits. }
    CollectMatchingLines: function(const ANeedle: string; AMaxLines: Integer;
      ACaseSensitive: Boolean): string of object;
    GetActiveFilterText: function: string of object;
    GetFilteredHitCount: function: Int64 of object;
    GetFilterPartial: function: Boolean of object;
    ExportFile: procedure of object;
    ExportFiltered: procedure of object;
    DeleteDuplicateLines: procedure of object;
    ExtractFrequentStrings: procedure of object;
    ShowCheckboxes: procedure of object;
    GotoLine: procedure(ALineNo: Integer) of object;
    CharacterCodeValue: procedure of object;
    ShowTabMergeLines: procedure of object;
    ShowTabMergeFiles: procedure(const APath: string; AMergeMode: Integer;
    AAfterLine: Integer) of object;
    ToggleWordWrap: procedure of object;
    GetContextSummary: function: string of object;
    GetOpenFilePath: function: string of object;
    { Put a validated path into edtFileName without starting Read. }
    SetFileNameBox: procedure(const APath: string) of object;
    GetOpenFileLineCount: function: Int64 of object;
    GetOpenFileDiskInfo: function(out ACreated, AAccessed, AModified: TDateTime;
      out ASizeBytes: Int64): Boolean of object;
    GetRecentFilePathByListIndex: function(AIndex1Based: Integer): string of object;
    ExecuteAction: procedure(const AStep: TAssistantChainStep) of object;
    NotifyGeneratedFile: procedure(const AFileName: string) of object;
    { Show/hide resize splitter chrome when the host panel visibility changes. }
    NotifyPanelVisible: procedure(AVisible: Boolean) of object;
    { Syntax-check a compose source file (.py/.js/.ts/.tsx). AReport = OK / ERROR lines. }
    ValidateComposedSource: function(const APath: string; out AReport: string): Boolean of object;
  end;

{ Shared gate for Assistente Validar / validate_source (see VALIDATABLE_SOURCE_EXTS). }
function IsValidatableComposeSourcePath(const APath: string): Boolean;
function ValidatableSourceOpenDialogFilter: string;

procedure SetFastFileAssistantHost(const AHost: TFastFileAssistantHost);
function FastFileAssistantHostReady: Boolean;
function AssistantHostGetContext: string;
function AssistantHostGetOpenFilePath: string;
procedure AssistantHostSetFileNameBox(const APath: string);
function AssistantHostGetOpenFileLineCount: Int64;
function AssistantHostGetOpenFileDiskInfo(out ACreated, AAccessed, AModified: TDateTime;
  out ASizeBytes: Int64): Boolean;
function AssistantHostGetRecentFilePathByListIndex(AIndex1Based: Integer): string;

procedure AssistantHostOpenAndRead(const APath: string);
procedure AssistantHostShowTabRead;
procedure AssistantHostShowTabRecent;
procedure AssistantHostShowHelp;
procedure AssistantHostShowFind;
procedure AssistantHostFindFirst(const AText: string; ACaseSensitive: Boolean);
procedure AssistantHostEditLine(ALineNo: Integer);
procedure AssistantHostOpenReplace;
procedure AssistantHostStartTail;
procedure AssistantHostShowTabCompare;
procedure AssistantHostSplitEqual(const ASourcePath: string; AParts: Integer);
procedure AssistantHostExtractParts(const ASourcePath: string; ATotalParts, APartFrom, APartTo: Integer);
procedure AssistantHostOpenFilterDialog;
procedure AssistantHostApplyFilter(const APattern: string; ACaseSensitive: Boolean);
procedure AssistantHostClearFilter;
procedure AssistantHostContinueFilter;
procedure AssistantHostCopyFiltered;
function AssistantHostCollectMatchingLines(const ANeedle: string; AMaxLines: Integer;
  ACaseSensitive: Boolean): string;
function AssistantHostGetActiveFilterText: string;
function AssistantHostGetFilteredHitCount: Int64;
function AssistantHostGetFilterPartial: Boolean;
procedure AssistantHostExportFile;
procedure AssistantHostExportFiltered;
procedure AssistantHostDeleteDuplicateLines;
procedure AssistantHostExtractFrequentStrings;
procedure AssistantHostShowCheckboxes;
procedure AssistantHostGotoLine(ALineNo: Integer);
procedure AssistantHostCharacterCodeValue;
procedure AssistantHostShowTabMergeLines;
procedure AssistantHostShowTabMergeFiles;
procedure AssistantHostShowTabMergeFilesEx(const APath: string; AMergeMode, AAfterLine: Integer);
procedure AssistantHostToggleWordWrap;

procedure AssistantHostClearChain;
function AssistantHostHasPendingChain: Boolean;
procedure AssistantHostSetChain(const Steps: array of TAssistantChainStep; ACount: Integer;
  ADeferUntilReadComplete: Boolean);
procedure AssistantHostNotifyReadFinished(const ALoadedPath: string);
function AssistantHostRunChainStep(const S: TAssistantChainStep): Boolean;
procedure AssistantHostExecuteAction(const AStep: TAssistantChainStep);
procedure AssistantHostNotifyGeneratedFile(const AFileName: string);
procedure AssistantHostNotifyPanelVisible(AVisible: Boolean);
function AssistantHostValidateComposedSource(const APath: string; out AReport: string): Boolean;
procedure AssistantSetExportPreferFile(AValue: Boolean);
function AssistantGetExportPreferFile: Boolean;
procedure AssistantHostSetLastExportPath(const APath: string);
function AssistantHostGetLastExportPath: string;

implementation

uses
  UnConsts;

var
  GHost: TFastFileAssistantHost;
  GChain: array[0..ASSISTANT_MAX_CHAIN - 1] of TAssistantChainStep;
  GChainCount: Integer;
  GChainWaitRead: Boolean;
  GExportPreferFile: Boolean;
  GLastExportPath: string;

function IsValidatableComposeSourcePath(const APath: string): Boolean;
var
  Ext, Needle: string;
begin
  Result := False;
  Ext := LowerCase(ExtractFileExt(Trim(APath)));
  if Ext = '' then Exit;
  Needle := ';' + Ext + ';';
  Result := Pos(Needle, ';' + LowerCase(VALIDATABLE_SOURCE_EXTS) + ';') > 0;
end;

function ValidatableSourceOpenDialogFilter: string;
begin
  { No *.* — chat "carregar o fonte pra validar" must pick a supported type first. }
  Result :=
    'Python / JavaScript / TypeScript / JSX / TSX' +
    '|*.py;*.js;*.jsx;*.ts;*.tsx;*.mjs;*.cjs|' +
    'Python (*.py)|*.py|' +
    'JavaScript (*.js;*.mjs;*.cjs)|*.js;*.mjs;*.cjs|' +
    'JSX (*.jsx)|*.jsx|' +
    'TypeScript (*.ts)|*.ts|' +
    'TSX (*.tsx)|*.tsx';
end;

procedure SetFastFileAssistantHost(const AHost: TFastFileAssistantHost);
begin
  GHost := AHost;
end;

function FastFileAssistantHostReady: Boolean;
begin
  Result := Assigned(GHost.OpenAndReadFile);
end;

function AssistantHostGetContext: string;
begin
  Result := '';
  if Assigned(GHost.GetContextSummary) then
    Result := GHost.GetContextSummary;
end;

function AssistantHostGetOpenFilePath: string;
begin
  Result := '';
  if Assigned(GHost.GetOpenFilePath) then
    Result := Trim(GHost.GetOpenFilePath);
end;

procedure AssistantHostSetFileNameBox(const APath: string);
begin
  if Assigned(GHost.SetFileNameBox) then
    GHost.SetFileNameBox(APath);
end;

function AssistantHostGetOpenFileLineCount: Int64;
begin
  Result := 0;
  if Assigned(GHost.GetOpenFileLineCount) then
    Result := GHost.GetOpenFileLineCount;
end;

function AssistantHostGetOpenFileDiskInfo(out ACreated, AAccessed, AModified: TDateTime;
  out ASizeBytes: Int64): Boolean;
begin
  Result := False;
  ACreated := 0;
  AAccessed := 0;
  AModified := 0;
  ASizeBytes := 0;
  if Assigned(GHost.GetOpenFileDiskInfo) then
    Result := GHost.GetOpenFileDiskInfo(ACreated, AAccessed, AModified, ASizeBytes);
end;

function AssistantHostGetRecentFilePathByListIndex(AIndex1Based: Integer): string;
begin
  Result := '';
  if Assigned(GHost.GetRecentFilePathByListIndex) then
    Result := GHost.GetRecentFilePathByListIndex(AIndex1Based);
end;

procedure AssistantHostOpenAndRead(const APath: string);
begin
  if Assigned(GHost.OpenAndReadFile) then
    GHost.OpenAndReadFile(APath);
end;

procedure AssistantHostShowTabRead;
begin
  if Assigned(GHost.ShowTabRead) then
    GHost.ShowTabRead;
end;

procedure AssistantHostShowTabRecent;
begin
  if Assigned(GHost.ShowTabRecent) then
    GHost.ShowTabRecent;
end;

procedure AssistantHostShowHelp;
begin
  if Assigned(GHost.ShowHelp) then
    GHost.ShowHelp;
end;

procedure AssistantHostShowFind;
begin
  if Assigned(GHost.ShowFind) then
    GHost.ShowFind;
end;

procedure AssistantHostFindFirst(const AText: string; ACaseSensitive: Boolean);
begin
  if Assigned(GHost.FindFirst) then
    GHost.FindFirst(AText, ACaseSensitive);
end;

procedure AssistantHostEditLine(ALineNo: Integer);
begin
  if Assigned(GHost.EditLine) then
    GHost.EditLine(ALineNo);
end;

procedure AssistantHostOpenReplace;
begin
  if Assigned(GHost.OpenReplace) then
    GHost.OpenReplace;
end;

procedure AssistantHostStartTail;
begin
  if Assigned(GHost.StartTail) then
    GHost.StartTail;
end;

procedure AssistantHostShowTabCompare;
begin
  if Assigned(GHost.ShowTabCompare) then
    GHost.ShowTabCompare;
end;

procedure AssistantHostSplitEqual(const ASourcePath: string; AParts: Integer);
begin
  if Assigned(GHost.SplitEqualParts) then
    GHost.SplitEqualParts(ASourcePath, AParts);
end;

procedure AssistantHostExtractParts(const ASourcePath: string; ATotalParts, APartFrom, APartTo: Integer);
begin
  if Assigned(GHost.ExtractFileParts) then
    GHost.ExtractFileParts(ASourcePath, ATotalParts, APartFrom, APartTo);
end;

procedure AssistantHostOpenFilterDialog;
begin
  if Assigned(GHost.OpenFilterDialog) then
    GHost.OpenFilterDialog;
end;

procedure AssistantHostApplyFilter(const APattern: string; ACaseSensitive: Boolean);
begin
  if Assigned(GHost.ApplyFilter) then
    GHost.ApplyFilter(APattern, ACaseSensitive);
end;

procedure AssistantHostClearFilter;
begin
  if Assigned(GHost.ClearFilter) then
    GHost.ClearFilter;
end;

procedure AssistantHostContinueFilter;
begin
  if Assigned(GHost.ContinueFilter) then
    GHost.ContinueFilter;
end;

procedure AssistantHostCopyFiltered;
begin
  if Assigned(GHost.CopyFiltered) then
    GHost.CopyFiltered;
end;

function AssistantHostCollectMatchingLines(const ANeedle: string; AMaxLines: Integer;
  ACaseSensitive: Boolean): string;
begin
  Result := '';
  if Assigned(GHost.CollectMatchingLines) then
    Result := GHost.CollectMatchingLines(ANeedle, AMaxLines, ACaseSensitive);
end;

function AssistantHostGetActiveFilterText: string;
begin
  Result := '';
  if Assigned(GHost.GetActiveFilterText) then
    Result := GHost.GetActiveFilterText;
end;

function AssistantHostGetFilteredHitCount: Int64;
begin
  Result := 0;
  if Assigned(GHost.GetFilteredHitCount) then
    Result := GHost.GetFilteredHitCount;
end;

function AssistantHostGetFilterPartial: Boolean;
begin
  Result := False;
  if Assigned(GHost.GetFilterPartial) then
    Result := GHost.GetFilterPartial;
end;

procedure AssistantHostExportFile;
begin
  if Assigned(GHost.ExportFile) then
    GHost.ExportFile;
end;

procedure AssistantHostExportFiltered;
begin
  if Assigned(GHost.ExportFiltered) then
    GHost.ExportFiltered;
end;

procedure AssistantHostDeleteDuplicateLines;
begin
  if Assigned(GHost.DeleteDuplicateLines) then
    GHost.DeleteDuplicateLines;
end;

procedure AssistantHostExtractFrequentStrings;
begin
  if Assigned(GHost.ExtractFrequentStrings) then
    GHost.ExtractFrequentStrings;
end;

procedure AssistantHostShowCheckboxes;
begin
  if Assigned(GHost.ShowCheckboxes) then
    GHost.ShowCheckboxes;
end;

procedure AssistantHostGotoLine(ALineNo: Integer);
begin
  if Assigned(GHost.GotoLine) then
    GHost.GotoLine(ALineNo);
end;

procedure AssistantHostCharacterCodeValue;
begin
  if Assigned(GHost.CharacterCodeValue) then
    GHost.CharacterCodeValue;
end;

procedure AssistantHostShowTabMergeLines;
begin
  if Assigned(GHost.ShowTabMergeLines) then
    GHost.ShowTabMergeLines;
end;

procedure AssistantHostShowTabMergeFiles;
begin
  if Assigned(GHost.ShowTabMergeFiles) then
    GHost.ShowTabMergeFiles('', -1, 1);
end;

procedure AssistantHostShowTabMergeFilesEx(const APath: string; AMergeMode, AAfterLine: Integer);
begin
  if Assigned(GHost.ShowTabMergeFiles) then
    GHost.ShowTabMergeFiles(APath, AMergeMode, AAfterLine);
end;

procedure AssistantHostToggleWordWrap;
begin
  if Assigned(GHost.ToggleWordWrap) then
    GHost.ToggleWordWrap;
end;

procedure AssistantHostClearChain;
begin
  GChainCount := 0;
  GChainWaitRead := False;
  FillChar(GChain, SizeOf(GChain), 0);
end;

function AssistantHostHasPendingChain: Boolean;
begin
  Result := GChainCount > 0;
end;

procedure AssistantHostSetChain(const Steps: array of TAssistantChainStep; ACount: Integer;
  ADeferUntilReadComplete: Boolean);
var
  i: Integer;
begin
  AssistantHostClearChain;
  GChainWaitRead := ADeferUntilReadComplete;
  if ACount <= 0 then Exit;
  if ACount > ASSISTANT_MAX_CHAIN then
    GChainCount := ASSISTANT_MAX_CHAIN
  else
    GChainCount := ACount;
  for i := 0 to GChainCount - 1 do
    GChain[i] := Steps[i];
end;

procedure AssistantHostExecuteAction(const AStep: TAssistantChainStep);
begin
  if Assigned(GHost.ExecuteAction) then
    GHost.ExecuteAction(AStep);
end;

procedure AssistantHostNotifyGeneratedFile(const AFileName: string);
begin
  if Assigned(GHost.NotifyGeneratedFile) then
    GHost.NotifyGeneratedFile(AFileName);
end;

procedure AssistantHostNotifyPanelVisible(AVisible: Boolean);
begin
  if Assigned(GHost.NotifyPanelVisible) then
    GHost.NotifyPanelVisible(AVisible);
end;

function AssistantHostValidateComposedSource(const APath: string; out AReport: string): Boolean;
begin
  AReport := '';
  Result := False;
  if not Assigned(GHost.ValidateComposedSource) then Exit;
  Result := GHost.ValidateComposedSource(APath, AReport);
end;

procedure AssistantHostSetLastExportPath(const APath: string);
begin
  GLastExportPath := Trim(APath);
end;

function AssistantHostGetLastExportPath: string;
begin
  Result := GLastExportPath;
end;

function AssistantHostRunChainStep(const S: TAssistantChainStep): Boolean;
begin
  Result := False;
  if S.ActionId = '' then Exit;
  if Assigned(GHost.ExecuteAction) then
  begin
    GHost.ExecuteAction(S);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'open_and_read_file') then
  begin
    AssistantHostOpenAndRead(S.Path);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'open_recent_file') then
  begin
    if Assigned(GHost.ExecuteAction) then
      GHost.ExecuteAction(S)
    else if S.LineNo <> 0 then
      AssistantHostOpenAndRead(AssistantHostGetRecentFilePathByListIndex(S.LineNo));
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_tab_read') then
  begin
    AssistantHostShowTabRead;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_tab_recent') then
  begin
    AssistantHostShowTabRecent;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_help') then
  begin
    AssistantHostShowHelp;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'open_find') then
  begin
    AssistantHostShowFind;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'find_text') then
  begin
    AssistantHostFindFirst(S.FilterText, S.CaseSensitive);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'edit_line') then
  begin
    AssistantHostEditLine(S.LineNo);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'open_replace') then
  begin
    AssistantHostOpenReplace;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'start_tail') then
  begin
    AssistantHostStartTail;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_tab_compare') then
  begin
    AssistantHostShowTabCompare;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'split_equal_parts') then
  begin
    AssistantHostSplitEqual(S.Path, S.Parts);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'extract_file_parts') then
  begin
    AssistantHostExtractParts(S.Path, S.TotalParts, S.PartFrom, S.PartTo);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'open_filter') then
  begin
    AssistantHostOpenFilterDialog;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'apply_filter') then
  begin
    AssistantHostApplyFilter(S.FilterText, S.CaseSensitive);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'clear_filter') then
  begin
    AssistantHostClearFilter;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'continue_filter') then
  begin
    AssistantHostContinueFilter;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'copy_filtered') then
  begin
    AssistantHostCopyFiltered;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'export_file') then
  begin
    AssistantHostExportFile;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'export_filtered') then
  begin
    AssistantHostExportFiltered;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'delete_duplicate_lines') then
  begin
    AssistantHostDeleteDuplicateLines;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'extract_frequent_strings') then
  begin
    AssistantHostExtractFrequentStrings;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_checkboxes') then
  begin
    AssistantHostShowCheckboxes;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'goto_line') then
  begin
    AssistantHostGotoLine(S.LineNo);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'character_code_value') then
  begin
    AssistantHostCharacterCodeValue;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_tab_merge_lines') then
  begin
    AssistantHostShowTabMergeLines;
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'show_tab_merge_files') then
  begin
    AssistantHostShowTabMergeFilesEx(S.Path, S.LineNo, S.Parts);
    Result := True;
    Exit;
  end;
  if SameText(S.ActionId, 'toggle_word_wrap') then
  begin
    AssistantHostToggleWordWrap;
    Result := True;
    Exit;
  end;
end;

procedure AssistantHostRunNextChainSteps;
var
  S: TAssistantChainStep;
begin
  while GChainCount > 0 do
  begin
    S := GChain[0];
    Dec(GChainCount);
    if GChainCount > 0 then
      Move(GChain[1], GChain[0], GChainCount * SizeOf(TAssistantChainStep));
    if not AssistantHostRunChainStep(S) then
      Break;
    if GChainWaitRead then
      Exit;
  end;
  GChainWaitRead := False;
end;

procedure AssistantHostNotifyReadFinished(const ALoadedPath: string);
begin
  if not GChainWaitRead then Exit;
  if GChainCount = 0 then
  begin
    GChainWaitRead := False;
    Exit;
  end;
  GChainWaitRead := False;
  AssistantHostRunNextChainSteps;
end;

procedure AssistantSetExportPreferFile(AValue: Boolean);
begin
  GExportPreferFile := AValue;
end;

function AssistantGetExportPreferFile: Boolean;
begin
  Result := GExportPreferFile;
end;

end.
