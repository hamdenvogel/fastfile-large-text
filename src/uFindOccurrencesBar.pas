unit uFindOccurrencesBar;
{ Docked Find Occurrences chrome after Ctrl+F.
  Prev/Next (Shift+F3 / F3), collect hits into a paginated clickable list
  (click → jump ListView/CheckList), Load more for next hit page from disk. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Math, Buttons, sPanel, sLabel, sButton, uFastFileScale;

type
  TFindOccHitEvent = procedure(Sender: TObject; AHitIndex: Int64) of object;

  TFastFileFindOccBar = class(TsPanel)
  private
    FBuilt: Boolean;
    FExpanded: Boolean;
    FAccent: TsPanel;
    FBody: TsPanel;
    FTopRow: TsPanel;
    FSearchRow: TsPanel;
    FBtnRow: TsPanel;
    FListHost: TsPanel;
    FListShell: TsPanel;
    FListInner: TsPanel;
    FPageBar: TsPanel;
    FLblTitle: TsLabel;
    FLblStatus: TsLabel;
    FLblPage: TsLabel;
    FEditShell: TsPanel;
    FEditFrame: TsPanel;
    FEdtFind: TEdit;
    FBtnGo: TsButton;
    FBtnPrev: TsButton;
    FBtnNext: TsButton;
    FBtnCollect: TsButton;
    FBtnLoadMore: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnClear: TsButton;
    FBtnHide: TsButton;
    FBtnFloat: TsButton;
    FBtnPagePrev: TsButton;
    FBtnPageNext: TsButton;
    FHitList: TListBox;
    FHitPageBase: Int64;
    FOnPrev: TNotifyEvent;
    FOnNext: TNotifyEvent;
    FOnSearch: TNotifyEvent;
    FOnCollect: TNotifyEvent;
    FOnLoadMore: TNotifyEvent;
    FOnExport: TNotifyEvent;
    FOnCopy: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnFloat: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnHitClick: TFindOccHitEvent;
    FOnListPagePrev: TNotifyEvent;
    FOnListPageNext: TNotifyEvent;
    FFloating: Boolean;
    FHeaderDown: Boolean;
    FHeaderPt: TPoint;
    procedure BuildChrome;
    procedure ForceColor(APnl: TsPanel; AColor: TColor);
    procedure StyleBtn(ABtn: TsButton; const AUiFont: string);
    procedure StyleChromeBtn(ABtn: TsButton; const AUiFont: string);
    procedure LayoutChrome;
    procedure BodyResize(Sender: TObject);
    procedure BtnPrevClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure BtnGoClick(Sender: TObject);
    procedure EdtFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnCollectClick(Sender: TObject);
    procedure BtnLoadMoreClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure BtnPagePrevClick(Sender: TObject);
    procedure BtnPageNextClick(Sender: TObject);
    procedure HitListDblClick(Sender: TObject);
    procedure HitListClick(Sender: TObject);
    procedure FireHitClick;
    procedure TitleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SyncFloatAction;
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure EnsureBuilt;
    procedure ApplyCaptions;
    procedure ApplySoftChrome;
    procedure SetStatus(const AStatusText: string; ABusy, AHasHits, APartial: Boolean);
    procedure SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
    procedure SetCollectEnabled(AEnabled: Boolean);
    procedure SetExpanded(AExpanded: Boolean);
    procedure ClearHitList;
    function PreferredExpandedHeight: Integer;
    function GetSearchText: string;
    procedure SetSearchText(const AText: string);
    procedure FocusSearchEdit;
    function SearchEditFocused: Boolean;
    procedure SetHitListPage(ALines: TStrings; APageBase: Int64;
      APageIndex, APageCount, ATotalHits: Integer; ACanPagePrev, ACanPageNext: Boolean);
    property OnPrev: TNotifyEvent read FOnPrev write FOnPrev;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
    property OnSearch: TNotifyEvent read FOnSearch write FOnSearch;
    property OnCollect: TNotifyEvent read FOnCollect write FOnCollect;
    property OnLoadMore: TNotifyEvent read FOnLoadMore write FOnLoadMore;
    property OnContinue: TNotifyEvent read FOnLoadMore write FOnLoadMore;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnHitClick: TFindOccHitEvent read FOnHitClick write FOnHitClick;
    property OnListPagePrev: TNotifyEvent read FOnListPagePrev write FOnListPagePrev;
    property OnListPageNext: TNotifyEvent read FOnListPageNext write FOnListPageNext;
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
  end;

  TFastFileFindOccPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftChrome;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  FIND_OCC_BAR_HEIGHT = 148;
  { Compact hit list so the file ListView below keeps usable space. }
  FIND_OCC_BAR_EXPANDED = 248;
  FIND_OCC_PEEK_HEIGHT = 5;
  FIND_OCC_BTN_H = 34;
  FIND_OCC_BTN_PAD_X = 22;
  FIND_OCC_TOP_H = 28;
  FIND_OCC_SEARCH_H = 32;
  FIND_OCC_LIST_PAGE_SIZE = 40;
  FIND_OCC_LIST_MIN_H = 64;

implementation

uses
  uI18n;

const
  { Soft warm chrome shared with Filter bar. }
  CAccent = TColor($00BFAF9C);
  CSurface = TColor($00F6F3EE);
  CSurfaceHi = TColor($00EDE8E1);
  CBorder = TColor($00CFC6BB);
  CWindow = TColor($00FFFCF8);
  CTitle = TColor($001C1610);
  CMuted = TColor($006B6158);
  CStatusOk = TColor($002E7D32);
  CStatusBusy = TColor($00B15A1A);
  CStatusIdle = TColor($006B6158);
  CAccentW = 3;

function PreferUiFont: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

{ TFastFileFindOccBar }

constructor TFastFileFindOccBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuilt := False;
  FExpanded := False;
  FFloating := False;
  FHeaderDown := False;
  FHitPageBase := 0;
  Align := alTop;
  Height := FfPx(FIND_OCC_BAR_HEIGHT);
  Constraints.MinHeight := FfPx(FIND_OCC_BAR_HEIGHT);
  BevelOuter := bvNone;
  Caption := '';
  ParentBackground := False;
  ParentColor := False;
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  Color := CSurface;
end;

procedure TFastFileFindOccBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(AParent) then
    EnsureBuilt;
end;

procedure TFastFileFindOccBar.EnsureBuilt;
begin
  if FBuilt then Exit;
  BuildChrome;
  FBuilt := True;
  ApplySoftChrome;
  ApplyCaptions;
  LayoutChrome;
end;

procedure TFastFileFindOccBar.ForceColor(APnl: TsPanel; AColor: TColor);
begin
  if not Assigned(APnl) then Exit;
  try
    APnl.SkinData.CustomColor := True;
    APnl.SkinData.SkinSection := '';
  except
  end;
  APnl.ParentBackground := False;
  APnl.ParentColor := False;
  APnl.Color := AColor;
end;

procedure TFastFileFindOccBar.StyleBtn(ABtn: TsButton; const AUiFont: string);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.Height := FfPx(FIND_OCC_BTN_H);
  ABtn.ParentFont := False;
  ABtn.Font.Name := AUiFont;
  ABtn.Font.Size := 9;
  ABtn.Font.Color := CTitle;
  ABtn.ShowHint := True;
  try
    ABtn.SkinData.SkinSection := 'BUTTON';
  except
  end;
end;

procedure TFastFileFindOccBar.StyleChromeBtn(ABtn: TsButton; const AUiFont: string);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.ParentFont := False;
  ABtn.Font.Name := AUiFont;
  ABtn.Font.Size := 11;
  ABtn.Font.Color := CMuted;
  ABtn.ShowHint := True;
  ABtn.TabStop := False;
  try
    ABtn.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
end;

procedure TFastFileFindOccBar.BuildChrome;
var
  UiFont: string;
begin
  UiFont := PreferUiFont;

  FAccent := TsPanel.Create(Self);
  FAccent.Parent := Self;
  FAccent.Align := alLeft;
  FAccent.Width := CAccentW;
  FAccent.BevelOuter := bvNone;
  FAccent.Caption := '';
  ForceColor(FAccent, CAccent);

  FBody := TsPanel.Create(Self);
  FBody.Parent := Self;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.Caption := '';
  FBody.Padding.Left := FfPx(10);
  FBody.Padding.Right := FfPx(8);
  FBody.Padding.Top := FfPx(8);
  FBody.Padding.Bottom := FfPx(8);
  FBody.OnResize := BodyResize;
  ForceColor(FBody, CSurface);

  FTopRow := TsPanel.Create(Self);
  FTopRow.Parent := FBody;
  FTopRow.Align := alNone;
  FTopRow.Height := FfPx(FIND_OCC_TOP_H);
  FTopRow.BevelOuter := bvNone;
  FTopRow.Caption := '';
  ForceColor(FTopRow, CSurfaceHi);

  FLblTitle := TsLabel.Create(Self);
  FLblTitle.Parent := FTopRow;
  FLblTitle.Align := alLeft;
  FLblTitle.AutoSize := True;
  FLblTitle.Transparent := True;
  FLblTitle.ParentFont := False;
  FLblTitle.Font.Name := UiFont;
  FLblTitle.Font.Size := 10;
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Font.Color := CTitle;
  FLblTitle.Caption := 'Occurrences';
  FLblTitle.Layout := tlCenter;
  FLblTitle.Cursor := crSizeAll;
  FLblTitle.OnMouseDown := TitleMouseDown;
  FLblTitle.OnMouseMove := TitleMouseMove;
  FLblTitle.OnMouseUp := TitleMouseUp;

  FBtnHide := TsButton.Create(Self);
  FBtnHide.Parent := FTopRow;
  FBtnHide.Align := alRight;
  FBtnHide.Width := FfPx(28);
  FBtnHide.OnClick := BtnHideClick;
  StyleChromeBtn(FBtnHide, UiFont);

  FBtnFloat := TsButton.Create(Self);
  FBtnFloat.Parent := FTopRow;
  FBtnFloat.Align := alRight;
  FBtnFloat.Width := FfPx(28);
  FBtnFloat.OnClick := BtnFloatClick;
  StyleChromeBtn(FBtnFloat, UiFont);

  FLblStatus := TsLabel.Create(Self);
  FLblStatus.Parent := FTopRow;
  FLblStatus.Align := alClient;
  FLblStatus.Transparent := True;
  FLblStatus.ParentFont := False;
  FLblStatus.Font.Name := UiFont;
  FLblStatus.Font.Size := 8;
  FLblStatus.Font.Color := CMuted;
  FLblStatus.Caption := '';
  FLblStatus.Layout := tlCenter;

  FSearchRow := TsPanel.Create(Self);
  FSearchRow.Parent := FBody;
  FSearchRow.Align := alNone;
  FSearchRow.Height := FfPx(FIND_OCC_SEARCH_H);
  FSearchRow.BevelOuter := bvNone;
  FSearchRow.Caption := '';
  ForceColor(FSearchRow, CSurface);

  FEditShell := TsPanel.Create(Self);
  FEditShell.Parent := FSearchRow;
  FEditShell.BevelOuter := bvNone;
  FEditShell.Caption := '';
  ForceColor(FEditShell, CBorder);

  FEditFrame := TsPanel.Create(Self);
  FEditFrame.Parent := FEditShell;
  FEditFrame.Align := alClient;
  FEditFrame.BevelOuter := bvNone;
  FEditFrame.Caption := '';
  FEditFrame.Padding.Left := FfPx(6);
  FEditFrame.Padding.Right := FfPx(6);
  FEditFrame.Padding.Top := FfPx(3);
  FEditFrame.Padding.Bottom := FfPx(3);
  ForceColor(FEditFrame, CWindow);

  FEdtFind := TEdit.Create(Self);
  FEdtFind.Parent := FEditFrame;
  FEdtFind.Align := alClient;
  FEdtFind.BorderStyle := bsNone;
  FEdtFind.ParentFont := False;
  FEdtFind.Font.Name := UiFont;
  FEdtFind.Font.Size := 10;
  FEdtFind.Font.Color := CTitle;
  FEdtFind.ParentColor := False;
  FEdtFind.Color := CWindow;
  FEdtFind.OnKeyDown := EdtFindKeyDown;
  FEdtFind.ShowHint := True;

  FBtnGo := TsButton.Create(Self);
  FBtnGo.Parent := FSearchRow;
  FBtnGo.OnClick := BtnGoClick;
  StyleBtn(FBtnGo, UiFont);
  FBtnGo.Font.Style := [fsBold];

  FBtnRow := TsPanel.Create(Self);
  FBtnRow.Parent := FBody;
  FBtnRow.Align := alNone;
  FBtnRow.Height := FfPx(FIND_OCC_BTN_H + 6);
  FBtnRow.BevelOuter := bvNone;
  FBtnRow.Caption := '';
  ForceColor(FBtnRow, CSurface);

  FBtnPrev := TsButton.Create(Self);
  FBtnPrev.Parent := FBtnRow;
  FBtnPrev.OnClick := BtnPrevClick;
  StyleBtn(FBtnPrev, UiFont);

  FBtnNext := TsButton.Create(Self);
  FBtnNext.Parent := FBtnRow;
  FBtnNext.OnClick := BtnNextClick;
  StyleBtn(FBtnNext, UiFont);

  FBtnCollect := TsButton.Create(Self);
  FBtnCollect.Parent := FBtnRow;
  FBtnCollect.OnClick := BtnCollectClick;
  StyleBtn(FBtnCollect, UiFont);

  FBtnLoadMore := TsButton.Create(Self);
  FBtnLoadMore.Parent := FBtnRow;
  FBtnLoadMore.OnClick := BtnLoadMoreClick;
  FBtnLoadMore.Enabled := False;
  FBtnLoadMore.Visible := False;
  StyleBtn(FBtnLoadMore, UiFont);

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBtnRow;
  FBtnExport.OnClick := BtnExportClick;
  FBtnExport.Visible := False;
  StyleBtn(FBtnExport, UiFont);

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBtnRow;
  FBtnCopy.OnClick := BtnCopyClick;
  FBtnCopy.Visible := False;
  StyleBtn(FBtnCopy, UiFont);

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBtnRow;
  FBtnClear.OnClick := BtnClearClick;
  StyleBtn(FBtnClear, UiFont);

  FListHost := TsPanel.Create(Self);
  FListHost.Parent := FBody;
  FListHost.Align := alNone;
  FListHost.BevelOuter := bvNone;
  FListHost.Caption := '';
  FListHost.Visible := False;
  ForceColor(FListHost, CSurface);

  FPageBar := TsPanel.Create(Self);
  FPageBar.Parent := FListHost;
  FPageBar.Align := alBottom;
  FPageBar.Height := FfPx(FIND_OCC_BTN_H);
  FPageBar.BevelOuter := bvNone;
  FPageBar.Caption := '';
  ForceColor(FPageBar, CSurfaceHi);

  FBtnPagePrev := TsButton.Create(Self);
  FBtnPagePrev.Parent := FPageBar;
  FBtnPagePrev.Align := alLeft;
  FBtnPagePrev.Width := FfPx(32);
  FBtnPagePrev.OnClick := BtnPagePrevClick;
  StyleChromeBtn(FBtnPagePrev, UiFont);
  FBtnPagePrev.Caption := '<';

  FBtnPageNext := TsButton.Create(Self);
  FBtnPageNext.Parent := FPageBar;
  FBtnPageNext.Align := alRight;
  FBtnPageNext.Width := FfPx(32);
  FBtnPageNext.OnClick := BtnPageNextClick;
  StyleChromeBtn(FBtnPageNext, UiFont);
  FBtnPageNext.Caption := '>';

  FLblPage := TsLabel.Create(Self);
  FLblPage.Parent := FPageBar;
  FLblPage.Align := alClient;
  FLblPage.Transparent := True;
  FLblPage.ParentFont := False;
  FLblPage.Font.Name := UiFont;
  FLblPage.Font.Size := 8;
  FLblPage.Font.Color := CMuted;
  FLblPage.Caption := '';
  FLblPage.Alignment := taCenter;
  FLblPage.Layout := tlCenter;

  FListShell := TsPanel.Create(Self);
  FListShell.Parent := FListHost;
  FListShell.Align := alClient;
  FListShell.BevelOuter := bvNone;
  FListShell.Caption := '';
  FListShell.Padding.Left := 1;
  FListShell.Padding.Top := 1;
  FListShell.Padding.Right := 1;
  FListShell.Padding.Bottom := 1;
  ForceColor(FListShell, CBorder);

  FListInner := TsPanel.Create(Self);
  FListInner.Parent := FListShell;
  FListInner.Align := alClient;
  FListInner.BevelOuter := bvNone;
  FListInner.Caption := '';
  ForceColor(FListInner, CWindow);

  FHitList := TListBox.Create(Self);
  FHitList.Parent := FListInner;
  FHitList.Align := alClient;
  FHitList.BorderStyle := bsNone;
  FHitList.ParentFont := False;
  FHitList.Font.Name := UiFont;
  FHitList.Font.Size := 9;
  FHitList.Font.Color := CTitle;
  FHitList.ParentColor := False;
  FHitList.Color := CWindow;
  FHitList.IntegralHeight := False;
  FHitList.OnDblClick := HitListDblClick;
  FHitList.OnClick := HitListClick;
end;

procedure TFastFileFindOccBar.LayoutChrome;
var
  X, Gap, InnerW, Y, TopH, SearchH, BtnRowH, ListH, NeedH, GoW, EditW, EditTop: Integer;
  MeasureBmp: TBitmap;

  function BtnW(ABtn: TsButton; AMin: Integer): Integer;
  begin
    Result := FfPx(AMin);
    if not Assigned(ABtn) or not Assigned(MeasureBmp) then Exit;
    MeasureBmp.Canvas.Font.Assign(ABtn.Font);
    Result := Max(Result, MeasureBmp.Canvas.TextWidth(ABtn.Caption) + FfPx(FIND_OCC_BTN_PAD_X));
  end;

  procedure PlaceLeft(ABtn: TsButton; AMinW: Integer);
  var
    W: Integer;
  begin
    if not Assigned(ABtn) or not ABtn.Visible then Exit;
    W := BtnW(ABtn, AMinW);
    ABtn.SetBounds(X, FfPx(2), W, FfPx(FIND_OCC_BTN_H));
    Inc(X, W + Gap);
  end;

begin
  if not FBuilt or not Assigned(FBody) or not Assigned(FBtnRow) or not Assigned(FTopRow) then Exit;

  TopH := FfPx(FIND_OCC_TOP_H);
  SearchH := FfPx(FIND_OCC_SEARCH_H);
  BtnRowH := FfPx(FIND_OCC_BTN_H + 6);
  Gap := FfPx(8);

  InnerW := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
  if InnerW < FfPx(200) then
    InnerW := FfPx(200);

  Y := FBody.Padding.Top;
  FTopRow.SetBounds(FBody.Padding.Left, Y, InnerW, TopH);
  Inc(Y, TopH + FfPx(6));

  if Assigned(FSearchRow) then
  begin
    FSearchRow.SetBounds(FBody.Padding.Left, Y, InnerW, SearchH);
    Inc(Y, SearchH + FfPx(6));
  end;

  FBtnRow.SetBounds(FBody.Padding.Left, Y, InnerW, BtnRowH);
  Inc(Y, BtnRowH + FfPx(4));

  if FExpanded and Assigned(FListHost) then
  begin
    ListH := FBody.ClientHeight - Y - FBody.Padding.Bottom;
    if ListH < FfPx(FIND_OCC_LIST_MIN_H) then
      ListH := FfPx(FIND_OCC_LIST_MIN_H);
    FListHost.Visible := True;
    FListHost.SetBounds(FBody.Padding.Left, Y, InnerW, ListH);
  end
  else if Assigned(FListHost) then
  begin
    FListHost.Visible := False;
    FListHost.SetBounds(FBody.Padding.Left, Y, InnerW, 0);
  end;

  if FExpanded then
    NeedH := PreferredExpandedHeight
  else
    NeedH := FfPx(FIND_OCC_BAR_HEIGHT);
  if (not FFloating) and (Height <> NeedH) then
    Height := NeedH;
  Constraints.MinHeight := FfPx(FIND_OCC_BAR_HEIGHT);
  if FExpanded and (not FFloating) then
    Constraints.MaxHeight := NeedH
  else
    Constraints.MaxHeight := 0;

  if Assigned(FBtnHide) then
    FBtnHide.Width := FfPx(28);
  if Assigned(FBtnFloat) then
    FBtnFloat.Width := FfPx(28);

  MeasureBmp := TBitmap.Create;
  try
    MeasureBmp.SetSize(8, 8);

    if Assigned(FSearchRow) and Assigned(FEditShell) and Assigned(FBtnGo) then
    begin
      GoW := BtnW(FBtnGo, 72);
      EditW := InnerW - GoW - Gap;
      if EditW < FfPx(120) then
        EditW := FfPx(120);
      EditTop := Max(0, (SearchH - FfPx(28)) div 2);
      FEditShell.SetBounds(0, EditTop, EditW, FfPx(28));
      FBtnGo.SetBounds(EditW + Gap, Max(0, (SearchH - FfPx(FIND_OCC_BTN_H)) div 2),
        GoW, FfPx(FIND_OCC_BTN_H));
    end;

    X := 0;
    PlaceLeft(FBtnPrev, 118);
    PlaceLeft(FBtnNext, 110);
    PlaceLeft(FBtnCollect, 140);
    PlaceLeft(FBtnLoadMore, 118);
    PlaceLeft(FBtnExport, 90);
    PlaceLeft(FBtnCopy, 78);
    PlaceLeft(FBtnClear, 78);
  finally
    MeasureBmp.Free;
  end;
end;

procedure TFastFileFindOccBar.BodyResize(Sender: TObject);
begin
  LayoutChrome;
end;

procedure TFastFileFindOccBar.Resize;
begin
  inherited;
  LayoutChrome;
end;

procedure TFastFileFindOccBar.ApplySoftChrome;
var
  UiFont: string;
begin
  UiFont := PreferUiFont;
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CSurface;
  ForceColor(Self, CSurface);
  if Assigned(FAccent) then
  begin
    ForceColor(FAccent, CAccent);
    FAccent.Width := CAccentW;
  end;
  if Assigned(FBody) then ForceColor(FBody, CSurface);
  if Assigned(FTopRow) then ForceColor(FTopRow, CSurfaceHi);
  if Assigned(FSearchRow) then ForceColor(FSearchRow, CSurface);
  if Assigned(FBtnRow) then ForceColor(FBtnRow, CSurface);
  if Assigned(FListHost) then ForceColor(FListHost, CSurface);
  if Assigned(FPageBar) then ForceColor(FPageBar, CSurfaceHi);
  if Assigned(FEditShell) then ForceColor(FEditShell, CBorder);
  if Assigned(FEditFrame) then ForceColor(FEditFrame, CWindow);
  if Assigned(FListShell) then ForceColor(FListShell, CBorder);
  if Assigned(FListInner) then ForceColor(FListInner, CWindow);
  if Assigned(FLblTitle) then
  begin
    FLblTitle.Font.Name := UiFont;
    FLblTitle.Font.Color := CTitle;
  end;
  if Assigned(FLblStatus) then
  begin
    FLblStatus.Font.Name := UiFont;
    FLblStatus.Font.Color := CMuted;
  end;
  if Assigned(FLblPage) then
  begin
    FLblPage.Font.Name := UiFont;
    FLblPage.Font.Color := CMuted;
  end;
  if Assigned(FEdtFind) then
  begin
    FEdtFind.ParentColor := False;
    FEdtFind.Color := CWindow;
    FEdtFind.ParentFont := False;
    FEdtFind.Font.Name := UiFont;
    FEdtFind.Font.Size := 10;
    FEdtFind.Font.Color := CTitle;
  end;
  if Assigned(FHitList) then
  begin
    FHitList.ParentColor := False;
    FHitList.Color := CWindow;
    FHitList.ParentFont := False;
    FHitList.Font.Name := UiFont;
    FHitList.Font.Size := 9;
    FHitList.Font.Color := CTitle;
  end;
end;

procedure TFastFileFindOccBar.ApplyCaptions;
begin
  if not FBuilt then Exit;
  FLblTitle.Caption := TrText('FindOcc.Title');
  FBtnPrev.Caption := TrText('FindOcc.Prev');
  FBtnNext.Caption := TrText('FindOcc.Next');
  FBtnCollect.Caption := TrText('FindOcc.ViewAllInList');
  FBtnLoadMore.Caption := TrText('FindOcc.LoadMore');
  FBtnExport.Caption := TrText('FindOcc.Export');
  FBtnCopy.Caption := TrText('FindOcc.Copy');
  FBtnClear.Caption := TrText('FindOcc.Clear');
  if Assigned(FBtnGo) then
    FBtnGo.Caption := TrText('FindOcc.Go');
  FBtnHide.Caption := #$00D7;
  FBtnPagePrev.Caption := '<';
  FBtnPageNext.Caption := '>';
  FBtnPrev.Hint := TrText('FindOcc.PrevHint');
  FBtnNext.Hint := TrText('FindOcc.NextHint');
  FBtnCollect.Hint := TrText('FindOcc.ViewAllInListHint');
  FBtnLoadMore.Hint := TrText('FindOcc.LoadMoreHint');
  FBtnExport.Hint := TrText('FindOcc.ExportHint');
  FBtnCopy.Hint := TrText('FindOcc.CopyHint');
  FBtnClear.Hint := TrText('FindOcc.ClearHint');
  if Assigned(FBtnGo) then
    FBtnGo.Hint := TrText('FindOcc.GoHint');
  if Assigned(FEdtFind) then
  begin
    FEdtFind.TextHint := TrText('FindOcc.SearchHint');
    FEdtFind.Hint := TrText('FindOcc.SearchHint');
  end;
  FBtnHide.Hint := TrText('Close');
  FBtnPagePrev.Hint := TrText('FindOcc.ListPagePrevHint');
  FBtnPageNext.Hint := TrText('FindOcc.ListPageNextHint');
  SyncFloatAction;
  LayoutChrome;
end;

procedure TFastFileFindOccBar.SetStatus(const AStatusText: string; ABusy, AHasHits, APartial: Boolean);
begin
  EnsureBuilt;
  if Assigned(FLblStatus) then
  begin
    FLblStatus.Caption := '  ' + AStatusText;
    if ABusy then
      FLblStatus.Font.Color := CStatusBusy
    else if AHasHits then
      FLblStatus.Font.Color := CStatusOk
    else
      FLblStatus.Font.Color := CStatusIdle;
  end;
  if Assigned(FBtnLoadMore) then
  begin
    FBtnLoadMore.Visible := APartial or AHasHits;
    FBtnLoadMore.Enabled := APartial and (not ABusy);
  end;
  if Assigned(FBtnExport) then
  begin
    FBtnExport.Visible := AHasHits;
    FBtnExport.Enabled := AHasHits and (not ABusy);
  end;
  if Assigned(FBtnCopy) then
  begin
    FBtnCopy.Visible := AHasHits;
    FBtnCopy.Enabled := AHasHits and (not ABusy);
  end;
  if Assigned(FBtnCollect) then
    FBtnCollect.Enabled := not ABusy;
  LayoutChrome;
end;

procedure TFastFileFindOccBar.SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnPrev) then FBtnPrev.Enabled := APrevEnabled;
  if Assigned(FBtnNext) then FBtnNext.Enabled := ANextEnabled;
