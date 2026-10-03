unit uDeltaEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ClipBrd, uPosBMH, uI18n;

type
  TfrmDeltaEditor = class(TForm)
    pnlTop: TPanel;
    lblHint: TLabel;
    lblLineNum: TLabel;
    lblContent: TLabel;
    edtLineNum: TEdit;
    edtContent: TEdit;
    btnAdd: TButton;
    lvDelta: TListView;
    pnlFooter: TPanel;
    Bevel1: TBevel;
    lblStatus: TLabel;
    btnDelete: TButton;
    btnConfirm: TButton;
    btnCancel: TButton;
    btnCopy: TButton;
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure lvDeltaSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvDeltaDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure edtLineNumKeyPress(Sender: TObject; var Key: Char);
    procedure edtContentKeyPress(Sender: TObject; var Key: Char);
  private
    FOnEscapeEmbedded: TNotifyEvent;
    function FindLineItem(LineNum: Int64): TListItem;
    procedure SetStatus(const Msg: string);
    procedure LayoutControls;
    procedure ApplyColumnCaptions;
    procedure WMFfLanguageChanged(var Msg: TMessage); message WM_FF_LANGUAGE_CHANGED;
  public
    property OnEscapeEmbedded: TNotifyEvent read FOnEscapeEmbedded write FOnEscapeEmbedded;
    function InsertSortedItem(LineNum: Int64): TListItem;
    procedure ApplyUiLanguage;
    function FlushDraftToList: Boolean;
    class function Execute(var AList: TStringList): Boolean;
  end;

var
  frmDeltaEditor: TfrmDeltaEditor;

implementation

uses
  Math, uFastFileMsgDlg;

{$R *.dfm}

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

{ TfrmDeltaEditor }

class function TfrmDeltaEditor.Execute(var AList: TStringList): Boolean;
var
  frm: TfrmDeltaEditor;
  i, P: Integer;
  item: TListItem;
begin
  Result := False;
  frm := TfrmDeltaEditor.Create(nil);
  try
    ApplyTranslationsToForm(frm);
    frm.ApplyUiLanguage;
    for i := 0 to AList.Count - 1 do
    begin
      P := PosBMH(': ', AList[i]);
      if P > 0 then
      begin
        item := frm.InsertSortedItem(StrToInt64Def(Trim(Copy(AList[i], 1, P - 1)), -1));
        if Assigned(item) then
          item.SubItems[0] := Copy(AList[i], P + 2, Length(AList[i]));
      end;
    end;

    if frm.ShowModal = mrOk then
    begin
      frm.FlushDraftToList;
      AList.Clear;
      for i := 0 to frm.lvDelta.Items.Count - 1 do
      begin
        if frm.lvDelta.Items[i].SubItems.Count > 0 then
          AList.Add(frm.lvDelta.Items[i].Caption + ': ' + frm.lvDelta.Items[i].SubItems[0]);
      end;
      Result := True;
    end;
  finally
    frm.Free;
  end;
end;

function TfrmDeltaEditor.FindLineItem(LineNum: Int64): TListItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to lvDelta.Items.Count - 1 do
  begin
    if StrToInt64Def(lvDelta.Items[i].Caption, -1) = LineNum then
    begin
      Result := lvDelta.Items[i];
      Break;
    end;
  end;
end;

function TfrmDeltaEditor.InsertSortedItem(LineNum: Int64): TListItem;
var
  i: Integer;
  Existing: Int64;
begin
  Result := FindLineItem(LineNum);
  if Assigned(Result) then Exit;
  if LineNum <= 0 then
  begin
    Result := nil;
    Exit;
  end;

  for i := 0 to lvDelta.Items.Count - 1 do
  begin
    Existing := StrToInt64Def(lvDelta.Items[i].Caption, High(Int64));
    if Existing > LineNum then
    begin
      Result := lvDelta.Items.Insert(i);
      Result.Caption := IntToStr(LineNum);
      Result.SubItems.Add('');
      Exit;
    end;
  end;
  Result := lvDelta.Items.Add;
  Result.Caption := IntToStr(LineNum);
  Result.SubItems.Add('');
end;

procedure TfrmDeltaEditor.SetStatus(const Msg: string);
begin
  if Assigned(lblStatus) then
    lblStatus.Caption := Msg;
