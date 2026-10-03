unit unHardwareInformation;

interface

Uses
  Windows, Classes;
Type
  TRProcessorInformation = Record
    Speed           : Integer;
    Level           : Integer;
    Count           : Integer;
    Name            : String;
    Architecture    : String;
    Identifier      : String;
    Revision        : String;
  End;
  TRMemoryInformation = Record
    MemoryUsage     : Integer;
    MemoryTotal     : Integer;
    MemoryAvailable : Integer;
  End;
  TCProcessorInformation = Class
  Private
    RProcessorInformation             : TRProcessorInformation;
    Function    GetProcSpeed          : Integer;
    Function    GetProcLevel          : Integer;
    Function    GetProcCount          : Integer;
    Function    GetProcName           : String;
    Function    GetProcArchitecture   : String;
    Function    GetProcIdentifier     : String;
    Function    GetProcRevision       : String;
    Function    ViewProcSpeed         : Integer;
    Function    ViewProcLevel         : Integer;
    Function    ViewProcCount         : Integer;
    Function    ViewProcName          : String;
    Function    ViewProcArchitecture  : String;
    Function    ViewProcIdentifier    : String;
    Function    ViewProcRevision      : String;
  Public
    Constructor Create;
    Procedure   Refresh;
    Property    ProcSpeed             : Integer Read ViewProcSpeed;
    Property    ProcLevel             : Integer Read ViewProcLevel;
    Property    ProcCount             : Integer Read ViewProcCount;
    Property    ProcName              : String  Read ViewProcName;
    Property    ProcArchitecture      : String  Read ViewProcArchitecture;
    Property    ProcIdentifier        : String  Read ViewProcIdentifier;
    Property    ProcRevision          : String  Read ViewProcRevision;
  End;
  TCMemoryInformation = Class
  Private
    RMemoryInformation                : TRMemoryInformation;
    Function    GetMemoryUsage        : Integer;
    Function    GetMemoryTotal        : Integer;
    Function    GetMemoryAvailable    : Integer;
    Function    ViewMemoryUsage       : Integer;
    Function    ViewMemoryTotal       : Integer;
    Function    ViewMemoryAvailable   : Integer;
  Public
    Constructor Create;
    Procedure   Refresh;
    Property    MemoryUsage           : Integer Read ViewMemoryUsage;
    Property    MemoryTotal           : Integer Read ViewMemoryTotal;
    Property    MemoryAvailable       : Integer Read ViewMemoryAvailable;
  End;
  TCHardDiskInformation = Class
  Public
    Function    GetTotSpace(drv: PChar)    : Integer;
    Function    GetFreeSpace(drv: PChar)   : Integer;
    Function    GetDrvType(drv : PChar)    : String;
    Function    GetFileSysType(drv: PChar) : String;
    Function    GetVolumeName(drv: PChar)  : String;
    Function    GetDrives(var sList: TStringList): Integer;
  End;
  TDrvType = (dtNotDetermined, dtNonExistent, dtRemoveable,
              dtFixed, dtRemote, dtCDROM, dtRamDrive);
implementation
{ IntToStr
  This function is used to convert integers to strings. }
Function IntToStr(Const Value: Integer): String;
Var
  s                 : String[11];
Begin
  Str(Value, s);
  Result := s;
End;
{ StrToInt
  This function is used to convert strings to integers. }
Function StrToInt(Const s: String): Integer;
Var
  e                 : integer;
Begin
  val(s, Result, e);
End;
{ TCProcessorInformation.Create
  This constructor will initialize the processor record. }
Constructor TCProcessorInformation.Create;
Begin
  Inherited;
  Refresh;
End;
{ TCProcessorInformation.Refresh
  This routine will refresh the processor record. }
Procedure TCProcessorInformation.Refresh;
Begin
  RProcessorInformation.Speed         := GetProcSpeed;
  RProcessorInformation.Level         := GetProcLevel;
  RProcessorInformation.Count         := GetProcCount;
  RProcessorInformation.Name          := GetProcName;
  RProcessorInformation.Architecture  := GetProcArchitecture;
  RProcessorInformation.Identifier    := GetProcIdentifier;
  RProcessorInformation.Revision      := GetProcRevision;
End;
{ TCProcessorInformation.ViewProcSpeed
  This routine will return the processor speed. }
Function TCProcessorInformation.ViewProcSpeed: Integer;
Begin
  Result := RProcessorInformation.Speed;
End;
{ TCProcessorInformation.ViewProcCount
  This routine will return the amount of processors. }
Function TCProcessorInformation.ViewProcCount: Integer;
Begin
  Result := RProcessorInformation.Count;