end;

procedure TFastFileFindOccBar.SetCollectEnabled(AEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnCollect) then
    FBtnCollect.Enabled := AEnabled;
end;

procedure TFastFileFindOccBar.SetExpanded(AExpanded: Boolean);
begin
  EnsureBuilt;
  FExpanded := AExpanded;
  if AExpanded then
  begin
    Constraints.MaxHeight := 0;
    Height := PreferredExpandedHeight;
    if not FFloating then
      Constraints.MaxHeight := Height;
  end
  else
  begin
    Constraints.MaxHeight := 0;
    Height := FfPx(FIND_OCC_BAR_HEIGHT);
  end;
  LayoutChrome;
end;

function TFastFileFindOccBar.PreferredExpandedHeight: Integer;
var
  Cap, FloorH: Integer;
begin
  Result := FfPx(FIND_OCC_BAR_EXPANDED);
  FloorH := FfPx(FIND_OCC_BAR_HEIGHT) + FfPx(FIND_OCC_LIST_MIN_H) + FfPx(8);
  if Result < FloorH then
    Result := FloorH;
  { Docked: leave most of the center pane for the file ListView. }
  if (not FFloating) and Assigned(Parent) and (Parent.ClientHeight > 0) then
  begin
    Cap := (Parent.ClientHeight * 36) div 100;
    if Cap < FloorH then
      Cap := FloorH;
    if Cap > Parent.ClientHeight - FfPx(120) then
      Cap := Max(FloorH, Parent.ClientHeight - FfPx(120));
    if Result > Cap then
      Result := Cap;
  end;
