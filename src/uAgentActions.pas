unit uAgentActions;

{
  FastFile core actions the agent may request (ids from the Assistant capability map).
  Static tables: safe to read from the agent thread. Execution goes through the
  Assistant dispatcher (AssistantHostExecuteAction) on the main thread.

  View   : navigation / display only; run automatically after the agent answers.
  Review : writes files, changes settings or opens a tool on the file; queued in
           Proposed edits and run only when the user accepts.
  Blocked: the agent has its own tool for this (line edits, count) or it needs a
           different chat (compose, consumer AI/RAG).
}

interface

type
  TAgentActionClass = (aacUnsupported, aacBlocked, aacView, aacReview);

function AgentActionClass(const AId: string): TAgentActionClass;
{ The action works on the file loaded in the main window: open APath first when it differs. }
function AgentActionNeedsOpenFile(const AId: string): Boolean;
{ Writes the open file in place: other proposals on that file become stale. }
function AgentActionMutatesFile(const AId: string): Boolean;
{ Not an Assistant catalog id: the host runs it (TfrmAgentWorkspace.OnRunExtraAction). }
function AgentActionIsExtra(const AId: string): Boolean;
function AgentActionBlockedHint(const AId: string): string;

implementation

uses
  SysUtils;

const
  VIEW_IDS: array[0..59] of string = (
    'toggle_fullscreen',
    'open_find', 'open_filter', 'open_replace', 'find_in_files', 'open_options',
    'show_help', 'show_about', 'show_version_history', 'show_script_engine', 'show_tail_macro',
    'new_file', 'open_preferences', 'toggle_bookmark_bar', 'restore_session_tabs', 'open_anonymize_dialog',
    'goto_line', 'goto_byte_offset', 'goto_file_start', 'goto_file_end',
    'find_text', 'find_next', 'find_previous', 'view_find_occurrences', 'clear_find',
    'find_case_auto', 'find_case_sensitive', 'find_case_ignore',
    'apply_filter', 'clear_filter', 'continue_filter', 'copy_filtered',
    'filter_match_auto', 'filter_match_contains', 'filter_match_prefix', 'filter_match_regex',
    'filter_case_auto', 'filter_case_sensitive', 'filter_case_ignore',
    'toggle_bookmark', 'next_bookmark', 'prev_bookmark',
    'toggle_word_wrap', 'show_checkboxes', 'zoom_in', 'zoom_out', 'toggle_whitespace_marks',
    'toggle_csv_mode', 'toggle_csv_header', 'character_code_value',
    'show_tab_read', 'show_tab_recent', 'show_tab_compare', 'show_tab_merge_lines',
    'show_tab_merge_files', 'open_and_read_file', 'open_recent_file', 'reload_file',
    'start_tail', 'pause_tail');

  REVIEW_IDS: array[0..24] of string = (
    'replace_all', 'delete_duplicate_lines', 'extract_frequent_strings',
    'split_equal_parts', 'extract_file_parts', 'split_files', 'pattern_split',
    'export_file', 'export_lines', 'export_matching_lines', 'export_filtered',
    'clear_bookmarks', 'force_index_file', 'toggle_readonly_session', 'save_session', 'load_session',
    'toggle_zero_scan', 'open_policy_auto', 'open_policy_index', 'open_policy_instant',
    'configure_max_gb', 'toggle_segmented_heavy_ops', 'segment_ops_auto', 'segment_ops_always',
    'segment_ops_never');

  BLOCKED_IDS: array[0..18] of string = (
    'edit_line', 'insert_line', 'duplicate_line', 'delete_line', 'insert_multiple_lines',
    'paste_lines', 'copy_selection', 'undo', 'redo', 'clear_file', 'cancel_search',
    'count_matching_lines', 'count_line_prefixes', 'consumer_ai', 'consumer_rag',
    'compose_document', 'validate_source', 'open_file_dialog', 'tail_macro_reprocess');

  { Not in the Assistant catalog: run by the host's own handler (OnRunExtraAction). }
  EXTRA_IDS: array[0..4] of string = (
    'new_file', 'open_preferences', 'toggle_bookmark_bar', 'restore_session_tabs', 'open_anonymize_dialog');

  FILE_BOUND_IDS: array[0..33] of string = (
    'open_find', 'open_filter', 'open_replace',
    'goto_line', 'goto_byte_offset', 'goto_file_start', 'goto_file_end',
    'find_text', 'find_next', 'find_previous', 'view_find_occurrences', 'clear_find',
    'apply_filter', 'clear_filter', 'continue_filter', 'copy_filtered',
    'toggle_bookmark', 'next_bookmark', 'prev_bookmark', 'clear_bookmarks',
    'toggle_csv_mode', 'toggle_csv_header', 'toggle_whitespace_marks', 'character_code_value',
    'start_tail', 'pause_tail', 'reload_file',
    'replace_all', 'delete_duplicate_lines', 'extract_frequent_strings', 'split_files',
    'pattern_split', 'export_file', 'export_matching_lines');

  MUTATE_IDS: array[0..1] of string = ('replace_all', 'delete_duplicate_lines');

function InList(const AId: string; const AList: array of string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(AList) do
    if SameText(AList[I], AId) then
      Exit(True);
  Result := False;
end;

function AgentActionClass(const AId: string): TAgentActionClass;
var
  Id: string;
begin
  Id := Trim(AId);
  if InList(Id, VIEW_IDS) then
    Result := aacView
  else if InList(Id, REVIEW_IDS) then
    Result := aacReview
  else if InList(Id, BLOCKED_IDS) then
    Result := aacBlocked
  else
    Result := aacUnsupported;
end;

function AgentActionNeedsOpenFile(const AId: string): Boolean;
begin
  Result := InList(Trim(AId), FILE_BOUND_IDS);
end;

function AgentActionIsExtra(const AId: string): Boolean;
begin
  Result := InList(Trim(AId), EXTRA_IDS);
end;

function AgentActionMutatesFile(const AId: string): Boolean;
begin
  Result := InList(Trim(AId), MUTATE_IDS);
end;

function AgentActionBlockedHint(const AId: string): string;
var
  Id: string;
begin
  Id := LowerCase(Trim(AId));
  if (Id = 'edit_line') or (Id = 'insert_line') or (Id = 'duplicate_line') or (Id = 'delete_line') or
     (Id = 'insert_multiple_lines') or (Id = 'paste_lines') or (Id = 'clear_file') then
    Result := 'use propose_edit, insert_lines or delete_lines instead'
  else if (Id = 'count_matching_lines') or (Id = 'count_line_prefixes') then
    Result := 'use the count tool instead'
  else if (Id = 'undo') or (Id = 'redo') then
    Result := 'the user runs undo/redo from the main window'
  else
    Result := 'not available to the agent; tell the user plainly it cannot be done from here';
end;

end.
