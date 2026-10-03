unit uFastFileAssistantCatalog;

{
  Action metadata aligned with DOC_ZS_ATALHOS.md / F1 shortcuts.
  Used for Lambda prompt (KNOWLEDGE) and local intent resolution (execute in app).
}

interface

uses
  Types, uFastFileAssistantHost;

function BuildAssistantZsAtalhosCatalogKB: string;
function CatalogIsAllowedActionId(const AId: string): Boolean;
function ExtractRecentListIndexFromText(const AQuestion: string): Integer;
function UserQuestionRefersToRecentFilesList(const AQuestion: string): Boolean;
function TryParseLineRangeParams(const AQuestion: string; out AParams: string): Boolean;
function UserWantsCatalogExportLineRange(const AQuestion: string; out AParams: string): Boolean;
function UserWantsShowScriptEngine(const AQuestion: string): Boolean;
function UserWantsShowTailMacro(const AQuestion: string): Boolean;
function UserWantsShowConsumerAI(const AQuestion: string): Boolean;
function UserWantsShowConsumerRAG(const AQuestion: string): Boolean;
function UserWantsConsumerAIContentQuestion(const AQuestion: string): Boolean;
function UserWantsConsumerRAGContentQuestion(const AQuestion: string): Boolean;
function LooksLikeSemanticFileQuestion(const L: string): Boolean;
function LooksLikeFileMathOrDataOp(const AQuestion: string): Boolean;
function LooksLikeTabularSqlQuestion(const L: string): Boolean;
function LooksLikeFilePurposeQuestion(const AQuestion: string): Boolean;
function LooksLikeExplainOrSummarizeAsk(const AQuestion: string): Boolean;
function LooksLikeRichDocFormatAsk(const L: string): Boolean;
function QuestionHasLongDigitNeedle(const AQuestion: string): Boolean;
function CollectDigitRunNeedles(const AQuestion: string;
  out ANeedles: TStringDynArray): Boolean;
function UserWantsComposeAsSavedDocument(const AQuestion: string): Boolean;
function UserWantsFileSummaryToDocument(const AQuestion: string): Boolean;
function UserWantsComposePythonSource(const AQuestion: string): Boolean;
function UserWantsComposeSourceCode(const AQuestion: string): Boolean;
function UserWantsComposeDocument(const AQuestion: string): Boolean;
function UserWantsFixComposedDocument(const AQuestion: string): Boolean;
function UserWantsShortComposeFix(const AQuestion: string): Boolean;
function UserAsksValidateSupportedLanguages(const AQuestion: string): Boolean;
function UserWantsValidateSource(const AQuestion: string): Boolean;
function UserWantsLoadSourceToValidate(const AQuestion: string): Boolean;
function SanitizeQuestionForConsumerPython(const AQuestion: string; AForRAG: Boolean): string;
function UserHasNativeFastFileToolIntent(const AQuestion: string): Boolean;
function UserHasSpecificToolIntent(const AQuestion: string): Boolean;
function UserQuestionLooksLikeNaturalLanguage(const AQuestion: string): Boolean;
function UserQuestionIsExplicitLocalShortcut(const AQuestion: string): Boolean;
function UserAsksOpenFileTotalLineCount(const AQuestion: string): Boolean;
function UserQuestionImpliesOpenFile(const AQuestion: string): Boolean;
function UserQuestionUsesOpenFilePronoun(const AQuestion: string): Boolean;
function UserQuestionRefersToOpenFile(const AQuestion: string): Boolean;
function UserQuestionNeedsLlmBeyondLocalFileFacts(const AQuestion: string): Boolean;
function UserWantsAggregateResultsAsDocument(const AQuestion: string): Boolean;
function StripRichDocAskFromQuestion(const AQuestion: string): string;
function TryParseLinePrefixCountAsk(const AQuestion: string;
  out APrefixes: TStringDynArray): Boolean;
function ExtractSearchTextFromText(const AQuestion: string): string;
{ Structural only: needles inside "..." '...' `...` (joined by |). No NL verbs. }
function ExtractQuotedNeedlesFromText(const AQuestion: string): string;
function ExtractPathFromUserText(const AQuestion: string): string;
{ Every Windows full path in the question (C:\... or \\server\...), unique order. }
function CollectWindowsFullPathsFromText(const AQuestion: string;
  out APaths: TStringDynArray): Boolean;
{ Structural "no maximo 100" / "at most 100" / "100 registros" — 0 if absent. Cap 500. }
function ExtractMaxRecordsFromText(const AQuestion: string): Integer;

type
  TAssistantOpenFileMetaKind = (
    aofmNone, aofmCreated, aofmModified, aofmAccessed, aofmSize, aofmProps);
  TAssistantOpenFileMetaKinds = set of TAssistantOpenFileMetaKind;

function DetectOpenFileDiskMetaAsk(const AQuestion: string): TAssistantOpenFileMetaKind;
function CollectOpenFileDiskMetaAsks(const AQuestion: string): TAssistantOpenFileMetaKinds;
function ConsumerRAGPlanAllowed(const AQuestion: string): Boolean;
function ConsumerAIPlanAllowed(const AQuestion: string): Boolean;
{ Local-shortcut / offline path ONLY — never call after the LLM chose an action. }
function TryCatalogResolveAction(const AQuestion: string;
  var AActionId: string; var AStep: TAssistantChainStep): Boolean;
{ AI-first: keep AActionId; fill empty path/filter/parts/line from structure only. }
function TryCatalogEnrichActionParams(const AQuestion, AActionId: string;
  var AStep: TAssistantChainStep): Boolean;
function ParseMergeFilesModeFromQuestion(const AQuestion: string;
  out AModeIndex, AAfterLine: Integer): Boolean;
function ContainsTokenAsWord(const L, Tok: string): Boolean;

implementation

uses
  SysUtils, Classes, uPosBMH, uFastFileAssistantMap;

