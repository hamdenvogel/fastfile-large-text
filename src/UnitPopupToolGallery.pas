unit UnitPopupToolGallery;

{ Tools gallery dropdown: polished list rows (bold title + muted shortcut),
  grouped sections, partial search. Height from visible content. }

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, sSpeedButton, sPanel, sBevel, sLabel, sEdit, ExtCtrls,
  sSkinProvider, acAlphaImageList, System.ImageList, Vcl.ImgList, Vcl.StdCtrls;

type
  TWinControlAccess = class(TWinControl);

  TGalleryItemHost = class(TsPanel)
  private
    FSelectedLook: Boolean;
  public
    procedure PaintWindow(DC: HDC); override;
    property SelectedLook: Boolean read FSelectedLook write FSelectedLook;
  end;

  TFormPopupToolGallery = class(TForm)
    sPanel1: TsPanel;
    pnlAccent: TsPanel;
    pnlBody: TsPanel;
    pnlGalleryHeader: TsPanel;
    lblGalleryHeader: TsLabel;
    pnlSearchRow: TsPanel;
    btnSearchGlyph: TsSpeedButton;
    edtGallerySearch: TsEdit;
    btnClearSearch: TsSpeedButton;
    sBevelHeader: TsBevel;
    lblGroupSplit: TsLabel;
    btnGallerySplitPattern: TsSpeedButton;
    btnGallerySplitEqual: TsSpeedButton;
    btnGalleryExtractParts: TsSpeedButton;
    sBevel1: TsBevel;
    lblGroupFind: TsLabel;
    btnGalleryFindFiles: TsSpeedButton;
    sBevel2: TsBevel;
    lblGroupAppearance: TsLabel;
    btnGallerySelectSkin: TsSpeedButton;
    sSkinProvider1: TsSkinProvider;
    imgSearchGlyphs: TsCharImageList;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtGallerySearchChange(Sender: TObject);
    procedure edtGallerySearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSearchGlyphClick(Sender: TObject);
    procedure btnClearSearchClick(Sender: TObject);
  private
    FShortcutLbl: array[0..4] of TsLabel;
    FItemHost: array[0..4] of TGalleryItemHost;
    FItemShortcut: array[0..4] of string;
    FItemSearchText: array[0..4] of string;
    FSelectedTag: Integer;
    FFileSearchMode: Boolean;
    function ItemButton(ATag: Integer): TsSpeedButton;
    function BodyChildIndex(AControl: TControl): Integer;
    function HostOrItem(ATag: Integer): TControl;
    function ScaledPx(ADesignPx: Integer): Integer;
    procedure EnsureShortcutLabels;
    procedure EnsureItemHosts;
    procedure NormalizeGalleryBodyOrder;
    procedure StyleItemBtn(ABtn: TsSpeedButton; ASelected: Boolean);
    procedure StyleItemHost(AHost: TGalleryItemHost; ASelected: Boolean);
    procedure PlaceShortcutLabels;
    procedure StyleSearchBox;
    procedure ApplySearchCue;
    procedure UpdateClearSearchBtn;
    procedure ClearSearchText;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ClosePopup(AnimationAllowed: Boolean = False);
    procedure SyncItem(ATarget, ASource: TsSpeedButton);
    procedure ConfigureFileSearchMode(AImages: TCustomImageList;
      AFindImageIndex, AFilterImageIndex, ABookmarkImageIndex: Integer;
      const AFindTitle, AFindHint, AFindShortcut: string;
      const AFilterTitle, AFilterHint, AFilterShortcut: string;
      const ABookmarkTitle, ABookmarkHint, ABookmarkShortcut: string);
    procedure SetSelectedTag(ATag: Integer);
    function SelectedTag: Integer;
    procedure PrepareLayout;
    procedure ApplyGalleryFilter;
    procedure RelayoutChrome;
    procedure FocusSearch;
    property FileSearchMode: Boolean read FFileSearchMode;
  end;

var
  FormPopupToolGallery: TFormPopupToolGallery;

implementation

{$R *.dfm}

uses
  uI18n;

const
  GALLERY_ITEM_H = 68;
  GALLERY_TITLE_H = 26;
  GALLERY_SEARCH_H = 28;
  GALLERY_HEADER_PAD = 4;
  GALLERY_HEADER_H = GALLERY_TITLE_H + GALLERY_SEARCH_H + GALLERY_HEADER_PAD; { ~58 }
  GALLERY_GROUP_H = 24;
  GALLERY_SEP_H = 12;
  GALLERY_HEADER_SEP_H = 10;
  GALLERY_BODY_PAD = 12;
  GALLERY_ACCENT_W = 5;
  GALLERY_MIN_W = 400;
  GALLERY_ICON_SLOT = 48;
  GALLERY_SIDE_PAD = 44;
  GALLERY_SHORTCUT_RESERVE = 88;
  EM_SETCUEBANNER = $1501;
  GALLERY_GROUP_TEXT = $00666666;
  GALLERY_SHORTCUT_TEXT = $00888888;
  { Soft blue used elsewhere (ListView selection $00E8F4FF family). }
  GALLERY_GRAD_TOP = $00FFF8F2;
  GALLERY_GRAD_BOT = $00F4E6D6;
  GALLERY_GRAD_SEL_TOP = $00FFEAD8;
  GALLERY_GRAD_SEL_BOT = $00F0D4BC;
  GALLERY_GRAD_BORDER = $00E2D0BC;
  GALLERY_GRAD_SEL_BORDER = $00D0B898;

