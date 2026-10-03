unit HVSyncObjs;
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
  SysUtils,
  Classes
  ;

type
  TSynchroObject = class(TObject)
  public
    constructor Create; virtual;
    procedure Acquire; virtual; abstract;
    procedure Release; virtual; abstract;
  end;
  TSynchroObjectClass = class of TSynchroObject;

  TCriticalSection = class(TSynchroObject)
  protected
    FSection: TRTLCriticalSection;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Acquire; override;
    procedure Release; override;
    procedure Enter;
    procedure Leave;
  end;

  TWaitResult = (wrSignaled, wrTimeout, wrAbandoned, wrError, wrMessage);
  TWaitResults = set of TWaitResult;
  THandleObject = class(TSynchroObject)
  protected
    FHandle: THandle;
    FLastError: DWORD;
  public
    destructor Destroy; override;
    procedure Acquire; override;
    function WaitFor(Timeout: DWORD): TWaitResult;
    property LastError: DWORD read FLastError;
    property Handle: THandle read FHandle;
  end;

  TWin32OpenNamedObjFunc = function (dwDesiredAccess: DWORD; bInheritHandle: BOOL; lpName: PChar): THandle; stdcall;
  TNamedObject = class(THandleObject)
  protected
    FOpenFunc : TWin32OpenNamedObjFunc;
    procedure Initialize; virtual;
  public
    constructor Create; override;
    constructor CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string); virtual;
    constructor CreateSimple;
    constructor CreateNamed(const Name: string);
    constructor Open(DesiredAccess: DWORD; InheritHandle: boolean; const Name: string);
    constructor OpenSimple(const Name: string);
  end;
  TNamedObjectClass = class of TNamedObject;

  TMutex = class(TNamedObject)
  public
    constructor CreateInit(SecurityAttributes: PSecurityAttributes; InitialOwner: boolean; const Name: string);
    constructor CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string); override;
    procedure Release; override;
  end;

  TEvent = class(TNamedObject)
  public
    constructor CreateInit(SecurityAttributes: PSecurityAttributes; ManualReset, InitialState: Boolean; const Name: string);
    constructor CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string); override;
    constructor CreateAutoReset;
    procedure SetEvent;
    procedure ResetEvent;
    procedure Acquire; override;
    procedure Release; override;
  end;

  TSemaphore = class(TNamedObject)
  protected
    procedure ReleaseSemaphore(ReleaseCount: longint; PreviousCount: PLongint);
  public
    constructor CreateInit(SecurityAttributes: PSecurityAttributes; InitialCount, MaximumCount: Longint; const Name: string);
    constructor CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string); override;
    procedure Release; override;
    procedure ReleaseBy(Value: integer);
    function  GetReleaseBy(Value: integer): longint;
  end;

  TWaitableThreadList = class(TSemaphore)
  private
    FList: TThreadList;
  protected
    procedure Initialize; override;
    procedure FreeItems;
  public
    destructor Destroy; override;
    procedure Add(Item: TObject);
    function Last: TObject;
    function Count: integer;
    property List: TThreadList read FList;
  end;

function Win32Handle(Handle: THandle): THandle;

implementation

function Win32Handle(Handle: THandle): THandle;
begin
  if Handle = 0 then SysUtils.RaiseLastWin32Error;
  Result := Handle;
end;

{ TSynchroObject }

constructor TSynchroObject.Create;
begin
  inherited Create;
end;

{ TCriticalSection }

constructor TCriticalSection.Create;
begin
  inherited Create;
  InitializeCriticalSection(FSection);
end;

destructor TCriticalSection.Destroy;
begin
  DeleteCriticalSection(FSection);
  inherited Destroy;
end;

procedure TCriticalSection.Acquire;
begin
  Enter;
end;

procedure TCriticalSection.Release;
begin
  Leave;
end;

procedure TCriticalSection.Enter;
begin
  EnterCriticalSection(FSection);
end;

procedure TCriticalSection.Leave;
begin
  LeaveCriticalSection(FSection);
end;

{ THandleObject }

destructor THandleObject.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

function THandleObject.WaitFor(Timeout: DWORD): TWaitResult;
begin
  case WaitForSingleObject(Handle, Timeout) of
    WAIT_ABANDONED: Result := wrAbandoned;
    WAIT_OBJECT_0 : Result := wrSignaled;
    WAIT_TIMEOUT  : Result := wrTimeout;
    WAIT_FAILED   :
      begin
        Result := wrError;
        FLastError := GetLastError;
      end;
  else
    Result := wrError;
  end;
end;

procedure THandleObject.Acquire;
// We define acquiring a waitable object the same as waiting for it to signal
// Raise an exception if something went wrong
begin
  if WaitFor(INFINITE) <> wrSignaled then
    RaiseLastWin32Error;
end;

{ TNamedObject }

constructor TNamedObject.Create;
begin
  inherited Create;
  CreateSimple;
