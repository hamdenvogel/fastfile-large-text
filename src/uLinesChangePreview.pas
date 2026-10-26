unit uLinesChangePreview;

{ Pre-visualizacao (antes / depois) das linhas que serao gravadas no arquivo.
  So as linhas alteradas aparecem; a lista e virtual para aguentar o limite
  de linhas selecionadas sem criar um item por linha. }

interface

uses
  Classes;

{ ALineNos/AOld/ANew tem o mesmo tamanho (uma entrada por linha selecionada).
  Devolve True quando o usuario confirma a gravacao. }
function ShowLinesChangePreview(AOwner: TComponent; const ACaption: string;
  const ALineNos: array of Int64; AOld, ANew: TStrings): Boolean;

implementation

uses
  Windows, SysUtils, Math, Controls, Forms, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  uI18n, uFastFileScale;

const
  CELL_MAX_CHARS = 400;
  BEFORE_BG = $00E8E8FF;
  AFTER_BG = $00E0F5E0;

type
  TLinesPreviewForm = class(TForm)
  private
    FLineNos: TArray<Int64>;
    FOld, FNew: TArray<string>;
    LblSummary: TLabel;
    LblUndo: TLabel;
    Lv: TListView;
    PnlDetail: TPanel;
    LblBefore, LblAfter: TLabel;
    MmBefore, MmAfter: TMemo;
    PnlFooter: TPanel;
    BtnSave, BtnBack: TButton;
    procedure BuildUi(ATotal: Integer);
    procedure LvData(Sender: TObject; Item: TListItem);
    procedure LvSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure LvCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure FormResizePreview(Sender: TObject);
    procedure ShowDetail(AIndex: Integer);
  end;

function Cell(const S: string): string;
var
  I: Integer;
begin
  if Length(S) > CELL_MAX_CHARS then
    Result := Copy(S, 1, CELL_MAX_CHARS) + #$2026
  else
    Result := S;
  for I := 1 to Length(Result) do
    if Result[I] < ' ' then
      Result[I] := ' ';
end;

procedure TLinesPreviewForm.BuildUi(ATotal: Integer);
var
  Col: TListColumn;
  M: Integer;
begin
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poOwnerFormCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := clBtnFace;
  KeyPreview := True;
  M := FfPx(10);

  PnlFooter := TPanel.Create(Self);
  PnlFooter.Parent := Self;
  PnlFooter.Align := alBottom;
  PnlFooter.Height := FfPx(48);
  PnlFooter.BevelOuter := bvNone;
  PnlFooter.ParentBackground := False;
  PnlFooter.Color := clBtnFace;

  BtnBack := TButton.Create(Self);
  BtnBack.Parent := PnlFooter;
  BtnBack.Caption := TrText('LinesPreview.Back');
  BtnBack.ModalResult := mrCancel;
  BtnBack.Cancel := True;
  BtnBack.Anchors := [akTop, akRight];

  BtnSave := TButton.Create(Self);
  BtnSave.Parent := PnlFooter;
  BtnSave.Caption := TrText('LinesPreview.Save');
  BtnSave.ModalResult := mrOk;
  BtnSave.Default := True;
  BtnSave.Anchors := [akTop, akRight];

  LblSummary := TLabel.Create(Self);
  LblSummary.Parent := Self;
  LblSummary.Align := alTop;
  LblSummary.AlignWithMargins := True;
  LblSummary.Margins.SetBounds(M, M, M, FfPx(2));
  LblSummary.WordWrap := True;
  LblSummary.ShowAccelChar := False;
  LblSummary.Font.Style := [fsBold];
  LblSummary.Caption := Format(TrText('LinesPreview.Summary'), [Length(FLineNos), ATotal]);

  LblUndo := TLabel.Create(Self);
  LblUndo.Parent := Self;
  LblUndo.Align := alTop;
  LblUndo.Top := LblSummary.Top + LblSummary.Height + 1;
  LblUndo.AlignWithMargins := True;
  LblUndo.Margins.SetBounds(M, 0, M, FfPx(6));
  LblUndo.WordWrap := True;
  LblUndo.ShowAccelChar := False;
  LblUndo.Font.Color := clGrayText;
  LblUndo.Caption := TrText('LinesPreview.UndoNote');

  PnlDetail := TPanel.Create(Self);
  PnlDetail.Parent := Self;
  PnlDetail.Align := alBottom;
  PnlDetail.Height := FfPx(150);
  PnlDetail.Top := PnlFooter.Top - PnlDetail.Height;
  PnlDetail.BevelOuter := bvNone;
  PnlDetail.ParentBackground := False;
  PnlDetail.Color := clBtnFace;

  LblBefore := TLabel.Create(Self);
  LblBefore.Parent := PnlDetail;
  LblBefore.ShowAccelChar := False;
  LblBefore.Caption := TrText('LinesPreview.ColBefore');
  LblAfter := TLabel.Create(Self);
  LblAfter.Parent := PnlDetail;
  LblAfter.ShowAccelChar := False;
  LblAfter.Caption := TrText('LinesPreview.ColAfter');

  MmBefore := TMemo.Create(Self);
  MmBefore.Parent := PnlDetail;
  MmBefore.ReadOnly := True;
  MmBefore.ScrollBars := ssVertical;
  MmBefore.Color := BEFORE_BG;
  MmBefore.Font.Name := 'Consolas';
  MmBefore.Font.Size := 9;
  MmAfter := TMemo.Create(Self);
  MmAfter.Parent := PnlDetail;
  MmAfter.ReadOnly := True;
  MmAfter.ScrollBars := ssVertical;
  MmAfter.Color := AFTER_BG;
  MmAfter.Font.Name := 'Consolas';
  MmAfter.Font.Size := 9;

  Lv := TListView.Create(Self);
  Lv.Parent := Self;
  Lv.Align := alClient;
  Lv.AlignWithMargins := True;
  Lv.Margins.SetBounds(M, 0, M, FfPx(6));
  Lv.ViewStyle := vsReport;
  Lv.OwnerData := True;
  Lv.ReadOnly := True;
  Lv.RowSelect := True;
  Lv.HideSelection := False;
  Lv.GridLines := True;
  Lv.Font.Name := 'Consolas';
  Lv.Font.Size := 9;
  Col := Lv.Columns.Add;
  Col.Caption := TrText('LinesPreview.ColLine');
  Col.Width := FfPx(80);
  Col.Alignment := taRightJustify;
  Col := Lv.Columns.Add;
  Col.Caption := TrText('LinesPreview.ColBefore');
  Col := Lv.Columns.Add;
  Col.Caption := TrText('LinesPreview.ColAfter');
  Lv.OnData := LvData;
  Lv.OnSelectItem := LvSelect;
  Lv.OnCustomDrawSubItem := LvCustomDrawSubItem;
  Lv.Items.Count := Length(FLineNos);

  OnResize := FormResizePreview;
  FfPrepareDialog(Self, 900, 560);
  Constraints.MinWidth := FfPx(520);
  Constraints.MinHeight := FfPx(380);
  FormResizePreview(nil);
  if Lv.Items.Count > 0 then
  begin
    Lv.Items[0].Selected := True;
    Lv.Items[0].Focused := True;
    ShowDetail(0);
  end;
  ActiveControl := BtnSave;
