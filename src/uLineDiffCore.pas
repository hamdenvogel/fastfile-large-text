unit uLineDiffCore;

{
  Bounded line diff (LCS DP) for two TStringLists.
  Intended for a limited line window (thousands), not whole multi-GB files.
}

interface

uses
  Classes;

type
  TFFDiffKind = (ffdkEqual, ffdkDelete, ffdkInsert, ffdkChange);

  PFFDiffRow = ^TFFDiffRow;
  TFFDiffRow = record
    Kind: TFFDiffKind;
    LNum: Int64;
    RNum: Int64;
    LText: string;
    RText: string;
  end;

{ Clears ADiff (does not free items). Caller should dispose existing PFFDiffRow first if needed. }
procedure FFBuildLineDiffRows(const Left, Right: TStringList; const AMaxDim: Integer;
  ADiff: TList);

implementation

uses
  SysUtils, Math;

procedure FFDisposeDiffRows(ADiff: TList);
var
  k: Integer;
begin
  if not Assigned(ADiff) then Exit;
  for k := 0 to ADiff.Count - 1 do
    Dispose(PFFDiffRow(ADiff[k]));
  ADiff.Clear;
end;

procedure FFBuildLineDiffRowsChunk(const L, R: TStringList; BaseL, BaseR: Int64; ADiff: TList);
var
  n, m, i, j, idx, stride: Integer;
  P: PInteger;
  Rr: PFFDiffRow;
  Tmp: TList;
  TopMatch, BottomMatch: Integer;
  HL, HR: TArray<Cardinal>;

  function Cell(const k: Integer): PInteger;
  begin
    Result := PInteger(NativeInt(P) + NativeInt(k) * SizeOf(Integer));
  end;

  function HashOf(const S: string): Cardinal;
  var
    q: Integer;
  begin
    Result := 2166136261;
    for q := 1 to Length(S) do
      Result := (Result xor Ord(S[q])) * 16777619;
  end;

  function Same(const a, b: Integer): Boolean;
  begin
    Result := (HL[a] = HR[b]) and (L[TopMatch + a] = R[TopMatch + b]);
  end;

  procedure Emit(AKind: TFFDiffKind; a, b: Integer; AList: TList);
  var
    Q: PFFDiffRow;
  begin
    New(Q);
    Q^.Kind := AKind;
    Q^.LNum := 0;
    Q^.RNum := 0;
    if AKind <> ffdkInsert then
    begin
      Q^.LNum := BaseL + TopMatch + a + 1;
      Q^.LText := L[TopMatch + a];
    end;
    if AKind <> ffdkDelete then
    begin
      Q^.RNum := BaseR + TopMatch + b + 1;
      Q^.RText := R[TopMatch + b];
    end;
    AList.Add(Q);
  end;

  { Myers O((n+m)*D): quase linear com poucas diferencas; desiste acima de cMyersMaxD. }
  function TryMyers: Boolean;
  const
    cMyersMaxD = 1000;
  var
    V: TArray<Integer>;
    Trace: TArray<TArray<Integer>>;
    d, k, x, y, off, dMax, found, prevK, prevX, prevY, q: Integer;
    Rev: TList;
  begin
    Result := False;
    dMax := Min(n + m, cMyersMaxD);
    off := dMax + 1;
    SetLength(V, 2 * dMax + 3);
    SetLength(Trace, dMax + 1);
    found := -1;
    for d := 0 to dMax do
    begin
      Trace[d] := Copy(V, off - d - 1, 2 * d + 3);
      k := -d;
      while k <= d do
      begin
        if (k = -d) or ((k <> d) and (V[off + k - 1] < V[off + k + 1])) then
          x := V[off + k + 1]
        else
          x := V[off + k - 1] + 1;
        y := x - k;
        while (x < n) and (y < m) and Same(x, y) do
        begin
          Inc(x);
          Inc(y);
        end;
        V[off + k] := x;
        if (x >= n) and (y >= m) then
        begin
          found := d;
          Break;
        end;
        Inc(k, 2);
      end;
      if found >= 0 then Break;
    end;
    if found < 0 then Exit;

    Rev := TList.Create;
    try
      x := n;
      y := m;
      for d := found downto 0 do
      begin
        { Trace[d] guarda V[-d-1..d+1] antes da iteracao d. }
        k := x - y;
        if (k = -d) or ((k <> d) and (Trace[d][k - 1 + d + 1] < Trace[d][k + 1 + d + 1])) then
          prevK := k + 1
        else
          prevK := k - 1;
        prevX := Trace[d][prevK + d + 1];
        prevY := prevX - prevK;
        while (x > prevX) and (y > prevY) do
        begin
          Dec(x);
          Dec(y);
          Emit(ffdkEqual, x, y, Rev);
        end;
        if d > 0 then
        begin
          if x = prevX then
            Emit(ffdkInsert, 0, prevY, Rev)
          else
            Emit(ffdkDelete, prevX, 0, Rev);
        end;
        x := prevX;
        y := prevY;
      end;
      for q := Rev.Count - 1 downto 0 do
        ADiff.Add(Rev[q]);
    finally
      Rev.Free;
    end;
    Result := True;
  end;