end;

procedure TFastFileFindOccBar.ClearHitList;
begin
  EnsureBuilt;
  FHitPageBase := 0;
  if Assigned(FHitList) then
    FHitList.Items.Clear;
  if Assigned(FLblPage) then
    FLblPage.Caption := '';
  SetExpanded(False);
end;

function TFastFileFindOccBar.GetSearchText: string;
begin
  EnsureBuilt;
  if Assigned(FEdtFind) then
    Result := FEdtFind.Text
  else
    Result := '';
end;

procedure TFastFileFindOccBar.SetSearchText(const AText: string);
begin
  EnsureBuilt;
  if not Assigned(FEdtFind) then Exit;
  if FEdtFind.Text = AText then Exit;
  FEdtFind.Text := AText;
end;

procedure TFastFileFindOccBar.FocusSearchEdit;
begin
  EnsureBuilt;
  if not Assigned(FEdtFind) then Exit;
  if not Visible then Exit;
  if not HandleAllocated then Exit;
  if FEdtFind.CanFocus then
  begin
    FEdtFind.SetFocus;
    FEdtFind.SelectAll;
  end;
end;

function TFastFileFindOccBar.SearchEditFocused: Boolean;
begin
  Result := Assigned(FEdtFind) and FEdtFind.Focused;
