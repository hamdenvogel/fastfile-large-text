unit uAgentTargets;

{
  Which of the selected files a request is about, read from the request in any of the 14 UI languages:
  by name ("log.txt"), by position ("o primeiro arquivo", "leia somente o último", "the last two files",
  "arquivo 2"), by type ("do CSV"), all ("todos os arquivos") or all but some ("todos menos o último").
  This file is UTF-8 with BOM: the words below are written in their own scripts.
}

interface

uses
  Classes;

type
  TAgentTargetMode = (
    tgtAll,       // names no file: every selected file
    tgtNamed,     // names files by name
    tgtPosition,  // picks files by position or excludes some ("all but the last")
    tgtType,      // names a file type: the selected files of that type
    tgtNone);     // picks a position that is not in the list

{ Fills ATargets with the selected files the request is about, in the order of AFiles. }
function AgentInferTargets(const APrompt: string; AFiles, ATargets: TStrings): TAgentTargetMode;
{ One line for the model with the files FastFile inferred; '' with a single selected file. }
function AgentTargetsNote(AMode: TAgentTargetMode; AFiles, ATargets: TStrings): string;

implementation

uses
  SysUtils, StrUtils, uAgentMatchIntent;

const
  PUNCT_MARK = 'zzpz';

  FILE_WORDS: array[0..36] of string = (
    'arquivo', 'arquivos', 'ficheiro', 'ficheiros', 'fonte', 'fontes',
    'archivo', 'archivos', 'fichier', 'fichiers', 'source', 'sources',
    'datei', 'dateien', 'file', 'files',
    'plik', 'pliki', 'pliku', 'plikow', 'plikach',
    'fisier', 'fisiere', 'fisierul', 'fisierele', 'fisierului',
    'fajl', 'fajlt', 'fajlok', 'fajlokat', 'fajlban', 'fajlbol',
    'soubor', 'soubory', 'souboru', 'souborech', 'dokument');

  { Words before a bare ordinal ("o último", "only the last", "somente o primeiro"). }
  LEAD_WORDS: array[0..69] of string = (
    'o', 'a', 'os', 'as', 'do', 'da', 'dos', 'das', 'no', 'na', 'nos', 'nas', 'ao', 'aos', 'pelo', 'pela',
    'the', 'el', 'la', 'los', 'las', 'del', 'al', 'le', 'les', 'l', 'du', 'au', 'aux',
    'der', 'die', 'das', 'den', 'dem', 'vom', 'im', 'il', 'lo', 'gli', 'i', 'dal', 'nel', 'sul',
    'az', 'e', 'and', 'y', 'et', 'und', 'si', 'es', 'ou', 'or',
    'somente', 'so', 'apenas', 'only', 'just', 'solo', 'solamente', 'seulement', 'uniquement', 'nur',
    'tylko', 'doar', 'csak', 'jen', 'pouze', 'leia', 'read');

  { Words right after a bare ordinal that end the reference ("o último em 3 partes", "the last one"). }
  FOLLOW_WORDS: array[0..56] of string = (
    'em', 'para', 'pra', 'por', 'com', 'tambem', 'apenas', 'somente', 'deles', 'delas', 'dela', 'dele',
    'in', 'into', 'to', 'by', 'with', 'on', 'one', 'only', 'too', 'also', 'of',
    'en', 'con', 'tambien', 'solamente',
    'dans', 'par', 'avec', 'pour', 'sur', 'aussi', 'seulement',
    'im', 'mit', 'nach', 'auf', 'zu', 'auch', 'nur',
    'per', 'su', 'anche',
    'w', 'we', 'po', 'tez',
    'cu', 'pe', 'si',
    'ban', 'be', 'is',
    've', 'se', 'take');

  CONJ_WORDS: array[0..11] of string = ('e', 'and', 'y', 'et', 'und', 'i', 'es', 'si', 'ou', 'or', 'oder', 'a');

  ALL_WORDS: array[0..21] of string = ('todos', 'todas', 'all', 'every', 'each', 'cada', 'tous', 'toutes',
    'chaque', 'alle', 'allen', 'jede', 'tutti', 'tutte', 'ogni', 'wszystkie', 'toate', 'fiecare', 'minden',
    'osszes', 'vsechny', 'kazdy');

  EXCEPT_WORDS: array[0..17] of string = ('menos', 'exceto', 'excepto', 'salvo', 'except', 'excluding',
    'sauf', 'excepte', 'hormis', 'ausser', 'ausgenommen', 'tranne', 'eccetto', 'oprocz', 'poza',
    'exceptia', 'kiveve', 'krome');

  { Words that put a type after them out of the source list ("para um txt", "save as csv"). }
  TO_WORDS: array[0..21] of string = ('para', 'pra', 'to', 'into', 'em', 'en', 'in', 'como', 'as', 'um',
    'uma', 'an', 'un', 'une', 'ein', 'eine', 'einen', 'formato', 'format', 'zu', 'au', 'w');

  NUMBER_WORDS: array[0..33] of string = ('dois', 'duas', 'tres', 'quatro', 'cinco', 'two', 'three', 'four',
    'five', 'dos', 'cuatro', 'deux', 'trois', 'quatre', 'cinq', 'zwei', 'drei', 'vier', 'funf', 'due', 'tre',
    'quattro', 'dwa', 'trzy', 'cztery', 'doi', 'trei', 'patru', 'ketto', 'harom', 'negy', 'dva', 'tri', 'ctyri');
  NUMBER_VALUES: array[0..33] of Integer = (2, 2, 3, 4, 5, 2, 3, 4,
    5, 2, 4, 2, 3, 4, 5, 2, 3, 4, 5, 2, 3,
    4, 2, 3, 4, 2, 3, 4, 2, 3, 4, 2, 3, 4);

