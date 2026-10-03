unit uPrefsDialog;

{ Pilot preferences dialog: MRU sizes + line-hint delay/limits. Built in code (no DFM). }

interface

uses
  Classes, Controls, Forms, StdCtrls, ExtCtrls, SysUtils;

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
  public
    class function Execute: Boolean;
  end;

implementation

uses
  Graphics, Windows, Dialogs, Math, Menus, uI18n, uUserPrefs;

function RangeHint(AMin, AMax, ADef: Integer): string;
begin
  Result := Format(TrText('Prefs.RangeDefault'), [AMin, AMax, ADef]);
end;

procedure TfrmUserPrefs.BuildUi;
const
  L = 16;
  W = 460;
  EDIT_W = 72;
begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 492;
  ClientHeight := 500;
  Font.Name := 'Tahoma';
  Font.Size := 8;
  Color := clBtnFace;

  FLblIntro := TLabel.Create(Self);
  FLblIntro.Parent := Self;
  FLblIntro.AutoSize := False;
  FLblIntro.WordWrap := True;
  FLblIntro.SetBounds(L, 12, W, 40);
  FLblIntro.Font.Color := clGrayText;

  FGrpMru := TGroupBox.Create(Self);
  FGrpMru.Parent := Self;
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
  FGrpHints.Parent := Self;
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
  FGrpHistory.Parent := Self;
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
  FGrpDisplay.Parent := Self;
  FGrpDisplay.SetBounds(L, 456, W, 66);

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

  FBtnReset := TButton.Create(Self);
  FBtnReset.Parent := Self;
  FBtnReset.SetBounds(L, 458, 120, 25);
  FBtnReset.OnClick := btnResetClick;

  FBtnOK := TButton.Create(Self);
  FBtnOK.Parent := Self;
  FBtnOK.SetBounds(296, 458, 88, 25);
  FBtnOK.Default := True;
  FBtnOK.OnClick := btnOKClick;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(392, 458, 88, 25);
  FBtnCancel.Cancel := True;
  FBtnCancel.OnClick := btnCancelClick;
end;

procedure TfrmUserPrefs.LayoutAfterI18n;
const
  L = 16;
  MIN_W = 460;
  MIN_LBL_W = 286;
  EDIT_W = 72;
  GAP = 10;
  BTN_H = 25;
  BTN_GAP = 12;
  MIN_BTN_W = 88;
  BTN_PAD = 24;
var
  IntroH, Y, NeedH, W, LblW, HintW, EditLeft, ResetW, OkW, CancelW, I, G: Integer;
  R: TRect;
  Groups: array[0..3] of TGroupBox;
  C: TControl;
begin
  Canvas.Font := Font;
  Groups[0] := FGrpMru;
  Groups[1] := FGrpHints;
  Groups[2] := FGrpHistory;
  Groups[3] := FGrpDisplay;

  { Size columns/buttons from the translated captions (long in DE/PL/HU...). }
  LblW := MIN_LBL_W;
  HintW := 0;
  for G := 0 to High(Groups) do
    for I := 0 to Groups[G].ControlCount - 1 do
    begin
      C := Groups[G].Controls[I];
      if not (C is TLabel) then Continue;
      if TLabel(C).Font.Color = clGrayText then
        HintW := Max(HintW, Canvas.TextWidth(TLabel(C).Caption))
      else
        LblW := Max(LblW, Canvas.TextWidth(TLabel(C).Caption) + 8);
    end;
  EditLeft := 12 + LblW + 12;
  W := Max(MIN_W, Max(EditLeft + EDIT_W + 16, 12 + HintW + 16));

  ResetW := Max(120, Canvas.TextWidth(StripHotkey(FBtnReset.Caption)) + BTN_PAD);
  OkW := Max(MIN_BTN_W, Canvas.TextWidth(StripHotkey(FBtnOK.Caption)) + BTN_PAD);
  CancelW := Max(MIN_BTN_W, Canvas.TextWidth(StripHotkey(FBtnCancel.Caption)) + BTN_PAD);
  W := Max(W, ResetW + 8 + OkW + 8 + CancelW);

  ClientWidth := W + 2 * L;
  for G := 0 to High(Groups) do
    for I := 0 to Groups[G].ControlCount - 1 do
    begin
      C := Groups[G].Controls[I];
      if C is TEdit then
        C.Left := EditLeft
      else if C is TLabel then
      begin
        if TLabel(C).Font.Color = clGrayText then
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
  FGrpDisplay.SetBounds(L, Y, W, FGrpDisplay.Height);
  Y := FGrpDisplay.Top + FGrpDisplay.Height + BTN_GAP;
  FBtnReset.SetBounds(L, Y, ResetW, BTN_H);
  FBtnCancel.SetBounds(L + W - CancelW, Y, CancelW, BTN_H);
  FBtnOK.SetBounds(FBtnCancel.Left - 8 - OkW, Y, OkW, BTN_H);

  NeedH := Y + BTN_H + 12;
  if ClientHeight < NeedH then
    ClientHeight := NeedH
  else if ClientHeight > NeedH + 8 then
    ClientHeight := NeedH;
end;

procedure TfrmUserPrefs.ApplyI18n;
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
  if (V.DefaultUIScalePPI > 0) and (V.DefaultUIScalePPI < MIN_UI_SCALE_PPI) then
  begin
    MessageDlg(Format(TrText('Prefs.OutOfRange'),
      [TrText('Prefs.DefaultUIScalePPI'), MIN_UI_SCALE_PPI, MAX_UI_SCALE_PPI]), mtError, [mbOK], 0);
    if FEdtUIScale.CanFocus then FEdtUIScale.SetFocus;
    Exit;
  end;
  SetUserPrefValues(V);
  Result := True;
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

class function TfrmUserPrefs.Execute: Boolean;
var
  Frm: TfrmUserPrefs;
begin
  Frm := TfrmUserPrefs.CreateNew(nil);
  try
    Frm.BuildUi;
    Frm.ApplyI18n;
    Frm.LoadFromPrefs;
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

end.