end;

procedure TFastFileFindOccBar.SetHitListPage(ALines: TStrings; APageBase: Int64;
  APageIndex, APageCount, ATotalHits: Integer; ACanPagePrev, ACanPageNext: Boolean);
begin
  EnsureBuilt;
  FHitPageBase := APageBase;
  if Assigned(FHitList) then
  begin
    FHitList.Items.BeginUpdate;
    try
      FHitList.Items.Clear;
      if Assigned(ALines) then
        FHitList.Items.Assign(ALines);
    finally
      FHitList.Items.EndUpdate;
    end;
  end;
  if Assigned(FLblPage) then
    FLblPage.Caption := Format(TrText('FindOcc.ListPageStatus'),
      [APageIndex, APageCount, ATotalHits]);
  if Assigned(FBtnPagePrev) then
    FBtnPagePrev.Enabled := ACanPagePrev;
  if Assigned(FBtnPageNext) then
    FBtnPageNext.Enabled := ACanPageNext;
  SetExpanded(True);
end;

procedure TFastFileFindOccBar.FireHitClick;
var
  Idx: Integer;
begin
  if not Assigned(FOnHitClick) or not Assigned(FHitList) then Exit;
  Idx := FHitList.ItemIndex;
  if Idx < 0 then Exit;
  FOnHitClick(Self, FHitPageBase + Idx);