end;

procedure TLinesPreviewForm.FormResizePreview(Sender: TObject);
var
  M, W, H, BtnW, LblH: Integer;
begin
  if not Assigned(PnlFooter) then Exit;
  M := FfPx(10);
  H := FfPx(28);
  BtnW := Max(FfPx(110), Canvas.TextWidth(BtnSave.Caption) + FfPx(28));
  BtnSave.SetBounds(PnlFooter.ClientWidth - M - BtnW - FfPx(8) -
    Max(FfPx(90), Canvas.TextWidth(BtnBack.Caption) + FfPx(28)), FfPx(10), BtnW, H);
  BtnBack.SetBounds(BtnSave.Left + BtnSave.Width + FfPx(8), FfPx(10),
    Max(FfPx(90), Canvas.TextWidth(BtnBack.Caption) + FfPx(28)), H);

  LblH := Canvas.TextHeight('Ag') + FfPx(2);
  W := (PnlDetail.ClientWidth - 3 * M) div 2;
  LblBefore.SetBounds(M, FfPx(2), W, LblH);
  LblAfter.SetBounds(2 * M + W, FfPx(2), W, LblH);
  MmBefore.SetBounds(M, LblH + FfPx(4), W, PnlDetail.ClientHeight - LblH - FfPx(8));
  MmAfter.SetBounds(2 * M + W, LblH + FfPx(4), W, PnlDetail.ClientHeight - LblH - FfPx(8));

  if Lv.Columns.Count = 3 then
  begin
    W := Lv.ClientWidth - Lv.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) - 4;
    if W < FfPx(200) then W := FfPx(200);
    Lv.Columns[1].Width := W div 2;
    Lv.Columns[2].Width := W - W div 2;
  end;
end;

procedure TLinesPreviewForm.LvData(Sender: TObject; Item: TListItem);
var
  I: Integer;
begin
  I := Item.Index;
  if (I < 0) or (I > High(FLineNos)) then Exit;
  Item.Caption := IntToStr(FLineNos[I]);
  Item.SubItems.Add(Cell(FOld[I]));
  Item.SubItems.Add(Cell(FNew[I]));
end;

procedure TLinesPreviewForm.LvCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
  SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw := True;
  if cdsSelected in State then Exit;
  case SubItem of
    1: Sender.Canvas.Brush.Color := BEFORE_BG;
    2: Sender.Canvas.Brush.Color := AFTER_BG;
  else
    Sender.Canvas.Brush.Color := clWindow;
  end;
end;

procedure TLinesPreviewForm.LvSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
    ShowDetail(Item.Index);
end;

procedure TLinesPreviewForm.ShowDetail(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FLineNos)) then Exit;
  LblBefore.Caption := TrText('LinesPreview.ColBefore') + ' - ' +
    TrText('LinesPreview.ColLine') + ' ' + IntToStr(FLineNos[AIndex]);
  LblAfter.Caption := TrText('LinesPreview.ColAfter');
  MmBefore.Text := FOld[AIndex];
  MmAfter.Text := FNew[AIndex];
end;

function ShowLinesChangePreview(AOwner: TComponent; const ACaption: string;
  const ALineNos: array of Int64; AOld, ANew: TStrings): Boolean;
var
  Frm: TLinesPreviewForm;
  I, N, Total: Integer;
begin
  Result := False;
  Total := Length(ALineNos);
  if (AOld = nil) or (ANew = nil) or (AOld.Count < Total) or (ANew.Count < Total) then Exit;
  Frm := TLinesPreviewForm.CreateNew(AOwner);
  try
    Frm.Caption := ACaption;
    N := 0;
    for I := 0 to Total - 1 do
      if AOld[I] <> ANew[I] then
        Inc(N);
    SetLength(Frm.FLineNos, N);
    SetLength(Frm.FOld, N);
    SetLength(Frm.FNew, N);
    N := 0;
    for I := 0 to Total - 1 do
      if AOld[I] <> ANew[I] then
      begin
        Frm.FLineNos[N] := ALineNos[I];
        Frm.FOld[N] := AOld[I];
        Frm.FNew[N] := ANew[I];
        Inc(N);
      end;
    Frm.BuildUi(Total);
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

end.
