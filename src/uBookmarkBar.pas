unit uBookmarkBar;
{ Docked Bookmarks chrome (Ctrl+B): list of bookmarks, jump on click,
  Prev/Next, remove one, clear all, Export/Copy, hide + float/peek. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Math, Buttons, sPanel, sLabel, sButton, uFastFileScale;

type
  TBookmarkJumpEvent = procedure(Sender: TObject; AIndex: Integer) of object;

  TFastFileBookmarkBar = class(TsPanel)
  private
    FBuilt: Boolean;
    FAccent: TsPanel;
    FBody: TsPanel;
    FTopRow: TsPanel;
    FBtnRow: TsPanel;
    FListHost: TsPanel;
    FListShell: TsPanel;
    FListInner: TsPanel;
    FPageBar: TsPanel;
    FLblTitle: TsLabel;
    FLblStatus: TsLabel;
    FLblPage: TsLabel;
    FBtnPrev: TsButton;
    FBtnNext: TsButton;
    FBtnRemove: TsButton;
    FBtnClear: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnHide: TsButton;
    FBtnFloat: TsButton;
    FBtnPagePrev: TsButton;
    FBtnPageNext: TsButton;
    FList: TListBox;
    FPageBase: Integer;
    FOnPrev: TNotifyEvent;
    FOnNext: TNotifyEvent;
    FOnRemove: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FOnExport: TNotifyEvent;
    FOnCopy: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnFloat: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnJump: TBookmarkJumpEvent;
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
    procedure BtnRemoveClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure BtnPagePrevClick(Sender: TObject);
    procedure BtnPageNextClick(Sender: TObject);
    procedure ListClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure FireJump;
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
    procedure SetStatus(const AStatusText: string; AHasItems: Boolean);
    procedure SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
    procedure ClearList;
    function PreferredHeight: Integer;
    function SelectedIndexAbsolute: Integer;
    procedure SetListPage(ALines: TStrings; APageBase, APageIndex, APageCount,
      ATotal: Integer; ACanPagePrev, ACanPageNext: Boolean);
    property OnPrev: TNotifyEvent read FOnPrev write FOnPrev;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
    property OnRemove: TNotifyEvent read FOnRemove write FOnRemove;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnJump: TBookmarkJumpEvent read FOnJump write FOnJump;
    property OnListPagePrev: TNotifyEvent read FOnListPagePrev write FOnListPagePrev;
    property OnListPageNext: TNotifyEvent read FOnListPageNext write FOnListPageNext;
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
  end;

  TFastFileBookmarkPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftChrome;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  BOOKMARK_BAR_HEIGHT = 200;
  BOOKMARK_PEEK_HEIGHT = 5;
  BOOKMARK_BTN_H = 30;
  BOOKMARK_TOP_H = 28;
  BOOKMARK_LIST_PAGE_SIZE = 40;
  BOOKMARK_LIST_MIN_H = 72;

implementation

uses
  uI18n;

const
  CAccent = TColor($00BFAF9C);
  CSurface = TColor($00F6F3EE);
  CSurfaceHi = TColor($00EDE8E1);
  CBorder = TColor($00CFC6BB);
  CWindow = TColor($00FFFCF8);
  CTitle = TColor($001C1610);
  CMuted = TColor($006B6158);
  CStatusOk = TColor($002E7D32);
  CStatusIdle = TColor($006B6158);
  CAccentW = 3;

function PreferUiFont: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

constructor TFastFileBookmarkBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuilt := False;
  FFloating := False;
  FHeaderDown := False;
  FPageBase := 0;
  Align := alTop;
  Height := FfPx(BOOKMARK_BAR_HEIGHT);
  Constraints.MinHeight := FfPx(140);
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

procedure TFastFileBookmarkBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(AParent) then
    EnsureBuilt;
end;

procedure TFastFileBookmarkBar.EnsureBuilt;
begin
  if FBuilt then Exit;
  BuildChrome;
  FBuilt := True;
  ApplySoftChrome;
  ApplyCaptions;
  LayoutChrome;
end;

procedure TFastFileBookmarkBar.ForceColor(APnl: TsPanel; AColor: TColor);
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

procedure TFastFileBookmarkBar.StyleBtn(ABtn: TsButton; const AUiFont: string);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.Height := FfPx(BOOKMARK_BTN_H);
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

procedure TFastFileBookmarkBar.StyleChromeBtn(ABtn: TsButton; const AUiFont: string);
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

procedure TFastFileBookmarkBar.BuildChrome;
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
  FTopRow.Height := FfPx(BOOKMARK_TOP_H);
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
  FLblTitle.Caption := 'Bookmarks';
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

  FBtnRow := TsPanel.Create(Self);
  FBtnRow.Parent := FBody;
  FBtnRow.Align := alNone;
  FBtnRow.Height := FfPx(BOOKMARK_BTN_H + 6);
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

  FBtnRemove := TsButton.Create(Self);
  FBtnRemove.Parent := FBtnRow;
  FBtnRemove.OnClick := BtnRemoveClick;
  StyleBtn(FBtnRemove, UiFont);

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBtnRow;
  FBtnClear.OnClick := BtnClearClick;
  StyleBtn(FBtnClear, UiFont);

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBtnRow;
  FBtnExport.OnClick := BtnExportClick;
  StyleBtn(FBtnExport, UiFont);

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBtnRow;
  FBtnCopy.OnClick := BtnCopyClick;
  StyleBtn(FBtnCopy, UiFont);

  FListHost := TsPanel.Create(Self);
  FListHost.Parent := FBody;
  FListHost.Align := alNone;
  FListHost.BevelOuter := bvNone;
  FListHost.Caption := '';
  ForceColor(FListHost, CSurface);

  FPageBar := TsPanel.Create(Self);
  FPageBar.Parent := FListHost;
  FPageBar.Align := alBottom;
  FPageBar.Height := FfPx(BOOKMARK_BTN_H);
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

  FList := TListBox.Create(Self);
  FList.Parent := FListInner;
  FList.Align := alClient;
  FList.BorderStyle := bsNone;
  FList.ParentFont := False;
  FList.Font.Name := UiFont;
  FList.Font.Size := 9;
  FList.Font.Color := CTitle;
  FList.Color := CWindow;
  FList.OnClick := ListClick;
  FList.OnDblClick := ListDblClick;
end;

procedure TFastFileBookmarkBar.LayoutChrome;
var
  Y, X, Gap, Bw, BodyW, ListH: Integer;
  Btns: array[0..5] of TsButton;
  Caps: array[0..5] of string;
  I: Integer;
  MeasureBmp: TBitmap;
begin
  if not FBuilt or not Assigned(FBody) then Exit;
  BodyW := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
  if BodyW < 80 then BodyW := 80;
  Y := 0;
  FTopRow.SetBounds(0, Y, BodyW, FfPx(BOOKMARK_TOP_H));
  Inc(Y, FTopRow.Height + FfPx(6));
  FBtnRow.SetBounds(0, Y, BodyW, FfPx(BOOKMARK_BTN_H + 6));
  Inc(Y, FBtnRow.Height + FfPx(6));

  Btns[0] := FBtnPrev; Caps[0] := FBtnPrev.Caption;
  Btns[1] := FBtnNext; Caps[1] := FBtnNext.Caption;
  Btns[2] := FBtnRemove; Caps[2] := FBtnRemove.Caption;
  Btns[3] := FBtnClear; Caps[3] := FBtnClear.Caption;
  Btns[4] := FBtnExport; Caps[4] := FBtnExport.Caption;
  Btns[5] := FBtnCopy; Caps[5] := FBtnCopy.Caption;
  Gap := FfPx(6);
  X := 0;
  MeasureBmp := TBitmap.Create;
  try
    MeasureBmp.SetSize(1, 1);
    for I := 0 to High(Btns) do
    begin
      if not Assigned(Btns[I]) or not Btns[I].Visible then Continue;
      MeasureBmp.Canvas.Font.Assign(Btns[I].Font);
      Bw := MeasureBmp.Canvas.TextWidth(Caps[I]) + FfPx(22);
      if Bw < FfPx(64) then Bw := FfPx(64);
      if X + Bw > BodyW then
        Bw := Max(FfPx(52), (BodyW - X - Gap) div Max(1, High(Btns) - I + 1));
      Btns[I].SetBounds(X, 2, Bw, FfPx(BOOKMARK_BTN_H));
      Inc(X, Bw + Gap);
    end;
  finally
    MeasureBmp.Free;
  end;

  ListH := FBody.ClientHeight - Y - FBody.Padding.Bottom;
  if ListH < FfPx(BOOKMARK_LIST_MIN_H) then
    ListH := FfPx(BOOKMARK_LIST_MIN_H);
  FListHost.SetBounds(0, Y, BodyW, ListH);
  FListHost.Visible := True;
end;

procedure TFastFileBookmarkBar.BodyResize(Sender: TObject);
begin
  LayoutChrome;
end;

procedure TFastFileBookmarkBar.Resize;
begin
  inherited Resize;
  if FBuilt then
    LayoutChrome;
end;

procedure TFastFileBookmarkBar.RelayoutAfterDock;
begin
  EnsureBuilt;
  LayoutChrome;
end;

procedure TFastFileBookmarkBar.ApplySoftChrome;
begin
  EnsureBuilt;
  ForceColor(Self, CSurface);
  ForceColor(FAccent, CAccent);
  ForceColor(FBody, CSurface);
  ForceColor(FTopRow, CSurfaceHi);
  ForceColor(FBtnRow, CSurface);
  ForceColor(FListHost, CSurface);
  ForceColor(FPageBar, CSurfaceHi);
  ForceColor(FListShell, CBorder);
  ForceColor(FListInner, CWindow);
  if Assigned(FList) then
    FList.Color := CWindow;
end;

procedure TFastFileBookmarkBar.SyncFloatAction;
begin
  if not Assigned(FBtnFloat) then Exit;
  if FFloating then
  begin
    FBtnFloat.Caption := #$25A3;
    FBtnFloat.Hint := TrText('BookmarkBar.DockHint');
  end
  else
  begin
    FBtnFloat.Caption := #$2398;
    FBtnFloat.Hint := TrText('BookmarkBar.FloatHint');
  end;
end;

procedure TFastFileBookmarkBar.SetFloatingLook(AFloating: Boolean);
begin
  FFloating := AFloating;
  SyncFloatAction;
end;

procedure TFastFileBookmarkBar.ApplyCaptions;
begin
  EnsureBuilt;
  FLblTitle.Caption := TrText('BookmarkBar.Title');
  FBtnPrev.Caption := TrText('BookmarkBar.Prev');
  FBtnNext.Caption := TrText('BookmarkBar.Next');
  FBtnRemove.Caption := TrText('BookmarkBar.Remove');
  FBtnClear.Caption := TrText('BookmarkBar.ClearAll');
  FBtnExport.Caption := TrText('FilterBar.Export');
  FBtnCopy.Caption := TrText('Assistant.CopyReply');
  FBtnHide.Caption := #$00D7;
  FBtnPrev.Hint := TrText('Pr&evious bookmark');
  FBtnNext.Hint := TrText('&Next bookmark');
  FBtnRemove.Hint := TrText('BookmarkBar.RemoveHint');
  FBtnClear.Hint := TrText('Clear a&ll bookmarks');
  FBtnExport.Hint := TrText('BookmarkBar.ExportHint');
  FBtnCopy.Hint := TrText('BookmarkBar.CopyHint');
  FBtnHide.Hint := TrText('Close');
  FBtnPagePrev.Hint := TrText('BookmarkBar.PagePrevHint');
  FBtnPageNext.Hint := TrText('BookmarkBar.PageNextHint');
  SyncFloatAction;
  LayoutChrome;
end;

procedure TFastFileBookmarkBar.SetStatus(const AStatusText: string; AHasItems: Boolean);
begin
  EnsureBuilt;
  if Assigned(FLblStatus) then
  begin
    FLblStatus.Caption := '  ' + AStatusText;
    if AHasItems then
      FLblStatus.Font.Color := CStatusOk
    else
      FLblStatus.Font.Color := CStatusIdle;
  end;
  if Assigned(FBtnRemove) then FBtnRemove.Enabled := AHasItems;
  if Assigned(FBtnClear) then FBtnClear.Enabled := AHasItems;
  if Assigned(FBtnExport) then FBtnExport.Enabled := AHasItems;
  if Assigned(FBtnCopy) then FBtnCopy.Enabled := AHasItems;
  SetNavEnabled(AHasItems, AHasItems);
  LayoutChrome;
end;

procedure TFastFileBookmarkBar.SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnPrev) then FBtnPrev.Enabled := APrevEnabled;
  if Assigned(FBtnNext) then FBtnNext.Enabled := ANextEnabled;
