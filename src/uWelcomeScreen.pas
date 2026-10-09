{ ============================================================================
  uWelcomeScreen.pas
  FastFile — Professional start/welcome screen.

  Shows recent files (name, folder, size, modified date, session indicator)
  and recent folders, letting the user open a file or clear the "show on
  startup" preference.

  Entry point:
    TfrmWelcomeScreen.Execute(ARecentFilesIni, AExeDir, AMainIni, OutFile)
    Returns True and OutFile = selected path if user picked a file.
    Returns False if dismissed without selecting.
    Short-circuits (returns False immediately) when the user has ticked
    "Don't show this screen on startup" in ASkin.ini.
  ============================================================================ }
unit uWelcomeScreen;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniFiles, UnConsts;

type
  TfrmWelcomeScreen = class(TForm)
    pnlHeader:         TPanel;
    lblTitle:          TLabel;
    lblTagline:        TLabel;
    lblVersion:        TLabel;
    pnlBottom:         TPanel;
    chkDontShow:       TCheckBox;
    btnOpenFile:       TButton;
    btnOpenSelected:   TButton;
    btnClose:          TButton;
    pnlMain:           TPanel;
    pnlRecentFolders:  TPanel;
    lblRecentFolders:  TLabel;
    lvRecentFolders:   TListView;
    Splitter1:         TSplitter;
    pnlRecentFiles:    TPanel;
    lblRecentFiles:    TLabel;
    lvRecentFiles:     TListView;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnOpenSelectedClick(Sender: TObject);
    procedure lvRecentFilesDblClick(Sender: TObject);
    procedure lvRecentFilesChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure lvRecentFilesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lvRecentFilesCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvRecentFoldersDblClick(Sender: TObject);
    procedure chkDontShowClick(Sender: TObject);

  private
    FSelectedFile:    string;
    FRecentFilesIni:  string;
    FExeDir:          string;
    FMainIni:         string;
    { Cache: key = full path, value = '1' exists / '0' missing }
    FExistsCache:     TStringList;

    procedure LoadData;
    procedure PopulateRecentFolders;
    procedure AcceptSelectedFile;
    procedure RemoveRecentFile(const AFilePath: string);
    function  SessionFileExists(const AFilePath: string): Boolean;
    function  FormatFileSize(const Size: Int64): string;
    function  GetFileModDate(const APath: string): string;
    function  GetFileSizeInt64(const APath: string): Int64;
    function  CachedFileExists(const APath: string): Boolean;

  public
    { Returns True when a file was selected; OutFile receives the full path. }
    class function Execute(
      const ARecentFilesIni: string;
      const AExeDir:         string;
      const AMainIni:        string;
      var   OutFile:         string): Boolean;
  end;

implementation

uses
  uFastFilePaths, uI18n, uFastFileMsgDlg;

{$R *.dfm}

{ ============================================================================ }
{ Form lifecycle                                                                }
{ ============================================================================ }

procedure TfrmWelcomeScreen.FormCreate(Sender: TObject);
begin
  FSelectedFile := '';
  FExistsCache  := TStringList.Create;
  FExistsCache.CaseSensitive := False;
  pnlHeader.DoubleBuffered       := True;
  lvRecentFiles.DoubleBuffered   := True;
  lvRecentFolders.DoubleBuffered := True;
  lblVersion.Caption := APPLICATION_VERSION;
  lblTitle.Caption := APPLICATION_DISPLAY_NAME;
  Caption := APPLICATION_DISPLAY_NAME + ' - Start';
  lblTagline.Caption := TrText('Open and edit multi-gigabyte text files instantly - where other editors can''t keep up. ' +
    'Exclusive features like Python macros, AI to extract/analyze files, and much more.');
  lblTagline.WordWrap := True;
  lblTagline.AutoSize := False;
  lblRecentFiles.Caption := TrText('Recent Files');
  lblRecentFolders.Caption := TrText('Recent Folders');
  btnOpenFile.Caption := TrText('Open File...');
  btnOpenSelected.Caption := TrText('Open Selected');
  btnClose.Caption := TrText('Close');
  chkDontShow.Caption := TrText('Don''t show this screen on startup');
  pnlHeader.Height := 80;
  lblTagline.Width := ClientWidth - 28;
  lblTagline.Height := 36;
