{*************************************************************************
*      Biblioteca de Funes
*      Autor: Hamden Vogel
*
*      Freeware.
*      Escrito em Delphi 7.
*      Copyright 2006-2024  Hamden Vogel
*      Tambm existem funes de domnio pblico.
*      ltima Atualizao: 05/10/2024.
*
*************************************************************************}
{$WARNINGS OFF}


unit Biblioteca;
interface
uses uPosBMH, Windows, Messages, SysUtils, Classes, Controls, Variants, ExtCtrls, Graphics, Forms, Dialogs,
StdCtrls, Buttons, DB, ADODB,  Grids, DBGrids, ComObj, ComCtrls, Mask, ShlObj, ActiveX, QuickRpt,
DBCtrls, ShellAPI, DateUtils, Printers, {QRTEE,}  Series, Urlmon, Winsock, StrUtils, Tlhelp32, Richedit,
Clipbrd, IdSMTP, IdMessage, TypInfo,  DBClient, DBTables;

const
  DIGITS  = ['0'..'9'];
  //TNumbs  = ['0'..'9'];    //Set of numerical chars
  vet_valido: array [0..35] of string = ('0','1','2','3','4','5','6','7',
  '8','9','a','b','c','d','e','f', 'g','h','i','j','k','l','m','n', 'o',
  'p','q','r','s','t','u','v', 'w','x','y','z');
