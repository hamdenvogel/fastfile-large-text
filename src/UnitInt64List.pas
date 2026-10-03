unit UnitInt64List;

interface

{$IFDEF VER80 }{$DEFINE VERYOLDVERSION}{$ENDIF D1    }
{$IFDEF VER90 }{$DEFINE VERYOLDVERSION}{$ENDIF D2    }
{$IFDEF VER93 }{$DEFINE VERYOLDVERSION}{$ENDIF BCB++1}
{$IFDEF VER100}{$DEFINE VERYOLDVERSION}{$ENDIF D3    }
{$IFDEF VER110}{$DEFINE VERYOLDVERSION}{$ENDIF BCB++3}
{$IFDEF VER120}{$DEFINE VERYOLDVERSION}{$ENDIF D4    }
{$IFDEF VER125}{$DEFINE VERYOLDVERSION}{$ENDIF BCB++4}
{$IFDEF VER130}{$DEFINE VERYOLDVERSION}{$ENDIF D5    }
{$IFDEF VER140}{$DEFINE OLDVERSION}{$ENDIF D6,CB++6,Kylix 1&2}
{$IFDEF VER150}{$DEFINE OLDVERSION}{$ENDIF D7, Kylix 3}
{$IFDEF VER160}{$DEFINE OLDVERSION}{$ENDIF D8 for .NET}
{$IFDEF VER170}{$DEFINE OLDVERSION}{$ENDIF D2005}
{$IFDEF VER180}{$DEFINE OLDVERSION}{$ENDIF D2006, D2007 Win32}
{$IFDEF VER180}{$DEFINE OLDVERSION}{$ENDIF D2007 Win32}
{$IFDEF VER185}{$DEFINE OLDVERSION}{$ENDIF D2007 Win32}
{$IFDEF VER190}{$DEFINE OLDVERSION}{$ENDIF D2007 .NET}
{$IFDEF VER200}{$DEFINE OLDVERSION}{$ENDIF D2009, CB++ 2009}
{$IFDEF VER210}{$DEFINE OLDVERSION}{$ENDIF Delphi 2010}
{$IFDEF VER220}{$DEFINE OLDVERSION}{$ENDIF Delphi XE}

{$IFDEF FPC} // Lazarus / Free Pascal
 uses SysUtils, Classes, RTLConsts;
 {$HINTS OFF} // Solve useless "local variable not initialized"
{$ELSE} // Delphi
 {$IFDEF VERYOLDVERSION} // Delphi 1 -> 5
  uses SysUtils, Classes, Consts;
 {$ELSE}
  {$IFDEF OLDVERSION} // Delphi 6 -> XE
   uses SysUtils, Classes, RTLConsts;
  {$ELSE} // Delphi XE2 Win 32/64 + MacOS
   uses System.SysUtils, System.Classes,
        System.RTLConsts;
  {$ENDIF OLDVERSION}
 {$ENDIF VERYOLDVERSION}
{$ENDIF FPC}

type
  TIntegerArray = array of Int64;

const 
 MaxInt64ListSize = Maxint div SizeOf(Int64);

 SInt64ListVoidError='Invalid method call (empty list)!';
 SInt64ListSortError='Invalid method call (sorted list)!';

type
  PInt64PtrList = ^TInt64PtrList;
  
  TInt64PtrList = array[0..MaxInt64ListSize - 1] of Int64;
  
  TInt64ListSortCompare = function (Item1, Item2: Int64): Integer;
  
  TInt64Descriptor = function (Index:Integer;Item : Int64) : string;

  TInt64SortOption 
   = (
      Int64SortNone,
      Int64SortUpWithDup,
      Int64SortUpNoDup,
      Int64SortDownWithDup,
      Int64SortDownNoDup      
     );  

type
  TInt64List = class(TObject)
  private
    FData: PInt64PtrList;
    FCapacity: integer;
    FCount: integer;
    FSortType   : TInt64SortOption;
    procedure Grow;
    procedure SetCapacity(_NewCapacity: Integer);
    function GetItems(_Idx: integer): Int64;
    procedure SetItems(_Idx: integer; const Value: Int64);
