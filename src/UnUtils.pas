unit UnUtils;

interface

uses
  uPosBMH,
  SysUtils, Math, Types, Windows, Forms, Controls, TypInfo, Classes, ExtCtrls, ComCtrls, StdCtrls, Mask,
  StopWatch, ShellApi, Dialogs, sLabel, Graphics, ImageHlp, DateUtils, Tlhelp32, UnConsts;

type
  TPromptResult = record
    Option: Integer;   // 1 = Incluir, 2 = Editar, 3 = Cancelar
    Text: string;      // Texto digitado (opcional)
  end;

  TPromptForm = class(TForm)
  private
    FEdit: TEdit;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor CreatePrompt(AOwner: TComponent); reintroduce;
  end;

type
  TActionComponent = (acVisible, acNotVisible, acEnabled, acNotEnabled, acClear);
type
  WinIsWow64 = function( Handle: THandle; var Iret: BOOL ): Windows.BOOL; stdcall;

  function DefaultDateFormat(const Value: string): string;
  function RoundWithDecimals(X: double; Decimals: integer): Double;
  function GetFmtFileVersion(const FileName: String = ''; const Fmt: String = '%d.%d.%d.%d'): String;
  procedure TrimAppMemorySize;
  function FormatMillisecondsToDateTime(const ms: integer): string;
  function CheckFileName(const sFileName: string): Boolean;
  function CheckFile(const sFileName: string): Boolean;
  procedure ActionComponent(const ArrayCtrls: array of TControl; const cActionComponent: TActionComponent);
  procedure ClearControls(const ArrayCtrls: array of TControl);
  function GetTmpDir: string;
  function IsNumber(strNumber: String): Boolean;
  function getNumberValue(const Search: string): string;
  function GetFileSize(const FileName: String): Int64;
  { Delphi 7: TFileStream.Seek/Size truncam >2 GB; usar com ficheiros grandes. }
  procedure FileStreamSeek64(const AStream: TFileStream; const AOffset: Int64; Origin: Word);
  function FileStreamSize64(const AStream: TFileStream): Int64;
  Function ExtractName(const Filename: String): String;
  function myShellCopyFile(FormHandle: THandle; StrFrom, StrTo: string; BlnSilent: Boolean = False): Boolean;
  function OpenLongFileName(ALongFileName: string; DesiredAccess, ShareMode, CreationDisposition: LongWord): THandle;
  function CreateLongFileName(const ALongFileName: String; SharingMode: DWORD): THandle; overload;
  function CustomFileCopy(const ASourceFileName, ADestinationFileName: TFileName): boolean;
  procedure DelTree(const Directory: TFileName);
  function MyMessageDlg(const Msg: string; DlgTypt: TmsgDlgType; button: TMsgDlgButtons;
      Caption: array of string; dlgcaption: string): Integer;
  function showForm(const title: string; const text: string): TModalResult;
  function GetFirstWord(const S: string): string;
  function GetStrAfterSubstr(const Substr, Str: string): string;
  function MessageBox(const title: string; const body: string; const buttonInfoText: string = 'OK'; const bShowCheckBox: Boolean = False): Boolean;
  function SplitString(Text, Separator: string): TStringList;
  function ExtractPageNumberFromLineString(const str: string): Int64;
  function MessageDlgCustom(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; ToCaptions: array of string;
    var CheckVar: Boolean; const bShowCheckBox: Boolean = False; customFont: TFont = nil) : integer;
  function MessageDlgDefCheck(const Msg: string; AType: TMsgDlgType; AButtons: TMsgDlgButtons; ABtnCaptions: Array of String;
    DefButton: TModalResult; CheckText: String; var CheckVar: Boolean): Word;
  function LoadTextFromFile(FileName: string): string;
  procedure SaveTextToFile(FileName, Text: string);
  //Boyer-Moore-Horspool text searching
  function Search(pat: string; text: string): integer;
  function IAmIn64Bits: Boolean;
  function GetAppBitnessText: string;
  function GetDisplayVersion(const IncludeBitness: Boolean = True): string;
  function GetFileLastWriteDateTime(FileName: String): TDateTime;
  function extractText(const text: string): String;
  procedure DeleteDirectory(const DirName: string);
  function FormatNumber(l: Int64): string;
  function FormatMoney(const Text: string; const Decimals: Word = 2; const useSign: Boolean = True): string;
  procedure Terminate;
  function IsAppRunning(ExeFileName: String): Boolean;
  function LoadConfig(const showDeveloperInfo: Boolean = False): string;
  procedure AppendToTextFile(ffilename: string; line: string);
  procedure ExtractResource(const ResName, OutputFile: string);
  function keepOnlyLetters(p: pAnsiChar): AnsiString;
  function ShowMemoForm(const Title, LabelText, InitialText: string; var MemoContent: string): TModalResult;
  function PromptOptions(const ATitulo: string): TPromptResult;
  procedure PackFolder(const InputDir, OutputFile: string);
  procedure ExtractDirResource(const ResourceName, OutputDir: string);
  function ExecuteWithoutFreezing(const Command: string): Boolean;
  { AInteractive=False: sem MessageDlg/ShowMessage (uso no fecho da app / limpeza). }
  function ForceDeleteFile(const APath: string; AInteractive: Boolean = False): Boolean;
  { Apaga sem di�logos; repete em caso de ficheiro em uso (ex.: fecho da app com Tail). }
  function TryDeleteFileWithRetry(const APath: string; ARetries: Integer = 5;
    ASleepMs: Integer = 50): Boolean;
  { Snapshot do ficheiro no disco (tamanho + ftLastWriteTime) para detetar alteracoes externas. }
  procedure GetFileSizeAndWriteTime(const FileName: string; out Size: Int64; out LastWrite: TFileTime);
  function SameFileSizeAndWriteTime(const FileName: string; const Size: Int64; const LastWrite: TFileTime): Boolean;
  { Escreve temp e substitui destino com retries (padrao save atomico). }
  function TryRenameTempOverTarget(const TempPath, TargetPath: string; out ErrMsg: string): Boolean;
  { Espaco livre no volume (falha API = False, AFreeBytes=0). }
  function VolumeFreeBytes(const AnyPathOnVolume: string; out AFreeBytes: Int64): Boolean;
  { Verifica espaco livre no volume que contem AnyPathOnVolume (falha API = assume OK). }
  function VolumeHasMinFreeBytes(const AnyPathOnVolume: string; const MinFree: Int64): Boolean;

implementation

uses
  uI18n, uFastFileMsgDlg;

function DefaultDateFormat(const Value: string): string;
var
  AuxDay, AuxMonth, AuxYear: string;
  IntDay, IntMonth, IntYear: smallint;
begin
  Result := Value;
  if (Value = '') then Exit;
  if PosBMH('-', Value) = 0 then Exit;

  AuxYear := copy(Value,1,4);
  AuxMonth := copy(Value,6,2);
  AuxDay := copy(Value,9,2);

  IntDay := StrToIntDef(AuxDay, 10);
  IntMonth := StrToIntDef(AuxMonth, 10);
  IntYear := StrToIntDef(AuxYear, 1900);

  Result := SysUtils.FormatFloat('00', IntDay) + '/' + SysUtils.FormatFloat('00', IntMonth) + '/' + IntToStr(IntYear);
end;

function RoundWithDecimals(X: double;
  Decimals: integer): Double;
var
  Mult: Double;
begin
  Mult := Power(10, Decimals);
  Result := Trunc(X*Mult+0.5*Sign(X))/Mult;
end;

