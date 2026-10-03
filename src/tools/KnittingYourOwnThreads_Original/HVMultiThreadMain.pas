unit HVMultiThreadMain;
//
// Written by Hallvard Vassbotn, hallvard@falcon.no
//
// Based on source code Copyright (c) 1998 by Reuters Group PLC
// Reproduction and/or distribution of source code or DCUs strictly prohibited.
//
// For publication in The Delphi Magazine only
//
interface

uses
  Windows,
  Classes,
  Forms,
  ExtCtrls,
  HVSyncObjs,
  HVSignalList
  ;

type
  TMultiThreadedMainLoop = class(TObject)
  private
    FHasBeenIdle : boolean;
    FIdleTimer   : TTimer;
    FOldAppIdle  : TIdleEvent;
    FSignalList: TSignalList;
    procedure SetIdleTimerInterval(Value: integer);
    function GetIdleTimerInterval: integer;
  protected
    procedure OnIdleTimer(Sender: TObject);
    procedure AppIdle(Sender: TObject; var Done: boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure TriggerOnHandle(aHandle: THandle; anOnTrigger: TNotifyEvent);
    procedure TriggerOnObject(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
    procedure TriggerOnThread(aThread: TThread; anOnTrigger: TNotifyEvent);

    property SignalList: TSignalList read FSignalList;
    property IdleTimerInterval: integer read GetIdleTimerInterval write SetIdleTimerInterval;
  end;

function MultiThreadedMainLoop: TMultiThreadedMainLoop;

implementation

uses
  HVUtils
  ;

{ TMultiThreadedMainLoop }

constructor TMultiThreadedMainLoop.Create;
begin
  inherited Create;
  // Create the list used for the thread signals
  FSignalList := TSignalList.Create;

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
//  FreeObject(FIdleHookList);
  FreeObject(FSignalList);
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
  FSignalList.AddSignal(THandleSignal.Create(aHandle, anOnTrigger));
end;

procedure TMultiThreadedMainLoop.TriggerOnObject(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
begin
  FSignalList.AddSignal(TObjectSignal.Create(aHandleObject, anOnTrigger));
end;

procedure TMultiThreadedMainLoop.TriggerOnThread(aThread: TThread; anOnTrigger: TNotifyEvent);
begin
  FSignalList.AddSignal(TThreadSignal.Create(aThread, anOnTrigger));
end;

procedure TMultiThreadedMainLoop.AppIdle(Sender: TObject; var Done: boolean);
// Whenever the application becomes idle, i.e. there are no messages in the
// message queue, this procedure is entered.
begin
  // The default case for the old idle event
  // handler should be that it is done processing
  Done := true;

  // Call any old idle event handler
  // - this could be extended with an idle hook chain
  if Assigned(FOldAppIdle) then
    FOldAppIdle(Sender, Done);

  // WaitUntil handles all signaled objects for the main thread
  if Done then
    // If the old idle event handler is done,
    // wait until there is a message for us (blocking)
    FSignalList.WaitUntil(INFINITE, [wrMessage])
  else
    // If the old idle event handler is not done yet,
    // just check for signaled objects or messages (non-blocking)
    FSignalList.WaitUntil(0       , [wrMessage, wrTimeOut]);

  // Tell the timer-loop that we have actully been idle
  FHasBeenIdle := true;

  // Now return to the message loop in TApplication and
  // let it have a look at the message for us
  // Note that we will normally return with Done = true.
  // This will call WaitMessage in TApplication.Idle, but it will not
  // block because we already know there is a message in the message queue
end;

procedure TMultiThreadedMainLoop.OnIdleTimer(Sender: TObject);
// This timer handler is called (roughly) 10 times pr second
// This is to allow signaled objects to be handled even when other
// message loops than TApplication is running (e.g. menu, dialog box etc.)
begin
  // Some time since we were idle?
  if not FHasBeenIdle then
  begin
    // Empty the list of signaled objects
    while (SignalList.WaitOneAndTrigger(0) = wrSignaled) do
      {Loop};
  end;
  // Reset the idle flag
  FHasBeenIdle := false;
end;

var
  MultiThreadedMainLoopInstance: TMultiThreadedMainLoop;

function MultiThreadedMainLoop: TMultiThreadedMainLoop;
begin
  if not Assigned(MultiThreadedMainLoopInstance) then
    MultiThreadedMainLoopInstance := TMultiThreadedMainLoop.Create;
 Result := MultiThreadedMainLoopInstance;
end;

initialization
finalization
  FreeObject(MultiThreadedMainLoopInstance);

end.
