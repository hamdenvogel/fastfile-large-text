unit uPrefsDialog;

{ Pilot preferences dialog: MRU sizes + line-hint delay/limits. Built in code (no DFM). }

interface

uses
  Classes, Controls, Forms, StdCtrls, ExtCtrls, SysUtils, Messages;

type
  TfrmUserPrefs = class(TForm)
  private
    FLblIntro: TLabel;
    FGrpMru: TGroupBox;
    FLblFilterMru: TLabel;
    FEdtFilterMru: TEdit;
    FLblFilterMruHint: TLabel;
    FLblAssistMru: TLabel;
    FEdtAssistMru: TEdit;
    FLblAssistMruHint: TLabel;
    FLblTabsMru: TLabel;
    FEdtTabsMru: TEdit;
    FLblTabsMruHint: TLabel;
    FGrpHints: TGroupBox;
    FLblHintDelay: TLabel;
    FEdtHintDelay: TEdit;
    FLblHintDelayHint: TLabel;
    FLblHintChars: TLabel;
    FEdtHintChars: TEdit;
    FLblHintCharsHint: TLabel;
    FLblHintLines: TLabel;
    FEdtHintLines: TEdit;
    FLblHintLinesHint: TLabel;
    FGrpHistory: TGroupBox;
    FLblHistExcerpt: TLabel;
    FEdtHistExcerpt: TEdit;
    FLblHistExcerptHint: TLabel;
    FGrpDisplay: TGroupBox;
    FLblUIScale: TLabel;
    FEdtUIScale: TEdit;
    FLblUIScaleHint: TLabel;
    FChkShowWorkflowWizard: TCheckBox;
    FBtnShowWorkflowWizardNow: TButton;
    FShowWorkflowWizardNow: Boolean;
    FGrpAgent: TGroupBox;
    FLblAgentSecs: TLabel;
    FEdtAgentSecs: TEdit;
    FLblAgentSecsHint: TLabel;
    FLblAgentSample: TLabel;
    FEdtAgentSample: TEdit;
    FLblAgentSampleHint: TLabel;
    FLblPythonMacroSample: TLabel;
    FEdtPythonMacroSample: TEdit;
    FLblPythonMacroSampleHint: TLabel;
    FGrpSelLines: TGroupBox;
    FLblSelLinesMax: TLabel;
    FEdtSelLinesMax: TEdit;
    FLblSelLinesMaxHint: TLabel;
    FLblAnonMax: TLabel;
    FEdtAnonMax: TEdit;
    FLblAnonMaxHint: TLabel;
    FLblMergeMax: TLabel;
    FEdtMergeMax: TEdit;
    FLblMergeMaxHint: TLabel;
    FLblTranslateMax: TLabel;
    FEdtTranslateMax: TEdit;
    FLblTranslateMaxHint: TLabel;
    FGrpMore: TGroupBox;
    FLblExportClip: TLabel;
    FEdtExportClip: TEdit;
    FLblExportClipHint: TLabel;
    FLblExportFile: TLabel;
    FEdtExportFile: TEdit;
    FLblExportFileHint: TLabel;
    FLblInsertMax: TLabel;
    FEdtInsertMax: TEdit;
    FLblInsertMaxHint: TLabel;
    FLblSplitFiles: TLabel;
    FEdtSplitFiles: TEdit;
    FLblSplitFilesHint: TLabel;
    FLblSplitParts: TLabel;
    FEdtSplitParts: TEdit;
    FLblSplitPartsHint: TLabel;
    FScroll: TScrollBox;
    FBtnBar: TPanel;
    FBtnReset: TButton;
    FBtnOK: TButton;
    FBtnCancel: TButton;
    procedure BuildUi;
    procedure LayoutAfterI18n;
    procedure LoadFromPrefs;
    procedure ApplyI18n;
    function CollectToPrefs: Boolean;
    procedure btnResetClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnShowWorkflowWizardNowClick(Sender: TObject);
  public
    procedure MouseWheelHandler(var Message: TMessage); override;
    class function Execute(out AShowWorkflowWizardNow: Boolean): Boolean;
  end;

implementation

uses
  Graphics, Windows, Dialogs, Math, Menus, uI18n, UnConsts, uUserPrefs;

function RangeHint(AMin, AMax, ADef: Integer): string;
begin
  Result := Format(TrText('Prefs.RangeDefault'), [AMin, AMax, ADef]);
end;

procedure TfrmUserPrefs.BuildUi;
const
  L = 20;
  W = 640;
  EDIT_W = 88;
var
  FooterDivider: TPanel;
  Accent: TPanel;
  Sections: array[0..6] of TGroupBox;
  I: Integer;
begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 684;
  ClientHeight := 500;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := $00F1F4F8;

  FBtnBar := TPanel.Create(Self);
  FBtnBar.Parent := Self;
  FBtnBar.Align := alBottom;
  FBtnBar.Height := 54;
  FBtnBar.BevelOuter := bvNone;
  FBtnBar.Color := clWhite;
  FBtnBar.ParentBackground := False;

  FooterDivider := TPanel.Create(FBtnBar);
  FooterDivider.Parent := FBtnBar;
  FooterDivider.Align := alTop;
  FooterDivider.Height := 1;
  FooterDivider.BevelOuter := bvNone;
  FooterDivider.ParentColor := False;
  FooterDivider.Color := $00DCE4ED;

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;
  FScroll.BorderStyle := bsNone;
  FScroll.Color := $00F1F4F8;
  FScroll.ParentBackground := False;
  FScroll.HorzScrollBar.Visible := False;
  FScroll.VertScrollBar.Tracking := True;

  FLblIntro := TLabel.Create(Self);
  FLblIntro.Parent := FScroll;
  FLblIntro.AutoSize := False;
  FLblIntro.WordWrap := True;
  FLblIntro.SetBounds(L, 12, W, 40);
  FLblIntro.Font.Color := $0054677A;

  FGrpMru := TGroupBox.Create(Self);
  FGrpMru.Parent := FScroll;
  FGrpMru.SetBounds(L, 58, W, 150);

  FLblFilterMru := TLabel.Create(Self);
  FLblFilterMru.Parent := FGrpMru;
  FLblFilterMru.SetBounds(12, 24, 280, 13);
  FEdtFilterMru := TEdit.Create(Self);
  FEdtFilterMru.Parent := FGrpMru;
  FEdtFilterMru.SetBounds(310, 20, EDIT_W, 21);
  FLblFilterMruHint := TLabel.Create(Self);
  FLblFilterMruHint.Parent := FGrpMru;
  FLblFilterMruHint.SetBounds(12, 42, 420, 13);
  FLblFilterMruHint.Font.Color := clGrayText;

  FLblAssistMru := TLabel.Create(Self);
  FLblAssistMru.Parent := FGrpMru;
  FLblAssistMru.SetBounds(12, 66, 280, 13);
  FEdtAssistMru := TEdit.Create(Self);
  FEdtAssistMru.Parent := FGrpMru;
  FEdtAssistMru.SetBounds(310, 62, EDIT_W, 21);
  FLblAssistMruHint := TLabel.Create(Self);
  FLblAssistMruHint.Parent := FGrpMru;
  FLblAssistMruHint.SetBounds(12, 84, 420, 13);
  FLblAssistMruHint.Font.Color := clGrayText;

  FLblTabsMru := TLabel.Create(Self);
  FLblTabsMru.Parent := FGrpMru;
  FLblTabsMru.SetBounds(12, 108, 280, 13);
  FEdtTabsMru := TEdit.Create(Self);
  FEdtTabsMru.Parent := FGrpMru;
  FEdtTabsMru.SetBounds(310, 104, EDIT_W, 21);
  FLblTabsMruHint := TLabel.Create(Self);
  FLblTabsMruHint.Parent := FGrpMru;
  FLblTabsMruHint.SetBounds(12, 126, 420, 13);
  FLblTabsMruHint.Font.Color := clGrayText;

  FGrpHints := TGroupBox.Create(Self);
  FGrpHints.Parent := FScroll;
  FGrpHints.SetBounds(L, 220, W, 150);

  FLblHintDelay := TLabel.Create(Self);
  FLblHintDelay.Parent := FGrpHints;
  FLblHintDelay.SetBounds(12, 24, 280, 13);
  FEdtHintDelay := TEdit.Create(Self);
  FEdtHintDelay.Parent := FGrpHints;
  FEdtHintDelay.SetBounds(310, 20, EDIT_W, 21);
  FLblHintDelayHint := TLabel.Create(Self);
  FLblHintDelayHint.Parent := FGrpHints;
  FLblHintDelayHint.SetBounds(12, 42, 420, 13);
  FLblHintDelayHint.Font.Color := clGrayText;

  FLblHintChars := TLabel.Create(Self);
  FLblHintChars.Parent := FGrpHints;
  FLblHintChars.SetBounds(12, 66, 280, 13);
  FEdtHintChars := TEdit.Create(Self);
  FEdtHintChars.Parent := FGrpHints;
  FEdtHintChars.SetBounds(310, 62, EDIT_W, 21);
  FLblHintCharsHint := TLabel.Create(Self);
  FLblHintCharsHint.Parent := FGrpHints;
  FLblHintCharsHint.SetBounds(12, 84, 420, 13);
  FLblHintCharsHint.Font.Color := clGrayText;

  FLblHintLines := TLabel.Create(Self);
  FLblHintLines.Parent := FGrpHints;
  FLblHintLines.SetBounds(12, 108, 280, 13);
  FEdtHintLines := TEdit.Create(Self);
  FEdtHintLines.Parent := FGrpHints;
  FEdtHintLines.SetBounds(310, 104, EDIT_W, 21);
  FLblHintLinesHint := TLabel.Create(Self);
  FLblHintLinesHint.Parent := FGrpHints;
  FLblHintLinesHint.SetBounds(12, 126, 420, 13);
  FLblHintLinesHint.Font.Color := clGrayText;

  FGrpHistory := TGroupBox.Create(Self);
  FGrpHistory.Parent := FScroll;
  FGrpHistory.SetBounds(L, 380, W, 66);

  FLblHistExcerpt := TLabel.Create(Self);
  FLblHistExcerpt.Parent := FGrpHistory;
  FLblHistExcerpt.SetBounds(12, 24, 290, 13);
  FEdtHistExcerpt := TEdit.Create(Self);
  FEdtHistExcerpt.Parent := FGrpHistory;
  FEdtHistExcerpt.SetBounds(310, 20, EDIT_W, 21);
  FLblHistExcerptHint := TLabel.Create(Self);
  FLblHistExcerptHint.Parent := FGrpHistory;
  FLblHistExcerptHint.SetBounds(12, 42, 420, 13);
  FLblHistExcerptHint.Font.Color := clGrayText;

  FGrpDisplay := TGroupBox.Create(Self);
  FGrpDisplay.Parent := FScroll;
  FGrpDisplay.SetBounds(L, 456, W, 124);

  FLblUIScale := TLabel.Create(Self);
  FLblUIScale.Parent := FGrpDisplay;
  FLblUIScale.SetBounds(12, 24, 290, 13);
  FEdtUIScale := TEdit.Create(Self);
  FEdtUIScale.Parent := FGrpDisplay;
  FEdtUIScale.SetBounds(310, 20, EDIT_W, 21);
  FLblUIScaleHint := TLabel.Create(Self);
  FLblUIScaleHint.Parent := FGrpDisplay;
  FLblUIScaleHint.SetBounds(12, 42, 420, 13);
  FLblUIScaleHint.Font.Color := clGrayText;
  FChkShowWorkflowWizard := TCheckBox.Create(Self);
  FChkShowWorkflowWizard.Parent := FGrpDisplay;
  FChkShowWorkflowWizard.SetBounds(12, 64, W - 24, 20);
  FBtnShowWorkflowWizardNow := TButton.Create(Self);
  FBtnShowWorkflowWizardNow.Parent := FGrpDisplay;
  FBtnShowWorkflowWizardNow.SetBounds(12, 90, 180, 26);
  FBtnShowWorkflowWizardNow.OnClick := btnShowWorkflowWizardNowClick;

  FGrpAgent := TGroupBox.Create(Self);
  FGrpAgent.Parent := FScroll;
  FGrpAgent.SetBounds(L, 532, W, 150);

  FLblAgentSecs := TLabel.Create(Self);
  FLblAgentSecs.Parent := FGrpAgent;
  FLblAgentSecs.SetBounds(12, 24, 290, 13);
  FEdtAgentSecs := TEdit.Create(Self);
  FEdtAgentSecs.Parent := FGrpAgent;
  FEdtAgentSecs.SetBounds(310, 20, EDIT_W, 21);
  FEdtAgentSecs.MaxLength := 4;
  FLblAgentSecsHint := TLabel.Create(Self);
  FLblAgentSecsHint.Parent := FGrpAgent;
  FLblAgentSecsHint.SetBounds(12, 42, 420, 13);
  FLblAgentSecsHint.Font.Color := clGrayText;

  FLblAgentSample := TLabel.Create(Self);
  FLblAgentSample.Parent := FGrpAgent;
  FLblAgentSample.SetBounds(12, 66, 290, 13);
  FEdtAgentSample := TEdit.Create(Self);
  FEdtAgentSample.Parent := FGrpAgent;
  FEdtAgentSample.SetBounds(310, 62, EDIT_W, 21);
  FEdtAgentSample.MaxLength := 4;
  FLblAgentSampleHint := TLabel.Create(Self);
  FLblAgentSampleHint.Parent := FGrpAgent;
  FLblAgentSampleHint.SetBounds(12, 84, 420, 13);
  FLblAgentSampleHint.Font.Color := clGrayText;

  FLblPythonMacroSample := TLabel.Create(Self);
  FLblPythonMacroSample.Parent := FGrpAgent;
  FLblPythonMacroSample.SetBounds(12, 108, 290, 13);
  FEdtPythonMacroSample := TEdit.Create(Self);
  FEdtPythonMacroSample.Parent := FGrpAgent;
  FEdtPythonMacroSample.SetBounds(310, 104, EDIT_W, 21);
  FEdtPythonMacroSample.MaxLength := 3;
  FLblPythonMacroSampleHint := TLabel.Create(Self);
  FLblPythonMacroSampleHint.Parent := FGrpAgent;
  FLblPythonMacroSampleHint.SetBounds(12, 126, 420, 13);
  FLblPythonMacroSampleHint.Font.Color := clGrayText;

  FGrpSelLines := TGroupBox.Create(Self);
  FGrpSelLines.Parent := FScroll;
  FGrpSelLines.SetBounds(L, 608, W, 192);

  FLblSelLinesMax := TLabel.Create(Self);
  FLblSelLinesMax.Parent := FGrpSelLines;
  FLblSelLinesMax.SetBounds(12, 24, 290, 13);
  FEdtSelLinesMax := TEdit.Create(Self);
  FEdtSelLinesMax.Parent := FGrpSelLines;
  FEdtSelLinesMax.SetBounds(310, 20, EDIT_W, 21);
  FEdtSelLinesMax.MaxLength := 5;
  FLblSelLinesMaxHint := TLabel.Create(Self);
  FLblSelLinesMaxHint.Parent := FGrpSelLines;
  FLblSelLinesMaxHint.SetBounds(12, 42, 420, 13);
  FLblSelLinesMaxHint.Font.Color := clGrayText;

  FLblAnonMax := TLabel.Create(Self);
  FLblAnonMax.Parent := FGrpSelLines;
  FLblAnonMax.SetBounds(12, 66, 290, 13);
  FEdtAnonMax := TEdit.Create(Self);
  FEdtAnonMax.Parent := FGrpSelLines;
  FEdtAnonMax.SetBounds(310, 62, EDIT_W, 21);
  FEdtAnonMax.MaxLength := 5;
  FLblAnonMaxHint := TLabel.Create(Self);
  FLblAnonMaxHint.Parent := FGrpSelLines;
  FLblAnonMaxHint.SetBounds(12, 84, 420, 13);
  FLblAnonMaxHint.Font.Color := clGrayText;

  FLblMergeMax := TLabel.Create(Self);
  FLblMergeMax.Parent := FGrpSelLines;
  FLblMergeMax.SetBounds(12, 108, 290, 13);
  FEdtMergeMax := TEdit.Create(Self);
  FEdtMergeMax.Parent := FGrpSelLines;
  FEdtMergeMax.SetBounds(310, 104, EDIT_W, 21);
  FEdtMergeMax.MaxLength := 5;
  FLblMergeMaxHint := TLabel.Create(Self);
  FLblMergeMaxHint.Parent := FGrpSelLines;
  FLblMergeMaxHint.SetBounds(12, 126, 420, 13);
  FLblMergeMaxHint.Font.Color := clGrayText;

  FLblTranslateMax := TLabel.Create(Self);
  FLblTranslateMax.Parent := FGrpSelLines;
  FLblTranslateMax.SetBounds(12, 150, 290, 13);
  FEdtTranslateMax := TEdit.Create(Self);
  FEdtTranslateMax.Parent := FGrpSelLines;
  FEdtTranslateMax.SetBounds(310, 146, EDIT_W, 21);
  FEdtTranslateMax.MaxLength := 4;
  FLblTranslateMaxHint := TLabel.Create(Self);
  FLblTranslateMaxHint.Parent := FGrpSelLines;
  FLblTranslateMaxHint.SetBounds(12, 168, 420, 13);
  FLblTranslateMaxHint.Font.Color := clGrayText;

  FGrpMore := TGroupBox.Create(Self);
  FGrpMore.Parent := FScroll;
  FGrpMore.SetBounds(L, 820, W, 234);

  FLblExportClip := TLabel.Create(Self);
  FLblExportClip.Parent := FGrpMore;
  FLblExportClip.SetBounds(12, 24, 290, 13);
  FEdtExportClip := TEdit.Create(Self);
  FEdtExportClip.Parent := FGrpMore;
  FEdtExportClip.SetBounds(310, 20, EDIT_W, 21);
  FEdtExportClip.MaxLength := 5;
  FLblExportClipHint := TLabel.Create(Self);
  FLblExportClipHint.Parent := FGrpMore;
  FLblExportClipHint.SetBounds(12, 42, 420, 13);
  FLblExportClipHint.Font.Color := clGrayText;

  FLblExportFile := TLabel.Create(Self);
  FLblExportFile.Parent := FGrpMore;
  FLblExportFile.SetBounds(12, 66, 290, 13);
  FEdtExportFile := TEdit.Create(Self);
  FEdtExportFile.Parent := FGrpMore;
  FEdtExportFile.SetBounds(310, 62, EDIT_W, 21);
  FEdtExportFile.MaxLength := 7;
  FLblExportFileHint := TLabel.Create(Self);
  FLblExportFileHint.Parent := FGrpMore;
  FLblExportFileHint.SetBounds(12, 84, 420, 13);
  FLblExportFileHint.Font.Color := clGrayText;

  FLblInsertMax := TLabel.Create(Self);
  FLblInsertMax.Parent := FGrpMore;
  FLblInsertMax.SetBounds(12, 108, 290, 13);
  FEdtInsertMax := TEdit.Create(Self);
  FEdtInsertMax.Parent := FGrpMore;
  FEdtInsertMax.SetBounds(310, 104, EDIT_W, 21);
  FEdtInsertMax.MaxLength := 6;
  FLblInsertMaxHint := TLabel.Create(Self);
  FLblInsertMaxHint.Parent := FGrpMore;
  FLblInsertMaxHint.SetBounds(12, 126, 420, 13);
  FLblInsertMaxHint.Font.Color := clGrayText;

  FLblSplitFiles := TLabel.Create(Self);
  FLblSplitFiles.Parent := FGrpMore;
  FLblSplitFiles.SetBounds(12, 150, 290, 13);
  FEdtSplitFiles := TEdit.Create(Self);
  FEdtSplitFiles.Parent := FGrpMore;
  FEdtSplitFiles.SetBounds(310, 146, EDIT_W, 21);
  FEdtSplitFiles.MaxLength := 4;
  FLblSplitFilesHint := TLabel.Create(Self);
  FLblSplitFilesHint.Parent := FGrpMore;
  FLblSplitFilesHint.SetBounds(12, 168, 420, 13);
  FLblSplitFilesHint.Font.Color := clGrayText;

  FLblSplitParts := TLabel.Create(Self);
  FLblSplitParts.Parent := FGrpMore;
  FLblSplitParts.SetBounds(12, 192, 290, 13);
  FEdtSplitParts := TEdit.Create(Self);
  FEdtSplitParts.Parent := FGrpMore;
  FEdtSplitParts.SetBounds(310, 188, EDIT_W, 21);
  FEdtSplitParts.MaxLength := 4;
  FLblSplitPartsHint := TLabel.Create(Self);
  FLblSplitPartsHint.Parent := FGrpMore;
  FLblSplitPartsHint.SetBounds(12, 210, 420, 13);
  FLblSplitPartsHint.Font.Color := clGrayText;

  FBtnReset := TButton.Create(Self);
  FBtnReset.Parent := FBtnBar;
  FBtnReset.SetBounds(L, 458, 120, 25);
  FBtnReset.OnClick := btnResetClick;

  FBtnOK := TButton.Create(Self);
  FBtnOK.Parent := FBtnBar;
  FBtnOK.SetBounds(296, 458, 88, 25);
  FBtnOK.Default := True;
  FBtnOK.OnClick := btnOKClick;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := FBtnBar;
  FBtnCancel.SetBounds(392, 458, 88, 25);
  FBtnCancel.Cancel := True;
  FBtnCancel.OnClick := btnCancelClick;

  Sections[0] := FGrpMru;
  Sections[1] := FGrpHints;
  Sections[2] := FGrpHistory;
  Sections[3] := FGrpDisplay;
  Sections[4] := FGrpAgent;
  Sections[5] := FGrpSelLines;
  Sections[6] := FGrpMore;
  for I := Low(Sections) to High(Sections) do
  begin
    Accent := TPanel.Create(Sections[I]);
    Accent.Parent := Sections[I];
    Accent.Align := alLeft;
    Accent.Width := 3;
    Accent.BevelOuter := bvNone;
    Accent.ParentColor := False;
    Accent.Color := $00D48831;
  end;