begin
  n := L.Count;
  m := R.Count;
  if (n <= 0) and (m <= 0) then Exit;

  { FAST PATH: Trim matching prefix lines }
  TopMatch := 0;
  while (TopMatch < n) and (TopMatch < m) and (L[TopMatch] = R[TopMatch]) do
  begin
    New(Rr);
    Rr^.Kind := ffdkEqual;
    Rr^.LNum := BaseL + TopMatch + 1;
    Rr^.RNum := BaseR + TopMatch + 1;
    Rr^.LText := L[TopMatch];
    Rr^.RText := R[TopMatch];
    ADiff.Add(Rr);
    Inc(TopMatch);
  end;

  { FAST PATH: Trim matching suffix lines }
  BottomMatch := 0;
  while (BottomMatch < n - TopMatch) and (BottomMatch < m - TopMatch) and 
        (L[n - 1 - BottomMatch] = R[m - 1 - BottomMatch]) do
    Inc(BottomMatch);

  { The remaining matrix is just the middle part that actually differs! }
  n := n - TopMatch - BottomMatch;
  m := m - TopMatch - BottomMatch;

  if (n > 0) or (m > 0) then
  begin
    stride := m + 1;
    SetLength(HL, n);
    SetLength(HR, m);
    for i := 0 to n - 1 do HL[i] := HashOf(L[TopMatch + i]);
    for j := 0 to m - 1 do HR[j] := HashOf(R[TopMatch + j]);
    if not TryMyers then
    begin
    GetMem(P, (n + 1) * (m + 1) * SizeOf(Integer));
    try
      FillChar(Cell(0)^, (n + 1) * (m + 1) * SizeOf(Integer), 0);

      for i := 1 to n do
        for j := 1 to m do
        begin
          idx := i * stride + j;
          if Same(i - 1, j - 1) then
            Cell(idx)^ := Cell((i - 1) * stride + (j - 1))^ + 1
          else
            Cell(idx)^ := Max(Cell((i - 1) * stride + j)^, Cell(i * stride + (j - 1))^);
        end;

      Tmp := TList.Create;
      try
        i := n;
        j := m;
        while (i > 0) or (j > 0) do
        begin
          if (i > 0) and (j > 0) and Same(i - 1, j - 1) then
          begin
            New(Rr);
            Rr^.Kind := ffdkEqual;
            Rr^.LNum := BaseL + TopMatch + i;
            Rr^.RNum := BaseR + TopMatch + j;
            Rr^.LText := L[TopMatch + i - 1];
            Rr^.RText := R[TopMatch + j - 1];
            Tmp.Add(Rr);
            Dec(i);
            Dec(j);
          end
          else if (j > 0) and ((i = 0) or (Cell((i - 1) * stride + j)^ <= Cell(i * stride + (j - 1))^)) then
          begin
            New(Rr);
            Rr^.Kind := ffdkInsert;
            Rr^.LNum := 0;
            Rr^.RNum := BaseR + TopMatch + j;
            Rr^.LText := '';
            Rr^.RText := R[TopMatch + j - 1];
            Tmp.Add(Rr);
            Dec(j);
          end
          else if i > 0 then
          begin
            New(Rr);
            Rr^.Kind := ffdkDelete;
            Rr^.LNum := BaseL + TopMatch + i;
            Rr^.RNum := 0;
            Rr^.LText := L[TopMatch + i - 1];
            Rr^.RText := '';
            Tmp.Add(Rr);
            Dec(i);
          end
          else
            Break;
        end;

        { reverse into ADiff }
        for idx := Tmp.Count - 1 downto 0 do
          ADiff.Add(Tmp[idx]);
      finally
        Tmp.Free;
      end;
    finally
      FreeMem(P);
    end;
    end;
  end;

  { Add the bottom matching lines }
  for idx := BottomMatch - 1 downto 0 do
  begin
    New(Rr);
    Rr^.Kind := ffdkEqual;
    Rr^.LNum := BaseL + (L.Count - idx);
    Rr^.RNum := BaseR + (R.Count - idx);
    Rr^.LText := L[L.Count - 1 - idx];
    Rr^.RText := R[R.Count - 1 - idx];
    ADiff.Add(Rr);
  end;
