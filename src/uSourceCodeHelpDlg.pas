unit uSourceCodeHelpDlg;

{
  "Source code: learn more" — what the AI can generate, which languages are validated (and with
  which tool), the fix-with-AI loop, where each feature lives on screen, which compilers this PC has
  and what is not supported. Opened from the Assistant (button </>, file-formats "?", failed
  validation) and from the "What can I do?" list (Assistant and AI agent).
  Texts: SrcHelp.* in uI18n; each item is "title|description|example" (example optional).
}

interface

{ True when the user chose "Use example": AExample goes to the caller's prompt box. }
function ShowSourceCodeHelp(out AExample: string): Boolean;
{ The whole help as plain text (Copy button, and for asking the AI about it). }
function SourceCodeHelpText: string;

implementation

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls, ExtCtrls, Clipbrd, Math,
  uI18n, uFastFileScale, uSourceValidators;

type
  TRowKind = (rkSection, rkItem);

  THelpRow = record
    Kind: TRowKind;
    Title: string;
    Desc: string;
    Example: string;
    { rkItem of the "on this computer" section: 1 = available, 0 = missing, -1 = n/a. }
    State: Integer;
  end;

const
  SECTIONS: array[0..5] of string = ('SrcHelp.Sec.Where', 'SrcHelp.Sec.Generate', 'SrcHelp.Sec.Validate',
    'SrcHelp.Sec.Fix', 'SrcHelp.Sec.Status', 'SrcHelp.Sec.Limits');
  SEC_STATUS = 4;
  WHERE_ITEMS: array[0..2] of string = ('SrcHelp.Where.Assistant', 'SrcHelp.Where.Agent',
    'SrcHelp.Where.Card');
  GEN_ITEMS: array[0..10] of string = ('SrcHelp.Gen.Js', 'SrcHelp.Gen.Ts', 'SrcHelp.Gen.React',
    'SrcHelp.Gen.Py', 'SrcHelp.Gen.Java', 'SrcHelp.Gen.Cs', 'SrcHelp.Gen.Go', 'SrcHelp.Gen.Pas',
    'SrcHelp.Gen.Other', 'SrcHelp.Gen.Data', 'SrcHelp.Gen.Docs');
  VAL_ITEMS: array[0..6] of string = ('SrcHelp.Val.How', 'SrcHelp.Val.Py', 'SrcHelp.Val.Js',
    'SrcHelp.Val.Native', 'SrcHelp.Val.Java', 'SrcHelp.Val.Go', 'SrcHelp.Val.Cs');
  FIX_ITEMS: array[0..1] of string = ('SrcHelp.Fix.Auto', 'SrcHelp.Fix.Manual');
  LIM_ITEMS: array[0..2] of string = ('SrcHelp.Lim.NoRun', 'SrcHelp.Lim.NotValidated',
    'SrcHelp.Lim.SingleFile');

  CTitle = TColor($00283038);
  CMuted = TColor($00606870);
  CAccent = TColor($00D77800);
  CHeadBg = TColor($00F8F0E8);
  CSelBg = TColor($00FBE6D2);
  COk = TColor($00327D2E);
  CMissing = TColor($002F2FC6);
  CRowPad = 12;

type
  TSourceHelpForm = class(TForm)
  private
    FUiFont: string;
    FList: TListBox;
    FBtnUse: TButton;
    FBtnCopy: TButton;
    FFlashTimer: TTimer;
    FRows: TArray<THelpRow>;
    FExample: string;
    procedure Build;
    procedure ListMeasure(Control: TWinControl; Index: Integer; var Height: Integer);
    procedure ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure ListClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure UseClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure FlashTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    function TextH(const S: string; AWidth: Integer; AStyle: TFontStyles; ASize: Integer): Integer;
    function MakeButton(AParent: TWinControl; const ACaption, AHint: string; AMinW: Integer): TButton;
    procedure UpdateUseButton;
    function SelectedRow(out ARow: THelpRow): Boolean;
  public
    constructor CreateHelp; reintroduce;
  end;

procedure SplitHelpItem(const AKey: string; out ATitle, ADesc, AExample: string);
var
  S: string;
  P: Integer;
begin
  S := TrText(AKey);
  ATitle := '';
  ADesc := S;
  AExample := '';
  P := Pos('|', S);
  if P = 0 then Exit;
  ATitle := Trim(Copy(S, 1, P - 1));
  S := Copy(S, P + 1, MaxInt);
  P := Pos('|', S);
  if P = 0 then
    ADesc := Trim(S)
  else
  begin
    ADesc := Trim(Copy(S, 1, P - 1));
    AExample := Trim(Copy(S, P + 1, MaxInt));
  end;
end;

function BuildRows: TArray<THelpRow>;
var
  L: TArray<THelpRow>;
  Sec: Integer;

