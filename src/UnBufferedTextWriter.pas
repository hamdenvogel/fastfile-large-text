unit UnBufferedTextWriter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

const
  INDEX_RECORD_BYTES = 20;
  { Fila de offsets Int64; descarrega em blocos para evitar overhead por linha. }
  OFFSET_QUEUE_CAPACITY = 65536;

type
  TBufferedTextWriter = class
  private
    FStream: TStream;
    FOwnsStream: Boolean;
    FBuf: array of AnsiChar;
    FPos: Integer;
    FOffsetQueue: array[0..OFFSET_QUEUE_CAPACITY - 1] of Int64;
    FOffsetQueueCount: Integer;
    FEol: array[0..1] of AnsiChar;
    FEolLen: Integer;
    procedure WriteOffsetRecordAt(const Value: Int64; ABufPos: Integer);
    procedure FlushOffsetQueue;
    procedure FlushBuffer;
    function GetLineBreak: AnsiString;
    procedure SetLineBreak(const Value: AnsiString);
  public
    constructor Create(const AFileName: string; ABufferSize: Integer = 4194304); // Default 4MB
    { AHandle: ja aberto (ex. TTemporaryFileStream). Nao fecha o handle. }
    constructor CreateFromHandle(AHandle: THandle; ABufferSize: Integer = 4194304);
    destructor Destroy; override;
    procedure Flush;
    // Escreve o offset diretamente no buffer sem usar Format ou alocar strings
    procedure WriteOffsetDirect(Value: Int64);
    procedure WriteLine(const S: AnsiString);
    procedure WriteRaw(P: Pointer; Len: Integer);
    { Bytes already flushed to disk plus bytes in the internal buffer. }
    function CurrentFileSize: Int64;
    { Terminador usado por WriteLine (CR, LF ou CRLF; padrao CRLF). Registos de indice
      (WriteOffsetDirect) mantem sempre CRLF de largura fixa. }
    property LineBreak: AnsiString read GetLineBreak write SetLineBreak;
  end;  

implementation

const
  INDEX_RECORD_PAD18: array[0..17] of AnsiChar = '                  ';

{ Nao herda THandleStream: em D7 Handle e read-only e Destroy fecha o handle. }
type
  TNoCloseHandleStream = class(TStream)
  private
    FHandle: THandle;
    function GetStreamSize: Longint;
    procedure SetStreamSize(NewSize: Longint);
  public
    constructor Create(AHandle: THandle);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    property Size: Longint read GetStreamSize write SetStreamSize;
  end;

constructor TNoCloseHandleStream.Create(AHandle: THandle);
begin
  inherited Create;
  FHandle := AHandle;
end;

destructor TNoCloseHandleStream.Destroy;
begin
  FHandle := 0;
  inherited Destroy;
end;

function TNoCloseHandleStream.Read(var Buffer; Count: Longint): Longint;
var
  N: DWORD;
begin
  Result := 0;
  if (FHandle = 0) or (FHandle = INVALID_HANDLE_VALUE) then Exit;
  if not ReadFile(FHandle, Buffer, DWORD(Count), N, nil) then
    RaiseLastWin32Error;
  Result := N;
end;

function TNoCloseHandleStream.Write(const Buffer; Count: Longint): Longint;
var
  N: DWORD;
begin
  Result := 0;
  if (FHandle = 0) or (FHandle = INVALID_HANDLE_VALUE) then Exit;
  if not WriteFile(FHandle, Buffer, DWORD(Count), N, nil) then
    RaiseLastWin32Error;
  Result := N;
end;

function TNoCloseHandleStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := SetFilePointer(FHandle, Offset, nil, DWORD(Origin));
  if Result = DWORD(-1) then
    RaiseLastWin32Error;
end;

function TNoCloseHandleStream.GetStreamSize: Longint;
var
  Hi, Lo: DWORD;
begin
  Lo := GetFileSize(FHandle, @Hi);
  if Lo = INVALID_FILE_SIZE then
  begin
    Result := 0;
    Exit;
  end;
  if Hi <> 0 then
    Result := MaxInt
  else
    Result := Lo;
end;

procedure TNoCloseHandleStream.SetStreamSize(NewSize: Longint);
begin
  Seek(NewSize, soFromBeginning);
  SetEndOfFile(FHandle);
end;

{ TBufferedTextWriter }

