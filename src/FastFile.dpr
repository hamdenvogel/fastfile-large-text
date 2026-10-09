program FastFile;

uses
  FastMM4 in 'FastMM4-master\FastMM4.pas',
{$IFDEF WIN64}
  { FastCode uses x86 assembly; Win64 builds use the Delphi RTL directly. }
{$ELSE}
  Fastcode in 'FastCode.Libraries-0.6.4\FastCode.pas',
{$ENDIF}
  Winapi.Windows,
  Forms,
  sDialogs,
  SysUtils,
  uFastFileAIClient in 'uFastFileAIClient.pas',
  uVBScriptRegex in 'uVBScriptRegex.pas',
  uFastFileAIScreenHelp in 'uFastFileAIScreenHelp.pas',
  uFastFileAIPythonMacroHelp in 'uFastFileAIPythonMacroHelp.pas',
  UnUtils in 'UnUtils.pas',
  uDiskSpaceCheck in 'uDiskSpaceCheck.pas',
  UnDM in 'UnDM.pas' {DataModule1: TDataModule},
  UnitPopupScaling in 'UnitPopupScaling.pas' {FormPopupScaling},
  UnSplash in 'UnSplash.pas' {frmSplash},
  UnFormAboutFF in 'UnFormAboutFF.pas' {frmAboutFF},
  unHardwareInformation in 'unHardwareInformation.pas',
  unSplitView in 'unSplitView.pas' {frmSplitView},
  MruHelper in 'MruHelper.pas',
  UnConsts in 'UnConsts.pas',
  uFileOpenPolicy in 'uFileOpenPolicy.pas',
  uPosBMH in 'uPosBMH.pas',
  UnConsumerAI in 'UnConsumerAI.pas',
  UnConsumerDialog in 'UnConsumerDialog.pas',
  uTemporaryFileStream in 'uTemporaryFileStream.pas',
  uZeroScanBlockIndex in 'uZeroScanBlockIndex.pas',
  uLineIndexScan in 'uLineIndexScan.pas',
  uSmoothLoading in 'uSmoothLoading.pas' {frmSmoothLoadingForm},
  uDeltaEditor in 'uDeltaEditor.pas' {frmDeltaEditor},
  uFileSessionHistory in 'uFileSessionHistory.pas',
  uLineDiffCore in 'uLineDiffCore.pas',
  uHistPagedPreview in 'uHistPagedPreview.pas',
  uHistChangedIndex in 'uHistChangedIndex.pas',
  uMergeApply in 'uMergeApply.pas',
  uHistLineDetailDlg in 'uHistLineDetailDlg.pas',
  uCompareMergeUI in 'uCompareMergeUI.pas' {frmCompareMerge},
  uTailMacro in 'uTailMacro.pas',
  uTailExportDialog in 'uTailExportDialog.pas',
  uEmEditorFeatures in 'uEmEditorFeatures.pas',
  uAnonymize in 'uAnonymize.pas',
  uAnonymizeDialog in 'uAnonymizeDialog.pas',
  uAgentPrefs in 'uAgentPrefs.pas',
  uAgentProtocol in 'uAgentProtocol.pas',
  uAgentTools in 'uAgentTools.pas',
  uAgentPatch in 'uAgentPatch.pas',
  uAgentMatchIntent in 'uAgentMatchIntent.pas',
  uAgentSql in 'uAgentSql.pas',
  uExportDoneDlg in 'uExportDoneDlg.pas',
  uAgentBridge in 'uAgentBridge.pas',
  uAgentLoop in 'uAgentLoop.pas',
  uAgentActions in 'uAgentActions.pas',
  uAgentWorkspace in 'uAgentWorkspace.pas',
  uFastFileAssistantHost in 'uFastFileAssistantHost.pas',
  uFastFileAssistantMap in 'uFastFileAssistantMap.pas',
  uFastFileAssistantRAG in 'uFastFileAssistantRAG.pas',
  uFastFileAssistantCatalog in 'uFastFileAssistantCatalog.pas',
  uFastFileAssistantIntent in 'uFastFileAssistantIntent.pas',
  uFastFileComposeExport in 'uFastFileComposeExport.pas',
  uFastFileNotice in 'uFastFileNotice.pas',
  uFastFileMsgDlg in 'uFastFileMsgDlg.pas',
  uFastFileScale in 'uFastFileScale.pas',
  uFastFileFloatHost in 'uFastFileFloatHost.pas',
  uFastFileAssistant in 'uFastFileAssistant.pas',
  uAssistantPipelineStore in 'uAssistantPipelineStore.pas',
  uAssistantPostAction in 'uAssistantPostAction.pas',
  uFastFileExternalExe in 'uFastFileExternalExe.pas',
  uFileFormatConvert in 'uFileFormatConvert.pas',
  uEolPolicy in 'uEolPolicy.pas',
  uFilterBar in 'uFilterBar.pas',
  uFindOccurrencesBar in 'uFindOccurrencesBar.pas',
  uBookmarkBar in 'uBookmarkBar.pas',
  uMruFind in 'uMruFind.pas',
  uUserPrefs in 'uUserPrefs.pas',
  uPrefsDialog in 'uPrefsDialog.pas',
  uFastFileAppGuard in 'uFastFileAppGuard.pas',
  uFastFileWatchdog in 'uFastFileWatchdog.pas',
  UnitPopupMruList in 'UnitPopupMruList.pas' {FormPopupMruList},
  MainUnit in 'MainUnit.pas' {frmMain};

