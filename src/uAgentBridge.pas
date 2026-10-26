unit uAgentBridge;

{
  Lets the Assistant panel run a request on the AI agent engine (the "AI agent" tab), and the
  agent hand a request back to the Assistant, without either unit using the other. The main
  form installs the agent commands; the agent tab reports progress; the Assistant listens.
  Main thread only.
}

interface

type
  TAgentBridgeEvent = (
    abeStatus,        { AText = progress text }
    abeDone,          { AText = answer; ACount = proposed edits waiting for review; AErr in AExtra }
    abeEditsChanged,  { ACount = proposed edits still waiting }
    abeApplied        { AText = result of accepting edits }
  );

  TAgentBridgeListener = procedure(AEvent: TAgentBridgeEvent; const AText, AExtra: string;
    ACount: Integer) of object;
  { Starts the agent on APath with APrompt. False (with AWhy) when it cannot start now. }
  TAgentBridgeRunFunc = function(const APrompt, APath: string; out AWhy: string): Boolean of object;
  TAgentBridgeProc = procedure of object;

  { Reverse direction: the agent hands a request to the Assistant panel (documents, source validation,
    questions about FastFile). The Assistant installs the command and reports its reply once. }
  TAssistantBridgeRunFunc = function(const ARequest: string; out AWhy: string): Boolean of object;
  TAssistantBridgeReplyListener = procedure(const AText: string) of object;

var
  AgentBridgeRun: TAgentBridgeRunFunc;
  AgentBridgeAcceptAll: TAgentBridgeProc;
  AgentBridgeRejectAll: TAgentBridgeProc;
  AgentBridgeReview: TAgentBridgeProc;
  AgentBridgeStop: TAgentBridgeProc;
  AssistantBridgeRun: TAssistantBridgeRunFunc;

procedure AgentBridgeSetListener(AListener: TAgentBridgeListener);
procedure AgentBridgeNotify(AEvent: TAgentBridgeEvent; const AText: string; const AExtra: string = '';
  ACount: Integer = 0);
function AgentBridgeAvailable: Boolean;

procedure AssistantBridgeSetReplyListener(AListener: TAssistantBridgeReplyListener);
procedure AssistantBridgeNotifyReply(const AText: string);
function AssistantBridgeAvailable: Boolean;

implementation

var
  GListener: TAgentBridgeListener;
  GReplyListener: TAssistantBridgeReplyListener;

procedure AgentBridgeSetListener(AListener: TAgentBridgeListener);
begin
  GListener := AListener;
end;

procedure AgentBridgeNotify(AEvent: TAgentBridgeEvent; const AText, AExtra: string; ACount: Integer);
begin
  if Assigned(GListener) then
    GListener(AEvent, AText, AExtra, ACount);
end;

function AgentBridgeAvailable: Boolean;
begin
  Result := Assigned(AgentBridgeRun);
end;

procedure AssistantBridgeSetReplyListener(AListener: TAssistantBridgeReplyListener);
begin
  GReplyListener := AListener;
end;

procedure AssistantBridgeNotifyReply(const AText: string);
begin
  if Assigned(GReplyListener) then
    GReplyListener(AText);
end;

function AssistantBridgeAvailable: Boolean;
begin
  Result := Assigned(AssistantBridgeRun);
end;

end.
