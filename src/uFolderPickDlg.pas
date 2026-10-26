unit uFolderPickDlg;

{
  Folder picker for the AI agent and AI diagnosis.
  Borderless modal in the same soft style as the other FastFile dialogs:
  browse drives and folders, collect several from different places, then confirm.
  Texts: FolderPick.* in uI18n.
}

interface

uses
  Classes, Controls;

type
  TFolderPickKind = (fpkAgent, fpkHub);

{ mrOk copies the chosen directories into ADest (already normalized). }
function PickFolders(AOwner: TComponent; AKind: TFolderPickKind; ADest: TStrings;
  const AStartDir: string = ''): Boolean;

implementation

uses
  Windows, Messages, SysUtils, Types, Graphics, Forms, StdCtrls, ExtCtrls, ShellAPI, CommCtrl,
  Math, uI18n, uFastFileScale, UnConsts, uAgentPrefs, UnitPopupMruList, uMruFind, uFastFileMsgDlg;

const
  CTitle = TColor($00283038);
  CMuted = TColor($00606870);
  CAccent = TColor($00D77800);
  CErr = TColor($003232C8);
  CCardLine = TColor($00D2C4B4);

type
  TFolderRow = class
  public
    Name: string;
    Path: string;
    Icon: Integer;
  end;

  TPickBtnKind = (pbGhost, pbSoft, pbPrimary, pbIcon, pbClose);

  TPickBtn = class(TCustomControl)
  private
    FKind: TPickBtnKind;
    FCaption: string;
    FHover: Boolean;
    FPressed: Boolean;
    FBack: TColor;
    procedure SetCaption(const Value: string);
    procedure SetBack(const Value: TColor);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Kind: TPickBtnKind read FKind write FKind;
    property Caption: string read FCaption write SetCaption;
    property BackColor: TColor read FBack write SetBack;
    property OnClick;
  end;

  TPickCard = class(TCustomControl)
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TFolderPickForm = class(TForm)
  private
    FKind: TFolderPickKind;
    FUiFont: string;
    FReady: Boolean;
    FCurrent: string;
    FHist: TStringList;
    FHistIndex: Integer;
    FChosen: TStringList;
    FFolderRecent: TStringList;
    FRecentPosted: Boolean;
    FRecentW: Integer;
    FHoverBrowser: Integer;
    FHoverTray: Integer;
    FGradTop, FGradBot: TColor;
    FPrimaryW, FCancelW, FAddThisW, FAddSelW: Integer;
    FIcon: TPaintBox;
    FTitle, FSub, FStatus, FBrowserTitle, FBrowserHint: TLabel;
    FTrayTitle, FTrayEmptyTitle, FTrayEmptyHint: TLabel;
    FTrayArt: TPaintBox;
    FPath: TEdit;
    FChkHidden: TCheckBox;
    FBrowserCard, FTrayCard: TPickCard;
    FBrowser, FTray: TListBox;
    FBtnClose, FBtnBack, FBtnUp, FBtnRefresh, FBtnRecent, FBtnGo: TPickBtn;
    FBtnAddThis, FBtnAddSel, FBtnRemove, FBtnClear, FBtnCancel, FBtnOk: TPickBtn;
    procedure Build;
    procedure ApplyTexts;
    procedure MeasureCaps;
    procedure FitInitialSize;
    procedure Layout;
    procedure ApplyRoundRegion;
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure IconPaint(Sender: TObject);
    procedure TrayArtPaint(Sender: TObject);
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMRecentPopup(var Msg: TMessage); message WM_APP + 51;
    procedure RememberFolder(const APath: string);
    procedure RecentClick(Sender: TObject);
    procedure OpenRecentPopup;
    procedure RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure RecentRemove(Sender: TObject; const AValue: string);
    procedure RecentProps(Sender: TObject; const AValue: string);
    procedure RecentClearAll(Sender: TObject);
    procedure CloseRecentPopup;
    procedure Navigate(const APath: string; APush: Boolean);
    procedure Reload;
    procedure UpdateChrome;
    procedure SetStatus(const AText: string; AError: Boolean);
    function SelectedCount: Integer;
    function CommitCount: Integer;
    function AddToTray(const APath, AName: string; AIcon: Integer): Boolean;
    procedure FreeRows(AList: TListBox);
    procedure GoClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure UpClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure HiddenClick(Sender: TObject);
    procedure AddThisClick(Sender: TObject);
    procedure AddSelClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure ConfirmClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure BrowserClick(Sender: TObject);
    procedure BrowserDblClick(Sender: TObject);
    procedure BrowserKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BrowserMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure BrowserMouseLeave(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure TrayKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TrayMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TrayMouseLeave(Sender: TObject);
    procedure ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    function RowAt(AList: TListBox; AIndex: Integer): TFolderRow;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreatePick(AOwner: TComponent; AKind: TFolderPickKind; const AStartDir: string);
    destructor Destroy; override;
    property Chosen: TStringList read FChosen;
  end;

function Mix(C1, C2: TColor; C2Pct: Integer): TColor;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);
  Result := RGB(
    GetRValue(C1) + (GetRValue(C2) - GetRValue(C1)) * C2Pct div 100,
    GetGValue(C1) + (GetGValue(C2) - GetGValue(C1)) * C2Pct div 100,
    GetBValue(C1) + (GetBValue(C2) - GetBValue(C1)) * C2Pct div 100);
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

function UiFontName: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

function SysImages: HIMAGELIST;
var
  FI: TSHFileInfo;