end;

procedure TfrmDeltaEditor.ApplyColumnCaptions;
begin
  if not Assigned(lvDelta) or (lvDelta.Columns.Count < 2) then Exit;
  lvDelta.Columns[0].Caption := TrText('Line Number');
  lvDelta.Columns[1].Caption := TrText('Content');
end;

procedure TfrmDeltaEditor.WMFfLanguageChanged(var Msg: TMessage);
begin
  ApplyUiLanguage;
  SetStatus('');
end;

procedure TfrmDeltaEditor.ApplyUiLanguage;
var
  BtnW: Integer;
begin
  if Assigned(lblHint) then
    lblHint.Caption := TrText('DeltaEditor.Hint');
  if Assigned(lblLineNum) then
    lblLineNum.Caption := TrText('Line Number:');
  if Assigned(lblContent) then
    lblContent.Caption := TrText('Content:');
  if Assigned(btnAdd) then
    btnAdd.Caption := TrText('Add/Update');
  if Assigned(btnDelete) then
    btnDelete.Caption := TrText('Remove');
  if Assigned(btnCopy) then
    btnCopy.Caption := TrText('Copy');
  if Assigned(btnConfirm) then
    btnConfirm.Caption := TrText('Merge');
  if Assigned(btnCancel) then
    btnCancel.Caption := TrText('Cancel');
  Caption := TrText('Merge lines');
  ApplyColumnCaptions;

  if Assigned(Canvas) then
  begin
    Canvas.Font.Assign(Font);
    if Assigned(btnAdd) then
    begin
      BtnW := Max(104, Canvas.TextWidth(btnAdd.Caption) + 24);
      btnAdd.Width := BtnW;
    end;
    if Assigned(btnConfirm) then
      btnConfirm.Width := Max(75, Canvas.TextWidth(btnConfirm.Caption) + 24);
    if Assigned(btnCancel) then
      btnCancel.Width := Max(75, Canvas.TextWidth(btnCancel.Caption) + 24);
    if Assigned(btnCopy) then
      btnCopy.Width := Max(75, Canvas.TextWidth(btnCopy.Caption) + 20);
    if Assigned(btnDelete) then
      btnDelete.Width := Max(75, Canvas.TextWidth(btnDelete.Caption) + 20);
  end;
  LayoutControls;
end;

function TfrmDeltaEditor.FlushDraftToList: Boolean;
var
  LineNum: Int64;
  item: TListItem;
begin
  Result := False;
  if Trim(edtLineNum.Text) = '' then Exit;
  LineNum := StrToInt64Def(Trim(edtLineNum.Text), -1);
  if LineNum <= 0 then Exit;

  item := FindLineItem(LineNum);
  if not Assigned(item) then
    item := InsertSortedItem(LineNum);
  if not Assigned(item) then Exit;
  if item.SubItems.Count = 0 then
    item.SubItems.Add(edtContent.Text)
  else
    item.SubItems[0] := edtContent.Text;
  Result := True;
end;

procedure TfrmDeltaEditor.btnAddClick(Sender: TObject);
var
  LineNum: Int64;
  item: TListItem;
  WasUpdate: Boolean;
begin
  if Trim(edtLineNum.Text) = '' then
  begin
    ShowAppMessage('Please enter a valid line number.');
    edtLineNum.SetFocus;
    Exit;
  end;

  LineNum := StrToInt64Def(Trim(edtLineNum.Text), -1);
  if LineNum <= 0 then
  begin
    ShowAppMessage('Line number must be greater than 0.');
    edtLineNum.SetFocus;
    Exit;
  end;

  WasUpdate := Assigned(FindLineItem(LineNum));
  item := InsertSortedItem(LineNum);
  if not Assigned(item) then Exit;
  if item.SubItems.Count = 0 then
    item.SubItems.Add(edtContent.Text)
  else
    item.SubItems[0] := edtContent.Text;

  lvDelta.Selected := nil;
  item.Selected := True;
  item.MakeVisible(False);

  if WasUpdate then
    SetStatus(Format(TrText('DeltaEditor.Updated: %d'), [LineNum]))
  else
    SetStatus(Format(TrText('DeltaEditor.Added: %d'), [LineNum]));

  edtLineNum.Clear;
  edtContent.Clear;
  edtLineNum.SetFocus;
