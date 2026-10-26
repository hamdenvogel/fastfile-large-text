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
  Menus, Clipbrd, Math, Types,
  UnConsts, uPosBMH, uFastFileAIClient, uFastFileAIScreenHelp, uI18n, uTextEncoding,
  uFastFilePaths, uUserPrefs, uMruFind, UnitPopupMruList, uFastFileScale, uSmoothLoading;

const
  WM_FF_PYAI_RESET_BUSY = WM_USER + 429;
  WM_FF_PYAI_FOCUS_NOTE = WM_USER + 430;
  PYAI_RECENT_FILE = 'PyMacroAIRecent.txt';
  PYAI_CLR_HEADER = $00FAF3EC;
  PYAI_CLR_ACCENT = $00703C10;
  PYAI_CLR_CODEBG = $00FBFBFB;
  PYAI_UNDO_MAX = 100;
  PYAI_TYPING_MERGE_MS = 1000;

type
  TPyAiUndoAction = (pyuTyping, pyuMru, pyuResponse, pyuPaste);

  TPyAiUndoState = record
    Action: TPyAiUndoAction;
    Note: string;
    NoteSel: Integer;
    Resp: string;
    Prepared: string;
    UserNote: string;
    HasEditor: Boolean;
    Editor: string;
    EditorModified: Boolean;
  end;

  TfrmAIPythonMacro = class(TForm)
    PnlTop: TPanel;
    PnlHeader: TPanel;
    LblTitle: TLabel;
    LblScope: TLabel;
    LblCtx: TLabel;
    MemoCtx: TMemo;
    LblNoteTitle: TLabel;
    LblNote: TLabel;
    MemoNote: TMemo;
    BtnNoteMru: TButton;
    BtnSend: TButton;
    BtnPaste: TButton;
    BtnApplyClose: TButton;
    BtnCopy: TButton;
    BtnUndo: TButton;
    BtnRedo: TButton;
    BtnClose: TButton;
    LblResp: TLabel;
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
    FRecent: TStringList;
    FUndo: TArray<TPyAiUndoState>;
    FRedo: TArray<TPyAiUndoState>;
    FRestoring: Boolean;
    FNoteShadow: string;
    FNoteShadowSel: Integer;
    FLastTypingTick: Cardinal;
    FSendState: TPyAiUndoState;
    FWaitTimer: TTimer;
    FWaitStart: Cardinal;
    FThread: TThread;
    FThreadAlive: Boolean;
    FIgnoreReply: Boolean;
    procedure StartAIWait;
    procedure StopAIWait;
    procedure WaitTimerTick(Sender: TObject);
    procedure CancelAIWait;
    function CaptureState(AAction: TPyAiUndoAction; AWithEditor: Boolean): TPyAiUndoState;
    procedure RestoreState(const AState: TPyAiUndoState);
    procedure PushUndo(const AState: TPyAiUndoState);
    procedure DoUndo;
    procedure DoRedo;
    procedure UpdateUndoButtons;
    procedure SyncNoteShadow;
    function UndoActionText(AAction: TPyAiUndoAction): string;
    procedure MemoNoteChange(Sender: TObject);
    procedure BtnUndoClick(Sender: TObject);
    procedure BtnRedoClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure LoadRecent;
    procedure SaveRecent;
    procedure RememberRequest(const S: string);
    procedure NoteMruClick(Sender: TObject);
    procedure NoteMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure NoteMruRemove(Sender: TObject; const AValue: string);
    procedure NoteMruClearAll(Sender: TObject);
    function MakeSectionLabel(const ACaption: string): TLabel;
    function ButtonWidthFor(AButton: TButton): Integer;
    procedure BuildControlsForm;
    procedure LayoutTopStack;
    procedure RecalcTopPanelHeight;
    procedure FormResize(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure BtnPasteClick(Sender: TObject);
    procedure BtnApplyCloseClick(Sender: TObject);
    function ApplyToEditor: Boolean;
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
    function TextLineHeight: Integer;
    function ExtractPythonForEditor(const Body: string): string;
    procedure MemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WireMemoShortcuts;
  public
    destructor Destroy; override;
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
  if (S <> '') and ((S[1] = ' ') or (S[1] = #9)) then Exit;
  T := Trim(S);
  if T = '' then Exit;
  U := UpperCase(T);
  if PosBMH('DEF TRANSFORM', U) > 0 then Exit;
  if PosBMH('```', T) > 0 then Exit;
  if BMHStartsWith('IMPORT ', U) or BMHStartsWith('FROM ', U) then Exit;
  if PosBMH('RETURN ', U) > 0 then Exit;
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

{ Linha de codigo Python de nivel superior (import, def, constante, decorador, comentario...). }
function LineLooksLikeTopLevelPython(const L: string): Boolean;
var
  Low: string;
  I: Integer;
begin
  Low := LowerCase(L);
  Result := BMHStartsWith('import ', Low) or BMHStartsWith('from ', Low) or
    BMHStartsWith('def ', Low) or BMHStartsWith('class ', Low) or
    BMHStartsWith('@', Low) or BMHStartsWith('#', Low) or
    BMHStartsWith('return ', Low) or BMHStartsWith('if ', Low) or
    BMHStartsWith('for ', Low) or BMHStartsWith('while ', Low) or
    BMHStartsWith('try:', Low) or BMHStartsWith('with ', Low);
  if Result then Exit;
  { NOME = valor / NOME: tipo = valor }
  I := 1;
  while (I <= Length(L)) and CharInSet(L[I], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Inc(I);
  if I > 1 then
  begin
    while (I <= Length(L)) and (L[I] = ' ') do Inc(I);
    Result := (I <= Length(L)) and CharInSet(L[I], ['=', ':', '[', '.', '(']) and
      not ((I < Length(L)) and (L[I] = ':') and (L[I + 1] = ' ') and (Pos('=', L) = 0));
  end;
end;

function LineLooksLikeAiProse(const S: string): Boolean;
var
  L: string;
begin
  Result := False;
  { Linhas indentadas sao corpo de funcao: nunca prosa. }
  if (S <> '') and ((S[1] = ' ') or (S[1] = #9)) then Exit;
  L := Trim(S);
  if L = '' then Exit;
  if Copy(L, 1, 3) = '```' then Exit;
  if LineLooksLikeTopLevelPython(L) then Exit;
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

function UserAskedForSeparator(const Note: string): Boolean;
const
  WORDS: array[0..14] of string = ('espa', 'space', 'separ', 'virgul', 'vírgul', 'comma', 'coma',
    'tab', 'delimit', 'join', 'csv', 'entre cada', 'between each', 'leerzeichen', 'ponto e v');
var
  N: string;
  I: Integer;
begin
  N := LowerCase(Note);
  Result := False;
  for I := Low(WORDS) to High(WORDS) do
    if Pos(WORDS[I], N) > 0 then
      Exit(True);
end;

{ IA costuma devolver " ".join(...) por conta propria; sem pedido de separador, juntar sem espacos. }
function DropUnrequestedJoinSeparator(const Code, UserNote: string): string;
begin
  Result := Code;
  if UserAskedForSeparator(UserNote) then Exit;
  Result := StringReplace(Result, '" ".join(', '"".join(', [rfReplaceAll]);
  Result := StringReplace(Result, ''' ''.join(', '''''.join(', [rfReplaceAll]);
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
    { Incluir imports / constantes / helpers logo acima do def transform. }
    while DefIdx > 0 do
    begin
      L := SL[DefIdx - 1];
      if (Trim(L) <> '') and
         (LineStopsPythonExtract(L) or LineLooksLikeFileDataRow(L) or LineLooksLikeAiProse(L)) then
        Break;
      Dec(DefIdx);
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

function TfrmAIPythonMacro.MakeSectionLabel(const ACaption: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := PnlTop;
  Result.AutoSize := False;
  Result.Layout := tlBottom;
  Result.Transparent := True;
  Result.Font.Style := [fsBold];
  Result.Font.Color := PYAI_CLR_ACCENT;
  Result.Caption := ACaption;
end;

function TfrmAIPythonMacro.ButtonWidthFor(AButton: TButton): Integer;
begin
  Canvas.Font := Font;
  Result := Max(FfPx(96), Canvas.TextWidth(StripHotkey(AButton.Caption)) + FfPx(36));
end;

procedure TfrmAIPythonMacro.BuildControlsForm;
var
  MI: TMenuItem;
begin
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Position := poScreenCenter;
  Scaled := False;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  ClientWidth := FfPx(900);
  ClientHeight := FfPx(740);
  Constraints.MinWidth := FfPx(840);
  Constraints.MinHeight := FfPx(560);
  DoubleBuffered := True;

  FRecent := TStringList.Create;
  LoadRecent;

  { Response first (alClient); top panel fixed height via LayoutTopStack (no Align stack). }
  MemoResp := TMemo.Create(Self);
  MemoResp.Parent := Self;
  MemoResp.Align := alClient;
  MemoResp.AlignWithMargins := True;
  MemoResp.Margins.SetBounds(FfPx(14), 0, FfPx(14), FfPx(14));
  MemoResp.ReadOnly := True;
  MemoResp.HideSelection := False;
  MemoResp.WantReturns := True;
  MemoResp.ScrollBars := ssBoth;
  MemoResp.WordWrap := False;
  MemoResp.Color := PYAI_CLR_CODEBG;
  MemoResp.Font.Name := 'Consolas';
  MemoResp.Font.Size := 10;

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

  PnlHeader := TPanel.Create(Self);
  PnlHeader.Parent := PnlTop;
  PnlHeader.BevelOuter := bvNone;
  PnlHeader.Caption := '';
  PnlHeader.ParentBackground := False;
  PnlHeader.Color := PYAI_CLR_HEADER;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent := PnlHeader;
  LblTitle.AutoSize := False;
  LblTitle.Transparent := True;
  LblTitle.Font.Size := 13;
  LblTitle.Font.Style := [fsBold];
  LblTitle.Font.Color := PYAI_CLR_ACCENT;

  LblScope := TLabel.Create(Self);
  LblScope.Parent := PnlHeader;
  LblScope.AutoSize := False;
  LblScope.WordWrap := True;
  LblScope.Transparent := True;
  LblScope.Font.Color := clGrayText;

  LblCtx := MakeSectionLabel('');

  MemoCtx := TMemo.Create(Self);
  MemoCtx.Parent := PnlTop;
  MemoCtx.ReadOnly := True;
  MemoCtx.Color := PYAI_CLR_CODEBG;
  MemoCtx.Font.Name := 'Consolas';
  MemoCtx.Font.Size := 9;
  MemoCtx.ScrollBars := ssBoth;
  MemoCtx.WordWrap := False;
  MemoCtx.HideSelection := False;
  MemoCtx.PopupMenu := PopResp;

  LblNoteTitle := MakeSectionLabel('');

  LblNote := TLabel.Create(Self);
  LblNote.Parent := PnlTop;
  LblNote.AutoSize := False;
  LblNote.WordWrap := True;
  LblNote.Transparent := True;
  LblNote.Font.Color := clGrayText;

  MemoNote := TMemo.Create(Self);
  MemoNote.Parent := PnlTop;
  MemoNote.ScrollBars := ssVertical;
  MemoNote.WordWrap := True;
  MemoNote.TabStop := True;
  MemoNote.HideSelection := False;
  MemoNote.PopupMenu := PopResp;

  BtnNoteMru := TButton.Create(Self);
  BtnNoteMru.Parent := PnlTop;
  BtnNoteMru.Caption := #$25BC;
  BtnNoteMru.Hint := TrText('Extract.AI.RecentHint');
  BtnNoteMru.ShowHint := True;
  BtnNoteMru.TabStop := False;
  BtnNoteMru.OnClick := NoteMruClick;

  PnlBtns := TPanel.Create(Self);
  PnlBtns.Parent := PnlTop;
  PnlBtns.BevelOuter := bvNone;
  PnlBtns.Caption := '';
  PnlBtns.ParentBackground := False;
  PnlBtns.ParentColor := False;
  PnlBtns.Color := clBtnFace;

  BtnSend := TButton.Create(Self);
  BtnSend.Parent := PnlBtns;
  BtnSend.Caption := TrText('Send');
  BtnSend.Hint := 'Ctrl+Enter';
  BtnSend.ShowHint := True;
  BtnSend.Default := True;
  BtnSend.Font.Style := [fsBold];
  BtnSend.OnClick := BtnSendClick;

  BtnPaste := TButton.Create(Self);
  BtnPaste.Parent := PnlBtns;
  BtnPaste.Enabled := False;
  if Assigned(BtnApplyClose) then BtnApplyClose.Enabled := False;
  BtnPaste.Caption := TrText('AI_PY_MACRO_APPLY');
  BtnPaste.Hint := TrText('AI_PY_MACRO_APPLY_HINT');
  BtnPaste.ShowHint := True;
  BtnPaste.OnClick := BtnPasteClick;

  BtnApplyClose := TButton.Create(Self);
  BtnApplyClose.Parent := PnlBtns;
  BtnApplyClose.Enabled := False;
  BtnApplyClose.Caption := TrText('AI_PY_MACRO_APPLY_CLOSE');
  BtnApplyClose.Hint := TrText('AI_PY_MACRO_APPLY_CLOSE_HINT');
  BtnApplyClose.ShowHint := True;
  BtnApplyClose.OnClick := BtnApplyCloseClick;

  BtnCopy := TButton.Create(Self);
  BtnCopy.Parent := PnlBtns;
  BtnCopy.Enabled := False;
  BtnCopy.Caption := TrText('Copy');
  BtnCopy.OnClick := BtnCopyClick;

  BtnUndo := TButton.Create(Self);
  BtnUndo.Parent := PnlBtns;
  BtnUndo.Enabled := False;
  BtnUndo.Caption := #$21B6 + ' ' + TrText('AI_PY_MACRO_UNDO');
  BtnUndo.Hint := TrText('AI_PY_MACRO_UNDO_HINT');
  BtnUndo.ShowHint := True;
  BtnUndo.OnClick := BtnUndoClick;

  BtnRedo := TButton.Create(Self);
  BtnRedo.Parent := PnlBtns;
  BtnRedo.Enabled := False;
  BtnRedo.Caption := #$21B7 + ' ' + TrText('AI_PY_MACRO_REDO');
  BtnRedo.Hint := TrText('AI_PY_MACRO_REDO_HINT');
  BtnRedo.ShowHint := True;
  BtnRedo.OnClick := BtnRedoClick;

  BtnClose := TButton.Create(Self);
  BtnClose.Parent := PnlBtns;
  BtnClose.Caption := TrText('Close');
  BtnClose.Cancel := True;
  BtnClose.OnClick := BtnCloseClick;

  LblStatus := TLabel.Create(Self);
  LblStatus.Parent := PnlTop;
  LblStatus.AutoSize := False;
  LblStatus.WordWrap := True;
  LblStatus.Transparent := True;
  LblStatus.Font.Color := clGrayText;

  LblResp := MakeSectionLabel('');

  LayoutTopStack;

  OnShow := FormShow;
  OnResize := FormResize;
  OnCloseQuery := FormCloseQuery;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnKeyPress := FormKeyPress;
  MemoNote.OnChange := MemoNoteChange;
  WireMemoShortcuts;
end;

procedure TfrmAIPythonMacro.LayoutTopStack;
var
  Y, X, LR, Gap, InnerW, LineH, CodeLineH, HdrH, BtnH, MruW, R: Integer;

  function WrappedHeight(ALabel: TLabel; AWidth, AMinLines: Integer): Integer;
  var
    Rc: TRect;
  begin
    Result := LineH * AMinLines;
    if (ALabel.Caption = '') or (AWidth < 1) then Exit;
    Canvas.Font := ALabel.Font;
    Rc := Rect(0, 0, AWidth, 0);
    DrawText(Canvas.Handle, PChar(ALabel.Caption), -1, Rc,
      DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
    Result := Max(Result, Rc.Bottom + 2);
  end;

  function CodeLineHeight: Integer;
  begin
    Canvas.Font := MemoCtx.Font;
    Result := Canvas.TextHeight('Ay');
  end;

begin
  if not Assigned(PnlTop) or not Assigned(LblResp) then Exit;
  LR := FfPx(14);
  Gap := FfPx(8);
  LineH := TextLineHeight;
  CodeLineH := CodeLineHeight;
  BtnH := LineH + FfPx(14);
  InnerW := Max(FfPx(120), PnlTop.ClientWidth - (LR * 2));

  { Cabecalho colorido: titulo + escopo. }
  Canvas.Font := LblTitle.Font;
  HdrH := Canvas.TextHeight('Ay');
  LblTitle.SetBounds(LR, FfPx(10), InnerW, HdrH + 2);
  Y := LblTitle.Top + LblTitle.Height + FfPx(2);
  LblScope.SetBounds(LR, Y, InnerW, WrappedHeight(LblScope, InnerW, 1));
  Inc(Y, LblScope.Height + FfPx(10));
  PnlHeader.SetBounds(0, 0, PnlTop.ClientWidth, Y);
  Inc(Y, Gap);

  LblCtx.SetBounds(LR, Y, InnerW, LineH + FfPx(4));
  Inc(Y, LblCtx.Height + FfPx(3));
  MemoCtx.SetBounds(LR, Y, InnerW, CodeLineH * 6 + GetSystemMetrics(SM_CYHSCROLL) + FfPx(8));
  Inc(Y, MemoCtx.Height + Gap + FfPx(4));

  LblNoteTitle.SetBounds(LR, Y, InnerW, LineH + FfPx(4));
  Inc(Y, LblNoteTitle.Height + FfPx(1));
  LblNote.SetBounds(LR, Y, InnerW, WrappedHeight(LblNote, InnerW, 1));
  Inc(Y, LblNote.Height + FfPx(3));
  MruW := FfPx(28);
  MemoNote.SetBounds(LR, Y, InnerW - MruW - FfPx(4), LineH * 3 + FfPx(10));
  BtnNoteMru.SetBounds(LR + InnerW - MruW, Y, MruW, MemoNote.Height);
  Inc(Y, MemoNote.Height + Gap);

  PnlBtns.SetBounds(LR, Y, InnerW, BtnH);
  X := 0;
  BtnSend.SetBounds(X, 0, ButtonWidthFor(BtnSend) + FfPx(16), BtnH);
  Inc(X, BtnSend.Width + FfPx(8));
  BtnCopy.SetBounds(X, 0, ButtonWidthFor(BtnCopy), BtnH);
  Inc(X, BtnCopy.Width + FfPx(16));
  BtnUndo.SetBounds(X, 0, ButtonWidthFor(BtnUndo), BtnH);
  Inc(X, BtnUndo.Width + FfPx(4));
  BtnRedo.SetBounds(X, 0, ButtonWidthFor(BtnRedo), BtnH);
  Inc(X, BtnRedo.Width + FfPx(16));
  { Grupo da direita, como no Eclipse: Aplicar | Aplicar e fechar | Fechar. }
  R := Max(X, PnlBtns.ClientWidth - ButtonWidthFor(BtnPaste) - ButtonWidthFor(BtnApplyClose) -
    ButtonWidthFor(BtnClose) - FfPx(8) * 2);
  BtnPaste.SetBounds(R, 0, ButtonWidthFor(BtnPaste), BtnH);
  Inc(R, BtnPaste.Width + FfPx(8));
  BtnApplyClose.SetBounds(R, 0, ButtonWidthFor(BtnApplyClose), BtnH);
  Inc(R, BtnApplyClose.Width + FfPx(8));
  BtnClose.SetBounds(R, 0, ButtonWidthFor(BtnClose), BtnH);
  Inc(Y, BtnH + FfPx(4));

  LblStatus.SetBounds(LR, Y, InnerW, WrappedHeight(LblStatus, InnerW, 1));
  Inc(Y, LblStatus.Height + FfPx(2));

  LblResp.SetBounds(LR, Y, InnerW, LineH + FfPx(4));
  Inc(Y, LblResp.Height + FfPx(3));

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

  if M = MemoNote then
  begin
    { Ctrl+Enter: enviar. F4 / Alt+Seta para baixo: pedidos recentes. }
    if (Key = VK_RETURN) and (ssCtrl in Shift) then
    begin
      Key := 0;
      if BtnSend.Enabled then
        BtnSendClick(BtnSend);
      Exit;
    end;
    if ((Key = VK_F4) and (Shift = [])) or ((Key = VK_DOWN) and (Shift = [ssAlt])) then
    begin
      Key := 0;
      NoteMruClick(BtnNoteMru);
      Exit;
    end;
  end;

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
    LblScope.Caption := TrText('AI_PY_MACRO_SCOPE_TAIL');
  end
  else
  begin
    Caption := TrText('AI_PY_HELP_TITLE_SCRIPT');
    LblScope.Caption := TrText('AI_PY_MACRO_SCOPE_SCRIPT');
  end;
  LblTitle.Caption := Caption;

  LblCtx.Caption := '1. ' + TrText('AI_PY_MACRO_CTX_LABEL');
  LblNoteTitle.Caption := '2. ' + TrText('AI_PY_MACRO_NOTE_TITLE');
  LblResp.Caption := '3. ' + TrText('AI_PY_MACRO_RESP_LABEL');
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
  if Assigned(BtnApplyClose) then BtnApplyClose.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  SetLength(FUndo, 0);
  SetLength(FRedo, 0);
  SyncNoteShadow;
  UpdateUndoButtons;
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
    TrText('AI_PY_PROMPT_RULES_P7') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P8') + #13#10#13#10;

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
    TrText('AI_PY_PROMPT_RULES_P5') + #13#10 +
    TrText('AI_PY_PROMPT_RULES_P8') + #13#10);
end;

procedure TfrmAIPythonMacro.BtnSendClick(Sender: TObject);
var
  W: WideString;
begin
  if FBusy then Exit;
  if Assigned(FThread) then
  begin
    MessageDlg(TrText('AI_PY_MACRO_PREV_PENDING'), mtInformation, [mbOk], 0);
    Exit;
  end;
  if Length(Trim(MemoNote.Text)) < FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS then
  begin
    MessageDlg(Format(TrText('AI_PY_MACRO_NOTE_REQUIRED'),
      [FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS]), mtInformation, [mbOk], 0);
    Exit;
  end;

  FSendState := CaptureState(pyuResponse, False);
  FLastUserNote := MemoNote.Text;
  RememberRequest(FLastUserNote);
  W := BuildPromptW;
  MemoResp.Text := '';
  FLastPrepared := '';
  BtnPaste.Enabled := False;
  if Assigned(BtnApplyClose) then BtnApplyClose.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  LblStatus.Caption := TrText('AI_PY_MACRO_CONTACTING');
  AdjustStatusLabelHeight;
  FBusy := True;
  BtnSend.Enabled := False;
  BtnPaste.Enabled := False;
  if Assigned(BtnApplyClose) then BtnApplyClose.Enabled := False;
  if Assigned(BtnCopy) then BtnCopy.Enabled := False;
  BtnClose.Enabled := False;
  MemoNote.Enabled := False;
  BtnNoteMru.Enabled := False;
  UpdateUndoButtons;
  FIgnoreReply := False;
  FThread := TAIPythonMacroThread.Create(Self, W);
  StartAIWait;
  FThread.Start;
end;

procedure TfrmAIPythonMacro.ApplyFinished(const Ok: Boolean; const Ans: WideString;
  const Err: string);
begin
  FThread := nil;
  if FIgnoreReply then
  begin
    FIgnoreReply := False;
    Exit;
  end;
  StopAIWait;
  PushUndo(FSendState);
  if Ok then
  begin
    FLastPrepared := ApplyCharFilterFallbackIfNeeded(
      CleanPythonMacroAIResponse(PrepareAiMemoText(Ans)), FLastUserNote);
    FLastPrepared := StripMarkdownFences(FLastPrepared);
    if Trim(FLastPrepared) = '' then
      FLastPrepared := StripMarkdownFences(PrepareAiMemoText(Ans));
    FLastPrepared := DropUnrequestedJoinSeparator(FLastPrepared, FLastUserNote);
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

function TfrmAIPythonMacro.TextLineHeight: Integer;
begin
  { Scaled = False: a fonte em pontos cresce com o DPI, as alturas fixas em pixels nao. }
  Canvas.Font := Font;
  Result := Canvas.TextHeight('Ay');
  if Result < 14 then Result := 14;
end;

destructor TfrmAIPythonMacro.Destroy;
begin
  StopAIWait;
  { Pedido cancelado ainda em andamento: a thread nao pode chamar um form destruido. }
  if Assigned(FThread) then
    TAIPythonMacroThread(FThread).FOwnerDlg := nil;
  if Assigned(FormPopupMruList) and
     (TMethod(FormPopupMruList.OnPick).Data = Pointer(Self)) then
  begin
    FormPopupMruList.OnPick := nil;
    FormPopupMruList.OnRemove := nil;
    FormPopupMruList.OnClearAll := nil;
    if FormPopupMruList.Visible then
      FormPopupMruList.ClosePopup(False);
  end;
  FRecent.Free;
  inherited;
end;

procedure TfrmAIPythonMacro.LoadRecent;
var
  Path: string;
  I: Integer;
begin
  FRecent.Clear;
  Path := FastFileExeDirPath(PYAI_RECENT_FILE);
  if not FileExists(Path) then Exit;
  try
    FRecent.LoadFromFile(Path, TEncoding.UTF8);
  except
    FRecent.Clear;
  end;
  for I := FRecent.Count - 1 downto 0 do
    if Trim(FRecent[I]) = '' then
      FRecent.Delete(I);
  while FRecent.Count > PrefAssistantRecentMax do
    FRecent.Delete(FRecent.Count - 1);
end;

procedure TfrmAIPythonMacro.SaveRecent;
var
  Path: string;
begin
  Path := FastFileExeDirPath(PYAI_RECENT_FILE);
  try
    if FRecent.Count = 0 then
      SysUtils.DeleteFile(Path)
    else
      FRecent.SaveToFile(Path, TEncoding.UTF8);
  except
  end;
end;

procedure TfrmAIPythonMacro.RememberRequest(const S: string);
var
  Q: string;
  I: Integer;
begin
  Q := Trim(StringReplace(StringReplace(S, #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
  if Q = '' then Exit;
  for I := FRecent.Count - 1 downto 0 do
    if AnsiSameText(Trim(FRecent[I]), Q) then
      FRecent.Delete(I);
  FRecent.Insert(0, Q);
  while FRecent.Count > PrefAssistantRecentMax do
    FRecent.Delete(FRecent.Count - 1);
  SaveRecent;
end;

procedure TfrmAIPythonMacro.NoteMruClick(Sender: TObject);
var
  CR: TRect;
  OwnerComp: TComponent;
begin
  if FBusy then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    if TMethod(FormPopupMruList.OnPick).Data = Pointer(Self) then
      Exit;
  end;
  if FRecent.Count = 0 then
  begin
    LblStatus.Caption := TrText('Extract.AI.RecentEmpty');
    AdjustStatusLabelHeight;
    Exit;
  end;
  if not MemoNote.HandleAllocated then Exit;
  GetWindowRect(MemoNote.Handle, CR);
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Extract.AI.Recent'),
    MruMoreCaption('Assistant.RecentQuestionsMore'), FRecent,
    BtnNoteMru.BoundsRect.Right - MemoNote.Left, Point(CR.Left, CR.Bottom),
    NoteMruPick, TrText('Assistant.RecentQuestionsMoreHint'),
    nil, NoteMruRemove, BtnNoteMru, NoteMruClearAll, Handle);
end;

procedure TfrmAIPythonMacro.NoteMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  if FBusy or not MemoNote.Enabled then Exit;
  if MemoNote.Text = AValue then Exit;
  PushUndo(CaptureState(pyuMru, False));
  FRestoring := True;
  try
    MemoNote.Text := AValue;
    MemoNote.SelStart := Length(MemoNote.Text);
  finally
    FRestoring := False;
  end;
  SyncNoteShadow;
  if MemoNote.CanFocus then
    MemoNote.SetFocus;
end;

procedure TfrmAIPythonMacro.NoteMruRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
begin
  I := FRecent.IndexOf(AValue);
  if I >= 0 then
  begin
    FRecent.Delete(I);
    SaveRecent;
  end;
end;

procedure TfrmAIPythonMacro.NoteMruClearAll(Sender: TObject);
begin
  FRecent.Clear;
  SaveRecent;
end;

procedure TfrmAIPythonMacro.AdjustStatusLabelHeight;
begin
  RecalcTopPanelHeight;
end;

procedure TfrmAIPythonMacro.AdjustNoteLabelHeight;
begin
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
  if Assigned(BtnApplyClose) then
    BtnApplyClose.Enabled := Assigned(FTargetEditor) and HasCode and (not FBusy);
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
begin
  if ApplyToEditor then
  begin
    LblStatus.Caption := TrText('AI_PY_MACRO_APPLIED');
    AdjustStatusLabelHeight;
  end;
end;

procedure TfrmAIPythonMacro.BtnApplyCloseClick(Sender: TObject);
begin
  if ApplyToEditor then
    ModalResult := mrOk;
end;

function TfrmAIPythonMacro.ApplyToEditor: Boolean;
var
  Code: string;
begin
  Result := False;
  if FBusy or not Assigned(FTargetEditor) then Exit;
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
  if FTargetEditor.Text <> Code then
    PushUndo(CaptureState(pyuPaste, True));
  FTargetEditor.Lines.BeginUpdate;
  try
    FTargetEditor.Lines.Text := Code;
    FTargetEditor.Modified := True;
  finally
    FTargetEditor.Lines.EndUpdate;
  end;
  Result := True;
end;

procedure TfrmAIPythonMacro.WMResetBusy(var Msg: TMessage);
begin
  FBusy := False;
  BtnSend.Enabled := True;
  BtnClose.Enabled := True;
  MemoNote.Enabled := True;
  BtnNoteMru.Enabled := True;
  UpdateActionButtons;
  UpdateUndoButtons;
end;

function TfrmAIPythonMacro.CaptureState(AAction: TPyAiUndoAction;
  AWithEditor: Boolean): TPyAiUndoState;
begin
  Result.Action := AAction;
  Result.Note := MemoNote.Text;
  Result.NoteSel := MemoNote.SelStart;
  Result.Resp := MemoResp.Text;
  Result.Prepared := FLastPrepared;
  Result.UserNote := FLastUserNote;
  Result.HasEditor := AWithEditor and Assigned(FTargetEditor);
  if Result.HasEditor then
  begin
    Result.Editor := FTargetEditor.Text;
    Result.EditorModified := FTargetEditor.Modified;
  end
  else
  begin
    Result.Editor := '';
    Result.EditorModified := False;
  end;
end;

procedure TfrmAIPythonMacro.RestoreState(const AState: TPyAiUndoState);
begin
  FRestoring := True;
  try
    if MemoNote.Text <> AState.Note then
      MemoNote.Text := AState.Note;
    MemoNote.SelStart := Min(AState.NoteSel, Length(MemoNote.Text));
    if MemoResp.Text <> AState.Resp then
    begin
      MemoResp.Lines.BeginUpdate;
      try
        MemoResp.Lines.Text := AState.Resp;
        MemoResp.SelStart := 0;
      finally
        MemoResp.Lines.EndUpdate;
      end;
    end;
    FLastPrepared := AState.Prepared;
    FLastUserNote := AState.UserNote;
    if AState.HasEditor and Assigned(FTargetEditor) then
    begin
      FTargetEditor.Lines.BeginUpdate;
      try
        FTargetEditor.Lines.Text := AState.Editor;
      finally
        FTargetEditor.Lines.EndUpdate;
      end;
      FTargetEditor.Modified := AState.EditorModified;
    end;
  finally
    FRestoring := False;
  end;
  SyncNoteShadow;
  UpdateActionButtons;
  UpdateUndoButtons;
end;

procedure TfrmAIPythonMacro.PushUndo(const AState: TPyAiUndoState);
begin
  if Length(FUndo) >= PYAI_UNDO_MAX then
    Delete(FUndo, 0, 1);
  SetLength(FUndo, Length(FUndo) + 1);
  FUndo[High(FUndo)] := AState;
  SetLength(FRedo, 0);
  UpdateUndoButtons;
end;

function TfrmAIPythonMacro.UndoActionText(AAction: TPyAiUndoAction): string;
begin
  case AAction of
    pyuTyping: Result := TrText('AI_PY_MACRO_ACT_TYPING');
    pyuMru: Result := TrText('AI_PY_MACRO_ACT_MRU');
    pyuResponse: Result := TrText('AI_PY_MACRO_ACT_RESPONSE');
  else
    Result := TrText('AI_PY_MACRO_ACT_PASTE');
  end;
end;

procedure TfrmAIPythonMacro.DoUndo;
var
  S: TPyAiUndoState;
begin
  if FBusy or (Length(FUndo) = 0) then Exit;
  S := FUndo[High(FUndo)];
  SetLength(FUndo, Length(FUndo) - 1);
  SetLength(FRedo, Length(FRedo) + 1);
  FRedo[High(FRedo)] := CaptureState(S.Action, S.HasEditor);
  FLastTypingTick := 0;
  RestoreState(S);
  LblStatus.Caption := Format(TrText('AI_PY_MACRO_UNDONE'), [UndoActionText(S.Action)]);
  AdjustStatusLabelHeight;
end;

procedure TfrmAIPythonMacro.DoRedo;
var
  S: TPyAiUndoState;
begin
  if FBusy or (Length(FRedo) = 0) then Exit;
  S := FRedo[High(FRedo)];
  SetLength(FRedo, Length(FRedo) - 1);
  SetLength(FUndo, Length(FUndo) + 1);
  FUndo[High(FUndo)] := CaptureState(S.Action, S.HasEditor);
  FLastTypingTick := 0;
  RestoreState(S);
  LblStatus.Caption := Format(TrText('AI_PY_MACRO_REDONE'), [UndoActionText(S.Action)]);
  AdjustStatusLabelHeight;
end;

procedure TfrmAIPythonMacro.UpdateUndoButtons;
begin
  if Assigned(BtnUndo) then
    BtnUndo.Enabled := (not FBusy) and (Length(FUndo) > 0);
  if Assigned(BtnRedo) then
    BtnRedo.Enabled := (not FBusy) and (Length(FRedo) > 0);
end;

procedure TfrmAIPythonMacro.SyncNoteShadow;
begin
  FNoteShadow := MemoNote.Text;
  FNoteShadowSel := MemoNote.SelStart;
end;

procedure TfrmAIPythonMacro.MemoNoteChange(Sender: TObject);
var
  NowTick: Cardinal;
  S: TPyAiUndoState;
begin
  if FRestoring then Exit;
  if MemoNote.Text = FNoteShadow then Exit;
  NowTick := GetTickCount;
  { Digitacao continua vira um unico passo; pausa > 1 s abre um novo passo. }
  if not ((Length(FUndo) > 0) and (FUndo[High(FUndo)].Action = pyuTyping) and
          (FLastTypingTick <> 0) and (NowTick - FLastTypingTick < PYAI_TYPING_MERGE_MS)) then
  begin
    S := CaptureState(pyuTyping, False);
    S.Note := FNoteShadow;
    S.NoteSel := FNoteShadowSel;
    PushUndo(S);
  end;
  FLastTypingTick := NowTick;
  SyncNoteShadow;
end;

procedure TfrmAIPythonMacro.BtnUndoClick(Sender: TObject);
begin
  DoUndo;
end;

procedure TfrmAIPythonMacro.BtnRedoClick(Sender: TObject);
begin
  DoRedo;
end;

procedure TfrmAIPythonMacro.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = Ord('Z')) and (Shift = [ssCtrl]) then
  begin
    Key := 0;
    DoUndo;
  end
  else if ((Key = Ord('Y')) and (Shift = [ssCtrl])) or
          ((Key = Ord('Z')) and (Shift = [ssCtrl, ssShift])) then
  begin
    Key := 0;
    DoRedo;
  end;
end;

procedure TfrmAIPythonMacro.FormKeyPress(Sender: TObject; var Key: Char);
begin
  { Ctrl+Z / Ctrl+Y geram #26 / #25: o undo nativo de um nivel do TMemo nao deve rodar. }
  if (Key = #26) or (Key = #25) then
    Key := #0;
end;

procedure TfrmAIPythonMacro.StartAIWait;
begin
  FWaitStart := GetTickCount;
  TfrmSmoothLoading.ResetCancel;
  TfrmSmoothLoading.ShowLoading(Self, TrText('AI_PY_MACRO_WAIT_TITLE'), True);
  TfrmSmoothLoading.SnapFullyOpaque;
  TfrmSmoothLoading.SetWaitTexts(TrText('AI_PY_MACRO_WAIT_TITLE'), TrText('AI_PY_MACRO_WAIT_SENDING'));
  TfrmSmoothLoading.SetIndeterminate(False);
  TfrmSmoothLoading.SetCancelVisible(True);
  TfrmSmoothLoading.UpdateProgress(5);
  TfrmSmoothLoading.FlushPaint;
  if not Assigned(FWaitTimer) then
  begin
    FWaitTimer := TTimer.Create(Self);
    FWaitTimer.Interval := 250;
    FWaitTimer.OnTimer := WaitTimerTick;
  end;
  FWaitTimer.Enabled := True;
end;

procedure TfrmAIPythonMacro.StopAIWait;
begin
  if Assigned(FWaitTimer) then
    FWaitTimer.Enabled := False;
  if FWaitStart = 0 then Exit;
  FWaitStart := 0;
  if TfrmSmoothLoading.IsShowing then
  begin
    TfrmSmoothLoading.UpdateProgress(100);
    TfrmSmoothLoading.HideLoading;
  end;
end;

procedure TfrmAIPythonMacro.WaitTimerTick(Sender: TObject);
var
  Secs: Cardinal;
begin
  if (FWaitStart = 0) or not FBusy then Exit;
  if TfrmSmoothLoading.CancelRequested then
  begin
    CancelAIWait;
    Exit;
  end;
  Secs := (GetTickCount - FWaitStart) div 1000;
  if Secs < 2 then
    Exit;
  { Duracao desconhecida (modelo pensando): a barra avanca devagar sem voltar a 0. }
  TfrmSmoothLoading.CreepProgress(90);
  TfrmSmoothLoading.SetWaitTexts(TrText('AI_PY_MACRO_WAIT_TITLE'),
    Format(TrText('AI_PY_MACRO_WAIT_WAITING'), [Integer(Secs)]));
end;

procedure TfrmAIPythonMacro.CancelAIWait;
begin
  FIgnoreReply := Assigned(FThread);
  StopAIWait;
  TfrmSmoothLoading.ResetCancel;
  RestoreState(FSendState);
  LblStatus.Caption := TrText('AI_PY_MACRO_CANCELLED');
  AdjustStatusLabelHeight;
  PostMessage(Handle, WM_FF_PYAI_RESET_BUSY, 0, 0);
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
    FfFitFormToWorkArea(F);
    if (F.ShowModal = mrOk) and Assigned(ATargetEditor) then
    try
      if ATargetEditor.CanFocus then
        ATargetEditor.SetFocus;
    except
      on E: EInvalidOperation do ;
    end;
  finally
    F.Free;
  end;
end;

end.