procedure PaintSoftBlueGradient(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  V: array[0..1] of TTriVertex;
  GR: TGradientRect;
  C1, C2, Border: TColor;

  procedure FillVertex(var Vert: TTriVertex; AX, AY: Integer; AColor: TColor);
  var
    RGB: COLORREF;
  begin
    RGB := ColorToRGB(AColor);
    Vert.X := AX;
    Vert.Y := AY;
    Vert.Red := GetRValue(RGB) shl 8;
    Vert.Green := GetGValue(RGB) shl 8;
    Vert.Blue := GetBValue(RGB) shl 8;
    Vert.Alpha := 0;
  end;

begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
  if ASelected then
  begin
    C1 := GALLERY_GRAD_SEL_TOP;
    C2 := GALLERY_GRAD_SEL_BOT;
    Border := GALLERY_GRAD_SEL_BORDER;
  end
  else
  begin
    C1 := GALLERY_GRAD_TOP;
    C2 := GALLERY_GRAD_BOT;
    Border := GALLERY_GRAD_BORDER;
  end;
  FillVertex(V[0], R.Left, R.Top, C1);
  FillVertex(V[1], R.Right, R.Bottom, C2);
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  GradientFill(ACanvas.Handle, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V);
  ACanvas.Pen.Color := Border;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 10, 10);
end;

function GalleryUIFontName: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else if Assigned(Application.MainForm) and (Trim(Application.MainForm.Font.Name) <> '') then
    Result := Application.MainForm.Font.Name
  else
    Result := 'Tahoma';
end;

procedure StyleGroupLabel(ALbl: TsLabel; const ACaption: string; AHeight: Integer);
begin
  if not Assigned(ALbl) then Exit;
  ALbl.Caption := '  ' + ACaption;
  ALbl.Height := AHeight;
  ALbl.AutoSize := False;
  ALbl.Alignment := taLeftJustify;
  ALbl.ParentFont := False;
  ALbl.Font.Name := GalleryUIFontName;
  ALbl.Font.Height := -11;
  ALbl.Font.Style := [fsBold];
  ALbl.Font.Color := GALLERY_GROUP_TEXT;
end;

constructor TFormPopupToolGallery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSelectedTag := -1;
  FFileSearchMode := False;
end;

procedure TGalleryItemHost.PaintWindow(DC: HDC);
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

function TFormPopupToolGallery.BodyChildIndex(AControl: TControl): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(pnlBody) or not Assigned(AControl) then Exit;
  for i := 0 to pnlBody.ControlCount - 1 do
    if pnlBody.Controls[i] = AControl then
    begin
      Result := i;
      Exit;
    end;
end;

function TFormPopupToolGallery.ItemButton(ATag: Integer): TsSpeedButton;
begin
  case ATag of
    0: Result := btnGallerySplitPattern;
    1: Result := btnGallerySplitEqual;
    2: Result := btnGalleryExtractParts;
    3: Result := btnGalleryFindFiles;
    4: Result := btnGallerySelectSkin;
  else
    Result := nil;
  end;
end;

procedure TFormPopupToolGallery.StyleItemHost(AHost: TGalleryItemHost; ASelected: Boolean);
begin
  if not Assigned(AHost) then Exit;
  AHost.SelectedLook := ASelected;
  if ASelected then
    AHost.Color := GALLERY_GRAD_SEL_TOP
  else
    AHost.Color := GALLERY_GRAD_TOP;
  AHost.Invalidate;
end;

function TFormPopupToolGallery.HostOrItem(ATag: Integer): TControl;
begin
  if (ATag >= 0) and (ATag <= 4) and Assigned(FItemHost[ATag]) then
    Result := FItemHost[ATag]
  else
    Result := ItemButton(ATag);
end;

function TFormPopupToolGallery.ScaledPx(ADesignPx: Integer): Integer;
{ Map design (96 DPI) sizes to current AlphaSkins PPI so ApplyGalleryFilter
  after UpdateScale does not shrink rows back to design pixels. }
var
  PPI: Integer;
begin
  PPI := 96;
  if Assigned(sSkinProvider1) and (sSkinProvider1.SkinData.CurrentPPI > 0) then
    PPI := sSkinProvider1.SkinData.CurrentPPI;
  if PPI = 96 then
    Result := ADesignPx
  else
    Result := MulDiv(ADesignPx, PPI, 96);
end;