  procedure AddRow(AKind: TRowKind; const ATitle, ADesc, AExample: string; AState: Integer);
  var
    R: THelpRow;
  begin
    R.Kind := AKind;
    R.Title := ATitle;
    R.Desc := ADesc;
    R.Example := AExample;
    R.State := AState;
    SetLength(L, Length(L) + 1);
    L[High(L)] := R;
  end;

  procedure AddItems(const AKeys: array of string);
  var
    I: Integer;
    T, D, E: string;
  begin
    for I := Low(AKeys) to High(AKeys) do
    begin
      SplitHelpItem(AKeys[I], T, D, E);
      AddRow(rkItem, T, D, E, -1);
    end;
  end;

  procedure AddToolStatus(AKind: TSourceToolKind);
  var
    Path, Desc: string;
  begin
    Path := FindSourceTool(AKind);
    if Path <> '' then
    begin
      Desc := Format(TrText('SrcHelp.Status.Found'), [Path]);
      if (AKind = stkCsc) and IsLegacyCsc(Path) then
        Desc := Desc + sLineBreak + TrText('SrcVal.Tool.LegacyCsc');
      AddRow(rkItem, SourceToolName(AKind), Desc, '', 1);
    end
    else
      AddRow(rkItem, SourceToolName(AKind), SourceToolMissingText(AKind), '', 0);
  end;

var
  T, D, E: string;
begin
  SetLength(L, 0);
  for Sec := 0 to High(SECTIONS) do
  begin
    AddRow(rkSection, TrText(SECTIONS[Sec]), '', '', -1);
    case Sec of
      0: AddItems(WHERE_ITEMS);
      1: AddItems(GEN_ITEMS);
      2: AddItems(VAL_ITEMS);
      3: AddItems(FIX_ITEMS);
      SEC_STATUS:
        begin
          SplitHelpItem('SrcHelp.Status.Native', T, D, E);
          AddRow(rkItem, T, D, '', 1);
          SplitHelpItem('SrcHelp.Status.Companions', T, D, E);
          AddRow(rkItem, T, D, '', 1);
          AddToolStatus(stkJavac);
          AddToolStatus(stkGofmt);
          AddToolStatus(stkCsc);
        end;
      5: AddItems(LIM_ITEMS);
    end;
  end;
  Result := L;
end;

function RowsAsText(const ARows: TArray<THelpRow>): string;
var
  SL: TStringList;
  R: THelpRow;
  Mark: string;
begin
  SL := TStringList.Create;
  try
    SL.Add(TrText('SrcHelp.Title'));
    SL.Add('');
    SL.Add(TrText('SrcHelp.Intro'));
    for R in ARows do
    begin
      if R.Kind = rkSection then
      begin
        SL.Add('');
        SL.Add('[' + R.Title + ']');
        Continue;
      end;
      case R.State of
        1: Mark := '[OK] ';
        0: Mark := '[--] ';
      else
        Mark := '';
      end;
      if R.Title <> '' then
        SL.Add('- ' + Mark + R.Title + ': ' + R.Desc)
      else
        SL.Add('- ' + Mark + R.Desc);
      if R.Example <> '' then
        SL.Add('  ' + TrText('AICaps.ExamplePrefix') + ' ' + R.Example);
    end;
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

function SourceCodeHelpText: string;
begin
  Result := RowsAsText(BuildRows);
end;

{ TSourceHelpForm }

constructor TSourceHelpForm.CreateHelp;
begin
  inherited CreateNew(Application);
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    FUiFont := 'Segoe UI'
  else
    FUiFont := 'Tahoma';
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poMainFormCenter;
  KeyPreview := True;
  Font.Name := FUiFont;
  Font.Size := 9;
  Color := clWindow;
  Caption := TrText('SrcHelp.Title');
  ClientWidth := FfPx(760);
  ClientHeight := FfPx(620);
  Constraints.MinWidth := FfPx(560);
  Constraints.MinHeight := FfPx(340);
  FFlashTimer := TTimer.Create(Self);
  FFlashTimer.Enabled := False;
  FFlashTimer.Interval := 1500;
  FFlashTimer.OnTimer := FlashTimer;
  FRows := BuildRows;
  Build;
  OnResize := FormResize;
end;

function TSourceHelpForm.MakeButton(AParent: TWinControl; const ACaption, AHint: string;
  AMinW: Integer): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Hint := AHint;
  Result.ShowHint := AHint <> '';
  Canvas.Font.Name := FUiFont;
  Canvas.Font.Size := 9;
  Result.Width := Max(FfPx(AMinW), Canvas.TextWidth(ACaption) + FfPx(28));
  Result.Height := FfPx(28);
  Result.Top := FfPx(10);
end;

procedure TSourceHelpForm.Build;
var
  Top, Bottom: TPanel;
  Title, Intro: TLabel;
  BtnClose: TButton;
  I: Integer;
begin
  Top := TPanel.Create(Self);
  Top.Parent := Self;
  Top.Align := alTop;
  Top.BevelOuter := bvNone;
  Top.ParentBackground := False;
  Top.Color := CHeadBg;
  Top.Caption := '';

