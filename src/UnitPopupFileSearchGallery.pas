unit UnitPopupFileSearchGallery;

{ Compact gallery popup for file-toolbar "Search tools" — same visual language
  as UnitPopupToolGallery (Mais ferramentas): accent strip, soft item hosts,
  bold title + muted hint, large left glyph. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  StdCtrls, ImgList, Buttons, sPanel, sLabel, sSpeedButton, sSkinProvider, sBevel;

type
  TFileSearchGalleryItemHost = class(TsPanel)
  private
    FSelectedLook: Boolean;
  public
    procedure PaintWindow(DC: HDC); override;
    property SelectedLook: Boolean read FSelectedLook write FSelectedLook;
  end;

  TFormPopupFileSearchGallery = class(TForm)
  private
    FSkin: TsSkinProvider;
    FRoot: TsPanel;
    FAccent: TsPanel;
    FBody: TsPanel;
    FHeader: TsPanel;
    FLblHeader: TsLabel;
    FSep: TsBevel;
    FHostFind: TFileSearchGalleryItemHost;
    FHostFilter: TFileSearchGalleryItemHost;
    FBtnFind: TsSpeedButton;
    FBtnFilter: TsSpeedButton;
    FLblFindHint: TsLabel;
    FLblFilterHint: TsLabel;
    FOnPickFind: TNotifyEvent;
    FOnPickFilter: TNotifyEvent;
    FFindVisibleState: Boolean;
    FFilterVisibleState: Boolean;
    function ScaledPx(ADesignPx: Integer): Integer;
    procedure BuildChrome;
    procedure StyleHost(AHost: TFileSearchGalleryItemHost; ASelected: Boolean);
    procedure StyleItem(ABtn: TsSpeedButton);
    procedure PlaceHints;
    procedure BtnFindClick(Sender: TObject);
    procedure BtnFilterClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Prepare(AImages: TCustomImageList; AFindImageIndex, AFilterImageIndex: Integer;
      AFindPanelVisible, AFilterPanelVisible: Boolean);
    procedure RelayoutChrome;
    procedure ClosePopup(AnimationAllowed: Boolean = False);
    property OnPickFind: TNotifyEvent read FOnPickFind write FOnPickFind;
    property OnPickFilter: TNotifyEvent read FOnPickFilter write FOnPickFilter;
  end;

var
  FormPopupFileSearchGallery: TFormPopupFileSearchGallery;

implementation

uses
  uI18n;

const
  GALLERY_ITEM_H = 68;
  GALLERY_HEADER_H = 32;
  GALLERY_SEP_H = 10;
  GALLERY_BODY_PAD = 12;
  GALLERY_ACCENT_W = 5;
  GALLERY_MIN_W = 360;
  GALLERY_GRAD_TOP = $00FFF8F2;
  GALLERY_GRAD_BOT = $00F4E6D6;
  GALLERY_GRAD_SEL_TOP = $00FFEAD8;
  GALLERY_GRAD_SEL_BOT = $00F0D4BC;
  GALLERY_GRAD_BORDER = $00E2D0BC;
  GALLERY_GRAD_SEL_BORDER = $00D0B898;
  GALLERY_HINT_TEXT = $00888888;

function GalleryUIFontName: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

procedure PaintSoftBlueGradient(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  Y, H: Integer;
  C1, C2, C: TColor;
  R1, G1, B1, R2, G2, B2: Integer;
  T: Double;
begin
  if ASelected then
  begin
    C1 := GALLERY_GRAD_SEL_TOP;
    C2 := GALLERY_GRAD_SEL_BOT;
  end
  else
  begin
    C1 := GALLERY_GRAD_TOP;
    C2 := GALLERY_GRAD_BOT;
  end;
  R1 := GetRValue(C1); G1 := GetGValue(C1); B1 := GetBValue(C1);
  R2 := GetRValue(C2); G2 := GetGValue(C2); B2 := GetBValue(C2);
  H := R.Bottom - R.Top;
  if H <= 0 then Exit;
  for Y := 0 to H - 1 do
  begin
    T := Y / (H - 1);
    C := RGB(
      R1 + Round((R2 - R1) * T),
      G1 + Round((G2 - G1) * T),
      B1 + Round((B2 - B1) * T));
    ACanvas.Pen.Color := C;
    ACanvas.MoveTo(R.Left, R.Top + Y);
    ACanvas.LineTo(R.Right, R.Top + Y);
  end;
  if ASelected then
    ACanvas.Pen.Color := GALLERY_GRAD_SEL_BORDER
  else
    ACanvas.Pen.Color := GALLERY_GRAD_BORDER;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Rectangle(R);
end;

procedure TFileSearchGalleryItemHost.PaintWindow(DC: HDC);
var
  C: TCanvas;
  R: TRect;
begin
  inherited PaintWindow(DC);
  C := TCanvas.Create;
  try
    C.Handle := DC;
    R := ClientRect;
    InflateRect(R, -1, -3);
    PaintSoftBlueGradient(C, R, FSelectedLook);
  finally
    C.Handle := 0;
    C.Free;
  end;
end;

constructor TFormPopupFileSearchGallery.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  KeyPreview := True;
  Position := poDesigned;
  Width := GALLERY_MIN_W;
  Height := 200;
  Color := clWindow;
  OnKeyDown := FormKeyDown;
  BuildChrome;
end;

function TFormPopupFileSearchGallery.ScaledPx(ADesignPx: Integer): Integer;
var
  Ppi: Integer;
begin
  Ppi := PixelsPerInch;
  if Ppi <= 0 then
    Ppi := Screen.PixelsPerInch;
  if Ppi <= 0 then
    Ppi := 96;
  Result := MulDiv(ADesignPx, Ppi, 96);
end;

procedure TFormPopupFileSearchGallery.BuildChrome;
begin
  FSkin := TsSkinProvider.Create(Self);
  FSkin.SkinData.SkinSection := 'DIALOG';

  FRoot := TsPanel.Create(Self);
  FRoot.Parent := Self;
  FRoot.Align := alClient;
  FRoot.BevelOuter := bvNone;
  FRoot.SkinData.SkinSection := 'PANEL';

  FAccent := TsPanel.Create(Self);
  FAccent.Parent := FRoot;
  FAccent.Align := alLeft;
  FAccent.Width := ScaledPx(GALLERY_ACCENT_W);
  FAccent.BevelOuter := bvNone;
  FAccent.SkinData.CustomColor := True;
  FAccent.Color := $00D8CFC6;

  FBody := TsPanel.Create(Self);
  FBody.Parent := FRoot;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.Padding.Left := ScaledPx(GALLERY_BODY_PAD);
  FBody.Padding.Right := ScaledPx(GALLERY_BODY_PAD);
  FBody.Padding.Top := ScaledPx(8);
  FBody.Padding.Bottom := ScaledPx(10);
  FBody.SkinData.SkinSection := 'TRANSPARENT';

  FHeader := TsPanel.Create(Self);
  FHeader.Parent := FBody;
  FHeader.Align := alTop;
  FHeader.Height := ScaledPx(GALLERY_HEADER_H);
  FHeader.BevelOuter := bvNone;
  FHeader.SkinData.SkinSection := 'TRANSPARENT';

  FLblHeader := TsLabel.Create(Self);
  FLblHeader.Parent := FHeader;
  FLblHeader.Align := alClient;
  FLblHeader.Layout := tlCenter;
  FLblHeader.Transparent := True;
  FLblHeader.ParentFont := False;
  FLblHeader.Font.Name := GalleryUIFontName;
  FLblHeader.Font.Style := [fsBold];
  FLblHeader.Font.Height := ScaledPx(-13);
  FLblHeader.Font.Color := $00666666;
  FLblHeader.Caption := TrText('FileSearch.MoreTools');

  FSep := TsBevel.Create(Self);
  FSep.Parent := FBody;
  FSep.Align := alTop;
  FSep.Height := ScaledPx(GALLERY_SEP_H);
  FSep.Shape := bsTopLine;

  FHostFind := TFileSearchGalleryItemHost.Create(Self);
  FHostFind.Parent := FBody;
  FHostFind.Align := alTop;
  FHostFind.Height := ScaledPx(GALLERY_ITEM_H);
  FHostFind.BevelOuter := bvNone;
  FHostFind.SkinData.SkinSection := 'TRANSPARENT';
  StyleHost(FHostFind, False);

  FBtnFind := TsSpeedButton.Create(Self);
  FBtnFind.Parent := FHostFind;
  FBtnFind.Align := alClient;
  FBtnFind.OnClick := BtnFindClick;
  StyleItem(FBtnFind);

  FLblFindHint := TsLabel.Create(Self);
  FLblFindHint.Parent := FHostFind;
  FLblFindHint.Transparent := True;
  FLblFindHint.Enabled := False;
  FLblFindHint.ParentFont := False;
  FLblFindHint.Font.Name := GalleryUIFontName;
  FLblFindHint.Font.Height := ScaledPx(-10);
  FLblFindHint.Font.Color := GALLERY_HINT_TEXT;
  FLblFindHint.Caption := '';

  FHostFilter := TFileSearchGalleryItemHost.Create(Self);
  FHostFilter.Parent := FBody;
  FHostFilter.Align := alTop;
  FHostFilter.Height := ScaledPx(GALLERY_ITEM_H);
  FHostFilter.BevelOuter := bvNone;
  FHostFilter.SkinData.SkinSection := 'TRANSPARENT';
  StyleHost(FHostFilter, False);

  FBtnFilter := TsSpeedButton.Create(Self);
  FBtnFilter.Parent := FHostFilter;
  FBtnFilter.Align := alClient;
  FBtnFilter.OnClick := BtnFilterClick;
  StyleItem(FBtnFilter);

  FLblFilterHint := TsLabel.Create(Self);
  FLblFilterHint.Parent := FHostFilter;
  FLblFilterHint.Transparent := True;
  FLblFilterHint.Enabled := False;
  FLblFilterHint.ParentFont := False;
  FLblFilterHint.Font.Name := GalleryUIFontName;
  FLblFilterHint.Font.Height := ScaledPx(-10);
  FLblFilterHint.Font.Color := GALLERY_HINT_TEXT;
  FLblFilterHint.Caption := '';
end;

procedure TFormPopupFileSearchGallery.StyleHost(AHost: TFileSearchGalleryItemHost; ASelected: Boolean);
begin
  if not Assigned(AHost) then Exit;
  AHost.SelectedLook := ASelected;
  if ASelected then
    AHost.Color := GALLERY_GRAD_SEL_TOP
  else
    AHost.Color := GALLERY_GRAD_TOP;
  AHost.Invalidate;
end;

procedure TFormPopupFileSearchGallery.StyleItem(ABtn: TsSpeedButton);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.Flat := True;
  ABtn.Layout := blGlyphLeft;
  ABtn.Alignment := taLeftJustify;
  ABtn.TextAlignment := taLeftJustify;
  ABtn.Margin := ScaledPx(14);
  ABtn.Spacing := ScaledPx(14);
  ABtn.ParentFont := False;
  ABtn.Font.Name := GalleryUIFontName;
  ABtn.Font.Height := ScaledPx(-13);
  ABtn.Font.Style := [fsBold];
  ABtn.Font.Color := clWindowText;
  ABtn.AnimatEvents := [];
  try
    ABtn.SkinData.SkinSection := 'TRANSPARENT';
    ABtn.Blend := 0;
    ABtn.Reflected := False;
  except
  end;
end;

procedure TFormPopupFileSearchGallery.PlaceHints;
begin
  if Assigned(FLblFindHint) then
  begin
    FLblFindHint.BringToFront;
    FLblFindHint.Left := FHostFind.Width - FLblFindHint.Width - ScaledPx(14);
    if FLblFindHint.Left < ScaledPx(56) then
      FLblFindHint.Left := ScaledPx(56);
    FLblFindHint.Top := (FHostFind.Height - FLblFindHint.Height) div 2;
  end;
  if Assigned(FLblFilterHint) then
  begin
    FLblFilterHint.BringToFront;
    FLblFilterHint.Left := FHostFilter.Width - FLblFilterHint.Width - ScaledPx(14);
    if FLblFilterHint.Left < ScaledPx(56) then
      FLblFilterHint.Left := ScaledPx(56);
    FLblFilterHint.Top := (FHostFilter.Height - FLblFilterHint.Height) div 2;
  end;
end;

procedure TFormPopupFileSearchGallery.Prepare(AImages: TCustomImageList;
  AFindImageIndex, AFilterImageIndex: Integer;
  AFindPanelVisible, AFilterPanelVisible: Boolean);
var
  CapFind, CapFilter: string;
begin
  FFindVisibleState := AFindPanelVisible;
  FFilterVisibleState := AFilterPanelVisible;

  FLblHeader.Caption := StringReplace(TrText('FileSearch.MoreTools'), #13#10, ' ', [rfReplaceAll]);

  if AFindPanelVisible then
    CapFind := TrText('FileSearch.HideFind')
  else
    CapFind := TrText('FileSearch.ShowFind');
  if AFilterPanelVisible then
    CapFilter := TrText('FileSearch.HideFilter')
  else
    CapFilter := TrText('FileSearch.ShowFilter');

  FBtnFind.Caption := CapFind;
  FBtnFind.Hint := CapFind;
  FBtnFind.Images := AImages;
  FBtnFind.ImageIndex := AFindImageIndex;
  FLblFindHint.Caption := 'Ctrl+F';

  FBtnFilter.Caption := CapFilter;
  FBtnFilter.Hint := CapFilter;
  FBtnFilter.Images := AImages;
  FBtnFilter.ImageIndex := AFilterImageIndex;
  FLblFilterHint.Caption := 'Ctrl+L';

  StyleItem(FBtnFind);
  StyleItem(FBtnFilter);
  StyleHost(FHostFind, False);
  StyleHost(FHostFilter, False);
  RelayoutChrome;
end;

procedure TFormPopupFileSearchGallery.RelayoutChrome;
var
  NeedH, NeedW: Integer;
begin
  FAccent.Width := ScaledPx(GALLERY_ACCENT_W);
  FHeader.Height := ScaledPx(GALLERY_HEADER_H);
  FSep.Height := ScaledPx(GALLERY_SEP_H);
  FHostFind.Height := ScaledPx(GALLERY_ITEM_H);
  FHostFilter.Height := ScaledPx(GALLERY_ITEM_H);
  FBody.Padding.Left := ScaledPx(GALLERY_BODY_PAD);
  FBody.Padding.Right := ScaledPx(GALLERY_BODY_PAD);

  NeedW := ScaledPx(GALLERY_MIN_W);
  NeedH := ScaledPx(8 + GALLERY_HEADER_H + GALLERY_SEP_H + GALLERY_ITEM_H * 2 + 10 + 4);
  if Width < NeedW then
    Width := NeedW;
  Height := NeedH;
  PlaceHints;
end;

procedure TFormPopupFileSearchGallery.ClosePopup(AnimationAllowed: Boolean = False);
begin
  if Assigned(FSkin) and (not AnimationAllowed) then
  begin
    FSkin.AllowAnimation := False;
    Close;
    FSkin.AllowAnimation := True;
    Application.ProcessMessages;
  end
  else
    Close;
end;

procedure TFormPopupFileSearchGallery.BtnFindClick(Sender: TObject);
begin
  StyleHost(FHostFind, True);
  if Assigned(FOnPickFind) then
    FOnPickFind(Self);
  ClosePopup(False);
end;

procedure TFormPopupFileSearchGallery.BtnFilterClick(Sender: TObject);
begin
  StyleHost(FHostFilter, True);
  if Assigned(FOnPickFilter) then
    FOnPickFilter(Self);
  ClosePopup(False);
end;

procedure TFormPopupFileSearchGallery.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ClosePopup(False);
  end;
end;

end.
