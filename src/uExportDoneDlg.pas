unit uExportDoneDlg;

{
  "File created" dialog shown when an operation generates files: the file (or the folder of the
  generated files) as a clickable card, a "click here to open" link (or one link per generated file)
  and buttons to open it in FastFile, open its folder or copy its path.
  Same look as uFastFileMsgDlg (soft gradient, rounded corners, green accent).
}

interface

uses
  Classes;

{ ARecords < 0: the record count is not known and is not shown. Also remembers the file
  (kept across sessions) so the window can be shown again later. }
procedure ShowGeneratedFileDialog(const AFileName: string; ARecords: Int64 = -1);
{ Same window for one or more generated files (e.g. the parts of a split). ADetail is an extra
  line for the subtitle (e.g. the elapsed time); files that do not exist are ignored. }
procedure ShowGeneratedFilesDialog(AFiles: TStrings; ARecords: Int64 = -1; const ADetail: string = '');
function LastGeneratedFile(out APath: string; out ARecords: Int64): Boolean;
{ Shows the window again for the last generated file(s), or says why it cannot. }
procedure ShowLastGeneratedFileDialog;
{ Called (Sender = nil) whenever the last generated file changes. }
procedure AddLastGeneratedFileListener(AEvent: TNotifyEvent);
procedure RemoveLastGeneratedFileListener(AEvent: TNotifyEvent);

implementation

uses
  Windows, Messages, SysUtils, Types, Graphics, Controls, Forms, StdCtrls, ExtCtrls, ShellAPI, Clipbrd,
  Math, IniFiles, uI18n, uFastFileScale, UnConsts, uFastFileAssistantHost, uFastFilePaths, uFastFileMsgDlg,
  uAgentPrefs;

const
  DLG_W = 560;
  DLG_PAD = 24;
  DLG_CORNER = 18;
  DLG_ACCENT_W = 5;
  DLG_ICON = 52;
  DLG_CARD_H = 66;
  DLG_FOOTER = 56;
  DLG_BTN_H = 30;
  DLG_MAX_ROWS = 8;
  CTitle = TColor($00283038);
  CMuted = TColor($00606870);
  CAccent = TColor($004CAF50);
  CLink = TColor($00D77800);
  CLinkHot = TColor($00A05000);

type
  TExportDoneForm = class(TForm)
  private
    FPaths: TStringList;
    FPath: string;
    FChosen: string;
    FMulti: Boolean;
    FRecords: Int64;
    FDetail: string;
    FUiFont: string;
    FGradTop, FGradBot: TColor;
    FRoundRgn: HRGN;
    FIcon: TPaintBox;
    FTitle: TLabel;
    FSub: TLabel;
    FCard: TPaintBox;
    FCardHot: Boolean;
    FLink: TLabel;
    FLinkDefault: TLabel;
    FBtnRow: TPanel;
    FBtnCopy: TButton;
    FCopyCaption: string;
    FCopyTimer: TTimer;
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure IconPaint(Sender: TObject);
    procedure CardPaint(Sender: TObject);
    procedure CardEnter(Sender: TObject);
    procedure CardLeave(Sender: TObject);
    procedure LinkEnter(Sender: TObject);
    procedure LinkLeave(Sender: TObject);
    procedure OpenInAppClick(Sender: TObject);
    procedure OpenFileRowClick(Sender: TObject);
    procedure OpenDefaultClick(Sender: TObject);
    procedure OpenFolderClick(Sender: TObject);
    procedure CopyPathClick(Sender: TObject);
    procedure CopyTimerTick(Sender: TObject);
    function AddButton(const ACaption: string; AClick: TNotifyEvent): TButton;
    function MakeLink(const ACaption: string; ASize: Integer; AClick: TNotifyEvent): TLabel;
    function MakeMuted(const ACaption: string; ASize: Integer): TLabel;
    procedure ApplyRoundRegion;
    procedure Build;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateFor(APaths: TStrings; ARecords: Int64; const ADetail: string); reintroduce;
    destructor Destroy; override;
    property Chosen: string read FChosen;
  end;

function MixColor(C1, C2: TColor; C2Pct: Integer): TColor;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);
  Result := RGB(
    GetRValue(C1) + (GetRValue(C2) - GetRValue(C1)) * C2Pct div 100,
    GetGValue(C1) + (GetGValue(C2) - GetGValue(C1)) * C2Pct div 100,
    GetBValue(C1) + (GetBValue(C2) - GetBValue(C1)) * C2Pct div 100);