end;

procedure TfrmWelcomeScreen.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FExistsCache);
end;

procedure TfrmWelcomeScreen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

{ ============================================================================ }
{ Header gradient painting                                                      }
{ ============================================================================ }

{ ============================================================================ }
{ File system helpers                                                           }
{ ============================================================================ }

function TfrmWelcomeScreen.GetFileSizeInt64(const APath: string): Int64;
var
  FindData: TWin32FindData;
  H: THandle;
begin
  Result := -1;
  if APath = '' then Exit;
  H := FindFirstFile(PChar(APath), FindData);
  if H = INVALID_HANDLE_VALUE then Exit;
  Windows.FindClose(H);
  Result := Int64(FindData.nFileSizeHigh) shl 32 or Int64(FindData.nFileSizeLow);
end;

function TfrmWelcomeScreen.GetFileModDate(const APath: string): string;
var
  FindData: TWin32FindData;
  H: THandle;
  FT: TFileTime;
  ST: TSystemTime;
begin
  Result := '';
  if APath = '' then Exit;
  H := FindFirstFile(PChar(APath), FindData);
  if H = INVALID_HANDLE_VALUE then Exit;
  Windows.FindClose(H);
  FT := FindData.ftLastWriteTime;
  FileTimeToLocalFileTime(FT, FT);
  FileTimeToSystemTime(FT, ST);
  Result := Format('%04d-%02d-%02d  %02d:%02d',
    [ST.wYear, ST.wMonth, ST.wDay, ST.wHour, ST.wMinute]);
end;

function TfrmWelcomeScreen.FormatFileSize(const Size: Int64): string;
const
  KB = Int64(1024);
  MB = Int64(1024) * 1024;
  GB = Int64(1024) * 1024 * 1024;
begin
  if Size < 0 then
    Result := '—'
  else if Size < KB then
    Result := IntToStr(Size) + ' B'
  else if Size < MB then
    Result := Format('%.1f KB', [Size / KB])
  else if Size < GB then
    Result := Format('%.1f MB', [Size / MB])
  else
    Result := Format('%.2f GB', [Size / GB]);
end;

function TfrmWelcomeScreen.CachedFileExists(const APath: string): Boolean;
var
  Idx: Integer;
begin
  Idx := FExistsCache.IndexOfName(APath);
  if Idx >= 0 then
    Result := (FExistsCache.ValueFromIndex[Idx] = '1')
  else
  begin
    Result := SysUtils.FileExists(APath);
    if Result then
      FExistsCache.Values[APath] := '1'
    else
      FExistsCache.Values[APath] := '0';
  end;
end;

function TfrmWelcomeScreen.SessionFileExists(const AFilePath: string): Boolean;
var
  Safe: string;
  I: Integer;
  C: Char;
begin
  Safe := AFilePath;
  for I := 1 to Length(Safe) do
  begin
    C := Safe[I];
    if PosBMH(C, ILLEGAL_FILENAME_CHARS) > 0 then
      Safe[I] := '_';
  end;
  Result := SysUtils.FileExists(FastFileSessionPath(Safe));
end;

{ ============================================================================ }
{ Data loading                                                                  }
{ ============================================================================ }

procedure TfrmWelcomeScreen.LoadData;
var
  Ini: TIniFile;
  I, Cnt: Integer;
  FilePath, FName, FDir, FSizeStr, FDateStr, FSession: string;
  FSize: Int64;
  Exists: Boolean;
  Item: TListItem;
