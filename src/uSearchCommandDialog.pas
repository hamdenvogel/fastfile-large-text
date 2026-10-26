unit uSearchCommandDialog;

interface

uses
  Classes, uSearchCommands, uAgentPrefs;

type
  TSearchAIInvoke = function(const APrompt: WideString; out AAnswer: WideString;
    out AError: string): Boolean;
  TSearchPrepareFile = function(const APath, ACommand: string): Boolean of object;
  TSearchAskAI = procedure(const APrompt: string) of object;

function ShowSearchCommand(AOwner: TComponent; const AText: string; ARoots: TStrings;
  const APrefs: TAgentPrefs; const ABookmarkPath: string;
  const ABookmarks: TArray<Int64>; out AResult: TSearchResult;
  out AOpenHit: TSearchHit; out AMark: Boolean;
  AAIInvoke: TSearchAIInvoke = nil; ACanUseBookmarks: Boolean = True;
  APrepareFile: TSearchPrepareFile = nil; AAskAI: TSearchAskAI = nil): Boolean;

implementation

uses
  Windows, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs, Clipbrd,
  ComCtrls, uAgentTools, uI18n, uFastFileScale, uFastFileAIClient;

type
  TSearchWorker = class(TThread)
  private
    procedure ScanTick(ACount: Integer; var ACancel: Boolean);
  protected
    procedure Execute; override;
  public
    Roots: TStringList;
    Prefs: TAgentPrefs;
    Command: TSearchCommand;
    BookmarkPath: string;
    Bookmarks: TArray<Int64>;
    Cancel, Done: Integer;
    Data: TSearchResult;
    Error: string;
    constructor Create;
    destructor Destroy; override;
  end;

  TSearchAIWorker = class(TThread)
  protected
    procedure Execute; override;
  public
    Invoke: TSearchAIInvoke;
    Prompt, Error: string;
    Advice: TSearchCommandAdvice;
    Done: Integer;
  end;

  TSearchDialog = class(TForm)
  private
    Worker: TSearchWorker;
    WorkerStarted: Boolean;
    AIWorker: TSearchAIWorker;
    AIStarted, DiscardAI, CanUseBookmarks: Boolean;
    InvokeAI: TSearchAIInvoke;
    PrepareFile: TSearchPrepareFile;
    Roots: TStringList;
    Prefs: TAgentPrefs;
    BookmarkPath: string;
    Bookmarks: TArray<Int64>;
    RequestEdit, CommandEdit: TEdit;
    Suggestions: TComboBox;
    AIButton, RunButton: TButton;
    Memo: TMemo;
    HitList: TListBox;
    GroupView: TListView;
    Status: TLabel;
    Timer: TTimer;
    StopBtn, MarkBtn, OpenBtn, PrevBtn, NextBtn, CopyBtn, AskBtn: TButton;
    AskPrompt: string;
    Page: Integer;
    EscapeClose: Boolean;
    procedure Tick(Sender: TObject);
    procedure EscapeKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StopClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure AskClick(Sender: TObject);
    procedure PrevClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure UpdatePage;
    procedure CloseSearch(Sender: TObject; var CanClose: Boolean);
    procedure GenerateClick(Sender: TObject);
    procedure RunClick(Sender: TObject);
    procedure SuggestionClick(Sender: TObject);
    procedure SetBusy(ABusy: Boolean);
  public
    destructor Destroy; override;
  end;

function InvokeSearchAI(const APrompt: WideString; out AAnswer: WideString;
  out AError: string): Boolean;
begin
  Result := FastFileAIInvokePrompt(APrompt, AAnswer, AError);
end;

procedure TSearchAIWorker.Execute;
var
  Answer: WideString;
begin
  try
    try
      if not Invoke(Prompt, Answer, Error) then
      begin
        if Error = '' then Error := TrText('SearchCmd.Failed');
        Exit;
      end;
      Advice := ParseSearchCommandAdvice(Answer);
    except
      on E: Exception do Error := E.Message;
    end;
  finally
    InterlockedExchange(Done, 1);
  end;
end;

constructor TSearchWorker.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Roots := TStringList.Create;
end;

destructor TSearchWorker.Destroy;
begin
  inherited;
  Roots.Free;
