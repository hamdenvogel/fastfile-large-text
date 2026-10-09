unit uFastFileMsgDlg;
{ Professional modal messages. Soft idle-workspace gradient + rounded corners.
  Uses plain VCL TButton (reliable ModalResult) — no AlphaBlend / fade timer. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  StdCtrls, Dialogs;

type
  TFfMsgKind = (fmkInfo, fmkSuccess, fmkWarning, fmkError, fmkConfirm);

function FastFileMsgDlg(const AMsg: string; AKind: TFfMsgKind;
  Buttons: TMsgDlgButtons; const ACaption: string = '';
  ADefaultBtn: TMsgDlgBtn = mbOK): Integer;
function FastFileMessageDlg(const AMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint = 0): Integer;
function FastFileMessageBox(const AText, ACaption: string; Flags: UINT): Integer;
procedure FastFileMsgInfo(const AMsg: string; const ACaption: string = '');
procedure FastFileMsgWarn(const AMsg: string; const ACaption: string = '');
procedure FastFileMsgError(const AMsg: string; const ACaption: string = '');
procedure FastFileMsgSuccess(const AMsg: string; const ACaption: string = '');
function FastFileMsgYesNo(const AMsg: string; const ACaption: string = '';
  ADefaultYes: Boolean = True): Boolean;

implementation

uses
  Math, uI18n, uFastFileScale, UnConsts;

const
  MSG_CORNER = 18;
  MSG_ACCENT_W = 5;
  MSG_MIN_W = 400;
  MSG_MAX_W = 500;
  MSG_PAD = 24;
  MSG_ICON = 50;
  MSG_FOOTER = 54;
  MSG_BTN_H = 30;
  MSG_MIN_H = 158;
  CMsgTitle = TColor($00283038);
  CMsgMuted = TColor($00404858);
  CMsgAccentWarn = TColor($0000A5FF);
  CMsgAccentError = TColor($003232E8);
  CMsgAccentOk = TColor($004CAF50);
  CMsgAccentAsk = TColor($00C87828);

type
  TFfMsgForm = class(TForm)
  private
    FKind: TFfMsgKind;
    FIconHost: TPaintBox;
    FCaptionLbl: TLabel;
    FMsg: TLabel;
    FBtnRow: TPanel;
    FUiFont: string;
    FGradTop, FGradBot, FAccent, FBorder: TColor;
    FRoundRgn: HRGN;
    FLaidOut: Boolean;
    procedure FormPaint(Sender: TObject);
    procedure IconPaint(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnClick(Sender: TObject);
    procedure ApplyRoundRegion;
    procedure ResolveColors;
    function BtnCaption(ABtn: TMsgDlgBtn): string;
    function BtnModal(ABtn: TMsgDlgBtn): TModalResult;
    procedure BuildButtons(Buttons: TMsgDlgButtons; ADef: TMsgDlgBtn);
    procedure LayoutContent(const ACaption, AMessage: string);
    function MeasureMsgHeight(const AText: string; AWidth: Integer): Integer;
    function BreakLongWords(const AText: string; AWidth: Integer): string;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateMsg(AOwner: TComponent; AKind: TFfMsgKind); reintroduce;
    destructor Destroy; override;
  end;

function PreferMsgUiFont: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

function MixMsgColor(C1, C2: TColor; C2Pct: Integer): TColor;
var
  R1, G1, B1, R2, G2, B2: Integer;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);
  R1 := GetRValue(C1); G1 := GetGValue(C1); B1 := GetBValue(C1);
  R2 := GetRValue(C2); G2 := GetGValue(C2); B2 := GetBValue(C2);
  Result := RGB(
    R1 + (R2 - R1) * C2Pct div 100,
    G1 + (G2 - G1) * C2Pct div 100,
    B1 + (B2 - B1) * C2Pct div 100);
end;

procedure FillVertex(var V: TRIVERTEX; X, Y: Integer; C: TColor);
begin
  C := ColorToRGB(C);
  V.x := X;
  V.y := Y;
  V.Red := GetRValue(C) shl 8;
  V.Green := GetGValue(C) shl 8;
  V.Blue := GetBValue(C) shl 8;
  V.Alpha := 0;
end;

procedure PaintVerticalGradient(ACanvas: TCanvas; const R: TRect; CTop, CBot: TColor);
var
  V: array[0..1] of TRIVERTEX;
  GR: GRADIENT_RECT;
begin
  FillVertex(V[0], R.Left, R.Top, CTop);
  FillVertex(V[1], R.Right, R.Bottom, CBot);
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  GradientFill(ACanvas.Handle, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V);
end;

constructor TFfMsgForm.CreateMsg(AOwner: TComponent; AKind: TFfMsgKind);
begin
  inherited CreateNew(AOwner);
  FKind := AKind;
  FUiFont := PreferMsgUiFont;
  FRoundRgn := 0;
  FLaidOut := False;
  BorderStyle := bsNone;
  BorderIcons := [];
  Position := poScreenCenter;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnResize := FormResize;
  OnShow := FormShow;
  OnPaint := FormPaint;
  Color := IDLE_WORKSPACE_GRAD_LEFT;
  Font.Name := FUiFont;
  Font.Size := 9;
  Font.Color := CMsgTitle;
  DoubleBuffered := True;
  AlphaBlend := False;
  ResolveColors;
end;

destructor TFfMsgForm.Destroy;
begin
  if FRoundRgn <> 0 then
  begin
    if HandleAllocated then
      SetWindowRgn(Handle, 0, False);
    DeleteObject(FRoundRgn);
    FRoundRgn := 0;
  end;
  inherited Destroy;
end;

procedure TFfMsgForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

procedure TFfMsgForm.ResolveColors;
begin
  FGradTop := IDLE_WORKSPACE_GRAD_LEFT;
  FGradBot := IDLE_WORKSPACE_GRAD_RIGHT;
  FBorder := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, clBlack, 18);
  case FKind of
    fmkWarning:
      begin
        FAccent := CMsgAccentWarn;
        FGradTop := MixMsgColor(IDLE_WORKSPACE_GRAD_LEFT, CMsgAccentWarn, 6);
        FGradBot := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, CMsgAccentWarn, 10);
      end;
    fmkError:
      begin
        FAccent := CMsgAccentError;
        FGradTop := MixMsgColor(IDLE_WORKSPACE_GRAD_LEFT, CMsgAccentError, 5);
        FGradBot := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, CMsgAccentError, 8);
      end;
    fmkConfirm:
      begin
        FAccent := CMsgAccentAsk;
        FGradTop := MixMsgColor(IDLE_WORKSPACE_GRAD_LEFT, CMsgAccentAsk, 5);
        FGradBot := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, CMsgAccentAsk, 8);
      end;
    fmkSuccess:
      begin
        FAccent := CMsgAccentOk;
        FGradTop := MixMsgColor(IDLE_WORKSPACE_GRAD_LEFT, CMsgAccentOk, 5);
        FGradBot := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, CMsgAccentOk, 8);
      end;
  else
    FAccent := MixMsgColor(IDLE_WORKSPACE_GRAD_RIGHT, clNavy, 35);
  end;