{**************************************************************************************}
{                                                                                      }
{    Function:    GetFmtFileVersion                                                    }
{    Description: The GetFmtFileVersion function reads the file resource of "FileName" }
{    and returns the version number as formatted text.                                 }
{                                                                                      }
{                                                                                      }
{    Copyright � : Douglas, 2005                                                       }
{    Site:     http://www.delphipages.com/forum/showthread.php?t=144890                }
{                                                                                      }
{**************************************************************************************}
{
 Example of use:
     GetFmtFileVersion() = '4.13.128.0'
     GetFmtFileVersion('', '%.2d-%.2d-%.2d') = '04-13-128'

     Remarks:
       If "Fmt" is invalid, the function may raise an EConvertError exception.

     Parameters:
       "FileName": Full path to exe or dll. If an empty string is passed, the function
       uses the filename of the running exe or dll.
       "Fmt":  Format string, you can use at most four integer values.

     Result: Formatted version number of file, '' if no version resource found.
}
function GetFmtFileVersion(const FileName, Fmt: String): String;
var
  sFileName: String;
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  iVer: array[1..4] of Word;
begin
  // set default value
  Result := '';
  // get filename of exe/dll if no filename is specified
  sFileName := FileName;
  if (sFileName = '') then
  begin
    // prepare buffer for path and terminating #0
    SetLength(sFileName, MAX_PATH + 1);
    SetLength(sFileName,
      GetModuleFileName(hInstance, PChar(sFileName), MAX_PATH + 1));
  end;
  // get size of version info (0 if no version info exists)
  iBufferSize := GetFileVersionInfoSize(PChar(sFileName), iDummy);
  if (iBufferSize > 0) then
  begin
    GetMem(pBuffer, iBufferSize);
    try
    // get fixed file info (language independent)
    GetFileVersionInfo(PChar(sFileName), 0, iBufferSize, pBuffer);
    VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
    // read version blocks
    iVer[1] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
    iVer[2] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
    iVer[3] := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    iVer[4] := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    finally
      FreeMem(pBuffer);
    end;
    // format result string
    Result := Format('v%s', [Format(Fmt, [iVer[1], iVer[2], iVer[3], iVer[4]])]);
  end;    
end;

procedure TrimAppMemorySize;
var
  hProcess: THandle;
begin
  hProcess := OpenProcess(PROCESS_SET_QUOTA, false, GetCurrentProcessId);
  try
    SetProcessWorkingSetSize(hProcess, $FFFFFFFF, $FFFFFFFF);
  finally
    CloseHandle(hProcess);
  end;
  Application.ProcessMessages;
end;

function FormatMillisecondsToDateTime(const ms: integer): string;
var
  dt : TDateTime;
begin
  dt := ms / MSecsPerSec / SecsPerDay;
  result := Format('%s', [FormatDateTime('hh:nn:ss.z', Frac(dt))]);
end;

function CheckFileName(const sFileName: string): Boolean;
var
  dwAttr:  DWORD;
begin
  Result := (sFileName <> '');
  if not Result then Exit;

  Result := sysUtils.FileExists(sFileName);
  if not Result then Exit;

  // Get file attributes
  dwAttr := GetFileAttributes(PChar(sFileName));
  // Check
  result := (dwAttr <> $FFFFFFFF) and ((dwAttr and FILE_ATTRIBUTE_DIRECTORY) = 0);
end;

function CheckFile(const sFileName: string): Boolean;
begin
  Result := CheckFileName(sFileName);
  //if not Result then
  //  FastFileMessageBox(cInvalidFileName, 'Error', MB_OK + MB_ICONERROR);
end;

{**************************************************************************************}
{                                                                                      }
{    Procedure:    ActionComponent                                                     }
{    Description: The ActionComponent procedure  automatically performs the methods    }
{    "Enabled / Not Enabled / Visible / Not Visible" using SetOrdProp procedure.       }
{    It is also used the procedure "IsPublishedProp" to check if a property of this    }
{    component exists, before changing its contents.                                   }
{                                                                                      }
{                 It uses internally the SetOrdProp procedure from TypInfo unit,       }
{    to set the value of a component property that is an ordinal type.                 }
{    SetOrdProp utilises Delphi's RTTI (Run Time Type Information) to set the value of }
{    a component's property where that property is an Integer, Char, WideChar, or      }
{    Class type.                                                                       }
{
{    Copyright � : Hamden Vogel, 2015                                                  }
{    Email:  hamdenvogel@gmail.com                                                     }
{                                                                                      }
{**************************************************************************************}
{
 Example of use:
 1 - Set visible components:
   ActionComponent([edit1, edit2, label1, label2], acVisible);
 2 - Set invisible components:
   ActionComponent([edit1, edit2, label1, label2], acNotVisible);
 3 - Set enabled components:
   ActionComponent([edit1, edit2, label1, label2], acEnabled);
 4 - Set disabled components:
   ActionComponent([edit1, edit2, label1, label2], acNotEnabled);
 5 - Empty components:
   ActionComponent([edit1, edit2, label1, label2], acClear);  
}
procedure ActionComponent(const ArrayCtrls: array of TControl; const cActionComponent: TActionComponent);
var
  i: integer;
begin
  case Ord(cActionComponent) of
    0:   for i := 0 to High(ArrayCtrls) do
           if IsPublishedProp(ArrayCtrls[i],'Visible') then
             SetOrdProp(ArrayCtrls[i],'Visible', 1);
    1:   for i := 0 to High(ArrayCtrls) do
           if IsPublishedProp(ArrayCtrls[i],'Visible') then
             SetOrdProp(ArrayCtrls[i],'Visible', 0);
    2:   for i := 0 to High(ArrayCtrls) do
           if IsPublishedProp(ArrayCtrls[i],'Enabled') then
             SetOrdProp(ArrayCtrls[i],'Enabled', 1);
    3:   for i := 0 to High(ArrayCtrls) do
           if IsPublishedProp(ArrayCtrls[i],'Enabled') then
             SetOrdProp(ArrayCtrls[i],'Enabled', 0);
    4:   ClearControls(ArrayCtrls);
  end; // end case
end;

procedure ClearControls(const ArrayCtrls: array of TControl);
var
  i: integer;
begin
  for i := 0 to High(ArrayCtrls) do
  begin
    if TComponent(ArrayCtrls[i]) is TMemo       then
      TMemo(TComponent(ArrayCtrls[i])).Clear;
    if TComponent(ArrayCtrls[i]) is TRichEdit   then
      TRichEdit(TComponent(ArrayCtrls[i])).Clear;
    if TComponent(ArrayCtrls[i]) is TRadioGroup then
      TRadioGroup(TComponent(ArrayCtrls[i])).ItemIndex := -1;
    if TComponent(ArrayCtrls[i]) is TMaskedit   then
      TMaskedit(TComponent(ArrayCtrls[i])).Clear;
    if TComponent(ArrayCtrls[i]) is TComboBox   then
      TComboBox(TComponent(ArrayCtrls[i])).Items.Clear;
    if TComponent(ArrayCtrls[i]) is TStaticText then
      TComboBox(TComponent(ArrayCtrls[i])).Text := EmptyStr;
    if TComponent(ArrayCtrls[i]) is TLabel      then
      TLabel(TComponent(ArrayCtrls[i])).Caption := EmptyStr;
    if TComponent(ArrayCtrls[i]) is TEdit       then
      TEdit(TComponent(ArrayCtrls[i])).Clear;
  end;
end;

function GetTmpDir: string;
var
  pc: PChar;
begin
  pc := StrAlloc(MAX_PATH + 1);
  try
    GetTempPath(MAX_PATH, pc);
    // Result := IncludeTrailingPathDelimiter(string(pc));
    Result := ExcludeTrailingPathDelimiter(string(pc));
  finally
    StrDispose(pc);
  end;
end;

function IsNumber(strNumber: String): Boolean;
var
  i : Integer;
begin
  for i:=1 to Length(strNumber) do
  begin
    if not (strNumber[i] in [#48..#57]) then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := (strNumber <> '');
end;

function GetAppBitnessText: string;
begin
  if SizeOf(Pointer) = 8 then
    Result := '64-bit'
  else
    Result := '32-bit';
end;

function GetDisplayVersion(const IncludeBitness: Boolean = True): string;
begin
  Result := 'v' + APPLICATION_VERSION;
  if IncludeBitness then
    Result := Result + '  (' + GetAppBitnessText + ')';
end;

function getNumberValue(const Search: string): string;
var
  index: byte;
begin
  index := PosBMH(': ', Search);
  if index = 0 then
  begin
    Result := '';
  end
  else
  begin
    Result := Copy(Search, index + Length(': '), length(Search));
    index := PosBMH(' ', Result);
    Result := SysUtils.Trim(copy(Result,1, index-1));
    Result := StringReplace(Result, '.', '', [rfReplaceAll]);
  end;
end;

{**************************************************************************************}
{                                                                                      }
{    Function:    GetFileSize                                                          }
{    Description: The GetFileSize function determines the size of a file in bytes.     }
{                 The size can be more than 2 GB.                                      }
{                                                                                      }
{    Copyright � : Hamden Vogel, 2015                                                  }
{    Email:  hamdenvogel@gmail.com                                                     }
{                                                                                      }
{**************************************************************************************}
function GetFileSize(const FileName: String): Int64;
var
  myFile: THandle;
  myFindData: TWin32FindData;
begin
  // set default value
  Result := 0;
  // get the file handle.
  myFile := FindFirstFile(PChar(FileName), myFindData);
  if (myFile <> INVALID_HANDLE_VALUE) then
  begin
    Windows.FindClose(myFile);
    Int64Rec(Result).Lo := myFindData.nFileSizeLow;
    Int64Rec(Result).Hi := myFindData.nFileSizeHigh;
  end;
end;

procedure FileStreamSeek64(const AStream: TFileStream; const AOffset: Int64; Origin: Word);
var
  Lo, Hi: Longint;
  Res: DWORD;
  MoveMethod: DWORD;
begin
  Lo := Longint(Longword(AOffset and $FFFFFFFF));
  Hi := Longint(AOffset shr 32);
  case Origin of
    0: MoveMethod := FILE_BEGIN;
    1: MoveMethod := FILE_CURRENT;
    2: MoveMethod := FILE_END;
  else
    MoveMethod := FILE_BEGIN;
  end;
  Res := SetFilePointer(AStream.Handle, Lo, @Hi, MoveMethod);
  if (Res = DWORD(-1)) and (GetLastError <> 0) then
    RaiseLastWin32Error;
end;

function FileStreamSize64(const AStream: TFileStream): Int64;
var
  Lo, Hi: Longint;
begin
  Hi := 0;
  Lo := SetFilePointer(AStream.Handle, 0, @Hi, FILE_END);
  if (Lo = -1) and (GetLastError <> 0) then
    RaiseLastWin32Error;
  Result := Int64(Cardinal(Lo)) or (Int64(Hi) shl 32);
end;

function ExtractName(const Filename: String): String;
var
  aExt : String;
  aPos : Integer;
begin
  aExt := ExtractFileExt(Filename);
  Result := ExtractFileName(Filename);

  if aExt <> '' then
  begin
    aPos := PosBMH(aExt,Result);

    if aPos > 0 then
    begin
      Delete(Result,aPos,Length(aExt));
    end;
  end;
end;

function myShellCopyFile(FormHandle: THandle; StrFrom,
  StrTo: string; BlnSilent: Boolean): Boolean;
var
  F : TShFileOpStruct;
begin
  F.Wnd:=FormHandle;
  F.wFunc:=FO_COPY;
  F.pFrom:=PChar(StrFrom+#0);
  F.pTo:=PChar(StrTo+#0);
  F.fFlags := FOF_ALLOWUNDO or FOF_RENAMEONCOLLISION;
  if BlnSilent then
    F.fFlags := F.fFlags or FOF_SILENT;
  if ShFileOperation(F) <> 0 then
    result:=False
  else
    result:=True;
end;

function OpenLongFileName(ALongFileName: string; DesiredAccess,
  ShareMode, CreationDisposition: LongWord): THandle;
var
  IsUNC: Boolean;
  FileName: PWideChar;
begin
  // Translate relative paths to absolute ones
  ALongFileName := ExpandFileName(ALongFileName);
  // Check if already an UNC path
  IsUNC := Copy(ALongFileName, 1, 2) = '\\';
  if not IsUNC then
    ALongFileName := '\\?\' + ALongFileName;
  // Preparing the FileName for the CreateFileW API call
  FileName := PWideChar(WideString(ALongFileName));
  // Calling the API
  Result := CreateFileW(FileName, DesiredAccess, ShareMode, nil,
    CreationDisposition, FILE_ATTRIBUTE_NORMAL, 0);
end;

function CreateLongFileName(const ALongFileName: String;
  SharingMode: DWORD): THandle;
begin
  if CompareMem(@(ALongFileName[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    Result := CreateFileW(PWideChar(WideString(ALongFileName)), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFileW(PWideChar(WideString('\\?\' + ALongFileName)), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
end;

function CustomFileCopy(const ASourceFileName,
  ADestinationFileName: TFileName): boolean;
const
  BUFFER_SIZE = $F000; // 512KB blocks, change this to tune your speed
  //BUFFER_SIZE = 262144;
var
  Buffer: array of Byte;
  ASourceFile, ADestinationFile: THandle;
  FileSize, BytesRead, BytesWritten, BytesWritten2, TotalBytesWritten,
  CreationDisposition: LongWord;
  CanContinue, CanContinueFlag: Boolean;
begin
  FileSize := 0;
  TotalBytesWritten := 0;
  CanContinue := True;
  SetLength(Buffer, BUFFER_SIZE);

  // Manage the Creation Disposition flag
  CreationDisposition := OPEN_ALWAYS;
  // Opening the source file in read mode
  ASourceFile := OpenLongFileName(ASourceFileName, GENERIC_READ, 0, OPEN_EXISTING);
  if ASourceFile <> 0 then
  try
    FileSize := FileSeek(ASourceFile, 0, FILE_END);
    FileSeek(ASourceFile, 0, FILE_BEGIN);
    // Opening the destination file in write mode (in create/append state)
    ADestinationFile := OpenLongFileName(ADestinationFileName, GENERIC_WRITE,
      FILE_SHARE_READ, CreationDisposition);
    if ADestinationFile <> 0 then
    try
      // If append mode, jump to the file end
      FileSeek(ADestinationFile, 0, FILE_END);
      // For each blocks in the source file
      while CanContinue and (LongWord(FileSeek(ASourceFile, 0, FILE_CURRENT)) < FileSize) do
      begin
        // Reading from source
        if (Windows.ReadFile(ASourceFile, Buffer[0], BUFFER_SIZE, BytesRead, nil)) and (BytesRead <> 0) then
        begin
          // Writing to destination
          Windows.WriteFile(ADestinationFile, Buffer[0], BytesRead, BytesWritten, nil);
          // Read/Write secure code block (e.g. for WiFi connections)
          if BytesWritten < BytesRead then
          begin
            Windows.WriteFile(ADestinationFile, Buffer[BytesWritten], BytesRead - BytesWritten, BytesWritten2, nil);
            Inc(BytesWritten, BytesWritten2);
            if BytesWritten < BytesRead then
              RaiseLastOSError;
          end;
          // Notifying the caller for the current state
          Inc(TotalBytesWritten, BytesWritten);
          CanContinueFlag := True;
          CanContinue := CanContinue and CanContinueFlag;
        end;
      end;
    finally
      CloseHandle(ADestinationFile);
    end;
  finally
    CloseHandle(ASourceFile);
  end;
  // Check if cancelled or not
  if not CanContinue then
    if FileExists(ADestinationFileName) then
      DeleteFile(PChar(ADestinationFileName));
  // Results (checking CanContinue flag isn't needed)
  Result := (FileSize <> 0) and (FileSize = TotalBytesWritten);
end;

procedure DelTree(const Directory: TFileName);
var
  DrivesPathsBuff: array[0..1024] of char;
  DrivesPaths: string;
  len: longword;
  ShortPath: array[0..MAX_PATH] of char;
  dir: TFileName;
procedure rDelTree(const Directory: TFileName);
// Recursively deletes all files and directories
// inside the directory passed as parameter.
var
  SearchRec: TSearchRec;
  Attributes: LongWord;
  ShortName, FullName: TFileName;
  pname: pchar;
begin
  if FindFirst(Directory + '*', faAnyFile and not faVolumeID,
    SearchRec) = 0 then
  begin
    try
    repeat // Processes all files and directories
      if SearchRec.FindData.cAlternateFileName [0] = #0 then
        ShortName := SearchRec.Name
      else
         ShortName := SearchRec.FindData.cAlternateFileName;
       FullName := Directory + ShortName;
       if (SearchRec.Attr and faDirectory) <> 0 then
       begin
         // It's a directory
         if (ShortName <> '.') and (ShortName <> '..') then
           rDelTree(FullName + '\');
       end else
       begin
         // It's a file
         pname := PChar(FullName);
         Attributes := GetFileAttributes(pname);
         if Attributes = $FFFFFFFF then
           raise EInOutError.Create(SysErrorMessage(GetLastError));
         if (Attributes and FILE_ATTRIBUTE_READONLY) <> 0 then
           SetFileAttributes(pname, Attributes and not
             FILE_ATTRIBUTE_READONLY);
         if Windows.DeleteFile(pname) = False then
           raise EInOutError.Create(SysErrorMessage(GetLastError));
       end;
    until FindNext(SearchRec) <> 0;
    except
      SysUtils.FindClose(SearchRec);
    raise;
  end;
   SysUtils.FindClose(SearchRec);
  end;
  if PosBMH(#0 + Directory + #0, DrivesPaths) = 0 then
  begin
   // if not a root directory, remove it
    pname := PChar(Directory);
    Attributes := GetFileAttributes(pname);
    if Attributes = $FFFFFFFF then
      raise EInOutError.Create(SysErrorMessage(GetLastError));
    if (Attributes and FILE_ATTRIBUTE_READONLY) <> 0 then
      SetFileAttributes(pname, Attributes and not FILE_ATTRIBUTE_READONLY);
    if Windows.RemoveDirectory(pname) = False then
    begin
      raise EInOutError.Create(SysErrorMessage(GetLastError));
    end;
  end;
end;
// ----------------
begin
  DrivesPathsBuff[0] := #0;
  len := GetLogicalDriveStrings(1022, @DrivesPathsBuff[1]);
  if len = 0 then
    raise EInOutError.Create(SysErrorMessage(GetLastError));
  SetString(DrivesPaths, DrivesPathsBuff, len + 1);
  DrivesPaths := Uppercase(DrivesPaths);
  len := GetShortPathName(PChar(Directory), ShortPath, MAX_PATH);
  if len = 0 then
    raise EInOutError.Create(SysErrorMessage(GetLastError));
  SetString(dir, ShortPath, len);
  dir := Uppercase(dir);
  rDelTree(IncludeTrailingBackslash(dir));
end;

function MyMessageDlg(const Msg: string; DlgTypt: TmsgDlgType;
  button: TMsgDlgButtons; Caption: array of string;
  dlgcaption: string): Integer;
var
  aMsgdlg: TForm;
  i: Integer;
  Dlgbutton: Tbutton;
  Captionindex: Integer;
begin
  aMsgdlg := createMessageDialog(Msg, DlgTypt, button);
  aMsgdlg.Caption := dlgcaption;
  aMsgdlg.BiDiMode := bdRightToLeft;
  Captionindex := 0;
  for i := 0 to aMsgdlg.componentcount - 1 Do
  begin
    if (aMsgdlg.components[i] is Tbutton) then
    Begin
      Dlgbutton := Tbutton(aMsgdlg.components[i]);
      if Captionindex <= High(Caption) then
        Dlgbutton.Caption := Caption[Captionindex];
      inc(Captionindex);
    end;
  end;
  Result := aMsgdlg.Showmodal;
end;

function showForm(const title: string; const text: string): TModalResult;
var
  frm: TForm;
  lbl: TLabel;
  lblTemp: TLabel;
  btnYes, btnNo: TButton;
begin
  frm := TForm.Create(nil);
  try
    lbl := TLabel.Create(frm);
    lblTemp := TLabel.Create(frm);
    btnYes := TButton.Create(frm);
    btnNo := TButton.Create(frm);
    frm.BorderStyle := bsDialog;
    frm.Caption := title;
    frm.Width := 300;
    frm.Position := poScreenCenter;

    lbl.Parent := frm;
    lbl.Top := 8;
    lbl.Left := 8;
    lbl.Caption := text;

    lblTemp.Parent := frm;
    lblTemp.Top := lbl.Top + lbl.Height + 8;
    lblTemp.Left := 8;
    lblTemp.Width := 200;

    btnYes.Parent := frm;
    btnYes.Caption := TrText('Yes');
    btnYes.Default := true;
    btnYes.ModalResult := mrYes;
    btnYes.Top := lblTemp.Top + lblTemp.Height + 8;
    btnYes.Left := lblTemp.Left + lblTemp.Width - btnYes.Width - btnNo.Width;

    btnNo.Parent := frm;
    btnNo.Caption := TrText('No');
    btnNo.Default := true;
    btnNo.ModalResult := mrNo;
    btnNo.Top := lblTemp.Top + lblTemp.Height + 8;
    btnNo.Left := lblTemp.Left + lblTemp.Width - btnYes.Width + 10;

    frm.ClientHeight := btnYes.Top + btnYes.Height + 8;
    frm.ClientWidth := lblTemp.Left + lblTemp.Width + 8;

    case frm.ShowModal of
      mrYes: Result := mrYes;
      mrNo: Result := mrNo;
    else
      Result := mrCancel;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

function GetFirstWord(const S: string): string;
var
  P: integer;
begin
  Result := S;
  P := PosBMH(' ', Result);
  Result := StringReplace((Copy(Result,1, P-1)),'.','',[rfReplaceAll]);
end;

function GetStrAfterSubstr(const Substr, Str: string): string;
var
  P: integer;
begin
  Result := Str;
  P := PosBMH(Substr, Result);
  Result :=  trim(GetFirstWord(trim(Copy(Result, P+1, length(result)))));
end;

function MessageBox(const title: string; const body: string; const buttonInfoText: string = 'OK'; const bShowCheckBox: Boolean = False): Boolean;
var
  checkVar: Boolean;
  Cap, Msg: string;
begin
  Result := False;
  Cap := Trim(title);
  if Cap = '' then
    Cap := 'Information';
  Cap := TrText(Cap);
  Msg := TrText(body);
  if bShowCheckBox then
  begin
    MessageDlgCustom(Msg, mtInformation, [mbOK], ['&Ok'], checkVar);
    Result := checkVar;
  end
  else
    FastFileMsgInfo(Msg, Cap);
end;

function SplitString(Text, Separator: string): TStringList;
var
  S, P, Tot : string;
  i, a : integer;
  Lista : TStringList;
begin
  Lista := TStringList.Create;
  S := Separator;
  a := 1;
  for i := 0 to length(Text) do
  begin
    if (i <= length(Text)) then
    begin
      P := copy(Text,a,1);
      if ( P <> S )and( P <> '') then
        Tot := Tot + P
    else
    begin
      Lista.add(Tot);
      Tot := ''; P := '';
    end;
  inc(a);
    end
  end;
  result := Lista;
end;

function ExtractPageNumberFromLineString(const str: string): Int64;
var
  strFound: TStringList;
begin
  Result := -1;
  strFound := TStringList.Create;
  try
    try
      strFound := UnUtils.SplitString(str, ' ');
      Result := StrToInt64Def((Trim(StringReplace(strFound[1], '.', '', [rfReplaceAll]))), 0);
    except
      Result := -1;
    end;    
  finally
    FreeAndNil(strFound);
  end;
end;

function GetTextWidth(s: string; fnt: TFont; HWND: THandle): integer;
var
  canvas: TCanvas;
begin
  canvas := TCanvas.Create;
  try
    canvas.Handle := GetWindowDC(HWND);
    canvas.Font := fnt;
    Result := canvas.TextWidth(s);
  finally
    ReleaseDC(HWND,canvas.Handle);
    FreeAndNil(canvas);
  end;  //try-finally
end;

function MessageDlgCustom(const Msg: string;
  DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; ToCaptions: array of string; var CheckVar: Boolean;
  const bShowCheckBox: Boolean = False; customFont: TFont = nil): integer;
const
  c_BtnMargin = 10;  //margin of button around caption text
var
  dialog: TForm;
  i, oldButtonWidth, newButtonWidth, btnCnt: integer;
  msgWidth: integer;
  checkBox : TCheckBox;
begin
  try
    dialog := CreateMessageDialog(Msg, DlgType, Buttons);
    dialog.Position := poScreenCenter;
    oldButtonWidth := 0;
    newButtonWidth := 0;
    btnCnt := 0;
    msgWidth := 0;
    if bShowCheckBox then
    begin
      checkBox := TCheckBox.Create(dialog);
      with checkBox do
      begin
        Parent := dialog;
        Font.Name := dialog.Font.Name;
        Font.Size := dialog.Font.Size;
        Font.Style := Font.Style - [fsBold];
        Caption := 'Don''t show me again.';
        dialog.Height := dialog.Height + 20;
        Width := dialog.Canvas.TextWidth(Caption) + 50;
        Top := dialog.ClientHeight - Height - 10;
        Left := 8;
        Checked := CheckVar;
      end;
    end;
    for i := 0 to dialog.ComponentCount - 1 do begin
      //if they asked for a custom font, assign it here
      if customFont <> nil then begin
        if dialog.Components[i] is TLabel then begin
          TLabel(dialog.Components[i]).Font := customFont;
        end;
        if dialog.Components[i] is TButton then begin
          TButton(dialog.Components[i]).Font := customFont;
        end;
      end;

      if dialog.Components[i] is TButton then begin
        //check buttons for a match with a "from" (default) string
        //if found, replace with a "to" (custom) string
        Inc(btnCnt);

        //record the button width *before* we changed the caption
        oldButtonWidth := oldButtonWidth + TButton(dialog.Components[i]).Width;

        //if a custom caption has been provided use that instead,
        //or just leave the default caption if the custom caption is empty
        if ToCaptions[btnCnt - 1] <>'' then
          TButton(dialog.Components[i]).Caption := ToCaptions[btnCnt - 1];

        //auto-size the button for the new caption
        TButton(dialog.Components[i]).Width :=
          GetTextWidth(TButton(dialog.Components[i]).Caption,
            TButton(dialog.Components[i]).Font, dialog.Handle) + c_BtnMargin;

        //the first button can stay where it is.
        //all other buttons need to slide over to the right of the one b4.
        if (1 < btnCnt) and (0 < i) then begin
          TButton(dialog.Components[i]).Left :=
            TButton(dialog.Components[i-1]).Left +
            TButton(dialog.Components[i-1]).Width + c_BtnMargin;
        end;       
        //record the button width *after* changing the caption
        newButtonWidth := newButtonWidth + TButton(dialog.Components[i]).Width;
      end;  //if TButton
    end;  //for i

    //if it�s just one button lets align center to the form
    if (btnCnt = 1) and (length(ToCaptions) = 1) then
    begin
      for i := 0 to dialog.ComponentCount - 1 do
      begin
        if dialog.Components[i] is TButton then
        begin
          TButton(dialog.Components[i]).Width :=
            GetTextWidth(ToCaptions[0], TButton(dialog.Components[i]).Font, dialog.Handle) + c_BtnMargin;
          msgWidth := TButton(dialog.Components[i]).Width;
          TButton(dialog.Components[i]).Left := Trunc(dialog.clientWidth/2)-(c_BtnMargin * 3);
        end;
      end;
      dialog.Width := Round(dialog.Width + (newButtonWidth - oldButtonWidth) +
        (c_BtnMargin * btnCnt)) + msgWidth;
    end
    else
      //whatever we changed the buttons by, widen / shrink the form accordingly
      dialog.Width := Round(dialog.Width + (newButtonWidth - oldButtonWidth) +
        (c_BtnMargin * btnCnt));

    Result := dialog.ShowModal;
    if Assigned(checkBox) and (bShowCheckBox) then
      CheckVar := checkBox.Checked;
  finally
    if Assigned(checkBox) and (bShowCheckBox) then FreeAndNil(checkBox);
    dialog.Release;
  end;
end;

function MessageDlgDefCheck(const Msg: string; AType: TMsgDlgType;
  AButtons: TMsgDlgButtons; ABtnCaptions : Array of String;
  DefButton: TModalResult; CheckText: String; var CheckVar: Boolean): Word;
var
  i : Integer;
  CurrBtn : Integer;
  MessageDialog : TForm;
  CheckBox : TCheckBox;
begin
  // cria a message dialog
  MessageDialog := CreateMessageDialog(Msg, AType, AButtons);
  with MessageDialog do
  try
    CurrBtn := 0;
    // procura os bot�es
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TButton then begin
        // altera o t�tulo do bot�o encontrado
        with TButton(Components[i]) do
          if CurrBtn <= High(ABtnCaptions) then begin
            Caption := ABtnCaptions[CurrBtn];
            Inc(CurrBtn);
          end;
        // altera o bot�o default
        if DefButton = ModalResult then
          ActiveControl := TButton(Components[i]);
      end;
    // se CheckText <> '' tem checkbox
    if CheckText <> '' then begin
      // aumenta altura da caixa
      Height := Height + 15;
      // cria checkbox
      CheckBox := TCheckBox.Create(MessageDialog);
      // configura checkbox
      with CheckBox do begin
        Parent := MessageDialog;
        Caption := CheckText;
        // posiciona checkbox na parte de baixo da janela
        Top := MessageDialog.ClientHeight - Height - 4;
        Left := 10;
        Width := Canvas.TextWidth(Caption) + 30;
        Checked := CheckVar;
      end;
    end
    else
      Checkbox := nil;
    // mostra caixa
    Result := ShowModal;
    // atualiza vari�vel de checagem
    if Assigned(CheckBox) then
      CheckVar := CheckBox.Checked;
  finally
    Free;
  end;
end;

function LoadTextFromFile(FileName: string): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  Try
    SetLength(Result, Stream.Size div SizeOf(Char));
    if Length(Result)>0 then
      Stream.ReadBuffer(Result[1], Length(Result)*SizeOf(Char));
  Finally
    Stream.Free;
  End;
end;

procedure SaveTextToFile(FileName, Text: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  Try
    if Length(Text)>0 then
      Stream.WriteBuffer(Text[1], Length(Text)*SizeOf(Char));
  Finally
    Stream.Free;
  End;
end;

function Search(pat: string; text: string): integer;
var
  i, j, k, m, n: integer;
  skip: array [0..MAXCHAR] of integer;
  found: boolean;
begin
  found := FALSE;
  Search := 0;
  m := length(pat);
  if m=0 then
  begin
    Search := 1;
    found := TRUE;
  end;
  for k:=0 to MAXCHAR do
    skip[k] := m;   {*** Preprocessing ***}
  for k:= m-1 downto 1 do
    skip[ord(pat[k])] := m-k;
  k := m;
  n := length(text);            {*** Search ***}
  while not found and (k <= n) do
  begin
    i := k; j := m;
    while (j >= 1) do
    begin
      if text[i] <> pat[j] then
        j := -1
      else
      begin
        j := j-1;
        i := i-1;
      end;
      if j = 0 then
      begin
        Search := i+1;
        found := TRUE;
      end;
      k := k + skip[ord(text[k])];
    end;
  end;
end;

function IAmIn64Bits: Boolean;
var
  HandleTo64BitsProcess: WinIsWow64;
  Iret                 : Windows.BOOL;
begin
  Result := False;
  HandleTo64BitsProcess := GetProcAddress(GetModuleHandle('kernel32.dll'), 'IsWow64Process');
  if Assigned(HandleTo64BitsProcess) then
  begin
    if not HandleTo64BitsProcess(GetCurrentProcess, Iret) then
      Raise Exception.Create('Invalid handle');
    Result := Iret;
  end;
end;

function GetFileLastWriteDateTime(FileName: String): TDateTime;
var
  F : TSearchRec;
begin
  SysUtils.FindFirst(filename,faAnyFile,F);
  try
    //Result := F.Time;
    //if you wanted a TDateTime, change the return type and use this line:
    Result := FileDateToDatetime(F.Time);
  finally
    SysUtils.FindClose(F);
  end;  
end;

function extractText(const text: string): String;
var
  index: byte;
begin
  index := PosBMH(': ', text);
  if index = 0 then
  begin
    Result := '';
  end
  else
  begin
    Result := Copy(text, index + Length(': '), length(text));
    index := PosBMH(' ', Result);
    Result := copy(Result,1, index-1);
  end;
end;

procedure DeleteDirectory(const DirName: string);
var
  FileOp: TSHFileOpStruct;
begin
  FillChar(FileOp, SizeOf(FileOp), 0);
  FileOp.wFunc := FO_DELETE;
  FileOp.pFrom := PChar(DirName+#0);//double zero-terminated
  FileOp.fFlags := FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  SHFileOperation(FileOp);
end;

function FormatNumber(l: Int64): string;
var
 len, count: integer;
 s: string;
begin
  str(l, s);
  len := length(s);
  for count := ((len - 1) div 3) downto 1 do
  begin
    insert('.', s, len - (count * 3) + 1);
    len := len + 1;
  end;
  FormatNumber := s;
end;

function FormatMoney(const Text: string; const Decimals: Word = 2; const useSign: Boolean = True): string;
begin
  case useSign of
    True: Result := Format('%s %s', [FormatSettings.CurrencyString, FormatFloat(Format('0,.%s', [StringOfChar('0',Decimals)]), StrToFloatDef(StringReplace(Text, '.', ',', [rfReplaceAll]),0))]);
    False: Result := FormatFloat(Format('0,.%s', [StringOfChar('0',Decimals)]), StrToFloatDef(StringReplace(Text, '.', ',', [rfReplaceAll]),0));
  end;
end;

procedure Terminate;
function GetPIDbyProcessName(processName:String):integer;
var 
  GotProcess: Boolean; 
  tempHandle: tHandle; 
  procE: tProcessEntry32;
begin
  tempHandle:=CreateToolHelp32SnapShot(TH32CS_SNAPALL, 0); 
  procE.dwSize:=SizeOf(procE); 
  GotProcess:=Process32First(tempHandle, procE);
  {$B-} 
    if GotProcess and not SameText(procE.szExeFile, processName) then 
      repeat GotProcess := Process32Next(tempHandle, procE); 
      until (not GotProcess) or SameText(procE.szExeFile,processName); 
  {$B+}

  if GotProcess then 
    result := procE.th32ProcessID 
  else
    result := 0; // process not found in running process list

  CloseHandle(tempHandle);
end;
begin
  TerminateProcess(OpenProcess(PROCESS_ALL_ACCESS,False,GetPIDbyProcessName(ExtractFileName(ParamStr(0)))),0);
end;

(*
procedure TForm1.Button1Click(Sender: TObject);
Var
  xExeFileName: String;
begin
  xExeFileName := 'chrome.exe';
  if IsAppRunning(xExeFileName) then
  begin
    ShowMessage(xExeFileName + ' is running !!!');
  end
  else
  begin
    ShowMessage(xExeFileName + ' is NOT running !!!');
  end;
end;

*)
function IsAppRunning(ExeFileName: String): Boolean;
const
   PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := False;

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase
        (ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase
        (ExeFileName))) then
    begin
      Result := True;
      Exit;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function LoadConfig(const showDeveloperInfo: Boolean = False): string;
var
  strVersion: string;
  b64bits: Boolean;
  str3264Bits, str3264BitsVersion: string;
  strDateTimeBuild: string;
begin
  strVersion := UnUtils.GetDisplayVersion(False);
  b64bits := UnUtils.IAmIn64Bits;
  if b64bits then str3264Bits := '64' else str3264Bits := '32';
  str3264BitsVersion := Format('(%s) bits', [str3264Bits]);
  strDateTimeBuild := Format('Build time: %s', [DateTimeToStr(UnUtils.GetFileLastWriteDateTime(Application.ExeName))]);
  case showDeveloperInfo of
    True: Result := Format('%s %s %s %s', [strVersion, str3264BitsVersion, Format(#13#10'%s', [strDateTimeBuild]),
    Format(#13#10'%s', [APPLICATION_DEVELOPER])]);
    False: Result := Format('%s %s %s', [strVersion, str3264BitsVersion, strDateTimeBuild]);
  end;
end;

procedure AppendToTextFile(ffilename: string; line: string);
var
  FileTXT: TextFile;
begin
  try
    AssignFile(FileTXT, ffilename);
    if FileExists(ffilename) then
    begin
      Append(FileTXT);
      Flush(FileTXT);
    end
    else
      Rewrite(FileTXT);
    Writeln(FileTXT, line);
  finally
    //Flush(FileTXT);
    CloseFile(FileTXT);
  end;
end;

{
Fun��o para incluir um arquivo dentro do execut�vel:
1 - Copiar o arquivo a ser inclu�do para o mesmo diret�rio dos fontes do programa.
2 - Criar um arquivo com extens�o .rc, por exemplo temp.rc e colocar a seguinte linha:
(substituir arquivo.txt pelo arquivo a ser inclu�do)
NOME       RCDATA DISCARDABLE "arquivo.txt"
3 - Digitar:
brcc32 -32 temp.rc -fotemp.res
4 - No arquivo .PAS, colocar a seguinte linha depois do implementation:
{$R temp.res}
{5 - Utilizar esta procedure abaixo:
Ao chamar a procedure extractResource('NOME', '.\arquivo.txt'); o arquivo vai ser extra�do para o diret�rio atual
}
procedure ExtractResource(const ResName, OutputFile: string);
var
  ResStream: TResourceStream;
begin
  ResStream := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
  try
    ResStream.SaveToFile(OutputFile);
  finally
    ResStream.Free;
  end;
end;

function keepOnlyLetters(p: pAnsiChar): AnsiString;
var
  rP: pAnsiChar;
  k: LongWord;
  c: AnsiChar;
begin
  rP := p;
  k := 0;

  // 1: Conta quantos caracteres N�O s�o letras
  while rP^ <> #0 do
  begin
    c := rP^;
    if not ((c in ['A'..'Z']) or (c in ['a'..'z'])) then
      Inc(k); // Conta quantos ser�o removidos
    Inc(rP);
  end;

  // 2: Define o tamanho do resultado
  SetLength(Result, LongWord(rP - p) - k);

  // 3: Copia apenas letras para o resultado
  rP := pAnsiChar(Result);
  while p^ <> #0 do
  begin
    c := p^;
    if (c in ['A'..'Z']) or (c in ['a'..'z']) then
    begin
      rP^ := c;
      Inc(rP);
    end;
    Inc(p);
  end;
end;

function ShowMemoForm(const Title, LabelText, InitialText: string; var MemoContent: string): TModalResult;
var
  frm: TForm;
  lbl: TLabel;
  memo: TMemo;
  btnYes, btnNo: TButton;
begin
  frm := TForm.Create(nil);
  try
    frm.BorderStyle := bsDialog;
    frm.Caption := Title;
    frm.Position := poScreenCenter;
    frm.Width := 420;
    frm.Height := 320;
    frm.KeyPreview := True; // importante para capturar teclas

    // Label
    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.Caption := LabelText;
    lbl.Top := 8;
    lbl.Left := 8;

    // Memo
    memo := TMemo.Create(frm);
    memo.Parent := frm;
    memo.Top := lbl.Top + lbl.Height + 8;
    memo.Left := 8;
    memo.Width := frm.ClientWidth - 16;
    memo.Height := 160;
    memo.ScrollBars := ssVertical;
    memo.Text := InitialText;
    memo.TabOrder := 0;

    // Bot�o YES
    btnYes := TButton.Create(frm);
    btnYes.Parent := frm;
    btnYes.Caption := TrText('Yes');
    btnYes.ModalResult := mrYes;
    btnYes.Default := True;   // Enter ? Yes
    btnYes.Top := memo.Top + memo.Height + 10;
    btnYes.Left := frm.ClientWidth div 2 - btnYes.Width - 10;
    btnYes.TabOrder := 1;

    // Bot�o NO
    btnNo := TButton.Create(frm);
    btnNo.Parent := frm;
    btnNo.Caption := TrText('No');
    btnNo.ModalResult := mrNo;
    btnNo.Cancel := True;     // Esc ? No
    btnNo.Top := btnYes.Top;
    btnNo.Left := btnYes.Left + btnYes.Width + 20;
    btnNo.TabOrder := 2;

    // Ajustar altura total do form
    frm.ClientHeight := btnYes.Top + btnYes.Height + 12;

    // Mostrar o form de forma modal
    Result := frm.ShowModal;

    // Retornar o texto digitado no Memo (somente se clicou Yes)
    if Result = mrYes then
      MemoContent := memo.Text;
  finally
    frm.Free;
  end;
end;

procedure PromptFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = Ord('1') then
    TForm(Sender).ModalResult := 1
  else if Key = Ord('2') then
    TForm(Sender).ModalResult := 2
  else if Key = Ord('3') then
    TForm(Sender).ModalResult := 3;
end;

function PromptOptions(const ATitulo: string): TPromptResult;
var
  frm: TPromptForm;
begin
  FillChar(Result, SizeOf(Result), 0);

  frm := TPromptForm.CreatePrompt(nil);
  try
    frm.Caption := ATitulo;
    Result.Option := frm.ShowModal;
    Result.Text := Trim(frm.FEdit.Text);
  finally
    frm.Free;
  end;
end;

{ TPromptForm }

constructor TPromptForm.CreatePrompt(AOwner: TComponent);
var
  lbl: TLabel;
  btn1, btn2, btn3: TButton;
begin
  inherited CreateNew(AOwner);
  Caption := 'Escolha uma op��o';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  BorderIcons := [];      // ? Remove bot�o "X"
  Width := 360;
  Height := 220;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;

  lbl := TLabel.Create(Self);
  lbl.Parent := Self;
  lbl.Caption :=
    'Tecle uma das op��es abaixo:' + sLineBreak +
    '1 - Incluir' + sLineBreak +
    '2 - Editar' + sLineBreak +
    '3 - Cancelar e voltar';
  lbl.Left := 20;
  lbl.Top := 20;
  lbl.Width := 300;

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Left := 20;
  FEdit.Top := 100;
  FEdit.Width := 300;
  FEdit.Text := '';
  FEdit.Hint := 'Digite algo (opcional)';
  FEdit.ShowHint := True;

  btn1 := TButton.Create(Self);
  btn1.Parent := Self;
  btn1.Caption := '1 - Incluir';
  btn1.ModalResult := 1;
  btn1.Left := 20;
  btn1.Top := 140;

  btn2 := TButton.Create(Self);
  btn2.Parent := Self;
  btn2.Caption := '2 - Editar';
  btn2.ModalResult := 2;
  btn2.Left := 130;
  btn2.Top := 140;

  btn3 := TButton.Create(Self);
  btn3.Parent := Self;
  btn3.Caption := '3 - Cancelar';
  btn3.ModalResult := 3;
  btn3.Left := 240;
  btn3.Top := 140;
end;

procedure TPromptForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    Ord('1'), VK_NUMPAD1: ModalResult := 1;
    Ord('2'), VK_NUMPAD2: ModalResult := 2;
    Ord('3'), VK_NUMPAD3: ModalResult := 3;
  end;
end;

procedure PackFolder(const InputDir, OutputFile: string);
var
  SR: TSearchRec;
  OutFS: TFileStream;
  Mem: TMemoryStream;
  F: TFileStream;
  FileCount, NameLen: Integer;
  FileName: string;
  FileNameAnsi: AnsiString;
  FileSize: Integer;
  SearchResult: Integer;
begin
  Mem := TMemoryStream.Create;
  try
    // contar arquivos
    FileCount := 0;
    SearchResult := FindFirst(IncludeTrailingPathDelimiter(InputDir) + '*.*', faAnyFile, SR);
    try
      while SearchResult = 0 do
      begin
        if (SR.Attr and faDirectory) = 0 then
          Inc(FileCount);
        SearchResult := FindNext(SR);
      end;
    finally
      // use a vers�o de SysUtils
      SysUtils.FindClose(SR);
    end;

    // gravar quantidade
    Mem.WriteBuffer(FileCount, SizeOf(FileCount));

    // agora empacotar arquivos
    SearchResult := FindFirst(IncludeTrailingPathDelimiter(InputDir) + '*.*', faAnyFile, SR);
    try
      while SearchResult = 0 do
      begin
        if (SR.Attr and faDirectory) = 0 then
        begin
          FileName := SR.Name;
          FileNameAnsi := AnsiString(FileName);
          NameLen := Length(FileNameAnsi);
          Mem.WriteBuffer(NameLen, SizeOf(NameLen));
          if NameLen > 0 then
            Mem.WriteBuffer(FileNameAnsi[1], NameLen);

          F := TFileStream.Create(IncludeTrailingPathDelimiter(InputDir) + FileName, fmOpenRead or fmShareDenyNone);
          try
            FileSize := F.Size;
            Mem.WriteBuffer(FileSize, SizeOf(FileSize));
            Mem.CopyFrom(F, FileSize);
          finally
            F.Free;
          end;
        end;
        SearchResult := FindNext(SR);
      end;
    finally
      SysUtils.FindClose(SR);
    end;

    // salvar arquivo final
    OutFS := TFileStream.Create(OutputFile, fmCreate);
    try
      Mem.Position := 0;
      OutFS.CopyFrom(Mem, Mem.Size);
    finally
      OutFS.Free;
    end;
  finally
    Mem.Free;
  end;
end;

procedure ExtractDirResource(const ResourceName, OutputDir: string);
var
  RS: TResourceStream;
  Count, Len, FileSize: Integer;
  FileNameAnsi: AnsiString;
  FileName: string;
  FS: TFileStream;
  OutDir: string;
begin
  OutDir := IncludeTrailingPathDelimiter(OutputDir);
  if not DirectoryExists(OutDir) then
    ForceDirectories(OutDir);

  RS := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
  try
    // N�mero de arquivos
    RS.ReadBuffer(Count, SizeOf(Count));

    while Count > 0 do
    begin
      // Ler nome
      RS.ReadBuffer(Len, SizeOf(Len));
      SetLength(FileNameAnsi, Len);
      if Len > 0 then
        RS.ReadBuffer(FileNameAnsi[1], Len);
      FileName := string(FileNameAnsi);

      // Ler tamanho conte�do
      RS.ReadBuffer(FileSize, SizeOf(FileSize));

      // Criar arquivo
      FS := TFileStream.Create(OutDir + FileName, fmCreate);
      try
        FS.CopyFrom(RS, FileSize);
      finally
        FS.Free;
      end;

      Dec(Count);
    end;
  finally
    RS.Free;
  end;
end;

function ExecuteWithoutFreezing(const Command: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CommandPChar: array[0..MAX_PATH] of Char;
  ExitCode: Cardinal; // In Delphi 7, DWORD is Cardinal
begin
  Result := False;

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE; // Remains hidden

  StrPCopy(CommandPChar, Command);

  if CreateProcess(nil, CommandPChar, nil, nil, False, 0, nil, nil, SI, PI) then
  begin
    try
      // "SMART" WAIT LOOP
      repeat
        // 1. Frees Delphi to draw the screen and accept clicks
        Application.ProcessMessages; 
        
        // 2. Pause for 50ms to avoid using 100% CPU unnecessarily
        Sleep(50); 
        
        // 3. Checks the status of the process
        GetExitCodeProcess(PI.hProcess, ExitCode);
        
      until ExitCode <> STILL_ACTIVE; // Exits the loop when it is no longer active

      Result := True; // Execution finished
    finally
      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
    end;
  end;
end;

function TryDeleteFileWithRetry(const APath: string; ARetries: Integer;
  ASleepMs: Integer): Boolean;
var
  Attributes: Cardinal;
  I: Integer;
begin
  Result := False;
  if Trim(APath) = '' then Exit;
  if not FileExists(APath) then
  begin
    Result := True;
    Exit;
  end;
  Attributes := GetFileAttributes(PChar(APath));
  if Attributes <> $FFFFFFFF then
    SetFileAttributes(PChar(APath), FILE_ATTRIBUTE_NORMAL);
  if ARetries < 1 then ARetries := 1;
  if ASleepMs < 0 then ASleepMs := 0;
  for I := 1 to ARetries do
  begin
    if Windows.DeleteFile(PChar(APath)) then
    begin
      Result := True;
      Exit;
    end;
    if (I < ARetries) and (ASleepMs > 0) then
      Sleep(ASleepMs);
  end;
end;

function ForceDeleteFile(const APath: string; AInteractive: Boolean): Boolean;
var
  Attributes: Cardinal;
  LastError: DWORD;
  Msg: string;
  Retries: Integer;
begin
  Result := False;

  if not FileExists(APath) then
  begin
    Result := True;
    Exit;
  end;

  Attributes := GetFileAttributes(PChar(APath));
  if Attributes <> $FFFFFFFF then
    SetFileAttributes(PChar(APath), FILE_ATTRIBUTE_NORMAL);

  if AInteractive then
    Retries := 3
  else
    Retries := 12;
  if TryDeleteFileWithRetry(APath, Retries, 50) then
  begin
    Result := True;
    Exit;
  end;

  if not AInteractive then
    Exit;

  Windows.DeleteFile(PChar(APath));
  LastError := GetLastError;

  case LastError of
    ERROR_ACCESS_DENIED:
      Msg := TrText('FF_DELETE_ACCESS_DENIED');
    ERROR_SHARING_VIOLATION:
      Msg := TrText('FF_DELETE_SHARING_VIOLATION');
    else
      Msg := Format(TrText('FF_DELETE_UNKNOWN_ERROR'), [IntToStr(LastError)]);
  end;

  if (LastError = ERROR_ACCESS_DENIED) or (LastError = ERROR_SHARING_VIOLATION) then
  begin
    if MessageDlg(Msg + #13#10#13#10 + TrText('FF_DELETE_SCHEDULE_REBOOT_QUESTION'),
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if MoveFileEx(PChar(APath), nil, MOVEFILE_DELAY_UNTIL_REBOOT) then
      begin
        ShowMessage(TrText('FF_DELETE_SCHEDULED_REBOOT_OK'));
        Result := True;
      end
      else
        ShowMessage(TrText('FF_DELETE_SCHEDULE_REBOOT_FAIL'));
    end;
  end
  else
    ShowMessage(TrText('FF_DELETE_COULD_NOT_DELETE') + Msg);
end;

procedure GetFileSizeAndWriteTime(const FileName: string; out Size: Int64; out LastWrite: TFileTime);
var
  H: THandle;
  FD: TWin32FindData;
begin
  Size := 0;
  FillChar(LastWrite, SizeOf(LastWrite), 0);
  H := Windows.FindFirstFile(PChar(FileName), FD);
  if H = INVALID_HANDLE_VALUE then
    Exit;
  Windows.FindClose(H);
  Int64Rec(Size).Lo := FD.nFileSizeLow;
  Int64Rec(Size).Hi := FD.nFileSizeHigh;
  LastWrite := FD.ftLastWriteTime;
end;

function SameFileSizeAndWriteTime(const FileName: string; const Size: Int64; const LastWrite: TFileTime): Boolean;
var
  CurSize: Int64;
  CurLW: TFileTime;
begin
  Result := False;
  if not FileExists(FileName) then
    Exit;
  GetFileSizeAndWriteTime(FileName, CurSize, CurLW);
  Result := (CurSize = Size) and CompareMem(@CurLW, @LastWrite, SizeOf(TFileTime));
end;

function TryRenameTempOverTarget(const TempPath, TargetPath: string; out ErrMsg: string): Boolean;
var
  i: Integer;
  LastErr: DWORD;
  Bak: string;
begin
  Result := False;
  ErrMsg := '';
  if not FileExists(TempPath) then
  begin
    if TempPath <> '' then
      ErrMsg := Format(TrText('Temporary output file was not created.') + ' (%s)', [TempPath])
    else
      ErrMsg := TrText('Temporary output file was not created.');
    Exit;
  end;
  if FileExists(TargetPath) then
  begin
    if not TryDeleteFileWithRetry(TargetPath, 24, 100) then
    begin
      Bak := TargetPath + '.' + FormatDateTime('hhnnss', Now) + '.ffbak';
      TryDeleteFileWithRetry(Bak, 6, 50);
      if not RenameFile(TargetPath, Bak) then
      begin
        ErrMsg := TrText('FF_DELETE_SHARING_VIOLATION');
        TryDeleteFileWithRetry(TempPath, 8, 50);
        Exit;
      end;
      TryDeleteFileWithRetry(Bak, 6, 50);
    end;
  end;
  LastErr := 0;
  for i := 1 to 120 do
  begin
    if RenameFile(TempPath, TargetPath) then
    begin
      Result := FileExists(TargetPath);
      if not Result then
      begin
        ErrMsg := TrText('Rename reported success but target file is missing.');
        if FileExists(TempPath) then
          TryDeleteFileWithRetry(TempPath, 8, 50);
      end;
      Exit;
    end;
    LastErr := GetLastError;
    Sleep(100);
  end;
  { Cross-volume or locked target: copy temp over target, then remove temp. }
  if CustomFileCopy(TempPath, TargetPath) and FileExists(TargetPath) then
  begin
    Result := True;
    TryDeleteFileWithRetry(TempPath, 12, 80);
    Exit;
  end;
  ErrMsg := Format(TrText('Could not finalize save (rename). Error %d: %s'), [LastErr, SysErrorMessage(LastErr)]);
  TryDeleteFileWithRetry(TempPath, 8, 50);
end;

type
  { Mesmo layout que ULARGE_INTEGER na API GetDiskFreeSpaceExA. }
  TULargeIntegerRec = packed record
    LowPart: LongWord;
    HighPart: LongWord;
  end;

function UnKernelGetDiskFreeSpaceExA(lpDirectoryName: PChar;
  lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'GetDiskFreeSpaceExA';

function VolumeFreeBytes(const AnyPathOnVolume: string; out AFreeBytes: Int64): Boolean;
var
  Dir: string;
  FreeU, TotalU, TFreeU: TULargeIntegerRec;
begin
  Result := False;
  AFreeBytes := 0;
  Dir := ExtractFilePath(ExpandFileName(AnyPathOnVolume));
  if Dir = '' then
    Exit;
  FillChar(FreeU, SizeOf(FreeU), 0);
  FillChar(TotalU, SizeOf(TotalU), 0);
  FillChar(TFreeU, SizeOf(TFreeU), 0);
  { Evita conflito com varias declaracoes de GetDiskFreeSpaceEx no Windows.pas (Int64 vs PLargeInteger). }
  if not UnKernelGetDiskFreeSpaceExA(PChar(Dir), @FreeU, @TotalU, @TFreeU) then
    Exit;
  AFreeBytes := Int64(FreeU.LowPart) + (Int64(FreeU.HighPart) shl 32);
  Result := True;
end;

function VolumeHasMinFreeBytes(const AnyPathOnVolume: string; const MinFree: Int64): Boolean;
var
  FreeBytes: Int64;
begin
  Result := True;
  if MinFree <= 0 then
    Exit;
  if not VolumeFreeBytes(AnyPathOnVolume, FreeBytes) then
    Exit;
  Result := FreeBytes >= MinFree;
end;

end.