const
  CWhitespace   = [#32, #9, #13, #10];
const
  cUnknownCharacter  = #$3F;  // ? unknown char
const
  cNULL   = #0;         //Blank char
  cNONE   = $00;        //Blank number
const
  cHexChars = '0123456789ABCDEF';
  cSoundexTable: array[65..122] of Byte =
   ({A}0, {B}1, {C}2, {D}3, {E}0, {F}1, {G}2, {H}0, {I}0, {J}2, {K}2, {L}4, {M}5,
    {N}5, {O}0, {P}1, {Q}2, {R}6, {S}2, {T}3, {U}0, {V}1, {W}0, {X}2, {Y}0, {Z}2,
    0, 0, 0, 0, 0, 0,
    {a}0, {b}1, {c}2, {d}3, {e}0, {f}1, {g}2, {h}0, {i}0, {j}2, {k}2, {l}4, {m}5,
    {n}5, {o}0, {p}1, {q}2, {r}6, {s}2, {t}3, {u}0, {v}1, {w}0, {x}2, {y}0, {z}2);

const
  MaxBufferSize = $F000;
  VALID_CHARACTERS: set of Char = ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '-', '\', '"', '!', '@'
  , #$23, '$', '%', #$A7, '*', '(', ')', '{', '}', '[', ']', '<', '>', '.', ':', ';', ',', '?', '!', '/',
  '+', '-', #$BA, '`', '=', '^', '~', '&', ' '];

const
  WIN1250_UNICODE : array [$00..$FF] of WORD = (
                    $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009,
                    $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013,
                    $0014, $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D,
                    $001E, $001F, $0020, $0021, $0022, $0023, $0024, $0025, $0026, $0027,
                    $0028, $0029, $002A, $002B, $002C, $002D, $002E, $002F, $0030, $0031,
                    $0032, $0033, $0034, $0035, $0036, $0037, $0038, $0039, $003A, $003B,
                    $003C, $003D, $003E, $003F, $0040, $0041, $0042, $0043, $0044, $0045,
                    $0046, $0047, $0048, $0049, $004A, $004B, $004C, $004D, $004E, $004F,
                    $0050, $0051, $0052, $0053, $0054, $0055, $0056, $0057, $0058, $0059,
                    $005A, $005B, $005C, $005D, $005E, $005F, $0060, $0061, $0062, $0063,
                    $0064, $0065, $0066, $0067, $0068, $0069, $006A, $006B, $006C, $006D,
                    $006E, $006F, $0070, $0071, $0072, $0073, $0074, $0075, $0076, $0077,
                    $0078, $0079, $007A, $007B, $007C, $007D, $007E, $007F,

                    $20AC, $0081, $201A, $0083, $201E, $2026, $2020, $2021, $0088, $2030,
                    $0160, $2039, $015A, $0164, $017D, $0179, $0090, $2018, $2019, $201C,
                    $201D, $2022, $2013, $2014, $0098, $2122, $0161, $203A, $015B, $0165,
                    $017E, $017A, $00A0, $02C7, $02D8, $0141, $00A4, $0104, $00A6, $00A7,
                    $00A8, $00A9, $015E, $00AB, $00AC, $00AD, $00AE, $017B, $00B0, $00B1,
                    $02DB, $0142, $00B4, $00B5, $00B6, $00B7, $00B8, $0105, $015F, $00BB,
                    $013D, $02DD, $013E, $017C, $0154, $00C1, $00C2, $0102, $00C4, $0139,
                    $0106, $00C7, $010C, $00C9, $0118, $00CB, $011A, $00CD, $00CE, $010E,
                    $0110, $0143, $0147, $00D3, $00D4, $0150, $00D6, $00D7, $0158, $016E,
                    $00DA, $0170, $00DC, $00DD, $0162, $00DF, $0155, $00E1, $00E2, $0103,
                    $00E4, $013A, $0107, $00E7, $010D, $00E9, $0119, $00EB, $011B, $00ED,
                    $00EE, $010F, $0111, $0144, $0148, $00F3, $00F4, $0151, $00F6, $00F7,
                    $0159, $016F, $00FA, $0171, $00FC, $00FD, $0163, $02D9);

  WIN1251_UNICODE : array [$00..$FF] of WORD = (
                    $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009,
                    $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013,
                    $0014, $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D,
                    $001E, $001F, $0020, $0021, $0022, $0023, $0024, $0025, $0026, $0027,
                    $0028, $0029, $002A, $002B, $002C, $002D, $002E, $002F, $0030, $0031,
                    $0032, $0033, $0034, $0035, $0036, $0037, $0038, $0039, $003A, $003B,
                    $003C, $003D, $003E, $003F, $0040, $0041, $0042, $0043, $0044, $0045,
                    $0046, $0047, $0048, $0049, $004A, $004B, $004C, $004D, $004E, $004F,
                    $0050, $0051, $0052, $0053, $0054, $0055, $0056, $0057, $0058, $0059,
                    $005A, $005B, $005C, $005D, $005E, $005F, $0060, $0061, $0062, $0063,
                    $0064, $0065, $0066, $0067, $0068, $0069, $006A, $006B, $006C, $006D,
                    $006E, $006F, $0070, $0071, $0072, $0073, $0074, $0075, $0076, $0077,
                    $0078, $0079, $007A, $007B, $007C, $007D, $007E, $007F,

                    $0402, $0403, $201A, $0453, $201E, $2026, $2020, $2021, $20AC, $2030,
                    $0409, $2039, $040A, $040C, $040B, $040F, $0452, $2018, $2019, $201C,
                    $201D, $2022, $2013, $2014, $0098, $2122, $0459, $203A, $045A, $045C,
                    $045B, $045F, $00A0, $040E, $045E, $0408, $00A4, $0490, $00A6, $00A7,
                    $0401, $00A9, $0404, $00AB, $00AC, $00AD, $00AE, $0407, $00B0, $00B1,
                    $0406, $0456, $0491, $00B5, $00B6, $00B7, $0451, $2116, $0454, $00BB,
                    $0458, $0405, $0455, $0457, $0410, $0411, $0412, $0413, $0414, $0415,
                    $0416, $0417, $0418, $0419, $041A, $041B, $041C, $041D, $041E, $041F,
                    $0420, $0421, $0422, $0423, $0424, $0425, $0426, $0427, $0428, $0429,
                    $042A, $042B, $042C, $042D, $042E, $042F, $0430, $0431, $0432, $0433,
                    $0434, $0435, $0436, $0437, $0438, $0439, $043A, $043B, $043C, $043D,
                    $043E, $043F, $0440, $0441, $0442, $0443, $0444, $0445, $0446, $0447,
                    $0448, $0449, $044A, $044B, $044C, $044D, $044E, $044F);

  WIN1252_UNICODE : array [$00..$FF] of WORD = (
                    $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009,
                    $000A, $000B, $000C, $000D, $000E, $000F, $0010, $0011, $0012, $0013,
                    $0014, $0015, $0016, $0017, $0018, $0019, $001A, $001B, $001C, $001D,
                    $001E, $001F, $0020, $0021, $0022, $0023, $0024, $0025, $0026, $0027,
                    $0028, $0029, $002A, $002B, $002C, $002D, $002E, $002F, $0030, $0031,
                    $0032, $0033, $0034, $0035, $0036, $0037, $0038, $0039, $003A, $003B,
                    $003C, $003D, $003E, $003F, $0040, $0041, $0042, $0043, $0044, $0045,
                    $0046, $0047, $0048, $0049, $004A, $004B, $004C, $004D, $004E, $004F,
                    $0050, $0051, $0052, $0053, $0054, $0055, $0056, $0057, $0058, $0059,
                    $005A, $005B, $005C, $005D, $005E, $005F, $0060, $0061, $0062, $0063,
                    $0064, $0065, $0066, $0067, $0068, $0069, $006A, $006B, $006C, $006D,
                    $006E, $006F, $0070, $0071, $0072, $0073, $0074, $0075, $0076, $0077,
                    $0078, $0079, $007A, $007B, $007C, $007D, $007E, $007F,

                    $20AC, $0081, $201A, $0192, $201E, $2026, $2020, $2021, $02C6, $2030,
                    $0160, $2039, $0152, $008D, $017D, $008F, $0090, $2018, $2019, $201C,
                    $201D, $2022, $2013, $2014, $02DC, $2122, $0161, $203A, $0153, $009D,
                    $017E, $0178, $00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
                    $00A8, $00A9, $00AA, $00AB, $00AC, $00AD, $00AE, $00AF, $00B0, $00B1,
                    $00B2, $00B3, $00B4, $00B5, $00B6, $00B7, $00B8, $00B9, $00BA, $00BB,
                    $00BC, $00BD, $00BE, $00BF, $00C0, $00C1, $00C2, $00C3, $00C4, $00C5,
                    $00C6, $00C7, $00C8, $00C9, $00CA, $00CB, $00CC, $00CD, $00CE, $00CF,
                    $00D0, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7, $00D8, $00D9,
                    $00DA, $00DB, $00DC, $00DD, $00DE, $00DF, $00E0, $00E1, $00E2, $00E3,
                    $00E4, $00E5, $00E6, $00E7, $00E8, $00E9, $00EA, $00EB, $00EC, $00ED,
                    $00EE, $00EF, $00F0, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
                    $00F8, $00F9, $00FA, $00FB, $00FC, $00FD, $00FE, $00FF);

var NomArq: TextFile;
type
  TChars = set of char;
type
  TCharset = set of AnsiChar;
type
  TDriveType = (dtUnknown, dtNoDrive, dtFloppy, dtFixed, dtNetwork, dtCDROM, dtRAM);
type
  TBMJumpTable = array[0..255] of Integer;
  TFastPosProc = function (const aSource, aFind: Pointer; const aSourceLen, aFindLen: Integer;
var JumpTable: TBMJumpTable): Pointer;
  TFastPosIndexProc = function (const aSourceString, aFindString: string;
  const aSourceLen, aFindLen, StartPos: Integer; var JumpTable: TBMJumpTable): Integer;
  TFastTagReplaceProc = procedure (var Tag: string; const UserData: Integer);

type
  WinIsWow64 = function( Handle: THandle; var Iret: BOOL ): Windows.BOOL; stdcall;

function BMFind(szSubStr, buf: PChar; iBufSize: integer; wholeword_only: boolean): integer;
function FormataDecimal(const Texto: string; const Decimais: Word = 2; const usaCifrao: Boolean = True): string;
procedure AppendToTextFile(ffilename: string; line: string);
//Boyer-Moore-Horspool text searching
function search(pat: string; text: string): integer;
function forceDeleteFile(pFileName:pAnsiChar):boolean;
function dnsLookUp(p:pAnsiChar):ansiString;
function isNumeric(p:pAnsiChar):boolean;
function isNumericFloat(p:pAnsiChar):boolean;
procedure safeDispose(var p);
procedure safeFree(var obj);
procedure safeTerminate(var thrd);
function pCount(p:pAnsiChar;ch:TCharSet):longWord;
function boolToStr(bl:boolean):ansiString;
function validIp(p:pAnsiChar):boolean;
function pCopy(p:pAnsiChar;n:longWord):ansiString;
function pLen(p:pAnsiChar):longWord;
function pPos(p:pAnsiChar;ch:char):longWord;
function removeHtml(p:pAnsiChar;aLen:longWord):ansiString;
function removeChars(p:pAnsiChar;ch:TCharSet):ansiString;
function TranslateCharacter(const UnicodeValue: integer; const UnknownChar: AnsiString): AnsiString;
function TranslateEncoding(const Source: AnsiString; const CurEncoding: AnsiString = 'UTF-8'): AnsiString;
function AnsiToUtf8 (Source : ANSISTRING) : AnsiString;
function Utf8ToAnsi (Source : AnsiString; UnknownChar : ANSICHAR = cUnknownCharacter): ANSISTRING;
function  DeleteChars (Source : AnsiString; CharsToDelete : TCharset) : AnsiString;
function  TrimWs (Source : AnsiString) : AnsiString;
function TrimAndPackSpace (Source : AnsiString) : AnsiString;
function  ConvertWs (Source: AnsiString; PackWs: BOOLEAN) : AnsiString;
procedure setStringSF (var S : AnsiString; BufferStart, BufferFinal : PAnsiChar);
function  StrLPas  (Start : PAnsiChar; Len : INTEGER) : AnsiString;
function  StrSFPas (Start, Finish : PAnsiChar) : AnsiString;
function  StrScanE (const Source : PAnsiChar; const CharToScanFor : ANSICHAR) : PAnsiChar;
procedure ExtractQuote (Start : PAnsiChar; var Content : AnsiString; var Final : PAnsiChar);
function StrScan (const Start: PAnsiChar; const Ch: AnsiChar): PAnsiChar; // Same functionality as SysUtils.StrScan
function StrPos (const Str, SearchStr : PAnsiChar): PAnsiChar; // Same functionality as SysUtils.StrPos, but faster
function removeInvalidCharacters(const auxStr: string): String;
procedure FireAnAccessViolationExceptionJustToTest;
function GenerateRandomStrings(aLength: Longint): string;
procedure CreateDataListViewObject(const fListView: TListView; const fTotalColums: integer = 10; const fTotalCharactersPerLine: integer = 10);
function IsDirectoryWritable(const Dir: String): Boolean;
function OpenLongFileName(const ALongFileName: String; SharingMode: DWORD): THandle; overload;
function OpenLongFileName(const ALongFileName: WideString; SharingMode: DWORD): THandle;  overload;
function CreateLongFileName(const ALongFileName: String; SharingMode: DWORD): THandle; overload;
function CreateLongFileName(const ALongFileName: WideString; SharingMode: DWORD): THandle; overload;
procedure CustomFileCopy(const ASourceFileName, ADestinationFileName: TFileName);
procedure CopyFile(const FileName, DestName: string);
function WindowsPath: string;
function IAmIn64Bits: Boolean;
function Is64BitProcessor: boolean;
function CPUIDavailable:boolean;
function Has64BitFeatureFlag: boolean;
Procedure SetChildTaborders(const Parent: TWinControl);
 { Stores a record to stream. Record can later be retrieved with
      RecordFromStream procedure }
Procedure RecordToStream(DSet          : tdataSet;{ Datset in question }
                         Stream        : TStream; { Stream to store to }
                         PhysFieldsOnly: Boolean { Do not store lookup and calculated fields }
                         {;FieldsNotStore: array of tField}); { Additional fields that should not be stored }
    { Reads record from the stream. The record was previously stored with
      RecordToStream procedure. Dset must be in edit/insert mode }
Procedure RecordFromStream(DSet   : tdataSet; { Datset in question }
                           Stream : TStream{;  { Stream to retrieve from }
                           {FieldsToIgnore: array of tField}); { Fields that should not be retrieved }
procedure SetRecNo(DataSet: TDataSet; const RecNo: Integer);
procedure SaveTextToFile(FileName, Text: string);
function LoadTextFromFile(FileName: string): string;
function CountFilesInFolder (path: string): integer;
function CheckFileName(const sFileName: string): Boolean;
function MemoryStreamToString(M: TMemoryStream): AnsiString;
function FormatMillisecondsToDateTime(const ms: integer): string;
function GetNextWord(const Str, Find: string): string;
function FileExistsLongFileNames(const FileName: WideString): Boolean;
function CheckFileExistence(FileName: String): Boolean;
function UserName: String;
function removeFileExt(p:pAnsiChar):ansiString;
procedure EmptyDir(const strDir: string);
function StreamsAreIdentical(var aError: Integer; const aStream1, aStream2: TStream; const aBlockSize: Integer = 4096): Boolean;
function FilesAreIdentical(var aError: Integer; const aFileName1, aFileName2: String; const aBlockSize: Integer = 4096): Boolean;
procedure ObtemDados(const DataSet: TClientDataSet; const KeyFields: string; const From: array of TDataSet);
//retorna o nome do arquivo sem extenso
function ExtractFileNameWithoutExtension (p:pAnsiChar):ansiString;
// fill the rich edit with colors
// <b>bold</b>, <s>string</s>, <n>number</n>, <c>comment</c>, <i>identifier</i>
procedure FillRichEdit (edit: TRichEdit; text: string);
procedure HideTabsInPageCtrl(PageControl: TPageControl);
function GetFmtFileVersion(const FileName: String = '';
  const Fmt: String = '%d.%d.%d.%d'): String;
function MyShellExecute(const FileName, Parameters: String; var ExitCode: DWORD; const Wait: DWORD = 0;
  const Hide: Boolean = False): Boolean;
function ShellExecuteAndWait(FileName: string; Visibility: integer): DWORD;
function RemoveTitleBar(hWindow: THANDLE; Hide: boolean = True): DWORD;
function LoadWindowsStr(const LibraryName: String; const Ident: Integer;
  const DefaultText: String = ''): String;
procedure PasteFilenamesFromClipboard(Filenames: TStrings);
function CopyFilenamesToClipboard(Filenames: TStrings): Boolean;
procedure SearchDirectory(List: TStrings; const Directory: String;
  const Mask: String = '*.*'; Recursive: Boolean = True;
  Append: Boolean = False);
procedure DeleteFilesToRecyclebin(const ParentWindow: HWND; const Filenames: TStrings;
  const ToRecycleBin: Boolean = True);
function GetFileSize(const FileName: String): Int64; //this function determines the size of a file in bytes,
//the size can be more than 2 GB.
function  ExtractLongPathName(const ShortPathName: String): String;
procedure DBGridSelectAll(AGrid: TDBGrid);
procedure AutoWidthCombobox(Combobox: TCombobox);
procedure AlignTitles(Grid : TDBGrid);
function JanelaExiste(const fForm: TForm): Boolean;
function JanelaMDIExiste(const fForm: TForm): Boolean;
function MinutesToHours(const Min: integer): string;
function HoursToMinutes(const Hour: string): string;
function HoursToDays(const Hour: string): string;
function EmptyExists(const Value: string): Boolean;
function EmptyDate(const FStringDate: string): Boolean;
function IsValidDate(const FStringDate: string): Boolean;
function EmptyCEP(const Value: string): Boolean;
function EmptyFone(const Value: string): Boolean;
function EmptyCPF(const Value: string): Boolean;
Function IsNumber(strNumber : String) : Boolean;
function FormatPercent(const Value: double): string;
function StrWithoutAccents(S: string): string;
Function WordCount(str: string) : integer;
function ConvertHTMLSpecialChars(const S: string; const pAccents: boolean = true): string;
function ArredondaComDecimais(X: double; Decimals: integer): Double;
procedure ExtraiIconeDoPrograma(const DirOndeEstaOPrograma: string; const DirOndeVaiSalvarOIcone: string);
function CopiaEntreTags(Frase, Inicio, Fim: String): String;  
procedure ExportaStringGridBrOffice(const FStringGrid: TStringGrid);
procedure SendToOpenOffice(aDataSet: TDataSet);
//procedure AjustaGrafico(Grafico : TQRDBChart);
function IsFileInUse(fName: string): boolean;
function Win32Type: string;
function SetLocalTime(Value: TDateTime): boolean;
function CarregaRelatorio(InstanceClass: TComponentClass; var Reference): TQuickRep;
function NumberOfTheMonth(const Mes: string): integer;
function RetornaIntervaloString(const S: string; const De: string; const Ate: string): string;
function retornaVARIABLEfromASP(const Search: string): string;
function RetornaTexto(Texto: String; Caracter: Char): String;
function WithoutAllSpaces(const S: String): String;
function AfterFirsSpace(const Str: string): string;
function FiltraLetra(const S:string;const ValidChars: TChars):boolean;
function AbreviaNome(Nome: String): String;
procedure MostraForm(aFormClass: TFormClass);
procedure MudarComEnter(var Msg: TMsg; var Handled: Boolean);
procedure GerarExcel(Consulta: TADOQuery);
Function Modulo11CGC(Numero: string):String;
Function Modulo11CPF(Numero: string):String;
Function ValidaCGC(Numero: string):Boolean;
Function ValidaCPF(Numero: string):Boolean;
function cpf(num: string): boolean;
Function fCheckEmail(Email : String): Boolean;
function ReverseStr (S: ShortString): ShortString;
function RemoveAcentos(Str: String): String;
function TiraPontos(x: String): String;
function strNiceNum(const S: String) : String;
function IntToSpell(num: integer): string;
function trans99(num: integer): string;
function trans19(num: integer): string;
function trans9(num: integer): string;
Function GetShortFileName(Const FileName : String) : String;
Function GetLongFileName(Const FileName : String) : String;
function ExecExplorer(OpenAtPath: string; OpenWithExplorer, OpenAsRoot: Boolean): boolean;
procedure OpenInternetExplorer( sURL : string );
function FileExec(const aCmdLine: String; aHide, aWait,bWait: Boolean):Boolean;
procedure FmtStr(var Result: string; const Format: string;
 const Args: array of const);
function FormatNumber(l: longint): string;
function IdadeAtual(Nasc : TDate): Integer;
Function ImpresConect(Porta:Word):Boolean;
function PrinterOnLine: Boolean;
function MMtoPixelX (MM : Integer) : Longint;
function MMtoPixelY (MM : Integer) : Longint;
function MonthString(const Month: Word): string;
function Gerapercentual(valor:real;Percent:Real):real;
function Maiuscula(Texto:String): String;
Function PrimeiroDiaUtil(Data : TDateTime) : TDateTime;
Procedure FindReplace (const Enc, subs: String; Var Texto: TMemo);
function DifDateUtil(dataini,datafin:string):integer;
function RemoveZeros(S: string): string;
function ObterTermo(APosicao: Integer; ASeparador,ALinha: String): String;
function GetTmpDir: string; // Obter o diretrio temporrio do Windows
function FormatSecsToHMS(Secs: LongInt): string;
procedure MouseCell(Grid: TStringGrid; var Coluna, Linha: integer);
function func_VerifEmail(email: string): boolean;
function ValidaTituloEleitor(NumTitulo: string): Boolean;
procedure cripto(const BMP: TBitmap; Key: Integer);
function WinExit(flags: integer): boolean;
procedure ColorToNegative(ABmp: TBitmap);
Procedure CriaCodigo(Cod : String; Imagem : TCanvas);
function FormataCEP(sCEP:String):String;
function FormataCEPComPonto(sCEP:String):String;
function ValidaContaCorrente(Agencia, CtaCorrente : integer) : boolean;
function ConverteMaisculo(str: string): string;
function StringToFloat(s : string) : Extended;
function Before(const Search, Find: string): string;
function after(const Search, Find: string): string;
function BuscaTroca(Text,Busca,Troca : string) : string;
function extenso (valor: real): string;
procedure GetDirList(Directory: String; var Result: TStrings;
IsRecursive: Boolean);
Procedure ApagaArq(vMasc:String);
function GetNumbersFromFile(var FileToNumber: string): integer;    
function ChecaCEP(cCep:String; cEstado:String): Boolean;
function DeleteChar(const Ch: Char; const S: string): string;
function RemovePrefixosNumericosDeUmaString(
 const S: string): string;
function ContaPalavras(const Texto : String) : Integer;
//funes para enviar msgs, semelhante ao NetSend do Windows
function NetSend(dest, Source, Msg: string): Longint; overload;
function NetSend(Dest, Msg: string): Longint; overload; // normalmente usar este
function NetSend(Msg: string): Longint; overload;
function QuebraString(Texto, Separador: string): TStringList;
Procedure ExecuteProgram(Nome,Parametros:String);
function ExecuteFile(const FileName, Params, DefaultDir: string;
 ShowCmd: Integer): THandle;
procedure ClearControlsPassedByParameters(const ArrayCtrls: array of TControl);
procedure FocaControle(const ArrayCtrls: array of TWinControl);
procedure DirList( ASource : string; ADirList : TStringList );
//fazendo um executvel se auto-deletar.
procedure DelExe;
function vpis(Dado: String):boolean;
function DownloadFile(Source, Dest: string): Boolean;
procedure CreateODBCDriver(Const
cDSNName,cExclusive,cDescription,cDataBase,cDefaultPath,cConfigSql,cDriver: string);
function ColorToHtml(mColor: TColor): string;
function StrToHtml(mStr: string; mFont: TFont = nil): string;
function DBGridToHtmlTable(mDBGrid: TDBGrid; mStrings: TStrings;
 mCaption: TCaption = ''): Boolean;
function GetIP:string;
procedure CriaAtalho(const Atalho: string);
Function EliminaCaracteres (sTexto: String; sCaracteres: string; Caixalta: Boolean; Comparacao : Boolean ):String;
function GeraImagem(Img: TImage): string;
function AlinhaE(Texto : String; Tamanho : Integer) : String;
function AlinhaC(Texto : String; Tamanho : integer) : String;
function AlinhaD(Texto : String; Tamanho : Integer) : String;
procedure DelTree(const Directory: TFileName);
Procedure FileCopy(sourcefilename:string; targetfilename: String );
//incluir um arquivo dentro do executvel
function extractResource(binresname: string; path: string): boolean;
function ObterNome(const Title: string; const MainLabel: string; var Nome: string; const Intervalo: string): boolean;
function SumAll (const Args: array of const): Extended;
procedure ShowMeHelp(const TitleHelp: string; const TextoHelp: string);
function Base64Encode(const Source: AnsiString): AnsiString;
function Base64Decode(const Source: string): string;
function CopyStr(const aSourceString : string; aStart, aLength : Integer) : string;
function Decrypt(const S: string; Key: Word): string;
function Encrypt(const S: string; Key: Word): string;
function ExtractHTML(S : string) : string;
function ExtractNonHTML(S : string) : string;
function HexToInt(aHex : string) : int64;
function LeftStr(const aSourceString : string; Size : Integer) : string;
function StringMatches(Value, Pattern : string) : Boolean;
function MissingText(Pattern, Source : string; SearchText : string = '?') : string;
function RandomFileName(aFilename : string) : string;
function RandomStr(aLength : Longint) : string;
function RightStr(const aSourceString : string; Size : Integer) : string;
function RGBToColor(aRGB : string) : TColor;
function StringCount(const aSourceString, aFindString : string; Const CaseSensitive : Boolean = TRUE) : Integer;
function SoundEx(const aSourceString: string): Integer;
function UniqueFilename(aFilename : string) : string;
function URLToText(aValue : string) : string;
function WordAt(Text : string; Position : Integer) : string;
function splitstr(input: string; schar: Char; s: Integer): string;
function StripHTMLorNonHTML(const S : string; WantHTML : Boolean) : string; forward;
//Boyer-Moore routines
procedure MakeBMTable(Buffer: PChar; BufferLen: Integer; var JumpTable: TBMJumpTable);
procedure MakeBMTableNoCase(Buffer: PChar; BufferLen: Integer; var JumpTable: TBMJumpTable);
function BMPos(const aSource, aFind: Pointer; const aSourceLen, aFindLen: Integer; var JumpTable: TBMJumpTable): Pointer;
function BMPosNoCase(const aSource, aFind: Pointer; const aSourceLen, aFindLen: Integer; var JumpTable: TBMJumpTable): Pointer;
function FastAnsiReplace(const S, OldPattern, NewPattern: string; Flags: TReplaceFlags): string;
procedure FastCharMove(const Source; var Dest; Count : Integer);
function FastCharPos(const aSource : string; const C: Char; StartPos : Integer): Integer;
function FastCharPosNoCase(const aSource : string; C: Char; StartPos : Integer): Integer;
function FastPos(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
function FastPosNoCase(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
function FastPosBack(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
function FastPosBackNoCase(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
function FastReplace(const aSourceString : string; const aFindString, aReplaceString : string;
 CaseSensitive : Boolean = False) : string;
function FastTagReplace(const SourceString, TagStart, TagEnd: string;
 FastTagReplaceProc: TFastTagReplaceProc; const UserData: Integer): string;
function SmartPos(const SearchStr,SourceStr : string;
                 const CaseSensitive : Boolean = TRUE;
                 const StartPos : Integer = 1;
                 const ForwardSearch : Boolean = TRUE) : Integer;
//Finalizando Processos: fechando aplicativos sem salvar os documentos
function KillTask(ExeFileName: string): Integer;
//Obter o MAC das placas de redes
function MacAddress: string;
//Marcador de Texto para um RichEdit
procedure MarkRichEditText(RichEdit: TRichEdit; fgColor, bkColor: TColor; MarkMode: Integer);
//converter texto em imagem
procedure ConvTextOut(CV: TCanvas; const sText: String; x, y, angle:integer);
function CreateBitmapFromIcon(Icon: TIcon; BackColor: TColor): TBitmap;
function CreateIconFromBitmap(Bitmap: TBitmap; TransparentColor: TColor): TIcon;
function LoadDLL(const LibName: string): THandle;
function RegisterServer(const ModuleName: string): Boolean;
procedure Delay(MSecs: Longint);
procedure FitRectToScreen(var Rect: TRect);
procedure CenterControl(Control: TControl);
procedure CenterWindow(Wnd: HWnd);
procedure MergeForm(AControl: TWinControl; AForm: TForm; Align: TAlign;
  Show: Boolean);
function MakeVariant(const Values: array of Variant): Variant;
function GetVersion: string; //obter verso de um sistema
procedure ExtraiIconeDoExecESalvaEmIcoEBMP; //extrai o cone de um excutvel, e salva nos formatos BMP e ICO.
                                            //til quando tem-se o executvel e deseja-se obter o seu cone.
procedure ExtraiBMPESalvaEmIcone;


Type
  NOME_DIA = record
    nData : String[10]; {dd/mm/aaaa}
    cData : String[40]; {Nome do dia}
  end;

  FERIADOS = record
    Ano : String[4];
    Data : array[1..14] of NOME_DIA;
  end;

function DiaDaSemana(data:TDate): string;
function Gauss(ano: integer): string;
function vFeriados(Ano: integer): FERIADOS; 



{            TFilterFile      **********************
// Classe para ler e escrever contedo de arquivos, byte a byte.
// melhor por ser mais rpido do que utilizando os mtodos read
//e write comum (textfile). Jim Mischel (1997). Adaptado por mim (Hamden).
//exemplo de como utiliz-la:
 const
  BigBufferSize = 65536;
var
 InputFile : TFilterFile;
 OutputFile : TFilterFile;
 C: byte;
begin
 InputFile := TFilterFile.Create ('C:\arq_origem.txt', BigBufferSize);
 if (not InputFile.Open (fioRead)) then begin
   Showmessage ('Erro ao abrir arquivo de entrada');
   Halt;
 end;
 OutputFile := TFilterFile.Create ('C:\arq_destino.txt', BigBufferSize);
 if (not OutputFile.Open (fioWrite)) then begin
   Showmessage ('Erro ao abrir arquivo de sada');
   Halt;
 end;
 //processa e l cada caracter.
 while (not InputFile.Eof) do begin
   c := char ( InputFile.GetByte);
   c := UpCase(c);
   if (not OutputFile.PutByte (byte (c))) then begin
     Showmessage ('Erro de escrita');
     Halt;
   end;
 end;
 InputFile.Close;
 InputFile.Free;
 OutputFile.Close;
 OutputFile.Free;
end;
}
type
 FileIOMode = (fioNotOpen, fioRead, fioWrite);
 BuffArray = array[0..1] of byte;
 pBuffArray = ^BuffArray;
TFilterFile = class (TObject)
 private
   FFilename : String;
   F : File;
   FBufferSize : Integer;
   FBuffer : pBuffArray;
   FBytesInBuff : Integer;
   FBuffIndx : Integer;
   FFileMode : FileIOMode;
   function ReadBuffer : boolean;
   function WriteBuffer : boolean;
 public
   constructor Create (AName : String; ABufSize : Integer);
   destructor Destroy; override;
   function Open (AMode : FileIOMode) : Boolean;
   procedure Close;
   function Eof : Boolean;
   function GetByte : byte;
   function PutByte (b : byte) : boolean;
 end;
implementation

uses Math, uI18n, uFastFileMsgDlg;

procedure ShowMessage(const Msg: string); overload;
begin
  FastFileMsgInfo(TrText(Msg));
end;

function MessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer; overload;
var
  Kind: TFfMsgKind;
begin
  case DlgType of
    mtWarning: Kind := fmkWarning;
    mtError: Kind := fmkError;
    mtConfirmation: Kind := fmkConfirm;
  else
    Kind := fmkInfo;
  end;
  Result := FastFileMsgDlg(TrText(Msg), Kind, Buttons);
end;

const
  cKey1 = 52845;
  cKey2 = 22719;
  Base64_Table : shortstring = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  cDeltaSize = 1.5;

var
  GUpcaseTable : array[0..255] of char;
  GUpcaseLUT: Pointer;

function BMFind(szSubStr, buf: PChar; iBufSize: integer;
  wholeword_only: boolean): integer;
  { Returns -1 if substring not found,
  or zero-based index into buffer if substring found }
var
  iSubStrLen: integer;
  skip: array [char] of integer;
  found: boolean;
  iMaxSubStrIdx: integer;
  iSubStrIdx: integer;
  iBufIdx: integer;
  iScanSubStr: integer;
  mismatch: boolean;
  iBufScanStart: integer;
  ch: char;
begin
  found := False;
  Result := -1;
  iSubStrLen := StrLen(szSubStr);
  if iSubStrLen = 0 then
  begin
    Result := 0;
    Exit
  end;

  iMaxSubStrIdx := iSubStrLen - 1;
  { Initialise the skip table }
  for ch := Low(skip) to High(skip) do skip[ch] := iSubStrLen;
    for iSubStrIdx := 0 to (iMaxSubStrIdx - 1) do
      skip[szSubStr[iSubStrIdx]] := iMaxSubStrIdx - iSubStrIdx;

  { Scan the buffer, starting comparisons at the end of the substring }
  iBufScanStart := iMaxSubStrIdx;
  while (not found) and (iBufScanStart < iBufSize) do
  begin
    iBufIdx := iBufScanStart;
    iScanSubStr := iMaxSubStrIdx;
    repeat
      mismatch := (szSubStr[iScanSubStr] <> buf[iBufIdx]);
      if not mismatch then
        if iScanSubStr > 0 then
        begin // more characters to scan
          Dec(iBufIdx); Dec(iScanSubStr)
        end
        else
          found := True;
    until mismatch or found;
    if found and wholeword_only then
    begin
      if (iBufIdx > 0) then
        found := not IsCharAlpha(buf[iBufIdx - 1]);
      if found then
        if iBufScanStart < (iBufSize - 1) then
          found := not IsCharAlpha(buf[iBufScanStart + 1]);
    end;
    if found then
      Result := iBufIdx
    else
      iBufScanStart := iBufScanStart + skip[buf[iBufScanStart]];
  end;
end;

(* Exemplo de como usar:
var
  str: string;
begin
  str := FormataDecimal('23545665,88',4);
  ShowMessage(str);
end;
*)
function FormataDecimal(const Texto: string; const Decimais: Word = 2; const usaCifrao: Boolean = True): string;
begin
  case usaCifrao of
    True: Result := Format('%s %s', [FormatSettings.CurrencyString, FormatFloat(Format(',.%s', [StringOfChar('0',Decimais)]), StrToFloatDef(StringReplace(Texto, '.', ',', [rfReplaceAll]),0))]);
    False: FormatFloat(Format(',.%s', [StringOfChar('0',Decimais)]), StrToFloatDef(StringReplace(Texto, '.', ',', [rfReplaceAll]),0));
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

function search(pat: string; text: string): integer;
var
  i, j, k, m, n: integer;
  skip: array [0..MAXCHAR] of integer;
  found: boolean;
begin
  found := FALSE;
  search := 0;
  m := length(pat);
  if m=0 then
  begin
    search := 1;
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
        search := i+1;
        found := TRUE;
      end;
      k := k + skip[ord(text[k])];
    end;
  end;
end;

function forceDeleteFile(pFileName:pAnsiChar):boolean;
begin
  windows.setFileAttributes(pFileName,cNONE);//clear file attributes
  result:=windows.deleteFile(pFileName);    //then delete the file
end;
{Example
procedure TForm1.FormCreate(Sender: TObject);
var s:ansiString;
begin
 s:='google.com';
 caption:=dnsLookUp(pAnsiChar(s));  //ip to hostname
end; }
function dnsLookUp(p:pAnsiChar):ansiString;
  function ipToInt(p:pAnsiChar;aLen:longWord):longWord;
  var q,b:byte;lP:pAnsiChar;e:integer;
  begin
   result:=0;
   q:=0;
   lP:=p;
   while aLen<>0 do begin
    if p^='.' then begin
     val(pCopy(lP,p-lP),b,e);if e<>0 then b:=0;
     inc(result,b shl q);if q>$10 then break;inc(q,8);
     lP:=p+1;
    end;inc(p);dec(aLen)
   end;
   if q>$18 then exit;
   val(pCopy(lP,p-lP),b,e);
   if e=cNONE then inc(result,b shl q);
  end;
var
  wsa:tWsaData;n:longWord;rP:pHostEnt;
begin
  if (p=nil) or (p^=NULL) then begin result:='';exit end;
    result:=pCopy(p,pLen(p));
  if wsaStartUp(1 or 0 shl 8,wsa)<>NOERROR then exit;
  if validIp(p) then
  begin
    n:=ipToInt(p,pLen(p));//ip to host
    rP:=getHostByAddr(@n,4,AF_INET);
    if rP<>nil then result:=rP^.h_name;
  end
  else
  begin //host to ip
    rP:=getHostByName(p);
    if rP<>nil then result:=inet_ntoa(pInAddr(rP^.h_addr^)^);
  end;
  wsaCleanUp;
end;

function isNumeric(p:pAnsiChar):boolean;
begin
 result:=false;if p=nil then exit;        //Check input
 if p^='-' then inc(p);                   //Ignore minus
 if p^=cNULL then exit;                    //Deny empty input
 while p^<>cNULL do                        //Loop chars
  if p^ in DIGITS then inc(p) else exit;  //Check if numerical char
 result:=true
end;

function isNumericFloat(p:pAnsiChar):boolean;
var bl:boolean;
begin
 result:=false;if p=nil then exit;        //Check input
 if p^='-' then inc(p);                   //Ignore minus
 if p^=cNULL then exit;                    //Deny empty input
 bl:=false;                               //True if had comma or dot
 while p^<>cNULL do begin                  //Loop all chars
  if not (p^ in DIGITS) then              //Check if numerical char
  if p^ in ['.',','] then begin           //Check if comma or dot
   if not bl then bl:=true else exit      //Deny multiple comma or dot
  end else exit;                          //Deny any other char
  inc(p);                                 //Next char
 end;
 result:=true
end;

{
  //Examples
  safeFree(obj);            //Instead of obj.free;
  safeDispose(p);           //Instead of dispose(p);
  safeTerminate(thread);    //Instead of thread.Terminate;
}
procedure safeDispose(var p);
var
  q:pointer;//clear reference before dispose data
begin
  try
    if pointer(p)=nil then exit;
    q:=pointer(p);
    pointer(p):=nil;
    dispose(q);
  except
    pointer(p):=nil;
  end;
end;

procedure safeFree(var obj);
var p:TObject;//clear reference before destroy object
begin
 try
  if TObject(obj)=nil then exit;
  p:=TObject(obj);
  TObject(obj):=nil;
  p.free;
 except
  TObject(obj):=nil;
 end;
end;

procedure safeTerminate(var thrd);
var p:TThread;//clear reference before terminate thread
begin
 try
  if TThread(thrd)=nil then exit;
  p:=TThread(thrd);
  TThread(thrd):=nil;
  p.terminate;
 except
  TThread(thrd):=nil;
 end;
end;
{procedure TForm1.FormCreate(Sender: TObject);
var n:longWord;s:ansiString;
begin
 s:='www.mortenbs.com';         //Define string to count chars from
 n:=pCount(pAnsiChar(s),['.']); //Count number of dots in string "s"
 caption:=intToStr(n);          //Show the number in form caption
end;
}
function pCount(p:pAnsiChar;ch:TCharSet):longWord;
begin
  result:=0;
  if p<>nil then while p^<>cNULL do
  begin
    if p^ in ch then inc(result);
    inc(p);
  end
end;

function boolToStr(bl:boolean):ansiString;
begin
 if bl then result:='yes' else result:='no';
end;
{procedure TForm1.FormCreate(Sender: TObject);
var s:ansiString;
begin
 s:='10.0.0.1';
 caption:=boolToStr(validIp(pAnsiChar(s)));
end;}
function validIp(p:pAnsiChar):boolean;
var lP:pAnsiChar;i,e:integer;b:byte;
begin
 result:=false;
 b:=cNONE;
 lP:=p;
 while p^<>NULL do begin
  case p^ of
   '0'..'9':;//accept.
   '.':begin
    val(pCopy(lP,p-lP),i,e);
    if (e<>cNONE) or (i>$FF) then exit;
    inc(b);lP:=p+1
   end;
  else exit end;inc(p);
 end;
 if b<>3 then exit;
 val(pCopy(lP,p-lP),i,e);
 if (e=cNONE) and (i<$100) then result:=true
end;
{Example
procedure TForm1.FormCreate(Sender: TObject);
var s:ansiString;
begin
 s:='1234567890';
 caption:=pCopy(pAnsiChar(s),4);
end; }
function pCopy(p:pAnsiChar;n:longWord):ansiString;
var
  rP:pAnsiChar;
begin
 setLength(result,n);
 rP:=pAnsiChar(result);
 while n<>cNONE do begin rP^:=p^;inc(rP);inc(p);dec(n) end;
end;

function pLen(p:pAnsiChar):longWord;
var
  p1:pAnsiChar;
begin
 if p=nil then begin result:=cNONE;exit end;
 p1:=p;
 while p^<>cNULL do inc(p);
 result:=p-p1;
end;

function pPos(p:pAnsiChar;ch:char):longWord;
var
  q:pAnsiChar;
begin
  result:=0;
  q:=p;
  while p^<>cNULL do
    if p^=ch then begin result:=p-q+1;exit end else inc(p);
end;
{
Example
procedure TForm1.FormCreate(Sender: TObject);
var src:ansiString;
begin
 src:='<b>Hi there</b>';
 caption:=removeHtml(pAnsiChar(src),length(src));
end;
}
function removeHtml(p:pAnsiChar;aLen:longWord):ansiString;
const
  ch=['0'..'9','a'..'z','A'..'Z'];
var
  eP,rP,p1:pAnsiChar;
  v,n:longWord;
begin
  setLength(result,aLen);if aLen=0 then exit;
  rP:=pAnsiChar(result);
  p1:=rP;
  n:=aLen;
  eP:=p+aLen;
  while p<eP do
  begin
    while p^='<' do
    begin
      v:=pPos(p,'>');
      if v=0 then inc(p) else
      begin
        if (rP<>p1) and ((rP-1)^<>' ') and ((p+v)^ in ch) then
        begin
          rP^:=' ';inc(rP); //add space
          inc(n);
        end;
        dec(n,v);
        inc(p,v);
      end;
    end;
    rP^:=p^;inc(rP);
    inc(p);
  end;
  if n<>aLen then setLength(result,n);
end;
{Example
procedure TForm1.FormCreate(Sender: TObject);
var s:ansiString;
begin
 s:='1.2.3';                          //Define string to delete chars from
 s:=removeChars(pAnsiChar(s),['.']);  //Remove DOTS from string "s"
 caption:=string(s);                  //Show the result in form caption
end;}
function removeChars(p:pAnsiChar;ch:TCharSet):ansiString;
var
  rP:pAnsiChar;k:longWord;
begin
  rP:=p;k:=0;                                         //Reset
  while rP^<>cNULL do begin                            //Find length and count chars
    if rP^ in ch then inc(k);                          //Number of chars to remove
    inc(rP);                                           //Next char
  end;
  setLength(result,longWord(rP-p)-k);                 //Set result length
  rP:=pChar(result);                                  //Get result pointer
  while p^<>cNULL do begin                             //Fill data into result
    if not (p^ in ch) then begin rP^:=p^;inc(rP) end;  //Write char if not excluded
    inc(p);                                            //Next char
  end;
end;

function TranslateCharacter(const UnicodeValue: integer; const UnknownChar: AnsiString): AnsiString;
var
  I : integer;
begin
  if (UnicodeValue <= 127) then begin
    Result := AnsiChar (UnicodeValue);
    exit;
  end
  else
    for I := 128 to 255 do
      if UnicodeValue = WIN1252_UNICODE [I] then begin
        Result := AnsiChar (I);
        exit;
      end;
  Result := cUnknownCharacter;
end;

function TranslateEncoding(const Source: AnsiString; const CurEncoding: AnsiString = 'UTF-8'): AnsiString;
begin
  if CurEncoding = 'UTF-8'
    then Result := Utf8ToAnsi (Source)
    else Result := Source;
end;

function AnsiToUtf8 (Source: AnsiString): AnsiString;
var
  I   : Integer;
  U   : Word;
  Len : Integer;
begin
  setLength (Result, Length (Source) * 3);   
  Len := 0;
  for I := 1 to Length (Source) do begin
    U := WIN1252_UNICODE [Ord(Source[I])];
    case U of
      $0000..$007F : begin
                       Inc(Len);
                       Result [Len] := AnsiChar (U);
                     end;
      $0080..$07FF : begin
                       Inc(Len);
                       Result [Len] := AnsiChar ($C0 OR (U SHR 6));
                       Inc(Len);
                       Result [Len] := AnsiChar ($80 OR (U AND $3F));
                     end;
      $0800..$FFFF : begin
                       Inc(Len);
                       Result [Len] := AnsiChar ($E0 OR (U SHR 12));
                       Inc(Len);
                       Result [Len] := AnsiChar ($80 OR ((U SHR 6) AND $3F));
                       Inc(Len);
                       Result [Len] := AnsiChar ($80 OR (U AND $3F));
                     end;
      end;
    end;
  setLength (Result, Len);
end;

function Utf8ToAnsi (Source : AnsiString; UnknownChar : ANSICHAR = cUnknownCharacter): AnsiString;
var
  SourceLen : Integer;
  I, K      : Integer;
  A         : Byte;
  U         : Word;
  Ch        : AnsiChar;
  Len       : Integer;
begin
  SourceLen := Length (Source);
  setLength (Result, SourceLen);
  Len := 0;
  I   := 1;
  while I <= SourceLen do begin
    A := Ord(Source [I]);
    if A < $80 then begin
      Inc(Len);
      Result [Len] := Source [I];
      Inc(I);
      end
    else begin
      if (A and $E0 = $C0) and (I < SourceLen) then begin
        U := (WORD (A AND $1F) SHL 6) OR (ORD (Source [I+1]) AND $3F);
        INC (I, 2);
        end
      else if (A AND $F0 = $E0) AND (I < SourceLen-1) then begin
        U := (WORD (A AND $0F) SHL 12) OR
             (WORD (ORD (Source [I+1]) AND $3F) SHL 6) OR
             (      ORD (Source [I+2]) AND $3F);
        INC (I, 3);
        end
      else begin
        INC (I);
        for K := 7 downto 0 do
          if A AND (1 SHL K) = 0 then begin
            INC (I, (A SHR (K+1))-1);
            BREAK;
            end;
        U := WIN1252_UNICODE [ORD (UnknownChar)];
        end;
      Ch := UnknownChar;
      if U <= $7F then
        Ch := AnsiChar (U)
      else
        for A := $80 to $FF DO
          if WIN1252_UNICODE [A] = U then begin
            Ch := ANSICHAR (A);
            BREAK;
            end;
      INC (Len);
      Result [Len] := Ch;
      end;
    end;
  setLength (Result, Len);
end;

function DeleteChars (Source : AnsiString; CharsToDelete : TCharset): AnsiString;
var
  I : Integer;
begin
  Result := Source;
  for I := Length (Result) downto 1 do
    if Result [I] IN CharsToDelete then
      Delete (Result, I, 1);
end;

function TrimWs (Source : AnsiString) : AnsiString;
var
  I : Integer;
begin
  I := 1;
  while (I <= Length (Source)) and (Source [I] in CWhitespace) do
    inc(I);
  Result := Copy (Source, I, MaxInt);
  I := Length (Result);
  while (I > 1) and (Result [I] in CWhitespace) do
    dec(I);
  Delete(Result, I+1, Length (Result)-I);
end;

function TrimAndPackSpace (Source : AnsiString) : AnsiString;
var
  I, T : Integer;
begin
  T := 1;
  for I := 1 to Length (Source) do
    if Source [I] = #32
      then Inc(T)
      else Break;
  if T > 1
    then Result := Copy (Source, T, MaxInt)
    else Result := Source;
  I := Length (Result);
  while (I > 1) and (Result [I] = #32) do
    Dec(I);
  Delete (Result, I+1, Length (Result)-I);

  for I := Length (Result) downto 2 do
    if (Result [I] = #32) and (Result [I-1] = #32) then
      Delete (Result, I, 1);
end;

function  ConvertWs (Source: AnsiString; PackWs: BOOLEAN) : AnsiString;
var
  I : Integer;
begin
  Result := Source;
  for I := Length (Result) downto 1 do
    if (Result [I] in CWhitespace) then
      if PackWs and (I > 1) and (Result [I-1] in CWhitespace)
        then Delete (Result, I, 1)
        else Result [I] := #32;
end;

procedure setStringSF (var S : AnsiString; BufferStart, BufferFinal : PAnsiChar);
begin
  setString (S, BufferStart, BufferFinal-BufferStart+1);
end;

function  StrLPas  (Start : PAnsiChar; Len : INTEGER) : AnsiString;
begin
  setString (Result, Start, Len);
end;

function  StrSFPas (Start, Finish : PAnsiChar) : AnsiString;
begin
  setString (Result, Start, Finish-Start+1);
end;

function  StrScanE (const Source : PAnsiChar; const CharToScanFor : ANSICHAR) : PAnsiChar;
begin
  Result := StrScan (Source, CharToScanFor);
  if Result = nil then
    Result := Strend (Source)-1;
end;

procedure ExtractQuote (Start : PAnsiChar; var Content : AnsiString; var Final : PAnsiChar);
begin
  Final := StrScan (Start+1, Start^);
  if Final = nil then begin
    Final := Strend (Start+1)-1;
    setString (Content, Start+1, Final-Start);
    end
  else
    setString (Content, Start+1, Final-1-Start);
end;

function StrScan (const Start: PAnsiChar; const Ch: AnsiChar): PAnsiChar;
begin
  Result := Start;
  while Result^ <> Ch do begin
    if Result^ = #0 then begin
      Result := nil;
      Exit;
    end;
    Inc(Result);
  end;
end;

function StrPos (const Str, SearchStr : PAnsiChar): PAnsiChar;
var
  First : AnsiChar;
  Len   : Integer;
begin
  First  := SearchStr^;
  Len    := StrLen (SearchStr);
  Result := Str;
  repeat
    if Result^ = First then
      if StrLComp (Result, SearchStr, Len) = 0 then break;
    if Result^ = #0 then
    begin
      Result := nil;
      break;
    end;
    Inc (Result);
  until FALSE;
end;

function removeInvalidCharacters(const auxStr: string): String;
var
  strStream: TStringStream;
  Buffer: array of AnsiChar;
  TempStr: string;
  i: integer;
begin
  strStream := TStringStream.Create(auxStr);
  try
    strStream.Seek(0, soFromBeginning);
    SetLength(Buffer, MaxBufferSize);
    strStream.Read(Buffer[0],MaxBufferSize);

    for i := Low(Buffer) to High(Buffer) do
    begin
      if Buffer[i] in VALID_CHARACTERS then
        TempStr := TempStr + Buffer[i];
    end;

    Result := SysUtils.Trim(TempStr);
  finally
    FreeAndNil(strStream);
  end;
end;

procedure FireAnAccessViolationExceptionJustToTest;
begin
  try
    SysUtils.StrLen(nil);
  except on E:Exception do
    raise Exception.Create(E.Message);
  end;    
end;

function GenerateRandomStrings(aLength: Longint): string;
var
  X: Longint;
begin
  if aLength <= 0 then exit;
  SetLength(Result, aLength);
  for X:=1 to aLength do
    Result[X] := Chr(Random(26) + 65);
end;

procedure CreateDataListViewObject(const fListView: TListView; const fTotalColums: integer = 10; const fTotalCharactersPerLine: integer = 10);
var
  i,k: integer;
  ListItem: TListItem;
  //WITDH_PER_ROW: integer;
var
  TOTAL_COLUMNS: integer;
  TOTAL_CHARACTERS_PER_ROW: integer;
begin
  TOTAL_COLUMNS := fTotalColums;
  TOTAL_CHARACTERS_PER_ROW := fTotalCharactersPerLine;
  //WITDH_PER_ROW := 0;
  fListView.ViewStyle := vsReport;
  //ListView1.DoubleBuffered := true;

  fListView.Items.BeginUpdate;
  try
    for i := 0 to TOTAL_COLUMNS do
      fListView.Columns.Add.Caption := GenerateRandomStrings(TOTAL_CHARACTERS_PER_ROW);

     for i := 0 to fListView.Columns.Count - 1 do
      begin
        ListItem := fListView.Items.Add;
        ListItem.Caption := GenerateRandomStrings(TOTAL_CHARACTERS_PER_ROW);

        for k := 0 to fListView.Columns.Count - 1 do
          ListItem.SubItems.Add(GenerateRandomStrings(TOTAL_CHARACTERS_PER_ROW));

      end;

    for i := 0 to fListView.Items.Count - 1 do
    begin
      for k := 0 to fListView.Items[i].SubItems.Count - 1 do
        fListView.Items[i].SubItems[k] := GenerateRandomStrings(TOTAL_CHARACTERS_PER_ROW);
    end;

    //for i := 0 to TOTAL_COLUMNS do
     // ListView1.Columns[i].Width := -1 or -2;

    //WITDH_PER_ROW := ListView1.Columns[0].Width;

  finally
    fListView.Items.EndUpdate;
  end;
end;

function IsDirectoryWritable(const Dir: String): Boolean;
var
  TempFile: array[0..MAX_PATH] of Char;
begin
  if GetTempFileName(PChar(Dir), 'DA', 0, TempFile) <> 0 then
    Result := Windows.DeleteFile(TempFile)
  else
    Result := False;
end;

function OpenLongFileName(const ALongFileName: String; SharingMode: DWORD): THandle; overload;
begin
  if CompareMem(@(ALongFileName[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    Result := CreateFileW(PWideChar(WideString(ALongFileName)), GENERIC_READ, SharingMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFileW(PWideChar(WideString('\\?\' + ALongFileName)), GENERIC_READ, SharingMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
end;
function OpenLongFileName(const ALongFileName: WideString; SharingMode: DWORD): THandle;  overload;
begin
  if CompareMem(@(WideCharToString(PWideChar(ALongFileName))[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    Result := CreateFileW(PWideChar(ALongFileName), GENERIC_READ, SharingMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFileW(PWideChar('\\?\' + ALongFileName), GENERIC_READ, SharingMode, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
end;

function CreateLongFileName(const ALongFileName: String; SharingMode: DWORD): THandle; overload;
begin
  if CompareMem(@(ALongFileName[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    Result := CreateFileW(PWideChar(WideString(ALongFileName)), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFileW(PWideChar(WideString('\\?\' + ALongFileName)), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
end;
function CreateLongFileName(const ALongFileName: WideString; SharingMode: DWORD): THandle; overload;
begin
  if CompareMem(@(WideCharToString(PWideChar(ALongFileName))[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    Result := CreateFileW(PWideChar(ALongFileName), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFileW(PWideChar('\\?\' + ALongFileName), GENERIC_WRITE, SharingMode, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
end;

procedure CustomFileCopy(const ASourceFileName, ADestinationFileName: TFileName);
const
  BufferSize = 1024; // 1KB blocks, change this to tune your speed
var
  Buffer : array of Byte;
  ASourceFile, ADestinationFile: THandle;
  FileSize: DWORD;
  BytesRead, BytesWritten, BytesWritten2: DWORD;
begin
  SetLength(Buffer, BufferSize);
  ASourceFile := OpenLongFileName(ASourceFileName, 0);
  if ASourceFile <> 0 then
  try
    FileSize := FileSeek(ASourceFile, 0, FILE_END);
    FileSeek(ASourceFile, 0, FILE_BEGIN);
    ADestinationFile :=  CreateLongFileName(ADestinationFileName, FILE_SHARE_READ);
    if ADestinationFile <> 0 then
    try
      while (FileSize - FileSeek(ASourceFile, 0, FILE_CURRENT)) >= BufferSize do
      begin
        if (not ReadFile(ASourceFile, Buffer[0], BufferSize, BytesRead, nil)) and (BytesRead = 0) then
         Continue;
        WriteFile(ADestinationFile, Buffer[0], BytesRead, BytesWritten, nil);
        if BytesWritten < BytesRead then
        begin
          WriteFile(ADestinationFile, Buffer[BytesWritten], BytesRead - BytesWritten, BytesWritten2, nil);
          if (BytesWritten2 + BytesWritten) < BytesRead then
            RaiseLastOSError;
        end;
      end;
      if FileSeek(ASourceFile, 0, FILE_CURRENT)  < FileSize then
      begin
        if (not ReadFile(ASourceFile, Buffer[0], FileSize - FileSeek(ASourceFile, 0, FILE_CURRENT), BytesRead, nil)) and (BytesRead = 0) then
         ReadFile(ASourceFile, Buffer[0], FileSize - FileSeek(ASourceFile, 0, FILE_CURRENT), BytesRead, nil);
        WriteFile(ADestinationFile, Buffer[0], BytesRead, BytesWritten, nil);
        if BytesWritten < BytesRead then
        begin
          WriteFile(ADestinationFile, Buffer[BytesWritten], BytesRead - BytesWritten, BytesWritten2, nil);
          if (BytesWritten2 + BytesWritten) < BytesRead then
            RaiseLastOSError;
        end;
      end;
    finally
      CloseHandle(ADestinationFile);
    end;
  finally
    CloseHandle(ASourceFile);
  end;
end;

procedure CopyFile(const FileName, DestName: string);
var
  CopyBuffer   : Pointer; { buffer for copying }
  BytesCopied  : Longint;
  Source, Dest : Integer; { handles }
  Destination  : TFileName; { holder for expanded destination name }
const
  ChunkSize  : Longint = 8192; { copy in 8K chunks }
begin
  Destination := DestName;
  GetMem(CopyBuffer, ChunkSize); { allocate the buffer }
  try
    Source := FileOpen(FileName, fmShareDenyNone); { open source file }
    if Source < 0
      then raise EFOpenError.CreateFmt('Error: Can''t open file!', [FileName]);
    try
      Dest := FileCreate(Destination); { create output file; overwrite existing }
      if Dest < 0
        then raise EFCreateError.CreateFmt('Error: Can''t create file!', [Destination]);
      try
        repeat
          BytesCopied := FileRead(Source, CopyBuffer^, ChunkSize); { read chunk }
          if BytesCopied > 0  {if we read anything... }
            then FileWrite(Dest, CopyBuffer^, BytesCopied); { ...write chunk }
        until BytesCopied < ChunkSize; { until we run out of chunks }

      finally
        FileClose(Dest); { close the destination file }
      end;
    finally
      FileClose(Source); { close the source file }
    end;
  finally
    FreeMem(CopyBuffer, ChunkSize); { free the buffer }
  end;
end;


function WindowsPath: string;
begin
    SetLength(Result, MAX_PATH);
    SetLength(Result, GetWindowsDirectory(@Result[1], MAX_PATH));
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

{
  Site:  http://stackoverflow.com/questions/1436185/how-can-i-tell-if-im-running-on-x64

  A note on CPUIDavailable: This is of course assuming a >= 32-bit x86 processor (80386 or later),
but Delphi Win32 code won't run on earlier machines anyway.
The CPUID instruction was introduced with late 80486 processors.
}

function Is64BitProcessor: boolean;
begin
  Result:=false;
  if CpuidAvailable = true then Result := Has64BitFeatureFlag;
end;

function CPUIDavailable:boolean;
asm // if EFLAGS bit 21 can be modified then CPUID is available
    pushfd              //Save Flags
          pushfd        //Copy flags to EAX
          pop eax
          mov ecx,eax   //Make another copy in ECX
          btc eax,21    //Complement bit 21
          push eax      //Copy EAX to flags
          popfd
          pushfd        //Copy flags back to EAX
          pop eax
          cmp eax,ecx   //Compare "old" flags value with potentially modified "new" value
          setne al      //Set return value
    popfd               //Restore flags
end;

function Has64BitFeatureFlag: boolean;
asm
  //IF CPUID.80000001h.EDX[bit29]=1 THEN it's a 64bit processor.
  //But we first need to check whether there's a function 80000001h.
  push ebx                  //Save EBX as CPUID will modify EBX
  push esi                  //Save ESI as we'll use ESI internally

  xor eax,eax             //Setting EAX = input param for CPUID to 0
  cpuid                   //Call CPUID.0
                          //Returns -> EAX = max "standard" EAX input value
  mov esi, eax            //Saving MaxStdInput Value

  mov eax,80000000h       //Setting EAX = input param for CPUID to $80000000
  cpuid                   //Call CPUID.80000000h
                          //Returns -> EAX = max "extended" EAX input value
                          //If 80000000h call is unsupported (no 64-bit processor),
                          //cpuid should return the same as in call 0
  cmp eax, esi
  je @No64BitProcessor    //IF EAX{MaxExtInput} = ESI{MaxStdInput} THEN goto No64BitProcessor;

  cmp eax, 80000001h
  jb @No64BitProcessor    //IF EAX{MaxExtInput} < $80000001 THEN goto No64BitProcessor;

  mov eax,80000001h       //Call $80000001 is supported, setting EAX:=$80000001
  cpuid                   //Call CPUID.80000001h
                          //Checking "AMD long mode"/"Intel EM64T" feature bit (i.e., 64bit processor)
  bt edx, 29              //by checking CPUID.80000001h.EDX[bit29]
  setc al                 //IF Bit29=1 then AL{Result}:=1{true; it's a 64-bit processor}
  jmp @Exit               //Exit {Note that Delphi may actually recode this as POP ESI; POP EBX; RET}


  @No64BitProcessor:
      xor eax, eax            //Result{AL/EAX}:=0{false; it's a 32-bit processor};
   @Exit:
    pop esi                   //Restore ESI
    pop ebx                   //Restore EBX
end;

Procedure SetChildTaborders(const Parent: TWinControl);
procedure FixTabOrder(const Parent: TWinControl);
  var
    ctl, L: Integer;
    List: TList;
  begin
    List := TList.Create;
    try
      for ctl := 0 to Parent.ControlCount - 1 do
      begin
        if Parent.Controls[ctl] is TWinControl then
        begin
          if List.Count = 0 then
            L := 0
          else
          begin
            with Parent.Controls[ctl] do
              for L := 0 to List.Count - 1 do
                if (Top < TControl(List[L]).Top) or ((Top = TControl(List[L]).Top) and (Left < TControl(List[L]).Left)) then
                  Break;
          end;

          List.Insert(L, Parent.Controls[ctl]);
          FixTabOrder(TWinControl(Parent.Controls[ctl]));
        end;
      end;
      for ctl := 0 to List.Count - 1 do
        TWinControl(List[ctl]).TabOrder := ctl;
    finally
      List.Free;
    end;
  end;
begin
  FixTabOrder(Parent);
end;

{
  EXEMPLO DE COMO UTILIZAR AS FUNES ABAIXO  RecordFromStream E A RecordToStream:

procedure TfrmMain.btnLoadFromStreamClick(Sender: TObject);
var
  filestream: TFileStream;
begin
  filestream := TFileStream.Create(ExtractFilePath(Application.ExeName)+'bd.settings' ,fmOpenRead or fmShareDenyNone);
  try
    ClientDataSet1.EmptyDataSet;
    ClientDataSet1.Append;
    Biblioteca.RecordFromStream(ClientDataSet1,filestream);
  finally
    FreeAndNil(filestream);
  end;
end;

procedure TfrmMain.btnSaveToStreamClick(Sender: TObject);
var
  filestream: TFileStream;
begin
  filestream := TFileStream.Create(ExtractFilePath(Application.ExeName)+'bd.settings' ,fmCreate or fmShareDenyNone);
  try
    if (ClientDataSet1.State in [dsInsert, dsEdit]) then ClientDataSet1.Post;
    Biblioteca.RecordToStream(ClientDataSet1,filestream,True);
  finally
    FreeAndNil(filestream);
  end;         
end;
}

procedure RecordFromStream(DSet: tdataSet; Stream: TStream {;FieldsToIgnore: array of tField}  );
function DoReadFld(aFld: tField):Boolean;
  //var i: Integer;
  begin
    Result := (aFld <> NIL) and (aFld.FieldNo > 0); { calculated and lookup fields are allways ignored }
    //if Result then
    {For i := 0 to High(FieldsToIgnore) do
    if aFld = FieldsToIgnore[i] then begin
      Result := false;
      break;
    end;}
  end;

  function ReadFldname: string;
  var L: longint;
  begin
    Stream.Read(L,sizeOf(L));
    if L = 0 then result := '' else begin
      SetLength(Result,L);
      Stream.Read(Result[1],L);
    end;
  end;

var Len    : Longint;
    Fld    : tField;
    Fldname: string;
    FldBuff: Pointer;
begin
  Getmem(FldBuff,256);
  try
    Fldname := ReadFldname;
    while Fldname <> '' do begin
      Fld := DSet.FindField(Fldname);
      Stream.Read(Len,SizeOf(Len));
      if (Len > 0) and DoReadFld(Fld) then begin
        if Fld is tBlobField then begin
          With TBlobStream.Create(Fld as tBlobField, bmWrite) do Try;
            CopyFrom(Stream,Len);
          finally
            Free;
          end;
        end else begin
          if Fld.datasize <> Len then
            raise Exception.CreateFmt('Field size changed: Field: %s',[Fldname]);
          Stream.Read(FldBuff^,Fld.dataSize);
          Fld.Setdata(FldBuff);
        end;
      end else if Len > 0 then Stream.Seek(Len, soFromCurrent);
      Fldname := ReadFldname;
    end
  finally
    Freemem(FldBuff,256);
  end;
end;

procedure RecordToStream(DSet: tdataSet; Stream: TStream;
  PhysFieldsOnly: Boolean {; FieldsNotStore: array of tField});
  function DoStoreFld(aFld: tField):Boolean;
    { Checks whether the field should be stored }
   // var i: Integer;
    begin
      Result := not PhysFieldsOnly or (aFld.FieldNo > 0); { FieldNo of Lookup and calculated fields is <= 0 }
     { if Result then
      For i := 0 to High(FieldsNotStore) do
      if aFld = FieldsNotStore[i] then begin
        Result := false;
        break;
      end;}
    end;

    procedure WriteFldname(fldname: string);
    var L: longint;
    begin
      L := length(fldname);
      Stream.Write(L,sizeOf(L));
      Stream.Write(fldname[1],L);
    end;

var I,Cnt,Len: Longint;
    Fld      : tField;
    FldBuff  : Pointer;
    BStream  : tBlobStream;
begin
  Cnt := DSet.FieldCount;
  Getmem(FldBuff,256);
  try
    For i := 1 to Cnt do begin
      Fld := DSet.Fields[i-1];
     // if not DoStoreFld(Fld) then Continue;
      WriteFldname(Fld.Fieldname);
      if Fld is tBlobField then begin
        BStream := TBlobStream.Create(Fld as tBlobField, bmRead);
        TRY
          Len := BStream.Size;
          Stream.Write(len,SizeOf(Len));
          if Len > 0 then Stream.CopyFrom(BStream,Len);
        finally
          BStream.Free;
        end;
      end else begin
        Len := Fld.dataSize;
        Fld.Getdata(FldBuff);
        Stream.Write(Len,SizeOf(Len));
        Stream.Write(FldBuff^,Len);
      End;
    end; { For }
    Len := 0;
    Stream.Write(Len,SizeOf(Len)); { mark the end of the stream with zero }
  finally
    Freemem(FldBuff,256);
  end;
end;


procedure SetRecNo(DataSet: TDataSet; const RecNo: Integer);
var
  ActiveRecNo, Distance: Integer;
begin
  if (RecNo > 0) then
  begin
    ActiveRecNo := DataSet.RecNo;
    if (RecNo <> ActiveRecNo) then
    begin
      DataSet.DisableControls;
      try
        Distance := RecNo - ActiveRecNo;
        DataSet.MoveBy(Distance);
      finally
        DataSet.EnableControls;
      end;
    end;
  end;
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


function CountFilesInFolder(path: string): integer;
var
  tsr: TSearchRec;
begin
  path := IncludeTrailingPathDelimiter (path);
  result := 0;
  if FindFirst (path + '*.*', faAnyFile and not faDirectory, tsr) = 0 then begin
    repeat
      inc (result);
    until FindNext (tsr) <> 0;
    FindClose (tsr);
  end;
end;

function CheckFileName(const sFileName: string): Boolean;
begin
  Result := CheckFileExistence(sFileName);
end;

{function MemoryStreamToString(M: TMemoryStream): string;
begin
  SetString(Result, PChar(M.Memory), M.Size div SizeOf(Char));
end;
}
function MemoryStreamToString(M: TMemoryStream): AnsiString;
begin
  SetString(Result, PAnsiChar(M.Memory), M.Size);
end;


//teste:   ShowMessage(FormatMillisecondsToDateTime(214363));
function FormatMillisecondsToDateTime(const ms: integer): string;
var
  dt : TDateTime;
begin
  dt := ms / MSecsPerSec / SecsPerDay;
  result := Format('%d days, %s', [trunc(dt), FormatDateTime('hh:nn:ss.z', Frac(dt))]);
end;


function GetNextWord(const Str, Find: string): string;
var
  i, k: integer;
  auxStr: string;
begin
  auxStr := Trim(Str);
  i := PosBMH(Find, Str);
  Result := Trim(Copy(str, i + length(Find), length(str)));
  k := PosBMH(' ', Result);
  if k > 0 then
    Result := Trim(Copy(Result, 1, k));
end;


function FileExistsLongFileNames(const FileName: WideString): Boolean;
begin
  if Length(FileName) < 2 then
  begin
    Result := False;
    Exit;
  end;
  if CompareMem(@FileName[1], @WideString('\\')[1], 2) then
    Result := (GetFileAttributesW(PWideChar(FileName)) and FILE_ATTRIBUTE_DIRECTORY = 0)
  else
    Result := (GetFileAttributesW(PWideChar(WideString('\\?\' + FileName))) and FILE_ATTRIBUTE_DIRECTORY = 0)
end;


function CheckFileExistence(FileName: String): Boolean;
var
  dwAttr:  DWORD;
begin
  // Get file attributes
  dwAttr:=GetFileAttributes(PChar(FileName));
  // Check
  result:=(dwAttr <> $FFFFFFFF) and ((dwAttr and FILE_ATTRIBUTE_DIRECTORY) = 0);
end;


function UserName: String;
var User: PChar;
    i: DWord;
begin
  i := 1024;
  user := StrAlloc(Succ(i));
  if GetUserName(User, i) then Result := StrPas(User)
                          else Result := 'unknown';
end; 

function removeFileExt(p:pAnsiChar):ansiString;
var
  p1,p2:pAnsiChar;
const
  NULL = #0;
begin
  p2:=nil;p1:=p;
  while p^<>NULL do begin if p^='.' then p2:=p;inc(p) end;
  if p2=nil then p2:=p;
  setLength(result,p2-p1);
  p:=pAnsiChar(result);
  while p1<>p2 do begin p^:=p1^;inc(p);inc(p1) end;
end;


procedure EmptyDir(const strDir: string);
var
  APath: string;
  MySearch: TSearchRec;
begin
  APath:=strDir;
  FindFirst(APath+'\*.*', faArchive, MySearch);
  DeleteFile(APath+'\'+MySearch.Name);
  while FindNext(MySearch)=0 do
  begin
    DeleteFile(APath+'\'+MySearch.Name);
  end;
  FindClose(MySearch);
end;


function StreamsAreIdentical(var aError: Integer; const aStream1, aStream2: TStream; const aBlockSize: Integer = 4096): Boolean;
var
  lBuffer1: array of byte;
  lBuffer2: array of byte;
  lBuffer1Readed,
  lBuffer2Readed,
  lBlockSize: integer;

begin
  Result:=False;
  aError:=0;
  try
    if aStream1.Size <> aStream2.Size
       then Exit;

    aStream1.Position:=0;
    aStream2.Position:=0;

    if aBlockSize>0
       then lBlockSize:=aBlockSize
       else lBlockSize:=4096;

    SetLength(lBuffer1, lBlockSize);
    SetLength(lBuffer2, lBlockSize);

    lBuffer1Readed:=1; // just for entering while

    while (lBuffer1Readed > 0) and (aStream1.Position < aStream1.Size) do
    begin
      lBuffer1Readed := aStream1.Read(lBuffer1[0], lBlockSize);
      lBuffer2Readed := aStream2.Read(lBuffer2[0], lBlockSize);

      if (lBuffer1Readed <> lBuffer2Readed) or ((lBuffer1Readed <> lBlockSize) and (aStream1.Position < aStream1.Size))
         then Exit;

      if not CompareMem(@lBuffer1[0], @lBuffer2[0], lBuffer1Readed)
         then Exit;
    end; // while

    Result:=True;
  except
    aError:=1; // stream read exception
  end;
end;


function FilesAreIdentical(var aError: Integer; const aFileName1, aFileName2: String; const aBlockSize: Integer = 4096): Boolean;
var lFileStream1,
    lFilestream2: TFileStream;

begin
 Result:=False;
 try
   if not (FileExists(aFileName1) and FileExists(aFileName2))
      then begin
        aError:=2; // file not found
        Exit;
      end;

   lFileStream1:=nil;
   lFileStream2:=nil;
   try
     lFileStream1:=TfileStream.Create(aFileName1, fmOpenRead or fmShareDenyNone);
     lFileStream2:=TFileStream.Create(aFileName2, fmOpenRead or fmShareDenyNone);
     result:=StreamsAreIdentical(aError, lFileStream1, lFileStream2, aBlockSize);
   finally
     if lFileStream2<>nil
        then lFileStream2.Free;

     if lFileStream1<>nil
        then lFileStream1.Free;
   end; // finally
 except
   aError:=3; // file open exception
 end; // except
end;


{ Exemplo de como usar:
  ObtemDados(MyClientDataSet, 'AnoMes', [auxAmilPago, auxAmilNaoPago, auxBradescoPago, auxBradescoNaoPago,
    auxGoldenCrossPago, auxGoldenCrossNaoPago, auxParticularPago, auxParticularNaoPago,
    X5PAGO, X5NAOPAGO, X6PAGO, X6NAOPAGO, X7PAGO, X7NAOPAGO, X8PAGO, X8NAOPAGO ]);
}
procedure ObtemDados(const DataSet: TClientDataSet; const KeyFields: string; const From: array of TDataSet);
function CompareFields(const FieldNames: string; const DB1, DB2: TDataSet): integer;
var
  Pos: integer;
  FName: string;
  F, FRef: TField;
begin
  Result := 0;
  Pos := 1;
  while (Pos <= Length(FieldNames)) and (Result = 0) do // continua no while somente enquanto for o campo for igual...
  begin
    FName := ExtractFieldName(FieldNames, Pos);
    F := DB1.FindField(FName);
    FRef := DB2.FindField(FName);
    if Assigned(F) and Assigned(FRef) then
    case F.DataType of
      ftSmallint,
      ftInteger,
      ftLargeint: Result := F.AsInteger - FRef.AsInteger;
      ftString: if TrimRight(TStringField(F).Value) > TrimRight(TStringField(FRef).Value) then Result := 1
                else if TrimRight(TStringField(F).Value) < TrimRight(TStringField(FRef).Value) then Result := -1;
      ftBCD, // ?
      ftFloat,
      ftCurrency: if F.AsFloat > FRef.AsFloat then Result := 1
                  else if F.AsFloat < FRef.AsFloat then Result := -1;
      ftDate,
      ftDateTime,
      ftTimeStamp: if F.AsDateTime > FRef.AsDateTime then Result := 1
                   else if F.AsDateTime < FRef.AsDateTime then Result := -1;
      else if F.Value > FRef.Value then Result := 1
      else if F.Value < FRef.Value then Result := -1;
    end;
  end;
end;

procedure InsertMergeData(const Dest: TDataSet;
  const KeyFields: string; const From: array of TDataSet);
var
  I: integer;
  FName: string;
  Field: TField;
  DBInsert: TDataSet;
  LActive: array of boolean;
  HighFrom: integer;
  {function IsKeyField(const FieldName: string): boolean;
  var
    Pos: integer;
  begin
    Pos := 1;
    while Pos <= Length(KeyFields) do
      if AnsiSameText(FieldName, ExtractFieldName(KeyFields, Pos)) then
      begin
        Result := True;
        exit;
      end;
    Result := False;
  end;}
  procedure InsertData;
  var
    J: integer;
  begin
    if not (Dest.State in dsEditModes) or (HighFrom = 0) or
       (CompareFields(KeyFields, DBInsert, Dest) <> 0) then
    begin
      Dest.CheckBrowseMode;
      Dest.Append;
    end;
    for J := 0 to DBInsert.FieldCount - 1 do
    begin
      FName := DBInsert.Fields[J].FieldName;
      //if not IsKeyField(FName) then
      begin
        Field := Dest.FindField(FName);
        if Assigned(Field) then
          Field.Value := DBInsert.Fields[J].Value;
      end;
    end;
  end;
begin
  //Dest.Open;
  HighFrom := High(From);
  SetLength(LActive, HighFrom + 1);
  for I := 0 to HighFrom do
  begin
    LActive[I] := From[I].Active;
    if LActive[I] then From[I].First
    else From[I].Open;
  end;

  repeat
    DBInsert := nil;
    // busca From com a menor chave
    for I := 0 to HighFrom do
      if not From[I].Eof and ((DBInsert = nil) or
         (CompareFields(KeyFields, From[I], DBInsert) < 0)) then
        DBInsert := From[I];
    if Assigned(DBInsert) then
    begin
      InsertData;
      DBInsert.Next;
    end;
  until DBInsert = nil;
  Dest.CheckBrowseMode;

  for I := 0 to HighFrom do
    From[I].Active := LActive[I];
end;


begin
  DataSet.AggregatesActive := False;
  DataSet.AutoCalcFields := False;
  if DataSet.Active then DataSet.EmptyDataSet
  else DataSet.CreateDataSet;
  InsertMergeData(DataSet, KeyFields, From);
  DataSet.AutoCalcFields := True;
  DataSet.AggregatesActive := True;
end;

{
Example
procedure TForm1.FormCreate(Sender: TObject);
var s:ansiString;
begin
 s:='C:\test.pas';
 caption:=string(ExtractFileNameWithoutExtension(pAnsiChar(s)));
end;
}
function ExtractFileNameWithoutExtension (p:pAnsiChar):ansiString;
var p1,p2:pAnsiChar;
begin
 p2:=nil;p1:=p;
 while p^<>cNULL do begin if p^='.' then p2:=p;inc(p) end;
 if p2=nil then p2:=p;
 setLength(result,p2-p1);
 p:=pAnsiChar(result);
 while p1<>p2 do begin p^:=p1^;inc(p);inc(p1) end;
end;

{
Function ExtractFileNameWithoutExtension(const Filename: String): String;
//Retorna o nome do Arquivo sem extenso
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
}

// fill the rich edit with colors
// <b>bold</b>, <s>string</s>, <n>number</n>, <c>comment</c>, <i>identifier</i>
{
    '<b>unit</b> <i>ecMini</i>;' + #$D#$A + #$D#$A +
    '<b>interface</b>' + #$D#$A + #$D#$A +
    '<b>implementation</b>' + #$D#$A + #$D#$A +
    '<b>initialization</b>' + #$D#$A +
    '  <b>raise</b> <i>Exception</i>.<i>Create</i>(<s>''Demo "early unit initialization".''</s>);' + #$D#$A +
    '<b>end</b>.',

    '<b>unit</b> <i>ecMain</i>;' + #$D#$A + #$D#$A +
    '<b>interface</b>' + #$D#$A + #$D#$A +
    '<b>uses</b>' + #$D#$A +
    '  <i>Windows</i>, <i>Messages</i>, <i>SysUtils</i>, <i>Classes</i>, <i>Graphics</i>, <i>Controls</i>, <i>Forms</i>,' + #$D#$A +
    '  <i>Dialogs</i>, <i>StdCtrls</i>, <i>ExtCtrls</i>, <i>Buttons</i>, <i>ComCtrls</i>;' + #$D#$A + #$D#$A +
    '<b>type</b>' + #$D#$A +
    '  <i>TFMainForm</i> = <b>class</b>(<i>TForm</i>) [...] <b>end</b>;' + #$D#$A + #$D#$A +
   }

procedure FillRichEdit(edit: TRichEdit; text: string);
var i1 : integer;
begin
  edit.Clear;
  while true do begin
    i1 := PosBMH('<', text);
    if i1 > 0 then begin
      if text[i1 + 1] <> '>' then begin
        edit.SelText := Copy(text, 1, i1 - 1);
        with edit.SelAttributes do
          case text[i1 + 1] of
            'b' : begin Style := [fsBold];   Color := clBlack  end;
            'i' : begin Style := [];         Color := clMaroon end;
            's' : begin Style := [];         Color := clGreen  end;
            'c' : begin Style := [fsItalic]; Color := clNavy   end;
            'n' : begin Style := [];         Color := clPurple end;
          end;
        Delete(text, 1, i1 + 2);
        i1 := PosBMH('</', text);
        edit.SelText := Copy(text, 1, i1 - 1);
        Delete(text, 1, i1 + 3);
        with edit.SelAttributes do begin
          Style := [];
          Color := clBlack;
        end;
      end else begin
        edit.SelText := Copy(text, 1, i1);
        Delete(text, 1, i1);
      end;
    end else
      break;
  end;
  edit.SelText := Copy(text, 1, Length(text));
end;



procedure HideTabsInPageCtrl(PageControl: TPageControl);
var iPage: Integer;
begin
  // hide the tabs
  for iPage := 0 to PageControl.PageCount - 1 do
    PageControl.Pages[iPage].TabVisible := False;
  // set the active tabsheet
  if (PageControl.PageCount > 0) then
    PageControl.ActivePage := PageControl.Pages[0];
  // hide the border of the pagecontrol
  PageControl.Style := tsButtons;
end;



/// <summary>
///   This function reads the file resource of "FileName" and returns
///   the version number as formatted text.</summary>
/// <example>
///   GetFmtFileVersion() = '4.13.128.0'
///   GetFmtFileVersion('', '%.2d-%.2d-%.2d') = '04-13-128'
/// </example>
/// <remarks>If "Fmt" is invalid, the function may raise an
///   EConvertError exception.</remarks>
/// <param name="FileName">Full path to exe or dll. If an empty
///   string is passed, the function uses the filename of the
///   running exe or dll.</param>
/// <param name="Fmt">Format string, you can use at most four integer
///   values.</param>
/// <returns>Formatted version number of file, '' if no version
///   resource found.</returns>
function GetFmtFileVersion(const FileName: String = '';
  const Fmt: String = '%d.%d.%d.%d'): String;
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
    Result := Format(Fmt, [iVer[1], iVer[2], iVer[3], iVer[4]]);
  end;
end;


/// <summary>
///   Executes an external program or opens a document with its
///   standard application.</summary>
/// <param name="FileName">Full path of application or document.</param>
/// <param name="Parameters">Command line arguments.</param>
/// <param name="ExitCode">Exitcode of application (only avaiable
///   if Wait > 0).</param>
/// <param name="Wait">[milliseconds] Maximum of time to wait,
///   until application has finished. After reaching this timeout,
///   the application will be terminated and False is returned as
///   result. 0 = don't wait on application, return immediately.</param>
/// <param name="Hide">If True, application runs invisible in the
///   background.</param>
/// <returns>True if application could be started successfully, False
///   if app could not be started or timeout was reached.</returns>
function MyShellExecute(const FileName, Parameters: String; var ExitCode: DWORD; const Wait: DWORD = 0;
  const Hide: Boolean = False): Boolean;
var
  myInfo: SHELLEXECUTEINFO;
  iWaitRes: DWORD;
begin
  // prepare SHELLEXECUTEINFO structure
  ZeroMemory(@myInfo, SizeOf(SHELLEXECUTEINFO));
  myInfo.cbSize := SizeOf(SHELLEXECUTEINFO);
  myInfo.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
  myInfo.lpFile := PChar(FileName);
  myInfo.lpParameters := PChar(Parameters);
  if Hide then
    myInfo.nShow := SW_HIDE
  else
    myInfo.nShow := SW_SHOWNORMAL;
  // start file
  ExitCode := 0;
  Result := ShellExecuteEx(@myInfo);
  // if process could be started
  if Result then
  begin
    // wait on process ?
    if (Wait > 0) then
    begin
      iWaitRes := WaitForSingleObject(myInfo.hProcess, Wait);
      // timeout reached ?
      if (iWaitRes = WAIT_TIMEOUT) then
      begin
        Result := False;
        TerminateProcess(myInfo.hProcess, 0);
      end;
      // get the exitcode
      GetExitCodeProcess(myInfo.hProcess, ExitCode);
    end;
    // close handle, because SEE_MASK_NOCLOSEPROCESS was set
    CloseHandle(myInfo.hProcess);
  end;
end;





//Executar e esperar at que o processo seja encerrado
//exemplo de como utilizar:   ShellExecuteAndWait('c:\arquivo.exe', SW_SHOWNORMAL);
function ShellExecuteAndWait(FileName: string; Visibility: integer): DWORD;
// Espera at que o processo criado seja encerrado 
  procedure WaitForExec(processHandle: THandle); 
  var msg: TMsg;
    ret: DWORD; 
  begin 
    // Fica em loop esperando o processo terminar 
    repeat 
      ret := MsgWaitForMultipleObjects(1, { diz para aguardar } 
        processHandle, { handle do processo } 
        False, { "acorda" com qualquer evento } 
        INFINITE, { espera o quanto for necessrio } 
        QS_PAINT or { "acorda" em mensagens de PAINT } 
        QS_SENDMESSAGE { "acorda" com msgs enviadas por outras threads }); 

      if ret = WAIT_FAILED then exit; { se falhou, cai fora... } 

      if ret = (WAIT_OBJECT_0 + 1) then 
      begin 
         {Recebeu uma mensagem, mas processa apenas mensagens de PAINT} 
        while PeekMessage(msg, 0, WM_PAINT, WM_PAINT, PM_REMOVE) do 
          DispatchMessage(msg); 
      end; 
    until ret = WAIT_OBJECT_0; 
  end; 

var
  ShellExecuteInfo: TShellExecuteInfo; 

begin 
  FillChar(ShellExecuteInfo, SizeOf(ShellExecuteInfo), #0); 
  with ShellExecuteInfo do 
  begin 
    cbSize := SizeOf(TShellExecuteInfo); 
    fMask := SEE_MASK_NOCLOSEPROCESS; 
    Wnd := application.Handle; 
    lpVerb := 'open'; 
    lpFile := PCHAR(FileName); 
    lpParameters := nil; 
    lpDirectory := nil; 
    nShow := SW_SHOWNORMAL; 
  end; 

  ShellExecuteEx(@ShellExecuteInfo); 
  if ShellExecuteInfo.hProcess = 0 then 
    Result := DWORD(-1) { Falhou na criao do processo} 
  else 
  begin 
    // Aguarda pelo encerramento do processo 
    WaitforExec(ShellExecuteInfo.hProcess); 
    // Recupera o cdigo de retorno da aplicao 
    GetExitCodeProcess(ShellExecuteInfo.hProcess, Result); 
    // Fecha o handle do processo para liberar os resources 
    CloseHandle(ShellExecuteInfo.hProcess); 
  end;
end; 



{
Exemplo de como utilizar a funo RemoveTitleBar:
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  RemoveTitleBar(Handle);
end;
}

function RemoveTitleBar(hWindow: THANDLE; Hide: boolean = True): DWORD;
var
  R: TRect;
begin
  Result := GetWindowLong(hWindow, GWL_STYLE);
  if (Hide) then
    Result := Result and not WS_CAPTION
  else
    Result := Result or WS_CAPTION;
  GetClientRect(hWindow, R);
  SetWindowLong(hWindow, GWL_STYLE, Result);
  AdjustWindowRect(R, Result, boolean(GetMenu(hWindow)));
  SetWindowPos(hWindow, 0, 0, 0, (R.Right - R.Left), (R.Bottom - R.Top),
    SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOSENDCHANGING);
end;


///   function _LoadWindowsStr
///   Searches for a text resource in a Windows library.
///   Sometimes, using the existing Windows resources, you can
///   make your code language independent and you don't have to
///   care about translation problems.
/// </summary>
/// <example>
///   btnCancel.Caption := Sto_LoadWindowsStr('user32.dll', 801, 'Cancel');
///   btnYes.Caption := Sto_LoadWindowsStr('user32.dll', 805, 'Yes');
/// </example>
/// <param name="LibraryName">Name of the windows library like
///   'user32.dll' or 'shell32.dll'</param>
/// <param name="Ident">Id of the string resource.</param>
/// <param name="DefaultText">Return this text, if the resource
///   string could not be found.</param>
/// <returns>Desired string if the resource was found, otherwise
///   the DefaultText</returns>
function LoadWindowsStr(const LibraryName: String; const Ident: Integer;
  const DefaultText: String = ''): String;
const
  BUF_SIZE = 1024;
var
  hLibrary: THandle;
  iSize: Integer;
begin
  hLibrary := GetModuleHandle(PChar(LibraryName));
  if (hLibrary <> 0) then
  begin
    SetLength(Result, BUF_SIZE);
    iSize := LoadString(hLibrary, Ident, PChar(Result), BUF_SIZE);
    if (iSize > 0) then
      SetLength(Result, iSize)
    else
      Result := DefaultText;
  end
  else
    Result := DefaultText;
end;



////////////////////////////////////////////////////////////////
// copies filenames from the clipboard to "Filenames" if there
// are any. the clipboard can contain file- and directory names.

procedure PasteFilenamesFromClipboard(Filenames: TStrings);
var
  hDropHandle: HDROP;
  szBuffer: PChar;
  iCount, iIndex: Integer;
  iLength: Integer;
begin
  // check entry conditions
  if (Filenames = nil) then Exit;
  Filenames.Clear;
  // lock clipboard
  Clipboard.Open;
  try
  // does clipboard contain filenames?
  if (Clipboard.HasFormat(CF_HDROP)) then
  begin
    // get drop handle from the clipboard
    hDropHandle := Clipboard.GetAsHandle(CF_HDROP);
    // enumerate filenames
    iCount := DragQueryFile(hDropHandle, $FFFFFFFF, nil, 0);
    for iIndex := 0 to iCount - 1 do
    begin
      // get length of filename
      iLength := DragQueryFile(hDropHandle, iIndex, nil, 0);
      // allocate the memory, the #0 is not included in "iLength"
      szBuffer := StrAlloc(iLength + 1);
      try
      // get filename
      DragQueryFile(hDropHandle, iIndex, szBuffer, iLength + 1);
      Filenames.Add(szBuffer);
      finally // free the memory
        StrDispose(szBuffer);
      end;
    end;
  end;
  finally
    // unlock clipboard
    Clipboard.Close;
  end;
end;


////////////////////////////////////////////////////////////////
// copies filenames from "Filenames" to the clipboard.
// "Filenames" can contain file- and directory names.
function CopyFilenamesToClipboard(Filenames: TStrings): Boolean;
var
  sFilenames: String;
  iIndex: Integer;
  hBuffer: HGLOBAL;
  pBuffer: PDropFiles;
begin
  // check entry conditions
  Result := (Filenames <> nil) and (Filenames.Count > 0);
  if (not Result) then Exit;
  // bring the filenames in a form,
  // separated by #0 and ending with a double #0#0
  sFilenames := '';
  for iIndex := 0 to Filenames.Count - 1 do
    sFilenames := sFilenames +
      ExcludeTrailingPathDelimiter(Filenames.Strings[iIndex]) + #0;
  sFilenames := sFilenames + #0;
  // allocate memory with the size of the "DropFiles" structure plus the
  // length of the filename buffer.
  hBuffer := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT,
    SizeOf(DROPFILES) + Length(sFilenames));
  try
  Result := (hBuffer <> 0);
  if (Result) then
  begin
    pBuffer := GlobalLock(hBuffer);
    try
    // prepare the "DROPFILES" structure
    pBuffer^.pFiles := SizeOf(DROPFILES);
    // behind the "DROPFILES" structure we place the filenames
    pBuffer := Pointer(Integer(pBuffer) + SizeOf(DROPFILES));
    CopyMemory(pBuffer, PChar(sFilenames), Length(sFilenames));
    finally
      GlobalUnlock(hBuffer);
    end;
    // copy buffer to the clipboard
    Clipboard.Open;
    try
    Clipboard.SetAsHandle(CF_HDROP, hBuffer);
    finally
      Clipboard.Close;
    end;
  end;
  except
    Result := False;
    // free only if handle could not be passed to the clipboard
    GlobalFree(hBuffer);
  end;
end;


////////////////////////////////////////////////////////////////
// "Directory": will be searched for files and directories, the results will
//   be added with the full path to "List". directories are written with a
//   trailing "\" at the end.
// "Mask": can contain one or several masks, delimited with a semikolon. to
//   ignore directory names, add an extension to the mask. for more detailed
//   information see the delphi function "FindFirst".
// "Recursive": if true, subdirectories will be searched too.
// "Append": if true, existing entries remain in "List".

procedure SearchDirectory(List: TStrings; const Directory: String;
  const Mask: String = '*.*'; Recursive: Boolean = True;
  Append: Boolean = False);
 procedure _SearchDirectory(List: TStrings; const DelimitedDirectory: String;
    Masks: TStrings; Recursive: Boolean);
  var
    iMaskIndex: Integer;
    bFoundFile: Boolean;
    mySearchRec: TSearchRec;
    sFile, sDirectory: String;
  begin
    // list files and directories
    for iMaskIndex := 0 to Masks.Count - 1 do
    begin
      bFoundFile := FindFirst(DelimitedDirectory + Masks[iMaskIndex],
        faAnyFile, mySearchRec) = 0;
      while (bFoundFile) do
      begin
        // skip "." and ".."
        if (mySearchRec.Name <> '.') and (mySearchRec.Name <> '..') then
        begin
          sFile := DelimitedDirectory + mySearchRec.Name;
          // add delimiter to directories
          if ((mySearchRec.Attr and faDirectory) <> 0) then
            sFile := IncludeTrailingPathDelimiter(sFile);
          // add to list
          List.Add(sFile);
        end;
        // find next file
        bFoundFile := FindNext(mySearchRec) = 0;
      end;
      FindClose(mySearchRec);
    end;
    // recursive call for directories
    if (Recursive) then
    begin
      bFoundFile := FindFirst(DelimitedDirectory + '*', faDirectory,
        mySearchRec) = 0;
      while (bFoundFile) do
      begin
        // skip "." and ".."
        if (mySearchRec.Name <> '.') and (mySearchRec.Name <> '..') then
        begin
          sDirectory := IncludeTrailingPathDelimiter(DelimitedDirectory +
            mySearchRec.Name);
          _SearchDirectory(List, sDirectory, Masks, Recursive);
        end;
        // find next directory
        bFoundFile := FindNext(mySearchRec) = 0;
      end;
      FindClose(mySearchRec);
    end;
  end;

var
  slMasks: TStringList;
begin
  // prepare list
  if (not Append) then
    List.Clear;
  List.BeginUpdate;
  slMasks := TStringList.Create;
  try
  // prepare masks
  if (Mask = '') then
    slMasks.Add('*')
  else
  begin
    slMasks.Delimiter := ';';
    slMasks.DelimitedText := Mask;
  end;
  // start recursive loop
  _SearchDirectory(List, IncludeTrailingPathDelimiter(Directory),
    slMasks, Recursive);
  finally
    slMasks.Free;
    List.EndUpdate;
  end;
end;



 // - "Filenames" is a list of files and directories you want to delete.
//   the user will be asked for confirmation and the progress dialog will
//   be displayed if necessary.
// - "ParentWindow" is the parent window for message boxes, you can pass "0".
// after executing, you have to check, which files where really deleted,
// because the user can cancel the deleting procedure.
procedure DeleteFilesToRecyclebin(const ParentWindow: HWND; const Filenames: TStrings;
  const ToRecycleBin: Boolean = True);
var
  iFile: Integer;
  sFilenames: String;
  myFileOp: SHFILEOPSTRUCT;
begin
  if (Filenames.Count = 0) then Exit;
  // create a #0 delimited string with two trailing #0
  sFilenames := '';
  for iFile := 0 to Filenames.Count - 1 do
    sFilenames := sFilenames + ExcludeTrailingPathDelimiter(Filenames.Strings[iFile]) + #0;
  sFilenames := sFilenames + #0;
  // prepare the SHFILEOPSTRUCT
  FillChar(myFileOp, SizeOf(myFileOp), 0);
  myFileOp.Wnd := ParentWindow;
  myFileOp.wFunc := FO_DELETE;
  myFileOp.pFrom := PChar(sFilenames);
  // could be moved to the recyclebin, even if "ToRecycleBin" is false.
  if ToRecycleBin then
    myFileOp.fFlags := myFileOp.fFlags or FOF_ALLOWUNDO;
  SHFileOperation(myFileOp);
end;



//this function determines the size of a file in bytes,
//the size can be more than 2 GB.
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

//To get the short DOS filename, Delphi offers the function "ExtractShortPathName",
//to get the long filename from a DOS filename you can use the ExtractLongPathName function:
function  ExtractLongPathName(const ShortPathName: String): String;
var
  bSuccess: Boolean;
  fncGetLongPathName: function (lpszShortPath: LPCTSTR;
    lpszLongPath: LPTSTR; cchBuffer: DWORD): DWORD stdcall;
  szBuffer: array[0..MAX_PATH] of Char;
  pDesktop: IShellFolder;
  swShortPath: WideString;
  iEaten: ULONG;
  pItemList: PItemIDList;
  iAttributes: ULONG;
begin
  bSuccess := False;
  // try to use the function "GetLongPathNameA" (Win98/2000 and up)
  @fncGetLongPathName := GetProcAddress(
    GetModuleHandle('Kernel32.dll'), 'GetLongPathNameA');
  if (Assigned(fncGetLongPathName)) then
  begin
    bSuccess := fncGetLongPathName(PChar(ShortPathName), szBuffer,
      SizeOf(szBuffer)) <> 0;
    if bSuccess then
      Result := szBuffer;
  end;
  // use an alternative way of getting the path (Win95/NT). the function
  // "SHGetFileInfo" (as often seen in examples) only converts the
  // filename without the path.
  if (not bSuccess) and Succeeded(SHGetDesktopFolder(pDesktop)) then
  begin
    swShortPath := ShortPathName;
    iAttributes := 0;
    if Succeeded(pDesktop.ParseDisplayName(0, nil, POLESTR(swShortPath),
      iEaten, pItemList, iAttributes)) then
    begin
      bSuccess := SHGetPathFromIDList(pItemList, szBuffer);
      if bSuccess then
        Result := szBuffer;
      // release ItemIdList (SHGetMalloc is superseded)
      CoTaskMemFree(pItemList);
    end;
  end;
  // give back the original path if unsuccessful
  if (not bSuccess) then
    Result := ShortPathName;

end;


procedure DBGridSelectAll(AGrid: TDBGrid) ;
begin
   AGrid.SelectedRows.Clear;
   with AGrid.DataSource.DataSet do
   begin
     DisableControls;
     First;
     try
       while not EOF do
       begin
         AGrid.SelectedRows.CurrentRowSelected := True;
         Next;
       end;
     finally
       EnableControls;
     end;
   end;
end;

////////////////////////////////////////////////////////////////
// this procedure sets the with of the dropdown box, if the
// content is to large for the standard width.
procedure AutoWidthCombobox(Combobox: TCombobox);
const
  HORIZONTAL_PADDING = 4;
var
  iWidth: Integer;
  iIndex: Integer;
  iLineWidth: Integer;
begin
  iWidth := 0;
  // calculate the width of the drop down content
  for iIndex := 0 to Combobox.Items.Count - 1 do
  begin
    iLineWidth := Combobox.Canvas.TextWidth(Combobox.Items[iIndex]);
    Inc(iLineWidth, 2 * HORIZONTAL_PADDING);
    if (iLineWidth > iWidth) then
      iWidth := iLineWidth;
  end;
  // set the calculated width if necessary
  if (iWidth > Combobox.Width) then
    SendMessage(Combobox.Handle, CB_SETDROPPEDWIDTH, iWidth, 0);
end;



procedure AlignTitles(Grid : TDBGrid);
var
   j, k: Integer;
begin
  with Grid.DataSource.DataSet do
   for j := 0 to -1 + Grid.FieldCount do
    for k := 0 to -1 + FieldCount do
     if Fields[k].FieldName = Grid.Fields[j].FieldName then
      Grid.Columns[j].Title.Alignment := Fields[k].Alignment;
end; (* AlignTitles *)


function JanelaExiste(const fForm: TForm): Boolean;
var
  i: integer;
begin
  Result := False;
  if Assigned(fForm) then
  for i := 0 to Screen.FormCount - 1 do
    if (Screen.Forms[i] = fForm) then
    begin
      Result := True;
      Break;
    end;
end;

function JanelaMDIExiste(const fForm: TForm): Boolean;
var
  i: integer;
begin
  Result := False;
  if Assigned(fForm) then
  for i := fForm.MDIChildCount - 1 downto 0 do
    if (fForm.MDIChildren[i] = fForm) then
    begin
      Result := True;
      fForm.MDIChildren[i].BringToFront;
      Break;
    end;
end;

procedure ClearControlsPassedByParameters(
 const ArrayCtrls: array of TControl);
var i: integer;
begin
  for i := 0 to HIGH(ArrayCtrls) do
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


procedure FocaControle(const ArrayCtrls: array of TWinControl);
var
  i: integer;
begin
  for i := 0 to HIGH(ArrayCtrls) do
  begin
    if TComponent(ArrayCtrls[i]) is TEdit then //TEdit
    begin
      if TEdit(TComponent(ArrayCtrls[i])).Focused then
        TEdit(TComponent(ArrayCtrls[i])).Color := $00D8FEFC
      else
        TEdit(TComponent(ArrayCtrls[i])).Color := clWindow;
    end;
    if TComponent(ArrayCtrls[i]) is TMaskEdit then //TMaskEdit
    begin
      if TMaskEdit(TComponent(ArrayCtrls[i])).Focused then
        TMaskEdit(TComponent(ArrayCtrls[i])).Color := $00D8FEFC
      else
        TMaskEdit(TComponent(ArrayCtrls[i])).Color := clWindow;
    end;
    if TComponent(ArrayCtrls[i]) is TComboBox then //TComboBox
    begin
      if TComboBox(TComponent(ArrayCtrls[i])).Focused then
        TComboBox(TComponent(ArrayCtrls[i])).Color := $00D8FEFC
      else
        TComboBox(TComponent(ArrayCtrls[i])).Color := clWindow;
    end;
  end;
end;



//funo para converter de minutos para horas
function MinutesToHours(const Min: integer): string;
const
  MinSeparator: array[boolean] of string = (':', ':0');
begin
  Result := FormatFloat('0,', Min div 60) + MinSeparator[Min mod 60 < 10]
   + IntToStr(Min mod 60);
end;


//funo para converter de horas para minutos
//obs: converte QUALQUER quantidade de horas para minutos.
function HoursToMinutes(const Hour: string): string;
var
  auxHr, auxMin: string;
begin
  Result := '0';
  if (Hour = '') then Exit;

  auxHr  := copy(Hour,pos(':',Hour)-length(Hour),pos(':',Hour)-1);
  auxMin := copy(Hour,pos(':',Hour)+1,length(hour));

  if (auxHr = '0') or (auxHr = '00') then
    Result := IntToStr(StrToIntDef(auxMin,0))
  else if (auxHr <> EmptyStr) then Result := IntToStr((StrToIntDef(auxHr,0) * 60) + StrToIntDef(auxMin, 0));
end;


//funo para converter de horas para dias
//mostra aproximao de duas casas decimais =>cd ex: 2,5 dias.
function HoursToDays(const Hour: string): string;
var
  Minutos: integer;
  dHoras: Double;
 // auxAntesDecimal, auxDepoisDecimal: string;
begin
  Minutos := StrToIntDef(HoursToMinutes(Hour),0);
  dHoras := ArredondaComDecimais (Minutos/480,2); //480 = 8h * 60 min. A hora aqui  a comercial (8h e no 24).
                           //Para calcular hora integral alterar de 480 para 1440 (24h * 60 min)
  Result := FloatToStr(dHoras);
  Result := Result + ' dias';
end;

//funo prtica para arrendondamento com decimais, pois a funo Round do Delphi
//no faz isso...
function ArredondaComDecimais(X: double; Decimals: integer): Double;
var
  Mult: Double;
begin
  Mult   := Power(10, Decimals);
  Result := Trunc(X*Mult+0.5*Sign(X))/Mult;
end;

//funo para extrair o cone de um programa.
//basta passar dois parmetros: Ex:
//ExtraiIconeDoPrograma('C:\Bcps.exe','C:\Bcps.ico');
procedure ExtraiIconeDoPrograma(const DirOndeEstaOPrograma: string; const DirOndeVaiSalvarOIcone: string);
var
  Image: TPicture;
  Handle: THandle;
begin
  Image := TPicture.Create;
  Image.Icon.Handle := ExtractIcon(Handle,Pchar(DirOndeEstaOPrograma),0);
  Image.SaveToFile(DirOndeVaiSalvarOIcone);
  Image.Free;
end;


//Retorna a string entre as Tags de um HTML.
//Exemplo:
//label1.caption:= CopiaEntreTags('<TITLE>Ttulo da pgina</TITLE>','<TITLE>','</TITLE>');
//retornar a string 'Ttulo da pgina'.
function CopiaEntreTags(Frase, Inicio, Fim: String): String;
var
  iAux,kAux:Integer;
begin
  Result:='';
  if (PosBMH(Fim,Frase) <> 0) and (PosBMH(Inicio,Frase)<>0) then
  begin
    iAux:=PosBMH(Inicio,Frase)+length(Inicio);
    kAux:=PosBMH(Fim,Frase);
    Result:=Copy(Frase,iAux,kAux-iAux);
  end;
end;    


{Uso:
RetornaTexto('Exemplo de um "texto" entre aspas','"');
retornar uma string contendo a palavra texto }
function RetornaTexto(Texto: String;
  Caracter: Char): String;
var
  I,Posicao1,Posicao2:Integer;
  TextoInvertido:String;
begin
  Result:='';
  for I := Length(Texto) downto 1 do
  begin
    TextoInvertido:=TextoInvertido+Texto[I]
  end;
  Posicao1:=PosBMH(Caracter,Texto)+1;
  Posicao2:=PosBMH(Caracter,TextoInvertido)-1;
  Result:=Copy(Texto,Posicao1,Length(Texto)-(Posicao1+Posicao2));
end;


function EmptyExists(const Value: string): Boolean;
begin
  Result := (PosBMH(' ',Value) > 0);
end;

function EmptyDate(const FStringDate: string): Boolean;
begin
  Result := (FStringDate = '  /  /    ') or (FStringDate = '');
end;


//passar a data no formato dd/mm/yyyy
function IsValidDate(const FStringDate: string): Boolean;
var AuxDia, AuxMes, AuxAno: string;
  IntDia, IntMes, IntAno: smallint;
begin
  AuxDia := copy(FStringDate,1,2);
  AuxMes := copy(FStringDate,4,2);
  AuxAno := copy(FStringDate,7,4);
  IntDia := 0;
  IntMes := 0;
  IntAno := 0;

  if AuxDia <> EmptyStr then IntDia := StrToIntDef(AuxDia, 0);
  if AuxMes <> EmptyStr then IntMes := StrToIntDef(AuxMes, 0);
  if AuxAno <> EmptyStr then IntAno := StrToIntDef(AuxAno, 0);

  Result := (IntAno >= 1) and (IntAno <= 9999) and
  (IntMes >= 1) and (IntMes <= 12) and
  (IntDia >= 1) and (IntDia <= DaysInAMonth(IntAno, IntMes));
end;


function EmptyCEP(const Value: string): Boolean;
begin
  Result := (Value = '  .   -   ')     or (Value = '');
end;

function EmptyFone(const Value: string): Boolean;
begin
  Result := (Value = '(  )     -    ') or (Value = '');
end;

function EmptyCPF(const Value: string): Boolean;
begin
  Result := (Value = '   .   .   -  ') or (Value = '');
end;

Function IsNumber(strNumber : String) : Boolean;
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

function AfterFirsSpace(const Str: string): string;
var
 P: integer;
begin
  Result := Str;
  P := PosBMH(' ', Result);
 //  if (StrToIntDef(Copy(Result, 1, P - 1), -1) <> -1) then  // apenas no incio
 //   if (P > 1) and (P < 5)  then  // apenas no incio
  Result := Copy(Result, P+1, length(result));
end;


function FiltraLetra(const S:string;const ValidChars: TCHars):boolean;
 var i:integer;
begin
  result:=false;
  for I:=1 to length(s) do
  if S[I] in ValidChars then
  result:=true;
 //Result:= Result + S[I];
end;

function AbreviaNome(Nome: String): String;
var
  Nomes: array[1..20] of string;
  i, TotalNomes: integer;
begin
  Nome := Trim(Nome);
  Result := Nome;
  Nome := Nome + #32;
  i := PosBMH(#32, Nome);
  if  i > 0 then
  begin
   TotalNomes := 0;
  while i > 0 do
  begin
    Inc(TotalNomes);
    Nomes[TotalNomes] := Copy(Nome, 1, i - 1);
    Delete(Nome, 1, i);
    i := PosBMH(#32, Nome);
  end;
  begin
  for i := 2 to TotalNomes - 1 do
  begin
    if Length(Nomes[i]) > 3 then
    Nomes[i] := Nomes[i][1] +  '.';
  end;
  Result := ' ';
  for i := 1 to TotalNomes do
    Result := Result + Trim(Nomes[i]) + #32;
  Result := Trim(Result);
  end;
  end;
end;

procedure MostraForm(aFormClass: TFormClass);
begin
 with aFormClass.Create(Application) do
  try
    ShowModal;
    BringToFront;
  finally
    Free;
  end;
end;

procedure MudarComEnter(var Msg: TMsg; var Handled: Boolean);
begin
  If not ((Screen.ActiveControl is TCustomMemo) or
  (Screen.ActiveControl is TCustomGrid) or
  (Screen.ActiveForm.ClassName = 'TMessageForm')) then
  begin
    If Msg.message = WM_KEYDOWN then
    begin
      Case Msg.wParam of
        VK_RETURN,VK_DOWN : Screen.ActiveForm.Perform(WM_NextDlgCtl,0,0);
        VK_UP : Screen.ActiveForm.Perform(WM_NextDlgCtl,1,0);
        VK_TAB: ShowMessage('Attention: use the ENTER key only, not TAB.');
      end;
    end;
  end;
end;

procedure GerarExcel(Consulta: TADOQuery);
var
 coluna, linha: integer;
 excel: variant;
 valor: string;
begin
  try
  excel:=CreateOleObject('Excel.Application');
  excel.Workbooks.add(1);
  except FastFileMessageBox('Verso do Ms-Excel'+
  'Incompatvel','Erro',MB_OK+MB_ICONEXCLAMATION);
  end;
  Consulta.First;
  try
    for linha:=0 to Consulta.RecordCount-1 do
    begin
    for coluna:=1 to Consulta.FieldCount do
    begin
      valor:= Consulta.Fields[coluna-1].AsString; excel.cells [linha+2,coluna]:=valor;
    end;
    Consulta.Next;
  end;
    for coluna:=1 to Consulta.FieldCount do
    begin
      valor:= Consulta.Fields[coluna-1].DisplayLabel;
      excel.cells[1,coluna]:=valor;
    end;
      excel.columns.AutoFit;
      excel.visible:=true;
  except
   FastFileMessageBox('Aconteceu um erro desconhecido durante a converso'+ 
   'da tabela para o Ms-Excel','Erro',MB_OK+MB_ICONEXCLAMATION);
 end;
end;



function FormataCEP(sCEP:String):String;
begin
  Result := copy(sCEP,1,2) +  copy(sCEP,3,3) + '-' +
  copy(sCEP,6,5);
end;

function FormataCEPComPonto(sCEP:String):String;
begin
  Result := copy(sCEP,1,2) + '.'+ copy(sCEP,3,8);
end;

Function Modulo11CGC(Numero: String):String;
var
  aPeso: array[1..20] of integer;
  aNum:  array[1..20] of integer;
  Total,nX,nC,Dv: integer;
begin
  nC:=2;
  Total:=0;
  for nX:=length(Numero) downto 1 do
  begin
    aPeso[nX]:=nC;
    nC:=nC+1;
  if nC > 9 then nC:=2;
  end;
  for nX:=1 to length(Numero) do
  begin
    aNum[nX]:=strtoint(copy(Numero,nX,1));
    Total:=Total+(aNum[nX]*aPeso[nX]);
  end;
  Dv:=(11-(Total mod 11));
  if Dv > 9 then Dv:=0;
  Result:=inttostr(Dv)
end;

Function ValidaCGC(Numero: String):Boolean;
var
  Dv1,Dv2: string;
begin
  Dv1:=Modulo11CGC(copy(Numero,1,12));
  Dv2:=Modulo11CGC(copy(Numero,1,12)+Dv1);
  Result := (Dv1<>copy(Numero,13,1)) or (Dv2<>copy(Numero,14,1));
end;

Function Modulo11CPF(Numero: String):String;
var
  aPeso: array[1..20] of integer;
  aNum:  array[1..20] of integer;
  Total,nX,nC,Dv: integer;
begin
  nC:=2;
  Total:=0;
  for nX:=length(Numero) downto 1 do
  begin
    aPeso[nX]:=nC;
    nC:=nC+1;
  end;
  for nX:=1 to length(Numero) do
  begin
    aNum[nX]:=strtoint(copy(Numero,nX,1));
    Total:=Total+(aNum[nX]*aPeso[nX]);
  end;
  Dv:=(11-(Total mod 11));
  if Dv > 9 then Dv:=0;
  Result:=inttostr(Dv);
end;

Function ValidaCPF(Numero: String):Boolean;
var
 Dv1,Dv2: string;
begin
  Dv1:=Modulo11CPF(copy(Numero,1,9));
  Dv2:=Modulo11CPF(copy(Numero,1,9)+Dv1);
  if (Dv1<>copy(Numero,10,1)) or (Dv2<>copy(Numero,11,1)) then
  begin
    Abort;
    Result:=True;
  end
  else Result:=False;
end;

function cpf(num: string): boolean;
var
  n1,n2,n3,n4,n5,n6,n7,n8,n9: integer;
  d1,d2: integer;
  digitado, calculado: string;
begin
  n1:=StrToInt(num[1]);
  n2:=StrToInt(num[2]);
  n3:=StrToInt(num[3]);
  n4:=StrToInt(num[4]);
  n5:=StrToInt(num[5]);
  n6:=StrToInt(num[6]);
  n7:=StrToInt(num[7]); 
  n8:=StrToInt(num[8]);
  n9:=StrToInt(num[9]);
  d1:=n9*2+n8*3+n7*4+n6*5+n5*6+n4*7+n3*8+n2*9+n1*10;
  d1:=11-(d1 mod 11);
  if d1>=10 then
     d1:=0;
     d2:=d1*2+n9*3+n8*4+n7*5+n6*6+n5*7+n4*8+n3*9+n2*10+n1*11; 
     d2:=11-(d2 mod 11);
     if d2>=10 then
        d2:=0;
        calculado:=inttostr(d1)+inttostr(d2);
        digitado:=num[10]+num[11];
        if calculado=digitado then
          cpf:=true
          else cpf:=false;
end;

function fCheckEmail(Email: String): Boolean;
var {sintaxe: nome@provedor.com.br ou outros}
  s: String;
  EPos: Integer; 
begin
  EPos:= pos('@',Email);
  if Epos > 1 then
   begin
   s:= copy(EMail,Epos+1,Length(Email));
   if (pos('.',s)> 1) and (pos('.',s)< length(s)) then
   Result := true
   else Result := False;
   end
   else
   Result := False;
end;

function ReverseStr (S: ShortString): ShortString;
var
  I: Integer;
  begin
  Result := '';
  For I := Length(S) DownTo 1 Do
  Result := Result + S[I];
end;

function RemoveAcentos(Str: String): String;
Const ComAcento = '';
     SemAcento = 'aaeouaoaeioucuAAEOUAOAEIOUCU';
var
  x: integer;
begin
  For x:= 1 to Length(Str) do
  begin
  if PosBMH(Str[x], ComAcento) <> 0 then
    Str[x] := SemAcento[PosBMH(Str[x], ComAcento)];
  end;
  Result := Str;
end;

function TiraPontos(x: String): String;
  Var Cont:Integer;
Begin
  Result:='';
  for Cont:=1 to Length(x) do
    If  x[Cont]<>'.' then
      Result:=Result+x[cont]
End;


function strNiceNum(const S: String) : String;
var
  i    : Integer;
  Seps : set of Char;
begin
  Seps:=[FormatSettings.ThousandSeparator,FormatSettings.DecimalSeparator];
  Result:= '0';
  for i := 1 to Length(S) do
  if S[i] in DIGITS + Seps then
  begin
  if S[i] = FormatSettings.ThousandSeparator then
    Result:=Result+FormatSettings.DecimalSeparator
  else
   Result:=Result+S[i];
   if S[i] In Seps then Seps:=[];
  end
end;


function IntToSpell(num: integer): string;
var
  spell: string;
  hspell: string;
  hundred: string;
  thousand: string;
  tthousand: string;
  hthousand: string;
  million: string;
begin
  if num < 10 then
     spell := trans9(num);
  {endif}
  if (num < 20) and (num > 10) then
     spell := trans19(num);
  {endif}
  if (((num < 100) and (num > 19)) or (num = 10)) then
  begin
    hspell := copy(IntToStr(num),1,1) + '0';
    spell := trans99(StrToInt(hspell));
    hspell := copy(IntToStr(num),2,1);
    spell := spell + ' ' + IntToSpell(StrToInt(hspell));
  end;
  if (num < 1000) and (num > 100) then
  begin
    hspell := copy(IntToStr(num),1,1);
    hundred := IntToSpell(StrToInt(hspell));
    hspell := copy(IntToStr(num),2,2);
    hundred := hundred + ' cem e ' + IntToSpell(StrToInt(hspell));
    spell := hundred;
  end;
  if (num < 10000) and (num > 1000) then
  begin
    hspell := copy(IntToStr(num),1,1);
    thousand := IntToSpell(StrToInt(hspell));
    hspell := copy(IntToStr(num),2,3);
    thousand := thousand + ' mil ' + IntToSpell(StrToInt(hspell));
    spell := thousand;
  end;
  if (num < 100000) and (num > 10000) then
  begin
    hspell := copy(IntToStr(num),1,2);
    tthousand := IntToSpell(StrToInt(hspell));
    hspell := copy(IntToStr(num),3,3);
    tthousand := tthousand + ' mil ' + IntToSpell(StrToInt(hspell));
    spell := tthousand;
  end;
  if (num < 1000000) and (num > 100000) then
  begin
    hspell := copy(IntToStr(num),1,3);
    hthousand := IntToSpell(StrToInt(hspell));
    hspell := copy(IntToStr(num),4,3);
    hthousand := hthousand + ' mil e ' +
    IntToSpell(StrToInt(hspell));
    spell := hthousand;
  end;
  if (num < 10000000) and (num > 1000000) then
  begin
    hspell := copy(IntToStr(num),1,1);
    million := IntToSpell(StrToInt(hspell));
    hspell := copy(IntToStr(num),2,6);
    million := million + ' million and ' + IntToSpell(StrToInt(hspell));
    spell := million;
  end;
  IntToSpell := spell;
end;


function trans99(num: integer): string;
const
  cSpell: array[1..9] of string = ('dez',
 'vinte','trinta','quarenta','cinquenta', 'sessenta',
 'setenta','oitenta','noventa');
begin
  Result := cSpell[num div 10];

 { case num of
    10 : spell := 'dez';
    20 : spell := 'vinte';
    30 : spell := 'trinta';
    40 : spell := 'quarenta';
    50 : spell := 'cinquenta';
    60 : spell := 'sessenta';
    70 : spell := 'setenta';
    80 : spell := 'oitenta';
    90 : spell := 'noventa';
  end;
  trans99 := spell;}
end;

function trans19(num: integer): string;
var
  spell: string;
begin
  case num of
    11 : spell := 'onze';
    12 : spell := 'doze';
    13 : spell := 'treze';
    14 : spell := 'catorze';
    15 : spell := 'quinze';
    16 : spell := 'dezesseis';
    17 : spell := 'dezessete';
    18 : spell := 'dezoito';
    19 : spell := 'dezenove';
  end;
  trans19 := spell;
end;

function trans9(num: integer): string;
var
  spell : string;
begin
  case num of
    1 : spell := 'um';
    2 : spell := 'dois';
    3 : spell := 'trs';
    4 : spell := 'quatro';
    5 : spell := 'cinco';
    6 : spell := 'seis';
    7 : spell := 'sete';
    8 : spell := 'oito';
    9 : spell := 'nove';
  end;
  trans9 := spell;
end;


Function GetShortFileName(Const FileName : String) : String;
var
  aTmp: array[0..255] of char;
begin
  if GetShortPathName(PChar(FileName), aTmp, Sizeof(aTmp)-1)=0 then
  Result := FileName
  else
  Result := StrPas(aTmp);
end;

Function GetLongFileName(Const FileName : String) : String;
var
  aInfo: TSHFileInfo;
begin
  if SHGetFileInfo(PChar(FileName), 0, aInfo, Sizeof(aInfo), SHGFI_DISPLAYNAME)<>0 then
  Result:= String(aInfo.szDisplayName )
  else
  Result:= FileName;
end;

function ExecExplorer(OpenAtPath: string; OpenWithExplorer, OpenAsRoot: Boolean): boolean;
//
// Executa o Windows Explorer a partir de uma pasta
// especificada
//
// Requer a unit ShellApi
//
//  ex: execExplorer('C:\Temp', True,True);
//
var
  s: string;
begin
  if OpenWithExplorer then
  begin
  if OpenAsRoot then
     s := ' /e,/root,"' + OpenAtPath + '"'
  else
     s := ' /e,"' + OpenAtPath + '"';
  end
  else
    s := '"' + OpenAtPath + '"';
    result := ShellExecute(Application.Handle,PChar('open'),PChar('explorer.exe'),PChar(s),nil,SW_NORMAL) > 32;
end;

procedure OpenInternetExplorer( sURL : string );
//
// Executa o Internet Explorer a partir de uma Url especificada
//
// ex: OpenInternetExplorer(' http://www.geocities.com/Broadway/3367');
//
// Requer a unit ComObj na clausula Uses
//
const
  csOLEObjName = 'InternetExplorer.Application';
var
 IE : Variant;WinHanlde : HWnd;
begin
  if( VarIsEmpty( IE ) )then
    begin
      IE := CreateOleObject( csOLEObjName );
      IE.Visible := true;
      IE.Navigate( sURL );
    end
  else
  begin
    WinHanlde := FindWIndow( 'IEFrame', nil );
  if( 0 <> WinHanlde )then
    begin
      IE.Navigate( sURL );
      SetForegroundWindow( WinHanlde );
    end
    else Showmessage('Ocorreu um erro no informado!');
 end;
end;

function FileExec(const aCmdLine: String; aHide, aWait,bWait: Boolean):Boolean;
//
// Executa um arquivo
// aHide = Se vai ser exibido ou oculto
// aWait = Se o aplicativo ser executado em segundo plano
// bWait = Se o Sistema deve esperar este aplicativo ser finalizado para
//         prosseguir ou no
//
var
  StartupInfo : TStartupInfo;
  ProcessInfo : TProcessInformation;
begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb:= SizeOf(TStartupInfo);
      dwFlags:= STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
    if aHide then
    wShowWindow:= SW_HIDE
    else
    wShowWindow:= SW_SHOWNORMAL;
    end;
  Result := CreateProcess(nil,PChar(aCmdLine), nil, nil,
  False,NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo);
  if aWait and Result then
  begin
    WaitForInputIdle(ProcessInfo.hProcess, INFINITE);
  if bWait then
    WaitForSingleObject(ProcessInfo.hProcess,INFINITE);
   end;
end;


procedure FmtStr(var Result: string; const Format: string;
 const Args: array of const);
var
  Len, BufLen: Integer;
  Buffer: array[0..4097] of Char;
begin
  BufLen := SizeOf(Buffer);
  if Length(Format) < (BufLen - (BufLen div 4)) then
    Len := FormatBuf(Buffer, BufLen - 1, Pointer(Format)^, Length(Format), Args)
  else
  begin
    BufLen := Length(Format);
    Len := BufLen;
  end;

  if Len >= BufLen - 1 then
  begin
    while Len >= BufLen - 1 do
    begin Inc(BufLen, BufLen);
      Result := '';
      SetLength(Result, BufLen);
      Len := FormatBuf(Pointer(Result)^, BufLen - 1, Pointer(Format)^,
       Length(Format), Args);
    end;
    SetLength(Result, Len);
  end
  else SetString(Result, Buffer, Len);
end;

function FormatNumber(l: longint): string;
//
// Formata um valor numrico inserindo mascaras
// do ponto nele.
//
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


function IdadeAtual(Nasc : TDate): Integer;
//
// Retorna a idade Atual de uma pessoa a partir da data de nascimento
//
// Esta funo retorna a idade em formato integer
//
Var AuxIdade, Meses : String; 
  MesesFloat : Real;
  IdadeInc, IdadeReal : Integer;
begin
  AuxIdade := Format('%0.2f', [(Date - Nasc) / 365.6]);
  Meses := FloatToStr(Frac(StrToFloat(AuxIdade)));
  if AuxIdade = '0' then
  begin
    Result := 0;
    Exit;
  end;
  if Meses[1] = '-' then Meses := FloatToStr(StrToFloat(Meses) * -1);
   Delete(Meses, 1, 2);
  if Length(Meses) = 1 then Meses := Meses + '0';

  if (Meses <> '0') And (Meses <> '') then
    MesesFloat := Round(((365.6 * StrToInt(Meses)) / 100) / 30.47)
  else
    MesesFloat := 0;

  if MesesFloat <> 12 then
    IdadeReal := Trunc(StrToFloat(AuxIdade)) // + MesesFloat;
  else
  begin
    IdadeInc := Trunc(StrToFloat(AuxIdade));
    Inc(IdadeInc);
    IdadeReal := IdadeInc;
  end;
  Result := IdadeReal;
end;

Function ImpresConect(Porta:Word):Boolean;
Const
 Portas :Byte = $02;
Var
  Res :Byte;
Begin Asm
  mov ah,Portas;
  mov dx,Porta;
  Int $17;
  mov Res,ah;
end;
  Result := (Res and $80) = $80; 
end;

function PrinterOnLine: Boolean;
const
  PrnStInt: Byte = $17;
  StRq: Byte = $02;
  PrnNum: Word = 0;
var
  nResult: Byte;
begin
ASM
  mov ah, StRq;
  mov dx, PrnNum;
  Int $17;
  mov nResult, ah;
end;
end;

function MMtoPixelX (MM : Integer) : Longint;
var
  mmPointX : Real;
  PageSize, OffSetUL : TPoint;
begin
  mmPointX := Printer.PageWidth / GetDeviceCaps(Printer.Handle,HORZSIZE);
  Escape (Printer.Handle ,GETPRINTINGOFFSET, 0, nil, @OffSetUL);
  Escape (Printer.Handle,GETPHYSPAGESIZE, 0, nil, @PageSize);
  if MM > 0 then
  Result := round ((MM * mmPointX) - OffSetUL.X) else Result := round (MM * mmPointX);
end;

function MMtoPixelY (MM : Integer) : Longint;
var
  mmPointY : Real;
  PageSize, OffSetUL : TPoint;
begin
  mmPointY := Printer.PageHeight /
  GetDeviceCaps(Printer.Handle,VERTSIZE);
  Escape (Printer.Handle ,GETPRINTINGOFFSET, 0, nil, @OffSetUL);
  Escape (Printer.Handle,GETPHYSPAGESIZE, 0, nil, @PageSize);
  if MM > 0 then
  Result := round ((MM * mmPointY) - OffSetUL.Y) else Result := round (MM * mmPointY);
end;


function MonthString(const Month: Word): string;
const MonthStr: array[1..12] of string = ('Janeiro','Fevereiro','Maro',
'Abril','Maio','Junho','Julho','Agosto', 'Setembro','Outubro','Novembro','Dezembro');
begin
  MonthString := MonthStr[Month]
end;

function Gerapercentual(valor:real;Percent:Real):real;
begin
  percent := percent / 100;
try
  valor := valor * Percent;
finally
  result := valor;
end;
end;

function Maiuscula(Texto:String): String;
{Converte a primeira letra do texto especificado para
 maiuscula e as restantes para minuscula}
begin
  if Texto <> '' then
  begin
    //Texto := UpperCase(Copy(Texto,1,1))+LowerCase(Copy(Texto,2,Length(Texto)));
    Result := Texto;
    Result[1] := UpCase(Result[1]);
  end;
end;

Function PrimeiroDiaUtil(Data : TDateTime) : TDateTime;
//
// Retorna data do primeiro dia Util do mes, de uma data informada
//
var Ano, Mes, Dia : word;
  DiaDaSemana : Integer;
begin
  DecodeDate (Data, Ano, Mes, Dia);
  Dia := 1;
  DiaDaSemana := DayOfWeek(Data);
  if DiaDaSemana = 1 then Dia := 2
  else
  if DiaDaSemana = 7 then Dia := 3;
  Result := EncodeDate (Ano, Mes, Dia);
end;


// Faz a procura e substitui uma String no campo memo.
// Exemplo :: FindReplace(Edit1.Text,Edit2.Text, Memo1);
Procedure FindReplace (const Enc, subs: String; Var Texto: TMemo);
Var
  i, Posicao: Integer; Linha: string;
Begin
  For i := 0 to Texto.Lines.count - 1 do
  begin
    Linha := Texto. Lines[i];
  Repeat
    Posicao:=PosBMH(Enc,Linha);
  If Posicao > 0 then
  begin
    Delete(Linha,Posicao,Length(Enc));
    Insert(Subs,Linha,Posicao);
    Texto.Lines[i] := Linha;
  end;
  until Posicao = 0;
 end;
end;

function DifDateUtil(dataini,datafin:string):integer;
{Retorna a quantidade de dias uteis entre duas datas}
var a,b,c:tdatetime;
  ct,s:integer;
begin
  if StrToDate(DataFin) < StrtoDate(DataIni) then
  begin
    Result := 0;
    exit;
  end;
  ct := 0;
  s := 1;
  a := strtodate(dataFin);
  b := strtodate(dataIni);
  if a > b then
  begin
    c := a;
    a := b;
    b := c;
    s := 1;
  end;
  a := a + 1;
  while (dayofweek(a)<>2) and (a <= b) do
  begin
    if dayofweek(a) in [2..6] then
    begin
      inc(ct);
    end;
  a := a + 1;
  end;
    ct := ct + round((5*int((b-a)/7)));
    a := a + (7*int((b-a)/7));
  while a <= b do
  begin
    if dayofweek(a) in [2..6] then
    begin
      inc(ct);
    end;
  a := a + 1;
  end;
    if ct < 0 then
    begin
      ct := 0;
    end;
  result := s*ct;
end;

// Remove os zeros na frente de um valor.
function RemoveZeros(S: string): string;
 var  I, J : Integer;
begin
  I := Length(S);
  while (I > 0) and (S[I] <= ' ') do Dec(I);
  J := 1;
  while (J < I) and ((S[J] <= ' ') or (S[J] = '0')) do Inc(J);
  Result := Copy(S, J, (I-J) + 1);
end;

function ObterTermo(APosicao: Integer; ASeparador,ALinha: String): String;
 //ex: ObterTermo(2, ':', 'Abc:Def:Ghi'); retornar 'Def'
var
  sAux: TStringList;
begin
  Result:='';
  sAux:=TStringList.Create;
  sAux.Text:=StringReplace(ALinha,ASeparador,#13#10,[rfReplaceAll, rfIgnoreCase]);
  if APosicao <= sAux.Count then
    Result:=sAux.Strings[APosicao-1];
  sAux.Free;
end;

function GetTmpDir: string; // Obter o diretrio temporrio do Windows
 var pc: PChar;
begin
  pc := StrAlloc(MAX_PATH + 1);
  GetTempPath(MAX_PATH, pc);
  Result := IncludeTrailingPathDelimiter(string(pc));
  StrDispose(pc);
{
outra maneira de fazer a mesma coisa:
var
 i: integer;
begin
 SetLength(Result, MAX_PATH);
 i := GetTempPath(Length(Result), PChar(Result));
 SetLength(Result, i);
 Result := IncludeTrailingBackslash(Result);
end;
}
{
mais uma outra maneira de fazer a mesma coisa:
var
  iAssumedSize, iSize: DWORD;
begin
  // try with a reasonable buffer size
  iAssumedSize := 80;
  SetLength(Result, iAssumedSize);
  iSize := GetTempPath(iAssumedSize, PChar(Result));
  // reserve more buffer if necessary
  if (iSize > iAssumedSize) then
  begin
    // in this case the terminating #0 is included in iSize.
    SetLength(Result, iSize);
    iSize := GetTempPath(iSize, PChar(Result));
  end;
  // reduce buffer to the effectively used size. if the api call
  // was successful, the terminating #0 is not included in iSize.
  SetLength(Result, iSize);
}
end;

//Converte um certo nmero de segundos em horas j formatado
function FormatSecsToHMS(Secs: LongInt): string;
var
  Hrs, Min: Word;
begin
  Hrs := Secs div 3600;
  Secs := Secs mod 3600;
  Min := Secs div 60;
  Secs := Secs mod 60;
  Result := Format('%d:%d:%d', [Hrs, Min, Secs]);
end;

//Obter a clula de um StringGrid que est sob o cursor do mouse
{
exemplo de como usar:
procedure TForm1.Button1Click(Sender: TObject);
var
Coluna, Linha: integer;
begin
MouseCell(StringGrid1, Coluna, Linha); 
if (Coluna >= 0) and (Linha >= 0) then
Caption := 'Coluna: ' + IntToStr(Coluna) + ' - ' +
'Linha: ' + IntToStr(Linha);
else
Caption := 'O mouse no est no StringGrid'; 
end;
}
procedure MouseCell(Grid: TStringGrid; var Coluna, Linha: integer);
var
  Pt: TPoint;
begin
  GetCursorPos(Pt);
  Pt := Grid.ScreenToClient(Pt);
  if PtInRect(Grid.ClientRect, Pt) then
   Grid.MouseToCell(Pt.X, Pt.Y, Coluna, Linha)
  else
  begin
    Coluna := -1;
    Linha := -1;
  end;
end;

function func_VerifEmail(email: string): boolean;
const
  msg1 = 'Caractere(s) invlido(s) no incio do e-mail.';
  msg2 = 'Smbolo @ no foi encontrado.';
  msg3 = 'Excesso do smbolo @.';
  msg4 = 'Caractere(s) invlido(s) antes do smbolo @.';
  msg5 = 'Caractere(s) invlido(s) depois do smbolo @.';
  msg6 = 'Agrupamento de caractere(s) invlido(s) a esqueda do @.';
  msg7 = 'No existe ponto(s) digitado(s).';
  msg8 = 'Ponto encontrado no final do e-mail.';
  msg9 = 'Ausncia de caractere(s) aps o ltimo ponto.';
  msg10 = 'Excesso de ponto(s) a direita do @.';
  msg11 = 'Ponto(s) disposto(s) de forma errada aps o @.';
  msg12 = 'Caractere(s) invlido(s) antes do ponto.';
  msg13 = 'Caractere(s) invlido(s) depois do ponto.';
var
  i, j, tam_email, simb_arroba, simb_arroba2, qtd_arroba, qtd_pontos,
  qtd_pontos_esq, qtd_pontos_dir, posicao, posicao2, ponto, ponto2: integer;
  vet_email: array [0..49] of string; //50 posies, capacidade do Edit
  msg: string;
begin
  qtd_pontos:= 0; qtd_pontos_esq:= 0; qtd_pontos_dir:= 0; qtd_arroba:= 0;
  posicao:=0; posicao2:=0; simb_arroba:=0; simb_arroba2:=0; ponto:= 0;
  ponto2:= 0; msg:='';
  Result:= True;
 //Verificando parte inicial do E-mail
  tam_email:= Length(email);
  for i:= 0 to tam_email-1 do
  begin
    vet_email[i]:= Copy(email,i+1,1);
    if vet_email[i] = '@' then
    begin
      Inc(qtd_arroba);
      posicao:= i;
    end;
  end;
  if ((vet_email[0] = '@') or (vet_email[0] = '.') or (vet_email[0] = '-')) then
  begin
    Result:= False;
    msg:= msg1;
  end;
  //Verificando se tem o smbolo @ e quantos tem
  if qtd_arroba < 1 then
  begin
    Result:= False;
    msg:= msg2;
  end
  else if qtd_arroba > 1 then
  begin
    Result:= False;
    msg:= msg3 + ' Encontrado(s): '+IntToStr(qtd_arroba)+'.';
  end
  else
  //Verificando o que vem antes e depois do smbolo @
  begin
  for i:=0 to 35 do
  begin
    if vet_email[posicao-1] <> vet_valido[i] then Inc(simb_arroba)
    else Dec(simb_arroba);
    if vet_email[posicao+1] <> vet_valido[i] then Inc(simb_arroba2)
    else Dec(simb_arroba2);
  end;
  if simb_arroba = 36 then
  begin
   //Antes do arroba h um smbolo desconhecido do vetor vlido
   Result:= False;
   msg:= msg4;
  end
  else if simb_arroba2 = 36 then
  begin
   //Depois do arroba h um smbolo desconhecido do vetor vlido
    Result:= False;
    msg:= msg5;
  end
  end;
  //Verificando se h pontos e quantos, e Verificando parte final do e-mail
  for j:=0 to tam_email-1 do
  if vet_email[j] = '-' then
  if ((vet_email[j-1] = '.') or (vet_email[j-1] = '-')) then
  begin
    Result:= False;
    msg:= msg6;
  end;
  for i:=0 to tam_email-1 do
  if vet_email[i] = '.' then
  begin
    Inc(qtd_pontos);
    posicao2:= i+1;
    if i > posicao then Inc(qtd_pontos_dir)
    else Inc(qtd_pontos_esq);
    if ((vet_email[i-1] = '.') or (vet_email[i-1] = '-')) then
    begin
      Result:= False;
      msg:= msg6;
    end;
  end;
  if qtd_pontos < 1 then
  begin
    Result:= False;
    msg:= msg7;
  end
  else if vet_email[tam_email-1] = '.' then
  begin
    Result:= False;
    msg:= msg8;
  end
  else if vet_email[tam_email-2] = '.' then
  begin
    Result:= False;
    msg:= msg9;
  end
  else if qtd_pontos_dir > 2 then
  begin
    Result:= False;
    msg:= msg10 + ' Encontrado(s): '+
    IntToStr(qtd_pontos)+#10+'Encontrado(s) a direita do @: '+
    IntToStr(qtd_pontos_dir)+'.';
  end
  else if (not ((((tam_email - posicao2) = 3) and (qtd_pontos_dir = 1)) or
  (((tam_email - posicao2) = 2) and (qtd_pontos_dir = 2)) or
  (((tam_email - posicao2) = 2) and (qtd_pontos_dir = 1)))) then
  begin
    Result:= False;
    msg:= msg11 +#10+ 'Encontrado(s) a esquerda do @: '+
    IntToStr(qtd_pontos_esq) +#10+ 'Encontrado(s) a direita do @: '+
    IntToStr(qtd_pontos_dir)+'.';
  end
  else
  //Verificando o que vem antes e depois do ponto
  begin
  for i:=0 to 35 do
  begin
    if vet_email[posicao2-2] <> vet_valido[i] then Inc(ponto)
    else Dec(ponto);
    if vet_email[posicao2] <> vet_valido[i] then Inc(ponto2)
    else Dec(ponto2);
  end;
  if ponto = 36 then
  begin
   //Antes do ponto h um smbolo desconhecido do vetor vlido
    Result:= False;
    msg:= msg12;
  end
  else if ponto2 = 36 then
  begin
    //Depois do ponto h um smbolo desconhecido do vetor vlido
    Result:= False;
    msg:= msg13;
  end
  end;
  //Verificao final
  if not Result then
  begin
    msg:= msg +#10+ 'Formato de E-mail no aceitvel!!';
    FastFileMessageBox(Pchar(msg), 'Erro: Formato Invlido de E-mail', MB_OK + MB_ICONWARNING);
    //MessageDlg(msg,mtWarning,[mbRetry],0);
  end;
end;

function ValidaTituloEleitor(NumTitulo: string): Boolean;
var
  i, Soma : integer;
  sTitulo: string;
  Resto, Dig1, Dig2 : double;
begin
  sTitulo := '';
  for i := 1 to Length(NumTitulo) do
  if (Copy(NumTitulo,i,1) >= '0') and (Copy(NumTitulo,i,1) <= '9') then
  sTitulo := sTitulo + Copy(NumTitulo,i,1);
  sTitulo := FormatFloat('0000000000000', StrToFloat(sTitulo));
  Soma := StrToInt(sTitulo[1]) * 2 +
  StrToInt(sTitulo[2]) * 9 +
  StrToInt(sTitulo[3]) * 8 +
  StrToInt(sTitulo[4]) * 7 +
  StrToInt(sTitulo[5]) * 6 +
  StrToInt(sTitulo[6]) * 5 +
  StrToInt(sTitulo[7]) * 4 +
  StrToInt(sTitulo[8]) * 3 +
  StrToInt(sTitulo[9]) * 2 ;
  Resto := Soma mod 11;
  if (Resto = 0) or (Resto = 1) then
  begin
    if (Copy(sTitulo,10,2) = '01') or (Copy(sTitulo,10,2) = '02') then
    begin
      if Resto = 0 then
        Dig1 := 1
      else
        Dig1 := 0;
    end
    else
    Dig1 := 0
  end
  else
    Dig1 := 11 - Resto;
    Soma := StrToInt(FloatToStr((StrToInt(sTitulo[10]) * 4) +
    (StrToInt(sTitulo[11]) * 3) + (Dig1 * 2)));
    Resto := Soma mod 11;
    if (Resto = 0) or (Resto = 1) then
    begin
      if (Copy(sTitulo,10,2) = '01') or (Copy(sTitulo,10,2) = '02') then
      begin
        if Resto = 0 then
           Dig2 := 1
        else
          Dig2 := 0;
        end
      else
        Dig2 := 0;
      end
  else
  Dig2 := 11 - Resto;
  if (StrToInt(sTitulo[12]) > Dig1) or (StrToInt(sTitulo[13]) > Dig2) then
    Result := False
  else
    Result := True;
end;

//ENCRIPTAR IMAGENS ...
procedure cripto(const BMP: TBitmap; Key: Integer);
  var BytesPorScan: Integer;
  w, h: integer; p: pByteArray;
begin
  try
    BytesPorScan := Abs(Integer(BMP.ScanLine[1]) - Integer(BMP.ScanLine[0]));
  except
    raise Exception.Create('Erro !');
  end;
    RandSeed := Key;
  for h := 0 to BMP.Height - 1 do
  begin
    P := BMP.ScanLine[h];
    for w := 0 to BytesPorScan - 1 do
      P^[w] := P^[w] xor Random(256);
  end;
end;
{exemplo:
procedure TForm1.Button1Click(Sender: TObject);
begin
cripto(Image1.Picture.Bitmap, 1);
Image1.Refresh;
end;
}

// desligar o Windows NT
//EXEMPLO: WinExit(EWX_SHUTDOWN or EWX_FORCE);
function WinExit(flags: integer): boolean;
function SetPrivilege(privilegeName: string; enable: boolean): boolean;
var
  tpPrev, tp : TTokenPrivileges;
  token : THandle;
  dwRetLen : DWord;
begin
  result := False;
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, token);
  tp.PrivilegeCount := 1;
  if LookupPrivilegeValue(nil, pchar(privilegeName), tp.Privileges[0].LUID) then
  begin
    if enable then
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
    else
      tp.Privileges[0].Attributes := 0;
      dwRetLen := 0;
      result := AdjustTokenPrivileges(token, False, tp, SizeOf(tpPrev), tpPrev, dwRetLen);
  end;
    CloseHandle(token);
  end;
  begin
  if SetPrivilege('SeShutdownPrivilege', true) then
  begin
    ExitWindowsEx(flags, 0);
    SetPrivilege('SeShutdownPrivilege', False)
  end;
end;

//Transforma a imagem em negativo de fotografia
procedure ColorToNegative(ABmp: TBitmap);
//exemplo:
// var x: TBitmap;
// begin
// x := TBitmap.create;
// x.LoadFromFile('c:\MVC-267S.bmp');
// ColorToNegative(x);
// image1.Picture.Assign(x);
// end;
const
 _high = 255;
var
  c: TCursor;
  x, y: Integer;
  ColorRGB: LongInt;
begin
  c := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  for y := 0 to (ABmp.Height - 1) do
  for x := 0 to (ABmp.Width - 1) do
  begin
    ColorRGB := ColorToRGB(ABmp.Canvas.Pixels[x, y]);
    ABmp.Canvas.Pixels[x, y] := PaletteRGB(_high - GetRValue(ColorRGB),_high - GetGValue(ColorRGB), _high - GetBValue(ColorRGB));
  end;
  Screen.Cursor := c;
end;

{ PROCEDURE PARA CRIAR CDIGO DE BARRAS.
 exemplo:
procedure TForm1.Button1Click(Sender: TObject);
begin
CriaCodigo('03213213241',Image1.Canvas);
end;
}

Procedure CriaCodigo(Cod : String; Imagem : TCanvas);
Const
  digitos : array['0'..'9'] of string[5]= ('00110',
  '10001',
  '01001',
  '11000',
  '00101',
  '10100',
  '01100',
  '00011',
  '10010',
  '01010');
Var
  Numero : String;
  Cod1 : Array[1..1000] Of Char;
  Cod2 : Array[1..1000] Of Char;
  Codigo : Array[1..1000] Of Char;
  Digito : String;
  c1,c2 : Integer;
  x,y,z,h : LongInt;
  a,b,c,d : TPoint;
  I : Boolean;
Begin
  Numero := Cod;
  For x := 1 to 1000 Do
  Begin
    Cod1 [x] := #0;
    Cod2 [x] := #0;
    Codigo[x] := #0;
  End;
  c1 := 1;
  c2 := 1;
  x := 1;
  For y := 1 to Length(Numero) div 2 do
  Begin
    Digito := Digitos[Numero[x ]];
  For z := 1 to 5 do
  Begin
    Cod1[c1] := Digito[z];
    Inc(c1);
  End;
    Digito := Digitos[Numero[x+1]];
  For z := 1 to 5 do
  Begin
    Cod2[c2] := Digito[z];
    Inc(c2);
  End;
    Inc(x,2);
  End;
  y := 5;
  Codigo[1] := '0';
  Codigo[2] := '0';
  Codigo[3] := '0';
  Codigo[4] := '0'; { Inicio do Codigo }
  For x := 1 to c1-1 do
  begin
    Codigo[y] := Cod1[x]; Inc(y);
    Codigo[y] := Cod2[x]; Inc(y);
  end;
  Codigo[y] := '1'; Inc(y); { Final do Codigo }
  Codigo[y] := '0'; Inc(y);
  Codigo[y] := '0';
  Imagem.Pen .Width := 1;
  Imagem.Brush.Color := ClWhite;
  Imagem.Pen .Color := ClWhite;
  a.x := 1; a.y := 0;
  b.x := 1; b.y := 79;
  c.x := 2000; c.y := 79;
  d.x := 2000; d.y := 0;
  Imagem.Polygon([a,b,c,d]);
  Imagem.Brush.Color := ClBlack;
  Imagem.Pen .Color := ClBlack;
  x := 0;
  i := True;
  for y:=1 to 1000 do
  begin
  If Codigo[y] <> #0 Then
    Begin
      If Codigo[y] = '0' then
        h := 1
      Else
        h := 3;
      a.x := x; a.y := 0;
      b.x := x; b.y := 79;
      c.x := x+h-1; c.y := 79;
      d.x := x+h-1; d.y := 0;
      If i Then
        Imagem.Polygon([a,b,c,d]);
      i := Not(i);
      x := x + h;
    End;
  end;
end;



function ValidaContaCorrente(Agencia, CtaCorrente : integer) : boolean;
var
  sConta : string[10];
  i, iSoma, iResto : integer;
  vConta : array [1..10] of integer;
const
  vMultiplic : array [1..9] of integer = (2,9,8,7,6,5,4,3,2);
begin
  iSoma := 0;
  sConta := Format('%03.3d', [Agencia]) + Format ('%07.7d', [CtaCorrente]);
  for i := 1 to 10 do
    vConta[i] := StrToInt(sConta[i]);
  for i := 1 to 9 do
    iSoma := iSoma + vConta[i] * vMultiplic[i];
  iResto := iSoma mod 11;
  if iResto in [0,1] then
    iResto := 0
  else
    iResto := 11 - iResto;
  Result := iResto = vConta[10];
end;

function ConverteMaisculo(str: string): string;
begin
  str :=  UpperCase(str);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  str :=  StringReplace(str,'' ,'',[rfReplaceAll]);
  Result := str;
end;

function StringToFloat(s: string): Extended;
var
  i :Integer;
  t : string;
  SeenDecimal,SeenSgn : Boolean;
begin
  t := '';
  SeenDecimal := False;
  SeenSgn := False;
  {Percorre os caracteres da string:}
  for i := Length(s) downto 0 do
  {Filtra a string, aceitando somente nmeros e separador decimal:}
  if (s[i] in ['0'..'9', '-','+',FormatSettings.DecimalSeparator]) then
  begin
    if (s[i] = FormatSettings.DecimalSeparator) and (not SeenDecimal) then
    begin
      t := s[i] + t;
      SeenDecimal := True;
    end
    else if (s[i] in ['+','-']) and (not SeenSgn) and (i = 1) then
    begin
      t := s[i] + t;
      SeenSgn := True;
    end
    else if s[i] in ['0'..'9'] then
    begin
      t := s[i] + t;
    end;
  end;
  Result := StrToFloatDef(t,0);
end;

function Before(const Search, Find: string): string;
{Retorna uma cadeia de caracteres antecedentes a uma parte da string selecionada}
const
  BlackSpace = [#33..#126];
var
  index: byte;
begin
  index:=PosBMH(Find, Search);
  if index = 0 then
  Result:=Search
  else
  Result:=Copy(Search, 1, index - 1);
end;

function after(const Search, Find: string): string;
{Retorna uma cadeia de caracteres aps a parte da string selecionada}
var
  index: byte;
begin
  index := PosBMH(Find, Search);
  if index = 0 then
  begin
    Result := '';
  end
  else
  begin
    Result := Copy(Search, index + Length(Find), 255);
  end;
end;

function BuscaTroca(Text,Busca,Troca : string) : string;
{ Substitui um caractere dentro da string}
var n : integer;
begin
  for n := 1 to length(Text) do
  begin
  if Copy(Text,n,1) = Busca then
    begin
      Delete(Text,n,1);
      Insert(Troca,Text,n);
    end;
  end;
  Result := Text;
end;



function FormatPercent(const Value: double): string;
begin
  Result := Format('%3.2f %%', [Value * 100]);
end;

function extenso (valor: real): string;
var
  Centavos, Centena, Milhar, Texto, msg: string;
const
  Unidades: array[1..9] of string = ('Um', 'Dois', 'Tres', 'Quatro', 'Cinco', 'Seis', 'Sete', 'Oito', 'Nove');
  Dez: array[1..9] of string = ('Onze', 'Doze', 'Treze', 'Quatorze', 'Quinze', 'Dezesseis', 'Dezessete', 'Dezoito', 'Dezenove');
  Dezenas: array[1..9] of string = ('Dez', 'Vinte', 'Trinta', 'Quarenta', 'Cinquenta', 'Sessenta', 'Setenta', 'Oitenta', 'Noventa');
  Centenas: array[1..9] of string = ('Cento', 'Duzentos', 'Trezentos', 'Quatrocentos', 'Quinhentos', 'Seiscentos', 'Setecentos', 'Oitocentos', 'Novecentos');
function ifs(Expressao: Boolean; CasoVerdadeiro, CasoFalso: String): String;
begin
  if Expressao
  then Result:=CasoVerdadeiro
  else Result:=CasoFalso;
end;
function MiniExtenso (trio: string): string;
var
  Unidade, Dezena, Centena: string;
begin
  Unidade:='';
  Dezena:='';
  Centena:='';
  if (trio[2]='1') and (trio[3]<>'0') then
  begin
    Unidade:=Dez[strtoint(trio[3])];
    Dezena:='';
  end
  else
  begin
    if trio[2]<>'0' then Dezena:=Dezenas[strtoint(trio[2])];
    if trio[3]<>'0' then Unidade:=Unidades[strtoint(trio[3])];
  end;

  if (trio[1]='1') and (Unidade='') and (Dezena='')
  then Centena:='cem'
  else
  if trio[1]<>'0'
  then Centena:=Centenas[strtoint(trio[1])]
  else Centena:='';
  Result:= Centena + ifs((Centena<>'') and ((Dezena<>'') or (Unidade<>'')), ' e ', '')
  + Dezena + ifs((Dezena<>'') and (Unidade<>''),' e ', '') + Unidade;
  end;
  begin
  if (valor>999999.99) or (valor<0) then
  begin
     msg:='O valor est fora do intervalo permitido.';
     msg:=msg+'O nmero deve ser maior ou igual a zero e menor que 999.999,99.';
     msg:=msg+' Se no for corrigido o nmero no ser escrito por extenso.';
     showmessage(msg);
     Result:='';
     exit;
  end;
  if valor=0 then
   begin
     Result:='';
     Exit;
   end;
  Texto:=formatfloat('000000.00',valor);
  Milhar:=MiniExtenso(Copy(Texto,1,3));
  Centena:=MiniExtenso(Copy(Texto,4,3));
  Centavos:=MiniExtenso('0'+Copy(Texto,8,2));
  Result:=Milhar;
  if Milhar<>'' then
    if copy(texto,4,3)='000' then
      Result:=Result+' Mil Reais'
    else
      Result:=Result+' Mil, ';
  {if (((copy(texto,4,2)='00') and (Milhar<>'')
   and (copy(texto,6,1)<>'0')) or (centavos=''))
   and (Centena<>'') then Result:=Result+' e ';
  }
  if (Milhar+Centena <>'') then Result:=Result+Centena;
    if (Milhar='') and (copy(texto,4,3)='001') then
      Result:=Result+' Real'
   else
     if (copy(texto,4,3)<>'000') then Result:=Result+' Reais';
       if Centavos='' then
       begin
         Result:=Result+'.';
         Exit;
       end
       else
       begin
       if Milhar+Centena='' then
         Result:=Centavos
       else
         Result:=Result+', e '+Centavos;
       if (copy(texto,8,2)='01') and (Centavos<>'') then
         Result:=Result+' Centavo.'
       else
         Result:=Result+' Centavos.';
      end;
end;

procedure GetDirList(Directory: String; var Result: TStrings;
IsRecursive: Boolean);
var
  Sr : TSearchRec;
procedure Recursive(Dir : String); { Sub Procedure, Recursiva }
var
  SrAux : TSearchRec;
begin
  if SrAux.Name = EmptyStr then
    FindFirst(Directory + '\' + Dir + '\*.*', faDirectory, SrAux);
  while FindNext(SrAux) = 0 do
  if SrAux.Name <> '..' then
  if DirectoryExists(Directory + '\' + Dir + '\' + SrAux.Name) then
  begin
    Result.Add(SrAux.Name);
    Recursive(Dir + '\' + SrAux.Name);
  end;
end;
begin
  FindFirst(Directory + '\*.*', faDirectory, Sr);
  while FindNext(Sr) = 0 do
    if Sr.Name <> '..' then
    if DirectoryExists(Directory + '\' + Sr.Name) then
    begin
      Result.Add(Sr.Name);
    if IsRecursive then
      Recursive(Sr.Name);
    end;
end;
{Exemplo Chamada: 
procedure TForm1.Button1Click(Sender: TObject);
var
Lista : TStrings;
begin
Lista := TStringList.Create;
GetDirList(Edit1.Text, Lista , CheckBox1.Checked);
ListBox1.Items.Clear;
ListBox1.Items := Lista; 
Lista.Free;
end;
 }

Procedure ApagaArq(vMasc:String);
Var Dir : TsearchRec;
  Erro: Integer;
Begin
  Erro := FindFirst(vMasc,faArchive,Dir);
  While Erro = 0 do Begin
    DeleteFile( ExtractFilePAth(vMasc)+Dir.Name );
    Erro := FindNext(Dir);
  End;
  FindClose(Dir);
End;

//Funo para saber quantas linhas tem um Arquivo. Pode ser de qualquer
//extenso.
//Exemplo:
//Gauge1.MaxValue:=GetNumbersFromFile('C:\socir32\Importad\CAD1A025.txt');
function GetNumbersFromFile(var FileToNumber: string): integer; 
var iLin: integer;
  NumberFile: TextFile;
  Handle: THandle;
begin
  AssignFile(NumberFile,FileToNumber);
  {i-}
  Reset(NumberFile);
  {i+}
  if (IOResult <> 0) then Abort; // Rewrite(NumberFile);
  iLin := 0;
  LockWindowUpdate(Handle);
  try
    while not Eof(NumberFile) do
    begin
      Readln(NumberFile);
      Inc(iLin);
    end;
  finally
    LockWindowUpdate(0);
  end;
  System.Close(NumberFile);
  Result := iLin;
end;

{procedure AjustaGrafico(Grafico : TQRDBChart);
var
  I: integer;
begin
  for I := 0 to Grafico.SeriesList.Count - 1 do
    if Grafico.Series[I] is TLineSeries then
    with TLineSeries(Grafico.Series[I]).Pointer do
    begin
      InflateMargins := True;
      Style := psCircle;
      Visible := (Grafico.Series[I].Count = 1);
    end;
    with Grafico do
    begin
      LeftAxis.AutomaticMinimum := false;
      LeftAxis.Minimum := 0.00 ;
    end;
end;}

function IsFileInUse(fName: string): boolean;
var
  HFileRes : HFILE;
begin
  Result := false;
  if not FileExists(fName) then exit;
  HFileRes := CreateFile(pchar(fName),
    GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0) ;
  Result := (HFileRes = INVALID_HANDLE_VALUE) ;
    //if not Result then
   // CloseHandle
end;


function Win32Type: string;
begin
  {VerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);  GetVersionEx(VerInfo);}
  {is this Windows 2000 or XP?}
  if Win32MajorVersion >= 5 then
  begin
    if Win32MinorVersion >= 1 then
    begin
      Result := 'WindowsXP';
    end
    else
    begin
      Result := 'Windows2000';
    end;
  end
  else
  begin
    {is this WIndows 95, 98, Me, or NT 40}
    if Win32MajorVersion > 3 then
    begin
      if Win32Platform = VER_PLATFORM_WIN32_NT then
      begin
        Result := 'WindowsNT40';
      end
      else
      begin
        {mask off junk}
        Win32BuildNumber := Win32BuildNumber and $FFFF;
        if Win32MinorVersion >= 90 then
        begin
          Result := 'WindowsMe';
        end
        else
        begin
          if Win32MinorVersion >= 10 then
          begin
            {Windows 98}
            if Win32BuildNumber >= 2222 then
            begin
              Result := 'Windows98SE'
            end
            else
            begin
              Result := 'Windows98';
            end;
          end
          else
          begin {Windows 95}
            if Win32BuildNumber >= 1000 then
            begin
              Result := 'Windows95OSR2'
            end
            else
            begin
              Result := 'Windows95';
            end;
          end;
        end;
      end;//if VER_PLATFORM_WIN32_NT
    end
    else
    begin
      Result := 'Win32s';
    end;
  end;//if Win32MajorVersion >= 5
end;

function SetLocalTime(Value: TDateTime): boolean;
{I admit that this routine is a little more complicated than the one
in Indy 8.0.  However, this routine does support Windows NT privillages
meaning it will work if you have administrative rights under that OS

Original author Kerry G. Neighbour with modifications and testing
from J. Peter Mugaas}
var
  dSysTime: TSystemTime;
  buffer: DWord;
  tkp, tpko: TTokenPrivileges;
  hToken: THandle;
begin
  Result := False;
  if SysUtils.Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if not Windows.OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
      hToken) then
    begin
      exit;
    end;
    Windows.LookupPrivilegeValue(nil, 'SE_SYSTEMTIME_NAME', tkp.Privileges[0].Luid);    {Do not Localize}
    tkp.PrivilegeCount := 1;
    tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    if not Windows.AdjustTokenPrivileges(hToken, FALSE, tkp, sizeof(tkp), tpko, buffer) then
    begin
      exit;
    end;
  end;
  DateTimeToSystemTime(Value, dSysTime);
  Result := Windows.SetLocalTime(dSysTime);
  {Undo the Process Privillage change we had done for the set time
  and close the handle that was allocated}
  if SysUtils.Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    Windows.AdjustTokenPrivileges(hToken, FALSE,tpko, sizeOf(tpko), tkp, Buffer);
    Windows.CloseHandle(hToken);
  end;
end;

     
function CarregaRelatorio(InstanceClass: TComponentClass;
  var Reference): TQuickRep;
  var Instance: TComponent;
begin
  Result := nil;
  if TComponent(Reference) = nil then
  begin
    Instance := TComponent(InstanceClass.NewInstance);
    TComponent(Reference) := Instance;
    try
      Instance.Create(nil);
      Result := TComponent(Reference) as TQuickRep;
      if Assigned(Result) then Result.Preview;
    except
      TComponent(Reference) := nil;
      raise;
    end;
  if Assigned(TComponent(Reference)) then
    FreeAndNil(TComponent(Reference));
  end;
end;

function NumberOfTheMonth(
  const Mes: string): integer;
const
  Meses: array[0..11, 0..1] of string =
    (('Janeiro',   '01'),
     ('Fevereiro', '02'),
     ('Maro',     '03'),
     ('Abril',     '04'),
     ('Maio',      '05'),
     ('Junho',     '06'),
     ('Julho',     '07'),
     ('Agosto',    '08'),
     ('Setembro',  '09'),
     ('Outubro',   '10'),
     ('Novembro',  '11'),
     ('Dezembro',  '12'));
var  i: integer;
begin
  Result := 0;
  for i := 0 to high(Meses) do
  if (AnsiUpperCase(trim(Mes)) =  AnsiUpperCase(Meses[i,0])) then
  begin
    Result := StrToInt(meses[i,1]);
    Break;
  end;
end;


//funo RetornaIntervaloString
//finalidade: retornar o texto entre os parmetros "De" e "Ate" .
// case insensitive, no importando maisculas ou minsculas.
//exemplo:
// var aux: string;
//begin
// aux := 'Hamden Vogel';
// aux := RetornaIntervaloString(aux,'M','g') ;
// ShowMessage(aux);  // => retorna  'den Vo'
function RetornaIntervaloString(const S, De,
  Ate: string): string;
var P: integer;
  aux: string;
begin
  Result := S;
  P := system.pos(AnsiUpperCase(Ate), AnsiUpperCase(Result));
  aux := Copy(Result, P- length(Result) , P-1 );
  if aux <> '' then
  Result :=  Trim(Copy(aux, system.pos(AnsiUpperCase(De) , AnsiUpperCase(aux))+1  ,length(aux)));
end;



//------------------------------------------------------------------------------
//funo retornaVARIABLEfromASP
//finalidade: Funo que extrai tudo o que est entre as tags ASP '<%' e '%>',
//exemplo:
//dada a seguinte linha em ASP:
//<%=TOTAL%>
//Utilizando a funo, ela extrai o que est entre as tags ASP:
//retornaVARIABLEfromASP('<%=TOTAL%>')   =>  TOTAL
                
function retornaVARIABLEfromASP(
  const Search: string): string;
var
  index: byte;
begin
  index := PosBMH('<%=', Search);
  if index = 0 then
  begin
    Result := '';
  end
  else
  begin
    Result := Copy(Search, index + Length('<%='), 255);
    index:=PosBMH('%>', Result);
    Result := copy(Result,1, index-1);
  end;
end;





function WithoutAllSpaces(const S: String): String;
var A,B: Integer;
begin
  if S='' then
  begin
    Result:='';
    exit;
  end;

  SetLength(Result,length(S));
  A:=1; B:=0;
  while A<=length(S) do
  begin
    if not (S[A] in [' ',#10,#13,#9]) then
    begin
      Inc(B);
      Result[B]:=S[A];
    end;
    Inc(A);
  end;
  SetLength(Result,B);
end;   

//retirar acentos de uma string.
function StrWithoutAccents(S: string): string;
var
  I, L: integer;
  Buffer: array[0..1023] of WideChar;
begin
  L := MultiByteToWideChar (CP_ACP, MB_COMPOSITE, PChar (S), Length (S), Buffer,
        SizeOf(Buffer) div SizeOf (WideChar) {2});
  Result := '';
  for I := 0 to L - 1 do if Buffer [I] <= #255 then
    Result := Result + Buffer [I];
end;

function ChecaCEP(cCep, cEstado: String): Boolean;
var
  cCEP1 : Integer;
begin
  cCep := copy(cCep,1,5) + copy(cCep,7,3);
  cCEP1 := StrToInt(copy(cCep,1,3));
  if Length(trim(cCep)) > 0 then
  begin
  if (StrToInt(cCep) <= 1000000.0) then
  begin
    MessageDlg('CEP tem que ser maior que [01000-000]',mtError,[mbOk],0);
    Result := False
   end
  else
  begin
  if Length(trim(copy(cCep,6,3))) < 3 then Result := False else
  if (cEstado = 'SP') and (cCEP1 >= 10 ) and (cCEP1 <= 199) then Result := True else
  if (cEstado = 'RJ') and (cCEP1 >= 200) and (cCEP1 <= 289) then Result := True else
  if (cEstado = 'ES') and (cCEP1 >= 290) and (cCEP1 <= 299) then Result := True else
  if (cEstado = 'MG') and (cCEP1 >= 300) and (cCEP1 <= 399) then Result := True else
  if (cEstado = 'BA') and (cCEP1 >= 400) and (cCEP1 <= 489) then Result := True else
  if (cEstado = 'SE') and (cCEP1 >= 490) and (cCEP1 <= 499) then Result := True else
  if (cEstado = 'PE') and (cCEP1 >= 500) and (cCEP1 <= 569) then Result := True else
  if (cEstado = 'AL') and (cCEP1 >= 570) and (cCEP1 <= 579) then Result := True else
  if (cEstado = 'PB') and (cCEP1 >= 580) and (cCEP1 <= 589) then Result := True else
  if (cEstado = 'RN') and (cCEP1 >= 590) and (cCEP1 <= 599) then Result := True else
  if (cEstado = 'CE') and (cCEP1 >= 600) and (cCEP1 <= 639) then Result := True else
  if (cEstado = 'PI') and (cCEP1 >= 640) and (cCEP1 <= 649) then Result := True else
  if (cEstado = 'MA') and (cCEP1 >= 650) and (cCEP1 <= 659) then Result := True else
  if (cEstado = 'PA') and (cCEP1 >= 660) and (cCEP1 <= 688) then Result := True else
  if (cEstado = 'AM') and ((cCEP1 >= 690) and (cCEP1 <= 692) or (cCEP1 >= 694) and
  (cCEP1 <= 698)) then Result := True else
  if (cEstado = 'AP') and (cCEP1 = 689) then Result := True else
  if (cEstado = 'RR') and (cCEP1 = 693) then Result := True else
  if (cEstado = 'AC') and (cCEP1 = 699) then Result := True else
  if ((cEstado = 'DF') or (cEstado = 'GO')) and (cCEP1 >= 000)and(cCEP1 <= 999)then
  Result := True else
  if (cEstado = 'TO') and (cCEP1 >= 770) and (cCEP1 <= 779) then Result := True else
  if (cEstado = 'MT') and (cCEP1 >= 780) and (cCEP1 <= 788) then Result := True else
  if (cEstado = 'MS') and (cCEP1 >= 790) and (cCEP1 <= 799) then Result := True else
  if (cEstado = 'RO') and (cCEP1 = 789) then Result := True else
  if (cEstado = 'PR') and (cCEP1 >= 800) and (cCEP1 <= 879) then Result := True else
  if (cEstado = 'SC') and (cCEP1 >= 880) and (cCEP1 <= 899) then Result := True else
  if (cEstado = 'RS') and (cCEP1 >= 900) and (cCEP1 <= 999) then Result := True else
  Result := False
  end;
  end
  else
  begin
    Result := True;
  end
end;    

function DeleteChar(const Ch: Char; const S: string): string;
var
  Posicao: integer;
begin
  Result := S;
  Posicao := PosBMH(Ch, Result);
  while Posicao > 0 do
  begin
    Delete(Result, Posicao, 1);
    Posicao := PosBMH(Ch, Result);
  end;
end;

//remove numeros iniciais (ex: '1. ','2. ') em uma string.
//Ex: '1. Hamden Vogel'  = usando a funo, retorna: 'Hamden Vogel'.
//Edit1.Text :=RemovePrefixosNumericosDeUmaString(Edit1.Text )
function RemovePrefixosNumericosDeUmaString(
 const S: string): string;
var
  P: integer;
begin
 // Elimina nmeros no incio, sucedidos por .     ex: 1.     2.    3.    ...
  Result := S;
  P := PosBMH('. ', Result);
  if (StrToIntDef(Copy(Result, 1, P - 1), -1) <> -1) then  // apenas no incio
 //   if (P > 1) and (P < 5)  then  // apenas no incio
    System.Delete(Result, 1, P+1);
end; 

//Ex:  ShowMessage(IntToStr(ContaPalavras(Memo1.Text))+' palavras');
function ContaPalavras(const Texto : String) : Integer;
const
  Delimitadores = [#0..#$1F, ' ', '.', ',', '?', ':', ';', '(',')', '/', '\'];
var
  i : Integer;
  DelAnt : Boolean;
begin
  Result := 0;
  if Length(Texto) = 0 then
    exit;
// procura primeira palavra
  i := 1;
  while Texto[i] in Delimitadores do
    Inc(i);
  DelAnt := False;
// pesquisa no texo
  while i <= Length(Texto) do begin
   if (Texto[i] in Delimitadores) then begin
// encontrou delimitador
     if (not DelAnt) then begin
//  o primeiro ? nova palavra
       Inc(Result);
       DelAnt := True;
     end;
   end
   else
// no  delimitador. Limpa flag
     DelAnt := False;
   Inc(i);
 end;
// terminou texto sem delimitador, adiciona palavra final
 if not DelAnt then 
   Inc(Result);
end;


function NetSend(dest, Source, Msg: string): Longint;
type
  TNetMessageBufferSendFunction = function(
  servername, msgname, fromname: PWideChar;
  buf: PWideChar; buflen: Cardinal): Longint;  stdcall;
var
  NetMessageBufferSend: TNetMessageBufferSendFunction;
  SourceWideChar: PWideChar;
  DestWideChar: PWideChar;
  MessagetextWideChar: PWideChar;
  Handle: THandle;
begin
  Handle := LoadLibrary('NETAPI32.DLL');
  if Handle = 0 then
  begin
    Result := GetLastError;
    exit;
  end;
  try
    MessagetextWideChar := nil;
    DestWideChar        := nil;

    @NetMessageBufferSend := GetProcAddress(Handle, 'NetMessageBufferSend');
    if @NetMessageBufferSend = nil then
    begin
      Result := GetLastError;
      exit;
    end;

  GetMem(MessagetextWideChar, Length(Msg) * SizeOf(WideChar) + 1);
  GetMem(DestWideChar, 20 * SizeOf(WideChar) + 1);
  StringToWideChar(Msg, MessagetextWideChar, Length(Msg)
   * SizeOf(WideChar) + 1);
  StringToWideChar(Dest, DestWideChar, 20 * SizeOf(WideChar) + 1);

  if Source = '' then
    Result := NetMessageBufferSend(nil, DestWideChar, nil,
   MessagetextWideChar, Length(Msg) * SizeOf(WideChar) + 1)
  else
  begin
    GetMem(SourceWideChar, 20 * SizeOf(WideChar) + 1);
  try
    StringToWideChar(Source, SourceWideChar, 20 * SizeOf(WideChar) + 1);
    Result := NetMessageBufferSend(nil, DestWideChar, SourceWideChar,
      MessagetextWideChar, Length(Msg) * SizeOf(WideChar) + 1);
  finally
    FreeMem(SourceWideChar);
  end;
  end;
  finally
    FreeMem(DestWideChar);
    FreeMem(MessagetextWideChar);
    FreeLibrary(Handle);
  end;
end;

function NetSend(Dest, Msg: string): Longint;
begin
  Result := NetSend(Dest, '', Msg);
end;

function NetSend(Msg: string): Longint;
begin
  Result := NetSend('', '', Msg);
end;

//exemplo de como usar:
//var linha, campo: string;
//begin
//linha := 'uma,dois,tres,quatro,cinco,seis,sete,oito,nove,dez';
//Campo := QuebraString(linha,',').Strings[6];
//ShowMessage(campo); 
//end;
function QuebraString(Texto, Separador: string): TStringList;
var
  S, P, Tot : string;
  i, a : integer;
  Lista : TStringList;
begin
  Lista := TStringList.Create;
  S := Separador;
  a := 1;
  for i := 0 to length(Texto) do
  begin
    if (i <= length(Texto)) then
    begin
      P := copy(Texto,a,1);
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


//Para usar esta funo ExecuteProgram,
//segue exemplos:
//ExecuteProgram('WINWORD.EXE,'');
//ou
//ExecuteProgram('C:\MSOFFICE\EXCEL\EXCEL.EXE','CONTAS.XLS');
Procedure ExecuteProgram(Nome,Parametros:String);
Var Comando : Array[0..1024] of Char;
  Parms : Array[0..1024] of Char;
Begin
  StrPCopy(Comando,Nome);
  StrPCopy(Parms,Parametros);
  ShellExecute(0,nil,Comando,Parms,nil,SW_SHOWMAXIMIZED);
End;


function ExecuteFile(const FileName, Params, DefaultDir: string;
  ShowCmd: Integer): THandle;
var
  zFileName, zParams, zDir: array[0..79] of Char;
begin
  Result := ShellExecute(Application.MainForm.Handle , nil,
  StrPCopy(zFileName, FileName), StrPCopy(zParams, Params),
  StrPCopy(zDir, DefaultDir), ShowCmd);

  If Result< 32 then
    Case Result of
      0                      : Raise Exception.Create('No h memria ou recursos disponveis.');
      ERROR_FILE_NOT_FOUND   : Raise Exception.Create('Arquivo no encontrado.');
      ERROR_PATH_NOT_FOUND   : Raise Exception.Create('Caminho no encontrado.');
      ERROR_BAD_FORMAT       : Raise Exception.Create('Formato invlido. O arquivo .EXE no  um aplicativo Win32 vlido.');
      SE_ERR_ACCESSDENIED    : Raise Exception.Create('Acesso ao arquivo negado.');
      SE_ERR_ASSOCINCOMPLETE : Raise Exception.Create('Associao de extenso est incompleta ou  invlida.');
      SE_ERR_DDEBUSY         : Raise Exception.Create('Transao DDE no foi completada pois h outra transao sendo processada.');
      SE_ERR_DDEFAIL         : Raise Exception.Create('A transao DDE falhou.');
      SE_ERR_DDETIMEOUT      : Raise Exception.Create('Transao DDE no foi completada pois a requisio expirou.');
      SE_ERR_DLLNOTFOUND     : Raise Exception.Create('A DLL especificada no foi encontrada.');
      SE_ERR_NOASSOC         : Raise Exception.Create('No existe aplicativo associado com esse tipo de arquivo.');
      SE_ERR_OOM             : Raise Exception.Create('No havia memria suficiente para completar a operao.');
      SE_ERR_SHARE           : Raise Exception.Create('Violao de compartilhamento.');
    Else
      Raise Exception.Create('Erro no classificado. Cdigo de erro ( ' + IntToStr(Result) + ' )');
    end;
end;


{ Exemplo de como utilizar:
var lista: TStringlist;
begin
lista:= TStringlist.create;
DirList('C:\*.*', lista);
Memo1.Lines.Assign(lista);
}
procedure DirList(ASource: string; ADirList: TStringList); 
var
  SearchRec : TSearchRec;
  Result : integer;
begin
  Result := FindFirst( ASource, faAnyFile, SearchRec );
  if Result = 0 then
    while (Result = 0) do
    begin
      if (SearchRec.Name+' ')[1] = '.' then
      // Se pegou nome de SubDiretorio
      begin
        Result := FindNext( SearchRec );
        Continue;
      end;
      ADirList.Add( SearchRec.Name );
      Result := FindNext( SearchRec );
    end;
  FindClose( SearchRec );
  ADirList.Sort ;
end;

//fazendo um executvel se auto-deletar.
//exemplo de como utilizar:
//procedure TForm1.Button1Click(Sender: TObject);
//begin
//DelExe;
//end;
procedure DelExe;
function GetTmpFileName(ext: string): string; 
var
  pc: PChar;
begin
  pc := StrAlloc(MAX_PATH + 1);
  GetTempFileName(PChar(GetTmpDir), 'EZC', 0, pc);
  Result := string(pc);
  Result := ChangeFileExt(Result, ext);
  StrDispose(pc);
end;
var
  batchfile: TStringList;
  batchname: string;
begin
  if (TDRiveType(GetDriveType(PChar('C:\'))) = dtFloppy) or (TDRiveType(GetDriveType(PChar('C:\'))) = dtFixed) then
  begin
    batchname := GetTmpFileName('.bat');
    FileSetAttr(ParamStr(0), 0);
    batchfile := TStringList.Create;
    with batchfile do
    begin
    try
      Add(':Label1');
      Add('del "' + ParamStr(0) + '"');
      Add('if Exist "' + ParamStr(0) + '" goto Label1');
      Add('rmdir "' + ExtractFilePath(ParamStr(0)) + '"');
      Add('del "' + GetTmpDir + ExtractFileName(ParamStr(0)) + '"');
      Add('del ' + batchname);
      SaveToFile(batchname);
      ChDir(GetTmpDir);
      WinExec(PChar(batchname), SW_HIDE);
    finally
      batchfile.Free;
    end;
     Halt;
    end;
  end; //else with Owner as TForm do Close;
end;

function vpis(Dado: String):boolean;
var
  i,wsoma,wm11,wdv,wdigito: integer;
begin
  if Trim(Dado) <> '' then
  begin
    wdv := StrToInt(copy(Dado,11,1));
    wsoma := 0;
    wm11 := 2;
  for i := 1 to 10 do
  begin
    wsoma := wsoma + (wm11 * StrToInt(Copy(Dado,11 -i, 1)));
  if wm11 < 9 then
    wm11 := wm11+1
  else
    wm11 := 2;
  end;
    wdigito := 11 - (wsoma mod 11);
    if wdigito > 9 then
    wdigito := 0;
    if wdv = wdigito then
    begin
      FastFileMessageBox('Valor vlido!','Aviso !', mb_IconStop+mb_ok);
      vpis := True;
    end
    else
    begin
      FastFileMessageBox('Valor informado no  vlido!', 'Ateno!', mb_IconStop+mb_ok);
      vpis := false;
    end;
  end;
end;

{
Para usar esta function  preciso declarar Urlmon na seo uses da unit. Depois basta fazer uma chamada padro:
if DownloadFile ('http://www.onde.com/arq.htm','c:\arq.htm' ) then
ShowMessage('Download Concludo.');
}
function DownloadFile(Source, Dest: string): Boolean;
begin
  try
    Result:= UrlDownloadToFile(nil, PChar(source),PChar(Dest), 0, nil) = 0;
  except
    Result:= False;
  end;
end;


{ criando driver ODBC dinamicamente...
procedure TForm1.Button1Click(Sender: TObject);
begin
CreateOdbcDriver('Hamden DSN', '1', 'Hamden', 'users.MDB', 'ODBCCP32', 'SQLConfigDataSource', 'Microsoft Access Driver (*.mdb)'); 
end;
end.
Conclues: Com esta dica voc poder criar drivers ODBC em tempo de execuo,
softwares de instalao, economizando tempo e deixando suas aplicaes mais dinmicas.
}


procedure CreateODBCDriver(Const
cDSNName,cExclusive,cDescription,cDataBase,cDefaultPath,cConfigSql,cDriver: string);
type
  TSQLConfigDataSource = function( hwndParent: HWND; fRequest: WORD; lpszDriver: LPCSTR;
  lpszAttributes: LPCSTR ): BOOL; stdcall;
const
  ODBC_ADD_DSN = 1; // Adiciona uma fonte de dados (data source)
  ODBC_CONFIG_DSN = 2; // Configura a fonte de dados (data source)
  ODBC_REMOVE_DSN = 3; // Remove a fonte de dados (data source)
  ODBC_ADD_SYS_DSN = 4; // Adiciona um DSN no sistema
  ODBC_CONFIG_SYS_DSN = 5; // Configura o DSN do sistema
  ODBC_REMOVE_SYS_DSN = 6; // Remove o DSN do sistema
var
  pFn: TSQLConfigDataSource;
  hLib: LongWord;
  strDriver: string;
  strHome: string;
  strAttr: string;
  strFile: string;
  fResult: BOOL;
  ModName: array[0..MAX_PATH] of Char;
  srInfo : TSearchRec;
begin
  Windows.GetModuleFileName( HInstance, ModName, SizeOf(ModName) );
  strHome := ModName;
  while ( strHome[length(strHome)] <> '\' ) do
  Delete( strHome, length(strHome), 1 );
  strFile := strHome + cDatabase; // Teste com access (Axes = Access)
  hLib := LoadLibrary( pChar(cDefaultPath) ); // carregando para o diretrio padro
  if( hLib <> NULL ) then
  begin
    @pFn := GetProcAddress( hLib, pChar(cConfigSql) );
  if( @pFn <> nil ) then
  begin
    strDriver := cDriver;
    strAttr := Format( 'DSN=%s'+#0+
    'DBQ=%s'+#0+
    'Exclusive=%s'+#0+
    'Description=%s'+#0+#0,
    [cDSNName,strFile,cExclusive,cDescription] );
    fResult := pFn( 0, ODBC_ADD_SYS_DSN, @strDriver[1], @strAttr[1] );
  if( fResult = false ) then
    ShowMessage( 'Falha ao tentar criar o DSN (Data source).' );
  if( FindFirst( strFile, 0, srInfo ) <> 0 ) then
  begin
    strDriver := cDriver;
    strAttr := Format( 'DSN=%s'+#0+
    'DBQ=%s'+#0+
    'Exclusive=%s'+#0+
    'Description= %s'+#0+#0+
    'CREATE_DB="%s"'#0+#0,
    [cDSNName,strFile,cExclusive,cDescription,strFile]);
    fResult := pFn( 0, ODBC_ADD_SYS_DSN, @strDriver[1], @strAttr[1] );
  if( fResult = false ) then
    ShowMessage( 'Falha ao tentar criar o banco de dados' );
  end;
    FindClose( srInfo );
  end;
  FreeLibrary( hLib );
  if fResult then
    ShowMessage( 'Banco de dados criado.' );
  end
  else
  begin
    ShowMessage( 'o sistema no pode carregar a biblioteca ODBCCP32.DLL' );
  end;
end;

function ColorToHtml(mColor: TColor): string;
begin
  mColor := ColorToRGB(mColor);
  Result := Format('#%.2x%.2x%.2x',
  [GetRValue(mColor), GetGValue(mColor), GetBValue(mColor)]);
end; { ColorToHtml } 

function StrToHtml(mStr: string; mFont: TFont = nil): string;
var
  vLeft, vRight: string;
begin
  Result := mStr;
  Result := StringReplace(Result, '&', '&AMP;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&LT;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&GT;', [rfReplaceAll]);
  if not Assigned(mFont) then Exit;
  vLeft := Format('<FONT FACE="%s" COLOR="%s">',
   [mFont.Name, ColorToHtml(mFont.Color)]);
  vRight := '</FONT>';
  if fsBold in mFont.Style then begin
    vLeft := vLeft + '<B>';
    vRight := '</B>' + vRight;
  end;
  if fsItalic in mFont.Style then begin
    vLeft := vLeft + '<I>';
    vRight := '</I>' + vRight;
  end;
  if fsUnderline in mFont.Style then begin
    vLeft := vLeft + '<U>';
    vRight := '</U>' + vRight;
  end;
  if fsStrikeOut in mFont.Style then begin
    vLeft := vLeft + '<S>';
    vRight := '</S>' + vRight;
  end;
  Result := vLeft + Result + vRight;
end; { StrToHtml }

{
CONVERTENDO UM DATASET EXIBIDO NO DBGRID PARA
O FORMATO HTML
EXEMPLO DE COMO USAR:

procedure TForm1.Button1Click(Sender: TObject);
begin
 DBGridToHtmlTable(DBGrid1, Memo1.Lines, Caption);
 Memo1.Lines.SaveToFile('c:\temp.htm');
 ShellExecute(Handle, nil, 'c:\temp.htm', nil, nil, SW_SHOW); 
end;
}

function DBGridToHtmlTable(mDBGrid: TDBGrid; mStrings: TStrings;
 mCaption: TCaption = ''): Boolean;
const
 cAlignText: array[TAlignment] of string = ('LEFT', 'RIGHT', 'CENTER'); 
var
  vColFormat: string;
  vColText: string;
  vAllWidth: Integer;
  vWidths: array of Integer;
  vBookmark: string;
  I, J: Integer;
begin
  Result := False;
  if not Assigned(mStrings) then Exit;
  if not Assigned(mDBGrid) then Exit;
  if not Assigned(mDBGrid.DataSource) then Exit;
  if not Assigned(mDBGrid.DataSource.DataSet) then Exit;
  if not mDBGrid.DataSource.DataSet.Active then Exit;
  vBookmark := mDBGrid.DataSource.DataSet.Bookmark;
  mDBGrid.DataSource.DataSet.DisableControls;
  try
    J := 0;
    vAllWidth := 0;
    for I := 0 to mDBGrid.Columns.Count - 1 do
    if mDBGrid.Columns[I].Visible then
    begin
      Inc(J);
      SetLength(vWidths, J);
      vWidths[J - 1] := mDBGrid.Columns[I].Width;
      Inc(vAllWidth, mDBGrid.Columns[I].Width);
    end;
   if J <= 0 then Exit;
  mStrings.Clear ;
  mStrings.Add(Format('<TABLE BGCOLOR="%s" BORDER=1 WIDTH="100%%">',
    [ColorToHtml(mDBGrid.Color)]));
  if mCaption <> '' then
    mStrings.Add(Format('<CAPTION>%s</CAPTION>', [StrToHtml(mCaption)]));
  vColFormat := '';
  vColText := '';
  vColFormat := vColFormat + '<TR>'#13#10;
  vColText := vColText + '<TR>'#13#10;
  J := 0;
  for I := 0 to mDBGrid.Columns.Count - 1 do
    if mDBGrid.Columns[I].Visible then
    begin
      vColFormat := vColFormat + Format(
'  <TD BGCOLOR="%s" ALIGN=%s WIDTH="%d%%">DisplayText%d</TD>'#13#10,
         [ColorToHtml( mDBGrid.Columns[I].Color),
         cAlignText[mDBGrid.Columns[I].Alignment],
         Round(vWidths[J] / vAllWidth * 100), J]);
       vColText := vColText + Format(
'  <TD BGCOLOR="%s" ALIGN=%s WIDTH="%d%%">%s</TD>'#13#10,
         [ColorToHtml(mDBGrid.Columns[I].Title.Color),
         cAlignText[mDBGrid.Columns[I].Alignment],
         Round(vWidths[J] / vAllWidth * 100),
         StrToHtml(mDBGrid.Columns[I].Title.Caption,
            mDBGrid.Columns[I].Title.Font)]);
       Inc(J);
    end;
  vColFormat := vColFormat + '</TR>'#13#10;
  vColText := vColText + '</TR>'#13#10;
  mStrings.Text := mStrings.Text + vColText;
  mDBGrid.DataSource.DataSet.First;
  while not mDBGrid.DataSource.DataSet.Eof do
  begin
    J := 0;
    vColText := vColFormat;
  for I := 0 to mDBGrid.Columns.Count - 1 do
    if mDBGrid.Columns[I].Visible then
    begin
      vColText := StringReplace(vColText, Format('>DisplayText%d<', [J]),
         Format('>%s<', [StrToHtml(mDBGrid.Columns[I].Field.DisplayText,
           mDBGrid.Columns[I].Font)]),
        [rfReplaceAll]);
      Inc(J);
    end;
    mStrings.Text := mStrings.Text + vColText;
    mDBGrid.DataSource.DataSet.Next;
  end;
   mStrings.Add('</TABLE>');
 finally
   mDBGrid.DataSource.DataSet.Bookmark := vBookmark;
   mDBGrid.DataSource.DataSet.EnableControls;
   vWidths := nil;
 end;
 Result := True;
end; { DBGridToHtmlTable } 

function GetIP:string;
//--> Declare a Winsock na clausula uses da unit
var
  WSAData: TWSAData;
  HostEnt: PHostEnt;
  Name:string;
begin
  WSAStartup(2, WSAData);
  SetLength(Name, 255);
  Gethostname(PChar(Name), 255);
  SetLength(Name, StrLen(PChar(Name)));
  HostEnt := gethostbyname(PChar(Name));
  with HostEnt^ do
  begin
    Result := Format('%d.%d.%d.%d',
    [Byte(h_addr^[0]),Byte(h_addr^[1]),
    Byte(h_addr^[2]),Byte(h_addr^[3])]);
  end;
  WSACleanup;
end;

procedure CriaAtalho(const Atalho: string);
var
  ItemIDList :  PItemIDList;
  ShellLink : IShellLink;
  PersistFile : IPersistFile;
  NomeLnk : WideString;
  DirDesktop : String;
begin
  SetLength(DirDesktop,MAX_PATH);
  SHGetSpecialFolderLocation(Application.Handle, CSIDL_DESKTOPDIRECTORY,
    ItemIDList);
  SHGetPathFromIDList(ItemIdList,PChar(DirDesktop));
  SetLength(DirDesktop,StrLen(PChar(DirDesktop)));
// cria interface IShellLink
  ShellLink := CreateComObject(CLSID_ShellLink) as IShellLink;
// cria interface IPersistFile
  PersistFile := ShellLink as IPersistFile;
// preenche dados de IShellLink
  with ShellLink do begin
    SetDescription(PChar(Atalho));
    SetPath(PChar(ExtractFilePath(ParamStr(0)) + Atalho + '.exe'));
    SetWorkingDirectory(PChar(ExtractFilePath(ParamStr(0) + Atalho + '.exe')));
  end;
  NomeLnk := DirDesktop+'\'+ChangeFileExt(Atalho,'.lnk');
// salva atalho
  PersistFile.Save(PWideChar(NomeLnk),False);
end;

Function EliminaCaracteres (sTexto: String; sCaracteres: string; Caixalta: Boolean; Comparacao : Boolean ):String;
var
  nPos, nTamChar, antes, depois : Integer;
begin
  if sCaracteres <> '' then
  begin
    antes := length(sTexto);
    Result := '';
    nPos := 1;
    nTamChar := length(sCaracteres);

  while nPos <= nTamChar do
  begin
    sTexto := AnsiReplaceStr(sTexto,copy(sCaracteres,nPos,1),'');
    inc(nPos);
  end;
  depois := length(sTexto);

  if Caixalta = true then
    Result := UpperCase(sTexto)
  else
    Result := LowerCase(sTexto);
  end;
  if Comparacao = True then
  begin
    if antes = depois then
      Result := CurrToStr((StrToCurr(sTexto)) * 100);
  end;
end;

function GeraImagem(Img: TImage): string;
const
  f: array [0..4] of string =
  ('Courier New', 'Impact', 'Times New Roman', 'Verdana', 'Arial');
  s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; 
  C : array [0..14] of TColor =
  (clAqua, clBlack, clBlue, clFuchsia, clGray, clGreen, clLime, clMaroon, clNavy,
  clOlive, clPurple, clRed, clSilver, clTeal, clYellow);
var
  i, x, y : integer;
  r : string;
begin
  randomize;
  Img.Width := 160;
  Img.Height := 60;
  for i := 0 to 3 do
  r := r + s[Random(length(s)-1)+1];
  with Img.Picture.Bitmap do
  begin
    width := Img.Width;
    Height := Img.Height;
    Canvas.Brush.Color := $00EFEFEF;
    Canvas.FillRect(Img.ClientRect);
  for i := 0 to 3 do
  begin
    Canvas.Font.Size := random(20) + 20;
    Canvas.Font.Name := f[High(f)];
    Canvas.Font.Color := c[random(High(c))];
    Canvas.TextOut(i*40,0,r[i+1]);
  end;
  for i := 0 to 2 do
  begin
    Canvas.Pen.Color := c[random(High(c))];
    Canvas.Pen.Width := 2;
    canvas.MoveTo(random(Width),0);
    Canvas.LineTo (random(Width),Height);
    Canvas.Pen.Width := 1;
    x := random(Width-10);
    y := random(Height-10);
    Canvas.Rectangle(x,y,x+10,y+10);
  end;
  end;
  Result := r;
end;

// para texto a esquerda
function AlinhaE(Texto : String; Tamanho : Integer) : String;
begin
  Texto := Trim(Texto);
  while length(Texto) < Tamanho do
  begin
   Texto := Texto + ' ';
  end ;
  Result := Texto;
end;

// para texto centralizado
function AlinhaC(Texto : String; Tamanho : integer) : String;
 var metade: integer;
begin
  Texto := Trim(Texto);
  metade := ((Tamanho-Length(Texto)) div 2);
  while Length(Texto)+metade < Tamanho do
    Texto := ' ' + Texto;
  result := Texto;
end;

// para texto a direita
function AlinhaD(Texto : String; Tamanho : Integer) : String;
begin
  Texto := Trim(Texto);
  while length(Texto) < Tamanho do
  begin
    Texto := ' ' + Texto;
  end;
  Result := Texto;
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
      FindClose(SearchRec);
    raise;
  end;
   FindClose(SearchRec);
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

Procedure FileCopy(sourcefilename:string; targetfilename: String );
 Var S, T: TFileStream;
Begin
  S := TFileStream.Create( sourcefilename, fmShareDenyNone );
  try
  T := TFileStream.Create( targetfilename, fmOpenWrite or fmCreate );
    try
      T.CopyFrom(S, S.Size ) ;
    finally
      T.Free;
    end;
  finally
    S.Free;
  end;
End;

{
Funo para incluir um arquivo dentro do executvel:
1 - Copiar o arquivo a ser includo para o mesmo diretrio dos fontes do programa.
2 - Criar um arquivo com extenso .rc, por exemplo temp.rc e colocar a seguinte linha:
(substituir arquivo.txt pelo arquivo a ser includo)
NOME       RCDATA DISCARDABLE "arquivo.txt"
3 - Digitar:
brcc32 -32 temp.rc -fotemp.res
4 - No arquivo .PAS, colocar a seguinte linha depois do implementation:
{$R temp.res}
{5 - Utilizar esta procedure abaixo:
Ao chamar a procedure extractResource('NOME', '.\arquivo.txt'); o arquivo vai ser extrado para o diretrio atual
}
function extractResource(binresname: string; path: string): boolean;
var
  ResSize, HG, HI, SizeWritten, hFileWrite: Cardinal;
begin
  result := false;
  HI := FindResource(hInstance, @binresname[1], RT_RCDATA);
  if HI <> 0 then
  begin
    HG := LoadResource(hInstance, HI);
    if HG <> 0 then
    begin
      ResSize := SizeOfResource(hInstance, HI);
      hFileWrite := CreateFile(@path[1], GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
      CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
    if hFileWrite <> INVALID_HANDLE_VALUE then
      try
        result := (WriteFile(hFileWrite, LockResource(HG)^, ResSize, SizeWritten, nil) and (SizeWritten = ResSize));
      finally
        CloseHandle(hFileWrite);
      end;
    end;
  end;
end;

function ObterNome(const Title: string; const MainLabel: string; var Nome: string; const Intervalo: string): boolean;

var
  Form: TForm; { Varivel para o Form }
  //  Edt: TMeuEdit1; { Varivel para o MeuEdit1 -> componente que criei -  para fazer filtro do
  //  evento OnKeyPress - baseado no parmetro da const Intervalo}
  Cb : TComboBox;
  Panel: TPanel; { Varivel para o Panel }
  groupbox: TGroupBox; { Varivel para o Groupbox }
procedure EdtKeyPress(Sender: TObject; var Key: Char);
begin
  if not (key in ['1'..'3']) then Abort; 
end;

begin
  { Cria o form }
  Form := TForm.Create(Application);
  try
  { Altera algumas propriedades do Form }
    Form.BorderStyle := bsDialog;
    Form.Caption := Title;
    Form.Position := poScreenCenter;
    Form.Width := 300;
    Form.Height := 210;
    // Font.Name := 'Verdana';
    //Font.Size := 8;

  { Cria e Posiciona o Panel }
  Panel := TPanel.Create(Form);
  with Panel do begin
    Parent := Form;
    Font.Name := 'Verdana';
    Font.Color := clBlue;
    Font.Size := 8;
    Align := alClient;
  end;

  { Cria e Posiciona o GroupBox }
  groupbox := TGroupBox.Create(Form);
  with groupbox do begin
    Align := alBottom;
    Parent := Form;
    Height := Form.ClientHeight - 90;
  end;

  { Cria e Posiciona o Label }
  with TLabel.Create(Form) do begin
    Parent := Panel;
    AutoSize := false;
    WordWrap := true;
    Caption := MainLabel;
    Font.Style := [fsBold];
    //Font.Name := 'MS Sans Serif';
    Font.Size := 8;
    Left := 10;
    Top := 5;
    Width := 270;
    Height := 320;
  end;

  { Cria e Posiciona o Label '---------------' }
  {    with TLabel.Create(Form) do begin
   Parent := groupbox;
   Caption := '-------------------------------------------------------';
   Alignment := taLeftJustify;
   Font.Style := [fsBold];
   Font.Name := 'Verdana';
   Font.Size := 8;
   Left := 3;// Form.ClientWidth - 230;
   Top := 35;
  end;
  }

  { Cria e Posiciona o Label 'Digite a opo desejada: ' }
  with TLabel.Create(Form) do begin
    Parent := groupbox;
    AutoSize := false;
    WordWrap := true;
    Height := 50;
    Width := 150;
    Caption := 'Digite a opo desejada: ';
    Alignment := taLeftJustify;
    Font.Style := [fsBold];
    Font.Name := 'Verdana';
    Font.Size := 8;
    Left := 15;// Form.ClientWidth - 230;
    Top := 12;
  end;

  { Cria e Posiciona o Edit }
  {  Edt := TMeuEdit1.Create(Form);
  with Edt do begin
   Parent := Form;
   Edt.SetIntervalo(Intervalo);
   Text := '1';
   Left := 130;
   Top := 205;
   Font.Color := clNavy;
   Font.Style := [fsBold];
   Color := $00D8FEFC;
   CharCase := ecUpperCase;
   MaxLength := 1;
   { Ajusta o comprimento do Edit de acordo com a largura
   do form }
  //    Width := 20;// Form.ClientWidth - 20;
  //  end;
  Cb := TComboBox.Create(Form);
  with Cb do begin
  Parent := Form;
  if (Intervalo = '1-3') then begin
    Items.Add('1');
    Items.Add('2');
    Items.Add('3');
  end
  else if (Intervalo = '1-2') then begin
    Items.Add('1');
    Items.Add('2');
  end
  else if (Intervalo = '1-4') then begin
    Items.Add('1');
    Items.Add('2');
    Items.Add('3');
    Items.Add('4');
  end;
    Left := 130;
    Top := 105;
    Font.Color := clNavy;
    Font.Style := [fsBold];
    Color := $00D8FEFC;
    Style := csDropDownList;
    ItemIndex := 0;
    Width := 40;
  end;

  { Cria e Posiciona o Boto OK }
  with TBitBtn.Create(Form) do begin
    Parent := Form;
    { Posiciona de acordo com a largura do form }
    Left := 10;//  Form.ClientWidth - (Width * 2) - 60;
    Top := 140;
    Width := 130;
    Kind := bkOK; { Boto Ok }
  end;

  { Cria e Posiciona o Boto Cancela }
  with TBitBtn.Create(Form) do begin
    Parent := Form;
    Left := 150;// Form.ClientWidth - Width - 50;
    Top :=  140;
    Width := 130;
    Caption := 'Cancela';
    Kind := bkCancel; { Boto Cancel }
  end;

  { agora, se pressionar cancela, o valor ser retornado tambm ... }
  if Form.ShowModal = mrOK then begin
    Nome := Cb.Items.Strings[Cb.itemindex];
    Result := true;
  end
  else begin
    Nome := Cb.Items.Strings [Cb.itemindex];
    Result := true;
  end;
  finally
    Form.Free;
  end;
end;

{          function SumAll  -> abaixo:
Exemplo de como utilizar:
procedure TForm1.Button4Click(Sender: TObject);
var
 X: Extended;
 Y: Integer;
begin
 Y := 10;
 X := SumAll ([Y * Y, 'k', True, 10.34, '99999']);
 ShowMessage (Format (
   'SumAll ([Y*Y, ''k'', True, 10.34, ''99999'']) => %n', [X]));
end;
}
function SumAll (const Args: array of const): Extended; 
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Args) to High (Args) do
  case Args [I].VType of
    vtInteger: Result :=
      Result + Args [I].VInteger;
    vtBoolean:
      if Args [I].VBoolean then
        Result := Result + 1;
    vtChar:
      Result := Result + Ord (Args [I].VChar);
    vtExtended:
      Result := Result + Args [I].VExtended^;
    vtString, vtAnsiString:
      Result := Result + StrToIntDef ((Args [I].VString^), 0);
     vtWideChar:
      Result := Result + Ord (Args [I].VWideChar);
    vtCurrency:
      Result := Result + Args [I].VCurrency^;
   end; // case
end;

procedure ShowMeHelp(const TitleHelp: string; const TextoHelp: string);
var Frm: TForm;
  MM: TMemo;
begin
  Frm := TForm.Create(nil);
   try
     Frm.Width := 300;
     Frm.Height := 120;
     Frm.Top := Mouse.CursorPos.Y;
     Frm.Left := Mouse.CursorPos.X;
     Frm.BorderStyle := bsToolWindow;
     Frm.Font.Name  := 'Verdana';
     Frm.Caption := TitleHelp; 
     MM := TMemo.Create(nil);
     try
       MM.Parent     := Frm;
       MM.Align      := alClient;
       MM.Text       := TextoHelp;
       MM.Font.Color := clBlack;
       MM.Font.Style := [fsBold]; 
       MM.ReadOnly   := True;
       MM.Color      := $00D8FEFC;
       Frm.ShowModal;
     finally
       MM.Free;
     end;
   finally
     Frm.Free;
   end;
end;


function Base64Encode(const Source: AnsiString): AnsiString;
var
  NewLength: Integer;
begin
  NewLength := ((2 + Length(Source)) div 3) * 4;
  SetLength( Result, NewLength);
asm
   Push  ESI
   Push  EDI
   Push  EBX
   Lea   EBX, Base64_Table
   Inc   EBX                // Move past String Size (ShortString)
   Mov   EDI, Result
   Mov   EDI, [EDI]
   Mov   ESI, Source
   Mov   EDX, [ESI-4]        //Length of Input String 
@WriteFirst2:
   CMP EDX, 0
   JLE @Done
   MOV AL, [ESI]
   SHR AL, 2
{$IFDEF VER140} // Changes to BASM in D6
   XLATB
{$ELSE}
   XLAT
{$ENDIF}
   MOV [EDI], AL
   INC EDI
   MOV AL, [ESI + 1] 
   MOV AH, [ESI]
   SHR AX, 4
   AND AL, 63
{$IFDEF VER140} // Changes to BASM in D6
   XLATB
{$ELSE}
   XLAT
{$ENDIF}
   MOV [EDI], AL
   INC EDI
   CMP EDX, 1
   JNE @Write3
   MOV AL, 61                        // Add == 
   MOV [EDI], AL
   INC EDI
   MOV [EDI], AL
   INC EDI
   JMP @Done
@Write3:
   MOV AL, [ESI + 2]
   MOV AH, [ESI + 1]
   SHR AX, 6
   AND AL, 63
{$IFDEF VER140} // Changes to BASM in D6 
   XLATB
{$ELSE}
   XLAT
{$ENDIF}
   MOV [EDI], AL
   INC EDI
   CMP EDX, 2
   JNE @Write4
   MOV AL, 61                        // Add =
   MOV [EDI], AL
   INC EDI
   JMP @Done
@Write4: 
   MOV AL, [ESI + 2]
   AND AL, 63
{$IFDEF VER140} // Changes to BASM in D6
   XLATB
{$ELSE}
   XLAT
{$ENDIF}
   MOV [EDI], AL
   INC EDI
   ADD ESI, 3
   SUB EDX, 3
   JMP @WriteFirst2 
@done:
   Pop EBX
   Pop EDI
   Pop ESI
end;
end;

//Decode Base64
function Base64Decode(const Source: string): string;
var
  NewLength: Integer;
begin
{
 NB: On invalid input this routine will simply skip the bad data, a
better solution would probably report the error 

 ESI -> Source String
 EDI -> Result String
 ECX -> length of Source (number of DWords)
 EAX -> 32 Bits from Source
 EDX -> 24 Bits Decoded
 BL -> Current number of bytes decoded
}
  SetLength( Result, (Length(Source) div 4) * 3);
  NewLength := 0;
asm
   Push  ESI
   Push  EDI
   Push  EBX
   Mov   ESI, Source
   Mov   EDI, Result //Result address
   Mov   EDI, [EDI]
   Or    ESI,ESI   // Nil Strings
   Jz    @Done
   Mov   ECX, [ESI-4]
   Shr   ECX,2       // DWord Count
   JeCxZ @Error      // Empty String
   Cld
   jmp   @Read4
 @Next:
   Dec   ECX
   Jz   @Done
 @Read4:
   lodsd
   Xor   BL, BL
   Xor   EDX, EDX
   Call  @DecodeTo6Bits
   Shl   EDX, 6
   Shr   EAX,8
   Call  @DecodeTo6Bits
   Shl   EDX, 6
   Shr   EAX,8
   Call  @DecodeTo6Bits
   Shl   EDX, 6
   Shr   EAX,8
   Call  @DecodeTo6Bits

 // Write Word
   Or    BL, BL
   JZ    @Next  // No Data
   Dec   BL
   Or    BL, BL
   JZ    @Next  // Minimum of 2 decode values to translate to 1 byte
   Mov   EAX, EDX
   Cmp   BL, 2
   JL    @WriteByte
   Rol   EAX, 8
   BSWAP EAX
   StoSW
   Add NewLength, 2
 @WriteByte:
   Cmp BL, 2
   JE  @Next
   SHR EAX, 16
   StoSB
   Inc NewLength
   jmp   @Next
 @Error:
   jmp @Done
 @DecodeTo6Bits:
 @TestLower:
   Cmp AL, 'a'
   Jl @TestCaps
   Cmp AL, 'z'
   Jg @Skip
   Sub AL, 71
   Jmp @Finish
 @TestCaps:
   Cmp AL, 'A'
   Jl  @TestEqual
   Cmp AL, 'Z'
   Jg  @Skip
   Sub AL, 65
   Jmp @Finish
 @TestEqual:
   Cmp AL, '='
   Jne @TestNum
   // Skip byte
   ret
 @TestNum:
   Cmp AL, '9'
   Jg @Skip
   Cmp AL, '0'
   JL  @TestSlash
   Add AL, 4
   Jmp @Finish
 @TestSlash:
   Cmp AL, '/'
   Jne @TestPlus
   Mov AL, 63
   Jmp @Finish
 @TestPlus:
   Cmp AL, '+'
   Jne @Skip
   Mov AL, 62
 @Finish:
   Or  DL, AL
   Inc BL
 @Skip:
   Ret
 @Done:
   Pop   EBX
   Pop   EDI
   Pop   ESI
end;
  SetLength( Result, NewLength); // Trim off the excess
end;

//Encrypt a string
function Encrypt(const S: string; Key: Word): string;
var
  I: byte;
begin
  SetLength(result,length(s));
  for I := 1 to Length(S) do
  begin
    Result[I] := char(byte(S[I]) xor (Key shr 8));
    Key := (byte(Result[I]) + Key) * cKey1 + cKey2;
  end;
end;


//Decrypt a string encoded with Encrypt
function Decrypt(const S: string; Key: Word): string;
var
  I: byte;
begin
  SetLength(result,length(s));
  for I := 1 to Length(S) do
  begin
    Result[I] := char(byte(S[I]) xor (Key shr 8));
    Key := (byte(S[I]) + Key) * cKey1 + cKey2;
  end;
end;

//Return only the HTML of a string
function ExtractHTML(S : string) : string;
begin
  Result := StripHTMLorNonHTML(S, True);
end;

function CopyStr(const aSourceString : string; aStart, aLength : Integer) : string;
var
  L : Integer;
begin
  L := Length(aSourceString);
  if L=0 then Exit;
  if (aStart < 1) or (aLength < 1) then Exit;
  if aStart + (aLength-1) > L then aLength := L - (aStart-1);
  if (aStart <1) then exit;
  SetLength(Result,aLength);
  FastCharMove(aSourceString[aStart], Result[1], aLength);
end;

//Take all HTML out of a string
function ExtractNonHTML(S : string) : string;
begin
  Result := StripHTMLorNonHTML(S,False);
end;

//Convert a text-HEX value (FF0088 for example) to an integer
function  HexToInt(aHex : string) : int64;
var
  Multiplier      : Int64;
  Position        : Byte;
  Value           : Integer;
begin
  Result := 0;
  Multiplier := 1;
  Position := Length(aHex);
  while Position >0 do
  begin
    Value := FastCharPosNoCase(cHexChars, aHex[Position], 1)-1;
  if Value = -1 then
    raise Exception.Create('Invalid hex character ' + aHex[Position]);
    Result := Result + (Value * Multiplier);
    Multiplier := Multiplier * 16;
    Dec(Position);
  end;
end;

//Get the left X amount of chars
function LeftStr(const aSourceString : string; Size : Integer) : string;
begin
  if Size > Length(aSourceString) then
    Result := aSourceString
  else
  begin
    SetLength(Result, Size);
    Move(aSourceString[1],Result[1],Size);
  end;
end;

//Do strings match with wildcards, eg
//StringMatches('The cat sat on the mat', 'The * sat * the *') = True 
function StringMatches(Value, Pattern : string) : Boolean;
var
  NextPos,
  Star1,
  Star2       : Integer;
  NextPattern   : string;
begin
  Star1 := FastCharPos(Pattern,'*',1);
  if Star1 = 0 then
    Result := (Value = Pattern)
  else
  begin
    Result := (Copy(Value,1,Star1-1) = Copy(Pattern,1,Star1-1));
    if Result then
    begin
    if Star1 > 1 then Value := Copy(Value,Star1,Length(Value));
      Pattern := Copy(Pattern,Star1+1,Length(Pattern));
      NextPattern := Pattern;
      Star2 := FastCharPos(NextPattern, '*',1);
      if Star2 > 0 then NextPattern := Copy(NextPattern,1,Star2-1);
    //pos(NextPattern,Value);
    NextPos := FastPos(Value, NextPattern, Length(Value), Length(NextPattern), 1);
    if (NextPos = 0) and not (NextPattern = '') then
      Result := False
    else
    begin
      Value := Copy(Value,NextPos,Length(Value));
     if Pattern = '' then
       Result := True
     else
       Result := Result and StringMatches(Value,Pattern);
     end;
    end;
  end;
end;

//Missing text will tell you what text is missing, eg
//MissingText('the ? sat on the mat','the cat sat on the mat','?') = 'cat'
function MissingText(Pattern, Source : string; SearchText : string = '?') : string;
var
  Position                    : Longint;
  BeforeText,
  AfterText                   : string;
  BeforePos,
  AfterPos                     : Integer;
  lSearchText,
  lBeforeText,
  lAfterText,
  lSource                     : Longint;
begin
  Result := '';
  Position := PosBMH(SearchText,Pattern);
  if Position = 0 then exit;
  lSearchText := Length(SearchText);
  lSource := Length(Source);
  BeforeText := Copy(Pattern,1,Position-1);
  AfterText := Copy(Pattern,Position+lSearchText,lSource);
  lBeforeText := Length(BeforeText);
  lAfterText := Length(AfterText);
  AfterPos := lBeforeText;
 repeat
   AfterPos := FastPosNoCase(Source,AfterText,lSource,lAfterText,AfterPos+lSearchText);
   if AfterPos > 0 then
   begin
     BeforePos := FastPosBackNoCase(Source,BeforeText,AfterPos-1,lBeforeText,AfterPos - (lBeforeText-1));
     if (BeforePos > 0) then
     begin
       Result := Copy(Source,BeforePos + lBeforeText, AfterPos - (BeforePos + lBeforeText));
       Break;
     end;
   end;
 until AfterPos = 0;
end;

//Generates a random filename but preserves the original path + extension
function RandomFilename(aFilename : string) : string;
var
  Path, 
  Filename,
  Ext               : string;
begin
  Result := aFilename;
  Path := ExtractFilepath(aFilename);
  Ext := ExtractFileExt(aFilename);
  Filename := ExtractFilename(aFilename);
  if Length(Ext) > 0 then
    Filename := Copy(Filename,1,Length(Filename)-Length(Ext));
  repeat
    Result := Path + RandomStr(32) + Ext;
  until not FileExists(Result);
end;

//Makes a string of aLength filled with random characters 
function RandomStr(aLength : Longint) : string;
var
  X                           : Longint;
begin
  if aLength <= 0 then exit;
  SetLength(Result, aLength);
  for X:=1 to aLength do
    Result[X] := Chr(Random(26) + 65); 
end;

function StringCount(const aSourceString, aFindString : string; Const CaseSensitive : Boolean = TRUE) : Integer;
var
  Find,
  Source,
  NextPos                     : PChar;
  LSource,
  LFind                       : Integer; 
  Next                        : TFastPosProc;
  JumpTable                   : TBMJumpTable;
begin
  Result := 0;
  LSource := Length(aSourceString);
  if LSource = 0 then exit;
  LFind := Length(aFindString);
  if LFind = 0 then exit;
  if CaseSensitive then
  begin
    Next := BMPos;
    MakeBMTable(PChar(aFindString), Length(aFindString), JumpTable);
  end else
  begin
    Next := BMPosNoCase;
    MakeBMTableNoCase(PChar(aFindString), Length(aFindString), JumpTable);
  end;
  Source := @aSourceString[1];
  Find := @aFindString[1];
  repeat
    NextPos := Next(Source, Find, LSource, LFind, JumpTable);
    if NextPos <> nil then
    begin
      Dec(LSource, (NextPos - Source) + LFind);
      Inc(Result);
      Source := NextPos + LFind;
    end;
  until NextPos = nil;
end;

function SoundEx(const aSourceString: string): Integer;
var
  CurrentChar: PChar;
  I, S, LastChar, SoundexGroup: Byte;
  Multiple: Word;
begin
  if aSourceString = '' then
    Result := 0
  else
  begin
    //Store first letter immediately
    Result := Ord(Upcase(aSourceString[1]));
    //Last character found = 0
    LastChar := 0;
    Multiple := 26;
    //Point to first character
    CurrentChar := @aSourceString[1];
    for I := 1 to Length(aSourceString) do
    begin
      Inc(CurrentChar);
      S := Ord(CurrentChar^);
      if (S > 64) and (S < 123) then
      begin
        SoundexGroup := cSoundexTable[S];
        if (SoundexGroup <> LastChar) and (SoundexGroup > 0) then
        begin
          Inc(Result, SoundexGroup * Multiple);
          if Multiple = 936 then Break; {26 * 6 * 6}
          Multiple := Multiple * 6;
           LastChar := SoundexGroup;
        end;
      end;
    end;
  end;
end;

//Used by ExtractHTML and ExtractNonHTML
function StripHTMLorNonHTML(const S : string; WantHTML : Boolean) : string;
var
  X: Integer;
  TagCnt: Integer;
  ResChar: PChar;
  SrcChar: PChar;
begin
  TagCnt := 0;
  SetLength(Result, Length(S));
  if Length(S) = 0 then Exit;
  ResChar := @Result[1];
  SrcChar := @S[1];
  for X:=1 to Length(S) do
  begin
  case SrcChar^ of
  '<':
  begin
    Inc(TagCnt);
    if WantHTML and (TagCnt = 1) then
    begin
      ResChar^ := '<';
      Inc(ResChar);
    end;
  end;
  '>':
  begin
    Dec(TagCnt);
    if WantHTML and (TagCnt = 0) then
    begin
      ResChar^ := '>';
      Inc(ResChar);
    end;
  end;
  else
  case WantHTML of
  False:
    if TagCnt <= 0 then
    begin
      ResChar^ := SrcChar^;
      Inc(ResChar);
      TagCnt := 0;
    end;
  True:
    if TagCnt >= 1 then
    begin
      ResChar^ := SrcChar^;
      Inc(ResChar);
    end else
     if TagCnt < 0 then TagCnt := 0;
  end;
  end;
  Inc(SrcChar);
 end;
  SetLength(Result, ResChar - PChar(@Result[1]));
  Result := FastReplace(Result, '&nbsp;', ' ', False);
  Result := FastReplace(Result,'&amp;','&', False);
  Result := FastReplace(Result,'&lt;','<', False);
  Result := FastReplace(Result,'&gt;','>', False);
  Result := FastReplace(Result,'&quot;','"', False); 
end;

//Generates a UniqueFilename, makes sure the file does not exist before returning a result
function UniqueFilename(aFilename : string) : string;
var
  Path,
  Filename,
  Ext               : string;
  Index             : Integer;
begin
  Result := aFilename;
  if FileExists(aFilename) then
  begin
    Path := ExtractFilepath(aFilename);
    Ext := ExtractFileExt(aFilename);
    Filename := ExtractFilename(aFilename);
    if Length(Ext) > 0 then
      Filename := Copy(Filename,1,Length(Filename)-Length(Ext));
   Index := 2;
   repeat
     Result := Path + Filename + IntToStr(Index) + Ext;
     Inc(Index);
   until not FileExists(Result);
  end;
end;

//Decodes all that %3c stuff you get in a URL
function URLToText(aValue : string) : string;
var
  X : Integer;
begin
  Result := '';
  X := 1;
  while X <= Length(aValue) do
  begin
    if aValue[X] <> '%' then
      Result := Result + aValue[X]
    else
    begin
      Result := Result + Chr( HexToInt( Copy(aValue,X+1,2) ) );
      Inc(X,2);
    end;
   Inc(X);
  end;
end;

//Returns the whole word at a position
function WordAt(Text : string; Position : Integer) : string;
var
  L,
  X : Integer;
begin
  Result := '';
  L := Length(Text);
  if (Position > L) or (Position < 1) then Exit;
  for X:=Position to L do
  begin
    if Upcase(Text[X]) in ['A'..'Z','0'..'9'] then
      Result := Result + Text[X]
    else
      Break;
  end;
  for X:=Position-1 downto 1 do
  begin
    if Upcase(Text[X]) in ['A'..'Z','0'..'9'] then
      Result := Text[X] + Result
    else
      Break;
  end;
end;

{
 VERY fast split function
 this function returns part of a string based on
 constant defineable delimiters, such as ";". So
 SPLIT('this is a test ',' ',3) = 'is' or
 SPLIT('data;another;yet;again;more;',';',4) = 'yet'

 Split function shifts index integer by two to
 be compatible with commonly used PD split function
 gpl 2004 / Juhani Suhonen
}

function splitstr(input: string; schar: Char; s: Integer): string;
var
  c: array of Integer;
  b, t: Integer;
begin
  Inc(s, 1);
  Dec(s, 2);  // for compatibility with very old & slow split function
  t := 0;     // variable T needs to be initialized...
  setlength(c, Length(input));
  for b := 0 to pred(High(c)) do 
  begin
    c[b + 1] := posex(schar, input, succ(c[b]));
    // BREAK LOOP if posex looped (position before previous)
    // or wanted position reached..
    if (c[b + 1] < c[b]) or (s < t) then break 
    else 
      Inc(t);
  end;
  Result := Copy(input, succ(c[s]), pred(c[s + 1] - c[s]));
end;

//MakeBMJumpTable takes a FindString and makes a JumpTable
procedure MakeBMTable(Buffer: PChar; BufferLen: Integer; var JumpTable: TBMJumpTable);
begin
 if BufferLen = 0 then raise Exception.Create('BufferLen is 0');
 asm
       push    EDI
       push    ESI 
       mov     EDI, JumpTable
       mov     EAX, BufferLen
       mov     ECX, $100
       REPNE   STOSD
       mov     ECX, BufferLen
       mov     EDI, JumpTable
       mov     ESI, Buffer
       dec     ECX 
       xor     EAX, EAX
@@loop:
       mov     AL, [ESI]
       lea     ESI, ESI + 1
       mov     [EDI + EAX * 4], ECX
       dec     ECX
       jg      @@loop
       pop     ESI
       pop     EDI 
 end;
end;

procedure MakeBMTableNoCase(Buffer: PChar; BufferLen: Integer; var JumpTable: TBMJumpTable);
begin
 if BufferLen = 0 then raise Exception.Create('BufferLen is 0');
 asm
       push    EDI
       push    ESI
       mov     EDI, JumpTable
       mov     EAX, BufferLen
       mov     ECX, $100
       REPNE   STOSD
       mov     EDX, GUpcaseLUT
       mov     ECX, BufferLen
       mov     EDI, JumpTable
       mov     ESI, Buffer
       dec     ECX
       xor     EAX, EAX
@@loop:
       mov     AL, [ESI]
       lea     ESI, ESI + 1
       mov     AL, [EDX + EAX]
       mov     [EDI + EAX * 4], ECX
       dec     ECX
       jg      @@loop
       pop     ESI
       pop     EDI
 end;
end;

function BMPos(const aSource, aFind: Pointer; const aSourceLen, aFindLen: Integer; var JumpTable: TBMJumpTable): Pointer;
var
 LastPos: Pointer;
begin
 LastPos := Pointer(Integer(aSource) + aSourceLen - 1);
 asm
       push    ESI
       push    EDI
       push    EBX
       mov     EAX, aFindLen
       mov     ESI, aSource
       lea     ESI, ESI + EAX - 1
       std
       mov     EBX, JumpTable
@@comparetext:
       cmp     ESI, LastPos
       jg      @@NotFound
       mov     EAX, aFindLen
       mov     EDI, aFind
       mov     ECX, EAX
       push    ESI //Remember where we are
       lea     EDI, EDI + EAX - 1
       xor     EAX, EAX
@@CompareNext:
       mov     al, [ESI]
       cmp     al, [EDI]
       jne     @@LookAhead
       lea     ESI, ESI - 1
       lea     EDI, EDI - 1
       dec     ECX
       jz      @@Found
       jmp     @@CompareNext
@@LookAhead:
       //Look up the char in our Jump Table
       pop     ESI
       mov     al, [ESI]
       mov     EAX, [EBX + EAX * 4]
       lea     ESI, ESI + EAX
       jmp     @@CompareText
@@NotFound:
       mov     Result, 0
       jmp     @@TheEnd
@@Found:
       pop     EDI //We are just popping, we don't need the value
       inc     ESI
       mov     Result, ESI
@@TheEnd:
       cld
       pop     EBX
       pop     EDI
       pop     ESI
  end;
end;

function BMPosNoCase(const aSource, aFind: Pointer; const aSourceLen, aFindLen: Integer; var JumpTable: TBMJumpTable): Pointer;
var
 LastPos: Pointer;
begin
 LastPos := Pointer(Integer(aSource) + aSourceLen - 1);
 asm
       push    ESI
       push    EDI
       push    EBX
       mov     EAX, aFindLen
       mov     ESI, aSource 
       lea     ESI, ESI + EAX - 1
       std
       mov     EDX, GUpcaseLUT
@@comparetext:
       cmp     ESI, LastPos
       jg      @@NotFound
       mov     EAX, aFindLen
       mov     EDI, aFind 
       push    ESI //Remember where we are
       mov     ECX, EAX
       lea     EDI, EDI + EAX - 1
       xor     EAX, EAX
@@CompareNext:
       mov     al, [ESI]
       mov     bl, [EDX + EAX]
       mov     al, [EDI]
       cmp     bl, [EDX + EAX]
       jne     @@LookAhead
       lea     ESI, ESI - 1
       lea     EDI, EDI - 1
       dec     ECX
       jz      @@Found
       jmp     @@CompareNext 
@@LookAhead:
       //Look up the char in our Jump Table
       pop     ESI
       mov     EBX, JumpTable
       mov     al, [ESI]
       mov     al, [EDX + EAX]
       mov     EAX, [EBX + EAX * 4]
       lea     ESI, ESI + EAX
       jmp     @@CompareText
@@NotFound:
       mov     Result, 0
       jmp     @@TheEnd
@@Found:
       pop     EDI //We are just popping, we don't need the value
       inc     ESI 
       mov     Result, ESI
@@TheEnd:
       cld
       pop     EBX
       pop     EDI
       pop     ESI
 end;
end;

//NOTE : FastCharPos and FastCharPosNoCase do not require you to pass the length
//       of the string, this was only done in FastPos and FastPosNoCase because
//       they are used by FastReplace many times over, thus saving a LENGTH()
//       operation each time.  I can't see you using these two routines for the
//       same purposes so I didn't do that this time !
function FastCharPos(const aSource : string; const C: Char; StartPos : Integer) : Integer; 
var
  L                           : Integer;
begin
 //If this assert failed, it is because you passed 0 for StartPos, lowest value is 1 !!
  Assert(StartPos > 0);
  Result := 0;
  L := Length(aSource);
  if L = 0 then exit;
  if StartPos > L then exit;
  Dec(StartPos);
 asm
     PUSH EDI                 //Preserve this register
     mov  EDI, aSource        //Point EDI at aSource
     add  EDI, StartPos
     mov  ECX, L              //Make a note of how many chars to search through
     sub  ECX, StartPos
     mov  AL,  C              //and which char we want
   @Loop:
     cmp  Al, [EDI]           //compare it against the SourceString
     jz   @Found
     inc  EDI
     dec  ECX
     jnz  @Loop
     jmp  @NotFound
   @Found:
     sub  EDI, aSource        //EDI has been incremented, so EDI-OrigAdress = Char pos !
     inc  EDI
     mov  Result,   EDI
   @NotFound:
     POP  EDI
  end;
end;

function FastCharPosNoCase(const aSource : string; C: Char; StartPos : Integer) : Integer;
var
  L                           : Integer;
begin
  Result := 0;
  L := Length(aSource);
  if L = 0 then exit;
  if StartPos > L then exit;
  Dec(StartPos);
  if StartPos < 0 then StartPos := 0;
 asm
     PUSH EDI                 //Preserve this register
     PUSH EBX
     mov  EDX, GUpcaseLUT
     mov  EDI, aSource        //Point EDI at aSource
     add  EDI, StartPos
     mov  ECX, L              //Make a note of how many chars to search through
     sub  ECX, StartPos
     xor  EBX, EBX
     mov  BL,  C
     mov  AL, [EDX+EBX]
   @Loop:
     mov  BL, [EDI]
     inc  EDI
     cmp  Al, [EDX+EBX]
     jz   @Found
     dec  ECX
     jnz  @Loop
     jmp  @NotFound
   @Found:
     sub  EDI, aSource        //EDI has been incremented, so EDI-OrigAdress = Char pos !
     mov  Result,   EDI
   @NotFound:
     POP  EBX
     POP  EDI
 end;
end;

//The first thing to note here is that I am passing the SourceLength and FindLength
//As neither Source or Find will alter at any point during FastReplace there is
//no need to call the LENGTH subroutine each time !
function FastPos(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer; 
var
  JumpTable: TBMJumpTable;
begin
  //If this assert failed, it is because you passed 0 for StartPos, lowest value is 1 !!
  Assert(StartPos > 0);
  if aFindLen < 1 then begin
    Result := 0;
    exit;
  end;
  if aFindLen > aSourceLen then begin
    Result := 0;
    exit;
  end;
  MakeBMTable(PChar(aFindString), aFindLen, JumpTable);
  Result := Integer(BMPos(PChar(aSourceString) + (StartPos - 1), PChar(aFindString),aSourceLen - (StartPos-1), aFindLen, JumpTable));
  if Result > 0 then
    Result := Result - Integer(@aSourceString[1]) +1;
end;

function FastPosNoCase(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
var
  JumpTable: TBMJumpTable;
begin
 //If this assert failed, it is because you passed 0 for StartPos, lowest value is 1 !!
  Assert(StartPos > 0);
  if aFindLen < 1 then begin
    Result := 0;
    exit;
  end;
  if aFindLen > aSourceLen then begin
    Result := 0;
    exit;
  end;
  MakeBMTableNoCase(PChar(AFindString), aFindLen, JumpTable);
  Result := Integer(BMPosNoCase(PChar(aSourceString) + (StartPos - 1), PChar(aFindString),aSourceLen - (StartPos-1), aFindLen, JumpTable));
  if Result > 0 then
    Result := Result - Integer(@aSourceString[1]) +1;
end;

function FastPosBack(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
var
  SourceLen : Integer;
begin
  if aFindLen < 1 then begin
    Result := 0;
    exit;
  end;
  if aFindLen > aSourceLen then begin
    Result := 0;
    exit;
  end;
  if (StartPos = 0) or  (StartPos + aFindLen > aSourceLen) then
    SourceLen := aSourceLen - (aFindLen-1)
  else
    SourceLen := StartPos;
  asm
         push ESI
         push EDI
         push EBX
         mov EDI, aSourceString
         add EDI, SourceLen
         Dec EDI
         mov ESI, aFindString
         mov ECX, SourceLen
         Mov  Al, [ESI]
   @ScaSB:
         cmp  Al, [EDI]
         jne  @NextChar
   @CompareStrings:
         mov  EBX, aFindLen
         dec  EBX
         jz   @FullMatch
   @CompareNext:
         mov  Ah, [ESI+EBX]
         cmp  Ah, [EDI+EBX]
         Jnz  @NextChar
   @Matches:
         Dec  EBX
         Jnz  @CompareNext
   @FullMatch:
         mov  EAX, EDI
         sub  EAX, aSourceString
         inc  EAX
         mov  Result, EAX
         jmp  @TheEnd
   @NextChar:
         dec  EDI
         dec  ECX
         jnz  @ScaSB
         mov  Result,0
   @TheEnd:
         pop  EBX
         pop  EDI
         pop  ESI
  end;
end;

function FastPosBackNoCase(const aSourceString, aFindString : string; const aSourceLen, aFindLen, StartPos : Integer) : Integer;
var
  SourceLen : Integer;
begin
  if aFindLen < 1 then begin
    Result := 0;
    exit;
  end;
  if aFindLen > aSourceLen then begin
    Result := 0;
    exit;
  end;
  if (StartPos = 0) or  (StartPos + aFindLen > aSourceLen) then
    SourceLen := aSourceLen - (aFindLen-1)
  else
    SourceLen := StartPos;
  asm
         push ESI
         push EDI
         push EBX
         mov  EDI, aSourceString
         add  EDI, SourceLen
         Dec  EDI
         mov  ESI, aFindString
         mov  ECX, SourceLen
         mov  EDX, GUpcaseLUT
         xor  EBX, EBX
         mov  Bl, [ESI]
         mov  Al, [EDX+EBX]
   @ScaSB:
         mov  Bl, [EDI]
         cmp  Al, [EDX+EBX]
         jne  @NextChar
   @CompareStrings:
         PUSH ECX
         mov  ECX, aFindLen
         dec  ECX
         jz   @FullMatch
   @CompareNext:
         mov  Bl, [ESI+ECX]
         mov  Ah, [EDX+EBX]
         mov  Bl, [EDI+ECX]
         cmp  Ah, [EDX+EBX]
         Jz   @Matches
   //Go back to findind the first char
         POP  ECX
         Jmp  @NextChar
   @Matches:
         Dec  ECX
         Jnz  @CompareNext
   @FullMatch:
         POP  ECX
         mov  EAX, EDI
         sub  EAX, aSourceString
         inc  EAX
         mov  Result, EAX
         jmp  @TheEnd
   @NextChar:
         dec  EDI
         dec  ECX
         jnz  @ScaSB
         mov  Result,0
   @TheEnd:
         pop  EBX
         pop  EDI
         pop  ESI
  end;
end;

//My move is not as fast as MOVE when source and destination are both
//DWord aligned, but certainly faster when they are not.
//As we are moving characters in a string, it is not very likely at all that
//both source and destination are DWord aligned, so moving bytes avoids the
//cycle penality of reading/writing DWords across physical boundaries 
procedure FastCharMove(const Source; var Dest; Count : Integer);
asm
//Note:  When this function is called, delphi passes the parameters as follows
//ECX = Count
//EAX = Const Source
//EDX = Var Dest
       //If no bytes to copy, just quit altogether, no point pushing registers
       cmp   ECX,0
       Je    @JustQuit
       //Preserve the critical delphi registers
       push  ESI
       push  EDI
       //move Source into ESI  (generally the SOURCE register)
       //move Dest into EDI (generally the DEST register for string commands)
       //This may not actually be neccessary, as I am not using MOVsb etc
       //I may be able just to use EAX and EDX, there may be a penalty for
       //not using ESI, EDI but I doubt it, this is another thing worth trying !
       mov   ESI, EAX
       mov   EDI, EDX
       //The following loop is the same as repNZ MovSB, but oddly quicker ! 
   @Loop:
       //Get the source byte
       Mov   AL, [ESI]
       //Point to next byte
       Inc   ESI
       //Put it into the Dest
       mov   [EDI], AL
       //Point dest to next position 
       Inc   EDI
       //Dec ECX to note how many we have left to copy
       Dec   ECX
       //If ECX <> 0 then loop
       Jnz   @Loop
       //Another optimization note.
       //Many people like to do this 
       //Mov AL, [ESI]
       //Mov [EDI], Al
       //Inc ESI
       //Inc ESI
       //There is a hidden problem here, I wont go into too much detail, but
       //the pentium can continue processing instructions while it is still 
       //working out the result of INC ESI or INC EDI
       //(almost like a multithreaded CPU)
       //if, however, you go to use them while they are still being calculated
       //the processor will stop until they are calculated (a penalty)
       //Therefore I alter ESI and EDI as far in advance as possible of using them
       //Pop the critical Delphi registers that we have altered
       pop   EDI
       pop   ESI
   @JustQuit:
end;

function FastAnsiReplace(const S, OldPattern, NewPattern: string;
 Flags: TReplaceFlags): string;
var
  BufferSize, BytesWritten: Integer;
  SourceString, FindString: string;
  ResultPChar: PChar;
  FindPChar, ReplacePChar: PChar; 
  SPChar, SourceStringPChar, PrevSourceStringPChar: PChar;
  FinalSourceMarker: PChar;
  SourceLength, FindLength, ReplaceLength, CopySize: Integer;
  FinalSourcePosition: Integer;
begin
 //Set up string lengths 
  BytesWritten := 0;
  SourceLength := Length(S);
  FindLength := Length(OldPattern);
  ReplaceLength := Length(NewPattern);
  //Quick exit
  if (SourceLength = 0) or (FindLength = 0) or
   (FindLength > SourceLength) then
  begin
    Result := S;
    Exit;
  end;
 //Set up the source string and find string
  if rfIgnoreCase in Flags then
  begin
    SourceString := AnsiUpperCase(S);
    FindString := AnsiUpperCase(OldPattern);
  end else
  begin
    SourceString := S;
    FindString := OldPattern;
  end;
 //Set up the result buffer size and pointers
  try
    if ReplaceLength <= FindLength then
     //Result cannot be larger, only same size or smaller
     BufferSize := SourceLength
    else
     //Assume a source string made entired of the sub string
     BufferSize := (SourceLength * ReplaceLength) div
    FindLength;
    //10 times is okay for starters. We don't want to
    //go allocating much more than we need.
    if BufferSize > (SourceLength * 10) then
      BufferSize := SourceLength * 10;
  except
    //Oops, integer overflow! Better start with a string
    //of the same size as the source.
    BufferSize := SourceLength;
  end;
  SetLength(Result, BufferSize);
  ResultPChar := @Result[1];
  //Set up the pointers to S and SourceString
  SPChar := @S[1];
  SourceStringPChar := @SourceString[1];
  PrevSourceStringPChar := SourceStringPChar;
  FinalSourceMarker := @SourceString[SourceLength - (FindLength - 1)];
  //Set up the pointer to FindString
  FindPChar := @FindString[1];
  //Set the pointer to ReplaceString
  if ReplaceLength > 0 then
    ReplacePChar := @NewPattern[1]
  else
    ReplacePChar := nil;
  //Replace routine
  repeat
   //Find the sub string
  SourceStringPChar := AnsiStrPos(PrevSourceStringPChar,
  FindPChar);
  if SourceStringPChar = nil then Break;
  //How many characters do we need to copy before
  //the string occurs
  CopySize := SourceStringPChar - PrevSourceStringPChar;
  //Check we have enough space in our Result buffer
  if CopySize + ReplaceLength > BufferSize - BytesWritten then
  begin
    BufferSize := Trunc((BytesWritten + CopySize + ReplaceLength) * cDeltaSize);
    SetLength(Result, BufferSize);
    ResultPChar := @Result[BytesWritten + 1];
  end;
  //Copy the preceeding characters to our result buffer
  Move(SPChar^, ResultPChar^, CopySize);
  Inc(BytesWritten, CopySize);
  //Advance the copy position of S
  Inc(SPChar, CopySize + FindLength);
  //Advance the Result pointer
  Inc(ResultPChar, CopySize);
  //Copy the replace string into the Result buffer
  if Assigned(ReplacePChar) then
  begin
    Move(ReplacePChar^, ResultPChar^, ReplaceLength);
    Inc(ResultPChar, ReplaceLength);
    Inc(BytesWritten, ReplaceLength);
  end;
  //Fake delete the start of the source string
  PrevSourceStringPChar := SourceStringPChar + FindLength;
  until (PrevSourceStringPChar > FinalSourceMarker) or
  not (rfReplaceAll in Flags);
  FinalSourcePosition := Integer(SPChar - @S[1]);
  CopySize := SourceLength - FinalSourcePosition;
  SetLength(Result, BytesWritten + CopySize);
  if CopySize > 0 then
    Move(SPChar^, Result[BytesWritten + 1], CopySize);
end;

function FastReplace(const aSourceString : string; const aFindString, aReplaceString : string;
  CaseSensitive : Boolean = False) : string;
var
  PResult                     : PChar;
  PReplace                    : PChar; 
  PSource                     : PChar;
  PFind                       : PChar;
  PPosition                   : PChar;
  CurrentPos,
  BytesUsed,
  lResult,
  lReplace,
  lSource,
  lFind                       : Integer; 
  Find                        : TFastPosProc;
  CopySize                    : Integer;
  JumpTable                   : TBMJumpTable;
begin
  LSource := Length(aSourceString);
  if LSource = 0 then begin
    Result := aSourceString;
    exit;
  end;
  PSource := @aSourceString[1];
  LFind := Length(aFindString);
  if LFind = 0 then exit;
  PFind := @aFindString[1];
  LReplace := Length(aReplaceString);
 //Here we may get an Integer Overflow, or OutOfMemory, if so, we use a Delta
  try
  if LReplace <= LFind then
    SetLength(Result,lSource)
  else
    SetLength(Result, (LSource *LReplace) div  LFind);
  except
    SetLength(Result,0);
  end;
  LResult := Length(Result);
  if LResult = 0 then begin
    LResult := Trunc((LSource + LReplace) * cDeltaSize);
    SetLength(Result, LResult);
  end;

  PResult := @Result[1];

  if CaseSensitive then
  begin
    MakeBMTable(PChar(AFindString), lFind, JumpTable);
    Find := BMPos;
  end else
  begin
    MakeBMTableNoCase(PChar(AFindString), lFind, JumpTable);
    Find := BMPosNoCase;
  end;

  BytesUsed := 0;
  if LReplace > 0 then
  begin
    PReplace := @aReplaceString[1];
    repeat
      PPosition := Find(PSource,PFind,lSource, lFind, JumpTable);
      if PPosition = nil then break;
      CopySize := PPosition - PSource;
      Inc(BytesUsed, CopySize + LReplace);
      if BytesUsed >= LResult then
      begin
       //We have run out of space
        CurrentPos := Integer(PResult) - Integer(@Result[1]) +1;
        LResult := Trunc(LResult * cDeltaSize);
        SetLength(Result,LResult);
        PResult := @Result[CurrentPos];
      end;
      FastCharMove(PSource^,PResult^,CopySize);
      Dec(lSource,CopySize + LFind);
      Inc(PSource,CopySize + LFind);
      Inc(PResult,CopySize);
      FastCharMove(PReplace^,PResult^,LReplace);
      Inc(PResult,LReplace);
    until lSource < lFind;
 end else
 begin
   repeat
     PPosition := Find(PSource,PFind,lSource, lFind, JumpTable);
     if PPosition = nil then break;
     CopySize := PPosition - PSource;
     FastCharMove(PSource^,PResult^,CopySize);
     Dec(lSource,CopySize + LFind);
     Inc(PSource,CopySize + LFind);
     Inc(PResult,CopySize);
     Inc(BytesUsed, CopySize);
   until lSource < lFind;
 end;
 SetLength(Result, (PResult+LSource) - @Result[1]);
 if LSource > 0 then
   FastCharMove(PSource^, Result[BytesUsed + 1], LSource);
end;

function FastTagReplace(const SourceString, TagStart, TagEnd: string;
 FastTagReplaceProc: TFastTagReplaceProc; const UserData: Integer): string;
var
  TagStartPChar: PChar;
  TagEndPChar: PChar;
  SourceStringPChar: PChar; 
  TagStartFindPos: PChar;
  TagEndFindPos: PChar;
  TagStartLength: Integer;
  TagEndLength: Integer;
  DestPChar: PChar;
  FinalSourceMarkerStart: PChar;
  FinalSourceMarkerEnd: PChar;
  BytesWritten: Integer;
  BufferSize: Integer;
  CopySize: Integer;
  ReplaceString: string;
 procedure AddBuffer(const Buffer: Pointer; Size: Integer);
 begin
   if BytesWritten + Size > BufferSize then
   begin
     BufferSize := Trunc(BufferSize * cDeltaSize); 
     if BufferSize <= (BytesWritten + Size) then
       BufferSize := Trunc((BytesWritten + Size) * cDeltaSize);
     SetLength(Result, BufferSize);
     DestPChar := @Result[BytesWritten + 1];
   end;
   Inc(BytesWritten, Size);
   FastCharMove(Buffer^, DestPChar^, Size);
   DestPChar := DestPChar + Size;
 end;
begin
  Assert(Assigned(@FastTagReplaceProc));
  TagStartPChar := PChar(TagStart);
  TagEndPChar := PChar(TagEnd);
  if (SourceString = '') or (TagStart = '') or (TagEnd = '') then
  begin
    Result := SourceString;
    Exit;
  end;
  SourceStringPChar := PChar(SourceString);
  TagStartLength := Length(TagStart);
  TagEndLength := Length(TagEnd);
  FinalSourceMarkerEnd := SourceStringPChar + Length(SourceString) - TagEndLength;
  FinalSourceMarkerStart := FinalSourceMarkerEnd - TagStartLength;
  BytesWritten := 0;
  BufferSize := Length(SourceString);
  SetLength(Result, BufferSize);
  DestPChar := @Result[1];
  repeat
    TagStartFindPos := AnsiStrPos(SourceStringPChar, TagStartPChar);
    if (TagStartFindPos = nil) or (TagStartFindPos > FinalSourceMarkerStart) then Break;
    TagEndFindPos := AnsiStrPos(TagStartFindPos + TagStartLength, TagEndPChar);
    if (TagEndFindPos = nil) or (TagEndFindPos > FinalSourceMarkerEnd) then Break;
    CopySize := TagStartFindPos - SourceStringPChar;
    AddBuffer(SourceStringPChar, CopySize);
    CopySize := TagEndFindPos - (TagStartFindPos + TagStartLength);
    SetLength(ReplaceString, CopySize);
    if CopySize > 0 then
      Move((TagStartFindPos + TagStartLength)^, ReplaceString[1], CopySize);
    FastTagReplaceProc(ReplaceString, UserData);
    if Length(ReplaceString) > 0 then
      AddBuffer(@ReplaceString[1], Length(ReplaceString));
    SourceStringPChar := TagEndFindPos + TagEndLength;
  until SourceStringPChar > FinalSourceMarkerStart;
  CopySize := PChar(@SourceString[Length(SourceString)]) - (SourceStringPChar - 1);
  if CopySize > 0 then
    AddBuffer(SourceStringPChar, CopySize);
  SetLength(Result, BytesWritten);
end;

function SmartPos(const SearchStr,SourceStr : string;
                 const CaseSensitive : Boolean = TRUE;
                 const StartPos : Integer = 1;
                 const ForwardSearch : Boolean = TRUE) : Integer; 
begin
  Result := FastPos(SourceStr, SearchStr, Length(SourceStr), Length(SearchStr),StartPos);
 (*
 // NOTE:  When using StartPos, the returned value is absolute!
  if (CaseSensitive) then
    if (ForwardSearch) then
      Result:=
        FastPos(SourceStr,SearchStr,Length(SourceStr),Length(SearchStr),StartPos)
    else
      Result:=
        FastPosBack(SourceStr,SearchStr,Length(SourceStr),Length(SearchStr),StartPos)
  else
  if (ForwardSearch) then
    Result:=
      FastPosNoCase(SourceStr,SearchStr,Length(SourceStr),Length(SearchStr),StartPos)
  else
    Result:=
      FastPosBackNoCase(SourceStr,SearchStr,Length(SourceStr),Length(SearchStr),StartPos) *)
end;

//Returns X amount of chars from the right of a string
function RightStr(const aSourceString : string; Size : Integer) : string;
begin
  if Size > Length(aSourceString) then
    Result := aSourceString
  else
  begin
    SetLength(Result, Size);
    FastCharMove(aSourceString[Length(aSourceString)-(Size-1)],Result[1],Size);
  end;
end;

//Converts a typical HTML RRGGBB color to a TColor
function RGBToColor(aRGB : string) : TColor; 
begin
  if Length(aRGB) < 6 then raise EConvertError.Create('Not a valid RGB value');
  if aRGB[1] = '#' then aRGB := Copy(aRGB,2,Length(aRGB));
  if Length(aRGB) <> 6 then raise EConvertError.Create ('Not a valid RGB value');
  Result := HexToInt(aRGB);
  asm
    mov   EAX, Result
    BSwap EAX
    shr   EAX, 8
    mov   Result, EAX
  end;
end;

{Fechar um aplicativo sem perguntar se deseja "salvar o arquivo...etc"
Exemplo de como utilizar:
procedure TForm1.Button1Click(Sender: TObject);
begin
  KillTask('calc.exe'); // Notepad
end;
}
function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0; 
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do 
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName)) or
        (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), 
        FProcessEntry32.th32ProcessID), 0));
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function MacAddress: string;
var
  Lib: Cardinal;
  Func: function(GUID: PGUID): Longint; stdcall;
  GUID1, GUID2: TGUID;
begin
  Result := '';
  Lib := LoadLibrary('rpcrt4.dll');
  if Lib <> 0 then
  begin
    @Func := GetProcAddress(Lib, 'UuidCreateSequential');
    if Assigned(Func) then
    begin
      if (Func(@GUID1) = 0) and
     (Func(@GUID2) = 0) and
         ( GUID1.D4[2] = GUID2.D4[2]) and
         (GUID1.D4[3] = GUID2.D4[3]) and
         (GUID1.D4[4] = GUID2.D4[4]) and
         (GUID1.D4[5] = GUID2.D4[5]) and
         (GUID1.D4[6] = GUID2.D4[6]) and
         (GUID1.D4 [7] = GUID2.D4[7]) then
      begin
        Result := IntToHex(GUID1.D4[2], 2) + '-' +
          IntToHex(GUID1.D4[3], 2) + '-' +
          IntToHex(GUID1.D4[4], 2) + '-' +
          IntToHex( GUID1.D4[5], 2) + '-' +
          IntToHex(GUID1.D4[6], 2) + '-' +
          IntToHex(GUID1.D4[7], 2);
      end;
    end;
  end;
end;


(* Modos possveis:
  -> SCF_ALL 
  -> SCF_SELECTION
  -> SCF_WORD
  -> declaradas na unit RichEdit *)
  {
Para us-la, voc possui 3 alternativas:

Marcar texto selecionado: MarkRichEditText(RichEdit1, clRed, clLime, SCF_SELECTION);
Marcar texto inteiro: MarkRichEditText(RichEdit1, clBlack, clYellow, SCF_ALL);
Marcar palavra sob o cursor MarkRichEditText(RichEdit1, RichEdit1.Font.Color, clAqua, SCF_WORD);
}

procedure MarkRichEditText(RichEdit: TRichEdit; fgColor, bkColor: TColor; MarkMode: Integer);
var
  CharFormat: TCharFormat2;
begin
  //na marcao de palavra, na chamada a EM_SETCHARFORMAT deve ser
  //concatenado SCF_SELECTION ao parmetro SCF_WORD 
  if MarkMode = SCF_WORD then
    MarkMode := MarkMode or SCF_SELECTION;
  CharFormat.cbSize := SizeOf(CharFormat);
  CharFormat.dwMask := CFM_BACKCOLOR or CFM_COLOR;
  CharFormat.crBackColor := ColorToRGB(bkColor); 
  CharFormat.crTextColor := ColorToRGB(fgColor);
  SendMessage(RichEdit.handle, EM_SETCHARFORMAT, MarkMode, LongInt(@CharFormat));
end;


function CreateBitmapFromIcon(Icon: TIcon; BackColor: TColor): TBitmap;
var
  IWidth, IHeight: Integer;
begin
  IWidth := Icon.Width;
  IHeight := Icon.Height;
  Result := TBitmap.Create;
  try
    Result.Width := IWidth;
    Result.Height := IHeight;
    with Result.Canvas do begin
      Brush.Color := BackColor;
      FillRect(Rect(0, 0, IWidth, IHeight));
      Draw(0, 0, Icon);
    end;
    Result.TransparentColor := BackColor;
    Result.Transparent := True;
  except
    Result.Free;
    raise;
  end;
end;

function CreateIconFromBitmap(Bitmap: TBitmap; TransparentColor: TColor): TIcon;
begin
  with TImageList.CreateSize(Bitmap.Width, Bitmap.Height) do
  try
    if TransparentColor = clDefault then
      TransparentColor := Bitmap.TransparentColor;
    AllocBy := 1;
    AddMasked(Bitmap, TransparentColor);
    Result := TIcon.Create;
    try
      GetIcon(0, Result);
    except
      Result.Free;
      raise;
    end;
  finally
    Free;
  end;
end;

type
  THack = class(TCustomControl);

function LoadDLL(const LibName: string): THandle;
var
  ErrMode: Cardinal;
{$IFNDEF WIN32}
  P: array[0..255] of Char;
{$ENDIF}
begin
  ErrMode := SetErrorMode(SEM_NOOPENFILEERRORBOX);
{$IFDEF WIN32}
  Result := LoadLibrary(PChar(LibName));
{$ELSE}
  Result := LoadLibrary(StrPCopy(P, LibName));
{$ENDIF}
  SetErrorMode(ErrMode);
  if Result < HINSTANCE_ERROR then
{$IFDEF WIN32}
    Win32Check(False);
{$ELSE}
    raise EOutOfResources.CreateResFmt(SLoadLibError, [LibName]);
{$ENDIF}
end;

function RegisterServer(const ModuleName: string): Boolean;
{ RegisterServer procedure written by Vladimir Gaitanoff, 2:50/430.2 }
type
  TProc = procedure;
var
  Handle: THandle;
  DllRegServ: Pointer;
begin
  Result := False;
  Handle := LoadDLL(ModuleName);
  try
    DllRegServ := GetProcAddress(Handle, 'DllRegisterServer');
    if Assigned(DllRegServ) then begin
      TProc(DllRegServ);
      Result := True;
    end;
  finally
    FreeLibrary(Handle);
  end;
end;


procedure Delay(MSecs: Longint);
var
  FirstTickCount, Now: Longint;
begin
  FirstTickCount := GetTickCount;
  repeat
    Application.ProcessMessages;
    { allowing access to other controls, etc. }
    Now := GetTickCount;
  until (Now - FirstTickCount >= MSecs) or (Now < FirstTickCount);
end;

procedure FitRectToScreen(var Rect: TRect);
var
  X, Y, Delta: Integer;
begin
  X := GetSystemMetrics(SM_CXSCREEN);
  Y := GetSystemMetrics(SM_CYSCREEN);
  with Rect do begin
    if Right > X then begin
      Delta := Right - Left;
      Right := X;
      Left := Right - Delta;
    end;
    if Left < 0 then begin
      Delta := Right - Left;
      Left := 0;
      Right := Left + Delta;
    end;
    if Bottom > Y then begin
      Delta := Bottom - Top;
      Bottom := Y;
      Top := Bottom - Delta;
    end;
    if Top < 0 then begin
      Delta := Bottom - Top;
      Top := 0;
      Bottom := Top + Delta;
    end;
  end;
end;



procedure CenterControl(Control: TControl);
var
  X, Y: Integer;
begin
  X := Control.Left;
  Y := Control.Top;
  if Control is TForm then begin
    with Control do begin
      if (TForm(Control).FormStyle = fsMDIChild) and
        (Application.MainForm <> nil) then
      begin
        X := (Application.MainForm.ClientWidth - Width) div 2;
        Y := (Application.MainForm.ClientHeight - Height) div 2;
      end
      else begin
        X := (Screen.Width - Width) div 2;
        Y := (Screen.Height - Height) div 2;
      end;
    end;
  end
  else if Control.Parent <> nil then begin
    with Control do begin
      Parent.HandleNeeded;
      X := (Parent.ClientWidth - Width) div 2;
      Y := (Parent.ClientHeight - Height) div 2;
    end;
  end;
  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  with Control do SetBounds(X, Y, Width, Height);
end;


procedure CenterWindow(Wnd: HWnd);
var
  R: TRect;
begin
  GetWindowRect(Wnd, R);
  R := Rect((GetSystemMetrics(SM_CXSCREEN) - R.Right + R.Left) div 2,
    (GetSystemMetrics(SM_CYSCREEN) - R.Bottom + R.Top) div 2,
    R.Right - R.Left, R.Bottom - R.Top);
  FitRectToScreen(R);
  SetWindowPos(Wnd, 0, R.Left, R.Top, 0, 0, SWP_NOACTIVATE or
    SWP_NOSIZE or SWP_NOZORDER);
end;

procedure MergeForm(AControl: TWinControl; AForm: TForm; Align: TAlign;
  Show: Boolean);
var
  R: TRect;
  AutoScroll: Boolean;
begin
  AutoScroll := AForm.AutoScroll;
  AForm.Hide;
  THack(AForm).DestroyHandle;
  with AForm do begin
    BorderStyle := bsNone;
    BorderIcons := [];
    Parent := AControl;
  end;
  AControl.DisableAlign;
  try
    if Align <> alNone then AForm.Align := Align
    else begin
      R := AControl.ClientRect;
      AForm.SetBounds(R.Left + AForm.Left, R.Top + AForm.Top, AForm.Width,
        AForm.Height);
    end;
    AForm.AutoScroll := AutoScroll;
    AForm.Visible := Show;
  finally
    AControl.EnableAlign;
  end;
end;

function MakeVariant(const Values: array of Variant): Variant;
begin
  if High(Values) - Low(Values) > 1 then
    Result := VarArrayOf(Values)
  else if High(Values) - Low(Values) = 1 then
    Result := Values[Low(Values)]
  else Result := Null;
end;

function GetVersion: string;
var
  S         : String;
  n, i      : Integer;
  Buf       : PChar;
  Value     : PChar;
  hAux, Len : THandle;
begin
  Result := '';
  S := Application.ExeName;
  n := GetFileVersionInfoSize(PChar(S), hAux);
  if n > 0 then
    begin
    Buf := AllocMem(n);
    GetFileVersionInfo(PChar(S),0,n,Buf);
    if VerQueryValue(Buf,PChar('StringFileInfo\041604E4\FileVersion'), Pointer(Value), Len) then
      For i:= Length(Value) downto 1 do
        If Value[i]= '.' then
          Begin
            Result := 'Verso ' + Copy(Value, 1, i);
            Break;
          end;
    FreeMem(Buf,n);
    end;
end;

procedure ExtraiIconeDoExecESalvaEmIcoEBMP;
var
  bmp: TImage;
  fOpenDialog: TOpenDialog;
  fRenamedIcoFile, fRenamedBmpFile: string;
begin
  fOpenDialog := TOpenDialog.Create(nil);
  fOpenDialog.Filter := 'Arquivos Executveis (*.exe)|*.EXE';
  fOpenDialog.Options := [ofOverwritePrompt, ofFileMustExist, ofHideReadOnly];
  try
  if fOpenDialog.Execute then
  begin
    fRenamedIcoFile := ChangeFileExt(fOpenDialog.FileName,'.ico');
    ExtraiIconeDoPrograma(fOpenDialog.FileName, fRenamedIcoFile);
    bmp := TImage.Create(nil);
    bmp.Picture.Icon.LoadFromFile(fRenamedIcoFile);
    bmp.Picture.Bitmap := CreateBitmapFromIcon(bmp.Picture.Icon,clWindow);
    fRenamedBmpFile := ChangeFileExt(fRenamedIcoFile,'.bmp');
    bmp.Picture.SaveToFile(fRenamedBmpFile);
  end;
  finally
    bmp.Free;
    FreeAndNil(fOpenDialog);
  end;
  ShowMessage(Format(TrText('File created successfully: %s'), [fRenamedBmpFile]));
end;


procedure ExtraiBMPESalvaEmIcone;
var
  fOpenDialog: TOpenDialog;
  fRenamedIcoFile: string;
  bmp:  TBitmap;
//  icon: TIcon;
begin
  fOpenDialog := TOpenDialog.Create(nil);
  fOpenDialog.Filter := 'Arquivos Executveis (*.bmp)|*.BMP';
  fOpenDialog.Options := [ofOverwritePrompt, ofFileMustExist, ofHideReadOnly];
  try
  if fOpenDialog.Execute then
  begin
    fRenamedIcoFile := ChangeFileExt(fOpenDialog.FileName,'.ico');
    bmp := TBitmap.Create;
    bmp.LoadFromFile(fOpenDialog.FileName);
  //  icon := TIcon.Create;
   // icon.Handle := CreateIconFromBitmap(bmp, clBtnFace);   

    ExtraiIconeDoPrograma(fOpenDialog.FileName, fRenamedIcoFile);
  end;
  finally
    FreeAndNil(fOpenDialog);
    bmp.Free;
  end;
end;


function DiaDaSemana(data:TDate): string;
//I Retorna o dia da semana de uma data
//* DiaDaSemana(data:TDate): string;
//*
//* Entrada: data ==> data
//*
//* Sada  : dia da semanha
//F
var diasemana: integer;
    strdiasemana: string;
begin

    diasemana:=dayofweek(data);
    case diasemana of
      1:strdiasemana:='Domingo';
      2:strdiasemana:='Segunda-feira';
      3:strdiasemana:='Tera-feira';
      4:strdiasemana:='Quarta-feira';
      5:strdiasemana:='Quinta-feira';
      6:strdiasemana:='Sexta-feira';
      7:strdiasemana:='Sbado';
    end;

    DiaDaSemana:= strdiasemana;
end;


function Gauss(ano: integer): string;
var
  Domingo_de_Pascoa : string;
  a, b, c, d, e, M, n : integer;
begin
  Case Ano of
    1582..1699:
    begin
      M := 22;
      n := 2;
    end;
    1700..1799:
    begin
      M := 23;
      n := 3;
    end;
    1800..1899:
    begin
      M := 24;
      n := 4;
    end;
    1900..2099:
    begin
      M := 24;
      n := 5;
    end;
    Else
    begin
      Gauss := 'Erro: Somente at o ano 2099!';
      exit;
    end;
  end;

  a:= Ano Mod 4;
  b:= Ano Mod 7;
  c:= Ano Mod 19;
  d:= (19 * c + M) Mod 30;
  e:= (2 * a + 4 * b + 6 * d + n) Mod 7;

  If (22 + d + e) > 31 Then
    Domingo_de_Pascoa := IntToStr(d + e - 9) + '/' + '04/' + Trim(IntToStr(Ano))
  Else
    Domingo_de_Pascoa := IntToStr(22 + d + e) + '/' + '03/' + Trim(IntToStr(Ano));

  Gauss:= FormatDateTime('dd/mm/yyyy', StrToDate( Domingo_de_Pascoa ) );
end;

function vFeriados(Ano: integer): FERIADOS;
var
  Datas : FERIADOS;
  Domingo_de_Pascoa : string;
  Sexta_Feira_da_Paixao : String;
  Terca_Feira_de_Carnaval : string;
  Quarta_Feira_de_Cinzas : string;
  Corpus_Christi : string;

begin
  Domingo_de_Pascoa      := Gauss(Ano);
  Sexta_Feira_da_Paixao  := FormatDateTime('dd/mm/yyyy', StrToDate( Domingo_de_Pascoa ) - 2 );
  Terca_Feira_de_Carnaval:= FormatDateTime('dd/mm/yyyy', StrToDate( Domingo_de_Pascoa ) - 47 );
  Quarta_Feira_de_Cinzas := FormatDateTime('dd/mm/yyyy', StrToDate( Domingo_de_Pascoa )- 46 );
  Corpus_Christi         := FormatDateTime('dd/mm/yyyy', StrToDate( Domingo_de_Pascoa )+ 60 );

  Datas.Ano := IntToStr(Ano);

  Datas.Data[1].nData := '01/01/' + IntToStr(Ano);
  Datas.Data[1].cData := 'Dia Mundial da Paz';
  Datas.Data[2].nData := Terca_Feira_de_Carnaval;
  Datas.Data[2].cData := 'Terca de Carnaval';
  Datas.Data[3].nData := Quarta_Feira_de_Cinzas;
  Datas.Data[3].cData := 'Quarta Feira de Cinzas';
  Datas.Data[4].nData := Sexta_Feira_da_Paixao;
  Datas.Data[4].cData := 'Sexta-Feira da Paixo';
  Datas.Data[5].nData := Domingo_de_Pascoa;
  Datas.Data[5].cData := 'Domingo de Pscoa';
  Datas.Data[6].nData := '21/04/' + IntToStr(Ano);
  Datas.Data[6].cData := 'Tiradentes';
  Datas.Data[7].nData := '01/05/' + IntToStr(Ano);
  Datas.Data[7].cData := 'Dia do Trabalho';
  Datas.Data[8].nData := Corpus_Christi;
  Datas.Data[8].cData := 'Corpus Christi';
  Datas.Data[9].nData := '07/09/' + IntToStr(Ano);
  Datas.Data[9].cData := 'Indep. do Brasil';
  Datas.Data[10].nData:= '12/10/' + IntToStr(Ano);
  Datas.Data[10].cData:= 'N. S. Aparecida';
  Datas.Data[11].nData:= '02/11/' + IntToStr(Ano);
  Datas.Data[11].cData:= 'Finados';
  Datas.Data[12].nData:= '15/11/' + IntToStr(Ano);
  Datas.Data[12].cData:= 'Proclamao da Rep.';
  Datas.Data[13].nData:= '30/11/' + IntToStr(Ano);
  Datas.Data[13].cData:= 'Dia do Evanglico';
  Datas.Data[14].nData:= '25/12/' + IntToStr(Ano);
  Datas.Data[14].cData:= 'Natal';

  vFeriados := Datas;
end;



{
Para us-la, voc precisa passar o Canvas de destino, ou seja,
onde seu texto ser desenhado.
Qualquer componente que possua a propriedade Canvas poder ser utilizado para tal,
como o prprio form, e at um TImage, que nos permitir salvar a imagem. Ex: 
No Form:

  ConvTextOut(Canvas, Edit1.Text, 10, 70, 0);
No TImage:

  ConvTextOut(Image1.Canvas, Edit1.Text, 20, 10,
}
procedure ConvTextOut(CV: TCanvas; const sText: String; x, y, angle:integer);
var
  LogFont: TLogFont;
  SaveFont: TFont;
begin
  SaveFont := TFont.Create ;
  SaveFont.Assign(CV.Font);
  GetObject(SaveFont.Handle, sizeof(TLogFont), @LogFont);
  with LogFont do
  begin
    lfEscapement := angle *10;
    lfPitchAndFamily := FIXED_PITCH or FF_DONTCARE;
  end;
  CV.Font.Handle := CreateFontIndirect(LogFont);
  SetBkMode(CV.Handle, TRANSPARENT);
  CV.TextOut(x, y, sText);
  CV.Font.Assign(SaveFont);
  SaveFont.Free;
end;

procedure SendToOpenOffice(aDataSet: TDataSet);
var
  OpenDesktop, Calc, Sheets, Sheet, oBorda, oLinBorda : Variant;
  Connect, OpenOffice : Variant;
  i : Integer; // Coluna
  j : Integer; // Linha
begin
  Screen.Cursor      := crSQLWait;
  aDataset.Open;
  aDataset.Last;

  // Cria o link OLE com o OpenOffice
  if VarIsEmpty(OpenOffice) then
    OpenOffice := CreateOleObject('com.sun.star.ServiceManager');
  Connect := not (VarIsEmpty(OpenOffice) or VarIsNull(OpenOffice));

  // Inicia o Calc
  OpenDesktop := OpenOffice.CreateInstance('com.sun.star.frame.Desktop');
  Calc        := OpenDesktop.LoadComponentFromURL('private:factory/scalc', '_blank', 0, VarArrayCreate([0, - 1], varVariant));
  Sheets      := Calc.Sheets;
  Sheet       := Sheets.getByIndex(0);
  oBorda      := Sheet.getPropertyValue('TableBorder');
  oLinBorda   := Sheet.getPropertyValue('TopBorder');
  // define a espessura da borda
  oLinBorda.OuterLineWidth := 30;

   // Cria linha de cabealho
  i := 0;
  while i <= aDataset.FieldCount - 1 do
  begin
    Sheet.getCellByPosition(i,0).setString(aDataset.Fields[i].FieldName);
    i := i + 1;
  end;

   // Preenche a planilha
  j := 1;
  aDataset.First;
  while not aDataset.Eof do
  begin
    i := 0;
    while i <= aDataset.FieldCount - 1 do
    begin
      if aDataset.Fields[i].DataType in [ftBCD, ftSmallint, ftInteger, ftLargeint] then
        Sheet.getCellByPosition(i,j).SetValue(aDataset.Fields[i].AsString)
      else if aDataset.Fields[i].DataType in [ftDateTime] then
      begin
        Sheet.GetCellByPosition(i,j).setPropertyValue('NumberFormat',51);
        Sheet.getCellByPosition(i,j).Setvalue(strtodatetime( aDataset.Fields[i].Value));
      end
      else Sheet.getCellByPosition(i,j).SetString(aDataset.Fields[i].AsString);

    {  Sheet.GetCellByPosition(i,j).setPropertyValue('TopBorder', oLinBorda);
      Sheet.GetCellByPosition(i,j).setPropertyValue('RightBorder', oLinBorda);
      Sheet.GetCellByPosition(i,j).setPropertyValue('LeftBorder', oLinBorda);
      Sheet.GetCellByPosition(i,j).setPropertyValue('BottomBorder', oLinBorda);   }
      i := i + 1;
      end;
    aDataset.Next;
    j := j + 1;
  end;

{  for i := 0 to aDataSet.FieldCount - 1 do
  begin
    Sheet.GetCellByPosition(i,0).setPropertyValue('HoriJustify', 1);   // Centraliza na Clula
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharHeight', 12);   // Tamanho de fonte
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharColor', 32768); // Cor da fonte
    Sheet.GetCellByPosition(i,0).setPropertyValue('CellBackColor', 65535);  // Cor de fundo da Clula
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharWeight',200);    // Texto em negrito
  end;
}
  Screen.Cursor      := crDefault;
   // Desconecta o OpenOffice
  OpenOffice         := Unassigned;
//  end;
end;



procedure ExportaStringGridBrOffice(const FStringGrid: TStringGrid);
var
  OpenDesktop, Calc, Sheets, Sheet, oBorda, oLinBorda: Variant;
  Connect, OpenOffice{, Valor} : Variant;
  i : Integer; // Coluna
  k : Integer; // Linha
begin
  Screen.Cursor      := crSQLWait;
  try

  // Cria o link OLE com o OpenOffice
  if VarIsEmpty(OpenOffice) then
    OpenOffice := CreateOleObject('com.sun.star.ServiceManager');
  Connect := not (VarIsEmpty(OpenOffice) or VarIsNull(OpenOffice));

  // Inicia o Calc
  OpenDesktop := OpenOffice.CreateInstance('com.sun.star.frame.Desktop');
  Calc        := OpenDesktop.LoadComponentFromURL('private:factory/scalc', '_blank', 0, VarArrayCreate([0, - 1], varVariant));
  Sheets      := Calc.Sheets;
  Sheet       := Sheets.getByIndex(0);

  for i := 0 to FStringGrid.ColCount - 1 do
    for k := 0 to FStringGrid.RowCount -1 do
    begin
      if IsNumber(FStringGrid.Cells[i,k]) then Sheet.getCellByPosition(i,k).SetValue(FStringGrid.Cells[i,k])
      else if IsValidDate(FStringGrid.Cells[i,k]) then
      begin
        Sheet.GetCellByPosition(i,k).setPropertyValue('NumberFormat',51);
        Sheet.getCellByPosition(i,k).Setvalue(strtodatetime(FStringGrid.Cells[i,k]));
      end
      else Sheet.getCellByPosition(i,k).SetString(FStringGrid.Cells[i,k]);
    end;

  oBorda := Sheet.getPropertyValue('TableBorder');
  oLinBorda := Sheet.getPropertyValue('TopBorder');

  // define a espessura da borda
  oLinBorda.OuterLineWidth := 30;

  // coloca borda nas celulas selecionadas
  for i := 0 to FStringGrid.ColCount - 1 do
  begin
    for k := 0 to FStringGrid.RowCount -1 do
    begin
      Sheet.GetCellByPosition(i,k).setPropertyValue('TopBorder', oLinBorda);
      Sheet.GetCellByPosition(i,k).setPropertyValue('RightBorder', oLinBorda);
      Sheet.GetCellByPosition(i,k).setPropertyValue('LeftBorder', oLinBorda);
      Sheet.GetCellByPosition(i,k).setPropertyValue('BottomBorder', oLinBorda);
    end;
  end;

  for i := 0 to FStringGrid.ColCount - 1 do
  begin
    Sheet.GetCellByPosition(i,0).setPropertyValue('HoriJustify', 2);   // Centraliza na Clula
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharHeight', 12);   // Tamanho de fonte
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharColor', 32768); // Cor da fonte
    Sheet.GetCellByPosition(i,0).setPropertyValue('CellBackColor', 65535);  // Cor de fundo da Clula
    Sheet.GetCellByPosition(i,0).setPropertyValue('CharWeight',200);    // Texto em negrito
  end;

  finally
    Screen.Cursor      := crDefault;
    // Desconecta o OpenOffice
    OpenOffice         := Unassigned;
  end;
end;

{Function sgml2win(text : String) : String;
begin
 text := stringreplaceall (text,'&aacute;','');
 text := stringreplaceall (text,'&Aacute;','');
 text := stringreplaceall (text,'&aelig;','');
 text := stringreplaceall (text,'&Aelig;','');
 text := stringreplaceall (text,'&agrave;','');
 text := stringreplaceall (text,'&Agrave;','');
 text := stringreplaceall (text,'&aring;','');
 text := stringreplaceall (text,'&Aring;','');
 text := stringreplaceall (text,'&auml;','');
 text := stringreplaceall (text,'&Auml;','');
 text := stringreplaceall (text,'&Acirc;' ,'');
 text := stringreplaceall (text,'&acirc;' ,'');
 text := stringreplaceall (text,'&atilde;','');
 text := stringreplaceall (text,'&Atilde;','');
 text := stringreplaceall (text,'&ccedil;','');
 text := stringreplaceall (text,'&Ccedil;','');
 text := stringreplaceall (text,'&eacute;','');
 text := stringreplaceall (text,'&Eacute;','');
 text := stringreplaceall (text,'&egrave;','');
 text := stringreplaceall (text,'&Egrave;','');
 text := stringreplaceall (text,'&ecirc;' ,'');
 text := stringreplaceall (text,'&Ecirc;' ,'');
 text := stringreplaceall (text,'&euml;'  ,'');
 text := stringreplaceall (text,'&Euml;'  ,'');
 text := stringreplaceall (text,'&icirc;' ,'');
 text := stringreplaceall (text,'&Icirc;' ,'');
 text := stringreplaceall (text,'&iacute;','');
 text := stringreplaceall (text,'&Iacute;','');
 text := stringreplaceall (text,'&igrave;','');
 text := stringreplaceall (text,'&Igrave;','');
 text := stringreplaceall (text,'&iuml;'  ,'');
 text := stringreplaceall (text,'&Iuml;'  ,'');
 text := stringreplaceall (text,'&ntilde;','');
 text := stringreplaceall (text,'&Ntilde;','');
 text := stringreplaceall (text,'&ograve;','');
 text := stringreplaceall (text,'&Ograve;','');
 text := stringreplaceall (text,'&oacute;','');
 text := stringreplaceall (text,'&Oacute;','');
 text := stringreplaceall (text,'&ouml;','');
 text := stringreplaceall (text,'&Ouml;','');
 text := stringreplaceall (text,'&oslash;','');
 text := stringreplaceall (text,'&Oslash;','');
 text := stringreplaceall (text,'&Ocirc;' ,'');
 text := stringreplaceall (text,'&ocirc;' ,'');
 text := stringreplaceall (text,'&otilde;','');
 text := stringreplaceall (text,'&Otilde;','');
 text := stringreplaceall (text,'&uuml;','');
 text := stringreplaceall (text,'&Uuml;','');
 text := stringreplaceall (text,'&uacute;','');
 text := stringreplaceall (text,'&Uacute;','');
 text := stringreplaceall (text,'&ucirc;' ,'');
 text := stringreplaceall (text,'&Ucirc;' ,'');
 text := stringreplaceall (text,'&Ugrave;','');
 text := stringreplaceall (text,'&ugrave;','');
 text := stringreplaceall (text,'&yacute;','');
 text := stringreplaceall (text,'&Yacute;','');
 text := stringreplaceall (text,'&yuml;'  ,'');
 text := stringreplaceall (text,'&nbsp;','|');
 text := stringreplaceall (text,'&amp;','&');
 result := text;
End;
}
Function WordCount(str: string) : integer;
var
  count : integer;
  i : integer;
  len : integer;
begin
  len := length(str);
  count := 0;
  i := 1;
  while i <= len do
  begin
    while ((i <= len) and ((str[i] = #32) or (str[i] = #9))) do inc(i);
      if i <= len then inc(count);
      while ((i <= len) and ((str[i] <> #32) and (str[i] <> #9) and (Str[i] <> ';'))) do inc(i);
  end;
  Result := count;
end;


function ConvertHTMLSpecialChars(const S: string; const pAccents: boolean = true): string;
const
  cHTMLReplaceWords: array[0..61] of array[0..1] of string = (('&nbsp;', ' '),
    ('&amp;'   ,'&'), ('&lt;'    ,'<'), ('&gt;'    ,'>'), ('&quot;'  ,'"'),
    ('&aacute;',''), ('&Agrave;',''), ('&aring;' ,''), ('&Aring;' ,''),
    ('&Aacute;',''), ('&aelig;' ,''), ('&Aelig;' ,''), ('&agrave;',''),
    ('&auml;'  ,''), ('&Auml;'  ,''), ('&Acirc;' ,''), ('&acirc;' ,''),
    ('&atilde;',''), ('&Atilde;',''), ('&ccedil;',''), ('&Ccedil;',''),
    ('&eacute;',''), ('&Eacute;',''), ('&egrave;',''), ('&Egrave;',''),
    ('&ecirc;' ,''), ('&Ecirc;' ,''), ('&euml;'  ,''), ('&Euml;'  ,''),
    ('&icirc;' ,''), ('&Icirc;' ,''), ('&iacute;',''), ('&Iacute;',''),
    ('&igrave;',''), ('&Igrave;',''), ('&iuml;'  ,''), ('&Iuml;'  ,''),
    ('&ntilde;',''), ('&Ntilde;',''), ('&ograve;',''), ('&Ograve;',''),
    ('&oacute;',''), ('&Oacute;',''), ('&ouml;'  ,''), ('&Ouml;'  ,''),
    ('&oslash;',''), ('&Oslash;',''), ('&Ocirc;' ,''), ('&ocirc;' ,''),
    ('&otilde;',''), ('&Otilde;',''), ('&uuml;'  ,''), ('&Uuml;'  ,''),
    ('&uacute;',''), ('&Uacute;',''), ('&ucirc;' ,''), ('&Ucirc;' ,''),
    ('&Ugrave;',''), ('&ugrave;',''), ('&yacute;',''), ('&Yacute;',''),
    ('&yuml;'  ,'')
    );
  cHighReplace: array[boolean] of integer = (4, High(cHTMLReplaceWords));
var
  I: integer;
begin
  Result := S;

  for I := 0 to cHighReplace[pAccents] do
    Result := FastReplace(Result, cHTMLReplaceWords[I, 0],
      cHTMLReplaceWords[I, 1]);
end;

{ TFilterFile }
{ Cria - mas no abre o arquivo }
constructor TFilterFile.Create
     (
       AName : String;
       ABufSize : Integer
     );
begin
  inherited Create;
  FFilename := AName;
  FBufferSize := ABufSize;
  FBytesInBuff := 0;
  FBuffIndx := 0;
  FFileMode := fioNotOpen;
  { Associa mas no abre }
  Assign (F, FFilename);
  { aloca memria para o buffer }
  GetMem (FBuffer, FBufferSize);
end;

{ Destroy -- fecha o arquivo (se aberto) e destri o objeto }
destructor TFilterFile.Destroy;
begin
 { se o arquivo estiver aberto, feche-o }
  if (FFileMode <> fioNotOpen) then
  begin
    Self.Close ;
  end;
 { se o buffer estiver sido alocado, libere-o }
  if (FBuffer <> Nil) then
  begin
    FreeMem (FBuffer, FBufferSize);
    FBuffer := Nil;
  end;
  inherited Destroy;
end;

function TFilterFile.Open 
     (
       AMode : FileIOMode
     ) : Boolean;
var
  SaveFileMode : Byte;
begin
  Result := True;
  SaveFileMode := FileMode;  { FileMode definido na unit system }
 { tenta abrir o arquivo }
  try
  case AMode of
    fioRead :
    begin
      FileMode := 0;
      Reset (F, 1);
    end;
    fioWrite :
    begin
       FileMode := 1;
       Rewrite (F, 1);
    end;
  end;
   FFileMode := AMode; 
  except
    Result := False;
  end;
  FBytesInBuff := 0;
  FBuffIndx := 0;
  FileMode := SaveFileMode;
end;

procedure TFilterFile.Close;
begin
  if ((FFileMode = fioWrite) and
    (FBytesInBuff > 0)) then
  begin
    WriteBuffer;
  end;
  try
    System.Close (F);
  finally
    FFileMode := fioNotOpen;
  end;
end;

function TFilterFile.ReadBuffer : Boolean;
begin
  Result := True;
  if (Self.Eof) then
  begin
    Result := False;
  end
  else
  begin
    try
      BlockRead (F, FBuffer^, FBufferSize, FBytesInBuff);
    except
      Result := False;
    end;
  end;
end;

{ GetByte -- retorna o proximo byte no arquivo - l o buffer se necessrio } 
function TFilterFile.GetByte : byte;
begin
  if (FBuffIndx >= FBytesInBuff) then
  begin
    if (not ReadBuffer) then
    begin
      Result := 0;
      Exit;
    end
    else
    begin
      FBuffIndx := 0;
    end;
  end;
  Result := FBuffer^[FBuffIndx];
  Inc (FBuffIndx);
end;

function TFilterFile.WriteBuffer : Boolean;
begin
  Result := True;
  try
    BlockWrite (F, FBuffer^, FBytesInBuff);
  except
    Result := False;
  end;
  if (Result = True) then
  begin
    FBytesInBuff := 0;
  end;
end;

function TFilterFile.PutByte (b : byte) : Boolean;
begin
 if (FBytesInBuff = FBufferSize) then
 begin
   if (not WriteBuffer) then
   begin
     Result := False;
     Exit;
   end
   else
   begin
     FBytesInBuff := 0;
   end;
 end;
  FBuffer^[FBytesInBuff] := b;
  Inc (FBytesInBuff);
  Result := True;
end;

function TFilterFile.Eof : Boolean;
begin
  Result := (FBuffIndx >= FBytesInBuff);
  if Result then
  begin
    try
      Result := System.Eof (F);
    except
      Result := True;
    end;
  end;
end;


var
 I: Integer;
initialization
 {$IFNDEF LINUX}
   for I:=0 to 255 do GUpcaseTable[I] := Chr(I);
   CharUpperBuff(@GUpcaseTable[0], 256);
 {$ELSE}
   for I:=0 to 255 do GUpcaseTable[I] := UpCase(Chr(I)); 
 {$ENDIF}
 GUpcaseLUT := @GUpcaseTable[0];

end.
{$WARNINGS ON}



************************************************

Cdigo para apagar o prprio programa aps execuo:
(pode ser til no caso de uma desinstalao ;)

var F: TextFile;
 batName := ExtractFilePath(ParamStr(0)) + '\$$$$$$$$.bat';
AssignFile(F,batName);
Rewrite(F);
Writeln(F,':try');
Writeln(F,'del "'+ParamStr(0)+'"'); 
Writeln(F,'if exist "'+ ParamStr(0)+'"'+' goto try');
Writeln(F,'del "' + batName + '"' );
CloseFile(F);
FillChar(si, SizeOf(si), $00);
si.dwFlags := STARTF_USESHOWWINDOW;
si.wShowWindow := SW_HIDE;
if CreateProcess( nil, PChar(batName), nil, nil, False, IDLE_PRIORITY_CLASS, nil, nil, si, pi ) then
begin
CloseHandle(pi.hThread);
CloseHandle(pi.hProcess );
end;
 
**********************************************************************************

