unit uScriptRunPreview;

{ Pre-visualizacao da saida do Script engine (Python transform) antes de gerar
  a saida completa. Mostra so uma amostra pequena (o chamador limita o numero
  de linhas); a lista e virtual. }

interface

uses
  Classes;

const
  SCRIPT_PREVIEW_MAX_LINES = 200;
  SCRIPT_PREVIEW_KIND_OK = 0;
  SCRIPT_PREVIEW_KIND_SKIP = 1;
  SCRIPT_PREVIEW_KIND_ERROR = 2;
  SCRIPT_PREVIEW_KIND_NONE = 3;

{ ALineNos/AOrig/AResult/AKinds tem o mesmo tamanho (uma entrada por linha da amostra).
  AScopeTotal = linhas que a execucao completa vai processar.
  Devolve True quando o usuario escolhe gerar a saida completa. }
function ShowScriptRunPreview(AOwner: TComponent; const ALineNos: array of Int64;
  const AOrig, AResult: array of string; const AKinds: array of Integer;
  AScopeTotal: Int64; AToFile: Boolean): Boolean;

implementation

uses
  Windows, SysUtils, Math, Controls, Forms, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  uI18n, uFastFileScale;

const
  CELL_MAX_CHARS = 400;
  CLR_HEADER = $00FAF3EC;
  CLR_ACCENT = $00703C10;
  CLR_OK_BG = $00E0F5E0;
  CLR_SKIP_BG = $00EFEFEF;
  CLR_ERR_BG = $00E0E0FF;
  CLR_ERR_FG = $000000B0;
  CLR_ORIG_BG = $00FBFBFB;

type
  TScriptPreviewForm = class(TForm)
  private
    FLineNos: TArray<Int64>;
    FOrig, FRes: TArray<string>;
    FKinds: TArray<Integer>;
    FOk, FSkip, FErr: Integer;
    PnlHeader: TPanel;
    LblTitle, LblSummary, LblNote, LblWarn: TLabel;
    Lv: TListView;
    PnlDetail: TPanel;
    LblOrig, LblRes: TLabel;
    MmOrig, MmRes: TMemo;
    PnlFooter: TPanel;
    BtnGenerate, BtnBack: TButton;
    procedure BuildUi(AScopeTotal: Int64; AToFile: Boolean);
    procedure LvData(Sender: TObject; Item: TListItem);
    procedure LvSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure LvCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure FormResizePreview(Sender: TObject);
    procedure ShowDetail(AIndex: Integer);
    function KindText(AKind: Integer): string;
    function LabelHeight(ALabel: TLabel; AWidth: Integer): Integer;
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

function TScriptPreviewForm.KindText(AKind: Integer): string;
begin
  case AKind of
    SCRIPT_PREVIEW_KIND_OK: Result := #$2714 + ' ' + TrText('ScriptPreview.StOk');
    SCRIPT_PREVIEW_KIND_SKIP: Result := #$2298 + ' ' + TrText('ScriptPreview.StSkip');
    SCRIPT_PREVIEW_KIND_ERROR: Result := #$2716 + ' ' + TrText('ScriptPreview.StErr');
  else
    Result := '?';
  end;
end;

function TScriptPreviewForm.LabelHeight(ALabel: TLabel; AWidth: Integer): Integer;
var
  R: TRect;
