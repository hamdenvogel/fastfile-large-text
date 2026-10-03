unit uFastFileAIPythonMacroHelp;

{
  Modal "Talk with AI" for Tail macro and Script Engine Python panels.
  Same gateway as Regex split (FastFileAIInvokePrompt); scope limited to transform(line, ctx).
}

interface

uses
  Classes, StdCtrls;

type
  TFastFilePythonMacroAIKind = (pyaiTail, pyaiScript);

procedure ShowFastFileAIPythonMacroHelp(AOwner: TComponent; AKind: TFastFilePythonMacroAIKind;
  const ASourcePath, ACurrentScript, AExamplesText, AFileSample: string;
  ATargetEditor: TMemo);

{ Corrige corpo de transform sem indentacao (erro comum apos colar da IA). }
function EnsurePythonTransformIndent(const Src: string): string;

{ Garante import re (etc.) quando o script usa o modulo sem importar. }
function EnsurePythonStdImports(const Src: string): string;

implementation

uses
  SysUtils, Windows, Messages, Forms, Controls, Dialogs, ExtCtrls, Graphics,
  Menus, Clipbrd,
  UnConsts, uPosBMH, uFastFileAIClient, uFastFileAIScreenHelp, uI18n, uTextEncoding;

const
  WM_FF_PYAI_RESET_BUSY = WM_USER + 429;
  WM_FF_PYAI_FOCUS_NOTE = WM_USER + 430;

