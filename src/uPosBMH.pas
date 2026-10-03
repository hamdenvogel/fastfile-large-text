unit uPosBMH;

{
  Boyer-Moore-Horspool substring search (replaces SysUtils.Pos for hot paths).
  Shared by FastFile units — keep this unit free of UI / MainUnit dependencies.
}

interface

type
  TBMHByteShiftTable = array[0..255] of Integer;

function PosBMH(const SubStr, S: string): Integer;
function PosBMHFrom(const SubStr, S: string; const StartPos: Integer): Integer;
function BMHStartsWith(const SubStr, S: string): Boolean;
function ContainsBMH(const SubStr, S: string): Boolean;
function PosBMHCi(const SubStr, S: string): Integer;
function ContainsBMHCi(const SubStr, S: string): Boolean;

{ Raw-buffer BMH (0-based indices; -1 = not found). Use for file/MMF hot paths. }
procedure BMHInitSingleByte(var Shift: TBMHByteShiftTable);
function BMHFindBytePAnsi(const Buf: PAnsiChar; const BufLen, StartIndex: Integer;
  const AByte: Byte; const Shift: TBMHByteShiftTable): Integer;
function BMHCountBytePAnsi(const Buf: PAnsiChar; const BufLen: Integer; const AByte: Byte;
  const Shift: TBMHByteShiftTable): Integer;

implementation

uses
  SysUtils;

procedure BMHInitSingleByte(var Shift: TBMHByteShiftTable);
var
  i: Integer;
begin
  for i := 0 to 255 do
    Shift[i] := 1;
end;

function BMHFindBytePAnsi(const Buf: PAnsiChar; const BufLen, StartIndex: Integer;
  const AByte: Byte; const Shift: TBMHByteShiftTable): Integer;
var
  i: Integer;
  b: Byte;
begin
  Result := -1;
  if (Buf = nil) or (BufLen <= 0) or (StartIndex >= BufLen) then Exit;
  if StartIndex < 0 then
    i := 0
  else
    i := StartIndex;
  while i < BufLen do
  begin
    if Byte(Buf[i]) = AByte then
    begin
      Result := i;
      Exit;
    end;
    b := Byte(Buf[i]);
    Inc(i, Shift[b]);
  end;
end;

function BMHCountBytePAnsi(const Buf: PAnsiChar; const BufLen: Integer; const AByte: Byte;
  const Shift: TBMHByteShiftTable): Integer;
var
  SearchAt, P: Integer;
begin
  Result := 0;
  if (Buf = nil) or (BufLen <= 0) then Exit;
  SearchAt := 0;
  while SearchAt < BufLen do
  begin
    P := BMHFindBytePAnsi(Buf, BufLen, SearchAt, AByte, Shift);
    if P < 0 then Break;
    Inc(Result);
    SearchAt := P + 1;
  end;
end;

function PosBMH(const SubStr, S: string): Integer;
var
  Shift: TBMHByteShiftTable;
  SubLen, SLen, i, j: Integer;
  P: Integer;
begin
  Result := 0;
  SubLen := Length(SubStr);
  SLen := Length(S);
  if (SubLen = 0) or (SLen = 0) or (SubLen > SLen) then Exit;

  if SubLen = 1 then
  begin
    for i := 1 to SLen do
      if S[i] = SubStr[1] then
      begin
        Result := i;
        Exit;
      end;
    Exit;
  end;

  for i := 0 to 255 do
    Shift[i] := SubLen;
  { Ord and $FF — never Byte(Char): with $R+, Ord>255 raises ERangeError on Unicode text. }
  for i := 1 to SubLen - 1 do
    Shift[Ord(SubStr[i]) and $FF] := SubLen - i;

  i := SubLen;
  while i <= SLen do
  begin
    j := SubLen;
    while (j > 0) and (S[i - SubLen + j] = SubStr[j]) do
      Dec(j);
    if j = 0 then
    begin
      Result := i - SubLen + 1;
      Exit;
    end;
    Inc(i, Shift[Ord(S[i]) and $FF]);
  end;
end;

function PosBMHFrom(const SubStr, S: string; const StartPos: Integer): Integer;
var
  P, Start: Integer;
begin
  Start := StartPos;
  if Start < 1 then Start := 1;
  if Start > Length(S) then
  begin
    Result := 0;
    Exit;
  end;
  P := PosBMH(SubStr, Copy(S, Start, MaxInt));
  if P > 0 then
    Result := Start + P - 1
  else
    Result := 0;
end;

function BMHStartsWith(const SubStr, S: string): Boolean;
begin
  Result := PosBMH(SubStr, S) = 1;
end;

function ContainsBMH(const SubStr, S: string): Boolean;
begin
  Result := PosBMH(SubStr, S) > 0;
end;

function PosBMHCi(const SubStr, S: string): Integer;
begin
  Result := PosBMH(LowerCase(SubStr), LowerCase(S));
end;

function ContainsBMHCi(const SubStr, S: string): Boolean;
begin
  Result := PosBMHCi(SubStr, S) > 0;
end;

end.
