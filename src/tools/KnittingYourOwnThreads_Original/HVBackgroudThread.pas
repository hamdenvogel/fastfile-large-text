unit HVBackgroudThread;
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
  Classes,
  HVSyncObjs;

type
  TBackgroundTask = class;

  TTaskDoneEvent = procedure(Task: TBackgroundTask) of object;

  TBackgroundTask = class(TObject)
  private
    FTaskDoneEvent : TTaskDoneEvent;
    FCookie        : TObject;
  protected
    procedure Perform; virtual; abstract;
    procedure Done;
  public
    // A magic value to pass back to the event - can be useful sometimes
    property Cookie: TObject read FCookie write FCookie;
    // The event to call when the task is done
    property OnTaskDone: TTaskDoneEvent read FTaskDoneEvent write FTaskDoneEvent;
  end;
  TBackgroundTaskClass = class of TBackgroundTask;

  TBackgroundTasksThread = class(TThread)
  private
    FInBox : TWaitableThreadList;
    FOutBox: TWaitableThreadList;
  protected
    // Runs in main context, via Syncronize
    procedure AppHandleException;
    // Runs in thread context
    procedure HandleBackgroundTask(aBackgroundTask: TBackgroundTask);
    procedure Execute; override;
    // Runs in main context
    procedure ItemInOutBoxReady(Sender: TObject);
  public
    // Runs in main context
    constructor Create;
    destructor Destroy; override;
    procedure AddBackgroundTask(aBackgroundTask: TBackgroundTask);
    // Used to communicate between the main and the thread contexts
    property OutBox: TWaitableThreadList read FOutBox;
    property InBox : TWaitableThreadList read FInBox;
  end;

implementation

uses
  Windows,
  Forms,
  HVUtils,
  HVMultiThreadMain;

{ --------------------------- TBackgroundTask --------------------------- }

procedure TBackgroundTask.Done;
begin
  if Assigned(FTaskDoneEvent) then
    FTaskDoneEvent(Self);
end;

{ --------------------------- TBackgroundTasksThread --------------------------- }

constructor TBackgroundTasksThread.Create;
begin
  // Create the thread in the suspended state
  inherited Create(true);

  // Default to low priority!
  Priority           := tpIdle;

  // Application is reponsible for freeing us explicitly
  FreeOnTerminate    := false;

  // Create the In and Out boxes that will function as the communication mechanism
  FInBox             := TWaitableThreadList.Create;
  FOutBox            := TWaitableThreadList.Create;

  // Set up event that will be called in main thread context when items are ready in the outbox
  MultiThreadedMainLoop.TriggerOnObject(FOutBox, Self.ItemInOutBoxReady);

  // Now start running the thread
  Suspended          := false;
end;

destructor TBackgroundTasksThread.Destroy;
begin
  inherited Destroy;
  // Note: The thread must finish executing before freeing these objects,
  // so put them _after_ the inherited Destroy;
  FreeObject(FInBox);
  FreeObject(FOutBox);
end;

procedure TBackgroundTasksThread.HandleBackgroundTask(aBackgroundTask: TBackgroundTask);
begin
// Assert(Assigned(aBackgroundTask));
  // Perform the BackgroundTask in this low-priority thread
  if Assigned(aBackgroundTask) then
    aBackgroundTask.Perform;
  // Now signal to other threads (usually the main thread) that a task result is ready by adding it the the outbox list
  FOutBox.Add(aBackgroundTask);
end;

procedure TBackgroundTasksThread.AppHandleException;
begin
  Application.HandleException(Self);
end;

procedure TBackgroundTasksThread.Execute;
const
  TimeOut = 100; // Wait 0.1 sec before checking if thread is terminated
begin
  while not Terminated do
  begin
    try
      if (FInBox.WaitFor(TimeOut) = wrSignaled) and not Terminated then
        HandleBackgroundTask(TBackgroundTask(FInBox.Last));  // This removes the entry from the InBox list
    except
      Synchronize(AppHandleException); // Need to copy exception object??
    end;
  end;
end;

// These methods runs outside the context of this thread (called from the main thread):

procedure TBackgroundTasksThread.AddBackgroundTask(aBackgroundTask: TBackgroundTask);
begin
  InBox.Add(aBackgroundTask);
end;

procedure TBackgroundTasksThread.ItemInOutBoxReady(Sender: TObject);
var
  BackgroundTask: TBackgroundTask;
begin
  BackgroundTask := TBackgroundTask(FOutBox.Last);
  BackgroundTask.Done;
end;

end.