End;
{ TCProcessorInformation.ViewProcLevel
  This routine will return the processor level. }
Function TCProcessorInformation.ViewProcLevel: Integer;
Begin
  Result := RProcessorInformation.Level;
End;
{ TCProcessorInformation.ViewProcName
  This routine will return the processor name. }
Function TCProcessorInformation.ViewProcName: String;
Begin
  Result := RProcessorInformation.Name;
End;
{ TCProcessorInformation.ViewProcArchitecture
  This routine will return the processor architecture. }
Function TCProcessorInformation.ViewProcArchitecture: String;
Begin
  Result := RProcessorInformation.Architecture;
End;
{ TCProcessorInformation.ViewProcIdentifier
  This routine will return the processor identifier. }
Function TCProcessorInformation.ViewProcIdentifier: String;
Begin
  Result := RProcessorInformation.Identifier;
End;
{ TCProcessorInformation.ViewProcRevision
  This routine will return the processor revision. }
Function TCProcessorInformation.ViewProcRevision: String;
Begin
  Result := RProcessorInformation.Revision;
End;
{ TCProcessorInformation.GetProcName
  This routine is used to retrieve the processor name. }
Function TCProcessorInformation.GetProcName: String;
Const
  Size              : Integer = 2048;
Var
  Temp              : HKEY;
  Res               : pChar;
Begin
  GetMem(Res, (MAX_PATH + 1));
  RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_QUERY_VALUE, Temp);
  RegQueryValueEx(HKEY_LOCAL_MACHINE, 'ProcessorNameString', NIL, NIL, pByte(Res), @Size);
  RegCloseKey(Temp);
  Result := pChar(Res);
  FreeMem(Res);
End;
{ TCProcessorInformation.GetProcSpeed
  This routine is used to retrieve the processor speed. }
Function TCProcessorInformation.GetProcSpeed: Integer;
Const
  Size              : Integer = 2048;
Var
  Temp              : HKEY;
Begin
  RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_QUERY_VALUE, Temp);
  RegQueryValueEx(Temp, '~MHz', NIL, NIL, @Result, @Size);
  RegCloseKey(Temp);
End;
{ TCProcessorInformation.GetProcArchitecture
  This routine is used to retrieve the processor architecture. }
Function TCProcessorInformation.GetProcArchitecture: String;
Var
  EnvVarLength      : Integer;
  EnvVarString      : String;
Begin
  Result := '';
  EnvVarLength := GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', NIL, 0);
  If (EnvVarLength > 0) Then
  Begin
    SetLength(EnvVarString, EnvVarLength);
    GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', pChar(EnvVarString), EnvVarLength);
    SetLength(EnvVarString, (EnvVarLength - 1));
    Result := EnvVarString;
  End;
End;
{ TCProcessorInformation.GetProcLevel
  This routine is used to retrieve the processor level. }
Function TCProcessorInformation.GetProcLevel: Integer;
Var
  EnvVarLength      : Integer;
  EnvVarString      : String;
Begin
  Result := -1;
  EnvVarLength := GetEnvironmentVariable('PROCESSOR_LEVEL', NIL, 0);
  If (EnvVarLength > 0) Then
  Begin
    SetLength(EnvVarSTring, EnvVarLength);
    GetEnvironmentVariable('PROCESSOR_LEVEL', pChar(EnvVarString), EnvVarLength);
    SetLength(EnvVarString, (EnvVarLength - 1));
    Result := StrToInt(EnvVarString);
  End;
End;
{ TCProcessorInformation.GetProcIdentifier
  This routine is used to retrieve the processor identifier. }
Function TCProcessorInformation.GetProcIdentifier: String;
Var
  EnvVarLength      : Integer;
  EnvVarString      : String;
Begin
  Result := '';
  EnvVarLength := GetEnvironmentVariable('PROCESSOR_IDENTIFIER', NIL, 0);
  If (EnvVarLength > 0) Then
  Begin
    SetLength(EnvVarSTring, EnvVarLength);
    GetEnvironmentVariable('PROCESSOR_IDENTIFIER', pChar(EnvVarString), EnvVarLength);
    SetLength(EnvVarString, (EnvVarLength - 1));
    Result := EnvVarString;
  End;
End;
{ TCProcessorInformation.GetProcRevision
  This routine is used to retrieve the processor revision. }
Function TCProcessorInformation.GetProcRevision: String;
Var
  EnvVarLength      : Integer;
  EnvVarString      : String;