type
  TfrmAIPythonMacro = class(TForm)
    PnlTop: TPanel;
    MemoScope: TMemo;
    LblCtx: TLabel;
    MemoCtx: TMemo;
    LblNote: TLabel;
    MemoNote: TMemo;
    BtnSend: TButton;
    BtnPaste: TButton;
    BtnCopy: TButton;
    BtnClose: TButton;
    MemoResp: TMemo;
    LblStatus: TLabel;
    PnlBtns: TPanel;
    PopResp: TPopupMenu;
  private
    FKind: TFastFilePythonMacroAIKind;
    FSrc: string;
    FScript: string;
    FEx: string;
    FFileSample: string;
    FTargetEditor: TMemo;
    FBusy: Boolean;
    FLastPrepared: string;
    FLastUserNote: string;
    procedure BuildControlsForm;
    procedure LayoutTopStack;
    procedure RecalcTopPanelHeight;
    procedure FormResize(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure BtnPasteClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure PopCopyClick(Sender: TObject);
    procedure PopSelectAllClick(Sender: TObject);
    procedure UpdateActionButtons;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure WMResetBusy(var Msg: TMessage); message WM_FF_PYAI_RESET_BUSY;
    procedure WMFocusNote(var Msg: TMessage); message WM_FF_PYAI_FOCUS_NOTE;
    procedure Setup(const Src, CurScript, Ex, FileSample: string; AEditor: TMemo);
    function BuildPromptW: WideString;
    procedure ApplyFinished(const Ok: Boolean; const Ans: WideString; const Err: string);
    procedure AdjustStatusLabelHeight;
    procedure AdjustNoteLabelHeight;
    function ExtractPythonForEditor(const Body: string): string;
    procedure MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WireMemoShortcuts;
  end;

  TAIPythonMacroThread = class(TThread)
  private
    FOwnerDlg: TfrmAIPythonMacro;
    FPrompt: WideString;
    FAns: WideString;
    FErr: string;
    FOk: Boolean;
    procedure UISync;
  protected
    procedure Execute; override;
  public
    constructor Create(ADlg: TfrmAIPythonMacro; const PromptW: WideString);
  end;

function TrimmedLineForFenceCheck(const S: string): string;
var
  T: string;
begin
  T := Trim(S);
  while (Length(T) >= 3) and (Copy(T, 1, 3) = '```') do
  begin
    Delete(T, 1, 3);
    T := Trim(T);
    if (Length(T) >= 6) and (LowerCase(Copy(T, 1, 6)) = 'python') then
      T := Trim(Copy(T, 7, MaxInt));
  end;
  Result := T;
end;

function StripFenceMarkersFromLine(const S: string): string;
var
  Lead, T: string;
  I: Integer;
begin
  Lead := '';
  for I := 1 to Length(S) do
    if S[I] in [' ', #9] then
      Lead := Lead + S[I]
    else
      Break;
  T := Copy(S, Length(Lead) + 1, MaxInt);
  while (Length(T) >= 3) and (Copy(T, 1, 3) = '```') do
  begin
    Delete(T, 1, 3);
    while (Length(T) > 0) and (T[1] in [' ', #9]) do
      Delete(T, 1, 1);
    if (Length(T) >= 6) and (LowerCase(Copy(T, 1, 6)) = 'python') then
      Delete(T, 1, 6);
    while (Length(T) > 0) and (T[1] in [' ', #9]) do
      Delete(T, 1, 1);
  end;
  Result := Lead + T;
end;

function LineHasTransformDef(const S: string): Boolean;
begin
  Result := PosBMH('def transform', LowerCase(TrimmedLineForFenceCheck(S))) > 0;
end;

function LineStopsPythonExtract(const S: string): Boolean;
var
  L: string;
begin
  L := LowerCase(TrimmedLineForFenceCheck(S));
  if L = '' then
  begin
    Result := False;
    Exit;
  end;
  Result := (L = '```') or BMHStartsWith('```', L) or
    BMHStartsWith('# teste', L) or BMHStartsWith('# test', L) or
    BMHStartsWith('# print(', L) or BMHStartsWith('print(transform', L) or
    BMHStartsWith('if __name__', L) or BMHStartsWith('--- tarefa', L) or
    BMHStartsWith('--- task', L);
end;

function DedupeRepeatedUserText(const S: string): string;
var
  T, Half: string;
  L, H: Integer;
begin
  Result := Trim(S);
  if Result = '' then Exit;
  T := Result;
  L := Length(T);
  if L < 16 then Exit;
  H := L div 2;
  Half := Trim(Copy(T, 1, H));
  if SameText(Half, Trim(Copy(T, H + 1, MaxInt))) then
    Result := Half
  else if (L >= 32) and (Copy(T, 1, H) = Copy(T, H + 1, H)) then
    Result := Trim(Copy(T, 1, H));
end;

function LineLooksLikeFileDataRow(const S: string): Boolean;
var
  T, U: string;
  HashCount, I, Digitish: Integer;
  C: Char;
begin
  Result := False;
  T := Trim(S);
  if T = '' then Exit;
  U := UpperCase(T);
  if PosBMH('DEF TRANSFORM', U) > 0 then Exit;
  if PosBMH('```', T) > 0 then Exit;
  if BMHStartsWith('IMPORT ', U) or BMHStartsWith('FROM ', U) then Exit;
  if (PosBMH('RETURN ', U) > 0) or (T[1] = ' ') or (T[1] = #9) then Exit;
  if (Length(T) >= 4) and (U[1] = 'L') and (T[2] >= '0') and (T[2] <= '9') and (T[3] = ':') then
  begin
    Result := True;
    Exit;
  end;
  HashCount := 0;
  Digitish := 0;
  for I := 1 to Length(T) do
  begin
    C := T[I];
    if C = '#' then Inc(HashCount);
    if C in ['0'..'9', '#', ';', '.', ' '] then Inc(Digitish);
  end;
  if (HashCount >= 6) and (Length(T) > 50) and (Digitish * 100 div Length(T) > 75) then
  begin
    Result := True;
    Exit;
  end;
  if (Length(T) >= 40) and (Digitish * 100 div Length(T) > 88) then
    Result := True;
end;

function LineLooksLikeAiProse(const S: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := Trim(S);
  if L = '' then Exit;
  if PosBMH('def transform', LowerCase(L)) > 0 then Exit;
  if BMHStartsWith('import ', LowerCase(L)) or BMHStartsWith('from ', LowerCase(L)) then Exit;
  if Copy(L, 1, 3) = '```' then Exit;
  if (L[1] = ' ') or (L[1] = #9) then Exit;
  if BMHStartsWith('return ', LowerCase(L)) then Exit;
  Result := Length(L) > 12;
end;

function LineLooksLikeWrongAiSnippet(const S: string): Boolean;
var
  L: string;
begin
  Result := False;
  { Linhas indentadas fazem parte do corpo de transform — nao apagar return line[:N]. }
  if (Length(S) > 0) and ((S[1] = ' ') or (S[1] = #9)) then Exit;
  L := LowerCase(Trim(S));
  if L = '' then Exit;
  Result := BMHStartsWith('return line[:', L) or BMHStartsWith('return line[', L) or
    (PosBMH('values = [line[i]', L) > 0) or (PosBMH('range(1, 7)', L) > 0) or
    (PosBMH('range(1,7)', L) > 0);
end;

function StripMarkdownFences(const Body: string): string;
var
  SL: TStringList;
  I: Integer;
  L: string;
begin
  Result := Trim(Body);
  if Result = '' then Exit;
  SL := TStringList.Create;
  try
    SL.Text := Result;
    for I := SL.Count - 1 downto 0 do
    begin
      L := Trim(SL[I]);
      if (Copy(L, 1, 3) = '```') then
        SL.Delete(I);
    end;
    Result := Trim(SL.Text);
  finally
    SL.Free;
  end;
end;

function LooksLikePythonSnippet(const S: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(S));
  Result := (L <> '') and (
    (PosBMH('return ', L) > 0) or (PosBMH('return(', L) > 0) or
    BMHStartsWith('import ', L) or BMHStartsWith('from ', L) or
    BMHStartsWith('if ', L) or BMHStartsWith('for ', L) or
    BMHStartsWith('while ', L) or BMHStartsWith('try:', L) or
    BMHStartsWith('with ', L) or (PosBMH('line[', L) > 0) or
    (PosBMH('line.', L) > 0) or (PosBMH('def ', L) > 0));
end;

function WrapAsTransformDef(const Body: string): string;
var
  Inner: string;
  SL: TStringList;
  I: Integer;
  L: string;
begin
  Inner := StripMarkdownFences(Body);
  if Trim(Inner) = '' then
  begin
    Result := '';
    Exit;
  end;
  if PosBMH('def transform', LowerCase(Inner)) > 0 then
  begin
    Result := Inner;
    Exit;
  end;
  if not LooksLikePythonSnippet(Inner) then
  begin
    Result := '';
    Exit;
  end;
  SL := TStringList.Create;
  try
    SL.Text := Inner;
    Result := 'def transform(line, ctx):';
    for I := 0 to SL.Count - 1 do
    begin
      L := SL[I];
      if Trim(L) = '' then
        Result := Result + #13#10
      else if (L[1] = ' ') or (L[1] = #9) then
        Result := Result + #13#10 + L
      else
        Result := Result + #13#10 + '    ' + L;
    end;
  finally
    SL.Free;
  end;
end;

function SummarizeFileSampleForAIPrompt(const RawSample: string): string;
var
  SL: TStringList;
  I, LineLen, J, HashCnt: Integer;
  L, Preview, HStr: string;
  HasHash: Boolean;
begin
  Result := Trim(RawSample);
  if Result = '' then Exit;
  SL := TStringList.Create;
  try
    SL.Text := Result;
    Result := '';
    for I := 0 to SL.Count - 1 do
    begin
      L := Trim(SL[I]);
      if L = '' then Continue;
      if (Length(L) > 3) and (UpCase(L[1]) = 'L') and (L[2] >= '0') and (L[2] <= '9') and (L[3] = ':') then
        L := Trim(Copy(L, 4, MaxInt));
      LineLen := Length(L);
      HashCnt := 0;
      for J := 1 to LineLen do
        if L[J] = '#' then Inc(HashCnt);
      HasHash := HashCnt > 0;
      if LineLen > 48 then
        Preview := Copy(L, 1, 48) + '...'
      else
        Preview := L;
      if HasHash then HStr := 'true' else HStr := 'false';
      if Result <> '' then Result := Result + #13#10;
      Result := Result + Format('line_%d: len=%d, hash_count=%d, preview="%s"',
        [I + 1, LineLen, HashCnt, Preview]);
    end;
    if Result = '' then
      Result := '(empty sample)';
  finally
    SL.Free;
  end;
end;

function UserRequestsKeepOnlyCharsFilter(const Note: string): Boolean;
var
  N: string;
begin
  N := LowerCase(Note);
  Result := ((PosBMH('numeric', N) > 0) or (PosBMH('numer', N) > 0) or (PosBMH('digit', N) > 0) or
    (PosBMH('numero', N) > 0) or (PosBMH('cifra', N) > 0) or (PosBMH('somente', N) > 0) or
    (PosBMH('apenas', N) > 0) or (PosBMH('extraia', N) > 0) or (PosBMH('extrair', N) > 0)) and
    ((PosBMH('#', Note) > 0) or (PosBMH('cerquilha', N) > 0) or (PosBMH('hash', N) > 0)) and
    ((PosBMH(';', Note) > 0) or (PosBMH('ponto-v', N) > 0) or (PosBMH('ponto v', N) > 0) or
     (PosBMH('semicolon', N) > 0) or (PosBMH('vírgula', N) > 0) or (PosBMH('virgula', N) > 0));
end;

function PythonMacroHasCharFilterSolution(const Code: string): Boolean;
begin
  Result := (PosBMH('re.sub', LowerCase(Code)) > 0) or
    (PosBMH('[^0-9;#]', Code) > 0) or (PosBMH('[^0-9;#]', LowerCase(Code)) > 0);
end;

function CanonicalCharFilterMacroScript: string;
begin
  Result :=
    'import re' + #13#10#13#10 +
    'def transform(line, ctx):' + #13#10 +
    '    return re.sub(r''[^0-9;#]'', '''', line)';
end;

function CleanPythonMacroAIResponse(const Body: string): string;
var
  SL: TStringList;
  I: Integer;
  Cleaned: string;
  HasDef: Boolean;
begin
  Result := StripMarkdownFences(Body);
  if Trim(Result) = '' then Exit;
  HasDef := PosBMH('def transform', LowerCase(Result)) > 0;
  SL := TStringList.Create;
  try
    SL.Text := Result;
    for I := SL.Count - 1 downto 0 do
      if LineLooksLikeFileDataRow(SL[I]) or LineLooksLikeAiProse(SL[I]) or
         (HasDef and LineLooksLikeWrongAiSnippet(SL[I])) then
        SL.Delete(I);
    Cleaned := Trim(SL.Text);
    { Se a limpeza removeu quase tudo (ex.: so ficou ```), manter o corpo original. }
    if Cleaned = '' then
    begin
      if HasDef then
        Result := StripMarkdownFences(Body)
      else
        Result := Cleaned;
    end
    else
      Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function ApplyCharFilterFallbackIfNeeded(const Body, UserNote: string): string;
begin
  Result := Body;
  if not UserRequestsKeepOnlyCharsFilter(UserNote) then Exit;
  if PythonMacroHasCharFilterSolution(Body) then Exit;
  Result := '```python' + #13#10 + CanonicalCharFilterMacroScript + #13#10 + '```';
end;

function SanitizeSourcePathForDisplay(const S: string): string;
begin
  Result := Trim(S);
  while (Length(Result) > 0) and (Result[1] in ['"', '''']) do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] in ['"', '''']) do
    Delete(Result, Length(Result), 1);
end;

function TfrmAIPythonMacro.ExtractPythonForEditor(const Body: string): string;
var
  SL: TStringList;
  I, DefIdx, EndIdx, PDef: Integer;
  L: string;
begin
  Result := '';
  if Trim(Body) = '' then Exit;
  SL := TStringList.Create;
  try
    SL.Text := Body;
    DefIdx := -1;
    for I := 0 to SL.Count - 1 do
      if LineHasTransformDef(SL[I]) then
      begin
        DefIdx := I;
        Break;
      end;
    if DefIdx < 0 then
    begin
      PDef := PosBMH('def transform', LowerCase(Body));
      if PDef <= 0 then
      begin
        { IA devolveu so o corpo (ex.: return line[:5]) — embrulhar em transform. }
        Result := WrapAsTransformDef(Body);
        Exit;
      end;
      SL.Text := Copy(Body, PDef, MaxInt);
      DefIdx := 0;
    end;
    EndIdx := SL.Count - 1;
    for I := DefIdx + 1 to SL.Count - 1 do
      if LineStopsPythonExtract(SL[I]) or LineLooksLikeFileDataRow(SL[I]) or
         LineLooksLikeAiProse(SL[I]) or LineLooksLikeWrongAiSnippet(SL[I]) then
      begin
        EndIdx := I - 1;
        Break;
      end;
    for I := DefIdx to EndIdx do
    begin
      L := StripFenceMarkersFromLine(SL[I]);
      if Trim(L) = '' then Continue;
      if (Copy(L, 1, 3) = '```') and (PosBMH('def transform', LowerCase(L)) = 0) then Continue;
      if Result <> '' then Result := Result + #13#10;
      Result := Result + L;
    end;
    Result := Trim(Result);
    if PosBMH('def transform', LowerCase(Result)) > 1 then
    begin
      Delete(Result, 1, PosBMH('def transform', LowerCase(Result)) - 1);
      Result := Trim(Result);
    end;
  finally
    SL.Free;
  end;
end;

function EnsurePythonStdImports(const Src: string): string;
var
  SL: TStringList;
  I: Integer;
  L, Lower: string;
  NeedsRe: Boolean;
begin
  Result := Src;
  if Trim(Result) = '' then Exit;
  NeedsRe := (PosBMH('re.', Result) > 0) or (PosBMH('re.sub', LowerCase(Result)) > 0) or
    (PosBMH('re.match', LowerCase(Result)) > 0) or (PosBMH('re.search', LowerCase(Result)) > 0);
  if not NeedsRe then Exit;
  SL := TStringList.Create;
  try
    SL.Text := Src;
    for I := SL.Count - 1 downto 0 do
    begin
      L := Trim(SL[I]);
      Lower := LowerCase(L);
      if (Lower = 'import re') or (Lower = 'from re import') or
         (Copy(Lower, 1, 9) = 'import re') then
        SL.Delete(I);
    end;
    Result := 'import re' + #13#10#13#10 + SL.Text;
  finally
    SL.Free;
  end;
end;

function EnsurePythonTransformIndent(const Src: string): string;
var
  SL: TStringList;
  I, DefIdx: Integer;
  L: string;
  NeedFix: Boolean;
begin
  Result := Src;
  if Trim(Src) = '' then Exit;
  SL := TStringList.Create;
  try
    SL.Text := Src;
    DefIdx := -1;
    for I := 0 to SL.Count - 1 do
      if PosBMH('def transform', LowerCase(Trim(SL[I]))) > 0 then
      begin
        DefIdx := I;
        Break;
      end;
    if DefIdx < 0 then Exit;
    NeedFix := False;
    for I := DefIdx + 1 to SL.Count - 1 do
    begin
      L := SL[I];
      if Trim(L) = '' then Continue;
      if (L[1] <> ' ') and (L[1] <> #9) then
      begin
        NeedFix := True;
        Break;
      end;
    end;
    if not NeedFix then Exit;
    for I := DefIdx + 1 to SL.Count - 1 do
    begin
      L := SL[I];
      if Trim(L) = '' then Continue;
      if (L[1] <> ' ') and (L[1] <> #9) then
        SL[I] := '    ' + L;
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ TAIPythonMacroThread }

constructor TAIPythonMacroThread.Create(ADlg: TfrmAIPythonMacro; const PromptW: WideString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOwnerDlg := ADlg;
  FPrompt := PromptW;
end;

procedure TAIPythonMacroThread.Execute;
begin
  FOk := FastFileAIInvokePrompt(FPrompt, FAns, FErr);
  Synchronize(UISync);
end;

procedure TAIPythonMacroThread.UISync;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyFinished(FOk, FAns, FErr);
end;

{ TfrmAIPythonMacro }

procedure TfrmAIPythonMacro.BuildControlsForm;
const
  H_BTN = 30;
  H_BTNPANEL = 36;
var
  MI: TMenuItem;
begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Scaled := False;
  ClientWidth := 720;
  ClientHeight := 640;
  Constraints.MinWidth := 560;
  Constraints.MinHeight := 480;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  DoubleBuffered := True;

  { Response first (alClient); top panel fixed height via LayoutTopStack (no Align stack). }
  MemoResp := TMemo.Create(Self);
  MemoResp.Parent := Self;
  MemoResp.Align := alClient;
  MemoResp.ReadOnly := True;
  MemoResp.HideSelection := False;
  MemoResp.WantReturns := True;
  MemoResp.ScrollBars := ssBoth;
  MemoResp.WordWrap := True;
  MemoResp.Font.Name := 'Consolas';
  MemoResp.Font.Size := 9;

  PopResp := TPopupMenu.Create(Self);
  MI := TMenuItem.Create(PopResp);
  MI.Caption := TrText('Copy');
  MI.ShortCut := Menus.ShortCut(Ord('C'), [ssCtrl]);
  MI.OnClick := PopCopyClick;
  PopResp.Items.Add(MI);
  MI := TMenuItem.Create(PopResp);
  MI.Caption := TrText('Select All');
  MI.ShortCut := Menus.ShortCut(Ord('A'), [ssCtrl]);
  MI.OnClick := PopSelectAllClick;
  PopResp.Items.Add(MI);
  MemoResp.PopupMenu := PopResp;

  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.BevelOuter := bvNone;
  PnlTop.Caption := '';
  PnlTop.ParentBackground := False;
  PnlTop.ParentColor := False;
  PnlTop.Color := clBtnFace;
  PnlTop.DoubleBuffered := True;

  MemoScope := TMemo.Create(Self);
  MemoScope.Parent := PnlTop;
  MemoScope.Align := alNone;
  MemoScope.ReadOnly := True;
  MemoScope.TabStop := False;
  MemoScope.BorderStyle := bsNone;
  MemoScope.ScrollBars := ssVertical;
  MemoScope.WordWrap := True;
  MemoScope.Color := $00EEEEEE;
  MemoScope.HideSelection := False;
  MemoScope.PopupMenu := PopResp;

  LblCtx := TLabel.Create(Self);
  LblCtx.Parent := PnlTop;
  LblCtx.Align := alNone;
  LblCtx.AutoSize := False;
  LblCtx.Height := 18;
  LblCtx.Layout := tlCenter;
  LblCtx.Transparent := False;
  LblCtx.ParentColor := True;

  MemoCtx := TMemo.Create(Self);
  MemoCtx.Parent := PnlTop;
  MemoCtx.Align := alNone;
  MemoCtx.ReadOnly := True;
  MemoCtx.Color := $00F2F2F2;
  MemoCtx.ScrollBars := ssVertical;
  MemoCtx.WordWrap := False;
  MemoCtx.HideSelection := False;
  MemoCtx.PopupMenu := PopResp;

  LblNote := TLabel.Create(Self);
  LblNote.Parent := PnlTop;
  LblNote.Align := alNone;
  LblNote.AutoSize := False;
  LblNote.Height := 40;
  LblNote.WordWrap := True;
  LblNote.Transparent := False;
  LblNote.ParentColor := True;

  MemoNote := TMemo.Create(Self);
  MemoNote.Parent := PnlTop;
  MemoNote.Align := alNone;
  MemoNote.ScrollBars := ssVertical;
  MemoNote.WordWrap := True;
  MemoNote.TabStop := True;
  MemoNote.HideSelection := False;
  MemoNote.PopupMenu := PopResp;

  PnlBtns := TPanel.Create(Self);
  PnlBtns.Parent := PnlTop;
  PnlBtns.Align := alNone;
  PnlBtns.Height := H_BTNPANEL;
  PnlBtns.BevelOuter := bvNone;
  PnlBtns.Caption := '';
  PnlBtns.ParentBackground := False;
  PnlBtns.ParentColor := False;
  PnlBtns.Color := clBtnFace;

  BtnSend := TButton.Create(Self);
  BtnSend.Parent := PnlBtns;
  BtnSend.Left := 0;
  BtnSend.Top := (H_BTNPANEL - H_BTN) div 2;
  BtnSend.Height := H_BTN;
  BtnSend.Width := 110;
  BtnSend.Caption := TrText('Send');
  BtnSend.OnClick := BtnSendClick;

  BtnPaste := TButton.Create(Self);
  BtnPaste.Parent := PnlBtns;
  BtnPaste.Left := 118;
  BtnPaste.Top := BtnSend.Top;
  BtnPaste.Height := H_BTN;
  BtnPaste.Width := 180;
  BtnPaste.Enabled := False;
  BtnPaste.Caption := TrText('AI_PY_MACRO_PASTE_BTN');
  BtnPaste.OnClick := BtnPasteClick;

  BtnCopy := TButton.Create(Self);
  BtnCopy.Parent := PnlBtns;
  BtnCopy.Left := 306;
  BtnCopy.Top := BtnSend.Top;
  BtnCopy.Height := H_BTN;
  BtnCopy.Width := 80;
  BtnCopy.Enabled := False;
  BtnCopy.Caption := TrText('Copy');
  BtnCopy.OnClick := BtnCopyClick;

  BtnClose := TButton.Create(Self);
  BtnClose.Parent := PnlBtns;
  BtnClose.Top := BtnSend.Top;
  BtnClose.Height := H_BTN;
  BtnClose.Width := 92;
  BtnClose.Caption := TrText('Close');
  BtnClose.Cancel := True;
  BtnClose.OnClick := BtnCloseClick;

  LblStatus := TLabel.Create(Self);
  LblStatus.Parent := PnlTop;
  LblStatus.Align := alNone;
  LblStatus.AutoSize := False;
  LblStatus.Height := 20;
  LblStatus.WordWrap := True;
  LblStatus.Transparent := False;
  LblStatus.ParentColor := True;

  LayoutTopStack;

  OnShow := FormShow;
  OnResize := FormResize;
  OnCloseQuery := FormCloseQuery;
  WireMemoShortcuts;
end;

procedure TfrmAIPythonMacro.LayoutTopStack;
const
  LR = 10;
  GAP = 6;
  H_SCOPE = 48;
  H_CTXMEMO = 96;
  H_NOTEMEMO = 64;
  H_BTNPANEL = 36;
var
  Y, InnerW: Integer;
begin
  if not Assigned(PnlTop) then Exit;
  InnerW := PnlTop.ClientWidth - (LR * 2);
  if InnerW < 120 then InnerW := 120;
  Y := GAP;

  if Assigned(MemoScope) then
  begin
    MemoScope.SetBounds(LR, Y, InnerW, H_SCOPE);
    Inc(Y, H_SCOPE + GAP);
  end;
  if Assigned(LblCtx) then
  begin
    LblCtx.SetBounds(LR, Y, InnerW, 18);
    Inc(Y, 18 + 2);
  end;
  if Assigned(MemoCtx) then
  begin
    MemoCtx.SetBounds(LR, Y, InnerW, H_CTXMEMO);
    Inc(Y, H_CTXMEMO + GAP);
  end;
  if Assigned(LblNote) then
  begin
    if LblNote.Height < 36 then LblNote.Height := 36;
    LblNote.SetBounds(LR, Y, InnerW, LblNote.Height);
    Inc(Y, LblNote.Height + 2);
  end;
  if Assigned(MemoNote) then
  begin
    MemoNote.SetBounds(LR, Y, InnerW, H_NOTEMEMO);
    Inc(Y, H_NOTEMEMO + GAP);
  end;
  if Assigned(PnlBtns) then
  begin
    PnlBtns.SetBounds(LR, Y, InnerW, H_BTNPANEL);
    if Assigned(BtnClose) then
    begin
      BtnClose.Left := PnlBtns.ClientWidth - BtnClose.Width;
      if Assigned(BtnCopy) and (BtnClose.Left < BtnCopy.Left + BtnCopy.Width + 8) then
        BtnClose.Left := BtnCopy.Left + BtnCopy.Width + 8
      else if Assigned(BtnPaste) and (BtnClose.Left < BtnPaste.Left + BtnPaste.Width + 8) then
        BtnClose.Left := BtnPaste.Left + BtnPaste.Width + 8;
    end;
    Inc(Y, H_BTNPANEL + 2);
  end;
  if Assigned(LblStatus) then
  begin
    if LblStatus.Height < 18 then LblStatus.Height := 18;
    LblStatus.SetBounds(LR, Y, InnerW, LblStatus.Height);
    Inc(Y, LblStatus.Height + GAP);
  end;

  if Y < 220 then Y := 220;
  PnlTop.Height := Y;
end;

procedure TfrmAIPythonMacro.RecalcTopPanelHeight;
begin
  LayoutTopStack;
end;

procedure TfrmAIPythonMacro.FormResize(Sender: TObject);
begin
  LayoutTopStack;
end;

procedure TfrmAIPythonMacro.FormShow(Sender: TObject);
begin
  LayoutTopStack;
  { Defer focus until the modal is fully visible (avoids EInvalidOperation when
    ListView/panels are hidden and Setup/ShowModal timing differs). }
  PostMessage(Handle, WM_FF_PYAI_FOCUS_NOTE, 0, 0);
end;

procedure TfrmAIPythonMacro.WMFocusNote(var Msg: TMessage);
begin
  if (not Visible) or (not Enabled) then Exit;
  if not Assigned(MemoNote) or (not MemoNote.Visible) or (not MemoNote.Enabled) then Exit;
  try
    if MemoNote.CanFocus then
      MemoNote.SetFocus;
  except
    on E: EInvalidOperation do ;
  end;
end;

procedure TfrmAIPythonMacro.WireMemoShortcuts;
begin
  if Assigned(MemoScope) then MemoScope.OnKeyDown := MemoKeyDown;
  if Assigned(MemoCtx) then MemoCtx.OnKeyDown := MemoKeyDown;
  if Assigned(MemoNote) then MemoNote.OnKeyDown := MemoKeyDown;
  if Assigned(MemoResp) then MemoResp.OnKeyDown := MemoKeyDown;
end;

procedure TfrmAIPythonMacro.MemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  M: TMemo;
  H: HWND;
begin
  if not (Sender is TMemo) then Exit;
  M := TMemo(Sender);
  if not M.HandleAllocated then Exit;
  H := M.Handle;

  { Ctrl+C / Ctrl+Insert: copy selection }
  if (((ssCtrl in Shift) and not (ssAlt in Shift) and (Key = Ord('C'))) or
      ((Key = VK_INSERT) and (Shift = [ssCtrl]))) then
  begin
    SendMessage(H, WM_COPY, 0, 0);
    Key := 0;
    Exit;
  end;

  { Ctrl+V / Shift+Insert: paste (MemoNote only; readonly memos stay read-only) }
  if (((ssCtrl in Shift) and not (ssAlt in Shift) and (Key = Ord('V'))) or
      ((Key = VK_INSERT) and (Shift = [ssShift]))) then
  begin
    if M.ReadOnly then
    begin
      Key := 0;
      Exit;
    end;
    SendMessage(H, WM_PASTE, 0, 0);
    Key := 0;
    Exit;
  end;

  { Ctrl+X: cut (editable memo only) }
  if (ssCtrl in Shift) and not (ssAlt in Shift) and (Key = Ord('X')) then
  begin
    if not M.ReadOnly then
      SendMessage(H, WM_CUT, 0, 0);
    Key := 0;
    Exit;
  end;

  { Ctrl+A / Ctrl+T: select all }
  if (ssCtrl in Shift) and not (ssAlt in Shift) and
     ((Key = Ord('A')) or (Key = Ord('T'))) then
  begin
    SendMessage(H, EM_SETSEL, 0, LPARAM(-1));
    Key := 0;
    Exit;
  end;

  { Esc: close when not waiting for AI }
  if (Key = VK_ESCAPE) and not FBusy then
  begin
    Close;
    Key := 0;
  end;
end;

procedure TfrmAIPythonMacro.Setup(const Src, CurScript, Ex, FileSample: string;
  AEditor: TMemo);
const
  CTX_HALF = FASTFILE_AI_MAX_CONTEXT_CHARS div 2;
begin
  FSrc := SanitizeSourcePathForDisplay(Src);
  FScript := CurScript;
  FEx := Ex;
  FFileSample := FileSample;
  FTargetEditor := AEditor;
  FLastPrepared := '';

  if FKind = pyaiTail then
  begin
    Caption := TrText('AI_PY_HELP_TITLE_TAIL');
    MemoScope.Text := TrText('AI_PY_MACRO_SCOPE_TAIL');
  end
  else
  begin
    Caption := TrText('AI_PY_HELP_TITLE_SCRIPT');
    MemoScope.Text := TrText('AI_PY_MACRO_SCOPE_SCRIPT');
  end;

  LblCtx.Caption := TrText('AI_PY_MACRO_CTX_LABEL');
  MemoCtx.Text := TrText('Source file:') + ' ' + FSrc + #13#10#13#10;
  if Trim(FFileSample) <> '' then
  begin
    MemoCtx.Text := MemoCtx.Text +
      TrText('AI_PY_PROMPT_HDR_SAMPLE') + #13#10 +
      Utf8HeuristicToDisplayString(Copy(FFileSample, 1, CTX_HALF));
    if Length(FFileSample) > CTX_HALF then
      MemoCtx.Text := MemoCtx.Text + #13#10 + TrText('AI_SPLIT_TRUNCATED');
    MemoCtx.Text := MemoCtx.Text + #13#10#13#10;
  end;
  if Trim(FScript) <> '' then
  begin
    MemoCtx.Text := MemoCtx.Text +
      TrText('AI_PY_MACRO_HDR_SCRIPT') + #13#10 +
      Utf8HeuristicToDisplayString(Copy(FScript, 1, CTX_HALF));
    if Length(FScript) > CTX_HALF then
      MemoCtx.Text := MemoCtx.Text + #13#10 + TrText('AI_SPLIT_TRUNCATED');
    MemoCtx.Text := MemoCtx.Text + #13#10#13#10;
  end;
  if Trim(FEx) <> '' then
  begin
    MemoCtx.Text := MemoCtx.Text +
      TrText('AI_PY_MACRO_HDR_EXAMPLES') + #13#10 +
      Utf8HeuristicToDisplayString(Copy(FEx, 1, CTX_HALF));
    if Length(FEx) > CTX_HALF then
      MemoCtx.Text := MemoCtx.Text + #13#10 + TrText('AI_SPLIT_TRUNCATED');
  end;
  MemoCtx.SelStart := 0;

  LblNote.Caption := Format(TrText('AI_PY_MACRO_NOTE_HINT'),
    [FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS]);
  AdjustNoteLabelHeight;
  MemoNote.Text := '';
  MemoResp.Text := '';
  LblStatus.Caption := '';
  AdjustStatusLabelHeight;
  BtnPaste.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  RecalcTopPanelHeight;
end;

function TfrmAIPythonMacro.BuildPromptW: WideString;
const
  PROMPT_HALF = FASTFILE_AI_MAX_CONTEXT_CHARS div 2;
var
  Note, SampleTxt, Excerpt, TaskBody, HeaderBlock, FilterMandate: string;
  ReplyLine: WideString;
begin
  Note := DedupeRepeatedUserText(MemoNote.Text);
  SampleTxt := SummarizeFileSampleForAIPrompt(Trim(FFileSample));
  if Length(SampleTxt) > PROMPT_HALF then
    SampleTxt := Copy(SampleTxt, 1, PROMPT_HALF) + #13#10 + TrText('AI_PROMPT_CTX_TRUNCATED');
  Excerpt := FEx;
  if Length(Excerpt) > PROMPT_HALF then
    Excerpt := Copy(Excerpt, 1, PROMPT_HALF) + #13#10 + TrText('AI_PROMPT_CTX_TRUNCATED');

  if FKind = pyaiTail then
    TaskBody := TrText('AI_PY_PROMPT_TASK_TAIL')
  else
    TaskBody := TrText('AI_PY_PROMPT_TASK_SCRIPT');

  ReplyLine := WideString(TrText('AI_PROMPT_REPLY_LANG'));

  HeaderBlock :=
    TrText('AI_PY_PROMPT_HEADER') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P1') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P2') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P3') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P4') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P5') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P6') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P7') + #13#10#13#10;

  FilterMandate := '';
  if UserRequestsKeepOnlyCharsFilter(Note) then
    FilterMandate := TrText('AI_PY_PROMPT_FILTER_MANDATE') + #13#10#13#10;

  Result := WideString(HeaderBlock) + WideString(FilterMandate) + ReplyLine + WideString(#13#10#13#10 +
    TrText('AI_PROMPT_HDR_TASK') + #13#10 + TaskBody + #13#10#13#10 +
    TrText('AI_PROMPT_HDR_SOURCE') + #13#10 + FSrc + #13#10#13#10);
  if SampleTxt <> '' then
    Result := Result + WideString(TrText('AI_PY_PROMPT_HDR_SAMPLE') + #13#10 +
      SampleTxt + #13#10#13#10);
  if Trim(FScript) <> '' then
    Result := Result + WideString(
      TrText('AI_PY_MACRO_HDR_SCRIPT') + #13#10 +
      Copy(FScript, 1, PROMPT_HALF) + #13#10#13#10);
  if Excerpt <> '' then
    Result := Result + WideString(
      TrText('AI_PY_MACRO_HDR_EXAMPLES') + #13#10 + Excerpt + #13#10#13#10);
  Result := Result + WideString(
    TrText('AI_PY_MACRO_HDR_FOCUS') + #13#10 + Note + #13#10#13#10 +
    TrText('AI_PY_PROMPT_RULES_P5') + #13#10);
end;

procedure TfrmAIPythonMacro.BtnSendClick(Sender: TObject);
var
  W: WideString;
begin
  if FBusy then Exit;
  if Length(Trim(MemoNote.Text)) < FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS then
  begin
    MessageDlg(Format(TrText('AI_PY_MACRO_NOTE_REQUIRED'),
      [FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS]), mtInformation, [mbOk], 0);
    Exit;
  end;

  FLastUserNote := MemoNote.Text;
  W := BuildPromptW;
  MemoResp.Text := '';
  FLastPrepared := '';
  BtnPaste.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  LblStatus.Caption := TrText('AI_PY_MACRO_CONTACTING');
  AdjustStatusLabelHeight;
  FBusy := True;
  BtnSend.Enabled := False;
  BtnPaste.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  BtnClose.Enabled := False;
  MemoNote.Enabled := False;
  Application.ProcessMessages;

  TAIPythonMacroThread.Create(Self, W).Resume;
end;

procedure TfrmAIPythonMacro.ApplyFinished(const Ok: Boolean; const Ans: WideString;
  const Err: string);
begin
  if Ok then
  begin
    FLastPrepared := ApplyCharFilterFallbackIfNeeded(
      CleanPythonMacroAIResponse(PrepareAiMemoText(Ans)), FLastUserNote);
    FLastPrepared := StripMarkdownFences(FLastPrepared);
    if Trim(FLastPrepared) = '' then
      FLastPrepared := StripMarkdownFences(PrepareAiMemoText(Ans));
    MemoResp.Lines.BeginUpdate;
    try
      MemoResp.Lines.Text := FLastPrepared;
      MemoResp.SelStart := 0;
      MemoResp.SelLength := Length(MemoResp.Text);
    finally
      MemoResp.Lines.EndUpdate;
    end;
  end
  else
  begin
    FLastPrepared := '';
    if Trim(Err) = '' then
      MemoResp.Text := TrText('AI_PY_MACRO_FAILED_UNKNOWN')
    else
      MemoResp.Text := Format(TrText('AI_PY_MACRO_FAILED'), [Err]);
  end;
  LblStatus.Caption := TrText('AI_PY_MACRO_FINISHED');
  AdjustStatusLabelHeight;
  UpdateActionButtons;
  PostMessage(Handle, WM_FF_PYAI_RESET_BUSY, 0, 0);
end;

procedure TfrmAIPythonMacro.AdjustStatusLabelHeight;
var
  R: TRect;
  H: Integer;
begin
  if not Assigned(LblStatus) then Exit;
  if Trim(LblStatus.Caption) = '' then
  begin
    LblStatus.Height := 18;
    RecalcTopPanelHeight;
    Exit;
  end;
  R := Rect(0, 0, LblStatus.ClientWidth, 0);
  if R.Right < 1 then R.Right := 1;
  LblStatus.Canvas.Font := LblStatus.Font;
  H := DrawText(LblStatus.Canvas.Handle, PChar(LblStatus.Caption), -1, R,
    DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
  if H < 18 then H := 18;
  if H > 64 then H := 64;
  LblStatus.Height := H;
  RecalcTopPanelHeight;
end;

procedure TfrmAIPythonMacro.AdjustNoteLabelHeight;
var
  R: TRect;
  H: Integer;
begin
  if not Assigned(LblNote) then Exit;
  if Trim(LblNote.Caption) = '' then Exit;
  R := Rect(0, 0, LblNote.ClientWidth, 0);
  if R.Right < 200 then
    R.Right := ClientWidth - 24;
  LblNote.Canvas.Font := LblNote.Font;
  H := DrawText(LblNote.Canvas.Handle, PChar(LblNote.Caption), -1, R,
    DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
  if H < 36 then H := 36;
  if H > 88 then H := 88;
  LblNote.Height := H;
  RecalcTopPanelHeight;
end;

procedure TfrmAIPythonMacro.UpdateActionButtons;
var
  HasCode, HasText: Boolean;
begin
  HasCode := Trim(ExtractPythonForEditor(FLastPrepared)) <> '';
  if not HasCode then
    HasCode := Trim(ExtractPythonForEditor(MemoResp.Text)) <> '';
  HasText := Trim(MemoResp.Text) <> '';
  if Assigned(BtnPaste) then
    BtnPaste.Enabled := Assigned(FTargetEditor) and HasCode and (not FBusy);
  if Assigned(BtnCopy) then
    BtnCopy.Enabled := HasText and (not FBusy);
end;

procedure TfrmAIPythonMacro.BtnCopyClick(Sender: TObject);
begin
  if not Assigned(MemoResp) then Exit;
  if Trim(MemoResp.Text) = '' then Exit;
  if MemoResp.SelLength = 0 then
    MemoResp.SelectAll;
  MemoResp.CopyToClipboard;
end;

procedure TfrmAIPythonMacro.PopCopyClick(Sender: TObject);
var
  M: TMemo;
begin
  M := nil;
  if Assigned(PopResp) and (PopResp.PopupComponent is TMemo) then
    M := TMemo(PopResp.PopupComponent)
  else if Assigned(MemoResp) then
    M := MemoResp;
  if not Assigned(M) then Exit;
  if M.SelLength = 0 then
    M.SelectAll;
  M.CopyToClipboard;
end;

procedure TfrmAIPythonMacro.PopSelectAllClick(Sender: TObject);
var
  M: TMemo;
begin
  M := nil;
  if Assigned(PopResp) and (PopResp.PopupComponent is TMemo) then
    M := TMemo(PopResp.PopupComponent)
  else if Assigned(MemoResp) then
    M := MemoResp;
  if Assigned(M) then
    M.SelectAll;
end;

procedure TfrmAIPythonMacro.BtnPasteClick(Sender: TObject);
var
  Code: string;
begin
  if not Assigned(FTargetEditor) then Exit;
  Code := ExtractPythonForEditor(FLastPrepared);
  if Trim(Code) = '' then
    Code := ExtractPythonForEditor(MemoResp.Text);
  if Trim(Code) = '' then
  begin
    MessageDlg(TrText('AI_PY_MACRO_PASTE_EMPTY'), mtInformation, [mbOk], 0);
    Exit;
  end;
  if UserRequestsKeepOnlyCharsFilter(FLastUserNote) and
     not PythonMacroHasCharFilterSolution(Code) then
    Code := CanonicalCharFilterMacroScript;
  Code := EnsurePythonStdImports(EnsurePythonTransformIndent(Code));
  FTargetEditor.Lines.BeginUpdate;
  try
    FTargetEditor.Lines.Text := Code;
    FTargetEditor.Modified := True;
  finally
    FTargetEditor.Lines.EndUpdate;
  end;
  try
    if FTargetEditor.CanFocus then
      FTargetEditor.SetFocus;
  except
    on E: EInvalidOperation do ;
  end;
end;

procedure TfrmAIPythonMacro.WMResetBusy(var Msg: TMessage);
begin
  FBusy := False;
  BtnSend.Enabled := True;
  BtnClose.Enabled := True;
  MemoNote.Enabled := True;
  UpdateActionButtons;
end;

procedure TfrmAIPythonMacro.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmAIPythonMacro.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    MessageDlg(TrText('AI_PY_MACRO_WAIT_CLOSE'), mtInformation, [mbOk], 0);
    CanClose := False;
  end
  else
    CanClose := True;
end;

procedure ShowFastFileAIPythonMacroHelp(AOwner: TComponent; AKind: TFastFilePythonMacroAIKind;
  const ASourcePath, ACurrentScript, AExamplesText, AFileSample: string;
  ATargetEditor: TMemo);
var
  F: TfrmAIPythonMacro;
begin
  F := TfrmAIPythonMacro.CreateNew(AOwner);
  try
    F.FKind := AKind;
    F.BuildControlsForm;
    F.Setup(ASourcePath, ACurrentScript, AExamplesText, AFileSample, ATargetEditor);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