const
  showDeveloperInfo: Boolean = True;
var
  //i: integer;
  Map: THandle;

{$R *.RES}
{$SetPEFlags $0020} // IMAGE_FILE_LARGE_ADDRESS_AWARE: allows 4 GB VA on 64-bit Windows (vs 2 GB default)
{$i sDefs.inc}

begin
  { Single instance per platform (Win32 and Win64 may run together).
    Use Local\ — Global\ needs SeCreateGlobalPrivilege and fails for normal
    users with CreateFileMapping=0 ("Error memory allocation."). }
{$IFDEF WIN64}
  Map := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 32,
    'Local\FastFile_SingleInstance_x64');
{$ELSE}
  Map := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READONLY, 0, 32,
    'Local\FastFile_SingleInstance_x86');
{$ENDIF}
  if Map = 0 then
  begin
    sShowMessage(Format('Could not create single-instance lock (error %d).',
      [GetLastError]));
    Halt;
  end
  else if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    sShowMessage('This application is already running');
    Halt;
  end; //End checking for one instance

  Application.Initialize;
  FfInstallFormLayoutManager;
  InstallFastFileExceptionGuard;
  InstallFastFileWatchdog;
  try
    // DataModule with TsSkinManager component should be created first
    //  if LoadProfilerDll then
    //    ShowProfileForm;
  {$IFDEF D2007}
    {$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
    {$ENDIF}
    Application.MainFormOnTaskBar := True;
  {$ENDIF}
    //  acAllowLatestCommonDialogs := True;
    Application.Title := 'FastFile';
    DataModule1 := TDataModule1.Create(Application);
    (*frmSplash := TfrmSplash.Create(Application);
    //frmSplash.lblInfo.Caption := UnUtils.LoadConfig(showDeveloperInfo);
    frmSplash.Show;
    // Here maybe placed any initialization or other code
    for i := 300 downto 1 do
    begin
      //fmSplash.sLabelFX2.Caption := 'This form will be shown for ' + IntToStr(i div 1000 + 1) + ' seconds...';
      Application.ProcessMessages;
      Sleep(1);
    end;  *)
    Application.CreateForm(TfrmMain, frmMain);
    FfFitFormToWorkArea(Application.MainForm);
  except
    on E: Exception do
    begin
      ReportFastFileException('Startup', E, True);
      Halt(1);
    end;
  end;
  try
    Application.Run;
  except
    on E: Exception do
      ReportFastFileException('Application.Run', E, True);
  end;
end.
