unit uAssistantPostAction;
{ System-wide AI-First post-action pipeline.
  After any notable FastFile activity, offer "What do you want to do next?"
  with contextual action chips + an AI draft question in the assistant. }

interface

{ AActivityId: find_hit, find_collect, filter, export, split, merge, read,
  index, compare, dedupe, script, replace, generic
  AFacts: optional key=value;key2=value2 snapshot for resume bridge
  AOfferUI: when False, only persists bridge memory (no banner/chips) }
procedure NotifyAssistantPostAction(const AActivityId, ASummary: string;
  const AFacts: string = ''; AOfferUI: Boolean = True);
procedure NotifyAssistantPostActionEx(const AActivityId, ASummary,
  AExtraActionIds, AFacts: string; AOfferUI: Boolean = True);
{ Re-renders the AI draft of the last offer in the current language (after a
  runtime language switch). False when no offer was made in this session. }
function AssistantRebuildLastOfferDraft(out ADraft: string): Boolean;
{ Last completed flow and its action ids. The summary is the sentence already
  produced for that flow. }
function AssistantLastOffer(out AActivityId, AActions, ASummary: string): Boolean;

implementation

uses
  SysUtils, Windows, uI18n, uFastFileAssistant, uAssistantPipelineStore;

var
  GLastOfferTick: DWORD = 0;
  GLastActivityId: string = '';
  GLastOfferSummary: string = '';

function ResolveOffer(const AActivityId: string; out AActions, AAiDraft: string): Boolean;
var
  Id: string;
begin
  Result := True;
  Id := LowerCase(Trim(AActivityId));
  AActions := 'ask_ai,open_find,open_filter';
  AAiDraft := TrText('Assistant.Offer.Draft.Generic');

  if (Id = 'find_hit') or (Id = 'find') then
  begin
    AActions := 'ask_ai,view_find_occurrences,find_previous,find_next,open_replace,clear_find';
    AAiDraft := TrText('Assistant.Offer.Draft.Find');
  end
  else if (Id = 'find_collect') or (Id = 'find_hits') then
  begin
    AActions := 'ask_ai,find_next,export_matching_lines,open_replace,clear_find,clear_filter';
    AAiDraft := TrText('Assistant.Offer.Draft.FindCollect');
  end
  else if Id = 'filter' then
  begin
    AActions := 'ask_ai,continue_filter,export_matching_lines,open_find,clear_filter';
    AAiDraft := TrText('Assistant.Offer.Draft.Filter');
  end
  else if Id = 'export' then
  begin
    AActions := 'ask_ai,open_find,open_filter,show_tab_read,consumer_ai';
    AAiDraft := TrText('Assistant.Offer.Draft.Export');
  end
  else if Id = 'split' then
  begin
    AActions := 'ask_ai,show_tab_merge_files,open_and_read_file,open_find,consumer_ai';
    AAiDraft := TrText('Assistant.Offer.Draft.Split');
  end
  else if Id = 'merge' then
  begin
    AActions := 'ask_ai,open_and_read_file,export_file,open_find,consumer_ai';
    AAiDraft := TrText('Assistant.Offer.Draft.Merge');
  end
  else if Id = 'read' then
  begin
    AActions := 'ask_ai,open_find,open_filter,consumer_ai,consumer_rag,export_file';
    AAiDraft := TrText('Assistant.Offer.Draft.Read');
  end
  else if Id = 'index' then
  begin
    AActions := 'ask_ai,open_find,open_filter,force_index_file,consumer_ai';
    AAiDraft := TrText('Assistant.Offer.Draft.Index');
  end
  else if Id = 'compare' then
  begin
    AActions := 'ask_ai,show_tab_compare,open_find,export_file';
    AAiDraft := TrText('Assistant.Offer.Draft.Compare');
  end
  else if Id = 'dedupe' then
  begin
    AActions := 'ask_ai,open_and_read_file,export_file,open_find';
    AAiDraft := TrText('Assistant.Offer.Draft.Dedupe');
  end
  else if Id = 'script' then
  begin
    AActions := 'ask_ai,show_script_engine,open_find,export_file';
    AAiDraft := TrText('Assistant.Offer.Draft.Script');
  end
  else if Id = 'csv_sort' then
  begin
    AActions := 'ask_ai,clear_csv_sort,toggle_csv_header,apply_filter,clear_filter';
    AAiDraft := TrText('Assistant.Offer.Draft.CsvSort');
  end
  else if Id = 'grep_groups' then
  begin
    AActions := 'ask_ai,apply_filter,export_matching_lines,open_find';
    AAiDraft := TrText('Assistant.Offer.Draft.GrepGroups');
  end
  else if Id = 'session' then
  begin
    AActions := 'ask_ai,save_session,load_session,apply_filter,goto_line';
    AAiDraft := TrText('Assistant.Offer.Draft.Session');
  end
  else if Id = 'replace' then
  begin
    AActions := 'ask_ai,find_next,open_replace,view_find_occurrences,clear_find';
    AAiDraft := TrText('Assistant.Offer.Draft.Replace');
  end
  else if Id = 'generic' then
  begin
    AActions := 'ask_ai,open_find,open_filter,consumer_ai,consumer_rag';
    AAiDraft := TrText('Assistant.Offer.Draft.Generic');
  end
  else
    Result := True; { unknown id → generic chips already set }
end;

{ Richer next steps for the on-file guide. The assistant banner keeps ResolveOffer. }
function ResolveWorkflowOffer(const AActivityId: string; out AActions: string): Boolean;
var
  Draft: string;
  Id: string;