end;

procedure TFastFileFindOccBar.HitListClick(Sender: TObject);
begin
  FireHitClick;
end;

procedure TFastFileFindOccBar.HitListDblClick(Sender: TObject);
begin
  FireHitClick;
end;

procedure TFastFileFindOccBar.BtnPrevClick(Sender: TObject);
begin
  if Assigned(FOnPrev) then FOnPrev(Self);
end;

procedure TFastFileFindOccBar.BtnNextClick(Sender: TObject);
begin
  if Assigned(FOnNext) then FOnNext(Self);
end;

procedure TFastFileFindOccBar.BtnGoClick(Sender: TObject);
begin
  if Assigned(FOnSearch) then FOnSearch(Self);
end;

procedure TFastFileFindOccBar.EdtFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if Assigned(FOnSearch) then FOnSearch(Self);
  end;
end;

procedure TFastFileFindOccBar.BtnCollectClick(Sender: TObject);
begin
  if Assigned(FOnCollect) then FOnCollect(Self);
end;

procedure TFastFileFindOccBar.BtnLoadMoreClick(Sender: TObject);
begin
  if Assigned(FOnLoadMore) then FOnLoadMore(Self);
end;

procedure TFastFileFindOccBar.BtnExportClick(Sender: TObject);
begin
  if Assigned(FOnExport) then FOnExport(Self);