end;

procedure TFfMsgForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end
  else if Key = VK_RETURN then
  begin
    Key := 0;
    ModalResult := mrOk;
  end;
end;

procedure TFfMsgForm.ApplyRoundRegion;
var
  R: Integer;
  NewRgn: HRGN;
begin
  if not HandleAllocated then Exit;
  if (ClientWidth < 8) or (ClientHeight < 8) then Exit;
  R := FfPx(MSG_CORNER);
  NewRgn := CreateRoundRectRgn(0, 0, ClientWidth + 1, ClientHeight + 1, R, R);
  SetWindowRgn(Handle, NewRgn, True);
  if FRoundRgn <> 0 then
    DeleteObject(FRoundRgn);
  FRoundRgn := NewRgn;
end;

procedure TFfMsgForm.FormResize(Sender: TObject);
begin
  if not FLaidOut then Exit;
  ApplyRoundRegion;
  Invalidate;
end;

procedure TFfMsgForm.FormShow(Sender: TObject);
begin
  if Assigned(FBtnRow) then
    FBtnRow.BringToFront;
  ApplyRoundRegion;
  Invalidate;
end;

procedure TFfMsgForm.BtnClick(Sender: TObject);
var
  Mr: TModalResult;
begin
  if Sender is TButton then
    Mr := TButton(Sender).ModalResult
  else
    Mr := mrOk;
  if Mr = mrNone then
    Mr := mrOk;
  ModalResult := Mr;
