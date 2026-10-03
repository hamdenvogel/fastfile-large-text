unit UnTextFileStream;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Classes, Controls,
  StdCtrls, ExtCtrls, ComCtrls;

type
  TTextFileStream = class(TFileStream)
  private
    FBuffer: string;
  public
    function Eof: Boolean;
    procedure WriteLn(Text: string; const bUseLineFeedCarriageReturn: Boolean = True);
    function ReadLn: string;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function RowsCount: Integer;
  end;

implementation

{ TTextFileStream }

function TTextFileStream.Eof: Boolean;
begin
  Eof := ((Position - Length(FBuffer)) = Size);
end;

function TTextFileStream.ReadLn: string;
const
  BufferLength = 10000;
var
  NewBuffer: string;
  Readed: Integer;
begin
  Readed := 1;
  while (PosBMH(#13, FBuffer) = 0) and (Readed > 0) do begin
    SetLength(NewBuffer, BufferLength + 2);
    Readed := Read(NewBuffer[1], BufferLength);
    SetLength(NewBuffer, Readed);
    FBuffer := FBuffer + NewBuffer;
  end;
  if PosBMH(#13, FBuffer) > 0 then begin
    Result := Copy(FBuffer, 1, PosBMH(#13, FBuffer) - 1);
    Delete(FBuffer, 1, PosBMH(#13, FBuffer) + 1);
  end else begin
    Result := FBuffer;
    FBuffer := '';
  end;
end;

function TTextFileStream.RowsCount: Integer;
begin
  Result := 1;
  FBuffer := '';
  Seek(0, soBeginning);
  while not Eof do begin
    ReadLn;
    Inc(Result);
  end;
  Seek(0, soBeginning);
end;

function TTextFileStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  if Origin = soCurrent then
    Result := inherited Seek(Offset - Length(FBuffer), Origin)
    else Result := inherited Seek(Offset, Origin);
  FBuffer := '';
end;

procedure TTextFileStream.WriteLn(Text: string; const bUseLineFeedCarriageReturn: Boolean = True);
const
  NewLine = #13#10;
begin
  Seek(0, soCurrent);
  Write(Text[1], Length(Text));
  if bUseLineFeedCarriageReturn then
    Write(NewLine, 2);
end;

end.