begin
  Result := SHGetFileInfo(PChar(''), FILE_ATTRIBUTE_DIRECTORY, FI, SizeOf(FI),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
end;

function IconIndexOf(const APath: string): Integer;
var
  FI: TSHFileInfo;
begin
  Result := -1;
  FillChar(FI, SizeOf(FI), 0);
  if APath = '' then Exit;
  if SHGetFileInfo(PChar(APath), FILE_ATTRIBUTE_DIRECTORY, FI, SizeOf(FI),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON) <> 0 then
    Result := FI.iIcon
  else if SHGetFileInfo(PChar(APath), FILE_ATTRIBUTE_DIRECTORY, FI, SizeOf(FI),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES) <> 0 then
    Result := FI.iIcon;
end;

procedure DrawShellIcon(ACanvas: TCanvas; AIndex, X, Y: Integer);
begin
  if (AIndex < 0) or (SysImages = 0) then Exit;
  ImageList_Draw(SysImages, AIndex, ACanvas.Handle, X, Y, ILD_TRANSPARENT);
end;

function NormalizeDir(const APath: string): string;
begin
  Result := Trim(APath);
  if Result = '' then Exit;
  Result := ExpandFileName(Result);
  if (Length(Result) = 2) and (Result[2] = ':') then
    Result := Result + '\';
end;

function DirTitle(const APath: string): string;
var
  S: string;
begin
  S := ExcludeTrailingPathDelimiter(APath);
  Result := ExtractFileName(S);
  if Result = '' then
    Result := S;
  if Result = '' then
    Result := APath;
end;

function ParentOf(const APath: string): string;
var
  S, D: string;
begin
  Result := '';
  if APath = '' then Exit;
  S := ExcludeTrailingPathDelimiter(APath);
  if (Length(S) = 2) and (UpCase(S[2]) = ':') then Exit;
  D := ExtractFileDir(S);
  if (D = '') or SameText(D, S) then Exit;
  Result := D;
  if (Length(Result) = 2) and (Result[2] = ':') then
    Result := Result + '\';
end;

function VolumeLabelOf(const ARoot: string): string;
var
  Buf: array[0..MAX_PATH] of Char;
  Comp, Flags: DWORD;
begin
  Result := '';
  Buf[0] := #0;
  Comp := 0;
  Flags := 0;
  if GetVolumeInformation(PChar(ARoot), Buf, MAX_PATH, nil, Comp, Flags, nil, 0) then
    Result := Buf;
end;

function DriveCaption(const ARoot: string): string;
var
  Vol, Letter, Key: string;
  Dt: UINT;
begin
  Letter := Copy(ARoot, 1, 2);
  Vol := VolumeLabelOf(ARoot);
  if Vol <> '' then
  begin
    Result := Vol + ' (' + Letter + ')';
    Exit;
  end;
  Dt := GetDriveType(PChar(ARoot));
  case Dt of
    DRIVE_REMOVABLE: Key := 'FolderPick.DriveRemovable';
    DRIVE_FIXED: Key := 'FolderPick.DriveFixed';
    DRIVE_REMOTE: Key := 'FolderPick.DriveRemote';
    DRIVE_CDROM: Key := 'FolderPick.DriveCD';
    DRIVE_RAMDISK: Key := 'FolderPick.DriveRam';
  else
    Key := 'FolderPick.DriveUnknown';
  end;
  Result := Format(TrText(Key), [Letter]);
end;

function StartPath(const AStart: string): string;
begin
  Result := Trim(AStart);
  if (Result <> '') and FileExists(Result) and not DirectoryExists(Result) then
    Result := ExtractFileDir(Result);
  if (Result <> '') and DirectoryExists(Result) then
  begin
    Result := NormalizeDir(Result);
    Exit;
  end;
  Result := GetEnvironmentVariable('USERPROFILE');
  if DirectoryExists(Result) then
    Result := NormalizeDir(Result)
  else
    Result := '';
end;

function PickFolders(AOwner: TComponent; AKind: TFolderPickKind; ADest: TStrings;
  const AStartDir: string): Boolean;
var
  F: TFolderPickForm;
begin
  Result := False;
  if ADest = nil then Exit;
  F := TFolderPickForm.CreatePick(AOwner, AKind, AStartDir);
  try
    if F.ShowModal = mrOk then
    begin
      ADest.Assign(F.Chosen);
      Result := ADest.Count > 0;
    end;
  finally
    F.Free;
  end;
end;

{ TPickBtn }

constructor TPickBtn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop := True;
  FKind := pbSoft;
  FBack := clBtnFace;
  Cursor := crHandPoint;
  Font.Name := UiFontName;
  Font.Size := 9;
  Font.Color := CTitle;
  Height := 32;
  Width := 96;
end;

procedure TPickBtn.SetCaption(const Value: string);
begin
  if FCaption = Value then Exit;
  FCaption := Value;
  Invalidate;
end;

procedure TPickBtn.SetBack(const Value: TColor);
begin
  if FBack = Value then Exit;
  FBack := Value;
  Invalidate;
end;

procedure TPickBtn.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FHover := True;
  Invalidate;
end;

procedure TPickBtn.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FHover := False;
  FPressed := False;
  Invalidate;
end;

procedure TPickBtn.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
  Invalidate;
end;

procedure TPickBtn.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FPressed := True;
    Invalidate;
  end;
end;

procedure TPickBtn.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FPressed := False;
  Invalidate;
end;

procedure TPickBtn.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if not Enabled then Exit;
  if (Key = VK_SPACE) or (Key = VK_RETURN) then
  begin
    Key := 0;
    Click;
  end;
end;

procedure TPickBtn.Paint;
var
  R: TRect;
  Rad, CX, CY: Integer;
  Fill, Border, TC: TColor;
  Hot: Boolean;
  Flags: UINT;
begin
  R := ClientRect;
  Canvas.Brush.Color := FBack;
  Canvas.FillRect(R);
  Hot := Enabled and (FHover or FPressed or Focused);
  Rad := FfPx(8);
  case FKind of
    pbPrimary:
      begin
        if not Enabled then
        begin
          Fill := Mix(FBack, clGray, 18);
          TC := CMuted;
          Border := Fill;
        end
        else if FPressed then
        begin
          Fill := Mix(CAccent, clBlack, 18);
          TC := clWhite;
          Border := Fill;
        end
        else if Hot then
        begin
          Fill := Mix(CAccent, clWhite, 12);
          TC := clWhite;
          Border := Fill;
        end
        else
        begin
          Fill := CAccent;
          TC := clWhite;
          Border := Mix(CAccent, clBlack, 12);
        end;
      end;
    pbSoft:
      begin
        if not Enabled then
        begin
          Fill := Mix(FBack, clWhite, 55);
          TC := CMuted;
          Border := Mix(CCardLine, clWhite, 30);
        end
        else if FPressed then
        begin
          Fill := Mix(clWhite, CAccent, 18);
          TC := Mix(CAccent, clBlack, 10);
          Border := CAccent;
        end
        else if Hot then
        begin
          Fill := Mix(clWhite, CAccent, 10);
          TC := CAccent;
          Border := CAccent;
        end
        else
        begin
          Fill := clWhite;
          TC := CAccent;
          Border := Mix(CAccent, clWhite, 25);
        end;
      end;
    pbClose, pbIcon:
      begin
        Rad := Height div 2;
        if not Enabled then
        begin
          Fill := FBack;
          TC := Mix(CMuted, FBack, 35);
          Border := FBack;
        end
        else if FKind = pbClose then
        begin
          if FPressed then
            Fill := Mix(FBack, CErr, 28)
          else if Hot then
            Fill := Mix(FBack, CErr, 14)
          else
            Fill := FBack;
          if Hot then
            TC := CErr
          else
            TC := CTitle;
          Border := Fill;
        end
        else
        begin
          if FPressed then
            Fill := Mix(FBack, CAccent, 16)
          else if Hot then
            Fill := Mix(FBack, CAccent, 9)
          else
            Fill := FBack;
          TC := CTitle;
          Border := Fill;
        end;
      end;
  else
    begin
      if not Enabled then
      begin
        Fill := FBack;
        TC := CMuted;
        Border := Mix(CCardLine, FBack, 40);
      end
      else if Hot then
      begin
        Fill := Mix(FBack, clWhite, 35);
        TC := CTitle;
        Border := Mix(CCardLine, clWhite, 10);
      end
      else
      begin
        Fill := Mix(FBack, clWhite, 18);
        TC := CTitle;
        Border := Mix(CCardLine, FBack, 25);
      end;
    end;
  end;

  Canvas.Pen.Color := Border;
  Canvas.Brush.Color := Fill;
  Canvas.RoundRect(1, 1, Width - 1, Height - 1, Rad, Rad);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := UiFontName;
  Canvas.Font.Color := TC;
  if FKind = pbPrimary then
    Canvas.Font.Style := [fsBold]
  else
    Canvas.Font.Style := [];
  if FKind in [pbIcon, pbClose] then
    Canvas.Font.Size := 12
  else
    Canvas.Font.Size := 9;
  Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;
  DrawText(Canvas.Handle, PChar(FCaption), -1, R, Flags);

  if Focused and Enabled and not (FKind in [pbIcon, pbClose]) then
  begin
    Canvas.Pen.Color := Mix(CAccent, clWhite, 20);
    Canvas.Brush.Style := bsClear;
    Canvas.RoundRect(3, 3, Width - 3, Height - 3, Rad, Rad);
  end;
  CX := Width div 2;
  CY := Height div 2;
  if (FKind = pbClose) and Focused and Enabled then
  begin
    Canvas.Pen.Color := CErr;
    Canvas.Brush.Style := bsClear;
    Canvas.Ellipse(CX - FfPx(11), CY - FfPx(11), CX + FfPx(11), CY + FfPx(11));
  end;
end;

{ TPickCard }

constructor TPickCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  ParentBackground := False;
  DoubleBuffered := True;
  Color := clWhite;
end;

procedure TPickCard.Paint;
var
  R: TRect;
  Rad: Integer;
begin
  R := ClientRect;
  Canvas.Brush.Color := Mix(IDLE_WORKSPACE_GRAD_RIGHT, clWhite, 55);
  Canvas.Pen.Style := psClear;
  Rad := FfPx(16);
  Canvas.RoundRect(R.Left + 1, R.Top + 2, R.Right, R.Bottom, Rad, Rad);
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := CCardLine;
  Canvas.Brush.Color := clWhite;
  Canvas.RoundRect(R.Left, R.Top, R.Right - 2, R.Bottom - 2, Rad, Rad);
end;

{ TFolderPickForm }

constructor TFolderPickForm.CreatePick(AOwner: TComponent; AKind: TFolderPickKind;
  const AStartDir: string);
begin
  inherited CreateNew(AOwner);
  FKind := AKind;
  FUiFont := UiFontName;
  FHoverBrowser := -1;
  FHoverTray := -1;
  FHistIndex := -1;
  FGradTop := IDLE_WORKSPACE_GRAD_LEFT;
  FGradBot := IDLE_WORKSPACE_GRAD_RIGHT;
  FHist := TStringList.Create;
  FChosen := TStringList.Create;
  FFolderRecent := TStringList.Create;
  LoadAgentFolderRecent(FFolderRecent);
  BorderStyle := bsNone;
  BorderIcons := [];
  Position := poOwnerFormCenter;
  KeyPreview := True;
  DoubleBuffered := True;
  Color := FGradTop;
  Font.Name := FUiFont;
  Font.Size := 9;
  Font.Color := CTitle;
  OnPaint := FormPaint;
  OnShow := FormShow;
  OnKeyDown := FormKeyDown;
  OnMouseDown := FormMouseDown;
  OnResize := FormResize;
  if AOwner is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(AOwner);
  end
  else
    PopupMode := pmAuto;
  Build;
  ApplyTexts;
  MeasureCaps;
  FReady := True;
  FitInitialSize;
  Navigate(StartPath(AStartDir), True);
end;

destructor TFolderPickForm.Destroy;
begin
  CloseRecentPopup;
  if HandleAllocated then
    ReleaseMruListPopup(Handle);
  FreeRows(FBrowser);
  FreeRows(FTray);
  FHist.Free;
  FChosen.Free;
  FFolderRecent.Free;
  inherited Destroy;
end;

procedure TFolderPickForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

procedure TFolderPickForm.WMNCHitTest(var Msg: TWMNCHitTest);
var
  P: TPoint;
  B: Integer;
begin
  inherited;
  if Msg.Result <> HTCLIENT then Exit;
  P := ScreenToClient(Point(Msg.XPos, Msg.YPos));
  B := FfPx(7);
  if P.Y >= ClientHeight - B then
  begin
    if P.X <= B then
      Msg.Result := HTBOTTOMLEFT
    else if P.X >= ClientWidth - B then
      Msg.Result := HTBOTTOMRIGHT
    else
      Msg.Result := HTBOTTOM;
  end
  else if P.Y <= B then
  begin
    if P.X <= B then
      Msg.Result := HTTOPLEFT
    else if P.X >= ClientWidth - B then
      Msg.Result := HTTOPRIGHT
    else
      Msg.Result := HTTOP;
  end
  else if P.X <= B then
    Msg.Result := HTLEFT
  else if P.X >= ClientWidth - B then
    Msg.Result := HTRIGHT;
end;

function TFolderPickForm.RowAt(AList: TListBox; AIndex: Integer): TFolderRow;
begin
  Result := nil;
  if (AList = nil) or (AIndex < 0) or (AIndex >= AList.Items.Count) then Exit;
  if AList.Items.Objects[AIndex] is TFolderRow then
    Result := TFolderRow(AList.Items.Objects[AIndex]);
end;

procedure TFolderPickForm.FreeRows(AList: TListBox);
var
  I: Integer;
begin
  if AList = nil then Exit;
  for I := 0 to AList.Items.Count - 1 do
  begin
    AList.Items.Objects[I].Free;
    AList.Items.Objects[I] := nil;
  end;
  AList.Items.Clear;
end;

procedure TFolderPickForm.Build;
  function MakeLabel(AParent: TWinControl; ASize: Integer; ABold: Boolean; AColor: TColor): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Transparent := True;
    Result.AutoSize := False;
    Result.ParentFont := False;
    Result.Font.Name := FUiFont;
    Result.Font.Size := ASize;
    Result.Font.Color := AColor;
    if ABold then
      Result.Font.Style := [fsBold]
    else
      Result.Font.Style := [];
    Result.EllipsisPosition := epEndEllipsis;
    Result.OnMouseDown := HeaderMouseDown;
  end;

  function MakeBtn(AParent: TWinControl; AKind: TPickBtnKind; AClick: TNotifyEvent): TPickBtn;
  begin
    Result := TPickBtn.Create(Self);
    Result.Parent := AParent;
    Result.Kind := AKind;
    Result.BackColor := FGradTop;
    Result.OnClick := AClick;
  end;

  function MakeList(AParent: TWinControl; AHeight: Integer): TListBox;
  begin
    Result := TListBox.Create(Self);
    Result.Parent := AParent;
    Result.BorderStyle := bsNone;
    Result.Style := lbOwnerDrawFixed;
    Result.ItemHeight := AHeight;
    Result.Color := clWhite;
    Result.MultiSelect := True;
    Result.ExtendedSelect := True;
    Result.IntegralHeight := False;
    Result.DoubleBuffered := True;
    Result.ParentFont := False;
    Result.Font.Name := FUiFont;
    Result.Font.Size := 9;
    Result.OnDrawItem := ListDraw;
  end;

begin
  FIcon := TPaintBox.Create(Self);
  FIcon.Parent := Self;
  FIcon.OnPaint := IconPaint;
  FIcon.OnMouseDown := HeaderMouseDown;

  FTitle := MakeLabel(Self, 14, True, CTitle);
  FSub := MakeLabel(Self, 9, False, CMuted);
  FSub.WordWrap := True;
  FSub.EllipsisPosition := epNone;
  FStatus := MakeLabel(Self, 9, False, CMuted);
  FStatus.OnMouseDown := nil;

  FBtnClose := MakeBtn(Self, pbClose, CloseClick);
  FBtnBack := MakeBtn(Self, pbIcon, BackClick);
  FBtnUp := MakeBtn(Self, pbIcon, UpClick);
  FBtnRefresh := MakeBtn(Self, pbIcon, RefreshClick);
  FBtnRecent := MakeBtn(Self, pbSoft, RecentClick);
  FBtnGo := MakeBtn(Self, pbSoft, GoClick);

  FPath := TEdit.Create(Self);
  FPath.Parent := Self;
  FPath.ParentFont := False;
  FPath.Font.Name := FUiFont;
  FPath.Font.Size := 10;
  FPath.Font.Color := CTitle;
  FPath.Color := clWhite;
  FPath.AutoSelect := True;
  FPath.OnKeyDown := PathKeyDown;

  FBrowserCard := TPickCard.Create(Self);
  FBrowserCard.Parent := Self;
  FTrayCard := TPickCard.Create(Self);
  FTrayCard.Parent := Self;

  FBrowserTitle := MakeLabel(FBrowserCard, 10, True, CTitle);
  FBrowserTitle.OnMouseDown := nil;
  FChkHidden := TCheckBox.Create(Self);
  FChkHidden.Parent := FBrowserCard;
  FChkHidden.ParentFont := False;
  FChkHidden.Font.Name := FUiFont;
  FChkHidden.Font.Size := 9;
  FChkHidden.Font.Color := CMuted;
  FChkHidden.OnClick := HiddenClick;

  FBrowser := MakeList(FBrowserCard, FfPx(34));
  FBrowser.OnClick := BrowserClick;
  FBrowser.OnDblClick := BrowserDblClick;
  FBrowser.OnKeyDown := BrowserKeyDown;
  FBrowser.OnMouseMove := BrowserMouseMove;
  FBrowser.OnMouseLeave := BrowserMouseLeave;
  FBrowserHint := MakeLabel(FBrowserCard, 8, False, CMuted);
  FBrowserHint.OnMouseDown := nil;

  FTrayTitle := MakeLabel(FTrayCard, 10, True, CTitle);
  FTrayTitle.OnMouseDown := nil;
  FTray := MakeList(FTrayCard, FfPx(48));
  FTray.OnClick := TrayClick;
  FTray.OnKeyDown := TrayKeyDown;
  FTray.OnMouseMove := TrayMouseMove;
  FTray.OnMouseLeave := TrayMouseLeave;

  FTrayArt := TPaintBox.Create(Self);
  FTrayArt.Parent := FTrayCard;
  FTrayArt.OnPaint := TrayArtPaint;
  FTrayEmptyTitle := MakeLabel(FTrayCard, 10, True, CTitle);
  FTrayEmptyTitle.Alignment := taCenter;
  FTrayEmptyTitle.OnMouseDown := nil;
  FTrayEmptyHint := MakeLabel(FTrayCard, 8, False, CMuted);
  FTrayEmptyHint.Alignment := taCenter;
  FTrayEmptyHint.WordWrap := True;
  FTrayEmptyHint.EllipsisPosition := epNone;
  FTrayEmptyHint.OnMouseDown := nil;

  FBtnRemove := MakeBtn(FTrayCard, pbGhost, RemoveClick);
  FBtnClear := MakeBtn(FTrayCard, pbGhost, ClearClick);
  FBtnAddThis := MakeBtn(Self, pbSoft, AddThisClick);
  FBtnAddSel := MakeBtn(Self, pbSoft, AddSelClick);
  FBtnCancel := MakeBtn(Self, pbGhost, CloseClick);
  FBtnOk := MakeBtn(Self, pbPrimary, ConfirmClick);
end;

procedure TFolderPickForm.ApplyTexts;
begin
  if FKind = fpkHub then
    FTitle.Caption := TrText('FolderPick.Title.Hub')
  else
    FTitle.Caption := TrText('FolderPick.Title.Agent');
  Caption := FTitle.Caption;
  FSub.Caption := TrText('FolderPick.Sub');
  FBtnClose.Caption := #$00D7;
  FBtnClose.Hint := TrText('FolderPick.CloseHint');
  FBtnClose.ShowHint := True;
  FBtnBack.Caption := #$2190;
  FBtnBack.Hint := TrText('FolderPick.BackHint');
  FBtnBack.ShowHint := True;
  FBtnUp.Caption := #$2191;
  FBtnUp.Hint := TrText('FolderPick.UpHint');
  FBtnUp.ShowHint := True;
  FBtnRefresh.Caption := #$21BB;
  FBtnRefresh.Hint := TrText('FolderPick.RefreshHint');
  FBtnRefresh.ShowHint := True;
  FBtnRecent.Caption := TrText('FolderPick.Recent') + ' ' + #$25BE;
  FBtnRecent.Hint := TrText('FolderPick.RecentHint');
  FBtnRecent.ShowHint := True;
  FBtnGo.Caption := TrText('FolderPick.Open');
  FBtnGo.Hint := TrText('FolderPick.OpenHint');
  FBtnGo.ShowHint := True;
  FPath.TextHint := TrText('FolderPick.PathHint');
  FChkHidden.Caption := TrText('FolderPick.Hidden');
  FChkHidden.Hint := TrText('FolderPick.HiddenHint');
  FChkHidden.ShowHint := True;
  FBtnAddThis.Caption := TrText('FolderPick.AddThis') + '  ' + #$2192;
  FBtnAddThis.Hint := TrText('FolderPick.AddThisHint');
  FBtnAddThis.ShowHint := True;
  FBtnAddSel.Caption := TrText('FolderPick.AddSel') + '  ' + #$2192;
  FBtnAddSel.Hint := TrText('FolderPick.AddSelHint');
  FBtnAddSel.ShowHint := True;
  FBtnRemove.Caption := TrText('FolderPick.Remove');
  FBtnRemove.Hint := TrText('FolderPick.RemoveHint');
  FBtnRemove.ShowHint := True;
  FBtnClear.Caption := TrText('FolderPick.Clear');
  FBtnClear.Hint := TrText('FolderPick.ClearHint');
  FBtnClear.ShowHint := True;
  FBtnCancel.Caption := TrText('FolderPick.Cancel');
  FBtnCancel.Hint := TrText('FolderPick.Cancel');
  FBtnCancel.ShowHint := True;
  FBtnOk.Hint := TrText('FolderPick.HintOkThis');
  FBtnOk.ShowHint := True;
  FTrayEmptyTitle.Caption := TrText('FolderPick.EmptyTitle');
  FTrayEmptyHint.Caption := TrText('FolderPick.EmptyHint');
  ShowHint := True;
end;

procedure TFolderPickForm.MeasureCaps;
var
  B: TBitmap;
  function W(const S: string; AExtra: Integer): Integer;
  begin
    Result := B.Canvas.TextWidth(S) + FfPx(AExtra);
  end;
begin
  B := TBitmap.Create;
  try
    B.SetSize(1, 1);
    B.Canvas.Font.Name := FUiFont;
    B.Canvas.Font.Size := 9;
    B.Canvas.Font.Style := [fsBold];
    FPrimaryW := W(TrText('FolderPick.Confirm1'), 44);
    FPrimaryW := Max(FPrimaryW, W(Format(TrText('FolderPick.ConfirmN'), [99]), 44));
    FPrimaryW := Max(FPrimaryW, W(TrText('FolderPick.Confirm'), 44));
    FPrimaryW := Max(FPrimaryW, FfPx(168));
    B.Canvas.Font.Style := [];
    FCancelW := Max(FfPx(104), W(TrText('FolderPick.Cancel'), 36));
    FAddThisW := Max(FfPx(168), W(TrText('FolderPick.AddThis') + '  ' + #$2192, 36));
    FAddSelW := Max(FfPx(150), W(TrText('FolderPick.AddSel') + '  ' + #$2192, 36));
    FRecentW := Max(FfPx(108), W(TrText('FolderPick.Recent') + ' ' + #$25BE, 28));
  finally
    B.Free;
  end;
end;

procedure TFolderPickForm.FitInitialSize;
var
  Area: TRect;
  W, H, MaxW, MaxH: Integer;
begin
  FfWorkAreaOf(Self, Area);
  W := FfPx(920);
  H := FfPx(640);
  MaxW := Area.Right - Area.Left - FfPx(24);
  MaxH := Area.Bottom - Area.Top - FfPx(24);
  if (MaxW > FfPx(520)) and (W > MaxW) then
    W := MaxW;
  if (MaxH > FfPx(420)) and (H > MaxH) then
    H := MaxH;
  ClientWidth := W;
  ClientHeight := H;
  Constraints.MinWidth := Min(W, FfPx(720));
  Constraints.MinHeight := Min(H, FfPx(480));
end;

procedure TFolderPickForm.ApplyRoundRegion;
var
  Rgn: HRGN;
  R: Integer;
begin
  if not HandleAllocated then Exit;
  if (ClientWidth < 8) or (ClientHeight < 8) then Exit;
  R := FfPx(18);
  Rgn := CreateRoundRectRgn(0, 0, ClientWidth + 1, ClientHeight + 1, R, R);
  SetWindowRgn(Handle, Rgn, True);
end;

procedure TFolderPickForm.Layout;
var
  Pad, Gap, HeadH, ToolY, ToolH, FootH, BodyTop, BodyH, RightW: Integer;
  X, BH, GoW, Inner, BtnH, ListTop, ListH: Integer;
  Back: TColor;
  procedure Place(ABtn: TPickBtn; AX, AY, AW, AH: Integer; ABack: TColor);
  begin
    ABtn.BackColor := ABack;
    ABtn.SetBounds(AX, AY, AW, AH);
  end;
begin
  if not FReady then Exit;
  Pad := FfPx(20);
  Gap := FfPx(10);
  HeadH := FfPx(92);
  ToolH := FfPx(36);
  FootH := FfPx(68);
  RightW := FfPx(292);
  if ClientWidth < FfPx(860) then
    RightW := Max(FfPx(220), (ClientWidth - Pad * 2) * 34 div 100);

  FIcon.SetBounds(Pad + FfPx(6), FfPx(18), FfPx(48), FfPx(48));
  Place(FBtnClose, ClientWidth - Pad - FfPx(32), FfPx(16), FfPx(32), FfPx(32),
    Mix(FGradTop, clWhite, 28));
  FTitle.SetBounds(FIcon.BoundsRect.Right + FfPx(12), FfPx(16),
    FBtnClose.Left - FIcon.BoundsRect.Right - FfPx(24), FfPx(26));
  FSub.SetBounds(FTitle.Left, FTitle.Top + FfPx(28), FTitle.Width, FfPx(40));

  ToolY := HeadH;
  BH := ToolH;
  Place(FBtnBack, Pad, ToolY, BH, BH, FGradTop);
  Place(FBtnUp, FBtnBack.Left + BH + FfPx(6), ToolY, BH, BH, FGradTop);
  Place(FBtnRefresh, FBtnUp.Left + BH + FfPx(6), ToolY, BH, BH, FGradTop);
  Canvas.Font.Name := FUiFont;
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [];
  GoW := Max(FfPx(84), Canvas.TextWidth(FBtnGo.Caption) + FfPx(28));
  Place(FBtnGo, ClientWidth - Pad - GoW, ToolY, GoW, BH, FGradTop);
  X := FRecentW;
  if FBtnGo.Left - (FBtnRefresh.BoundsRect.Right + FfPx(8) + X + FfPx(16)) < FfPx(140) then
    X := Max(FfPx(88), FBtnGo.Left - FBtnRefresh.BoundsRect.Right - FfPx(8) - FfPx(16) - FfPx(140));
  Place(FBtnRecent, FBtnRefresh.BoundsRect.Right + FfPx(8), ToolY, X, BH, FGradTop);
  FPath.SetBounds(FBtnRecent.BoundsRect.Right + FfPx(8), ToolY + FfPx(3),
    Max(FfPx(48), FBtnGo.Left - FBtnRecent.BoundsRect.Right - FfPx(16)), BH - FfPx(6));
  FStatus.SetBounds(Pad, ToolY + ToolH + FfPx(6), ClientWidth - Pad * 2, FfPx(18));

  BodyTop := FStatus.Top + FStatus.Height + FfPx(8);
  BodyH := ClientHeight - FootH - BodyTop;
  if BodyH < FfPx(140) then
    BodyH := FfPx(140);
  FBrowserCard.SetBounds(Pad, BodyTop, ClientWidth - Pad * 2 - RightW - Gap, BodyH);
  FTrayCard.SetBounds(FBrowserCard.BoundsRect.Right + Gap, BodyTop, RightW, BodyH);

  Inner := FfPx(12);
  BtnH := FfPx(32);
  Canvas.Font.Assign(FChkHidden.Font);
  GoW := Canvas.TextWidth(FChkHidden.Caption) + FfPx(24);
  if GoW > (FBrowserCard.Width - Inner * 2) div 2 then
    GoW := (FBrowserCard.Width - Inner * 2) div 2;
  if GoW < FfPx(96) then
    GoW := FfPx(96);
  FChkHidden.SetBounds(FBrowserCard.Width - Inner - GoW, FfPx(10), GoW, FfPx(22));
  FBrowserTitle.SetBounds(Inner, FfPx(10), FChkHidden.Left - Inner - FfPx(8), FfPx(22));
  FBrowserHint.SetBounds(Inner, FBrowserCard.Height - FfPx(28), FBrowserCard.Width - Inner * 2, FfPx(18));
  ListTop := FfPx(38);
  ListH := FBrowserHint.Top - ListTop - FfPx(4);
  if ListH < FfPx(40) then
    ListH := FfPx(40);
  FBrowser.SetBounds(FfPx(8), ListTop, FBrowserCard.Width - FfPx(16), ListH);

  FTrayTitle.SetBounds(Inner, FfPx(10), FTrayCard.Width - Inner * 2, FfPx(22));
  Place(FBtnRemove, Inner, FTrayCard.Height - Inner - BtnH,
    (FTrayCard.Width - Inner * 2 - FfPx(8)) div 2, BtnH, clWhite);
  Place(FBtnClear, FBtnRemove.BoundsRect.Right + FfPx(8), FBtnRemove.Top,
    FTrayCard.Width - Inner - (FBtnRemove.BoundsRect.Right + FfPx(8)), BtnH, clWhite);
  ListTop := FfPx(38);
  ListH := FBtnRemove.Top - ListTop - FfPx(8);
  if ListH < FfPx(40) then
    ListH := FfPx(40);
  FTray.SetBounds(FfPx(8), ListTop, FTrayCard.Width - FfPx(16), ListH);
  FTrayArt.SetBounds(FTray.Left + (FTray.Width - FfPx(64)) div 2, FTray.Top + FfPx(18), FfPx(64), FfPx(64));
  FTrayEmptyTitle.SetBounds(Inner, FTrayArt.BoundsRect.Bottom + FfPx(6), FTrayCard.Width - Inner * 2, FfPx(22));
  FTrayEmptyHint.SetBounds(Inner, FTrayEmptyTitle.BoundsRect.Bottom + FfPx(2),
    FTrayCard.Width - Inner * 2, FfPx(48));

  Back := Mix(FGradTop, FGradBot, 72);
  X := Pad;
  Place(FBtnAddThis, X, ClientHeight - FootH + FfPx(16), FAddThisW, FfPx(36), Back);
  Place(FBtnAddSel, FBtnAddThis.BoundsRect.Right + FfPx(8), FBtnAddThis.Top, FAddSelW, FfPx(36), Back);
  Place(FBtnOk, ClientWidth - Pad - FPrimaryW, FBtnAddThis.Top, FPrimaryW, FfPx(36), Back);
  Place(FBtnCancel, FBtnOk.Left - FfPx(8) - FCancelW, FBtnAddThis.Top, FCancelW, FfPx(36), Back);

  if FBtnAddSel.BoundsRect.Right > FBtnCancel.Left - FfPx(8) then
  begin
    FBtnAddSel.Width := Max(FfPx(96), FBtnCancel.Left - FfPx(8) - FBtnAddSel.Left);
    if FBtnAddThis.BoundsRect.Right > FBtnAddSel.Left - FfPx(8) then
      FBtnAddThis.Width := Max(FfPx(96), FBtnAddSel.Left - FfPx(8) - FBtnAddThis.Left);
  end;
end;

procedure TFolderPickForm.FormPaint(Sender: TObject);
var
  R, AccR, HiR: TRect;
  Rad, AccW: Integer;
begin
  R := ClientRect;
  PaintVerticalGradient(Canvas, R, FGradTop, FGradBot);
  HiR := Rect(0, 0, R.Right, FfPx(86));
  PaintVerticalGradient(Canvas, HiR, Mix(FGradTop, clWhite, 28), Mix(FGradTop, FGradBot, 12));
  AccW := FfPx(5);
  AccR := Rect(FfPx(12), FfPx(18), FfPx(12) + AccW, FfPx(78));
  Canvas.Brush.Color := CAccent;
  Canvas.Pen.Color := Mix(CAccent, clWhite, 20);
  Rad := AccW;
  Canvas.RoundRect(AccR.Left, AccR.Top, AccR.Right, AccR.Bottom, Rad, Rad);
  Canvas.Pen.Color := Mix(CCardLine, FGradBot, 30);
  Canvas.MoveTo(FfPx(20), ClientHeight - FfPx(68));
  Canvas.LineTo(ClientWidth - FfPx(20), ClientHeight - FfPx(68));
  Rad := FfPx(18);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := Mix(CCardLine, clWhite, 20);
  Canvas.RoundRect(1, 1, R.Right - 1, R.Bottom - 1, Rad, Rad);
end;

procedure TFolderPickForm.IconPaint(Sender: TObject);
var
  PB: TPaintBox;
  R: TRect;
  CX, CY, S: Integer;
begin
  PB := Sender as TPaintBox;
  R := PB.ClientRect;
  PB.Canvas.Brush.Color := Mix(FGradTop, clWhite, 30);
  PB.Canvas.FillRect(R);
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  S := Min(R.Right - R.Left, R.Bottom - R.Top) div 2 - 1;
  PB.Canvas.Pen.Color := Mix(CAccent, clWhite, 30);
  PB.Canvas.Brush.Color := Mix(CAccent, clWhite, 78);
  PB.Canvas.Ellipse(CX - S, CY - S, CX + S, CY + S);
  PB.Canvas.Pen.Color := CAccent;
  PB.Canvas.Brush.Color := Mix(CAccent, clWhite, 18);
  PB.Canvas.RoundRect(CX - S + 6, CY - 2, CX + S - 6, CY + S - 6, 4, 4);
  PB.Canvas.Brush.Color := CAccent;
  PB.Canvas.RoundRect(CX - S + 6, CY - S + 8, CX - 1, CY - 1, 3, 3);
end;

procedure TFolderPickForm.TrayArtPaint(Sender: TObject);
var
  PB: TPaintBox;
  R: TRect;
  CX, CY, S: Integer;
begin
  PB := Sender as TPaintBox;
  R := PB.ClientRect;
  PB.Canvas.Brush.Color := clWhite;
  PB.Canvas.FillRect(R);
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  S := Min(R.Right - R.Left, R.Bottom - R.Top) div 2 - 2;
  PB.Canvas.Pen.Color := Mix(CAccent, clWhite, 45);
  PB.Canvas.Brush.Color := Mix(CAccent, clWhite, 88);
  PB.Canvas.Ellipse(CX - S, CY - S, CX + S, CY + S);
  PB.Canvas.Pen.Color := Mix(CAccent, clWhite, 10);
  PB.Canvas.Brush.Color := Mix(CAccent, clWhite, 28);
  PB.Canvas.RoundRect(CX - S + 10, CY - 2, CX + S - 10, CY + S - 12, 5, 5);
  PB.Canvas.Brush.Color := CAccent;
  PB.Canvas.Pen.Color := CAccent;
  PB.Canvas.RoundRect(CX - S + 10, CY - S + 12, CX, CY, 3, 3);
end;

procedure TFolderPickForm.FormResize(Sender: TObject);
begin
  if not FReady then Exit;
  Layout;
  ApplyRoundRegion;
end;

procedure TFolderPickForm.PathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    GoClick(Sender);
  end;
end;

procedure TFolderPickForm.FormShow(Sender: TObject);
begin
  Layout;
  ApplyRoundRegion;
  if (FBrowser <> nil) and FBrowser.CanFocus and FBrowser.Visible then
    FBrowser.SetFocus;
end;

procedure TFolderPickForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end
  else if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    ConfirmClick(nil);
  end
  else if Key = VK_F5 then
  begin
    Key := 0;
    RefreshClick(nil);
  end
  else if (Key = VK_LEFT) and (ssAlt in Shift) then
  begin
    Key := 0;
    BackClick(nil);
  end
  else if (Key = VK_UP) and (ssAlt in Shift) then
  begin
    Key := 0;
    UpClick(nil);
  end
  else if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    Key := 0;
    RecentClick(nil);
  end;
end;

procedure TFolderPickForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  HeaderMouseDown(Sender, Button, Shift, X, Y);
end;

procedure TFolderPickForm.HeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0);
end;

procedure TFolderPickForm.SetStatus(const AText: string; AError: Boolean);
begin
  if FStatus = nil then Exit;
  FStatus.Caption := AText;
  if AError then
    FStatus.Font.Color := CErr
  else if AText = '' then
    FStatus.Font.Color := CMuted
  else
    FStatus.Font.Color := Mix(CAccent, clBlack, 8);
end;

procedure TFolderPickForm.Navigate(const APath: string; APush: Boolean);
var
  P: string;
begin
  P := APath;
  if P <> '' then
    P := NormalizeDir(P);
  if APush then
  begin
    if (FHistIndex < 0) or (FHistIndex >= FHist.Count) or not SameText(FHist[FHistIndex], P) then
    begin
      while FHist.Count > FHistIndex + 1 do
        FHist.Delete(FHist.Count - 1);
      FHist.Add(P);
      FHistIndex := FHist.Count - 1;
    end;
  end;
  FCurrent := P;
  Reload;
end;

procedure TFolderPickForm.Reload;
var
  Names: TStringList;
  SR: TSearchRec;
  Code, PrevCursor: Integer;
  Full, Msg: string;
  Row: TFolderRow;
  I: Integer;
  Buf: array[0..2047] of Char;
  P: PChar;
  procedure AddMessage(const AText: string);
  begin
    Row := TFolderRow.Create;
    Row.Name := AText;
    Row.Path := '';
    Row.Icon := -1;
    FBrowser.Items.AddObject(AText, Row);
  end;
  procedure AddDir(const AFull, AName: string);
  begin
    Row := TFolderRow.Create;
    Row.Path := AFull;
    Row.Name := AName;
    Row.Icon := IconIndexOf(AFull);
    Names.AddObject(AName, Row);
  end;
begin
  if FBrowser = nil then Exit;
  Msg := '';
  Names := TStringList.Create;
  PrevCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  FBrowser.Items.BeginUpdate;
  try
    Names.CaseSensitive := False;
    FreeRows(FBrowser);
    FHoverBrowser := -1;
    if FCurrent = '' then
    begin
      if GetLogicalDriveStrings(Length(Buf) - 1, Buf) = 0 then
        Msg := TrText('FolderPick.NoDrives')
      else
      begin
        P := @Buf[0];
        while P^ <> #0 do
        begin
          AddDir(IncludeTrailingPathDelimiter(P), DriveCaption(IncludeTrailingPathDelimiter(P)));
          P := P + StrLen(P) + 1;
        end;
      end;
    end
    else if not DirectoryExists(FCurrent) then
      Msg := TrText('FolderPick.NotFound')
    else
    begin
      Code := FindFirst(IncludeTrailingPathDelimiter(FCurrent) + '*', faAnyFile, SR);
      if Code <> 0 then
        Msg := TrText('FolderPick.OpenFail')
      else
      try
        repeat
          if (SR.Attr and faDirectory) = 0 then Continue;
          if (SR.Name = '.') or (SR.Name = '..') then Continue;
          {$WARN SYMBOL_PLATFORM OFF}
          if not FChkHidden.Checked and ((SR.Attr and faHidden) <> 0) then Continue;
          {$WARN SYMBOL_PLATFORM ON}
          Full := IncludeTrailingPathDelimiter(FCurrent) + SR.Name;
          AddDir(ExcludeTrailingPathDelimiter(Full), SR.Name);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
    Names.Sort;
    for I := 0 to Names.Count - 1 do
    begin
      FBrowser.Items.AddObject(Names[I], Names.Objects[I]);
      Names.Objects[I] := nil;
    end;
    if FBrowser.Items.Count = 0 then
    begin
      if Msg = '' then
      begin
        if FCurrent = '' then
          Msg := TrText('FolderPick.NoDrives')
        else
          Msg := TrText('FolderPick.EmptyDir');
      end;
      AddMessage(Msg);
      SetStatus(Msg, Msg <> TrText('FolderPick.EmptyDir'));
    end
    else
      SetStatus('', False);
  finally
    FBrowser.Items.EndUpdate;
    if Names <> nil then
    begin
      for I := 0 to Names.Count - 1 do
        Names.Objects[I].Free;
      Names.Free;
    end;
    Screen.Cursor := PrevCursor;
    UpdateChrome;
  end;
end;

function TFolderPickForm.SelectedCount: Integer;
var
  I: Integer;
  Row: TFolderRow;
begin
  Result := 0;
  if FBrowser = nil then Exit;
  for I := 0 to FBrowser.Items.Count - 1 do
  begin
    if not FBrowser.Selected[I] then Continue;
    Row := RowAt(FBrowser, I);
    if (Row <> nil) and (Row.Path <> '') then
      Inc(Result);
  end;
end;

function TFolderPickForm.CommitCount: Integer;
begin
  if (FTray <> nil) and (FTray.Items.Count > 0) then
    Result := FTray.Items.Count
  else
  begin
    Result := SelectedCount;
    if (Result = 0) and (FCurrent <> '') then
      Result := 1;
  end;
end;

function TFolderPickForm.AddToTray(const APath, AName: string; AIcon: Integer): Boolean;
var
  I: Integer;
  Row: TFolderRow;
  P, N: string;
begin
  Result := False;
  P := NormalizeDir(APath);
  if (P = '') or not DirectoryExists(P) then Exit;
  for I := 0 to FTray.Items.Count - 1 do
  begin
    Row := RowAt(FTray, I);
    if (Row <> nil) and SameText(Row.Path, P) then Exit;
  end;
  N := AName;
  if N = '' then
    N := DirTitle(P);
  Row := TFolderRow.Create;
  Row.Path := P;
  Row.Name := N;
  Row.Icon := AIcon;
  if Row.Icon < 0 then
    Row.Icon := IconIndexOf(P);
  FTray.Items.AddObject(N, Row);
  FTray.ItemIndex := FTray.Items.Count - 1;
  RememberFolder(P);
  Result := True;
end;

procedure TFolderPickForm.UpdateChrome;
var
  N: Integer;
  RealSel: Integer;
begin
  if not FReady then Exit;
  FBtnBack.Enabled := FHistIndex > 0;
  if FBtnRecent <> nil then
    FBtnRecent.Enabled := (FFolderRecent <> nil) and (FFolderRecent.Count > 0);
  FBtnUp.Enabled := FCurrent <> '';
  FBtnAddThis.Enabled := FCurrent <> '';
  RealSel := SelectedCount;
  FBtnAddSel.Enabled := RealSel > 0;
  FBtnRemove.Enabled := (FTray <> nil) and (FTray.SelCount > 0);
  FBtnClear.Enabled := (FTray <> nil) and (FTray.Items.Count > 0);
  N := CommitCount;
  FBtnOk.Enabled := N > 0;
  if N <= 0 then
  begin
    FBtnOk.Caption := TrText('FolderPick.Confirm');
    FBtnOk.Hint := TrText('FolderPick.HintOkThis');
  end
  else if N = 1 then
  begin
    FBtnOk.Caption := TrText('FolderPick.Confirm1');
    if (FTray <> nil) and (FTray.Items.Count > 0) then
      FBtnOk.Hint := TrText('FolderPick.HintOkTray')
    else if RealSel > 0 then
      FBtnOk.Hint := TrText('FolderPick.HintOkSel')
    else
      FBtnOk.Hint := TrText('FolderPick.HintOkThis');
  end
  else
  begin
    FBtnOk.Caption := Format(TrText('FolderPick.ConfirmN'), [N]);
    if (FTray <> nil) and (FTray.Items.Count > 0) then
      FBtnOk.Hint := TrText('FolderPick.HintOkTray')
    else
      FBtnOk.Hint := TrText('FolderPick.HintOkSel');
  end;

  if FCurrent = '' then
  begin
    FBrowserTitle.Caption := TrText('FolderPick.ThisPC');
    FPath.Text := '';
  end
  else
  begin
    FBrowserTitle.Caption := DirTitle(FCurrent);
    if FPath.Text <> FCurrent then
      FPath.Text := FCurrent;
  end;

  if RealSel > 0 then
  begin
    FBrowserHint.Caption := Format(TrText('FolderPick.SelectedN'), [RealSel]);
    FBrowserHint.Font.Color := CAccent;
  end
  else
  begin
    FBrowserHint.Caption := TrText('FolderPick.ListHint');
    FBrowserHint.Font.Color := CMuted;
  end;

  if FTray.Items.Count = 0 then
    FTrayTitle.Caption := TrText('FolderPick.ToAdd')
  else
    FTrayTitle.Caption := Format(TrText('FolderPick.ToAddN'), [FTray.Items.Count]);
  FTray.Visible := FTray.Items.Count > 0;
  FTrayArt.Visible := not FTray.Visible;
  FTrayEmptyTitle.Visible := not FTray.Visible;
  FTrayEmptyHint.Visible := not FTray.Visible;
end;

procedure TFolderPickForm.CloseRecentPopup;
begin
  if not Assigned(FormPopupMruList) then Exit;
  FormPopupMruList.OnPick := nil;
  FormPopupMruList.OnProperties := nil;
  FormPopupMruList.OnRemove := nil;
  FormPopupMruList.OnClearAll := nil;
  if FormPopupMruList.Visible then
    FormPopupMruList.ClosePopup(False);
end;

procedure TFolderPickForm.RememberFolder(const APath: string);
begin
  if FFolderRecent = nil then Exit;
  if not DirectoryExists(APath) then Exit;
  RememberAgentFolder(FFolderRecent, APath);
  SaveAgentFolderRecent(FFolderRecent);
end;

procedure TFolderPickForm.RecentClick(Sender: TObject);
begin
  Application.CancelHint;
  ReleaseCapture;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    CloseRecentPopup;
    Exit;
  end;
  OpenRecentPopup;
end;

procedure TFolderPickForm.OpenRecentPopup;
begin
  if (FBtnRecent = nil) or not FBtnRecent.Enabled then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if FRecentPosted then Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRecentPosted := True;
  PostMessage(Handle, WM_APP + 51, 0, 0);
end;

procedure TFolderPickForm.WMRecentPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FRecentPosted := False;
  ReleaseCapture;
  { Same as the other MRUs: wait until the opening click is finished. }
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FRecentPosted := True;
    PostMessage(Handle, WM_APP + 51, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if (FFolderRecent = nil) or (FFolderRecent.Count = 0) or not FBtnRecent.Enabled then Exit;
  if FBtnRecent.HandleAllocated then
  begin
    GetWindowRect(FBtnRecent.Handle, CR);
    P := Point(CR.Left, CR.Bottom);
    W := CR.Right - CR.Left;
  end
  else
  begin
    P := FBtnRecent.ClientToScreen(Point(0, FBtnRecent.Height));
    W := FBtnRecent.Width;
  end;
  W := Max(W, FfPx(420));
  { Component owner is the main form. The dialog handle is only the window
    owner, so closing this dialog cannot free the shared popup out from under
    the Diagnóstico / Agente Recentes buttons. }
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('FolderPick.RecentTitle'), MruMoreCaption('RecentFiles.More'),
    FFolderRecent, W, P, RecentPick, TrText('RecentFiles.MoreHint'),
    RecentProps, RecentRemove, FBtnRecent, RecentClearAll, Handle);
end;

procedure TFolderPickForm.RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
var
  P: string;
begin
  P := Trim(AValue);
  if DirectoryExists(P) then
  begin
    RememberFolder(P);
    Navigate(P, True);
    if AddToTray(P, DirTitle(P), IconIndexOf(P)) then
      SetStatus(Format(TrText('FolderPick.AddedN'), [1]), False)
    else
      SetStatus(TrText('FolderPick.Already'), False);
    UpdateChrome;
  end
  else
  begin
    RecentRemove(Sender, P);
    FastFileMsgInfo(Format(TrText('FolderPick.RecentMissing'), [P]), TrText('FolderPick.RecentTitle'));
  end;
end;

procedure TFolderPickForm.RecentRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
  P: string;
begin
  if FFolderRecent = nil then Exit;
  P := ExcludeTrailingPathDelimiter(Trim(AValue));
  for I := FFolderRecent.Count - 1 downto 0 do
    if SameText(ExcludeTrailingPathDelimiter(FFolderRecent[I]), P) then
      FFolderRecent.Delete(I);
  SaveAgentFolderRecent(FFolderRecent);
  UpdateChrome;
end;

procedure TFolderPickForm.RecentProps(Sender: TObject; const AValue: string);
var
  Info: TShellExecuteInfo;
  P: string;
begin
  P := Trim(AValue);
  if not DirectoryExists(P) then
  begin
    FastFileMsgInfo(Format(TrText('FolderPick.RecentMissing'), [P]), TrText('FolderPick.RecentTitle'));
    RecentRemove(Sender, P);
    Exit;
  end;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_INVOKEIDLIST;
  Info.Wnd := Handle;
  Info.lpVerb := 'properties';
  Info.lpFile := PChar(P);
  Info.nShow := SW_SHOW;
  ShellExecuteEx(@Info);
end;

procedure TFolderPickForm.RecentClearAll(Sender: TObject);
begin
  if FFolderRecent = nil then Exit;
  FFolderRecent.Clear;
  SaveAgentFolderRecent(FFolderRecent);
  UpdateChrome;
end;

procedure TFolderPickForm.GoClick(Sender: TObject);
var
  S: string;
begin
  S := Trim(FPath.Text);
  if S = '' then
  begin
    Navigate('', True);
    Exit;
  end;
  S := NormalizeDir(S);
  if DirectoryExists(S) then
    Navigate(S, True)
  else
    SetStatus(TrText('FolderPick.NotFound'), True);
end;

procedure TFolderPickForm.BackClick(Sender: TObject);
begin
  if FHistIndex <= 0 then Exit;
  Dec(FHistIndex);
  FCurrent := FHist[FHistIndex];
  Reload;
end;

procedure TFolderPickForm.UpClick(Sender: TObject);
begin
  if FCurrent = '' then Exit;
  Navigate(ParentOf(FCurrent), True);
end;

procedure TFolderPickForm.RefreshClick(Sender: TObject);
begin
  Reload;
end;

procedure TFolderPickForm.HiddenClick(Sender: TObject);
begin
  Reload;
end;

procedure TFolderPickForm.AddThisClick(Sender: TObject);
begin
  if FCurrent = '' then
  begin
    SetStatus(TrText('FolderPick.NeedOne'), True);
    Exit;
  end;
  if AddToTray(FCurrent, DirTitle(FCurrent), IconIndexOf(FCurrent)) then
    SetStatus(Format(TrText('FolderPick.AddedN'), [1]), False)
  else
    SetStatus(TrText('FolderPick.Already'), False);
  UpdateChrome;
end;

procedure TFolderPickForm.AddSelClick(Sender: TObject);
var
  I, N, Seen: Integer;
  Row: TFolderRow;
begin
  N := 0;
  Seen := 0;
  for I := 0 to FBrowser.Items.Count - 1 do
  begin
    if not FBrowser.Selected[I] then Continue;
    Row := RowAt(FBrowser, I);
    if (Row = nil) or (Row.Path = '') then Continue;
    Inc(Seen);
    if AddToTray(Row.Path, Row.Name, Row.Icon) then
      Inc(N);
  end;
  if N > 0 then
    SetStatus(Format(TrText('FolderPick.AddedN'), [N]), False)
  else if Seen > 0 then
    SetStatus(TrText('FolderPick.Already'), False)
  else
    SetStatus(TrText('FolderPick.NeedOne'), True);
  UpdateChrome;
end;

procedure TFolderPickForm.RemoveClick(Sender: TObject);
var
  I: Integer;
begin
  for I := FTray.Items.Count - 1 downto 0 do
    if FTray.Selected[I] then
    begin
      FTray.Items.Objects[I].Free;
      FTray.Items.Delete(I);
    end;
  UpdateChrome;
end;

procedure TFolderPickForm.ClearClick(Sender: TObject);
begin
  FreeRows(FTray);
  SetStatus('', False);
  UpdateChrome;
end;

procedure TFolderPickForm.ConfirmClick(Sender: TObject);
var
  I, N: Integer;
  Row: TFolderRow;
begin
  if not FBtnOk.Enabled then Exit;
  if FTray.Items.Count = 0 then
  begin
    N := 0;
    for I := 0 to FBrowser.Items.Count - 1 do
    begin
      if not FBrowser.Selected[I] then Continue;
      Row := RowAt(FBrowser, I);
      if (Row = nil) or (Row.Path = '') then Continue;
      if AddToTray(Row.Path, Row.Name, Row.Icon) then
        Inc(N);
    end;
    if (N = 0) and (FCurrent <> '') then
      AddToTray(FCurrent, DirTitle(FCurrent), IconIndexOf(FCurrent));
  end;
  FChosen.Clear;
  for I := 0 to FTray.Items.Count - 1 do
  begin
    Row := RowAt(FTray, I);
    if (Row <> nil) and (Row.Path <> '') and (FChosen.IndexOf(Row.Path) < 0) then
      FChosen.Add(Row.Path);
  end;
  if FChosen.Count = 0 then
  begin
    SetStatus(TrText('FolderPick.NeedOne'), True);
    UpdateChrome;
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TFolderPickForm.CloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFolderPickForm.BrowserClick(Sender: TObject);
var
  I: Integer;
  Row: TFolderRow;
begin
  for I := 0 to FBrowser.Items.Count - 1 do
  begin
    Row := RowAt(FBrowser, I);
    if (Row <> nil) and (Row.Path = '') then
      FBrowser.Selected[I] := False;
  end;
  UpdateChrome;
end;

procedure TFolderPickForm.BrowserDblClick(Sender: TObject);
var
  Row: TFolderRow;
begin
  Row := RowAt(FBrowser, FBrowser.ItemIndex);
  if (Row = nil) or (Row.Path = '') then Exit;
  Navigate(Row.Path, True);
end;

procedure TFolderPickForm.BrowserKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;
begin
  if (Key = VK_RETURN) and not (ssCtrl in Shift) then
  begin
    Key := 0;
    BrowserDblClick(Sender);
  end
  else if Key = VK_BACK then
  begin
    Key := 0;
    UpClick(Sender);
  end
  else if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    Key := 0;
    FBrowser.SelectAll;
    for I := 0 to FBrowser.Items.Count - 1 do
      if (RowAt(FBrowser, I) = nil) or (RowAt(FBrowser, I).Path = '') then
        FBrowser.Selected[I] := False;
    UpdateChrome;
  end;
end;

procedure TFolderPickForm.BrowserMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  I := FBrowser.ItemAtPos(Point(X, Y), True);
  if I <> FHoverBrowser then
  begin
    FHoverBrowser := I;
    FBrowser.Invalidate;
  end;
end;

procedure TFolderPickForm.BrowserMouseLeave(Sender: TObject);
begin
  if FHoverBrowser <> -1 then
  begin
    FHoverBrowser := -1;
    FBrowser.Invalidate;
  end;
end;

procedure TFolderPickForm.TrayClick(Sender: TObject);
begin
  UpdateChrome;
end;

procedure TFolderPickForm.TrayKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    Key := 0;
    RemoveClick(Sender);
  end;
end;

procedure TFolderPickForm.TrayMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  I := FTray.ItemAtPos(Point(X, Y), True);
  if I <> FHoverTray then
  begin
    FHoverTray := I;
    FTray.Invalidate;
  end;
end;

procedure TFolderPickForm.TrayMouseLeave(Sender: TObject);
begin
  if FHoverTray <> -1 then
  begin
    FHoverTray := -1;
    FTray.Invalidate;
  end;
end;

procedure TFolderPickForm.ListDraw(Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var
  List: TListBox;
  Row: TFolderRow;
  C: TCanvas;
  TR, Bar: TRect;
  Hover, Sel, Tray: Boolean;
  IX, IY, IW, IH: Integer;
begin
  List := Control as TListBox;
  C := List.Canvas;
  Row := RowAt(List, Index);
  Tray := List = FTray;
  Sel := (Row <> nil) and (Row.Path <> '') and (odSelected in State);
  Hover := (not Sel) and (Row <> nil) and (Row.Path <> '') and
    (((List = FBrowser) and (Index = FHoverBrowser)) or ((List = FTray) and (Index = FHoverTray)));
  if Sel then
    C.Brush.Color := Mix(clWhite, CAccent, 14)
  else if Hover then
    C.Brush.Color := Mix(clWhite, CAccent, 6)
  else
    C.Brush.Color := clWhite;
  C.FillRect(Rect);
  if Sel then
  begin
    C.Brush.Color := CAccent;
    Bar.Left := Rect.Left;
    Bar.Top := Rect.Top + 3;
    Bar.Right := Rect.Left + FfPx(3);
    Bar.Bottom := Rect.Bottom - 3;
    C.FillRect(Bar);
  end;
  if (Row = nil) or (Row.Path = '') then
  begin
    C.Font.Name := FUiFont;
    C.Font.Size := 9;
    C.Font.Style := [];
    C.Font.Color := CMuted;
    C.Brush.Style := bsClear;
    TR := Rect;
    InflateRect(TR, -FfPx(12), 0);
    DrawText(C.Handle, PChar(List.Items[Index]), -1, TR,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
    Exit;
  end;

  IW := 16;
  IH := 16;
  if SysImages <> 0 then
    ImageList_GetIconSize(SysImages, IW, IH);
  IX := Rect.Left + FfPx(12);
  IY := Rect.Top + (Rect.Bottom - Rect.Top - IH) div 2;
  if Row.Icon >= 0 then
    DrawShellIcon(C, Row.Icon, IX, IY)
  else
  begin
    C.Pen.Color := Mix(CAccent, clWhite, 15);
    C.Brush.Color := Mix(CAccent, clWhite, 35);
    C.RoundRect(IX, IY + 3, IX + IW, IY + IH, 3, 3);
    C.Brush.Color := CAccent;
    C.RoundRect(IX, IY, IX + IW div 2, IY + 4, 2, 2);
  end;

  C.Brush.Style := bsClear;
  C.Font.Name := FUiFont;
  TR := Rect;
  TR.Left := IX + IW + FfPx(10);
  TR.Right := Rect.Right - FfPx(10);
  if Tray then
  begin
    C.Font.Size := 9;
    C.Font.Style := [];
    C.Font.Color := CTitle;
    TR.Bottom := Rect.Top + (Rect.Bottom - Rect.Top) div 2 + FfPx(2);
    DrawText(C.Handle, PChar(Row.Name), -1, TR,
      DT_LEFT or DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
    C.Font.Size := 8;
    C.Font.Color := CMuted;
    TR.Top := TR.Bottom;
    TR.Bottom := Rect.Bottom - FfPx(4);
    DrawText(C.Handle, PChar(Row.Path), -1, TR,
      DT_LEFT or DT_TOP or DT_SINGLELINE or DT_PATH_ELLIPSIS or DT_NOPREFIX);
  end
  else
  begin
    C.Font.Size := 9;
    C.Font.Style := [];
    C.Font.Color := CTitle;
    DrawText(C.Handle, PChar(Row.Name), -1, TR,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;
end;

end.