function IsTokenWordChar(C: Char): Boolean;
begin
  Result := (C in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function ContainsTokenAsWord(const L, Tok: string): Boolean;
var
  p, LenT, StartAt: Integer;
begin
  Result := False;
  if (Tok = '') or (L = '') then Exit;
  LenT := Length(Tok);
  p := PosBMH(Tok, L);
  while p > 0 do
  begin
    if ((p = 1) or not IsTokenWordChar(L[p - 1])) and
       ((p + LenT - 1 = Length(L)) or not IsTokenWordChar(L[p + LenT])) then
    begin
      Result := True;
      Exit;
    end;
    StartAt := p + LenT;
    if StartAt > Length(L) then Break;
    p := PosBMH(Tok, Copy(L, StartAt, MaxInt));
    if p > 0 then Inc(p, StartAt - 1);
  end;
end;

function ContainsAnyToken(const L, Tokens: string): Boolean;
var
  i, p: Integer;
  Tok: string;
begin
  Result := False;
  if Tokens = '' then Exit;
  i := 1;
  while i <= Length(Tokens) do
  begin
    p := i;
    while (p <= Length(Tokens)) and (Tokens[p] <> '|') do Inc(p);
    Tok := Trim(Copy(Tokens, i, p - i));
    if Tok <> '' then
    begin
      if (Length(Tok) <= 4) and (Pos('|', Tokens) > 0) then
      begin
        if ContainsTokenAsWord(L, Tok) then
        begin
          Result := True;
          Exit;
        end;
      end
      else if PosBMH(Tok, L) > 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
    if p > Length(Tokens) then Break;
    i := p + 1;
  end;
end;

function ExtractLineNumberFromText(const AQuestion: string): Integer;
var
  L: string;
  i, p, StartAt: Integer;
  Num: string;
begin
  Result := 0;
  L := LowerCase(AQuestion);
  p := PosBMH('linha', L);
  if p = 0 then p := PosBMH('line', L);
  if p = 0 then Exit;
  StartAt := p;
  i := StartAt + 4;
  while (i <= Length(L)) and not (L[i] in ['0'..'9']) do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
end;

function QuotedNeedleLooksLikeFileName(const Body: string): Boolean;
var
  S, Ext, OpenName: string;
  Dot, Slash, j: Integer;
begin
  { PI121106.txt / C:\a\b.txt are paths, not filter needles. }
  Result := False;
  S := Trim(Body);
  if S = '' then Exit;
  if (Length(S) >= 3) and (S[2] = ':') and (S[3] in ['\', '/']) then
  begin
    Result := True;
    Exit;
  end;
  OpenName := ExtractFileName(AssistantHostGetOpenFilePath);
  if (OpenName <> '') and SameText(S, OpenName) then
  begin
    Result := True;
    Exit;
  end;
  Slash := LastDelimiter('\/', S);
  if Slash > 0 then
  begin
    Result := True;
    Exit;
  end;
  Dot := LastDelimiter('.', S);
  if (Dot <= 1) or (Dot >= Length(S)) then Exit;
  Ext := LowerCase(Copy(S, Dot + 1, MaxInt));
  if (Length(Ext) < 1) or (Length(Ext) > 5) then Exit;
  for j := 1 to Length(Ext) do
    if not (Ext[j] in ['a'..'z']) then Exit;
  Result := True;
end;

function ExtractSearchTextFromText(const AQuestion: string): string;
var
  i, p, q: Integer;
  Ch: Char;
  T: string;
begin
  Result := '';
  { Structural delimiters only: "..." '...' `...` — not NL verb dictionaries. }
  for i := 1 to Length(AQuestion) do
    if (AQuestion[i] = '"') or (AQuestion[i] = '''') or (AQuestion[i] = '`') then
    begin
      Ch := AQuestion[i];
      p := i + 1;
      q := p;
      while (q <= Length(AQuestion)) and (AQuestion[q] <> Ch) do Inc(q);
      if q > Length(AQuestion) then Continue;
      T := Trim(Copy(AQuestion, p, q - p));
      if QuotedNeedleLooksLikeFileName(T) then
        Continue;
      if T <> '' then
      begin
        Result := T;
        Exit;
      end;
    end;
end;

function UserRequestedCaseSensitive(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  if (PosBMH('insensitive', L) > 0) or (PosBMH('ignorar mai', L) > 0) or
     (PosBMH('case insensitive', L) > 0) then
    Result := False
  else if ((PosBMH('sensitive', L) > 0) and (PosBMH('insensitive', L) = 0)) or
     (PosBMH('maiuscul', L) > 0) or (PosBMH('match case', L) > 0) then
    Result := True
  else
    Result := False;
end;

function ExtractByteOffsetFromText(const AQuestion: string): Int64;
var
  L, S, Num: string;
  i, p: Integer;
begin
  Result := 0;
  L := LowerCase(AQuestion);
  if (PosBMH('byte', L) = 0) and (PosBMH('offset', L) = 0) and (PosBMH('hex', L) = 0) and
     (PosBMH('$', AQuestion) = 0) then
    Exit;
  p := PosBMH('$', AQuestion);
  if p > 0 then
  begin
    S := '';
    i := p + 1;
    while (i <= Length(AQuestion)) and (AQuestion[i] in ['0'..'9', 'A'..'F', 'a'..'f']) do
    begin
      S := S + AQuestion[i];
      Inc(i);
    end;
    Result := StrToInt64Def('$' + S, 0);
    if Result > 0 then Exit;
  end;
  i := 1;
  Num := '';
  while i <= Length(L) do
  begin
    if L[i] in ['0'..'9'] then
      Num := Num + L[i]
    else if Num <> '' then
    begin
      Result := StrToInt64Def(Num, 0);
      if Result > 0 then Exit;
      Num := '';
    end;
    Inc(i);
  end;
  if Num <> '' then
    Result := StrToInt64Def(Num, 0);
end;

function PathSoFarLooksComplete(const PathSoFar: string): Boolean;
var
  Dot, Slash, j: Integer;
  Ext: string;
begin
  Result := False;
  if PathSoFar = '' then Exit;
  Slash := LastDelimiter('\/', PathSoFar);
  Dot := LastDelimiter('.', PathSoFar);
  if (Dot <= 0) or (Dot <= Slash) or (Dot >= Length(PathSoFar)) then Exit;
  Ext := Copy(PathSoFar, Dot + 1, MaxInt);
  if (Length(Ext) < 1) or (Length(Ext) > 10) then Exit;
  for j := 1 to Length(Ext) do
    if not (Ext[j] in ['A'..'Z', 'a'..'z', '0'..'9']) then Exit;
  Result := True;
end;

procedure ClampExtractedFilePath(var Path: string);
var
  L: string;
  CutAt, p: Integer;
begin
  Path := Trim(Path);
  while (Length(Path) > 0) and (Path[Length(Path)] in
    [',', '.', ';', ':', ')', ']', '}', '"', '''', '?', '!', ' ', #9]) do
    SetLength(Path, Length(Path) - 1);
  if Path = '' then Exit;
  L := LowerCase(Path);
  CutAt := 0;
  p := PosBMH(' em ', L);
  if p > 0 then CutAt := p;
  p := PosBMH(' into ', L);
  if (p > 0) and ((CutAt = 0) or (p < CutAt)) then CutAt := p;
  p := PosBMH(' in ', L);
  if (p > 0) and PathSoFarLooksComplete(Copy(Path, 1, p - 1)) and
     ((CutAt = 0) or (p < CutAt)) then
    CutAt := p;
  if CutAt > 1 then
    Path := Trim(Copy(Path, 1, CutAt - 1));
end;

function ExtractPathFromUserText(const AQuestion: string): string;
var
  Paths: TStringDynArray;
begin
  Result := '';
  if CollectWindowsFullPathsFromText(AQuestion, Paths) then
    Result := Paths[0];
end;

function LooksLikeWindowsFullPath(const S: string): Boolean;
var
  T: string;
begin
  T := Trim(S);
  Result := False;
  if Length(T) < 3 then Exit;
  if (T[1] in ['A'..'Z', 'a'..'z']) and (T[2] = ':') and (T[3] in ['\', '/']) then
    Result := True
  else if (T[1] = '\') and (T[2] = '\') then
    Result := True;
end;

procedure AddWindowsFullPath(const Raw: string; List: TStringList);
var
  P: string;
  i: Integer;
begin
  P := Trim(Raw);
  if not LooksLikeWindowsFullPath(P) then Exit;
  ClampExtractedFilePath(P);
  if not LooksLikeWindowsFullPath(P) then Exit;
  for i := 0 to List.Count - 1 do
    if SameText(List[i], P) then
      Exit;
  List.Add(P);
end;

function CollectWindowsFullPathsFromText(const AQuestion: string;
  out APaths: TStringDynArray): Boolean;
var
  Src, T: string;
  List: TStringList;
  i, p, EndPos: Integer;
  Ch: Char;
begin
  Result := False;
  SetLength(APaths, 0);
  Src := Trim(AQuestion);
  if Src = '' then Exit;
  List := TStringList.Create;
  try
    i := 1;
    while i <= Length(Src) do
    begin
      if Src[i] in ['"', '''', '`'] then
      begin
        Ch := Src[i];
        p := i + 1;
        EndPos := p;
        while (EndPos <= Length(Src)) and (Src[EndPos] <> Ch) do
          Inc(EndPos);
        if EndPos <= Length(Src) then
        begin
          T := Trim(Copy(Src, i + 1, EndPos - i - 1));
          AddWindowsFullPath(T, List);
          i := EndPos + 1;
          Continue;
        end;
      end;
      Inc(i);
    end;
    i := 1;
    while i <= Length(Src) - 1 do
    begin
      if (Src[i] in ['A'..'Z', 'a'..'z']) and (i + 2 <= Length(Src)) and
         (Src[i + 1] = ':') and (Src[i + 2] in ['\', '/']) then
      begin
        p := i;
        EndPos := p;
        while EndPos <= Length(Src) do
        begin
          if Src[EndPos] in [#0..#31, '"', '''', '`'] then Break;
          if (Src[EndPos] in [' ', '?', '!']) and
             PathSoFarLooksComplete(Copy(Src, p, EndPos - p)) then
            Break;
          Inc(EndPos);
        end;
        AddWindowsFullPath(Copy(Src, p, EndPos - p), List);
        i := EndPos;
        Continue;
      end;
      if (Src[i] = '\') and (Src[i + 1] = '\') then
      begin
        p := i;
        EndPos := p + 2;
        while EndPos <= Length(Src) do
        begin
          if Src[EndPos] in [#0..#31, '"', '''', '`'] then Break;
          if (Src[EndPos] in [' ', '?', '!']) and
             PathSoFarLooksComplete(Copy(Src, p, EndPos - p)) then
            Break;
          Inc(EndPos);
        end;
        AddWindowsFullPath(Copy(Src, p, EndPos - p), List);
        i := EndPos;
        Continue;
      end;
      Inc(i);
    end;
    if List.Count = 0 then Exit;
    SetLength(APaths, List.Count);
    for i := 0 to List.Count - 1 do
      APaths[i] := List[i];
    Result := True;
  finally
    List.Free;
  end;
end;

function CatalogParseNumberAfter(const L: string; StartAt: Integer; out AValue: Integer): Boolean;
var
  i: Integer;
  Num: string;
begin
  Result := False;
  AValue := 0;
  i := StartAt;
  while (i <= Length(L)) and not (L[i] in ['0'..'9']) do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  AValue := StrToIntDef(Num, 0);
  Result := AValue > 0;
end;

function CatalogParseSecondAfterFirstNumber(const L: string; AfterFirst: Integer;
  out ASecond: Integer): Boolean;
var
  j: Integer;
  Rest: string;
begin
  Result := False;
  ASecond := 0;
  j := AfterFirst;
  while (j <= Length(L)) and (L[j] <= ' ') do Inc(j);
  if j > Length(L) then Exit;
  if L[j] = '-' then
    Inc(j)
  else if (j < Length(L)) and (L[j] = '.') and (L[j + 1] = '.') then
    Inc(j, 2)
  else
  begin
    Rest := Copy(L, j, 4);
    if PosBMH('ate ', Rest) = 1 then
      Inc(j, 4)
    else if PosBMH('to ', Rest) = 1 then
      Inc(j, 3)
    else if (L[j] = 'a') and ((j = Length(L)) or not IsTokenWordChar(L[j + 1])) then
      Inc(j)
    else if (L[j] = 'e') and ((j = Length(L)) or not IsTokenWordChar(L[j + 1])) then
      Inc(j)
    else
      Exit;
  end;
  Result := CatalogParseNumberAfter(L, j, ASecond);
end;

function TryParseLineRangeParams(const AQuestion: string; out AParams: string): Boolean;
var
  L: string;
  p, i, n1, n2: Integer;

  function FinishRange: Boolean;
  begin
    Result := False;
    if (n1 < 1) or (n2 < 1) then Exit;
    if n1 > n2 then
      AParams := Format('%d-%d', [n2, n1])
    else
      AParams := Format('%d-%d', [n1, n2]);
    Result := True;
  end;

  function ParsePairFrom(StartAt: Integer): Boolean;
  begin
    Result := False;
    if not CatalogParseNumberAfter(L, StartAt, n1) then Exit;
    i := StartAt;
    while (i <= Length(L)) and not (L[i] in ['0'..'9']) do Inc(i);
    while (i <= Length(L)) and (L[i] in ['0'..'9']) do Inc(i);
    if not CatalogParseSecondAfterFirstNumber(L, i, n2) then Exit;
    Result := FinishRange;
  end;

begin
  Result := False;
  AParams := '';
  L := LowerCase(AQuestion);
  if (PosBMH('linha', L) = 0) and (PosBMH('line', L) = 0) then Exit;

  p := PosBMH('entre ', L);
  if p > 0 then
  begin
    Result := ParsePairFrom(p + Length('entre '));
    if Result then Exit;
  end;

  p := PosBMH('linha', L);
  if p = 0 then p := PosBMH('line', L);
  if p > 0 then
    Result := ParsePairFrom(p);
end;

function UserImpliesLineRangeFileAction(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result :=
    (PosBMH('export', L) > 0) or (PosBMH('exportar', L) > 0) or
    (PosBMH('gerar', L) > 0) or (PosBMH('criar', L) > 0) or
    (PosBMH('novo', L) > 0) or (PosBMH('new file', L) > 0) or
    (PosBMH('salvar', L) > 0) or (PosBMH('gravar', L) > 0) or
    (PosBMH('guardar', L) > 0) or (PosBMH('save', L) > 0) or
    (PosBMH('extrair', L) > 0) or (PosBMH('extract', L) > 0) or
    (PosBMH('somente', L) > 0) or (PosBMH('apenas', L) > 0) or
    (PosBMH('only', L) > 0) or (PosBMH('inclusive', L) > 0) or
    (PosBMH('copiar', L) > 0) or
    (ExtractPathFromUserText(AQuestion) <> '');
end;

function UserWantsCatalogExportLineRange(const AQuestion: string; out AParams: string): Boolean;
begin
  Result := TryParseLineRangeParams(AQuestion, AParams) and
    UserImpliesLineRangeFileAction(AQuestion);
end;

function UserWantsComposeSourceCode(const AQuestion: string): Boolean;
var
  L: string;
const
  Langs =
    'python|.py|javascript|typescript|react|angular|golang|em go|' +
    'java|c++|cplusplus|csharp|c#|rust|php|ruby|kotlin|swift|' +
    'pascal|delphi|powershell|bash|shell script|' +
    '.java|.tsx|.jsx|.cpp|.cs|.pas|.dpr|.php|.rb|.kt|.swift|' +
    '.html|.sql|.ps1|.ts|.js|.go|.py|.rs|.cc|.cxx';
begin
  { Standalone source file — not Script Engine / Tail macro. }
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if ContainsAnyToken(L,
    'ctrl+alt+e|script engine|motor de script|macros python|macro python|' +
    'rodar python|executar python|run python|quero rodar|quero executar|' +
    'macro tail|tail macro') then
    Exit;
  if not ContainsAnyToken(L, Langs) then Exit;
  Result := ContainsAnyToken(L,
    'gere um programa|gera um programa|gerar um programa|escreva um programa|' +
    'escrever um programa|criar um programa|crie um programa|' +
    'gere uma classe|gera uma classe|gerar uma classe|escreva uma classe|' +
    'criar uma classe|crie uma classe|gere um componente|gera um componente|' +
    'gerar um componente|crie um componente|criar um componente|' +
    'gere uma funcao|gera uma funcao|gerar uma funcao|escreva uma funcao|' +
    'gere um script|gera um script|gerar um script|escreva um script|' +
    'gere um codigo|gera um codigo|gerar codigo|escreva um codigo|' +
    'codigo fonte|source code|generate a program|write a program|' +
    'create a program|create a class|write a class|generate a class|' +
    'create a component|write a component|generate a component|' +
    'generate a script|write a script|create a script|' +
    'gere um .py|gera um .py|gerar .py|escreva um .py|' +
    'gere um .js|gere um .ts|gere um .tsx|gere um .go|gere um .java|' +
    'gere um .cpp|gere um .c|gere um .cs|gere um .pas');
  if Result then Exit;
  Result := ContainsAnyToken(L, 'gere |gera |gerar |escreva |escrever |criar |crie ') and
    ContainsAnyToken(L, 'programa|program|classe|class |componente|component|' +
      'funcao|função|function|script|codigo|código|source') and
    ContainsAnyToken(L, Langs);
end;

function UserWantsComposePythonSource(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if not ContainsAnyToken(L, 'python|.py') then Exit;
  Result := UserWantsComposeSourceCode(AQuestion);
end;

function UserWantsShowScriptEngine(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  { Macro Tail e outro painel (Python no follow). }
  if ContainsAnyToken(L, 'macro tail|tail macro|python tail|macro python tail') then
    Exit;
  { "Gerar um programa / classe em X" is compose (source file), not Ctrl+Alt+E. }
  if UserWantsComposeSourceCode(AQuestion) then Exit;
  Result := ContainsAnyToken(L,
    'ctrl+alt+e|script engine|motor de script|macros python|macro python|' +
    'rodar python|executar python|run python|rodar um python|executar um python|' +
    'python para|editor python|painel python|' +
    'automacao python|automação python|' +
    'macros with python|quero rodar um python|quero executar python');
  if Result then Exit;
  { "script python" alone is ambiguous; prefer run/transform phrasing for the panel. }
  if ContainsAnyToken(L, 'script python|python script') and
     ContainsAnyToken(L, 'rodar|executar|run |macro|linhas|linha|painel|abrir') then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L, 'python') and
    ContainsAnyToken(L, 'rodar|executar|run |macro') and
    not ContainsAnyToken(L, 'gere |gera |gerar |escreva |escrever |criar |crie |programa');
end;

function UserWantsShowTailMacro(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  Result := ContainsAnyToken(L,
    'macro tail|tail macro|python tail|macro python tail|macro no tail|' +
    'python no follow|script no tail|automacao tail|tail python');
end;

function UserHasNativeFastFileToolIntent(const AQuestion: string): Boolean;
var
  L, Dummy: string;
begin
  { Editor tools that must win over ConsumerAI / ConsumerRAG. }
  Result := False;
  L := FoldDiacriticsForMatch(AQuestion);
  if L = '' then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsValidateSource(AQuestion) or UserAsksValidateSupportedLanguages(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsCatalogExportLineRange(AQuestion, Dummy) then
  begin
    Result := True;
    Exit;
  end;
  { Merge/join must win over RAG even for "Pode juntar esse arquivo?" / German umlauts. }
  if ContainsAnyToken(L, 'mesclar|unir|juntar|reunir|merge|join|fusionner|' +
      'zusammenfuehren|zusammenfuhren|unisci|scal|uneste|sloucit') and
     (ContainsAnyToken(L, 'arquivo|arquivos|ficheiro|ficheiros|file|files|' +
        'archivo|archivos|fichier|fichiers|datei|dateien|plik|pliki|' +
        'fisier|fisiere|soubor|soubory|part|parte|partes|teile|parti|' +
        'esse|este|this|that|diese|dieser|dieses|jene') or
      (ExtractPathFromUserText(AQuestion) <> '')) then
  begin
    Result := True;
    Exit;
  end;
  if ContainsAnyToken(L, 'juntar esse|unir esse|mesclar esse|reunir esse|' +
    'join this|merge this|juntar o arquivo|unir o arquivo|mesclar o arquivo|' +
    'diese datei zusammenfuehren|datei zusammenfuehren|dateien zusammenfuehren|' +
    'merge files|join files|join parts|merge parts|ctrl+shift+j') then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'script engine|motor de script|macros python|macro python|' +
    'rodar python|executar python|run python|python para|' +
    'dividir|partir o arquivo|particionar|extrair parte|partes iguais|' +
    'split into|split file|split equal|split files|' +
    'unir linhas|juntar linhas|mesclar|merge files|merge lines|' +
    'comparar|compare files|diff arquivos|' +
    'exportar|gerar um novo|criar um novo|somente com as linhas|' +
    'filtrar|filtro|grep|substituir|replace all|find and replace|' +
    'iniciar tail|start tail|follow mode|seguir o arquivo|monitorar o arquivo|' +
    'ir para linha|goto line|editar linha|apagar linha|inserir linha|' +
    'marcador|bookmark|word wrap|quebra de linha|' +
    'modo csv|colunas csv|zoom|tela cheia|fullscreen|' +
    'duplicad|strings frequente|zero scan|indexar|forcar indice|' +
    'procurar em|buscar em|localizar|find in files|find text');
end;

function LooksLikeHowToFastFile(const L: string): Boolean;
begin
  Result := ContainsAnyToken(L,
    'como leio|como eu leio|como faco|como faço|como abrir|como carregar|' +
    'como usar o fastfile|how do i|how can i|how to open|how to read|' +
    'how do I');
end;

function LooksLikeStrongFileQuestionFraming(const L: string): Boolean;
begin
  Result := ContainsAnyToken(L,
    'com relacao ao arquivo|com relação ao arquivo|com respeito ao arquivo|' +
    'em relacao ao arquivo|em relação ao arquivo|' +
    'a respeito do arquivo|a respeito deste arquivo|a respeito desse arquivo|' +
    'regarding the file|with regard to the file|about the file|' +
    'relacao ao arquivo|relação ao arquivo');
end;

function LooksLikeInterrogativeAsk(const L: string): Boolean;
begin
  if Pos('?', L) > 0 then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'quantos |quantas |qual |quais |o que |quem |quando |onde |por que|' +
    'porque |existe |ha algum|há algum|tem algum|me explique|me descreva|' +
    'me diga|me fale|resumo|resumir|summarize|describe |explain |what |why |' +
    'which |who |when |where |how many|how much');
end;

function LooksLikeFileMathOrDataOp(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Filtered counts / aggregates / SQL-style asks over file data → ConsumerAI
    (LLM may instead pick count_line_prefixes / count_matching_lines). Plain total
    line count ("quantas linhas tem") is NOT included — that is CURRENT_CONTEXT /
    local facts (and compose may cite it). }
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  Result := ContainsAnyToken(L,
    'valores unicos|valores distintos|unique values|' +
    'distinct values|distinct |group by|agrupar|agrupado|' +
    'soma |somar |somatorio|somatoria|subtrair|subtrai|multiplic|' +
    'dividir por|divisao|razao|proporcao|' +
    'media |average |avg |maximo |minimo |mediana|median |' +
    'desvio|variancia|variance|stddev|moda |mode |' +
    'calcular|calcule|calcula |compute |computation|operacao matem|' +
    'matematica|math |formula |' +
    'coluna |colunas |column |columns |campo |campos |schema|' +
    'consulta sql|query sql|select |duckdb|' +
    'percentual|porcentagem|percentage|por cento|percent |' +
    'valores nulos|null values|valores vazios|empty values|' +
    'quantos unicos|how many unique|top n |media de|soma de|' +
    'registros com |linhas onde |where |' +
    'se iniciam|se inicia|iniciam pelo|inicia pelo|iniciam com|inicia com|' +
    'comecam com|comeca com|comecam pelo|start with|starts with|starting with|' +
    'prefixo |prefix |pelo valor|pelo codigo|linhas que comecem|' +
    'linhas que iniciam|contem o valor|igual a |' +
    'maior que|menor que|between |entre o valor|faixa de|' +
    'frequencia|ocorrencias|occurrences|' +
    'contagem filtr|count where|sum |agregar|agregacao');
end;

function LooksLikeTabularSqlQuestion(const L: string): Boolean;
begin
  { ConsumerAI / DuckDB: counts, aggregates, columns, distinct, SQL, math on file. }
  Result := LooksLikeFileMathOrDataOp(L);
  if Result then Exit;
  Result := ContainsTokenAsWord(L, 'sql');
end;

function LooksLikeSemanticFileQuestion(const L: string): Boolean;
begin
  { ConsumerRAG: meaning, purpose, summary, analysis of unstructured text. }
  Result := False;
  if ContainsAnyToken(L, 'pra que|para que') and
     ContainsAnyToken(L, 'serve|servir|purpose') then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'o que e este arquivo|o que e esse arquivo|o que e este ficheiro|' +
    'o que e esse ficheiro|do que se trata|de que se trata|' +
    'sobre o conteudo|sobre este arquivo|sobre esse arquivo|' +
    'analisar o arquivo|analise o arquivo|analisar este arquivo|' +
    'analise este arquivo|interprete o arquivo|interpretar o arquivo|' +
    'qual a finalidade|qual o proposito|qual o propósito|' +
    'what is this file|what is the file for|about this file|' +
    'whats this file|what''s this file|what does this file|' +
    'resumo do arquivo|resumir o arquivo|summarize|sumarize|' +
    'me explique o arquivo|explique o arquivo|descreva o arquivo|' +
    'descrever o arquivo|visao geral|visão geral|overview|' +
    'o que significa|o que contem|o que contém|o que tem neste|' +
    'o que tem nesse|contexto do arquivo|sentido do arquivo|' +
    'o que esse arquivo representa|o que este arquivo representa|' +
    'o que o arquivo representa|arquivo representa|ficheiro representa|' +
    'represents|what does it represent|parece armazenar|parece ser|' +
    'quem aparece|o que aconteceu|find mentions|semantic|' +
    'utilidade|finalidade');
end;

function LooksLikeFilePurposeQuestion(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Broad "what is this file for" — 11 UI languages, paraphrases OK. }
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  if ContainsAnyToken(L, 'utilidade|finalidade|proposito|purpose|finalite|zweck|scopo|' +
      'cel |celu |scop |rendeltetes|ucel') then
  begin
    Result := True;
    Exit;
  end;
  if ContainsAnyToken(L, 'pra que|para que|para que sirve|a quoi sert|wozu dient|' +
      'a cosa serve|do czego|pentru ce|mire valo|k cemu') and
     ContainsAnyToken(L, 'serve|servir|sirve|sert|dient|serve|sluzy|foloseste|jo|' +
      'file|arquivo|ficheiro|archivo|fichier|datei|plik|fisier|fajl|soubor') then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'o que este arquivo faz|o que esse arquivo faz|what is this file for|' +
    'what does this file|para que sirve este archivo|a quoi sert ce fichier|' +
    'wozu ist diese datei|a cosa serve questo file|do czego jest ten plik|' +
    'pentru ce este acest fisier|mire valo ez a fajl|k cemu je tento soubor');
end;

function LooksLikeExplainOrSummarizeAsk(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Explain / summarize / describe the open file — any of 11 UI languages. }
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  if LooksLikeFilePurposeQuestion(AQuestion) or LooksLikeSemanticFileQuestion(L) then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'explicar|explique|me explique|explica |explain |expliquez|erklare|erklaren|' +
    'spiega |spiegami|wyjasnij|explica-me|explica me|explicati|' +
    'magyaraz|erklar|vysvetli|popis |descreva|descrever|describe |descriva|' +
    'beschreib|opisz |descrie|irja le|popiste|' +
    'resumo|resumir|summar|relatorio|report|overview|visao geral|' +
    'ubereblick|ueberblick|panoramica|podsumowanie|rezumat|osszefoglalo|' +
    'prehled|analisar|analise|analyze|analyse|analizuj|' +
    'representa|representar|represents|represent|' +
    'me diz o que|me diga o que|diz aproximadamente|aproximadamente o que');
end;

function LooksLikeRichDocFormatAsk(const L: string): Boolean;
var
  F: string;
begin
  { Format ids only (any of the 11 UI languages) — not PT/EN generate verbs.
    "generezi un PDF" / "gera um PDF" / "generate a PDF" all match on pdf. }
  F := LowerCase(FoldDiacriticsForMatch(Trim(L)));
  if F = '' then
  begin
    Result := False;
    Exit;
  end;
  Result := ContainsTokenAsWord(F, 'pdf') or ContainsTokenAsWord(F, 'docx') or
    ContainsTokenAsWord(F, 'odt') or ContainsTokenAsWord(F, 'rtf') or
    (Pos('.pdf', F) > 0) or (Pos('.docx', F) > 0) or
    (Pos('.odt', F) > 0) or (Pos('.rtf', F) > 0);
  if Result then Exit;
  { "Word" as a format id — not the English noun in "find the word X". }
  Result := (PosBMH(' em word', F) > 0) or (PosBMH(' en word', F) > 0) or
    (PosBMH(' in word', F) > 0) or (PosBMH(' im word', F) > 0) or
    (PosBMH('formato word', F) > 0) or (PosBMH('format word', F) > 0) or
    (PosBMH('microsoft word', F) > 0) or (PosBMH('documento word', F) > 0) or
    (PosBMH('document word', F) > 0) or (PosBMH('fisier word', F) > 0) or
    (PosBMH('documentul word', F) > 0);
end;

function CollectDigitRunNeedles(const AQuestion: string;
  out ANeedles: TStringDynArray): Boolean;
var
  Src, Tail, Head: string;
  List: TStringList;
  i, j, n: Integer;
begin
  { Digit runs of 4+ chars that are not years, not glued to a filename (PI121106.txt). }
  Result := False;
  SetLength(ANeedles, 0);
  Src := Trim(AQuestion);
  if Src = '' then Exit;
  List := TStringList.Create;
  try
    List.Sorted := True;
    List.Duplicates := dupIgnore;
    i := 1;
    while i <= Length(Src) do
    begin
      if Src[i] in ['0'..'9'] then
      begin
        j := i;
        while (j <= Length(Src)) and (Src[j] in ['0'..'9']) do
          Inc(j);
        n := j - i;
        if n >= 4 then
        begin
          Head := Copy(Src, i, 2);
          if not ((n = 4) and ((Head = '19') or (Head = '20'))) then
            if (i > 1) and (Src[i - 1] in ['A'..'Z', 'a'..'z', '_']) then
              { part of identifier / filename }
            else if (j <= Length(Src)) and (Src[j] = '.') then
              { .txt / .part001 }
            else
            begin
              Tail := LowerCase(FoldDiacriticsForMatch(Copy(Src, j, 48)));
              if (Pos('primeiras', Tail) = 0) and (Pos('primeras', Tail) = 0) and
                 (Pos('first ', Tail) = 0) and (Pos('ersten', Tail) = 0) and
                 (Pos('premieres', Tail) = 0) and (Pos('primi ', Tail) = 0) then
                List.Add(Copy(Src, i, n));
            end;
        end;
        i := j;
      end
      else
        Inc(i);
    end;
    if List.Count = 0 then Exit;
    SetLength(ANeedles, List.Count);
    for i := 0 to List.Count - 1 do
      ANeedles[i] := List[i];
    Result := True;
  finally
    List.Free;
  end;
end;

function QuestionHasLongDigitNeedle(const AQuestion: string): Boolean;
var
  Needles: TStringDynArray;
begin
  Result := CollectDigitRunNeedles(AQuestion, Needles);
end;

function UserWantsComposeAsSavedDocument(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Standalone file output (Word/RTF/DOCX/PDF/ODT), not a chat summary.
    Data aggregates / filtered counts + "gerar PDF" stay on ConsumerAI —
    compose must not invent counts from a file sample. }
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  { "exportar um PDF/Word" is compose_document, not Ctrl+Shift+O. }
  if UserHasNativeFastFileToolIntent(AQuestion) and
     (not LooksLikeRichDocFormatAsk(L)) then
    Exit;
  if LooksLikeTabularSqlQuestion(FoldDiacriticsForMatch(L)) and
     (not LooksLikeSemanticFileQuestion(L)) and
     (not LooksLikeFilePurposeQuestion(AQuestion)) then
    Exit;
  if not LooksLikeRichDocFormatAsk(L) then
    Exit;
  Result := ContainsAnyToken(L,
    'gere |gera |gerar |gerando |escreva |escrever |resumo|relatorio|' +
    'summary|compose |documento|salve |salvar |generate |generating |' +
    'create a|creating |explicar|explique|me explique|analisar|analise|' +
    'exporta |exportar |export |informa');
end;

function UserWantsFileSummaryToDocument(const AQuestion: string): Boolean;
var
  L: string;
begin
  { "Resumo/explicacao deste arquivo em Word/PDF/ODT" — compose, not chat RAG. }
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) and
     (not LooksLikeRichDocFormatAsk(L)) then
    Exit;
  { Filtered/aggregate counts are not a "file meaning → PDF" job. }
  if LooksLikeTabularSqlQuestion(FoldDiacriticsForMatch(L)) and
     (not LooksLikeSemanticFileQuestion(L)) and
     (not LooksLikeFilePurposeQuestion(AQuestion)) then
    Exit;
  if UserWantsComposeAsSavedDocument(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if not LooksLikeRichDocFormatAsk(L) then
    Exit;
  { Purpose/meaning/explain + saved rich doc = compose (any paraphrase / UI lang). }
  if LooksLikeExplainOrSummarizeAsk(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  { Size / dates / line count + PDF — local facts written into the document. }
  if (CollectOpenFileDiskMetaAsks(AQuestion) <> []) or
     UserAsksOpenFileTotalLineCount(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if not ContainsAnyToken(L,
    'resumo|summar|relatorio|report|visao geral|visão geral|overview|' +
    'explicar|explique|me explique|explain |describe |descreva|analisar|analise') then
    Exit;
  Result := True;
end;

function LooksLikeAskPythonAboutFile(const AQuestion, L: string): Boolean;
var
  Path: string;
begin
  Result := False;
  if LooksLikeHowToFastFile(L) then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  Path := ExtractPathFromUserText(AQuestion);
  if LooksLikeStrongFileQuestionFraming(L) then
  begin
    Result := True;
    Exit;
  end;
  if LooksLikeInterrogativeAsk(L) and
     ((Path <> '') or
      ContainsAnyToken(L, 'este arquivo|esse arquivo|deste arquivo|desse arquivo|' +
        'neste arquivo|nesse arquivo|this file|that file|o arquivo|' +
        'este archivo|ese archivo|ce fichier|cette fichier|' +
        'diese datei|questo file|quel file|ten plik|' +
        'este ficheiro|esse ficheiro|acest fisier|ez a fajl|tento soubor')) then
    Result := True;
end;

function UserWantsConsumerRAGContentQuestion(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserWantsFileSummaryToDocument(AQuestion) then Exit;
  if UserWantsComposeAsSavedDocument(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if LooksLikeHowToFastFile(L) then Exit;
  if LooksLikeTabularSqlQuestion(L) then Exit;
  if LooksLikeSemanticFileQuestion(L) then
  begin
    Result := True;
    Exit;
  end;
  Result := LooksLikeAskPythonAboutFile(AQuestion, L);
end;

function UserWantsConsumerAIContentQuestion(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  { File-meaning → Word/PDF stays compose; data aggregates may still say "gerar PDF". }
  if UserWantsFileSummaryToDocument(AQuestion) then Exit;
  if UserWantsComposeAsSavedDocument(AQuestion) and
     (not LooksLikeTabularSqlQuestion(FoldDiacriticsForMatch(L))) then
    Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if LooksLikeHowToFastFile(L) then Exit;
  if LooksLikeSemanticFileQuestion(L) then Exit;
  if LooksLikeTabularSqlQuestion(FoldDiacriticsForMatch(L)) then
  begin
    Result := True;
    Exit;
  end;
end;

function StripWindowsPathsFromText(const S: string): string;
var
  i, q: Integer;
  Ch: Char;
  Quoted: string;
begin
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    if S[i] in ['"', ''''] then
    begin
      Ch := S[i];
      q := i + 1;
      while (q <= Length(S)) and (S[q] <> Ch) do Inc(q);
      if q > Length(S) then
      begin
        Result := Result + Copy(S, i, MaxInt);
        Exit;
      end;
      Quoted := Trim(Copy(S, i + 1, q - i - 1));
      if not ((Length(Quoted) >= 3) and (Quoted[2] = ':') and (Quoted[3] in ['\', '/'])) then
        Result := Result + Copy(S, i, q - i + 1);
      i := q + 1;
    end
    else if (i <= Length(S) - 2) and (S[i] in ['A'..'Z', 'a'..'z']) and
            (S[i + 1] = ':') and (S[i + 2] in ['\', '/']) then
    begin
      Inc(i, 3);
      while (i <= Length(S)) and not (S[i] in [#0..#32, '"', '''', ',', ';', '?', '!']) do
        Inc(i);
    end
    else
    begin
      Result := Result + S[i];
      Inc(i);
    end;
  end;
end;

function CollapseQuestionSpaces(const S: string): string;
var
  i: Integer;
  LastSpace: Boolean;
begin
  Result := '';
  LastSpace := False;
  for i := 1 to Length(S) do
  begin
    if S[i] <= ' ' then
    begin
      if not LastSpace then
        Result := Result + ' ';
      LastSpace := True;
    end
    else
    begin
      Result := Result + S[i];
      LastSpace := False;
    end;
  end;
  Result := Trim(Result);
  while (Length(Result) > 0) and (Result[1] in [',', ';', ':', '-', '.']) do
    Delete(Result, 1, 1);
  Result := Trim(Result);
end;

function SanitizeQuestionForConsumerPython(const AQuestion: string; AForRAG: Boolean): string;
var
  S: string;
begin
  { Python already has the file loaded. Paths in the question make RAG search
    for the path text inside the file (and fail). }
  S := StripWindowsPathsFromText(Trim(AQuestion));
  S := StringReplace(S, 'com relação ao arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'com relacao ao arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em relação ao arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em relacao ao arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'a respeito deste arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'a respeito desse arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'a respeito do arquivo', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'regarding the file', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'with regard to the file', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'about the file', '', [rfReplaceAll, rfIgnoreCase]);
  S := CollapseQuestionSpaces(S);
  if AForRAG and (LooksLikeFilePurposeQuestion(AQuestion) or
     LooksLikeFilePurposeQuestion(S) or (S = '') or (S = '?')) then
  begin
    { Exact phrase the shipped ConsumerRAG treats as overview, not lexical search. }
    Result := 'O que este arquivo faz?';
    Exit;
  end;
  if S = '' then
  begin
    if AForRAG then
      Result := 'O que este arquivo faz?'
    else
      Result := Trim(AQuestion);
    Exit;
  end;
  Result := S;
end;

function ConsumerExplicitOpenRAGPanel(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(AQuestion));
  Result := ContainsAnyToken(L,
    'chat avancado|advanced ai|ctrl+alt+r|consumer rag|ia avancada|' +
    'chat ia avancado|advanced ai chat');
end;

function ConsumerExplicitOpenAIPanel(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(AQuestion));
  Result := ContainsAnyToken(L,
    'chat sql|ctrl+shift+a|consumer ai|ai chat sql|perguntar ao sql|' +
    'chat ia sql');
end;

{ Conservative gate before launching ConsumerRAG.exe — blocks native tool verbs and
  bare "? + this file" without clear content/meaning intent. }
function ConsumerRAGPlanAllowed(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := FoldDiacriticsForMatch(AQuestion);
  if L = '' then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then Exit;
  if UserWantsComposeDocument(AQuestion) or UserWantsFileSummaryToDocument(AQuestion) or
     UserWantsComposeAsSavedDocument(AQuestion) then Exit;
  if LooksLikeTabularSqlQuestion(L) then Exit;
  if ConsumerExplicitOpenRAGPanel(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if LooksLikeSemanticFileQuestion(L) or LooksLikeFilePurposeQuestion(AQuestion) or
     LooksLikeStrongFileQuestionFraming(L) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsConsumerRAGContentQuestion(AQuestion) then
  begin
    Result := ContainsAnyToken(L,
      'resumo|summar|explique|explain|descreva|describe|overview|visao geral|' +
      'conteudo|content|meaning|significado|analise|analyze|interpret|interpretar|' +
      'pra que|para que|what is|what does|do que se trata|de que se trata');
    Exit;
  end;
end;

function ConsumerAIPlanAllowed(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := FoldDiacriticsForMatch(AQuestion);
  if L = '' then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then Exit;
  if UserWantsComposeDocument(AQuestion) or UserWantsFileSummaryToDocument(AQuestion) then Exit;
  if ConsumerExplicitOpenAIPanel(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if LooksLikeSemanticFileQuestion(L) and not LooksLikeTabularSqlQuestion(L) then Exit;
  Result := LooksLikeTabularSqlQuestion(L) or UserWantsConsumerAIContentQuestion(AQuestion);
end;

function UserWantsShowConsumerRAG(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserWantsConsumerRAGContentQuestion(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'chat avancado|advanced ai|ctrl+alt+r|consumer rag|ia avancada|' +
    'chat ia avancado|advanced ai chat');
end;

function UserWantsShowConsumerAI(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserWantsShowConsumerRAG(AQuestion) then Exit;
  if UserWantsConsumerAIContentQuestion(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  Result := ContainsAnyToken(L,
    'chat sql|ctrl+shift+a|consumer ai|ai chat sql|perguntar ao sql|' +
    'chat ia sql');
end;

function UserWantsComposeDocument(const AQuestion: string): Boolean;
var
  L, Dummy: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserWantsComposeSourceCode(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserWantsCatalogExportLineRange(AQuestion, Dummy) then Exit;
  if UserWantsFileSummaryToDocument(AQuestion) or UserWantsComposeAsSavedDocument(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsShowConsumerRAG(AQuestion) or UserWantsShowConsumerAI(AQuestion) then
    Exit;
  Result := ContainsAnyToken(L,
    'gere um documento|gera um documento|gerar um documento|escreva um documento|' +
    'escrever um documento|documento avulso|gerar documento avulso|' +
    'gere um relatorio|gera um relatorio|gerar um relatorio|escreva um relatorio|' +
    'gere um readme|gera um readme|gerar readme|escreva um readme|write a readme|' +
    'gere um codigo|gera um codigo|gerar codigo|escreva um codigo|escrever um codigo|' +
    'gere um programa|gera um programa|gerar um programa|escreva um programa|' +
    'programa em python|programa python|classe em java|classe em javascript|' +
    'classe em typescript|componente react|componente angular|' +
    'gere um .pas|gera um .pas|gerar .pas|escreva um .pas|write a pascal|' +
    'gere um .py|gera um .py|gerar .py|escreva um .py|' +
    'gere um .js|gere um .ts|gere um .go|gere um .java|gere um .cpp|' +
    'gere um .md|gera um .md|gerar markdown|escreva um markdown|generate a markdown|' +
    'compose a document|generate a document|write a document|' +
    'generate source code|create a source file|generate a python program|' +
    'create a java class|write a go program|create a react component');
end;

function LooksLikeComposeFixVerb(const L: string): Boolean;
begin
  Result := ContainsAnyToken(L,
    'arruma|arrumar|conserta|consertar|corrigir|corrija|' +
    'fix it|fix this|fix the|repair it|repair the|revise the');
end;

function UserWantsFixComposedDocument(const AQuestion: string): Boolean;
var
  L, Dummy: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserWantsShowConsumerRAG(AQuestion) or UserWantsShowConsumerAI(AQuestion) then
    Exit;
  if UserWantsCatalogExportLineRange(AQuestion, Dummy) then Exit;
  if UserWantsComposeDocument(AQuestion) then Exit;
  if ContainsAnyToken(L, 'linha |linhas |line ') then Exit;
  if not LooksLikeComposeFixVerb(L) then Exit;
  Result := ContainsAnyToken(L,
    'codigo gerado|documento gerado|arquivo gerado|readme gerado|' +
    'ficheiro gerado|generated file|generated code|generated document|' +
    'o que voce gerou|o que voce criou|esse codigo|este codigo|' +
    'this code|this document|este documento|esse documento|' +
    'esse readme|este readme|.pas|.py|.md|.dpr|.js|.ts|.tsx|.go|.java|.cpp|.cs|' +
    '.rtf|.docx|.odt|.pdf');
end;

function UserWantsShortComposeFix(const AQuestion: string): Boolean;
var
  L, Dummy: string;
begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;
  if Length(L) > 160 then Exit;
  if UserHasNativeFastFileToolIntent(AQuestion) then Exit;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
    Exit;
  if UserWantsShowConsumerRAG(AQuestion) or UserWantsShowConsumerAI(AQuestion) then
    Exit;
  if UserWantsCatalogExportLineRange(AQuestion, Dummy) then Exit;
  if UserWantsComposeDocument(AQuestion) then Exit;
  if ContainsAnyToken(L, 'linha |linhas |line ') then Exit;
  if UserWantsFixComposedDocument(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if not LooksLikeComposeFixVerb(L) then Exit;
  if (PosBMH('.txt', L) > 0) then Exit;
  if ContainsAnyToken(L, 'arquivo|ficheiro|file ') and
     not ContainsAnyToken(L, 'gerado|generated|codigo|code|documento|readme|.pas|.py|.md') then
    Exit;
  Result := True;
end;

function UserAsksValidateSupportedLanguages(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  { "quais linguagens ... valida?" — match "valida" without a trailing space. }
  if not ContainsAnyToken(L,
    'validar|validacao|valida|validate|validation|syntax|sintaxe|' +
    'pruefen|prufung|convalid|walidac|waliduj|valideaz|ellenoriz|overit') then
    Exit;
  Result := ContainsAnyToken(L,
    'linguagem|linguagens|linguas|language|languages|lenguaje|lenguajes|' +
    'langage|langages|sprache|sprachen|linguaggio|linguaggi|jezyk|jezyki|' +
    'limbaj|limbaje|nyelv|nyelvek|jazyk|jazyky|programacao|programming|' +
    'quais |which |que lenguajes|que linguagens|suportad|supported|' +
    'atualmente valida|currently validate|pode validar|can validate|' +
    'aplicacao valida|app valida|ela valida|hoje valida|' +
    'aceita validar|tipos de arquivo|file types|extensoes|extensions');
end;

function UserWantsValidateSource(const AQuestion: string): Boolean;
var
  L, Path: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  { Language-list questions are answered locally without running validate. }
  if UserAsksValidateSupportedLanguages(AQuestion) and
     not ContainsAnyToken(L, 'carregar|load |abrir |open |validar este|validar esse|' +
       'validar o |validate this|validate the|check this|check the') then
    Exit;
  Result := ContainsAnyToken(L,
    'validar fonte|validar o fonte|validar o codigo|validar codigo|' +
    'validar sintaxe|verificar sintaxe|checar sintaxe|' +
    'carregar o fonte pra validar|carregar fonte para validar|' +
    'carregar o fonte para validar|carregar fonte pra validar|' +
    'recarregar o fonte|recarregar fonte|recarregar algum fonte|' +
    'recarregar um fonte|recarregar o codigo|reload source|' +
    'reload the source|reload file to validate|' +
    'validate source|validate the source|validate this source|' +
    'check syntax|syntax check|load source to validate|load file to validate|' +
    'validar fuente|comprobar sintaxis|cargar fuente para validar|' +
    'valider le source|verifier la syntaxe|charger le source pour valider|' +
    'quellcode pruefen|syntax pruefen|quelldatei zum pruefen|' +
    'validare sorgente|controlla sintassi|carica sorgente da validare|' +
    'waliduj zrodlo|sprawdz skladnie|zaladuj zrodlo do walidacji|' +
    'valideaza sursa|verifica sintaxa|incarca sursa pentru validare|' +
    'forras ellenorzese|szintaxis ellenorzese|forras betoltese ellenorzeshez|' +
    'overit zdroj|zkontrolovat syntax|nacist zdroj k overeni|' +
    'validar este arquivo|validar esse arquivo|validar este ficheiro|' +
    'validar esse codigo|validate this file|validate that file');
  if Result then Exit;
  Path := ExtractPathFromUserText(AQuestion);
  if (Path <> '') and IsValidatableComposeSourcePath(Path) and
     ContainsAnyToken(L, 'validar|validate|sintaxe|syntax|pruefen|convalid|' +
       'waliduj|valideaz|ellenoriz|overit') then
    Result := True;
end;

function UserWantsLoadSourceToValidate(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  if not UserWantsValidateSource(AQuestion) then Exit;
  Result := ContainsAnyToken(L,
    'carregar|recarregar|reload |load |abrir fonte|open source|pick |escolher|selecionar|' +
    'cargar|charger|laden|carica |zaladuj|incarca|betoltes|nacist|' +
    'pra validar|para validar|to validate|zum pruefen|da validare|' +
    'do walidacji|pentru validare|ellenorzeshez|k overeni|' +
    'algum fonte|um fonte|outro fonte|outro arquivo');
end;

function UserHasSpecificToolIntent(const AQuestion: string): Boolean;
var
  L, Dummy: string;
begin
  L := LowerCase(Trim(AQuestion));
  Result := False;
  if L = '' then Exit;
  if UserWantsShowScriptEngine(AQuestion) then begin Result := True; Exit; end;
  if UserWantsShowTailMacro(AQuestion) then begin Result := True; Exit; end;
  if UserWantsFileSummaryToDocument(AQuestion) or UserWantsComposeDocument(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsShowConsumerRAG(AQuestion) then begin Result := True; Exit; end;
  if UserWantsShowConsumerAI(AQuestion) then begin Result := True; Exit; end;
  if UserWantsFixComposedDocument(AQuestion) or UserWantsShortComposeFix(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsCatalogExportLineRange(AQuestion, Dummy) then begin Result := True; Exit; end;
  Result := ContainsAnyToken(L,
    'script engine|motor de script|macros python|macro python|' +
    'rodar python|executar python|run python|python para|' +
    'dividir|partir o arquivo|particionar|extrair parte|partes iguais|' +
    'split into|split file|split equal|split files|' +
    'unir linhas|juntar linhas|mesclar|merge files|merge lines|' +
    'comparar|compare files|diff arquivos|' +
    'exportar|gerar um novo|criar um novo|somente com as linhas|' +
    'filtrar|filtro|grep|substituir|replace all|find and replace|' +
    'iniciar tail|start tail|follow mode|seguir o arquivo|monitorar o arquivo|' +
    'ir para linha|goto line|editar linha|apagar linha|inserir linha|' +
    'marcador|bookmark|word wrap|quebra de linha|' +
    'modo csv|colunas csv|zoom|tela cheia|fullscreen|' +
    'duplicad|strings frequente|zero scan|indexar|forcar indice|' +
    'procurar em|buscar em|localizar|find in files|' +
    'com relacao ao arquivo|com relação ao arquivo|regarding the file|' +
    'pra que serve|para que serve|quantas linhas|chat avancado|chat sql|' +
    'gere um documento|documento avulso|gerar codigo|codigo fonte');
end;

{ Only Ctrl/F-key shortcuts and very short toolbar labels skip the LLM. }
function UserQuestionIsExplicitLocalShortcut(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := Trim(AQuestion);
  if L = '' then Exit;
  L := FoldDiacriticsForMatch(L);
  L := StringReplace(L, '-', ' ', [rfReplaceAll]);
  while Pos('  ', L) > 0 do
    L := StringReplace(L, '  ', ' ', [rfReplaceAll]);

  if ContainsAnyToken(L,
    'ctrl+shift+j|ctrl+shift+m|ctrl+shift+k|ctrl+shift+p|ctrl+shift+h|' +
    'ctrl+alt+p|ctrl+alt+e|ctrl+alt+r|ctrl+shift+a|ctrl+shift+f|' +
    'ctrl+shift+l|ctrl+shift+d|ctrl+o|ctrl+g|ctrl+w|f1|f5|f11') then
  begin
    Result := True;
    Exit;
  end;

  if (Length(L) <= 24) and ContainsAnyToken(L,
    'merge files|split files|find in files|export file|reload file|open file|' +
    'mesclar arquivos|juntar arquivos|dividir arquivos|unir ficheiros') then
    Result := True;
end;

{ Total line/row count of the open file (not filtered/SQL aggregates). 11 UI langs. }
function UserAsksOpenFileTotalLineCount(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  { Filtered / aggregate / column / prefix questions stay on ConsumerAI. }
  if ContainsAnyToken(L,
    'where |onde |distinct|unicos|unicas|unique |group by|agrupar|' +
    'soma |somar |somatorio|somatoria|media |average |avg |maximo |minimo |' +
    'coluna |column |campo |percentual|porcentagem|nulos|null values|vazios|' +
    'empty values|top n |linhas onde|registros com |com o valor|com valor|' +
    'se iniciam|se inicia|iniciam pelo|inicia pelo|iniciam com|inicia com|' +
    'comecam com|comeca com|comecam pelo|start with|starts with|starting with|' +
    'prefixo |prefix |pelo valor|pelo codigo|pelo código') then
    Exit;
  Result := ContainsAnyToken(L,
    'quantas linhas|quantos registros|quantas rows|how many lines|' +
    'how many rows|how many records|contar linhas|contar registros|' +
    'total de linhas|total de registros|numero de linhas|number of lines|' +
    'line count|row count|combien de lignes|combien de enregistrements|' +
    'wie viele zeilen|wieviele zeilen|anzahl der zeilen|anzahl zeilen|' +
    'quante righe|quante linee|numero di righe|ile linii|ile wierszy|' +
    'liczba linii|cate linii|numarul de linii|hány sor|sorok szama|' +
    'kolik radku|pocet radku|cuantas lineas|cuantos registros|' +
    'numero de lineas|nombre de lignes');
end;

{ "this/that/the open file" without an explicit Windows path (11 UI langs). }
function UserQuestionImpliesOpenFile(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  if ExtractPathFromUserText(AQuestion) <> '' then
    Exit; { explicit path — not "implied" }
  Result := ContainsAnyToken(L,
    'esse arquivo|este arquivo|deste arquivo|desse arquivo|neste arquivo|nesse arquivo|' +
    'daquele arquivo|do arquivo|no arquivo|ao arquivo|arquivo aberto|' +
    'esse ficheiro|este ficheiro|deste ficheiro|desse ficheiro|ficheiro aberto|' +
    'this file|that file|the file|current file|opened file|' +
    'este archivo|ese archivo|el archivo|archivo abierto|' +
    'ce fichier|le fichier|fichier ouvert|cette fichier|' +
    'diese datei|die datei|dieser datei|offene datei|' +
    'questo file|quel file|il file|file aperto|' +
    'ten plik|tym pliku|plik otwarty|' +
    'acest fisier|fisierul|fisier deschis|' +
    'ez a fajl|a fajl|megnyitott fajl|' +
    'tento soubor|souboru|otevreny soubor');
end;

function UserQuestionUsesOpenFilePronoun(const AQuestion: string): Boolean;
var
  L: string;
begin
  Result := False;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  Result := ContainsTokenAsWord(L, 'dele') or ContainsTokenAsWord(L, 'dela') or
    ContainsTokenAsWord(L, 'desse') or ContainsTokenAsWord(L, 'desta') or
    ContainsTokenAsWord(L, 'nele') or ContainsTokenAsWord(L, 'nela') or
    ContainsAnyToken(L,
      'do mesmo|da mesma|of it|its |thereof|davon|di esso|di essa|' +
      'jego |jej |acestuia|acesteia|ennek a|annak a|jeho |jeji ');
end;

function DetectOpenFileDiskMetaAsk(const AQuestion: string): TAssistantOpenFileMetaKind;
var
  L: string;
begin
  Result := aofmNone;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;

  if ContainsAnyToken(L,
    'propriedades do arquivo|propriedades do ficheiro|propriedades dele|' +
    'detalhes do arquivo|detalhes dele|info do arquivo|informacoes do arquivo|' +
    'informacao do arquivo|file properties|file info|file details|file metadata|' +
    'metadados do|atributos do arquivo|propiedades del archivo|' +
    'proprietes du fichier|dateieigenschaften|proprieta del file|' +
    'wlasciwosci pliku|informatii despre fisier|fajl tulajdonsagok|' +
    'vlastnosti souboru') then
  begin
    Result := aofmProps;
    Exit;
  end;

  if ContainsAnyToken(L,
    'data de criacao|data da criacao|data criacao|criado em|criacao do|' +
    'criacao dele|quando foi criado|quando criou|quando criado|' +
    'creation date|created on|date created|file created|when created|' +
    'when was it created|fecha de creacion|fecha creacion|creado el|' +
    'date de creation|date creation|cree le|quand a t il ete cree|' +
    'erstellungsdatum|erstellt am|wann erstellt|data di creazione|' +
    'creato il|quando creato|data utworzenia|utworzony|kiedy utworzony|' +
    'data crearii|creat la|letrehozas|letrehozva|datum vytvoreni|vytvoren') then
  begin
    Result := aofmCreated;
    Exit;
  end;

  if ContainsAnyToken(L,
    'data de modificacao|data da modificacao|data de alteracao|data da alteracao|' +
    'ultima modificacao|ultima alteracao|modificado em|alterado em|' +
    'modificacao dele|alteracao dele|quando foi modificado|quando foi alterado|' +
    'last modified|modification date|date modified|modified on|when modified|' +
    'when was it modified|fecha de modificacion|ultima modificacion|' +
    'date de modification|modifie le|anderungsdatum|geandert am|' +
    'data di modifica|modificato il|data modyfikacji|zmodyfikowany|' +
    'data modificarii|modificat la|modositas|modositva|datum zmeny|zmenen') then
  begin
    Result := aofmModified;
    Exit;
  end;

  if ContainsAnyToken(L,
    'data de acesso|ultimo acesso|ultima vez acessado|foi acessado|quando foi acessado|' +
    'quando acessou|acessado pela ultima|last access|accessed|date accessed|' +
    'when accessed|when was it accessed|fecha de acceso|dernier acces|' +
    'zugriffsdatum|ultimo accesso|data dostepu|ultimul acces|utolso hozzaferes|' +
    'datum pristupu') then
  begin
    Result := aofmAccessed;
    Exit;
  end;

  if ContainsAnyToken(L,
    'tamanho do arquivo|tamanho do ficheiro|tamanho dele|qual o tamanho|' +
    'o tamanho|tamanho em bytes|quanto pesa|quanto ocupa|quantos bytes|' +
    'file size|how big|how large|size of the file|bytes do arquivo|' +
    'how many bytes|tamano del archivo|taille du fichier|' +
    'dateigroesse|dateigroße|wie gross|dimensione del file|' +
    'rozmiar pliku|dimensiunea fisierului|fajlmeret|velikost souboru') then
    Result := aofmSize;
end;

function CollectOpenFileDiskMetaAsks(const AQuestion: string): TAssistantOpenFileMetaKinds;
var
  L: string;
begin
  Result := [];
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;

  if ContainsAnyToken(L,
    'propriedades do arquivo|propriedades do ficheiro|propriedades dele|' +
    'detalhes do arquivo|detalhes dele|info do arquivo|informacoes do arquivo|' +
    'informacao do arquivo|file properties|file info|file details|file metadata|' +
    'metadados do|atributos do arquivo|propiedades del archivo|' +
    'proprietes du fichier|dateieigenschaften|proprieta del file|' +
    'wlasciwosci pliku|informatii despre fisier|fajl tulajdonsagok|' +
    'vlastnosti souboru') then
  begin
    Result := [aofmProps];
    Exit;
  end;

  if ContainsAnyToken(L,
    'data de criacao|data da criacao|data criacao|criado em|criacao do|' +
    'criacao dele|quando foi criado|quando criou|quando criado|' +
    'creation date|created on|date created|file created|when created|' +
    'when was it created|fecha de creacion|fecha creacion|creado el|' +
    'date de creation|date creation|cree le|quand a t il ete cree|' +
    'erstellungsdatum|erstellt am|wann erstellt|data di creazione|' +
    'creato il|quando creato|data utworzenia|utworzony|kiedy utworzony|' +
    'data crearii|creat la|letrehozas|letrehozva|datum vytvoreni|vytvoren') then
    Include(Result, aofmCreated);

  if ContainsAnyToken(L,
    'data de modificacao|data da modificacao|data de alteracao|data da alteracao|' +
    'ultima modificacao|ultima alteracao|modificado em|alterado em|' +
    'modificacao dele|alteracao dele|quando foi modificado|quando foi alterado|' +
    'last modified|modification date|date modified|modified on|when modified|' +
    'when was it modified|fecha de modificacion|ultima modificacion|' +
    'date de modification|modifie le|anderungsdatum|geandert am|' +
    'data di modifica|modificato il|data modyfikacji|zmodyfikowany|' +
    'data modificarii|modificat la|modositas|modositva|datum zmeny|zmenen') then
    Include(Result, aofmModified);

  if ContainsAnyToken(L,
    'data de acesso|ultimo acesso|ultima vez acessado|foi acessado|quando foi acessado|' +
    'quando acessou|acessado pela ultima|last access|accessed|date accessed|' +
    'when accessed|when was it accessed|fecha de acceso|dernier acces|' +
    'zugriffsdatum|ultimo accesso|data dostepu|ultimul acces|utolso hozzaferes|' +
    'datum pristupu') then
    Include(Result, aofmAccessed);

  if ContainsAnyToken(L,
    'tamanho do arquivo|tamanho do ficheiro|tamanho dele|qual o tamanho|' +
    'o tamanho|tamanho em bytes|quanto pesa|quanto ocupa|quantos bytes|' +
    'file size|how big|how large|size of the file|bytes do arquivo|' +
    'how many bytes|tamano del archivo|taille du fichier|' +
    'dateigroesse|dateigroße|wie gross|dimensione del file|' +
    'rozmiar pliku|dimensiunea fisierului|fajlmeret|velikost souboru') then
    Include(Result, aofmSize);
end;

function UserQuestionRefersToOpenFile(const AQuestion: string): Boolean;
var
  Explicit, OpenPath: string;
begin
  Result := False;
  Explicit := ExtractPathFromUserText(AQuestion);
  OpenPath := AssistantHostGetOpenFilePath;
  if Explicit <> '' then
  begin
    Result := (OpenPath = '') or SameText(Explicit, OpenPath);
    Exit;
  end;
  if UserQuestionImpliesOpenFile(AQuestion) or UserQuestionUsesOpenFilePronoun(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  { Disk/line facts with edtFileName filled (or empty → caller shows NoFileOpen). }
  if (DetectOpenFileDiskMetaAsk(AQuestion) <> aofmNone) or
     (CollectOpenFileDiskMetaAsks(AQuestion) <> []) or
     UserAsksOpenFileTotalLineCount(AQuestion) then
    Result := True;
end;

function UserQuestionNeedsLlmBeyondLocalFileFacts(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Local line/date/size answers only when that is the whole request.
    Extra FastFile work (any of the 11 languages) goes to the LLM.
    Do not require Portuguese verbs: format ids and long digit needles are enough. }
  Result := False;
  L := FoldDiacriticsForMatch(Trim(AQuestion));
  if L = '' then Exit;
  if LooksLikeRichDocFormatAsk(L) or QuestionHasLongDigitNeedle(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserHasNativeFastFileToolIntent(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsComposeDocument(AQuestion) or UserWantsFileSummaryToDocument(AQuestion) or
     UserWantsComposeAsSavedDocument(AQuestion) or UserWantsComposeSourceCode(AQuestion) or
     UserWantsComposePythonSource(AQuestion) or UserWantsFixComposedDocument(AQuestion) or
     UserWantsAggregateResultsAsDocument(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if UserWantsShowScriptEngine(AQuestion) or UserWantsShowTailMacro(AQuestion) then
  begin
    Result := True;
    Exit;
  end;
  if LooksLikeSemanticFileQuestion(L) or LooksLikeFilePurposeQuestion(AQuestion) or
     LooksLikeFileMathOrDataOp(AQuestion) or LooksLikeTabularSqlQuestion(L) then
    Result := True;
end;

function UserWantsAggregateResultsAsDocument(const AQuestion: string): Boolean;
var
  L: string;
begin
  { Any file math/data op + "gerar PDF/Word/…" → ConsumerAI then save results doc.
    Dynamic compound asks ("calcule X e tb me gere um PDF").
    Not the same as "explain this file in a PDF" (compose sample pipeline). }
  Result := False;
  if not LooksLikeFileMathOrDataOp(AQuestion) then Exit;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if LooksLikeSemanticFileQuestion(L) or LooksLikeFilePurposeQuestion(AQuestion) then
    Exit;
  if not LooksLikeRichDocFormatAsk(L) then Exit;
  Result := True;
end;

function StripRichDocAskFromQuestion(const AQuestion: string): string;
var
  S: string;
begin
  { Keep the data/math question for ConsumerAI; drop "gerar/salvar em PDF/Word…". }
  S := Trim(AQuestion);
  S := StringReplace(S, 'e tb me gere um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'e tambem me gere um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'e também me gere um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'e tb me gere', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'e tambem me gere', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'e também me gere', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'and also generate a pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'and also generate', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar num pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gere um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gera um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerando um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em um pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'num pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'to pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'as pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'as a pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'generate a pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar um word', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar word', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em word', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar um docx', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar docx', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'gerar odt', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em odt', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'em rtf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'salvar em pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, 'salve em pdf', '', [rfReplaceAll, rfIgnoreCase]);
  S := CollapseQuestionSpaces(S);
  while (Length(S) > 0) and (S[Length(S)] in [',', ';', '.', ' ']) do
    SetLength(S, Length(S) - 1);
  Result := Trim(S);
  if Result = '' then
    Result := Trim(AQuestion);
end;

function TryParseLinePrefixCountAsk(const AQuestion: string;
  out APrefixes: TStringDynArray): Boolean;
var
  L, Src: string;
  List: TStringList;
  j, i: Integer;

  procedure CollectAfter(const ANeedle: string);
  var
    At, k: Integer;
    T: string;
  begin
    At := PosBMH(ANeedle, L);
    while At > 0 do
    begin
      k := At + Length(ANeedle);
      while (k <= Length(Src)) and (Src[k] in [' ', #9, '"', '''', '=']) do
        Inc(k);
      T := '';
      while (k <= Length(Src)) and (Src[k] in ['0'..'9', 'A'..'Z', 'a'..'z', '_']) do
      begin
        T := T + Src[k];
        Inc(k);
      end;
      if Length(T) >= 2 then
        List.Add(T);
      At := PosBMHFrom(ANeedle, L, At + Length(ANeedle));
    end;
  end;

  procedure CollectDigitRuns;
  var
    Tail: string;
  begin
    i := 1;
    while i <= Length(Src) do
    begin
      if Src[i] in ['0'..'9'] then
      begin
        j := i;
        while (j <= Length(Src)) and (Src[j] in ['0'..'9']) do
          Inc(j);
        if (j - i) >= 3 then
        begin
          { Skip "100 primeiras linhas" / "first 100 lines" sample-size cues. }
          Tail := LowerCase(FoldDiacriticsForMatch(Copy(Src, j, 48)));
          if (Pos('primeiras', Tail) = 0) and (Pos('primeras', Tail) = 0) and
             (Pos('first ', Tail) = 0) and (Pos('ersten', Tail) = 0) and
             (Pos('premieres', Tail) = 0) and (Pos('primi ', Tail) = 0) then
            List.Add(Copy(Src, i, j - i));
        end;
        i := j;
      end
      else
        Inc(i);
    end;
  end;

begin
  Result := False;
  SetLength(APrefixes, 0);
  Src := Trim(AQuestion);
  if Src = '' then Exit;
  L := LowerCase(Src);
  { Generic NL cues (any UI language) — not a fixed sample sentence. }
  if not ContainsAnyToken(FoldDiacriticsForMatch(L),
    'iniciam|inicia |comecam|comeca |comienzan|comienza |comienzan por|empieza|empiezan|' +
    'commencent|commence |beginnen|beginnt |iniziano|inizia |zaczynaja|zaczyna |' +
    'incep cu|incepe cu|kezdodnek|kezdodik|zacinaji|zacina |' +
    'start with|starts with|starting with|startswith|prefixo|prefix |prefijo') then
    Exit;
  if not ContainsAnyToken(FoldDiacriticsForMatch(L),
    'quantas|quantos|cuantas|cuantos|combien|wie viele|quante|quanti|ile |cate |' +
    'hány|hany |kolik|contar|contagem|contare|conta |conte |somatorio|soma |' +
    'how many|count |numero de|número de|' +
    'zahlen|zahle |zaehle|zaehlen|zaehl ') then
    Exit;

  List := TStringList.Create;
  try
    List.Sorted := True;
    List.Duplicates := dupIgnore;
    CollectAfter('pelo valor ');
    CollectAfter('pelo valor');
    CollectAfter('com o valor ');
    CollectAfter('com valor ');
    CollectAfter('con el valor ');
    CollectAfter('con valor ');
    CollectAfter('comecam com ');
    CollectAfter('comeca com ');
    CollectAfter('iniciam com ');
    CollectAfter('inicia com ');
    CollectAfter('iniciam pelo ');
    CollectAfter('inicia pelo ');
    CollectAfter('quantas com ');
    CollectAfter('quantos com ');
    CollectAfter('e quantas com ');
    CollectAfter('e quantos com ');
    CollectAfter('tambien com ');
    CollectAfter('também com ');
    CollectAfter('tb com ');
    CollectAfter('comienzan con ');
    CollectAfter('comienza con ');
    CollectAfter('empiezan con ');
    CollectAfter('empieza con ');
    CollectAfter('cuantas con ');
    CollectAfter('y cuantas con ');
    CollectAfter('commencent par ');
    CollectAfter('commence par ');
    CollectAfter('beginnen mit ');
    CollectAfter('beginnt mit ');
    CollectAfter('die mit ');
    CollectAfter('zeilen die mit ');
    CollectAfter('iniziano con ');
    CollectAfter('inizia con ');
    CollectAfter('start with ');
    CollectAfter('starts with ');
    CollectAfter('starting with ');
    CollectAfter('startswith ');
    CollectAfter('and with ');
    CollectAfter('and also with ');
    CollectAfter('prefixo ');
    CollectAfter('prefijo ');
    CollectAfter('prefix ');
    { Always merge digit runs (>= 3). Phrase cues alone often catch only the
      first value ("iniciam com X e quantas com Y"). }
    CollectDigitRuns;
    if List.Count = 0 then Exit;
    SetLength(APrefixes, List.Count);
    for i := 0 to List.Count - 1 do
      APrefixes[i] := List[i];
    Result := True;
  finally
    List.Free;
  end;
end;

function ExtractQuotedNeedlesFromText(const AQuestion: string): string;
var
  Src, Body: string;
  List: TStringList;
  i, q: Integer;
  Ch: Char;
begin
  { Structural delimiters only — AI supplies the needle in filter_text; this fills
    gaps when the model left filter_text empty but quoted the term. }
  Result := '';
  Src := Trim(AQuestion);
  if Src = '' then Exit;
  List := TStringList.Create;
  try
    List.Sorted := True;
    List.Duplicates := dupIgnore;
    i := 1;
    while i <= Length(Src) do
    begin
      if Src[i] in ['"', '''', '`'] then
      begin
        Ch := Src[i];
        q := i + 1;
        while (q <= Length(Src)) and (Src[q] <> Ch) do
          Inc(q);
        if q <= Length(Src) then
        begin
          Body := Trim(Copy(Src, i + 1, q - i - 1));
          if (Body <> '') and (Length(Body) <= 64) and (Pos('?', Body) = 0) then
            if not QuotedNeedleLooksLikeFileName(Body) then
              List.Add(Body);
          i := q + 1;
        end
        else
          Inc(i);
      end
      else
        Inc(i);
    end;
    for i := 0 to List.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + '|';
      Result := Result + List[i];
    end;
  finally
    List.Free;
  end;
end;

{ Conversational NL (any of 11 UI langs) → LLM on Send, not local auto-execute. }
function UserQuestionLooksLikeNaturalLanguage(const AQuestion: string): Boolean;
begin
  { AI-first: anything that is not an explicit shortcut is treated as NL. }
  Result := not UserQuestionIsExplicitLocalShortcut(AQuestion);
end;

function PartsCountFromWordToken(const W: string): Integer;
var
  T: string;
begin
  Result := 0;
  T := LowerCase(Trim(W));
  if T = '' then Exit;
  { Strip common accented forms by checking both ASCII and #nnn variants. }
  if (T = 'dois') or (T = 'duas') or (T = 'two') or (T = 'dos') or
     (T = 'deux') or (T = 'zwei') or (T = 'due') or (T = 'dwa') or
     (T = 'dwie') or (T = 'doua') or (T = 'ket') or (T = 'ketto') or
     (T = 'kett'#337) or (T = 'dva') or (T = 'dve') then
    Result := 2
  else if (T = 'tres') or (T = 'tr'#234's') or (T = 'three') or (T = 'trois') or
          (T = 'drei') or (T = 'tre') or (T = 'trzy') or (T = 'trei') or
          (T = 'harom') or (T = 'h'#225'rom') or (T = 'tri') then
    Result := 3
  else if (T = 'quatro') or (T = 'four') or (T = 'cuatro') or (T = 'quatre') or
          (T = 'vier') or (T = 'quattro') or (T = 'cztery') or (T = 'patru') or
          (T = 'negy') or (T = 'n'#233'gy') or (T = 'ctyri') then
    Result := 4
  else if (T = 'cinco') or (T = 'five') or (T = 'cinq') or (T = 'funf') or
          (T = 'f'#252'nf') or (T = 'cinque') or (T = 'piec') or (T = 'cinci') or
          (T = 'ot') or (T = #246't') or (T = 'pet') then
    Result := 5
  else if (T = 'seis') or (T = 'six') or (T = 'sechs') or (T = 'sei') or
          (T = 'szesc') or (T = 'sase') or (T = 'hat') or (T = 'sest') then
    Result := 6
  else if (T = 'sete') or (T = 'seven') or (T = 'siete') or (T = 'sept') or
          (T = 'sieben') or (T = 'sette') or (T = 'siedem') or (T = 'sapte') or
          (T = 'het') or (T = 'sedm') then
    Result := 7
  else if (T = 'oito') or (T = 'eight') or (T = 'ocho') or (T = 'huit') or
          (T = 'acht') or (T = 'otto') or (T = 'osiem') or (T = 'opt') or
          (T = 'nyolc') or (T = 'osm') then
    Result := 8
  else if (T = 'nove') or (T = 'nine') or (T = 'nueve') or (T = 'neuf') or
          (T = 'neun') or (T = 'dziewiec') or (T = 'noua') or (T = 'kilenc') or
          (T = 'devet') then
    Result := 9
  else if (T = 'dez') or (T = 'ten') or (T = 'diez') or (T = 'dix') or
          (T = 'zehn') or (T = 'dieci') or (T = 'dziesiec') or (T = 'zece') or
          (T = 'tiz') or (T = 't'#237'z') or (T = 'deset') then
    Result := 10;
end;

function ExtractPartsCountFromText(const AQuestion: string): Integer;
var
  L, Word: string;
  i, p, WordEdge: Integer;
  Num: string;

  function FindPartsKeywordPos(const S: string): Integer;
  begin
    Result := PosBMH(' partes', S);
    if Result = 0 then Result := PosBMH(' parts', S);
    if Result = 0 then Result := PosBMH(' parte', S);
    if Result = 0 then Result := PosBMH(' part', S);
    if Result = 0 then Result := PosBMH(' parties', S);
    if Result = 0 then Result := PosBMH(' teile', S);
    if Result = 0 then
    begin
      { " parti" matches Italian/RO; skip Portuguese "partir". }
      Result := PosBMH(' parti', S);
      if (Result > 0) and (Result + 6 <= Length(S)) and (S[Result + 6] = 'r') then
        Result := 0;
    end;
    if Result = 0 then Result := PosBMH(' czesci', S);
    if Result = 0 then Result := PosBMH(' casti', S);
    if Result = 0 then Result := PosBMH(' reszek', S);
  end;

begin
  Result := 0;
  L := LowerCase(AQuestion);
  p := FindPartsKeywordPos(L);
  if p > 0 then
  begin
    i := p - 1;
    while (i >= 1) and (L[i] = ' ') do Dec(i);
    Num := '';
    while (i >= 1) and (L[i] in ['0'..'9']) do
    begin
      Num := L[i] + Num;
      Dec(i);
    end;
    Result := StrToIntDef(Num, 0);
    if Result >= 2 then Exit;

    { Word before "part(e/s)": "duas partes", "two parts", "deux parties". }
    WordEdge := i;
    while (WordEdge >= 1) and (L[WordEdge] in ['a'..'z', #128..#255]) do Dec(WordEdge);
    Word := Copy(L, WordEdge + 1, i - WordEdge);
    Result := PartsCountFromWordToken(Word);
    if Result >= 2 then Exit;
  end;

  { "em 2" / "en dos" / "into two" / "in 3" / "na dwie". }
  p := PosBMH(' into ', L);
  if p > 0 then
    i := p + 6
  else
  begin
    p := PosBMH(' em ', L);
    if p > 0 then
      i := p + 4
    else
    begin
      p := PosBMH(' en ', L);
      if p > 0 then
        i := p + 4
      else
      begin
        p := PosBMH(' in ', L);
        if p = 0 then
        begin
          p := PosBMH(' na ', L);
          if p = 0 then Exit;
          i := p + 4;
        end
        else
          i := p + 4;
      end;
    end;
  end;
  while (i <= Length(L)) and (L[i] = ' ') do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
  if Result >= 2 then Exit;
  WordEdge := i;
  while (WordEdge <= Length(L)) and (L[WordEdge] in ['a'..'z', #128..#255]) do Inc(WordEdge);
  Word := Copy(L, i, WordEdge - i);
  Result := PartsCountFromWordToken(Word);
end;

function ExtractMaxRecordsFromText(const AQuestion: string): Integer;
var
  L, Num: string;
  p, i: Integer;

  function DigitsAfter(const Cue: string): Integer;
  var
    At, PosN: Integer;
    Dig: string;
  begin
    Result := 0;
    At := PosBMH(Cue, L);
    if At = 0 then Exit;
    PosN := At + Length(Cue);
    while (PosN <= Length(L)) and (L[PosN] in [' ', #9, ':', '=', '"', '''']) do Inc(PosN);
    Dig := '';
    while (PosN <= Length(L)) and (L[PosN] in ['0'..'9']) do
    begin
      Dig := Dig + L[PosN];
      Inc(PosN);
    end;
    Result := StrToIntDef(Dig, 0);
  end;

begin
  Result := 0;
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;
  Result := DigitsAfter('no maximo ');
  if Result = 0 then Result := DigitsAfter('maximo ');
  if Result = 0 then Result := DigitsAfter('at most ');
  if Result = 0 then Result := DigitsAfter('up to ');
  if Result = 0 then Result := DigitsAfter('max_lines ');
  if Result = 0 then Result := DigitsAfter('max_records ');
  if Result = 0 then
  begin
    p := PosBMH(' registros', L);
    if p = 0 then p := PosBMH(' records', L);
    if p > 0 then
    begin
      i := p - 1;
      while (i >= 1) and (L[i] = ' ') do Dec(i);
      Num := '';
      while (i >= 1) and (L[i] in ['0'..'9']) do
      begin
        Num := L[i] + Num;
        Dec(i);
      end;
      Result := StrToIntDef(Num, 0);
    end;
  end;
  if Result > 500 then Result := 500;
end;

function ParseMergeFilesModeFromQuestion(const AQuestion: string;
  out AModeIndex, AAfterLine: Integer): Boolean;
var
  L: string;
  N: Integer;
begin
  { AModeIndex: 0=beginning, 1=after line, 2=end. Result=True if user named a mode. }
  Result := False;
  AModeIndex := 0;
  AAfterLine := 1;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;

  if ContainsAnyToken(L,
    'no final|no fim|ao final|ao fim|at the end|at end|inserir no fim|' +
    'inserindo no fim|inserindo no final|inserir no final|append|no termine|' +
    'al final|au final|am ende|alla fine|na koncu|la sfarsit|a vegen|na konci') then
  begin
    AModeIndex := 2;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L,
    'depois da linha|apos a linha|após a linha|after line|after the line|' +
    'inserir apos|inserir após|inserindo apos|inserindo após') then
  begin
    AModeIndex := 1;
    N := ExtractLineNumberFromText(AQuestion);
    if N > 0 then
      AAfterLine := N;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L,
    'no comeco|no começo|no inicio|no início|ao comeco|ao começo|ao inicio|ao início|' +
    'inserindo no comeco|inserindo no começo|inserindo no inicio|inserindo no início|' +
    'inserir no comeco|inserir no começo|inserir no inicio|inserir no início|' +
    'at the beginning|at beginning|at the start|at start|first line') then
  begin
    AModeIndex := 0;
    Result := True;
  end;
end;

procedure FillStepFromMapHit(const AQuestion, AMappedId, APath, ASearchTxt, AFilterPat: string;
  ALineN: Integer; AByteOff: Int64; var AActionId: string; var AStep: TAssistantChainStep);
var
  L: string;
  MergeMode, AfterLine: Integer;
begin
  L := LowerCase(Trim(AQuestion));
  AActionId := AMappedId;
  if SameText(AActionId, 'open_and_read_file') and (APath = '') then
    AActionId := 'open_file_dialog';
  AStep.ActionId := AActionId;
  if APath <> '' then AStep.Path := APath;
  if ALineN > 0 then AStep.LineNo := ALineN;
  if AByteOff > 0 then AStep.ByteOffset := AByteOff;
  if ASearchTxt <> '' then AStep.FilterText := ASearchTxt;
  if (AStep.FilterText = '') and (AFilterPat <> '') then
    AStep.FilterText := AFilterPat;
  if SameText(AActionId, 'consumer_ai') then
  begin
    if UserWantsConsumerAIContentQuestion(AQuestion) then
      AStep.FilterText := SanitizeQuestionForConsumerPython(AQuestion, False)
    else
      AStep.FilterText := '';
  end
  else if SameText(AActionId, 'consumer_rag') then
  begin
    if UserWantsConsumerRAGContentQuestion(AQuestion) then
      AStep.FilterText := SanitizeQuestionForConsumerPython(AQuestion, True)
    else
      AStep.FilterText := '';
  end;
  AStep.Parts := ExtractPartsCountFromText(AQuestion);
  AStep.CaseSensitive := UserRequestedCaseSensitive(AQuestion);
  if SameText(AActionId, 'delete_line') and
     ContainsAnyToken(L, 'ultima linha|last line') then
    AStep.LineNo := 0;
  if SameText(AActionId, 'split_equal_parts') or
     SameText(AActionId, 'extract_file_parts') or
     SameText(AActionId, 'show_tab_merge_files') then
  begin
    if AStep.Path = '' then
      AStep.Path := AssistantHostGetOpenFilePath;
  end;
  if SameText(AActionId, 'show_tab_merge_files') then
  begin
    { LineNo = merge mode (-1 unset, 0/1/2); Parts = after-line when mode=1. }
    AStep.LineNo := -1;
    AStep.Parts := 1;
    if APath <> '' then
      AStep.Path := APath;
    if AStep.Path = '' then
      AStep.Path := AssistantHostGetOpenFilePath;
    if ParseMergeFilesModeFromQuestion(AQuestion, MergeMode, AfterLine) then
    begin
      AStep.LineNo := MergeMode;
      AStep.Parts := AfterLine;
    end;
  end;
end;

procedure InitStep(var St: TAssistantChainStep);
begin
  FillChar(St, SizeOf(St), 0);
end;

function ExtractRecentListIndexFromText(const AQuestion: string): Integer;
var
  L: string;
  i, p: Integer;
  Num: string;
begin
  Result := 0;
  L := LowerCase(AQuestion);
  if ContainsAnyToken(L, 'ultimo|último|last') then
  begin
    Result := -1;
    Exit;
  end;
  if ContainsAnyToken(L, 'primeiro|first|1o|1º|1ª') and
     not ContainsAnyToken(L, 'segundo|second|terceiro|third|quarto|fourth|quinto|fifth') then
  begin
    Result := 1;
    Exit;
  end;
  if ContainsAnyToken(L, 'segundo|second|2o|2º|2ª') then
  begin
    Result := 2;
    Exit;
  end;
  if ContainsAnyToken(L, 'terceiro|third|3o|3º|3ª') then
  begin
    Result := 3;
    Exit;
  end;
  if ContainsAnyToken(L, 'quarto|fourth|4o|4º|4ª') then
  begin
    Result := 4;
    Exit;
  end;
  if ContainsAnyToken(L, 'quinto|fifth|5o|5º|5ª') then
  begin
    Result := 5;
    Exit;
  end;

  p := PosBMH('da lista', L);
  if p = 0 then p := PosBMH('na lista', L);
  if p = 0 then p := PosBMH('in the list', L);
  if p = 0 then p := PosBMH('from the list', L);
  if p = 0 then p := PosBMH('list', L);
  if p = 0 then Exit;

  i := p - 1;
  Num := '';
  while (i >= 1) and (L[i] in ['0'..'9']) do
  begin
    Num := L[i] + Num;
    Dec(i);
  end;
  if Num <> '' then
  begin
    Result := StrToIntDef(Num, 0);
    Exit;
  end;

  i := p + 1;
  while (i <= Length(L)) and not (L[i] in ['0'..'9']) do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
end;

function UserQuestionRefersToRecentFilesList(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(AQuestion));
  Result := ContainsAnyToken(L,
    'lista|list|recent|recentes|grid|listview|arquivos recentes|da lista|na lista|in the list|from the list') or
    (ContainsAnyToken(L, 'primeiro|segundo|terceiro|quarto|quinto|ultimo|último|first|second|third|last') and
     ContainsAnyToken(L, 'arquivo|arquivos|ficheiro|ficheiros|file|files'));
end;

function TryCatalogResolveAction(const AQuestion: string;
  var AActionId: string; var AStep: TAssistantChainStep): Boolean;
{ Local-shortcut / offline path ONLY — never use to override an LLM ActionId.
  After AI: call TryCatalogEnrichActionParams instead. }
var
  L, Path, SearchTxt, FilterPat, RangeParams, MappedId: string;
  LineN, Parts, RecentIdx, BestSc, SecondSc, MergeMode, AfterLine: Integer;
  ByteOff: Int64;
begin
  Result := False;
  AActionId := '';
  InitStep(AStep);
  L := FoldDiacriticsForMatch(AQuestion);
  if L = '' then Exit;

  SearchTxt := ExtractSearchTextFromText(AQuestion);
  FilterPat := SearchTxt;
  LineN := ExtractLineNumberFromText(AQuestion);
  Path := ExtractPathFromUserText(AQuestion);
  ByteOff := ExtractByteOffsetFromText(AQuestion);
  RecentIdx := ExtractRecentListIndexFromText(AQuestion);

  { Language-list asks are handled in TryHandleValidateSourceChat (explain). }
  if UserWantsValidateSource(AQuestion) then
  begin
    AActionId := 'validate_source';
    AStep.ActionId := AActionId;
    if Path <> '' then
      AStep.Path := Path;
    Result := True;
    Exit;
  end;

  if (RecentIdx <> 0) and (Path = '') and UserQuestionRefersToRecentFilesList(L) and
     ContainsAnyToken(L, 'abrir|open|ler|read|carregar|load|abra|quero|want|abra|mostrar|show|ver|view') then
  begin
    AActionId := 'open_recent_file';
    AStep.ActionId := AActionId;
    AStep.LineNo := RecentIdx;
    Result := True;
    Exit;
  end;

  if (SearchTxt <> '') and ContainsAnyToken(L,
    'procur|busc|search|find|localiz|palavra|word|texto|termo') and
     not UserHasSpecificToolIntent(AQuestion) then
  begin
    AActionId := 'find_text';
    AStep.ActionId := AActionId;
    AStep.FilterText := SearchTxt;
    AStep.CaseSensitive := UserRequestedCaseSensitive(AQuestion);
    Result := True;
    Exit;
  end;

  if (LineN > 0) and ContainsAnyToken(L, 'editar|edit |edite|alterar|modificar') then
  begin
    AActionId := 'edit_line';
    AStep.ActionId := AActionId;
    AStep.LineNo := LineN;
    Result := True;
    Exit;
  end;

  if UserWantsCatalogExportLineRange(AQuestion, RangeParams) then
  begin
    AActionId := 'export_lines';
    AStep.ActionId := AActionId;
    AStep.FilterText := RangeParams;
    if Path <> '' then AStep.Path := Path;
    Result := True;
    Exit;
  end;

  if (LineN > 0) and ContainsAnyToken(L, 'ir para|vai para|goto|go to|ctrl+g') and
     not TryParseLineRangeParams(AQuestion, RangeParams) then
  begin
    AActionId := 'goto_line';
    AStep.ActionId := AActionId;
    AStep.LineNo := LineN;
    Result := True;
    Exit;
  end;

  if (ByteOff > 0) and ContainsAnyToken(L, 'byte|offset|hex|desloc') then
  begin
    AActionId := 'goto_byte_offset';
    AStep.ActionId := AActionId;
    AStep.ByteOffset := ByteOff;
    Result := True;
    Exit;
  end;

  if UserWantsShowScriptEngine(AQuestion) then
  begin
    AActionId := 'show_script_engine';
    AStep.ActionId := AActionId;
    if Path <> '' then AStep.Path := Path;
    Result := True;
    Exit;
  end;

  if UserWantsShowTailMacro(AQuestion) then
  begin
    AActionId := 'show_tail_macro';
    AStep.ActionId := AActionId;
    if Path <> '' then AStep.Path := Path;
    Result := True;
    Exit;
  end;

  { Merge/join before RAG: PT/EN/DE/... including "zusammenführen" after umlaut fold. }
  if ContainsAnyToken(L, 'ctrl+shift+j|merge files|unir ficheiros|juntar arquivos|mesclar arquivos|' +
    'quero mesclar|quero unir|quero juntar|juntar esse|unir esse|mesclar esse|' +
    'juntar o arquivo|unir o arquivo|mesclar o arquivo|reunir esse|reunir o arquivo|' +
    'unir os|mesclar os|unir archivos|juntar as partes|unir as partes|' +
    'join files|join parts|merge parts|fusionner fichiers|dateien zusammenfuehren|' +
    'diese datei zusammenfuehren|datei zusammenfuehren|' +
    'unisci file|scal pliki|uneste fisiere|sloucit soubory|pode juntar|can you join|' +
    'can you merge|puedes unir|puedes juntar|koennen sie') or
     (ContainsAnyToken(L, 'mesclar|unir|juntar|reunir|merge|join|fusionner|zusammenfuehren|' +
      'zusammenfuhren|unisci|scal|uneste|sloucit') and
      (ContainsAnyToken(L, 'arquivo|arquivos|ficheiros|file|files|archivo|archivos|' +
        'fichier|fichiers|datei|dateien|plik|pliki|fisier|fisiere|soubor|soubory|' +
        'part|parte|partes|teile|parti|esse|este|this|that|diese|dieser|dieses') or
       (Path <> ''))) then
  begin
    AActionId := 'show_tab_merge_files';
    AStep.ActionId := AActionId;
    if Path <> '' then
      AStep.Path := Path;
    if AStep.Path = '' then
      AStep.Path := AssistantHostGetOpenFilePath;
    AStep.LineNo := -1;
    AStep.Parts := 1;
    if ParseMergeFilesModeFromQuestion(AQuestion, MergeMode, AfterLine) then
    begin
      AStep.LineNo := MergeMode;
      AStep.Parts := AfterLine;
    end;
    Result := True;
    Exit;
  end;

  if UserWantsShowConsumerRAG(AQuestion) then
  begin
    AActionId := 'consumer_rag';
    AStep.ActionId := AActionId;
    if Path <> '' then AStep.Path := Path;
    if UserWantsConsumerRAGContentQuestion(AQuestion) then
      AStep.FilterText := SanitizeQuestionForConsumerPython(AQuestion, True);
    Result := True;
    Exit;
  end;

  if UserWantsShowConsumerAI(AQuestion) then
  begin
    AActionId := 'consumer_ai';
    AStep.ActionId := AActionId;
    if Path <> '' then AStep.Path := Path;
    if UserWantsConsumerAIContentQuestion(AQuestion) then
      AStep.FilterText := SanitizeQuestionForConsumerPython(AQuestion, False);
    Result := True;
    Exit;
  end;

  if UserWantsFixComposedDocument(AQuestion) or UserWantsFileSummaryToDocument(AQuestion) or
     UserWantsComposeDocument(AQuestion) then
  begin
    AActionId := 'compose_document';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  { Score the capability ingest before greedy "open file". Colloquial tool
    requests ("quero filtrar", "rodar python", "dividir em 5") must not be
    stolen by path + quero/arquivo. Anti-phrases in the map veto conflicts
    (Word summary vs RAG, generate .py vs Script Engine). }
  if TryScoreCapabilityMap(AQuestion, MappedId, BestSc, SecondSc) and
     not SameText(MappedId, 'open_and_read_file') then
  begin
    if not (SameText(MappedId, 'compose_document') and
            not UserWantsComposeDocument(AQuestion) and
            not UserWantsFileSummaryToDocument(AQuestion) and
            not UserWantsFixComposedDocument(AQuestion) and
            not UserWantsComposeSourceCode(AQuestion)) then
    begin
      FillStepFromMapHit(AQuestion, MappedId, Path, SearchTxt, FilterPat,
        LineN, ByteOff, AActionId, AStep);
      Result := True;
      Exit;
    end;
  end;

  if (Path <> '') and ContainsAnyToken(L,
    'ler|leia|carregar|carrega|abrir|abra|read |load |open ') and
    not ContainsAnyToken(L, 'como |how ') and
    not UserHasSpecificToolIntent(AQuestion) then
  begin
    Parts := ExtractPartsCountFromText(AQuestion);
    if (Parts >= 2) and ContainsAnyToken(L, 'divid|split|part|depois|entao|then') then
      Exit;
    AActionId := 'open_and_read_file';
    AStep.ActionId := AActionId;
    AStep.Path := Path;
    Result := True;
    Exit;
  end;

  FilterPat := ExtractSearchTextFromText(AQuestion);
  if (FilterPat <> '') and ContainsAnyToken(L, 'filtr|filter|grep|filtrer|filtra|filtruj') and
     not ContainsAnyToken(L, 'limpar|clear|borrar|effacer') then
  begin
    AActionId := 'apply_filter';
    AStep.ActionId := AActionId;
    AStep.FilterText := FilterPat;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'limpar filtro|clear filter|remover filtro') or
     (ContainsAnyToken(L, 'limpar|clear') and ContainsAnyToken(L, 'filtro|filter')) then
  begin
    AActionId := 'clear_filter';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'continuar filtro|continue filter|mais hits|more hits|' +
     'carregar mais filtro|load more filter|mais resultados do filtro|seguir filtrando') then
  begin
    AActionId := 'continue_filter';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if (ContainsAnyToken(L, 'copiar|copy|clipboard') and
      ContainsAnyToken(L, 'filtro|filter|filtrado|filtered|hits|grep')) then
  begin
    AActionId := 'copy_filtered';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'f3|proxima ocorrencia|proxima ocorr|next match|next find|seguinte ocorrencia') then
  begin
    AActionId := 'find_next';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'shift+f3|anterior ocorrencia|previous match|prev find|ocorrencia anterior') then
  begin
    AActionId := 'find_previous';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'shift+end|fim do arquivo|fim do ficheiro|final do arquivo|end of file|ir ao fim') then
  begin
    AActionId := 'goto_file_end';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'shift+home|inicio do arquivo|inicio do ficheiro|topo do arquivo|go to top|ir ao inicio') then
  begin
    AActionId := 'goto_file_start';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+t|pausar tail|pause tail|retomar tail|resume tail') then
  begin
    AActionId := 'pause_tail';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'f2|next bookmark|proximo marcador|proxima marca') and
     not ContainsAnyToken(L, 'shift') then
  begin
    AActionId := 'next_bookmark';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'shift+f2|previous bookmark|marcador anterior') then
  begin
    AActionId := 'prev_bookmark';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+b|clear bookmark|limpar marcador|limpar marca') then
  begin
    AActionId := 'clear_bookmarks';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+n|multiplas linhas|multiple lines|inserir varias') then
  begin
    AActionId := 'insert_multiple_lines';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+i|inserir linha|insert line|nova linha|' +
    'insertar linea|inserer une ligne|zeile einfuegen|inserisci riga') then
  begin
    AActionId := 'insert_line';
    AStep.ActionId := AActionId;
    if LineN > 0 then AStep.LineNo := LineN;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+u|duplicar linha|duplicate line|' +
    'duplicar linea|dupliquer la ligne|zeile duplizieren|duplica riga') then
  begin
    AActionId := 'duplicate_line';
    AStep.ActionId := AActionId;
    if LineN > 0 then AStep.LineNo := LineN;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'deletar|apagar|excluir|remover|eliminar|supprimer|loeschen|elimina') and
     ContainsAnyToken(L, 'ultima linha|ultima linha do|last line|last line of|' +
       'ultima linea|derniere ligne|letzte zeile|ultima riga') then
  begin
    AActionId := 'delete_line';
    AStep.ActionId := AActionId;
    AStep.LineNo := 0;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+d|apagar linha|delete line|excluir linha|remover linha|deletar linha|' +
    'eliminar linea|supprimer la ligne|zeile loeschen|elimina riga') then
  begin
    AActionId := 'delete_line';
    AStep.ActionId := AActionId;
    if LineN > 0 then AStep.LineNo := LineN;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+e|editar linha|edit line|editar linea|modifier la ligne|' +
    'zeile bearbeiten|modifica riga') and (LineN = 0) then
  begin
    AActionId := 'edit_line';
    AStep.ActionId := AActionId;
    AStep.LineNo := 0;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+z|desfazer|undo') then
  begin
    AActionId := 'undo';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+y|refazer|redo') then
  begin
    AActionId := 'redo';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+c|copiar|copy selection') then
  begin
    AActionId := 'copy_selection';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ((PosBMH('export', L) > 0) or (PosBMH('exportar', L) > 0)) and
     ((PosBMH('palavra', L) > 0) or (PosBMH('procur', L) > 0) or (PosBMH('busc', L) > 0) or
      (PosBMH('conten', L) > 0) or (PosBMH('filtr', L) > 0) or (PosBMH('grep', L) > 0)) then
  begin
    AActionId := 'export_matching_lines';
    AStep.ActionId := AActionId;
    AStep.FilterText := ExtractSearchTextFromText(AQuestion);
    if Trim(AStep.FilterText) = '' then
    begin
      Result := False;
      Exit;
    end;
    AStep.CaseSensitive := UserRequestedCaseSensitive(AQuestion);
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+v|colar linhas|paste lines|colar no ficheiro|colar no arquivo') then
  begin
    AActionId := 'paste_lines';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+g|byte offset|offset byte|ir para byte') then
  begin
    AActionId := 'goto_byte_offset';
    AStep.ActionId := AActionId;
    if ByteOff > 0 then AStep.ByteOffset := ByteOff;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+g|ir para linha|goto line|go to line') and (LineN = 0) then
  begin
    AActionId := 'goto_line';
    AStep.ActionId := AActionId;
    AStep.LineNo := 0;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+f|procurar dialog|find dialog|abrir busca') and (SearchTxt = '') then
  begin
    AActionId := 'open_find';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+h|replace dialog|find replace dialog') and
     not ContainsAnyToken(L, ' por | by | with ') then
  begin
    AActionId := 'open_replace';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+l|filtro dialog|filter dialog|abrir filtro|mostrar filtro|' +
     'abrir barra de filtro|show filter bar|abrir o filtro|abrir grep') and (FilterPat = '') then
  begin
    AActionId := 'open_filter';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+t|tail|follow|seguir arquivo|monitorar arquivo') and
     not ContainsAnyToken(L, 'pausar|pause|shift+t') then
  begin
    AActionId := 'start_tail';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+b|bookmark|marcador|marca linha') and
     not ContainsAnyToken(L, 'shift+b|limpar|clear') then
  begin
    AActionId := 'toggle_bookmark';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+w|word wrap|quebra linha|quebra de linha') then
  begin
    AActionId := 'toggle_word_wrap';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+s|select mode|modo select|checkbox|checklist|' +
    'modo seleccion|mode selection|auswahlmodus|modalita selezione') then
  begin
    AActionId := 'show_checkboxes';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'f5|recarregar|reload|read file|ler ficheiro|carregar ficheiro|' +
    'recharger|neu laden|ricarica') and (Path = '') then
  begin
    AActionId := 'reload_file';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+o|abrir ficheiro|open file dialog|abrir arquivo') and (Path = '') then
  begin
    AActionId := 'open_file_dialog';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+r|recentes|recent files|ficheiros recentes') and
     not ContainsAnyToken(L, 'ctrl+alt') then
  begin
    AActionId := 'show_tab_recent';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+1|aba ler|read tab|show read') then
  begin
    AActionId := 'show_tab_read';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+x|clear file|limpar arquivo|limpar ficheiro|' +
    'borrar archivo|vaciar archivo|effacer le fichier|datei leeren|svuotare file') then
  begin
    AActionId := 'clear_file';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+o|exportar|export file|exportar archivo|exporter fichier|' +
    'datei exportieren|esporta file') and
     not ContainsAnyToken(L, 'filtr|filter|tail') then
  begin
    AActionId := 'export_file';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+l|exportar filtro|export filtered|export tail|' +
    'exportar filtrado|exporter filtre|gefiltert exportieren') then
  begin
    AActionId := 'export_filtered';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+f|find in files|procurar em ficheiros|procurar em arquivos|' +
    'buscar en archivos|rechercher dans fichiers|in dateien suchen|cerca nei file') then
  begin
    AActionId := 'find_in_files';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+k|split files|dividir ficheiros|dividir por tamanho|' +
    'split by size|diviser par taille|nach groesse teilen|dividi per dimensione') then
  begin
    AActionId := 'split_files';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+p|partes iguais|equal parts|split equal|dividir|split into|' +
    'particionar|dividir en|teilen|dividi in|podziel|imparte|rozdelit|split file') and
     (ExtractPartsCountFromText(AQuestion) >= 2) then
  begin
    AActionId := 'split_equal_parts';
    AStep.ActionId := AActionId;
    AStep.Parts := ExtractPartsCountFromText(AQuestion);
    if Path <> '' then AStep.Path := Path;
    if AStep.Path = '' then
      AStep.Path := AssistantHostGetOpenFilePath;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+q|extrair partes|extract parts|extraer partes|extraire parties|' +
    'teile extrahieren|estrarre parti|1/|2/|3/|4/|5/|6/|7/|8/|9/') and
     ((PosBMH('/', L) > 0) and
      ((PosBMH('part', L) > 0) or (PosBMH('teil', L) > 0) or (PosBMH('parti', L) > 0))) then
  begin
    AActionId := 'extract_file_parts';
    AStep.ActionId := AActionId;
    if Path <> '' then AStep.Path := Path;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+alt+p|split pattern|dividir padrao|regex split|dividir por patron|' +
    'diviser par motif|nach muster teilen|dividi per pattern') then
  begin
    AActionId := 'pattern_split';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+m|merge lines|unir linhas|juntar linhas|unir lineas|' +
    'fusionner lignes|zeilen zusammenfuehren|unisci righe') then
  begin
    AActionId := 'show_tab_merge_lines';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+j|merge files|unir ficheiros|juntar arquivos|mesclar arquivos|' +
    'quero mesclar|quero unir|quero juntar|juntar esse|unir esse|mesclar esse|' +
    'juntar o arquivo|unir o arquivo|mesclar o arquivo|reunir esse|reunir o arquivo|' +
    'unir os|mesclar os|unir archivos|mesclar (unir)|juntar as partes|unir as partes|' +
    'join files|join parts|merge parts|fusionner fichiers|dateien zusammenfuehren|' +
    'diese datei zusammenfuehren|datei zusammenfuehren|' +
    'unisci file|scal pliki|uneste fisiere|sloucit soubory') or
     (ContainsAnyToken(L, 'mesclar|unir|juntar|reunir|merge|join|fusionner|zusammenfuehren|' +
      'zusammenfuhren|unisci|scal|uneste|sloucit') and
      ContainsAnyToken(L, 'arquivo|arquivos|ficheiros|file|files|archivo|archivos|' +
        'fichier|fichiers|datei|dateien|plik|pliki|fisier|fisiere|soubor|soubory|' +
        'part|parte|partes|teile|parti|diese|dieser|dieses|esse|este|this|that')) then
  begin
    AActionId := 'show_tab_merge_files';
    AStep.ActionId := AActionId;
    if Path <> '' then
      AStep.Path := Path;
    if AStep.Path = '' then
      AStep.Path := AssistantHostGetOpenFilePath;
    AStep.LineNo := -1;
    AStep.Parts := 1;
    if ParseMergeFilesModeFromQuestion(AQuestion, MergeMode, AfterLine) then
    begin
      AStep.LineNo := MergeMode;
      AStep.Parts := AfterLine;
    end;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+h|compare|comparar|merge history|comparer|vergleichen|' +
    'confronta|porownaj|compara|porovnat|diff files') then
  begin
    AActionId := 'show_tab_compare';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'duplicat|dedup|linhas duplicadas') then
  begin
    AActionId := 'delete_duplicate_lines';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'frequent string|strings frequentes|extrair string') then
  begin
    AActionId := 'extract_frequent_strings';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'character code|codigo caractere|codigo do caractere') then
  begin
    AActionId := 'character_code_value';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'f1|ajuda|help') then
  begin
    AActionId := 'show_help';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+p|opcoes|options menu') then
  begin
    AActionId := 'open_options';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+alt+r|read-only|somente leitura|readonly session') then
  begin
    AActionId := 'toggle_readonly_session';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+alt+s|save session|guardar sessao|salvar sessao') then
  begin
    AActionId := 'save_session';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+alt+l|load session|carregar sessao') then
  begin
    AActionId := 'load_session';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+shift+a|consumer ai|chat ia') then
  begin
    AActionId := 'consumer_ai';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'consumer rag|ctrl+alt+r rag') then
  begin
    AActionId := 'consumer_rag';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'zoom in|aumentar fonte|ctrl+num+|aumentar fuente|agrandir police|' +
    'schrift vergrossern|aumenta font') then
  begin
    AActionId := 'zoom_in';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'zoom out|diminuir fonte|ctrl+num-|reducir fuente|reduire police|' +
    'schrift verkleinern|riduci font') then
  begin
    AActionId := 'zoom_out';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'ctrl+alt+m|whitespace|marcas visiveis|espacos visiveis') then
  begin
    AActionId := 'toggle_whitespace_marks';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'cancelar busca|cancel search|esc find') then
  begin
    AActionId := 'cancel_search';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if ContainsAnyToken(L, 'tela carregar|load screen|aba ler') then
  begin
    AActionId := 'show_tab_read';
    AStep.ActionId := AActionId;
    Result := True;
    Exit;
  end;

  if TryScoreCapabilityMap(AQuestion, MappedId, BestSc, SecondSc) then
  begin
    if SameText(MappedId, 'compose_document') and
       not UserWantsComposeDocument(AQuestion) and
       not UserWantsFileSummaryToDocument(AQuestion) and
       not UserWantsFixComposedDocument(AQuestion) and
       not UserWantsComposeSourceCode(AQuestion) then
      Exit;
    FillStepFromMapHit(AQuestion, MappedId, Path, SearchTxt, FilterPat,
      LineN, ByteOff, AActionId, AStep);
    Result := True;
  end;
