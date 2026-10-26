program DelimOrderTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IOUtils, uDelimOrder;

type
  TReader = class
    Lines: TStringList;
    Cancelled: Boolean;
    function ReadLine(ALine0: Int64): string;
    procedure Progress(ADone, ATotal: Int64; var ACancel: Boolean);
  end;

function TReader.ReadLine(ALine0: Int64): string;
begin
  if (ALine0 < 0) or (ALine0 >= Lines.Count) then
    Result := ''
  else
    Result := Lines[ALine0];
end;

procedure TReader.Progress(ADone, ATotal: Int64; var ACancel: Boolean);
begin
  if Cancelled then
    ACancel := True;
end;

procedure Check(Ok: Boolean; const Name: string);
begin
  if not Ok then
    raise Exception.Create(Name);
end;

function OrderOf(const Path: string): TArray<Int64>;
var
  Stream: TFileStream;
  N, I: Integer;
begin
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  try
    N := Stream.Size div SizeOf(Int64);
    SetLength(Result, N);
    if N > 0 then
      Stream.ReadBuffer(Result[0], N * SizeOf(Int64));
    for I := 0 to N - 1 do
      if Stream.Position < 0 then
        Break;
  finally
    Stream.Free;
  end;
end;

var
  R: TReader;
  Path: string;
  Order: TArray<Int64>;

begin
  R := TReader.Create;
  try
    R.Lines := TStringList.Create;
    R.Lines.Add('b,10');
    R.Lines.Add('a,2');
    R.Lines.Add('c,1');
    R.Lines.Add('"a,b",z');
    Path := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'ff_delim_order.idx';
    Check(BuildDelimSortOrder(Path, 0, 4, 0, ',', False, R.ReadLine, nil, 2), 'build');
    Order := OrderOf(Path);
    Check((Length(Order) = 4) and (Order[0] = 1) and (Order[1] = 3) and
      (Order[2] = 0) and (Order[3] = 2), 'text order a, "a,b", b, c');
    Check(DelimCell('"a,b",z', ',', 0) = 'a,b', 'quoted cell');
    Check(BuildDelimSortOrder(Path, 0, 3, 1, ',', False, R.ReadLine, nil, 2), 'numeric build');
    Order := OrderOf(Path);
    Check((Length(Order) = 3) and (Order[0] = 2) and (Order[1] = 1) and (Order[2] = 0),
      'numeric 1, 2, 10');
    Check(BuildDelimSortOrder(Path, 0, 3, 0, ',', True, R.ReadLine, nil, 2), 'desc');
    Order := OrderOf(Path);
    Check((Length(Order) = 3) and (Order[0] = 2) and (Order[1] = 0) and (Order[2] = 1),
      'desc c, b, a');
    R.Cancelled := True;
    Check(not BuildDelimSortOrder(Path, 0, 4, 0, ',', False, R.ReadLine, R.Progress, 2),
      'cancel');
    Writeln('PASS: delimiter column order');
  finally
    if R.Lines <> nil then
      R.Lines.Free;
    R.Free;
  end;
end.
