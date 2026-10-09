unit uAgentSql;

{
  SQL over one delimited text file (CSV, TSV, ...) in one streaming pass: the file is never loaded whole.
  The model writes the statement from the user's request; FastFile runs it.

  SELECT [DISTINCT] [TOP n] items [FROM name] [WHERE e] [GROUP BY e, ...] [HAVING e]
    [ORDER BY e [ASC|DESC], ...] [LIMIT n [OFFSET m]]
  UPDATE [name] SET col = e, ... [WHERE e]
  DELETE [FROM name] [WHERE e]
  INSERT INTO [name] [(col, ...)] VALUES (e, ...), ...
  ALTER TABLE name ADD [COLUMN] col [type] [DEFAULT e] [FIRST | AFTER col]
  ALTER TABLE name DROP [COLUMN] col | RENAME [COLUMN] col TO new
  TRUNCATE [TABLE] name   (deletes every data line; the header stays)

  UPDATE, DELETE, INSERT and ALTER only build line changes; the caller queues them for Accept.
  UPDATE rewrites only the assigned fields: the rest of the line keeps its bytes.
  Column names come from the header line ("Nome Completo", [Nome] or `Nome` when they have spaces);
  c1..cN are columns by position, line is the whole line, line_no its number.
  Text comparisons (=, <>, <, LIKE, IN) ignore case. Empty fields are NULL.
  Numbers in text are read with "." or "," as decimal separator ("1.234,56", "R$ 10,50").
}

interface