end;

procedure TSearchWorker.ScanTick(ACount: Integer; var ACancel: Boolean);
begin
  ACancel := Cancel <> 0;
end;

procedure TSearchWorker.Execute;
var
  Files: TStringList;
  Complete: Boolean;
  I: Integer;
  Path: string;
begin
  Files := TStringList.Create;
  try
    try
      Files.CaseSensitive := False;
      Files.Duplicates := dupIgnore;
      Files.Sorted := True;
      for I := 0 to Roots.Count - 1 do
      begin
        Path := Copy(Roots[I], 3, MaxInt);
        if not FileExists(Path) and not DirectoryExists(Path) then
          raise ESearchCommand.CreateFmt(TrText('SearchCmd.Read'), [Path]);
      end;
      Complete := AgentExpandRoots(Roots, Prefs, Files, ScanTick, True);
      Data := RunSearchCommand(Files, Command, @Cancel, BookmarkPath, Bookmarks);
      Data.Partial := Data.Partial or not Complete or (Files.Count >= Prefs.MaxFiles);
    except
      on E: Exception do Error := E.Message;
    end;
  finally
    Files.Free;
    InterlockedExchange(Done, 1);
  end;
end;

destructor TSearchDialog.Destroy;
begin
  if Assigned(AIWorker) then
  begin
    if not AIStarted then AIWorker.Start;
    AIWorker.WaitFor;
    AIWorker.Free;
  end;
  if Assigned(Worker) then
  begin
    InterlockedExchange(Worker.Cancel, 1);
    if not WorkerStarted then Worker.Start;
    Worker.WaitFor;
    Worker.Free;
  end;
  Roots.Free;
  inherited;
end;

procedure TSearchDialog.SetBusy(ABusy: Boolean);
begin
  AIButton.Enabled := not ABusy;
  RunButton.Enabled := not ABusy;
  RequestEdit.Enabled := not ABusy;
  CommandEdit.Enabled := not ABusy;
  Suggestions.Enabled := not ABusy;
  if ABusy then
  begin
    MarkBtn.Enabled := False;
    OpenBtn.Enabled := False;
    CopyBtn.Enabled := False;
    PrevBtn.Enabled := False;
    NextBtn.Enabled := False;
  end
  else if Assigned(Worker) and (Worker.Done <> 0) and (Worker.Error = '') then
  begin
    MarkBtn.Enabled := (Length(Worker.Data.Hits) > 0) and
      (Worker.Command.Kind = sckGrep) and CanUseBookmarks;
    CopyBtn.Enabled := True;
    UpdatePage;
  end;
  StopBtn.ModalResult := mrNone;
  if ABusy then StopBtn.Caption := TrText('Stop')
  else
  begin
    StopBtn.Caption := TrText('Close');
    StopBtn.ModalResult := mrCancel;
  end;
end;

procedure TSearchDialog.GenerateClick(Sender: TObject);
begin
  if Trim(RequestEdit.Text) = '' then
  begin
    Status.Caption := TrText('SearchCmd.AIRequest');
    RequestEdit.SetFocus;
    Exit;
  end;
  FreeAndNil(AIWorker);
  AIStarted := False;
  AIWorker := TSearchAIWorker.Create(True);
  AIWorker.FreeOnTerminate := False;
  AIWorker.Invoke := InvokeAI;
  AIWorker.Prompt := SearchCommandPrompt(RequestEdit.Text, CommandEdit.Text,
    AppLanguageCode(GetCurrentLanguage));
  if not CanUseBookmarks then
    AIWorker.Prompt := AIWorker.Prompt + sLineBreak +
      'Bookmark commands are unavailable in this modal. Do not suggest --mark or --bookmarks. ' +
      'If requested, explain that the user must use the indexed open file in the main window.';
  DiscardAI := False;
  SetBusy(True);
  Status.Caption := TrText('SearchCmd.AIWaiting');
  AIWorker.Start;
  AIStarted := True;
  Timer.Enabled := True;
end;

procedure TSearchDialog.SuggestionClick(Sender: TObject);
begin
  if Suggestions.ItemIndex < 0 then Exit;
  CommandEdit.Text := Suggestions.Items[Suggestions.ItemIndex];
  Status.Caption := TrText('SearchCmd.AIReview');
