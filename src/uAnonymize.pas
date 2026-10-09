unit uAnonymize;

{ Descaracterizacao (anonimizacao) de dados em ficheiros de qualquer tamanho.

  Cada caractere trocado mantem a classe (digito, maiuscula, minuscula, vogal,
  consoante, ideograma...) e exatamente o mesmo numero de bytes na codificacao
  do ficheiro. Por isso a gravacao e feita no proprio ficheiro, sem copia
  temporaria, e o indice de linhas (offsets) continua valido.

  Undo/redo: o jornal guarda apenas as sequencias de bytes alteradas
  (offset + bytes do "outro" estado + hash do estado que deve estar no
  ficheiro). Desfazer e refazer sao a mesma operacao: troca ficheiro <-> jornal,
  com verificacao do hash e reversao automatica se algo nao bater. }

{$Q-}
{$R-}
{$O+}

interface

uses
  Windows, SysUtils, Classes;

const
  { Prefixo das notas UNDO/REDO do historico de sessao vindas da descaracterizacao. }
  ANON_HIST_NOTE_MARK = '[ANON] ';

type
  TAnonTextMode = (atmNone, atmNames, atmAllWords);

  TAnonOptions = record
    Key: UInt64;
    Numbers: Boolean;
    MinDigits: Integer;
    Dates: Boolean;
    Emails: Boolean;
    Codes: Boolean;
    TextMode: TAnonTextMode;
    AllCapsAsNames: Boolean;
    Consistent: Boolean;
    SkipHeader: Boolean;
    { #0 = sem colunas }
    Delimiter: Char;
    { '2,5-7'; vazio = todas as colunas }
    Columns: string;
    { separadas por virgula, ponto e virgula, espaco ou quebra de linha }
    KeepWords: string;
  end;

  TAnonRange = record
    Start: Int64;
    Len: Int64;
  end;
  TAnonRanges = array of TAnonRange;

  TAnonChar = record
    Pos: Integer;
    CP: Cardinal;
    Len: Byte;
    Cls: Byte;
    Grp: Byte;
    SB: Boolean;
  end;

  TAnonGroup = record
    Kind: Byte;
    First: Integer;
    Count: Integer;
    SepCP: Cardinal;
  end;

  { Estado de trabalho de uma thread (um por parte processada em paralelo). }
  TAnonCtx = class
  public
    T: array of TAnonChar;
    G: array of TAnonGroup;
    Idx: array of Integer;
    OrigD: array of Integer;
    NewD: array of Integer;
    N, M: Integer;
    Src, Dst: PByte;
    AbsBase: Int64;
    Field: Integer;
    InQuotes: Boolean;
    LineDirty: Boolean;
    SentenceStart: Boolean;
    LastTokLen: Integer;
    LinesChanged: Int64;
    Rng: UInt64;
    constructor Create;
  end;

  TAnonEngine = class
  private
    FOpt: TAnonOptions;
    FKind: Integer;
    FSbcs: Integer;
    FUnit: Integer;
    FDelim: Cardinal;
    FColsActive: Boolean;
    FCols: array[0..1023] of Boolean;
    FLead: array[0..255] of Boolean;
    FSkip: array[0..255] of Boolean;
    FGb18030: Boolean;
    FKeep: array of UInt64;
    procedure AddKeepWord(const W: string);
    procedure Decode(Src: PByte; I, L: Integer; var Ch: TAnonChar);
    function PutCP(C: TAnonCtx; AIdx: Integer; ANewCP: Cardinal): Boolean;
    procedure PutDigit(C: TAnonCtx; AIdx, ADigit: Integer);
    procedure WriteNumber(C: TAnonCtx; AGroup, AValue, AWidth: Integer);
    function GroupValue(C: TAnonCtx; AGroup: Integer): Integer;
    function FoldHash(C: TAnonCtx; A, B: Integer): UInt64;
    function SeedFor(C: TAnonCtx; A, B: Integer; ASalt: Cardinal): UInt64;
    function IsKept(AHash: UInt64): Boolean;
    function GroupEnd(C: TAnonCtx; AGroup: Integer): Integer;
    function GluedAfter(C: TAnonCtx; AGroup: Integer): Boolean;
    procedure EndLine(C: TAnonCtx);
    procedure ProcessToken(C: TAnonCtx);
    procedure ProcessGroups(C: TAnonCtx; G0, G1: Integer);
    procedure ProcessWord(C: TAnonCtx; A, B: Integer);
    procedure ProcessLetterWord(C: TAnonCtx; A, B: Integer);
    procedure ReplaceDigitRange(C: TAnonCtx; A, B: Integer);
    procedure ScrambleRange(C: TAnonCtx; A, B: Integer; ALettersOnly: Boolean);
    function TryDictionary(C: TAnonCtx; A, B: Integer): Boolean;
    procedure ProcessEmail(C: TAnonCtx; AAt: Integer);
    function TryDate(C: TAnonCtx; GI: Integer): Integer;
    function TryTime(C: TAnonCtx; GI: Integer): Integer;
    function TryIPv4(C: TAnonCtx; GI: Integer): Integer;
    function TryCpfCnpj(C: TAnonCtx; GI: Integer): Integer;
    function UnitAt(P: PByte; I: Integer): Cardinal;
  public
    constructor Create(const AOptions: TAnonOptions; const AEncoding: string);
    { Src/Dst com Len bytes; Dst deve comecar como copia de Src. }
    procedure ProcessSpan(C: TAnonCtx; Src, Dst: PByte; Len: Integer; AbsBase: Int64);
    { Fim seguro de bloco: depois da ultima quebra de linha (ou fronteira de caractere). }
    function FindCut(P: PByte; Len: Integer): Integer;
    function NextLineStart(P: PByte; AFrom, Len: Integer): Integer;
    property UnitSize: Integer read FUnit;
  end;

  TAnonJobKind = (ajkApply, ajkUndo, ajkRedo);

  TAnonJobResult = record
    Kind: TAnonJobKind;
    Success: Boolean;
    Cancelled: Boolean;
    Mismatch: Boolean;
    RolledBack: Boolean;
    ErrorMsg: string;
    BytesScanned: Int64;
    BytesChanged: Int64;
    LinesChanged: Int64;
    RunCount: Int64;
    JournalPath: string;
    ElapsedMs: Cardinal;
  end;

  { APhase: 0 = descaracterizar, 1 = reverter, 2 = desfazer/refazer }
  TAnonProgressEvent = procedure(ADone, ATotal: Int64; APhase: Integer) of object;
  TAnonCancelQuery = function: Boolean of object;

function AnonDefaultOptions: TAnonOptions;
function AnonNewRandomKey: UInt64;
function AnonKeyFromText(const S: string): UInt64;
function AnonKeyToText(AKey: UInt64): string;
function AnonColumnsValid(const S: string): Boolean;

{ Pre-visualizacao de uma linha (bytes crus, sem quebra). }
function AnonPreviewBytes(AEngine: TAnonEngine; const ARaw: AnsiString;
  AAbsOffset: Int64; out AChanged: Boolean): AnsiString;

{ ARanges: offsets de bytes 0-based; vazio = arquivo inteiro. }
function AnonApplyToFile(const ATarget, AJournal: string; const AOptions: TAnonOptions;
  const AEncoding: string; const ARanges: TAnonRanges;
  AProgress: TAnonProgressEvent; ACancel: TAnonCancelQuery): TAnonJobResult;
function AnonSwapFile(AKind: TAnonJobKind; const ATarget, AJournal: string;
  AProgress: TAnonProgressEvent): TAnonJobResult;

function AnonJournalDir: string;
function AnonNewJournalPath: string;
procedure AnonDeleteJournal(const APath: string);
{ Remove jornais de sessoes anteriores (processo dono ja terminou). }
procedure AnonCleanupJournalDir;
function AnonEstimateJournalBytes(AScopeBytes: Int64; AChangedRatio: Double): Int64;

implementation

uses
  Math, DateUtils, System.Threading, Generics.Collections, uTextEncoding, uFastFilePaths;

const
  ANON_WINDOW = 16 * 1024 * 1024;
  ANON_SPAN_GAP = 256 * 1024;
  ANON_MAX_TOKEN = 1024;
  ANON_RUN_GAP = 16;
  ANON_MAX_RUN = 1024 * 1024;
  ANON_PARALLEL_MIN = 2 * 1024 * 1024;
  ANON_MAX_PARTS = 8;
  ANON_JOURNAL_HEADER = 32;
  ANON_RUN_HEADER = 16;
  ANON_JOURNAL_BUF = 4 * 1024 * 1024;
  ANON_SWAP_CHUNK = 8 * 1024 * 1024;
  ANON_SWAP_GAP = 64 * 1024;
  ANON_JOURNAL_SUBDIR = 'anon_undo';
  ANON_JOURNAL_EXT = '.ffanon';

  aekBytes = 0;
  aekDbcs = 1;
  aekUtf16LE = 2;
  aekUtf16BE = 3;
  aekUtf32LE = 4;
  aekUtf32BE = 5;

  asbNone = 0;
  asbLatin1 = 1;
  asbCyrillic = 2;

  ccOther = 0;
  ccDigit = 1;
  ccUpper = 2;
  ccLower = 3;
  ccNoCase = 4;
  ccKeep = 5;

  rgNone = 0;
  rgAUV = 1;
  rgAUC = 2;
  rgALV = 3;
  rgALC = 4;
  rgDigit = 5;
  rgFullDigit = 6;
  rgLUV = 7;
  rgLUC = 8;
  rgLLV = 9;
  rgLLC = 10;
  rgCyrU = 11;
  rgCyrL = 12;
  rgCJK = 13;
  rgHira = 14;
  rgKata = 15;
  rgHangul = 16;
  rgFullU = 17;
  rgFullL = 18;
  RG_COUNT = 19;

  gkDigits = 0;
  gkLetters = 1;
  gkSep = 2;

  FNV64_OFFSET: UInt64 = UInt64($CBF29CE484222325);
  FNV64_PRIME: UInt64 = UInt64($00000100000001B3);
  GOLDEN64: UInt64 = UInt64($9E3779B97F4A7C15);

  ANON_JOURNAL_MAGIC: AnsiString = 'FFANONJ1';

  ANON_SECOND_LEVEL = ' com net org gov edu co ac ne or go mil nom art eti adv ind inf ';
  ANON_PUBLIC_MAIL = ' gmail googlemail hotmail outlook live msn yahoo ymail icloud me mac aol uol' +
    ' bol terra ig globo globomail r7 zipmail oi proton protonmail pm gmx yandex mail qq' +
    ' 163 126 sina naver daum web libero orange free wp o2 seznam freemail citromail ';
  ANON_BUILTIN_KEEP = 'de da do das dos e del la las los le van von der den di du y of the and ' +
    'Sr Sra Srta Dr Dra Prof Tel Fone Cel Av Rua Mr Mrs Ms Nr Nro';

  { Nomes e sobrenomes usados como substitutos (mesmo comprimento e mesma
    posicao de acentos do original). }
  ANON_NAMES_1 =
    'Al Bo Di Ed Jo Lu Mo Ra Li Zé Tó Lé ' +
    'Ana Bia Edu Ivo Lia Rui Teo Ari Gil Ian Ada Max Leo Noa Zoe Ema Ben Dan Eva Ida ' +
    'Joe Kim Liz Ned Pam Ray Sam Tom Val Abe Cid Dom Eli Fay Gus Hal Ike Jan Kai Lou ' +
    'Mia Nil Ola Pia Ron Sol Uri Vic Wes Yan Zac Léa Tão Ené ';
  ANON_NAMES_2 =
    'Alex Alan Bela Beto Caio Davi Duda Enzo Erik Gabi Hugo Igor Iara Jair Joel Kaio ' +
    'Lara Luan Luiz Maya Nina Otto Raul Rita Tais Theo Vera Yuri Zeca Abel Alda Anna ' +
    'Beth Bill Carl Dave Dora Elsa Emma Fred Gina Hans Iris Jack Jane Joan John Josh ' +
    'Karl Kate Kyle Leah Lena Lisa Luke Mark Mary Matt Mike Nick Noah Owen Paul Pete ' +
    'Rosa Ruth Ryan Sara Sean Tina Toby Todd Troy Wade Walt Zara Lima Melo Rios Dias ' +
    'João José Inês Adão Iná Simão Lúcio ';
  ANON_NAMES_3 =
    'Bruno Pedro Lucas Mateus Paulo Carla Diego Elisa Fabio Gisele Heitor Irene Jorge ' +
    'Laura Mario Nadia Oscar Paula Renan Sofia Tiago Ursula Vitor Wilma Xavier Yasmin ' +
    'Silva Souza Costa Rocha Alves Gomes Nunes Moura Pinto Mendes Ramos Cunha Barros ' +
    'Freitas Ribeiro Martins Carvalho Teixeira Moreira Cardoso Machado Barbosa ' +
    'Andrade Azevedo Correia Fonseca Monteiro Medeiros Siqueira Quintana Valente ' +
    'Benedito Clarisse Domingos Eduardo Fernanda Gustavo Henrique Isabela Juliana ' +
    'Leonardo Marcelo Natalia Rafaela Rodrigo Samuel Tatiana Vanessa Wagner Adriana ';
  ANON_NAMES_4 =
    'Oliveira Rodrigues Nascimento Albuquerque Vasconcelos Cavalcanti Bittencourt ' +
    'Wanderley Figueiredo Constantino Maximiliano Florentino Valentina Guilherme ' +
    'Alessandra Montenegro Christopher Cristiano Francisco Gabriela Leopoldo Margarida ' +
    'Esperança Conceição Assunção Gonçalves Magalhães Brandão Simões Guimarães Antônio ' +
    'Sebastião Estêvão Lúcia Mônica Márcia Patrícia Letícia Cecília Natália Vitória ' +
    'Valéria Flávia Fábio Júlio César Rúben Vinícius Damião Romão Lourenço Inácio ';
  ANON_NAMES_5 =
    'Otávio Ângela Érica Ítalo Úrsula Ênio Débora Rômulo Péricles Ônix Álvaro Aurélio ' +
    'Cláudio Cristóvão Émerson Fabrício Glória Hélio Jéssica Lívia Mário Nélson Sílvia ' +
    'Tânia Vânia Zélia Mércia Célia Jânio Pâmela Tício Sérgio Lázaro Gaspar Baltazar ' +
    'Cristina Leandro Roberto Ricardo Augusto Marcos Carlos Danilo Thiago Felipe ' +
    'Daniela Camila Larissa Beatriz Mariana Amanda Leticia Priscila Rebeca Simone ';

type
  TAnonPool = record
    Lo, Hi: Cardinal;
    Items: array of Cardinal;
  end;

  TAnonNameList = TList<Integer>;

var
  GPools: array[0..RG_COUNT - 1] of TAnonPool;
  GLowCls: array[0..255] of Byte;
  GLowGrp: array[0..255] of Byte;
  GCp1252Hi: array[$80..$9F] of Cardinal;
  GNames: array of TArray<Cardinal>;
  GNameHashes: TArray<UInt64>;
  GSecondLevelHashes: TArray<UInt64>;
  GPublicMailHashes: TArray<UInt64>;
  GNameBuckets: TObjectDictionary<Cardinal, TAnonNameList>;

{ ---------------------------------------------------------------------------- }
{ Hash / PRNG                                                                  }
{ ---------------------------------------------------------------------------- }

function Mix64(X: UInt64): UInt64;
begin
  X := (X xor (X shr 30)) * UInt64($BF58476D1CE4E5B9);
  X := (X xor (X shr 27)) * UInt64($94D049BB133111EB);
  Result := X xor (X shr 31);
end;

function NextRand(C: TAnonCtx): UInt64; inline;
begin
  C.Rng := C.Rng + GOLDEN64;
  Result := Mix64(C.Rng);
end;

function RandInt(C: TAnonCtx; N: Integer): Integer;
begin
  if N <= 1 then
    Result := 0
  else
    Result := Integer((NextRand(C) shr 33) mod UInt64(N));
end;

function Fnv32(P: PByte; Len: Integer): Cardinal;
var
  I: Integer;
begin
  Result := 2166136261;
  for I := 0 to Len - 1 do
    Result := (Result xor P[I]) * 16777619;
end;

function FoldCP(CP: Cardinal): Cardinal; inline;
begin
  Result := CP;
  if (CP >= Ord('A')) and (CP <= Ord('Z')) then
    Inc(Result, 32)
  else if (CP >= $C0) and (CP <= $DE) and (CP <> $D7) then
    Inc(Result, 32)
  else if (CP >= $0410) and (CP <= $042F) then
    Inc(Result, 32)
  else if (CP >= $FF21) and (CP <= $FF3A) then
    Inc(Result, 32);
end;

function UpperCP(CP: Cardinal): Cardinal;
begin
  Result := CP;
  if (CP >= Ord('a')) and (CP <= Ord('z')) then
    Dec(Result, 32)
  else if (CP >= $E0) and (CP <= $FE) and (CP <> $F7) then
    Dec(Result, 32)
  else if (CP >= $0430) and (CP <= $044F) then
    Dec(Result, 32)
  else if (CP >= $FF41) and (CP <= $FF5A) then
    Dec(Result, 32);
end;

function PoolPick(AGrp: Byte; R: UInt64): Cardinal;
begin
  if Length(GPools[AGrp].Items) > 0 then
    Result := GPools[AGrp].Items[R mod UInt64(Length(GPools[AGrp].Items))]
  else
    Result := GPools[AGrp].Lo + Cardinal(R mod UInt64(GPools[AGrp].Hi - GPools[AGrp].Lo + 1));
end;

{ ---------------------------------------------------------------------------- }
{ Classificacao de caracteres                                                  }
{ ---------------------------------------------------------------------------- }

procedure ClassifyCP(CP: Cardinal; out ACls, AGrp: Byte);
begin
  if CP <= $FF then
  begin
    ACls := GLowCls[CP];
    AGrp := GLowGrp[CP];
    Exit;
  end;
  AGrp := rgNone;
  ACls := ccKeep;
  case CP of
    $0410..$042F: begin ACls := ccUpper; AGrp := rgCyrU; end;
    $0430..$044F: begin ACls := ccLower; AGrp := rgCyrL; end;
    $2000..$2BFF, $3000..$3040, $D800..$DFFF, $FE10..$FE6F, $FF01..$FF0F,
    $FF1A..$FF20, $FF3B..$FF40, $FF5B..$FF65, $FFF0..$FFFF:
      ACls := ccOther;
    $3041..$3093: begin ACls := ccNoCase; AGrp := rgHira; end;
    $30A1..$30F3: begin ACls := ccNoCase; AGrp := rgKata; end;
    $4E00..$9FA5: begin ACls := ccNoCase; AGrp := rgCJK; end;
    $AC00..$D7A3: begin ACls := ccNoCase; AGrp := rgHangul; end;
    $FF10..$FF19: begin ACls := ccDigit; AGrp := rgFullDigit; end;
    $FF21..$FF3A: begin ACls := ccUpper; AGrp := rgFullU; end;
    $FF41..$FF5A: begin ACls := ccLower; AGrp := rgFullL; end;
  else
    if CP >= $10000 then
      ACls := ccOther;
  end;
end;

function IsConnector(CP: Cardinal): Boolean; inline;
begin
  case CP of
    Ord('.'), Ord('-'), Ord('/'), Ord(':'), Ord('@'), Ord('_'), Ord('+'):
      Result := True;
  else
    Result := False;
  end;
end;

function IsLatin1Group(G: Byte): Boolean; inline;
begin
  Result := (G >= rgLUV) and (G <= rgLLC);
end;

function IsAsciiLetterGroup(G: Byte): Boolean; inline;
begin
  Result := (G >= rgAUV) and (G <= rgALC);
end;

{ ---------------------------------------------------------------------------- }
{ Tabelas globais                                                              }
{ ---------------------------------------------------------------------------- }

procedure SetPoolStr(AGrp: Byte; const S: string);
var
  I: Integer;
begin
  SetLength(GPools[AGrp].Items, Length(S));
  for I := 1 to Length(S) do
    GPools[AGrp].Items[I - 1] := Ord(S[I]);
end;

procedure SetPoolRange(AGrp: Byte; ALo, AHi: Cardinal);
begin
  GPools[AGrp].Lo := ALo;
  GPools[AGrp].Hi := AHi;
  SetLength(GPools[AGrp].Items, 0);
end;

procedure SetLow(CP: Cardinal; ACls, AGrp: Byte);
begin
  GLowCls[CP] := ACls;
  GLowGrp[CP] := AGrp;
end;

procedure InitTables;
const
  UV = #$C0#$C1#$C2#$C3#$C4#$C8#$C9#$CA#$CB#$CC#$CD#$CE#$CF#$D2#$D3#$D4#$D5#$D6#$D9#$DA#$DB#$DC;
  LV = #$E0#$E1#$E2#$E3#$E4#$E8#$E9#$EA#$EB#$EC#$ED#$EE#$EF#$F2#$F3#$F4#$F5#$F6#$F9#$FA#$FB#$FC;
var
  I: Integer;
  C: Char;
begin
  FillChar(GLowCls, SizeOf(GLowCls), ccOther);
  FillChar(GLowGrp, SizeOf(GLowGrp), rgNone);
  for C := '0' to '9' do SetLow(Ord(C), ccDigit, rgDigit);
  for C := 'A' to 'Z' do
    if Pos(C, 'AEIOU') > 0 then SetLow(Ord(C), ccUpper, rgAUV) else SetLow(Ord(C), ccUpper, rgAUC);
  for C := 'a' to 'z' do
    if Pos(C, 'aeiou') > 0 then SetLow(Ord(C), ccLower, rgALV) else SetLow(Ord(C), ccLower, rgALC);
  for I := $C0 to $DE do
    SetLow(I, ccUpper, rgLUV);
  for I := $DF to $FF do
    SetLow(I, ccLower, rgLLV);
  SetLow($C7, ccUpper, rgLUC);
  SetLow($D0, ccUpper, rgLUC);
  SetLow($D1, ccUpper, rgLUC);
  SetLow($DE, ccUpper, rgLUC);
  SetLow($DF, ccLower, rgLLC);
  SetLow($E7, ccLower, rgLLC);
  SetLow($F0, ccLower, rgLLC);
  SetLow($F1, ccLower, rgLLC);
  SetLow($FE, ccLower, rgLLC);
  SetLow($D7, ccOther, rgNone);
  SetLow($F7, ccOther, rgNone);
  SetLow($AA, ccKeep, rgNone);
  SetLow($BA, ccKeep, rgNone);
  SetLow($B5, ccKeep, rgNone);

  SetPoolStr(rgAUV, 'AEIOU');
  SetPoolStr(rgAUC, 'BCDFGHJKLMNPQRSTVWXZ');
  SetPoolStr(rgALV, 'aeiou');
  SetPoolStr(rgALC, 'bcdfghjklmnpqrstvwxz');
  SetPoolRange(rgDigit, Ord('0'), Ord('9'));
  SetPoolRange(rgFullDigit, $FF10, $FF19);
  SetPoolStr(rgLUV, UV);
  SetPoolStr(rgLUC, #$C7#$D1);
  SetPoolStr(rgLLV, LV);
  SetPoolStr(rgLLC, #$E7#$F1);
  SetPoolRange(rgCyrU, $0410, $042F);
  SetPoolRange(rgCyrL, $0430, $044F);
  SetPoolRange(rgCJK, $4E00, $9FA5);
  SetPoolRange(rgHira, $3041, $3093);
  SetPoolRange(rgKata, $30A1, $30F3);
  SetPoolRange(rgHangul, $AC00, $D7A3);
  SetPoolRange(rgFullU, $FF21, $FF3A);
  SetPoolRange(rgFullL, $FF41, $FF5A);

  for I := $80 to $9F do
    GCp1252Hi[I] := $FFFD;
  GCp1252Hi[$8A] := $0160;
  GCp1252Hi[$8C] := $0152;
  GCp1252Hi[$8E] := $017D;
  GCp1252Hi[$9A] := $0161;
  GCp1252Hi[$9C] := $0153;
  GCp1252Hi[$9E] := $017E;
  GCp1252Hi[$9F] := $0178;
end;

procedure InitNames;
var
  All: string;
  Words: TStringList;
  I, K, N: Integer;
  Sig: Cardinal;
  Cls, Grp: Byte;
  Ok: Boolean;
  L: TAnonNameList;
  H: UInt64;
begin
  GNameBuckets := TObjectDictionary<Cardinal, TAnonNameList>.Create([doOwnsValues]);
  All := ANON_NAMES_1 + ANON_NAMES_2 + ANON_NAMES_3 + ANON_NAMES_4 + ANON_NAMES_5;
  Words := TStringList.Create;
  try
    Words.Delimiter := ' ';
    Words.StrictDelimiter := True;
    Words.DelimitedText := Trim(All);
    SetLength(GNames, Words.Count);
    SetLength(GNameHashes, Words.Count);
    N := 0;
    for I := 0 to Words.Count - 1 do
    begin
      if (Length(Words[I]) < 2) or (Length(Words[I]) > 16) then Continue;
      SetLength(GNames[N], Length(Words[I]));
      Sig := Cardinal(Length(Words[I])) shl 16;
      Ok := True;
      for K := 1 to Length(Words[I]) do
      begin
        GNames[N][K - 1] := FoldCP(Ord(Words[I][K]));
        ClassifyCP(GNames[N][K - 1], Cls, Grp);
        if IsLatin1Group(Grp) then
          Sig := Sig or (Cardinal(1) shl (K - 1))
        else if not IsAsciiLetterGroup(Grp) then
          Ok := False;
      end;
      if not Ok then Continue;
      H := FNV64_OFFSET;
      for K := 0 to High(GNames[N]) do
        H := (H xor GNames[N][K]) * FNV64_PRIME;
      GNameHashes[N] := H;
      if not GNameBuckets.TryGetValue(Sig, L) then
      begin
        L := TAnonNameList.Create;
        GNameBuckets.Add(Sig, L);
      end;
      L.Add(N);
      Inc(N);
    end;
    SetLength(GNames, N);
    SetLength(GNameHashes, N);
    TArray.Sort<UInt64>(GNameHashes);
  finally
    Words.Free;
  end;
end;

function InSortedHashes(const AList: TArray<UInt64>; AHash: UInt64): Boolean;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := High(AList);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) shr 1;
    if AList[Mid] = AHash then
    begin
      Result := True;
      Exit;
    end;
    if AList[Mid] < AHash then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
  Result := False;
end;

function IsKnownName(AHash: UInt64): Boolean; inline;
begin
  Result := InSortedHashes(GNameHashes, AHash);
end;

function BuildHashSet(const S: string): TArray<UInt64>;
var
  I, N: Integer;
  H: UInt64;
  InWord: Boolean;
begin
  SetLength(Result, Length(S));
  N := 0;
  H := FNV64_OFFSET;
  InWord := False;
  for I := 1 to Length(S) + 1 do
    if (I > Length(S)) or (S[I] = ' ') then
    begin
      if InWord then
      begin
        Result[N] := H;
        Inc(N);
      end;
      H := FNV64_OFFSET;
      InWord := False;
    end
    else
    begin
      H := (H xor FoldCP(Ord(S[I]))) * FNV64_PRIME;
      InWord := True;
    end;
  SetLength(Result, N);
  TArray.Sort<UInt64>(Result);
end;

{ ---------------------------------------------------------------------------- }
{ Opcoes / chave                                                               }
{ ---------------------------------------------------------------------------- }

function AnonDefaultOptions: TAnonOptions;
begin
  Result.Key := AnonNewRandomKey;
  Result.Numbers := True;
  Result.MinDigits := 1;
  Result.Dates := True;
  Result.Emails := True;
  Result.Codes := True;
  Result.TextMode := atmNames;
  Result.AllCapsAsNames := False;
  Result.Consistent := True;
  Result.SkipHeader := False;
  Result.Delimiter := #0;
  Result.Columns := '';
  Result.KeepWords := '';
end;

function AnonNewRandomKey: UInt64;
var
  PC: Int64;
  G: TGUID;
begin
  QueryPerformanceCounter(PC);
  CreateGUID(G);
  Result := Mix64(UInt64(PC) xor (UInt64(G.D1) shl 32) xor UInt64(G.D2) xor
    (UInt64(G.D3) shl 16) xor UInt64(GetTickCount));
  Result := Mix64(Result xor PUInt64(@G.D4[0])^);
end;

function AnonKeyToText(AKey: UInt64): string;
begin
  Result := IntToHex(Int64(AKey), 16);
end;

function AnonKeyFromText(const S: string): UInt64;
var
  T: string;
  I, D: Integer;
  H: UInt64;
  IsHex: Boolean;
begin
  T := UpperCase(Trim(S));
  IsHex := Length(T) = 16;
  H := 0;
  for I := 1 to Length(T) do
  begin
    case T[I] of
      '0'..'9': D := Ord(T[I]) - Ord('0');
      'A'..'F': D := Ord(T[I]) - Ord('A') + 10;
    else
      D := -1;
    end;
    if D < 0 then
    begin
      IsHex := False;
      Break;
    end;
    H := (H shl 4) or UInt64(D);
  end;
  if IsHex then
  begin
    Result := H;
    Exit;
  end;
  T := Trim(S);
  H := FNV64_OFFSET;
  for I := 1 to Length(T) do
    H := (H xor Ord(T[I])) * FNV64_PRIME;
  Result := Mix64(H);
end;

function ParseColumns(const S: string; var ACols: array of Boolean): Boolean;
var
  Parts: TStringList;
  I, P, A, B, K: Integer;
  Part: string;
begin
  Result := True;
  for K := 0 to High(ACols) do
    ACols[K] := False;
  Parts := TStringList.Create;
  try
    Parts.Delimiter := ',';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := StringReplace(Trim(S), ';', ',', [rfReplaceAll]);
    for I := 0 to Parts.Count - 1 do
    begin
      Part := Trim(Parts[I]);
      if Part = '' then Continue;
      P := Pos('-', Part);
      if P > 0 then
      begin
        A := StrToIntDef(Trim(Copy(Part, 1, P - 1)), -1);
        B := StrToIntDef(Trim(Copy(Part, P + 1, MaxInt)), -1);
      end
      else
      begin
        A := StrToIntDef(Part, -1);
        B := A;
      end;
      if (A < 1) or (B < A) or (B > High(ACols)) then
      begin
        Result := False;
        Exit;
      end;
      for K := A to B do
        ACols[K] := True;
    end;
  finally
    Parts.Free;
  end;
end;

function AnonColumnsValid(const S: string): Boolean;
var
  Cols: array[0..1023] of Boolean;
begin
  Result := ParseColumns(S, Cols);
end;

{ ---------------------------------------------------------------------------- }
{ TAnonCtx                                                                     }
{ ---------------------------------------------------------------------------- }

constructor TAnonCtx.Create;
begin
  inherited Create;
  SetLength(T, ANON_MAX_TOKEN + 4);
  SetLength(G, ANON_MAX_TOKEN + 4);
  SetLength(Idx, ANON_MAX_TOKEN + 4);
  SetLength(OrigD, ANON_MAX_TOKEN + 4);
  SetLength(NewD, ANON_MAX_TOKEN + 4);
end;

{ ---------------------------------------------------------------------------- }
{ TAnonEngine                                                                  }
{ ---------------------------------------------------------------------------- }

constructor TAnonEngine.Create(const AOptions: TAnonOptions; const AEncoding: string);
var
  CP: UINT;
  I: Integer;
  S, W: string;
  Cls, Grp: Byte;
  K: Integer;
  Tmp: UInt64;
  J: Integer;
begin
  inherited Create;
  FOpt := AOptions;
  if FOpt.MinDigits < 1 then FOpt.MinDigits := 1;
  FKind := aekBytes;
  FSbcs := asbNone;
  FUnit := 1;
  if IsUtf32BEEncoding(AEncoding) then
  begin
    FKind := aekUtf32BE;
    FUnit := 4;
  end
  else if IsUtf32LEEncoding(AEncoding) then
  begin
    FKind := aekUtf32LE;
    FUnit := 4;
  end
  else if IsUtf16BEEncoding(AEncoding) then
  begin
    FKind := aekUtf16BE;
    FUnit := 2;
  end
  else if IsUtf16LEEncoding(AEncoding) then
  begin
    FKind := aekUtf16LE;
    FUnit := 2;
  end
  else if not IsUtf8Encoding(AEncoding) then
  begin
    if not TryGetCodePageFromEncoding(AEncoding, CP) then
      CP := CP_ACP;
    if CP = CP_ACP then
      CP := GetACP;
    case CP of
      1252, 28591, 28605:
        FSbcs := asbLatin1;
      1251:
        FSbcs := asbCyrillic;
      932, 936, 949, 950, 1361, 54936:
        begin
          FKind := aekDbcs;
          FGb18030 := CP = 54936;
          for I := $80 to $FF do
            FLead[I] := IsDBCSLeadByteEx(CP, Byte(I));
        end;
    end;
  end;

  FDelim := Ord(FOpt.Delimiter);
  FColsActive := (FDelim <> 0) and (Trim(FOpt.Columns) <> '') and ParseColumns(FOpt.Columns, FCols);

  for I := 0 to 255 do
    FSkip[I] := (I < $80) and (GLowCls[I] = ccOther) and (I <> 10) and (I <> 13) and
      (I <> 34) and (I <> Ord('.')) and (I <> Ord('!')) and (I <> Ord('?')) and
      (Cardinal(I) <> FDelim);

  S := ANON_BUILTIN_KEEP + ' ' + FOpt.KeepWords;
  W := '';
  for I := 1 to Length(S) do
  begin
    ClassifyCP(Ord(S[I]), Cls, Grp);
    if Cls = ccOther then
    begin
      if W <> '' then AddKeepWord(W);
      W := '';
    end
    else
      W := W + S[I];
  end;
  if W <> '' then AddKeepWord(W);
  { ordenacao simples (lista pequena) para busca binaria }
  for K := 1 to High(FKeep) do
  begin
    Tmp := FKeep[K];
    J := K - 1;
    while (J >= 0) and (FKeep[J] > Tmp) do
    begin
      FKeep[J + 1] := FKeep[J];
      Dec(J);
    end;
    FKeep[J + 1] := Tmp;
  end;
end;

procedure TAnonEngine.AddKeepWord(const W: string);
var
  H: UInt64;
  I: Integer;
begin
  H := FNV64_OFFSET;
  for I := 1 to Length(W) do
    H := (H xor FoldCP(Ord(W[I]))) * FNV64_PRIME;
  SetLength(FKeep, Length(FKeep) + 1);
  FKeep[High(FKeep)] := H;
end;

function TAnonEngine.IsKept(AHash: UInt64): Boolean;
var
  Lo, Hi, Mid: Integer;
begin
  Lo := 0;
  Hi := High(FKeep);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) shr 1;
    if FKeep[Mid] = AHash then
    begin
      Result := True;
      Exit;
    end;
    if FKeep[Mid] < AHash then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
  Result := False;
end;

procedure TAnonEngine.Decode(Src: PByte; I, L: Integer; var Ch: TAnonChar);
var
  B0, B1, B2, B3: Byte;
  CP: Cardinal;
begin
  Ch.Pos := I;
  Ch.SB := False;
  case FKind of
    aekBytes:
      begin
        B0 := Src[I];
        if B0 < $80 then
        begin
          Ch.CP := B0;
          Ch.Len := 1;
          Ch.Cls := GLowCls[B0];
          Ch.Grp := GLowGrp[B0];
          Exit;
        end;
        if (B0 >= $C2) and (B0 <= $DF) and (I + 1 < L) and ((Src[I + 1] and $C0) = $80) then
        begin
          Ch.CP := (Cardinal(B0 and $1F) shl 6) or (Src[I + 1] and $3F);
          Ch.Len := 2;
          ClassifyCP(Ch.CP, Ch.Cls, Ch.Grp);
          Exit;
        end;
        if (B0 >= $E0) and (B0 <= $EF) and (I + 2 < L) then
        begin
          B1 := Src[I + 1];
          B2 := Src[I + 2];
          if ((B1 and $C0) = $80) and ((B2 and $C0) = $80) then
          begin
            CP := (Cardinal(B0 and $0F) shl 12) or (Cardinal(B1 and $3F) shl 6) or (B2 and $3F);
            if (CP >= $800) and ((CP < $D800) or (CP > $DFFF)) then
            begin
              Ch.CP := CP;
              Ch.Len := 3;
              ClassifyCP(CP, Ch.Cls, Ch.Grp);
              Exit;
            end;
          end;
        end;
        if (B0 >= $F0) and (B0 <= $F4) and (I + 3 < L) then
        begin
          B1 := Src[I + 1];
          B2 := Src[I + 2];
          B3 := Src[I + 3];
          if ((B1 and $C0) = $80) and ((B2 and $C0) = $80) and ((B3 and $C0) = $80) then
          begin
            CP := (Cardinal(B0 and $07) shl 18) or (Cardinal(B1 and $3F) shl 12) or
              (Cardinal(B2 and $3F) shl 6) or (B3 and $3F);
            if (CP >= $10000) and (CP <= $10FFFF) then
            begin
              Ch.CP := CP;
              Ch.Len := 4;
              Ch.Cls := ccOther;
              Ch.Grp := rgNone;
              Exit;
            end;
          end;
        end;
        { byte isolado: pagina de codigo de 1 byte }
        Ch.Len := 1;
        Ch.SB := True;
        case FSbcs of
          asbLatin1:
            begin
              if B0 >= $A0 then
                Ch.CP := B0
              else
                Ch.CP := GCp1252Hi[B0];
              ClassifyCP(Ch.CP, Ch.Cls, Ch.Grp);
            end;
          asbCyrillic:
            if B0 >= $C0 then
            begin
              Ch.CP := $0410 + Cardinal(B0 - $C0);
              ClassifyCP(Ch.CP, Ch.Cls, Ch.Grp);
            end
            else
            begin
              Ch.CP := $FFFD;
              Ch.Cls := ccKeep;
              Ch.Grp := rgNone;
            end;
        else
          Ch.CP := $FFFD;
          Ch.Cls := ccKeep;
          Ch.Grp := rgNone;
        end;
      end;
    aekDbcs:
      begin
        B0 := Src[I];
        if B0 < $80 then
        begin
          Ch.CP := B0;
          Ch.Len := 1;
          Ch.Cls := GLowCls[B0];
          Ch.Grp := GLowGrp[B0];
          Exit;
        end;
        Ch.CP := $FFFD;
        Ch.Cls := ccKeep;
        Ch.Grp := rgNone;
        Ch.Len := 1;
        if FLead[B0] and (I + 1 < L) then
        begin
          if FGb18030 and (I + 3 < L) and (Src[I + 1] >= $30) and (Src[I + 1] <= $39) then
            Ch.Len := 4
          else
            Ch.Len := 2;
        end;
      end;
    aekUtf16LE, aekUtf16BE:
      begin
        if I + 1 >= L then
        begin
          Ch.CP := Src[I];
          Ch.Len := 1;
          Ch.Cls := ccOther;
          Ch.Grp := rgNone;
          Exit;
        end;
        if FKind = aekUtf16LE then
          Ch.CP := Src[I] or (Cardinal(Src[I + 1]) shl 8)
        else
          Ch.CP := (Cardinal(Src[I]) shl 8) or Src[I + 1];
        Ch.Len := 2;
        ClassifyCP(Ch.CP, Ch.Cls, Ch.Grp);
      end;
  else
    begin
      if I + 3 >= L then
      begin
        Ch.CP := Src[I];
        Ch.Len := 1;
        Ch.Cls := ccOther;
        Ch.Grp := rgNone;
        Exit;
      end;
      if FKind = aekUtf32LE then
        Ch.CP := Src[I] or (Cardinal(Src[I + 1]) shl 8) or (Cardinal(Src[I + 2]) shl 16) or
          (Cardinal(Src[I + 3]) shl 24)
      else
        Ch.CP := (Cardinal(Src[I]) shl 24) or (Cardinal(Src[I + 1]) shl 16) or
          (Cardinal(Src[I + 2]) shl 8) or Src[I + 3];
      Ch.Len := 4;
      ClassifyCP(Ch.CP, Ch.Cls, Ch.Grp);
    end;
  end;
end;

function TAnonEngine.PutCP(C: TAnonCtx; AIdx: Integer; ANewCP: Cardinal): Boolean;
var
  P: PByte;
begin
  Result := ANewCP <> C.T[AIdx].CP;
  if not Result then Exit;
  P := C.Dst + C.T[AIdx].Pos;
  case FKind of
    aekBytes, aekDbcs:
      if C.T[AIdx].SB then
      begin
        if FSbcs = asbCyrillic then
          P^ := Byte(ANewCP - $0410 + $C0)
        else
          P^ := Byte(ANewCP);
      end
      else
        case C.T[AIdx].Len of
          1: P^ := Byte(ANewCP);
          2:
            begin
              P[0] := $C0 or Byte(ANewCP shr 6);
              P[1] := $80 or Byte(ANewCP and $3F);
            end;
          3:
            begin
              P[0] := $E0 or Byte(ANewCP shr 12);
              P[1] := $80 or Byte((ANewCP shr 6) and $3F);
              P[2] := $80 or Byte(ANewCP and $3F);
            end;
        end;
    aekUtf16LE:
      begin
        P[0] := Byte(ANewCP);
        P[1] := Byte(ANewCP shr 8);
      end;
    aekUtf16BE:
      begin
        P[0] := Byte(ANewCP shr 8);
        P[1] := Byte(ANewCP);
      end;
    aekUtf32LE:
      begin
        P[0] := Byte(ANewCP);
        P[1] := Byte(ANewCP shr 8);
        P[2] := Byte(ANewCP shr 16);
        P[3] := Byte(ANewCP shr 24);
      end;
    aekUtf32BE:
      begin
        P[0] := Byte(ANewCP shr 24);
        P[1] := Byte(ANewCP shr 16);
        P[2] := Byte(ANewCP shr 8);
        P[3] := Byte(ANewCP);
      end;
  end;
  C.LineDirty := True;
end;

function DigitVal(const Ch: TAnonChar): Integer; inline;
begin
  if Ch.Grp = rgFullDigit then
    Result := Integer(Ch.CP) - $FF10
  else
    Result := Integer(Ch.CP) - Ord('0');
end;

procedure TAnonEngine.PutDigit(C: TAnonCtx; AIdx, ADigit: Integer);
begin
  if C.T[AIdx].Grp = rgFullDigit then
    PutCP(C, AIdx, Cardinal($FF10 + ADigit))
  else
    PutCP(C, AIdx, Cardinal(Ord('0') + ADigit));
end;

procedure TAnonEngine.WriteNumber(C: TAnonCtx; AGroup, AValue, AWidth: Integer);
var
  K: Integer;
begin
  for K := AWidth - 1 downto 0 do
  begin
    PutDigit(C, C.G[AGroup].First + K, AValue mod 10);
    AValue := AValue div 10;
  end;
end;

function TAnonEngine.GroupValue(C: TAnonCtx; AGroup: Integer): Integer;
var
  K: Integer;
begin
  Result := 0;
  for K := C.G[AGroup].First to C.G[AGroup].First + Min(C.G[AGroup].Count, 9) - 1 do
    Result := Result * 10 + DigitVal(C.T[K]);
end;

function TAnonEngine.GroupEnd(C: TAnonCtx; AGroup: Integer): Integer;
begin
  Result := C.G[AGroup].First + C.G[AGroup].Count;
end;

function TAnonEngine.GluedAfter(C: TAnonCtx; AGroup: Integer): Boolean;
begin
  Result := (AGroup < C.M) and (C.G[AGroup].Kind <> gkSep);
end;

function TAnonEngine.FoldHash(C: TAnonCtx; A, B: Integer): UInt64;
var
  K: Integer;
begin
  Result := FNV64_OFFSET;
  for K := A to B - 1 do
    Result := (Result xor FoldCP(C.T[K].CP)) * FNV64_PRIME;
end;

function TAnonEngine.SeedFor(C: TAnonCtx; A, B: Integer; ASalt: Cardinal): UInt64;
begin
  Result := Mix64(FoldHash(C, A, B) xor FOpt.Key xor (UInt64(ASalt) * GOLDEN64));
  if not FOpt.Consistent then
    Result := Mix64(Result xor UInt64(C.AbsBase + C.T[A].Pos));
end;

procedure TAnonEngine.EndLine(C: TAnonCtx);
begin
  if C.LineDirty then
    Inc(C.LinesChanged);
  C.LineDirty := False;
  C.SentenceStart := True;
  C.Field := 1;
  C.InQuotes := False;
end;

procedure TAnonEngine.ProcessSpan(C: TAnonCtx; Src, Dst: PByte; Len: Integer; AbsBase: Int64);
var
  I: Integer;
  Ch, Nx: TAnonChar;
  PT: ^TAnonChar;
  ByteMode: Boolean;
begin
  C.Src := Src;
  C.Dst := Dst;
  C.AbsBase := AbsBase;
  C.Field := 1;
  C.InQuotes := False;
  C.LineDirty := False;
  C.SentenceStart := True;
  ByteMode := FKind <= aekDbcs;
  I := 0;
  while I < Len do
  begin
    if ByteMode then
    begin
      while (I < Len) and FSkip[Src[I]] do
        Inc(I);
      if I >= Len then Break;
    end;
    Decode(Src, I, Len, Ch);
    if Ch.Cls = ccOther then
    begin
      if (Ch.CP = 10) or (Ch.CP = 13) then
        EndLine(C)
      else if Ch.CP = 34 then
        C.InQuotes := not C.InQuotes
      else if (Ch.CP = FDelim) and (not C.InQuotes) then
        Inc(C.Field)
      else if Ch.CP = Ord('.') then
        C.SentenceStart := C.LastTokLen > 3
      else if (Ch.CP = Ord('!')) or (Ch.CP = Ord('?')) then
        C.SentenceStart := True;
      Inc(I, Ch.Len);
      Continue;
    end;
    C.N := 0;
    C.T[0] := Ch;
    C.N := 1;
    Inc(I, Ch.Len);
    while (I < Len) and (C.N < ANON_MAX_TOKEN) do
    begin
      if ByteMode and (Src[I] < $80) and (GLowCls[Src[I]] <> ccOther) then
      begin
        PT := @C.T[C.N];
        PT^.Pos := I;
        PT^.CP := Src[I];
        PT^.Len := 1;
        PT^.Cls := GLowCls[Src[I]];
        PT^.Grp := GLowGrp[Src[I]];
        PT^.SB := False;
        Inc(C.N);
        Inc(I);
        Continue;
      end;
      Decode(Src, I, Len, Ch);
      if Ch.Cls <> ccOther then
      begin
        C.T[C.N] := Ch;
        Inc(C.N);
        Inc(I, Ch.Len);
        Continue;
      end;
      if IsConnector(Ch.CP) and (Ch.CP <> FDelim) and (I + Ch.Len < Len) then
      begin
        Decode(Src, I + Ch.Len, Len, Nx);
        if Nx.Cls <> ccOther then
        begin
          C.T[C.N] := Ch;
          C.T[C.N + 1] := Nx;
          Inc(C.N, 2);
          Inc(I, Ch.Len + Nx.Len);
          Continue;
        end;
      end;
      Break;
    end;
    if (not FColsActive) or ((C.Field <= High(FCols)) and FCols[C.Field]) then
      ProcessToken(C);
    C.SentenceStart := False;
    C.LastTokLen := C.N;
  end;
  EndLine(C);
end;

procedure TAnonEngine.ProcessToken(C: TAnonCtx);
var
  K, GI: Integer;
  Kind: Byte;
begin
  C.M := 0;
  for K := 0 to C.N - 1 do
  begin
    case C.T[K].Cls of
      ccDigit: Kind := gkDigits;
      ccOther: Kind := gkSep;
    else
      Kind := gkLetters;
    end;
    if (Kind = gkSep) or (C.M = 0) or (C.G[C.M - 1].Kind <> Kind) then
    begin
      C.G[C.M].Kind := Kind;
      C.G[C.M].First := K;
      C.G[C.M].Count := 1;
      C.G[C.M].SepCP := C.T[K].CP;
      Inc(C.M);
    end
    else
      Inc(C.G[C.M - 1].Count);
  end;
  if FOpt.Emails then
    for GI := 1 to C.M - 2 do
      if (C.G[GI].Kind = gkSep) and (C.G[GI].SepCP = Ord('@')) and
         (C.G[GI - 1].Kind <> gkSep) and (C.G[GI + 1].Kind <> gkSep) then
      begin
        ProcessEmail(C, GI);
        Exit;
      end;
  ProcessGroups(C, 0, C.M - 1);
end;

procedure TAnonEngine.ProcessGroups(C: TAnonCtx; G0, G1: Integer);
var
  GI, GJ, Used: Integer;
begin
  GI := G0;
  while GI <= G1 do
  begin
    if C.G[GI].Kind = gkSep then
    begin
      Inc(GI);
      Continue;
    end;
    if C.G[GI].Kind = gkDigits then
    begin
      Used := 0;
      if FOpt.Numbers then
      begin
        Used := TryCpfCnpj(C, GI);
        if Used = 0 then
          Used := TryIPv4(C, GI);
      end;
      if (Used = 0) and FOpt.Dates then
        Used := TryDate(C, GI);
      if Used > 0 then
      begin
        Inc(GI, Used);
        Continue;
      end;
    end;
    GJ := GI;
    while (GJ <= G1) and (C.G[GJ].Kind <> gkSep) do
      Inc(GJ);
    ProcessWord(C, C.G[GI].First, GroupEnd(C, GJ - 1));
    GI := GJ;
  end;
end;

procedure TAnonEngine.ProcessWord(C: TAnonCtx; A, B: Integer);
var
  K, Digits: Integer;
  HasD, HasL, HasRep: Boolean;
begin
  HasD := False;
  HasL := False;
  HasRep := False;
  Digits := 0;
  for K := A to B - 1 do
    if C.T[K].Cls = ccDigit then
    begin
      HasD := True;
      Inc(Digits);
    end
    else
    begin
      HasL := True;
      if C.T[K].Grp <> rgNone then HasRep := True;
    end;
  if HasD and (not HasL) then
  begin
    if FOpt.Numbers and (Digits >= FOpt.MinDigits) then
    begin
      C.Rng := SeedFor(C, A, B, 1);
      ReplaceDigitRange(C, A, B);
    end;
    Exit;
  end;
  if HasD and HasL then
  begin
    C.Rng := SeedFor(C, A, B, 2);
    if FOpt.Numbers and (Digits >= FOpt.MinDigits) then
      ReplaceDigitRange(C, A, B);
    if FOpt.Codes then
      ScrambleRange(C, A, B, True);
    Exit;
  end;
  if HasRep then
    ProcessLetterWord(C, A, B);
end;

procedure TAnonEngine.ReplaceDigitRange(C: TAnonCtx; A, B: Integer);
var
  K, Cnt, FirstNZ, Sum, D: Integer;
  Leading, Same, Dbl: Boolean;
begin
  Cnt := 0;
  for K := A to B - 1 do
    if C.T[K].Cls = ccDigit then
    begin
      C.Idx[Cnt] := K;
      C.OrigD[Cnt] := DigitVal(C.T[K]);
      Inc(Cnt);
    end;
  if Cnt = 0 then Exit;
  Leading := True;
  FirstNZ := -1;
  for K := 0 to Cnt - 1 do
  begin
    if Leading and (C.OrigD[K] = 0) and (K < Cnt - 1) then
      C.NewD[K] := 0
    else if Leading then
    begin
      C.NewD[K] := 1 + RandInt(C, 9);
      Leading := False;
      FirstNZ := K;
    end
    else
      C.NewD[K] := RandInt(C, 10);
  end;
  { 16 digitos iniciados por 3..6: numero de cartao - mantem o digito Luhn valido }
  if (Cnt = 16) and (C.OrigD[0] >= 3) and (C.OrigD[0] <= 6) then
  begin
    Sum := 0;
    Dbl := True;
    for K := Cnt - 2 downto 0 do
    begin
      D := C.NewD[K];
      if Dbl then
      begin
        D := D * 2;
        if D > 9 then Dec(D, 9);
      end;
      Inc(Sum, D);
      Dbl := not Dbl;
    end;
    C.NewD[Cnt - 1] := (10 - Sum mod 10) mod 10;
  end;
  Same := True;
  for K := 0 to Cnt - 1 do
    if C.NewD[K] <> C.OrigD[K] then
    begin
      Same := False;
      Break;
    end;
  if Same then
  begin
    K := Cnt - 1;
    if K = FirstNZ then
      C.NewD[K] := 1 + (C.NewD[K] mod 9)
    else
      C.NewD[K] := (C.NewD[K] + 1) mod 10;
  end;
  for K := 0 to Cnt - 1 do
    PutDigit(C, C.Idx[K], C.NewD[K]);
end;

procedure TAnonEngine.ScrambleRange(C: TAnonCtx; A, B: Integer; ALettersOnly: Boolean);
var
  K, Tries: Integer;
  Changed: Boolean;
begin
  Changed := False;
  for K := A to B - 1 do
  begin
    if C.T[K].Grp = rgNone then Continue;
    if ALettersOnly and (C.T[K].Cls = ccDigit) then Continue;
    if PutCP(C, K, PoolPick(C.T[K].Grp, NextRand(C))) then
      Changed := True;
  end;
  if Changed then Exit;
  for K := A to B - 1 do
  begin
    if C.T[K].Grp = rgNone then Continue;
    if ALettersOnly and (C.T[K].Cls = ccDigit) then Continue;
    for Tries := 1 to 8 do
      if PutCP(C, K, PoolPick(C.T[K].Grp, NextRand(C))) then
        Exit;
  end;
end;

type
  TAnonNameChars = array[0..15] of Cardinal;
  PAnonNameChars = ^TAnonNameChars;

function TAnonEngine.TryDictionary(C: TAnonCtx; A, B: Integer): Boolean;
var
  N, K, R: Integer;
  Sig, CP: Cardinal;
  L: TAnonNameList;
  Same: Boolean;
  Name: PAnonNameChars;
begin
  Result := False;
  N := B - A;
  if (N < 2) or (N > 16) then Exit;
  Sig := Cardinal(N) shl 16;
  for K := 0 to N - 1 do
  begin
    if IsLatin1Group(C.T[A + K].Grp) then
      Sig := Sig or (Cardinal(1) shl K)
    else if not IsAsciiLetterGroup(C.T[A + K].Grp) then
      Exit;
  end;
  if not GNameBuckets.TryGetValue(Sig, L) then Exit;
  R := RandInt(C, L.Count);
  Name := PAnonNameChars(@GNames[L[R]][0]);
  Same := True;
  for K := 0 to N - 1 do
    if Name^[K] <> FoldCP(C.T[A + K].CP) then
    begin
      Same := False;
      Break;
    end;
  if Same then
  begin
    if L.Count < 2 then Exit;
    Name := PAnonNameChars(@GNames[L[(R + 1) mod L.Count]][0]);
  end;
  for K := 0 to N - 1 do
  begin
    CP := Name^[K];
    if C.T[A + K].Cls = ccUpper then
      CP := UpperCP(CP);
    PutCP(C, A + K, CP);
  end;
  Result := True;
end;

procedure TAnonEngine.ProcessLetterWord(C: TAnonCtx; A, B: Integer);
var
  K, N: Integer;
  AllUpper: Boolean;
  H: UInt64;
begin
  if FOpt.TextMode = atmNone then Exit;
  N := B - A;
  if N < 2 then Exit;
  H := FoldHash(C, A, B);
  if IsKept(H) then Exit;
  if FOpt.TextMode = atmNames then
  begin
    if C.T[A].Cls <> ccUpper then Exit;
    AllUpper := True;
    for K := A + 1 to B - 1 do
      if C.T[K].Cls = ccLower then
      begin
        AllUpper := False;
        Break;
      end;
    if AllUpper and (not FOpt.AllCapsAsNames) then Exit;
    { inicio de frase: maiuscula nao indica nome proprio }
    if C.SentenceStart and (not IsKnownName(H)) then Exit;
  end;
  C.Rng := SeedFor(C, A, B, 3);
  if not TryDictionary(C, A, B) then
    ScrambleRange(C, A, B, True);
end;

procedure TAnonEngine.ProcessEmail(C: TAnonCtx; AAt: Integer);
const
  MAX_LABELS = 64;
var
  LS, DS, DE, GI, LC, KeepFrom, Li: Integer;
  LabelStart, LabelEnd: array[0..MAX_LABELS - 1] of Integer;
begin
  LS := AAt - 1;
  while (LS > 0) and not ((C.G[LS - 1].Kind = gkSep) and
    (C.G[LS - 1].SepCP <> Ord('.')) and (C.G[LS - 1].SepCP <> Ord('_')) and
    (C.G[LS - 1].SepCP <> Ord('-')) and (C.G[LS - 1].SepCP <> Ord('+'))) do
    Dec(LS);
  if LS > 0 then
    ProcessGroups(C, 0, LS - 1);

  C.Rng := SeedFor(C, C.G[LS].First, C.G[AAt].First, 4);
  ScrambleRange(C, C.G[LS].First, C.G[AAt].First, False);

  DS := AAt + 1;
  DE := DS;
  while (DE < C.M) and ((C.G[DE].Kind <> gkSep) or (C.G[DE].SepCP = Ord('.')) or
    (C.G[DE].SepCP = Ord('-'))) do
    Inc(DE);
  while (DE > DS) and (C.G[DE - 1].Kind = gkSep) do
    Dec(DE);

  LC := 0;
  GI := DS;
  while (GI < DE) and (LC < MAX_LABELS) do
  begin
    LabelStart[LC] := GI;
    while (GI < DE) and not ((C.G[GI].Kind = gkSep) and (C.G[GI].SepCP = Ord('.'))) do
      Inc(GI);
    LabelEnd[LC] := GI;
    Inc(LC);
    Inc(GI);
  end;
  if LC > 0 then
  begin
    KeepFrom := LC - 1;
    if LC >= 3 then
    begin
      if (C.G[LabelStart[LC - 1]].Count = 2) and (LabelEnd[LC - 1] - LabelStart[LC - 1] = 1) and
         InSortedHashes(GSecondLevelHashes,
           FoldHash(C, C.G[LabelStart[LC - 2]].First, GroupEnd(C, LabelEnd[LC - 2] - 1))) then
        KeepFrom := LC - 2;
    end;
    if (KeepFrom >= 1) and InSortedHashes(GPublicMailHashes,
      FoldHash(C, C.G[LabelStart[KeepFrom - 1]].First, GroupEnd(C, LabelEnd[KeepFrom - 1] - 1))) then
      KeepFrom := 0;
    for Li := 0 to KeepFrom - 1 do
    begin
      C.Rng := SeedFor(C, C.G[LabelStart[Li]].First, GroupEnd(C, LabelEnd[Li] - 1), 5);
      ScrambleRange(C, C.G[LabelStart[Li]].First, GroupEnd(C, LabelEnd[Li] - 1), False);
    end;
  end;
  if DE < C.M then
    ProcessGroups(C, DE, C.M - 1);
end;

function TAnonEngine.TryTime(C: TAnonCtx; GI: Integer): Integer;
var
  WH, VH, NH, Used, K: Integer;
  HasSec: Boolean;
begin
  Result := 0;
  if not ((GI + 2 < C.M) and (C.G[GI].Kind = gkDigits) and (C.G[GI + 1].Kind = gkSep) and
    (C.G[GI + 1].SepCP = Ord(':')) and (C.G[GI + 2].Kind = gkDigits)) then Exit;
  WH := C.G[GI].Count;
  if WH > 2 then Exit;
  VH := GroupValue(C, GI);
  if (VH > 24) or (C.G[GI + 2].Count <> 2) or (GroupValue(C, GI + 2) > 59) then Exit;
  Used := 3;
  HasSec := False;
  if (GI + 4 < C.M) and (C.G[GI + 3].Kind = gkSep) and (C.G[GI + 3].SepCP = Ord(':')) and
     (C.G[GI + 4].Kind = gkDigits) and (C.G[GI + 4].Count = 2) and (GroupValue(C, GI + 4) <= 60) then
  begin
    Used := 5;
    HasSec := True;
  end;
  if HasSec and (GI + 6 < C.M) and (C.G[GI + 5].Kind = gkSep) and
     ((C.G[GI + 5].SepCP = Ord('.')) or (C.G[GI + 5].SepCP = Ord(','))) and
     (C.G[GI + 6].Kind = gkDigits) then
    Used := 7;
  if GluedAfter(C, GI + Used) then
  begin
    if (C.G[GI + Used].Kind = gkLetters) and (C.G[GI + Used].Count <= 2) then
      Inc(Used)
    else
      Exit;
  end;
  C.Rng := SeedFor(C, C.G[GI].First, GroupEnd(C, GI + Used - 1), 6);
  if WH = 1 then
  begin
    if VH = 0 then NH := RandInt(C, 10) else NH := 1 + RandInt(C, 9);
  end
  else if (VH >= 1) and (VH <= 12) then
    NH := 1 + RandInt(C, 12)
  else
    NH := RandInt(C, 24);
  WriteNumber(C, GI, NH, WH);
  WriteNumber(C, GI + 2, RandInt(C, 60), 2);
  if HasSec then
    WriteNumber(C, GI + 4, RandInt(C, 60), 2);
  if Used >= 7 then
    for K := C.G[GI + 6].First to GroupEnd(C, GI + 6) - 1 do
      PutDigit(C, K, RandInt(C, 10));
  Result := Used;
end;

function TAnonEngine.TryDate(C: TAnonCtx; GI: Integer): Integer;
var
  Sep: Cardinal;
  W0, W2, W4, V0, V2, Y, Mo, D, Y4, GY, GM, GD, WY, WM, WD, Off, TU, K: Integer;
  Ambig, PadM, PadD: Boolean;
  NY, NM, ND: Word;
  Nw: TDateTime;
begin
  Result := 0;
  if not ((GI + 4 < C.M) and (C.G[GI].Kind = gkDigits) and (C.G[GI + 1].Kind = gkSep) and
    (C.G[GI + 2].Kind = gkDigits) and (C.G[GI + 3].Kind = gkSep) and (C.G[GI + 4].Kind = gkDigits)) then
  begin
    Result := TryTime(C, GI);
    Exit;
  end;
  Sep := C.G[GI + 1].SepCP;
  if not ((Sep = Ord('-')) or (Sep = Ord('/')) or (Sep = Ord('.'))) or (C.G[GI + 3].SepCP <> Sep) then
  begin
    Result := TryTime(C, GI);
    Exit;
  end;
  W0 := C.G[GI].Count;
  W2 := C.G[GI + 2].Count;
  W4 := C.G[GI + 4].Count;
  V0 := GroupValue(C, GI);
  V2 := GroupValue(C, GI + 2);
  Ambig := False;
  if (W0 = 4) and (W2 <= 2) and (W4 <= 2) then
  begin
    GY := GI;
    GM := GI + 2;
    GD := GI + 4;
  end
  else if (W0 <= 2) and (W2 <= 2) and ((W4 = 2) or (W4 = 4)) then
  begin
    GY := GI + 4;
    if (V0 > 12) and (V2 <= 12) then
    begin
      GD := GI;
      GM := GI + 2;
    end
    else if (V2 > 12) and (V0 <= 12) then
    begin
      GM := GI;
      GD := GI + 2;
    end
    else if (V0 <= 12) and (V2 <= 12) then
    begin
      GD := GI;
      GM := GI + 2;
      Ambig := True;
    end
    else
      Exit;
  end
  else
    Exit;
  Y := GroupValue(C, GY);
  Mo := GroupValue(C, GM);
  D := GroupValue(C, GD);
  WY := C.G[GY].Count;
  WM := C.G[GM].Count;
  WD := C.G[GD].Count;
  if WY = 2 then
  begin
    if Y >= 70 then Y4 := 1900 + Y else Y4 := 2000 + Y;
  end
  else
    Y4 := Y;
  if (Mo < 1) or (Mo > 12) or (D < 1) or (Y4 < 1000) or (D > DaysInAMonth(Y4, Mo)) then Exit;

  TU := -1;
  if GluedAfter(C, GI + 5) then
  begin
    if (C.G[GI + 5].Kind = gkLetters) and (C.G[GI + 5].Count = 1) and
       ((C.T[C.G[GI + 5].First].CP = Ord('T')) or (C.T[C.G[GI + 5].First].CP = Ord('t'))) and
       (GI + 6 < C.M) and (C.G[GI + 6].Kind = gkDigits) then
      TU := GI + 6
    else
      Exit;
  end;

  C.Rng := SeedFor(C, C.G[GI].First, GroupEnd(C, GI + 4), 7);
  Off := 1 + RandInt(C, 1460);
  if RandInt(C, 2) = 0 then Off := -Off;
  Nw := EncodeDate(Y4, Mo, D) + Off;
  DecodeDate(Nw, NY, NM, ND);
  if NY < 1000 then NY := 1000;
  if NY > 9999 then NY := 9999;
  PadM := (WM = 2) and (DigitVal(C.T[C.G[GM].First]) = 0);
  PadD := (WD = 2) and (DigitVal(C.T[C.G[GD].First]) = 0);
  if WM = 1 then
  begin
    if NM > 9 then Dec(NM, 9);
  end
  else if (not PadM) and (NM < 10) then
    NM := 10 + (NM mod 3);
  if Ambig and (ND > 12) then
    ND := 1 + (ND mod 12);
  if WD = 1 then
  begin
    if ND > 9 then ND := 1 + (ND mod 9);
  end
  else if (not PadD) and (ND < 10) then
  begin
    Inc(ND, 10);
    if Ambig and (ND > 12) then ND := 10 + (ND mod 3);
  end;
  if ND > DaysInAMonth(NY, NM) then
    ND := DaysInAMonth(NY, NM);
  if WY = 2 then
    WriteNumber(C, GY, NY mod 100, 2)
  else
    WriteNumber(C, GY, NY, WY);
  WriteNumber(C, GM, NM, WM);
  WriteNumber(C, GD, ND, WD);
  Result := 5;
  if TU >= 0 then
  begin
    K := TryTime(C, TU);
    if K > 0 then
      Result := TU - GI + K;
  end;
end;

function TAnonEngine.TryIPv4(C: TAnonCtx; GI: Integer): Integer;
var
  K, W, G: Integer;
begin
  Result := 0;
  if GI + 6 >= C.M then Exit;
  for K := 0 to 3 do
  begin
    G := GI + K * 2;
    if (C.G[G].Kind <> gkDigits) or (C.G[G].Count > 3) or (GroupValue(C, G) > 255) then Exit;
    if (K < 3) and ((C.G[G + 1].Kind <> gkSep) or (C.G[G + 1].SepCP <> Ord('.'))) then Exit;
  end;
  if GluedAfter(C, GI + 7) then Exit;
  if (GI + 8 < C.M) and (C.G[GI + 7].SepCP = Ord('.')) and (C.G[GI + 8].Kind = gkDigits) then Exit;
  C.Rng := SeedFor(C, C.G[GI].First, GroupEnd(C, GI + 6), 8);
  for K := 0 to 3 do
  begin
    G := GI + K * 2;
    W := C.G[G].Count;
    case W of
      1: WriteNumber(C, G, RandInt(C, 10), 1);
      2: WriteNumber(C, G, 10 + RandInt(C, 90), 2);
    else
      WriteNumber(C, G, 100 + RandInt(C, 156), 3);
    end;
  end;
  Result := 7;
end;

function TAnonEngine.TryCpfCnpj(C: TAnonCtx; GI: Integer): Integer;
const
  CPF_W: array[0..4] of Integer = (3, 3, 3, 2, 0);
  CPF_S: array[0..3] of Char = ('.', '.', '-', #0);
  CNPJ_W: array[0..5] of Integer = (2, 3, 3, 4, 2, 0);
  CNPJ_S: array[0..4] of Char = ('.', '.', '/', '-', #0);
  CNPJ_W1: array[0..11] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  CNPJ_W2: array[0..12] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);

  function Match(const AW: array of Integer; const AS_: array of Char; AGroups: Integer): Boolean;
  var
    K: Integer;
  begin
    Result := False;
    if GI + AGroups * 2 - 2 >= C.M then Exit;
    for K := 0 to AGroups - 1 do
    begin
      if (C.G[GI + K * 2].Kind <> gkDigits) or (C.G[GI + K * 2].Count <> AW[K]) then Exit;
      if (K < AGroups - 1) and ((C.G[GI + K * 2 + 1].Kind <> gkSep) or
        (C.G[GI + K * 2 + 1].SepCP <> Ord(AS_[K]))) then Exit;
    end;
    Result := not GluedAfter(C, GI + AGroups * 2 - 1);
  end;

  function Dv(ASum: Integer): Integer;
  begin
    Result := ASum mod 11;
    if Result < 2 then Result := 0 else Result := 11 - Result;
  end;

var
  Dg: array[0..13] of Integer;
  K, N, Sum, P, G: Integer;
begin
  Result := 0;
  if Match(CPF_W, CPF_S, 4) then
  begin
    C.Rng := SeedFor(C, C.G[GI].First, GroupEnd(C, GI + 6), 9);
    for K := 0 to 8 do
      Dg[K] := RandInt(C, 10);
    Sum := 0;
    for K := 0 to 8 do Inc(Sum, Dg[K] * (10 - K));
    Dg[9] := Dv(Sum);
    Sum := 0;
    for K := 0 to 9 do Inc(Sum, Dg[K] * (11 - K));
    Dg[10] := Dv(Sum);
    N := 11;
    Result := 7;
  end
  else if Match(CNPJ_W, CNPJ_S, 5) then
  begin
    C.Rng := SeedFor(C, C.G[GI].First, GroupEnd(C, GI + 8), 10);
    for K := 0 to 11 do
      Dg[K] := RandInt(C, 10);
    Sum := 0;
    for K := 0 to 11 do Inc(Sum, Dg[K] * CNPJ_W1[K]);
    Dg[12] := Dv(Sum);
    Sum := 0;
    for K := 0 to 12 do Inc(Sum, Dg[K] * CNPJ_W2[K]);
    Dg[13] := Dv(Sum);
    N := 14;
    Result := 9;
  end
  else
    Exit;
  P := 0;
  G := GI;
  while (P < N) and (G < GI + Result) do
  begin
    if C.G[G].Kind = gkDigits then
      for K := C.G[G].First to GroupEnd(C, G) - 1 do
      begin
        PutDigit(C, K, Dg[P]);
        Inc(P);
      end;
    Inc(G);
  end;
end;

function TAnonEngine.UnitAt(P: PByte; I: Integer): Cardinal;
begin
  case FKind of
    aekUtf16LE: Result := P[I] or (Cardinal(P[I + 1]) shl 8);
    aekUtf16BE: Result := (Cardinal(P[I]) shl 8) or P[I + 1];
    aekUtf32LE: Result := P[I] or (Cardinal(P[I + 1]) shl 8) or (Cardinal(P[I + 2]) shl 16) or
      (Cardinal(P[I + 3]) shl 24);
    aekUtf32BE: Result := (Cardinal(P[I]) shl 24) or (Cardinal(P[I + 1]) shl 16) or
      (Cardinal(P[I + 2]) shl 8) or P[I + 3];
  else
    Result := P[I];
  end;
end;

function TAnonEngine.FindCut(P: PByte; Len: Integer): Integer;
var
  I, Lim: Integer;
  B: Byte;
  U: Cardinal;
begin
  I := (Len div FUnit) * FUnit - FUnit;
  while I >= 0 do
  begin
    U := UnitAt(P, I);
    if (U = 10) or (U = 13) then
    begin
      Result := I + FUnit;
      Exit;
    end;
    Dec(I, FUnit);
  end;
  { linha maior que a janela: corta numa fronteira segura de caractere }
  case FKind of
    aekBytes, aekDbcs:
      begin
        Lim := Max(0, Len - 65536);
        I := Len - 1;
        while I >= Lim do
        begin
          B := P[I];
          if (B < $40) and not ((B >= Ord('0')) and (B <= Ord('9'))) then
          begin
            Result := I + 1;
            Exit;
          end;
          Dec(I);
        end;
        I := Len - 1;
        while (I > 0) and (Len - I < 8) and ((P[I] and $C0) = $80) do
          Dec(I);
        Result := I;
      end;
    aekUtf16LE, aekUtf16BE:
      begin
        Result := Len and not 1;
        if Result >= 2 then
        begin
          U := UnitAt(P, Result - 2);
          if (U >= $D800) and (U <= $DBFF) then Dec(Result, 2);
        end;
      end;
  else
    Result := Len and not 3;
  end;
  if Result <= 0 then
    Result := (Len div FUnit) * FUnit;
end;

function TAnonEngine.NextLineStart(P: PByte; AFrom, Len: Integer): Integer;
var
  I: Integer;
  U: Cardinal;
begin
  I := ((AFrom + FUnit - 1) div FUnit) * FUnit;
  while I + FUnit <= Len do
  begin
    U := UnitAt(P, I);
    if (U = 10) or (U = 13) then
    begin
      Result := I + FUnit;
      Exit;
    end;
    Inc(I, FUnit);
  end;
  Result := Len;
end;

function AnonPreviewBytes(AEngine: TAnonEngine; const ARaw: AnsiString;
  AAbsOffset: Int64; out AChanged: Boolean): AnsiString;
var
  C: TAnonCtx;
  Skip, Len: Integer;
begin
  Result := ARaw;
  AChanged := False;
  if (AEngine = nil) or (ARaw = '') then Exit;
  UniqueString(Result);
  Skip := 0;
  if AEngine.UnitSize > 1 then
    Skip := Integer((AEngine.UnitSize - (AAbsOffset mod AEngine.UnitSize)) mod AEngine.UnitSize);
  Len := ((Length(ARaw) - Skip) div AEngine.UnitSize) * AEngine.UnitSize;
  if Len <= 0 then Exit;
  C := TAnonCtx.Create;
  try
    AEngine.ProcessSpan(C, PByte(PAnsiChar(ARaw)) + Skip, PByte(PAnsiChar(Result)) + Skip, Len,
      AAbsOffset + Skip);
  finally
    C.Free;
  end;
  AChanged := Result <> ARaw;
end;

{ ---------------------------------------------------------------------------- }
{ Jornal                                                                       }
{ ---------------------------------------------------------------------------- }

type
  EAnonCancelled = class(Exception);
  EAnonMismatch = class(Exception);

  TAnonJournalWriter = class
  private
    FStream: TFileStream;
    FBuf: array of Byte;
    FLen: Integer;
    FRuns: Int64;
    FFileSize: Int64;
  public
    constructor Create(const APath: string; AFileSize: Int64);
    destructor Destroy; override;
    procedure AddRun(AOffset: Int64; AData: PByte; ALen: Integer; ANewHash: Cardinal);
    procedure Flush;
    procedure Finish;
    property Stream: TFileStream read FStream;
  end;

  TAnonRunRec = record
    BufOff: Integer;
    FileOff: Int64;
    Len: Integer;
    Hash: Cardinal;
  end;

  TAnonRunner = class
  private
    FProgress: TAnonProgressEvent;
    FCancel: TAnonCancelQuery;
    FEngine: TAnonEngine;
    FFile: TFileStream;
    FJ: TAnonJournalWriter;
    FIn, FOut: PByte;
    FCtxs: array of TAnonCtx;
    FRanges: TAnonRanges;
    FResult: TAnonJobResult;
    FDone, FTotal: Int64;
    FPhase: Integer;
    FLastTick: Cardinal;
    FCommitted: Int64;
    FSwapStop: Int64;
    procedure Report(AForce: Boolean);
    procedure CheckCancel;
    procedure ReadExact(APos: Int64; ABuf: PByte; ALen: Integer);
    procedure NormalizeRanges(AFileSize: Int64; ASkipHeader: Boolean);
    function FirstLineEnd(AFrom, AFileSize: Int64): Int64;
    procedure CommitWindow(ABase: Int64; ALen: Integer);
    procedure ProcessParallel(ABase: Int64; ALen: Integer);
    procedure DoSpan(AFirst, ALast: Integer);
    procedure DoLargeRange(const R: TAnonRange);
    function SwapJournal(J, F: TFileStream; AFrom, ATo: Int64): Boolean;
  public
    function Apply(const ATarget, AJournal: string; const AOptions: TAnonOptions;
      const AEncoding: string; const ARanges: TAnonRanges): TAnonJobResult;
    function Swap(AKind: TAnonJobKind; const ATarget, AJournal: string): TAnonJobResult;
  end;

constructor TAnonJournalWriter.Create(const APath: string; AFileSize: Int64);
var
  H: array[0..ANON_JOURNAL_HEADER - 1] of Byte;
begin
  inherited Create;
  FFileSize := AFileSize;
  FStream := TFileStream.Create(APath, fmCreate or fmShareExclusive);
  SetLength(FBuf, ANON_JOURNAL_BUF);
  FillChar(H, SizeOf(H), 0);
  Move(PAnsiChar(ANON_JOURNAL_MAGIC)^, H[0], 8);
  Move(AFileSize, H[8], 8);
  FStream.WriteBuffer(H, SizeOf(H));
end;

destructor TAnonJournalWriter.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TAnonJournalWriter.Flush;
begin
  if FLen > 0 then
  begin
    FStream.Position := FStream.Size;
    FStream.WriteBuffer(FBuf[0], FLen);
    FLen := 0;
  end;
end;

procedure TAnonJournalWriter.AddRun(AOffset: Int64; AData: PByte; ALen: Integer; ANewHash: Cardinal);
var
  Need: Integer;
begin
  Need := ANON_RUN_HEADER + ALen;
  if FLen + Need > Length(FBuf) then
    Flush;
  if Need > Length(FBuf) then
    SetLength(FBuf, Need);
  Move(AOffset, FBuf[FLen], 8);
  Move(ALen, FBuf[FLen + 8], 4);
  Move(ANewHash, FBuf[FLen + 12], 4);
  Move(AData^, FBuf[FLen + ANON_RUN_HEADER], ALen);
  Inc(FLen, Need);
  Inc(FRuns);
end;

procedure TAnonJournalWriter.Finish;
var
  Flags: Integer;
begin
  Flush;
  FStream.Position := 16;
  FStream.WriteBuffer(FRuns, 8);
  Flags := 1;
  FStream.WriteBuffer(Flags, 4);
  FlushFileBuffers(FStream.Handle);
end;

{ ---------------------------------------------------------------------------- }
{ TAnonRunner                                                                  }
{ ---------------------------------------------------------------------------- }

procedure TAnonRunner.Report(AForce: Boolean);
var
  Now_: Cardinal;
begin
  if not Assigned(FProgress) then Exit;
  Now_ := GetTickCount;
  if (not AForce) and (Now_ - FLastTick < 150) then Exit;
  FLastTick := Now_;
  FProgress(FDone, FTotal, FPhase);
end;

procedure TAnonRunner.CheckCancel;
begin
  if Assigned(FCancel) and FCancel() then
    raise EAnonCancelled.Create('cancelled');
end;

procedure TAnonRunner.ReadExact(APos: Int64; ABuf: PByte; ALen: Integer);
begin
  FFile.Position := APos;
  if FFile.Read(ABuf^, ALen) <> ALen then
    raise EInOutError.CreateFmt('Read error at offset %d', [APos]);
end;

function TAnonRunner.FirstLineEnd(AFrom, AFileSize: Int64): Int64;
var
  Buf: array of Byte;
  Pos_: Int64;
  N, I, U: Integer;
begin
  U := FEngine.UnitSize;
  SetLength(Buf, 65536);
  Pos_ := AFrom;
  while Pos_ < AFileSize do
  begin
    FFile.Position := Pos_;
    N := FFile.Read(Buf[0], Length(Buf));
    if N <= 0 then Break;
    I := 0;
    while I + U <= N do
    begin
      case FEngine.UnitAt(@Buf[0], I) of
        10:
          begin
            Result := Pos_ + I + U;
            Exit;
          end;
        13:
          begin
            if (I + 2 * U <= N) and (FEngine.UnitAt(@Buf[0], I + U) = 10) then
              Result := Pos_ + I + 2 * U
            else
              Result := Pos_ + I + U;
            Exit;
          end;
      end;
      Inc(I, U);
    end;
    Inc(Pos_, N);
  end;
  Result := AFileSize;
end;

procedure TAnonRunner.NormalizeRanges(AFileSize: Int64; ASkipHeader: Boolean);
var
  Bom: array[0..3] of Byte;
  N, I, K, U: Integer;
  MinStart, S, E: Int64;
  Tmp: TAnonRange;
  Outp: TAnonRanges;
begin
  FillChar(Bom, SizeOf(Bom), 0);
  FFile.Position := 0;
  N := FFile.Read(Bom, 4);
  MinStart := 0;
  if (N >= 4) and (Bom[0] = $FF) and (Bom[1] = $FE) and (Bom[2] = 0) and (Bom[3] = 0) then MinStart := 4
  else if (N >= 4) and (Bom[0] = 0) and (Bom[1] = 0) and (Bom[2] = $FE) and (Bom[3] = $FF) then MinStart := 4
  else if (N >= 3) and (Bom[0] = $EF) and (Bom[1] = $BB) and (Bom[2] = $BF) then MinStart := 3
  else if (N >= 2) and (((Bom[0] = $FF) and (Bom[1] = $FE)) or ((Bom[0] = $FE) and (Bom[1] = $FF))) then MinStart := 2;
  U := FEngine.UnitSize;
  MinStart := ((MinStart + U - 1) div U) * U;
  if ASkipHeader then
    MinStart := Max(MinStart, FirstLineEnd(MinStart, AFileSize));

  { ordena por inicio (insercao: a selecao ja vem quase sempre ordenada) }
  for I := 1 to High(FRanges) do
  begin
    Tmp := FRanges[I];
    K := I - 1;
    while (K >= 0) and (FRanges[K].Start > Tmp.Start) do
    begin
      FRanges[K + 1] := FRanges[K];
      Dec(K);
    end;
    FRanges[K + 1] := Tmp;
  end;

  SetLength(Outp, Length(FRanges));
  N := 0;
  for I := 0 to High(FRanges) do
  begin
    S := Max(FRanges[I].Start, MinStart);
    E := Min(FRanges[I].Start + FRanges[I].Len, AFileSize);
    S := ((S + U - 1) div U) * U;
    E := (E div U) * U;
    if E <= S then Continue;
    if (N > 0) and (S <= Outp[N - 1].Start + Outp[N - 1].Len) then
    begin
      if E > Outp[N - 1].Start + Outp[N - 1].Len then
        Outp[N - 1].Len := E - Outp[N - 1].Start;
      Continue;
    end;
    Outp[N].Start := S;
    Outp[N].Len := E - S;
    Inc(N);
  end;
  SetLength(Outp, N);
  FRanges := Outp;
end;

procedure TAnonRunner.CommitWindow(ABase: Int64; ALen: Integer);
var
  I, K, RunStart, RunEnd, FirstDiff, LastDiff: Integer;
  JEnd: Int64;
begin
  FirstDiff := -1;
  LastDiff := -1;
  I := 0;
  while I < ALen do
  begin
    while (I + 8 <= ALen) and (PUInt64(FIn + I)^ = PUInt64(FOut + I)^) do
      Inc(I, 8);
    while (I < ALen) and (FIn[I] = FOut[I]) do
      Inc(I);
    if I >= ALen then Break;
    RunStart := I;
    RunEnd := I + 1;
    Inc(FResult.BytesChanged);
    K := I + 1;
    while (K < ALen) and (K - RunStart < ANON_MAX_RUN) do
    begin
      if FIn[K] <> FOut[K] then
      begin
        RunEnd := K + 1;
        Inc(FResult.BytesChanged);
      end
      else if K - RunEnd >= ANON_RUN_GAP then
        Break;
      Inc(K);
    end;
    if Assigned(FJ) then
      FJ.AddRun(ABase + RunStart, FIn + RunStart, RunEnd - RunStart,
        Fnv32(FOut + RunStart, RunEnd - RunStart));
    Inc(FResult.RunCount);
    if FirstDiff < 0 then FirstDiff := RunStart;
    LastDiff := RunEnd;
    I := RunEnd;
  end;
  if FirstDiff < 0 then Exit;
  JEnd := 0;
  if Assigned(FJ) then
  begin
    FJ.Flush;
    JEnd := FJ.Stream.Size;
  end;
  FFile.Position := ABase + FirstDiff;
  FFile.WriteBuffer((FOut + FirstDiff)^, LastDiff - FirstDiff);
  if Assigned(FJ) then
    FCommitted := JEnd;
end;

procedure TAnonRunner.ProcessParallel(ABase: Int64; ALen: Integer);
var
  Starts: TArray<Integer>;
  Cnt, P, B: Integer;
  Work: TProc<Integer>;
begin
  if (Length(FCtxs) <= 1) or (ALen < ANON_PARALLEL_MIN) then
  begin
    FEngine.ProcessSpan(FCtxs[0], FIn, FOut, ALen, ABase);
    Exit;
  end;
  SetLength(Starts, Length(FCtxs) + 1);
  Starts[0] := 0;
  Cnt := 1;
  for P := 1 to High(FCtxs) do
  begin
    B := FEngine.NextLineStart(FIn, Integer(Int64(ALen) * P div Length(FCtxs)), ALen);
    if (B > Starts[Cnt - 1]) and (B < ALen) then
    begin
      Starts[Cnt] := B;
      Inc(Cnt);
    end;
  end;
  Starts[Cnt] := ALen;
  if Cnt = 1 then
  begin
    FEngine.ProcessSpan(FCtxs[0], FIn, FOut, ALen, ABase);
    Exit;
  end;
  Work :=
    procedure(AIdx: Integer)
    begin
      FEngine.ProcessSpan(FCtxs[AIdx], FIn + Starts[AIdx], FOut + Starts[AIdx],
        Starts[AIdx + 1] - Starts[AIdx], ABase + Starts[AIdx]);
    end;
  TParallel.For(0, Cnt - 1, Work);
end;

procedure TAnonRunner.DoSpan(AFirst, ALast: Integer);
var
  SpanStart, SpanEnd: Int64;
  K, Len: Integer;
begin
  SpanStart := FRanges[AFirst].Start;
  SpanEnd := FRanges[ALast].Start + FRanges[ALast].Len;
  Len := Integer(SpanEnd - SpanStart);
  ReadExact(SpanStart, FIn, Len);
  Move(FIn^, FOut^, Len);
  for K := AFirst to ALast do
  begin
    FEngine.ProcessSpan(FCtxs[0], FIn + (FRanges[K].Start - SpanStart),
      FOut + (FRanges[K].Start - SpanStart), Integer(FRanges[K].Len), FRanges[K].Start);
    Inc(FDone, FRanges[K].Len);
  end;
  CommitWindow(SpanStart, Len);
  Report(False);
end;

procedure TAnonRunner.DoLargeRange(const R: TAnonRange);
var
  Pos_, EndPos: Int64;
  Want, Cut: Integer;
begin
  Pos_ := R.Start;
  EndPos := R.Start + R.Len;
  while Pos_ < EndPos do
  begin
    CheckCancel;
    Want := Integer(Min(Int64(ANON_WINDOW), EndPos - Pos_));
    ReadExact(Pos_, FIn, Want);
    if Pos_ + Want < EndPos then
      Cut := FEngine.FindCut(FIn, Want)
    else
      Cut := Want;
    if Cut <= 0 then Cut := Want;
    Move(FIn^, FOut^, Cut);
    ProcessParallel(Pos_, Cut);
    CommitWindow(Pos_, Cut);
    Inc(Pos_, Cut);
    Inc(FDone, Cut);
    Report(False);
  end;
end;

function TAnonRunner.Apply(const ATarget, AJournal: string; const AOptions: TAnonOptions;
  const AEncoding: string; const ARanges: TAnonRanges): TAnonJobResult;
var
  I, J, P: Integer;
  SpanStart, SpanEnd, FileSize: Int64;
begin
  FillChar(FResult, SizeOf(FResult), 0);
  FResult.Kind := ajkApply;
  FResult.JournalPath := AJournal;
  FPhase := 0;
  FEngine := TAnonEngine.Create(AOptions, AEncoding);
  FFile := nil;
  FJ := nil;
  FIn := nil;
  FOut := nil;
  try
    try
      FFile := TFileStream.Create(ATarget, fmOpenReadWrite or fmShareDenyNone);
      FileSize := FFile.Size;
      if Length(ARanges) = 0 then
      begin
        SetLength(FRanges, 1);
        FRanges[0].Start := 0;
        FRanges[0].Len := FileSize;
      end
      else
        FRanges := Copy(ARanges);
      NormalizeRanges(FileSize, AOptions.SkipHeader);
      FTotal := 0;
      for I := 0 to High(FRanges) do
        Inc(FTotal, FRanges[I].Len);
      FResult.BytesScanned := FTotal;
      if AJournal <> '' then
        FJ := TAnonJournalWriter.Create(AJournal, FileSize);
      FCommitted := ANON_JOURNAL_HEADER;
      GetMem(FIn, ANON_WINDOW);
      GetMem(FOut, ANON_WINDOW);
      P := Max(1, Min(TThread.ProcessorCount, ANON_MAX_PARTS));
      SetLength(FCtxs, P);
      for I := 0 to P - 1 do
        FCtxs[I] := TAnonCtx.Create;
      Report(True);
      try
        I := 0;
        while I < Length(FRanges) do
        begin
          CheckCancel;
          if FRanges[I].Len > ANON_WINDOW then
          begin
            DoLargeRange(FRanges[I]);
            Inc(I);
            Continue;
          end;
          J := I;
          SpanStart := FRanges[I].Start;
          SpanEnd := FRanges[I].Start + FRanges[I].Len;
          while (J + 1 < Length(FRanges)) and (FRanges[J + 1].Len <= ANON_WINDOW) and
            (FRanges[J + 1].Start + FRanges[J + 1].Len - SpanStart <= ANON_WINDOW) and
            (FRanges[J + 1].Start - SpanEnd <= ANON_SPAN_GAP) do
          begin
            Inc(J);
            SpanEnd := FRanges[J].Start + FRanges[J].Len;
          end;
          DoSpan(I, J);
          I := J + 1;
        end;
        if Assigned(FJ) then
          FJ.Finish;
        FlushFileBuffers(FFile.Handle);
        FResult.Success := True;
        Report(True);
      except
        on E: Exception do
        begin
          FResult.Cancelled := E is EAnonCancelled;
          if not FResult.Cancelled then
            FResult.ErrorMsg := E.Message;
          if Assigned(FJ) then
          begin
            FPhase := 1;
            FDone := 0;
            FTotal := FCommitted - ANON_JOURNAL_HEADER;
            Report(True);
            try
              FJ.Flush;
            except
            end;
            FResult.RolledBack := (FCommitted <= ANON_JOURNAL_HEADER) or
              SwapJournal(FJ.Stream, FFile, ANON_JOURNAL_HEADER, FCommitted);
            FlushFileBuffers(FFile.Handle);
          end;
        end;
      end;
      for I := 0 to High(FCtxs) do
        Inc(FResult.LinesChanged, FCtxs[I].LinesChanged);
    except
      on E: Exception do
      begin
        FResult.Success := False;
        if FResult.ErrorMsg = '' then
          FResult.ErrorMsg := E.Message;
      end;
    end;
  finally
    for I := 0 to High(FCtxs) do
      FCtxs[I].Free;
    SetLength(FCtxs, 0);
    if Assigned(FIn) then FreeMem(FIn);
    if Assigned(FOut) then FreeMem(FOut);
    FJ.Free;
    FFile.Free;
    FEngine.Free;
  end;
  if (not FResult.Success) and (AJournal <> '') then
    AnonDeleteJournal(AJournal);
  Result := FResult;
end;

function TAnonRunner.SwapJournal(J, F: TFileStream; AFrom, ATo: Int64): Boolean;
var
  Buf, Win: array of Byte;
  Recs: array of TAnonRunRec;
  Pos_: Int64;
  Want, Got, P, NRec, R, GStart, K, Q, Off, Len, RegionStart, RegionLen: Integer;
  SpanStart, SpanEnd, FileSz: Int64;
  NewHash: Cardinal;
  Tmp: Byte;
begin
  Result := False;
  FSwapStop := AFrom;
  FileSz := F.Size;
  SetLength(Buf, ANON_SWAP_CHUNK);
  SetLength(Win, ANON_WINDOW);
  Pos_ := AFrom;
  while Pos_ < ATo do
  begin
    Want := Integer(Min(Int64(Length(Buf)), ATo - Pos_));
    J.Position := Pos_;
    Got := J.Read(Buf[0], Want);
    if Got < ANON_RUN_HEADER then
      raise EInOutError.Create('Undo data is damaged.');
    P := 0;
    NRec := 0;
    while P + ANON_RUN_HEADER <= Got do
    begin
      Move(Buf[P + 8], Len, 4);
      if (Len <= 0) or (Len > ANON_MAX_RUN) then
        raise EInOutError.Create('Undo data is damaged.');
      if P + ANON_RUN_HEADER + Len > Got then Break;
      if NRec >= Length(Recs) then
        SetLength(Recs, NRec * 2 + 1024);
      Recs[NRec].BufOff := P;
      Move(Buf[P], Recs[NRec].FileOff, 8);
      Recs[NRec].Len := Len;
      Move(Buf[P + 12], Recs[NRec].Hash, 4);
      if (Recs[NRec].FileOff < 0) or (Recs[NRec].FileOff + Len > FileSz) then
        raise EInOutError.Create('Undo data is damaged.');
      Inc(NRec);
      Inc(P, ANON_RUN_HEADER + Len);
    end;
    if NRec = 0 then
    begin
      if Got < Want then
        raise EInOutError.Create('Undo data is damaged.');
      SetLength(Buf, Length(Buf) * 2);
      Continue;
    end;
    R := 0;
    while R < NRec do
    begin
      GStart := R;
      SpanStart := Recs[R].FileOff;
      SpanEnd := SpanStart + Recs[R].Len;
      while (R + 1 < NRec) and (Recs[R + 1].FileOff >= SpanEnd) and
        (Recs[R + 1].FileOff + Recs[R + 1].Len - SpanStart <= Length(Win)) and
        (Recs[R + 1].FileOff - SpanEnd <= ANON_SWAP_GAP) do
      begin
        Inc(R);
        SpanEnd := Recs[R].FileOff + Recs[R].Len;
      end;
      F.Position := SpanStart;
      if F.Read(Win[0], Integer(SpanEnd - SpanStart)) <> Integer(SpanEnd - SpanStart) then
        raise EInOutError.Create('Read error.');
      for K := GStart to R do
        if Fnv32(@Win[Recs[K].FileOff - SpanStart], Recs[K].Len) <> Recs[K].Hash then
        begin
          FResult.Mismatch := True;
          Exit;
        end;
      for K := GStart to R do
      begin
        Off := Integer(Recs[K].FileOff - SpanStart);
        NewHash := Fnv32(@Buf[Recs[K].BufOff + ANON_RUN_HEADER], Recs[K].Len);
        for Q := 0 to Recs[K].Len - 1 do
        begin
          Tmp := Win[Off + Q];
          Win[Off + Q] := Buf[Recs[K].BufOff + ANON_RUN_HEADER + Q];
          Buf[Recs[K].BufOff + ANON_RUN_HEADER + Q] := Tmp;
        end;
        Move(NewHash, Buf[Recs[K].BufOff + 12], 4);
      end;
      RegionStart := Recs[GStart].BufOff;
      RegionLen := Recs[R].BufOff + ANON_RUN_HEADER + Recs[R].Len - RegionStart;
      J.Position := Pos_ + RegionStart;
      J.WriteBuffer(Buf[RegionStart], RegionLen);
      F.Position := SpanStart;
      F.WriteBuffer(Win[0], Integer(SpanEnd - SpanStart));
      FSwapStop := Pos_ + RegionStart + RegionLen;
      Inc(FDone, RegionLen);
      Report(False);
      Inc(R);
    end;
    Inc(Pos_, P);
  end;
  Result := True;
end;

function TAnonRunner.Swap(AKind: TAnonJobKind; const ATarget, AJournal: string): TAnonJobResult;
var
  JS: TFileStream;
  H: array[0..ANON_JOURNAL_HEADER - 1] of Byte;
  Sz: Int64;
  Flags: Integer;
  Magic: AnsiString;
begin
  FillChar(FResult, SizeOf(FResult), 0);
  FResult.Kind := AKind;
  FResult.JournalPath := AJournal;
  FPhase := 2;
  FFile := nil;
  JS := nil;
  try
    try
      if not FileExists(AJournal) then
        raise EInOutError.Create('Undo data not found.');
      FFile := TFileStream.Create(ATarget, fmOpenReadWrite or fmShareDenyNone);
      JS := TFileStream.Create(AJournal, fmOpenReadWrite or fmShareExclusive);
      if JS.Read(H, SizeOf(H)) <> SizeOf(H) then
        raise EInOutError.Create('Undo data is damaged.');
      SetString(Magic, PAnsiChar(@H[0]), 8);
      Move(H[8], Sz, 8);
      Move(H[24], Flags, 4);
      if (Magic <> ANON_JOURNAL_MAGIC) or (Flags <> 1) then
        raise EInOutError.Create('Undo data is damaged.');
      if Sz <> FFile.Size then
      begin
        FResult.Mismatch := True;
        Exit;
      end;
      FTotal := JS.Size - ANON_JOURNAL_HEADER;
      FDone := 0;
      Report(True);
      try
        if SwapJournal(JS, FFile, ANON_JOURNAL_HEADER, JS.Size) then
          FResult.Success := True
        else if FSwapStop > ANON_JOURNAL_HEADER then
          FResult.RolledBack := SwapJournal(JS, FFile, ANON_JOURNAL_HEADER, FSwapStop)
        else
          FResult.RolledBack := True;
      except
        on E: Exception do
        begin
          FResult.ErrorMsg := E.Message;
          if FSwapStop > ANON_JOURNAL_HEADER then
          try
            FResult.RolledBack := SwapJournal(JS, FFile, ANON_JOURNAL_HEADER, FSwapStop);
          except
            FResult.RolledBack := False;
          end;
        end;
      end;
      FlushFileBuffers(FFile.Handle);
      FlushFileBuffers(JS.Handle);
      FResult.BytesScanned := FTotal;
    except
      on E: Exception do
        if FResult.ErrorMsg = '' then
          FResult.ErrorMsg := E.Message;
    end;
  finally
    JS.Free;
    FFile.Free;
  end;
  Result := FResult;
end;

function AnonApplyToFile(const ATarget, AJournal: string; const AOptions: TAnonOptions;
  const AEncoding: string; const ARanges: TAnonRanges;
  AProgress: TAnonProgressEvent; ACancel: TAnonCancelQuery): TAnonJobResult;
var
  R: TAnonRunner;
  T0: Cardinal;
begin
  T0 := GetTickCount;
  R := TAnonRunner.Create;
  try
    R.FProgress := AProgress;
    R.FCancel := ACancel;
    Result := R.Apply(ATarget, AJournal, AOptions, AEncoding, ARanges);
  finally
    R.Free;
  end;
  Result.ElapsedMs := GetTickCount - T0;
end;

function AnonSwapFile(AKind: TAnonJobKind; const ATarget, AJournal: string;
  AProgress: TAnonProgressEvent): TAnonJobResult;
var
  R: TAnonRunner;
  T0: Cardinal;
begin
  T0 := GetTickCount;
  R := TAnonRunner.Create;
  try
    R.FProgress := AProgress;
    Result := R.Swap(AKind, ATarget, AJournal);
  finally
    R.Free;
  end;
  Result.ElapsedMs := GetTickCount - T0;
end;

{ ---------------------------------------------------------------------------- }
{ Ficheiros de jornal                                                          }
{ ---------------------------------------------------------------------------- }

function AnonJournalDir: string;
begin
  Result := EnsureFastFileTempSubDir(ANON_JOURNAL_SUBDIR);
end;

function AnonNewJournalPath: string;
begin
  Result := AnonJournalDir + 'ffanon_' + IntToStr(GetCurrentProcessId) + '_' +
    IntToHex(Int64(AnonNewRandomKey and $FFFFFFFF), 8) + ANON_JOURNAL_EXT;
end;

function JournalOwnerAlive(const AName: string): Boolean;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  P1, P2: Integer;
  Pid: Cardinal;
  H: THandle;
begin
  Result := False;
  P1 := Pos('_', AName);
  if P1 = 0 then Exit;
  P2 := Pos('_', Copy(AName, P1 + 1, MaxInt));
  if P2 = 0 then Exit;
  Pid := StrToIntDef(Copy(AName, P1 + 1, P2 - 1), 0);
  if Pid = 0 then Exit;
  if Pid = GetCurrentProcessId then Exit;
  H := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, Pid);
  Result := H <> 0;
  if H <> 0 then
    CloseHandle(H);
end;

procedure AnonDeleteJournal(const APath: string);
begin
  if (APath <> '') and FileExists(APath) then
    DeleteFile(APath);
end;

procedure AnonCleanupJournalDir;
var
  Dir: string;
  SR: TSearchRec;
begin
  Dir := IncludeTrailingPathDelimiter(FastFileTempDir + ANON_JOURNAL_SUBDIR);
  if not DirectoryExists(Dir) then Exit;
  if FindFirst(Dir + '*' + ANON_JOURNAL_EXT, faAnyFile, SR) = 0 then
  try
    repeat
      if ((SR.Attr and faDirectory) = 0) and not JournalOwnerAlive(SR.Name) then
        DeleteFile(Dir + SR.Name);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function AnonEstimateJournalBytes(AScopeBytes: Int64; AChangedRatio: Double): Int64;
var
  R: Double;
begin
  R := AChangedRatio * 1.6 + 0.02;
  if R > 1.1 then R := 1.1;
  Result := Round(AScopeBytes * R) + ANON_JOURNAL_HEADER;
end;

initialization
  InitTables;
  InitNames;
  GSecondLevelHashes := BuildHashSet(ANON_SECOND_LEVEL);
  GPublicMailHashes := BuildHashSet(ANON_PUBLIC_MAIL);

finalization
  GNameBuckets.Free;

end.
