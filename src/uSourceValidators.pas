unit uSourceValidators;

{
  Source validation that does not need the ScriptEngine / CodeCheck companions:
  - JSON, HTML and SQL are checked in-process (structure only);
  - Java, Go and C# use the compiler already installed on this PC (javac, gofmt, csc).
  Nothing here runs the user's code. Messages: SrcVal.* in uI18n.
}

interface

type
  TSourceToolKind = (stkJavac, stkGofmt, stkCsc);

{ JSON / HTML / SQL / Java / Go / C#. AHandled = False: not one of these (the caller uses
  its own validator). AHandled = True: the result and the report are final. }
function ValidateSourceBuiltIn(const APath: string; out AHandled: Boolean; out AReport: string): Boolean;
{ False only for Java / Go / C# when their compiler is not installed on this PC. }
function SourceValidatorAvailable(const APath: string): Boolean;
{ Full path of the compiler found on this PC, or ''. }
function FindSourceTool(AKind: TSourceToolKind): string;
{ csc.exe of the .NET Framework (C# 5 only), not the Roslyn one of Visual Studio. }
function IsLegacyCsc(const ACscPath: string): Boolean;
function SourceToolName(AKind: TSourceToolKind): string;
{ "<tool> was not found..." plus how to install it. }
function SourceToolMissingText(AKind: TSourceToolKind): string;

implementation

uses
  Windows, SysUtils, Classes, Forms, IOUtils, StrUtils, uI18n, UnConsts;

const
  JSON_MAX_DEPTH = 1000;

function IsValidUtf8(const B: TBytes; AStart: Integer): Boolean;
var
  I, N, Need: Integer;
  C: Byte;
begin
  Result := False;
  I := AStart;
  N := Length(B);
  while I < N do
  begin
    C := B[I];
    if C < $80 then
      Need := 0
    else if (C and $E0) = $C0 then
      Need := 1
    else if (C and $F0) = $E0 then
      Need := 2
    else if (C and $F8) = $F0 then
      Need := 3
    else
      Exit;
    Inc(I);
    while Need > 0 do
    begin
      if (I >= N) or ((B[I] and $C0) <> $80) then Exit;
      Inc(I);
      Dec(Need);
    end;
  end;
  Result := True;
end;

function DecodeBytes(const B: TBytes): string;
var
  Enc: TEncoding;
  Skip: Integer;
begin
  Enc := nil;
  Skip := TEncoding.GetBufferEncoding(B, Enc);
  if (Skip = 0) and IsValidUtf8(B, 0) then
    Enc := TEncoding.UTF8;
  Result := Enc.GetString(B, Skip, Length(B) - Skip);
end;

function LoadSourceText(const APath: string): string;
begin
  Result := DecodeBytes(TFile.ReadAllBytes(APath));
end;

procedure LineColAt(const S: string; AIdx: Integer; out ALine, ACol: Integer);
var
  I: Integer;
begin
  ALine := 1;
  ACol := 1;
  if AIdx > Length(S) + 1 then
    AIdx := Length(S) + 1;
  for I := 1 to AIdx - 1 do
    if S[I] = #10 then
    begin
      Inc(ALine);
      ACol := 1;
    end
    else if S[I] <> #13 then
      Inc(ACol);
end;

function LineAt(const S: string; AIdx: Integer): Integer;
var
  C: Integer;
begin
  LineColAt(S, AIdx, Result, C);
end;

function AtPos(const S: string; AIdx: Integer; const AMsg: string): string;
var
  L, C: Integer;
begin
  LineColAt(S, AIdx, L, C);
  Result := Format(TrText('SrcVal.LineCol'), [L, C, AMsg]);
end;

{ ---------------------------------------------------------------- JSON }

function CheckJson(const S: string; out AErr: string): Boolean;
var
  P, N, ErrPos: Integer;
  Msg: string;

  function Fail(APos: Integer; const AMsg: string): Boolean;
  begin
    if Msg = '' then
    begin
      ErrPos := APos;
      Msg := AMsg;
    end;
    Result := False;
  end;

  function Unexpected: Boolean;
  begin
    if P > N then
      Result := Fail(P, TrText('SrcVal.Json.UnexpectedEnd'))
    else
      Result := Fail(P, Format(TrText('SrcVal.Json.Unexpected'), [string(S[P])]));
  end;

  function Expected(const AWhat: string): Boolean;
  begin
    if P > N then
      Result := Fail(P, TrText('SrcVal.Json.UnexpectedEnd'))
    else
      Result := Fail(P, Format(TrText('SrcVal.Json.Expected'), [AWhat, string(S[P])]));
  end;

  procedure SkipWs;
  begin
    while (P <= N) and CharInSet(S[P], [' ', #9, #10, #13]) do
      Inc(P);
  end;

  function IsHex4(AFrom: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := AFrom + 3 <= N;
    if not Result then Exit;
    for I := AFrom to AFrom + 3 do
      if not CharInSet(S[I], ['0'..'9', 'a'..'f', 'A'..'F']) then
        Exit(False);
  end;

  function ParseString: Boolean;
  var
    Start: Integer;
  begin
    Start := P;
    Inc(P);
    while P <= N do
    begin
      case S[P] of
        '"':
          begin
            Inc(P);
            Exit(True);
          end;
        '\':
          begin
            Inc(P);
            if P > N then Break;
            case S[P] of
              '"', '\', '/', 'b', 'f', 'n', 'r', 't': Inc(P);
              'u':
                begin
                  if not IsHex4(P + 1) then
                    Exit(Fail(P - 1, TrText('SrcVal.Json.BadEscape')));
                  Inc(P, 5);
                end;
            else
              Exit(Fail(P - 1, TrText('SrcVal.Json.BadEscape')));
            end;
          end;
        #0..#31:
          Exit(Fail(P, TrText('SrcVal.Json.CtrlInString')));
      else
        Inc(P);
      end;
    end;
    Result := Fail(Start, TrText('SrcVal.Json.UnclosedString'));
  end;

  function ParseNumber: Boolean;
  var
    Start: Integer;

    function Digits: Boolean;
    var
      Q: Integer;
    begin
      Q := P;
      while (P <= N) and CharInSet(S[P], ['0'..'9']) do
        Inc(P);
      Result := P > Q;
    end;

  begin
    Start := P;
    if S[P] = '-' then
      Inc(P);
    if (P <= N) and (S[P] = '0') then
      Inc(P)
    else if not Digits then
      Exit(Fail(Start, TrText('SrcVal.Json.BadNumber')));
    if (P <= N) and (S[P] = '.') then
    begin
      Inc(P);
      if not Digits then
        Exit(Fail(Start, TrText('SrcVal.Json.BadNumber')));
    end;
    if (P <= N) and CharInSet(S[P], ['e', 'E']) then
    begin
      Inc(P);
      if (P <= N) and CharInSet(S[P], ['+', '-']) then
        Inc(P);
      if not Digits then
        Exit(Fail(Start, TrText('SrcVal.Json.BadNumber')));
    end;
    Result := True;
  end;

  function ParseWord(const AWord: string): Boolean;
  begin
    if Copy(S, P, Length(AWord)) = AWord then
    begin
      Inc(P, Length(AWord));
      Result := True;
    end
    else
      Result := Unexpected;
  end;

  function ParseValue(ADepth: Integer): Boolean;
  begin
    SkipWs;
    if P > N then
      Exit(Unexpected);
    if ADepth > JSON_MAX_DEPTH then
      Exit(Fail(P, TrText('SrcVal.Json.TooDeep')));
    case S[P] of
      '{':
        begin
          Inc(P);
          SkipWs;
          if (P <= N) and (S[P] = '}') then
          begin
            Inc(P);
            Exit(True);
          end;
          repeat
            SkipWs;
            if (P <= N) and (S[P] = '}') then
              Exit(Fail(P, TrText('SrcVal.Json.TrailingComma')));
            if (P > N) or (S[P] <> '"') then
              Exit(Expected('"'));
            if not ParseString then
              Exit(False);
            SkipWs;
            if (P > N) or (S[P] <> ':') then
              Exit(Expected(':'));
            Inc(P);
            if not ParseValue(ADepth + 1) then
              Exit(False);
            SkipWs;
            if (P <= N) and (S[P] = ',') then
            begin
              Inc(P);
              Continue;
            end;
            if (P <= N) and (S[P] = '}') then
            begin
              Inc(P);
              Exit(True);
            end;
            Exit(Expected(', }'));
          until False;
        end;
      '[':
        begin
          Inc(P);
          SkipWs;
          if (P <= N) and (S[P] = ']') then
          begin
            Inc(P);
            Exit(True);
          end;
          repeat
            SkipWs;
            if (P <= N) and (S[P] = ']') then
              Exit(Fail(P, TrText('SrcVal.Json.TrailingComma')));
            if not ParseValue(ADepth + 1) then
              Exit(False);
            SkipWs;
            if (P <= N) and (S[P] = ',') then
            begin
              Inc(P);
              Continue;
            end;
            if (P <= N) and (S[P] = ']') then
            begin
              Inc(P);
              Exit(True);
            end;
            Exit(Expected(', ]'));
          until False;
        end;
      '"': Result := ParseString;
      '-', '0'..'9': Result := ParseNumber;
      't': Result := ParseWord('true');
      'f': Result := ParseWord('false');
      'n': Result := ParseWord('null');
    else
      Result := Unexpected;
    end;
  end;

begin
  AErr := '';
  Msg := '';
  ErrPos := 1;
  N := Length(S);
  P := 1;
  if (N > 0) and (S[1] = #$FEFF) then
    P := 2;
  SkipWs;
  if P > N then
  begin
    AErr := TrText('SrcVal.Empty');
    Exit(False);
  end;
  Result := ParseValue(0);
  if Result then
  begin
    SkipWs;
    if P <= N then
      Result := Fail(P, TrText('SrcVal.Json.Trailing'));
  end;
  if not Result then
    AErr := AtPos(S, ErrPos, Msg);
end;

{ ---------------------------------------------------------------- HTML }

function InBarList(const AList, AName: string): Boolean;
begin
  Result := Pos('|' + AName + '|', AList) > 0;
end;

function CheckHtml(const S: string; out AErr: string): Boolean;
const
  VOID_TAGS = '|area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr|keygen|command|' +
    'basefont|frame|isindex|';
  OPTIONAL_END = '|p|li|dt|dd|option|optgroup|tr|td|th|thead|tbody|tfoot|colgroup|caption|rp|rt|rb|' +
    'rtc|html|head|body|';
  RAW_TEXT = '|script|style|textarea|title|xmp|';
var
  LowS, Name: string;
  StackName: array of string;
  StackPos: array of Integer;
  Count, P, N, Q, NameStart, TagStart, I, J: Integer;
  Closing, SelfClose: Boolean;
  Quote: Char;

  function Fail(AIdx: Integer; const AMsg: string): Boolean;
  begin
    AErr := AtPos(S, AIdx, AMsg);
    Result := False;
  end;

  procedure Push(const AName: string; AIdx: Integer);
  begin
    if Count >= Length(StackName) then
    begin
      SetLength(StackName, Count * 2 + 16);
      SetLength(StackPos, Count * 2 + 16);
    end;
    StackName[Count] := AName;
    StackPos[Count] := AIdx;
    Inc(Count);
  end;

  function SameFamily(const ATop, AName: string): Boolean;
  begin
    Result := (ATop = AName) or
      (InBarList('|td|th|', ATop) and InBarList('|td|th|tr|', AName)) or
      ((ATop = 'tr') and (AName = 'tr')) or
      (InBarList('|dt|dd|', ATop) and InBarList('|dt|dd|', AName)) or
      ((ATop = 'option') and (AName = 'optgroup'));
  end;

begin
  AErr := '';
  LowS := LowerCase(S);
  N := Length(S);
  Count := 0;
  P := 1;
  while P <= N do
  begin
    if S[P] <> '<' then
    begin
      Inc(P);
      Continue;
    end;
    TagStart := P;
    if Copy(S, P, 4) = '<!--' then
    begin
      Q := PosEx('-->', S, P + 4);
      if Q = 0 then
        Exit(Fail(TagStart, TrText('SrcVal.Html.Comment')));
      P := Q + 3;
      Continue;
    end;
    if (P < N) and CharInSet(S[P + 1], ['!', '?']) then
    begin
      Q := PosEx('>', S, P);
      if Q = 0 then
        Exit(Fail(TagStart, Format(TrText('SrcVal.Html.Unterminated'), [Copy(S, P + 1, 8)])));
      P := Q + 1;
      Continue;
    end;
    Closing := (P < N) and (S[P + 1] = '/');
    Q := P + 1;
    if Closing then
      Inc(Q);
    NameStart := Q;
    if (Q > N) or not CharInSet(S[Q], ['a'..'z', 'A'..'Z']) then
    begin
      Inc(P);
      Continue;
    end;
    while (Q <= N) and CharInSet(S[Q], ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', ':', '.']) do
      Inc(Q);
    Name := LowerCase(Copy(S, NameStart, Q - NameStart));
    Quote := #0;
    while Q <= N do
    begin
      if Quote <> #0 then
      begin
        if S[Q] = Quote then
          Quote := #0;
      end
      else if CharInSet(S[Q], ['"', '''']) then
        Quote := S[Q]
      else if CharInSet(S[Q], ['>', '<']) then
        Break;
      Inc(Q);
    end;
    if (Q > N) or (S[Q] <> '>') then
      Exit(Fail(TagStart, Format(TrText('SrcVal.Html.Unterminated'), [Name])));
    SelfClose := S[Q - 1] = '/';
    P := Q + 1;

    if Closing then
    begin
      if InBarList(VOID_TAGS, Name) then
        Continue;
      I := Count - 1;
      while (I >= 0) and (StackName[I] <> Name) and InBarList(OPTIONAL_END, StackName[I]) do
        Dec(I);
      if (I >= 0) and (StackName[I] = Name) then
      begin
        Count := I;
        Continue;
      end;
      J := Count - 1;
      while (J >= 0) and (StackName[J] <> Name) do
        Dec(J);
      if J < 0 then
        Exit(Fail(TagStart, Format(TrText('SrcVal.Html.Stray'), [Name])));
      Exit(Fail(TagStart, Format(TrText('SrcVal.Html.Mismatch'),
        [Name, StackName[Count - 1], LineAt(S, StackPos[Count - 1])])));
    end;

    if SelfClose or InBarList(VOID_TAGS, Name) then
      Continue;
    if InBarList(RAW_TEXT, Name) then
    begin
      Q := PosEx('</' + Name, LowS, P);
      if Q = 0 then
        Exit(Fail(TagStart, Format(TrText('SrcVal.Html.Unclosed'), [Name])));
      Push(Name, TagStart);
      P := Q;
      Continue;
    end;
    if InBarList(OPTIONAL_END, Name) then
      while (Count > 0) and InBarList(OPTIONAL_END, StackName[Count - 1]) and
        SameFamily(StackName[Count - 1], Name) do
        Dec(Count);
    Push(Name, TagStart);
  end;
  for I := Count - 1 downto 0 do
    if not InBarList(OPTIONAL_END, StackName[I]) then
      Exit(Fail(StackPos[I], Format(TrText('SrcVal.Html.Unclosed'), [StackName[I]])));
  Result := True;
end;

{ ---------------------------------------------------------------- SQL }

function CheckSql(const S: string; out AErr: string): Boolean;
var
  P, N, Q, Start, I: Integer;
  Parens, Blocks: array of Integer;
  ParenCount, BlockCount: Integer;
  Word, NextWord, Tag: string;
  Quote: Char;

  function Fail(AIdx: Integer; const AMsg: string): Boolean;
  begin
    AErr := AtPos(S, AIdx, AMsg);
    Result := False;
  end;

  procedure PushTo(var AArr: array of Integer; var ACount: Integer; AIdx: Integer);
  begin
    AArr[ACount] := AIdx;
    Inc(ACount);
  end;

  function IsWordChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9', '_']) or (Ord(C) > 127);
  end;

  { Next word after AFrom (whitespace only in between); ';' is returned as is. }
  function PeekWord(AFrom: Integer): string;
  var
    K, B: Integer;
  begin
    K := AFrom;
    while (K <= N) and CharInSet(S[K], [' ', #9, #10, #13]) do
      Inc(K);
    if (K <= N) and (S[K] = ';') then
      Exit(';');
    B := K;
    while (K <= N) and IsWordChar(S[K]) do
      Inc(K);
    Result := UpperCase(Copy(S, B, K - B));
  end;

  { Position just after the next word (used to consume "END IF", "END CASE"...). }
  function SkipNextWord(AFrom: Integer): Integer;
  begin
    Result := AFrom;
    while (Result <= N) and CharInSet(S[Result], [' ', #9, #10, #13]) do
      Inc(Result);
    while (Result <= N) and IsWordChar(S[Result]) do
      Inc(Result);
  end;

begin
  AErr := '';
  N := Length(S);
  SetLength(Parens, N + 1);
  SetLength(Blocks, N + 1);
  ParenCount := 0;
  BlockCount := 0;
  P := 1;
  while P <= N do
  begin
    case S[P] of
      '-':
        if (P < N) and (S[P + 1] = '-') then
        begin
          while (P <= N) and (S[P] <> #10) do
            Inc(P);
          Continue;
        end;
      '/':
        if (P < N) and (S[P + 1] = '*') then
        begin
          Q := PosEx('*/', S, P + 2);
          if Q = 0 then
            Exit(Fail(P, TrText('SrcVal.Sql.Comment')));
          P := Q + 2;
          Continue;
        end;
      '''', '"', '`':
        begin
          Quote := S[P];
          Start := P;
          Inc(P);
          while True do
          begin
            if P > N then
              Exit(Fail(Start, Format(TrText('SrcVal.Sql.Quote'), [string(Quote)])));
            if S[P] = Quote then
            begin
              if (P < N) and (S[P + 1] = Quote) then
                Inc(P, 2)
              else
                Break;
            end
            else
              Inc(P);
          end;
          Inc(P);
          Continue;
        end;
      '[':
        begin
          Q := PosEx(']', S, P + 1);
          if Q = 0 then
            Exit(Fail(P, Format(TrText('SrcVal.Sql.Quote'), ['['])));
          P := Q + 1;
          Continue;
        end;
      '$':
        begin
          Q := P + 1;
          while (Q <= N) and CharInSet(S[Q], ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
            Inc(Q);
          if (Q <= N) and (S[Q] = '$') and ((Q = P + 1) or not CharInSet(S[P + 1], ['0'..'9'])) then
          begin
            Tag := Copy(S, P, Q - P + 1);
            I := PosEx(Tag, S, Q + 1);
            if I = 0 then
              Exit(Fail(P, Format(TrText('SrcVal.Sql.Quote'), [Tag])));
            P := I + Length(Tag);
            Continue;
          end;
        end;
      '(':
        PushTo(Parens, ParenCount, P);
      ')':
        begin
          if ParenCount = 0 then
            Exit(Fail(P, TrText('SrcVal.Sql.CloseParen')));
          Dec(ParenCount);
        end;
      'a'..'z', 'A'..'Z', '_':
        begin
          Start := P;
          while (P <= N) and IsWordChar(S[P]) do
            Inc(P);
          Word := UpperCase(Copy(S, Start, P - Start));
          if Word = 'BEGIN' then
          begin
            NextWord := PeekWord(P);
            if not ((NextWord = ';') or (NextWord = '') or (NextWord = 'TRAN') or
              (NextWord = 'TRANSACTION') or (NextWord = 'WORK') or (NextWord = 'DISTRIBUTED') or
              (NextWord = 'DEFERRED') or (NextWord = 'IMMEDIATE') or (NextWord = 'EXCLUSIVE')) then
              PushTo(Blocks, BlockCount, Start);
          end
          else if Word = 'CASE' then
            PushTo(Blocks, BlockCount, Start)
          else if Word = 'END' then
          begin
            NextWord := PeekWord(P);
            if (NextWord = 'IF') or (NextWord = 'LOOP') or (NextWord = 'WHILE') or
              (NextWord = 'REPEAT') or (NextWord = 'FOR') then
              P := SkipNextWord(P)
            else
            begin
              if BlockCount = 0 then
                Exit(Fail(Start, TrText('SrcVal.Sql.EndWithoutBegin')));
              Dec(BlockCount);
              if (NextWord = 'CASE') or (NextWord = 'TRY') or (NextWord = 'CATCH') then
                P := SkipNextWord(P);
            end;
          end;
          Continue;
        end;
    end;
    Inc(P);
  end;
  if ParenCount > 0 then
    Exit(Fail(Parens[ParenCount - 1], TrText('SrcVal.Sql.OpenParen')));
  if BlockCount > 0 then
  begin
    I := Blocks[BlockCount - 1];
    Q := I;
    while (Q <= N) and IsWordChar(S[Q]) do
      Inc(Q);
    Exit(Fail(I, Format(TrText('SrcVal.Sql.BlockOpen'), [UpperCase(Copy(S, I, Q - I))])));
  end;
  Result := True;
end;

{ ---------------------------------------------------------------- compilers }

function ProgramFilesDirs: TArray<string>;

  procedure AddDir(const AVar: string);
  var
    D: string;
    I: Integer;
  begin
    D := Trim(GetEnvironmentVariable(AVar));
    if (D = '') or not DirectoryExists(D) then Exit;
    for I := 0 to High(Result) do
      if SameText(Result[I], D) then Exit;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := D;
  end;

begin
  SetLength(Result, 0);
  AddDir('ProgramW6432');
  AddDir('ProgramFiles');
  AddDir('ProgramFiles(x86)');
end;

{ ABase\<sub-folder matching ASubMask>\ATail — the last one in name order (usually the newest). }
function NewestUnder(const ABase, ASubMask, ATail: string): string;
var
  SR: TSearchRec;
  L: TStringList;
  Base, Candidate: string;
begin
  Result := '';
  if (ABase = '') or not DirectoryExists(ABase) then Exit;
  Base := IncludeTrailingPathDelimiter(ABase);
  L := TStringList.Create;
  try
    if FindFirst(Base + ASubMask, faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          Candidate := Base + SR.Name + '\' + ATail;
          if FileExists(Candidate) then
            L.Add(Candidate);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    if L.Count > 0 then
    begin
      L.Sort;
      Result := L[L.Count - 1];
    end;
  finally
    L.Free;
  end;
end;

function OnPath(const AExe: string): string;
begin
  Result := FileSearch(AExe, GetEnvironmentVariable('PATH'));
  if Result <> '' then
    Result := ExpandFileName(Result);
end;

function IsLegacyCsc(const ACscPath: string): Boolean;
begin
  Result := Pos('\MICROSOFT.NET\FRAMEWORK', UpperCase(ACscPath)) > 0;
end;

function FindJavac: string;
var
  PF, Home: string;
begin
  Result := OnPath('javac.exe');
  if Result <> '' then Exit;
  Home := Trim(GetEnvironmentVariable('JAVA_HOME'));
  if (Home <> '') and FileExists(IncludeTrailingPathDelimiter(Home) + 'bin\javac.exe') then
    Exit(IncludeTrailingPathDelimiter(Home) + 'bin\javac.exe');
  for PF in ProgramFilesDirs do
  begin
    Result := NewestUnder(PF + '\Java', 'jdk*', 'bin\javac.exe');
    if Result = '' then
      Result := NewestUnder(PF + '\Eclipse Adoptium', '*', 'bin\javac.exe');
    if Result = '' then
      Result := NewestUnder(PF + '\Microsoft', 'jdk*', 'bin\javac.exe');
    if Result = '' then
      Result := NewestUnder(PF + '\Zulu', '*', 'bin\javac.exe');
    if Result = '' then
      Result := NewestUnder(PF + '\Amazon Corretto', '*', 'bin\javac.exe');
    if Result = '' then
      Result := NewestUnder(PF + '\BellSoft', '*', 'bin\javac.exe');
    if Result <> '' then Exit;
  end;
end;

function FindGofmt: string;
var
  PF, Root: string;
begin
  Result := OnPath('gofmt.exe');
  if Result <> '' then Exit;
  Root := Trim(GetEnvironmentVariable('GOROOT'));
  if (Root <> '') and FileExists(IncludeTrailingPathDelimiter(Root) + 'bin\gofmt.exe') then
    Exit(IncludeTrailingPathDelimiter(Root) + 'bin\gofmt.exe');
  for PF in ProgramFilesDirs do
    if FileExists(PF + '\Go\bin\gofmt.exe') then
      Exit(PF + '\Go\bin\gofmt.exe');
  if FileExists('C:\Go\bin\gofmt.exe') then
    Result := 'C:\Go\bin\gofmt.exe';
end;

function FindCsc: string;
var
  PF, Win, OnPathCsc, VsRoot: string;
  SR: TSearchRec;
begin
  Result := '';
  OnPathCsc := OnPath('csc.exe');
  if (OnPathCsc <> '') and not IsLegacyCsc(OnPathCsc) then
    Exit(OnPathCsc);
  for PF in ProgramFilesDirs do
  begin
    VsRoot := PF + '\Microsoft Visual Studio\';
    if not DirectoryExists(VsRoot) then Continue;
    if FindFirst(VsRoot + '*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) or (SR.Name = '.') or (SR.Name = '..') then Continue;
        Result := NewestUnder(VsRoot + SR.Name, '*', 'MSBuild\Current\Bin\Roslyn\csc.exe');
        if Result = '' then
          Result := NewestUnder(VsRoot + SR.Name, '*', 'MSBuild\15.0\Bin\Roslyn\csc.exe');
      until (Result <> '') or (FindNext(SR) <> 0);
    finally
      FindClose(SR);
    end;
    if Result <> '' then Exit;
  end;
  if OnPathCsc <> '' then
    Exit(OnPathCsc);
  Win := GetEnvironmentVariable('WINDIR');
  if FileExists(Win + '\Microsoft.NET\Framework64\v4.0.30319\csc.exe') then
    Result := Win + '\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
  else if FileExists(Win + '\Microsoft.NET\Framework\v4.0.30319\csc.exe') then
    Result := Win + '\Microsoft.NET\Framework\v4.0.30319\csc.exe';
end;

function FindSourceTool(AKind: TSourceToolKind): string;
begin
  case AKind of
    stkJavac: Result := FindJavac;
    stkGofmt: Result := FindGofmt;
  else
    Result := FindCsc;
  end;
end;

function SourceToolName(AKind: TSourceToolKind): string;
begin
  case AKind of
    stkJavac: Result := 'javac (Java)';
    stkGofmt: Result := 'gofmt (Go)';
  else
    Result := 'csc (C#)';
  end;
end;

function SourceToolMissingText(AKind: TSourceToolKind): string;
const
  MISSING_KEYS: array[TSourceToolKind] of string = ('SrcVal.Tool.MissingJava', 'SrcVal.Tool.MissingGo',
    'SrcVal.Tool.MissingCs');
  HINT_KEYS: array[TSourceToolKind] of string = ('SrcVal.Tool.InstallJava', 'SrcVal.Tool.InstallGo',
    'SrcVal.Tool.InstallCs');
begin
  Result := TrText(MISSING_KEYS[AKind]) + sLineBreak + TrText(HINT_KEYS[AKind]) + sLineBreak +
    TrText('SrcVal.Tool.StillWorks');
end;

function ToolKindForExt(const AExt: string; out AKind: TSourceToolKind): Boolean;
begin
  Result := True;
  if AExt = '.java' then
    AKind := stkJavac
  else if AExt = '.go' then
    AKind := stkGofmt
  else if AExt = '.cs' then
    AKind := stkCsc
  else
    Result := False;
end;

function SourceValidatorAvailable(const APath: string): Boolean;
var
  Kind: TSourceToolKind;
begin
  Result := True;
  if ToolKindForExt(LowerCase(ExtractFileExt(Trim(APath))), Kind) then
    Result := FindSourceTool(Kind) <> '';
end;

function RunCaptured(const ACmdLine, AWorkDir: string; out AOutput: string;
  out AExitCode: DWORD; out ATimedOut: Boolean): Boolean;
var
  Security: TSecurityAttributes;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  StdOutRead, StdOutWrite: THandle;
  Buf: array[0..4095] of Byte;
  BytesRead, Avail: DWORD;
  Acc: TBytesStream;
  T0: Cardinal;
  Cmd: string;

  procedure DrainPipe;
  begin
    while PeekNamedPipe(StdOutRead, nil, 0, nil, @Avail, nil) and (Avail > 0) do
    begin
      if not ReadFile(StdOutRead, Buf[0], SizeOf(Buf), BytesRead, nil) or (BytesRead = 0) then
        Break;
      Acc.WriteBuffer(Buf[0], BytesRead);
    end;
  end;

begin
  Result := False;
  AOutput := '';
  AExitCode := 1;
  ATimedOut := False;
  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  if not CreatePipe(StdOutRead, StdOutWrite, @Security, 0) then Exit;
  Acc := TBytesStream.Create;
  try
    SetHandleInformation(StdOutRead, HANDLE_FLAG_INHERIT, 0);
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := StdOutWrite;
    StartupInfo.hStdError := StdOutWrite;
    FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
    Cmd := ACmdLine;
    UniqueString(Cmd);
    if not CreateProcess(nil, PChar(Cmd), nil, nil, True, CREATE_NO_WINDOW, nil,
      PChar(AWorkDir), StartupInfo, ProcessInfo) then
    begin
      CloseHandle(StdOutWrite);
      StdOutWrite := 0;
      Exit;
    end;
    CloseHandle(StdOutWrite);
    StdOutWrite := 0;
    try
      T0 := GetTickCount;
      repeat
        DrainPipe;
        if WaitForSingleObject(ProcessInfo.hProcess, 150) <> WAIT_TIMEOUT then
          Break;
        if GetTickCount - T0 >= DWORD(CODECHECK_VALIDATE_TIMEOUT_MS) then
        begin
          TerminateProcess(ProcessInfo.hProcess, 1);
          ATimedOut := True;
          Break;
        end;
        if GetCurrentThreadId = MainThreadID then
          Application.ProcessMessages;
      until False;
      DrainPipe;
      while ReadFile(StdOutRead, Buf[0], SizeOf(Buf), BytesRead, nil) and (BytesRead > 0) do
        Acc.WriteBuffer(Buf[0], BytesRead);
      GetExitCodeProcess(ProcessInfo.hProcess, AExitCode);
      AOutput := Trim(DecodeBytes(Copy(Acc.Bytes, 0, Integer(Acc.Size))));
      Result := True;
    finally
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ProcessInfo.hProcess);
    end;
  finally
    if StdOutWrite <> 0 then
      CloseHandle(StdOutWrite);
    CloseHandle(StdOutRead);
    Acc.Free;
  end;
end;

function MakeScratchDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, Format('FastFile_validate_%d_%d',
    [GetCurrentProcessId, GetTickCount]));
  ForceDirectories(Result);
end;

procedure DropScratchDir(const ADir: string);
begin
  try
    if (ADir <> '') and DirectoryExists(ADir) then
      TDirectory.Delete(ADir, True);
  except
  end;
end;

function Quoted(const S: string): string;
begin
  Result := '"' + S + '"';
end;

{ Shared tail of the compiler runs: timeout / launch failure / result text. }
function FinishToolRun(AKind: TSourceToolKind; const ATool: string; ALaunched, ATimedOut: Boolean;
  AExitCode: DWORD; const AOutput, AOkNote: string; out AReport: string): Boolean;
begin
  Result := False;
  if not ALaunched then
  begin
    AReport := Format(TrText('SrcVal.Tool.LaunchFailed'), [ATool]);
    Exit;
  end;
  if ATimedOut then
  begin
    AReport := TrText('Assistant.Validate.Timeout');
    if AOutput <> '' then
      AReport := AReport + sLineBreak + AOutput;
    Exit;
  end;
  Result := AExitCode = 0;
  if Result then
  begin
    AReport := Format(TrText('SrcVal.Tool.Using'), [ATool]);
    if AOkNote <> '' then
      AReport := AReport + sLineBreak + AOkNote;
    if AOutput <> '' then
      AReport := AReport + sLineBreak + sLineBreak + AOutput;
  end
  else
  begin
    AReport := AOutput;
    if AReport = '' then
      AReport := Format(TrText('SrcVal.Tool.ExitCode'), [SourceToolName(AKind), AExitCode]);
    AReport := AReport + sLineBreak + sLineBreak + Format(TrText('SrcVal.Tool.Using'), [ATool]);
  end;
end;

function ValidateJava(const APath: string; out AReport: string): Boolean;
var
  Tool, Scratch, OutDir, Src, Cmd, Output: string;
  Bytes: TBytes;
  Code: DWORD;
  TimedOut, Launched: Boolean;
begin
  Result := False;
  Tool := FindSourceTool(stkJavac);
  if Tool = '' then
  begin
    AReport := SourceToolMissingText(stkJavac);
    Exit;
  end;
  Scratch := MakeScratchDir;
  try
    OutDir := TPath.Combine(Scratch, 'classes');
    ForceDirectories(OutDir);
    Src := APath;
    { javac -encoding UTF-8 rejects the BOM ("illegal character '\ufeff'"): check a copy without it. }
    Bytes := TFile.ReadAllBytes(APath);
    if (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
    begin
      Src := TPath.Combine(Scratch, ExtractFileName(APath));
      TFile.WriteAllBytes(Src, Copy(Bytes, 3, Length(Bytes) - 3));
    end;
    Cmd := Quoted(Tool) +
      ' -J-Dfile.encoding=UTF-8 -J-Dsun.stdout.encoding=UTF-8 -J-Dsun.stderr.encoding=UTF-8' +
      ' -J-Dstdout.encoding=UTF-8 -J-Dstderr.encoding=UTF-8' +
      ' -encoding UTF-8 -proc:none -implicit:none -nowarn -Xlint:none' +
      ' -sourcepath ' + Quoted(ExcludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(APath)))) +
      ' -d ' + Quoted(OutDir) + ' ' + Quoted(Src);
    Launched := RunCaptured(Cmd, Scratch, Output, Code, TimedOut);
    if not SameText(Src, APath) then
      Output := StringReplace(Output, Src, APath, [rfReplaceAll, rfIgnoreCase]);
    Result := FinishToolRun(stkJavac, Tool, Launched, TimedOut, Code, Output,
      TrText('SrcVal.Java.Scope'), AReport);
  finally
    DropScratchDir(Scratch);
  end;
end;

function ValidateGo(const APath: string; out AReport: string): Boolean;
var
  Tool, Cmd, Output: string;
  Code: DWORD;
  TimedOut, Launched: Boolean;
begin
  Result := False;
  Tool := FindSourceTool(stkGofmt);
  if Tool = '' then
  begin
    AReport := SourceToolMissingText(stkGofmt);
    Exit;
  end;
  Cmd := Quoted(Tool) + ' -e -l ' + Quoted(APath);
  Launched := RunCaptured(Cmd, ExtractFilePath(ExpandFileName(APath)), Output, Code, TimedOut);
  { -l prints the file name when only the formatting differs: not an error. }
  if Launched and (Code = 0) then
    Output := '';
  Result := FinishToolRun(stkGofmt, Tool, Launched, TimedOut, Code, Output,
    TrText('SrcVal.Go.Scope'), AReport);
end;

function ValidateCSharp(const APath: string; out AReport: string): Boolean;
var
  Tool, Scratch, Cmd, Output, Note: string;
  Code: DWORD;
  TimedOut, Launched: Boolean;

  function Run(const ATarget, AOutExt: string): Boolean;
  begin
    Cmd := Quoted(Tool) + ' /nologo /utf8output /t:' + ATarget + ' /nowarn:0168,0219,1591' +
      ' /out:' + Quoted(TPath.Combine(Scratch, 'ffcheck' + AOutExt)) + ' ' + Quoted(APath);
    Result := RunCaptured(Cmd, Scratch, Output, Code, TimedOut);
  end;

begin
  Result := False;
  Tool := FindSourceTool(stkCsc);
  if Tool = '' then
  begin
    AReport := SourceToolMissingText(stkCsc);
    Exit;
  end;
  Scratch := MakeScratchDir;
  try
    Launched := Run('library', '.dll');
    { Top-level statements (C# 9+) only build as an executable. }
    if Launched and (not TimedOut) and (Code <> 0) and (Pos('CS8805', Output) > 0) then
      Launched := Run('exe', '.exe');
    Note := TrText('SrcVal.Cs.Scope');
    if IsLegacyCsc(Tool) then
      Note := Note + sLineBreak + TrText('SrcVal.Tool.LegacyCsc');
    Result := FinishToolRun(stkCsc, Tool, Launched, TimedOut, Code, Output, Note, AReport);
    if (not Result) and IsLegacyCsc(Tool) and Launched and not TimedOut then
      AReport := AReport + sLineBreak + TrText('SrcVal.Tool.LegacyCsc');
  finally
    DropScratchDir(Scratch);
  end;
end;

function ValidateBuiltInUnsafe(const APath: string; out AHandled: Boolean; out AReport: string): Boolean;
var
  Ext, Text, Err, Scope: string;
begin
  Result := False;
  AHandled := False;
  AReport := '';
  Ext := LowerCase(ExtractFileExt(Trim(APath)));
  if (Ext = '.json') or (Ext = '.html') or (Ext = '.htm') or (Ext = '.sql') then
  begin
    AHandled := True;
    try
      Text := LoadSourceText(APath);
    except
      on E: Exception do
      begin
        AReport := E.Message;
        Exit;
      end;
    end;
    if Trim(Text) = '' then
    begin
      AReport := TrText('SrcVal.Empty');
      Exit;
    end;
    if Ext = '.json' then
    begin
      Result := CheckJson(Text, Err);
      Scope := '';
    end
    else if Ext = '.sql' then
    begin
      Result := CheckSql(Text, Err);
      Scope := TrText('SrcVal.Sql.Scope');
    end
    else
    begin
      Result := CheckHtml(Text, Err);
      Scope := TrText('SrcVal.Html.Scope');
    end;
    if Result then
    begin
      AReport := TrText('SrcVal.Native');
      if Scope <> '' then
        AReport := AReport + sLineBreak + Scope;
    end
    else
      AReport := Err;
  end
  else if Ext = '.java' then
  begin
    AHandled := True;
    Result := ValidateJava(APath, AReport);
  end
  else if Ext = '.go' then
  begin
    AHandled := True;
    Result := ValidateGo(APath, AReport);
  end
  else if Ext = '.cs' then
  begin
    AHandled := True;
    Result := ValidateCSharp(APath, AReport);
  end;
end;

function ValidateSourceBuiltIn(const APath: string; out AHandled: Boolean; out AReport: string): Boolean;
begin
  try
    Result := ValidateBuiltInUnsafe(APath, AHandled, AReport);
  except
    on E: Exception do
    begin
      Result := False;
      AHandled := True;
      AReport := Format(TrText('SrcVal.Unexpected'), [E.Message]);
    end;
  end;
end;

end.
