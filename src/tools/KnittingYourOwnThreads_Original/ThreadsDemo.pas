unit ThreadsDemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,
  HVSyncObjs,
  HVBackgroudThread
  ;

type
  TSoundDemoForm = class(TForm)
    AddedTasksList: TListBox;
    DoneTasksList: TListBox;
    InBoxList: TListBox;
    OutBoxList: TListBox;
    AddButton: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ClearButton: TButton;
    MultithreadedCB: TCheckBox;
    procedure AddButtonClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure UpdateTStringsFromThreadList(Strings: TStrings; ThreadList: TWaitableThreadList);
    procedure UpdateAllLists;
    procedure SoundTaskDone(Task: TBackgroundTask);
  public
    { Public declarations }
  end;

var
  SoundDemoForm: TSoundDemoForm;

implementation

{$R *.DFM}

uses
  HVSounds
  ;

function IntToSound(SoundIndex: integer): string;
begin
  Result := 'Sound '+IntToStr(SoundIndex);
end;

procedure TSoundDemoForm.UpdateTStringsFromThreadList(Strings: TStrings; ThreadList: TWaitableThreadList);
var
  i : integer;
  SoundTask: TPlaySoundTask;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    with ThreadList.List.LockList do
      try
        for i := 0 to Count-1 do
        begin
          SoundTask := TPlaySoundTask(List^[i]);
          Strings.Add(IntToSound(SoundTask.SoundIndex));
        end;
      finally
        ThreadList.List.UnlockList;
      end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TSoundDemoForm.UpdateAllLists;
begin
  with PlaySoundThread do
  begin
    UpdateTStringsFromThreadList(InBoxList.Items, InBox);
    UpdateTStringsFromThreadList(OutBoxList.Items, OutBox);
  end;
end;

procedure TSoundDemoForm.SoundTaskDone(Task: TBackgroundTask);
begin
  with Task as TPlaySoundTask do
  begin
    DoneTasksList.Items.Add(IntToSound(SoundIndex));
    UpdateAllLists;
  end;
end;

procedure TSoundDemoForm.FormCreate(Sender: TObject);
begin
  Randomize;
end;

procedure TSoundDemoForm.AddButtonClick(Sender: TObject);
var
  SoundIndex : integer;
begin
  SoundIndex := Random(MaxSounds)+1;
  AddedTasksList.Items.Add(IntToSound(SoundIndex));
  UpdateAllLists;
  PlaySoundIndex(SoundIndex, Self.SoundTaskDone, MultithreadedCB.Checked);
end;

procedure TSoundDemoForm.ClearButtonClick(Sender: TObject);
begin
  AddedTasksList.Items.Clear;
  InBoxList.Items.Clear;
  OutBoxList.Items.Clear;
  DoneTasksList.Items.Clear;
end;

end.