begin
  FExistsCache.Clear;
  lvRecentFiles.Items.BeginUpdate;
  try
    lvRecentFiles.Items.Clear;
    if not SysUtils.FileExists(FRecentFilesIni) then Exit;
    Ini := TIniFile.Create(FRecentFilesIni);
    try
      Cnt := Ini.ReadInteger('RecentFiles', 'Count', 0);
      for I := 0 to Cnt - 1 do
      begin
        FilePath := Trim(Ini.ReadString('RecentFiles', 'File' + IntToStr(I), ''));
        if FilePath = '' then Continue;

        Exists := CachedFileExists(FilePath);

        FName := ExtractFileName(FilePath);
        FDir  := ExcludeTrailingPathDelimiter(ExtractFileDir(FilePath));

        if Exists then
        begin
          FSize    := GetFileSizeInt64(FilePath);
          FSizeStr := FormatFileSize(FSize);
          FDateStr := GetFileModDate(FilePath);
        end
        else
        begin
          FSizeStr := '—';
          FDateStr := '—';
        end;

        if SessionFileExists(FilePath) then
          FSession := '★  saved'
        else
          FSession := '';

        Item := lvRecentFiles.Items.Add;
        Item.Caption := FName;
        Item.SubItems.Add(FDir);
        Item.SubItems.Add(FSizeStr);
        Item.SubItems.Add(FDateStr);
        Item.SubItems.Add(FSession);
      end;
    finally
      Ini.Free;
    end;
  finally
    lvRecentFiles.Items.EndUpdate;
  end;

  PopulateRecentFolders;
end;

procedure TfrmWelcomeScreen.PopulateRecentFolders;
var
  I: Integer;
  Dir: string;
  Folders: TStringList;
  Item: TListItem;
begin
  Folders := TStringList.Create;
  try
    Folders.CaseSensitive := False;
    Folders.Sorted     := True;
    Folders.Duplicates := dupIgnore;
    for I := 0 to lvRecentFiles.Items.Count - 1 do
    begin
      Dir := lvRecentFiles.Items[I].SubItems[0];
      if Dir <> '' then
        Folders.Add(Dir);
    end;

    lvRecentFolders.Items.BeginUpdate;
    try
      lvRecentFolders.Items.Clear;
      for I := 0 to Folders.Count - 1 do
      begin
        Item := lvRecentFolders.Items.Add;
        Item.Caption := Folders[I];
      end;
    finally
      lvRecentFolders.Items.EndUpdate;
    end;
  finally
    Folders.Free;
  end;
end;

{ ============================================================================ }
{ User interaction                                                              }
{ ============================================================================ }

procedure TfrmWelcomeScreen.RemoveRecentFile(const AFilePath: string);
var
  Ini: TIniFile;
  I, Cnt: Integer;
  Paths: TStringList;
  P: string;
begin
  if Trim(AFilePath) = '' then Exit;
  Paths := TStringList.Create;
  try
    if SysUtils.FileExists(FRecentFilesIni) then
    begin
      Ini := TIniFile.Create(FRecentFilesIni);
      try
        Cnt := Ini.ReadInteger('RecentFiles', 'Count', 0);
        for I := 0 to Cnt - 1 do
        begin
          P := Trim(Ini.ReadString('RecentFiles', 'File' + IntToStr(I), ''));
          if (P <> '') and (not SameText(P, AFilePath)) then
            Paths.Add(P);
        end;
      finally
        Ini.Free;
      end;
    end;
    Ini := TIniFile.Create(FRecentFilesIni);
    try
      Ini.EraseSection('RecentFiles');
      Ini.WriteInteger('RecentFiles', 'Count', Paths.Count);
      for I := 0 to Paths.Count - 1 do
        Ini.WriteString('RecentFiles', 'File' + IntToStr(I), Paths[I]);
    finally
      Ini.Free;
    end;
  finally
    Paths.Free;
  end;
  LoadData;
end;

procedure TfrmWelcomeScreen.AcceptSelectedFile;
var
  Item: TListItem;
  FilePath: string;
