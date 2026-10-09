unit uHistLineDetailDlg;

{ Detalhe dos eventos do historico da sessao: linha inteira antes/depois,
  comparacao campo a campo e copia/exportacao (TXT / CSV / JSON) de um, varios
  ou todos os eventos listados. }

interface

uses
  Classes;

type
  THistDetailSpan = record
    Start0, Len: Integer;
  end;
  THistDetailSpans = array of THistDetailSpan;

  THistDetailItem = record
    Stamp: string;
    Op: string;           { rotulo ja' traduzido (EDT, INS, DEL, ...) }
    Line: Integer;
    Before, After: string;
    HasLines: Boolean;
    TruncLimit: Integer;  { > 0: o texto gravado no diario foi cortado neste limite }
    Summary: string;
    Selected: Boolean;    { pre-selecionado na lista de eventos }
    BeforeRuns, AfterRuns: THistDetailSpans;
  end;
  THistDetailItems = array of THistDetailItem;

procedure ShowHistLineDetailDialog(AOwner: TComponent; const ASourceFile: string;
  const AItems: THistDetailItems; AStartIndex: Integer);

implementation

uses
  Windows, Messages, SysUtils, Types, Controls, Forms, StdCtrls, ExtCtrls, ComCtrls,
  Graphics, Menus, Dialogs, Math, ClipBrd, uI18n, uFastFileScale, uFastFileMsgDlg, uExportDoneDlg;

type
  THistExportKind = (hekTxt, hekCsv, hekJson);
  THistScope = (hsCurrent, hsSelected, hsAll);

  THistDetailForm = class(TForm)
  private
    FItems: THistDetailItems;
    FSource: string;
    FCur: Integer;
    FDiffIdx: Integer;
    FLoading: Boolean;

    PnlHead, PnlBottom, PnlLines, PnlFieldsBar: TPanel;
    LblFile, LblEvents, LblEvent, LblStats, LblTrunc: TLabel;
    LbEvents: TListBox;
    Pages: TPageControl;
    TabLines, TabFields, TabSummary: TTabSheet;
    LblBefore, LblAfter, LblDelim, LblFieldsInfo, LblDiffPos: TLabel;
    MemoBefore, MemoAfter, MemoSummary: TMemo;
    CbDelim: TComboBox;
    ChkOnlyChanged, ChkWrap: TCheckBox;
    LvFields: TListView;
    BtnPrevDiff, BtnNextDiff, BtnCopy, BtnExport, BtnClose: TButton;
    PmCopy, PmExport, PmEvents, PmFields: TPopupMenu;

    function S(AValue: Integer): Integer;
    function TextW(const AText: string): Integer;
    function NewLabel(AParent: TWinControl; const ACaption: string): TLabel;
    function NewButton(AParent: TWinControl; const ACaption: string; AOnClick: TNotifyEvent): TButton;
    function AddMenu(AMenu: TPopupMenu; const ACaption: string; ATag: Integer;
      AOnClick: TNotifyEvent): TMenuItem;
    procedure BuildUi;
    procedure LayoutHead;
    procedure LayoutBottom;
    procedure LayoutFieldColumns;
    procedure ShowItem(AIndex: Integer);
    procedure ApplyWrap;
    procedure UpdateDiffPos;
    procedure GoDiff(ADir: Integer);
    procedure RefreshFields;
    function CurrentDelim: Char;
    function SelectedCount: Integer;
    function ScopeIndexes(AScope: THistScope): TArray<Integer>;
    function EventHead(const AItem: THistDetailItem): string;
    function EventBlock(const AItem: THistDetailItem): string;
    function BuildText(const AIdx: TArray<Integer>; AWithHeader: Boolean): string;
    function BuildCsv(const AIdx: TArray<Integer>): string;
    function BuildJson(const AIdx: TArray<Integer>): string;
    procedure ExportScope(AScope: THistScope);

    procedure FormResized(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LinesResized(Sender: TObject);
    procedure EventsClick(Sender: TObject);
    procedure EventsPopup(Sender: TObject);
    procedure EventsMenuClick(Sender: TObject);
    procedure WrapClick(Sender: TObject);
    procedure PrevDiffClick(Sender: TObject);
    procedure NextDiffClick(Sender: TObject);
    procedure CopyBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure CopyPopup(Sender: TObject);
    procedure ExportPopup(Sender: TObject);
    procedure CopyMenuClick(Sender: TObject);
    procedure ExportMenuClick(Sender: TObject);
    procedure FieldsOptionChanged(Sender: TObject);
    procedure FieldsMenuClick(Sender: TObject);
    procedure FieldsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure FieldsResized(Sender: TObject);
  public
    constructor CreateDlg(AOwner: TComponent; const ASourceFile: string;
      const AItems: THistDetailItems; AStartIndex: Integer);
  end;

var
  GWordWrap: Boolean = True;
  GOnlyChanged: Boolean = False;
  GDelimIndex: Integer = 0;

const
  DELIMS: array[1..4] of Char = (',', ';', #9, ' ');
  NL = #13#10;

{ ---------------------------------------------------------------------------- }
{ Utilitarios                                                                  }
{ ---------------------------------------------------------------------------- }

function DetectDelim(const S: string): Char;
var
  Cnt: array[1..3] of Integer;
  i, k, Best: Integer;
  InQ: Boolean;
begin
  Result := #0;
  FillChar(Cnt, SizeOf(Cnt), 0);
  InQ := False;
  for i := 1 to Length(S) do
  begin
    if S[i] = '"' then
      InQ := not InQ
    else if not InQ then
      for k := 1 to 3 do
        if S[i] = DELIMS[k] then
          Inc(Cnt[k]);
  end;
  Best := 0;
  for k := 1 to 3 do
    if (Cnt[k] > 0) and ((Best = 0) or (Cnt[k] > Cnt[Best])) then
      Best := k;
  if Best > 0 then
    Result := DELIMS[Best];
end;

procedure SplitFields(const S: string; D: Char; L: TStrings);
var
  i: Integer;
  Cur: string;
  InQ: Boolean;
begin
  L.Clear;
  if S = '' then Exit;
  if D = #0 then
  begin
    L.Add(S);
    Exit;
  end;
  Cur := '';
  InQ := False;
  for i := 1 to Length(S) do
  begin
    if S[i] = '"' then
      InQ := not InQ;
    if (S[i] = D) and not InQ then
    begin
      L.Add(Cur);
      Cur := '';
    end
    else
      Cur := Cur + S[i];
  end;
  L.Add(Cur);
end;

function CsvQ(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
end;

function JsonEsc(const S: string): string;
var
  i: Integer;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create(Length(S) + 8);
  try
    for i := 1 to Length(S) do
      case S[i] of
        '"': SB.Append('\"');
        '\': SB.Append('\\');
        #8: SB.Append('\b');
        #9: SB.Append('\t');
        #10: SB.Append('\n');
        #12: SB.Append('\f');
        #13: SB.Append('\r');
      else
        if S[i] < #32 then
          SB.Append('\u' + IntToHex(Ord(S[i]), 4))
        else
          SB.Append(S[i]);
      end;
    Result := '"' + SB.ToString + '"';
  finally
    SB.Free;
  end;
end;

procedure SaveUtf8(const APath, AText: string; ABom: Boolean);
var
  FS: TFileStream;
  B: TBytes;
begin
  FS := TFileStream.Create(APath, fmCreate);
  try
    if ABom then
    begin
      B := TEncoding.UTF8.GetPreamble;
      if Length(B) > 0 then
        FS.WriteBuffer(B[0], Length(B));
    end;
    B := TEncoding.UTF8.GetBytes(AText);
    if Length(B) > 0 then
      FS.WriteBuffer(B[0], Length(B));
  finally
    FS.Free;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ Formulario                                                                   }
{ ---------------------------------------------------------------------------- }

constructor THistDetailForm.CreateDlg(AOwner: TComponent; const ASourceFile: string;
  const AItems: THistDetailItems; AStartIndex: Integer);
var
  i: Integer;
begin
  inherited CreateNew(AOwner);
  FItems := AItems;
  FSource := ASourceFile;
  FCur := -1;
  BuildUi;
  FLoading := True;
  try
    for i := 0 to High(FItems) do
    begin
      LbEvents.Items.Add(Format('%d. %s', [i + 1, EventHead(FItems[i])]));
      LbEvents.Selected[i] := FItems[i].Selected;
    end;
    if (AStartIndex < 0) or (AStartIndex > High(FItems)) then
      AStartIndex := 0;
    LbEvents.Selected[AStartIndex] := True;
    LbEvents.ItemIndex := AStartIndex;
  finally
    FLoading := False;
  end;
  ShowItem(AStartIndex);
end;

function THistDetailForm.S(AValue: Integer): Integer;
begin
  Result := FfPx(AValue);
end;

function THistDetailForm.TextW(const AText: string): Integer;
begin
  Canvas.Font.Assign(Font);
  Result := Canvas.TextWidth(StripHotkey(AText));
end;

function THistDetailForm.NewLabel(AParent: TWinControl; const ACaption: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.AutoSize := False;
  Result.Caption := ACaption;
end;

function THistDetailForm.NewButton(AParent: TWinControl; const ACaption: string;
  AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.OnClick := AOnClick;
end;

function THistDetailForm.AddMenu(AMenu: TPopupMenu; const ACaption: string; ATag: Integer;
  AOnClick: TNotifyEvent): TMenuItem;
begin
  Result := TMenuItem.Create(AMenu);
  Result.Caption := ACaption;
  Result.Tag := ATag;
  Result.OnClick := AOnClick;
  AMenu.Items.Add(Result);
end;

procedure THistDetailForm.BuildUi;
var
  Col: TListColumn;
begin
  Caption := TrText('HistDetail.Title');
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poDesigned;
  KeyPreview := True;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  FfPrepareDialog(Self, 1000, 660);
  Constraints.MinWidth := S(680);
  Constraints.MinHeight := S(460);
  OnResize := FormResized;
  OnKeyDown := FormKeyDown;

  { --- cabecalho: ficheiro, lista de eventos, evento atual --- }
  PnlHead := TPanel.Create(Self);
  PnlHead.Parent := Self;
  PnlHead.Align := alTop;
  PnlHead.BevelOuter := bvNone;
  PnlHead.Height := S(120);

  LblFile := NewLabel(PnlHead, Format(TrText('HistDetail.File'), [FSource]));
  LblFile.EllipsisPosition := epPathEllipsis;
  LblFile.Font.Color := clGrayText;

  LblEvents := NewLabel(PnlHead, '');
  LbEvents := TListBox.Create(Self);
  LbEvents.Parent := PnlHead;
  LbEvents.MultiSelect := True;
  LbEvents.ExtendedSelect := True;
  LbEvents.Font.Name := 'Consolas';
  LbEvents.Font.Size := 9;
  LbEvents.Hint := TrText('HistDetail.EventsHint');
  LbEvents.ShowHint := True;
  LbEvents.OnClick := EventsClick;
  PmEvents := TPopupMenu.Create(Self);
  PmEvents.OnPopup := EventsPopup;
  LbEvents.PopupMenu := PmEvents;

  LblEvent := NewLabel(PnlHead, '');
  LblEvent.Font.Style := [fsBold];
  LblStats := NewLabel(PnlHead, '');
  LblTrunc := NewLabel(PnlHead, '');
  LblTrunc.Font.Color := clMaroon;

  { --- rodape --- }
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.BevelOuter := bvNone;
  PnlBottom.Height := S(48);

  ChkWrap := TCheckBox.Create(Self);
  ChkWrap.Parent := PnlBottom;
  ChkWrap.Caption := TrText('HistDetail.WordWrap');
  ChkWrap.Checked := GWordWrap;
  ChkWrap.OnClick := WrapClick;

  BtnPrevDiff := NewButton(PnlBottom, TrText('HistDetail.PrevChange'), PrevDiffClick);
  BtnPrevDiff.Hint := TrText('HistDetail.PrevChangeHint');
  BtnPrevDiff.ShowHint := True;
  BtnNextDiff := NewButton(PnlBottom, TrText('HistDetail.NextChange'), NextDiffClick);
  BtnNextDiff.Hint := TrText('HistDetail.NextChangeHint');
  BtnNextDiff.ShowHint := True;
  LblDiffPos := NewLabel(PnlBottom, '');
  LblDiffPos.Font.Color := clGrayText;

  BtnClose := NewButton(PnlBottom, TrText('Close'), nil);
  BtnClose.Cancel := True;
  BtnClose.ModalResult := mrCancel;
  BtnExport := NewButton(PnlBottom, TrText('HistDetail.Export') + ' '#$25BE, ExportBtnClick);
  BtnCopy := NewButton(PnlBottom, TrText('HistDetail.Copy') + ' '#$25BE, CopyBtnClick);
  PmCopy := TPopupMenu.Create(Self);
  PmCopy.OnPopup := CopyPopup;
  PmExport := TPopupMenu.Create(Self);
  PmExport.OnPopup := ExportPopup;

  { --- abas --- }
  Pages := TPageControl.Create(Self);
  Pages.Parent := Self;
  Pages.Align := alClient;
  Pages.AlignWithMargins := True;
  Pages.Margins.SetBounds(S(8), S(2), S(8), 0);

  TabLines := TTabSheet.Create(Self);
  TabLines.PageControl := Pages;
  TabLines.Caption := TrText('HistDetail.Tab.Lines');
  PnlLines := TPanel.Create(Self);
  PnlLines.Parent := TabLines;
  PnlLines.Align := alClient;
  PnlLines.BevelOuter := bvNone;
  PnlLines.OnResize := LinesResized;
  LblBefore := NewLabel(PnlLines, '');
  LblBefore.Font.Style := [fsBold];
  LblBefore.Font.Color := $00000099;
  MemoBefore := TMemo.Create(Self);
  MemoBefore.Parent := PnlLines;
  MemoBefore.ReadOnly := True;
  MemoBefore.HideSelection := False;
  MemoBefore.Font.Name := 'Consolas';
  MemoBefore.Font.Size := 10;
  MemoBefore.Color := $00F0F0FF;
  LblAfter := NewLabel(PnlLines, '');
  LblAfter.Font.Style := [fsBold];
  LblAfter.Font.Color := $00006400;
  MemoAfter := TMemo.Create(Self);
  MemoAfter.Parent := PnlLines;
  MemoAfter.ReadOnly := True;
  MemoAfter.HideSelection := False;
  MemoAfter.Font.Name := 'Consolas';
  MemoAfter.Font.Size := 10;
  MemoAfter.Color := $00EEF8EE;

  TabFields := TTabSheet.Create(Self);
  TabFields.PageControl := Pages;
  TabFields.Caption := TrText('HistDetail.Tab.Fields');
  PnlFieldsBar := TPanel.Create(Self);
  PnlFieldsBar.Parent := TabFields;
  PnlFieldsBar.Align := alTop;
  PnlFieldsBar.BevelOuter := bvNone;
  PnlFieldsBar.Height := S(34);
  LblDelim := NewLabel(PnlFieldsBar, TrText('HistDetail.Delimiter'));
  LblDelim.SetBounds(S(6), S(10), S(60), S(18));
  LblDelim.AutoSize := True;
  CbDelim := TComboBox.Create(Self);
  CbDelim.Parent := PnlFieldsBar;
  CbDelim.Style := csDropDownList;
  CbDelim.Items.Add(TrText('HistDetail.Delim.Auto'));
  CbDelim.Items.Add(TrText('HistDetail.Delim.Comma'));
  CbDelim.Items.Add(TrText('HistDetail.Delim.Semicolon'));
  CbDelim.Items.Add(TrText('HistDetail.Delim.Tab'));
  CbDelim.Items.Add(TrText('HistDetail.Delim.Space'));
  CbDelim.Items.Add(TrText('HistDetail.Delim.None'));
  CbDelim.ItemIndex := EnsureRange(GDelimIndex, 0, CbDelim.Items.Count - 1);
  CbDelim.SetBounds(LblDelim.Left + LblDelim.Width + S(6), S(6), S(180), S(22));
  CbDelim.OnChange := FieldsOptionChanged;
  ChkOnlyChanged := TCheckBox.Create(Self);
  ChkOnlyChanged.Parent := PnlFieldsBar;
  ChkOnlyChanged.Caption := TrText('HistDetail.OnlyChanged');
  ChkOnlyChanged.Checked := GOnlyChanged;
  ChkOnlyChanged.SetBounds(CbDelim.Left + CbDelim.Width + S(14), S(8),
    TextW(ChkOnlyChanged.Caption) + GetSystemMetrics(SM_CXMENUCHECK) + S(12), S(20));
  ChkOnlyChanged.OnClick := FieldsOptionChanged;
  LblFieldsInfo := NewLabel(PnlFieldsBar, '');
  LblFieldsInfo.Font.Color := clGrayText;
  LblFieldsInfo.Anchors := [akLeft, akTop, akRight];
  LblFieldsInfo.SetBounds(ChkOnlyChanged.Left + ChkOnlyChanged.Width + S(14), S(10),
    Max(S(80), PnlFieldsBar.Width - ChkOnlyChanged.Left - ChkOnlyChanged.Width - S(20)), S(18));
  LvFields := TListView.Create(Self);
  LvFields.Parent := TabFields;
  LvFields.Align := alClient;
  LvFields.ViewStyle := vsReport;
  LvFields.ReadOnly := True;
  LvFields.RowSelect := True;
  LvFields.MultiSelect := True;
  LvFields.HideSelection := False;
  LvFields.Font.Name := 'Consolas';
  LvFields.Font.Size := 9;
  LvFields.OnCustomDrawItem := FieldsCustomDrawItem;
  LvFields.OnResize := FieldsResized;
  Col := LvFields.Columns.Add;
  Col.Caption := TrText('HistDetail.Col.Field');
  Col.Alignment := taRightJustify;
  Col.Width := S(56);
  Col := LvFields.Columns.Add;
  Col.Caption := TrText('HistDetail.Col.Before');
  Col := LvFields.Columns.Add;
  Col.Caption := TrText('HistDetail.Col.After');
  PmFields := TPopupMenu.Create(Self);
  AddMenu(PmFields, TrText('HistDetail.Fields.CopyBefore'), 1, FieldsMenuClick);
  AddMenu(PmFields, TrText('HistDetail.Fields.CopyAfter'), 2, FieldsMenuClick);
  AddMenu(PmFields, TrText('HistDetail.Fields.CopyRows'), 3, FieldsMenuClick);
  LvFields.PopupMenu := PmFields;

  TabSummary := TTabSheet.Create(Self);
  TabSummary.PageControl := Pages;
  TabSummary.Caption := TrText('HistDetail.Tab.Summary');
  MemoSummary := TMemo.Create(Self);
  MemoSummary.Parent := TabSummary;
  MemoSummary.Align := alClient;
  MemoSummary.ReadOnly := True;
  MemoSummary.ScrollBars := ssBoth;
  MemoSummary.WordWrap := False;
  MemoSummary.Font.Name := 'Consolas';
  MemoSummary.Font.Size := 9;

  Pages.ActivePage := TabLines;
  ApplyWrap;
end;

procedure THistDetailForm.LayoutHead;
var
  Y, W, X: Integer;
begin
  X := S(10);
  W := Max(S(100), PnlHead.ClientWidth - S(20));
  Y := S(8);
  LblFile.SetBounds(X, Y, W, S(18));
  Inc(Y, S(22));
  LblEvents.Visible := Length(FItems) > 1;
  LbEvents.Visible := LblEvents.Visible;
  if LbEvents.Visible then
  begin
    LblEvents.SetBounds(X, Y, W, S(18));
    Inc(Y, S(19));
    LbEvents.SetBounds(X, Y, W, S(Min(110, 18 + 16 * Length(FItems))));
    Inc(Y, LbEvents.Height + S(8));
  end;
  LblEvent.SetBounds(X, Y, W, S(20));
  Inc(Y, S(22));
  LblStats.SetBounds(X, Y, W, S(18));
  Inc(Y, S(20));
  if LblTrunc.Visible then
  begin
    LblTrunc.SetBounds(X, Y, W, S(18));
    Inc(Y, S(20));
  end;
  if PnlHead.Height <> Y + S(2) then
    PnlHead.Height := Y + S(2);
end;

procedure THistDetailForm.LayoutBottom;
var
  X, W, Top: Integer;

  procedure PlaceRight(B: TButton; AMin: Integer);
  begin
    W := Max(S(AMin), TextW(B.Caption) + S(28));
    X := X - W;
    B.SetBounds(X, Top, W, S(28));
    X := X - S(8);
  end;

begin
  Top := S(10);
  ChkWrap.SetBounds(S(10), S(14), TextW(ChkWrap.Caption) + GetSystemMetrics(SM_CXMENUCHECK) + S(12), S(20));
  X := ChkWrap.Left + ChkWrap.Width + S(12);
  W := Max(S(90), TextW(BtnPrevDiff.Caption) + S(24));
  BtnPrevDiff.SetBounds(X, Top, W, S(28));
  X := X + W + S(6);
  W := Max(S(90), TextW(BtnNextDiff.Caption) + S(24));
  BtnNextDiff.SetBounds(X, Top, W, S(28));
  LblDiffPos.SetBounds(X + W + S(10), S(16), S(160), S(18));
  X := PnlBottom.ClientWidth - S(10);
  PlaceRight(BtnClose, 90);
  PlaceRight(BtnExport, 110);
  PlaceRight(BtnCopy, 100);
  LblDiffPos.Width := Max(S(40), BtnCopy.Left - LblDiffPos.Left - S(8));
end;

procedure THistDetailForm.LinesResized(Sender: TObject);
var
  W, H, LblH, Half, Y: Integer;
begin
  W := Max(S(60), PnlLines.ClientWidth - S(12));
  H := PnlLines.ClientHeight;
  LblH := S(20);
  Half := Max(S(40), (H - 2 * LblH - S(20)) div 2);
  LblBefore.SetBounds(S(6), S(6), W, LblH);
  MemoBefore.SetBounds(S(6), S(6) + LblH, W, Half);
  Y := MemoBefore.Top + Half + S(8);
  LblAfter.SetBounds(S(6), Y, W, LblH);
  MemoAfter.SetBounds(S(6), Y + LblH, W, Max(S(40), H - (Y + LblH) - S(6)));
end;

procedure THistDetailForm.LayoutFieldColumns;
var
  W: Integer;
begin
  if LvFields.Columns.Count < 3 then Exit;
  W := LvFields.ClientWidth - LvFields.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) - 4;
  if W < S(200) then W := S(200);
  LvFields.Columns[1].Width := W div 2;
  LvFields.Columns[2].Width := W - W div 2;
end;

procedure THistDetailForm.FormResized(Sender: TObject);
begin
  if not Assigned(PnlHead) then Exit;
  LayoutHead;
  LayoutBottom;
end;

procedure THistDetailForm.FieldsResized(Sender: TObject);
begin
  LayoutFieldColumns;
end;

procedure THistDetailForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F3 then
  begin
    if ssShift in Shift then
      GoDiff(-1)
    else
      GoDiff(1);
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key in [VK_PRIOR, VK_NEXT]) and (Length(FItems) > 1) then
  begin
    if Key = VK_PRIOR then
      LbEvents.ItemIndex := Max(0, FCur - 1)
    else
      LbEvents.ItemIndex := Min(High(FItems), FCur + 1);
    ShowItem(LbEvents.ItemIndex);
    Key := 0;
  end;
end;

function THistDetailForm.EventHead(const AItem: THistDetailItem): string;
begin
  if AItem.Line > 0 then
    Result := Format(TrText('HistDetail.EventHead'), [AItem.Stamp, AItem.Op, AItem.Line])
  else
    Result := Format(TrText('HistDetail.EventHeadNoLine'), [AItem.Stamp, AItem.Op]);
end;

procedure THistDetailForm.ShowItem(AIndex: Integer);
var
  It: THistDetailItem;
  D, nRuns: Integer;
  DS: string;
begin
  if (AIndex < 0) or (AIndex > High(FItems)) then Exit;
  FCur := AIndex;
  It := FItems[AIndex];
  if Length(FItems) > 1 then
    Caption := Format(TrText('HistDetail.TitleN'), [AIndex + 1, Length(FItems)])
  else
    Caption := TrText('HistDetail.Title');
  LblEvents.Caption := Format(TrText('HistDetail.EventsLabel'), [Length(FItems), SelectedCount]);
  LblEvent.Caption := EventHead(It);
  nRuns := Max(Length(It.BeforeRuns), Length(It.AfterRuns));
  if It.HasLines then
  begin
    D := Length(It.After) - Length(It.Before);
    if D > 0 then DS := '+' + IntToStr(D) else DS := IntToStr(D);
    LblStats.Caption := Format(TrText('HistDetail.Stats'),
      [Length(It.Before), Length(It.After), DS, nRuns]);
  end
  else
    LblStats.Caption := TrText('HistDetail.NoLines');
  LblTrunc.Visible := It.TruncLimit > 0;
  if LblTrunc.Visible then
    LblTrunc.Caption := Format(TrText('HistDetail.Truncated'), [It.TruncLimit]);

  LblBefore.Caption := Format(TrText('HistDetail.LineBefore'), [Length(It.Before)]);
  LblAfter.Caption := Format(TrText('HistDetail.LineAfter'), [Length(It.After)]);
  MemoBefore.Text := It.Before;
  MemoAfter.Text := It.After;
  MemoBefore.SelStart := 0;
  MemoAfter.SelStart := 0;
  MemoSummary.Text := It.Summary;
  TabLines.TabVisible := It.HasLines;
  TabFields.TabVisible := It.HasLines;
  if not It.HasLines then
    Pages.ActivePage := TabSummary
  else if Pages.ActivePage = TabSummary then
    Pages.ActivePage := TabLines;
  FDiffIdx := -1;
  BtnPrevDiff.Enabled := nRuns > 0;
  BtnNextDiff.Enabled := nRuns > 0;
  UpdateDiffPos;
  RefreshFields;
  LayoutHead;
end;

procedure THistDetailForm.ApplyWrap;
begin
  GWordWrap := ChkWrap.Checked;
  MemoBefore.WordWrap := GWordWrap;
  MemoAfter.WordWrap := GWordWrap;
  if GWordWrap then
  begin
    MemoBefore.ScrollBars := ssVertical;
    MemoAfter.ScrollBars := ssVertical;
  end
  else
  begin
    MemoBefore.ScrollBars := ssBoth;
    MemoAfter.ScrollBars := ssBoth;
  end;
end;

procedure THistDetailForm.WrapClick(Sender: TObject);
begin
  ApplyWrap;
end;

procedure THistDetailForm.UpdateDiffPos;
var
  n: Integer;
begin
  if FCur < 0 then Exit;
  n := Max(Length(FItems[FCur].BeforeRuns), Length(FItems[FCur].AfterRuns));
  if n = 0 then
    LblDiffPos.Caption := ''
  else if FDiffIdx < 0 then
    LblDiffPos.Caption := Format(TrText('HistDetail.ChangesCount'), [n])
  else
    LblDiffPos.Caption := Format(TrText('HistDetail.ChangePos'), [FDiffIdx + 1, n]);
end;

procedure THistDetailForm.GoDiff(ADir: Integer);
var
  n: Integer;

  procedure SelectRun(AMemo: TMemo; const ARuns: THistDetailSpans);
  begin
    if FDiffIdx > High(ARuns) then Exit;
    AMemo.SelStart := ARuns[FDiffIdx].Start0;
    AMemo.SelLength := ARuns[FDiffIdx].Len;
    AMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;

begin
  if FCur < 0 then Exit;
  n := Max(Length(FItems[FCur].BeforeRuns), Length(FItems[FCur].AfterRuns));
  if n = 0 then Exit;
  if FDiffIdx < 0 then
  begin
    if ADir > 0 then FDiffIdx := 0 else FDiffIdx := n - 1;
  end
  else
    FDiffIdx := (FDiffIdx + ADir + n) mod n;
  Pages.ActivePage := TabLines;
  SelectRun(MemoBefore, FItems[FCur].BeforeRuns);
  SelectRun(MemoAfter, FItems[FCur].AfterRuns);
  UpdateDiffPos;
end;

procedure THistDetailForm.PrevDiffClick(Sender: TObject);
begin
  GoDiff(-1);
end;

procedure THistDetailForm.NextDiffClick(Sender: TObject);
begin
  GoDiff(1);
end;

function THistDetailForm.CurrentDelim: Char;
begin
  case CbDelim.ItemIndex of
    1..4: Result := DELIMS[CbDelim.ItemIndex];
    5: Result := #0;
  else
    if FCur < 0 then
      Result := #0
    else
    begin
      Result := DetectDelim(FItems[FCur].Before);
      if Result = #0 then
        Result := DetectDelim(FItems[FCur].After);
    end;
  end;
end;

procedure THistDetailForm.RefreshFields;
var
  FB, FA: TStringList;
  i, n, nChanged: Integer;
  B, A: string;
  Changed: Boolean;
  Li: TListItem;
begin
  if FCur < 0 then Exit;
  FB := TStringList.Create;
  FA := TStringList.Create;
  LvFields.Items.BeginUpdate;
  try
    LvFields.Items.Clear;
    SplitFields(FItems[FCur].Before, CurrentDelim, FB);
    SplitFields(FItems[FCur].After, CurrentDelim, FA);
    n := Max(FB.Count, FA.Count);
    nChanged := 0;
    for i := 0 to n - 1 do
    begin
      if i < FB.Count then B := FB[i] else B := '';
      if i < FA.Count then A := FA[i] else A := '';
      Changed := (i >= FB.Count) or (i >= FA.Count) or (B <> A);
      if Changed then Inc(nChanged);
      if ChkOnlyChanged.Checked and not Changed then Continue;
      Li := LvFields.Items.Add;
      Li.Caption := IntToStr(i + 1);
      Li.SubItems.Add(B);
      Li.SubItems.Add(A);
      Li.Data := Pointer(NativeInt(Ord(Changed)));
    end;
    LblFieldsInfo.Caption := Format(TrText('HistDetail.FieldsInfo'), [n, nChanged]);
  finally
    LvFields.Items.EndUpdate;
    FA.Free;
    FB.Free;
  end;
  LayoutFieldColumns;
end;

procedure THistDetailForm.FieldsOptionChanged(Sender: TObject);
begin
  GDelimIndex := CbDelim.ItemIndex;
  GOnlyChanged := ChkOnlyChanged.Checked;
  RefreshFields;
end;

procedure THistDetailForm.FieldsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw := True;
  if NativeInt(Item.Data) <> 0 then
  begin
    Sender.Canvas.Font.Color := clRed;
    Sender.Canvas.Font.Style := [fsBold];
  end;
end;

procedure THistDetailForm.FieldsMenuClick(Sender: TObject);
var
  SL: TStringList;
  i: Integer;
  Li: TListItem;
begin
  SL := TStringList.Create;
  try
    for i := 0 to LvFields.Items.Count - 1 do
    begin
      Li := LvFields.Items[i];
      if not Li.Selected then Continue;
      case TMenuItem(Sender).Tag of
        1: SL.Add(Li.SubItems[0]);
        2: SL.Add(Li.SubItems[1]);
      else
        SL.Add(Li.Caption + #9 + Li.SubItems[0] + #9 + Li.SubItems[1]);
      end;
    end;
    if SL.Count > 0 then
      Clipboard.AsText := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

{ --- lista de eventos (multi-selecao) --- }

function THistDetailForm.SelectedCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to LbEvents.Items.Count - 1 do
    if LbEvents.Selected[i] then
      Inc(Result);
end;

procedure THistDetailForm.EventsClick(Sender: TObject);
begin
  if FLoading then Exit;
  if LbEvents.ItemIndex <> FCur then
    ShowItem(LbEvents.ItemIndex)
  else
    LblEvents.Caption := Format(TrText('HistDetail.EventsLabel'), [Length(FItems), SelectedCount]);
end;

procedure THistDetailForm.EventsPopup(Sender: TObject);
begin
  PmEvents.Items.Clear;
  AddMenu(PmEvents, TrText('HistDetail.SelectAll'), 1, EventsMenuClick);
  AddMenu(PmEvents, TrText('HistDetail.SelectNone'), 2, EventsMenuClick);
  AddMenu(PmEvents, '-', 0, nil);
  AddMenu(PmEvents, Format(TrText('HistDetail.ExportSelected'), [SelectedCount]), 3,
    EventsMenuClick).Enabled := SelectedCount > 0;
  AddMenu(PmEvents, Format(TrText('HistDetail.ExportAll'), [Length(FItems)]), 4, EventsMenuClick);
end;

procedure THistDetailForm.EventsMenuClick(Sender: TObject);
var
  i: Integer;
begin
  case TMenuItem(Sender).Tag of
    1, 2:
      begin
        for i := 0 to LbEvents.Items.Count - 1 do
          LbEvents.Selected[i] := TMenuItem(Sender).Tag = 1;
        if (TMenuItem(Sender).Tag = 2) and (FCur >= 0) then
          LbEvents.ItemIndex := FCur;
        LblEvents.Caption := Format(TrText('HistDetail.EventsLabel'), [Length(FItems), SelectedCount]);
      end;
    3: ExportScope(hsSelected);
    4: ExportScope(hsAll);
  end;
end;

function THistDetailForm.ScopeIndexes(AScope: THistScope): TArray<Integer>;
var
  i, n: Integer;
begin
  SetLength(Result, Length(FItems));
  n := 0;
  for i := 0 to High(FItems) do
    if (AScope = hsAll) or ((AScope = hsCurrent) and (i = FCur)) or
       ((AScope = hsSelected) and LbEvents.Selected[i]) then
    begin
      Result[n] := i;
      Inc(n);
    end;
  SetLength(Result, n);
end;

{ --- texto / CSV / JSON --- }

function THistDetailForm.EventBlock(const AItem: THistDetailItem): string;
begin
  Result := '=== ' + EventHead(AItem) + ' ===' + NL;
  if AItem.HasLines then
    Result := Result +
      Format(TrText('HistDetail.LineBefore'), [Length(AItem.Before)]) + NL + AItem.Before + NL +
      Format(TrText('HistDetail.LineAfter'), [Length(AItem.After)]) + NL + AItem.After + NL
  else
    Result := Result + AItem.Summary + NL;
  if AItem.TruncLimit > 0 then
    Result := Result + Format(TrText('HistDetail.Truncated'), [AItem.TruncLimit]) + NL;
end;

function THistDetailForm.BuildText(const AIdx: TArray<Integer>; AWithHeader: Boolean): string;
var
  SB: TStringBuilder;
  i: Integer;
begin
  SB := TStringBuilder.Create;
  try
    if AWithHeader then
    begin
      SB.Append(TrText('HistDetail.Title')).Append(NL);
      SB.Append(Format(TrText('HistDetail.File'), [FSource])).Append(NL);
      SB.Append(Format(TrText('HistDetail.Exported'),
        [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Length(AIdx)])).Append(NL).Append(NL);
    end;
    for i := 0 to High(AIdx) do
    begin
      if i > 0 then SB.Append(NL);
      SB.Append(EventBlock(FItems[AIdx[i]]));
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function THistDetailForm.BuildCsv(const AIdx: TArray<Integer>): string;
var
  SB: TStringBuilder;
  i: Integer;
  It: THistDetailItem;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(TrText('HistDetail.CsvHeader')).Append(NL);
    for i := 0 to High(AIdx) do
    begin
      It := FItems[AIdx[i]];
      SB.Append(CsvQ(It.Stamp)).Append(';').Append(CsvQ(It.Op)).Append(';')
        .Append(It.Line).Append(';').Append(CsvQ(It.Before)).Append(';')
        .Append(CsvQ(It.After)).Append(';').Append(Length(It.Before)).Append(';')
        .Append(Length(It.After)).Append(';');
      if It.HasLines then
        SB.Append('""')
      else
        SB.Append(CsvQ(StringReplace(It.Summary, NL, ' | ', [rfReplaceAll])));
      SB.Append(NL);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function THistDetailForm.BuildJson(const AIdx: TArray<Integer>): string;
const
  BoolS: array[Boolean] of string = ('false', 'true');
var
  SB: TStringBuilder;
  i: Integer;
  It: THistDetailItem;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('{').Append(NL);
    SB.Append('  "file": ').Append(JsonEsc(FSource)).Append(',').Append(NL);
    SB.Append('  "exported": ').Append(JsonEsc(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)))
      .Append(',').Append(NL);
    SB.Append('  "events": [').Append(NL);
    for i := 0 to High(AIdx) do
    begin
      It := FItems[AIdx[i]];
      SB.Append('    {').Append(NL);
      SB.Append('      "timestamp": ').Append(JsonEsc(It.Stamp)).Append(',').Append(NL);
      SB.Append('      "operation": ').Append(JsonEsc(It.Op)).Append(',').Append(NL);
      SB.Append('      "line": ').Append(It.Line).Append(',').Append(NL);
      if It.HasLines then
      begin
        SB.Append('      "before": ').Append(JsonEsc(It.Before)).Append(',').Append(NL);
        SB.Append('      "after": ').Append(JsonEsc(It.After)).Append(',').Append(NL);
        SB.Append('      "truncated": ').Append(BoolS[It.TruncLimit > 0]).Append(NL);
      end
      else
        SB.Append('      "summary": ').Append(JsonEsc(It.Summary)).Append(NL);
      SB.Append('    }');
      if i < High(AIdx) then SB.Append(',');
      SB.Append(NL);
    end;
    SB.Append('  ]').Append(NL).Append('}').Append(NL);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure THistDetailForm.ExportScope(AScope: THistScope);
var
  Idx: TArray<Integer>;
  Dlg: TSaveDialog;
  Path, Ext: string;
  Kind: THistExportKind;
begin
  Idx := ScopeIndexes(AScope);
  if Length(Idx) = 0 then
  begin
    FastFileMessageBox(TrText('Hist.ExportEmpty'), Caption, MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := TrText('HistDetail.ExportFilter');
    Dlg.FilterIndex := 1;
    Dlg.DefaultExt := 'txt';
    if (Length(Idx) = 1) and (FItems[Idx[0]].Line > 0) then
      Dlg.FileName := Format('history-line-%d', [FItems[Idx[0]].Line])
    else
      Dlg.FileName := 'history-events';
    Dlg.Options := [ofOverwritePrompt, ofPathMustExist];
    if not Dlg.Execute then Exit;
    Path := Dlg.FileName;
    Ext := LowerCase(ExtractFileExt(Path));
    if Ext = '.csv' then
      Kind := hekCsv
    else if Ext = '.json' then
      Kind := hekJson
    else if Ext = '.txt' then
      Kind := hekTxt
    else
      case Dlg.FilterIndex of
        2: Kind := hekCsv;
        3: Kind := hekJson;
      else
        Kind := hekTxt;
      end;
  finally
    Dlg.Free;
  end;
  try
    case Kind of
      hekCsv: SaveUtf8(Path, BuildCsv(Idx), True);
      hekJson: SaveUtf8(Path, BuildJson(Idx), False);
    else
      SaveUtf8(Path, BuildText(Idx, True), True);
    end;
  except
    on E: Exception do
    begin
      FastFileMessageBox(Format(TrText('HistDetail.ExportFailed'), [E.Message]), Caption,
        MB_OK or MB_ICONERROR);
      Exit;
    end;
  end;
  ShowGeneratedFileDialog(Path, Length(Idx));
end;

{ --- menus Copiar / Exportar --- }

procedure THistDetailForm.CopyBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  P := BtnCopy.ClientToScreen(Point(0, BtnCopy.Height));
  PmCopy.Popup(P.X, P.Y);
end;

procedure THistDetailForm.ExportBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  P := BtnExport.ClientToScreen(Point(0, BtnExport.Height));
  PmExport.Popup(P.X, P.Y);
end;

procedure THistDetailForm.CopyPopup(Sender: TObject);
var
  HasLines: Boolean;
begin
  PmCopy.Items.Clear;
  HasLines := (FCur >= 0) and FItems[FCur].HasLines;
  AddMenu(PmCopy, TrText('HistDetail.CopyBefore'), 1, CopyMenuClick).Enabled :=
    HasLines and (FItems[FCur].Before <> '');
  AddMenu(PmCopy, TrText('HistDetail.CopyAfter'), 2, CopyMenuClick).Enabled :=
    HasLines and (FItems[FCur].After <> '');
  AddMenu(PmCopy, TrText('HistDetail.CopyEvent'), 3, CopyMenuClick);
  if Length(FItems) > 1 then
  begin
    AddMenu(PmCopy, '-', 0, nil);
    AddMenu(PmCopy, Format(TrText('HistDetail.CopySelected'), [SelectedCount]), 4,
      CopyMenuClick).Enabled := SelectedCount > 0;
    AddMenu(PmCopy, Format(TrText('HistDetail.CopyAll'), [Length(FItems)]), 5, CopyMenuClick);
  end;
end;

procedure THistDetailForm.CopyMenuClick(Sender: TObject);
var
  T: string;
begin
  if FCur < 0 then Exit;
  case TMenuItem(Sender).Tag of
    1: T := FItems[FCur].Before;
    2: T := FItems[FCur].After;
    3: T := BuildText(ScopeIndexes(hsCurrent), False);
    4: T := BuildText(ScopeIndexes(hsSelected), False);
    5: T := BuildText(ScopeIndexes(hsAll), False);
  else
    T := '';
  end;
  if T <> '' then
    Clipboard.AsText := T;
end;

procedure THistDetailForm.ExportPopup(Sender: TObject);
begin
  PmExport.Items.Clear;
  AddMenu(PmExport, TrText('HistDetail.ExportCurrent'), 1, ExportMenuClick);
  if Length(FItems) > 1 then
  begin
    AddMenu(PmExport, Format(TrText('HistDetail.ExportSelected'), [SelectedCount]), 2,
      ExportMenuClick).Enabled := SelectedCount > 0;
    AddMenu(PmExport, Format(TrText('HistDetail.ExportAll'), [Length(FItems)]), 3, ExportMenuClick);
  end;
end;

procedure THistDetailForm.ExportMenuClick(Sender: TObject);
begin
  case TMenuItem(Sender).Tag of
    1: ExportScope(hsCurrent);
    2: ExportScope(hsSelected);
    3: ExportScope(hsAll);
  end;
end;

procedure ShowHistLineDetailDialog(AOwner: TComponent; const ASourceFile: string;
  const AItems: THistDetailItems; AStartIndex: Integer);
var
  F: THistDetailForm;
begin
  if Length(AItems) = 0 then Exit;
  F := THistDetailForm.CreateDlg(AOwner, ASourceFile, AItems, AStartIndex);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