constructor TBufferedTextWriter.Create(const AFileName: string; ABufferSize: Integer);
begin
  inherited Create;
  FStream := TFileStream.Create(AFileName, fmCreate);
  FOwnsStream := True;
  SetLength(FBuf, ABufferSize);
  FPos := 0;
  FOffsetQueueCount := 0;
  SetLineBreak(#13#10);
end;

constructor TBufferedTextWriter.CreateFromHandle(AHandle: THandle; ABufferSize: Integer);
begin
  inherited Create;
  FStream := TNoCloseHandleStream.Create(AHandle);
  FOwnsStream := True;
  SetLength(FBuf, ABufferSize);
  FPos := 0;
  FOffsetQueueCount := 0;
  SetLineBreak(#13#10);
end;

destructor TBufferedTextWriter.Destroy;
begin
  if Assigned(FStream) then
  begin
    Flush;
    if FOwnsStream then
      FStream.Free;
    FStream := nil;
  end;
  FBuf := nil;
  inherited Destroy;
end;

procedure TBufferedTextWriter.FlushBuffer;
begin
  if (FPos > 0) and Assigned(FStream) then
  begin
    FStream.WriteBuffer(FBuf[0], FPos);
    FPos := 0;
  end;
end;

procedure TBufferedTextWriter.Flush;
begin
  FlushOffsetQueue;
  FlushBuffer;
end;

procedure TBufferedTextWriter.WriteOffsetRecordAt(const Value: Int64; ABufPos: Integer);
var
  i: Integer;
  Temp: UInt64;
  IsNeg: Boolean;
  DigitPos: Integer;
begin
  Move(INDEX_RECORD_PAD18[0], FBuf[ABufPos], 18);
  IsNeg := Value < 0;
  if IsNeg then
    Temp := UInt64(-Value)
  else
    Temp := UInt64(Value);
  DigitPos := 17;
  if IsNeg then
    DigitPos := 16;
  i := DigitPos;
  repeat
    if i < 0 then
      Break;
    FBuf[ABufPos + i] := AnsiChar(Byte(Ord('0') + (Temp mod 10)));
    Temp := Temp div 10;
    Dec(i);
  until Temp = 0;
  if IsNeg and (i >= 0) then
    FBuf[ABufPos + i] := '-';
  FBuf[ABufPos + 18] := #13;
  FBuf[ABufPos + 19] := #10;
end;

procedure TBufferedTextWriter.FlushOffsetQueue;
var
  i, N, BatchBytes: Integer;
begin
  if FOffsetQueueCount = 0 then
    Exit;
  BatchBytes := FOffsetQueueCount * INDEX_RECORD_BYTES;
  if FPos + BatchBytes > Length(FBuf) then
    FlushBuffer;
  if FPos + BatchBytes > Length(FBuf) then
  begin
    for i := 0 to FOffsetQueueCount - 1 do
    begin
      WriteOffsetRecordAt(FOffsetQueue[i], 0);
      FStream.WriteBuffer(FBuf[0], INDEX_RECORD_BYTES);
    end;
  end
  else
  begin
    N := FPos;
    for i := 0 to FOffsetQueueCount - 1 do
    begin
      WriteOffsetRecordAt(FOffsetQueue[i], N);
      Inc(N, INDEX_RECORD_BYTES);
    end;
    FPos := N;
  end;
  FOffsetQueueCount := 0;
end;

procedure TBufferedTextWriter.WriteOffsetDirect(Value: Int64);
begin
  FOffsetQueue[FOffsetQueueCount] := Value;
  Inc(FOffsetQueueCount);
  if FOffsetQueueCount = OFFSET_QUEUE_CAPACITY then
    FlushOffsetQueue;
end;

procedure TBufferedTextWriter.WriteLine(const S: AnsiString);
var
  L, Need: Integer;
begin
  FlushOffsetQueue;
  L := Length(S);
  Need := L + FEolLen;
  if FPos + Need > Length(FBuf) then FlushBuffer;
  
  if L > 0 then
  begin
    Move(S[1], FBuf[FPos], L);
    Inc(FPos, L);
  end;
  FBuf[FPos] := FEol[0]; Inc(FPos);
  if FEolLen = 2 then
  begin
    FBuf[FPos] := FEol[1]; Inc(FPos);
  end;
end;

function TBufferedTextWriter.GetLineBreak: AnsiString;
begin
  SetString(Result, PAnsiChar(@FEol[0]), FEolLen);
end;

procedure TBufferedTextWriter.SetLineBreak(const Value: AnsiString);
begin
  if (Value = #10) or (Value = #13) then
  begin
    FEol[0] := Value[1];
    FEol[1] := #0;
    FEolLen := 1;
  end
  else
  begin
    FEol[0] := #13;
    FEol[1] := #10;
    FEolLen := 2;
  end;
end;

function TBufferedTextWriter.CurrentFileSize: Int64;
begin
  if not Assigned(FStream) then
    Result := 0
  else
    Result := FStream.Size + Int64(FPos) +
      Int64(FOffsetQueueCount) * INDEX_RECORD_BYTES;
end;

procedure TBufferedTextWriter.WriteRaw(P: Pointer; Len: Integer);
begin
  if Len <= 0 then Exit;
  FlushOffsetQueue;
  if FPos + Len > Length(FBuf) then
  begin
    FlushBuffer;
    // Se ainda assim for maior que o buffer (linha gigante), grava direto no stream
    if Len > Length(FBuf) then
    begin
      FStream.WriteBuffer(P^, Len);
      Exit;
    end;
  end;
  Move(P^, FBuf[FPos], Len);
  Inc(FPos, Len);
end;

end.