//    procedure RemoveItem(var A: TIntegerArray; const Index: Integer);
    function  ErrMsg(const Msg:string;Data:Integer):string;
  protected
    function  NormalAdd(Item: Int64): Integer;
    procedure SetCount(AValue: Integer);
    procedure SetSortType
                  (NewSortType: TInt64SortOption);
    procedure EliminateDups;
    function  NormalFind(Value: Int64): Integer;
    function  FastFindUp(Value:Int64;
                  var Position:Integer):Integer;
    function  FastFindDown(Value:Int64;
                  var Position:Integer):Integer;
    procedure ForceInsert(Index: Integer; Item: Int64);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Add(_Value: Int64): integer;
    property Items[_Idx: integer]: Int64 read GetItems write SetItems;
    property  List: PInt64PtrList read FData;
    property  Capacity: Integer   read FCapacity write SetCapacity;
    property  Count: Integer read FCount write SetCount;
   // procedure Remove(_Idx: integer);
    procedure SaveToStream(const S: TStream);
    procedure LoadFromStream(const S: TStream;
                  const KeepCurrentSortType:Boolean=false);
    procedure SaveToFile(FileName: string);
    procedure LoadFromFile(FileName: string;
                  const KeepCurrentSortType:Boolean=false);
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function  Expand: TInt64List;
    function  First: Int64;
    function  IndexOf(Value: Int64): Integer;
    procedure Insert(Index: Integer; Item: Int64);
    function  Last: Int64;
    procedure Move(CurIndex, NewIndex: Integer);
    function  Remove(Item: Int64): Integer;
    procedure Pack(NilValue:Int64);
    procedure Sort(Compare: TInt64ListSortCompare);
    procedure SortUp;
    procedure SortDown;
    property  SortType:TInt64SortOption read FSortType write SetSortType;
    function  Minimum:Int64;
    function  Maximum:Int64;
    function  Range:Int64;
    function  Sum:Extended;
    function  SumSqr:Extended;
    function  Average:Extended;
    procedure CopyFrom(List:TInt64List;
                  const KeepCurrentSortType:Boolean=false);
    procedure CopyTo(List:TInt64List;
                  const KeepDestSortType:Boolean=false);

    procedure Push(Value:Int64);
    function  LifoPop(DefValue:Int64):Int64;
    function  FifoPop(DefValue:Int64):Int64;
    procedure SplitTwoArrays(const indexToSplit: Integer; var fOriginalList: TInt64List; var fInt64ListA: TInt64List; var fInt64ListB: TInt64List);
    procedure MixTwoArraysInOne(var fOriginalList: TInt64List; var fInt64ListB: TInt64List);
    procedure InsertAtTheMiddle(var fOriginalList: TInt64List; var fInt64ListB: TInt64List; const fIndex: Integer);
  end;

//  procedure SplitTwoArrays(const itemToDivide: Integer; var fOriginalList: TInt64List; var fInt64ListA: TInt64List; var fInt64ListB: TInt64List);

implementation
{$IFNDEF FPC}
 {$IFDEF OLDVERSION}
  uses Consts;
 {$ENDIF}
{$ENDIF}

{ TInt64List }

function TInt64List.Add(_Value: Int64): integer;
begin
  NormalAdd(_Value);
end;

