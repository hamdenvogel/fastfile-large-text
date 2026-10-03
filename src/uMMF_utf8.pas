unit uMMF;

{
  uMMF.pas - Memory-Mapped File helper (Delphi 7 / Win32)

  Objetivo:
  - Leitura eficiente via MMF, com "views" por janelas (não mapeia o arquivo inteiro).
  - Compatível com Delphi 7 (32-bit), evitando tipos/recursos de versões novas.

  Notas:
  - Para arquivos grandes, o Win32 não permite mapear tudo de uma vez: usamos janelas.
  - Alinhamento obrigatório ao Allocation Granularity do Windows.
  - Esta unit é somente leitura (PAGE_READONLY / FILE_MAP_READ).
}

interface

uses
  Windows, SysUtils;

type
  TMMFReader = class
  private
    FFile: THandle;
    FMap: THandle;
    FFileSize: Int64;

    FViewPtr: Pointer;
    FViewOffset: Int64;   // offset absoluto do início do view
    FViewSize: Cardinal;  // tamanho do view mapeado (bytes)

    FGranularity: Cardinal;

    procedure UnmapView;
    procedure EnsureView(const AbsOffset: Int64; const MinBytes: Cardinal);
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;

    property FileSize: Int64 read FFileSize;

    // Retorna ponteiro válido para AbsOffset (0-based) e quantos bytes contíguos existem a partir dali.
    function PtrAt(const AbsOffset: Int64; const NeedBytes: Cardinal; out Contiguous: Cardinal): PByte;

    // Copia bytes para um buffer do chamador (conveniência).
    function ReadBytes(const AbsOffset: Int64; var Dest; const Len: Cardinal): Cardinal;
  end;

implementation

constructor TMMFReader.Create(const FileName: string);
var
  Info: SYSTEM_INFO;
  SizeHi: DWORD;
  SizeLo: DWORD;
begin
  inherited Create;

  GetSystemInfo(Info);
  FGranularity := Info.dwAllocationGranularity;

  FFile := CreateFile(PChar(FileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if FFile = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Não foi possível abrir arquivo: %s', [FileName]);

  SizeLo := GetFileSize(FFile, @SizeHi);
  if (SizeLo = $FFFFFFFF) and (GetLastError <> NO_ERROR) then
    raise Exception.Create('GetFileSize falhou.');
  FFileSize := (Int64(SizeHi) shl 32) or SizeLo;

  FMap := CreateFileMapping(FFile, nil, PAGE_READONLY, 0, 0, nil);
  if FMap = 0 then
    raise Exception.Create('CreateFileMapping falhou.');

  FViewPtr := nil;
  FViewOffset := 0;
  FViewSize := 0;
end;

destructor TMMFReader.Destroy;
begin
  UnmapView;

  if FMap <> 0 then
    CloseHandle(FMap);

  if (FFile <> 0) and (FFile <> INVALID_HANDLE_VALUE) then
    CloseHandle(FFile);

  inherited Destroy;
end;

procedure TMMFReader.UnmapView;
begin
  if FViewPtr <> nil then
  begin
    UnmapViewOfFile(FViewPtr);
    FViewPtr := nil;
    FViewOffset := 0;
    FViewSize := 0;
  end;
end;

procedure TMMFReader.EnsureView(const AbsOffset: Int64; const MinBytes: Cardinal);
var
  AlignedOffset: Int64;
  Delta: Cardinal;
  WantSize: Cardinal;
  OffHi, OffLo: DWORD;
const
  DEFAULT_VIEW_SIZE = 128 * 1024 * 1024; // 128 MB
begin
  if (AbsOffset < 0) or (AbsOffset >= FFileSize) then Exit;

  AlignedOffset := (AbsOffset div FGranularity) * FGranularity;
  Delta := Cardinal(AbsOffset - AlignedOffset);

  WantSize := DEFAULT_VIEW_SIZE;
  if WantSize < (Delta + MinBytes) then
    WantSize := Delta + MinBytes;

  if AlignedOffset + WantSize > FFileSize then
    WantSize := Cardinal(FFileSize - AlignedOffset);

  if (FViewPtr <> nil) and (AbsOffset >= FViewOffset) and
     (AbsOffset + Int64(MinBytes) <= FViewOffset + Int64(FViewSize)) then
    Exit;

  UnmapView;

  OffHi := DWORD(AlignedOffset shr 32);
  OffLo := DWORD(AlignedOffset and $FFFFFFFF);

  FViewPtr := MapViewOfFile(FMap, FILE_MAP_READ, OffHi, OffLo, WantSize);
  if FViewPtr = nil then
    raise Exception.Create('MapViewOfFile falhou.');

  FViewOffset := AlignedOffset;
  FViewSize := WantSize;
end;

function TMMFReader.PtrAt(const AbsOffset: Int64; const NeedBytes: Cardinal; out Contiguous: Cardinal): PByte;
var
  Delta: Int64;
  Avail: Int64;
begin
  Result := nil;
  Contiguous := 0;

  if (AbsOffset < 0) or (AbsOffset >= FFileSize) then Exit;

  EnsureView(AbsOffset, NeedBytes);

  Delta := AbsOffset - FViewOffset;
  Avail := Int64(FViewSize) - Delta;
  if Avail <= 0 then Exit;

  if Avail > High(Cardinal) then
    Contiguous := High(Cardinal)
  else
    Contiguous := Cardinal(Avail);

  Result := PByte(Integer(FViewPtr) + Integer(Delta));
end;

function TMMFReader.ReadBytes(const AbsOffset: Int64; var Dest; const Len: Cardinal): Cardinal;
var
  P: PByte;
  Cont: Cardinal;
begin
  Result := 0;
  if Len = 0 then Exit;

  P := PtrAt(AbsOffset, Len, Cont);
  if P = nil then Exit;

  if Cont < Len then
    Result := Cont
  else
    Result := Len;

  Move(P^, Dest, Result);
end;

end.