begin
  Result := ResolveOffer(AActivityId, AActions, Draft);
  Id := LowerCase(Trim(AActivityId));
  if (Id = 'find_hit') or (Id = 'find') then
    AActions := 'ask_ai,view_find_occurrences,find_previous,find_next,open_replace,' +
      'export_matching_lines,open_filter,clear_find'
  else if (Id = 'find_collect') or (Id = 'find_hits') then
    AActions := 'ask_ai,export_matching_lines,copy_filtered,open_replace,find_next,' +
      'open_filter,clear_find,clear_filter'
  else if Id = 'filter' then
    AActions := 'ask_ai,continue_filter,export_matching_lines,copy_filtered,open_find,' +
      'open_replace,clear_filter,edit_line'
  else if Id = 'export' then
    AActions := 'ask_ai,show_tab_read,open_find,open_filter,show_tab_compare,edit_line,' +
      'consumer_ai,open_and_read_file'
  else if Id = 'split' then
    AActions := 'ask_ai,show_tab_merge_files,open_and_read_file,open_find,show_tab_compare,' +
      'export_file,consumer_ai,show_tab_read'
  else if Id = 'merge' then
    AActions := 'ask_ai,open_and_read_file,export_file,open_find,open_filter,' +
      'show_tab_compare,edit_line,consumer_ai'
  else if Id = 'read' then
    AActions := 'ask_ai,open_find,open_filter,edit_line,show_tab_compare,' +
      'show_tab_merge_files,show_tab_merge_lines,export_file,consumer_ai'
  else if Id = 'index' then
    AActions := 'ask_ai,open_find,open_filter,force_index_file,export_file,edit_line,consumer_ai'
  else if Id = 'compare' then
    AActions := 'ask_ai,show_tab_compare,edit_line,show_tab_merge_files,open_find,' +
      'export_file,open_filter,consumer_ai'
  else if Id = 'dedupe' then
    AActions := 'ask_ai,open_and_read_file,export_file,open_find,show_tab_compare,' +
      'edit_line,open_filter,consumer_ai'
  else if Id = 'script' then
    AActions := 'ask_ai,show_script_engine,open_find,export_file,show_tab_read,edit_line,consumer_ai'
  else if Id = 'csv_sort' then
    AActions := 'ask_ai,apply_filter,clear_filter,export_file,open_find,edit_line,undo'
  else if Id = 'grep_groups' then
    AActions := 'ask_ai,apply_filter,export_matching_lines,copy_filtered,open_find,' +
      'clear_filter,consumer_ai'
  else if Id = 'session' then
    AActions := 'ask_ai,save_session,load_session,goto_line,open_find,apply_filter,' +
      'export_file,edit_line'
  else if Id = 'replace' then
    AActions := 'ask_ai,undo,find_next,open_replace,view_find_occurrences,edit_line,' +
      'show_tab_compare,clear_find'
  else if (Id = 'generic') or (Id = '') then
    AActions := 'ask_ai,open_find,open_filter,edit_line,show_tab_compare,' +
      'show_tab_merge_files,export_file,consumer_ai';
end;

function ShouldOfferNow(const AActivityId: string): Boolean;
var
  NowTick: DWORD;
begin
  Result := True;
  NowTick := GetTickCount;
  if (GLastActivityId <> '') and SameText(GLastActivityId, AActivityId) and
     (NowTick - GLastOfferTick < 2500) then
    Result := False;
end;

procedure NotifyAssistantPostActionEx(const AActivityId, ASummary,
  AExtraActionIds, AFacts: string; AOfferUI: Boolean);
var
  Actions, Draft, Extra: string;
begin
  { Always persist Redis-like bridge — even when UI offer is off / throttled. }
  PipelineRememberActivity(AActivityId, ASummary, AFacts);
  if (not AOfferUI) or (not ShouldOfferNow(AActivityId)) then
  begin
    GLastActivityId := LowerCase(Trim(AActivityId));
    GLastOfferSummary := Trim(ASummary);
    Exit;
  end;
  if not ResolveOffer(AActivityId, Actions, Draft) then Exit;
  Extra := Trim(AExtraActionIds);
  if Extra <> '' then
  begin
    if (Actions <> '') and (Actions[Length(Actions)] <> ',') then
      Actions := Actions + ',';
    Actions := Actions + Extra;
  end;

  Draft := PipelineBuildResumeDraft(Draft);

  GLastOfferTick := GetTickCount;
  GLastActivityId := LowerCase(Trim(AActivityId));
  GLastOfferSummary := Trim(ASummary);
  NotifyAssistantOfferNext(ASummary, Actions, Draft);
end;

function AssistantLastOffer(out AActivityId, AActions, ASummary: string): Boolean;
begin
  AActivityId := GLastActivityId;
  if AActivityId = '' then
    AActivityId := 'read';
  Result := ResolveWorkflowOffer(AActivityId, AActions);
  if SameText(GLastActivityId, AActivityId) then
    ASummary := GLastOfferSummary
  else
    ASummary := '';
  if Trim(ASummary) = '' then
    ASummary := TrText('WorkflowWizard.Description');
end;

procedure NotifyAssistantPostAction(const AActivityId, ASummary: string;
  const AFacts: string; AOfferUI: Boolean);
begin
  NotifyAssistantPostActionEx(AActivityId, ASummary, '', AFacts, AOfferUI);
end;

function AssistantRebuildLastOfferDraft(out ADraft: string): Boolean;
var
  Actions: string;
begin
  ADraft := '';
  Result := (GLastActivityId <> '') and ResolveOffer(GLastActivityId, Actions, ADraft);
  if Result then
    ADraft := PipelineBuildResumeDraft(ADraft);
end;

end.
