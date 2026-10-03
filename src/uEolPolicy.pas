unit uEolPolicy;

{
  Politica de fim de linha por ficheiro.
  - Byte terminador para indexar/percorrer linhas: LF (#10) em Windows/Unix/misto,
    CR (#13) em ficheiros Mac classico (so CR). Offsets do indice apontam para este byte.
  - Bytes de EOL para gravar linhas novas: os do ficheiro fonte; em misto/desconhecido,
    a preferencia "EOL padrao" (Windows por omissao).
  Deteccao por amostra (64 KB) com cache por caminho + tamanho + data de escrita.
}

interface

uses
  uFileFormatConvert;

function EolKindForFile(const AFileName: string): TLineEndingKind;
function LineTermByteForFile(const AFileName: string): Byte;
function LineTermCharForFile(const AFileName: string): AnsiChar;
function OutputEolForFile(const AFileName: string): AnsiString;
function OutputEolForKind(AKind: TLineEndingKind): AnsiString;
{ Converte quebras de linha de S (CRLF/CR/LF) para o EOL do ficheiro, se este for
  Windows, Unix ou Mac; caso contrario devolve S sem alteracao. }
function NormalizeTextEolForFile(const S, AFileName: string): string;

procedure SetDefaultOutputEolKind(AKind: TLineEndingKind);
function DefaultOutputEolKind: TLineEndingKind;

implementation

uses
  Windows, SysUtils, Classes, SyncObjs;

const
  EOL_CACHE_SLOTS = 8;

type
  TEolCacheEntry = record
    Path: string;
    Size: Int64;
    WriteTime: TFileTime;
    Kind: TLineEndingKind;
  end;

var
  GEolLock: TCriticalSection;
  GEolCache: array[0..EOL_CACHE_SLOTS - 1] of TEolCacheEntry;
  GEolCacheNext: Integer = 0;
  GDefaultOutputEol: TLineEndingKind = lekWindows;

function ReadFileStamp(const AFileName: string; out ASize: Int64;
  out AWriteTime: TFileTime): Boolean;
var
  Data: TWin32FileAttributeData;
begin
  Result := GetFileAttributesEx(PChar(AFileName), GetFileExInfoStandard, @Data) and
    ((Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0);
  if not Result then
  begin
    ASize := 0;
    AWriteTime.dwLowDateTime := 0;
    AWriteTime.dwHighDateTime := 0;
    Exit;
  end;
  ASize := (Int64(Data.nFileSizeHigh) shl 32) or Int64(Data.nFileSizeLow);
  AWriteTime := Data.ftLastWriteTime;
end;

{ UTF-16/32 (BOM): lekUnknown, mantendo LF como terminador e o EOL padrao na gravacao. }
function DetectEolKindForPolicy(const AFileName: string): TLineEndingKind;
const
  SAMPLE_BYTES = 65536;
var
  F: TFileStream;
  Sample: AnsiString;
  N: Integer;
begin
  Result := lekUnknown;
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Sample, SAMPLE_BYTES);
      N := F.Read(Pointer(Sample)^, SAMPLE_BYTES);
      SetLength(Sample, N);
    finally
      F.Free;
    end;
  except
    Exit;
  end;
  if N <= 0 then Exit;
  if (N >= 2) and (((Ord(Sample[1]) = $FF) and (Ord(Sample[2]) = $FE)) or
                   ((Ord(Sample[1]) = $FE) and (Ord(Sample[2]) = $FF))) then
    Exit;
  if (N >= 4) and (Ord(Sample[1]) = 0) and (Ord(Sample[2]) = 0) and
     (Ord(Sample[3]) = $FE) and (Ord(Sample[4]) = $FF) then
    Exit;
  if (N >= 3) and (Ord(Sample[1]) = $EF) and (Ord(Sample[2]) = $BB) and
     (Ord(Sample[3]) = $BF) then
    Delete(Sample, 1, 3);
  Result := DetectLineEndingFromBytes(Sample);
end;

function EolKindForFile(const AFileName: string): TLineEndingKind;
var
  Key: string;
  Size: Int64;
  WT: TFileTime;
  I: Integer;
begin
  Result := lekUnknown;
  if AFileName = '' then Exit;
  if not ReadFileStamp(AFileName, Size, WT) then Exit;
  Key := AnsiUpperCase(AFileName);
  GEolLock.Enter;
  try
    for I := 0 to EOL_CACHE_SLOTS - 1 do
      if (GEolCache[I].Path = Key) and (GEolCache[I].Size = Size) and
         (GEolCache[I].WriteTime.dwLowDateTime = WT.dwLowDateTime) and
         (GEolCache[I].WriteTime.dwHighDateTime = WT.dwHighDateTime) then
      begin
        Result := GEolCache[I].Kind;
        Exit;
      end;
  finally
    GEolLock.Leave;
  end;
  Result := DetectEolKindForPolicy(AFileName);
  GEolLock.Enter;
  try
    I := GEolCacheNext;
    GEolCache[I].Path := Key;
    GEolCache[I].Size := Size;
    GEolCache[I].WriteTime := WT;
    GEolCache[I].Kind := Result;
    GEolCacheNext := (I + 1) mod EOL_CACHE_SLOTS;
  finally
    GEolLock.Leave;
  end;
end;

function LineTermByteForFile(const AFileName: string): Byte;
begin
  if EolKindForFile(AFileName) = lekMac then
    Result := 13
  else
    Result := 10;
end;

function LineTermCharForFile(const AFileName: string): AnsiChar;
begin
  Result := AnsiChar(LineTermByteForFile(AFileName));
end;

function OutputEolForKind(AKind: TLineEndingKind): AnsiString;
begin
  if not (AKind in [lekWindows, lekUnix, lekMac]) then
    AKind := GDefaultOutputEol;
  Result := LineEndingBytesForKind(AKind);
end;

function OutputEolForFile(const AFileName: string): AnsiString;
begin
  Result := OutputEolForKind(EolKindForFile(AFileName));
end;

function NormalizeTextEolForFile(const S, AFileName: string): string;
var
  Kind: TLineEndingKind;
begin
  Result := S;
  if (Pos(#13, S) = 0) and (Pos(#10, S) = 0) then Exit;
  Kind := EolKindForFile(AFileName);
  if not (Kind in [lekWindows, lekUnix, lekMac]) then Exit;
  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  case Kind of
    lekWindows: Result := StringReplace(Result, #10, #13#10, [rfReplaceAll]);
    lekMac: Result := StringReplace(Result, #10, #13, [rfReplaceAll]);
  end;
end;

procedure SetDefaultOutputEolKind(AKind: TLineEndingKind);
begin
  if AKind in [lekWindows, lekUnix, lekMac] then
    GDefaultOutputEol := AKind
  else
    GDefaultOutputEol := lekWindows;
end;

function DefaultOutputEolKind: TLineEndingKind;
begin
  Result := GDefaultOutputEol;
end;

initialization
  GEolLock := TCriticalSection.Create;

finalization
  FreeAndNil(GEolLock);

end.