end;

procedure TFastFileBookmarkBar.ClearList;
begin
  EnsureBuilt;
  if Assigned(FList) then
    FList.Items.Clear;
  FPageBase := 0;
  if Assigned(FLblPage) then
    FLblPage.Caption := '';
end;

function TFastFileBookmarkBar.PreferredHeight: Integer;
begin
  Result := FfPx(BOOKMARK_BAR_HEIGHT);
end;

function TFastFileBookmarkBar.SelectedIndexAbsolute: Integer;
begin
  Result := -1;
  if not Assigned(FList) or (FList.ItemIndex < 0) then Exit;
  Result := FPageBase + FList.ItemIndex;
end;

procedure TFastFileBookmarkBar.SetListPage(ALines: TStrings; APageBase, APageIndex,
  APageCount, ATotal: Integer; ACanPagePrev, ACanPageNext: Boolean);
begin
  EnsureBuilt;
  FPageBase := APageBase;
  if Assigned(FList) then
  begin
    FList.Items.BeginUpdate;
    try
      FList.Items.Clear;
      if Assigned(ALines) then
        FList.Items.Assign(ALines);
    finally
      FList.Items.EndUpdate;
    end;
  end;
  if Assigned(FLblPage) then
  begin
    if ATotal <= 0 then
      FLblPage.Caption := ''
    else
      FLblPage.Caption := Format(TrText('BookmarkBar.PageFmt'),
        [APageIndex, Max(1, APageCount), ATotal]);
  end;
  if Assigned(FBtnPagePrev) then FBtnPagePrev.Enabled := ACanPagePrev;
  if Assigned(FBtnPageNext) then FBtnPageNext.Enabled := ACanPageNext;
  if Assigned(FPageBar) then
    FPageBar.Visible := APageCount > 1;
