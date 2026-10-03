unit uFastFileAIScreenHelp;

{
  Modal "Talk with AI" helper for Split-by-Regex tab.
  Prompts are assembled in code (regex scope only); optional user note is appended with limits.
}

interface

uses
  uPosBMH,
  Classes;

procedure ShowFastFileAISplitRegexHelp(AOwner: TComponent;
  const ASourcePath, APattern, AExamplesText, AFileSample: string);

{ Normalize AI reply for TMemo; validate suggested regex snippets (same helpers as modal AI). }
function PrepareAiMemoText(const W: WideString): string;
function BuildAiReplyRegexValidationAppendix(const PreparedBody: string): string;

implementation

uses
  SysUtils, Windows, Messages, Forms, Controls, Dialogs, StdCtrls, ExtCtrls, Graphics,
  UnConsts, uFastFileAIClient, uI18n, uTextEncoding, uVBScriptRegex;

const
  WM_FF_AI_RESET_BUSY = WM_USER + 428;

type
  TfrmAISplitRegex = class(TForm)
    PnlTop: TPanel;
    MemoScope: TMemo;
    RgPreset: TRadioGroup;
    LblCtx: TLabel;
    MemoCtx: TMemo;
    LblNote: TLabel;
    MemoNote: TMemo;
    BtnSend: TButton;
    BtnClose: TButton;
    MemoResp: TMemo;
    LblStatus: TLabel;
  private
    FSrc: string;
    FPat: string;
    FEx: string;
    FFileSample: string;
    FBusy: Boolean;
    procedure BuildControlsForm;
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WMResetBusy(var Msg: TMessage); message WM_FF_AI_RESET_BUSY;
    procedure Setup(const Src, Pat, Ex, FileSample: string);
    function BuildPromptW: WideString;
    procedure ApplyFinished(const Ok: Boolean; const Ans: WideString; const Err: string);
  end;

  TAISplitRegexThread = class(TThread)
  private
    FOwnerDlg: TfrmAISplitRegex;
    FPrompt: WideString;
    FAns: WideString;
    FErr: string;
    FOk: Boolean;
    procedure UISync;
  protected
    procedure Execute; override;
  public
    constructor Create(ADlg: TfrmAISplitRegex; const PromptW: WideString);
  end;

function PrepareAiMemoText(const W: WideString): string;
var
  Tmp: WideString;
  i: Integer;
  U: Word;