type
  TOrdinal = record
    W: string;
    V: Integer; // 1..5, -1 last, -2 last but one
  end;

const
  ORDINALS: array[0..110] of TOrdinal = (
    (W: 'first'; V: 1), (W: 'second'; V: 2), (W: 'third'; V: 3), (W: 'fourth'; V: 4), (W: 'fifth'; V: 5),
    (W: 'last'; V: -1), (W: 'penultimate'; V: -2),
    (W: 'primeiro'; V: 1), (W: 'primeira'; V: 1), (W: 'primeiros'; V: 1), (W: 'primeiras'; V: 1),
    (W: 'segundo'; V: 2), (W: 'segunda'; V: 2), (W: 'terceiro'; V: 3), (W: 'terceira'; V: 3),
    (W: 'quarto'; V: 4), (W: 'quarta'; V: 4), (W: 'quinto'; V: 5), (W: 'quinta'; V: 5),
    (W: 'ultimo'; V: -1), (W: 'ultima'; V: -1), (W: 'ultimos'; V: -1), (W: 'ultimas'; V: -1),
    (W: 'penultimo'; V: -2), (W: 'penultima'; V: -2),
    (W: 'primer'; V: 1), (W: 'primero'; V: 1), (W: 'primera'; V: 1), (W: 'primeros'; V: 1), (W: 'primeras'; V: 1),
    (W: 'tercer'; V: 3), (W: 'tercero'; V: 3), (W: 'tercera'; V: 3), (W: 'cuarto'; V: 4), (W: 'cuarta'; V: 4),
    (W: 'premier'; V: 1), (W: 'premiere'; V: 1), (W: 'premiers'; V: 1), (W: 'premieres'; V: 1),
    (W: 'deuxieme'; V: 2), (W: 'seconde'; V: 2), (W: 'troisieme'; V: 3), (W: 'quatrieme'; V: 4),
    (W: 'cinquieme'; V: 5), (W: 'dernier'; V: -1), (W: 'derniere'; V: -1), (W: 'derniers'; V: -1),
    (W: 'dernieres'; V: -1), (W: 'avantdernier'; V: -2),
    (W: 'erste'; V: 1), (W: 'ersten'; V: 1), (W: 'erstes'; V: 1), (W: 'erster'; V: 1),
    (W: 'zweite'; V: 2), (W: 'zweiten'; V: 2), (W: 'zweites'; V: 2), (W: 'dritte'; V: 3), (W: 'dritten'; V: 3),
    (W: 'vierte'; V: 4), (W: 'letzte'; V: -1), (W: 'letzten'; V: -1), (W: 'letztes'; V: -1),
    (W: 'letzter'; V: -1), (W: 'vorletzte'; V: -2), (W: 'vorletzten'; V: -2),
    (W: 'primo'; V: 1), (W: 'primi'; V: 1), (W: 'secondo'; V: 2), (W: 'terzo'; V: 3), (W: 'terza'; V: 3),
    (W: 'ultimi'; V: -1), (W: 'ultime'; V: -1),
    (W: 'pierwszy'; V: 1), (W: 'pierwszym'; V: 1), (W: 'pierwszego'; V: 1), (W: 'pierwsze'; V: 1),
    (W: 'drugi'; V: 2), (W: 'drugim'; V: 2), (W: 'drugiego'; V: 2), (W: 'trzeci'; V: 3), (W: 'czwarty'; V: 4),
    (W: 'ostatni'; V: -1), (W: 'ostatnim'; V: -1), (W: 'ostatniego'; V: -1), (W: 'ostatnie'; V: -1),
    (W: 'przedostatni'; V: -2),
    (W: 'primul'; V: 1), (W: 'primele'; V: 1), (W: 'ultimul'; V: -1), (W: 'ultimele'; V: -1),
    (W: 'penultimul'; V: -2),
    (W: 'elso'; V: 1), (W: 'elsot'; V: 1), (W: 'masodik'; V: 2), (W: 'masodikat'; V: 2),
    (W: 'harmadik'; V: 3), (W: 'negyedik'; V: 4), (W: 'utolso'; V: -1), (W: 'utolsot'; V: -1),
    (W: 'prvni'; V: 1), (W: 'prvnim'; V: 1), (W: 'prvniho'; V: 1), (W: 'druhy'; V: 2), (W: 'druhem'; V: 2),
    (W: 'druheho'; V: 2), (W: 'treti'; V: 3), (W: 'ctvrty'; V: 4), (W: 'posledni'; V: -1),
    (W: 'poslednim'; V: -1), (W: 'posledniho'; V: -1), (W: 'predposledni'; V: -2));

  { Japanese and Chinese: no spaces, matched as substrings followed by a word for file. }
  CJK_FILE: array[0..3] of string = ('ファイル', '文件', '檔案', '档案');
  CJK_ORD: array[0..13] of TOrdinal = (
    (W: '倒数第二'; V: -2), (W: '倒數第二'; V: -2), (W: '最後から2番目'; V: -2), (W: '最後から二番目'; V: -2),
    (W: '最後'; V: -1), (W: '最后'; V: -1), (W: '最初'; V: 1), (W: '第一'; V: 1), (W: '第二'; V: 2),
    (W: '第三'; V: 3), (W: '一番目'; V: 1), (W: '二番目'; V: 2), (W: '三番目'; V: 3), (W: '1番目'; V: 1));
  CJK_EXCEPT_BEFORE: array[0..0] of string = ('除了');
  CJK_EXCEPT_AFTER: array[0..1] of string = ('以外', '除外');