end;

procedure TFastFileFindOccBar.BtnCopyClick(Sender: TObject);
begin
  if Assigned(FOnCopy) then FOnCopy(Self);
end;

procedure TFastFileFindOccBar.BtnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then FOnClear(Self);
end;

procedure TFastFileFindOccBar.BtnHideClick(Sender: TObject);
begin
  if Assigned(FOnHide) then FOnHide(Self);
end;

procedure TFastFileFindOccBar.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloat) then FOnFloat(Self);
end;

procedure TFastFileFindOccBar.SyncFloatAction;
begin
  if not Assigned(FBtnFloat) then Exit;
  if FFloating then
  begin
    FBtnFloat.Caption := #$2199;
    FBtnFloat.Hint := TrText('Panel.DockHint');
  end
  else
  begin
    FBtnFloat.Caption := #$2197;
    FBtnFloat.Hint := TrText('Panel.RestoreFloatHint');
  end;
  FBtnFloat.ShowHint := True;
end;

procedure TFastFileFindOccBar.SetFloatingLook(AFloating: Boolean);
begin
  FFloating := AFloating;
  SyncFloatAction;
end;

procedure TFastFileFindOccBar.RelayoutAfterDock;
begin
  LayoutChrome;
end;

procedure TFastFileFindOccBar.TitleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
end;