end;

procedure TFastFileBookmarkBar.FireJump;
var
  AbsIdx: Integer;
begin
  AbsIdx := SelectedIndexAbsolute;
  if (AbsIdx < 0) or not Assigned(FOnJump) then Exit;
  FOnJump(Self, AbsIdx);
end;

procedure TFastFileBookmarkBar.ListClick(Sender: TObject);
begin
  FireJump;
end;

procedure TFastFileBookmarkBar.ListDblClick(Sender: TObject);
begin
  FireJump;
end;

procedure TFastFileBookmarkBar.BtnPrevClick(Sender: TObject);
begin
  if Assigned(FOnPrev) then FOnPrev(Self);
end;

procedure TFastFileBookmarkBar.BtnNextClick(Sender: TObject);
begin
  if Assigned(FOnNext) then FOnNext(Self);
end;

procedure TFastFileBookmarkBar.BtnRemoveClick(Sender: TObject);
begin
  if Assigned(FOnRemove) then FOnRemove(Self);
end;

procedure TFastFileBookmarkBar.BtnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then FOnClear(Self);
end;

procedure TFastFileBookmarkBar.BtnExportClick(Sender: TObject);
begin
  if Assigned(FOnExport) then FOnExport(Self);
end;

procedure TFastFileBookmarkBar.BtnCopyClick(Sender: TObject);
begin
  if Assigned(FOnCopy) then FOnCopy(Self);
