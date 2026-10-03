unit Unit1;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;



type
  TLineReader = class
  private
    FContents: string;
    FLine: Integer;
  public
    // Properties to read these data values
    property Contents: string read FContents write FContents;
    property Line: Integer read FLine write FLine; 
    // Constructor
    constructor Create(const AContents: string; const ALine: Integer);
  end;

  // The typed list of TLineReader objects
  TLineReaderList = class(TList)
  private
    function GetItem(Index: Integer): TLineReader;
  public
    property Items[Index: Integer]: TLineReader read GetItem; default; 
  end;

type
  TTextFileStream = class(TFileStream)
  private
    FBuffer: string;
  public
    function Eof: Boolean;
    procedure WriteLn(Text: string);
    function ReadLn: string;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function RowsCount: Integer;
  end;



type
  TForm1 = class(TForm)
    lblStopWatch: TLabel;
    Panel1: TPanel;
    btnRead: TButton;
    pnlMemo: TPanel;
    Memo1: TMemo;
    pnlLoading: TPanel;
    Splitter1: TSplitter;
    btnLoad: TButton;
    procedure btnReadClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    lineCounter: Int64;
    FLineReaderList : TLineReaderList;
    procedure DestroyTLineReaderListObjects;
  end;

const
  cDefaultStopWatchInitialText  = '0 elapsed milliseconds.';

var
  Form1: TForm1;

implementation

uses StopWatch, Biblioteca;

{$R *.dfm}






procedure TForm1.btnReadClick(Sender: TObject);
var
  fs: TTextFileStream;
  sw: TStopWatch;
  strFileName: string;
begin
  lblStopWatch.Caption  := cDefaultStopWatchInitialText;
  strFileName := 'D:\Delphi\teste.sql';
  DestroyTLineReaderListObjects;
  FLineReaderList := TLineReaderList.Create;
  lineCounter     := 0;
  sw := TStopWatch.Create;
  fs := TTextFileStream.Create(strFileName, fmOpenRead);
  pnlLoading.Visible := True;
  Screen.Cursor := crSQLWait;
  Memo1.Clear;
  Memo1.Lines.BeginUpdate;

  try
    sw.Start;
    while not fs.eof do
    begin
      FLineReaderList.Add(TLineReader.Create('Line ' + IntToStr(lineCounter) + ' - ' + fs.ReadLn, lineCounter));
      Inc(lineCounter);
     // Memo1.Lines.Add(s);
      Application.ProcessMessages;
    end;
  finally
    pnlLoading.Visible := False;
    Memo1.Lines.EndUpdate;
    Screen.Cursor := crDefault;
    sw.Stop;
    lblStopWatch.Caption := 'Elapsed ' + Biblioteca.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
    Memo1.Lines.Add('File ' + strFileName + ' readed line by line successfully.');
    Memo1.Lines.Add(lblStopWatch.Caption);
    FreeAndNil(sw);
    FreeAndNil(fs);
  end;
end;


procedure TForm1.btnLoadClick(Sender: TObject);
var
  iLine: integer;
  sw: TStopWatch;
begin
  if not Assigned(FLineReaderList) then Exit;

  sw := TStopWatch.Create;
  pnlLoading.Visible := True;
  Memo1.Clear;
  Memo1.Lines.BeginUpdate;
  Screen.Cursor := crSQLWait;
  try
    sw.Start;
    for iLine := 0 to FLineReaderList.Count - 1 do
    begin
      Memo1.Lines.Add(FLineReaderList.Items[iLine].Contents);
      Application.ProcessMessages;
    end;
  finally
    pnlLoading.Visible := False;
    Memo1.Lines.EndUpdate;
    Screen.Cursor := crDefault;
    sw.Stop;
    lblStopWatch.Caption := 'Elapsed ' + Biblioteca.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
    FreeAndNil(sw);
  end; 
end;



procedure TForm1.DestroyTLineReaderListObjects;
var
  i: integer;
begin
  if Assigned(FLineReaderList) then
  begin
    for i := 0 to FLineReaderList.Count - 1 do
      TObject(FLineReaderList[I]).Free;

      FreeAndNil(FLineReaderList);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DestroyTLineReaderListObjects;
end;


{ TTextFileStream }

function TTextFileStream.Eof: Boolean;
begin
  Eof := ((Position - Length(FBuffer)) = Size);
end;

function TTextFileStream.ReadLn: string;
const
  BufferLength = 10000;
var
  NewBuffer: string;
  Readed: Integer;
begin
  Readed := 1;
  while (PosBMH(#13, FBuffer) = 0) and (Readed > 0) do begin
    SetLength(NewBuffer, BufferLength + 2);
    Readed := Read(NewBuffer[1], BufferLength);
    SetLength(NewBuffer, Readed);
    FBuffer := FBuffer + NewBuffer;
  end;
  if PosBMH(#13, FBuffer) > 0 then begin
    Result := Copy(FBuffer, 1, PosBMH(#13, FBuffer) - 1);
    Delete(FBuffer, 1, PosBMH(#13, FBuffer) + 1);
  end else begin
    Result := FBuffer;
    FBuffer := '';
  end;
end;

function TTextFileStream.RowsCount: Integer;
begin
  Result := 1;
  FBuffer := '';
  Seek(0, soBeginning);
  while not Eof do begin
    ReadLn;
    Inc(Result);
  end;
  Seek(0, soBeginning);
end;

function TTextFileStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  if Origin = soCurrent then
    Result := inherited Seek(Offset - Length(FBuffer), Origin)
    else Result := inherited Seek(Offset, Origin);
  FBuffer := '';
end;

procedure TTextFileStream.WriteLn(Text: string);
const
  NewLine = #13#10;
begin
  Seek(0, soCurrent);
  Write(Text[1], Length(Text));
  Write(NewLine, 2);
end;

{ TLineReader }

constructor TLineReader.Create(const AContents: string;
  const ALine: Integer);
begin
  FContents := AContents;
  FLine     := ALine;
end;

{ TLineReaderList }

function TLineReaderList.GetItem(Index: Integer): TLineReader;
begin
  Result := TLineReader(inherited Items[Index]);
end;

end.