end;

procedure TFfMsgForm.FormPaint(Sender: TObject);
var
  R, AccR, HiR: TRect;
  Rad, AccW: Integer;
begin
  R := ClientRect;
  PaintVerticalGradient(Canvas, R, FGradTop, FGradBot);

  HiR := Rect(R.Left, R.Top, R.Right, R.Top + Max(FfPx(28), R.Bottom div 5));
  PaintVerticalGradient(Canvas, HiR,
    MixMsgColor(FGradTop, clWhite, 22),
    MixMsgColor(FGradTop, FGradBot, 8));

  AccW := FfPx(MSG_ACCENT_W);
  AccR := Rect(FfPx(14), FfPx(18), FfPx(14) + AccW, R.Bottom - FfPx(18));
  Canvas.Brush.Color := FAccent;
  Canvas.Pen.Color := MixMsgColor(FAccent, clWhite, 18);
  Rad := AccW + 2;
  Windows.RoundRect(Canvas.Handle, AccR.Left, AccR.Top, AccR.Right, AccR.Bottom, Rad, Rad);

  Rad := FfPx(MSG_CORNER);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := MixMsgColor(FBorder, FGradBot, 55);
  Windows.RoundRect(Canvas.Handle, 2, 2, R.Right - 2, R.Bottom - 2, Rad - 2, Rad - 2);
  Canvas.Pen.Color := MixMsgColor(FBorder, FGradBot, 28);
  Windows.RoundRect(Canvas.Handle, 1, 1, R.Right - 1, R.Bottom - 1, Rad, Rad);
end;

procedure TFfMsgForm.IconPaint(Sender: TObject);
var
  PB: TPaintBox;
  R: TRect;
  CX, CY, Rad: Integer;
  Ch: string;
