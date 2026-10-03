unit UnBufferedTextWriter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TBufferedTextWriter = class
  private
    FStream: TFileStream;
    FBuf: array of AnsiChar;
    FPos: Integer;
  public
    constructor Create(const AFileName: string; ABufferSize: Integer = 4194304); // Default 4MB
    destructor Destroy; override;
    procedure Flush;
    // Escreve o offset diretamente no buffer sem usar Format ou alocar strings
    procedure WriteOffsetDirect(Value: Int64);
    procedure WriteLine(const S: AnsiString);
    procedure WriteRaw(P: Pointer; Len: Integer);
  end;  

implementation

{ TBufferedTextWriter }

constructor TBufferedTextWriter.Create(const AFileName: string; ABufferSize: Integer);
begin
  inherited Create;
  FStream := TFileStream.Create(AFileName, fmCreate);
  SetLength(FBuf, ABufferSize);
  FPos := 0;
end;

destructor TBufferedTextWriter.Destroy;
begin
  if Assigned(FStream) then
  begin
    Flush;
    FStream.Free;
    FStream := nil;
  end;
  FBuf := nil;
  inherited Destroy;
end;

procedure TBufferedTextWriter.Flush;
begin
  if (FPos > 0) and Assigned(FStream) then
  begin
    FStream.WriteBuffer(FBuf[0], FPos);
    FPos := 0;
  end;
end;

procedure TBufferedTextWriter.WriteOffsetDirect(Value: Int64);
var
  i: Integer;
  Temp: UInt64;
  IsNeg: Boolean;
  DigitPos: Integer;
begin
  // Verifica se há espaço para 20 bytes (18 chars + CRLF) 
  if FPos + 20 > Length(FBuf) then Flush;

  // Preenche o espaço de 18 caracteres com espaços (Padding à esquerda)
  FillChar(FBuf[FPos], 18, Ord(' '));
  
  IsNeg := Value < 0;
  if IsNeg then
    Temp := UInt64(-Value)
  else
    Temp := UInt64(Value);

  // Se for negativo, reservamos 1 posição para o '-'
  DigitPos := 17;
  if IsNeg then DigitPos := 16;

  i := DigitPos;
  repeat
    if i < 0 then Break; // overflow: não há mais espaço para dígitos
    FBuf[FPos + i] := AnsiChar(Byte('0') + (Temp mod 10));
    Temp := Temp div 10;
    Dec(i);
  until (Temp = 0);

  // Escreve '-' imediatamente antes do primeiro dígito (onde houver espaço)
  if IsNeg and (i >= 0) then
    FBuf[FPos + i] := '-';

  // Avança o ponteiro do buffer em 18 bytes
  FPos := FPos + 18;
  
  // Adiciona o CRLF manual (Totalizando os 20 bytes do INDEX_RECORD_SIZE) 
  FBuf[FPos] := #13; Inc(FPos);
  FBuf[FPos] := #10; Inc(FPos);
end;

procedure TBufferedTextWriter.WriteLine(const S: AnsiString);
var
  L, Need: Integer;
begin
  L := Length(S);
  Need := L + 2;
  if FPos + Need > Length(FBuf) then Flush;
  
  if L > 0 then
  begin
    Move(S[1], FBuf[FPos], L);
    Inc(FPos, L);
  end;
  FBuf[FPos] := #13; Inc(FPos);
  FBuf[FPos] := #10; Inc(FPos);
end;

procedure TBufferedTextWriter.WriteRaw(P: Pointer; Len: Integer);
begin
  if Len <= 0 then Exit;
  if FPos + Len > Length(FBuf) then
  begin
    Flush;
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
