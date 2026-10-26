unit uDelimOrder;

{ Sort a delimited file by one column without keeping the file in RAM.
  Each pass stores only a short key plus the 0-based line number. Finished
  runs spill to disk and merge into an order file of Int64 line numbers. }

interface

type
  TDelimLineRead = function(ALine0: Int64): string of object;
  TDelimSortProgress = procedure(ADone, ATotal: Int64; var ACancel: Boolean) of object;

{ Writes AOrderPath as packed Int64 line numbers (0-based), one per data row.
  AFirst is the first file line to include. ACount is the number of rows.
  AChunk is the in-memory run size (tests use a small value). Returns False
  when cancelled or when nothing was written. }
function BuildDelimSortOrder(const AOrderPath: string; AFirst, ACount: Int64;
  AColumn: Integer; const ADelim: Char; ADescending: Boolean;
  ARead: TDelimLineRead; AProgress: TDelimSortProgress;
  AChunk: Integer = 32768): Boolean;

function DelimCell(const S: string; const ADelim: Char; AColumn: Integer): string;

implementation

uses
  SysUtils, Classes, Generics.Defaults, Generics.Collections;

type
  TSortKey = record
    Key: string;
    Line: Int64;
  end;

function DelimCell(const S: string; const ADelim: Char; AColumn: Integer): string;
var
  I, Col: Integer;
  InQuotes: Boolean;
  Token: string;
  C: Char;
begin
  Result := '';
  if AColumn < 0 then Exit;
  Token := '';
  InQuotes := False;
  Col := 0;
  I := 1;
  while I <= Length(S) do
  begin
    C := S[I];
    if C = '"' then
    begin
      if InQuotes and (I < Length(S)) and (S[I + 1] = '"') then
      begin
        Token := Token + '"';
        Inc(I);
      end
      else
        InQuotes := not InQuotes;
    end
    else if (C = ADelim) and (not InQuotes) then
    begin
      if Col = AColumn then
        Exit(Token);
      Token := '';
      Inc(Col);
    end
    else
      Token := Token + C;
    Inc(I);
  end;
  if Col = AColumn then
    Result := Token;
end;

function PlainNumber(const S: string; out V: Double): Boolean;
var
  T: string;
  I: Integer;
  Sep: Boolean;
  FS: TFormatSettings;
begin
  T := Trim(S);
  Result := T <> '';
  if not Result then Exit;
  Sep := False;
  for I := 1 to Length(T) do
  begin
    if (I = 1) and CharInSet(T[I], ['+', '-']) then Continue;
    if CharInSet(T[I], ['0'..'9']) then Continue;
    if (T[I] = '.') or (T[I] = ',') then
    begin
      if Sep then Exit(False);
      Sep := True;
      T[I] := '.';
      Continue;
    end;
    Exit(False);
  end;
  if (T = '+') or (T = '-') or (T = '.') then Exit(False);
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  Result := TryStrToFloat(T, V, FS);
end;

function CompareKeys(const A, B: string): Integer;
var
  NA, NB: Double;
begin
  if PlainNumber(A, NA) and PlainNumber(B, NB) then
  begin
    if NA < NB then Exit(-1);
    if NA > NB then Exit(1);
    Exit(0);
  end;
  Result := CompareText(A, B);
end;

function KeyLess(const A, B: TSortKey; ADescending: Boolean): Boolean;
var
  C: Integer;
begin
  C := CompareKeys(A.Key, B.Key);
  if ADescending then
    C := -C;
  if C = 0 then
    Result := A.Line < B.Line
  else
    Result := C < 0;
end;

procedure SortKeys(var A: TArray<TSortKey>; ACount: Integer; ADescending: Boolean);
var
  Slice: TArray<TSortKey>;
  I: Integer;
