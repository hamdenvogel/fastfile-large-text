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

implementation

uses
  SysUtils, Windows, uI18n, uFastFileAssistant, uAssistantPipelineStore;

var
  GLastOfferTick: DWORD = 0;
  GLastActivityId: string = '';

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
  if not AOfferUI then Exit;
  if not ShouldOfferNow(AActivityId) then Exit;
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
  NotifyAssistantOfferNext(ASummary, Actions, Draft);
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