  Title := TLabel.Create(Self);
  Title.Parent := Top;
  Title.ParentFont := False;
  Title.Font.Name := FUiFont;
  Title.Font.Size := 12;
  Title.Font.Style := [fsBold];
  Title.Font.Color := CTitle;
  Title.Caption := Caption;
  Title.SetBounds(FfPx(16), FfPx(12), FfPx(700), FfPx(24));

  Intro := TLabel.Create(Self);
  Intro.Parent := Top;
  Intro.ParentFont := False;
  Intro.Font.Name := FUiFont;
  Intro.Font.Size := 9;
  Intro.Font.Color := CMuted;
  Intro.WordWrap := True;
  Intro.AutoSize := False;
  Intro.Caption := TrText('SrcHelp.Intro');
  Intro.SetBounds(FfPx(16), FfPx(40), ClientWidth - FfPx(32), FfPx(52));
  Intro.Anchors := [akLeft, akTop, akRight];
  Top.Height := Intro.Top + Intro.Height + FfPx(8);

  Bottom := TPanel.Create(Self);
  Bottom.Parent := Self;
  Bottom.Align := alBottom;
  Bottom.BevelOuter := bvNone;
  Bottom.Caption := '';
  Bottom.Height := FfPx(48);

  FBtnCopy := MakeButton(Bottom, TrText('Agent.ToolCopy'), TrText('SrcHelp.CopyHint'), 80);
  FBtnCopy.Left := FfPx(16);
  FBtnCopy.OnClick := CopyClick;

  BtnClose := MakeButton(Bottom, TrText('Close'), '', 88);
  BtnClose.Cancel := True;
  BtnClose.ModalResult := mrCancel;
  BtnClose.Left := Bottom.Width - BtnClose.Width - FfPx(16);
  BtnClose.Anchors := [akTop, akRight];

