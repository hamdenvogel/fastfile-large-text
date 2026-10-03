unit MultiThreadedMainLoop;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Forms,
  HVClass,
  HVSyncObjs,
  ExtCtrls
  ;

type
  TIdleTimerEvent = procedure (Sender: TObject; var Done: Boolean; AppIsIdle: boolean) of object;
  TMultiThreadedMainLoop = class(TObject)
  private
    FHasBeenIdle : boolean;
    FIdleTimer   : TTimer;
    FIdleHookList: TEventList;
    FOldAppIdle  : TIdleEvent;
    FIdleWaitTime: integer;
    FBusyWaitTime: integer;
    FThreadEventList: TThreadEventList;
    procedure SetIdleTimerInterval(Value: integer);
    function GetIdleTimerInterval: integer;
  protected
    procedure CallIdleHooks(Sender: TObject; var HooksDone: boolean; AppIsIdle: boolean);
    procedure OnIdleTimer(Sender: TObject);
    procedure AppIdle(Sender: TObject; var Done: boolean);
  public
    constructor Create;
    destructor Destroy; override;
    // Idle hook support
    procedure AddIdleHook(Notify: TIdleTimerEvent);
    procedure RemoveIdleHook(Notify: TIdleTimerEvent);

    procedure TriggerOnHandle(aHandle: THandle; anOnTrigger: TNotifyEvent);
    procedure TriggerOnObject(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
    procedure TriggerOnThread(aThread: TThread; anOnTrigger: TNotifyEvent);

    property IdleWaitTime: integer read FIdleWaitTime write FIdleWaitTime;
    property BusyWaitTime: integer read FBusyWaitTime write FBusyWaitTime;
    property ThreadEventList: TThreadEventList read FThreadEventList write FThreadEventList;
    property IdleTimerInterval: integer read GetIdleTimerInterval write SetIdleTimerInterval;
  end;

var
  MultiThreadedMainLoop: TMultiThreadedMainLoop = nil;

implementation

uses
  HVUtils;

{ TMultiThreadedMainLoop }

constructor TMultiThreadedMainLoop.Create;
begin
  inherited Create;
  // By default, just block until we have a message or one of the handles signals
  FIdleWaitTime := INFINITE;
  FBusyWaitTime := 0;

  // Create the list used for the thread events
  FThreadEventList := TThreadEventList.Create;

  // Save and setup OnIdle handler, lets hope newcomers do the same...
  FOldAppIdle := Application.OnIdle;
  Application.OnIdle := AppIdle;

  FIdleTimer := TTimer.Create(nil);
  FIdleTimer.Interval := 100;  // every 100 ms, about 10 times pr second
  FIdleTimer.OnTimer := OnIdleTimer;
  FIdleTimer.Enabled := true;
end;

destructor TMultiThreadedMainLoop.Destroy;
begin
  // Stop being nagged by the timer
  FreeObject(FIdleTimer);
  // Restore the old OnIdle handler
  Application.OnIdle := FOldAppIdle;
  FreeObject(FIdleHookList);
  FreeObject(FThreadEventList);
  inherited Destroy;
end;

function TMultiThreadedMainLoop.GetIdleTimerInterval: integer;
begin
  Result := FIdleTimer.Interval;
end;

procedure TMultiThreadedMainLoop.SetIdleTimerInterval(Value: integer);
begin
  FIdleTimer.Interval := Value;
end;

procedure TMultiThreadedMainLoop.TriggerOnHandle(aHandle: THandle; anOnTrigger: TNotifyEvent);
begin
  FThreadEventList.TriggerOnHandle(aHandle, anOnTrigger);
end;

procedure TMultiThreadedMainLoop.TriggerOnObject(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
begin
  FThreadEventList.TriggerOnObject(aHandleObject, anOnTrigger);
end;

procedure TMultiThreadedMainLoop.TriggerOnThread(aThread: TThread; anOnTrigger: TNotifyEvent);
begin
  FThreadEventList.TriggerOnThread(aThread, anOnTrigger);
end;

procedure TMultiThreadedMainLoop.AddIdleHook(Notify: TIdleTimerEvent);
begin
  TEventList.AddEventListMember(FIdleHookList, TEventProc(Notify));
end;

procedure TMultiThreadedMainLoop.RemoveIdleHook(Notify: TIdleTimerEvent);
begin
  TEventList.RemoveEventListMember(FIdleHookList, TEventProc(Notify));
end;

procedure TMultiThreadedMainLoop.CallIdleHooks(Sender: TObject; var HooksDone: boolean; AppIsIdle: boolean);
var
  i      : integer;
  Done   : boolean;
  Method : TMethod;
begin
  // Call the old handler and check if it is done
  HooksDone := true;
  if Assigned(FOldAppIdle) and AppIsIdle then
    FOldAppIdle(Sender, HooksDone);

  // Then call any idle subscribers and check if they are done
  if Assigned(FIdleHookList) then
  begin
    for i := 0 to FIdleHookList.Count-1 do
    begin
      Done := true;
      Method := FIdleHookList.Items[i];
      TIdleTimerEvent(Method)(Sender, Done, AppIsIdle); // Dividing up the code below like this is ok!
//  TIdleTimerEvent(FIdleHookList.Items[i])(Sender, Done);  // Compiler bug: Generates wrong code for this!! (compiles fine, though
      HooksDone := HooksDone and Done;
    end;
  end;
end;

procedure TMultiThreadedMainLoop.AppIdle(Sender: TObject; var Done: boolean);
// Whenever the application becomes idle, i.e. there are no messages in the
// message queue, this procedure is entered.
var
  IdleChildrenDone: boolean;
  WaitTime        : integer;
  WaitResult      : TWaitResult;
begin
  repeat
    // Tell the timer-loop that we have actully been idle
    FHasBeenIdle := true;

    // Now call all other idle hooks, indicating that the application is actually idle
    CallIdleHooks(Sender, IdleChildrenDone, true);

    // If there are one or more idle handler that is not done yet, don't pause very long before returning
    if IdleChildrenDone
    then WaitTime := IdleWaitTime
    else WaitTime := BusyWaitTime;

    // Wait for a message or a timeout - handles all signaled objects in the process
    WaitResult := FThreadEventList.WaitUntil(WaitTime, [wrMessage, wrTimeOut]);

    // Loop until we get a message
  until WaitResult = wrMessage;

  // Always return Done=false to signal that the message loop should go back here when it has read all messages
  Done := false;
end;

{procedure TMultiThreadedMainLoop.WaitUntil(Condition: TConditionEvent);
var
  WaitResult: TWaitResult;
begin
  repeat
    // Wait for a message or a timeout - handles all signaled objects in the process
    WaitResult := FThreadEventList.WaitUntil(IdleWaitTime, [wrSignaled, wrError]);
    // Loop until we are satisfied
  until (WaitResult = wrError) or (Condition = true);
end;}

procedure TMultiThreadedMainLoop.OnIdleTimer(Sender: TObject);
// This timer handler is called (roughly) 10 times pr second
// This is to allow signaled objects to be handled even when other message loops than TApplication is running (e.g. menu)
var
  IdleChildrenDone: boolean;
begin
  // Some time since we were idle?
  if not FHasBeenIdle then
  begin
    // Now call all idle hooks, indicating that the application is _not_ actually idle
    CallIdleHooks(Sender, IdleChildrenDone, false);
    // Empty the list of signaled objects
    while (ThreadEventList.WaitOneAndTrigger(0) = wrSignaled) do
      {Loop};
  end;
  // Reset the idle flag
  FHasBeenIdle := false;
end;

end.
