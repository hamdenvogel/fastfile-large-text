unit uMMF;

{
  uMMF.pas - Memory-Mapped File helper (Delphi 7 / Win32 / Win64)

  Objetivo:
  - Leitura eficiente via MMF, com "views" por janelas (nùo mapeia o arquivo inteiro).
  - Compatùvel com Delphi 7 (32-bit), evitando tipos/recursos de versùes novas.

  Notas:
  - Para arquivos grandes, o Win32 nùo permite mapear tudo de uma vez: usamos janelas.
  - Alinhamento obrigatùrio ao Allocation Granularity do Windows.
  - Esta unit ù somente leitura (PAGE_READONLY / FILE_MAP_READ).
  - Win64: view actual + view de prefetch (janela seguinte) para scan sequencial GB+.
}

interface

uses
  Windows, SysUtils, ThreadFileLog, uFastFilePaths;

type
  TMMFReader = class
  private
    FFile: THandle;
    FMap: THandle;
    FFileSize: Int64;

    FViewPtr: Pointer;
    FViewOffset: Int64;   // offset absoluto do inùcio do view
    FViewSize: Cardinal;  // tamanho do view mapeado (bytes)

    FPrefetchPtr: Pointer;
    FPrefetchOffset: Int64;
    FPrefetchSize: Cardinal;

    FGranularity: Cardinal;
    FViewChunkSize: Cardinal;
    FPrefetchEnabled: Boolean;

    procedure UnmapView;
    procedure UnmapPrefetch;
    procedure HintMappedRange(APtr: Pointer; ASize: Cardinal);
    function TryMap(const AlignedOffset: Int64; const WantSize: Cardinal;
      out APtr: Pointer; out AOff: Int64; out ASize: Cardinal): Boolean;
    procedure KickPrefetch;
    procedure PromotePrefetch;
    procedure EnsureView(const AbsOffset: Int64; const MinBytes: Cardinal);
  public
    constructor Create(const FileName: string; AViewChunkSize: Cardinal = 0;
      AEnablePrefetch: Boolean = True);
    destructor Destroy; override;
    { Fecha view + mapping + handle do ficheiro (antes de rename/delete do original). }
    procedure ReleaseFileLocks;

    property FileSize: Int64 read FFileSize;

    // Retorna ponteiro vùlido para AbsOffset (0-based) e quantos bytes contùguos existem a partir dali.
    function PtrAt(const AbsOffset: Int64; const NeedBytes: Cardinal; out Contiguous: Cardinal): PByte;

    // Copia bytes para um buffer do chamador (conveniùncia).
    function ReadBytes(const AbsOffset: Int64; var Dest; const Len: Cardinal): Cardinal;
  end;

implementation

type
  TWin32MemoryRangeEntry = packed record
    VirtualAddress: Pointer;
    NumberOfBytes: NativeUInt;
  end;
  TPrefetchVirtualMemory = function(hProcess: THandle; NumberOfEntries: NativeUInt;
    VirtualAddresses: Pointer; Flags: ULONG): BOOL; stdcall;

var
  GPrefetchVM: TPrefetchVirtualMemory = nil;
  GPrefetchVMResolved: Boolean = False;

procedure ResolvePrefetchVirtualMemory;
var
  H: THandle;
begin
  if GPrefetchVMResolved then Exit;
  GPrefetchVMResolved := True;
  H := GetModuleHandle(kernel32);
  if H <> 0 then
    GPrefetchVM := TPrefetchVirtualMemory(GetProcAddress(H, 'PrefetchVirtualMemory'));
end;

constructor TMMFReader.Create(const FileName: string; AViewChunkSize: Cardinal;
  AEnablePrefetch: Boolean);
var
  Info: SYSTEM_INFO;
  SizeHi: DWORD;
  SizeLo: DWORD;
