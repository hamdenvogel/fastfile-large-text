unit uAgentBridge;

{
  Lets the Assistant panel run a request on the AI agent engine (the "AI agent" tab) without
  either unit using the other. The main form installs the commands; the agent tab reports
  progress; the Assistant listens. Main thread only.
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

var
  AgentBridgeRun: TAgentBridgeRunFunc;
  AgentBridgeAcceptAll: TAgentBridgeProc;
  AgentBridgeRejectAll: TAgentBridgeProc;
  AgentBridgeReview: TAgentBridgeProc;
  AgentBridgeStop: TAgentBridgeProc;

procedure AgentBridgeSetListener(AListener: TAgentBridgeListener);
procedure AgentBridgeNotify(AEvent: TAgentBridgeEvent; const AText: string; const AExtra: string = '';
  ACount: Integer = 0);
function AgentBridgeAvailable: Boolean;

implementation

var
  GListener: TAgentBridgeListener;

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

end.