begin
  Item := lvRecentFiles.Selected;
  if not Assigned(Item) then Exit;
  if Item.SubItems.Count < 1 then Exit;

  { Rebuild full path from the two display columns }
  FilePath := IncludeTrailingPathDelimiter(Item.SubItems[0]) + Item.Caption;

  if not SysUtils.FileExists(FilePath) then
  begin
    FastFileMessageBox(
      PChar(TrText('File not found:') + #13#10 + FilePath),
      'FastFile', MB_OK or MB_ICONWARNING);
    RemoveRecentFile(FilePath);
    Exit;
  end;

  FSelectedFile := FilePath;
  ModalResult   := mrOk;
end;

procedure TfrmWelcomeScreen.lvRecentFilesChange(Sender: TObject;
  Item: TListItem; Change: TItemChange);
begin
  btnOpenSelected.Enabled := Assigned(lvRecentFiles.Selected);
end;

procedure TfrmWelcomeScreen.lvRecentFilesDblClick(Sender: TObject);
begin
  AcceptSelectedFile;
end;

procedure TfrmWelcomeScreen.lvRecentFilesKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    AcceptSelectedFile
  else if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure TfrmWelcomeScreen.lvRecentFilesCustomDrawItem(
  Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  FilePath: string;
  FileFound: Boolean;
begin
  DefaultDraw := True;
  if (not Assigned(Item)) or (Item.SubItems.Count < 1) then Exit;

  FilePath  := IncludeTrailingPathDelimiter(Item.SubItems[0]) + Item.Caption;
  FileFound := (FExistsCache.Values[FilePath] = '1');

  if cdsSelected in State then
    Sender.Canvas.Font.Color := clHighlightText
  else if not FileFound then
    Sender.Canvas.Font.Color := clGrayText
  else
    Sender.Canvas.Font.Color := clWindowText;
end;

procedure TfrmWelcomeScreen.lvRecentFoldersDblClick(Sender: TObject);
var
  Item: TListItem;
begin
  Item := lvRecentFolders.Selected;
  if not Assigned(Item) then Exit;
  with TOpenDialog.Create(nil) do
  try
    InitialDir := Item.Caption;
    Filter     := 'All files (*.*)|*.*';
    Options    := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
    if Execute then
    begin
      FSelectedFile := FileName;
      ModalResult   := mrOk;
    end;
  finally
    Free;
  end;
end;

procedure TfrmWelcomeScreen.btnOpenFileClick(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
  try
    Filter  := 'All files (*.*)|*.*';
    Options := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
    if Execute then
    begin
      FSelectedFile := FileName;
      ModalResult   := mrOk;
    end;
  finally
    Free;
  end;
end;

procedure TfrmWelcomeScreen.btnOpenSelectedClick(Sender: TObject);
begin
  AcceptSelectedFile;
end;

procedure TfrmWelcomeScreen.chkDontShowClick(Sender: TObject);
var
  Ini: TIniFile;
begin
  if FMainIni = '' then Exit;
  Ini := TIniFile.Create(FMainIni);
  try
    if chkDontShow.Checked then
      Ini.WriteInteger(APPLICATION_NAME, 'WelcomeScreenShow', 0)
    else
      Ini.WriteInteger(APPLICATION_NAME, 'WelcomeScreenShow', 1);
  finally
    Ini.Free;
  end;
end;

{ ============================================================================ }
{ Class entry point                                                             }
{ ============================================================================ }

class function TfrmWelcomeScreen.Execute(
  const ARecentFilesIni: string;
  const AExeDir:         string;
  const AMainIni:        string;
  var   OutFile:         string): Boolean;
var
  Frm: TfrmWelcomeScreen;
  Ini: TIniFile;
  ShowValue: Integer;
begin
  Result  := False;
  OutFile := '';

  { Read show-preference from ASkin.ini (default = 1 = show) }
  ShowValue := 1;
  if SysUtils.FileExists(AMainIni) then
  begin
    Ini := TIniFile.Create(AMainIni);
    try
      ShowValue := Ini.ReadInteger(APPLICATION_NAME, 'WelcomeScreenShow', 1);
    finally
      Ini.Free;
    end;
  end;
  if ShowValue = 0 then Exit;

  Frm := TfrmWelcomeScreen.Create(nil);
  try
    Frm.FRecentFilesIni := ARecentFilesIni;
    Frm.FExeDir         := IncludeTrailingPathDelimiter(AExeDir);
    Frm.FMainIni        := AMainIni;
    Frm.chkDontShow.Checked := False; { ShowValue = 1 means we do show }
    Frm.LoadData;
    if Frm.ShowModal = mrOk then
    begin
      OutFile := Frm.FSelectedFile;
      Result  := (OutFile <> '');
    end;
  finally
    Frm.Free;
  end;
end;

end.
