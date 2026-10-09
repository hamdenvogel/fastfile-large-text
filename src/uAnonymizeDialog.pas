unit uAnonymizeDialog;

{ Dialogo de descaracterizacao (escopo, opcoes, pre-visualizacao ao vivo) e
  thread que executa aplicar / desfazer / refazer com o overlay de progresso. }

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, StdCtrls, ExtCtrls,
  ComCtrls, Graphics, Math, uAnonymize;

type
  TAnonScope = (ascSelection, ascWholeFile, ascLineRange);

  TAnonSample = record
    LineNo: Int64;      { 1-based }
    AbsOffset: Int64;   { 0-based, inicio da linha no ficheiro }
    Raw: AnsiString;    { bytes da linha (a quebra final e removida pelo dialogo) }
    Truncated: Boolean;
  end;
  TAnonSamples = array of TAnonSample;

  TAnonSampleProvider = function(AScope: TAnonScope; AFromLine, AToLine: Int64;
    out ASamples: TAnonSamples; out AScopeBytes: Int64): Boolean of object;

  TAnonDialogParams = record
    FileName: string;
    Encoding: string;
    FileSize: Int64;
    SelectedCount: Integer;
    TotalLines: Int64;
    TotalLinesExact: Boolean;
    InitialScope: TAnonScope;
    CsvDelimiter: Char;
    CsvHasHeader: Boolean;
  end;

  TAnonDialogResult = record
    Scope: TAnonScope;
    FromLine, ToLine: Int64;
    Options: TAnonOptions;
    KeepUndo: Boolean;
    ScopeBytes: Int64;
    ChangedRatio: Double;
  end;

  TAnonJobDoneEvent = procedure(const AResult: TAnonJobResult) of object;

function ShowAnonymizeDialog(AOwner: TComponent; const AParams: TAnonDialogParams;
  AProvider: TAnonSampleProvider; out AResult: TAnonDialogResult): Boolean;

function AnonFormatBytes(AValue: Int64): string;

procedure AnonStartApply(const ATarget, AJournal: string; const AOptions: TAnonOptions;
  const AEncoding: string; const ARanges: TAnonRanges; AOnDone: TAnonJobDoneEvent);
procedure AnonStartSwap(AKind: TAnonJobKind; const ATarget, AJournal: string;
  AOnDone: TAnonJobDoneEvent);
function AnonJobRunning: Boolean;

implementation

uses
  Menus, uI18n, uTextEncoding, uFastFileScale, uSmoothLoading;

var
  GLastOptions: TAnonOptions;
  GLastValid: Boolean = False;
  GLastKeepUndo: Boolean = True;
  GJobRunning: Boolean = False;

function AnonFormatBytes(AValue: Int64): string;
const
  Keys: array[0..4] of string = ('DiskSpace.Unit.B', 'DiskSpace.Unit.KB',
    'DiskSpace.Unit.MB', 'DiskSpace.Unit.GB', 'DiskSpace.Unit.TB');
  Defaults: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  V: Double;
  I: Integer;
  U: string;
begin
  V := AValue;
  I := 0;
  while (V >= 1024) and (I < 4) do
  begin
    V := V / 1024;
    Inc(I);
  end;
  U := TrText(Keys[I]);
  if (U = '') or (U = Keys[I]) then
    U := Defaults[I];
  if I = 0 then
    Result := Format('%d %s', [AValue, U])
  else
    Result := Format('%.1f %s', [V, U]);
end;

function FormatLineCount(N: Int64): string;
begin
  Result := FormatFloat('#,##0', N);
end;

function StripEol(const ARaw: AnsiString; AUnit: Integer): AnsiString;
var
  L: Integer;

  { UTF-16/32 LE ou BE: um unico byte CR/LF e os restantes zero }
  function UnitIsEol(APos: Integer): Boolean;
  var
    K: Integer;
    V: Byte;
  begin
    Result := False;
    V := 0;
    for K := 0 to AUnit - 1 do
      if ARaw[APos + K] <> #0 then
      begin
        if V <> 0 then Exit;
        V := Ord(ARaw[APos + K]);
      end;
    Result := (V = 10) or (V = 13);
  end;

begin
  L := Length(ARaw);
  while (L >= AUnit) and UnitIsEol(L - AUnit + 1) do
    Dec(L, AUnit);
  Result := Copy(ARaw, 1, L);
end;