  FBtnUse := MakeButton(Bottom, TrText('AICaps.UseExample'), TrText('SrcHelp.UseExampleHint'), 110);
  FBtnUse.Default := True;
  FBtnUse.Left := BtnClose.Left - FBtnUse.Width - FfPx(6);
  FBtnUse.Anchors := [akTop, akRight];
  FBtnUse.OnClick := UseClick;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.BorderStyle := bsNone;
  FList.Style := lbOwnerDrawVariable;
  FList.Font.Name := FUiFont;
  FList.Font.Size := 9;
  FList.OnMeasureItem := ListMeasure;
  FList.OnDrawItem := ListDraw;
  FList.OnClick := ListClick;
  FList.OnDblClick := ListDblClick;
  FList.Items.BeginUpdate;
  try
    for I := 0 to High(FRows) do
      FList.Items.Add('');
  finally
    FList.Items.EndUpdate;
  end;
  UpdateUseButton;
  ActiveControl := FList;
end;

function TSourceHelpForm.SelectedRow(out ARow: THelpRow): Boolean;
var
  I: Integer;
begin
  I := FList.ItemIndex;
  Result := (I >= 0) and (I <= High(FRows));
  if Result then
    ARow := FRows[I];
end;

function TSourceHelpForm.TextH(const S: string; AWidth: Integer; AStyle: TFontStyles;
  ASize: Integer): Integer;
var
  R: TRect;
begin
  FList.Canvas.Font.Name := FUiFont;
  FList.Canvas.Font.Size := ASize;
  FList.Canvas.Font.Style := AStyle;
  R := Rect(0, 0, Max(40, AWidth), 0);
  DrawText(FList.Canvas.Handle, PChar(S), Length(S), R, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  Result := R.Bottom - R.Top;
end;

procedure TSourceHelpForm.ListMeasure(Control: TWinControl; Index: Integer; var Height: Integer);
var
  W: Integer;
  R: THelpRow;
begin
  if (Index < 0) or (Index > High(FRows)) then
  begin
    Height := FfPx(20);
    Exit;
  end;
  R := FRows[Index];
  W := FList.ClientWidth - FfPx(CRowPad * 2) - FfPx(16);
  if R.Kind = rkSection then
    Height := FfPx(14) + TextH(R.Title, W, [fsBold], 10) + FfPx(8)
  else
  begin
    Height := FfPx(8);
    if R.Title <> '' then
      Inc(Height, TextH(R.Title, W, [fsBold], 9) + FfPx(2));
    Inc(Height, TextH(R.Desc, W, [], 9));
    if R.Example <> '' then
      Inc(Height, FfPx(3) + TextH(TrText('AICaps.ExamplePrefix') + ' ' + R.Example, W, [fsItalic], 9));
    Inc(Height, FfPx(8));
  end;
  Height := Min(Height, 255);
end;

procedure TSourceHelpForm.ListDraw(Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var
  C: TCanvas;
  X, Y: Integer;
  R: THelpRow;
  S, Bullet: string;
  TR: TRect;
begin
  if (Index < 0) or (Index > High(FRows)) then Exit;
  C := FList.Canvas;
  R := FRows[Index];
  X := Rect.Left + FfPx(CRowPad);
  C.Font.Name := FUiFont;
  if R.Kind = rkSection then
  begin
    C.Brush.Color := CHeadBg;
    C.FillRect(Rect);
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CAccent;
    TR := Classes.Rect(X, Rect.Top + FfPx(14), Rect.Right - FfPx(CRowPad), Rect.Bottom);
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(R.Title), Length(R.Title), TR, DT_WORDBREAK or DT_NOPREFIX);
    C.Brush.Style := bsSolid;
    Exit;
  end;
  if odSelected in State then
    C.Brush.Color := CSelBg
  else
    C.Brush.Color := clWindow;
  C.FillRect(Rect);
  C.Brush.Style := bsClear;
  C.Font.Size := 9;
  case R.State of
    1:
      begin
        Bullet := #$2714;
        C.Font.Color := COk;
      end;
    0:
      begin
        Bullet := #$2716;
        C.Font.Color := CMissing;
      end;
  else
    Bullet := #$2022;
    C.Font.Color := CTitle;
  end;
  C.Font.Style := [fsBold];
  C.TextOut(X, Rect.Top + FfPx(8), Bullet);
  Y := Rect.Top + FfPx(8);
  if R.Title <> '' then
  begin
    C.Font.Color := CTitle;
    TR := Classes.Rect(X + FfPx(16), Y, Rect.Right - FfPx(CRowPad), Rect.Bottom);
    DrawText(C.Handle, PChar(R.Title), Length(R.Title), TR, DT_WORDBREAK or DT_NOPREFIX or DT_CALCRECT);
    DrawText(C.Handle, PChar(R.Title), Length(R.Title), TR, DT_WORDBREAK or DT_NOPREFIX);
    Y := TR.Bottom + FfPx(2);
  end;
  C.Font.Style := [];
  if R.State = 0 then
    C.Font.Color := CMissing
  else
    C.Font.Color := CTitle;
  TR := Classes.Rect(X + FfPx(16), Y, Rect.Right - FfPx(CRowPad), Rect.Bottom);
  DrawText(C.Handle, PChar(R.Desc), Length(R.Desc), TR, DT_WORDBREAK or DT_NOPREFIX or DT_CALCRECT);
  DrawText(C.Handle, PChar(R.Desc), Length(R.Desc), TR, DT_WORDBREAK or DT_NOPREFIX);
  if R.Example <> '' then
  begin
    S := TrText('AICaps.ExamplePrefix') + ' ' + R.Example;
    C.Font.Style := [fsItalic];
    C.Font.Color := CMuted;
    TR := Classes.Rect(X + FfPx(16), TR.Bottom + FfPx(3), Rect.Right - FfPx(CRowPad), Rect.Bottom);
    DrawText(C.Handle, PChar(S), Length(S), TR, DT_WORDBREAK or DT_NOPREFIX);
  end;
  C.Brush.Style := bsSolid;
  if odFocused in State then
    C.DrawFocusRect(Rect);
end;

procedure TSourceHelpForm.UpdateUseButton;
var
  R: THelpRow;
begin
  FBtnUse.Enabled := SelectedRow(R) and (R.Kind = rkItem) and (R.Example <> '');
end;

procedure TSourceHelpForm.ListClick(Sender: TObject);
begin
  UpdateUseButton;
end;

procedure TSourceHelpForm.ListDblClick(Sender: TObject);
begin
  UseClick(nil);
end;

procedure TSourceHelpForm.UseClick(Sender: TObject);
var
  R: THelpRow;
begin
  if not SelectedRow(R) or (R.Example = '') then Exit;
  FExample := R.Example;
  ModalResult := mrOk;
end;

procedure TSourceHelpForm.CopyClick(Sender: TObject);
begin
  Clipboard.AsText := RowsAsText(FRows);
  FBtnCopy.Caption := TrText('AICaps.Copied');
  FFlashTimer.Enabled := False;
  FFlashTimer.Enabled := True;
end;

procedure TSourceHelpForm.FlashTimer(Sender: TObject);
begin
  FFlashTimer.Enabled := False;
  FBtnCopy.Caption := TrText('Agent.ToolCopy');
end;

procedure TSourceHelpForm.FormResize(Sender: TObject);
var
  I, Keep: Integer;
begin
  if not Assigned(FList) or not FList.HandleAllocated then Exit;
  { lbOwnerDrawVariable measures once per item: re-add so the wrapped heights follow the width. }
  Keep := FList.ItemIndex;
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to High(FRows) do
      FList.Items.Add('');
  finally
    FList.Items.EndUpdate;
  end;
  FList.ItemIndex := Keep;
end;

function ShowSourceCodeHelp(out AExample: string): Boolean;
var
  F: TSourceHelpForm;
begin
  AExample := '';
  F := TSourceHelpForm.CreateHelp;
  try
    Result := (F.ShowModal = mrOk) and (F.FExample <> '');
    if Result then
      AExample := F.FExample;
  finally
    F.Free;
  end;
end;

end.
