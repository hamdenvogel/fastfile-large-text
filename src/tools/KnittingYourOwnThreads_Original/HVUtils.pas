unit HVUtils;
//
// Written by Hallvard Vassbotn, hallvard@falcon.no
//
// Based on source code Copyright (c) 1998 by Reuters Group PLC
// Reproduction and/or distribution of source code or DCUs strictly prohibited.
//
// For publication in The Delphi Magazine only
//
interface

uses
  Classes;

function FreeObject(var AnObject): boolean;
procedure FreeOwningTList(var List: TList);


implementation

function FreeObject(var AnObject): boolean;
var
  Item: TObject absolute AnObject;
  Tmp : TObject;
begin
  Tmp := Item;
  Item := nil;
  Result := Assigned(Tmp);
  Tmp.Free;
end;

procedure FreeOwningTList(var List: TList);
var
  i : integer;
begin
  if Assigned(List) then
  begin
    for i := 0 to List.Count-1 do
      FreeObject(List.List^[i]);
    FreeObject(List);
  end;
end;


end.