end;

procedure TSearchDialog.RunClick(Sender: TObject);
var
  C: TSearchCommand;
  Target: string;
begin
  try
    C := ParseSearchCommand(CommandEdit.Text);
    if C.Kind = sckText then
      raise ESearchCommand.Create(TrText('SearchCmd.Pattern'));
    if C.Help then
    begin
      Memo.Text := SearchCommandHelp;
      Exit;
    end;
    Target := C.FilePath;
    if Assigned(PrepareFile) then
    begin
      if Target = '' then Target := BookmarkPath;
      if Target <> '' then
      begin
        Target := ValidateSearchFile(Target);
        if not PrepareFile(Target, CommandEdit.Text) then
        begin
          ModalResult := mrCancel;
          Exit;
        end;
      end;
    end
    else Target := '';
    if C.BookmarksOnly and (C.FilePath <> '') and
      not SameFileName(ExpandFileName(C.FilePath), ExpandFileName(BookmarkPath)) then
      raise ESearchCommand.CreateFmt(TrText('SearchCmd.OutsideSources'), [C.FilePath]);
    if (C.Mark or C.BookmarksOnly) and not CanUseBookmarks then
    begin
      if BookmarkPath = '' then
        raise ESearchCommand.Create(TrText('SearchCmd.BookmarkUnavailable'));
      raise ESearchCommand.Create(TrText('SearchCmd.Index'));
    end;
    if C.BookmarksOnly and (BookmarkPath = '') then
      raise ESearchCommand.Create(TrText('SearchCmd.NoSources'));
    if (Roots.Count = 0) and (Target = '') then
      raise ESearchCommand.Create(TrText('SearchCmd.NoSources'));
    FreeAndNil(Worker);
    WorkerStarted := False;
    Worker := TSearchWorker.Create;
    Worker.Roots.Assign(Roots);
    if Target <> '' then
    begin
      Worker.Roots.Clear;
      Worker.Roots.Add('F|' + Target);
    end;
    if C.BookmarksOnly then
    begin
      Worker.Roots.Clear;
      if BookmarkPath <> '' then Worker.Roots.Add('F|' + BookmarkPath);
    end;
    Worker.Prefs := Prefs;
    Worker.Command := C;
    Worker.BookmarkPath := BookmarkPath;
    Worker.Bookmarks := Copy(Bookmarks);
    HitList.Clear;
    Page := 0;
    MarkBtn.Enabled := False;
    OpenBtn.Enabled := False;
    CopyBtn.Enabled := False;
    PrevBtn.Enabled := False;
    NextBtn.Enabled := False;
    SetBusy(True);
    Status.Caption := TrText('SearchCmd.Scanning');
    Worker.Start;
    WorkerStarted := True;
    Timer.Enabled := True;
  except
    on E: Exception do
    begin
      Status.Caption := TrText('SearchCmd.Failed');
      Memo.Text := E.Message;
      SetBusy(False);
    end;
  end;
end;

procedure TSearchDialog.EscapeKey(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key <> VK_ESCAPE) or (Shift <> []) then Exit;
  if Assigned(Suggestions) and Suggestions.DroppedDown then Exit;
  Key := 0;
  EscapeClose := True;
  if Assigned(AIWorker) and (AIWorker.Done = 0) then
    DiscardAI := True;
  if Assigned(Worker) and (Worker.Done = 0) then
    InterlockedExchange(Worker.Cancel, 1);
  ModalResult := mrCancel;
end;

procedure TSearchDialog.CloseSearch(Sender: TObject; var CanClose: Boolean);
begin
  if EscapeClose then
  begin
    CanClose := True;
    Exit;
  end;
  if Assigned(AIWorker) and (AIWorker.Done = 0) then
  begin
    DiscardAI := True;
    Status.Caption := TrText('SearchCmd.AIStopping');
    CanClose := False;
  end;
  if Assigned(Worker) and (Worker.Done = 0) then
  begin
    InterlockedExchange(Worker.Cancel, 1);
    CanClose := False;
  end;
end;

procedure TSearchDialog.Tick(Sender: TObject);
var
  S: string;