end;

procedure TFastFileBookmarkBar.BtnHideClick(Sender: TObject);
begin
  if Assigned(FOnHide) then FOnHide(Self);
end;

procedure TFastFileBookmarkBar.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloat) then FOnFloat(Self);
end;

procedure TFastFileBookmarkBar.BtnPagePrevClick(Sender: TObject);
begin
  if Assigned(FOnListPagePrev) then FOnListPagePrev(Self);
end;

procedure TFastFileBookmarkBar.BtnPageNextClick(Sender: TObject);
begin
  if Assigned(FOnListPageNext) then FOnListPageNext(Self);
end;

procedure TFastFileBookmarkBar.TitleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
end;

procedure TFastFileBookmarkBar.TitleMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not FHeaderDown then Exit;
  if (Abs(X - FHeaderPt.X) < 4) and (Abs(Y - FHeaderPt.Y) < 4) then Exit;
  FHeaderDown := False;
  if Assigned(FOnTearOff) then
    FOnTearOff(Self);
end;

procedure TFastFileBookmarkBar.TitleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FHeaderDown := False;
end;

{ TFastFileBookmarkPeek }

constructor TFastFileBookmarkPeek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  Height := FfPx(BOOKMARK_PEEK_HEIGHT);
  BevelOuter := bvNone;
  Caption := '';
  Cursor := crHandPoint;
  ParentBackground := False;
  ParentColor := False;
  Color := CAccent;
  OnClick := PeekClick;
  ShowHint := True;
  Hint := TrText('BookmarkBar.PeekHint');
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
end;

procedure TFastFileBookmarkPeek.ApplySoftChrome;
begin
  Color := CAccent;
  Hint := TrText('BookmarkBar.PeekHint');
end;

procedure TFastFileBookmarkPeek.PeekClick(Sender: TObject);
begin
  if Assigned(FOnRestore) then
    FOnRestore(Self);
end;

end.