end;

procedure TfrmDeltaEditor.btnDeleteClick(Sender: TObject);
var
  i, Removed: Integer;
begin
  if lvDelta.SelCount = 0 then
  begin
    ShowAppMessage('Please select a line first.');
    Exit;
  end;

  Removed := 0;
  lvDelta.Items.BeginUpdate;
  try
    for i := lvDelta.Items.Count - 1 downto 0 do
      if lvDelta.Items[i].Selected then
      begin
        lvDelta.Items[i].Delete;
        Inc(Removed);
      end;
  finally
    lvDelta.Items.EndUpdate;
  end;
  SetStatus(Format(TrText('DeltaEditor.Removed: %d'), [Removed]));
  edtLineNum.Clear;
  edtContent.Clear;
end;

procedure TfrmDeltaEditor.btnCopyClick(Sender: TObject);
var
  i: Integer;
  SL: TStringList;
begin
  if lvDelta.SelCount = 0 then
  begin
    ShowAppMessage('Please select a line first.');
    Exit;
  end;

  SL := TStringList.Create;
  try
    for i := 0 to lvDelta.Items.Count - 1 do
    begin
      if lvDelta.Items[i].Selected and (lvDelta.Items[i].SubItems.Count > 0) then
        SL.Add(lvDelta.Items[i].SubItems[0]);
    end;
    Clipboard.AsText := SL.Text;
    SetStatus(Format(TrText('DeltaEditor.Copied: %d'), [SL.Count]));
  finally
    SL.Free;
  end;
end;

procedure TfrmDeltaEditor.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(FOnEscapeEmbedded) then
      FOnEscapeEmbedded(Self)
    else
      ModalResult := mrCancel;
  end
  else if (Key = VK_DELETE) and (Shift = []) and lvDelta.Focused then
  begin
    Key := 0;
    btnDeleteClick(btnDelete);
  end;
end;

procedure TfrmDeltaEditor.edtLineNumKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    if Trim(edtLineNum.Text) <> '' then
      edtContent.SetFocus;
  end;
end;

procedure TfrmDeltaEditor.edtContentKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnAddClick(btnAdd);
  end;
end;

procedure TfrmDeltaEditor.FormShow(Sender: TObject);
begin
  ApplyUiLanguage;
  LayoutControls;
  if Assigned(pnlTop) then
  begin
    pnlTop.ParentBackground := False;
    pnlTop.Color := clBtnFace;
  end;
  if Assigned(pnlFooter) then
  begin
    pnlFooter.ParentBackground := False;
    pnlFooter.Color := clBtnFace;
  end;
  Color := clBtnFace;
  if edtLineNum.CanFocus then
    edtLineNum.SetFocus;
end;

procedure TfrmDeltaEditor.LayoutControls;
const
  MARGIN = 12;
  GAP = 8;
  LABEL_GAP = 6;
var
  TextH, CtlH, RowTop, HintH, HintW, LabelW1, LabelW2: Integer;
  EditLeft, LineNumW, ContentLeft, ContentW, BtnW, StatusL, StatusW, FooterTop: Integer;

  procedure CenterLabel(L: TLabel; ALeft: Integer);
  begin
    L.AutoSize := True;
    L.Left := ALeft;
    L.Top := RowTop + (CtlH - L.Height) div 2;
  end;