procedure TInt64List.Delete(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then
    raise EListError.Create(
                   ErrMsg(SListIndexError, Index));
  Dec(FCount);
  if Index < FCount then
    System.Move(FData^[Index + 1], FData^[Index],
      (FCount - Index) * SizeOf(Int64));
end;

procedure TInt64List.Exchange(Index1, Index2: Integer);
var
  Item: Int64;
begin
  if FSortType <> Int64SortNone
    then raise EListError.Create(
                     ErrMsg(SInt64ListSortError,0));
  if (Index1 < 0) or (Index1 >= FCount)
    then raise EListError.Create(
                     ErrMsg(SListIndexError, Index1));
  if (Index2 < 0) or (Index2 >= FCount)
    then raise EListError.Create(
                     ErrMsg(SListIndexError, Index2));
  Item := FData^[Index1];
  FData^[Index1] := FData^[Index2];
  FData^[Index2] := Item;
end;

function TInt64List.Expand: TInt64List;
begin
  if FCount = FCapacity then Grow;
  Result := Self;
end;

function TInt64List.First: Int64;
begin
  Result := GetItems(0);
end;

function TInt64List.IndexOf(Value: Int64): Integer;
var
  P:Integer;
begin
  Result := -1;
  case FSortType of
    Int64SortNone:
      Result := NormalFind(Value);

    Int64SortUpWithDup,
      Int64SortUpNoDup:
        Result := FastFindUp(Value,P);

    Int64sortDownWithDup,
    Int64sortDownNoDup:
      Result := FastFindDown(Value,P);
  end;
end;

procedure TInt64List.Insert(Index: Integer; Item: Int64);
begin
  if FSortType <> Int64SortNone
    then raise EListError.Create(
                     ErrMsg(SInt64ListSortError,0));
  if (Index < 0) or (Index > FCount)
    then raise EListError.Create(
                     ErrMsg(SListIndexError, Index));
  ForceInsert(Index,Item);
end;

function TInt64List.Last: Int64;
begin
  Result := GetItems(FCount - 1);
end;

procedure TInt64List.LoadFromFile(FileName: string;
  const KeepCurrentSortType: Boolean);
var
  Stream:TFileStream;
begin
  Stream:=nil;
  try
   Stream := TFileStream.Create(FileName,fmOpenRead
                                or fmShareDenyWrite);
   LoadFromStream(Stream,KeepCurrentSortType);
  finally
    if assigned(Stream) then Stream.Free;
  end;
end;

procedure TInt64List.LoadFromStream(const S: TStream;
  const KeepCurrentSortType: Boolean);
 var
   N, T    : Integer;
   Current : TInt64SortOption;
   Saved   : TInt64SortOption;
begin
  S.Read(N,SizeOf(N));
  S.Read(T,SizeOf(T));
  Saved   := TInt64SortOption(T);
  Current := FSortType;
  Clear;
  SetSortType(Int64SortNone);
  SetCount(N);
  S.Read(FData^,N * SizeOf(Int64));
  if KeepCurrentSortType and (Current <> Saved) then
    SetSortType(Current)
  else FSortType := Saved;
end;

procedure TInt64List.Move(CurIndex, NewIndex: Integer);
var
  Item: Int64;
begin
  if FSortType <> Int64SortNone
    then raise EListError.Create(
                     ErrMsg(SInt64ListSortError,0));
  if CurIndex <> NewIndex then
  begin
    if (NewIndex < 0) or (NewIndex >= FCount)
      then raise EListError.Create(
                     ErrMsg(SListIndexError, NewIndex));
    Item := GetItems(CurIndex);
    Delete(CurIndex);
    Insert(NewIndex, Item);
  end;
end;

procedure TInt64List.Pack(NilValue: Int64);
var
  I: Integer;
begin
  for I := FCount - 1 downto 0 do
  if Items[I] = NilValue then
    Delete(I);
end;

function TInt64List.Remove(Item: Int64): Integer;
begin
  Result := IndexOf(Item);
  if Result <> -1 then Delete(Result);
end;

procedure TInt64List.SaveToFile(FileName: string);
var
  Stream:TFileStream;
begin
  Stream:=nil;
  try
    Stream := TFileStream.Create(FileName, fmCreate
                                or fmShareExclusive);
    SaveToStream(Stream);
  finally
    if assigned(Stream) then Stream.Free;
  end;
end;

procedure TInt64List.SaveToStream(const S: TStream);
var
  T : Integer;
begin
  T := Integer(FSortType);
  S.Write(FCount,SizeOf(FCount));
  S.Write(T,SizeOf(T));
  S.Write(FData^,FCount * SizeOf(Int64));
end;

procedure QuickSort(SortList: PInt64PtrList;
                    L, R: Integer;
  SCompare: TInt64ListSortCompare);
var
  I, J: Integer;
  P, T: Int64;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SCompare(SortList^[I], P) < 0 do Inc(I);
      while SCompare(SortList^[J], P) > 0 do Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure TInt64List.Sort(Compare: TInt64ListSortCompare);
begin
  if (FData <> nil) and (Count > 0)
    then QuickSort(FData, 0, Count - 1, Compare);
end;

procedure QuickSortDown(SortList: PInt64PtrList; 
                        L, R: Integer);
var
  I, J: Integer;
  P, T: Int64;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SortList^[I] > P do Inc(I);
      while SortList^[J] < P do Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSortDown(SortList, L, J);
    L := I;
  until I >= R;
end;

procedure TInt64List.SortDown;
begin
  if (FData <> nil) and (Count > 0) then
  begin
    QuickSortDown(FData, 0, Count - 1);
    FSortType := Int64SortNone
  end;
end;

procedure QuickSortUp(SortList: PInt64PtrList;
                      L, R: Integer);
var
  I, J: Integer;
  P, T: Int64;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SortList^[I] < P do Inc(I);
      while SortList^[J] > P do Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSortUp(SortList, L, J);
    L := I;
  until I >= R;
end;

procedure TInt64List.SortUp;
begin
  if (FData <> nil) and (Count > 0) then
  begin
    QuickSortUp(FData, 0, Count - 1);
    FSortType := Int64SortNone
  end;
end;

procedure TInt64List.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else if FCapacity > 8 then
    Delta := 16
  else
    Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

procedure TInt64List.SetCapacity(_NewCapacity: Integer);
begin
  if {(_NewCapacity < FCount) or }(_NewCapacity > MaxInt64ListSize) then
    raise EListError.Create(
                  ErrMsg(SListCapacityError, _NewCapacity));
    {raise Exception.CreateFmt('List out of bounds.'#13#10+
      'New Capacity %d, Count %d, MaxListSize %d',[_NewCapacity, FCount, MaxListSize]);}
  if _NewCapacity <> FCapacity then
  begin
    ReallocMem(FData, _NewCapacity * SizeOf(Int64));
    FCapacity := _NewCapacity;
  end;
end;

function TInt64List.GetItems(_Idx: integer): Int64;
begin
  if (_Idx < 0) or (_Idx > FCount) then
  begin
    //raise Exception.CreateFmt(('List index out of bounds (%d)'), [_Idx])
    //raise EListError.Create(ErrMsg(SListIndexError, Index));
    Result := 0;
  end
  else
    Result := FData[_Idx];
end;

procedure TInt64List.SetItems(_Idx: integer; const Value: Int64);
begin
  if (_Idx < 0) or (_Idx >= FCount) then
    raise EListError.Create(ErrMsg(SListIndexError, _Idx));
  FData[_Idx] := Value;
end;

{procedure TInt64List.Remove(_Idx: integer);
begin
  RemoveItem(TIntegerArray(FData), _Idx);
end;}

{procedure TInt64List.RemoveItem(var A: TIntegerArray; const Index: Integer);
var
  ALength: Cardinal;
  TailElements: Cardinal;
begin
  ALength := Length(A);
  Assert(ALength > 0);
  Assert(Index < ALength);
  Finalize(A[Index]);
  TailElements := ALength - Index;
  if TailElements > 0 then
    Move(A[Index + 1], A[Index], SizeOf(int64) * TailElements);
  Initialize(A[ALength - 1]);
  SetLength(A, ALength - 1);
  Assert(FCount >= 0);
  if (FCount >= 0) then
    Dec(FCount);
end; }

function TInt64List.ErrMsg(const Msg: string; Data: Integer): string;
begin
  Result := Format(Msg,[Data]);
end;

function TInt64List.NormalAdd(Item: Int64): Integer;
begin
  Result := FCount;
  if Result = FCapacity then Grow;
  FData^[Result] := Item;
  Inc(FCount);
end;

procedure TInt64List.SetCount(AValue: Integer);
begin
  if (AValue < 0) or (AValue > MaxInt64ListSize)
     then raise EListError.Create(
                     ErrMsg(SListCountError, AValue));
  if AValue > FCapacity
     then SetCapacity(AValue);
  if AValue > FCount
     then FillChar((@FData^[FCount])^,
            (AValue - FCount) * SizeOf(Int64), 0);
  FCount := AValue;
end;

procedure TInt64List.EliminateDups;
var
  I:Integer;
begin
  I:=0;
  while I < Count - 1 do
    if FData^[I + 1] = FData^[I] then Delete(I) else Inc(I);
end;

function TInt64List.FastFindDown(Value: Int64;
  var Position: Integer): Integer;
var
  A,B:Integer;
begin
  if Count = 0
    then begin Position := 0; Result := -1; exit end;
  if Value = FData^[0]
    then begin Position := 0; Result :=  0; exit end;
  if Value > FData^[0]
    then begin Position := 0; Result := -1; exit end;
  A := 0;
  B := Count;
  repeat
    Position:=(A + B) div 2;
    if Value = FData^[Position] then
    begin
      Result := Position;
      exit;
    end
    else if Value > FData^[Position] then
      B := Position
    else A := Position
  until B - A <= 1;
  Result := -1;
  if Value < FData^[Position] then
    inc(Position);
end;

function TInt64List.FastFindUp(Value: Int64;
  var Position: Integer): Integer;
var
  A,B:Integer;
begin
  if Count = 0 then
  begin
    Position := 0;
    Result := -1;
    exit;
  end;
  if Value = FData^[0] then
  begin
    Position := 0;
    Result :=  0;
    exit;
  end;
  if Value < FData^[0] then
  begin
    Position := 0;
    Result := -1;
    exit;
  end;
  A := 0;
  B := Count;
  repeat
    Position:=(A + B) div 2;
    if Value = FData^[Position] then
    begin
      Result := Position;
      exit;
    end
    else if Value < FData^[Position] then
      B := Position
    else A := Position
  until B - A <= 1;
  Result := -1;
  if Value > FData^[Position] then
    inc(Position);
end;

procedure TInt64List.ForceInsert(Index: Integer; Item: Int64);
begin
  if FCount = FCapacity then Grow;
  if Index < FCount then
    System.Move(FData^[Index], FData^[Index + 1],
      (FCount - Index) * SizeOf(Int64));
  FData^[Index] := Item;
  Inc(FCount);
end;

function TInt64List.NormalFind(Value: Int64): Integer;
begin
  Result := 0;
  while (Result < FCount) and (FData^[Result] <> Value) do
    Inc(Result);
  if Result = FCount then Result := -1;
end;

procedure TInt64List.SetSortType(NewSortType: TInt64SortOption);
begin
  if NewSortType = FSortType then exit;
  case NewSortType of
    Int64SortNone:
      begin
      end;

    Int64SortUpWithDup:
      begin
        if FSortType <> Int64SortUpNoDup then SortUp;
      end;

    Int64SortUpNoDup:
      begin
        if FSortType <> Int64SortUpWithDup then SortUp;
          EliminateDups;
      end;

    Int64SortDownWithDup:
      begin
        if FSortType <> Int64SortDownNoDup then SortDown;
      end;

    Int64SortDownNoDup:
       begin
         if FSortType <> Int64SortDownWithDup then SortDown;
           EliminateDups;
       end;
  end;
  FSortType := NewSortType;
end;

constructor TInt64List.Create;
begin
  inherited Create;
  FSortType := Int64SortNone;
end;

destructor TInt64List.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TInt64List.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

function TInt64List.Average: Extended;
begin
  if FCount=0 then
    raise EListError.Create(
                     ErrMsg(SInt64ListVoidError,0));
  Result := (Sum / FCount);
end;

procedure TInt64List.CopyFrom(List: TInt64List;
  const KeepCurrentSortType: Boolean);
var
  Current : TInt64SortOption;
begin
  Current := FSortType;
  Clear;
  SetSortType(Int64SortNone);
  SetCount(List.Count);
  System.Move(List.List^, FData^,
              List.Count*SizeOf(Int64));
  if KeepCurrentSortType and (Current <> List.SortType) then
    SetSortType(Current)
  else FSortType := List.SortType;
end;

procedure TInt64List.CopyTo(List: TInt64List;
  const KeepDestSortType: Boolean);
begin
  List.CopyFrom(Self,KeepDestSortType);
end;

function TInt64List.FifoPop(DefValue: Int64): Int64;
begin
  if Count=0 then
    Result := DefValue
  else
  begin
    Result := First;
    Delete(0);
  end;
end;

function TInt64List.LifoPop(DefValue: Int64): Int64;
begin
  if Count=0 then
    Result := DefValue
  else
  begin
    Result := Last;
    Delete(Count - 1);
  end;
end;

function TInt64List.Maximum: Int64;
var
  I:Integer;
begin
  Result := 0;
  if FCount=0 then
    raise EListError.Create(
                     ErrMsg(SInt64ListVoidError,0));
  case FSortType of
    Int64SortNone:
    begin
      Result := FData^[0];
      for I:=1 to FCount-1 do
        if FData^[I]>Result then
          Result := FData^[I];
    end;

    Int64SortUpWithDup,
    Int64SortUpNoDup:
      Result := FData^[FCount - 1];

    Int64sortDownWithDup,
    Int64sortDownNoDup:
      Result := FData^[0];
  end;
end;

function TInt64List.Minimum: Int64;
var
  I:Integer;
begin
  Result := 0;
  if FCount=0 then
    raise EListError.Create(
                     ErrMsg(SInt64ListVoidError,0));
  case FSortType of
    Int64SortNone:
    begin
      Result := FData^[0];
      for I:=1 to FCount-1 do
        if FData^[I]<Result then
          Result := FData^[I];
    end;

    Int64SortUpWithDup,
    Int64SortUpNoDup:
    begin
      Result := FData^[0];
    end;

    Int64sortDownWithDup,
    Int64sortDownNoDup:
    begin
      Result := FData^[FCount - 1];
    end;
  end;
end;

procedure TInt64List.Push(Value: Int64);
begin
  Add(Value);
end;

function TInt64List.Range: Int64;
var
  I:Integer;
  Min,Max,Item:Int64;
begin
  if FCount=0 then
    raise EListError.Create(ErrMsg(SInt64ListVoidError,0));
  if FSortType = Int64SortNone then
  begin
    Min := FData^[0];
    Max:=Min;
    for I:=1 to FCount-1 do
    begin
      Item:=FData^[I];
      if Item > Max then Max := Item;
      if Item < Min then Min := Item;
    end;
      Result := Max - Min;
   end
   else Result := Maximum - Minimum;
end;

function TInt64List.Sum: Extended;
var
  I:Integer;
 begin
   Result:=0;
   for I:=0 to FCount-1
     do Result := Result + FData^[I];
end;

function TInt64List.SumSqr: Extended;
var
  I:Integer;
  Dummy:Extended;
begin
  Result:=0;
  for I:=0 to FCount-1 do
  begin
    Dummy := FData^[I];
    Result := Result + (Dummy * Dummy);
  end;
end;

(* procedure SplitTwoArrays(const itemToDivide: Integer; var fOriginalList: TInt64List; var fInt64ListA: TInt64List; var fInt64ListB: TInt64List);
var
  i, k: integer;
begin
  Assert(Assigned(fOriginalList));
  Assert(Assigned(fInt64ListA));
  Assert(Assigned(fInt64ListB));   
end;
*)
     
procedure TInt64List.SplitTwoArrays(const indexToSplit: Integer;
  var fOriginalList, fInt64ListA, fInt64ListB: TInt64List);
var
  i, k, j, totalItensOriginalList: integer;
begin
  j := 0;
  i := 0;
  totalItensOriginalList := fOriginalList.Count;

  //fInt64ListA case
  while j < indexToSplit do
  begin
    k := fOriginalList.Items[j-i];
    fOriginalList.Remove(j-i);
    inc(j);
    inc(i);
    fInt64ListA.Add(k);
  end;

  j := 0;
  i := 0;

  //fInt64ListB case
  while j < (totalItensOriginalList-fInt64ListA.Count) do
  begin
    k := fOriginalList.Items[j-i];
    fOriginalList.Remove(j-i);
    inc(j);
    inc(i);
    fInt64ListB.Add(k);
  end;
end;

procedure TInt64List.MixTwoArraysInOne(var fOriginalList,
  fInt64ListB: TInt64List);
var
  i, k, j, totalItensListB: integer;
begin
  j := 0;
  i := 0;
  totalItensListB := fInt64ListB.Count;

  //mix List B to Original List A, while mixing is also deleting current itens from List B
  while j < totalItensListB do
  begin
    k := fInt64ListB.Items[j-i];
    fInt64ListB.Remove(j-i);
    inc(j);
    inc(i);
    fOriginalList.Add(k);
  end;    
end;

procedure TInt64List.InsertAtTheMiddle(var fOriginalList,
  fInt64ListB: TInt64List; const fIndex: Integer);
var
  tempListA, tempListB: TInt64List;
  i: integer;
begin
  tempListA := TInt64List.Create;
  tempListB := TInt64List.Create;
  try
    SplitTwoArrays(fIndex,fOriginalList,tempListA,tempListB);
    MixTwoArraysInOne(fOriginalList,tempListA);
    for i := 0 to fInt64ListB.Count - 1 do
      fOriginalList.Add(fInt64ListB.Items[i]);
    fInt64ListB.Clear;
    MixTwoArraysInOne(fOriginalList,tempListB);
  finally
    FreeAndNil(tempListA);
    FreeAndNil(tempListB);
  end;
end;

end.