begin
  if ACount <= 1 then Exit;
  SetLength(Slice, ACount);
  for I := 0 to ACount - 1 do
    Slice[I] := A[I];
  TArray.Sort<TSortKey>(Slice, TComparer<TSortKey>.Construct(
    function(const L, R: TSortKey): Integer
    var
      C: Integer;
    begin
      C := CompareKeys(L.Key, R.Key);
      if ADescending then
        C := -C;
      if C = 0 then
      begin
        if L.Line < R.Line then
          C := -1
        else if L.Line > R.Line then
          C := 1;
      end;
      Result := C;
    end));
  for I := 0 to ACount - 1 do
    A[I] := Slice[I];
end;

procedure WriteRun(const APath: string; const A: TArray<TSortKey>; ACount: Integer);
var
  Stream: TFileStream;
  I, N: Integer;
  Bytes: TBytes;
begin
  Stream := TFileStream.Create(APath, fmCreate);
  try
    N := ACount;
    Stream.WriteBuffer(N, SizeOf(N));
    for I := 0 to ACount - 1 do
    begin
      Bytes := TEncoding.UTF8.GetBytes(A[I].Key);
      N := Length(Bytes);
      if N > 65535 then
        N := 65535;
      Stream.WriteBuffer(N, SizeOf(N));
      if N > 0 then
        Stream.WriteBuffer(Bytes[0], N);
      Stream.WriteBuffer(A[I].Line, SizeOf(Int64));
    end;
  finally
    Stream.Free;
  end;
end;

type
  TRunReader = class
  public
    Stream: TFileStream;
    Key: string;
    Line: Int64;
    Has: Boolean;
    function Pull: Boolean;
  end;

function TRunReader.Pull: Boolean;
var
  N: Integer;
  Bytes: TBytes;
begin
  Has := False;
  Result := False;
  if Stream.Position >= Stream.Size then Exit;
  if Stream.Read(N, SizeOf(N)) <> SizeOf(N) then Exit;
  if N < 0 then Exit;
  if N > 0 then
  begin
    SetLength(Bytes, N);
    if Stream.Read(Bytes[0], N) <> N then Exit;
    Key := TEncoding.UTF8.GetString(Bytes);
  end
  else
    Key := '';
  if Stream.Read(Line, SizeOf(Line)) <> SizeOf(Line) then Exit;
  Has := True;
  Result := True;
end;

procedure MergeRuns(ARuns: TStringList; const ADest: string; AKeepKeys, ADescending: Boolean);
var
  Readers: array of TRunReader;
  OutStream: TFileStream;
  I, Best, Alive, N, BN: Integer;
  BestKey: TSortKey;
  Cur: TSortKey;
  CountPos: Int64;
  Bytes: TBytes;
begin
  SetLength(Readers, ARuns.Count);
  OutStream := TFileStream.Create(ADest, fmCreate);
  try
    if AKeepKeys then
    begin
      N := 0;
      OutStream.WriteBuffer(N, SizeOf(N));
    end;
    Alive := 0;
    for I := 0 to ARuns.Count - 1 do
    begin
      Readers[I] := TRunReader.Create;
      Readers[I].Stream := TFileStream.Create(ARuns[I], fmOpenRead or fmShareDenyWrite);
      Readers[I].Stream.Position := SizeOf(Integer);
      if Readers[I].Pull then
        Inc(Alive);
    end;
    CountPos := 0;
    N := 0;
    while Alive > 0 do
    begin
      Best := -1;
      for I := 0 to High(Readers) do
      begin
        if not Readers[I].Has then Continue;
        Cur.Key := Readers[I].Key;
        Cur.Line := Readers[I].Line;
        if Best < 0 then
          Best := I
        else
        begin
          BestKey.Key := Readers[Best].Key;
          BestKey.Line := Readers[Best].Line;
          if KeyLess(Cur, BestKey, ADescending) then
            Best := I;
        end;
      end;
      if Best < 0 then Break;
      if AKeepKeys then
      begin
        Bytes := TEncoding.UTF8.GetBytes(Readers[Best].Key);
        BN := Length(Bytes);
        if BN > 65535 then
          BN := 65535;
        OutStream.WriteBuffer(BN, SizeOf(BN));
        if BN > 0 then
          OutStream.WriteBuffer(Bytes[0], BN);
        OutStream.WriteBuffer(Readers[Best].Line, SizeOf(Int64));
      end
      else
        OutStream.WriteBuffer(Readers[Best].Line, SizeOf(Int64));
      Inc(N);
      if not Readers[Best].Pull then
        Dec(Alive);
    end;
    if AKeepKeys then
    begin
      OutStream.Position := CountPos;
      OutStream.WriteBuffer(N, SizeOf(N));
    end;
  finally
    for I := 0 to High(Readers) do
      if Readers[I] <> nil then
      begin
        Readers[I].Stream.Free;
        Readers[I].Free;
      end;
    OutStream.Free;
  end;
