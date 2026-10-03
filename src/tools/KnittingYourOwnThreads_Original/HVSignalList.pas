unit HVSignalList;
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
  HVSyncObjs
  ;

type
  // We can be waiting for:
  TCustomSignal = class(TObject)
  private
    FOnTrigger: TNotifyEvent;
  protected
    function GetHandle: THandle; virtual; abstract;
  public
    constructor Create(anOnTrigger: TNotifyEvent);
    procedure Trigger; virtual;
    property Handle: THandle read GetHandle;
  end;

  // - a TThread ending
  TThreadSignal = class(TCustomSignal)
  private
    FThread: TThread;
  protected
    function GetHandle: THandle; override;
  public
    constructor Create(aThread: TThread; anOnTrigger: TNotifyEvent);
    property Thread: TThread read FThread;
  end;

  // - a raw Handle returned by the Windows kernel
  THandleSignal = class(TCustomSignal)
  private
    FHandle: THandle;
  protected
    function GetHandle: THandle; override;
  public
    constructor Create(aHandle: THandle; anOnTrigger: TNotifyEvent);
  end;

  // - a syncrynization object derived from THandleObject
  TObjectSignal = class(TCustomSignal)
  private
    FHandleObject: THandleObject;
  protected
    function GetHandle: THandle; override;
  public
    constructor Create(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
    property HandleObject: THandleObject read FHandleObject;
  end;

  TSignalList = class(TObject)
  private
    FObjs           : TWOHandleArray;
    FList           : TList;
    FMsgWakeupMask  : longint;
    FIgnoreMessages : boolean;
    FWaitForAll     : boolean;
    procedure TriggeredIndex(Index: integer);
  public
    constructor Create;
    destructor Destroy; override;

    // Adding new triggers for handles, handleobjects and threads
    // Currently no support for removing triggers...
    procedure AddSignal(aSignal: TCustomSignal);

    function WaitOne(WaitTime: DWORD; var Index: integer): TWaitResult;
    function WaitOneAndTrigger(WaitTime: DWORD): TWaitResult;
    function WaitUntil(WaitTime: DWORD; WaitResultStop: TWaitResults): TWaitResult;
    property IgnoreMessages: boolean read FIgnoreMessages write FIgnoreMessages;
    property WaitForAll: boolean read FWaitForAll write FWaitForAll;
    property MsgWakeupMask: longint read FMsgWakeupMask write FMsgWakeupMask;
  end;

{ Utility routines }

function WaitForSingleHandleObject(Timeout: DWORD; WaitObject: THandleObject): TWaitResult;
function WaitForAnyHandleObject (Timeout: DWORD; var SignaledObject: THandleObject; WaitObjects: array of THandleObject): TWaitResult;
function WaitForAllHandleObjects(Timeout: DWORD; var SignaledObject: THandleObject; WaitObjects: array of THandleObject): TWaitResult;

implementation

uses
  SysUtils,
  HVUtils
  ;

{ TCustomSignal }

constructor TCustomSignal.Create(anOnTrigger: TNotifyEvent);
begin
  inherited Create;
  FOnTrigger := anOnTrigger;
end;

procedure TCustomSignal.Trigger;
begin
  if Assigned(FOnTrigger) then
    FOnTrigger(Self);
end;

{ TThreadSignal }

constructor TThreadSignal.Create(aThread: TThread; anOnTrigger: TNotifyEvent);
begin
  inherited Create(anOnTrigger);
  FThread := aThread;
end;

function TThreadSignal.GetHandle: THandle;
begin
  Result := Thread.Handle;
end;

{ THandleSignal }

constructor THandleSignal.Create(aHandle: THandle; anOnTrigger: TNotifyEvent);
begin
  inherited Create(anOnTrigger);
  FHandle := aHandle;
end;

function THandleSignal.GetHandle: THandle;
begin
  Result := FHandle;
end;

{ TObjectSignal }

constructor TObjectSignal.Create(aHandleObject: THandleObject; anOnTrigger: TNotifyEvent);
begin
  inherited Create(anOnTrigger);
  FHandleObject := aHandleObject;
end;

function TObjectSignal.GetHandle: THandle;
begin
  Result := HandleObject.Handle;
end;

{ TSignalList }

constructor TSignalList.Create;
begin
  inherited Create;
  FList := TList.Create;
  // See MsgWaitForMultipleObjects in help for list of possible values
  FMsgWakeupMask := QS_AllInput;
end;

destructor TSignalList.Destroy;
begin
  FreeOwningTList(FList);
  inherited Destroy;
end;

procedure TSignalList.AddSignal(aSignal: TCustomSignal);
begin
  // Check that we are not passing any limits (currently 64!)
  if FList.Count >= MAXIMUM_WAIT_OBJECTS then
    raise Exception.Create('Too many wait-objects!');

  // Update the low-level array with this new handle
  FObjs[FList.Count] := aSignal.Handle;

  // Add the thread event to the list
  FList.Add(aSignal);
end;

procedure TSignalList.TriggeredIndex(Index: integer);
begin
  // Use assertions to guarantee correct code while debugging and fast release code
  Assert((Index >= 0) and (Index < FList.Count));
  Assert(TObject(FList[Index]) is TCustomSignal);
  Assert(FObjs[Index] = TCustomSignal(FList[Index]).Handle);

  // Get the Signal associated with this index and trigger the event
  TCustomSignal(FList.List^[Index]).Trigger;
end;

function TSignalList.WaitOne(WaitTime: DWORD; var Index: integer): TWaitResult;
// We use the blocking function MsgWaitForMultipleObjects to wait for any
// message in the message queue or any signaled object from any of the
// other running threads in this process. See WINAPI32.HLP for details.
var
  WaitResult: DWORD;
begin
  // This call will block and use 0% CPU time until:
  // - A message arrives in the message queue, or
  // - Any of the object handles in the Objs array become signaled
  if IgnoreMessages
  then WaitResult :=    WaitForMultipleObjects(FList.Count, @FObjs, WaitForAll, WaitTime)
  else WaitResult := MsgWaitForMultipleObjects(FList.Count,  FObjs, WaitForAll, WaitTime, MsgWakeupMask);

  // Index is only valid when Result = wrSignaled
  Index := WaitResult - WAIT_OBJECT_0;

  // Convert from WAIT_ returncode to TWaitResult
  case WaitResult of
    WAIT_ABANDONED: Result := wrAbandoned;
    WAIT_TIMEOUT  : Result := wrTimeout;
    WAIT_FAILED   : Result := wrError;
    else
      if WaitResult = DWORD(WAIT_OBJECT_0 + FList.Count)
      then Result := wrMessage
      else Result := wrSignaled  // WAIT_OBJECT_0 .. WAIT_OBJECT_0+(FList.Count-1)
  end;
end;

function TSignalList.WaitOneAndTrigger(WaitTime: DWORD): TWaitResult;
var
  Index: integer;
begin
  Result := WaitOne(WaitTime, Index);
  if Result = wrSignaled then
    TriggeredIndex(Index);
end;

function TSignalList.WaitUntil(WaitTime: DWORD; WaitResultStop: TWaitResults): TWaitResult;
begin
  repeat
    Result := WaitOneAndTrigger(WaitTime);
  until (Result in WaitResultStop);
end;

{ Utility routines }

function WaitForHandleObjects(Timeout: DWORD; var SignaledObject: THandleObject; WaitObjects: array of THandleObject; WaitForAll: boolean): TWaitResult;
var
  SignalList : TSignalList;
  Index      : integer;
  i          : integer;
begin
  SignalList := TSignalList.Create;
  try
    for i := Low(WaitObjects) to High(WaitObjects) do
      SignalList.AddSignal(TObjectSignal.Create(WaitObjects[i], nil));

    SignalList.WaitForAll := WaitForAll;
    SignalList.IgnoreMessages := true;

    Result := SignalList.WaitOne(Timeout, Index);

    if Result = wrSignaled
    then SignaledObject := WaitObjects[Index]
    else SignaledObject := nil;
  finally
    SignalList.Free;
  end;
end;

function WaitForSingleHandleObject(Timeout: DWORD; WaitObject: THandleObject): TWaitResult;
var
  SignaledObject: THandleObject;
begin
  Result := WaitForHandleObjects(Timeout, SignaledObject, [WaitObject], false);
end;

function WaitForAnyHandleObject(Timeout: DWORD; var SignaledObject: THandleObject; WaitObjects: array of THandleObject): TWaitResult;
begin
  Result := WaitForHandleObjects(Timeout, SignaledObject, WaitObjects, false);
end;

function WaitForAllHandleObjects(Timeout: DWORD; var SignaledObject: THandleObject; WaitObjects: array of THandleObject): TWaitResult;
begin
  Result := WaitForHandleObjects(Timeout, SignaledObject, WaitObjects, true);
end;

end.