begin
  inherited Create;

  GetSystemInfo(Info);
  FGranularity := Info.dwAllocationGranularity;
  FPrefetchEnabled := AEnablePrefetch;

  FFile := CreateFile(PChar(FileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if FFile = INVALID_HANDLE_VALUE then
  begin
    LogAsync(FastFileRuntimeLogPath, '[MMF] Nùo foi possùvel abrir arquivo: ' + FileName);
    raise Exception.CreateFmt('Nùo foi possùvel abrir arquivo: %s', [FileName]);
  end;

  SizeLo := GetFileSize(FFile, @SizeHi);
  if (SizeLo = $FFFFFFFF) and (GetLastError <> NO_ERROR) then
  begin
    LogAsync(FastFileRuntimeLogPath, '[MMF] GetFileSize falhou.');
    raise Exception.Create('GetFileSize falhou.');
  end;
  FFileSize := (Int64(SizeHi) shl 32) or SizeLo;

  { Janelas MMF: blocos grandes reduzem MapViewOfFile em ficheiros GB (leitura sequencial). }
  if FFileSize >= Int64(1) * 1024 * 1024 * 1024 then
    FViewChunkSize := 512 * 1024 * 1024
  else if FFileSize > Int64(512) * 1024 * 1024 then
    FViewChunkSize := 256 * 1024 * 1024
  else if FFileSize > Int64(64) * 1024 * 1024 then
    FViewChunkSize := 192 * 1024 * 1024
  else
    FViewChunkSize := 128 * 1024 * 1024;
  if AViewChunkSize >= FGranularity then
    FViewChunkSize := AViewChunkSize;

  FMap := CreateFileMapping(FFile, nil, PAGE_READONLY, 0, 0, nil);
  if FMap = 0 then
  begin
    LogAsync(FastFileRuntimeLogPath, '[MMF] CreateFileMapping falhou.');
    raise Exception.Create('CreateFileMapping falhou.');
  end;

  FViewPtr := nil;
  FViewOffset := 0;
  FViewSize := 0;
  FPrefetchPtr := nil;
  FPrefetchOffset := 0;
  FPrefetchSize := 0;
end;

procedure TMMFReader.ReleaseFileLocks;
begin
  UnmapPrefetch;
  UnmapView;
  if FMap <> 0 then
  begin
    CloseHandle(FMap);
    FMap := 0;
  end;
  if (FFile <> 0) and (FFile <> INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(FFile);
    FFile := INVALID_HANDLE_VALUE;
  end;
end;

destructor TMMFReader.Destroy;
begin
  ReleaseFileLocks;
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

procedure TMMFReader.UnmapPrefetch;
begin
  if FPrefetchPtr <> nil then
  begin
    UnmapViewOfFile(FPrefetchPtr);
    FPrefetchPtr := nil;
    FPrefetchOffset := 0;
    FPrefetchSize := 0;
  end;
end;

procedure TMMFReader.HintMappedRange(APtr: Pointer; ASize: Cardinal);
var
  Entry: TWin32MemoryRangeEntry;
begin
  if (APtr = nil) or (ASize = 0) then Exit;
  ResolvePrefetchVirtualMemory;
  if not Assigned(GPrefetchVM) then Exit;
  Entry.VirtualAddress := APtr;
  Entry.NumberOfBytes := ASize;
  GPrefetchVM(GetCurrentProcess, 1, @Entry, 0);
end;

function TMMFReader.TryMap(const AlignedOffset: Int64; const WantSize: Cardinal;
  out APtr: Pointer; out AOff: Int64; out ASize: Cardinal): Boolean;
var
  OffHi, OffLo: DWORD;
begin
  Result := False;
  APtr := nil;
  AOff := 0;
  ASize := 0;
  if (FMap = 0) or (WantSize = 0) or (AlignedOffset < 0) or (AlignedOffset >= FFileSize) then
    Exit;
  OffHi := DWORD(AlignedOffset shr 32);
  OffLo := DWORD(AlignedOffset and $FFFFFFFF);
  APtr := MapViewOfFile(FMap, FILE_MAP_READ, OffHi, OffLo, WantSize);
  if APtr = nil then Exit;
  AOff := AlignedOffset;
  ASize := WantSize;
  Result := True;
end;

procedure TMMFReader.KickPrefetch;
var
  NextOff: Int64;
  Want: Cardinal;
begin
  {$IFNDEF WIN64}
  Exit;
  {$ENDIF}
  if not FPrefetchEnabled then Exit;
  if (FViewPtr = nil) or (FViewSize = 0) then Exit;
  NextOff := FViewOffset + Int64(FViewSize);
  if NextOff >= FFileSize then
  begin
    UnmapPrefetch;
    Exit;
  end;
  if (FPrefetchPtr <> nil) and (FPrefetchOffset = NextOff) then
  begin
    HintMappedRange(FPrefetchPtr, FPrefetchSize);
    Exit;
  end;
  UnmapPrefetch;
  Want := FViewChunkSize;
  if NextOff + Int64(Want) > FFileSize then
    Want := Cardinal(FFileSize - NextOff);
  if not TryMap(NextOff, Want, FPrefetchPtr, FPrefetchOffset, FPrefetchSize) then
    Exit;
  HintMappedRange(FPrefetchPtr, FPrefetchSize);
end;

procedure TMMFReader.PromotePrefetch;
begin
  UnmapView;
  FViewPtr := FPrefetchPtr;
  FViewOffset := FPrefetchOffset;
  FViewSize := FPrefetchSize;
  FPrefetchPtr := nil;
  FPrefetchOffset := 0;
  FPrefetchSize := 0;
  if FViewPtr <> nil then
    HintMappedRange(FViewPtr, FViewSize);
  KickPrefetch;
end;

procedure TMMFReader.EnsureView(const AbsOffset: Int64; const MinBytes: Cardinal);
var
  AlignedOffset: Int64;
  Delta: Cardinal;
  WantSize: Cardinal;
begin
  if (AbsOffset < 0) or (AbsOffset >= FFileSize) then Exit;

  AlignedOffset := (AbsOffset div FGranularity) * FGranularity;
  Delta := Cardinal(AbsOffset - AlignedOffset);

  WantSize := FViewChunkSize;
  if WantSize < (Delta + MinBytes) then
    WantSize := Delta + MinBytes;

  if AlignedOffset + WantSize > FFileSize then
    WantSize := Cardinal(FFileSize - AlignedOffset);

  if (FViewPtr <> nil) and (AbsOffset >= FViewOffset) and
     (AbsOffset + Int64(MinBytes) <= FViewOffset + Int64(FViewSize)) then
  begin
    KickPrefetch;
    Exit;
  end;

  if (FPrefetchPtr <> nil) and (AbsOffset >= FPrefetchOffset) and
     (AbsOffset + Int64(MinBytes) <= FPrefetchOffset + Int64(FPrefetchSize)) then
  begin
    PromotePrefetch;
    Exit;
  end;

  UnmapView;
  UnmapPrefetch;

  if not TryMap(AlignedOffset, WantSize, FViewPtr, FViewOffset, FViewSize) then
  begin
    LogAsync(FastFileRuntimeLogPath, '[MMF] MapViewOfFile falhou.');
    raise Exception.Create('MapViewOfFile falhou.');
  end;
  HintMappedRange(FViewPtr, FViewSize);
  KickPrefetch;
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

  Result := PByte(PAnsiChar(FViewPtr) + NativeInt(Delta));
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