begin
  if Assigned(AIWorker) then
  begin
    if AIWorker.Done = 0 then Exit;
    Timer.Enabled := False;
    AIWorker.WaitFor;
    SetBusy(False);
    if DiscardAI then
    begin
      ModalResult := mrCancel;
      Exit;
    end;
    if AIWorker.Error <> '' then
    begin
      Memo.Text := AIWorker.Error;
      Status.Caption := TrText('SearchCmd.Failed');
    end
    else
    begin
      CommandEdit.Text := AIWorker.Advice.Command;
      Memo.Text := AIWorker.Advice.Explanation;
      Suggestions.Items.Clear;
      for S in AIWorker.Advice.Suggestions do Suggestions.Items.Add(S);
      Status.Caption := TrText('SearchCmd.AIReview');
    end;
    FreeAndNil(AIWorker);
    Exit;
  end;
  if not Assigned(Worker) then Exit;
  if Worker.Done = 0 then Exit;
  Timer.Enabled := False;
  Worker.WaitFor;
  SetBusy(False);
  if Worker.Error <> '' then
  begin
    Memo.Text := Worker.Error;
    Status.Caption := TrText('SearchCmd.Failed');
    Exit;
  end;
  Status.Caption := Format(TrText('SearchCmd.Results'), [Length(Worker.Data.Hits),
    Worker.Data.FilesScanned]);
  if Worker.Data.Partial then Status.Caption := Status.Caption + ' ' + TrText('SearchCmd.Partial');
  if Worker.Data.Cancelled then Status.Caption := Status.Caption + ' ' + TrText('SearchCmd.Stopped');
  if Length(Worker.Data.GroupNames) > 0 then
    Status.Caption := Status.Caption + ' ' + Format(TrText('SearchCmd.GroupColumns'),
      [string.Join(', ', Worker.Data.GroupNames)]);
  MarkBtn.Enabled := (Length(Worker.Data.Hits) > 0) and
    (Worker.Command.Kind = sckGrep) and CanUseBookmarks;
  CopyBtn.Enabled := True;
  if Assigned(AskBtn) then
    AskBtn.Enabled := Length(Worker.Data.Hits) > 0;
  UpdatePage;
  if Worker.Command.Mark and not Worker.Data.Cancelled then ModalResult := mrYes;
end;

procedure TSearchDialog.UpdatePage;
var
  I, N, G: Integer;
  H: TSearchHit;
  Item: TListItem;
  Col: TListColumn;
  Names: TArray<string>;
begin
  Names := nil;
  if Assigned(Worker) then
    Names := Worker.Data.GroupNames;
  GroupView.Visible := Length(Names) > 0;
  HitList.Visible := not GroupView.Visible;
  N := 0;
  if Assigned(Worker) then
    N := Length(Worker.Data.Hits);
  if GroupView.Visible then
  begin
    GroupView.Items.BeginUpdate;
    try
      if GroupView.Columns.Count <> Length(Names) + 2 then
      begin
        GroupView.Columns.Clear;
        Col := GroupView.Columns.Add;
        Col.Caption := TrText('SearchCmd.File');
        Col.Width := FfPx(220);
        Col := GroupView.Columns.Add;
        Col.Caption := TrText('Line #');
        Col.Width := FfPx(70);
        for G := 0 to High(Names) do
        begin
          Col := GroupView.Columns.Add;
          Col.Caption := Names[G];
          Col.Width := FfPx(120);
        end;
      end;
      GroupView.Items.Clear;
      for I := Page * 40 to Page * 40 + 39 do
      begin
        if I >= N then Break;
        H := Worker.Data.Hits[I];
        Item := GroupView.Items.Add;
        Item.Caption := H.Path;
        if H.Line > 0 then
          Item.SubItems.Add(IntToStr(H.Line))
        else
          Item.SubItems.Add('');
        for G := 0 to High(Names) do
          if G < Length(H.GroupValues) then
            Item.SubItems.Add(H.GroupValues[G])
          else
            Item.SubItems.Add('');
      end;
      if GroupView.Items.Count > 0 then
        GroupView.ItemIndex := 0;
    finally
      GroupView.Items.EndUpdate;
    end;
    OpenBtn.Enabled := GroupView.Items.Count > 0;
  end
  else
  begin
    HitList.Items.BeginUpdate;
    try
      HitList.Clear;
      for I := Page * 40 to Page * 40 + 39 do
      begin
        if I >= N then Break;
        H := Worker.Data.Hits[I];
        if H.Line > 0 then
          HitList.Items.Add(H.Path + ':' + IntToStr(H.Line) + ': ' + H.Text)
        else
          HitList.Items.Add(H.Path);
      end;
      if HitList.Count > 0 then HitList.ItemIndex := 0;
      OpenBtn.Enabled := HitList.Count > 0;
    finally
      HitList.Items.EndUpdate;
    end;
  end;
  PrevBtn.Enabled := Page > 0;
  NextBtn.Enabled := (Page + 1) * 40 < N;