begin
  Result := 0;
  if (ALabel.Caption = '') or not ALabel.Visible then Exit;
  Canvas.Font := ALabel.Font;
  R := Rect(0, 0, Max(1, AWidth), 0);
  DrawText(Canvas.Handle, PChar(ALabel.Caption), -1, R,
    DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
  Result := R.Bottom + FfPx(2);
end;

procedure TScriptPreviewForm.BuildUi(AScopeTotal: Int64; AToFile: Boolean);
var
  Col: TListColumn;
  M, I: Integer;
begin
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poOwnerFormCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := clBtnFace;
  KeyPreview := True;
  M := FfPx(14);

  FOk := 0;
  FSkip := 0;
  FErr := 0;
  for I := 0 to High(FKinds) do
    case FKinds[I] of
      SCRIPT_PREVIEW_KIND_OK: Inc(FOk);
      SCRIPT_PREVIEW_KIND_SKIP: Inc(FSkip);
      SCRIPT_PREVIEW_KIND_ERROR: Inc(FErr);
    end;

  PnlHeader := TPanel.Create(Self);
  PnlHeader.Parent := Self;
  PnlHeader.Align := alTop;
  PnlHeader.BevelOuter := bvNone;
  PnlHeader.ParentBackground := False;
  PnlHeader.Color := CLR_HEADER;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent := PnlHeader;
  LblTitle.AutoSize := False;
  LblTitle.Transparent := True;
  LblTitle.ShowAccelChar := False;
  LblTitle.Font.Size := 13;
  LblTitle.Font.Style := [fsBold];
  LblTitle.Font.Color := CLR_ACCENT;
  LblTitle.Caption := TrText('ScriptPreview.Title');

  LblSummary := TLabel.Create(Self);
  LblSummary.Parent := PnlHeader;
  LblSummary.AutoSize := False;
  LblSummary.WordWrap := True;
  LblSummary.Transparent := True;
  LblSummary.ShowAccelChar := False;
  LblSummary.Font.Style := [fsBold];
  LblSummary.Caption := Format(TrText('ScriptPreview.Summary'),
    [Length(FLineNos), FormatFloat('#,##0', AScopeTotal), FOk, FSkip, FErr]);

  LblNote := TLabel.Create(Self);
  LblNote.Parent := PnlHeader;
  LblNote.AutoSize := False;
  LblNote.WordWrap := True;
  LblNote.Transparent := True;
  LblNote.ShowAccelChar := False;
  LblNote.Font.Color := clGrayText;
  if AToFile then
    LblNote.Caption := TrText('ScriptPreview.NoteFile')
  else
    LblNote.Caption := TrText('ScriptPreview.NoteMemo');

  LblWarn := TLabel.Create(Self);
  LblWarn.Parent := PnlHeader;
  LblWarn.AutoSize := False;
  LblWarn.WordWrap := True;
  LblWarn.Transparent := True;
  LblWarn.ShowAccelChar := False;
  LblWarn.Font.Style := [fsBold];
  LblWarn.Font.Color := CLR_ERR_FG;
  if (FErr > 0) and (FOk = 0) then
    LblWarn.Caption := TrText('ScriptPreview.AllErrors')
  else if (FOk = 0) and (FSkip > 0) then
    LblWarn.Caption := TrText('ScriptPreview.AllSkipped')
  else
    LblWarn.Caption := '';
  LblWarn.Visible := LblWarn.Caption <> '';

  PnlFooter := TPanel.Create(Self);
  PnlFooter.Parent := Self;
  PnlFooter.Align := alBottom;
  PnlFooter.Height := FfPx(52);
  PnlFooter.BevelOuter := bvNone;
  PnlFooter.ParentBackground := False;
  PnlFooter.Color := clBtnFace;

  BtnBack := TButton.Create(Self);
  BtnBack.Parent := PnlFooter;
  BtnBack.Caption := TrText('ScriptPreview.Back');
  BtnBack.ModalResult := mrCancel;
  BtnBack.Cancel := True;

  BtnGenerate := TButton.Create(Self);
  BtnGenerate.Parent := PnlFooter;
  BtnGenerate.Caption := TrText('ScriptPreview.Generate');
  BtnGenerate.ModalResult := mrOk;
  BtnGenerate.Font.Style := [fsBold];
  BtnGenerate.Default := FOk > 0;
  BtnBack.Default := FOk = 0;

  PnlDetail := TPanel.Create(Self);
  PnlDetail.Parent := Self;
  PnlDetail.Align := alBottom;
  PnlDetail.Height := FfPx(170);
  PnlDetail.Top := PnlFooter.Top - PnlDetail.Height;
  PnlDetail.BevelOuter := bvNone;
  PnlDetail.ParentBackground := False;
  PnlDetail.Color := clBtnFace;

  LblOrig := TLabel.Create(Self);
  LblOrig.Parent := PnlDetail;
  LblOrig.ShowAccelChar := False;
  LblOrig.Font.Style := [fsBold];
  LblOrig.Font.Color := CLR_ACCENT;
  LblRes := TLabel.Create(Self);
  LblRes.Parent := PnlDetail;
  LblRes.ShowAccelChar := False;
  LblRes.Font.Style := [fsBold];
  LblRes.Font.Color := CLR_ACCENT;

  MmOrig := TMemo.Create(Self);
  MmOrig.Parent := PnlDetail;
  MmOrig.ReadOnly := True;
  MmOrig.ScrollBars := ssVertical;
  MmOrig.Color := CLR_ORIG_BG;
  MmOrig.Font.Name := 'Consolas';
  MmOrig.Font.Size := 9;
  MmRes := TMemo.Create(Self);
  MmRes.Parent := PnlDetail;
  MmRes.ReadOnly := True;
  MmRes.ScrollBars := ssVertical;
  MmRes.Color := CLR_OK_BG;
  MmRes.Font.Name := 'Consolas';
  MmRes.Font.Size := 9;

  Lv := TListView.Create(Self);
  Lv.Parent := Self;
  Lv.Align := alClient;
  Lv.AlignWithMargins := True;
  Lv.Margins.SetBounds(M, FfPx(8), M, FfPx(6));
  Lv.ViewStyle := vsReport;
  Lv.OwnerData := True;
  Lv.ReadOnly := True;
  Lv.RowSelect := True;
  Lv.HideSelection := False;
  Lv.GridLines := True;
  Lv.Font.Name := 'Consolas';
  Lv.Font.Size := 9;
  Col := Lv.Columns.Add;
  Col.Caption := TrText('ScriptPreview.ColLine');
  Col.Width := FfPx(80);
  Col.Alignment := taRightJustify;
  Col := Lv.Columns.Add;
  Col.Caption := TrText('ScriptPreview.ColStatus');
  Col.Width := FfPx(130);
  Col := Lv.Columns.Add;
  Col.Caption := TrText('ScriptPreview.ColOriginal');
  Col := Lv.Columns.Add;
  Col.Caption := TrText('ScriptPreview.ColResult');
  Lv.OnData := LvData;
  Lv.OnSelectItem := LvSelect;
  Lv.OnCustomDrawSubItem := LvCustomDrawSubItem;
  Lv.Items.Count := Length(FLineNos);

  OnResize := FormResizePreview;
  FfPrepareDialog(Self, 980, 640);
  Constraints.MinWidth := FfPx(620);
  Constraints.MinHeight := FfPx(440);
  FormResizePreview(nil);
  if Lv.Items.Count > 0 then
  begin
    Lv.Items[0].Selected := True;
    Lv.Items[0].Focused := True;
    ShowDetail(0);
  end;
  if FOk > 0 then
    ActiveControl := BtnGenerate
  else
    ActiveControl := BtnBack;
end;

procedure TScriptPreviewForm.FormResizePreview(Sender: TObject);
var
  M, W, Y, H, BtnGenW, BtnBackW, LblH: Integer;
begin
  if not Assigned(PnlFooter) then Exit;
  M := FfPx(14);
  W := Max(FfPx(200), ClientWidth - 2 * M);

  Canvas.Font := LblTitle.Font;
  Y := FfPx(10);
  LblTitle.SetBounds(M, Y, W, Canvas.TextHeight('Ay') + 2);
  Inc(Y, LblTitle.Height + FfPx(4));
  LblSummary.SetBounds(M, Y, W, LabelHeight(LblSummary, W));
  Inc(Y, LblSummary.Height + FfPx(2));
  LblNote.SetBounds(M, Y, W, LabelHeight(LblNote, W));
  Inc(Y, LblNote.Height);
  if LblWarn.Visible then
  begin
    Inc(Y, FfPx(4));
    LblWarn.SetBounds(M, Y, W, LabelHeight(LblWarn, W));
    Inc(Y, LblWarn.Height);
  end;
  PnlHeader.Height := Y + FfPx(10);

  Canvas.Font := Font;
  H := Canvas.TextHeight('Ay') + FfPx(14);
  BtnGenW := Max(FfPx(130), Canvas.TextWidth(BtnGenerate.Caption) + FfPx(40));
  BtnBackW := Max(FfPx(110), Canvas.TextWidth(BtnBack.Caption) + FfPx(32));
  PnlFooter.Height := H + FfPx(20);
  BtnBack.SetBounds(PnlFooter.ClientWidth - M - BtnBackW, FfPx(10), BtnBackW, H);
  BtnGenerate.SetBounds(BtnBack.Left - FfPx(8) - BtnGenW, FfPx(10), BtnGenW, H);

  LblH := Canvas.TextHeight('Ay') + FfPx(2);
  W := (PnlDetail.ClientWidth - 3 * M) div 2;
  LblOrig.SetBounds(M, FfPx(2), W, LblH);
  LblRes.SetBounds(2 * M + W, FfPx(2), W, LblH);
  MmOrig.SetBounds(M, LblH + FfPx(4), W, PnlDetail.ClientHeight - LblH - FfPx(8));
  MmRes.SetBounds(2 * M + W, LblH + FfPx(4), W, PnlDetail.ClientHeight - LblH - FfPx(8));

  if Lv.Columns.Count = 4 then
  begin
    W := Lv.ClientWidth - Lv.Columns[0].Width - Lv.Columns[1].Width -
      GetSystemMetrics(SM_CXVSCROLL) - 4;
    if W < FfPx(200) then W := FfPx(200);
    Lv.Columns[2].Width := W div 2;
    Lv.Columns[3].Width := W - W div 2;
  end;
end;

procedure TScriptPreviewForm.LvData(Sender: TObject; Item: TListItem);
var
  I: Integer;
begin
  I := Item.Index;
  if (I < 0) or (I > High(FLineNos)) then Exit;
  Item.Caption := IntToStr(FLineNos[I]);
  Item.SubItems.Add(KindText(FKinds[I]));
  Item.SubItems.Add(Cell(FOrig[I]));
  if FKinds[I] = SCRIPT_PREVIEW_KIND_SKIP then
    Item.SubItems.Add('')
  else
    Item.SubItems.Add(Cell(FRes[I]));
end;

procedure TScriptPreviewForm.LvCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
  SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  K: Integer;
begin
  DefaultDraw := True;
  Sender.Canvas.Font.Color := clWindowText;
  if cdsSelected in State then Exit;
  K := SCRIPT_PREVIEW_KIND_NONE;
  if Assigned(Item) and (Item.Index >= 0) and (Item.Index <= High(FKinds)) then
    K := FKinds[Item.Index];
  case SubItem of
    1, 3:
      case K of
        SCRIPT_PREVIEW_KIND_OK: Sender.Canvas.Brush.Color := CLR_OK_BG;
        SCRIPT_PREVIEW_KIND_SKIP:
          begin
            Sender.Canvas.Brush.Color := CLR_SKIP_BG;
            Sender.Canvas.Font.Color := clGrayText;
          end;
        SCRIPT_PREVIEW_KIND_ERROR:
          begin
            Sender.Canvas.Brush.Color := CLR_ERR_BG;
            Sender.Canvas.Font.Color := CLR_ERR_FG;
          end;
      else
        Sender.Canvas.Brush.Color := clWindow;
      end;
  else
    Sender.Canvas.Brush.Color := clWindow;
  end;
end;

procedure TScriptPreviewForm.LvSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
    ShowDetail(Item.Index);
end;

procedure TScriptPreviewForm.ShowDetail(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FLineNos)) then Exit;
  LblOrig.Caption := TrText('ScriptPreview.ColOriginal') + ' - ' +
    TrText('ScriptPreview.ColLine') + ' ' + IntToStr(FLineNos[AIndex]);
  LblRes.Caption := TrText('ScriptPreview.ColResult') + ' - ' + KindText(FKinds[AIndex]);
  MmOrig.Text := FOrig[AIndex];
  case FKinds[AIndex] of
    SCRIPT_PREVIEW_KIND_SKIP:
      begin
        MmRes.Color := CLR_SKIP_BG;
        MmRes.Font.Color := clGrayText;
        MmRes.Text := TrText('ScriptPreview.SkipDetail');
      end;
    SCRIPT_PREVIEW_KIND_ERROR:
      begin
        MmRes.Color := CLR_ERR_BG;
        MmRes.Font.Color := CLR_ERR_FG;
        MmRes.Text := FRes[AIndex];
      end;
  else
    MmRes.Color := CLR_OK_BG;
    MmRes.Font.Color := clWindowText;
    MmRes.Text := FRes[AIndex];
  end;
end;

function ShowScriptRunPreview(AOwner: TComponent; const ALineNos: array of Int64;
  const AOrig, AResult: array of string; const AKinds: array of Integer;
  AScopeTotal: Int64; AToFile: Boolean): Boolean;
var
  Frm: TScriptPreviewForm;
  I, N: Integer;
begin
  Result := False;
  N := Length(ALineNos);
  if (Length(AOrig) < N) or (Length(AResult) < N) or (Length(AKinds) < N) then Exit;
  Frm := TScriptPreviewForm.CreateNew(AOwner);
  try
    Frm.Caption := TrText('ScriptPreview.Title');
    SetLength(Frm.FLineNos, N);
    SetLength(Frm.FOrig, N);
    SetLength(Frm.FRes, N);
    SetLength(Frm.FKinds, N);
    for I := 0 to N - 1 do
    begin
      Frm.FLineNos[I] := ALineNos[I];
      Frm.FOrig[I] := AOrig[I];
      Frm.FRes[I] := AResult[I];
      Frm.FKinds[I] := AKinds[I];
    end;
    Frm.BuildUi(AScopeTotal, AToFile);
    Result := Frm.ShowModal = mrOk;
  finally
    Frm.Free;
  end;
end;

end.