end;

function TryCatalogEnrichActionParams(const AQuestion, AActionId: string;
  var AStep: TAssistantChainStep): Boolean;
var
  Path, SearchTxt, RangeParams: string;
  LineN, Parts, RecentIdx, MergeMode, AfterLine: Integer;
  ByteOff: Int64;
  Prefs: TStringDynArray;
  i: Integer;
  Joined: string;
begin
  { AI-first: never changes AActionId — only fills empty structural params. }
  Result := False;
  if not CatalogIsAllowedActionId(AActionId) then Exit;
  AStep.ActionId := AActionId;

  Path := ExtractPathFromUserText(AQuestion);
  if (Trim(AStep.Path) = '') and (Path <> '') then
  begin
    AStep.Path := Path;
    Result := True;
  end;

  SearchTxt := ExtractSearchTextFromText(AQuestion);
  LineN := ExtractLineNumberFromText(AQuestion);
  ByteOff := ExtractByteOffsetFromText(AQuestion);
  RecentIdx := ExtractRecentListIndexFromText(AQuestion);

  if SameText(AActionId, 'find_text') or SameText(AActionId, 'apply_filter') or
     SameText(AActionId, 'export_matching_lines') or SameText(AActionId, 'replace_all') then
  begin
    if (Trim(AStep.FilterText) = '') and (SearchTxt <> '') then
    begin
      AStep.FilterText := SearchTxt;
      Result := True;
    end;
  end;

  if SameText(AActionId, 'count_line_prefixes') then
  begin
    if not TryParseLinePrefixCountAsk(AQuestion, Prefs) then
      CollectDigitRunNeedles(AQuestion, Prefs);
    Joined := '';
    for i := 0 to High(Prefs) do
    begin
      if Joined <> '' then
        Joined := Joined + '|';
      Joined := Joined + Prefs[i];
    end;
    if Joined <> '' then
    begin
      AStep.FilterText := Joined;
      Result := True;
    end;
  end;

  { AI chose count_matching_lines — fill empty filter from quotes / digit codes. }
  if SameText(AActionId, 'count_matching_lines') and (Trim(AStep.FilterText) = '') then
  begin
    Joined := ExtractQuotedNeedlesFromText(AQuestion);
    if Joined = '' then
    begin
      if CollectDigitRunNeedles(AQuestion, Prefs) then
        for i := 0 to High(Prefs) do
        begin
          if Joined <> '' then
            Joined := Joined + '|';
          Joined := Joined + Prefs[i];
        end;
    end;
    if Joined <> '' then
    begin
      AStep.FilterText := Joined;
      Result := True;
    end;
  end;

  if SameText(AActionId, 'export_lines') and (Trim(AStep.FilterText) = '') and
     TryParseLineRangeParams(AQuestion, RangeParams) then
  begin
    AStep.FilterText := RangeParams;
    Result := True;
  end;

  if (SameText(AActionId, 'goto_line') or SameText(AActionId, 'edit_line') or
      SameText(AActionId, 'delete_line')) and (AStep.LineNo <= 0) and (LineN > 0) then
  begin
    AStep.LineNo := LineN;
    Result := True;
  end;

  if SameText(AActionId, 'goto_byte_offset') and (AStep.ByteOffset <= 0) and (ByteOff > 0) then
  begin
    AStep.ByteOffset := ByteOff;
    Result := True;
  end;

  if SameText(AActionId, 'open_recent_file') and (AStep.LineNo <= 0) and (RecentIdx <> 0) then
  begin
    AStep.LineNo := RecentIdx;
    Result := True;
  end;

  if SameText(AActionId, 'split_equal_parts') then
  begin
    Parts := ExtractPartsCountFromText(AQuestion);
    if (AStep.Parts < 2) and (Parts >= 2) then
    begin
      AStep.Parts := Parts;
      Result := True;
    end;
  end;

  if SameText(AActionId, 'show_tab_merge_files') then
  begin
    if Trim(AStep.Path) = '' then
    begin
      AStep.Path := AssistantHostGetOpenFilePath;
      if AStep.Path <> '' then
        Result := True;
    end;
    if ParseMergeFilesModeFromQuestion(AQuestion, MergeMode, AfterLine) then
    begin
      AStep.LineNo := MergeMode;
      AStep.Parts := AfterLine;
      Result := True;
    end;
  end;

  if (Trim(AStep.Path) = '') and
     (SameText(AActionId, 'split_equal_parts') or
      SameText(AActionId, 'extract_file_parts') or
      SameText(AActionId, 'count_line_prefixes') or
      SameText(AActionId, 'count_matching_lines') or
      SameText(AActionId, 'apply_filter') or
      SameText(AActionId, 'find_text') or
      SameText(AActionId, 'compose_document') or
      SameText(AActionId, 'consumer_ai') or
      SameText(AActionId, 'consumer_rag')) then
  begin
    AStep.Path := AssistantHostGetOpenFilePath;
    if AStep.Path <> '' then
      Result := True;
  end;

  AStep.CaseSensitive := UserRequestedCaseSensitive(AQuestion);

  if AStep.MaxLines < 1 then
  begin
    LineN := ExtractMaxRecordsFromText(AQuestion);
    if LineN > 0 then
    begin
      AStep.MaxLines := LineN;
      Result := True;
    end;
  end;
end;

function CatalogIsAllowedActionId(const AId: string): Boolean;
begin
  Result := MapIsAllowedActionId(AId);
end;

function BuildAssistantZsAtalhosCatalogKB: string;
begin
  Result := BuildCapabilityMapKB;
end;

end.