Begin
  Result := '';
  EnvVarLength := GetEnvironmentVariable('PROCESSOR_REVISION', NIL, 0);
  If (EnvVarLength > 0) Then
  Begin
    SetLength(EnvVarSTring, EnvVarLength);
    GetEnvironmentVariable('PROCESSOR_REVISION', pChar(EnvVarString), EnvVarLength);
    SetLength(EnvVarString, (EnvVarLength - 1));
    Result := EnvVarString;
  End;
End;
{ TCProcessorInformation.GetProcCount
  This routine is used to retrieve the amount of processors. }
Function TCProcessorInformation.GetProcCount: Integer;
Var
  EnvVarLength      : Integer;
  EnvVarString      : String;
Begin
  Result := -1;
  EnvVarLength := GetEnvironmentVariable('NUMBER_OF_PROCESSORS', NIL, 0);
  If (EnvVarLength > 0) Then
  Begin
    SetLength(EnvVarSTring, EnvVarLength);
    GetEnvironmentVariable('NUMBER_OF_PROCESSORS', pChar(EnvVarString), EnvVarLength);
    SetLength(EnvVarString, (EnvVarLength - 1));
    Result := StrToInt(EnvVarString);
  End;
End;
{ TMemoryInformation.Create
  This constructor will initialize the memory record. }
Constructor TCMemoryInformation.Create;
Begin
  Inherited;
  Refresh;
End;
{ TMemoryInformation.Refresh
  This routine will refresh the memory record. }
Procedure TCMemoryInformation.Refresh;
Begin
  RMemoryInformation.MemoryUsage      := GetMemoryUsage;
  RMemoryInformation.MemoryTotal      := GetMemoryTotal;
  RMemoryInformation.MemoryAvailable  := GetMemoryAvailable;
End;
{ TMemoryInformation.ViewMemoryUsage
  This routine will return the amount of memory used. }
Function TCMemoryInformation.ViewMemoryUsage: Integer;
Begin
  Result := RMemoryInformation.MemoryUsage;
End;
{ TMemoryInformation.ViewMemoryTotal
  This routine will return the total amount of physical memory. }
Function TCMemoryInformation.ViewMemoryTotal: Integer;
Begin
  Result := RMemoryInformation.MemoryTotal;
End;
{ TMemoryInformation.ViewMemoryAvailable
  This routine will return the amount of memory available. }
Function TCMemoryInformation.ViewMemoryAvailable: Integer;
Begin
  Result := RMemoryInformation.MemoryAvailable;
End;
{ TMemoryInformation.GetMemoryUsage
  This routine is used to retrieve the amount of memory used. }
Function TCMemoryInformation.GetMemoryUsage: Integer;
Var
  MemoryStatus      : TMemoryStatus;
Begin
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  GlobalMemoryStatus(MemoryStatus);
  Result := Memorystatus.dwMemoryLoad;
End;
{ TMemoryInformation.GetMemoryTotal
  This routine is used to retrieve the total amount of physical memory. }
Function TCMemoryInformation.GetMemoryTotal: Integer;
Var
  MemoryStatus      : TMemoryStatus;
Begin
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  GlobalMemoryStatus(MemoryStatus);
  Result := (MemoryStatus.dwTotalPhys DIV 1048576);
End;
{ TMemoryInformation.GetMemoryAvailable
  This routine is used to retrieve the amount of memory available. }
Function TCMemoryInformation.GetMemoryAvailable: Integer;
Var
  MemoryStatus      : TMemoryStatus;
Begin
  MemoryStatus.dwLength := SizeOf(MemoryStatus);
  GlobalMemoryStatus(MemoryStatus);
  Result := (MemoryStatus.dwAvailPhys DIV 1048576);
End;
{ TCHardDiskInformation.GetDrives
  This routine will give you the name of your drives. }
Function TCHardDiskInformation.GetDrives(var sList: TStringList): Integer;
const
  DRIVE_UNKNOWN             = 0;
  DRIVE_NO_ROOT_DIR         = 1;
  DRIVE_REMOVABLE           = 2;
  DRIVE_FIXED               = 3;
  DRIVE_REMOTE              = 4;
  DRIVE_CDROM               = 5;
  DRIVE_RAMDISK             = 6;
var
  R                         : LongWord;
  Drives                    : Array[0..128] of Char;
  pDrive                    : PChar;
begin
  Result := 0;
  sList.Clear;
  R := GetLogicalDriveStrings(SizeOf(Drives), Drives);
  If r = 0 then
    Exit;
  If R > SizeOf(Drives) then
    Exit;
  pDrive := Drives;
  while pDrive^ <> #0 do
  begin
    if GetDriveType(pDrive) <> DRIVE_UNKNOWN then
      sList.Append(String(pDrive));
    Inc(pDrive, 4);
    Inc(Result, 1);
  end;
