program ThreadsDemoP;

uses
  Forms,
  ThreadsDemo in 'ThreadsDemo.pas' {SoundDemoForm},
  HVSignalList in 'HVSignalList.pas',
  HVMultiThreadMain in 'HVMultiThreadMain.pas',
  HVSyncObjs in 'HVSyncObjs.pas',
  HVBackgroudThread in 'HVBackgroudThread.pas',
  HVUtils in 'HVUtils.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TSoundDemoForm, SoundDemoForm);
  Application.Run;
end.