procedure TFastFileFindOccBar.TitleMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not FHeaderDown then Exit;
  if (Abs(X - FHeaderPt.X) < 4) and (Abs(Y - FHeaderPt.Y) < 4) then Exit;
  FHeaderDown := False;
  if (not FFloating) and Assigned(FOnTearOff) then
    FOnTearOff(Self);
end;

procedure TFastFileFindOccBar.TitleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FHeaderDown := False;
end;

procedure TFastFileFindOccBar.BtnPagePrevClick(Sender: TObject);
begin
  if Assigned(FOnListPagePrev) then FOnListPagePrev(Self);
end;

procedure TFastFileFindOccBar.BtnPageNextClick(Sender: TObject);
begin
  if Assigned(FOnListPageNext) then FOnListPageNext(Self);
end;

{ TFastFileFindOccPeek }

constructor TFastFileFindOccPeek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  Height := FIND_OCC_PEEK_HEIGHT;
  BevelOuter := bvNone;
  Caption := '';
  Cursor := crHandPoint;
  ShowHint := True;
  OnClick := PeekClick;
  ApplySoftChrome;
end;

procedure TFastFileFindOccPeek.ApplySoftChrome;
begin
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CAccent;
  Hint := TrText('FindOcc.PeekHint');
end;

procedure TFastFileFindOccPeek.PeekClick(Sender: TObject);
begin
  if Assigned(FOnRestore) then FOnRestore(Self);
end;

end.