end;

procedure FFBuildLineDiffRows(const Left, Right: TStringList; const AMaxDim: Integer;
  ADiff: TList);
var
  i, lim: Integer;
  SubL, SubR: TStringList;
  StartL, StartR: Integer;
  MaxChunk: Integer;
  idx: Integer;
  Rr: PFFDiffRow;
  FirstRow, LastEq: Integer;
begin
  if not Assigned(ADiff) then Exit;
  FFDisposeDiffRows(ADiff);

  if not Assigned(Left) or not Assigned(Right) then Exit;

  MaxChunk := AMaxDim;
  if MaxChunk > 2500 then MaxChunk := 2500; // Safety cap to avoid OOM in LCS matrix

  SubL := TStringList.Create;
  SubR := TStringList.Create;
  try
    StartL := 0;
    StartR := 0;
    while (StartL < Left.Count) or (StartR < Right.Count) do
    begin
      SubL.Clear;
      SubR.Clear;
      
      lim := Min(Left.Count - StartL, MaxChunk);
      for i := 0 to lim - 1 do SubL.Add(Left[StartL + i]);
      
      lim := Min(Right.Count - StartR, MaxChunk);
      for i := 0 to lim - 1 do SubR.Add(Right[StartR + i]);
      
      FirstRow := ADiff.Count;
      FFBuildLineDiffRowsChunk(SubL, SubR, StartL, StartR, ADiff);

      { Realinha o bloco seguinte na ultima linha igual: sem isto uma insercao
        desalinha todos os blocos seguintes e cada um paga o LCS completo. }
      LastEq := -1;
      if (StartL + SubL.Count < Left.Count) or (StartR + SubR.Count < Right.Count) then
        for idx := ADiff.Count - 1 downto FirstRow do
          if PFFDiffRow(ADiff[idx])^.Kind = ffdkEqual then
          begin
            LastEq := idx;
            Break;
          end;
      if LastEq >= 0 then
      begin
        Rr := PFFDiffRow(ADiff[LastEq]);
        for idx := ADiff.Count - 1 downto LastEq + 1 do
          Dispose(PFFDiffRow(ADiff[idx]));
        ADiff.Count := LastEq + 1;
        StartL := Integer(Rr^.LNum);
        StartR := Integer(Rr^.RNum);
      end
      else
      begin
        Inc(StartL, SubL.Count);
        Inc(StartR, SubR.Count);
      end;
    end;
  finally
    SubL.Free;
    SubR.Free;
  end;

  { upgrade adjacent delete+insert with different text to "change" for nicer UI }
  idx := 0;
  StartL := 0;
  while idx < ADiff.Count do
  begin
    Rr := PFFDiffRow(ADiff[idx]);
    if (idx < ADiff.Count - 1) and (Rr^.Kind = ffdkDelete) and
       (PFFDiffRow(ADiff[idx + 1])^.Kind = ffdkInsert) then
    begin
      Rr^.Kind := ffdkChange;
      Rr^.RNum := PFFDiffRow(ADiff[idx + 1])^.RNum;
      Rr^.RText := PFFDiffRow(ADiff[idx + 1])^.RText;
      Dispose(PFFDiffRow(ADiff[idx + 1]));
      ADiff[StartL] := Rr;
      Inc(StartL);
      Inc(idx, 2);
    end
    else
    begin
      ADiff[StartL] := Rr;
      Inc(StartL);
      Inc(idx);
    end;
  end;
  ADiff.Count := StartL;
end;

end.
