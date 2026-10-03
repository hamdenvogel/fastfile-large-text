unit HVSounds;
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
  HVBackgroudThread
  ;

const
  MaxSounds = 12;
type
  TPlaySoundTask = class(TBackgroundTask)
  private
    FSoundIndex: integer;
  protected
    procedure Perform; override;
  public
    // Runs in main context
    constructor CreateInit(aSoundIndex: integer; aOnSoundDone: TTaskDoneEvent);
    property SoundIndex: integer read FSoundIndex;
  end;

function PlaySoundThread: TBackgroundTasksThread;

//procedure PlaySoundIndex(aSoundIndex: integer; aOnSoundDone: TTaskDoneEvent);
procedure PlaySoundIndex(aSoundIndex: integer; aOnSoundDone: TTaskDoneEvent; Multithreaded: boolean);

implementation

uses
  Classes,
  Windows,
  MMSystem,
  SysUtils,
  HVUtils
  ;

{ Basic PC-speaker routines }

type
  TSoundRec = packed record
    OL: byte;      // Outer Loop iterations
    IL: byte;      // Inner Loop iterations
    B1: smallint;      // Base frequencies, -1 for no sound
    B2: smallint;
    B3: smallint;
    F1: shortint;  // Factor for each freqency (* with inner loop index)
    F2: shortint;
    F3: shortint;
    Dr: byte;      // Duration of each sound
  end;

const
  // Table-driven internal speaker sounds
  SoundsArr : array[1..MaxSounds] of TSoundRec =
  ((OL: 02; IL: 10; B1: 3000; B2: 3000; B3:   -1; F1: 30; F2:-30; F3: 00; Dr: 10),  //Sound 1
   (OL: 00; IL: 15; B1: 1000; B2: 5500; B3:   -1; F1: 00; F2: 00; F3: 00; Dr: 10),  //Sound 2
   (OL: 00; IL: 02; B1:  500; B2: 1000; B3: 1500; F1: 00; F2: 00; F3: 00; Dr: 40),  //Sound 3
   (OL: 00; IL: 02; B1:  300; B2:  500; B3:   -1; F1: 00; F2: 00; F3: 60; Dr: 60),  //Sound 4
   (OL: 00; IL: 50; B1: 0000; B2:   -1; B3:   -1; F1: 20; F2: 00; F3: 00; Dr:  2),  //Sound 5
   (OL: 00; IL: 50; B1: 1000; B2:   -1; B3:   -1; F1:-20; F2: 00; F3: 00; Dr:  2),  //Sound 6
   (OL: 00; IL: 50; B1: 1000; B2:   -1; B3:   -1; F1: 20; F2: 00; F3: 00; Dr:  2),  //Sound 7
   (OL: 00; IL: 50; B1: 2000; B2:   -1; B3:   -1; F1:-20; F2: 00; F3: 00; Dr:  2),  //Sound 8
   (OL: 00; IL: 00; B1:  700; B2:   -1; B3:   -1; F1: 00; F2: 00; F3: 00; Dr:255),  //Sound 9
   (OL: 00; IL: 00; B1:  300; B2:   -1; B3:   -1; F1: 00; F2: 00; F3: 00; Dr:255),  //Sound 10
   (OL: 02; IL: 10; B1:  500; B2:  500; B3:   -1; F1: 30; F2:-30; F3: 00; Dr: 10),  //Sound 11
   (OL: 01; IL: 10; B1:  500; B2: 3500; B3: 1200; F1: 40; F2:-60; F3:-10; Dr:  5)   //Sound 12
  );

procedure SoundFreq(Freq, Dur: integer);
begin
  Windows.Beep(Freq, Dur);
end;

procedure SoundOff;
begin
  Windows.Beep(0, 0);
end;

procedure PlaySoundRec(const SoundRec: TSoundRec);
var
  i: integer;
  j: integer;
begin
  with SoundRec do
  begin
    for i := 0 to OL do
      for j := 0 to IL do
      begin
        if B1 >= 0 then SoundFreq(B1 + (F1 * j), Dr);
        if B2 >= 0 then SoundFreq(B2 + (F2 * j), Dr);
        if B3 >= 0 then SoundFreq(B3 + (F3 * j), Dr);
      end;
    SoundOff;
  end;
end;

procedure SoundAlarm(SoundIndex: integer);
begin
  if (SoundIndex >= 1) and (SoundIndex <= MaxSounds) then
    PlaySoundRec(SoundsArr[SoundIndex])
  else
    Windows.MessageBeep($FFFFFFFF);
end;

{ TPlaySoundTask }

constructor TPlaySoundTask.CreateInit(aSoundIndex: integer; aOnSoundDone: TTaskDoneEvent);
begin
  inherited Create;
  OnTaskDone := aOnSoundDone;
  FSoundIndex := aSoundIndex;
end;

procedure TPlaySoundTask.Perform;
begin
  SoundAlarm(SoundIndex);
end;

{ Singleton interface }

var
  PlaySoundThreadInstance: TBackgroundTasksThread = nil;

function PlaySoundThread: TBackgroundTasksThread;
begin
  if not Assigned(PlaySoundThreadInstance) then
    PlaySoundThreadInstance:= TBackgroundTasksThread.Create;
  Result := PlaySoundThreadInstance;
end;

{ Simplified Sound API }

procedure PlaySoundIndex(aSoundIndex: integer; aOnSoundDone: TTaskDoneEvent; Multithreaded: boolean);
var
  Task: TPlaySoundTask;
begin
  Task := TPlaySoundTask.CreateInit(aSoundIndex, aOnSoundDone);
  if Multithreaded then
    PlaySoundThread.AddBackgroundTask(Task)
  else
  begin
    Task.Perform;
    Task.Done;
    Task.Free;
  end;
end;

initialization
finalization
  FreeObject(PlaySoundThreadInstance);
end.