end;

function BuildDelimSortOrder(const AOrderPath: string; AFirst, ACount: Int64;
  AColumn: Integer; const ADelim: Char; ADescending: Boolean;
  ARead: TDelimLineRead; AProgress: TDelimSortProgress;
  AChunk: Integer): Boolean;
var
  Keys: TArray<TSortKey>;
  Used, RunNo, K: Integer;
  N: Int64;
  Runs, Next: TStringList;
  Cancel: Boolean;
  Dest, Dir: string;

  function RunPath(AIndex: Integer): string;
  begin
    Result := AOrderPath + '.run' + IntToStr(AIndex);
  end;

  procedure Spill;
  begin
    if Used <= 0 then Exit;
    SortKeys(Keys, Used, ADescending);
    WriteRun(RunPath(RunNo), Keys, Used);
    Runs.Add(RunPath(RunNo));
    Inc(RunNo);
    Used := 0;
  end;

begin
  Result := False;
  if (ACount <= 0) or (AChunk < 2) or not Assigned(ARead) then Exit;
  Dir := ExtractFilePath(AOrderPath);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);
  Runs := TStringList.Create;
  try
    SetLength(Keys, AChunk);
    Used := 0;
    RunNo := 0;
    Cancel := False;
    for N := 0 to ACount - 1 do
    begin
      if Assigned(AProgress) and ((N = 0) or (N mod 2000 = 0) or (N = ACount - 1)) then
      begin
        AProgress(N + 1, ACount, Cancel);
        if Cancel then Exit;
      end;
      Keys[Used].Key := Copy(DelimCell(ARead(AFirst + N), ADelim, AColumn), 1, 48);
      Keys[Used].Line := AFirst + N;
      Inc(Used);
      if Used >= AChunk then
        Spill;
    end;
    Spill;
    if Runs.Count = 0 then Exit;
    while Runs.Count > 1 do
    begin
      Next := TStringList.Create;
      try
        while Runs.Count > 0 do
        begin
          var Group := TStringList.Create;
          try
            while (Group.Count < 8) and (Runs.Count > 0) do
            begin
              Group.Add(Runs[0]);
              Runs.Delete(0);
            end;
            Dest := RunPath(RunNo);
            Inc(RunNo);
            if Group.Count = 1 then
              Next.Add(Group[0])
            else
            begin
              MergeRuns(Group, Dest, True, ADescending);
              Next.Add(Dest);
              for var I := 0 to Group.Count - 1 do
                System.SysUtils.DeleteFile(Group[I]);
            end;
          finally
            Group.Free;
          end;
          if Assigned(AProgress) then
          begin
            AProgress(ACount, ACount, Cancel);
            if Cancel then Exit;
          end;
        end;
      finally
        for K := 0 to Runs.Count - 1 do
          System.SysUtils.DeleteFile(Runs[K]);
        Runs.Free;
        Runs := Next;
      end;
    end;
    MergeRuns(Runs, AOrderPath, False, ADescending);
    Result := FileExists(AOrderPath);
  finally
    if Runs <> nil then
    begin
      for var I := 0 to Runs.Count - 1 do
        if Runs[I] <> AOrderPath then
          System.SysUtils.DeleteFile(Runs[I]);
      Runs.Free;
    end;
    if not Result then
      System.SysUtils.DeleteFile(AOrderPath);
  end;
end;

end.