type
  TAgentSqlKind = (askSelect, askUpdate, askDelete, askInsert, askAlter);

  { SUM / AVG / MIN / MAX that left out values that are not numbers. }
  TAgentSqlSkip = record
    Expr: string;
    Count: Int64;
  end;

  { Replace lines LineStart..LineEnd with Text (lines separated by #10), delete them (Text = ''),
    or insert Text before LineStart (askInsert). }
  TAgentSqlChange = record
    LineStart: Int64;
    LineEnd: Int64;
    Text: string;
  end;

  TAgentSqlResult = record
    Ok: Boolean;
    Kind: TAgentSqlKind;
    { Tool output for the model. }
    Text: string;
    Sql: string;
    { SELECT result for the user: header line, then rows; columns separated by " | ". }
    Table: string;
    TotalRows: Int64;
    ShownRows: Integer;
    { The statement has a WHERE: MatchedRows records met it. }
    HasWhere: Boolean;
    MatchedRows: Int64;
    Changes: TArray<TAgentSqlChange>;
    ChangedLines: Int64;
    Skipped: TArray<TAgentSqlSkip>;
  end;

{ ADelimiter '' = detected from the first line. AHeader: -1 auto, 0 no header, 1 first line is the header.
  AMaxRows: SELECT rows kept for the user table. }
function AgentToolSql(const APath, ASql, ADelimiter: string; AHeader, AMaxRows: Integer;
  ACancelFlag: PInteger): TAgentSqlResult;
{ File name after FROM / UPDATE / INTO; '' when there is none or the statement does not parse. }
function AgentSqlFromName(const ASql: string): string;
{ AText starts with a SQL command word (SELECT, UPDATE, ALTER, ...). Words like "delete" are also plain verbs,
  so check AgentSqlParses before treating the text as SQL. }
function AgentSqlStartsLikeSql(const AText: string): Boolean;
{ AErr is the parser message when the statement is not valid in this dialect. }
function AgentSqlParses(const ASql: string; out AErr: string): Boolean;

implementation

uses
  SysUtils, Classes, StrUtils, Math, Character, Generics.Collections, Generics.Defaults,
  uFastFilePaths, uTextEncoding, uAgentTools, uAgentMatchIntent;

const
  MAX_GROUPS = 500000;
  MAX_DISTINCT = 2000000;
  MAX_LINE_NUMBERS = 1500;
  MODEL_ROWS = 100;
  CELL_CHARS = 200;
  MAX_CHANGE_BLOCKS = 2000;
  MAX_CHANGED_LINES = 200000;
  MAX_INSERT_ROWS = 5000;
  BLOCK_LINES = 5000;
  MAX_OFFSET = 100000;

  COL_UNBOUND = -100;
  COL_LINE = -1;
  COL_LINE_NO = -2;
  { A "quoted" name that is not a column: read as text. }
  COL_TEXT = -3;
  { A select alias used elsewhere (ORDER BY total, HAVING total > 5). }
  COL_ALIAS = -4;

  ALT_ADD = 1;
  ALT_DROP = 2;
  ALT_RENAME = 3;

  FN_UPPER = 0;
  FN_LOWER = 1;
  FN_TRIM = 2;
  FN_LTRIM = 3;
  FN_RTRIM = 4;
  FN_LENGTH = 5;
  FN_SUBSTR = 6;
  FN_LEFT = 7;
  FN_RIGHT = 8;
  FN_REPLACE = 9;
  FN_INSTR = 10;
  FN_COALESCE = 11;
  FN_NULLIF = 12;
  FN_CONCAT = 13;
  FN_ABS = 14;
  FN_ROUND = 15;
  FN_FLOOR = 16;
  FN_CEIL = 17;
  FN_NUM = 18;
  FN_INT = 19;
  FN_TEXT = 20;
  FN_YEAR = 21;
  FN_MONTH = 22;
  FN_DAY = 23;
  FN_DATE = 24;
  FN_CONTAINS = 25;
  FN_WORD = 26;
  FN_STARTS = 27;
  FN_ENDS = 28;
  FN_SPLIT = 29;
  FN_IIF = 30;

  FN_HELP = 'functions: COUNT SUM AVG MIN MAX UPPER LOWER TRIM LENGTH SUBSTR LEFT RIGHT REPLACE INSTR ' +
    'COALESCE NULLIF CONCAT ABS ROUND FLOOR CEIL NUM INT TEXT YEAR MONTH DAY DATE CONTAINS WORD_MATCH ' +
    'STARTS_WITH ENDS_WITH SPLIT_PART IIF CAST CASE';

type
  TFnDef = record
    Name: string;
    Id: Integer;
    MinA: Integer;
    MaxA: Integer;
  end;

const
  FNS: array[0..44] of TFnDef = (
    (Name: 'UPPER'; Id: FN_UPPER; MinA: 1; MaxA: 1),
    (Name: 'UCASE'; Id: FN_UPPER; MinA: 1; MaxA: 1),
    (Name: 'LOWER'; Id: FN_LOWER; MinA: 1; MaxA: 1),
    (Name: 'LCASE'; Id: FN_LOWER; MinA: 1; MaxA: 1),
    (Name: 'TRIM'; Id: FN_TRIM; MinA: 1; MaxA: 1),
    (Name: 'LTRIM'; Id: FN_LTRIM; MinA: 1; MaxA: 1),
    (Name: 'RTRIM'; Id: FN_RTRIM; MinA: 1; MaxA: 1),
    (Name: 'LENGTH'; Id: FN_LENGTH; MinA: 1; MaxA: 1),
    (Name: 'LEN'; Id: FN_LENGTH; MinA: 1; MaxA: 1),
    (Name: 'CHAR_LENGTH'; Id: FN_LENGTH; MinA: 1; MaxA: 1),
    (Name: 'SUBSTR'; Id: FN_SUBSTR; MinA: 2; MaxA: 3),
    (Name: 'SUBSTRING'; Id: FN_SUBSTR; MinA: 2; MaxA: 3),
    (Name: 'MID'; Id: FN_SUBSTR; MinA: 2; MaxA: 3),
    (Name: 'LEFT'; Id: FN_LEFT; MinA: 2; MaxA: 2),
    (Name: 'RIGHT'; Id: FN_RIGHT; MinA: 2; MaxA: 2),
    (Name: 'REPLACE'; Id: FN_REPLACE; MinA: 3; MaxA: 3),
    (Name: 'INSTR'; Id: FN_INSTR; MinA: 2; MaxA: 2),
    (Name: 'COALESCE'; Id: FN_COALESCE; MinA: 1; MaxA: 99),
    (Name: 'IFNULL'; Id: FN_COALESCE; MinA: 2; MaxA: 2),
    (Name: 'NVL'; Id: FN_COALESCE; MinA: 2; MaxA: 2),
    (Name: 'NULLIF'; Id: FN_NULLIF; MinA: 2; MaxA: 2),
    (Name: 'CONCAT'; Id: FN_CONCAT; MinA: 1; MaxA: 99),
    (Name: 'ABS'; Id: FN_ABS; MinA: 1; MaxA: 1),
    (Name: 'ROUND'; Id: FN_ROUND; MinA: 1; MaxA: 2),
    (Name: 'FLOOR'; Id: FN_FLOOR; MinA: 1; MaxA: 1),
    (Name: 'CEIL'; Id: FN_CEIL; MinA: 1; MaxA: 1),
    (Name: 'CEILING'; Id: FN_CEIL; MinA: 1; MaxA: 1),
    (Name: 'NUM'; Id: FN_NUM; MinA: 1; MaxA: 1),
    (Name: 'TO_NUMBER'; Id: FN_NUM; MinA: 1; MaxA: 1),
    (Name: 'NUMBER'; Id: FN_NUM; MinA: 1; MaxA: 1),
    (Name: 'INT'; Id: FN_INT; MinA: 1; MaxA: 1),
    (Name: 'TEXT'; Id: FN_TEXT; MinA: 1; MaxA: 1),
    (Name: 'STR'; Id: FN_TEXT; MinA: 1; MaxA: 1),
    (Name: 'YEAR'; Id: FN_YEAR; MinA: 1; MaxA: 1),
    (Name: 'MONTH'; Id: FN_MONTH; MinA: 1; MaxA: 1),
    (Name: 'DAY'; Id: FN_DAY; MinA: 1; MaxA: 1),
    (Name: 'DATE'; Id: FN_DATE; MinA: 1; MaxA: 1),
    (Name: 'CONTAINS'; Id: FN_CONTAINS; MinA: 2; MaxA: 2),
    (Name: 'WORD_MATCH'; Id: FN_WORD; MinA: 2; MaxA: 2),
    (Name: 'WHOLE_WORD'; Id: FN_WORD; MinA: 2; MaxA: 2),
    (Name: 'STARTS_WITH'; Id: FN_STARTS; MinA: 2; MaxA: 2),
    (Name: 'ENDS_WITH'; Id: FN_ENDS; MinA: 2; MaxA: 2),
    (Name: 'SPLIT_PART'; Id: FN_SPLIT; MinA: 3; MaxA: 3),
    (Name: 'IIF'; Id: FN_IIF; MinA: 3; MaxA: 3),
    (Name: 'IF'; Id: FN_IIF; MinA: 3; MaxA: 3));

  RESERVED: array[0..37] of string = ('SELECT', 'FROM', 'WHERE', 'GROUP', 'BY', 'HAVING', 'ORDER', 'LIMIT',
    'OFFSET', 'AND', 'OR', 'NOT', 'AS', 'ASC', 'DESC', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'CROSS',
    'OUTER', 'ON', 'UNION', 'LIKE', 'ILIKE', 'IN', 'IS', 'BETWEEN', 'THEN', 'WHEN', 'ELSE', 'END', 'DISTINCT',
    'FETCH', 'SET', 'VALUES', 'INTO');

type
  ESqlError = class(Exception);

  TSqlKind = (skNull, skNum, skStr);

  TSqlVal = record
    Kind: TSqlKind;
    Num: Double;
    Str: string;
  end;

  TAggFunc = (afCount, afSum, afAvg, afMin, afMax);

  TAggState = record
    Cnt: Int64;
    NumCnt: Int64;
    Skipped: Int64;
    Sum: Double;
    { MIN / MAX: over the numbers when the column has any, else over the text. }
    NumMin: Double;
    NumMax: Double;
    HasMinMax: Boolean;
    MinV: TSqlVal;
    MaxV: TSqlVal;
    Seen: TDictionary<string, Boolean>;
  end;

  TSqlEnv = record
    Fields: TArray<string>;
    LineNo: Int64;
    Line: string;
    Aggs: TArray<TAggState>;
  end;

  TFieldSpans = record
    { Segment of field K: Starts[K] .. Ends[K] - 1 (Ends[K] is the delimiter after it). }
    Starts: TArray<Integer>;
    Ends: TArray<Integer>;
    Quoted: TArray<Boolean>;
  end;
  PFieldSpans = ^TFieldSpans;

  TSqlNode = class
  public
    function Eval(const E: TSqlEnv): TSqlVal; virtual; abstract;
  end;

  TLitNode = class(TSqlNode)
  public
    V: TSqlVal;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TColNode = class(TSqlNode)
  public
    Name: string;
    Quoted: Boolean;
    Index: Integer;
    Target: TSqlNode;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TBinOp = (boOr, boAnd, boEq, boNe, boLt, boLe, boGt, boGe, boAdd, boSub, boMul, boDiv, boMod,
    boConcat, boLike);

  TBinNode = class(TSqlNode)
  public
    Op: TBinOp;
    A, B: TSqlNode;
    PatReady: Boolean;
    Pat: string;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TNotNode = class(TSqlNode)
  public
    A: TSqlNode;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TNegNode = class(TSqlNode)
  public
    A: TSqlNode;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TInNode = class(TSqlNode)
  public
    A: TSqlNode;
    Items: TArray<TSqlNode>;
    Neg: Boolean;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TBetweenNode = class(TSqlNode)
  public
    A, Lo, Hi: TSqlNode;
    Neg: Boolean;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TIsNullNode = class(TSqlNode)
  public
    A: TSqlNode;
    Neg: Boolean;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TFuncNode = class(TSqlNode)
  public
    Fn: Integer;
    Args: TArray<TSqlNode>;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TCaseNode = class(TSqlNode)
  public
    Operand: TSqlNode;
    Whens, Thens: TArray<TSqlNode>;
    ElseN: TSqlNode;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TAggNode = class(TSqlNode)
  public
    Func: TAggFunc;
    Arg: TSqlNode;
    Distinct: Boolean;
    Index: Integer;
    Text: string;
    function Eval(const E: TSqlEnv): TSqlVal; override;
  end;

  TSelItem = record
    Expr: TSqlNode;
    Alias: string;
    Text: string;
    Star: Boolean;
  end;

  TOrderItem = record
    Expr: TSqlNode;
    Desc: Boolean;
  end;

  TSqlQuery = class
  public
    Src: string;
    Kind: TAgentSqlKind;
    Distinct: Boolean;
    Items: TList<TSelItem>;
    FromName: string;
    Where: TSqlNode;
    Having: TSqlNode;
    GroupBy: TList<TSqlNode>;
    OrderBy: TList<TOrderItem>;
    Limit: Int64;
    Offset: Int64;
    SetCols: TList<TColNode>;
    SetExprs: TList<TSqlNode>;
    InsCols: TStringList;
    InsRows: TList<TArray<TSqlNode>>;
    AlterOp: Integer;
    AlterCol: string;
    AlterNew: string;
    AlterAfter: string;
    AlterFirst: Boolean;
    AlterDefault: TSqlNode;
    Nodes: TObjectList<TSqlNode>;
    Cols: TList<TColNode>;
    Aggs: TList<TAggNode>;
    constructor Create;
    destructor Destroy; override;
  end;

  TTokKind = (tkEnd, tkIdent, tkQIdent, tkStr, tkNum, tkSym);

  TTok = record
    Kind: TTokKind;
    Text: string;
    P1, P2: Integer;
  end;

  TSqlParser = class
  private
    FToks: TArray<TTok>;
    FI: Integer;
    FQ: TSqlQuery;
    FNoAgg: Integer;
    FInAgg: Integer;
    function Peek(AOfs: Integer = 0): TTok;
    function Next: TTok;
    function LastP2: Integer;
    procedure Fail(const AMsg: string);
    function PeekKw(const K: string): Boolean;
    function AcceptKw(const K: string): Boolean;
    procedure ExpectKw(const K: string);
    function PeekSym(const S: string): Boolean;
    function AcceptSym(const S: string): Boolean;
    procedure ExpectSym(const S: string);
    function ParseInt: Int64;
    function Own(N: TSqlNode): TSqlNode;
    function NewCol(const AName: string; AQuoted: Boolean): TColNode;
    function Bin(AOp: TBinOp; A, B: TSqlNode): TSqlNode;
    function NotOf(A: TSqlNode): TSqlNode;
    function FuncOf(AFn: Integer; const AArgs: array of TSqlNode): TSqlNode;
    function TableName: string;
    function ParseExpr: TSqlNode;
    function ParseOr: TSqlNode;
    function ParseAnd: TSqlNode;
    function ParseNot: TSqlNode;
    function ParseCmp: TSqlNode;
    function ParseAdd: TSqlNode;
    function ParseMul: TSqlNode;
    function ParseUnary: TSqlNode;
    function ParsePrimary: TSqlNode;
    function ParseCase: TSqlNode;
    function ParseCast: TSqlNode;
    function ParseFunc(const AName: string; AP1: Integer): TSqlNode;
    procedure ParseSelect;
    procedure ParseUpdate;
    procedure ParseDelete;
    procedure ParseInsert;
    procedure ParseAlter;
    procedure ParseTruncate;
    function ColName(const AWhat: string): string;
  public
    function Parse(const ASql: string): TSqlQuery;
  end;

  TSqlRow = record
    Vals: TArray<TSqlVal>;
    Keys: TArray<TSqlVal>;
    Seq: Int64;
  end;

  TSqlGroup = class
  public
    Fields: TArray<string>;
    LineNo: Int64;
    Line: string;
    Aggs: TArray<TAggState>;
    Seq: Int64;
    destructor Destroy; override;
  end;

  TSqlRun = class
  private
    FPend: Integer;
    FPendStart: Int64;
    FPendEnd: Int64;
    FPendText: TStringBuilder;
    procedure FlushChange;
  public
    Q: TSqlQuery;
    Enc: string;
    DelimArg: string;
    HeaderArg: Integer;
    Cancel: PInteger;
    MaxRows: Integer;
    Bound: Boolean;
    Delim: Char;
    UseHeader: Boolean;
    Names: TArray<string>;
    NormNames: TArray<string>;
    Final: TList<TSelItem>;
    HasAgg: Boolean;
    Keep: Int64;
    Scanned, Matched, ResultCount, Seq: Int64;
    LastDataLine: Int64;
    Rows: TList<TSqlRow>;
    Groups: TDictionary<string, TSqlGroup>;
    GroupList: TObjectList<TSqlGroup>;
    DistinctSet: TDictionary<string, Boolean>;
    LineNos: TStringBuilder;
    LineNoCount: Int64;
    Changes: TList<TAgentSqlChange>;
    ChangedLines: Int64;
    Notes: TStringList;
    Skipped: TList<TAgentSqlSkip>;
    { ALTER: the column dropped or renamed, or where the new one goes (-1 = after the last). }
    AlterIdx: Integer;
    Err: string;
    Stopped: Boolean;
    constructor Create;
    destructor Destroy; override;
    function FindName(const AName: string): Integer;
    procedure Resolve(C: TColNode);
    procedure Setup(const AFirst: string);
    procedure Bind;
    function EvalRow(const E: TSqlEnv; ASeq: Int64): TSqlRow;
    function CompareRows(const A, B: TSqlRow): Integer;
    procedure AddTopK(const R: TSqlRow);
    function QuoteField(const S: string; AWasQuoted: Boolean): string;
    function UpdatedLine(const ALine: string; const E: TSqlEnv; const ASpans: TFieldSpans): string;
    procedure AddChange(ALineNo: Int64; const AText: string);
    function InsertField(const ALine: string; const ASpans: TFieldSpans; const AText: string): string;
    function RemoveField(const ALine: string; const ASpans: TFieldSpans): string;
    procedure ProcessHeader(const ALine: string; ALineNo: Int64);
    procedure ProcessAlterRow(const ALine: string; ALineNo: Int64);
    procedure ProcessRow(const ALine: string; ALineNo: Int64);
    procedure Finish;
  end;

var
  GFS: TFormatSettings;

{ --- values ------------------------------------------------------------------------ }

function VNull: TSqlVal;
begin
  Result.Kind := skNull;
  Result.Num := 0;
  Result.Str := '';
end;

function VNum(D: Double): TSqlVal;
begin
  Result.Kind := skNum;
  Result.Num := D;
  Result.Str := '';
end;

function VStr(const S: string): TSqlVal;
begin
  Result.Kind := skStr;
  Result.Num := 0;
  Result.Str := S;
end;

{ Empty text is NULL, like an empty field. }
function VText(const S: string): TSqlVal;
begin
  if S = '' then
    Result := VNull
  else
    Result := VStr(S);
end;

function VBool(B: Boolean): TSqlVal;
begin
  Result := VNum(Ord(B));
end;

{ "1234.5", "1.234,56", "1,234.56", "R$ 10,50", "-3", "12%", "1e3". One "," alone is a decimal comma. }
function TryParseNum(const AText: string; out D: Double): Boolean;
var
  S: string;
  I, J, Dots, Commas, LastDot, LastComma, Digits: Integer;
  Neg: Boolean;
  DecSep, Thou: Char;
begin
  Result := False;
  D := 0;
  S := Trim(AText);
  if (S = '') or (Length(S) > 40) then Exit;
  if not (CharInSet(S[1], ['0'..'9', '-', '+', '.', ',', '$', 'R', 'U']) or (S[1] = #$20AC) or (S[1] = #$00A3)) then
    Exit;
  Neg := False;
  if CharInSet(S[1], ['-', '+']) then
  begin
    Neg := S[1] = '-';
    S := TrimLeft(Copy(S, 2, MaxInt));
  end;
  if StartsText('R$', S) then
    S := Copy(S, 3, MaxInt)
  else if StartsText('US$', S) then
    S := Copy(S, 4, MaxInt)
  else if (S <> '') and ((S[1] = '$') or (S[1] = #$20AC) or (S[1] = #$00A3)) then
    S := Copy(S, 2, MaxInt);
  S := Trim(S);
  if (S <> '') and (S[1] = '-') and not Neg then
  begin
    Neg := True;
    S := Copy(S, 2, MaxInt);
  end;
  if (S <> '') and (S[Length(S)] = '%') then
    SetLength(S, Length(S) - 1);
  if S = '' then Exit;
  Dots := 0;
  Commas := 0;
  LastDot := 0;
  LastComma := 0;
  Digits := 0;
  I := 1;
  while I <= Length(S) do
  begin
    case S[I] of
      '0'..'9':
        Inc(Digits);
      '.':
        begin
          Inc(Dots);
          LastDot := I;
        end;
      ',':
        begin
          Inc(Commas);
          LastComma := I;
        end;
      'e', 'E':
        begin
          if (Digits = 0) or (Commas > 0) or (I = Length(S)) then Exit;
          J := I + 1;
          if CharInSet(S[J], ['+', '-']) then
            Inc(J);
          if J > Length(S) then Exit;
          while J <= Length(S) do
          begin
            if not CharInSet(S[J], ['0'..'9']) then Exit;
            Inc(J);
          end;
          Break;
        end;
    else
      Exit;
    end;
    Inc(I);
  end;
  if Digits = 0 then Exit;
  DecSep := #0;
  Thou := #0;
  if (Dots > 0) and (Commas > 0) then
  begin
    if LastComma > LastDot then
    begin
      DecSep := ',';
      Thou := '.';
    end
    else
    begin
      DecSep := '.';
      Thou := ',';
    end;
  end
  else if Commas > 0 then
  begin
    if Commas = 1 then
      DecSep := ','
    else
      Thou := ',';
  end
  else if Dots > 1 then
    Thou := '.'
  else if Dots = 1 then
    DecSep := '.';
  if ((DecSep = '.') and (Dots > 1)) or ((DecSep = ',') and (Commas > 1)) then Exit;
  if Thou <> #0 then
    S := StringReplace(S, Thou, '', [rfReplaceAll]);
  if DecSep = ',' then
    S := StringReplace(S, ',', '.', []);
  Result := TryStrToFloat(S, D, GFS);
  if Result and Neg then
    D := -D;
end;

function FmtNum(D: Double): string;
begin
  if IsNan(D) or IsInfinite(D) then
    Exit('');
  if (Frac(D) = 0) and (Abs(D) < 1E15) then
    Result := IntToStr(Trunc(D))
  else
  begin
    Result := FormatFloat('0.######', D, GFS);
    if Result = '-0' then
      Result := '0';
  end;
end;

function ToText(const V: TSqlVal): string;
begin
  case V.Kind of
    skNum: Result := FmtNum(V.Num);
    skStr: Result := V.Str;
  else
    Result := '';
  end;
end;

function TryNumOf(const V: TSqlVal; out D: Double): Boolean;
begin
  case V.Kind of
    skNum:
      begin
        D := V.Num;
        Result := True;
      end;
    skStr:
      Result := TryParseNum(V.Str, D);
  else
    D := 0;
    Result := False;
  end;
end;

function Truthy(const V: TSqlVal): Boolean;
var
  D: Double;
begin
  case V.Kind of
    skNum: Result := V.Num <> 0;
    skStr:
      if TryParseNum(V.Str, D) then
        Result := D <> 0
      else
        Result := not SameText(V.Str, 'false');
  else
    Result := False;
  end;
end;

{ False when either side is NULL. Numbers (or text that reads as a number) compare as numbers. }
function CompareVals(const A, B: TSqlVal; out R: Integer): Boolean;
var
  X, Y: Double;
begin
  R := 0;
  if (A.Kind = skNull) or (B.Kind = skNull) then
    Exit(False);
  Result := True;
  if TryNumOf(A, X) and TryNumOf(B, Y) then
    R := CompareValue(X, Y)
  else
    R := AnsiCompareText(ToText(A), ToText(B));
end;

{ ORDER BY: NULLs last in both directions. }
function SortCompare(const A, B: TSqlVal; ADesc: Boolean): Integer;
begin
  if A.Kind = skNull then
  begin
    if B.Kind = skNull then
      Exit(0);
    Exit(1);
  end;
  if B.Kind = skNull then
    Exit(-1);
  CompareVals(A, B, Result);
  if ADesc then
    Result := -Result;
end;

{ Group / DISTINCT key: case-insensitive text, numbers by value. }
function ValKey(const V: TSqlVal): string;
var
  D: Double;
begin
  case V.Kind of
    skNum: Result := 'n' + FloatToStr(V.Num, GFS);
    skStr:
      if TryParseNum(V.Str, D) then
        Result := 'n' + FloatToStr(D, GFS)
      else
        Result := 's' + AnsiUpperCase(V.Str);
  else
    Result := #0;
  end;
end;

{ % = any run, _ = one character. Both sides already upper-cased. }
function LikeMatch(const S, P: string): Boolean;
var
  Si, Pj, Star, Mark: Integer;
begin
  Si := 1;
  Pj := 1;
  Star := 0;
  Mark := 0;
  while Si <= Length(S) do
  begin
    if (Pj <= Length(P)) and (P[Pj] <> '%') and ((P[Pj] = '_') or (P[Pj] = S[Si])) then
    begin
      Inc(Si);
      Inc(Pj);
    end
    else if (Pj <= Length(P)) and (P[Pj] = '%') then
    begin
      Star := Pj;
      Mark := Si;
      Inc(Pj);
    end
    else if Star > 0 then
    begin
      Pj := Star + 1;
      Inc(Mark);
      Si := Mark;
    end
    else
      Exit(False);
  end;
  while (Pj <= Length(P)) and (P[Pj] = '%') do
    Inc(Pj);
  Result := Pj > Length(P);
end;

function IsWordCh(C: Char): Boolean;
begin
  Result := C.IsLetterOrDigit or (C = '_');
end;

function WordMatch(const AText, AWord: string): Boolean;
var
  T, N: string;
  P, E: Integer;
begin
  Result := False;
  T := AnsiUpperCase(AText);
  N := AnsiUpperCase(Trim(AWord));
  if N = '' then Exit;
  P := Pos(N, T);
  while P > 0 do
  begin
    E := P + Length(N);
    if ((P = 1) or not IsWordCh(T[P - 1])) and ((E > Length(T)) or not IsWordCh(T[E])) then
      Exit(True);
    P := Pos(N, T, P + 1);
  end;
end;

{ yyyy-mm-dd[...], dd/mm/yyyy, dd-mm-yy, mm/dd/yyyy when the second number is above 12. }
function ParseDateParts(const S: string; out Y, M, D: Integer): Boolean;
var
  N, L: array[0..2] of Integer;
  I, K: Integer;
begin
  Result := False;
  Y := 0;
  M := 0;
  D := 0;
  K := 0;
  I := 1;
  while (I <= Length(S)) and (K < 3) do
  begin
    if CharInSet(S[I], ['0'..'9']) then
    begin
      N[K] := 0;
      L[K] := 0;
      while (I <= Length(S)) and CharInSet(S[I], ['0'..'9']) and (L[K] < 9) do
      begin
        N[K] := N[K] * 10 + Ord(S[I]) - Ord('0');
        Inc(L[K]);
        Inc(I);
      end;
      Inc(K);
    end
    else if (K > 0) and not CharInSet(S[I], ['-', '/', '.', ' ']) then
      Break
    else
      Inc(I);
  end;
  if K < 3 then Exit;
  if L[0] = 4 then
  begin
    Y := N[0];
    M := N[1];
    D := N[2];
  end
  else
  begin
    Y := N[2];
    if L[2] = 2 then
    begin
      if Y < 70 then
        Inc(Y, 2000)
      else
        Inc(Y, 1900);
    end
    else if L[2] <> 4 then
      Exit;
    if (N[0] <= 12) and (N[1] > 12) then
    begin
      M := N[0];
      D := N[1];
    end
    else
    begin
      D := N[0];
      M := N[1];
    end;
  end;
  Result := (Y > 0) and (M >= 1) and (M <= 12) and (D >= 1) and (D <= 31);
end;

function IntPart(X: Double; AUp: Boolean): Double;
begin
  Result := Int(X);
  if AUp and (Result < X) then
    Result := Result + 1
  else if (not AUp) and (Result > X) then
    Result := Result - 1;
end;

{ --- delimited lines ------------------------------------------------------------- }

function DetectDelim(const S: string): Char;
const
  CANDS: array[0..3] of Char = (';', ',', #9, '|');
var
  Cnt: array[0..3] of Integer;
  I, K, Best: Integer;
  InQ: Boolean;
begin
  for K := 0 to 3 do
    Cnt[K] := 0;
  InQ := False;
  for I := 1 to Length(S) do
    if S[I] = '"' then
      InQ := not InQ
    else if not InQ then
      for K := 0 to 3 do
        if S[I] = CANDS[K] then
          Inc(Cnt[K]);
  Best := -1;
  for K := 0 to 3 do
    if (Cnt[K] > 0) and ((Best < 0) or (Cnt[K] > Cnt[Best])) then
      Best := K;
  if Best < 0 then
    Result := #0
  else
    Result := CANDS[Best];
end;

{ Fields of one line ("..." quoting with "" inside), trimmed. D = #0: the whole line is one field. }
function SplitLine(const S: string; D: Char; ASpans: PFieldSpans): TArray<string>;
var
  I, N, K, Start, SegStart: Integer;
  F: string;
  Q: Boolean;
  Arr: TArray<string>;

  procedure Put;
  begin
    if K = Length(Arr) then
      SetLength(Arr, K * 2 + 4);
    Arr[K] := Trim(F);
    if ASpans <> nil then
    begin
      if K >= Length(ASpans.Starts) then
      begin
        SetLength(ASpans.Starts, K * 2 + 4);
        SetLength(ASpans.Ends, K * 2 + 4);
        SetLength(ASpans.Quoted, K * 2 + 4);
      end;
      ASpans.Starts[K] := SegStart;
      ASpans.Ends[K] := I;
      ASpans.Quoted[K] := Q;
    end;
    Inc(K);
  end;

begin
  N := Length(S);
  K := 0;
  SetLength(Arr, 16);
  if ASpans <> nil then
  begin
    SetLength(ASpans.Starts, 16);
    SetLength(ASpans.Ends, 16);
    SetLength(ASpans.Quoted, 16);
  end;
  if D = #0 then
  begin
    SegStart := 1;
    I := N + 1;
    F := S;
    Q := False;
    Put;
  end
  else
  begin
    I := 1;
    while True do
    begin
      SegStart := I;
      while (I <= N) and (S[I] = ' ') do
        Inc(I);
      Q := (I <= N) and (S[I] = '"');
      if Q then
      begin
        F := '';
        Inc(I);
        Start := I;
        while I <= N do
        begin
          if S[I] = '"' then
          begin
            if (I < N) and (S[I + 1] = '"') then
            begin
              F := F + Copy(S, Start, I - Start + 1);
              Inc(I, 2);
              Start := I;
              Continue;
            end;
            Break;
          end;
          Inc(I);
        end;
        F := F + Copy(S, Start, I - Start);
        Inc(I);
        Start := I;
        while (I <= N) and (S[I] <> D) do
          Inc(I);
        F := F + Copy(S, Start, I - Start);
      end
      else
      begin
        Start := I;
        while (I <= N) and (S[I] <> D) do
          Inc(I);
        F := Copy(S, Start, I - Start);
      end;
      if I > N + 1 then
        I := N + 1;
      Put;
      if I > N then
        Break;
      Inc(I);
      if I > N then
      begin
        SegStart := I;
        F := '';
        Q := False;
        Put;
        Break;
      end;
    end;
  end;
  SetLength(Arr, K);
  Result := Arr;
  if ASpans <> nil then
  begin
    SetLength(ASpans.Starts, K);
    SetLength(ASpans.Ends, K);
    SetLength(ASpans.Quoted, K);
  end;
end;

function NormName(const S: string): string;
begin
  Result := StringReplace(Trim(AgentFoldText(S)), ' ', '', [rfReplaceAll]);
end;

{ --- nodes --------------------------------------------------------------------- }

function TLitNode.Eval(const E: TSqlEnv): TSqlVal;
begin
  Result := V;
end;

function TColNode.Eval(const E: TSqlEnv): TSqlVal;
begin
  case Index of
    COL_LINE: Result := VText(E.Line);
    COL_LINE_NO: Result := VNum(E.LineNo);
    COL_TEXT: Result := VText(Name);
    COL_ALIAS: Result := Target.Eval(E);
  else
    if (Index >= 0) and (Index < Length(E.Fields)) then
      Result := VText(E.Fields[Index])
    else
      Result := VNull;
  end;
end;

function TBinNode.Eval(const E: TSqlEnv): TSqlVal;
var
  VA, VB: TSqlVal;
  R: Integer;
  X, Y: Double;
  P: string;
begin
  case Op of
    boOr:
      begin
        if Truthy(A.Eval(E)) then
          Exit(VBool(True));
        Exit(VBool(Truthy(B.Eval(E))));
      end;
    boAnd:
      begin
        if not Truthy(A.Eval(E)) then
          Exit(VBool(False));
        Exit(VBool(Truthy(B.Eval(E))));
      end;
  end;
  VA := A.Eval(E);
  VB := B.Eval(E);
  case Op of
    boEq, boNe, boLt, boLe, boGt, boGe:
      begin
        if not CompareVals(VA, VB, R) then
          Exit(VNull);
        case Op of
          boEq: Result := VBool(R = 0);
          boNe: Result := VBool(R <> 0);
          boLt: Result := VBool(R < 0);
          boLe: Result := VBool(R <= 0);
          boGt: Result := VBool(R > 0);
        else
          Result := VBool(R >= 0);
        end;
      end;
    boAdd, boSub, boMul, boDiv, boMod:
      begin
        if not (TryNumOf(VA, X) and TryNumOf(VB, Y)) then
          Exit(VNull);
        case Op of
          boAdd: Result := VNum(X + Y);
          boSub: Result := VNum(X - Y);
          boMul: Result := VNum(X * Y);
          boDiv:
            if Y = 0 then
              Result := VNull
            else
              Result := VNum(X / Y);
        else
          if (Abs(X) >= 9E18) or (Abs(Y) >= 9E18) or (Trunc(Y) = 0) then
            Result := VNull
          else
            Result := VNum(Trunc(X) mod Trunc(Y));
        end;
      end;
    boConcat:
      if (VA.Kind = skNull) and (VB.Kind = skNull) then
        Result := VNull
      else
        Result := VStr(ToText(VA) + ToText(VB));
  else
    begin
      if (VA.Kind = skNull) or (VB.Kind = skNull) then
        Exit(VNull);
      if B is TLitNode then
      begin
        if not PatReady then
        begin
          Pat := AnsiUpperCase(ToText(VB));
          PatReady := True;
        end;
        P := Pat;
      end
      else
        P := AnsiUpperCase(ToText(VB));
      Result := VBool(LikeMatch(AnsiUpperCase(ToText(VA)), P));
    end;
  end;
end;

function TNotNode.Eval(const E: TSqlEnv): TSqlVal;
var
  V: TSqlVal;
begin
  V := A.Eval(E);
  if V.Kind = skNull then
    Result := VNull
  else
    Result := VBool(not Truthy(V));
end;

function TNegNode.Eval(const E: TSqlEnv): TSqlVal;
var
  X: Double;
begin
  if TryNumOf(A.Eval(E), X) then
    Result := VNum(-X)
  else
    Result := VNull;
end;

function TInNode.Eval(const E: TSqlEnv): TSqlVal;
var
  V: TSqlVal;
  I, R: Integer;
  Found: Boolean;
begin
  V := A.Eval(E);
  if V.Kind = skNull then
    Exit(VNull);
  Found := False;
  for I := 0 to High(Items) do
    if CompareVals(V, Items[I].Eval(E), R) and (R = 0) then
    begin
      Found := True;
      Break;
    end;
  Result := VBool(Found <> Neg);
end;

function TBetweenNode.Eval(const E: TSqlEnv): TSqlVal;
var
  V: TSqlVal;
  R1, R2: Integer;
begin
  V := A.Eval(E);
  if not (CompareVals(V, Lo.Eval(E), R1) and CompareVals(V, Hi.Eval(E), R2)) then
    Exit(VNull);
  Result := VBool(((R1 >= 0) and (R2 <= 0)) <> Neg);
end;

function TIsNullNode.Eval(const E: TSqlEnv): TSqlVal;
begin
  Result := VBool((A.Eval(E).Kind = skNull) <> Neg);
end;

function TFuncNode.Eval(const E: TSqlEnv): TSqlVal;
var
  V: TArray<TSqlVal>;
  I, Y, M, D: Integer;
  S, T: string;
  X, Z: Double;
  N, L: Int64;
  Parts: TArray<string>;
begin
  case Fn of
    FN_COALESCE:
      begin
        for I := 0 to High(Args) do
        begin
          Result := Args[I].Eval(E);
          if Result.Kind <> skNull then
            Exit;
        end;
        Exit(VNull);
      end;
    FN_IIF:
      if Truthy(Args[0].Eval(E)) then
        Exit(Args[1].Eval(E))
      else
        Exit(Args[2].Eval(E));
  end;
  SetLength(V, Length(Args));
  for I := 0 to High(Args) do
    V[I] := Args[I].Eval(E);
  if Fn = FN_CONCAT then
  begin
    S := '';
    for I := 0 to High(V) do
      S := S + ToText(V[I]);
    Exit(VText(S));
  end;
  if V[0].Kind = skNull then
    Exit(VNull);
  S := ToText(V[0]);
  case Fn of
    FN_UPPER: Result := VStr(AnsiUpperCase(S));
    FN_LOWER: Result := VStr(AnsiLowerCase(S));
    FN_TRIM: Result := VText(Trim(S));
    FN_LTRIM: Result := VText(TrimLeft(S));
    FN_RTRIM: Result := VText(TrimRight(S));
    FN_LENGTH: Result := VNum(Length(S));
    FN_SUBSTR:
      begin
        if not TryNumOf(V[1], X) then
          Exit(VNull);
        X := Int(X);
        if X < 0 then
          X := Length(S) + X + 1;
        if X < 1 then
          X := 1;
        if X > Length(S) + 1 then
          Exit(VNull);
        N := Trunc(X);
        L := MaxInt;
        if Length(V) > 2 then
        begin
          if not TryNumOf(V[2], Z) then
            Exit(VNull);
          if Z < 0 then
            Z := 0;
          if Z < MaxInt then
            L := Trunc(Z);
        end;
        Result := VText(Copy(S, Integer(N), Integer(L)));
      end;
    FN_LEFT, FN_RIGHT:
      begin
        if not TryNumOf(V[1], X) then
          Exit(VNull);
        if X < 0 then
          X := 0;
        if X > Length(S) then
          X := Length(S);
        L := Trunc(X);
        if Fn = FN_LEFT then
          Result := VText(Copy(S, 1, Integer(L)))
        else
          Result := VText(Copy(S, Length(S) - Integer(L) + 1, Integer(L)));
      end;
    FN_REPLACE:
      if (V[1].Kind = skNull) then
        Result := V[0]
      else
        Result := VText(StringReplace(S, ToText(V[1]), ToText(V[2]), [rfReplaceAll]));
    FN_INSTR:
      Result := VNum(Pos(AnsiUpperCase(ToText(V[1])), AnsiUpperCase(S)));
    FN_NULLIF:
      if CompareVals(V[0], V[1], I) and (I = 0) then
        Result := VNull
      else
        Result := V[0];
    FN_ABS, FN_ROUND, FN_FLOOR, FN_CEIL, FN_NUM, FN_INT:
      begin
        if not TryNumOf(V[0], X) then
          Exit(VNull);
        case Fn of
          FN_ABS: Result := VNum(Abs(X));
          FN_ROUND:
            begin
              I := 0;
              if (Length(V) > 1) and TryNumOf(V[1], Z) then
                I := Trunc(EnsureRange(Z, -15, 15));
              Result := VNum(SimpleRoundTo(X, -I));
            end;
          FN_FLOOR: Result := VNum(IntPart(X, False));
          FN_CEIL: Result := VNum(IntPart(X, True));
          FN_INT: Result := VNum(Int(X));
        else
          Result := VNum(X);
        end;
      end;
    FN_TEXT:
      Result := VStr(S);
    FN_YEAR, FN_MONTH, FN_DAY, FN_DATE:
      begin
        if not ParseDateParts(S, Y, M, D) then
          Exit(VNull);
        case Fn of
          FN_YEAR: Result := VNum(Y);
          FN_MONTH: Result := VNum(M);
          FN_DAY: Result := VNum(D);
        else
          Result := VStr(Format('%.4d-%.2d-%.2d', [Y, M, D]));
        end;
      end;
    FN_CONTAINS:
      if V[1].Kind = skNull then
        Result := VNull
      else
        Result := VBool(Pos(AnsiUpperCase(ToText(V[1])), AnsiUpperCase(S)) > 0);
    FN_WORD:
      if V[1].Kind = skNull then
        Result := VNull
      else
        Result := VBool(WordMatch(S, ToText(V[1])));
    FN_STARTS:
      Result := VBool(StartsText(ToText(V[1]), S));
    FN_ENDS:
      Result := VBool(EndsText(ToText(V[1]), S));
    FN_SPLIT:
      begin
        T := ToText(V[1]);
        if (T = '') or not TryNumOf(V[2], X) then
          Exit(VNull);
        Parts := S.Split([T]);
        if (X >= 1) and (X <= Length(Parts)) then
          Result := VText(Trim(Parts[Trunc(X) - 1]))
        else
          Result := VNull;
      end;
  else
    Result := VNull;
  end;
end;

function TCaseNode.Eval(const E: TSqlEnv): TSqlVal;
var
  I, R: Integer;
  O: TSqlVal;
begin
  if Operand <> nil then
  begin
    O := Operand.Eval(E);
    for I := 0 to High(Whens) do
      if CompareVals(O, Whens[I].Eval(E), R) and (R = 0) then
        Exit(Thens[I].Eval(E));
  end
  else
    for I := 0 to High(Whens) do
      if Truthy(Whens[I].Eval(E)) then
        Exit(Thens[I].Eval(E));
  if ElseN <> nil then
    Result := ElseN.Eval(E)
  else
    Result := VNull;
end;

function TAggNode.Eval(const E: TSqlEnv): TSqlVal;
begin
  if Index >= Length(E.Aggs) then
    Exit(VNull);
  case Func of
    afCount:
      Result := VNum(E.Aggs[Index].Cnt);
    afSum:
      if E.Aggs[Index].NumCnt > 0 then
        Result := VNum(E.Aggs[Index].Sum)
      else
        Result := VNull;
    afAvg:
      if E.Aggs[Index].NumCnt > 0 then
        Result := VNum(E.Aggs[Index].Sum / E.Aggs[Index].NumCnt)
      else
        Result := VNull;
    afMin:
      if E.Aggs[Index].NumCnt > 0 then
        Result := VNum(E.Aggs[Index].NumMin)
      else if E.Aggs[Index].HasMinMax then
        Result := E.Aggs[Index].MinV
      else
        Result := VNull;
  else
    if E.Aggs[Index].NumCnt > 0 then
      Result := VNum(E.Aggs[Index].NumMax)
    else if E.Aggs[Index].HasMinMax then
      Result := E.Aggs[Index].MaxV
    else
      Result := VNull;
  end;
end;

procedure UpdateAgg(var S: TAggState; A: TAggNode; const E: TSqlEnv);
var
  V: TSqlVal;
  D: Double;
  R: Integer;
  K: string;
begin
  if A.Arg = nil then
  begin
    Inc(S.Cnt);
    Exit;
  end;
  V := A.Arg.Eval(E);
  if V.Kind = skNull then
    Exit;
  if A.Distinct then
  begin
    K := ValKey(V);
    if S.Seen = nil then
      S.Seen := TDictionary<string, Boolean>.Create;
    if S.Seen.ContainsKey(K) then
      Exit;
    S.Seen.Add(K, True);
  end;
  Inc(S.Cnt);
  if TryNumOf(V, D) then
  begin
    S.Sum := S.Sum + D;
    if (S.NumCnt = 0) or (D < S.NumMin) then
      S.NumMin := D;
    if (S.NumCnt = 0) or (D > S.NumMax) then
      S.NumMax := D;
    Inc(S.NumCnt);
  end
  else if A.Func in [afSum, afAvg] then
    Inc(S.Skipped);
  if A.Func in [afMin, afMax] then
  begin
    if not S.HasMinMax then
    begin
      S.MinV := V;
      S.MaxV := V;
      S.HasMinMax := True;
    end
    else
    begin
      if CompareVals(V, S.MinV, R) and (R < 0) then
        S.MinV := V;
      if CompareVals(V, S.MaxV, R) and (R > 0) then
        S.MaxV := V;
    end;
  end;
end;

{ --- query ------------------------------------------------------------------------ }

constructor TSqlQuery.Create;
begin
  inherited Create;
  Items := TList<TSelItem>.Create;
  GroupBy := TList<TSqlNode>.Create;
  OrderBy := TList<TOrderItem>.Create;
  SetCols := TList<TColNode>.Create;
  SetExprs := TList<TSqlNode>.Create;
  InsCols := TStringList.Create;
  InsRows := TList<TArray<TSqlNode>>.Create;
  Nodes := TObjectList<TSqlNode>.Create(True);
  Cols := TList<TColNode>.Create;
  Aggs := TList<TAggNode>.Create;
  Limit := -1;
  Offset := 0;
end;

destructor TSqlQuery.Destroy;
begin
  Items.Free;
  GroupBy.Free;
  OrderBy.Free;
  SetCols.Free;
  SetExprs.Free;
  InsCols.Free;
  InsRows.Free;
  Cols.Free;
  Aggs.Free;
  Nodes.Free;
  inherited;
end;

{ --- lexer ------------------------------------------------------------------------ }

function Lex(const S: string): TArray<TTok>;
var
  L: TList<TTok>;
  I, N, J: Integer;
  C, Close: Char;
  T: TTok;
  Two: string;
begin
  L := TList<TTok>.Create;
  try
    N := Length(S);
    I := 1;
    while I <= N do
    begin
      C := S[I];
      if C.IsWhiteSpace or (C = #0) then
      begin
        Inc(I);
        Continue;
      end;
      if (C = '-') and (I < N) and (S[I + 1] = '-') then
      begin
        while (I <= N) and (S[I] <> #10) do
          Inc(I);
        Continue;
      end;
      T.P1 := I;
      T.Text := '';
      if C = '''' then
      begin
        T.Kind := tkStr;
        Inc(I);
        while True do
        begin
          if I > N then
            raise ESqlError.Create('text in single quotes is not closed');
          if S[I] = '''' then
          begin
            if (I < N) and (S[I + 1] = '''') then
            begin
              T.Text := T.Text + '''';
              Inc(I, 2);
              Continue;
            end;
            Inc(I);
            Break;
          end;
          T.Text := T.Text + S[I];
          Inc(I);
        end;
      end
      else if CharInSet(C, ['"', '[', '`']) then
      begin
        T.Kind := tkQIdent;
        if C = '[' then
          Close := ']'
        else
          Close := C;
        Inc(I);
        while True do
        begin
          if I > N then
            raise ESqlError.Create('quoted name is not closed');
          if S[I] = Close then
          begin
            if (Close <> ']') and (I < N) and (S[I + 1] = Close) then
            begin
              T.Text := T.Text + Close;
              Inc(I, 2);
              Continue;
            end;
            Inc(I);
            Break;
          end;
          T.Text := T.Text + S[I];
          Inc(I);
        end;
      end
      else if CharInSet(C, ['0'..'9']) or ((C = '.') and (I < N) and CharInSet(S[I + 1], ['0'..'9'])) then
      begin
        T.Kind := tkNum;
        J := I;
        while (I <= N) and CharInSet(S[I], ['0'..'9', '.']) do
          Inc(I);
        if (I < N) and CharInSet(S[I], ['e', 'E']) and
          (CharInSet(S[I + 1], ['0'..'9']) or ((I + 1 < N) and CharInSet(S[I + 1], ['+', '-']) and
          CharInSet(S[I + 2], ['0'..'9']))) then
        begin
          Inc(I, 2);
          while (I <= N) and CharInSet(S[I], ['0'..'9']) do
            Inc(I);
        end;
        T.Text := Copy(S, J, I - J);
      end
      else if C.IsLetter or (C = '_') then
      begin
        T.Kind := tkIdent;
        J := I;
        while (I <= N) and (S[I].IsLetterOrDigit or CharInSet(S[I], ['_', '.'])) do
          Inc(I);
        T.Text := Copy(S, J, I - J);
      end
      else
      begin
        T.Kind := tkSym;
        Two := Copy(S, I, 2);
        if (Two = '<=') or (Two = '>=') or (Two = '<>') or (Two = '!=') or (Two = '==') or (Two = '||') then
        begin
          T.Text := Two;
          Inc(I, 2);
        end
        else if CharInSet(C, ['=', '<', '>', '(', ')', ',', '*', '+', '-', '/', '%', ';']) then
        begin
          T.Text := C;
          Inc(I);
        end
        else
          raise ESqlError.Create('unexpected character "' + C + '"');
      end;
      T.P2 := I - 1;
      L.Add(T);
    end;
    T.Kind := tkEnd;
    T.Text := '';
    T.P1 := N + 1;
    T.P2 := N;
    L.Add(T);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function IsReserved(const S: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(RESERVED) do
    if SameText(S, RESERVED[I]) then
      Exit(True);
  Result := False;
end;

function IsKw(const T: TTok; const K: string): Boolean;
begin
  Result := (T.Kind = tkIdent) and SameText(T.Text, K);
end;

function FindFn(const AName: string; out ADef: TFnDef): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(FNS) do
    if SameText(FNS[I].Name, AName) then
    begin
      ADef := FNS[I];
      Exit(True);
    end;
  Result := False;
end;

{ --- parser ----------------------------------------------------------------------- }

function TSqlParser.Peek(AOfs: Integer): TTok;
begin
  if FI + AOfs <= High(FToks) then
    Result := FToks[FI + AOfs]
  else
    Result := FToks[High(FToks)];
end;

function TSqlParser.Next: TTok;
begin
  Result := Peek;
  if FI < High(FToks) then
    Inc(FI);
end;

function TSqlParser.LastP2: Integer;
begin
  if FI > 0 then
    Result := FToks[FI - 1].P2
  else
    Result := 0;
end;

procedure TSqlParser.Fail(const AMsg: string);
var
  T: TTok;
begin
  T := Peek;
  if T.Kind = tkEnd then
    raise ESqlError.Create(AMsg + ' (at the end of the statement)')
  else
    raise ESqlError.Create(AMsg + ' (near "' + Copy(FQ.Src, T.P1, 40) + '")');
end;

function TSqlParser.PeekKw(const K: string): Boolean;
begin
  Result := IsKw(Peek, K);
end;

function TSqlParser.AcceptKw(const K: string): Boolean;
begin
  Result := PeekKw(K);
  if Result then
    Next;
end;

procedure TSqlParser.ExpectKw(const K: string);
begin
  if not AcceptKw(K) then
    Fail(K + ' expected');
end;

function TSqlParser.PeekSym(const S: string): Boolean;
begin
  Result := (Peek.Kind = tkSym) and (Peek.Text = S);
end;

function TSqlParser.AcceptSym(const S: string): Boolean;
begin
  Result := PeekSym(S);
  if Result then
    Next;
end;

procedure TSqlParser.ExpectSym(const S: string);
begin
  if not AcceptSym(S) then
    Fail('"' + S + '" expected');
end;

function TSqlParser.ParseInt: Int64;
var
  T: TTok;
  D: Double;
begin
  T := Peek;
  if (T.Kind <> tkNum) or not TryStrToFloat(T.Text, D, GFS) or (D < 0) or (D > 1E15) then
    Fail('whole number expected');
  Next;
  Result := Trunc(D);
end;

function TSqlParser.Own(N: TSqlNode): TSqlNode;
begin
  FQ.Nodes.Add(N);
  Result := N;
end;

function TSqlParser.NewCol(const AName: string; AQuoted: Boolean): TColNode;
begin
  Result := TColNode(Own(TColNode.Create));
  Result.Name := AName;
  Result.Quoted := AQuoted;
  Result.Index := COL_UNBOUND;
  FQ.Cols.Add(Result);
end;

function TSqlParser.Bin(AOp: TBinOp; A, B: TSqlNode): TSqlNode;
var
  N: TBinNode;
begin
  N := TBinNode(Own(TBinNode.Create));
  N.Op := AOp;
  N.A := A;
  N.B := B;
  Result := N;
end;

function TSqlParser.NotOf(A: TSqlNode): TSqlNode;
var
  N: TNotNode;
begin
  N := TNotNode(Own(TNotNode.Create));
  N.A := A;
  Result := N;
end;

function TSqlParser.FuncOf(AFn: Integer; const AArgs: array of TSqlNode): TSqlNode;
var
  F: TFuncNode;
  I: Integer;
begin
  F := TFuncNode(Own(TFuncNode.Create));
  F.Fn := AFn;
  SetLength(F.Args, Length(AArgs));
  for I := 0 to High(AArgs) do
    F.Args[I] := AArgs[I];
  Result := F;
end;

function TSqlParser.TableName: string;
var
  T: TTok;
begin
  T := Peek;
  if not (T.Kind in [tkIdent, tkQIdent, tkStr]) or ((T.Kind = tkIdent) and IsReserved(T.Text)) then
    Fail('file name expected');
  Next;
  Result := T.Text;
end;

function TSqlParser.ParseExpr: TSqlNode;
begin
  Result := ParseOr;
end;

function TSqlParser.ParseOr: TSqlNode;
var
  R: TSqlNode;
begin
  Result := ParseAnd;
  while AcceptKw('OR') do
  begin
    R := ParseAnd;
    Result := Bin(boOr, Result, R);
  end;
end;

function TSqlParser.ParseAnd: TSqlNode;
var
  R: TSqlNode;
begin
  Result := ParseNot;
  while AcceptKw('AND') do
  begin
    R := ParseNot;
    Result := Bin(boAnd, Result, R);
  end;
end;

function TSqlParser.ParseNot: TSqlNode;
begin
  if AcceptKw('NOT') then
    Result := NotOf(ParseNot)
  else
    Result := ParseCmp;
end;

function TSqlParser.ParseCmp: TSqlNode;
var
  T: TTok;
  Op: TBinOp;
  Has, Neg: Boolean;
  R, Lo, Hi: TSqlNode;
  InN: TInNode;
  BN: TBetweenNode;
  NN: TIsNullNode;
  L: TList<TSqlNode>;
begin
  Result := ParseAdd;
  T := Peek;
  if T.Kind = tkSym then
  begin
    Has := True;
    Op := boEq;
    if (T.Text = '=') or (T.Text = '==') then
      Op := boEq
    else if (T.Text = '<>') or (T.Text = '!=') then
      Op := boNe
    else if T.Text = '<' then
      Op := boLt
    else if T.Text = '<=' then
      Op := boLe
    else if T.Text = '>' then
      Op := boGt
    else if T.Text = '>=' then
      Op := boGe
    else
      Has := False;
    if Has then
    begin
      Next;
      R := ParseAdd;
      Result := Bin(Op, Result, R);
    end;
    Exit;
  end;
  Neg := False;
  if PeekKw('NOT') and (IsKw(Peek(1), 'LIKE') or IsKw(Peek(1), 'ILIKE') or IsKw(Peek(1), 'IN') or
    IsKw(Peek(1), 'BETWEEN') or IsKw(Peek(1), 'CONTAINS')) then
  begin
    Next;
    Neg := True;
  end;
  if AcceptKw('LIKE') or AcceptKw('ILIKE') then
  begin
    R := ParseAdd;
    if AcceptKw('ESCAPE') then
      ParseAdd;
    Result := Bin(boLike, Result, R);
  end
  else if AcceptKw('CONTAINS') then
  begin
    R := ParseAdd;
    Result := FuncOf(FN_CONTAINS, [Result, R]);
  end
  else if AcceptKw('IN') then
  begin
    ExpectSym('(');
    if PeekKw('SELECT') then
      raise ESqlError.Create('subqueries are not supported: run the inner SELECT first, then use its values');
    InN := TInNode(Own(TInNode.Create));
    InN.A := Result;
    L := TList<TSqlNode>.Create;
    try
      repeat
        L.Add(ParseExpr);
      until not AcceptSym(',');
      InN.Items := L.ToArray;
    finally
      L.Free;
    end;
    ExpectSym(')');
    InN.Neg := Neg;
    Exit(InN);
  end
  else if AcceptKw('BETWEEN') then
  begin
    Lo := ParseAdd;
    ExpectKw('AND');
    Hi := ParseAdd;
    BN := TBetweenNode(Own(TBetweenNode.Create));
    BN.A := Result;
    BN.Lo := Lo;
    BN.Hi := Hi;
    BN.Neg := Neg;
    Exit(BN);
  end
  else if AcceptKw('IS') then
  begin
    NN := TIsNullNode(Own(TIsNullNode.Create));
    NN.A := Result;
    NN.Neg := AcceptKw('NOT');
    ExpectKw('NULL');
    Exit(NN);
  end;
  if Neg then
    Result := NotOf(Result);
end;

function TSqlParser.ParseAdd: TSqlNode;
var
  R: TSqlNode;
begin
  Result := ParseMul;
  while True do
    if AcceptSym('+') then
    begin
      R := ParseMul;
      Result := Bin(boAdd, Result, R);
    end
    else if AcceptSym('-') then
    begin
      R := ParseMul;
      Result := Bin(boSub, Result, R);
    end
    else if AcceptSym('||') then
    begin
      R := ParseMul;
      Result := Bin(boConcat, Result, R);
    end
    else
      Break;
end;

function TSqlParser.ParseMul: TSqlNode;
var
  R: TSqlNode;
begin
  Result := ParseUnary;
  while True do
    if AcceptSym('*') then
    begin
      R := ParseUnary;
      Result := Bin(boMul, Result, R);
    end
    else if AcceptSym('/') then
    begin
      R := ParseUnary;
      Result := Bin(boDiv, Result, R);
    end
    else if AcceptSym('%') then
    begin
      R := ParseUnary;
      Result := Bin(boMod, Result, R);
    end
    else
      Break;
end;

function TSqlParser.ParseUnary: TSqlNode;
var
  N: TNegNode;
begin
  if AcceptSym('-') then
  begin
    N := TNegNode(Own(TNegNode.Create));
    N.A := ParseUnary;
    Result := N;
  end
  else if AcceptSym('+') then
    Result := ParseUnary
  else
    Result := ParsePrimary;
end;

function TSqlParser.ParsePrimary: TSqlNode;
var
  T: TTok;
  U: string;
  Lit: TLitNode;
  D: Double;
begin
  T := Peek;
  case T.Kind of
    tkNum:
      begin
        if not TryStrToFloat(T.Text, D, GFS) then
          Fail('bad number');
        Next;
        Lit := TLitNode(Own(TLitNode.Create));
        Lit.V := VNum(D);
        Result := Lit;
      end;
    tkStr:
      begin
        Next;
        Lit := TLitNode(Own(TLitNode.Create));
        Lit.V := VStr(T.Text);
        Result := Lit;
      end;
    tkQIdent:
      begin
        Next;
        Result := NewCol(T.Text, True);
      end;
    tkSym:
      begin
        if T.Text <> '(' then
          Fail('value or column expected');
        Next;
        if PeekKw('SELECT') then
          raise ESqlError.Create('subqueries are not supported: run the inner SELECT first, then use its values');
        Result := ParseExpr;
        ExpectSym(')');
      end;
    tkIdent:
      begin
        U := UpperCase(T.Text);
        if (Peek(1).Kind = tkSym) and (Peek(1).Text = '(') and (U <> 'IN') then
        begin
          Next;
          if U = 'CAST' then
            Result := ParseCast
          else
            Result := ParseFunc(U, T.P1);
        end
        else if U = 'NULL' then
        begin
          Next;
          Lit := TLitNode(Own(TLitNode.Create));
          Lit.V := VNull;
          Result := Lit;
        end
        else if (U = 'TRUE') or (U = 'FALSE') then
        begin
          Next;
          Lit := TLitNode(Own(TLitNode.Create));
          Lit.V := VBool(U = 'TRUE');
          Result := Lit;
        end
        else if U = 'CASE' then
        begin
          Next;
          Result := ParseCase;
        end
        else if IsReserved(U) then
        begin
          Fail('value or column expected');
          Result := nil;
        end
        else
        begin
          Next;
          Result := NewCol(T.Text, False);
        end;
      end;
  else
    begin
      Fail('value or column expected');
      Result := nil;
    end;
  end;
end;

function TSqlParser.ParseCase: TSqlNode;
var
  C: TCaseNode;
  W, T: TList<TSqlNode>;
begin
  C := TCaseNode(Own(TCaseNode.Create));
  if not PeekKw('WHEN') then
    C.Operand := ParseExpr;
  W := TList<TSqlNode>.Create;
  T := TList<TSqlNode>.Create;
  try
    while AcceptKw('WHEN') do
    begin
      W.Add(ParseExpr);
      ExpectKw('THEN');
      T.Add(ParseExpr);
    end;
    if W.Count = 0 then
      Fail('WHEN expected');
    C.Whens := W.ToArray;
    C.Thens := T.ToArray;
  finally
    W.Free;
    T.Free;
  end;
  if AcceptKw('ELSE') then
    C.ElseN := ParseExpr;
  ExpectKw('END');
  Result := C;
end;

{ CAST(x AS INT | DECIMAL(p,s) | VARCHAR(n) | DATE ...). The opening "(" is next. }
function TSqlParser.ParseCast: TSqlNode;
var
  E: TSqlNode;
  T: TTok;
  U: string;
  Fn: Integer;
begin
  ExpectSym('(');
  E := ParseExpr;
  ExpectKw('AS');
  T := Peek;
  if T.Kind <> tkIdent then
    Fail('type expected after AS');
  Next;
  U := UpperCase(T.Text);
  if MatchText(U, ['INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT', 'SIGNED', 'UNSIGNED']) then
    Fn := FN_INT
  else if MatchText(U, ['DECIMAL', 'NUMERIC', 'REAL', 'FLOAT', 'DOUBLE', 'MONEY', 'NUMBER']) then
    Fn := FN_NUM
  else if MatchText(U, ['CHAR', 'VARCHAR', 'NVARCHAR', 'NCHAR', 'TEXT', 'STRING', 'VARCHAR2']) then
    Fn := FN_TEXT
  else if MatchText(U, ['DATE', 'DATETIME', 'TIMESTAMP']) then
    Fn := FN_DATE
  else
  begin
    Fail('unknown type ' + T.Text);
    Fn := FN_TEXT;
  end;
  AcceptKw('PRECISION');
  if AcceptSym('(') then
  begin
    ParseInt;
    if AcceptSym(',') then
      ParseInt;
    ExpectSym(')');
  end;
  ExpectSym(')');
  Result := FuncOf(Fn, [E]);
end;

{ The function name was read; "(" is next. }
function TSqlParser.ParseFunc(const AName: string; AP1: Integer): TSqlNode;
var
  A: TAggNode;
  Def: TFnDef;
  L: TList<TSqlNode>;
  F: TFuncNode;
begin
  if MatchText(AName, ['COUNT', 'SUM', 'AVG', 'MIN', 'MAX']) then
  begin
    if FNoAgg > 0 then
      raise ESqlError.Create(AName + '() is not allowed in WHERE, GROUP BY, SET or VALUES; filter on aggregates with HAVING');
    if FInAgg > 0 then
      raise ESqlError.Create('an aggregate cannot be inside another aggregate');
    ExpectSym('(');
    A := TAggNode(Own(TAggNode.Create));
    if AName = 'COUNT' then
      A.Func := afCount
    else if AName = 'SUM' then
      A.Func := afSum
    else if AName = 'AVG' then
      A.Func := afAvg
    else if AName = 'MIN' then
      A.Func := afMin
    else
      A.Func := afMax;
    A.Distinct := AcceptKw('DISTINCT');
    if not A.Distinct then
      AcceptKw('ALL');
    if (A.Func = afCount) and AcceptSym('*') then
      A.Arg := nil
    else
    begin
      Inc(FInAgg);
      try
        A.Arg := ParseExpr;
      finally
        Dec(FInAgg);
      end;
    end;
    ExpectSym(')');
    A.Text := Copy(FQ.Src, AP1, LastP2 - AP1 + 1);
    A.Index := FQ.Aggs.Count;
    FQ.Aggs.Add(A);
    Exit(A);
  end;
  if not FindFn(AName, Def) then
    raise ESqlError.Create('unknown function ' + AName + '(). ' + FN_HELP);
  ExpectSym('(');
  L := TList<TSqlNode>.Create;
  try
    if not AcceptSym(')') then
    begin
      repeat
        L.Add(ParseExpr);
      until not AcceptSym(',');
      ExpectSym(')');
    end;
    if (L.Count < Def.MinA) or (L.Count > Def.MaxA) then
      raise ESqlError.CreateFmt('%s() takes %d to %d arguments, got %d', [AName, Def.MinA, Def.MaxA, L.Count]);
    F := TFuncNode(Own(TFuncNode.Create));
    F.Fn := Def.Id;
    F.Args := L.ToArray;
    Result := F;
  finally
    L.Free;
  end;
end;

procedure TSqlParser.ParseSelect;
var
  It: TSelItem;
  T: TTok;
  P1: Integer;
  OI: TOrderItem;
begin
  ExpectKw('SELECT');
  FQ.Kind := askSelect;
  if AcceptKw('DISTINCT') then
    FQ.Distinct := True
  else
    AcceptKw('ALL');
  if AcceptKw('TOP') then
    FQ.Limit := ParseInt;
  repeat
    It := Default(TSelItem);
    if AcceptSym('*') then
      It.Star := True
    else
    begin
      P1 := Peek.P1;
      It.Expr := ParseExpr;
      It.Text := Trim(Copy(FQ.Src, P1, LastP2 - P1 + 1));
      if AcceptKw('AS') then
      begin
        T := Peek;
        if not (T.Kind in [tkIdent, tkQIdent, tkStr]) then
          Fail('name expected after AS');
        Next;
        It.Alias := T.Text;
      end
      else if ((Peek.Kind = tkIdent) and not IsReserved(Peek.Text)) or (Peek.Kind = tkQIdent) then
        It.Alias := Next.Text;
    end;
    FQ.Items.Add(It);
  until not AcceptSym(',');
  if AcceptKw('INTO') then
    raise ESqlError.Create('SELECT INTO is not supported: to save rows to a new file use export_lines with the line_numbers of a SELECT');
  if AcceptKw('FROM') then
  begin
    FQ.FromName := TableName;
    if AcceptKw('AS') then
      TableName
    else if (Peek.Kind = tkIdent) and not IsReserved(Peek.Text) then
      Next;
    if PeekSym(',') or PeekKw('JOIN') or PeekKw('INNER') or PeekKw('LEFT') or PeekKw('RIGHT') or
      PeekKw('FULL') or PeekKw('CROSS') then
      raise ESqlError.Create('JOIN is not supported yet: one file per statement');
  end;
  if AcceptKw('WHERE') then
  begin
    Inc(FNoAgg);
    FQ.Where := ParseExpr;
    Dec(FNoAgg);
  end;
  if AcceptKw('GROUP') then
  begin
    ExpectKw('BY');
    Inc(FNoAgg);
    repeat
      FQ.GroupBy.Add(ParseExpr);
    until not AcceptSym(',');
    Dec(FNoAgg);
  end;
  if AcceptKw('HAVING') then
    FQ.Having := ParseExpr;
  if AcceptKw('ORDER') then
  begin
    ExpectKw('BY');
    repeat
      OI.Expr := ParseExpr;
      OI.Desc := False;
      if AcceptKw('DESC') then
        OI.Desc := True
      else
        AcceptKw('ASC');
      if AcceptKw('NULLS') then
        if not (AcceptKw('FIRST') or AcceptKw('LAST')) then
          Fail('FIRST or LAST expected');
      FQ.OrderBy.Add(OI);
    until not AcceptSym(',');
  end;
  if AcceptKw('LIMIT') then
  begin
    FQ.Limit := ParseInt;
    if AcceptSym(',') then
    begin
      FQ.Offset := FQ.Limit;
      FQ.Limit := ParseInt;
    end
    else if AcceptKw('OFFSET') then
      FQ.Offset := ParseInt;
  end
  else if AcceptKw('OFFSET') then
  begin
    FQ.Offset := ParseInt;
    if not AcceptKw('ROWS') then
      AcceptKw('ROW');
  end;
  if AcceptKw('FETCH') then
  begin
    if not (AcceptKw('FIRST') or AcceptKw('NEXT')) then
      Fail('FIRST expected');
    FQ.Limit := ParseInt;
    if not AcceptKw('ROWS') then
      AcceptKw('ROW');
    AcceptKw('ONLY');
  end;
  if PeekKw('UNION') then
    raise ESqlError.Create('UNION is not supported: send one SELECT per call');
  if FQ.Offset > MAX_OFFSET then
    raise ESqlError.Create('OFFSET above 100000 is not supported');
end;

procedure TSqlParser.ParseUpdate;
var
  T: TTok;
begin
  ExpectKw('UPDATE');
  FQ.Kind := askUpdate;
  if not PeekKw('SET') then
    FQ.FromName := TableName;
  ExpectKw('SET');
  Inc(FNoAgg);
  repeat
    T := Peek;
    if not (T.Kind in [tkIdent, tkQIdent]) then
      Fail('column name expected in SET');
    Next;
    FQ.SetCols.Add(NewCol(T.Text, False));
    ExpectSym('=');
    FQ.SetExprs.Add(ParseExpr);
  until not AcceptSym(',');
  if PeekKw('FROM') then
    raise ESqlError.Create('UPDATE ... FROM is not supported: one file per statement');
  if AcceptKw('WHERE') then
    FQ.Where := ParseExpr;
  Dec(FNoAgg);
end;

procedure TSqlParser.ParseDelete;
begin
  ExpectKw('DELETE');
  FQ.Kind := askDelete;
  AcceptKw('FROM');
  if not PeekKw('WHERE') and (Peek.Kind <> tkEnd) and not PeekSym(';') then
    FQ.FromName := TableName;
  Inc(FNoAgg);
  if AcceptKw('WHERE') then
    FQ.Where := ParseExpr;
  Dec(FNoAgg);
end;

procedure TSqlParser.ParseInsert;
var
  T: TTok;
  L: TList<TSqlNode>;
begin
  ExpectKw('INSERT');
  FQ.Kind := askInsert;
  AcceptKw('INTO');
  if not PeekSym('(') and not PeekKw('VALUES') then
    FQ.FromName := TableName;
  if AcceptSym('(') then
  begin
    repeat
      T := Peek;
      if not (T.Kind in [tkIdent, tkQIdent]) then
        Fail('column name expected');
      Next;
      FQ.InsCols.Add(T.Text);
    until not AcceptSym(',');
    ExpectSym(')');
  end;
  if PeekKw('SELECT') then
    raise ESqlError.Create('INSERT ... SELECT is not supported: use VALUES');
  ExpectKw('VALUES');
  Inc(FNoAgg);
  L := TList<TSqlNode>.Create;
  try
    repeat
      ExpectSym('(');
      L.Clear;
      repeat
        L.Add(ParseExpr);
      until not AcceptSym(',');
      ExpectSym(')');
      FQ.InsRows.Add(L.ToArray);
      if FQ.InsRows.Count > MAX_INSERT_ROWS then
        raise ESqlError.Create('more than 5000 rows in one INSERT');
    until not AcceptSym(',');
  finally
    L.Free;
  end;
  Dec(FNoAgg);
end;

function TSqlParser.ColName(const AWhat: string): string;
var
  T: TTok;
begin
  T := Peek;
  if not (T.Kind in [tkIdent, tkQIdent, tkStr]) then
    Fail(AWhat + ' expected');
  Next;
  Result := T.Text;
end;

{ A text file has no column types: a type after ADD col is read and ignored. }
procedure TSqlParser.ParseAlter;
var
  Depth: Integer;
begin
  ExpectKw('ALTER');
  FQ.Kind := askAlter;
  AcceptKw('TABLE');
  FQ.FromName := TableName;
  if AcceptKw('ADD') then
  begin
    if PeekKw('CONSTRAINT') or PeekKw('PRIMARY') or PeekKw('INDEX') or PeekKw('KEY') or PeekKw('UNIQUE') or
      PeekKw('FOREIGN') then
      raise ESqlError.Create('keys, indexes and constraints do not exist in a text file');
    AcceptKw('COLUMN');
    FQ.AlterOp := ALT_ADD;
    FQ.AlterCol := ColName('new column name');
    while (Peek.Kind <> tkEnd) and not PeekSym(';') do
    begin
      if AcceptKw('DEFAULT') then
      begin
        Inc(FNoAgg);
        FQ.AlterDefault := ParseExpr;
        Dec(FNoAgg);
      end
      else if AcceptKw('FIRST') then
        FQ.AlterFirst := True
      else if AcceptKw('AFTER') then
        FQ.AlterAfter := ColName('column name after AFTER')
      else if AcceptSym('(') then
      begin
        Depth := 1;
        while (Depth > 0) and (Peek.Kind <> tkEnd) do
        begin
          if PeekSym('(') then
            Inc(Depth)
          else if PeekSym(')') then
            Dec(Depth);
          Next;
        end;
      end
      else if Peek.Kind = tkIdent then
        Next
      else
        Fail('DEFAULT, FIRST or AFTER expected');
    end;
  end
  else if AcceptKw('DROP') then
  begin
    AcceptKw('COLUMN');
    FQ.AlterOp := ALT_DROP;
    FQ.AlterCol := ColName('column name');
  end
  else if AcceptKw('RENAME') then
  begin
    if PeekKw('TO') or PeekKw('AS') then
      raise ESqlError.Create('renaming the file is not done by sql; rename it in Windows');
    AcceptKw('COLUMN');
    FQ.AlterOp := ALT_RENAME;
    FQ.AlterCol := ColName('column name');
    ExpectKw('TO');
    FQ.AlterNew := ColName('new column name');
  end
  else if PeekKw('MODIFY') or PeekKw('CHANGE') or PeekKw('ALTER') then
    raise ESqlError.Create('column types do not exist in a text file. To change values use UPDATE; to rename ' +
      'use ALTER TABLE file RENAME COLUMN old TO new')
  else
    Fail('ADD COLUMN, DROP COLUMN or RENAME COLUMN expected');
end;

procedure TSqlParser.ParseTruncate;
begin
  ExpectKw('TRUNCATE');
  FQ.Kind := askDelete;
  AcceptKw('TABLE');
  FQ.FromName := TableName;
end;

function TSqlParser.Parse(const ASql: string): TSqlQuery;
var
  T: TTok;
begin
  FQ := TSqlQuery.Create;
  try
    FQ.Src := ASql;
    FToks := Lex(ASql);
    FI := 0;
    FNoAgg := 0;
    FInAgg := 0;
    T := Peek;
    if IsKw(T, 'SELECT') then
      ParseSelect
    else if IsKw(T, 'UPDATE') then
      ParseUpdate
    else if IsKw(T, 'DELETE') then
      ParseDelete
    else if IsKw(T, 'INSERT') then
      ParseInsert
    else if IsKw(T, 'ALTER') then
      ParseAlter
    else if IsKw(T, 'TRUNCATE') then
      ParseTruncate
    else if IsKw(T, 'WITH') then
      raise ESqlError.Create('WITH is not supported: write one SELECT')
    else if IsKw(T, 'DROP') then
      raise ESqlError.Create('DROP is not supported: the agent does not delete files. To empty the data use ' +
        'TRUNCATE TABLE file; to remove a column use ALTER TABLE file DROP COLUMN col')
    else if IsKw(T, 'CREATE') then
      raise ESqlError.Create('CREATE is not supported: the agent does not create files from sql. To save rows to ' +
        'a new file run a SELECT, then export_lines with its line_numbers')
    else if (T.Kind = tkIdent) and MatchText(T.Text, ['MERGE', 'GRANT', 'REVOKE', 'REPLACE', 'UPSERT',
      'COMMIT', 'ROLLBACK', 'BEGIN', 'EXEC', 'EXECUTE', 'CALL']) then
      raise ESqlError.Create(UpperCase(T.Text) + ' is not supported in a text file. ' +
        'Use SELECT, UPDATE, DELETE, INSERT, ALTER TABLE or TRUNCATE')
    else
      Fail('SELECT, UPDATE, DELETE, INSERT, ALTER TABLE or TRUNCATE expected');
    AcceptSym(';');
    if Peek.Kind <> tkEnd then
      Fail('unexpected text (one statement per sql call)');
    Result := FQ;
  except
    FreeAndNil(FQ);
    raise;
  end;
end;

{ --- run -------------------------------------------------------------------------- }

destructor TSqlGroup.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(Aggs) do
    Aggs[I].Seen.Free;
  inherited;
end;

constructor TSqlRun.Create;
begin
  inherited Create;
  Final := TList<TSelItem>.Create;
  Rows := TList<TSqlRow>.Create;
  Groups := TDictionary<string, TSqlGroup>.Create;
  GroupList := TObjectList<TSqlGroup>.Create(True);
  DistinctSet := TDictionary<string, Boolean>.Create;
  LineNos := TStringBuilder.Create;
  Changes := TList<TAgentSqlChange>.Create;
  Notes := TStringList.Create;
  Skipped := TList<TAgentSqlSkip>.Create;
  FPendText := TStringBuilder.Create;
end;

destructor TSqlRun.Destroy;
begin
  Final.Free;
  Rows.Free;
  Groups.Free;
  GroupList.Free;
  DistinctSet.Free;
  LineNos.Free;
  Changes.Free;
  Notes.Free;
  Skipped.Free;
  FPendText.Free;
  Q.Free;
  inherited;
end;

function TSqlRun.FindName(const AName: string): Integer;
var
  I: Integer;
  N: string;
begin
  for I := 0 to High(Names) do
    if SameText(Names[I], AName) then
      Exit(I);
  N := NormName(AName);
  if N <> '' then
    for I := 0 to High(NormNames) do
      if NormNames[I] = N then
        Exit(I);
  Result := -1;
end;

procedure TSqlRun.Resolve(C: TColNode);
var
  I, K: Integer;
  N: string;
begin
  I := FindName(C.Name);
  if (I < 0) and (Pos('.', C.Name) > 0) then
    I := FindName(Copy(C.Name, LastDelimiter('.', C.Name) + 1, MaxInt));
  if I >= 0 then
  begin
    C.Index := I;
    Exit;
  end;
  N := LowerCase(C.Name);
  if N = 'line' then
  begin
    C.Index := COL_LINE;
    Exit;
  end;
  if (N = 'line_no') or (N = 'line_number') or (N = 'lineno') then
  begin
    C.Index := COL_LINE_NO;
    Exit;
  end;
  if (Length(N) >= 2) and (N[1] = 'c') and TryStrToInt(Copy(N, 2, MaxInt), K) and (K >= 1) then
  begin
    C.Index := K - 1;
    Exit;
  end;
  for I := 0 to Final.Count - 1 do
    if (Final[I].Alias <> '') and (Final[I].Expr <> C) and
      (SameText(Final[I].Alias, C.Name) or (NormName(Final[I].Alias) = NormName(C.Name))) then
    begin
      C.Index := COL_ALIAS;
      C.Target := Final[I].Expr;
      Exit;
    end;
  if C.Quoted then
  begin
    C.Index := COL_TEXT;
    Notes.Add('note="' + C.Name + '" is not a column, so it was read as the text ''' + C.Name +
      '''. Write text values in single quotes.');
    Exit;
  end;
  raise ESqlError.Create('unknown column "' + C.Name + '". Use a name from columns= below, "quoted" when ' +
    'it has spaces, or c1, c2, ... by position. Text values go in single quotes.');
end;

procedure TSqlRun.Setup(const AFirst: string);
var
  I: Integer;
  F: TArray<string>;
  D: Double;
  AllNum: Boolean;
begin
  if DelimArg <> '' then
  begin
    if SameText(DelimArg, 'tab') or (DelimArg = '\t') then
      Delim := #9
    else
      Delim := DelimArg[1];
  end
  else
    Delim := DetectDelim(AFirst);
  if AFirst = '' then
    F := nil
  else
    F := SplitLine(AFirst, Delim, nil);
  if HeaderArg = 1 then
    UseHeader := True
  else if HeaderArg = 0 then
    UseHeader := False
  else
  begin
    { auto: a delimited first line is the header unless it is all numbers }
    AllNum := Length(F) > 0;
    for I := 0 to High(F) do
      if (F[I] <> '') and not TryParseNum(F[I], D) then
      begin
        AllNum := False;
        Break;
      end;
    UseHeader := (Delim <> #0) and (Length(F) > 1) and not AllNum;
  end;
  SetLength(Names, Length(F));
  SetLength(NormNames, Length(F));
  for I := 0 to High(F) do
  begin
    if UseHeader and (F[I] <> '') then
      Names[I] := F[I]
    else
      Names[I] := 'c' + IntToStr(I + 1);
    NormNames[I] := NormName(Names[I]);
  end;
  Bound := True;
  Bind;
end;

procedure TSqlRun.Bind;
var
  I, K: Integer;
  It, NewIt: TSelItem;
  C: TColNode;
  OI: TOrderItem;
  Lit: TLitNode;
begin
  Final.Clear;
  for It in Q.Items do
    if It.Star then
      for I := 0 to High(Names) do
      begin
        C := TColNode.Create;
        Q.Nodes.Add(C);
        C.Name := Names[I];
        C.Index := I;
        NewIt := Default(TSelItem);
        NewIt.Expr := C;
        NewIt.Text := Names[I];
        Final.Add(NewIt);
      end
    else
      Final.Add(It);
  for C in Q.Cols do
    Resolve(C);
  for C in Q.SetCols do
    if (C.Index < 0) and (C.Index <> COL_LINE) then
      raise ESqlError.Create('SET ' + C.Name + ': only file columns (or line) can be assigned');
  if Q.Kind = askAlter then
  begin
    if Delim = #0 then
      raise ESqlError.Create('ALTER TABLE needs a delimited file (CSV, TSV, ...); this file has one column per line');
    AlterIdx := -1;
    if Q.AlterOp in [ALT_DROP, ALT_RENAME] then
    begin
      AlterIdx := FindName(Q.AlterCol);
      if (AlterIdx < 0) and (Length(Q.AlterCol) >= 2) and SameText(Q.AlterCol[1], 'c') and
        TryStrToInt(Copy(Q.AlterCol, 2, MaxInt), K) and (K >= 1) and (K <= Length(Names)) then
        AlterIdx := K - 1;
      if AlterIdx < 0 then
        raise ESqlError.Create('unknown column "' + Q.AlterCol + '". Use a name from columns= below');
      if (Q.AlterOp = ALT_RENAME) and not UseHeader then
        raise ESqlError.Create('this file has no header line, so its columns have no names to rename');
      if (Q.AlterOp = ALT_DROP) and (Length(Names) < 2) then
        raise ESqlError.Create('the file has only one column; it cannot be dropped');
    end
    else
    begin
      if UseHeader and (FindName(Q.AlterCol) >= 0) then
        raise ESqlError.Create('column "' + Q.AlterCol + '" already exists');
      if Q.AlterFirst then
        AlterIdx := 0
      else if Q.AlterAfter <> '' then
      begin
        K := FindName(Q.AlterAfter);
        if K < 0 then
          raise ESqlError.Create('unknown column "' + Q.AlterAfter + '" after AFTER');
        AlterIdx := K + 1;
        if AlterIdx >= Length(Names) then
          AlterIdx := -1;
      end;
      if not UseHeader then
        Notes.Add('note=the file has no header line: the new column has no name and is filled with the DEFAULT value');
    end;
  end;
  for I := 0 to Q.OrderBy.Count - 1 do
    if Q.OrderBy[I].Expr is TLitNode then
    begin
      Lit := TLitNode(Q.OrderBy[I].Expr);
      K := Trunc(Lit.V.Num);
      if (Lit.V.Kind = skNum) and (K >= 1) and (K <= Final.Count) then
      begin
        OI := Q.OrderBy[I];
        OI.Expr := Final[K - 1].Expr;
        Q.OrderBy[I] := OI;
      end;
    end;
  for I := 0 to Q.GroupBy.Count - 1 do
    if Q.GroupBy[I] is TLitNode then
    begin
      Lit := TLitNode(Q.GroupBy[I]);
      K := Trunc(Lit.V.Num);
      if (Lit.V.Kind = skNum) and (K >= 1) and (K <= Final.Count) then
        Q.GroupBy[I] := Final[K - 1].Expr;
    end;
  HasAgg := (Q.Kind = askSelect) and ((Q.Aggs.Count > 0) or (Q.GroupBy.Count > 0));
  if (Q.Limit >= 0) and (Q.Limit < MaxRows) then
    Keep := Q.Offset + Q.Limit
  else
    Keep := Q.Offset + MaxRows;
end;

function TSqlRun.EvalRow(const E: TSqlEnv; ASeq: Int64): TSqlRow;
var
  I: Integer;
begin
  SetLength(Result.Vals, Final.Count);
  for I := 0 to Final.Count - 1 do
    Result.Vals[I] := Final[I].Expr.Eval(E);
  SetLength(Result.Keys, Q.OrderBy.Count);
  for I := 0 to Q.OrderBy.Count - 1 do
    Result.Keys[I] := Q.OrderBy[I].Expr.Eval(E);
  Result.Seq := ASeq;
end;

function TSqlRun.CompareRows(const A, B: TSqlRow): Integer;
var
  I: Integer;
begin
  for I := 0 to Q.OrderBy.Count - 1 do
  begin
    Result := SortCompare(A.Keys[I], B.Keys[I], Q.OrderBy[I].Desc);
    if Result <> 0 then
      Exit;
  end;
  Result := CompareValue(A.Seq, B.Seq);
end;

procedure TSqlRun.AddTopK(const R: TSqlRow);
var
  Lo, Hi, Mid: Integer;
begin
  if Keep <= 0 then Exit;
  if (Rows.Count >= Keep) and (CompareRows(R, Rows[Rows.Count - 1]) >= 0) then Exit;
  Lo := 0;
  Hi := Rows.Count;
  while Lo < Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if CompareRows(Rows[Mid], R) <= 0 then
      Lo := Mid + 1
    else
      Hi := Mid;
  end;
  Rows.Insert(Lo, R);
  if Rows.Count > Keep then
    Rows.Delete(Rows.Count - 1);
end;

function TSqlRun.QuoteField(const S: string; AWasQuoted: Boolean): string;
begin
  if AWasQuoted or (Pos('"', S) > 0) or ((Delim <> #0) and (Pos(Delim, S) > 0)) or
    (S <> Trim(S)) then
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := S;
end;

{ SET values are computed on the old row; only the assigned fields are rewritten. }
function TSqlRun.UpdatedLine(const ALine: string; const E: TSqlEnv; const ASpans: TFieldSpans): string;
var
  Vals: TArray<string>;
  Idx: TArray<Integer>;
  I, J, K, MaxIdx, FieldCount: Integer;
  Tail: string;
  Found: Boolean;
begin
  SetLength(Vals, Q.SetCols.Count);
  SetLength(Idx, Q.SetCols.Count);
  for I := 0 to Q.SetCols.Count - 1 do
  begin
    Vals[I] := ToText(Q.SetExprs[I].Eval(E));
    Idx[I] := Q.SetCols[I].Index;
    if Idx[I] = COL_LINE then
      Exit(Vals[I]);
  end;
  { a later assignment to the same column wins }
  for I := 0 to High(Idx) do
    for J := I + 1 to High(Idx) do
      if Idx[J] = Idx[I] then
        Idx[I] := -1;
  Result := ALine;
  FieldCount := Length(ASpans.Starts);
  MaxIdx := -1;
  for I := 0 to High(Idx) do
    if Idx[I] > MaxIdx then
      MaxIdx := Idx[I];
  { fields beyond the end of the line: appended after the replacements }
  Tail := '';
  for K := FieldCount to MaxIdx do
  begin
    Found := False;
    for I := 0 to High(Idx) do
      if Idx[I] = K then
      begin
        Tail := Tail + Delim + QuoteField(Vals[I], False);
        Found := True;
      end;
    if not Found then
      Tail := Tail + Delim;
  end;
  { right to left, so the earlier spans stay valid }
  for K := FieldCount - 1 downto 0 do
    for I := 0 to High(Idx) do
      if Idx[I] = K then
        Result := Copy(Result, 1, ASpans.Starts[K] - 1) + QuoteField(Vals[I], ASpans.Quoted[K]) +
          Copy(Result, ASpans.Ends[K], MaxInt);
  Result := Result + Tail;
end;

procedure TSqlRun.FlushChange;
var
  C: TAgentSqlChange;
begin
  if FPend = 0 then Exit;
  if Changes.Count >= MAX_CHANGE_BLOCKS then
    raise ESqlError.Create('the change touches more than 2000 separate blocks of lines; narrow the WHERE, ' +
      'or use replace_all for a plain text replacement');
  C.LineStart := FPendStart;
  C.LineEnd := FPendEnd;
  if Q.Kind = askDelete then
    C.Text := ''
  else
    C.Text := FPendText.ToString;
  Changes.Add(C);
  FPend := 0;
end;

procedure TSqlRun.AddChange(ALineNo: Int64; const AText: string);
begin
  if (FPend > 0) and (ALineNo = FPendEnd + 1) and (FPend < BLOCK_LINES) then
  begin
    FPendEnd := ALineNo;
    Inc(FPend);
    if Q.Kind <> askDelete then
      FPendText.Append(#10).Append(AText);
  end
  else
  begin
    FlushChange;
    FPendStart := ALineNo;
    FPendEnd := ALineNo;
    FPend := 1;
    FPendText.Clear;
    if Q.Kind <> askDelete then
      FPendText.Append(AText);
  end;
  Inc(ChangedLines);
  if ChangedLines > MAX_CHANGED_LINES then
    raise ESqlError.Create('the change touches more than 200000 lines; narrow the WHERE');
end;

{ New field AText at AlterIdx; after the last column of the header when AlterIdx = -1 (short lines are padded). }
function TSqlRun.InsertField(const ALine: string; const ASpans: TFieldSpans; const AText: string): string;
var
  FC, Target, K: Integer;
begin
  FC := Length(ASpans.Starts);
  if (AlterIdx >= 0) and (AlterIdx < FC) then
    Exit(Copy(ALine, 1, ASpans.Starts[AlterIdx] - 1) + AText + Delim + Copy(ALine, ASpans.Starts[AlterIdx], MaxInt));
  if AlterIdx >= 0 then
    Target := AlterIdx
  else
    Target := Max(FC, Length(Names));
  Result := ALine;
  for K := FC to Target - 1 do
    Result := Result + Delim;
  Result := Result + Delim + AText;
end;

function TSqlRun.RemoveField(const ALine: string; const ASpans: TFieldSpans): string;
var
  FC: Integer;
begin
  FC := Length(ASpans.Starts);
  if AlterIdx >= FC then
    Exit(ALine);
  if FC = 1 then
    Exit('');
  if AlterIdx = 0 then
    Result := Copy(ALine, ASpans.Ends[0] + 1, MaxInt)
  else
    Result := Copy(ALine, 1, ASpans.Ends[AlterIdx - 1] - 1) + Copy(ALine, ASpans.Ends[AlterIdx], MaxInt);
end;

procedure TSqlRun.ProcessHeader(const ALine: string; ALineNo: Int64);
var
  Spans: TFieldSpans;
  NewLine: string;
begin
  if Q.Kind <> askAlter then Exit;
  SplitLine(ALine, Delim, @Spans);
  case Q.AlterOp of
    ALT_ADD: NewLine := InsertField(ALine, Spans, QuoteField(Q.AlterCol, False));
    ALT_DROP: NewLine := RemoveField(ALine, Spans);
  else
    NewLine := Copy(ALine, 1, Spans.Starts[AlterIdx] - 1) + QuoteField(Q.AlterNew, Spans.Quoted[AlterIdx]) +
      Copy(ALine, Spans.Ends[AlterIdx], MaxInt);
  end;
  if NewLine <> ALine then
    AddChange(ALineNo, NewLine);
end;

procedure TSqlRun.ProcessAlterRow(const ALine: string; ALineNo: Int64);
var
  E: TSqlEnv;
  Spans: TFieldSpans;
  NewLine, V: string;
begin
  Inc(Scanned);
  Inc(Matched);
  if Q.AlterOp = ALT_RENAME then Exit;
  E.Fields := SplitLine(ALine, Delim, @Spans);
  E.LineNo := ALineNo;
  E.Line := ALine;
  E.Aggs := nil;
  if Q.AlterOp = ALT_ADD then
  begin
    if Q.AlterDefault <> nil then
      V := ToText(Q.AlterDefault.Eval(E))
    else
      V := '';
    NewLine := InsertField(ALine, Spans, QuoteField(V, False));
  end
  else
    NewLine := RemoveField(ALine, Spans);
  if NewLine <> ALine then
    AddChange(ALineNo, NewLine);
end;

procedure TSqlRun.ProcessRow(const ALine: string; ALineNo: Int64);
var
  E: TSqlEnv;
  Spans: TFieldSpans;
  Key, NewLine: string;
  G: TSqlGroup;
  R: TSqlRow;
  I: Integer;
begin
  if Q.Kind = askInsert then Exit;
  if Q.Kind = askAlter then
  begin
    ProcessAlterRow(ALine, ALineNo);
    Exit;
  end;
  if Q.Kind = askUpdate then
    E.Fields := SplitLine(ALine, Delim, @Spans)
  else
    E.Fields := SplitLine(ALine, Delim, nil);
  E.LineNo := ALineNo;
  E.Line := ALine;
  E.Aggs := nil;
  Inc(Scanned);
  if (Q.Where <> nil) and not Truthy(Q.Where.Eval(E)) then Exit;
  Inc(Matched);
  if (Q.Where <> nil) or not HasAgg then
  begin
    Inc(LineNoCount);
    if LineNoCount <= MAX_LINE_NUMBERS then
    begin
      if LineNos.Length > 0 then
        LineNos.Append(',');
      LineNos.Append(ALineNo);
    end;
  end;
  case Q.Kind of
    askDelete:
      begin
        AddChange(ALineNo, '');
        Exit;
      end;
    askUpdate:
      begin
        NewLine := UpdatedLine(ALine, E, Spans);
        if NewLine <> ALine then
          AddChange(ALineNo, NewLine);
        Exit;
      end;
  end;
  if HasAgg then
  begin
    Key := '';
    for I := 0 to Q.GroupBy.Count - 1 do
      Key := Key + ValKey(Q.GroupBy[I].Eval(E)) + #1;
    if not Groups.TryGetValue(Key, G) then
    begin
      if Groups.Count >= MAX_GROUPS then
        raise ESqlError.Create('more than 500000 groups; group by a column with fewer distinct values or add a WHERE');
      G := TSqlGroup.Create;
      G.Fields := E.Fields;
      G.LineNo := ALineNo;
      G.Line := ALine;
      SetLength(G.Aggs, Q.Aggs.Count);
      G.Seq := Groups.Count;
      GroupList.Add(G);
      Groups.Add(Key, G);
    end;
    for I := 0 to Q.Aggs.Count - 1 do
      UpdateAgg(G.Aggs[I], Q.Aggs[I], E);
    Exit;
  end;
  if Q.Distinct then
  begin
    R := EvalRow(E, Seq);
    Key := '';
    for I := 0 to High(R.Vals) do
      Key := Key + ValKey(R.Vals[I]) + #1;
    if DistinctSet.ContainsKey(Key) then Exit;
    if DistinctSet.Count >= MAX_DISTINCT then
      raise ESqlError.Create('more than 2000000 distinct rows; add a WHERE or select fewer columns');
    DistinctSet.Add(Key, True);
    Inc(Seq);
    Inc(ResultCount);
    if Q.OrderBy.Count = 0 then
    begin
      if Rows.Count < Keep then
        Rows.Add(R);
    end
    else
      AddTopK(R);
    Exit;
  end;
  Inc(ResultCount);
  if Q.OrderBy.Count = 0 then
  begin
    if Rows.Count < Keep then
      Rows.Add(EvalRow(E, Seq));
  end
  else
    AddTopK(EvalRow(E, Seq));
  Inc(Seq);
end;

procedure TSqlRun.Finish;
var
  G: TSqlGroup;
  E: TSqlEnv;
  I, K, Idx: Integer;
  Vals: TArray<string>;
  Line: string;
  Lines: TStringBuilder;
  C: TAgentSqlChange;
  Empty: TSqlEnv;
  Shown: Int64;
  Skip: TAgentSqlSkip;
begin
  if Q.Kind in [askUpdate, askDelete, askAlter] then
  begin
    FlushChange;
    Exit;
  end;
  if Q.Kind = askInsert then
  begin
    Empty := Default(TSqlEnv);
    Lines := TStringBuilder.Create;
    try
      for I := 0 to Q.InsRows.Count - 1 do
      begin
        if (Q.InsCols.Count > 0) and (Length(Q.InsRows[I]) <> Q.InsCols.Count) then
          raise ESqlError.CreateFmt('VALUES row %d has %d values for %d columns', [I + 1, Length(Q.InsRows[I]),
            Q.InsCols.Count]);
        if Delim = #0 then
        begin
          if Length(Q.InsRows[I]) <> 1 then
            raise ESqlError.Create('this file has no delimiter: each VALUES row is one line, one value');
          Line := ToText(Q.InsRows[I][0].Eval(Empty));
        end
        else
        begin
          K := Length(Names);
          if Q.InsCols.Count = 0 then
          begin
            if (K > 0) and (Length(Q.InsRows[I]) > K) then
              raise ESqlError.CreateFmt('VALUES row %d has %d values; the file has %d columns',
                [I + 1, Length(Q.InsRows[I]), K]);
            K := Max(K, Length(Q.InsRows[I]));
          end;
          SetLength(Vals, K);
          for Idx := 0 to K - 1 do
            Vals[Idx] := '';
          if Q.InsCols.Count = 0 then
            for Idx := 0 to High(Q.InsRows[I]) do
              Vals[Idx] := QuoteField(ToText(Q.InsRows[I][Idx].Eval(Empty)), False)
          else
            for Idx := 0 to Q.InsCols.Count - 1 do
            begin
              K := FindName(Q.InsCols[Idx]);
              if K < 0 then
                raise ESqlError.Create('unknown column "' + Q.InsCols[Idx] + '" in INSERT');
              Vals[K] := QuoteField(ToText(Q.InsRows[I][Idx].Eval(Empty)), False);
            end;
          Line := string.Join(Delim, Vals);
        end;
        if I > 0 then
          Lines.Append(#10);
        Lines.Append(Line);
      end;
      C.LineStart := LastDataLine + 1;
      C.LineEnd := C.LineStart - 1;
      C.Text := Lines.ToString;
      Changes.Add(C);
      ChangedLines := Q.InsRows.Count;
    finally
      Lines.Free;
    end;
    Exit;
  end;
  if HasAgg then
  begin
    if (Q.GroupBy.Count = 0) and (GroupList.Count = 0) then
    begin
      G := TSqlGroup.Create;
      SetLength(G.Aggs, Q.Aggs.Count);
      GroupList.Add(G);
    end;
    Rows.Clear;
    for G in GroupList do
    begin
      E.Fields := G.Fields;
      E.LineNo := G.LineNo;
      E.Line := G.Line;
      E.Aggs := G.Aggs;
      if (Q.Having <> nil) and not Truthy(Q.Having.Eval(E)) then
        Continue;
      Inc(ResultCount);
      Rows.Add(EvalRow(E, G.Seq));
    end;
    for I := 0 to Q.Aggs.Count - 1 do
    begin
      Shown := 0;
      for G in GroupList do
        Inc(Shown, G.Aggs[I].Skipped);
      if Shown > 0 then
      begin
        Notes.Add('note=' + Q.Aggs[I].Text + ': ' + IntToStr(Shown) +
          ' value(s) were not numbers and were left out');
        Skip.Expr := Q.Aggs[I].Text;
        Skip.Count := Shown;
        Skipped.Add(Skip);
      end;
    end;
    if Q.OrderBy.Count > 0 then
      Rows.Sort(TComparer<TSqlRow>.Construct(
        function(const L, R: TSqlRow): Integer
        begin
          Result := CompareRows(L, R);
        end));
  end;
  if Q.Offset > 0 then
  begin
    if Q.Offset >= Rows.Count then
      Rows.Clear
    else
      Rows.DeleteRange(0, Integer(Q.Offset));
  end;
  if (Q.Limit >= 0) and (Rows.Count > Q.Limit) then
    Rows.DeleteRange(Integer(Q.Limit), Rows.Count - Integer(Q.Limit));
  if Rows.Count > MaxRows then
    Rows.DeleteRange(MaxRows, Rows.Count - MaxRows);
end;

{ --- tool ------------------------------------------------------------------------- }

procedure SqlVisit(ALine: PAnsiChar; ALen: Integer; ALineNo: Int64; var AStop: Boolean; AUser: Pointer);
var
  Run: TSqlRun;
  Raw: AnsiString;
  S: string;
begin
  Run := TSqlRun(AUser);
  if Assigned(Run.Cancel) and (Run.Cancel^ <> 0) then
  begin
    Run.Stopped := True;
    AStop := True;
    Exit;
  end;
  if (ALine = nil) or (ALen <= 0) then
    S := ''
  else
  begin
    SetString(Raw, ALine, ALen);
    S := FileBytesToUnicodeText(AlignWideLine(Raw, Run.Enc), Run.Enc);
  end;
  while (S <> '') and CharInSet(S[Length(S)], [#10, #13]) do
    SetLength(S, Length(S) - 1);
  if (S <> '') and (S[1] = #$FEFF) then
    Delete(S, 1, 1);
  if Trim(S) = '' then Exit;
  Run.LastDataLine := ALineNo;
  try
    if not Run.Bound then
    begin
      Run.Setup(S);
      if Run.UseHeader then
      begin
        Run.ProcessHeader(S, ALineNo);
        Exit;
      end;
    end;
    Run.ProcessRow(S, ALineNo);
  except
    on E: Exception do
    begin
      Run.Err := E.Message;
      AStop := True;
    end;
  end;
end;

function OneLine(const S: string): string;
begin
  Result := StringReplace(StringReplace(Trim(S), #13#10, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
end;

function CellText(const V: TSqlVal): string;
begin
  Result := OneLine(ToText(V));
  if Length(Result) > CELL_CHARS then
    Result := Copy(Result, 1, CELL_CHARS) + '...';
end;

function DelimText(D: Char): string;
begin
  case D of
    #0: Result := 'none (one column per line: line)';
    #9: Result := 'tab';
  else
    Result := '"' + D + '"';
  end;
end;

function ColumnsText(Run: TSqlRun): string;
var
  I: Integer;
begin
  Result := IntToStr(Length(Run.Names)) + ': ';
  for I := 0 to High(Run.Names) do
  begin
    if I > 0 then
      Result := Result + ' | ';
    Result := Result + Run.Names[I];
    if Length(Result) > 3000 then
    begin
      Result := Result + ' | ...';
      Break;
    end;
  end;
end;

const
  SQL_HELP = 'note=dialect: SELECT [DISTINCT] cols FROM file [WHERE ..] [GROUP BY ..] [HAVING ..] ' +
    '[ORDER BY .. DESC] [LIMIT n]; UPDATE file SET col = .. WHERE ..; DELETE FROM file WHERE ..; ' +
    'INSERT INTO file (cols) VALUES (..); ALTER TABLE file ADD COLUMN c [DEFAULT ..] | DROP COLUMN c | ' +
    'RENAME COLUMN c TO d; TRUNCATE TABLE file. Text in single quotes, names with spaces in "double quotes". ' +
    'No JOIN, UNION or subqueries.';

function AgentToolSql(const APath, ASql, ADelimiter: string; AHeader, AMaxRows: Integer;
  ACancelFlag: PInteger): TAgentSqlResult;
var
  P: TSqlParser;
  Run: TSqlRun;
  SL, Tbl: TStringList;
  I, J: Integer;
  H, Row: string;
  KindName: string;
begin
  Result := Default(TAgentSqlResult);
  Result.Sql := Trim(ASql);
  while (Result.Sql <> '') and (Result.Sql[Length(Result.Sql)] = ';') do
    Result.Sql := TrimRight(Copy(Result.Sql, 1, Length(Result.Sql) - 1));
  if Result.Sql = '' then
  begin
    Result.Text := 'error=empty sql. Send {"tool":"sql","path":"<path>","sql":"SELECT ..."}';
    Exit;
  end;
  if not FileExists(APath) then
  begin
    Result.Text := 'error=file not found path=' + APath;
    Exit;
  end;
  if AMaxRows < 1 then
    AMaxRows := 1;
  Run := TSqlRun.Create;
  SL := TStringList.Create;
  Tbl := TStringList.Create;
  try
    P := TSqlParser.Create;
    try
      try
        Run.Q := P.Parse(Result.Sql);
      except
        on E: Exception do
        begin
          Result.Text := 'error=sql: ' + E.Message + #13#10 + 'sql=' + OneLine(Result.Sql) + #13#10 + SQL_HELP;
          Exit;
        end;
      end;
    finally
      P.Free;
    end;
    Result.Kind := Run.Q.Kind;
    Run.Enc := DetectTextFileEncoding(APath);
    Run.DelimArg := ADelimiter;
    Run.HeaderArg := AHeader;
    Run.Cancel := ACancelFlag;
    Run.MaxRows := AMaxRows;
    try
      FastFileForEachRawLine(APath, SqlVisit, Run);
      if (Run.Err = '') and not Run.Stopped then
      begin
        if not Run.Bound then
          Run.Setup('');
        Run.Finish;
      end;
    except
      on E: Exception do
        Run.Err := E.Message;
    end;
    case Run.Q.Kind of
      askUpdate: KindName := 'update';
      askDelete: KindName := 'delete';
      askInsert: KindName := 'insert';
      askAlter: KindName := 'alter';
    else
      KindName := 'select';
    end;
    SL.Add('statement=' + KindName);
    SL.Add('sql=' + OneLine(Result.Sql));
    SL.Add('path=' + APath);
    if Run.Bound then
    begin
      if Run.UseHeader then
        SL.Add('delimiter=' + DelimText(Run.Delim) + ' header=yes (first line, never changed)')
      else
        SL.Add('delimiter=' + DelimText(Run.Delim) + ' header=no (columns are c1, c2, ...)');
      SL.Add('columns=' + ColumnsText(Run));
    end;
    if Run.Err <> '' then
    begin
      Result.Text := 'error=sql: ' + Run.Err + #13#10 + SL.Text + SQL_HELP;
      Exit;
    end;
    if Run.Stopped then
    begin
      Result.Text := 'error=stopped by the user' + #13#10 + SL.Text;
      Exit;
    end;
    SL.Add('rows_scanned=' + IntToStr(Run.Scanned) + ' rows_matching_where=' + IntToStr(Run.Matched));
    if Run.Q.Kind = askSelect then
    begin
      H := '';
      for I := 0 to Run.Final.Count - 1 do
      begin
        if I > 0 then
          H := H + ' | ';
        if Run.Final[I].Alias <> '' then
          H := H + Run.Final[I].Alias
        else
          H := H + Run.Final[I].Text;
      end;
      Tbl.Add(H);
      for I := 0 to Run.Rows.Count - 1 do
      begin
        Row := '';
        for J := 0 to High(Run.Rows[I].Vals) do
        begin
          if J > 0 then
            Row := Row + ' | ';
          Row := Row + CellText(Run.Rows[I].Vals[J]);
        end;
        Tbl.Add(Row);
      end;
      Result.TotalRows := Run.ResultCount;
      Result.ShownRows := Run.Rows.Count;
      SL.Add('result_rows=' + IntToStr(Run.ResultCount) + ' shown=' + IntToStr(Run.Rows.Count));
      SL.Add('result (columns separated by " | "):');
      for I := 0 to Tbl.Count - 1 do
      begin
        if I > MODEL_ROWS then
        begin
          SL.Add('... ' + IntToStr(Tbl.Count - 1 - MODEL_ROWS) + ' more row(s) not shown to you; the user sees them');
          Break;
        end;
        SL.Add(Tbl[I]);
      end;
      Result.Table := TrimRight(Tbl.Text);
    end
    else
    begin
      Result.Changes := Run.Changes.ToArray;
      Result.ChangedLines := Run.ChangedLines;
      SL.Add('lines_changed=' + IntToStr(Run.ChangedLines) + ' blocks=' + IntToStr(Run.Changes.Count));
      if Run.Q.Kind = askInsert then
        SL.Add('insert_before_line=' + IntToStr(Run.LastDataLine + 1) + ' (end of the file)');
    end;
    if (Run.LineNoCount > 0) and ((Run.Q.Where <> nil) or not Run.HasAgg) then
    begin
      SL.Add('line_numbers=' + Run.LineNos.ToString);
      if Run.LineNoCount > MAX_LINE_NUMBERS then
        SL.Add('note=only the first ' + IntToStr(MAX_LINE_NUMBERS) + ' of ' + IntToStr(Run.LineNoCount) +
          ' line numbers are listed');
    end;
    for I := 0 to Run.Notes.Count - 1 do
      SL.Add(Run.Notes[I]);
    Result.Skipped := Run.Skipped.ToArray;
    Result.HasWhere := Run.Q.Where <> nil;
    Result.MatchedRows := Run.Matched;
    Result.Ok := True;
    Result.Text := TrimRight(SL.Text);
  finally
    Tbl.Free;
    SL.Free;
    Run.Free;
  end;
end;

function AgentSqlFromName(const ASql: string): string;
var
  P: TSqlParser;
  Q: TSqlQuery;
begin
  Result := '';
  P := TSqlParser.Create;
  try
    try
      Q := P.Parse(ASql);
      try
        Result := Q.FromName;
      finally
        Q.Free;
      end;
    except
      Result := '';
    end;
  finally
    P.Free;
  end;
end;

function AgentSqlStartsLikeSql(const AText: string): Boolean;
var
  S: string;
  I: Integer;
begin
  S := TrimLeft(AText);
  I := 1;
  while (I <= Length(S)) and CharInSet(S[I], ['A'..'Z', 'a'..'z']) do
    Inc(I);
  Result := (I <= Length(S)) and MatchText(Copy(S, 1, I - 1), ['SELECT', 'UPDATE', 'DELETE', 'INSERT', 'ALTER',
    'TRUNCATE', 'WITH', 'DROP', 'CREATE']);
end;

function AgentSqlParses(const ASql: string; out AErr: string): Boolean;
var
  P: TSqlParser;
begin
  AErr := '';
  P := TSqlParser.Create;
  try
    try
      P.Parse(ASql).Free;
      Result := True;
    except
      on E: Exception do
      begin
        AErr := E.Message;
        Result := False;
      end;
    end;
  finally
    P.Free;
  end;
end;

initialization
  GFS := TFormatSettings.Create;
  GFS.DecimalSeparator := '.';
  GFS.ThousandSeparator := ',';

end.
