unit UnTemporaryFileStream;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Classes, Controls,
  StdCtrls, ExtCtrls, ComCtrls;

const LINELIMIT = 18;
type
  TTemporaryFileStream = class(THandleStream)
  private
    FBuffer: string;
    FLineLimit: Integer;
    FRowCount: Int64;
    procedure SetRowCount(const value: Int64);
    procedure SetLineLimit(const value: Integer);
  public
    constructor Create(const ALineLimit: Integer = LINELIMIT);
    destructor Destroy; override;
    property LineLimit: Integer read FLineLimit write SetLineLimit;
    property RowCount: Int64 read FRowCount;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Eof: Boolean;
    procedure WriteLn(Text: string);
    function ReadLn: string;
    function RowCountFromScratch: Integer;
    function GetLineContent(const iLine: Int64): String;
    function LineExists(const iLine: Int64): Boolean;
  end;

implementation


{ TTemporaryFileStream }

constructor TTemporaryFileStream.Create(const ALineLimit: Integer);
var
  TempPath: array[0..MAX_PATH] of AnsiChar;
  TempFile: array[0..MAX_PATH] of AnsiChar;
  TempHandle: THandle;
begin
  GetTempPathA(High(TempPath), TempPath);
  GetTempFileNameA(TempPath, 'DA', 0, TempFile);
  TempHandle := CreateFileA(TempFile, GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_RANDOM_ACCESS or
    FILE_FLAG_DELETE_ON_CLOSE, 0);
  Assert(TempHandle <> INVALID_HANDLE_VALUE, 'Unable to create temporary file');
  inherited Create(TempHandle);
  LineLimit := ALineLimit;
  FRowCount := 0;
end;

destructor TTemporaryFileStream.Destroy;
begin
  FileClose(Handle);
  inherited Destroy;
end;

function TTemporaryFileStream.Eof: Boolean;
begin
  Eof := ((Position - Length(FBuffer)) = Size);
end;

function TTemporaryFileStream.GetLineContent(const iLine: Int64): String;
const
  MaxBufferSize = $F000;
begin
  if iLine = 1 then Position := 1
  else if iLine = 2 then Position := FLineLimit + 3
  else if iLine > 2 then
  begin
    Position := (iLine-1) * (FLineLimit + 2);
  end;
  Result := Trim(ReadLn);
end;

function TTemporaryFileStream.LineExists(const iLine: Int64): Boolean;
begin
  Result := (iLine <= RowCount);
end;

function TTemporaryFileStream.ReadLn: string;
const
  BufferLength = 10000;
var
  NewBuffer: string;
  Readed: Integer;
begin
  Readed := 1;
  while (PosBMH(#13, FBuffer) = 0) and (Readed > 0) do
  begin
    SetLength(NewBuffer, BufferLength + 2);
    Readed := Read(NewBuffer[1], BufferLength);
    SetLength(NewBuffer, Readed);
    FBuffer := FBuffer + NewBuffer;
  end;
  if PosBMH(#13, FBuffer) > 0 then
  begin
    Result := Copy(FBuffer, 1, PosBMH(#13, FBuffer) - 1);
    Delete(FBuffer, 1, PosBMH(#13, FBuffer) + 1);
  end
  else
  begin
    Result := FBuffer;
    FBuffer := '';
  end;
end;

function TTemporaryFileStream.RowCountFromScratch: Integer;
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

function TTemporaryFileStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  if Origin = soCurrent then
    Result := inherited Seek(Offset - Length(FBuffer), Origin)
    else Result := inherited Seek(Offset, Origin);
  FBuffer := '';
end;

procedure TTemporaryFileStream.SetLineLimit(const value: Integer);
begin
  FLineLimit := value;
end;

procedure TTemporaryFileStream.SetRowCount(const value: Int64);
begin
  FRowCount := value;
end;

(* procedure TTemporaryFileStream.WriteLn(Text: string);
const
  NewLine = #13#10;
begin
  Text := StringOfChar(' ', LineLimit - length(Text)) + Text;
  WriteBuffer(Pointer(Text+#13#10)^, Length(Text)+2);
  FRowCount := FRowCount + 1;
end; *)

procedure TTemporaryFileStream.WriteLn(Text: string);
const
  NewLine = #13#10;
begin
  Text := StringOfChar(' ', LineLimit - length(Text)) + Text;
  Seek(0, soCurrent);
  Write(Text[1], Length(Text));
  Write(NewLine, 2);
  FRowCount := FRowCount + 1;
end;

end.