procedure TFormPopupToolGallery.NormalizeGalleryBodyOrder;
{ VCL AlignControls sorts alTop by Control.Top (not ControlIndex). New hosts
  default to Top=0 and jump above the header — restore design order via Tops. }
var
  Y: Integer;

  procedure Place(ACtrl: TControl; AHeight: Integer);
  begin
    if not Assigned(ACtrl) then Exit;
    if ACtrl.Parent <> pnlBody then Exit;
    if not ACtrl.Visible then Exit;
    ACtrl.Align := alNone;
    ACtrl.Top := Y;
    ACtrl.Height := AHeight;
    ACtrl.Align := alTop;
    Inc(Y, AHeight);
  end;

begin
  if not Assigned(pnlBody) then Exit;
  Y := 0;
  pnlBody.DisableAlign;
  try
    Place(pnlGalleryHeader, ScaledPx(GALLERY_HEADER_H));
    Place(sBevelHeader, ScaledPx(GALLERY_HEADER_SEP_H));
    Place(lblGroupSplit, ScaledPx(GALLERY_GROUP_H));
    Place(HostOrItem(0), ScaledPx(GALLERY_ITEM_H));
    Place(HostOrItem(1), ScaledPx(GALLERY_ITEM_H));
    Place(HostOrItem(2), ScaledPx(GALLERY_ITEM_H));
    Place(sBevel1, ScaledPx(GALLERY_SEP_H));
    Place(lblGroupFind, ScaledPx(GALLERY_GROUP_H));
    Place(HostOrItem(3), ScaledPx(GALLERY_ITEM_H));
    Place(sBevel2, ScaledPx(GALLERY_SEP_H));
    Place(lblGroupAppearance, ScaledPx(GALLERY_GROUP_H));
    Place(HostOrItem(4), ScaledPx(GALLERY_ITEM_H));
  finally
    pnlBody.EnableAlign;
  end;
  pnlBody.Realign;
end;

procedure TFormPopupToolGallery.EnsureItemHosts;
var
  i, Idx, AnchorTop: Integer;
  B: TsSpeedButton;
  H: TGalleryItemHost;
begin
  if not Assigned(pnlBody) then Exit;
  for i := 0 to 4 do
  begin
    B := ItemButton(i);
    if not Assigned(B) then Continue;
    if Assigned(FItemHost[i]) then
    begin
      FItemHost[i].Visible := B.Visible;
      if FItemHost[i].Visible then
        FItemHost[i].Height := ScaledPx(GALLERY_ITEM_H);
      Continue;
    end;
    if B.Parent <> pnlBody then Continue;

    AnchorTop := B.Top;
    Idx := BodyChildIndex(B);
    H := TGalleryItemHost.Create(Self);
    H.BevelOuter := bvNone;
    H.Height := ScaledPx(GALLERY_ITEM_H);
    H.Tag := i;
    H.ParentBackground := False;
    H.ParentColor := False;
    H.Color := GALLERY_GRAD_TOP;
    H.SelectedLook := False;
    H.Top := AnchorTop; { keep AlignControls sort key before Parent/Align }
    try
      H.SkinData.SkinSection := 'TRANSPARENT';
      H.SkinData.CustomColor := True;
    except
    end;
    H.Parent := pnlBody;
    if Idx >= 0 then
      TWinControlAccess(pnlBody).SetChildOrder(H, Idx);
    H.Align := alTop;
    B.Parent := H;
    B.Align := alClient;
    FItemHost[i] := H;
  end;
end;

procedure TFormPopupToolGallery.SetSelectedTag(ATag: Integer);
var
  i: Integer;
  B: TsSpeedButton;
begin
  FSelectedTag := ATag;
  for i := 0 to 4 do
  begin
    B := ItemButton(i);
    if Assigned(B) then
      StyleItemBtn(B, i = FSelectedTag);
    if Assigned(FItemHost[i]) then
      StyleItemHost(FItemHost[i], i = FSelectedTag);
  end;
end;

function TFormPopupToolGallery.SelectedTag: Integer;
begin
  Result := FSelectedTag;
end;

procedure TFormPopupToolGallery.StyleItemBtn(ABtn: TsSpeedButton; ASelected: Boolean);
begin
  if not Assigned(ABtn) then Exit;
  if ABtn.Visible and (ABtn.Parent is TsPanel) and (ABtn.Parent <> pnlBody) then
    ABtn.Parent.Height := ScaledPx(GALLERY_ITEM_H)
  else if ABtn.Visible then
    ABtn.Height := ScaledPx(GALLERY_ITEM_H);
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
  if ASelected then
    ABtn.Font.Color := clHighlight
  else
    ABtn.Font.Color := clWindowText;
  ABtn.AnimatEvents := [];
  try
    { Transparent so the soft-blue host gradient shows through. }
    ABtn.SkinData.SkinSection := 'TRANSPARENT';
    ABtn.Blend := 0;
    ABtn.Reflected := False;
  except
  end;
end;

procedure TFormPopupToolGallery.EnsureShortcutLabels;
var
  i: Integer;