function BomLength(const ARaw: AnsiString): Integer;
begin
  Result := 0;
  if (Length(ARaw) >= 4) and (((ARaw[1] = #$FF) and (ARaw[2] = #$FE) and (ARaw[3] = #0) and (ARaw[4] = #0)) or
     ((ARaw[1] = #0) and (ARaw[2] = #0) and (ARaw[3] = #$FE) and (ARaw[4] = #$FF))) then
    Result := 4
  else if (Length(ARaw) >= 3) and (ARaw[1] = #$EF) and (ARaw[2] = #$BB) and (ARaw[3] = #$BF) then
    Result := 3
  else if (Length(ARaw) >= 2) and (((ARaw[1] = #$FF) and (ARaw[2] = #$FE)) or
     ((ARaw[1] = #$FE) and (ARaw[2] = #$FF))) then
    Result := 2;
end;

function DisplayOf(const ARaw: AnsiString; const AEnc: string): string;
var
  I: Integer;
begin
  Result := DisplayTextFromFileBytes(ARaw, AEnc);
  for I := 1 to Length(Result) do
    if Result[I] < ' ' then
      Result[I] := ' ';
end;

{ ---------------------------------------------------------------------------- }
{ Dialogo                                                                      }
{ ---------------------------------------------------------------------------- }

type
  TAnonRow = record
    LineNo: Int64;
    Orig, Anon: string;
    Changed, Truncated, Header: Boolean;
  end;

  TAnonDialogForm = class(TForm)
  private
    FParams: TAnonDialogParams;
    FProvider: TAnonSampleProvider;
    FSamples: TAnonSamples;
    FSamplesValid: Boolean;
    FSamplesOk: Boolean;
    FScopeBytes: Int64;
    FChangedRatio: Double;
    FRows: array of TAnonRow;
    FUpdating: Boolean;
    FTimer: TTimer;

    PnlTop, PnlBottom: TPanel;
    GrpScope, GrpWhat, GrpOpt: TGroupBox;
    RbSel, RbRange, RbFile: TRadioButton;
    EdFrom, EdTo: TEdit;
    LblDash: TLabel;
    ChkNumbers, ChkDates, ChkEmails, ChkCodes, ChkAllCaps: TCheckBox;
    LblMinDigits, LblWords: TLabel;
    EdMinDigits: TEdit;
    CbWords: TComboBox;
    ChkConsistent, ChkSkipHeader, ChkKeepUndo: TCheckBox;
    LblDelim, LblKeep, LblKey: TLabel;
    CbDelim: TComboBox;
    EdColumns, EdKeep, EdKey: TEdit;
    BtnNewKey: TButton;
    LblPreview: TLabel;
    LvPreview: TListView;
    MemoDetail: TMemo;
    LblInfo: TLabel;
    BtnRefresh, BtnApply, BtnCancel: TButton;

    function S(AValue: Integer): Integer;
    function NewLabel(AParent: TWinControl; X, Y: Integer; const ACaption: string): TLabel;
    function NewCheck(AParent: TWinControl; X, Y, W: Integer; const ACaption: string): TCheckBox;
    function NewEdit(AParent: TWinControl; X, Y, W: Integer): TEdit;
    function TextW(const AText: string): Integer;
    function CheckW(const ACaption: string): Integer;
    procedure LayoutGroups;
    procedure LayoutOptions;
    procedure BuildUi;
    procedure LoadState;
    function CurrentScope: TAnonScope;
    function ReadRange(out AFrom, ATo: Int64; out AError: string): Boolean;
    function ReadOptions(out AOpt: TAnonOptions; out AError: string): Boolean;
    procedure UpdateEnabled;
    procedure ScheduleRefresh;
    procedure RefreshPreview;
    procedure ShowRows;
    procedure LayoutColumns;
    function ConfirmText: string;

    procedure OptionChanged(Sender: TObject);
    procedure ScopeChanged(Sender: TObject);
    procedure TimerFired(Sender: TObject);
    procedure NewKeyClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure PreviewSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure PreviewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure FormResized(Sender: TObject);
    procedure FormShown(Sender: TObject);
  public
    ResultData: TAnonDialogResult;
    constructor CreateDlg(AOwner: TComponent; const AParams: TAnonDialogParams;
      AProvider: TAnonSampleProvider);
  end;

const
  DELIMS: array[0..4] of Char = (#0, ',', ';', #9, '|');

constructor TAnonDialogForm.CreateDlg(AOwner: TComponent; const AParams: TAnonDialogParams;
  AProvider: TAnonSampleProvider);
begin
  inherited CreateNew(AOwner);
  FParams := AParams;
  FProvider := AProvider;
  BuildUi;
  LoadState;
  UpdateEnabled;
end;

function TAnonDialogForm.S(AValue: Integer): Integer;
begin
  Result := FfPx(AValue);
end;

function TAnonDialogForm.NewLabel(AParent: TWinControl; X, Y: Integer; const ACaption: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Left := S(X);
  Result.Top := S(Y);
  Result.Caption := ACaption;
end;

function TAnonDialogForm.NewCheck(AParent: TWinControl; X, Y, W: Integer; const ACaption: string): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(S(X), S(Y), S(W), S(20));
  Result.Caption := ACaption;
  Result.OnClick := OptionChanged;
end;

function TAnonDialogForm.NewEdit(AParent: TWinControl; X, Y, W: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(S(X), S(Y), S(W), S(22));
  Result.OnChange := OptionChanged;
end;

function TAnonDialogForm.TextW(const AText: string): Integer;
begin
  Canvas.Font.Assign(Font);
  Result := Canvas.TextWidth(StripHotkey(AText));
end;

function TAnonDialogForm.CheckW(const ACaption: string): Integer;
begin
  Result := TextW(ACaption) + GetSystemMetrics(SM_CXMENUCHECK) + S(12);
end;

{ Sizes the two fixed-width groups and the form minimum from the translated captions. }
procedure TAnonDialogForm.LayoutGroups;
var
  W: Integer;
begin
  W := Max(Max(CheckW(RbSel.Caption), CheckW(RbRange.Caption)),
    CheckW(RbFile.Caption));
  GrpScope.Width := EnsureRange(W + S(24), S(280), S(380));
  RbSel.Width := GrpScope.ClientWidth - S(16);
  RbRange.Width := RbSel.Width;
  RbFile.Width := RbSel.Width;

  W := CheckW(ChkNumbers.Caption) + S(6) + TextW(LblMinDigits.Caption) + S(4) + EdMinDigits.Width;
  W := Max(W, CheckW(ChkDates.Caption));
  W := Max(W, CheckW(ChkEmails.Caption));
  W := Max(W, CheckW(ChkCodes.Caption));
  W := Max(W, CheckW(ChkAllCaps.Caption));
  W := Max(W, TextW(LblWords.Caption) + S(8) + S(170));
  GrpWhat.Width := EnsureRange(W + S(30), S(310), S(440));

  Constraints.MinWidth := Max(S(860), GrpScope.Width + GrpWhat.Width + S(400));
  if Width < Constraints.MinWidth then
    Width := Constraints.MinWidth;
end;

{ Places controls inside the groups after their labels, so long translations do not overlap. }
procedure TAnonDialogForm.LayoutOptions;
var
  CW, C, I, W: Integer;
begin
  CW := GrpWhat.ClientWidth;
  W := CheckW(ChkNumbers.Caption);
  ChkNumbers.Width := W;
  LblMinDigits.Left := ChkNumbers.Left + W + S(6);
  EdMinDigits.Left := LblMinDigits.Left + LblMinDigits.Width + S(4);
  ChkDates.Width := CW - S(16);
  ChkEmails.Width := CW - S(16);
  ChkCodes.Width := CW - S(16);
  ChkAllCaps.Width := CW - S(16);
  C := LblWords.Left + LblWords.Width + S(8);
  CbWords.Left := C;
  CbWords.Width := Max(S(120), CW - C - S(10));

  CW := GrpOpt.ClientWidth;
  ChkConsistent.Width := CW - S(16);
  ChkSkipHeader.Width := CW - S(16);
  ChkKeepUndo.Width := CW - S(16);
  C := LblDelim.Left + Max(Max(LblDelim.Width, LblKeep.Width), LblKey.Width) + S(8);
  W := 0;
  for I := 0 to CbDelim.Items.Count - 1 do
    W := Max(W, TextW(CbDelim.Items[I]));
  CbDelim.Left := C;
  CbDelim.Width := EnsureRange(W + GetSystemMetrics(SM_CXVSCROLL) + S(12), S(110), S(180));
  EdColumns.Left := CbDelim.Left + CbDelim.Width + S(6);
  EdColumns.Width := Max(S(60), CW - EdColumns.Left - S(10));
  EdKeep.Left := C;
  EdKeep.Width := Max(S(80), CW - C - S(10));
  BtnNewKey.Width := Max(S(80), TextW(BtnNewKey.Caption) + S(24));
  BtnNewKey.Left := CW - S(10) - BtnNewKey.Width;
  EdKey.Left := C;
  EdKey.Width := Max(S(80), BtnNewKey.Left - S(6) - C);
end;

procedure TAnonDialogForm.BuildUi;
var
  Col: TListColumn;
  Fn: string;
  W: Integer;
begin
  Caption := TrText('Anon.Title');
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poDesigned;
  KeyPreview := True;
  FfPrepareDialog(Self, 1040, 680);
  Constraints.MinWidth := S(860);
  Constraints.MinHeight := S(520);
  OnResize := FormResized;
  OnShow := FormShown;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 350;
  FTimer.OnTimer := TimerFired;

  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := S(222);
  PnlTop.BevelOuter := bvNone;
  PnlTop.Padding.SetBounds(S(8), S(6), S(8), S(0));

  { --- escopo --- }
  GrpScope := TGroupBox.Create(Self);
  GrpScope.Parent := PnlTop;
  GrpScope.Align := alLeft;
  GrpScope.Width := S(280);
  GrpScope.Caption := ' ' + TrText('Anon.Scope') + ' ';

  RbSel := TRadioButton.Create(Self);
  RbSel.Parent := GrpScope;
  RbSel.SetBounds(S(12), S(24), S(260), S(20));
  RbSel.Caption := Format(TrText('Anon.Scope.Selection'), [FParams.SelectedCount]);
  RbSel.OnClick := ScopeChanged;

  RbRange := TRadioButton.Create(Self);
  RbRange.Parent := GrpScope;
  RbRange.SetBounds(S(12), S(52), S(260), S(20));
  RbRange.Caption := TrText('Anon.Scope.Range');
  RbRange.OnClick := ScopeChanged;

  EdFrom := NewEdit(GrpScope, 32, 76, 100);
  EdFrom.OnChange := ScopeChanged;
  LblDash := NewLabel(GrpScope, 138, 79, '-');
  EdTo := NewEdit(GrpScope, 150, 76, 100);
  EdTo.OnChange := ScopeChanged;

  RbFile := TRadioButton.Create(Self);
  RbFile.Parent := GrpScope;
  RbFile.SetBounds(S(12), S(110), S(260), S(20));
  RbFile.Caption := Format(TrText('Anon.Scope.File'), [AnonFormatBytes(FParams.FileSize)]);
  RbFile.OnClick := ScopeChanged;

  with NewLabel(GrpScope, 12, 140, '') do
  begin
    AutoSize := False;
    WordWrap := True;
    SetBounds(S(12), S(140), S(258), S(70));
    Font.Color := clGrayText;
    if FParams.TotalLines > 0 then
    begin
      if FParams.TotalLinesExact then
        Fn := FormatLineCount(FParams.TotalLines)
      else
        Fn := '~' + FormatLineCount(FParams.TotalLines);
      Caption := Format(TrText('Anon.Scope.TotalLines'), [Fn]);
    end;
  end;

  { --- o que descaracterizar --- }
  GrpWhat := TGroupBox.Create(Self);
  GrpWhat.Parent := PnlTop;
  GrpWhat.Left := GrpScope.Left + GrpScope.Width + 1;
  GrpWhat.Align := alLeft;
  GrpWhat.Width := S(310);
  GrpWhat.AlignWithMargins := True;
  GrpWhat.Margins.SetBounds(S(8), 0, 0, 0);
  GrpWhat.Caption := ' ' + TrText('Anon.What') + ' ';

  ChkNumbers := NewCheck(GrpWhat, 12, 24, 170, TrText('Anon.Numbers'));
  LblMinDigits := NewLabel(GrpWhat, 186, 26, TrText('Anon.MinDigits'));
  EdMinDigits := NewEdit(GrpWhat, 262, 22, 36);
  EdMinDigits.NumbersOnly := True;
  EdMinDigits.MaxLength := 2;
  ChkDates := NewCheck(GrpWhat, 12, 50, 290, TrText('Anon.Dates'));
  ChkEmails := NewCheck(GrpWhat, 12, 76, 290, TrText('Anon.Emails'));
  ChkCodes := NewCheck(GrpWhat, 12, 102, 290, TrText('Anon.Codes'));
  LblWords := NewLabel(GrpWhat, 12, 136, TrText('Anon.Words'));
  CbWords := TComboBox.Create(Self);
  CbWords.Parent := GrpWhat;
  CbWords.Style := csDropDownList;
  CbWords.SetBounds(S(96), S(132), S(202), S(22));
  CbWords.Items.Add(TrText('Anon.Words.None'));
  CbWords.Items.Add(TrText('Anon.Words.Names'));
  CbWords.Items.Add(TrText('Anon.Words.All'));
  CbWords.OnChange := OptionChanged;
  ChkAllCaps := NewCheck(GrpWhat, 12, 164, 290, TrText('Anon.AllCaps'));

  { --- opcoes --- }
  GrpOpt := TGroupBox.Create(Self);
  GrpOpt.Parent := PnlTop;
  GrpOpt.Align := alClient;
  GrpOpt.AlignWithMargins := True;
  GrpOpt.Margins.SetBounds(S(8), 0, 0, 0);
  GrpOpt.Caption := ' ' + TrText('Anon.Options') + ' ';

  ChkConsistent := NewCheck(GrpOpt, 12, 22, 340, TrText('Anon.Consistent'));
  ChkSkipHeader := NewCheck(GrpOpt, 12, 46, 340, TrText('Anon.SkipHeader'));
  LblDelim := NewLabel(GrpOpt, 12, 76, TrText('Anon.Columns'));
  CbDelim := TComboBox.Create(Self);
  CbDelim.Parent := GrpOpt;
  CbDelim.Style := csDropDownList;
  CbDelim.SetBounds(S(100), S(72), S(110), S(22));
  CbDelim.Items.Add(TrText('Anon.Delimiter.None'));
  CbDelim.Items.Add(TrText('Anon.Delimiter.Comma'));
  CbDelim.Items.Add(TrText('Anon.Delimiter.Semicolon'));
  CbDelim.Items.Add(TrText('Anon.Delimiter.Tab'));
  CbDelim.Items.Add(TrText('Anon.Delimiter.Pipe'));
  CbDelim.OnChange := OptionChanged;
  EdColumns := NewEdit(GrpOpt, 216, 72, 120);
  EdColumns.TextHint := TrText('Anon.Columns.Hint');
  EdColumns.Hint := TrText('Anon.Columns.Hint');
  EdColumns.ShowHint := True;
  LblKeep := NewLabel(GrpOpt, 12, 106, TrText('Anon.KeepWords'));
  EdKeep := NewEdit(GrpOpt, 100, 102, 236);
  EdKeep.TextHint := TrText('Anon.KeepWords.Hint');
  EdKeep.Hint := TrText('Anon.KeepWords.Hint');
  EdKeep.ShowHint := True;
  LblKey := NewLabel(GrpOpt, 12, 136, TrText('Anon.Key'));
  EdKey := NewEdit(GrpOpt, 100, 132, 150);
  EdKey.Hint := TrText('Anon.Key.Hint');
  EdKey.ShowHint := True;
  BtnNewKey := TButton.Create(Self);
  BtnNewKey.Parent := GrpOpt;
  BtnNewKey.SetBounds(S(256), S(131), S(80), S(24));
  BtnNewKey.Caption := TrText('Anon.NewKey');
  BtnNewKey.OnClick := NewKeyClick;
  ChkKeepUndo := NewCheck(GrpOpt, 12, 166, 340, TrText('Anon.KeepUndo'));

  { --- rodape --- }
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := S(52);
  PnlBottom.BevelOuter := bvNone;

  BtnCancel := TButton.Create(Self);
  BtnCancel.Parent := PnlBottom;
  BtnCancel.Caption := TrText('Anon.Cancel');
  BtnCancel.Cancel := True;
  BtnCancel.ModalResult := mrCancel;
  BtnCancel.Anchors := [akTop, akRight];
  W := Max(S(100), TextW(BtnCancel.Caption) + S(28));
  BtnCancel.SetBounds(PnlBottom.Width - S(8) - W, S(12), W, S(28));

  BtnApply := TButton.Create(Self);
  BtnApply.Parent := PnlBottom;
  BtnApply.Caption := TrText('Anon.Apply');
  BtnApply.Default := True;
  BtnApply.Anchors := [akTop, akRight];
  W := Max(S(130), TextW(BtnApply.Caption) + S(28));
  BtnApply.SetBounds(BtnCancel.Left - S(8) - W, S(12), W, S(28));
  BtnApply.OnClick := ApplyClick;

  BtnRefresh := TButton.Create(Self);
  BtnRefresh.Parent := PnlBottom;
  BtnRefresh.Caption := TrText('Anon.Refresh');
  BtnRefresh.Anchors := [akTop, akRight];
  W := Max(S(110), TextW(BtnRefresh.Caption) + S(28));
  BtnRefresh.SetBounds(BtnApply.Left - S(8) - W, S(12), W, S(28));
  BtnRefresh.OnClick := RefreshClick;

  LblInfo := TLabel.Create(Self);
  LblInfo.Parent := PnlBottom;
  LblInfo.AutoSize := False;
  LblInfo.WordWrap := True;
  LblInfo.Layout := tlCenter;
  LblInfo.Anchors := [akLeft, akTop, akRight, akBottom];
  LblInfo.SetBounds(S(10), S(4), BtnRefresh.Left - S(20), S(44));

  { --- pre-visualizacao --- }
  MemoDetail := TMemo.Create(Self);
  MemoDetail.Parent := Self;
  MemoDetail.Align := alBottom;
  MemoDetail.AlignWithMargins := True;
  MemoDetail.Margins.SetBounds(S(8), S(4), S(8), 0);
  MemoDetail.Height := S(78);
  MemoDetail.ReadOnly := True;
  MemoDetail.ScrollBars := ssVertical;
  MemoDetail.Font.Name := 'Consolas';
  MemoDetail.Font.Size := 9;

  LblPreview := TLabel.Create(Self);
  LblPreview.Parent := Self;
  LblPreview.Top := PnlTop.Top + PnlTop.Height + 1;
  LblPreview.Align := alTop;
  LblPreview.AlignWithMargins := True;
  LblPreview.Margins.SetBounds(S(10), S(8), S(8), S(2));
  LblPreview.Caption := TrText('Anon.Preview');

  LvPreview := TListView.Create(Self);
  LvPreview.Parent := Self;
  LvPreview.Align := alClient;
  LvPreview.AlignWithMargins := True;
  LvPreview.Margins.SetBounds(S(8), 0, S(8), 0);
  LvPreview.ViewStyle := vsReport;
  LvPreview.ReadOnly := True;
  LvPreview.RowSelect := True;
  LvPreview.HideSelection := False;
  LvPreview.Font.Name := 'Consolas';
  LvPreview.Font.Size := 9;
  Col := LvPreview.Columns.Add;
  Col.Caption := TrText('Anon.Col.Line');
  Col.Alignment := taRightJustify;
  Col.Width := S(80);
  Col := LvPreview.Columns.Add;
  Col.Caption := TrText('Anon.Col.Original');
  Col := LvPreview.Columns.Add;
  Col.Caption := TrText('Anon.Col.Anonymized');
  LvPreview.OnSelectItem := PreviewSelect;
  LvPreview.OnCustomDrawItem := PreviewCustomDrawItem;
  LayoutGroups;
  LayoutOptions;
  LayoutColumns;
end;

procedure TAnonDialogForm.LoadState;
var
  O: TAnonOptions;
  I: Integer;
  D: Char;
begin
  FUpdating := True;
  try
    if GLastValid then
      O := GLastOptions
    else
      O := AnonDefaultOptions;
    ChkNumbers.Checked := O.Numbers;
    EdMinDigits.Text := IntToStr(O.MinDigits);
    ChkDates.Checked := O.Dates;
    ChkEmails.Checked := O.Emails;
    ChkCodes.Checked := O.Codes;
    CbWords.ItemIndex := Ord(O.TextMode);
    ChkAllCaps.Checked := O.AllCapsAsNames;
    ChkConsistent.Checked := O.Consistent;
    ChkSkipHeader.Checked := O.SkipHeader;
    D := O.Delimiter;
    if FParams.CsvDelimiter <> #0 then
    begin
      D := FParams.CsvDelimiter;
      ChkSkipHeader.Checked := FParams.CsvHasHeader;
    end;
    CbDelim.ItemIndex := 0;
    for I := Low(DELIMS) to High(DELIMS) do
      if DELIMS[I] = D then
        CbDelim.ItemIndex := I;
    EdColumns.Text := O.Columns;
    EdKeep.Text := O.KeepWords;
    EdKey.Text := AnonKeyToText(O.Key);
    ChkKeepUndo.Checked := GLastKeepUndo;

    EdFrom.Text := '1';
    if FParams.TotalLines > 0 then
      EdTo.Text := IntToStr(FParams.TotalLines)
    else
      EdTo.Text := '1';
    RbSel.Enabled := FParams.SelectedCount > 0;
    case FParams.InitialScope of
      ascSelection:
        if RbSel.Enabled then RbSel.Checked := True else RbFile.Checked := True;
      ascLineRange: RbRange.Checked := True;
    else
      RbFile.Checked := True;
    end;
  finally
    FUpdating := False;
  end;
end;

function TAnonDialogForm.CurrentScope: TAnonScope;
begin
  if RbSel.Checked then
    Result := ascSelection
  else if RbRange.Checked then
    Result := ascLineRange
  else
    Result := ascWholeFile;
end;

function TAnonDialogForm.ReadRange(out AFrom, ATo: Int64; out AError: string): Boolean;
begin
  AError := '';
  AFrom := StrToInt64Def(Trim(EdFrom.Text), 0);
  ATo := StrToInt64Def(Trim(EdTo.Text), 0);
  Result := (AFrom >= 1) and (ATo >= AFrom) and
    ((not FParams.TotalLinesExact) or (FParams.TotalLines <= 0) or (ATo <= FParams.TotalLines));
  if not Result then
    AError := Format(TrText('Anon.ErrRange'), [FormatLineCount(Max(FParams.TotalLines, 1))]);
end;

function TAnonDialogForm.ReadOptions(out AOpt: TAnonOptions; out AError: string): Boolean;
begin
  AError := '';
  AOpt := AnonDefaultOptions;
  AOpt.Numbers := ChkNumbers.Checked;
  AOpt.MinDigits := EnsureRange(StrToIntDef(EdMinDigits.Text, 1), 1, 99);
  AOpt.Dates := ChkDates.Checked;
  AOpt.Emails := ChkEmails.Checked;
  AOpt.Codes := ChkCodes.Checked;
  if CbWords.ItemIndex >= 0 then
    AOpt.TextMode := TAnonTextMode(CbWords.ItemIndex);
  AOpt.AllCapsAsNames := ChkAllCaps.Checked;
  AOpt.Consistent := ChkConsistent.Checked;
  AOpt.SkipHeader := ChkSkipHeader.Checked;
  if CbDelim.ItemIndex > 0 then
    AOpt.Delimiter := DELIMS[CbDelim.ItemIndex]
  else
    AOpt.Delimiter := #0;
  AOpt.Columns := Trim(EdColumns.Text);
  AOpt.KeepWords := EdKeep.Text;
  if Trim(EdKey.Text) <> '' then
    AOpt.Key := AnonKeyFromText(EdKey.Text);
  Result := True;
  if (AOpt.Delimiter <> #0) and (AOpt.Columns <> '') and not AnonColumnsValid(AOpt.Columns) then
  begin
    AError := TrText('Anon.ErrColumns');
    Result := False;
  end;
end;

procedure TAnonDialogForm.UpdateEnabled;
begin
  EdFrom.Enabled := RbRange.Checked;
  EdTo.Enabled := RbRange.Checked;
  EdMinDigits.Enabled := ChkNumbers.Checked;
  LblMinDigits.Enabled := ChkNumbers.Checked;
  ChkAllCaps.Enabled := CbWords.ItemIndex = Ord(atmNames);
  EdColumns.Enabled := CbDelim.ItemIndex > 0;
end;

procedure TAnonDialogForm.ScheduleRefresh;
begin
  if FUpdating then Exit;
  FTimer.Enabled := False;
  FTimer.Enabled := True;
end;

procedure TAnonDialogForm.OptionChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  UpdateEnabled;
  ScheduleRefresh;
end;

procedure TAnonDialogForm.ScopeChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  UpdateEnabled;
  FSamplesValid := False;
  ScheduleRefresh;
end;

procedure TAnonDialogForm.TimerFired(Sender: TObject);
begin
  FTimer.Enabled := False;
  RefreshPreview;
end;

procedure TAnonDialogForm.NewKeyClick(Sender: TObject);
begin
  EdKey.Text := AnonKeyToText(AnonNewRandomKey);
end;

procedure TAnonDialogForm.RefreshClick(Sender: TObject);
begin
  FSamplesValid := False;
  FTimer.Enabled := False;
  RefreshPreview;
  if BtnApply.Enabled then
    LblInfo.Caption := LblInfo.Caption + ' ' +
      Format(TrText('Anon.Refreshed'), [FormatDateTime('hh:nn:ss', Now)]);
end;

procedure TAnonDialogForm.RefreshPreview;
var
  Opt: TAnonOptions;
  Err: string;
  FromL, ToL: Int64;
  Engine: TAnonEngine;
  I, K, U, Bom, ChangedRows: Integer;
  Raw, Outp: AnsiString;
  Off: Int64;
  Changed: Boolean;
  SampleBytes, DiffBytes: Int64;
  OldCursor: TCursor;
  Est: Int64;
begin
  SetLength(FRows, 0);
  FChangedRatio := 0;
  BtnApply.Enabled := False;
  if not ReadOptions(Opt, Err) then
  begin
    LblInfo.Caption := Err;
    ShowRows;
    Exit;
  end;
  FromL := 0;
  ToL := 0;
  if (CurrentScope = ascLineRange) and not ReadRange(FromL, ToL, Err) then
  begin
    LblInfo.Caption := Err;
    ShowRows;
    Exit;
  end;
  if (CurrentScope = ascSelection) and (FParams.SelectedCount <= 0) then
  begin
    LblInfo.Caption := TrText('Anon.ErrNoSelection');
    ShowRows;
    Exit;
  end;

  if not FSamplesValid then
  begin
    OldCursor := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    try
      SetLength(FSamples, 0);
      FScopeBytes := 0;
      FSamplesOk := Assigned(FProvider) and FProvider(CurrentScope, FromL, ToL, FSamples, FScopeBytes);
    finally
      Screen.Cursor := OldCursor;
    end;
    FSamplesValid := True;
  end;
  if not FSamplesOk then
  begin
    LblInfo.Caption := TrText('Anon.ResolveFailed');
    ShowRows;
    Exit;
  end;

  Engine := TAnonEngine.Create(Opt, FParams.Encoding);
  try
    U := Engine.UnitSize;
    SetLength(FRows, Length(FSamples));
    ChangedRows := 0;
    SampleBytes := 0;
    DiffBytes := 0;
    for I := 0 to High(FSamples) do
    begin
      Raw := FSamples[I].Raw;
      Off := FSamples[I].AbsOffset;
      if U > 1 then
      begin
        K := Integer((U - Off mod U) mod U);
        if K > 0 then
        begin
          Delete(Raw, 1, K);
          Inc(Off, K);
        end;
        SetLength(Raw, (Length(Raw) div U) * U);
      end;
      Raw := StripEol(Raw, U);
      if Off = 0 then
      begin
        Bom := BomLength(Raw);
        if Bom > 0 then
        begin
          Delete(Raw, 1, Bom);
          Inc(Off, Bom);
        end;
      end;
      FRows[I].LineNo := FSamples[I].LineNo;
      FRows[I].Truncated := FSamples[I].Truncated;
      FRows[I].Header := Opt.SkipHeader and (FSamples[I].LineNo = 1);
      if FRows[I].Header then
      begin
        Outp := Raw;
        Changed := False;
      end
      else
        Outp := AnonPreviewBytes(Engine, Raw, Off, Changed);
      FRows[I].Orig := DisplayOf(Raw, FParams.Encoding);
      FRows[I].Anon := DisplayOf(Outp, FParams.Encoding);
      FRows[I].Changed := Changed;
      if Changed then
      begin
        Inc(ChangedRows);
        for K := 1 to Length(Raw) do
          if Raw[K] <> Outp[K] then
            Inc(DiffBytes);
      end;
      Inc(SampleBytes, Length(FSamples[I].Raw));
    end;
  finally
    Engine.Free;
  end;
  if SampleBytes > 0 then
    FChangedRatio := DiffBytes / SampleBytes;
  ShowRows;

  Est := AnonEstimateJournalBytes(FScopeBytes, FChangedRatio);
  if ChkKeepUndo.Checked then
    LblInfo.Caption := Format(TrText('Anon.Info'),
      [AnonFormatBytes(FScopeBytes), ChangedRows, Length(FRows), AnonFormatBytes(Est)])
  else
    LblInfo.Caption := Format(TrText('Anon.InfoNoUndo'),
      [AnonFormatBytes(FScopeBytes), ChangedRows, Length(FRows)]);
  BtnApply.Enabled := FScopeBytes > 0;
end;

procedure TAnonDialogForm.ShowRows;
var
  I: Integer;
  It: TListItem;
begin
  LvPreview.Items.BeginUpdate;
  try
    LvPreview.Items.Clear;
    for I := 0 to High(FRows) do
    begin
      It := LvPreview.Items.Add;
      It.Caption := IntToStr(FRows[I].LineNo);
      It.SubItems.Add(FRows[I].Orig);
      It.SubItems.Add(FRows[I].Anon);
      It.Data := Pointer(NativeInt(I));
    end;
  finally
    LvPreview.Items.EndUpdate;
  end;
  MemoDetail.Clear;
  if LvPreview.Items.Count > 0 then
    LvPreview.Items[0].Selected := True;
end;

procedure TAnonDialogForm.PreviewSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  I: Integer;
  T: string;
begin
  if (not Selected) or (Item = nil) then Exit;
  I := Integer(NativeInt(Item.Data));
  if (I < 0) or (I > High(FRows)) then Exit;
  T := '';
  if FRows[I].Truncated then
    T := ' ' + TrText('Anon.Truncated');
  MemoDetail.Lines.BeginUpdate;
  try
    MemoDetail.Clear;
    MemoDetail.Lines.Add(TrText('Anon.Detail.Original') + T);
    MemoDetail.Lines.Add(FRows[I].Orig);
    MemoDetail.Lines.Add(TrText('Anon.Detail.Anonymized'));
    MemoDetail.Lines.Add(FRows[I].Anon);
  finally
    MemoDetail.Lines.EndUpdate;
  end;
  MemoDetail.SelStart := 0;
end;

procedure TAnonDialogForm.PreviewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  I: Integer;
begin
  DefaultDraw := True;
  I := Integer(NativeInt(Item.Data));
  if (I >= 0) and (I <= High(FRows)) and (not FRows[I].Changed) then
    Sender.Canvas.Font.Color := clGrayText;
end;

procedure TAnonDialogForm.LayoutColumns;
var
  W: Integer;
begin
  if LvPreview.Columns.Count < 3 then Exit;
  W := LvPreview.ClientWidth - LvPreview.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) - 4;
  if W < S(200) then W := S(200);
  LvPreview.Columns[1].Width := W div 2;
  LvPreview.Columns[2].Width := W - W div 2;
end;

procedure TAnonDialogForm.FormResized(Sender: TObject);
begin
  if Assigned(LvPreview) then
  begin
    LayoutOptions;
    LayoutColumns;
  end;
end;

procedure TAnonDialogForm.FormShown(Sender: TObject);
begin
  LayoutOptions;
  LayoutColumns;
  RefreshPreview;
end;

function TAnonDialogForm.ConfirmText: string;
const
  NL = #13#10;
  MAX_SHOWN = 2;
  MAX_CHARS = 60;
var
  Desc, Sample: string;
  I, Shown: Integer;

  function Cut(const S: string): string;
  begin
    if Length(S) > MAX_CHARS then
      Result := Copy(S, 1, MAX_CHARS) + '...'
    else
      Result := S;
  end;

begin
  case CurrentScope of
    ascSelection: Desc := Format(TrText('Anon.Desc.Lines'), [FParams.SelectedCount]);
    ascLineRange: Desc := Format(TrText('Anon.Desc.Range'),
      [StrToInt64Def(Trim(EdFrom.Text), 0), StrToInt64Def(Trim(EdTo.Text), 0)]);
  else
    Desc := TrText('Anon.Desc.WholeFile');
  end;
  if ChkKeepUndo.Checked then
    Result := Format(TrText('Anon.ConfirmUndo'), [Desc, AnonFormatBytes(FScopeBytes)])
  else
    Result := Format(TrText('Anon.ConfirmNoUndo'), [Desc, AnonFormatBytes(FScopeBytes)]);
  Sample := '';
  Shown := 0;
  for I := 0 to High(FRows) do
    if FRows[I].Changed and (Shown < MAX_SHOWN) then
    begin
      Sample := Sample + NL + Format(TrText('Anon.ConfirmSample.Line'), [FRows[I].LineNo]) + NL +
        '  ' + Cut(FRows[I].Orig) + NL + '  → ' + Cut(FRows[I].Anon);
      Inc(Shown);
    end;
  if Sample <> '' then
    Result := Result + NL + NL + TrText('Anon.ConfirmSample') + Sample;
end;

procedure TAnonDialogForm.ApplyClick(Sender: TObject);
var
  Opt: TAnonOptions;
  Err: string;
  FromL, ToL: Int64;
begin
  if not ReadOptions(Opt, Err) then
  begin
    MessageBoxTrInfo(Err, Caption);
    Exit;
  end;
  FromL := 0;
  ToL := 0;
  if CurrentScope = ascLineRange then
    if not ReadRange(FromL, ToL, Err) then
    begin
      MessageBoxTrInfo(Err, Caption);
      Exit;
    end;
  if Trim(EdKey.Text) = '' then
  begin
    Opt.Key := AnonNewRandomKey;
    EdKey.Text := AnonKeyToText(Opt.Key);
  end;
  if FTimer.Enabled or not FSamplesValid then
  begin
    FTimer.Enabled := False;
    RefreshPreview;
  end;
  if not BtnApply.Enabled then Exit;
  if not MessageBoxTrYesNo(ConfirmText, Caption, ChkKeepUndo.Checked) then Exit;
  ResultData.Scope := CurrentScope;
  ResultData.FromLine := FromL;
  ResultData.ToLine := ToL;
  ResultData.Options := Opt;
  ResultData.KeepUndo := ChkKeepUndo.Checked;
  ResultData.ScopeBytes := FScopeBytes;
  ResultData.ChangedRatio := FChangedRatio;
  GLastOptions := Opt;
  GLastValid := True;
  GLastKeepUndo := ChkKeepUndo.Checked;
  ModalResult := mrOk;
end;

function ShowAnonymizeDialog(AOwner: TComponent; const AParams: TAnonDialogParams;
  AProvider: TAnonSampleProvider; out AResult: TAnonDialogResult): Boolean;
var
  F: TAnonDialogForm;
begin
  FillChar(AResult, SizeOf(AResult), 0);
  F := TAnonDialogForm.CreateDlg(AOwner, AParams, AProvider);
  try
    Result := F.ShowModal = mrOk;
    if Result then
      AResult := F.ResultData;
  finally
    F.Free;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ Thread de execucao                                                           }
{ ---------------------------------------------------------------------------- }

type
  TAnonJobThread = class(TThread)
  private
    FKind: TAnonJobKind;
    FTarget, FJournal, FEncoding: string;
    FOptions: TAnonOptions;
    FRanges: TAnonRanges;
    FOnDone: TAnonJobDoneEvent;
    FResult: TAnonJobResult;
    FStartTick: UInt64;
    FFmtDetail, FFmtEtaCalc, FTxtRevert: string;
    procedure Progress(ADone, ATotal: Int64; APhase: Integer);
    function CancelQuery: Boolean;
    procedure Finished(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor CreateJob(AKind: TAnonJobKind; const ATarget, AJournal: string;
      const AOptions: TAnonOptions; const AEncoding: string; const ARanges: TAnonRanges;
      AOnDone: TAnonJobDoneEvent);
  end;

function FormatEta(ASeconds: Int64): string;
begin
  if ASeconds >= 3600 then
    Result := Format('%d:%.2d:%.2d', [ASeconds div 3600, (ASeconds div 60) mod 60, ASeconds mod 60])
  else
    Result := Format('%d:%.2d', [ASeconds div 60, ASeconds mod 60]);
end;

constructor TAnonJobThread.CreateJob(AKind: TAnonJobKind; const ATarget, AJournal: string;
  const AOptions: TAnonOptions; const AEncoding: string; const ARanges: TAnonRanges;
  AOnDone: TAnonJobDoneEvent);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FKind := AKind;
  FTarget := ATarget;
  FJournal := AJournal;
  FOptions := AOptions;
  FEncoding := AEncoding;
  FRanges := Copy(ARanges);
  FOnDone := AOnDone;
  FFmtDetail := TrText('Anon.Progress.Detail');
  FFmtEtaCalc := TrText('Anon.Progress.EtaCalc');
  FTxtRevert := TrText('Anon.Progress.Revert');
  OnTerminate := Finished;
end;

procedure TAnonJobThread.Progress(ADone, ATotal: Int64; APhase: Integer);
var
  Pct: Integer;
  Elapsed: UInt64;
  Speed: Double;
  Eta, D: string;
begin
  if ATotal <= 0 then
    Pct := 0
  else
    Pct := Integer(EnsureRange((ADone * 100) div ATotal, 0, 100));
  Elapsed := GetTickCount64 - FStartTick;
  if (Elapsed > 500) and (ADone > 0) then
  begin
    Speed := ADone / (Elapsed / 1000);
    Eta := FormatEta(Round((ATotal - ADone) / Speed));
  end
  else
  begin
    Speed := 0;
    Eta := FFmtEtaCalc;
  end;
  D := Format(FFmtDetail, [AnonFormatBytes(ADone), AnonFormatBytes(ATotal),
    Speed / 1048576, Eta]);
  if APhase = 1 then
    D := FTxtRevert + ' ' + D;
  TfrmSmoothLoading.PostProgressWithDetailFromWorker(Pct, D);
end;

function TAnonJobThread.CancelQuery: Boolean;
begin
  Result := TfrmSmoothLoading.CancelRequested;
end;

procedure TAnonJobThread.Execute;
begin
  FStartTick := GetTickCount64;
  try
    if FKind = ajkApply then
      FResult := AnonApplyToFile(FTarget, FJournal, FOptions, FEncoding, FRanges,
        Progress, CancelQuery)
    else
      FResult := AnonSwapFile(FKind, FTarget, FJournal, Progress);
  except
    on E: Exception do
    begin
      FResult.Kind := FKind;
      FResult.Success := False;
      FResult.ErrorMsg := E.Message;
    end;
  end;
end;

procedure TAnonJobThread.Finished(Sender: TObject);
begin
  GJobRunning := False;
  TfrmSmoothLoading.HideLoading;
  TfrmSmoothLoading.ResetCancel;
  TfrmSmoothLoading.SetCancelVisible(True);
  if Assigned(FOnDone) then
    FOnDone(FResult);
end;

procedure StartJob(AKind: TAnonJobKind; const ATarget, AJournal: string;
  const AOptions: TAnonOptions; const AEncoding: string; const ARanges: TAnonRanges;
  AOnDone: TAnonJobDoneEvent);
var
  T: TAnonJobThread;
  Msg: string;
begin
  case AKind of
    ajkUndo: Msg := TrText('Anon.Progress.Undo');
    ajkRedo: Msg := TrText('Anon.Progress.Redo');
  else
    Msg := TrText('Anon.Progress.Apply');
  end;
  GJobRunning := True;
  TfrmSmoothLoading.ResetCancel;
  TfrmSmoothLoading.ShowLoading(Msg);
  { desfazer/refazer: a troca ficheiro<->jornal nao deve ficar a meio }
  TfrmSmoothLoading.SetCancelVisible(AKind = ajkApply);
  TfrmSmoothLoading.UpdateProgress(0);
  T := TAnonJobThread.CreateJob(AKind, ATarget, AJournal, AOptions, AEncoding, ARanges, AOnDone);
  T.Start;
end;

procedure AnonStartApply(const ATarget, AJournal: string; const AOptions: TAnonOptions;
  const AEncoding: string; const ARanges: TAnonRanges; AOnDone: TAnonJobDoneEvent);
begin
  StartJob(ajkApply, ATarget, AJournal, AOptions, AEncoding, ARanges, AOnDone);
end;

procedure AnonStartSwap(AKind: TAnonJobKind; const ATarget, AJournal: string;
  AOnDone: TAnonJobDoneEvent);
var
  NoRanges: TAnonRanges;
begin
  SetLength(NoRanges, 0);
  StartJob(AKind, ATarget, AJournal, AnonDefaultOptions, '', NoRanges, AOnDone);
end;

function AnonJobRunning: Boolean;
begin
  Result := GJobRunning;
end;

end.
