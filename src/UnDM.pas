unit UnDM;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, sSkinManager, sStoreUtils,
  DB, DBClient, UnUtils, UnConsts;

type
  TDataModule1 = class(TDataModule)
    sSkinManager1: TsSkinManager;
    clFiles: TClientDataSet;
    clFilesID: TIntegerField;
    clFilesFilename: TStringField;
    clFilesFileSize: TStringField;
    clFilesSourceLine: TStringField;
    clFilesTargetLine: TStringField;
    clFilesExclude: TClientDataSet;
    clFolders: TClientDataSet;
    clFoldersFolder: TStringField;
    clFilesExcludeFile: TStringField;
    clFilesExcludeStatus: TBooleanField;
    clFilesExcludeFileExclude: TStringField;
    procedure DataModuleCreate(Sender: TObject);
    procedure LoadInternalConfigs;
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.DFM}
{$R folders.res}

function SkinsFolderReady(const SkinsDir: string): Boolean;
var
  SR: TSearchRec;
begin
  Result := False;
  if not DirectoryExists(SkinsDir) then
    Exit;
  if FindFirst(IncludeTrailingPathDelimiter(SkinsDir) + '*.asz', faAnyFile, SR) = 0 then
  begin
    Result := True;
    SysUtils.FindClose(SR);
  end;
end;

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  LoadInternalConfigs;
end;

procedure TDataModule1.LoadInternalConfigs;
var
  IniName: string;
  fullPath: string;
  folderXMLFile: string;
  fileXMLFile: string;
  folderSkins: string;
  fileSkin: string;
  fileTexture: string;
  fileLogo: string;
  //fileConsumerAI: string;
begin
  folderXMLFile := ExtractFilePath(Application.ExeName) + XMLFOLDERS;
  try
    if not FileExists(folderXMLFile) then
      UnUtils.extractResource('FOLDERS', folderXMLFile);
  except
    Abort;
  end;

  fileXMLFile := ExtractFilePath(Application.ExeName) + XMLFILES;
  try
    if not FileExists(fileXMLFile) then
      UnUtils.extractResource('FILES', fileXMLFile);
  except
    Abort;
  end;

  fileSkin := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  try
    if not FileExists(fileSkin) then
      UnUtils.extractResource('SKINSINI', fileSkin);
  except
    Abort;
  end;

  folderSkins := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + FOLDERSKIN;
  try
    if not SkinsFolderReady(folderSkins) then
      UnUtils.ExtractDirResource('SKINS', folderSkins);
  except
    Abort;
  end;

  fullPath := ExtractFilePath(Application.ExeName);
  IniName := IncludeTrailingBackslash(fullPath) + ASKIN_INI;
  if FileExists(IniName) then
  begin
    sStoreUtils.WriteIniStr('FastFile', 'SkinDirectory', IncludeTrailingBackslash(fullPath) + FOLDERSKIN, IniName);  // Skin directory
  end;

  fileTexture := ExtractFilePath(Application.ExeName) + TEXTURE;
  try
    if not FileExists(fileTexture) then
      UnUtils.extractResource('TEXTURE', fileTexture);
  except
    Abort;
  end;

  fileLogo := ExtractFilePath(Application.ExeName) + LOGO;
  try
    if not FileExists(fileLogo) then
      UnUtils.extractResource('LOGO', fileLogo);
  except
    Abort;
  end;

  (*fileConsumerAI := ExtractFilePath(Application.ExeName) + CONSUMERAI;
  try
    if not FileExists(fileConsumerAI) then
      UnUtils.extractResource('CONSUMERAI', fileConsumerAI);
  except
    Abort;
  end; *)

end;

end.
