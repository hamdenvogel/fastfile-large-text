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
  Windows, Messages, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  Clipbrd, ComCtrls, IniFiles, uAgentTools, uI18n, uFastFileScale,
  uFastFileAIClient, uUserPrefs, uMruFind, UnitPopupMruList, uFastFilePaths,
  uBidiLayout, uSmoothLoading;

const
  WM_SEARCH_MRU_POPUP = WM_APP + 81;
  SEARCH_CMD_MRU_INI = 'mru_search_cmd.ini';
  SEARCH_CMD_MRU_SECTION = 'Commands';
  SEARCH_EXAMPLE_COUNT = 11;

function EncodeSearchMru(const ACommand: string): string;
begin
  Result := StringReplace(ACommand, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function DecodeSearchMru(const AEncoded: string): string;
var
  I: Integer;
  S: string;
begin
  Result := '';
  S := AEncoded;
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      if S[I + 1] = 'n' then
      begin
        Result := Result + #13#10;
        Inc(I, 2);
      end
      else if S[I + 1] = '\' then
      begin
        Result := Result + '\';
        Inc(I, 2);
      end
      else
      begin
        Result := Result + S[I];
        Inc(I);
      end;
    end
    else
    begin
      Result := Result + S[I];
      Inc(I);
    end;
  end;
end;

procedure SearchExample(AIndex: Integer; out AKind: TSearchCommandKind;
  out ACommand, AKey: string; out ANeedsBookmarks: Boolean);
begin
  ANeedsBookmarks := False;
  AKind := sckGrep;
  ACommand := '';
  AKey := '';
  case AIndex of
    0:
      begin
        AKind := sckGlob;
        ACommand := 'glob "*.csv"';
        AKey := 'SearchCmd.Ex.GlobCsv';
      end;
    1:
      begin
        AKind := sckGlob;
        ACommand := 'glob "**\*.log"';
        AKey := 'SearchCmd.Ex.GlobLog';
      end;
    2:
      begin
        AKind := sckGlob;
        ACommand := 'glob "report_202?.txt"';
        AKey := 'SearchCmd.Ex.GlobReport';
      end;
    3:
      begin
        AKind := sckGlob;
        ACommand := 'glob "**\*.log" --limit 500';
        AKey := 'SearchCmd.Ex.GlobLimit';
      end;
    4:
      begin
        ACommand := 'grep -i -F "error" --glob "*.log"';
        AKey := 'SearchCmd.Ex.GrepLog';
      end;
    5:
      begin
        ACommand := 'grep -E "error|failure"';
        AKey := 'SearchCmd.Ex.GrepOr';
      end;
    6:
      begin
        ACommand := 'grep -v -F "DEBUG"';
        AKey := 'SearchCmd.Ex.GrepInvert';
      end;
    7:
      begin
        ACommand := 'grep -w -i "id"';
        AKey := 'SearchCmd.Ex.GrepWord';
      end;
    8:
      begin
        ACommand := 'grep -E "(?<ip>\d+\.\d+\.\d+\.\d+).*(?<status>\d{3})"';
        AKey := 'SearchCmd.Ex.GrepGroups';
      end;
    9:
      begin
        ACommand := 'grep --bookmarks -i "pending"';
        AKey := 'SearchCmd.Ex.GrepBookmarks';
        ANeedsBookmarks := True;
      end;
    10:
      begin
        ACommand := 'grep --mark -i "error"';
        AKey := 'SearchCmd.Ex.GrepMark';
        ANeedsBookmarks := True;
      end;
  end;
end;

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
    Phase, Expanded: Integer;
    Progress: TSearchProgress;
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
    FRecent, FSuggest, FSuggestNotes, FHidden: TStringList;
    FKind: TSearchCommandKind;
    FUserCleared, FPopupPosted: Boolean;
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
    LoadShown: Boolean;
    LoadPhase: Integer;
    LoadStart: Cardinal;
    procedure ShowLoad(const AMessage: string; AIndeterminate: Boolean);
    procedure HideLoad;
    procedure UpdateScanLoad;
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
    procedure SuggestionDropDown(Sender: TObject);
    procedure WMSearchMruPopup(var Msg: TMessage); message WM_SEARCH_MRU_POPUP;
    procedure MruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure MruRemove(Sender: TObject; const AValue: string);
    procedure MruClearAll(Sender: TObject);
    procedure AddRecent(const ACommand: string);
    procedure RememberCommand(const ACommand: string);
    procedure LoadRecent;
    procedure SaveRecent;
    function CommandHidden(const ACommand: string): Boolean;
    function ExampleNote(const ACommand: string): string;
    procedure RebuildSuggestions;
    procedure RefreshSuggestions;
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
  Expanded := ACount;
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
      InterlockedExchange(Phase, 1);
      Data := RunSearchCommand(Files, Command, @Cancel, BookmarkPath, Bookmarks, @Progress);
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
  HideLoad;
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
  if HandleAllocated then
    ReleaseMruListPopup(Handle);
  Roots.Free;
  FRecent.Free;
  FSuggest.Free;
  FSuggestNotes.Free;
  FHidden.Free;
  inherited;
end;

function SearchFmtBytes(const ABytes: Int64): string;
begin
  if ABytes >= Int64(1024) * 1024 * 1024 then
    Result := FormatFloat('0.00', ABytes / (1024.0 * 1024 * 1024)) + ' GB'
  else if ABytes >= 1024 * 1024 then
    Result := FormatFloat('0.0', ABytes / (1024.0 * 1024)) + ' MB'
  else
    Result := FormatFloat('0', ABytes / 1024.0) + ' KB';
end;

function SearchFmtSecs(ASecs: Int64): string;
begin
  if ASecs < 0 then ASecs := 0;
  if ASecs >= 3600 then
    Result := Format('%d:%.2d:%.2d', [ASecs div 3600, (ASecs mod 3600) div 60, ASecs mod 60])
  else
    Result := Format('%.2d:%.2d', [ASecs div 60, ASecs mod 60]);
end;

procedure TSearchDialog.ShowLoad(const AMessage: string; AIndeterminate: Boolean);
begin
  if not LoadShown then
  begin
    TfrmSmoothLoading.ShowLoading(Self, AMessage, True);
    LoadShown := True;
    LoadStart := GetTickCount;
  end;
  TfrmSmoothLoading.SetIndeterminate(AIndeterminate);
end;

procedure TSearchDialog.HideLoad;
begin
  if not LoadShown then Exit;
  LoadShown := False;
  TfrmSmoothLoading.HideLoading;
end;

procedure TSearchDialog.UpdateScanLoad;
var
  Done, Total: Int64;
  Pct: Integer;
  Elapsed, Eta: Int64;
  Detail: string;
begin
  if not (LoadShown and Assigned(Worker)) then Exit;
  Elapsed := (GetTickCount - LoadStart) div 1000;
  if Worker.Phase = 0 then
  begin
    LoadPhase := 0;
    TfrmSmoothLoading.SetIndeterminate(True);
    TfrmSmoothLoading.SetWaitTexts(TrText('SearchCmd.ProgressListing'),
      Format(TrText('SearchCmd.ProgressListed'), [Worker.Expanded]) + '  |  ' +
      Format(TrText('SearchCmd.ProgressElapsed'), [SearchFmtSecs(Elapsed)]));
    Exit;
  end;
  Done := Worker.Progress.BytesDone;
  Total := Worker.Progress.BytesTotal;
  if Worker.Command.Kind = sckGlob then
  begin
    Done := Worker.Progress.FilesDone;
    Total := Worker.Progress.FilesTotal;
  end;
  if Total > 0 then
    Pct := Integer((Done * 100) div Total)
  else
    Pct := 0;
  if Pct > 100 then Pct := 100;
  TfrmSmoothLoading.SetIndeterminate(False);
  if LoadPhase <> 1 then
  begin
    LoadPhase := 1;
    TfrmSmoothLoading.SetWaitTexts(TrText('SearchCmd.ProgressScanning'), '');
  end;
  if Worker.Command.Kind = sckGlob then
    Detail := ''
  else
    Detail := SearchFmtBytes(Done) + ' / ' + SearchFmtBytes(Total) + '  |  ';
  Detail := Detail + Format(TrText('SearchCmd.ProgressFiles'),
    [Worker.Progress.FilesDone, Worker.Progress.FilesTotal]) + '  |  ' +
    Format(TrText('SearchCmd.ProgressHits'), [Worker.Progress.Hits]) + '  |  ' +
    Format(TrText('SearchCmd.ProgressElapsed'), [SearchFmtSecs(Elapsed)]);
  if (Done > 0) and (Total > Done) and (Elapsed > 0) then
  begin
    Eta := Round(Elapsed * ((Total - Done) / Done));
    Detail := Detail + '  |  ' + Format(TrText('SearchCmd.ProgressEta'), [SearchFmtSecs(Eta)]);
  end;
  TfrmSmoothLoading.UpdateProgressWithDetail(Pct, Detail);
end;

procedure TSearchDialog.SetBusy(ABusy: Boolean);
begin
  AIButton.Enabled := not ABusy;
  RunButton.Enabled := not ABusy;
  RequestEdit.Enabled := not ABusy;
  CommandEdit.Enabled := not ABusy;
  Suggestions.Enabled := (not ABusy) and Assigned(FSuggest) and (FSuggest.Count > 0);
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

procedure TSearchDialog.AddRecent(const ACommand: string);
var
  S, Key: string;
  I: Integer;
begin
  S := Trim(ACommand);
  if (S = '') or (not Assigned(FRecent)) then Exit;
  Key := AnsiLowerCase(S);
  for I := FRecent.Count - 1 downto 0 do
    if AnsiLowerCase(Trim(FRecent[I])) = Key then
      FRecent.Delete(I);
  FRecent.Insert(0, S);
  while FRecent.Count > PrefFilterRecentMax do
    FRecent.Delete(FRecent.Count - 1);
end;

procedure TSearchDialog.RememberCommand(const ACommand: string);
var
  I: Integer;
  Key: string;
begin
  if Trim(ACommand) = '' then Exit;
  Key := AnsiLowerCase(Trim(ACommand));
  if Assigned(FHidden) then
  begin
    I := FHidden.IndexOf(Key);
    if I >= 0 then
      FHidden.Delete(I);
  end;
  AddRecent(ACommand);
  FUserCleared := False;
  SaveRecent;
  RefreshSuggestions;
end;

procedure TSearchDialog.SaveRecent;
var
  Ini: TIniFile;
  I, N: Integer;
begin
  if not Assigned(FRecent) then Exit;
  Ini := TIniFile.Create(FastFileExeDirPath(SEARCH_CMD_MRU_INI));
  try
    N := FRecent.Count;
    if N > PrefFilterRecentMax then
      N := PrefFilterRecentMax;
    Ini.WriteInteger(SEARCH_CMD_MRU_SECTION, 'Count', N);
    Ini.WriteBool(SEARCH_CMD_MRU_SECTION, 'Cleared', FUserCleared and (N = 0));
    for I := 0 to PrefFilterRecentMax - 1 do
    begin
      if I < N then
        Ini.WriteString(SEARCH_CMD_MRU_SECTION, 'C' + IntToStr(I),
          EncodeSearchMru(FRecent[I]))
      else
        Ini.DeleteKey(SEARCH_CMD_MRU_SECTION, 'C' + IntToStr(I));
    end;
  finally
    Ini.Free;
  end;
end;

function TSearchDialog.CommandHidden(const ACommand: string): Boolean;
begin
  Result := Assigned(FHidden) and
    (FHidden.IndexOf(AnsiLowerCase(Trim(ACommand))) >= 0);
end;

function TSearchDialog.ExampleNote(const ACommand: string): string;
var
  I: Integer;
  Kind: TSearchCommandKind;
  Cmd, Key: string;
  Book: Boolean;
begin
  Result := '';
  for I := 0 to SEARCH_EXAMPLE_COUNT - 1 do
  begin
    SearchExample(I, Kind, Cmd, Key, Book);
    if AnsiSameText(Trim(Cmd), Trim(ACommand)) then
    begin
      Result := TrText(Key);
      Exit;
    end;
  end;
end;

procedure TSearchDialog.RebuildSuggestions;
var
  I: Integer;
  Shown, Kind: TSearchCommandKind;
  Cmd, Key: string;
  Book: Boolean;

  function Already(const S: string): Boolean;
  var
    J: Integer;
  begin
    Result := False;
    for J := 0 to FSuggest.Count - 1 do
      if AnsiSameText(Trim(FSuggest[J]), Trim(S)) then
        Exit(True);
  end;

begin
  if (not Assigned(FSuggest)) or (not Assigned(FSuggestNotes)) then Exit;
  FSuggest.Clear;
  FSuggestNotes.Clear;
  Shown := FKind;
  if Shown <> sckGlob then
    Shown := sckGrep;
  for I := 0 to SEARCH_EXAMPLE_COUNT - 1 do
  begin
    SearchExample(I, Kind, Cmd, Key, Book);
    if Kind <> Shown then Continue;
    if Book and (not CanUseBookmarks) then Continue;
    if CommandHidden(Cmd) then Continue;
    FSuggest.Add(Cmd);
    FSuggestNotes.Add(TrText(Key));
  end;
  if Assigned(FRecent) then
    for I := 0 to FRecent.Count - 1 do
    begin
      Cmd := Trim(FRecent[I]);
      if (Cmd = '') or CommandHidden(Cmd) or Already(Cmd) then Continue;
      FSuggest.Add(Cmd);
      FSuggestNotes.Add(ExampleNote(Cmd));
    end;
end;

procedure TSearchDialog.LoadRecent;
var
  Ini: TIniFile;
  Path: string;
  N, I: Integer;
  S: string;
begin
  if not Assigned(FRecent) then Exit;
  FRecent.Clear;
  FUserCleared := False;
  Path := FastFileExeDirPath(SEARCH_CMD_MRU_INI);
  if FileExists(Path) then
  begin
    Ini := TIniFile.Create(Path);
    try
      FUserCleared := Ini.ReadBool(SEARCH_CMD_MRU_SECTION, 'Cleared', False);
      N := Ini.ReadInteger(SEARCH_CMD_MRU_SECTION, 'Count', 0);
      if N > PrefFilterRecentMax then
        N := PrefFilterRecentMax;
      for I := 0 to N - 1 do
      begin
        S := DecodeSearchMru(Ini.ReadString(SEARCH_CMD_MRU_SECTION,
          'C' + IntToStr(I), ''));
        if Trim(S) <> '' then
          FRecent.Add(S);
      end;
    finally
      Ini.Free;
    end;
  end;
  RefreshSuggestions;
end;

procedure TSearchDialog.RefreshSuggestions;
var
  Shown: string;
begin
  RebuildSuggestions;
  if not Assigned(Suggestions) or (not Assigned(FSuggest)) then Exit;
  Suggestions.Items.BeginUpdate;
  try
    Suggestions.Items.Clear;
    if FSuggest.Count = 0 then
    begin
      Suggestions.Items.Add(TrText('SearchCmd.RecentEmpty'));
      Suggestions.ItemIndex := 0;
      Suggestions.Enabled := False;
    end
    else
    begin
      Shown := '';
      if Assigned(FRecent) and (FRecent.Count > 0) then
        Shown := Trim(FRecent[0]);
      if Shown = '' then
        Shown := FSuggest[0];
      Suggestions.Items.Add(Shown);
      Suggestions.ItemIndex := 0;
      Suggestions.Enabled := True;
    end;
    Suggestions.DropDownCount := 1;
  finally
    Suggestions.Items.EndUpdate;
  end;
end;

procedure TSearchDialog.SuggestionDropDown(Sender: TObject);
begin
  if Assigned(Suggestions) then
    Suggestions.DroppedDown := False;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if FPopupPosted then Exit;
  FPopupPosted := True;
  PostMessage(Handle, WM_SEARCH_MRU_POPUP, 0, 0);
end;

procedure TSearchDialog.WMSearchMruPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FPopupPosted := False;
  if Assigned(Suggestions) then
    Suggestions.DroppedDown := False;
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FPopupPosted := True;
    PostMessage(Handle, WM_SEARCH_MRU_POPUP, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if (not Assigned(FSuggest)) or (FSuggest.Count = 0) then Exit;
  if (not Assigned(Suggestions)) or (not Suggestions.Enabled) then Exit;
  if Suggestions.HandleAllocated then
  begin
    GetWindowRect(Suggestions.Handle, CR);
    W := CR.Right - CR.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := Suggestions.Width;
    P := Suggestions.ClientToScreen(Point(0, Suggestions.Height));
  end;
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('SearchCmd.AISuggestions'),
    MruMoreCaption('SearchCmd.RecentMore'), FSuggest, W, P, MruPick,
    TrText('SearchCmd.RecentMoreHint'), nil, MruRemove, Suggestions,
    MruClearAll, Handle, FSuggestNotes);
end;

procedure TSearchDialog.MruPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  if not Assigned(CommandEdit) or (not CommandEdit.Enabled) then Exit;
  CommandEdit.Text := AValue;
  CommandEdit.SelStart := Length(CommandEdit.Text);
  RememberCommand(AValue);
  if ExampleNote(AValue) <> '' then
    Status.Caption := ExampleNote(AValue)
  else
    Status.Caption := TrText('SearchCmd.AIReview');
  if CommandEdit.CanFocus then
    CommandEdit.SetFocus;
end;

procedure TSearchDialog.MruRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
  Key: string;
begin
  if not Assigned(FRecent) then Exit;
  Key := AnsiLowerCase(Trim(AValue));
  if Key = '' then Exit;
  if Assigned(FHidden) and (FHidden.IndexOf(Key) < 0) then
    FHidden.Add(Key);
  for I := FRecent.Count - 1 downto 0 do
    if AnsiLowerCase(Trim(FRecent[I])) = Key then
      FRecent.Delete(I);
  SaveRecent;
  RefreshSuggestions;
end;

procedure TSearchDialog.MruClearAll(Sender: TObject);
begin
  if not Assigned(FRecent) then Exit;
  FRecent.Clear;
  FUserCleared := True;
  SaveRecent;
  RefreshSuggestions;
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
    RememberCommand(CommandEdit.Text);
    SetBusy(True);
    Status.Caption := TrText('SearchCmd.Scanning');
    Worker.Start;
    WorkerStarted := True;
    LoadPhase := -1;
    ShowLoad(TrText('SearchCmd.ProgressListing'), True);
    Timer.Enabled := True;
  except
    on E: Exception do
    begin
      HideLoad;
      Status.Caption := TrText('SearchCmd.Failed');
      Memo.Text := E.Message;
      SetBusy(False);
    end;
  end;
end;

procedure TSearchDialog.EscapeKey(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key <> VK_ESCAPE) or (Shift <> []) then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    Key := 0;
    Exit;
  end;
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
  I: Integer;
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
      for I := High(AIWorker.Advice.Suggestions) downto 0 do
        RememberCommand(AIWorker.Advice.Suggestions[I]);
      RememberCommand(AIWorker.Advice.Command);
      Status.Caption := TrText('SearchCmd.AIReview');
    end;
    FreeAndNil(AIWorker);
    Exit;
  end;
  if not Assigned(Worker) then Exit;
  if Worker.Done = 0 then
  begin
    if LoadShown and TfrmSmoothLoading.CancelRequested and (Worker.Cancel = 0) then
    begin
      InterlockedExchange(Worker.Cancel, 1);
      Status.Caption := TrText('SearchCmd.Stopped');
    end;
    UpdateScanLoad;
    Exit;
  end;
  Timer.Enabled := False;
  Worker.WaitFor;
  HideLoad;
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
    D.FRecent := TStringList.Create;
    D.FSuggest := TStringList.Create;
    D.FSuggestNotes := TStringList.Create;
    D.FHidden := TStringList.Create;
    D.FKind := C.Kind;
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
    BidiKeepLtr(D.HitList);
    D.GroupView := TListView.Create(D);
    D.GroupView.Parent := D;
    D.GroupView.Align := alClient;
    D.GroupView.Visible := False;
    D.GroupView.ViewStyle := vsReport;
    D.GroupView.ReadOnly := True;
    D.GroupView.RowSelect := True;
    D.GroupView.HideSelection := False;
    D.GroupView.GridLines := True;
    BidiKeepLtr(D.GroupView);
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
    D.RequestEdit.Parent := Editor;
    { An empty TEdit copies Name into Text (csSetCaption). Keep the name, then clear it. }
    D.RequestEdit.Name := 'SearchAIRequest';
    D.RequestEdit.Text := '';
    D.RequestEdit.TextHint := TrText('SearchCmd.AIRequestCue');
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
    D.Suggestions.OnDropDown := D.SuggestionDropDown;
    D.Suggestions.Hint := TrText('SearchCmd.RecentHint');
    D.Suggestions.ShowHint := True;
    D.LoadRecent;
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
    BidiKeepLtr(D.CommandEdit);
    D.CommandEdit.Hint := TrText('Regex.ExamplesHint');
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
    if D.HandleAllocated then
      ReleaseMruListPopup(D.Handle);
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