begin
  if not Assigned(pnlBody) then Exit;
  for i := 0 to 4 do
    if not Assigned(FShortcutLbl[i]) then
    begin
      FShortcutLbl[i] := TsLabel.Create(Self);
      FShortcutLbl[i].Parent := pnlBody;
      FShortcutLbl[i].AutoSize := True;
      FShortcutLbl[i].Transparent := True;
      FShortcutLbl[i].Enabled := False;
      FShortcutLbl[i].ParentFont := False;
      FShortcutLbl[i].Font.Name := GalleryUIFontName;
      FShortcutLbl[i].Font.Height := ScaledPx(-10);
      FShortcutLbl[i].Font.Style := [];
      FShortcutLbl[i].Font.Color := GALLERY_SHORTCUT_TEXT;
      FShortcutLbl[i].Caption := '';
      FShortcutLbl[i].Visible := False;
    end;
end;

procedure TFormPopupToolGallery.PlaceShortcutLabels;
var
  i: Integer;
  B: TsSpeedButton;
  L: TsLabel;
  Host: TControl;
  Origin: TPoint;
begin
  EnsureShortcutLabels;
  for i := 0 to 4 do
  begin
    B := ItemButton(i);
    L := FShortcutLbl[i];
    if not Assigned(B) or not Assigned(L) then Continue;
    if (not B.Visible) or (Trim(FItemShortcut[i]) = '') then
    begin
      L.Visible := False;
      Continue;
    end;
    L.Caption := FItemShortcut[i];
    L.Visible := True;
    L.BringToFront;
    Host := B;
    if Assigned(B.Parent) and (B.Parent <> pnlBody) then
      Host := B.Parent;
    Origin := Host.ClientToParent(Point(0, 0), pnlBody);
    L.Left := Origin.X + Host.Width - L.Width - ScaledPx(14);
    if L.Left < Origin.X + ScaledPx(56) then
      L.Left := Origin.X + ScaledPx(56);
    L.Top := Origin.Y + (Host.Height - L.Height) div 2;
  end;
end;

procedure TFormPopupToolGallery.ClosePopup(AnimationAllowed: Boolean = False);
begin
  if not AnimationAllowed then begin
    sSkinProvider1.AllowAnimation := False;
    Close;
    sSkinProvider1.AllowAnimation := True;
    Application.ProcessMessages;
  end
  else
    Close;
end;

procedure GallerySplitCaption(const ARaw: string; out ATitle, AShortcut: string);
var
  P: Integer;
  Rest: string;
  HasCrlf: Boolean;
