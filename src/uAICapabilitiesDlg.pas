unit uAICapabilitiesDlg;

{
  "What can I do?" list for the Assistant panel, the AI agent tab and AI diagnosis:
  every capability with one example. "Use example" returns the example so the caller
  puts it in its prompt box; "Ask the AI" returns a question plus the item (or whole
  list) so the caller asks its AI. Texts: AICaps.* in uI18n (each item is "description|example").
}

interface

type
  TAICapsKind = (ackAssistant, ackAgent, ackHub);
  TAICapsChoice = (accNone, accExample, accAsk);

{ accExample: AText is the example. accAsk: AText is the selected item (or the whole list)
  and AQuestion the user's question about it. accNone: the list was just closed. }
function ShowAICapabilities(AKind: TAICapsKind; out AText, AQuestion: string): TAICapsChoice;
{ Whole list as plain text (or Markdown): title, intro, sections, items with examples. }
function AICapabilitiesText(AKind: TAICapsKind; AMarkdown: Boolean = False): string;

implementation

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls, ExtCtrls, Dialogs,
  Clipbrd, Math, uI18n, uFastFileScale, uSourceCodeHelpDlg;

const
  SEC_AGENT = 0;
  SEC_VIEW = 1;
  SEC_TOOLS = 2;
  SEC_AI = 3;
  SEC_ASSIST = 4;
  SEC_HUB = 5;
  SECTION_KEYS: array[0..5] of string = (
    'AICaps.Sec.AgentOnly', 'AICaps.Sec.View', 'AICaps.Sec.Tools',
    'AICaps.Sec.AI', 'AICaps.Sec.AssistantOnly', 'AICaps.Sec.HubOnly');

type
  TCapItem = record
    Key: string;
    Section: Integer;
  end;

const
  CAP_ITEMS: array[0..39] of TCapItem = (
    (Key: 'AICaps.Item.Describe'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Macro'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Multi'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Count'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Analyze'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Sql'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.SqlChange'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Edits'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Anon'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Exact'; Section: SEC_AGENT),
    (Key: 'AICaps.Item.Open'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Goto'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Find'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Filter'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.SearchCommands'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.CsvSort'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Session'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.View'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Tail'; Section: SEC_VIEW),
    (Key: 'AICaps.Item.Split'; Section: SEC_TOOLS),
    (Key: 'AICaps.Item.Export'; Section: SEC_TOOLS),
    (Key: 'AICaps.Item.Replace'; Section: SEC_TOOLS),
    (Key: 'AICaps.Item.Undo'; Section: SEC_TOOLS),
    (Key: 'AICaps.Item.Tabs'; Section: SEC_TOOLS),
    (Key: 'AICaps.Item.Doc'; Section: SEC_AI),
    (Key: 'AICaps.Item.Code'; Section: SEC_AI),
    (Key: 'AICaps.Item.Consumer'; Section: SEC_AI),
    (Key: 'AICaps.Item.HowTo'; Section: SEC_AI),
    (Key: 'AICaps.Item.Chain'; Section: SEC_AI),
    (Key: 'AICaps.Item.AgentMode'; Section: SEC_ASSIST),
    (Key: 'AICaps.Item.HubInventory'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubStructure'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubContent'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubSql'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubPrivacy'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubActions'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubMulti'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubReport'; Section: SEC_HUB),
    (Key: 'AICaps.Item.HubToAgent'; Section: SEC_HUB),
    (Key: 'AICaps.Item.SearchCommands'; Section: SEC_HUB));

  AGENT_SECTIONS: array[0..3] of Integer = (SEC_AGENT, SEC_VIEW, SEC_TOOLS, SEC_AI);
  ASSIST_SECTIONS: array[0..3] of Integer = (SEC_VIEW, SEC_TOOLS, SEC_AI, SEC_ASSIST);
  HUB_SECTIONS: array[0..0] of Integer = (SEC_HUB);

  ROW_NONE = -1000;
  CTitle = TColor($00283038);
  CMuted = TColor($00606870);
  CAccent = TColor($00D77800);
  CHeadBg = TColor($00F8F0E8);
  CSelBg = TColor($00FBE6D2);
  CRowPad = 12;

type
  TCapsForm = class(TForm)
  private
    FKind: TAICapsKind;
    FUiFont: string;
    FFilter: TEdit;
    FList: TListBox;
    FBtnUse: TButton;
    FBtnCopy: TButton;
    FBtnExport: TButton;
    FBtnAsk: TButton;
    FBtnCode: TButton;
    FFlashTimer: TTimer;
    FChoice: TAICapsChoice;
    FText: string;
    FQuestion: string;
    { Row codes: >= 0 item index, < 0 section header (-1 - section), ROW_NONE no match. }
    FRows: array of Integer;
    procedure Build;
    procedure Rebuild;
    procedure ListMeasure(Control: TWinControl; Index: Integer; var Height: Integer);
    procedure ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure ListClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure FilterChange(Sender: TObject);
    procedure FilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UseClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure AskClick(Sender: TObject);
    procedure CodeHelpClick(Sender: TObject);
    procedure FlashTimer(Sender: TObject);
    procedure Flash(AButton: TButton; const ACaptionKey: string);
    procedure FormResize(Sender: TObject);
    function RowCode(AIndex: Integer): Integer;
    function SelectedItemText: string;
    function TextHeight(const S: string; AWidth: Integer; AStyle: TFontStyles; ASize: Integer): Integer;
    function MakeButton(AParent: TWinControl; const ACaption, AHint: string; AMinW: Integer): TButton;
    procedure UpdateUseButton;
  public
    constructor CreateFor(AKind: TAICapsKind); reintroduce;
  end;

procedure SplitItem(const AKey: string; out ADesc, AExample: string);
var
  S: string;
  P: Integer;
begin
  S := TrText(AKey);
  P := Pos('|', S);
  if P = 0 then
  begin
    ADesc := S;
    AExample := '';
  end
  else
  begin
    ADesc := Trim(Copy(S, 1, P - 1));
    AExample := Trim(Copy(S, P + 1, MaxInt));
  end;
end;

function SectionOrder(AKind: TAICapsKind): TArray<Integer>;
var
  I: Integer;
begin
  case AKind of
    ackHub:
      begin
        SetLength(Result, Length(HUB_SECTIONS));
        for I := 0 to High(HUB_SECTIONS) do
          Result[I] := HUB_SECTIONS[I];
      end;
    ackAgent:
      begin
        SetLength(Result, Length(AGENT_SECTIONS));
        for I := 0 to High(AGENT_SECTIONS) do
          Result[I] := AGENT_SECTIONS[I];
      end;
  else
    begin
      SetLength(Result, Length(ASSIST_SECTIONS));
      for I := 0 to High(ASSIST_SECTIONS) do
        Result[I] := ASSIST_SECTIONS[I];
    end;
  end;
end;

function KindTitle(AKind: TAICapsKind): string;
begin
  case AKind of
    ackHub: Result := TrText('AICaps.Title.Hub');
    ackAgent: Result := TrText('AICaps.Title.Agent');
  else
    Result := TrText('AICaps.Title.Assistant');
  end;
end;

function KindIntro(AKind: TAICapsKind): string;
begin
  case AKind of
    ackHub: Result := TrText('AICaps.Intro.Hub');
    ackAgent: Result := TrText('AICaps.Intro.Agent');
  else
    Result := TrText('AICaps.Intro.Assistant');
  end;
end;

function ItemText(AIndex: Integer; AMarkdown: Boolean): string;
var
  Desc, Ex: string;
begin
  SplitItem(CAP_ITEMS[AIndex].Key, Desc, Ex);
  if AMarkdown then
  begin
    Result := '- ' + Desc;
    if Ex <> '' then
      Result := Result + sLineBreak + '  *' + TrText('AICaps.ExamplePrefix') + '* `' + Ex + '`';
  end
  else
  begin
    Result := '- ' + Desc;
    if Ex <> '' then
      Result := Result + sLineBreak + '  ' + TrText('AICaps.ExamplePrefix') + ' ' + Ex;
  end;
end;

function AICapabilitiesText(AKind: TAICapsKind; AMarkdown: Boolean): string;
var
  SL: TStringList;
  Sec, I: Integer;
begin
  SL := TStringList.Create;
  try
    if AMarkdown then
      SL.Add('# ' + KindTitle(AKind))
    else
      SL.Add(KindTitle(AKind));
    SL.Add('');
    SL.Add(KindIntro(AKind));
    for Sec in SectionOrder(AKind) do
    begin
      SL.Add('');
      if AMarkdown then
        SL.Add('## ' + TrText(SECTION_KEYS[Sec]))
      else
        SL.Add('[' + TrText(SECTION_KEYS[Sec]) + ']');
      for I := 0 to High(CAP_ITEMS) do
        if CAP_ITEMS[I].Section = Sec then
          SL.Add(ItemText(I, AMarkdown));
    end;
    Result := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

{ TCapsForm }

constructor TCapsForm.CreateFor(AKind: TAICapsKind);
begin
  inherited CreateNew(Application);
  FKind := AKind;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    FUiFont := 'Segoe UI'
  else
    FUiFont := 'Tahoma';
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poMainFormCenter;
  KeyPreview := True;
  Font.Name := FUiFont;
  Font.Size := 9;
  Color := clWindow;
  Caption := KindTitle(AKind);
  ClientWidth := FfPx(780);
  ClientHeight := FfPx(580);
  Constraints.MinWidth := FfPx(700);
  Constraints.MinHeight := FfPx(320);
  FFlashTimer := TTimer.Create(Self);
  FFlashTimer.Enabled := False;
  FFlashTimer.Interval := 1500;
  FFlashTimer.OnTimer := FlashTimer;
  Build;
  OnResize := FormResize;
end;

function TCapsForm.MakeButton(AParent: TWinControl; const ACaption, AHint: string; AMinW: Integer): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Hint := AHint;
  Result.ShowHint := AHint <> '';
  Canvas.Font.Name := FUiFont;
  Canvas.Font.Size := 9;
  Result.Width := Max(FfPx(AMinW), Canvas.TextWidth(ACaption) + FfPx(28));
  Result.Height := FfPx(28);
  Result.Top := FfPx(10);
end;

procedure TCapsForm.Build;
var
  Top, Bottom: TPanel;
  Title, Intro: TLabel;
  BtnClose: TButton;
  X: Integer;
begin
  Top := TPanel.Create(Self);
  Top.Parent := Self;
  Top.Align := alTop;
  Top.BevelOuter := bvNone;
  Top.ParentBackground := False;
  Top.Color := CHeadBg;
  Top.Caption := '';

  Title := TLabel.Create(Self);
  Title.Parent := Top;
  Title.ParentFont := False;
  Title.Font.Name := FUiFont;
  Title.Font.Size := 12;
  Title.Font.Style := [fsBold];
  Title.Font.Color := CTitle;
  Title.Caption := Caption;
  Title.SetBounds(FfPx(16), FfPx(12), FfPx(600), FfPx(24));

  Intro := TLabel.Create(Self);
  Intro.Parent := Top;
  Intro.ParentFont := False;
  Intro.Font.Name := FUiFont;
  Intro.Font.Size := 9;
  Intro.Font.Color := CMuted;
  Intro.WordWrap := True;
  Intro.AutoSize := False;
  Intro.Caption := KindIntro(FKind);
  Intro.SetBounds(FfPx(16), FfPx(40), ClientWidth - FfPx(32), FfPx(36));
  Intro.Anchors := [akLeft, akTop, akRight];

  FFilter := TEdit.Create(Self);
  FFilter.Parent := Top;
  FFilter.TextHint := TrText('AICaps.Filter');
  FFilter.SetBounds(FfPx(16), FfPx(82), ClientWidth - FfPx(32), FfPx(24));
  FFilter.Anchors := [akLeft, akTop, akRight];
  FFilter.OnChange := FilterChange;
  FFilter.OnKeyDown := FilterKeyDown;
  Top.Height := FFilter.Top + FFilter.Height + FfPx(10);

  Bottom := TPanel.Create(Self);
  Bottom.Parent := Self;
  Bottom.Align := alBottom;
  Bottom.BevelOuter := bvNone;
  Bottom.Caption := '';
  Bottom.Height := FfPx(48);

  X := FfPx(16);
  FBtnCopy := MakeButton(Bottom, TrText('Agent.ToolCopy'), TrText('AICaps.CopyHint'), 80);
  FBtnCopy.Left := X;
  FBtnCopy.OnClick := CopyClick;
  Inc(X, FBtnCopy.Width + FfPx(6));
  FBtnExport := MakeButton(Bottom, TrText('AICaps.Export'), TrText('AICaps.ExportHint'), 80);
  FBtnExport.Left := X;
  FBtnExport.OnClick := ExportClick;
  Inc(X, FBtnExport.Width + FfPx(6));
  FBtnAsk := MakeButton(Bottom, TrText('Agent.ToolAsk'), TrText('AICaps.AskHint'), 96);
  FBtnAsk.Left := X;
  FBtnAsk.OnClick := AskClick;
  Inc(X, FBtnAsk.Width + FfPx(6));
  FBtnCode := MakeButton(Bottom, TrText('SrcHelp.CapsButton'), TrText('SrcHelp.ButtonHint'), 96);
  FBtnCode.Left := X;
  FBtnCode.OnClick := CodeHelpClick;

  BtnClose := MakeButton(Bottom, TrText('Close'), '', 88);
  BtnClose.Cancel := True;
  BtnClose.ModalResult := mrCancel;
  BtnClose.Left := Bottom.Width - BtnClose.Width - FfPx(16);
  BtnClose.Anchors := [akTop, akRight];

  FBtnUse := MakeButton(Bottom, TrText('AICaps.UseExample'), TrText('AICaps.UseExampleHint'), 110);
  FBtnUse.Default := True;
  FBtnUse.Left := BtnClose.Left - FBtnUse.Width - FfPx(6);
  FBtnUse.Anchors := [akTop, akRight];
  FBtnUse.OnClick := UseClick;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.BorderStyle := bsNone;
  FList.Style := lbOwnerDrawVariable;
  FList.Font.Name := FUiFont;
  FList.Font.Size := 9;
  FList.OnMeasureItem := ListMeasure;
  FList.OnDrawItem := ListDraw;
  FList.OnClick := ListClick;
  FList.OnDblClick := ListDblClick;
  Rebuild;
  ActiveControl := FFilter;
end;

function TCapsForm.RowCode(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex > High(FRows)) then
    Result := ROW_NONE
  else
    Result := FRows[AIndex];
end;

function TCapsForm.SelectedItemText: string;
var
  Code: Integer;
begin
  Code := RowCode(FList.ItemIndex);
  if Code >= 0 then
    Result := ItemText(Code, False)
  else
    Result := '';
end;

procedure TCapsForm.Rebuild;
var
  Needle, Desc, Ex: string;
  Sec, I, Keep: Integer;
  HeaderAdded: Boolean;
begin
  Keep := RowCode(FList.ItemIndex);
  Needle := AnsiLowerCase(Trim(FFilter.Text));
  SetLength(FRows, 0);
  for Sec in SectionOrder(FKind) do
  begin
    HeaderAdded := False;
    for I := 0 to High(CAP_ITEMS) do
    begin
      if CAP_ITEMS[I].Section <> Sec then Continue;
      if Needle <> '' then
      begin
        SplitItem(CAP_ITEMS[I].Key, Desc, Ex);
        if (Pos(Needle, AnsiLowerCase(Desc)) = 0) and (Pos(Needle, AnsiLowerCase(Ex)) = 0) then
          Continue;
      end;
      if not HeaderAdded then
      begin
        SetLength(FRows, Length(FRows) + 1);
        FRows[High(FRows)] := -1 - Sec;
        HeaderAdded := True;
      end;
      SetLength(FRows, Length(FRows) + 1);
      FRows[High(FRows)] := I;
    end;
  end;
  if Length(FRows) = 0 then
  begin
    SetLength(FRows, 1);
    FRows[0] := ROW_NONE;
  end;
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to High(FRows) do
      FList.Items.Add('');
  finally
    FList.Items.EndUpdate;
  end;
  for I := 0 to High(FRows) do
    if (FRows[I] = Keep) and (Keep >= 0) then
      FList.ItemIndex := I;
  UpdateUseButton;
end;

function TCapsForm.TextHeight(const S: string; AWidth: Integer; AStyle: TFontStyles; ASize: Integer): Integer;
var
  R: TRect;
begin
  FList.Canvas.Font.Name := FUiFont;
  FList.Canvas.Font.Size := ASize;
  FList.Canvas.Font.Style := AStyle;
  R := Rect(0, 0, Max(40, AWidth), 0);
  DrawText(FList.Canvas.Handle, PChar(S), Length(S), R, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  Result := R.Bottom - R.Top;
end;

procedure TCapsForm.ListMeasure(Control: TWinControl; Index: Integer; var Height: Integer);
var
  Code, W: Integer;
  Desc, Ex: string;
begin
  Code := RowCode(Index);
  W := FList.ClientWidth - FfPx(CRowPad * 2) - FfPx(12);
  if Code >= 0 then
  begin
    SplitItem(CAP_ITEMS[Code].Key, Desc, Ex);
    Height := FfPx(8) + TextHeight(Desc, W, [], 9);
    if Ex <> '' then
      Inc(Height, FfPx(3) + TextHeight(TrText('AICaps.ExamplePrefix') + ' ' + Ex, W, [fsItalic], 9));
    Inc(Height, FfPx(8));
  end
  else if Code = ROW_NONE then
    Height := FfPx(40)
  else
    Height := FfPx(12) + TextHeight(TrText(SECTION_KEYS[-1 - Code]), W, [fsBold], 10) + FfPx(8);
  Height := Min(Height, 255);
end;

procedure TCapsForm.ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  Code, X: Integer;
  Desc, Ex, S: string;
  R: TRect;
begin
  C := FList.Canvas;
  Code := RowCode(Index);
  X := Rect.Left + FfPx(CRowPad);
  if Code < 0 then
  begin
    C.Brush.Color := CHeadBg;
    C.FillRect(Rect);
    C.Font.Name := FUiFont;
    if Code = ROW_NONE then
    begin
      C.Font.Size := 9;
      C.Font.Style := [fsItalic];
      C.Font.Color := CMuted;
      S := TrText('AICaps.NoMatch');
    end
    else
    begin
      C.Font.Size := 10;
      C.Font.Style := [fsBold];
      C.Font.Color := CAccent;
      S := TrText(SECTION_KEYS[-1 - Code]);
    end;
    R := Classes.Rect(X, Rect.Top + FfPx(12), Rect.Right - FfPx(CRowPad), Rect.Bottom);
    C.Brush.Style := bsClear;
    DrawText(C.Handle, PChar(S), Length(S), R, DT_WORDBREAK or DT_NOPREFIX);
    C.Brush.Style := bsSolid;
    Exit;
  end;
  if odSelected in State then
    C.Brush.Color := CSelBg
  else
    C.Brush.Color := clWindow;
  C.FillRect(Rect);
  SplitItem(CAP_ITEMS[Code].Key, Desc, Ex);
  C.Brush.Style := bsClear;
  C.Font.Name := FUiFont;
  C.Font.Size := 9;
  C.Font.Style := [];
  C.Font.Color := CTitle;
  C.TextOut(X, Rect.Top + FfPx(8), #$2022);
  R := Classes.Rect(X + FfPx(12), Rect.Top + FfPx(8), Rect.Right - FfPx(CRowPad), Rect.Bottom);
  DrawText(C.Handle, PChar(Desc), Length(Desc), R, DT_WORDBREAK or DT_NOPREFIX or DT_CALCRECT);
  DrawText(C.Handle, PChar(Desc), Length(Desc), R, DT_WORDBREAK or DT_NOPREFIX);
  if Ex <> '' then
  begin
    S := TrText('AICaps.ExamplePrefix') + ' ' + Ex;
    C.Font.Style := [fsItalic];
    C.Font.Color := CMuted;
    R := Classes.Rect(X + FfPx(12), R.Bottom + FfPx(3), Rect.Right - FfPx(CRowPad), Rect.Bottom);
    DrawText(C.Handle, PChar(S), Length(S), R, DT_WORDBREAK or DT_NOPREFIX);
  end;
  C.Brush.Style := bsSolid;
  if odFocused in State then
    C.DrawFocusRect(Rect);
end;

procedure TCapsForm.UpdateUseButton;
var
  Code: Integer;
  Desc, Ex: string;
begin
  Code := RowCode(FList.ItemIndex);
  Ex := '';
  if Code >= 0 then
    SplitItem(CAP_ITEMS[Code].Key, Desc, Ex);
  FBtnUse.Enabled := Ex <> '';
end;

procedure TCapsForm.ListClick(Sender: TObject);
begin
  UpdateUseButton;
end;

procedure TCapsForm.ListDblClick(Sender: TObject);
begin
  UseClick(nil);
end;

procedure TCapsForm.FilterChange(Sender: TObject);
begin
  Rebuild;
end;

procedure TCapsForm.FilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;
begin
  if Key <> VK_DOWN then Exit;
  for I := 0 to High(FRows) do
    if FRows[I] >= 0 then
    begin
      FList.ItemIndex := I;
      Break;
    end;
  FList.SetFocus;
  UpdateUseButton;
  Key := 0;
end;

procedure TCapsForm.UseClick(Sender: TObject);
var
  Code: Integer;
  Desc, Ex: string;
begin
  Code := RowCode(FList.ItemIndex);
  if Code < 0 then Exit;
  SplitItem(CAP_ITEMS[Code].Key, Desc, Ex);
  if Ex = '' then Exit;
  FChoice := accExample;
  FText := Ex;
  ModalResult := mrOk;
end;

procedure TCapsForm.Flash(AButton: TButton; const ACaptionKey: string);
begin
  FlashTimer(nil);
  AButton.Tag := 1;
  AButton.Caption := TrText(ACaptionKey);
  FFlashTimer.Enabled := True;
end;

procedure TCapsForm.FlashTimer(Sender: TObject);
begin
  FFlashTimer.Enabled := False;
  if FBtnCopy.Tag = 1 then
    FBtnCopy.Caption := TrText('Agent.ToolCopy');
  if FBtnExport.Tag = 1 then
    FBtnExport.Caption := TrText('AICaps.Export');
  FBtnCopy.Tag := 0;
  FBtnExport.Tag := 0;
end;

procedure TCapsForm.CopyClick(Sender: TObject);
var
  S: string;
begin
  S := SelectedItemText;
  if S = '' then
    S := AICapabilitiesText(FKind);
  Clipboard.AsText := S;
  Flash(FBtnCopy, 'AICaps.Copied');
end;

procedure TCapsForm.ExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  SL: TStringList;
  Md: Boolean;
begin
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := TrText('AICaps.ExportFilter');
    Dlg.FilterIndex := 1;
    Dlg.DefaultExt := 'txt';
    Dlg.Options := Dlg.Options + [ofOverwritePrompt, ofPathMustExist];
    case FKind of
      ackHub: Dlg.FileName := 'FastFile-AI-diagnosis.txt';
      ackAgent: Dlg.FileName := 'FastFile-AI-agent.txt';
    else
      Dlg.FileName := 'FastFile-AI-assistant.txt';
    end;
    if not Dlg.Execute(Handle) then Exit;
    Md := SameText(ExtractFileExt(Dlg.FileName), '.md') or
      ((Dlg.FilterIndex = 2) and (ExtractFileExt(Dlg.FileName) = ''));
    SL := TStringList.Create;
    try
      SL.Text := AICapabilitiesText(FKind, Md);
      SL.WriteBOM := True;
      SL.SaveToFile(Dlg.FileName, TEncoding.UTF8);
    finally
      SL.Free;
    end;
    Flash(FBtnExport, 'AICaps.Saved');
  finally
    Dlg.Free;
  end;
end;

procedure TCapsForm.AskClick(Sender: TObject);
var
  Q, S: string;
begin
  Q := '';
  if not InputQuery(TrText('Agent.ToolAsk'), TrText('AICaps.AskPrompt'), Q) then Exit;
  Q := Trim(Q);
  if Q = '' then Exit;
  S := SelectedItemText;
  if S = '' then
    S := AICapabilitiesText(FKind);
  FChoice := accAsk;
  FText := S;
  FQuestion := Q;
  ModalResult := mrOk;
end;

procedure TCapsForm.CodeHelpClick(Sender: TObject);
var
  Ex: string;
begin
  if not ShowSourceCodeHelp(Ex) then Exit;
  FChoice := accExample;
  FText := Ex;
  ModalResult := mrOk;
end;

procedure TCapsForm.FormResize(Sender: TObject);
begin
  if Assigned(FList) and FList.HandleAllocated then
    Rebuild;
end;

function ShowAICapabilities(AKind: TAICapsKind; out AText, AQuestion: string): TAICapsChoice;
var
  F: TCapsForm;
begin
  AText := '';
  AQuestion := '';
  Result := accNone;
  F := TCapsForm.CreateFor(AKind);
  try
    if F.ShowModal = mrOk then
    begin
      Result := F.FChoice;
      AText := F.FText;
      AQuestion := F.FQuestion;
    end;
  finally
    F.Free;
  end;
end;

end.