function InList(const W: string; const A: array of string): Boolean;
var
  S: string;
begin
  for S in A do
    if S = W then
      Exit(True);
  Result := False;
end;

function OrdinalOf(const W: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(ORDINALS) do
    if ORDINALS[I].W = W then
      Exit(ORDINALS[I].V);
  Result := 0;
end;

function NumberOf(const W: string): Integer;
var
  I: Integer;
begin
  Result := StrToIntDef(W, 0);
  if Result > 0 then
    Exit;
  for I := 0 to High(NUMBER_WORDS) do
    if NUMBER_WORDS[I] = W then
      Exit(NUMBER_VALUES[I]);
  Result := 0;
end;

function IsPlural(const W: string): Boolean;
begin
  Result := InList(W, ['primeiros', 'primeiras', 'ultimos', 'ultimas', 'primeros', 'primeras', 'premiers',
    'premieres', 'derniers', 'dernieres', 'primi', 'ultimi', 'ultime', 'pierwsze', 'ostatnie', 'primele',
    'ultimele']);
end;

{ Sentence punctuation becomes a word of its own, so "o último." ends the reference and "por último," does not
  run into the next words. A dot inside a name ("log.txt") is kept. }
function MarkPunctuation(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if CharInSet(C, ['.', ',', ';', ':', '!', '?']) and ((I = Length(S)) or (S[I + 1] <= ' ')) then
      Result := Result + ' ' + PUNCT_MARK + ' '
    else if (C = '，') or (C = '。') or (C = '、') or (C = '；') or (C = '！') or (C = '？') then
      Result := Result + ' ' + PUNCT_MARK + ' '
    else
      Result := Result + C;
  end;
end;

procedure MergePenultimate(var T: TArray<string>);
var
  I, J, Skip: Integer;
  R: TArray<string>;
begin
  SetLength(R, Length(T));
  J := 0;
  I := 0;
  while I <= High(T) do
  begin
    Skip := 0;
    if (I < High(T)) and (T[I] = 'avant') and ((T[I + 1] = 'dernier') or (T[I + 1] = 'derniere')) then
      Skip := 1
    else if (I < High(T)) and (T[I] = 'second') and (T[I + 1] = 'last') then
      Skip := 1
    else if (I < High(T) - 1) and (T[I] = 'second') and (T[I + 1] = 'to') and (T[I + 2] = 'last') then
      Skip := 2
    else if (I < High(T)) and ((T[I] = 'utolso') or (T[I] = 'utolsot')) and (Copy(T[I + 1], 1, 6) = 'elotti') then
      Skip := 1;
    if Skip > 0 then
    begin
      R[J] := 'penultimate';
      Inc(I, Skip + 1);
    end
    else
    begin
      R[J] := T[I];
      Inc(I);
    end;
    Inc(J);
  end;
  SetLength(R, J);
  T := R;
end;

type
  TPicks = record
    Count: Integer;
    Incl, Excl: TArray<Boolean>;
    OutOfRange, Any: Boolean;
    procedure Init(ACount: Integer);
    procedure Add(AIndex: Integer; AExclude: Boolean);
  end;

procedure TPicks.Init(ACount: Integer);
begin
  Count := ACount;
  SetLength(Incl, ACount);
  SetLength(Excl, ACount);
  OutOfRange := False;
  Any := False;
end;

procedure TPicks.Add(AIndex: Integer; AExclude: Boolean);
begin
  if (AIndex < 0) or (AIndex >= Count) then
  begin
    OutOfRange := True;
    Exit;
  end;
  Any := True;
  if AExclude then
    Excl[AIndex] := True
  else
    Incl[AIndex] := True;
end;

{ An ordinal value -> file index; ACount files, AN files for "the first two" / "the last two". }
procedure AddOrdinal(var P: TPicks; AValue, AN: Integer; AExclude: Boolean);
var
  K: Integer;
begin
  if AN < 1 then
    AN := 1;
  for K := 0 to AN - 1 do
    case AValue of
      -1: P.Add(P.Count - 1 - K, AExclude);
      -2: P.Add(P.Count - 2, AExclude);
    else
      if AValue = 1 then
        P.Add(K, AExclude)
      else
        P.Add(AValue - 1, AExclude);
    end;
end;

{ The ordinal at AI refers to a file: a word for file follows (at most one word between), or the reference
  ends right there after an article or "only" ("leia somente o último", "o primeiro e o último"). }
function OrdinalRefersToFile(const T: TArray<string>; AI, AAfter: Integer; ADepth: Integer = 0): Boolean;
var
  J, K, Before: Integer;
begin
  J := AAfter;
  if (J <= High(T)) and InList(T[J], FILE_WORDS) then
    Exit(True);
  if (J < High(T)) and (T[J] <> PUNCT_MARK) and InList(T[J + 1], FILE_WORDS) and (NumberOf(T[J]) = 0) then
    Exit(True);
  Before := AI - 1;
  while (Before >= 0) and (NumberOf(T[Before]) > 0) do
    Dec(Before);
  if (Before < 0) or not InList(T[Before], LEAD_WORDS) then
    Exit(False);
  if (J > High(T)) or (T[J] = PUNCT_MARK) or InList(T[J], FOLLOW_WORDS) then
    Exit(True);
  if InList(T[J], CONJ_WORDS) and (ADepth < 4) then
  begin
    K := J + 1;
    while (K <= High(T)) and InList(T[K], LEAD_WORDS) and (OrdinalOf(T[K]) = 0) do
      Inc(K);
    if (K <= High(T)) and (OrdinalOf(T[K]) <> 0) then
      Exit(OrdinalRefersToFile(T, K, K + 1, ADepth + 1));
    Exit(True);
  end;
  Result := False;
end;

{ Token index where an exception starts ("todos menos o último"), or MaxInt. Ends at the next punctuation. }
procedure ExceptRange(const T: TArray<string>; out AFrom, ATo: Integer);
var
  I: Integer;
begin
  AFrom := MaxInt;
  ATo := MaxInt;
  for I := 0 to High(T) do
    if InList(T[I], EXCEPT_WORDS) and not ((I > 0) and InList(T[I - 1], ['pelo', 'ao', 'al', 'least'])) then
    begin
      AFrom := I;
      Break;
    end;
  if AFrom = MaxInt then
    Exit;
  for I := AFrom + 1 to High(T) do
    if T[I] = PUNCT_MARK then
    begin
      ATo := I;
      Exit;
    end;
end;

procedure FindTokenPicks(const T: TArray<string>; AExFrom, AExTo: Integer; var P: TPicks);
var
  I, V, N, After: Integer;
  Ex: Boolean;
begin
  for I := 0 to High(T) do
  begin
    Ex := (I > AExFrom) and (I < AExTo);
    { "arquivo 2", "file 3" }
    if InList(T[I], FILE_WORDS) and (I < High(T)) and (StrToIntDef(T[I + 1], 0) > 0) then
    begin
      P.Add(StrToInt(T[I + 1]) - 1, Ex);
      Continue;
    end;
    V := OrdinalOf(T[I]);
    if V = 0 then
      Continue;
    N := 0;
    After := I + 1;
    if (I > 0) and (NumberOf(T[I - 1]) > 0) then
      N := NumberOf(T[I - 1])
    else if (After <= High(T)) and (NumberOf(T[After]) > 0) and (After < High(T)) and
      InList(T[After + 1], FILE_WORDS) then
    begin
      N := NumberOf(T[After]);
      Inc(After);
    end;
    if (N = 0) and IsPlural(T[I]) then
      Continue;
    if (V <> 1) and (V <> -1) then
      N := 0;
    if OrdinalRefersToFile(T, I, After) then
      AddOrdinal(P, V, N, Ex);
  end;
end;

procedure FindCjkPicks(const F: string; var P: TPicks);
var
  I, K, Pos0, After, FilePos, Best: Integer;
  Ex: Boolean;
  S, W: string;
begin
  for I := 0 to High(CJK_ORD) do
  begin
    Pos0 := Pos(CJK_ORD[I].W, F);
    while Pos0 > 0 do
    begin
      { "倒数第二" also contains "第二", "最後から2番目" also contains "最後". }
      if ((CJK_ORD[I].W = '第二') and (Pos0 > 2) and ((Copy(F, Pos0 - 2, 2) = '倒数') or
         (Copy(F, Pos0 - 2, 2) = '倒數'))) or
         (((CJK_ORD[I].W = '最後') or (CJK_ORD[I].W = '最后')) and (Copy(F, Pos0 + 2, 2) = 'から')) then
      begin
        Pos0 := PosEx(CJK_ORD[I].W, F, Pos0 + 1);
        Continue;
      end;
      After := Pos0 + Length(CJK_ORD[I].W);
      Best := 0;
      for K := 0 to High(CJK_FILE) do
      begin
        FilePos := PosEx(CJK_FILE[K], F, After);
        if (FilePos > 0) and (FilePos - After <= 3) then
        begin
          Best := FilePos + Length(CJK_FILE[K]);
          Break;
        end;
      end;
      if Best > 0 then
      begin
        Ex := False;
        for W in CJK_EXCEPT_BEFORE do
          if (Pos(W, F) > 0) and (Pos(W, F) < Pos0) and (Pos0 - Pos(W, F) <= 6) then
            Ex := True;
        S := Copy(F, Best, 4);
        for W in CJK_EXCEPT_AFTER do
          if Pos(W, S) > 0 then
            Ex := True;
        AddOrdinal(P, CJK_ORD[I].V, 1, Ex);
      end;
      Pos0 := PosEx(CJK_ORD[I].W, F, Pos0 + 1);
    end;
  end;
end;

{ Token index of the character position APos in the folded text F (" a b c "). }
function TokenAt(const F: string; APos: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 1 to APos do
    if F[I] = ' ' then
      Inc(Result);
end;

function AgentInferTargets(const APrompt: string; AFiles, ATargets: TStrings): TAgentTargetMode;
var
  F, Name, Base, Ext: string;
  T: TArray<string>;
  P: TPicks;
  Named, Typed: TArray<Boolean>;
  I, K, At, ExFrom, ExTo: Integer;
  AnyNamed, AnyTyped, AnyExc: Boolean;
begin
  ATargets.Clear;
  Result := tgtAll;
  if (AFiles = nil) or (AFiles.Count = 0) then
    Exit;
  F := AgentFoldText(MarkPunctuation(APrompt));
  T := Trim(F).Split([' ']);
  ExceptRange(T, ExFrom, ExTo);
  P.Init(AFiles.Count);
  SetLength(Named, AFiles.Count);
  SetLength(Typed, AFiles.Count);
  AnyNamed := False;
  AnyTyped := False;
  for I := 0 to AFiles.Count - 1 do
  begin
    Name := Trim(AgentFoldText(ExtractFileName(AFiles[I])));
    Base := Trim(AgentFoldText(ChangeFileExt(ExtractFileName(AFiles[I]), '')));
    At := Pos(' ' + Name + ' ', F);
    if (At = 0) and (Length(Base) >= 4) then
      At := Pos(' ' + Base + ' ', F);
    if At > 0 then
    begin
      K := TokenAt(F, At + 1);
      if (K > ExFrom) and (K < ExTo) then
        P.Add(I, True)
      else
      begin
        Named[I] := True;
        AnyNamed := True;
      end;
    end;
  end;
  if AFiles.Count > 1 then
  begin
    MergePenultimate(T);
    ExceptRange(T, ExFrom, ExTo);
    FindTokenPicks(T, ExFrom, ExTo, P);
    FindCjkPicks(F, P);
  end;
  { "do CSV", "os arquivos txt"; not "para um txt" nor the extension of a name ("saida.txt"). }
  for I := 0 to AFiles.Count - 1 do
  begin
    Ext := LowerCase(Copy(ExtractFileExt(AFiles[I]), 2, MaxInt));
    if Length(Ext) < 2 then
      Continue;
    for K := 1 to High(T) do
      if (T[K] = Ext) and not InList(T[K - 1], TO_WORDS) and
         (InList(T[K - 1], LEAD_WORDS) or InList(T[K - 1], FILE_WORDS) or InList(T[K - 1], ALL_WORDS)) then
      begin
        Typed[I] := True;
        AnyTyped := True;
      end;
  end;
  AnyExc := False;
  for I := 0 to AFiles.Count - 1 do
    AnyExc := AnyExc or P.Excl[I];
  for I := 0 to AFiles.Count - 1 do
    if (Named[I] or P.Incl[I]) and not P.Excl[I] then
      ATargets.Add(AFiles[I]);
  if ATargets.Count > 0 then
  begin
    if AnyNamed then
      Exit(tgtNamed);
    Exit(tgtPosition);
  end;
  if P.OutOfRange and not AnyTyped and not AnyExc then
    Exit(tgtNone);
  for I := 0 to AFiles.Count - 1 do
    if (Typed[I] or not AnyTyped) and not P.Excl[I] then
      ATargets.Add(AFiles[I]);
  if ATargets.Count = 0 then
    Exit(tgtNone);
  if AnyExc then
    Result := tgtPosition
  else if AnyTyped then
    Result := tgtType
  else
    Result := tgtAll;
end;

function AgentTargetsNote(AMode: TAgentTargetMode; AFiles, ATargets: TStrings): string;
var
  I: Integer;
  List: string;
begin
  Result := '';
  if (AFiles = nil) or (AFiles.Count < 2) then
    Exit;
  List := '';
  for I := 0 to ATargets.Count - 1 do
    List := List + #13#10 + ATargets[I];
  case AMode of
    tgtAll:
      Result := 'Files for this request (inferred by FastFile): the request names no file, so it is about ALL ' +
        IntToStr(AFiles.Count) + ' selected files. Do the work on each of them, each with its own path.';
    tgtNamed:
      Result := 'Files for this request (inferred by FastFile from the names in the request): ONLY these ' +
        IntToStr(ATargets.Count) + ' file(s). Do not change, export or split the other selected files:' + List;
    tgtPosition:
      Result := 'Files for this request (inferred by FastFile from the positions in the request): ONLY these ' +
        IntToStr(ATargets.Count) + ' file(s). Here "o primeiro" / "o último" / "the last" mean files of the ' +
        'Selected files list, not lines: "read the last" reads that whole file from line 1. Do not change, ' +
        'export or split the other selected files:' + List;
    tgtType:
      Result := 'Files for this request (inferred by FastFile from the file type in the request): ONLY these ' +
        IntToStr(ATargets.Count) + ' file(s). Do not change, export or split the other selected files:' + List;
    tgtNone:
      Result := 'Files for this request: the request picks a file by a position that is not in the list (only ' +
        IntToStr(AFiles.Count) + ' files are selected). Do not act on any file; tell the user which files are ' +
        'selected and ask which one they mean.';
  end;
end;

end.