begin
  PB := Sender as TPaintBox;
  R := PB.ClientRect;
  { Match surrounding gradient tone so icon host doesn't look like a tile. }
  PB.Canvas.Brush.Color := MixMsgColor(FGradTop, FGradBot, 28);
  PB.Canvas.FillRect(R);

  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Rad := Min(R.Right - R.Left, R.Bottom - R.Top) div 2 - 1;

  PB.Canvas.Pen.Color := MixMsgColor(FAccent, clBlack, 10);
  PB.Canvas.Brush.Color := MixMsgColor(FAccent, clWhite, 8);
  PB.Canvas.Ellipse(CX - Rad, CY - Rad, CX + Rad, CY + Rad);
  PB.Canvas.Brush.Color := MixMsgColor(FAccent, clWhite, 26);
  PB.Canvas.Pen.Color := FAccent;
  PB.Canvas.Ellipse(CX - Rad + 3, CY - Rad + 3, CX + Rad - 3, CY + Rad - 3);
  PB.Canvas.Brush.Color := FAccent;
  PB.Canvas.Ellipse(CX - Rad + 4, CY - Rad + 4, CX + Rad - 4, CY + Rad - 4);

  PB.Canvas.Brush.Style := bsClear;
  PB.Canvas.Font.Name := FUiFont;
  PB.Canvas.Font.Style := [fsBold];
  PB.Canvas.Font.Color := clWhite;
  case FKind of
    fmkWarning: begin PB.Canvas.Font.Size := 18; Ch := '!'; end;
    fmkError:   begin PB.Canvas.Font.Size := 15; Ch := #$00D7; end;
    fmkConfirm: begin PB.Canvas.Font.Size := 16; Ch := '?'; end;
    fmkSuccess: begin PB.Canvas.Font.Size := 14; Ch := #$2713; end;
  else
    begin PB.Canvas.Font.Size := 15; Ch := 'i'; end;
  end;
  PB.Canvas.TextOut(CX - PB.Canvas.TextWidth(Ch) div 2,
    CY - PB.Canvas.TextHeight(Ch) div 2 - 1, Ch);
end;

function TFfMsgForm.BtnCaption(ABtn: TMsgDlgBtn): string;
begin
  case ABtn of
    mbYes:    Result := TrText('Yes');
    mbNo:     Result := TrText('No');
    mbOK:     Result := '&' + TrText('Ok');
    mbCancel: Result := TrText('Cancel');
    mbAbort:  Result := TrText('MsgDlg.Abort');
    mbRetry:  Result := TrText('MsgDlg.Retry');
    mbIgnore: Result := TrText('MsgDlg.Ignore');
    mbAll:    Result := TrText('MsgDlg.All');
    mbNoToAll: Result := TrText('MsgDlg.NoToAll');
    mbYesToAll: Result := TrText('MsgDlg.YesToAll');
    mbClose:  Result := TrText('Close');
  else
    Result := TrText('Ok');
  end;
end;

function TFfMsgForm.BtnModal(ABtn: TMsgDlgBtn): TModalResult;
begin
  case ABtn of
    mbYes: Result := mrYes;
    mbNo: Result := mrNo;
    mbOK: Result := mrOk;
    mbCancel: Result := mrCancel;
    mbAbort: Result := mrAbort;
    mbRetry: Result := mrRetry;
    mbIgnore: Result := mrIgnore;
    mbAll: Result := mrAll;
    mbNoToAll: Result := mrNoToAll;
    mbYesToAll: Result := mrYesToAll;
    mbClose: Result := mrClose;
  else
    Result := mrOk;
  end;
end;

procedure TFfMsgForm.BuildButtons(Buttons: TMsgDlgButtons; ADef: TMsgDlgBtn);
const
  Order: array[0..10] of TMsgDlgBtn = (
    mbYes, mbNo, mbOK, mbCancel, mbAbort, mbRetry, mbIgnore,
    mbAll, mbNoToAll, mbYesToAll, mbClose);
var
  I, Gap, Bw, Bh: Integer;
  B: TButton;
  Measure: TBitmap;
  Cap: string;
begin
  FBtnRow := TPanel.Create(Self);
  FBtnRow.Parent := Self;
  FBtnRow.BevelOuter := bvNone;
  FBtnRow.BevelInner := bvNone;
  FBtnRow.Caption := '';
  FBtnRow.ParentBackground := True;
  FBtnRow.ParentColor := True;

  Gap := FfPx(10);
  Bh := FfPx(MSG_BTN_H);
  Measure := TBitmap.Create;
  try
    Measure.SetSize(1, 1);
    Measure.Canvas.Font.Name := FUiFont;
    Measure.Canvas.Font.Size := 9;
    for I := Low(Order) to High(Order) do
      if Order[I] in Buttons then
      begin
        Cap := BtnCaption(Order[I]);
        Bw := Measure.Canvas.TextWidth(StringReplace(Cap, '&', '', [rfReplaceAll])) + FfPx(40);
        if Bw < FfPx(100) then Bw := FfPx(100);
        B := TButton.Create(Self);
        B.Parent := FBtnRow;
        B.Caption := Cap;
        B.ModalResult := BtnModal(Order[I]);
        B.Default := Order[I] = ADef;
        B.Cancel := Order[I] in [mbCancel, mbNo];
        B.Height := Bh;
        B.Width := Bw;
        B.Font.Name := FUiFont;
        B.Font.Size := 9;
        B.Font.Color := CMsgTitle;
        B.OnClick := BtnClick;
        B.TabStop := True;
      end;
  finally
    Measure.Free;
  end;
end;

{ DT_WORDBREAK so' quebra em espacos: caminhos longos sem espaco eram cortados.
  Palavras mais largas que AWidth sao partidas (de preferencia apos \ ou /). }
function TFfMsgForm.BreakLongWords(const AText: string; AWidth: Integer): string;
var
  Bmp: TBitmap;
  Lines, Words: TStringList;
  i, j, k, Cut: Integer;
  W, Chunk, Piece, OutLine: string;
begin
  Result := AText;
  if AWidth < 40 then Exit;
  Bmp := TBitmap.Create;
  Lines := TStringList.Create;
  Words := TStringList.Create;
  try
    Bmp.SetSize(1, 1);
    Bmp.Canvas.Font.Name := FUiFont;
    Bmp.Canvas.Font.Size := 11;
    Lines.Text := AText;
    Words.Delimiter := ' ';
    Words.StrictDelimiter := True;
    for i := 0 to Lines.Count - 1 do
    begin
      Words.DelimitedText := Lines[i];
      OutLine := '';
      for j := 0 to Words.Count - 1 do
      begin
        W := Words[j];
        Piece := '';
        while Bmp.Canvas.TextWidth(W) > AWidth do
        begin
          Cut := 1;
          while (Cut < Length(W)) and (Bmp.Canvas.TextWidth(Copy(W, 1, Cut + 1)) <= AWidth) do
            Inc(Cut);
          for k := Cut downto Max(1, Cut div 2) do
            if CharInSet(W[k], ['\', '/', '_', '-', '.', ',', ';']) then
            begin
              Cut := k;
              Break;
            end;
          Chunk := Copy(W, 1, Cut);
          Delete(W, 1, Cut);
          Piece := Piece + Chunk + sLineBreak;
        end;
        if j > 0 then
          OutLine := OutLine + ' ';
        OutLine := OutLine + Piece + W;
      end;
      Lines[i] := OutLine;
    end;
    Result := TrimRight(Lines.Text);
  finally
    Words.Free;
    Lines.Free;
    Bmp.Free;
  end;
end;

function TFfMsgForm.MeasureMsgHeight(const AText: string; AWidth: Integer): Integer;
var
  R: TRect;
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(1, 1);
    Bmp.Canvas.Font.Name := FUiFont;
    Bmp.Canvas.Font.Size := 11;
    R := Rect(0, 0, Max(40, AWidth), 0);
    DrawText(Bmp.Canvas.Handle, PChar(AText), Length(AText), R,
      DT_CALCRECT or DT_WORDBREAK or DT_LEFT or DT_NOPREFIX);
    Result := R.Bottom - R.Top;
  finally
    Bmp.Free;
  end;
  if Result < FfPx(28) then Result := FfPx(28);
  if Result > Max(FfPx(220), Screen.WorkAreaHeight * 55 div 100) then
    Result := Max(FfPx(220), Screen.WorkAreaHeight * 55 div 100);
end;

procedure TFfMsgForm.LayoutContent(const ACaption, AMessage: string);
var
  IconSz, Pad, LeftPad, ContentW, MsgH, MinW, MaxW, NeedH, I, X, Gap, TotalW: Integer;
  B: TButton;
  MsgTop, CapH, FooterH: Integer;
  Body: string;
begin
  Color := FGradTop;

  if Trim(ACaption) <> '' then
  begin
    FCaptionLbl.Caption := ACaption;
    FCaptionLbl.Visible := True;
    CapH := FfPx(22);
  end
  else
  begin
    FCaptionLbl.Caption := '';
    FCaptionLbl.Visible := False;
    CapH := 0;
  end;

  FMsg.Font.Name := FUiFont;
  FMsg.Font.Size := 11;
  FMsg.Font.Color := CMsgTitle;

  MaxW := Screen.WorkAreaWidth * 44 div 100;
  if MaxW > FfPx(MSG_MAX_W) then MaxW := FfPx(MSG_MAX_W);
  if MaxW < FfPx(MSG_MIN_W) then MaxW := FfPx(MSG_MIN_W);
  MinW := FfPx(MSG_MIN_W);
  IconSz := FfPx(MSG_ICON);
  Pad := FfPx(MSG_PAD);
  LeftPad := FfPx(16) + FfPx(MSG_ACCENT_W) + FfPx(16);
  FooterH := FfPx(MSG_FOOTER);

  ContentW := MaxW - LeftPad - IconSz - Pad - FfPx(16);
  Body := BreakLongWords(AMessage, ContentW - FfPx(6));
  FMsg.Caption := Body;
  MsgH := MeasureMsgHeight(Body, ContentW);
  if MsgH < FfPx(30) then MsgH := FfPx(30);

  ClientWidth := Max(MinW, MaxW);
  NeedH := Pad + CapH + Max(IconSz, MsgH) + FfPx(18) + FooterH + FfPx(8);
  if NeedH < FfPx(MSG_MIN_H) then NeedH := FfPx(MSG_MIN_H);
  ClientHeight := NeedH;

  FBtnRow.SetBounds(0, ClientHeight - FooterH, ClientWidth, FooterH);
  FBtnRow.BringToFront;

  if CapH > 0 then
    FCaptionLbl.SetBounds(LeftPad + IconSz + FfPx(16), Pad,
      ClientWidth - LeftPad - IconSz - Pad - FfPx(16), CapH);

  MsgTop := Pad + CapH;
  if CapH > 0 then
    Inc(MsgTop, FfPx(8));
  if MsgH < IconSz then
    MsgTop := MsgTop + (IconSz - MsgH) div 2;

  FIconHost.SetBounds(LeftPad, Pad + CapH, IconSz, IconSz);
  FMsg.SetBounds(LeftPad + IconSz + FfPx(16), MsgTop,
    Max(120, ClientWidth - LeftPad - IconSz - Pad - FfPx(16)), MsgH);

  if FMsg.Top + FMsg.Height > FBtnRow.Top - FfPx(4) then
    FMsg.Height := Max(FfPx(20), FBtnRow.Top - FfPx(4) - FMsg.Top);

  Gap := FfPx(10);
  TotalW := 0;
  for I := 0 to FBtnRow.ControlCount - 1 do
    if FBtnRow.Controls[I] is TButton then
    begin
      if TotalW > 0 then Inc(TotalW, Gap);
      Inc(TotalW, TButton(FBtnRow.Controls[I]).Width);
    end;
  X := FBtnRow.ClientWidth - TotalW - FfPx(24);
  if X < FfPx(20) then X := FfPx(20);
  for I := 0 to FBtnRow.ControlCount - 1 do
    if FBtnRow.Controls[I] is TButton then
    begin
      B := TButton(FBtnRow.Controls[I]);
      B.Left := X;
      B.Top := (FBtnRow.ClientHeight - B.Height) div 2;
      Inc(X, B.Width + Gap);
    end;

  FBtnRow.BringToFront;
  ApplyRoundRegion;
  FLaidOut := True;
  Invalidate;
end;

function FastFileMsgDlg(const AMsg: string; AKind: TFfMsgKind;
  Buttons: TMsgDlgButtons; const ACaption: string;
  ADefaultBtn: TMsgDlgBtn): Integer;
var
  Frm: TFfMsgForm;
  Cap, Body: string;
  DefBtn: TMsgDlgBtn;
begin
  Body := Trim(AMsg);
  if Body = '' then
  begin
    Result := mrOk;
    Exit;
  end;
  Cap := Trim(ACaption);
  if Cap = '' then
    case AKind of
      fmkWarning: Cap := TrText('Warning');
      fmkError: Cap := TrText('Error');
      fmkConfirm: Cap := TrText('Confirmation');
      fmkSuccess: Cap := TrText('Information');
    else
      Cap := TrText('Information');
    end;

  if Buttons = [] then
    Buttons := [mbOK];
  if ADefaultBtn in Buttons then
    DefBtn := ADefaultBtn
  else if mbOK in Buttons then
    DefBtn := mbOK
  else if mbYes in Buttons then
    DefBtn := mbYes
  else
    DefBtn := mbCancel;

  Frm := TFfMsgForm.CreateMsg(Application, AKind);
  try
    Frm.Caption := Cap;

    Frm.BuildButtons(Buttons, DefBtn);

    Frm.FCaptionLbl := TLabel.Create(Frm);
    Frm.FCaptionLbl.Parent := Frm;
    Frm.FCaptionLbl.Transparent := True;
    Frm.FCaptionLbl.ParentFont := False;
    Frm.FCaptionLbl.Font.Name := Frm.FUiFont;
    Frm.FCaptionLbl.Font.Size := 11;
    Frm.FCaptionLbl.Font.Style := [fsBold];
    Frm.FCaptionLbl.Font.Color := CMsgMuted;

    Frm.FIconHost := TPaintBox.Create(Frm);
    Frm.FIconHost.Parent := Frm;
    Frm.FIconHost.OnPaint := Frm.IconPaint;

    Frm.FMsg := TLabel.Create(Frm);
    Frm.FMsg.Parent := Frm;
    Frm.FMsg.Transparent := True;
    Frm.FMsg.WordWrap := True;
    Frm.FMsg.ParentFont := False;
    Frm.FMsg.Font.Name := Frm.FUiFont;
    Frm.FMsg.Font.Size := 11;
    Frm.FMsg.Font.Color := CMsgTitle;

    Frm.LayoutContent(Cap, Body);
    Frm.FBtnRow.BringToFront;

    Result := Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

function FastFileMessageDlg(const AMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
var
  Kind: TFfMsgKind;
begin
  case DlgType of
    mtWarning: Kind := fmkWarning;
    mtError: Kind := fmkError;
    mtConfirmation: Kind := fmkConfirm;
  else
    Kind := fmkInfo;
  end;
  Result := FastFileMsgDlg(AMsg, Kind, Buttons);
end;

function FlagsToKind(Flags: UINT): TFfMsgKind;
var
  Icon: UINT;
begin
  Icon := Flags and $000000F0;
  case Icon of
    MB_ICONERROR: Result := fmkError;
    MB_ICONWARNING: Result := fmkWarning;
    MB_ICONQUESTION: Result := fmkConfirm;
    MB_ICONINFORMATION: Result := fmkInfo;
  else
    Result := fmkInfo;
  end;
end;

function FlagsToButtons(Flags: UINT): TMsgDlgButtons;
var
  Style: UINT;
begin
  Style := Flags and $0000000F;
  case Style of
    MB_OKCANCEL: Result := [mbOK, mbCancel];
    MB_YESNO: Result := [mbYes, mbNo];
    MB_YESNOCANCEL: Result := [mbYes, mbNo, mbCancel];
    MB_RETRYCANCEL: Result := [mbRetry, mbCancel];
    MB_ABORTRETRYIGNORE: Result := [mbAbort, mbRetry, mbIgnore];
  else
    Result := [mbOK];
  end;
end;

function ModalToMessageBoxId(AResult: Integer): Integer;
begin
  case AResult of
    mrOk: Result := IDOK;
    mrCancel: Result := IDCANCEL;
    mrYes: Result := IDYES;
    mrNo: Result := IDNO;
    mrAbort: Result := IDABORT;
    mrRetry: Result := IDRETRY;
    mrIgnore: Result := IDIGNORE;
  else
    Result := IDCANCEL;
  end;
end;

function FastFileMessageBox(const AText, ACaption: string; Flags: UINT): Integer;
var
  Kind: TFfMsgKind;
  Buttons: TMsgDlgButtons;
  Cap: string;
  Mr: Integer;
begin
  Kind := FlagsToKind(Flags);
  Buttons := FlagsToButtons(Flags);
  Cap := Trim(ACaption);
  if Cap = '' then
    case Kind of
      fmkWarning: Cap := TrText('Warning');
      fmkError: Cap := TrText('Error');
      fmkConfirm: Cap := TrText('Confirmation');
    else
      Cap := TrText('Information');
    end;
  Mr := FastFileMsgDlg(AText, Kind, Buttons, Cap);
  Result := ModalToMessageBoxId(Mr);
end;

procedure FastFileMsgInfo(const AMsg: string; const ACaption: string);
begin
  FastFileMsgDlg(AMsg, fmkInfo, [mbOK], ACaption);
end;

procedure FastFileMsgWarn(const AMsg: string; const ACaption: string);
begin
  FastFileMsgDlg(AMsg, fmkWarning, [mbOK], ACaption);
end;

procedure FastFileMsgError(const AMsg: string; const ACaption: string);
begin
  FastFileMsgDlg(AMsg, fmkError, [mbOK], ACaption);
end;

procedure FastFileMsgSuccess(const AMsg: string; const ACaption: string);
begin
  FastFileMsgDlg(AMsg, fmkSuccess, [mbOK], ACaption);
end;

function FastFileMsgYesNo(const AMsg: string; const ACaption: string;
  ADefaultYes: Boolean): Boolean;
var
  Cap: string;
  Def: TMsgDlgBtn;
begin
  Cap := ACaption;
  if Trim(Cap) = '' then
    Cap := TrText('Confirmation');
  if ADefaultYes then
    Def := mbYes
  else
    Def := mbNo;
  Result := FastFileMsgDlg(AMsg, fmkConfirm, [mbYes, mbNo], Cap, Def) = mrYes;
end;

end.