end;

procedure TfrmUserPrefs.LayoutAfterI18n;
const
  L = 20;
  MIN_W = 640;
  MIN_LBL_W = 286;
  EDIT_W = 88;
  GAP = 14;
  BTN_H = 30;
  MIN_BTN_W = 88;
  BTN_PAD = 24;
var
  IntroH, Y, NeedH, MaxH, MaxW, W, LblW, HintW, EditLeft, ResetW, OkW,
    CancelW, ShowNowW, I, G: Integer;
  R: TRect;
  Groups: array[0..6] of TGroupBox;
  C: TControl;
  IsHint: Boolean;
begin
  Canvas.Font := Font;
  Groups[0] := FGrpMru;
  Groups[1] := FGrpHints;
  Groups[2] := FGrpHistory;
  Groups[3] := FGrpDisplay;
  Groups[4] := FGrpAgent;
  Groups[5] := FGrpSelLines;
  Groups[6] := FGrpMore;

  for G := 0 to High(Groups) do
  begin
    Groups[G].ParentBackground := False;
    Groups[G].ParentFont := False;
    Groups[G].Color := clWhite;
    Groups[G].Font.Assign(Font);
    Groups[G].Font.Color := $00415A70;
    Groups[G].Font.Style := [fsBold];
  end;

  FLblIntro.ParentFont := False;
  FLblIntro.Font.Assign(Font);
  FLblIntro.Font.Size := 9;
  FLblIntro.Font.Color := $0054677A;

  { Size columns/buttons from the translated captions (long in DE/PL/HU...). }
  LblW := MIN_LBL_W;
  HintW := 0;
  for G := 0 to High(Groups) do
    for I := 0 to Groups[G].ControlCount - 1 do
    begin
      C := Groups[G].Controls[I];
      if C is TLabel then
      begin
        IsHint := TLabel(C).Font.Color = clGrayText;
        TLabel(C).ParentFont := False;
        TLabel(C).Font.Assign(Font);
        if IsHint then
        begin
          TLabel(C).Font.Color := $00738393;
          TLabel(C).Tag := 1;
          HintW := Max(HintW, Canvas.TextWidth(TLabel(C).Caption));
        end
        else
        begin
          TLabel(C).Font.Color := $00374656;
          LblW := Max(LblW, Canvas.TextWidth(TLabel(C).Caption) + 8);
        end;
      end
      else if C is TEdit then
      begin
        TEdit(C).ParentFont := False;
        TEdit(C).Font.Assign(Font);
        TEdit(C).Color := clWhite;
      end
      else if C is TCheckBox then
      begin
        TCheckBox(C).ParentFont := False;
        TCheckBox(C).Font.Assign(Font);
      end
      else if C is TButton then
      begin
        TButton(C).ParentFont := False;
        TButton(C).Font.Assign(Font);
        TButton(C).Font.Style := [fsBold];
      end;
    end;

  ResetW := Max(120, Canvas.TextWidth(StripHotkey(FBtnReset.Caption)) + BTN_PAD);
  OkW := Max(MIN_BTN_W, Canvas.TextWidth(StripHotkey(FBtnOK.Caption)) + BTN_PAD);
  CancelW := Max(MIN_BTN_W, Canvas.TextWidth(StripHotkey(FBtnCancel.Caption)) + BTN_PAD);
  ShowNowW := Max(160,
    Canvas.TextWidth(StripHotkey(FBtnShowWorkflowWizardNow.Caption)) + 36);
  EditLeft := 12 + LblW + 12;
  W := Max(MIN_W,
    Max(EditLeft + EDIT_W + 16, Max(12 + HintW + 16,
    ResetW + 8 + OkW + 8 + CancelW)));
  MaxW := 960;
  if Assigned(Screen) and (Screen.WorkAreaWidth > 500) then
    MaxW := Max(MIN_W, Screen.WorkAreaWidth - 80);
  W := Min(W, MaxW);
  LblW := Min(LblW, Max(220, W - EDIT_W - 56));
  EditLeft := 12 + LblW + 12;

  ClientWidth := W + 2 * L + 18;
  for G := 0 to High(Groups) do
    for I := 0 to Groups[G].ControlCount - 1 do
    begin
      C := Groups[G].Controls[I];
      if C is TEdit then
      begin
        C.Left := EditLeft;
        C.Width := EDIT_W;
      end
      else if C is TCheckBox then
        C.Width := W - 24
      else if C is TLabel then
      begin
        if TLabel(C).Tag = 1 then
          C.Width := W - 24
        else
          C.Width := LblW;
      end;
    end;

  R := Rect(0, 0, W, 0);
  DrawText(Canvas.Handle, PChar(FLblIntro.Caption), -1, R,
    DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
  IntroH := R.Bottom - R.Top;
  if IntroH < 13 then IntroH := 13;
  FLblIntro.SetBounds(L, 12, W, IntroH);

  Y := FLblIntro.Top + FLblIntro.Height + GAP;
  FGrpMru.SetBounds(L, Y, W, FGrpMru.Height);
  Y := FGrpMru.Top + FGrpMru.Height + GAP;
  FGrpHints.SetBounds(L, Y, W, FGrpHints.Height);
  Y := FGrpHints.Top + FGrpHints.Height + GAP;
  FGrpHistory.SetBounds(L, Y, W, FGrpHistory.Height);
  Y := FGrpHistory.Top + FGrpHistory.Height + GAP;
  FGrpDisplay.SetBounds(L, Y, W, 124);
  FChkShowWorkflowWizard.SetBounds(12, 64, W - 24, 20);
  FBtnShowWorkflowWizardNow.SetBounds(12, 90, Min(ShowNowW, W - 40), 28);
  Y := FGrpDisplay.Top + FGrpDisplay.Height + GAP;
  FGrpAgent.SetBounds(L, Y, W, FGrpAgent.Height);
  Y := FGrpAgent.Top + FGrpAgent.Height + GAP;
  FGrpSelLines.SetBounds(L, Y, W, FGrpSelLines.Height);
  Y := FGrpSelLines.Top + FGrpSelLines.Height + GAP;
  FGrpMore.SetBounds(L, Y, W, FGrpMore.Height);
  Y := FGrpMore.Top + FGrpMore.Height + 8;

  FBtnReset.SetBounds(L, 12, ResetW, BTN_H);
  FBtnCancel.SetBounds(L + W - CancelW, 12, CancelW, BTN_H);
  FBtnOK.SetBounds(FBtnCancel.Left - 8 - OkW, 12, OkW, BTN_H);

  NeedH := Y + FBtnBar.Height;
  MaxH := 480;
  if Assigned(Screen) and (Screen.WorkAreaHeight > 400) then
    MaxH := Screen.WorkAreaHeight - 64;
  if NeedH > MaxH then
    NeedH := MaxH;
  ClientHeight := NeedH;
end;

procedure TfrmUserPrefs.ApplyI18n;
  function WithDefault(const ACaption: string; ADefault: Integer): string;
  begin
    Result := ACaption + ' (' + Format(TrText('Limit.DefaultValue'), [ADefault]) + ')';
  end;
begin
  Caption := TrText('Prefs.Caption');
  FLblIntro.Caption := TrText('Prefs.Intro');
  FGrpMru.Caption := TrText('Prefs.Section.MRU');
  FLblFilterMru.Caption := TrText('Prefs.FilterRecentMax');
  FLblAssistMru.Caption := TrText('Prefs.AssistantRecentMax');
  FLblTabsMru.Caption := TrText('Prefs.OpenTabsMruMax');
  FGrpHints.Caption := TrText('Prefs.Section.Hints');
  FLblHintDelay.Caption := TrText('Prefs.LineHintShowDelayMs');
  FLblHintChars.Caption := TrText('Prefs.LineHintMaxChars');
  FLblHintLines.Caption := TrText('Prefs.LineHintMaxLines');
  FLblFilterMruHint.Caption := RangeHint(MIN_FILTER_RECENT_MAX, MAX_FILTER_RECENT_MAX, DEF_FILTER_RECENT_MAX);
  FLblAssistMruHint.Caption := RangeHint(MIN_ASSISTANT_RECENT_MAX, MAX_ASSISTANT_RECENT_MAX, DEF_ASSISTANT_RECENT_MAX);
  FLblTabsMruHint.Caption := RangeHint(MIN_OPEN_TABS_MRU_MAX, MAX_OPEN_TABS_MRU_MAX, DEF_OPEN_TABS_MRU_MAX);
  FLblHintDelayHint.Caption := RangeHint(MIN_LINE_HINT_SHOW_DELAY_MS, MAX_LINE_HINT_SHOW_DELAY_MS, DEF_LINE_HINT_SHOW_DELAY_MS);
  FLblHintCharsHint.Caption := RangeHint(MIN_LINE_HINT_MAX_CHARS, MAX_LINE_HINT_MAX_CHARS, DEF_LINE_HINT_MAX_CHARS);
  FLblHintLinesHint.Caption := RangeHint(MIN_LINE_HINT_MAX_LINES, MAX_LINE_HINT_MAX_LINES, DEF_LINE_HINT_MAX_LINES);
  FGrpHistory.Caption := TrText('Prefs.Section.History');
  FLblHistExcerpt.Caption := TrText('Prefs.HistoryLineExcerptMax');
  FLblHistExcerptHint.Caption := RangeHint(MIN_HISTORY_LINE_EXCERPT_MAX,
    MAX_HISTORY_LINE_EXCERPT_MAX, DEF_HISTORY_LINE_EXCERPT_MAX);
  FGrpDisplay.Caption := TrText('Prefs.Section.Display');
  FLblUIScale.Caption := TrText('Prefs.DefaultUIScalePPI');
  FLblUIScaleHint.Caption := Format(TrText('Prefs.DefaultUIScalePPIHint'),
    [MIN_UI_SCALE_PPI, MAX_UI_SCALE_PPI]);
  FChkShowWorkflowWizard.Caption := TrText('WorkflowWizard.Pref.Show');
  FBtnShowWorkflowWizardNow.Caption := TrText('WorkflowWizard.ShowNow');
  FGrpAgent.Caption := TrText('Prefs.Section.Agent');
  FLblAgentSecs.Caption := TrText('Prefs.AgentDecisionSeconds');
  FLblAgentSecsHint.Caption := RangeHint(MIN_AGENT_DECISION_SECONDS,
    MAX_AGENT_DECISION_SECONDS, DEF_AGENT_DECISION_SECONDS);
  FLblAgentSample.Caption := WithDefault(TrText('Prefs.AgentSampleLines'), DEF_AGENT_SAMPLE_LINES);
  FLblAgentSampleHint.Caption := RangeHint(MIN_AGENT_SAMPLE_LINES,
    MAX_AGENT_SAMPLE_LINES, DEF_AGENT_SAMPLE_LINES);
  FLblPythonMacroSample.Caption := WithDefault(
    TrText('Prefs.PythonMacroSampleLines'), DEF_PYTHON_MACRO_SAMPLE_LINES);
  FLblPythonMacroSampleHint.Caption :=
    TrText('Prefs.PythonMacroSampleLinesHint') + ' ' +
    RangeHint(MIN_PYTHON_MACRO_SAMPLE_LINES, MAX_PYTHON_MACRO_SAMPLE_LINES,
      DEF_PYTHON_MACRO_SAMPLE_LINES);
  FGrpSelLines.Caption := TrText('Prefs.Section.SelLines');
  FLblSelLinesMax.Caption := WithDefault(TrText('Prefs.SelectedLinesActionMax'), DEF_SELECTED_LINES_ACTION_MAX);
  FLblSelLinesMaxHint.Caption := RangeHint(MIN_SELECTED_LINES_ACTION_MAX,
    MAX_SELECTED_LINES_ACTION_MAX, DEF_SELECTED_LINES_ACTION_MAX);
  FLblAnonMax.Caption := WithDefault(TrText('Prefs.AnonymizeMaxLines'), DEF_ANONYMIZE_MAX_LINES);
  FLblAnonMaxHint.Caption := RangeHint(MIN_ANONYMIZE_MAX_LINES,
    MAX_ANONYMIZE_MAX_LINES, DEF_ANONYMIZE_MAX_LINES);
  FLblMergeMax.Caption := WithDefault(TrText('Prefs.MergeMaxLines'), DEF_MERGE_MAX_LINES);
  FLblMergeMaxHint.Caption := RangeHint(MIN_MERGE_MAX_LINES,
    MAX_MERGE_MAX_LINES, DEF_MERGE_MAX_LINES);
  FLblTranslateMax.Caption := WithDefault(TrText('Prefs.TranslateMaxLines'), DEF_TRANSLATE_MAX_LINES);
  FLblTranslateMaxHint.Caption := RangeHint(MIN_TRANSLATE_MAX_LINES,
    MAX_TRANSLATE_MAX_LINES, DEF_TRANSLATE_MAX_LINES);
  FGrpMore.Caption := TrText('Prefs.Section.MoreLimits');
  FLblExportClip.Caption := WithDefault(TrText('Prefs.ExportClipboardMaxLines'), DEF_EXPORT_CLIPBOARD_MAX_LINES);
  FLblExportClipHint.Caption := RangeHint(MIN_EXPORT_CLIPBOARD_MAX_LINES,
    MAX_EXPORT_CLIPBOARD_MAX_LINES, DEF_EXPORT_CLIPBOARD_MAX_LINES);
  FLblExportFile.Caption := WithDefault(TrText('Prefs.ExportFileMaxLines'), DEF_EXPORT_FILE_MAX_LINES);
  FLblExportFileHint.Caption := RangeHint(MIN_EXPORT_FILE_MAX_LINES,
    MAX_EXPORT_FILE_MAX_LINES, DEF_EXPORT_FILE_MAX_LINES);
  FLblInsertMax.Caption := WithDefault(TrText('Prefs.InsertMaxLines'), DEF_INSERT_MAX_LINES);
  FLblInsertMaxHint.Caption := RangeHint(MIN_INSERT_MAX_LINES,
    MAX_INSERT_MAX_LINES, DEF_INSERT_MAX_LINES);
  FLblSplitFiles.Caption := WithDefault(TrText('Prefs.SplitFilesMax'), DEF_SPLIT_FILES_MAX);
  FLblSplitFilesHint.Caption := RangeHint(MIN_SPLIT_FILES_MAX,
    MAX_SPLIT_FILES_MAX, DEF_SPLIT_FILES_MAX);
  FLblSplitParts.Caption := WithDefault(TrText('Prefs.SplitPartsMax'), DEF_SPLIT_PARTS_MAX);
  FLblSplitPartsHint.Caption := RangeHint(MIN_SPLIT_PARTS_MAX,
    MAX_SPLIT_PARTS_MAX, DEF_SPLIT_PARTS_MAX);
  FBtnReset.Caption := TrText('Prefs.ResetDefaults');
  FBtnOK.Caption := TrText('OK');
  FBtnCancel.Caption := TrText('Cancel');
  LayoutAfterI18n;
end;

procedure TfrmUserPrefs.LoadFromPrefs;
var
  V: TUserPrefValues;
begin
  V := GetUserPrefValues;
  FEdtFilterMru.Text := IntToStr(V.FilterRecentMax);
  FEdtAssistMru.Text := IntToStr(V.AssistantRecentMax);
  FEdtTabsMru.Text := IntToStr(V.OpenTabsMruMax);
  FEdtHintDelay.Text := IntToStr(V.LineHintShowDelayMs);
  FEdtHintChars.Text := IntToStr(V.LineHintMaxChars);
  FEdtHintLines.Text := IntToStr(V.LineHintMaxLines);
  FEdtHistExcerpt.Text := IntToStr(V.HistoryLineExcerptMax);
  FEdtUIScale.Text := IntToStr(V.DefaultUIScalePPI);
  FChkShowWorkflowWizard.Checked := V.ShowWorkflowWizard;
  FEdtAgentSecs.Text := IntToStr(V.AgentDecisionSeconds);
  FEdtAgentSample.Text := IntToStr(V.AgentSampleLines);
  FEdtPythonMacroSample.Text := IntToStr(V.PythonMacroSampleLines);
  FEdtSelLinesMax.Text := IntToStr(V.SelectedLinesActionMax);
  FEdtAnonMax.Text := IntToStr(V.AnonymizeMaxLines);
  FEdtMergeMax.Text := IntToStr(V.MergeMaxLines);
  FEdtTranslateMax.Text := IntToStr(V.TranslateMaxLines);
  FEdtExportClip.Text := IntToStr(V.ExportClipboardMaxLines);
  FEdtExportFile.Text := IntToStr(V.ExportFileMaxLines);
  FEdtInsertMax.Text := IntToStr(V.InsertMaxLines);
  FEdtSplitFiles.Text := IntToStr(V.SplitFilesMax);
  FEdtSplitParts.Text := IntToStr(V.SplitPartsMax);
end;

{ Strict: digits only, never blank. On any problem the default goes back into the field
  and the dialog stays open, so the user sees the value that will be saved. }
function ParseStrictField(Edt: TEdit; AMin, AMax, ADefault: Integer; const ALabel: string;
  out AValue: Integer): Boolean;
var
  S, Msg: string;
  I, N: Integer;
begin
  Result := False;
  AValue := ADefault;
  S := Trim(Edt.Text);
  Msg := '';
  N := -1;
  if S = '' then
    Msg := Format(TrText('Prefs.EmptyValue'), [ALabel])
  else
  begin
    for I := 1 to Length(S) do
      if not CharInSet(S[I], ['0'..'9']) then
      begin
        Msg := Format(TrText('Prefs.InvalidNumber'), [ALabel]);
        Break;
      end;
    if Msg = '' then
    begin
      N := StrToIntDef(S, -1);
      if (N < AMin) or (N > AMax) then
        Msg := Format(TrText('Prefs.OutOfRange'), [ALabel, AMin, AMax]);
    end;
  end;
  if Msg <> '' then
  begin
    MessageDlg(Msg + #13#10#13#10 + Format(TrText('Prefs.DefaultRestored'), [ADefault]), mtError, [mbOK], 0);
    Edt.Text := IntToStr(ADefault);
    if Edt.CanFocus then
    begin
      Edt.SetFocus;
      Edt.SelectAll;
    end;
    Exit;
  end;
  AValue := N;
  Result := True;
end;

function ParseField(Edt: TEdit; AMin, AMax, ADefault: Integer; const ALabel: string;
  out AValue: Integer): Boolean;
var
  N: Integer;
  S: string;
begin
  Result := False;
  S := Trim(Edt.Text);
  if S = '' then
  begin
    AValue := ADefault;
    Result := True;
    Exit;
  end;
  N := StrToIntDef(S, -MaxInt);
  if N = -MaxInt then
  begin
    MessageDlg(Format(TrText('Prefs.InvalidNumber'), [ALabel]), mtError, [mbOK], 0);
    if Edt.CanFocus then Edt.SetFocus;
    Exit;
  end;
  if (N < AMin) or (N > AMax) then
  begin
    MessageDlg(Format(TrText('Prefs.OutOfRange'), [ALabel, AMin, AMax]), mtError, [mbOK], 0);
    if Edt.CanFocus then Edt.SetFocus;
    Exit;
  end;
  AValue := N;
  Result := True;
end;

function TfrmUserPrefs.CollectToPrefs: Boolean;
var
  V: TUserPrefValues;
begin
  Result := False;
  if not ParseField(FEdtFilterMru, MIN_FILTER_RECENT_MAX, MAX_FILTER_RECENT_MAX,
    DEF_FILTER_RECENT_MAX, TrText('Prefs.FilterRecentMax'), V.FilterRecentMax) then Exit;
  if not ParseField(FEdtAssistMru, MIN_ASSISTANT_RECENT_MAX, MAX_ASSISTANT_RECENT_MAX,
    DEF_ASSISTANT_RECENT_MAX, TrText('Prefs.AssistantRecentMax'), V.AssistantRecentMax) then Exit;
  if not ParseField(FEdtTabsMru, MIN_OPEN_TABS_MRU_MAX, MAX_OPEN_TABS_MRU_MAX,
    DEF_OPEN_TABS_MRU_MAX, TrText('Prefs.OpenTabsMruMax'), V.OpenTabsMruMax) then Exit;
  if not ParseField(FEdtHintDelay, MIN_LINE_HINT_SHOW_DELAY_MS, MAX_LINE_HINT_SHOW_DELAY_MS,
    DEF_LINE_HINT_SHOW_DELAY_MS, TrText('Prefs.LineHintShowDelayMs'), V.LineHintShowDelayMs) then Exit;
  if not ParseField(FEdtHintChars, MIN_LINE_HINT_MAX_CHARS, MAX_LINE_HINT_MAX_CHARS,
    DEF_LINE_HINT_MAX_CHARS, TrText('Prefs.LineHintMaxChars'), V.LineHintMaxChars) then Exit;
  if not ParseField(FEdtHintLines, MIN_LINE_HINT_MAX_LINES, MAX_LINE_HINT_MAX_LINES,
    DEF_LINE_HINT_MAX_LINES, TrText('Prefs.LineHintMaxLines'), V.LineHintMaxLines) then Exit;
  if not ParseField(FEdtHistExcerpt, MIN_HISTORY_LINE_EXCERPT_MAX, MAX_HISTORY_LINE_EXCERPT_MAX,
    DEF_HISTORY_LINE_EXCERPT_MAX, TrText('Prefs.HistoryLineExcerptMax'), V.HistoryLineExcerptMax) then Exit;
  { 0 = Windows DPI, otherwise MIN_UI_SCALE_PPI..MAX_UI_SCALE_PPI. }
  if not ParseField(FEdtUIScale, 0, MAX_UI_SCALE_PPI,
    DEF_UI_SCALE_PPI, TrText('Prefs.DefaultUIScalePPI'), V.DefaultUIScalePPI) then Exit;
  V.ShowWorkflowWizard := FChkShowWorkflowWizard.Checked;
  if (V.DefaultUIScalePPI > 0) and (V.DefaultUIScalePPI < MIN_UI_SCALE_PPI) then
  begin
    MessageDlg(Format(TrText('Prefs.OutOfRange'),
      [TrText('Prefs.DefaultUIScalePPI'), MIN_UI_SCALE_PPI, MAX_UI_SCALE_PPI]), mtError, [mbOK], 0);
    if FEdtUIScale.CanFocus then FEdtUIScale.SetFocus;
    Exit;
  end;
  if not ParseStrictField(FEdtAgentSecs, MIN_AGENT_DECISION_SECONDS, MAX_AGENT_DECISION_SECONDS,
    DEF_AGENT_DECISION_SECONDS, TrText('Prefs.AgentDecisionSeconds'), V.AgentDecisionSeconds) then Exit;
  if not ParseStrictField(FEdtAgentSample, MIN_AGENT_SAMPLE_LINES, MAX_AGENT_SAMPLE_LINES,
    DEF_AGENT_SAMPLE_LINES, TrText('Prefs.AgentSampleLines'), V.AgentSampleLines) then Exit;
  if not ParseStrictField(FEdtPythonMacroSample, MIN_PYTHON_MACRO_SAMPLE_LINES,
    MAX_PYTHON_MACRO_SAMPLE_LINES, DEF_PYTHON_MACRO_SAMPLE_LINES,
    TrText('Prefs.PythonMacroSampleLines'), V.PythonMacroSampleLines) then Exit;
  if not ParseStrictField(FEdtSelLinesMax, MIN_SELECTED_LINES_ACTION_MAX, MAX_SELECTED_LINES_ACTION_MAX,
    DEF_SELECTED_LINES_ACTION_MAX, TrText('Prefs.SelectedLinesActionMax'), V.SelectedLinesActionMax) then Exit;
  if not ParseStrictField(FEdtAnonMax, MIN_ANONYMIZE_MAX_LINES, MAX_ANONYMIZE_MAX_LINES,
    DEF_ANONYMIZE_MAX_LINES, TrText('Prefs.AnonymizeMaxLines'), V.AnonymizeMaxLines) then Exit;
  if not ParseStrictField(FEdtMergeMax, MIN_MERGE_MAX_LINES, MAX_MERGE_MAX_LINES,
    DEF_MERGE_MAX_LINES, TrText('Prefs.MergeMaxLines'), V.MergeMaxLines) then Exit;
  if not ParseStrictField(FEdtTranslateMax, MIN_TRANSLATE_MAX_LINES, MAX_TRANSLATE_MAX_LINES,
    DEF_TRANSLATE_MAX_LINES, TrText('Prefs.TranslateMaxLines'), V.TranslateMaxLines) then Exit;
  if not ParseStrictField(FEdtExportClip, MIN_EXPORT_CLIPBOARD_MAX_LINES, MAX_EXPORT_CLIPBOARD_MAX_LINES,
    DEF_EXPORT_CLIPBOARD_MAX_LINES, TrText('Prefs.ExportClipboardMaxLines'), V.ExportClipboardMaxLines) then Exit;
  if not ParseStrictField(FEdtExportFile, MIN_EXPORT_FILE_MAX_LINES, MAX_EXPORT_FILE_MAX_LINES,
    DEF_EXPORT_FILE_MAX_LINES, TrText('Prefs.ExportFileMaxLines'), V.ExportFileMaxLines) then Exit;
  if not ParseStrictField(FEdtInsertMax, MIN_INSERT_MAX_LINES, MAX_INSERT_MAX_LINES,
    DEF_INSERT_MAX_LINES, TrText('Prefs.InsertMaxLines'), V.InsertMaxLines) then Exit;
  if not ParseStrictField(FEdtSplitFiles, MIN_SPLIT_FILES_MAX, MAX_SPLIT_FILES_MAX,
    DEF_SPLIT_FILES_MAX, TrText('Prefs.SplitFilesMax'), V.SplitFilesMax) then Exit;
  if not ParseStrictField(FEdtSplitParts, MIN_SPLIT_PARTS_MAX, MAX_SPLIT_PARTS_MAX,
    DEF_SPLIT_PARTS_MAX, TrText('Prefs.SplitPartsMax'), V.SplitPartsMax) then Exit;
  SetUserPrefValues(V);
  Result := True;
end;

procedure TfrmUserPrefs.MouseWheelHandler(var Message: TMessage);
var
  Pt: TPoint;
  Lines, Step: Integer;
begin
  if Assigned(FScroll) and FScroll.HandleAllocated then
  begin
    Pt := FScroll.ScreenToClient(SmallPointToPoint(TWMMouseWheel(Message).Pos));
    if PtInRect(FScroll.ClientRect, Pt) then
    begin
      Lines := Mouse.WheelScrollLines;
      if (Lines < 1) or (DWORD(Lines) = WHEEL_PAGESCROLL) then
        Lines := 3;
      Step := TWMMouseWheel(Message).WheelDelta * Lines * 24 div WHEEL_DELTA;
      if Step <> 0 then
        FScroll.VertScrollBar.Position := FScroll.VertScrollBar.Position - Step;
      Message.Result := 1;
      Exit;
    end;
  end;
  inherited MouseWheelHandler(Message);
end;

procedure TfrmUserPrefs.btnResetClick(Sender: TObject);
begin
  ResetUserPrefsToDefaults;
  LoadFromPrefs;
end;

procedure TfrmUserPrefs.btnOKClick(Sender: TObject);
begin
  if CollectToPrefs then
    ModalResult := mrOk;
end;

procedure TfrmUserPrefs.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmUserPrefs.btnShowWorkflowWizardNowClick(Sender: TObject);
begin
  FShowWorkflowWizardNow := True;
  FChkShowWorkflowWizard.Checked := True;
  btnOKClick(Sender);
end;

class function TfrmUserPrefs.Execute(
  out AShowWorkflowWizardNow: Boolean): Boolean;
var
  Frm: TfrmUserPrefs;
begin
  AShowWorkflowWizardNow := False;
  Frm := TfrmUserPrefs.CreateNew(nil);
  try
    Frm.BuildUi;
    Frm.ApplyI18n;
    Frm.LoadFromPrefs;
    Result := Frm.ShowModal = mrOk;
    if Result then
      AShowWorkflowWizardNow := Frm.FShowWorkflowWizardNow;
  finally
    Frm.Free;
  end;
end;

end.