end;

constructor TNamedObject.CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string);
begin
  Initialize;
end;

constructor TNamedObject.CreateSimple;
begin
  CreateDefault(nil, '');
end;

constructor TNamedObject.CreateNamed(const Name: string);
begin
  CreateDefault(nil, Name);
end;

constructor TNamedObject.Open(DesiredAccess: DWORD; InheritHandle: boolean;  const Name: string);
begin
//  inherited Create;
  Assert(Assigned(FOpenFunc));
  FHandle := Win32Handle(FOpenFunc(DesiredAccess, InheritHandle, PChar(Name)));
  Initialize;
end;

constructor TNamedObject.OpenSimple(const Name: string);
begin
  Open(MUTEX_ALL_ACCESS, false, Name);
end;

procedure TNamedObject.Initialize;
begin
  // Nothing to do here
end;

{ TMutex }

constructor TMutex.CreateInit(SecurityAttributes: PSecurityAttributes; InitialOwner: boolean; const Name: string);
begin
  FHandle := Win32Handle(Windows.CreateMutex(SecurityAttributes, InitialOwner, Pointer(Name)));
  Initialize;
end;

constructor TMutex.CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string);
begin
  CreateInit(SecurityAttributes, false, Name);
end;

procedure TMutex.Release;
begin
  Windows.ReleaseMutex(Handle);
end;

{ TEvent }

constructor TEvent.CreateInit(SecurityAttributes: PSecurityAttributes; ManualReset,
  InitialState: Boolean; const Name: string);
begin
  FOpenFunc := Windows.OpenEvent;
  FHandle := Win32Handle(CreateEvent(SecurityAttributes, ManualReset, InitialState, Pointer(Name)));
  Initialize;
end;

constructor TEvent.CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string);
begin
  CreateInit(SecurityAttributes, True, False, Name);
end;

constructor TEvent.CreateAutoReset;
begin
  CreateInit(nil, False, False, '');
end;

procedure TEvent.SetEvent;
begin
  Windows.SetEvent(Handle);
end;

procedure TEvent.ResetEvent;
begin
  Windows.ResetEvent(Handle);
end;

procedure TEvent.Acquire;
begin
  SetEvent;
end;

procedure TEvent.Release;
begin
  ResetEvent;
end;

{ TSemaphore }

constructor TSemaphore.CreateInit(SecurityAttributes: PSecurityAttributes; InitialCount, MaximumCount: Longint; const Name: string);
begin
  FHandle := Win32Handle(Windows.CreateSemaphore(SecurityAttributes, InitialCount, MaximumCount, Pointer(Name)));
  Initialize;
end;

constructor TSemaphore.CreateDefault(SecurityAttributes: PSecurityAttributes; const Name: string);
begin
  CreateInit(SecurityAttributes, 0, High(Longint), Name);
end;

procedure TSemaphore.ReleaseSemaphore(ReleaseCount: longint; PreviousCount: PLongint);
begin
  Windows.ReleaseSemaphore(Handle, ReleaseCount, PreviousCount);
end;

procedure TSemaphore.Release;
begin
  ReleaseSemaphore(1, nil);
end;

procedure TSemaphore.ReleaseBy(Value: integer);
begin
  ReleaseSemaphore(Value, nil);
end;

function TSemaphore.GetReleaseBy(Value: integer): longint;
begin
  ReleaseSemaphore(Value, @Result);
end;

{ TWaitableThreadList }

procedure TWaitableThreadList.Initialize;
// To allow the user to select any of the existing constructors,
// we do our specific initialization here
begin
  inherited Initialize;
  FList := TThreadList.Create;
end;

destructor TWaitableThreadList.Destroy;
begin
  FreeItems;
  FList.Free;
  FList := nil;
  inherited Destroy;
end;

procedure TWaitableThreadList.FreeItems;
var
  i : integer;
begin
  with FList.LockList do
    try
      for i := 0 to Count-1 do
        TObject(List^[i]).Free;
      Clear;
    finally
      FList.UnlockList;
    end;
end;

procedure TWaitableThreadList.Add(Item: TObject);
// Add item in the beginning of the list
begin
  with FList.LockList do
    try
      Insert(0, Item);
      Release;  // Signal that there is one more item in the list
    finally
      FList.UnlockList;
    end;
end;

function TWaitableThreadList.Last: TObject;
// Remove the last item in the list
// This should only be called after the list has been signalled, i.e. WaitFor has returned
begin
  with FList.LockList do
    try
      Assert(Count > 0);
      if Count > 0 then
      begin
        Result := Items[Count-1];
        Delete(Count-1);
      end
      else
        Result := nil;
    finally
      FList.UnlockList;
    end;
end;

function TWaitableThreadList.Count: integer;
begin
  with FList.LockList do
    try
      Result := Count;
    finally
      FList.UnlockList;
    end;
end;

end.