end;

procedure TSearchDialog.PrevClick(Sender: TObject);
begin
  Dec(Page);
  UpdatePage;
end;

procedure TSearchDialog.NextClick(Sender: TObject);
begin
  Inc(Page);
  UpdatePage;
end;

procedure TSearchDialog.StopClick(Sender: TObject);
begin
  if Assigned(AIWorker) and (AIWorker.Done = 0) then
  begin
    DiscardAI := True;
    Status.Caption := TrText('SearchCmd.AIStopping');
  end;
  if Assigned(Worker) and (Worker.Done = 0) then InterlockedExchange(Worker.Cancel, 1);
end;

procedure TSearchDialog.CopyClick(Sender: TObject);
begin
  Clipboard.AsText := SearchResultText(Worker.Data);
end;

procedure TSearchDialog.AskClick(Sender: TObject);
var
  Sample: string;
begin
  if not Assigned(Worker) then Exit;
  Sample := SearchResultText(Worker.Data);
  if Length(Sample) > 1800 then
    Sample := Copy(Sample, 1, 1800);
  AskPrompt := TrText('AI.Context.SearchGroups') + sLineBreak + CommandEdit.Text +
    sLineBreak + Sample;
  ModalResult := mrAbort;
end;

function ShowSearchCommand(AOwner: TComponent; const AText: string; ARoots: TStrings;
  const APrefs: TAgentPrefs; const ABookmarkPath: string;
  const ABookmarks: TArray<Int64>; out AResult: TSearchResult;
  out AOpenHit: TSearchHit; out AMark: Boolean;
  AAIInvoke: TSearchAIInvoke; ACanUseBookmarks: Boolean;
  APrepareFile: TSearchPrepareFile; AAskAI: TSearchAskAI): Boolean;
var
  D: TSearchDialog;
  AskPrompt: string;
  C: TSearchCommand;
  Footer, Editor: TPanel;
  LabelControl: TLabel;
  R, Index: Integer;

  function Button(const ACaption: string; ALeft, AWidth: Integer): TButton;
  begin
    Result := TButton.Create(D);
    Result.Parent := Footer;
    Result.Caption := ACaption;
    Result.SetBounds(FfPx(ALeft), FfPx(8), FfPx(AWidth), FfPx(34));
  end;