begin
  Tmp := W;
  for i := 1 to Length(Tmp) do
  begin
    U := Word(Tmp[i]);
    { Unicode line / paragraph separator -> LF }
    if (U = $2028) or (U = $2029) then
      Tmp[i] := WideChar(10);
  end;
  Result := string(Tmp);
  if Result = '' then Exit;
  { TMemo.Lines: usar CRLF; normalizar mistura LF / CR / CRLF }
  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #10, #13#10, [rfReplaceAll]);
  { Alguns gateways devolvem \\n literal no texto depois do parse JSON }
  if (PosBMH(#10, Result) = 0) and (PosBMH(#13, Result) = 0) and (Length(Result) > 100) then
    Result := StringReplace(Result, '\' + 'n', #13#10, [rfReplaceAll]);
end;

function RegexLooksLikeEnginePattern(const S: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Trim(S) = '' then Exit;
  if (Length(S) >= 2) and (S[1] = '/') then
  begin
    Result := True;
    Exit;
  end;
  for i := 1 to Length(S) do
    if S[i] in ['\', '^', '$', '.', '*', '+', '?', '(', ')', '[', ']', '{', '}', '|'] then
    begin
      Result := True;
      Exit;
    end;
end;

function StripOuterQuotes(const S: string): string;
var
  T: string;
begin
  T := Trim(S);
  if (Length(T) >= 2) and (T[1] = '"') and (T[Length(T)] = '"') then
    Result := Trim(Copy(T, 2, Length(T) - 2))
  else if (Length(T) >= 2) and (T[1] = '''') and (T[Length(T)] = '''') then
    Result := Trim(Copy(T, 2, Length(T) - 2))
  else
    Result := T;
end;

procedure TrimLeadingMarkdownStars(var S: string);
begin
  while (Length(S) >= 2) and (S[1] = '*') and (S[2] = '*') do
    S := Trim(Copy(S, 3, MaxInt));
end;

procedure ExtractPatternAfterLabel(const Line, LowerLabel: string; ACandidates: TStringList);
var
  p: Integer;
  Rest: string;
  LowLine: string;
begin
  LowLine := LowerCase(Line);
  p := PosBMH(LowerLabel, LowLine);
  if p = 0 then Exit;
  Rest := Trim(Copy(Line, p + Length(LowerLabel), MaxInt));
  TrimLeadingMarkdownStars(Rest);
  Rest := StripOuterQuotes(Rest);
  if Rest = '' then Exit;
  if ACandidates.IndexOf(Rest) < 0 then
    ACandidates.Add(Rest);
end;

procedure ExtractBacktickPatterns(const Line: string; ACandidates: TStringList);
var
  i, j: Integer;
  Chunk: string;
begin
  i := 1;
  while i <= Length(Line) do
  begin
    if Line[i] <> '`' then
    begin
      Inc(i);
      Continue;
    end;
    j := i + 1;
    while (j <= Length(Line)) and (Line[j] <> '`') do
      Inc(j);
    if j > Length(Line) then
      Break;
    Chunk := Trim(Copy(Line, i + 1, j - i - 1));
    if RegexLooksLikeEnginePattern(Chunk) then
      if ACandidates.IndexOf(Chunk) < 0 then
        ACandidates.Add(Chunk);
    i := j + 1;
  end;
end;

procedure MaybeWholeLineSlashPattern(const Line: string; ACandidates: TStringList);
var
  T: string;
begin
  T := Trim(Line);
  if T = '' then Exit;
  if T[1] <> '/' then Exit;
  if ACandidates.IndexOf(T) < 0 then
    ACandidates.Add(T);
end;

procedure CollectRegexCandidatesFromReply(const Body: string; ACandidates: TStringList);
var
  Lines: TStringList;
  i: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Body;
    for i := 0 to Lines.Count - 1 do
    begin
      ExtractPatternAfterLabel(Lines[i], 'regex:', ACandidates);
      ExtractPatternAfterLabel(Lines[i], 'search pattern:', ACandidates);
      ExtractPatternAfterLabel(Lines[i], 'current pattern:', ACandidates);
      ExtractBacktickPatterns(Lines[i], ACandidates);
      MaybeWholeLineSlashPattern(Lines[i], ACandidates);
      if ACandidates.Count >= 48 then
        Break;
    end;
  finally
    Lines.Free;
  end;
end;

function OneLineSnippet(const S: string): string;
begin
  Result := StringReplace(StringReplace(S, #13#10, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]);
  if Length(Result) > 200 then
    Result := Copy(Result, 1, 197) + '...';
end;

function BuildAiReplyRegexValidationAppendix(const PreparedBody: string): string;
var
  Cand, PasteList, RejectList: TStringList;
  i: Integer;
  Norm, Err: string;
  SB: string;
begin
  Result := '';
  Cand := TStringList.Create;
  PasteList := TStringList.Create;
  RejectList := TStringList.Create;
  try
    CollectRegexCandidatesFromReply(PreparedBody, Cand);
    if Cand.Count = 0 then Exit;

    for i := 0 to Cand.Count - 1 do
    begin
      if TryCompileVBScriptRegexPattern(Cand[i], Norm, Err) then
      begin
        if PasteList.IndexOf(Norm) < 0 then
          PasteList.Add(Norm);
      end
      else
      begin
        if Length(Err) > 160 then
          Err := Copy(Err, 1, 157) + '...';
        RejectList.Add(OneLineSnippet(Cand[i]) + '  |  ' + Err);
      end;
    end;

    SB := '';
    if PasteList.Count > 0 then
      SB := SB + #13#10#13#10 + TrText('AI_SPLIT_VALIDATION_PASTE_HDR') + #13#10 + PasteList.Text;

    if RejectList.Count > 0 then
    begin
      if PasteList.Count = 0 then
        SB := SB + #13#10#13#10 + TrText('AI_SPLIT_VALIDATION_NONE_PASTE');
      SB := SB + #13#10 + TrText('AI_SPLIT_VALIDATION_REJECT_HDR') + #13#10;
      for i := 0 to RejectList.Count - 1 do
        SB := SB + RejectList[i] + #13#10;
    end;

    if (PasteList.Count = 0) and (RejectList.Count = 0) then
      Exit;

    Result := SB;
  finally
    RejectList.Free;
    PasteList.Free;
    Cand.Free;
  end;
end;

{ TAISplitRegexThread }

constructor TAISplitRegexThread.Create(ADlg: TfrmAISplitRegex; const PromptW: WideString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOwnerDlg := ADlg;
  FPrompt := PromptW;
end;

procedure TAISplitRegexThread.Execute;
begin
  FOk := FastFileAIInvokePrompt(FPrompt, FAns, FErr);
  Synchronize(UISync);
end;

procedure TAISplitRegexThread.UISync;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyFinished(FOk, FAns, FErr);
end;

{ TfrmAISplitRegex }

procedure TfrmAISplitRegex.BuildControlsForm;
const
  LR = 10;
  GAP = 6;
  H_SCOPE = 46;
  H_PRESET = 96;
  H_CTXMEMO = 58;
  H_NOTELBL = 26;
  H_NOTEMEMO = 42;
  H_BTN = 30;
  H_STATUS = 22;
var
  Y: Integer;
  InnerW: Integer;
begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 700;
  ClientHeight := 660;
  Constraints.MinWidth := 580;
  Constraints.MinHeight := 480;
  Font.Size := 9;

  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.BevelOuter := bvNone;
  PnlTop.Caption := '';
  PnlTop.FullRepaint := False;
  PnlTop.Color := clBtnFace;

  InnerW := ClientWidth - 2 * LR;
  Y := GAP;

  MemoScope := TMemo.Create(Self);
  MemoScope.Parent := PnlTop;
  MemoScope.Left := LR;
  MemoScope.Top := Y;
  MemoScope.Width := InnerW;
  MemoScope.Height := H_SCOPE;
  MemoScope.Anchors := [akLeft, akTop, akRight];
  MemoScope.ReadOnly := True;
  MemoScope.TabStop := False;
  MemoScope.BorderStyle := bsNone;
  MemoScope.ScrollBars := ssVertical;
  MemoScope.WordWrap := True;
  MemoScope.Color := $00EEEEEE;
  MemoScope.Font.Assign(Font);

  Inc(Y, MemoScope.Height + GAP);

  RgPreset := TRadioGroup.Create(Self);
  RgPreset.Parent := PnlTop;
  RgPreset.Left := LR;
  RgPreset.Top := Y;
  RgPreset.Width := InnerW;
  RgPreset.Height := H_PRESET;
  RgPreset.Anchors := [akLeft, akTop, akRight];
  RgPreset.Caption := '';

  Inc(Y, RgPreset.Height + GAP);

  LblCtx := TLabel.Create(Self);
  LblCtx.Parent := PnlTop;
  LblCtx.Left := LR;
  LblCtx.Top := Y;
  LblCtx.Width := InnerW;
  LblCtx.Height := 16;
  LblCtx.Anchors := [akLeft, akTop, akRight];
  LblCtx.Caption := '';
  Inc(Y, 16 + GAP div 2);

  MemoCtx := TMemo.Create(Self);
  MemoCtx.Parent := PnlTop;
  MemoCtx.Left := LR;
  MemoCtx.Top := Y;
  MemoCtx.Width := InnerW;
  MemoCtx.Height := H_CTXMEMO;
  MemoCtx.Anchors := [akLeft, akTop, akRight];
  MemoCtx.ReadOnly := True;
  MemoCtx.Color := $00F2F2F2;
  MemoCtx.ScrollBars := ssVertical;
  MemoCtx.WordWrap := False;
  Inc(Y, MemoCtx.Height + GAP);

  LblNote := TLabel.Create(Self);
  LblNote.Parent := PnlTop;
  LblNote.Left := LR;
  LblNote.Top := Y;
  LblNote.Width := InnerW;
  LblNote.Height := H_NOTELBL;
  LblNote.Anchors := [akLeft, akTop, akRight];
  LblNote.Caption := '';
  LblNote.WordWrap := True;
  Inc(Y, LblNote.Height + GAP div 2);

  MemoNote := TMemo.Create(Self);
  MemoNote.Parent := PnlTop;
  MemoNote.Left := LR;
  MemoNote.Top := Y;
  MemoNote.Width := InnerW;
  MemoNote.Height := H_NOTEMEMO;
  MemoNote.Anchors := [akLeft, akTop, akRight];
  MemoNote.ScrollBars := ssVertical;
  MemoNote.WordWrap := True;
  Inc(Y, MemoNote.Height + GAP);

  BtnSend := TButton.Create(Self);
  BtnSend.Parent := PnlTop;
  BtnSend.Left := LR;
  BtnSend.Top := Y;
  BtnSend.Height := H_BTN;
  BtnSend.Width := 132;
  BtnSend.Caption := TrText('Send');
  BtnSend.OnClick := BtnSendClick;

  BtnClose := TButton.Create(Self);
  BtnClose.Parent := PnlTop;
  BtnClose.Left := PnlTop.ClientWidth - LR - 92;
  BtnClose.Top := Y;
  BtnClose.Height := H_BTN;
  BtnClose.Width := 92;
  BtnClose.Anchors := [akTop, akRight];
  BtnClose.Caption := TrText('Close');
  BtnClose.Cancel := True;
  BtnClose.OnClick := BtnCloseClick;

  Inc(Y, H_BTN + GAP);

  LblStatus := TLabel.Create(Self);
  LblStatus.Parent := PnlTop;
  LblStatus.Left := LR;
  LblStatus.Top := Y;
  LblStatus.Width := InnerW;
  LblStatus.Height := H_STATUS;
  LblStatus.Anchors := [akLeft, akTop, akRight];
  LblStatus.Caption := '';
  LblStatus.WordWrap := True;

  Inc(Y, LblStatus.Height + GAP);
  PnlTop.Height := Y;

  MemoResp := TMemo.Create(Self);
  MemoResp.Parent := Self;
  MemoResp.Align := alClient;
  MemoResp.ReadOnly := True;
  MemoResp.ScrollBars := ssBoth;
  MemoResp.WordWrap := True;
  MemoResp.Color := clWindow;
  MemoResp.Font.Assign(Font);
  MemoResp.SendToBack;

  OnCloseQuery := FormCloseQuery;
end;

procedure TfrmAISplitRegex.Setup(const Src, Pat, Ex, FileSample: string);
const
  CTX_HALF = FASTFILE_AI_MAX_CONTEXT_CHARS div 2;
begin
  FSrc := Src;
  FPat := Pat;
  FEx := Ex;
  FFileSample := FileSample;
  Caption := TrText('AI help - Regex split');
  MemoScope.Text := TrText('AI_SPLIT_SCOPE');
  RgPreset.Items.Clear;
  RgPreset.Items.Add(TrText('AI_SPLIT_PRESET_1'));
  RgPreset.Items.Add(TrText('AI_SPLIT_PRESET_2'));
  RgPreset.Items.Add(TrText('AI_SPLIT_PRESET_3'));
  RgPreset.ItemIndex := 0;
  LblCtx.Caption := TrText('AI_SPLIT_CONTEXT_LABEL');
  MemoCtx.Text := TrText('Source file:') + ' ' + FSrc + #13#10#13#10;
  if Trim(FFileSample) <> '' then
  begin
    MemoCtx.Text := MemoCtx.Text +
      TrText('Sample lines from file (dynamic — changes when you pick another file):') + #13#10 +
      Utf8HeuristicToDisplayString(Copy(FFileSample, 1, CTX_HALF));
    if Length(FFileSample) > CTX_HALF then
      MemoCtx.Text := MemoCtx.Text + #13#10 + TrText('AI_SPLIT_TRUNCATED');
    MemoCtx.Text := MemoCtx.Text + #13#10#13#10;
  end;
  MemoCtx.Text := MemoCtx.Text +
    TrText('FastFile auto-generated regex examples (dynamic — from file content):') + #13#10 +
    Utf8HeuristicToDisplayString(Copy(FEx, 1, CTX_HALF));
  if Length(FEx) > CTX_HALF then
    MemoCtx.Text := MemoCtx.Text + #13#10 + TrText('AI_SPLIT_TRUNCATED');
  MemoCtx.SelStart := 0;
  LblNote.Caption := Format(TrText('AI_SPLIT_NOTE_HINT'), [FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS]);
  MemoNote.Text := '';
  MemoResp.Text := '';
  LblStatus.Caption := '';
end;

function TfrmAISplitRegex.BuildPromptW: WideString;
const
  PROMPT_HALF = FASTFILE_AI_MAX_CONTEXT_CHARS div 2;
var
  Note, Excerpt, SampleTxt, TaskBody, HeaderBlock: string;
  PresetIdx: Integer;
  ReplyLine: WideString;
begin
  PresetIdx := RgPreset.ItemIndex;
  if PresetIdx < 0 then PresetIdx := 0;
  Note := Trim(MemoNote.Text);
  SampleTxt := Trim(FFileSample);
  if Length(SampleTxt) > PROMPT_HALF then
    SampleTxt := Copy(SampleTxt, 1, PROMPT_HALF) + #13#10 + TrText('AI_PROMPT_CTX_TRUNCATED');
  Excerpt := FEx;
  if Length(Excerpt) > PROMPT_HALF then
    Excerpt := Copy(Excerpt, 1, PROMPT_HALF) + #13#10 + TrText('AI_PROMPT_CTX_TRUNCATED');

  case PresetIdx of
    0: TaskBody := TrText('AI_PROMPT_TASK_0');
    1: TaskBody := TrText('AI_PROMPT_TASK_1');
    2: TaskBody := TrText('AI_PROMPT_TASK_2');
  else
    TaskBody := '';
  end;

  ReplyLine := WideString(TrText('AI_PROMPT_REPLY_LANG'));

  HeaderBlock :=
    TrText('AI_PROMPT_HEADER') + #13#10 +
    TrText('AI_PROMPT_RULES_P1') + #13#10 +
    TrText('AI_PROMPT_RULES_P2') + #13#10 +
    TrText('AI_PROMPT_RULES_P3') + #13#10#13#10;

  Result := WideString(HeaderBlock) + ReplyLine + WideString(#13#10#13#10 +
    TrText('AI_PROMPT_HDR_TASK') + #13#10 + TaskBody + #13#10#13#10 +
    TrText('AI_PROMPT_HDR_SOURCE') + #13#10 + FSrc + #13#10#13#10);
  if SampleTxt <> '' then
    Result := Result + WideString(TrText('Sample lines (raw, from current file):') + #13#10 +
      SampleTxt + #13#10#13#10);
  Result := Result + WideString(
    TrText('AI_PROMPT_HDR_PATTERN') + #13#10 + FPat + #13#10#13#10 +
    TrText('AI_PROMPT_HDR_EXAMPLES') + #13#10 +
    Excerpt + #13#10);

  if PresetIdx = 2 then
    Result := Result + WideString(#13#10 + TrText('AI_PROMPT_HDR_FOCUS_Q') + #13#10 + Note + #13#10)
  else if Note <> '' then
    Result := Result + WideString(#13#10 + TrText('AI_PROMPT_HDR_OPT_NOTE') + #13#10 + Note + #13#10);
end;

procedure TfrmAISplitRegex.BtnSendClick(Sender: TObject);
var
  W: WideString;
begin
  if FBusy then Exit;
  if RgPreset.ItemIndex = 2 then
  begin
    if Length(Trim(MemoNote.Text)) < FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS then
    begin
      MessageDlg(Format(TrText('AI_SPLIT_NOTE_REQUIRED'), [FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS]),
        mtInformation, [mbOk], 0);
      Exit;
    end;
  end;

  W := BuildPromptW;
  MemoResp.Text := '';
  LblStatus.Caption := TrText('AI_SPLIT_CONTACTING');
  FBusy := True;
  BtnSend.Enabled := False;
  BtnClose.Enabled := False;
  MemoNote.Enabled := False;
  RgPreset.Enabled := False;
  Application.ProcessMessages;

  TAISplitRegexThread.Create(Self, W).Resume;
end;

procedure TfrmAISplitRegex.ApplyFinished(const Ok: Boolean; const Ans: WideString; const Err: string);
var
  Prepared: string;
begin
  if Ok then
  begin
    MemoResp.Lines.BeginUpdate;
    try
      Prepared := PrepareAiMemoText(Ans);
      MemoResp.Lines.Text := Prepared + BuildAiReplyRegexValidationAppendix(Prepared);
      MemoResp.SelStart := 0;
    finally
      MemoResp.Lines.EndUpdate;
    end;
  end
  else
  begin
    if Trim(Err) = '' then
      MemoResp.Text := TrText('AI_SPLIT_FAILED_UNKNOWN')
    else
      MemoResp.Text := Format(TrText('AI_SPLIT_FAILED'), [Err]);
  end;
  LblStatus.Caption := TrText('AI_SPLIT_FINISHED');
  PostMessage(Handle, WM_FF_AI_RESET_BUSY, 0, 0);
end;

procedure TfrmAISplitRegex.WMResetBusy(var Msg: TMessage);
begin
  FBusy := False;
  BtnSend.Enabled := True;
  BtnClose.Enabled := True;
  MemoNote.Enabled := True;
  RgPreset.Enabled := True;
end;

procedure TfrmAISplitRegex.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmAISplitRegex.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    MessageDlg(TrText('AI_SPLIT_WAIT_CLOSE'), mtInformation, [mbOk], 0);
    CanClose := False;
  end
  else
    CanClose := True;
end;

procedure ShowFastFileAISplitRegexHelp(AOwner: TComponent;
  const ASourcePath, APattern, AExamplesText, AFileSample: string);
var
  F: TfrmAISplitRegex;
begin
  F := TfrmAISplitRegex.CreateNew(AOwner);
  try
    F.BuildControlsForm;
    F.Setup(ASourcePath, APattern, AExamplesText, AFileSample);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