end;

procedure PaintGradient(ACanvas: TCanvas; const R: TRect; CTop, CBot: TColor);
var
  V: array[0..1] of TRIVERTEX;
  GR: GRADIENT_RECT;

  procedure Fill(var AV: TRIVERTEX; X, Y: Integer; C: TColor);
  begin
    C := ColorToRGB(C);
    AV.x := X;
    AV.y := Y;
    AV.Red := GetRValue(C) shl 8;
    AV.Green := GetGValue(C) shl 8;
    AV.Blue := GetBValue(C) shl 8;
    AV.Alpha := 0;
  end;

begin
  Fill(V[0], R.Left, R.Top, CTop);
  Fill(V[1], R.Right, R.Bottom, CBot);
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  GradientFill(ACanvas.Handle, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V);
end;

function FileSizeOf(const APath: string): Int64;
var
  F: TSearchRec;
begin
  Result := -1;
  if FindFirst(APath, faAnyFile, F) <> 0 then Exit;
  try
    Result := F.Size;
  finally
    FindClose(F);
  end;
end;

function BytesText(ASize: Int64): string;
var
  N: Double;
begin
  Result := '';
  if ASize < 0 then Exit;
  N := ASize;
  if N < 1024 then
    Result := FormatFloat('0', N) + ' B'
  else if N < 1024 * 1024 then
    Result := FormatFloat('0.0', N / 1024) + ' KB'
  else if N < 1024.0 * 1024 * 1024 then
    Result := FormatFloat('0.0', N / (1024 * 1024)) + ' MB'
  else
    Result := FormatFloat('0.00', N / (1024.0 * 1024 * 1024)) + ' GB';
end;

{ Cuts the middle of a long name so its end (e.g. ".part012.csv") stays visible. }
function MiddleEllipsis(ACanvas: TCanvas; const S: string; AMaxW: Integer): string;
var
  Head, Tail: Integer;
begin
  Result := S;
  if ACanvas.TextWidth(S) <= AMaxW then Exit;
  Tail := Min(18, Length(S) div 2);
  Head := Length(S) - Tail - 1;
  while Head > 4 do
  begin
    Result := Copy(S, 1, Head) + #$2026 + Copy(S, Length(S) - Tail + 1, Tail);
    if ACanvas.TextWidth(Result) <= AMaxW then Exit;
    Dec(Head);
  end;
end;

{ Folder shared by all the paths, or the folder of the first one. }
function CommonFolder(APaths: TStrings): string;
var
  I: Integer;
begin
  Result := '';
  if APaths.Count = 0 then Exit;
  Result := ExtractFileDir(APaths[0]);
  for I := 1 to APaths.Count - 1 do
    if not SameText(ExtractFileDir(APaths[I]), Result) then
    begin
      Result := ExtractFileDir(APaths[0]);
      Exit;
    end;
end;

{ TExportDoneForm }

constructor TExportDoneForm.CreateFor(APaths: TStrings; ARecords: Int64; const ADetail: string);
begin
  inherited CreateNew(Application);
  FPaths := TStringList.Create;
  FPaths.Assign(APaths);
  FMulti := FPaths.Count > 1;
  if FMulti then
    FPath := ExcludeTrailingPathDelimiter(CommonFolder(FPaths))
  else
    FPath := FPaths[0];
  FRecords := ARecords;
  FDetail := ADetail;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    FUiFont := 'Segoe UI'
  else
    FUiFont := 'Tahoma';
  BorderStyle := bsNone;
  BorderIcons := [];
  Position := poMainFormCenter;
  KeyPreview := True;
  DoubleBuffered := True;
  Caption := TrText('ExportDone.Title');
  Font.Name := FUiFont;
  Font.Size := 9;
  Font.Color := CTitle;
  FGradTop := MixColor(IDLE_WORKSPACE_GRAD_LEFT, CAccent, 5);
  FGradBot := MixColor(IDLE_WORKSPACE_GRAD_RIGHT, CAccent, 8);
  Color := FGradTop;
  OnPaint := FormPaint;
  OnShow := FormShow;
  OnKeyDown := FormKeyDown;
  OnMouseDown := FormMouseDown;
  Build;
end;

destructor TExportDoneForm.Destroy;
begin
  if FRoundRgn <> 0 then
  begin
    if HandleAllocated then
      SetWindowRgn(Handle, 0, False);
    DeleteObject(FRoundRgn);
  end;
  FPaths.Free;
  inherited;
end;

procedure TExportDoneForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

