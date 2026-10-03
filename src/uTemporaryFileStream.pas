unit uTemporaryFileStream;

{
  Stream em ficheiro temporario sem limite de RAM (padrao DelphiArea).
  Usado na indexacao sob demanda do modo Zero Scan: ckpt/denso em fastfile_temp
  com rename atomico para temp_ckpt.txt / temp.txt junto ao exe.
}

interface

uses
  Windows, SysUtils, Classes, uFastFilePaths;

type
  TTemporaryFileStream = class(THandleStream)
  private
    FFilePath: string;
    FDeleteFileOnDestroy: Boolean;
  public
    { ATag: prefixo do nome (ex. zsckpt). Ficheiro em EnsureFastFileTempDir. }
    constructor CreateForIndex(const ATag: string);
    destructor Destroy; override;
    property FilePath: string read FFilePath;
  end;

implementation

constructor TTemporaryFileStream.CreateForIndex(const ATag: string);
var
  H: THandle;
  SafeTag: string;
begin
  SafeTag := ATag;
  if SafeTag = '' then
    SafeTag := 'idx';
  FFilePath := FastFileScratchTempPath(SafeTag);
  FDeleteFileOnDestroy := True;
  H := CreateFile(PChar(FFilePath), GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_RANDOM_ACCESS, 0);
  if H = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Unable to create temporary index file: %s', [FFilePath]);
  inherited Create(H);
end;

destructor TTemporaryFileStream.Destroy;
begin
  { THandleStream.Destroy fecha o handle; depois apagamos o ficheiro temp se pedido. }
  inherited Destroy;
  if FDeleteFileOnDestroy and (FFilePath <> '') and FileExists(FFilePath) then
    SysUtils.DeleteFile(FFilePath);
end;

end.
