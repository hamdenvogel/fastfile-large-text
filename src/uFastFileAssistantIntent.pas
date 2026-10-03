unit uFastFileAssistantIntent;

{
  Local intent classifier for the FastFile assistant chat.
  Priority slots (highest first): native editor tools, compose/fix document,
  ConsumerAI (SQL), ConsumerRAG (file meaning). Used before greedy open/RAG.
}

interface

type
  TAssistantIntentKind = (
    aikUnknown,
    aikNativeTool,
    aikComposeFix,
    aikCompose,
    aikConsumerSQL,
    aikConsumerRAG
  );

function ClassifyAssistantIntent(const AQuestion: string;
  AHasLastCompose: Boolean;
  out AKind: TAssistantIntentKind; out AActionHint: string): Boolean;
function IntentKindToActionHint(AKind: TAssistantIntentKind): string;

implementation

uses
  SysUtils, uFastFileAssistantCatalog, uFastFileAssistantMap;

function IntentKindToActionHint(AKind: TAssistantIntentKind): string;
begin
  case AKind of
    aikNativeTool: Result := 'native_tool';
    aikComposeFix: Result := 'compose_document';
    aikCompose: Result := 'compose_document';
    aikConsumerSQL: Result := 'consumer_ai';
    aikConsumerRAG: Result := 'consumer_rag';
  else
    Result := '';
  end;
end;

function ClassifyAssistantIntent(const AQuestion: string;
  AHasLastCompose: Boolean;
  out AKind: TAssistantIntentKind; out AActionHint: string): Boolean;
var
  Dummy, L: string;
begin
  Result := False;
  AKind := aikUnknown;
  AActionHint := '';
  if Trim(AQuestion) = '' then Exit;
  L := FoldDiacriticsForMatch(LowerCase(Trim(AQuestion)));

  { 0) AI-first: file math / data ops (even with "e tb me gere um PDF") → ConsumerAI.
    Never invent numbers via compose_document from a file sample.
    Substring/partial line counts are chosen by the LLM as count_matching_lines
    (prompt KB) — host does not NL-route them here. }
  if LooksLikeFileMathOrDataOp(AQuestion) or LooksLikeTabularSqlQuestion(L) or
     UserWantsConsumerAIContentQuestion(AQuestion) then
  begin
    AKind := aikConsumerSQL;
    AActionHint := 'consumer_ai';
    Result := True;
    Exit;
  end;

  { 1) Compose standalone source / Word-PDF doc before Script Engine. }
  if UserWantsComposeSourceCode(AQuestion) or
     UserWantsFileSummaryToDocument(AQuestion) or
     UserWantsComposeDocument(AQuestion) then
  begin
    AKind := aikCompose;
    AActionHint := 'compose_document';
    Result := True;
    Exit;
  end;

  { 2) Native editor tools (export, filter, split, Script Engine…). }
  if UserHasNativeFastFileToolIntent(AQuestion) or
     UserWantsShowScriptEngine(AQuestion) or
     UserWantsShowTailMacro(AQuestion) or
     UserWantsCatalogExportLineRange(AQuestion, Dummy) then
  begin
    AKind := aikNativeTool;
    AActionHint := 'native_tool';
    Result := True;
    Exit;
  end;

  { 3) Fix last generated document. }
  if UserWantsFixComposedDocument(AQuestion) or
     (AHasLastCompose and UserWantsShortComposeFix(AQuestion)) then
  begin
    AKind := aikComposeFix;
    AActionHint := 'compose_document';
    Result := True;
    Exit;
  end;

  { 4) Explicit SQL chat panel open. }
  if UserWantsShowConsumerAI(AQuestion) then
  begin
    AKind := aikConsumerSQL;
    AActionHint := 'consumer_ai';
    Result := True;
    Exit;
  end;

  { 5) File meaning / content (chat, not a saved document). }
  if UserWantsShowConsumerRAG(AQuestion) or
     UserWantsConsumerRAGContentQuestion(AQuestion) then
  begin
    AKind := aikConsumerRAG;
    AActionHint := 'consumer_rag';
    Result := True;
    Exit;
  end;
end;

end.