function TExportDoneForm.AddButton(const ACaption: string; AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := FBtnRow;
  Result.Caption := ACaption;
  Result.Font.Name := FUiFont;
  Result.Font.Size := 9;
  Result.Height := FfPx(DLG_BTN_H);
  Canvas.Font.Name := FUiFont;
  Canvas.Font.Size := 9;
  Result.Width := Max(FfPx(96), Canvas.TextWidth(ACaption) + FfPx(32));
  Result.OnClick := AClick;
end;

function TExportDoneForm.MakeLink(const ACaption: string; ASize: Integer; AClick: TNotifyEvent): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.Transparent := True;
  Result.ParentFont := False;
  Result.Font.Name := FUiFont;
  Result.Font.Size := ASize;
  Result.Font.Color := CLink;
  Result.Font.Style := [fsUnderline];
  Result.Cursor := crHandPoint;
  Result.Caption := ACaption;
  Result.Tag := -1;
  Result.OnClick := AClick;
  Result.OnMouseEnter := LinkEnter;
  Result.OnMouseLeave := LinkLeave;
end;

function TExportDoneForm.MakeMuted(const ACaption: string; ASize: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.Transparent := True;
  Result.ParentFont := False;
  Result.Font.Name := FUiFont;
  Result.Font.Size := ASize;
  Result.Font.Color := CMuted;
  Result.Caption := ACaption;
end;

procedure TExportDoneForm.Build;
var
  LeftPad, TextX, Y, W, X, Gap, TotalW, I, RowW, SizeW, Shown: Integer;
  Sub, S: string;
  Total, Sz: Int64;
  BtnOpen, BtnFolder, BtnClose: TButton;
  Row, SizeLbl: TLabel;
begin
  LeftPad := FfPx(16) + FfPx(DLG_ACCENT_W) + FfPx(16);
  ClientWidth := FfPx(DLG_W);

  FBtnRow := TPanel.Create(Self);
  FBtnRow.Parent := Self;
  FBtnRow.BevelOuter := bvNone;
  FBtnRow.Caption := '';
  FBtnRow.ParentBackground := True;
  FBtnRow.ParentColor := True;
  if FMulti then
  begin
    BtnOpen := nil;
    BtnFolder := AddButton(TrText('ExportDone.OpenFolder'), OpenFolderClick);
    BtnFolder.Default := True;
    FCopyCaption := TrText('ExportDone.CopyPaths');
  end
  else
  begin
    BtnOpen := AddButton(TrText('ExportDone.OpenInApp'), OpenInAppClick);
    BtnOpen.Default := True;
    BtnFolder := AddButton(TrText('ExportDone.OpenFolder'), OpenFolderClick);
    FCopyCaption := TrText('ExportDone.CopyPath');
  end;
  FBtnCopy := AddButton(FCopyCaption, CopyPathClick);
  BtnClose := AddButton(TrText('Close'), nil);
  BtnClose.ModalResult := mrCancel;
  BtnClose.Cancel := True;
  Gap := FfPx(8);
  TotalW := 0;
  for I := 0 to FBtnRow.ControlCount - 1 do
    Inc(TotalW, FBtnRow.Controls[I].Width);
  Inc(TotalW, (FBtnRow.ControlCount - 1) * Gap);
  ClientWidth := Max(ClientWidth, TotalW + LeftPad + FfPx(DLG_PAD));

  FIcon := TPaintBox.Create(Self);
  FIcon.Parent := Self;
  FIcon.SetBounds(LeftPad, FfPx(DLG_PAD), FfPx(DLG_ICON), FfPx(DLG_ICON));
  FIcon.OnPaint := IconPaint;

  TextX := LeftPad + FfPx(DLG_ICON) + FfPx(16);
  W := ClientWidth - TextX - FfPx(DLG_PAD);
  FTitle := TLabel.Create(Self);
  FTitle.Parent := Self;
  FTitle.Transparent := True;
  FTitle.ParentFont := False;
  FTitle.Font.Name := FUiFont;
  FTitle.Font.Size := 13;
  FTitle.Font.Style := [fsBold];
  FTitle.Font.Color := CTitle;
  if FMulti then
    FTitle.Caption := Format(TrText('ExportDone.TitleN'), [FPaths.Count])
  else
    FTitle.Caption := TrText('ExportDone.Title');
  FTitle.SetBounds(TextX, FfPx(DLG_PAD) + FfPx(2), W, FfPx(26));

  Sub := '';
  if FRecords >= 0 then
    Sub := Format(TrText('ExportDone.Records'), [FRecords]);
  Total := 0;
  for I := 0 to FPaths.Count - 1 do
  begin
    Sz := FileSizeOf(FPaths[I]);
    if Sz > 0 then
      Inc(Total, Sz);
  end;
  S := BytesText(Total);
  if FMulti then
    S := Format(TrText('ExportDone.TotalSize'), [S]);
  if S <> '' then
  begin
    if Sub <> '' then
      Sub := Sub + '   ' + #$00B7 + '   ';
    Sub := Sub + S;
  end;
  if FDetail <> '' then
  begin
    if Sub <> '' then
      Sub := Sub + '   ' + #$00B7 + '   ';
    Sub := Sub + FDetail;
  end;
  FSub := MakeMuted(Sub, 10);
  FSub.AutoSize := False;
  FSub.EllipsisPosition := epEndEllipsis;
  FSub.SetBounds(TextX, FTitle.Top + FfPx(28), W, FfPx(20));

  Y := FfPx(DLG_PAD) + FfPx(DLG_ICON) + FfPx(18);
  FCard := TPaintBox.Create(Self);
  FCard.Parent := Self;
  FCard.SetBounds(LeftPad, Y, ClientWidth - LeftPad - FfPx(DLG_PAD), FfPx(DLG_CARD_H));
  FCard.Cursor := crHandPoint;
  FCard.Hint := FPath;
  FCard.ShowHint := True;
  FCard.OnPaint := CardPaint;
  if FMulti then
    FCard.OnClick := OpenFolderClick
  else
    FCard.OnClick := OpenInAppClick;
  FCard.OnMouseEnter := CardEnter;
  FCard.OnMouseLeave := CardLeave;
  Y := Y + FfPx(DLG_CARD_H) + FfPx(14);

  if FMulti then
  begin
    with MakeMuted(TrText('ExportDone.ClickFile'), 9) do
    begin
      Left := LeftPad + FfPx(4);
      Top := Y;
      Y := Y + Height + FfPx(6);
    end;
    RowW := ClientWidth - LeftPad - FfPx(DLG_PAD) - FfPx(4);
    Canvas.Font.Name := FUiFont;
    Canvas.Font.Size := 9;
    SizeW := Canvas.TextWidth('0000.00 MB') + FfPx(8);
    Shown := Min(FPaths.Count, DLG_MAX_ROWS);
    if FPaths.Count = DLG_MAX_ROWS + 1 then
      Shown := FPaths.Count;
    for I := 0 to Shown - 1 do
    begin
      Row := MakeLink('', 10, OpenFileRowClick);
      Row.Font.Style := [];
      Row.Tag := I;
      Row.Hint := FPaths[I];
      Row.ShowHint := True;
      Row.AutoSize := False;
      Canvas.Font.Assign(Row.Font);
      Row.Caption := MiddleEllipsis(Canvas, #$25B6 + '  ' + ExtractFileName(FPaths[I]), RowW - SizeW - FfPx(8));
      Row.SetBounds(LeftPad + FfPx(4), Y, Canvas.TextWidth(Row.Caption) + FfPx(4),
        Canvas.TextHeight('Wg') + FfPx(2));
      SizeLbl := MakeMuted(BytesText(FileSizeOf(FPaths[I])), 9);
      SizeLbl.AutoSize := False;
      SizeLbl.Alignment := taRightJustify;
      SizeLbl.SetBounds(LeftPad + FfPx(4) + RowW - SizeW, Y + FfPx(2), SizeW, Row.Height);
      Y := Y + Row.Height + FfPx(4);
    end;
    if Shown < FPaths.Count then
      with MakeMuted(Format(TrText('ExportDone.More'), [FPaths.Count - Shown]), 9) do
      begin
        Left := LeftPad + FfPx(24);
        Top := Y + FfPx(2);
        Y := Y + Height + FfPx(6);
      end;
    Y := Y + FfPx(12);
  end
  else
  begin
    FLink := MakeLink(#$25B6 + '  ' + TrText('ExportDone.OpenLink'), 11, OpenInAppClick);
    FLink.Left := LeftPad + FfPx(4);
    FLink.Top := Y;
    Y := Y + FLink.Height + FfPx(6);
    FLinkDefault := MakeLink(TrText('ExportDone.OpenDefault'), 9, OpenDefaultClick);
    FLinkDefault.Left := LeftPad + FfPx(4) + FfPx(20);
    FLinkDefault.Top := Y;
    Y := Y + FLinkDefault.Height + FfPx(16);
  end;

  ClientHeight := Y + FfPx(DLG_FOOTER);
  FBtnRow.SetBounds(0, ClientHeight - FfPx(DLG_FOOTER), ClientWidth, FfPx(DLG_FOOTER));
  X := ClientWidth - TotalW - FfPx(DLG_PAD);
  for I := 0 to FBtnRow.ControlCount - 1 do
  begin
    FBtnRow.Controls[I].Left := X;
    FBtnRow.Controls[I].Top := (FfPx(DLG_FOOTER) - FfPx(DLG_BTN_H)) div 2 - FfPx(4);
    Inc(X, FBtnRow.Controls[I].Width + Gap);
  end;

  FCopyTimer := TTimer.Create(Self);
  FCopyTimer.Enabled := False;
  FCopyTimer.Interval := 1600;
  FCopyTimer.OnTimer := CopyTimerTick;
  if Assigned(BtnOpen) then
    ActiveControl := BtnOpen
  else
    ActiveControl := BtnFolder;
end;

procedure TExportDoneForm.ApplyRoundRegion;
var
  R: Integer;
  NewRgn: HRGN;
begin
  if not HandleAllocated then Exit;
  R := FfPx(DLG_CORNER);
  NewRgn := CreateRoundRectRgn(0, 0, ClientWidth + 1, ClientHeight + 1, R, R);
  SetWindowRgn(Handle, NewRgn, True);
  if FRoundRgn <> 0 then
    DeleteObject(FRoundRgn);
  FRoundRgn := NewRgn;
end;

procedure TExportDoneForm.FormShow(Sender: TObject);
begin
  ApplyRoundRegion;
  Invalidate;
end;

procedure TExportDoneForm.FormPaint(Sender: TObject);
var
  R, AccR: TRect;
  Rad, AccW: Integer;
begin
  R := ClientRect;
  PaintGradient(Canvas, R, FGradTop, FGradBot);
  PaintGradient(Canvas, Rect(R.Left, R.Top, R.Right, R.Top + FfPx(36)), MixColor(FGradTop, clWhite, 22), FGradTop);
  AccW := FfPx(DLG_ACCENT_W);
  AccR := Rect(FfPx(14), FfPx(18), FfPx(14) + AccW, R.Bottom - FfPx(18));
  Canvas.Brush.Color := CAccent;
  Canvas.Pen.Color := MixColor(CAccent, clWhite, 18);
  Windows.RoundRect(Canvas.Handle, AccR.Left, AccR.Top, AccR.Right, AccR.Bottom, AccW + 2, AccW + 2);
  Canvas.Pen.Color := MixColor(FGradBot, clBlack, 10);
  Canvas.MoveTo(FfPx(30), FBtnRow.Top);
  Canvas.LineTo(R.Right - FfPx(DLG_PAD), FBtnRow.Top);
  Rad := FfPx(DLG_CORNER);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := MixColor(IDLE_WORKSPACE_GRAD_RIGHT, clBlack, 22);
  Windows.RoundRect(Canvas.Handle, 1, 1, R.Right - 1, R.Bottom - 1, Rad, Rad);
  Canvas.Brush.Style := bsSolid;
end;

procedure TExportDoneForm.IconPaint(Sender: TObject);
var
  C: TCanvas;
  R: TRect;
  CX, CY, Rad: Integer;
  Ch: string;
begin
  C := FIcon.Canvas;
  R := FIcon.ClientRect;
  C.Brush.Color := MixColor(FGradTop, FGradBot, 20);
  C.FillRect(R);
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Rad := Min(R.Right, R.Bottom) div 2 - 1;
  C.Pen.Color := MixColor(CAccent, clWhite, 55);
  C.Brush.Color := MixColor(CAccent, clWhite, 78);
  C.Ellipse(CX - Rad, CY - Rad, CX + Rad, CY + Rad);
  C.Pen.Color := CAccent;
  C.Brush.Color := CAccent;
  C.Ellipse(CX - Rad + FfPx(5), CY - Rad + FfPx(5), CX + Rad - FfPx(5), CY + Rad - FfPx(5));
  C.Brush.Style := bsClear;
  C.Font.Name := FUiFont;
  C.Font.Size := 16;
  C.Font.Style := [fsBold];
  C.Font.Color := clWhite;
  Ch := #$2713;
  C.TextOut(CX - C.TextWidth(Ch) div 2, CY - C.TextHeight(Ch) div 2, Ch);
  C.Brush.Style := bsSolid;
end;

procedure TExportDoneForm.CardPaint(Sender: TObject);
var
  C: TCanvas;
  R, DocR, TR: TRect;
  Fold, X, NameX: Integer;
  Dir, Lbl: string;
  Pts: array[0..4] of TPoint;
  Folder: array[0..5] of TPoint;
begin
  C := FCard.Canvas;
  R := FCard.ClientRect;
  C.Brush.Color := MixColor(FGradTop, FGradBot, 40);
  C.FillRect(R);
  if FCardHot then
    C.Brush.Color := MixColor(clWhite, CLink, 6)
  else
    C.Brush.Color := MixColor(clWhite, FGradTop, 20);
  if FCardHot then
    C.Pen.Color := CLink
  else
    C.Pen.Color := MixColor(FGradBot, clBlack, 14);
  Windows.RoundRect(C.Handle, R.Left, R.Top, R.Right - 1, R.Bottom - 1, FfPx(12), FfPx(12));

  if FMulti then
  begin
    { folder glyph with a tab }
    DocR := Rect(R.Left + FfPx(14), R.Top + FfPx(16), R.Left + FfPx(14) + FfPx(38), R.Bottom - FfPx(14));
    Folder[0] := Point(DocR.Left, DocR.Top);
    Folder[1] := Point(DocR.Left + FfPx(14), DocR.Top);
    Folder[2] := Point(DocR.Left + FfPx(18), DocR.Top + FfPx(5));
    Folder[3] := Point(DocR.Right, DocR.Top + FfPx(5));
    Folder[4] := Point(DocR.Right, DocR.Bottom);
    Folder[5] := Point(DocR.Left, DocR.Bottom);
    C.Brush.Color := MixColor(clWhite, CAccent, 22);
    C.Pen.Color := CAccent;
    C.Polygon(Folder);
    C.Brush.Color := MixColor(clWhite, CAccent, 10);
    C.Rectangle(DocR.Left, DocR.Top + FfPx(10), DocR.Right + 1, DocR.Bottom + 1);
  end
  else
  begin
    { document glyph with a folded corner }
    DocR := Rect(R.Left + FfPx(16), R.Top + FfPx(12), R.Left + FfPx(16) + FfPx(32), R.Bottom - FfPx(12));
    Fold := FfPx(10);
    Pts[0] := Point(DocR.Left, DocR.Top);
    Pts[1] := Point(DocR.Right - Fold, DocR.Top);
    Pts[2] := Point(DocR.Right, DocR.Top + Fold);
    Pts[3] := Point(DocR.Right, DocR.Bottom);
    Pts[4] := Point(DocR.Left, DocR.Bottom);
    C.Brush.Color := MixColor(clWhite, CAccent, 12);
    C.Pen.Color := CAccent;
    C.Polygon(Pts);
    C.MoveTo(DocR.Right - Fold, DocR.Top);
    C.LineTo(DocR.Right - Fold, DocR.Top + Fold);
    C.LineTo(DocR.Right, DocR.Top + Fold);
    C.Pen.Color := MixColor(CAccent, clWhite, 35);
    for X := 0 to 2 do
    begin
      C.MoveTo(DocR.Left + FfPx(7), DocR.Top + FfPx(16) + X * FfPx(6));
      C.LineTo(DocR.Right - FfPx(7), DocR.Top + FfPx(16) + X * FfPx(6));
    end;
  end;

  C.Brush.Style := bsClear;
  X := DocR.Right + FfPx(16);
  C.Font.Name := FUiFont;
  C.Font.Size := 11;
  C.Font.Style := [];
  C.Font.Color := CMuted;
  if FMulti then
    Lbl := TrText('ExportDone.FolderLabel')
  else
    Lbl := TrText('ExportDone.FileLabel');
  TR := Rect(X, R.Top + FfPx(12), R.Right - FfPx(14), R.Top + FfPx(34));
  DrawText(C.Handle, PChar(Lbl), -1, TR, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER);
  NameX := X + C.TextWidth(Lbl) + FfPx(6);
  C.Font.Style := [fsBold];
  if FCardHot then
    C.Font.Color := CLinkHot
  else
    C.Font.Color := CTitle;
  TR := Rect(NameX, R.Top + FfPx(12), R.Right - FfPx(14), R.Top + FfPx(34));
  DrawText(C.Handle, PChar(ExtractFileName(FPath)), -1, TR, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or
    DT_END_ELLIPSIS or DT_VCENTER);
  C.Font.Size := 9;
  C.Font.Style := [];
  C.Font.Color := CMuted;
  if FMulti then
    Dir := FPath
  else
    Dir := ExtractFileDir(FPath);
  TR := Rect(X, R.Top + FfPx(36), R.Right - FfPx(14), R.Bottom - FfPx(8));
  DrawText(C.Handle, PChar(Dir), -1, TR, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_PATH_ELLIPSIS or
    DT_VCENTER);
  C.Brush.Style := bsSolid;
end;

procedure TExportDoneForm.CardEnter(Sender: TObject);
begin
  FCardHot := True;
  FCard.Invalidate;
end;

procedure TExportDoneForm.CardLeave(Sender: TObject);
begin
  FCardHot := False;
  FCard.Invalidate;
end;

procedure TExportDoneForm.LinkEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Color := CLinkHot;
  if TLabel(Sender).Tag >= 0 then
    TLabel(Sender).Font.Style := [fsUnderline];
end;

procedure TExportDoneForm.LinkLeave(Sender: TObject);
begin
  TLabel(Sender).Font.Color := CLink;
  if TLabel(Sender).Tag >= 0 then
    TLabel(Sender).Font.Style := [];
end;

procedure TExportDoneForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end;
end;

{ Drag the borderless window from any empty area. }
procedure TExportDoneForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0);
  end;
end;

procedure TExportDoneForm.OpenInAppClick(Sender: TObject);
begin
  FChosen := FPaths[0];
  ModalResult := mrOk;
end;

procedure TExportDoneForm.OpenFileRowClick(Sender: TObject);
begin
  FChosen := FPaths[TLabel(Sender).Tag];
  ModalResult := mrOk;
end;

procedure TExportDoneForm.OpenDefaultClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(FPath), nil, PChar(ExtractFileDir(FPath)), SW_SHOWNORMAL);
  ModalResult := mrClose;
end;

procedure TExportDoneForm.OpenFolderClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'explorer.exe', PChar('/select,"' + FPaths[0] + '"'), nil, SW_SHOWNORMAL);
  ModalResult := mrClose;
end;

procedure TExportDoneForm.CopyPathClick(Sender: TObject);
begin
  Clipboard.AsText := TrimRight(FPaths.Text);
  FBtnCopy.Caption := #$2713 + ' ' + TrText('ExportDone.Copied');
  FCopyTimer.Enabled := False;
  FCopyTimer.Enabled := True;
end;

procedure TExportDoneForm.CopyTimerTick(Sender: TObject);
begin
  FCopyTimer.Enabled := False;
  FBtnCopy.Caption := FCopyCaption;
end;

const
  LAST_SECTION = 'LastGeneratedFile';

var
  GLastLoaded: Boolean;
  GLastFiles: TStringList;
  GLastRecords: Int64 = -1;
  GLastDetail: string;
  GListeners: array of TNotifyEvent;

function LastFiles: TStringList;
begin
  if GLastFiles = nil then
    GLastFiles := TStringList.Create;
  Result := GLastFiles;
end;

procedure LoadLast;
var
  Ini: TMemIniFile;
  I, N: Integer;
  S: string;
begin
  if GLastLoaded then Exit;
  GLastLoaded := True;
  LastFiles.Clear;
  try
    Ini := TMemIniFile.Create(FastFileExeDirPath(AGENT_SESSION_FILE), TEncoding.UTF8);
    try
      N := Ini.ReadInteger(LAST_SECTION, 'Count', 0);
      for I := 1 to N do
      begin
        S := Ini.ReadString(LAST_SECTION, 'File' + IntToStr(I), '');
        if S <> '' then
          LastFiles.Add(S);
      end;
      S := Ini.ReadString(LAST_SECTION, 'Path', '');
      if (LastFiles.Count = 0) and (S <> '') then
        LastFiles.Add(S);
      GLastRecords := StrToInt64Def(Ini.ReadString(LAST_SECTION, 'Records', ''), -1);
      GLastDetail := Ini.ReadString(LAST_SECTION, 'Detail', '');
    finally
      Ini.Free;
    end;
  except
    LastFiles.Clear;
    GLastRecords := -1;
    GLastDetail := '';
  end;
end;

procedure RememberLast(AFiles: TStrings; ARecords: Int64; const ADetail: string);
var
  Ini: TMemIniFile;
  I: Integer;
begin
  GLastLoaded := True;
  LastFiles.Assign(AFiles);
  GLastRecords := ARecords;
  GLastDetail := ADetail;
  try
    Ini := TMemIniFile.Create(FastFileExeDirPath(AGENT_SESSION_FILE), TEncoding.UTF8);
    try
      Ini.EraseSection(LAST_SECTION);
      Ini.WriteString(LAST_SECTION, 'Path', AFiles[0]);
      Ini.WriteString(LAST_SECTION, 'Records', IntToStr(ARecords));
      Ini.WriteString(LAST_SECTION, 'Detail', ADetail);
      if AFiles.Count > 1 then
      begin
        Ini.WriteInteger(LAST_SECTION, 'Count', AFiles.Count);
        for I := 0 to AFiles.Count - 1 do
          Ini.WriteString(LAST_SECTION, 'File' + IntToStr(I + 1), AFiles[I]);
      end;
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
  except
  end;
  for I := 0 to High(GListeners) do
    if Assigned(GListeners[I]) then
      GListeners[I](nil);
end;

function SameEvent(const A, B: TNotifyEvent): Boolean;
begin
  Result := (TMethod(A).Code = TMethod(B).Code) and (TMethod(A).Data = TMethod(B).Data);
end;

procedure AddLastGeneratedFileListener(AEvent: TNotifyEvent);
var
  N: Integer;
begin
  if not Assigned(AEvent) then Exit;
  RemoveLastGeneratedFileListener(AEvent);
  N := Length(GListeners);
  SetLength(GListeners, N + 1);
  GListeners[N] := AEvent;
end;

procedure RemoveLastGeneratedFileListener(AEvent: TNotifyEvent);
var
  I, J: Integer;
begin
  for I := High(GListeners) downto 0 do
    if SameEvent(GListeners[I], AEvent) then
    begin
      for J := I to High(GListeners) - 1 do
        GListeners[J] := GListeners[J + 1];
      SetLength(GListeners, Length(GListeners) - 1);
    end;
end;

function LastGeneratedFile(out APath: string; out ARecords: Int64): Boolean;
begin
  LoadLast;
  APath := '';
  if LastFiles.Count > 0 then
    APath := LastFiles[0];
  ARecords := GLastRecords;
  Result := APath <> '';
end;

function ShowFor(AFiles: TStrings; ARecords: Int64; const ADetail: string): Boolean;
var
  F: TExportDoneForm;
  Chosen: string;
begin
  Result := AFiles.Count > 0;
  if not Result then Exit;
  F := TExportDoneForm.CreateFor(AFiles, ARecords, ADetail);
  try
    if F.ShowModal <> mrOk then Exit;
    Chosen := F.Chosen;
  finally
    F.Free;
  end;
  if Chosen <> '' then
    AssistantHostOpenAndRead(Chosen);
end;

function ExistingFiles(AFiles: TStrings): TStringList;
var
  I: Integer;
  S: string;
begin
  Result := TStringList.Create;
  for I := 0 to AFiles.Count - 1 do
  begin
    S := Trim(AFiles[I]);
    if (S <> '') and FileExists(S) and (Result.IndexOf(S) < 0) then
      Result.Add(S);
  end;
end;

procedure ShowLastGeneratedFileDialog;
var
  L: TStringList;
begin
  LoadLast;
  if LastFiles.Count = 0 then
  begin
    FastFileMsgInfo(TrText('ExportDone.NoneYet'), TrText('ExportDone.ShowLast'));
    Exit;
  end;
  L := ExistingFiles(LastFiles);
  try
    if L.Count = 0 then
      FastFileMsgInfo(Format(TrText('ExportDone.Missing'), [LastFiles[0]]), TrText('ExportDone.ShowLast'))
    else
      ShowFor(L, GLastRecords, GLastDetail);
  finally
    L.Free;
  end;
end;

procedure ShowGeneratedFilesDialog(AFiles: TStrings; ARecords: Int64; const ADetail: string);
var
  L: TStringList;
begin
  if AFiles = nil then Exit;
  L := ExistingFiles(AFiles);
  try
    if L.Count = 0 then Exit;
    RememberLast(L, ARecords, ADetail);
    ShowFor(L, ARecords, ADetail);
  finally
    L.Free;
  end;
end;

procedure ShowGeneratedFileDialog(const AFileName: string; ARecords: Int64);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add(AFileName);
    ShowGeneratedFilesDialog(L, ARecords);
  finally
    L.Free;
  end;
end;

initialization

finalization
  FreeAndNil(GLastFiles);

end.