begin
  ATitle := Trim(ARaw);
  AShortcut := '';
  if ATitle = '' then Exit;

  P := Pos(#13#10, ATitle);
  HasCrlf := P > 0;
  if not HasCrlf then
    P := Pos(#10, ATitle);
  if P = 0 then
  begin
    ATitle := StringReplace(ATitle, #13#10, ' ', [rfReplaceAll]);
    ATitle := StringReplace(ATitle, #10, ' ', [rfReplaceAll]);
    Exit;
  end;

  if HasCrlf then
    Rest := Trim(Copy(ATitle, P + 2, MaxInt))
  else
    Rest := Trim(Copy(ATitle, P + 1, MaxInt));
  ATitle := Trim(Copy(ATitle, 1, P - 1));
  ATitle := StringReplace(ATitle, #13#10, ' ', [rfReplaceAll]);
  ATitle := StringReplace(ATitle, #10, ' ', [rfReplaceAll]);
  Rest := StringReplace(Rest, #13#10, ' ', [rfReplaceAll]);
  Rest := StringReplace(Rest, #10, ' ', [rfReplaceAll]);

  if (Pos('Ctrl+', Rest) = 1) or (Pos('Alt+', Rest) = 1) or
     (Pos('Shift+', Rest) = 1) or ((Length(Rest) >= 2) and (Rest[1] = 'F') and
      (Rest[2] >= '0') and (Rest[2] <= '9')) then
    AShortcut := Rest
  else if Rest <> '' then
    ATitle := Trim(ATitle + ' ' + Rest);
end;

function GalleryTextMatches(const ANeedle, AHaystack: string): Boolean;
var
  N: string;
begin
  N := Trim(LowerCase(ANeedle));
  if N = '' then
  begin
    Result := True;
    Exit;
  end;
  Result := Pos(N, LowerCase(AHaystack)) > 0;
end;

procedure TFormPopupToolGallery.SyncItem(ATarget, ASource: TsSpeedButton);
var
  Title, Shortcut: string;
  Idx: Integer;
begin
  if not Assigned(ATarget) or not Assigned(ASource) then Exit;
  Idx := ATarget.Tag;
  if (Idx < 0) or (Idx > 4) then Exit;

  GallerySplitCaption(ASource.Caption, Title, Shortcut);
  if Shortcut = '' then
  begin
    if Idx = 3 then
      Shortcut := TrText('ToolsGallery.Shortcut.FindFiles')
    else if Idx = 4 then
      Shortcut := TrText('ToolsGallery.Shortcut.SelectSkin');
  end;
  FItemShortcut[Idx] := Shortcut;
  FItemSearchText[Idx] := Title + ' ' + Shortcut + ' ' + ASource.Hint;

  ATarget.Caption := Title;
  ATarget.Hint := ASource.Hint;
  if (ATarget.Hint = '') and (Shortcut <> '') then
    ATarget.Hint := Title + '  (' + Shortcut + ')';
  ATarget.Images := ASource.Images;
  ATarget.ImageIndex := ASource.ImageIndex;
  StyleItemBtn(ATarget, Idx = FSelectedTag);
end;

procedure TFormPopupToolGallery.ConfigureFileSearchMode(AImages: TCustomImageList;
  AFindImageIndex, AFilterImageIndex, ABookmarkImageIndex: Integer;
  const AFindTitle, AFindHint, AFindShortcut: string;
  const AFilterTitle, AFilterHint, AFilterShortcut: string;
  const ABookmarkTitle, ABookmarkHint, ABookmarkShortcut: string);
{ Reuse the exact Mais ferramentas chrome for Find / Filter-Grep / Bookmarks. }
var
  I: Integer;
begin
  FFileSearchMode := True;
  FSelectedTag := -1;

  FItemShortcut[0] := AFindShortcut;
  FItemSearchText[0] := AFindTitle + ' ' + AFindShortcut + ' ' + AFindHint;
  if Assigned(btnGallerySplitPattern) then
  begin
    btnGallerySplitPattern.Tag := 0;
    btnGallerySplitPattern.Caption := AFindTitle;
    btnGallerySplitPattern.Hint := AFindHint;
    if (btnGallerySplitPattern.Hint = '') and (AFindShortcut <> '') then
      btnGallerySplitPattern.Hint := AFindTitle + '  (' + AFindShortcut + ')';
    btnGallerySplitPattern.Images := AImages;
    btnGallerySplitPattern.ImageIndex := AFindImageIndex;
    btnGallerySplitPattern.Visible := True;
  end;

  FItemShortcut[1] := AFilterShortcut;
  FItemSearchText[1] := AFilterTitle + ' ' + AFilterShortcut + ' ' + AFilterHint;
  if Assigned(btnGallerySplitEqual) then
  begin
    btnGallerySplitEqual.Tag := 1;
    btnGallerySplitEqual.Caption := AFilterTitle;
    btnGallerySplitEqual.Hint := AFilterHint;
    if (btnGallerySplitEqual.Hint = '') and (AFilterShortcut <> '') then
      btnGallerySplitEqual.Hint := AFilterTitle + '  (' + AFilterShortcut + ')';
    btnGallerySplitEqual.Images := AImages;
    btnGallerySplitEqual.ImageIndex := AFilterImageIndex;
    btnGallerySplitEqual.Visible := True;
  end;

  FItemShortcut[2] := ABookmarkShortcut;
  FItemSearchText[2] := ABookmarkTitle + ' ' + ABookmarkShortcut + ' ' + ABookmarkHint;
  if Assigned(btnGalleryExtractParts) then
  begin
    btnGalleryExtractParts.Tag := 2;
    btnGalleryExtractParts.Caption := ABookmarkTitle;
    btnGalleryExtractParts.Hint := ABookmarkHint;
    if (btnGalleryExtractParts.Hint = '') and (ABookmarkShortcut <> '') then
      btnGalleryExtractParts.Hint := ABookmarkTitle + '  (' + ABookmarkShortcut + ')';
    btnGalleryExtractParts.Images := AImages;
    btnGalleryExtractParts.ImageIndex := ABookmarkImageIndex;
    btnGalleryExtractParts.Visible := True;
  end;

  for I := 3 to 4 do
  begin
    FItemShortcut[I] := '';
    FItemSearchText[I] := '';
    if Assigned(ItemButton(I)) then
      ItemButton(I).Visible := False;
  end;
end;

procedure TFormPopupToolGallery.FocusSearch;
begin
  if not Assigned(edtGallerySearch) then Exit;
  if edtGallerySearch.CanFocus then
    edtGallerySearch.SetFocus;
end;

procedure TFormPopupToolGallery.RelayoutChrome;
{ Reposition overlays after DPI UpdateScale without resetting alTop heights
  (NormalizeGalleryBodyOrder / fixed GALLERY_* would undo the scale). }
begin
  PlaceShortcutLabels;
  ApplySearchCue;
end;

procedure TFormPopupToolGallery.ApplyGalleryFilter;
var
  Needle: string;
  VisSplit, VisFind, VisAppear: Boolean;
  NeedH, BodyPad, I: Integer;
begin
  if not Assigned(pnlBody) then Exit;
  Needle := '';
  if Assigned(edtGallerySearch) then
    Needle := Trim(edtGallerySearch.Text);

  EnsureItemHosts;

  DisableAlign;
  try
    if Assigned(btnGallerySplitPattern) then
      btnGallerySplitPattern.Visible := GalleryTextMatches(Needle, FItemSearchText[0]);
    if Assigned(btnGallerySplitEqual) then
      btnGallerySplitEqual.Visible := GalleryTextMatches(Needle, FItemSearchText[1]);
    if FFileSearchMode then
    begin
      if Assigned(btnGalleryExtractParts) then
        btnGalleryExtractParts.Visible := GalleryTextMatches(Needle, FItemSearchText[2]);
      if Assigned(btnGalleryFindFiles) then
        btnGalleryFindFiles.Visible := False;
      if Assigned(btnGallerySelectSkin) then
        btnGallerySelectSkin.Visible := False;
    end
    else
    begin
      if Assigned(btnGalleryExtractParts) then
        btnGalleryExtractParts.Visible := GalleryTextMatches(Needle, FItemSearchText[2]);
      if Assigned(btnGalleryFindFiles) then
        btnGalleryFindFiles.Visible := GalleryTextMatches(Needle, FItemSearchText[3]);
      if Assigned(btnGallerySelectSkin) then
        btnGallerySelectSkin.Visible := GalleryTextMatches(Needle, FItemSearchText[4]);
    end;

    for I := 0 to 4 do
      if Assigned(FItemHost[I]) then
      begin
        FItemHost[I].Visible := Assigned(ItemButton(I)) and ItemButton(I).Visible;
        if FItemHost[I].Visible then
          FItemHost[I].Height := ScaledPx(GALLERY_ITEM_H);
      end;

    VisSplit := (Assigned(btnGallerySplitPattern) and btnGallerySplitPattern.Visible) or
      (Assigned(btnGallerySplitEqual) and btnGallerySplitEqual.Visible) or
      (Assigned(btnGalleryExtractParts) and btnGalleryExtractParts.Visible);
    VisFind := (not FFileSearchMode) and Assigned(btnGalleryFindFiles) and btnGalleryFindFiles.Visible;
    VisAppear := (not FFileSearchMode) and Assigned(btnGallerySelectSkin) and btnGallerySelectSkin.Visible;

    if Assigned(lblGroupSplit) then
    begin
      lblGroupSplit.Visible := VisSplit;
      if VisSplit then
        lblGroupSplit.Height := ScaledPx(GALLERY_GROUP_H);
    end;
    if Assigned(lblGroupFind) then
    begin
      lblGroupFind.Visible := VisFind;
      if VisFind then
        lblGroupFind.Height := ScaledPx(GALLERY_GROUP_H);
    end;
    if Assigned(lblGroupAppearance) then
    begin
      lblGroupAppearance.Visible := VisAppear;
      if VisAppear then
        lblGroupAppearance.Height := ScaledPx(GALLERY_GROUP_H);
    end;
    if Assigned(sBevel1) then
    begin
      sBevel1.Visible := VisSplit and VisFind;
      if sBevel1.Visible then
        sBevel1.Height := ScaledPx(GALLERY_SEP_H);
    end;
    if Assigned(sBevel2) then
    begin
      sBevel2.Visible := (VisSplit or VisFind) and VisAppear;
      if sBevel2.Visible then
        sBevel2.Height := ScaledPx(GALLERY_SEP_H);
    end;

    for I := 0 to 4 do
    begin
      if Assigned(ItemButton(I)) and ItemButton(I).Visible then
        StyleItemBtn(ItemButton(I), I = FSelectedTag);
      if Assigned(FItemHost[I]) and FItemHost[I].Visible then
        StyleItemHost(FItemHost[I], I = FSelectedTag);
    end;
  finally
    EnableAlign;
  end;

  NormalizeGalleryBodyOrder;

  NeedH := 0;
  for I := 0 to pnlBody.ControlCount - 1 do
    if pnlBody.Controls[I].Visible and (pnlBody.Controls[I].Align = alTop) then
      Inc(NeedH, pnlBody.Controls[I].Height);

  BodyPad := pnlBody.BorderWidth;
  if BodyPad < 1 then
    BodyPad := ScaledPx(GALLERY_BODY_PAD);
  NeedH := NeedH + (BodyPad * 2);
  if NeedH < ScaledPx(120) then
    NeedH := ScaledPx(120);

  ClientHeight := NeedH;
  if Assigned(pnlAccent) then
    pnlAccent.Height := ClientHeight;
  if Assigned(sPanel1) then
    sPanel1.Height := ClientHeight;

  PlaceShortcutLabels;
  ApplySearchCue;
end;

procedure TFormPopupToolGallery.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(edtGallerySearch) and edtGallerySearch.Focused and
      (Trim(edtGallerySearch.Text) <> '') then
      ClearSearchText
    else
      ClosePopup(False);
  end;
end;

procedure TFormPopupToolGallery.edtGallerySearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
    Key := 0;
end;

procedure TFormPopupToolGallery.edtGallerySearchChange(Sender: TObject);
begin
  UpdateClearSearchBtn;
  ApplyGalleryFilter;
end;

procedure TFormPopupToolGallery.btnSearchGlyphClick(Sender: TObject);
begin
  FocusSearch;
end;

procedure TFormPopupToolGallery.btnClearSearchClick(Sender: TObject);
begin
  ClearSearchText;
end;

procedure TFormPopupToolGallery.ClearSearchText;
begin
  if not Assigned(edtGallerySearch) then Exit;
  edtGallerySearch.Text := '';
  UpdateClearSearchBtn;
  ApplyGalleryFilter;
  ApplySearchCue;
  FocusSearch;
end;

procedure TFormPopupToolGallery.UpdateClearSearchBtn;
begin
  if not Assigned(btnClearSearch) then Exit;
  btnClearSearch.Visible := Assigned(edtGallerySearch) and (Trim(edtGallerySearch.Text) <> '');
end;

procedure TFormPopupToolGallery.ApplySearchCue;
var
  Cue: WideString;
begin
  if not Assigned(edtGallerySearch) or not edtGallerySearch.HandleAllocated then
    Exit;
  Cue := WideString(TrText('ToolsGallery.SearchCue'));
  SendMessageW(edtGallerySearch.Handle, EM_SETCUEBANNER, 1, LPARAM(PWideChar(Cue)));
end;

procedure TFormPopupToolGallery.StyleSearchBox;
begin
  if Assigned(pnlSearchRow) then
  begin
    pnlSearchRow.Align := alTop;
    pnlSearchRow.Height := ScaledPx(GALLERY_SEARCH_H);
    pnlSearchRow.BorderWidth := ScaledPx(3);
    pnlSearchRow.ParentBackground := False;
    pnlSearchRow.ParentColor := False;
    pnlSearchRow.Color := clWindow;
    try
      { EDIT skin forces a tall min-height asynchronously after show — avoid it. }
      pnlSearchRow.SkinData.SkinSection := 'TRANSPARENT';
      pnlSearchRow.SkinData.CustomColor := True;
    except
    end;
  end;

  if Assigned(btnSearchGlyph) then
  begin
    btnSearchGlyph.Width := ScaledPx(22);
    btnSearchGlyph.Height := ScaledPx(GALLERY_SEARCH_H) - ScaledPx(6);
    btnSearchGlyph.Flat := True;
    btnSearchGlyph.Caption := '';
    btnSearchGlyph.Margin := 0;
    btnSearchGlyph.Spacing := 0;
    btnSearchGlyph.ShowHint := True;
    btnSearchGlyph.Hint := TrText('ToolsGallery.SearchCue');
    if Assigned(imgSearchGlyphs) then
    begin
      btnSearchGlyph.Images := imgSearchGlyphs;
      btnSearchGlyph.ImageIndex := 0;
    end;
    try
      btnSearchGlyph.SkinData.SkinSection := 'TRANSPARENT';
      btnSearchGlyph.Blend := 0;
      btnSearchGlyph.Reflected := False;
    except
    end;
  end;

  if Assigned(btnClearSearch) then
  begin
    btnClearSearch.Width := ScaledPx(22);
    btnClearSearch.Height := ScaledPx(GALLERY_SEARCH_H) - ScaledPx(6);
    btnClearSearch.Flat := True;
    btnClearSearch.Caption := '';
    btnClearSearch.Margin := 0;
    btnClearSearch.Spacing := 0;
    btnClearSearch.ShowHint := True;
    btnClearSearch.Hint := TrText('ToolsGallery.ClearSearch');
    if Assigned(imgSearchGlyphs) then
    begin
      btnClearSearch.Images := imgSearchGlyphs;
      btnClearSearch.ImageIndex := 1;
    end;
    try
      btnClearSearch.SkinData.SkinSection := 'TRANSPARENT';
      btnClearSearch.Blend := 0;
      btnClearSearch.Reflected := False;
    except
    end;
  end;

  if Assigned(edtGallerySearch) then
  begin
    edtGallerySearch.Text := '';
    edtGallerySearch.ParentFont := False;
    edtGallerySearch.Font.Name := GalleryUIFontName;
    edtGallerySearch.Font.Height := ScaledPx(-12);
    edtGallerySearch.Font.Color := clWindowText;
    edtGallerySearch.Visible := True;
    try
      edtGallerySearch.SkinData.SkinSection := 'TRANSPARENT';
      edtGallerySearch.BoundLabel.Active := False;
    except
    end;
  end;

  UpdateClearSearchBtn;
  ApplySearchCue;
end;

procedure TFormPopupToolGallery.PrepareLayout;
var
  NeedH, NeedW, CapW, InnerH, BodyPad, i: Integer;
  Canvas: TControlCanvas;
  B: TsSpeedButton;

  procedure MeasureBtn(ABtn: TsSpeedButton);
  var
    LineW: Integer;
  begin
    if not Assigned(ABtn) then Exit;
    StyleItemBtn(ABtn, ABtn.Tag = FSelectedTag);
    LineW := Canvas.TextWidth(ABtn.Caption);
    if LineW > CapW then
      CapW := LineW;
  end;

begin
  if not Assigned(sPanel1) or not Assigned(pnlBody) then Exit;

  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  Constraints.MinWidth := 0;
  Constraints.MaxWidth := 0;

  EnsureShortcutLabels;
  EnsureItemHosts;

  DisableAlign;
  try
    if Assigned(pnlAccent) then
    begin
      pnlAccent.Width := ScaledPx(GALLERY_ACCENT_W);
      try
        pnlAccent.SkinData.CustomColor := True;
      except
      end;
      pnlAccent.Color := $00E8A060;
      pnlAccent.ParentBackground := False;
    end;

    BodyPad := ScaledPx(GALLERY_BODY_PAD);
    pnlBody.BorderWidth := BodyPad;

    if Assigned(pnlGalleryHeader) then
    begin
      pnlGalleryHeader.Height := ScaledPx(GALLERY_HEADER_H);
      pnlGalleryHeader.ParentBackground := True;
      pnlGalleryHeader.BorderWidth := ScaledPx(2);
      try
        pnlGalleryHeader.SkinData.CustomColor := False;
        pnlGalleryHeader.SkinData.SkinSection := 'TRANSPARENT';
      except
      end;
    end;

    if Assigned(lblGalleryHeader) then
    begin
      if FFileSearchMode then
        lblGalleryHeader.Caption := StringReplace(TrText('FileSearch.MoreTools'), #13#10, ' ', [rfReplaceAll])
      else
        lblGalleryHeader.Caption := TrText('More tools');
      lblGalleryHeader.Align := alTop;
      lblGalleryHeader.Height := ScaledPx(GALLERY_TITLE_H);
      lblGalleryHeader.AutoSize := False;
      lblGalleryHeader.Alignment := taLeftJustify;
      lblGalleryHeader.ParentFont := False;
      lblGalleryHeader.Font.Name := GalleryUIFontName;
      lblGalleryHeader.Font.Height := ScaledPx(-15);
      lblGalleryHeader.Font.Style := [fsBold];
      lblGalleryHeader.Font.Color := clWindowText;
    end;

    StyleSearchBox;

    if FFileSearchMode then
      StyleGroupLabel(lblGroupSplit, TrText('FileSearch.GalleryGroup'), ScaledPx(GALLERY_GROUP_H))
    else
      StyleGroupLabel(lblGroupSplit, TrText('ToolsGallery.GroupSplit'), ScaledPx(GALLERY_GROUP_H));
    StyleGroupLabel(lblGroupFind, TrText('ToolsGallery.GroupFind'), ScaledPx(GALLERY_GROUP_H));
    StyleGroupLabel(lblGroupAppearance, TrText('ToolsGallery.GroupAppearance'), ScaledPx(GALLERY_GROUP_H));

    if Assigned(sBevelHeader) then
      sBevelHeader.Height := ScaledPx(GALLERY_HEADER_SEP_H);
    if Assigned(sBevel1) then
      sBevel1.Height := ScaledPx(GALLERY_SEP_H);
    if Assigned(sBevel2) then
      sBevel2.Height := ScaledPx(GALLERY_SEP_H);

    CapW := 0;
    Canvas := TControlCanvas.Create;
    try
      Canvas.Control := pnlBody;
      Canvas.Font.Name := GalleryUIFontName;
      Canvas.Font.Height := ScaledPx(-13);
      Canvas.Font.Style := [fsBold];
      for i := 0 to 4 do
      begin
        B := ItemButton(i);
        if Assigned(B) then
          MeasureBtn(B);
      end;
    finally
      Canvas.Free;
    end;

    InnerH :=
      ScaledPx(GALLERY_HEADER_H) +
      ScaledPx(GALLERY_HEADER_SEP_H) +
      (ScaledPx(GALLERY_GROUP_H) * 3) +
      (ScaledPx(GALLERY_ITEM_H) * 5) +
      (ScaledPx(GALLERY_SEP_H) * 2);

    NeedH := InnerH + (BodyPad * 2);
    NeedW := ScaledPx(GALLERY_ACCENT_W) + (BodyPad * 2) + ScaledPx(GALLERY_SIDE_PAD) +
      ScaledPx(GALLERY_ICON_SLOT) + CapW + ScaledPx(GALLERY_SHORTCUT_RESERVE) + ScaledPx(GALLERY_SIDE_PAD);
    if NeedW < ScaledPx(GALLERY_MIN_W) then
      NeedW := ScaledPx(GALLERY_MIN_W);
    if NeedW > ScaledPx(560) then
      NeedW := ScaledPx(560);

    Scaled := False;
    AutoSize := False;
    BorderStyle := bsNone;
    ClientWidth := NeedW;
    ClientHeight := NeedH;
  finally
    EnableAlign;
  end;

  SetBounds(Left, Top, Width, Height);
  if ClientHeight <> NeedH then
    ClientHeight := NeedH;
  if ClientWidth <> NeedW then
    ClientWidth := NeedW;

  ApplyGalleryFilter;
  ApplySearchCue;
end;

end.