end;
{ Here is an example of how to use it. }
{Var
  temp        : Integer;
  sTemp       : TStringList;
  I           : Integer;
begin
  sTemp := TStringList.Create;
  temp := GetDrives(sTemp);
  For i := 0 To (sTemp.Count - 1) Do
  begin
    WriteLn(sTemp.Strings[i]);
    WriteLn('  Volume Name      : ' + GetVolumeName(pChar(sTemp.Strings[i])));
    WriteLn('  Total disk space : ' + IntToStr(GetTotDiskSpace(pChar(sTemp.Strings[i]))) + ' Mb');
    WriteLn('  Free disk space  : ' + IntToStr(GetFreeSpace(pChar(sTemp.Strings[i]))) + ' Mb');
    WriteLn('  File type        : ' + GetFileSysType(pChar(sTemp.Strings[i])));
    WriteLn('  Drive type       : ' + GetDrvType(sTemp.Strings[i]));
    WriteLn;
  end;
}
{ StrPas
  To use StrPas. }
function StrPas(const Str: PChar): string;
begin
  Result := Str;
end;
{ TCHardDisk.GetTotSpace
  This routine will return total space on the drive. }
Function TCHardDiskInformation.GetTotSpace(drv : PChar): Integer;
Var
  TotalSize        : Int64;
  FreeSize         : Int64;
Begin
  GetDiskFreeSpaceEx(drv, TotalSize, FreeSize, NIL);
  FreeSize := FreeSize DIV 1024 DIV 1024;
  Result := FreeSize;
end;
{ TCHardDiskInformation.GetFreeSpace
  This routine will return total free space on the drive. }
Function TCHardDiskInformation.GetFreeSpace(drv: PChar): Integer;
Var
  TotalSize       : Int64;
  FreeSize        : Int64;
Begin
  GetDiskFreeSpaceEx(drv, TotalSize, FreeSize, NIL);
  TotalSize := TotalSize DIV 1024 DIV 1024;
  Result := TotalSize;
End;
{ TCHardDiskInformation.GetDrvType
  This routine will return the drive type. }
Function TCHardDiskInformation.GetDrvType(drv : PChar): String;
Var
  dType           : TDrvType;
Begin
  dType := TDrvType(GetDriveType(PChar(drv)));
  case dType of
    dtNotDetermined : Result := 'Unable to Determine';
    dtNonExistent   : Result := 'Does not exist';
    dtRemoveable    : Result := 'Removable Drive (Floppy)';
    dtFixed         : Result := 'Fixed Disk';
    dtRemote        : Result := 'Remote or Network Drive';
    dtCDROM         : Result := 'CD-ROM Drive';
    dtRamDrive      : Result := 'RAM Drive';
  end;
End;
{ TCHardDiskInformation.GetFileSysType
  This routine will return the file system type. }
Function TCHardDiskInformation.GetFileSysType(drv: PChar): String;
Var
  pFSBuf       : PChar;
  pVolName     : PChar;
  nVNameSer    : PDWORD;
  FSSysFlags   : DWORD;
  maxCmpLen    : DWORD;
Begin
  GetMem(pVolName, MAX_PATH);
  GetMem(pFSBuf, MAX_PATH);
  GetMem(nVNameSer, MAX_PATH);
  GetVolumeInformation(PChar(drv), pVolName, MAX_PATH, nVNameSer, maxCmpLen, FSSysFlags, pFSBuf, MAX_PATH);
  Result := StrPas(pFSBuf);
  FreeMem(pVolName, MAX_PATH);
  FreeMem(pFSBuf, MAX_PATH);
  FreeMem(nVNameSer, MAX_PATH);
End;
{ TCHardDiskInformation.GetVolumeName
  This routine will return the volume name of the drive. }
Function TCHardDiskInformation.GetVolumeName(drv: PChar): String;
Var
  pFSBuf       : PChar;
  pVolName     : PChar;
  nVNameSer    : PDWORD;
  FSSysFlags   : DWORD;
  maxCmpLen    : DWORD;
Begin
  GetMem(pVolName, MAX_PATH);
  GetMem(pFSBuf, MAX_PATH);
  GetMem(nVNameSer, MAX_PATH);
  GetVolumeInformation(PChar(drv), pVolName, MAX_PATH, nVNameSer, maxCmpLen, FSSysFlags, pFSBuf, MAX_PATH);
  Result := StrPas(pVolName);
  FreeMem(pVolName, MAX_PATH);
  FreeMem(pFSBuf, MAX_PATH);
  FreeMem(nVNameSer, MAX_PATH);
End;
End.