begin
  Result := False;
  AskPrompt := '';
  AMark := False;
  AResult := Default(TSearchResult);
  AOpenHit := Default(TSearchHit);
  C := ParseSearchCommand(AText);
  D := TSearchDialog.CreateNew(AOwner);
  try
    D.Caption := 'glob / grep';
    D.Position := poScreenCenter;
    D.ClientWidth := FfPx(980);
    D.ClientHeight := FfPx(720);
    D.BorderStyle := bsSizeable;
    D.KeyPreview := True;
    D.OnKeyDown := D.EscapeKey;
    D.OnCloseQuery := D.CloseSearch;
    D.Roots := TStringList.Create;
    D.Roots.Assign(ARoots);
    D.Prefs := APrefs;
    D.BookmarkPath := ABookmarkPath;
    D.Bookmarks := Copy(ABookmarks);
    D.CanUseBookmarks := ACanUseBookmarks;
    D.PrepareFile := APrepareFile;
    D.InvokeAI := AAIInvoke;
    if not Assigned(D.InvokeAI) then D.InvokeAI := InvokeSearchAI;
    Footer := TPanel.Create(D);
    Footer.Parent := D;
    Footer.Align := alBottom;
    Footer.Height := FfPx(52);
    D.StopBtn := Button(TrText('Stop'), 8, 100);
    D.StopBtn.Name := 'SearchStop';
    D.StopBtn.Cancel := True;
    D.StopBtn.OnClick := D.StopClick;
    D.CopyBtn := Button(TrText('Copy'), 116, 100);
    D.CopyBtn.OnClick := D.CopyClick;
    D.CopyBtn.Enabled := False;
    D.MarkBtn := Button(TrText('SearchCmd.Mark'), 224, 280);
    D.MarkBtn.ModalResult := mrYes;
    D.MarkBtn.Enabled := False;
    D.OpenBtn := Button(TrText('Open'), 512, 120);
    D.OpenBtn.ModalResult := mrOk;
    D.OpenBtn.Enabled := False;
    D.PrevBtn := Button('<', 640, 48);
    D.PrevBtn.OnClick := D.PrevClick;
    D.PrevBtn.Enabled := False;
    D.NextBtn := Button('>', 696, 48);
    D.NextBtn.OnClick := D.NextClick;
    D.NextBtn.Enabled := False;
    if Assigned(AAskAI) then
    begin
      D.AskBtn := Button(TrText('SearchCmd.AskAI'), 752, 210);
      D.AskBtn.OnClick := D.AskClick;
      D.AskBtn.Enabled := False;
    end;
    D.Status := TLabel.Create(D);
    D.Status.Parent := D;
    D.Status.Align := alTop;
    D.Status.AutoSize := False;
    D.Status.Height := FfPx(48);
    D.Status.WordWrap := True;
    D.Status.Caption := TrText('SearchCmd.Scanning');
    D.Memo := TMemo.Create(D);
    D.Memo.Name := 'SearchExplanation';
    D.Memo.Parent := D;
    D.Memo.Align := alTop;
    D.Memo.Height := FfPx(180);
    D.Memo.ReadOnly := True;
    D.Memo.WantReturns := False;
    D.Memo.ScrollBars := ssBoth;
    D.Memo.Text := SearchCommandHelp;
    D.HitList := TListBox.Create(D);
    D.HitList.Parent := D;
    D.HitList.Align := alClient;
    D.HitList.ScrollWidth := FfPx(2000);
    D.GroupView := TListView.Create(D);
    D.GroupView.Parent := D;
    D.GroupView.Align := alClient;
    D.GroupView.Visible := False;
    D.GroupView.ViewStyle := vsReport;
    D.GroupView.ReadOnly := True;
    D.GroupView.RowSelect := True;
    D.GroupView.HideSelection := False;
    D.GroupView.GridLines := True;
    Editor := TPanel.Create(D);
    Editor.Parent := D;
    Editor.Align := alTop;
    Editor.Height := FfPx(158);
    Editor.BevelOuter := bvNone;
    Editor.Top := 0;
    LabelControl := TLabel.Create(D);
    LabelControl.Parent := Editor;
    LabelControl.Caption := TrText('SearchCmd.AIRequest');
    LabelControl.SetBounds(FfPx(8), FfPx(4), FfPx(800), FfPx(18));
    D.RequestEdit := TEdit.Create(D);
    D.RequestEdit.Name := 'SearchAIRequest';
    D.RequestEdit.Parent := Editor;
    LabelControl.FocusControl := D.RequestEdit;
    D.RequestEdit.SetBounds(FfPx(8), FfPx(24), FfPx(704), FfPx(26));
    D.RequestEdit.Anchors := [akLeft, akTop, akRight];
    D.AIButton := TButton.Create(D);
    D.AIButton.Name := 'SearchAIGenerate';
    D.AIButton.Parent := Editor;
    D.AIButton.Caption := TrText('SearchCmd.AIGenerate');
    D.AIButton.SetBounds(FfPx(720), FfPx(22), FfPx(250), FfPx(30));
    D.AIButton.Anchors := [akTop, akRight];
    D.AIButton.OnClick := D.GenerateClick;
    D.Suggestions := TComboBox.Create(D);
    D.Suggestions.Name := 'SearchSuggestions';
    D.Suggestions.Parent := Editor;
    D.Suggestions.Style := csDropDownList;
    D.Suggestions.SetBounds(FfPx(200), FfPx(56), FfPx(770), FfPx(26));
    D.Suggestions.Anchors := [akLeft, akTop, akRight];
    if C.Kind = sckGlob then
      D.Suggestions.Items.Text := 'glob "*.csv"' + sLineBreak +
        'glob "**\*.log"' + sLineBreak + 'glob "report_202?.txt" --limit 500'
    else
    begin
      D.Suggestions.Items.Text := 'grep -i -F "error" --glob "*.log"' + sLineBreak +
        'grep -E "error|failure"' + sLineBreak + 'grep -v -F "DEBUG"' + sLineBreak +
        'grep -E "(?<ip>\d+\.\d+\.\d+\.\d+).*(?<status>\d{3})"';
      if D.CanUseBookmarks then
      begin
        D.Suggestions.Items.Add('grep --bookmarks -i "pending"');
        D.Suggestions.Items.Add('grep --mark -i "error"');
      end;
    end;
    D.Suggestions.OnChange := D.SuggestionClick;
    D.Suggestions.Hint := TrText('SearchCmd.AISuggestions');
    D.Suggestions.ShowHint := True;
    LabelControl := TLabel.Create(D);
    LabelControl.Parent := Editor;
    LabelControl.Caption := TrText('SearchCmd.AISuggestions');
    LabelControl.FocusControl := D.Suggestions;
    LabelControl.SetBounds(FfPx(8), FfPx(60), FfPx(188), FfPx(22));
    D.CommandEdit := TEdit.Create(D);
    D.CommandEdit.Name := 'SearchCommand';
    D.CommandEdit.Parent := Editor;
    D.CommandEdit.Text := AText;
    D.CommandEdit.SetBounds(FfPx(8), FfPx(90), FfPx(704), FfPx(26));
    D.CommandEdit.Anchors := [akLeft, akTop, akRight];
    D.CommandEdit.Hint := TrText('SearchCmd.AIReview');
    D.CommandEdit.ShowHint := True;
    D.RunButton := TButton.Create(D);
    D.RunButton.Name := 'SearchRun';
    D.RunButton.Parent := Editor;
    D.RunButton.Caption := TrText('SearchCmd.Run');
    D.RunButton.SetBounds(FfPx(720), FfPx(88), FfPx(250), FfPx(30));
    D.RunButton.Anchors := [akTop, akRight];
    D.RunButton.OnClick := D.RunClick;
    LabelControl := TLabel.Create(D);
    LabelControl.Parent := Editor;
    LabelControl.Caption := TrText('SearchCmd.AIPrivacy');
    LabelControl.AutoSize := False;
    LabelControl.WordWrap := True;
    LabelControl.SetBounds(FfPx(8), FfPx(122), FfPx(962), FfPx(34));
    LabelControl.Anchors := [akLeft, akTop, akRight];
    D.Constraints.MinWidth := FfPx(980);
    D.Constraints.MinHeight := FfPx(600);
    D.Timer := TTimer.Create(D);
    D.Timer.Enabled := False;
    D.Timer.Interval := 100;
    D.Timer.OnTimer := D.Tick;
    D.SetBusy(False);
    D.Status.Caption := TrText('SearchCmd.AIReview');
    if not C.Help then D.RunClick(nil);
    R := D.ShowModal;
    AskPrompt := D.AskPrompt;
    D.Timer.Enabled := False;
    if not Assigned(D.Worker) then Exit;
    D.Worker.WaitFor;
    if D.Worker.Error <> '' then Exit;
    AResult := D.Worker.Data;
    AMark := R = mrYes;
    Index := -1;
    if (R = mrOk) and D.GroupView.Visible and (D.GroupView.ItemIndex >= 0) then
      Index := D.Page * 40 + D.GroupView.ItemIndex
    else if (R = mrOk) and (D.HitList.ItemIndex >= 0) then
      Index := D.Page * 40 + D.HitList.ItemIndex;
    if (Index >= 0) and (Index < Length(AResult.Hits)) then
      AOpenHit := AResult.Hits[Index];
    Result := AMark or (R = mrOk);
  finally
    D.Free;
  end;
  if (AskPrompt <> '') and Assigned(AAskAI) then
    AAskAI(AskPrompt);
end;

end.
