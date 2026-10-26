unit uAgentDiscovery;

{
  Deterministic folder/file inventory for the diagnosis hub (no LLM).
  Reuses AgentExpandRoots limits (mask, depth, max files, subdirs).
}

interface

uses
  Classes, SysUtils, uAgentPrefs, uAgentHubModel;

type
  THubDiscoverProgress = procedure(AListed: Integer) of object;

function AgentHubDiscover(ARoots: TStrings; const APrefs: TAgentPrefs;
  ADiscovery: THubDiscovery; ACancel: PInteger;
  AOnProgress: THubDiscoverProgress = nil): Boolean;

implementation

uses
  Generics.Collections, Generics.Defaults, uAgentTools;

type
  TExtBag = TDictionary<string, THubExtStat>;
  TFolderBag = TDictionary<string, THubFolderStat>;

  TDiscoverNotify = class
  public
    Cancel: PInteger;
    OnProgress: THubDiscoverProgress;
    Stopped: Boolean;
    procedure ScanTick(AListed: Integer; var ACancel: Boolean);
  end;

procedure TDiscoverNotify.ScanTick(AListed: Integer; var ACancel: Boolean);
begin
  if Assigned(Cancel) and (Cancel^ <> 0) then
  begin
    Stopped := True;
    ACancel := True;
  end;
  if Assigned(OnProgress) then
    OnProgress(AListed);
end;

function FileByteSize(const APath: string): Int64;
var
  SR: TSearchRec;
begin
  Result := 0;
  if FindFirst(APath, faAnyFile, SR) = 0 then
  try
    Result := SR.Size;
  finally
    FindClose(SR);
  end;
end;

function NormExt(const APath: string): string;
begin
  Result := LowerCase(ExtractFileExt(APath));
  if Result = '' then
    Result := '(none)';
end;

function AgentHubDiscover(ARoots: TStrings; const APrefs: TAgentPrefs;
  ADiscovery: THubDiscovery; ACancel: PInteger;
  AOnProgress: THubDiscoverProgress): Boolean;
var
  Files: TStringList;
  ExtMap: TExtBag;
  FolderMap: TFolderBag;
  Notify: TDiscoverNotify;
  I: Integer;
  Path, Dir, Ext: string;
  Sz: Int64;
  ES: THubExtStat;
  FS: THubFolderStat;
  Listed: Integer;
  ExtList: TList<THubExtStat>;
  FolderList: TList<THubFolderStat>;

  function Stopped: Boolean;
  begin
    Result := Assigned(ACancel) and (ACancel^ <> 0);
  end;

  procedure AddExt(const AExt: string; ABytes: Int64);
  begin
    if not ExtMap.TryGetValue(AExt, ES) then
    begin
      ES := THubExtStat.Create;
      ES.Ext := AExt;
      ES.Count := 0;
      ES.Bytes := 0;
      ExtMap.Add(AExt, ES);
    end;
    Inc(ES.Count);
    Inc(ES.Bytes, ABytes);
  end;

  procedure AddFolder(const ADir: string; ABytes: Int64);
  begin
    if ADir = '' then Exit;
    if not FolderMap.TryGetValue(ADir, FS) then
    begin
      FS := THubFolderStat.Create;
      FS.Path := ADir;
      FS.FileCount := 0;
      FS.Bytes := 0;
      FolderMap.Add(ADir, FS);
    end;
    Inc(FS.FileCount);
    Inc(FS.Bytes, ABytes);
  end;

begin
  Result := False;
  if (ARoots = nil) or (ADiscovery = nil) then Exit;
  ADiscovery.Roots.Clear;
  ADiscovery.Files.Clear;
  ADiscovery.Folders.Clear;
  ADiscovery.Exts.Clear;
  ADiscovery.TotalBytes := 0;
  ADiscovery.Truncated := False;
  ADiscovery.MaxFiles := APrefs.MaxFiles;
  ADiscovery.MaxDepth := APrefs.MaxDepth;
  ADiscovery.Mask := APrefs.Mask;
  ADiscovery.IncludeSubdirs := APrefs.IncludeSubdirs;

  for I := 0 to ARoots.Count - 1 do
    if ARoots.Objects[I] is TAgentRoot then
      ADiscovery.Roots.Add(TAgentRoot(ARoots.Objects[I]).Path)
    else
      ADiscovery.Roots.Add(ARoots[I]);

  Files := TStringList.Create;
  ExtMap := TExtBag.Create;
  FolderMap := TFolderBag.Create;
  Notify := TDiscoverNotify.Create;
  try
    Notify.Cancel := ACancel;
    Notify.OnProgress := AOnProgress;
    Notify.Stopped := False;
    AgentExpandRoots(ARoots, APrefs, Files, Notify.ScanTick);

    if Notify.Stopped or Stopped then
      Exit;

    ADiscovery.Truncated := Files.Count >= APrefs.MaxFiles;
    Listed := 0;
    for I := 0 to Files.Count - 1 do
    begin
      if Stopped then Exit;
      Path := Files[I];
      ADiscovery.Files.Add(Path);
      Sz := FileByteSize(Path);
      Inc(ADiscovery.TotalBytes, Sz);
      Ext := NormExt(Path);
      AddExt(Ext, Sz);
      Dir := ExcludeTrailingPathDelimiter(ExtractFilePath(Path));
      AddFolder(Dir, Sz);
      Inc(Listed);
      if Assigned(AOnProgress) and ((Listed mod 50) = 0) then
        AOnProgress(Listed);
    end;

    ExtList := TList<THubExtStat>.Create;
    try
      for ES in ExtMap.Values do
        ExtList.Add(ES);
      ExtMap.Clear;
      ExtList.Sort(
        TComparer<THubExtStat>.Construct(
          function(const L, R: THubExtStat): Integer
          begin
            Result := R.Count - L.Count;
            if Result = 0 then
              Result := CompareText(L.Ext, R.Ext);
          end));
      for I := 0 to ExtList.Count - 1 do
        ADiscovery.Exts.Add(ExtList[I]);
    finally
      ExtList.Free;
    end;

    FolderList := TList<THubFolderStat>.Create;
    try
      for FS in FolderMap.Values do
        FolderList.Add(FS);
      FolderMap.Clear;
      FolderList.Sort(
        TComparer<THubFolderStat>.Construct(
          function(const L, R: THubFolderStat): Integer
          begin
            Result := R.FileCount - L.FileCount;
            if Result = 0 then
              Result := CompareText(L.Path, R.Path);
          end));
      for I := 0 to FolderList.Count - 1 do
        ADiscovery.Folders.Add(FolderList[I]);
    finally
      FolderList.Free;
    end;

    Result := not Stopped;
  finally
    for ES in ExtMap.Values do
      ES.Free;
    ExtMap.Free;
    for FS in FolderMap.Values do
      FS.Free;
    FolderMap.Free;
    Notify.Free;
    Files.Free;
  end;
end;

end.