begin
  if not Assigned(pnlTop) or not Assigned(pnlFooter) then Exit;
  if ClientWidth < 280 then Exit;

  Canvas.Font.Assign(Font);
  TextH := Canvas.TextHeight('Hg');
  { One height for edits and buttons in the same row — follows font/DPI. }
  CtlH := Max(TextH + 10, 23);
  LineNumW := Max(72, Canvas.TextWidth('0000000000') + 12);

  HintW := Max(40, pnlTop.ClientWidth - 2 * MARGIN);
  HintH := TextH;
  if Assigned(lblHint) and (Canvas.TextWidth(lblHint.Caption) > HintW) then
    HintH := TextH * 2;
  if Assigned(lblHint) then
  begin
    lblHint.AutoSize := False;
    lblHint.WordWrap := True;
    lblHint.SetBounds(MARGIN, 8, HintW, HintH);
  end;

  RowTop := 8 + HintH + GAP;

  LabelW1 := 0;
  if Assigned(lblLineNum) then
    LabelW1 := Canvas.TextWidth(lblLineNum.Caption);
  LabelW2 := 0;
  if Assigned(lblContent) then
    LabelW2 := Canvas.TextWidth(lblContent.Caption);

  BtnW := 104;
  if Assigned(btnAdd) then
    BtnW := btnAdd.Width;

  if Assigned(lblLineNum) then
    CenterLabel(lblLineNum, MARGIN);
  EditLeft := MARGIN + LabelW1 + LABEL_GAP;
  if Assigned(edtLineNum) then
  begin
    edtLineNum.AutoSize := False;
    edtLineNum.SetBounds(EditLeft, RowTop, LineNumW, CtlH);
  end;

  ContentLeft := EditLeft + LineNumW + GAP + 4;
  if Assigned(lblContent) then
    CenterLabel(lblContent, ContentLeft);
  ContentLeft := ContentLeft + LabelW2 + LABEL_GAP;

  if Assigned(btnAdd) then
    btnAdd.SetBounds(pnlTop.ClientWidth - MARGIN - BtnW, RowTop, BtnW, CtlH);

  ContentW := Max(80, (pnlTop.ClientWidth - MARGIN - BtnW - GAP) - ContentLeft);
  if Assigned(edtContent) then
  begin
    edtContent.AutoSize := False;
    edtContent.SetBounds(ContentLeft, RowTop, ContentW, CtlH);
  end;

  pnlTop.Height := RowTop + CtlH + GAP + 2;

  { Footer: separator + one row of buttons of the same height. }
  pnlFooter.Height := CtlH + 2 * GAP + 6;
  FooterTop := 6 + GAP;
  if Assigned(Bevel1) then
    Bevel1.SetBounds(MARGIN, 3, Max(10, pnlFooter.ClientWidth - 2 * MARGIN), 2);

  if Assigned(btnCopy) then
    btnCopy.SetBounds(MARGIN, FooterTop, btnCopy.Width, CtlH);
  if Assigned(btnDelete) and Assigned(btnCopy) then
    btnDelete.SetBounds(btnCopy.Left + btnCopy.Width + GAP, FooterTop, btnDelete.Width, CtlH);
  if Assigned(btnCancel) then
    btnCancel.SetBounds(pnlFooter.ClientWidth - MARGIN - btnCancel.Width, FooterTop,
      btnCancel.Width, CtlH);
  if Assigned(btnConfirm) and Assigned(btnCancel) then
    btnConfirm.SetBounds(btnCancel.Left - GAP - btnConfirm.Width, FooterTop,
      btnConfirm.Width, CtlH);
  if Assigned(lblStatus) and Assigned(btnDelete) and Assigned(btnConfirm) then
  begin
    StatusL := btnDelete.Left + btnDelete.Width + GAP * 2;
    StatusW := Max(40, btnConfirm.Left - GAP * 2 - StatusL);
    lblStatus.AutoSize := False;
    lblStatus.SetBounds(StatusL, FooterTop + (CtlH - TextH) div 2, StatusW, TextH);
  end;

  if Assigned(lvDelta) and lvDelta.HandleAllocated and (lvDelta.Columns.Count >= 2) then
  begin
    lvDelta.Columns[0].Width := Max(90, Canvas.TextWidth(lvDelta.Columns[0].Caption) + 24);
    lvDelta.Columns[1].Width := Max(120,
      lvDelta.ClientWidth - lvDelta.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) - 8);
  end;
end;

procedure TfrmDeltaEditor.FormResize(Sender: TObject);
begin
  LayoutControls;
end;

procedure TfrmDeltaEditor.lvDeltaSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) and (lvDelta.SelCount = 1) then
  begin
    edtLineNum.Text := Item.Caption;
    if Item.SubItems.Count > 0 then
      edtContent.Text := Item.SubItems[0]
    else
      edtContent.Text := '';
  end;
end;

procedure TfrmDeltaEditor.lvDeltaDblClick(Sender: TObject);
begin
  if Assigned(lvDelta.Selected) then
    edtContent.SetFocus;
end;

end.
