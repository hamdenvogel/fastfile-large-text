unit UnReadFileThread;



interface



uses

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,

  Dialogs, StdCtrls, DateUtils, ComCtrls, ExtCtrls,

  Math, ClipBrd, CommCtrl,

  uPosBMH, uSmoothLoading,

  uLineEditor,

  uExportDialog, MidasLib, DB, DBClient, Grids, DBGrids , uMMF;



const

  INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';

  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';

  

  OUT_BUFFER_SIZE = 65536; 

  INDEX_RECORD_SIZE = 20;



  MAX_100_PERCENT = 100;



type


TByteArray = array[0..$7FFFFFF] of Byte;
PByteArray = ^TByteArray;



  PAnsiCharMap = ^TAnsiCharMap;

  TAnsiCharMap = array[AnsiChar] of AnsiChar;



type TStopWatch = class

private

   fFrequency : TLargeInteger;

   fStartCount, fStopCount : TLargeInteger;

   procedure SetTickStamp(var lInt : TLargeInteger) ;

   function  GetElapsedMilliseconds: TLargeInteger;

public

   function    FormatMillisecondsToDateTime(const ms: integer): string;

   constructor Create(const startOnCreate : boolean = false) ;

   procedure   Start;

   procedure   Stop;

   property    ElapsedMilliseconds : TLargeInteger read GetElapsedMilliseconds;

end;



type

  TfrmReadFileThread = class(TForm)

    lblReadFileName: TLabel;

    edtFileName: TEdit;

    btnReadFile: TButton;

    mmTimer: TMemo;

    btnEditFile: TButton;

    ListView1: TListView;

    btnExport: TButton; 

    SaveDialog1: TSaveDialog;

    trkFiles: TTrackBar;

    btnExecuteFiles: TButton;

    clFiles: TClientDataSet;

    clFilesID: TIntegerField;

    clFilesFilename: TStringField;

    clFilesFileSize: TStringField;

    clFilesSourceLine: TStringField;

    clFilesTargetLine: TStringField;

    dsFiles: TDataSource;

    dbgFiles: TDBGrid;

    lblFiles: TLabel;

    lblTrackBarFileValueSplitFile: TLabel;

    btnMergeMultipleLines: TButton;

    

    procedure btnReadFileClick(Sender: TObject);

    procedure btnEditFileClick(Sender: TObject);

    procedure FormDestroy(Sender: TObject);

    procedure FormCreate(Sender: TObject);

    

    // NOVO: Evento de redimensionamento

    procedure FormResize(Sender: TObject);

    

    // Eventos do ListView

    procedure ListView1Data(Sender: TObject; Item: TListItem);

    procedure ListView1DblClick(Sender: TObject);

    

    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure ListView1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

    procedure ListView1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure ListView1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure btnExportClick(Sender: TObject);
    procedure dbgFilesKeyDown(Sender: TObject; var Key: Word;

      Shift: TShiftState);

    procedure trkFilesChange(Sender: TObject);

    procedure tableTempFiles(const totalFiles: Integer);

    procedure btnExecuteFilesClick(Sender: TObject);

    procedure splitFileByLines(const newTextFileName: string; const sourceLine: Int64; targetLine: Int64; const splittedFileName: string = '');

    procedure FormKeyDown(Sender: TObject; var Key: Word;

      Shift: TShiftState);

    

  private

    FFindAutoRetry: Boolean;
    FLastFindDirection: Integer;
    FSourceFileStream: TFileStream;

    FIndexFileStream: TFileStream;

    FMMFReader: TMMFReader;
    

    FHasSelection: Boolean;   

    FIsDragging: Boolean;     

    FBlockStartPoint: TPoint; 

    FBlockEndPoint: TPoint;   

    

    FCharWidth: Integer;

    FLineHeight: Integer;

    



    // ==== BUSCA (não bloqueia UI) ====

    FFindText: string;

    FFindCaseSensitive: Boolean;

    FLastFoundLine: Integer;

    FLastFoundFilePos: Int64;

    // Destaque do match (coluna e tamanho) na linha encontrada
    FLastFoundCol: Integer;
    FLastFoundMatchLen: Integer;

    FFindThread: TThread;
    FOldListViewWndProc: TWndMethod;

    procedure DoFindDialog;

    procedure DoGotoLine;

    procedure StartFindFromPos(const AStartPos: Int64; const ADirection: Integer);

    procedure FindThreadDone(const AFound: Boolean; const ALineIndex: Integer; const AFilePos: Int64);

    procedure HookedListViewWndProc(var Message: TMessage);

    procedure DrawSelectionRect;


    function GetLineStartOffset(LineIndex: Integer): Int64;
    function BlendColors(const BaseColor, OverlayColor: TColor; const Alpha: Byte): TColor;
    procedure ListView1AdvancedCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);


    procedure OpenFileStreams(const AFileName: String);



    function GetRowIndexAt(X, Y: Integer): Integer; 

    

    procedure CalculateFontMetrics;

    procedure CopyVerticalSelectionToClipboard;



    function IsClickInFirstColumn(X: Integer): Boolean;

    procedure CopyMultiSelectionToClipboard;

    Function ExtractName(const Filename: String): String;

  public

    procedure finishFileNameRead(const timer: string; LineCount: Int64);

    procedure RefreshFile; // relê o arquivo e recarrega no ListView

    function GetLineContent(LineIndex: Integer): String;

    procedure CloseFileStreams;

    function UTF8ToAnsi(const S: AnsiString): string;

    function AnsiToUTF8(const S: string): AnsiString;

  

end;



var

  frmReadFileThread: TfrmReadFileThread;



implementation




{$R *.dfm}

uses
  uI18n, UnConsts, uFastFilePaths;

procedure ShowAppMessage(const Msg: string);
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

function AppMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := Dialogs.MessageDlg(TrText(Msg), DlgType, Buttons, HelpCtx);
end;



type

  TBufferedTextWriter = class

  private

    FStream: TFileStream;

    FBuf: array of AnsiChar;

    FPos: Integer;

  public

    constructor Create(const AFileName: string; ABufferSize: Integer = 1024*1024);

    destructor Destroy; override;



    procedure WriteLine(const S: AnsiString);

    procedure Flush;

end;



type

  TFindInFileThread = class(TThread)

  private

    FOwner: TfrmReadFileThread;

    FFileName: string;

    FIndexFileName: string;

    FNeedle: AnsiString;

    FNeedleUpper: AnsiString;

    FCaseSensitive: Boolean;

    FStartPos: Int64;     // 0-based byte offset in source file

    FDirection: Integer; // +1 forward, -1 backward

    FFound: Boolean;

    FFoundLine: Integer;

    FFoundPos: Int64;    // 0-based byte offset in source file

    procedure NotifyOwner;

    function OffsetToLineIndex(AIndexStream: TFileStream; const APos1Based: Int64): Integer;

    function RPosA(const SubStr, S: AnsiString): Integer;

  protected

    procedure Execute; override;

  public

    constructor Create(AOwner: TfrmReadFileThread; const AFileName, AIndexFileName: string;

      const ANeedle: string; ACaseSensitive: Boolean; const AStartPos: Int64; const ADirection: Integer);

  end;



constructor TBufferedTextWriter.Create(const AFileName: string; ABufferSize: Integer);

begin

  inherited Create;

  FStream := TFileStream.Create(AFileName, fmCreate);

  if ABufferSize < 64*1024 then

    ABufferSize := 64*1024;

  SetLength(FBuf, ABufferSize);

  FPos := 0;

end;



destructor TBufferedTextWriter.Destroy;

begin

  Flush;

  FStream.Free;

  inherited;

end;



procedure TBufferedTextWriter.Flush;

begin

  if FPos > 0 then

  begin

    FStream.WriteBuffer(FBuf[0], FPos);

    FPos := 0;

  end;

end;



procedure TBufferedTextWriter.WriteLine(const S: AnsiString);

const

  CRLF: array[0..1] of AnsiChar = (#13, #10);

var

  FirstIdx, LastIdx: Integer;

  L, Need: Integer;

  P: PAnsiChar;

begin

  // Remove quebras/bytes de controle no INÍCIO e no FIM (sem copiar string)

  FirstIdx := 1;

  LastIdx  := Length(S);



  // Alguns arquivos/índices podem incluir CR/LF (ou #0/#26) antes do conteúdo.

  while (FirstIdx <= LastIdx) and (S[FirstIdx] in [#10, #13, #0, #26]) do

    Inc(FirstIdx);



  while (LastIdx >= FirstIdx) and (S[LastIdx] in [#10, #13, #0, #26]) do

    Dec(LastIdx);



  L := LastIdx - FirstIdx + 1;

  if L < 0 then L := 0;



  Need := L + 2;



  // Linha maior que o buffer: grava direto
  if Need > Length(FBuf) then

  begin

    Flush;

    if L > 0 then

    begin

      P := PAnsiChar(S);

      Inc(P, FirstIdx - 1);

      FStream.WriteBuffer(P^, L);

    end;

    FStream.WriteBuffer(CRLF[0], 2);

    Exit;

  end;



  // Não cabe: descarrega
  if FPos + Need > Length(FBuf) then

    Flush;



  // Copia só os L bytes (sem EOL/bytes de controle)

  if L > 0 then

  begin

    P := PAnsiChar(S);

    Inc(P, FirstIdx - 1);

    Move(P^, FBuf[FPos], L);

    Inc(FPos, L);

  end;



  // Adiciona EXATAMENTE 1 CRLF

  Move(CRLF[0], FBuf[FPos], 2);

  Inc(FPos, 2);

end;



constructor TStopWatch.Create(const startOnCreate: boolean);

begin

  inherited Create;

  QueryPerformanceFrequency(fFrequency);

  if startOnCreate then Start;

end;



function TStopWatch.FormatMillisecondsToDateTime(const ms: integer): string;

var dt : TDateTime;

begin

  dt := ms / MSecsPerSec / SecsPerDay;

  result := Format('%s', [FormatDateTime('hh:nn:ss.z', Frac(dt))]);

end;



function TStopWatch.GetElapsedMilliseconds: TLargeInteger;

begin

  result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;

end;



procedure TStopWatch.SetTickStamp(var lInt: TLargeInteger);

begin

  QueryPerformanceCounter(lInt);

end;



procedure TStopWatch.Start;

begin

  SetTickStamp(fStartCount);

end;



procedure TStopWatch.Stop;

begin

  SetTickStamp(fStopCount);

end;



{ ============================================================================ }

// GESTÃO DE ARQUIVOS

{ ============================================================================ }



procedure TfrmReadFileThread.CloseFileStreams;

begin

  if Assigned(FMMFReader) then FreeAndNil(FMMFReader);
  if Assigned(FSourceFileStream) then FreeAndNil(FSourceFileStream);

  if Assigned(FIndexFileStream) then FreeAndNil(FIndexFileStream);

  if Assigned(ListView1) then

  begin

    ListView1.Items.Count := 0;

    ListView1.Invalidate;

  end;

end;



procedure TfrmReadFileThread.OpenFileStreams(const AFileName: String);

var

  IndexFileName: String;

begin

  CloseFileStreams;

  IndexFileName := FastFileExeDirPath(TEMPFILE);



  if FileExists(AFileName) and FileExists(IndexFileName) then

  begin

    try

      FSourceFileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);

      FMMFReader := TMMFReader.Create(AFileName);
      FIndexFileStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);

    except

      CloseFileStreams;

    end;

  end;

end;



function TfrmReadFileThread.GetLineContent(LineIndex: Integer): String;

var

  StartOffset, EndOffset: Int64;

  LineLength: Integer;

  Buffer, OffsetStr: AnsiString;

  ReadPos: Int64;

  CopyLen, Contiguous: Cardinal;

  P: PByte;

  FSize: Int64;

begin

  Result := '';

  // INDEX_RECORD_SIZE deve ser 20 conforme a nova TBufferedTextWriter

  if (not Assigned(FIndexFileStream)) then Exit;

  if (not Assigned(FMMFReader)) and (not Assigned(FSourceFileStream)) then Exit;



  if Assigned(FMMFReader) then

    FSize := FMMFReader.FileSize

  else

    FSize := FSourceFileStream.Size;



  try

    // 1. Leitura do Offset no índice (Sempre 20 bytes por registro)

    FIndexFileStream.Seek(Int64(LineIndex) * 20, soFromBeginning);

    SetLength(OffsetStr, 18);

    FIndexFileStream.Read(Pointer(OffsetStr)^, 18);

    StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);



    if StartOffset = -1 then Exit;



    // 2. Determinação do fim da linha (próximo offset ou fim do arquivo)

    if (Int64(LineIndex + 1) * 20) < FIndexFileStream.Size then

    begin

      FIndexFileStream.Seek(Int64(LineIndex + 1) * 20, soFromBeginning);

      FIndexFileStream.Read(Pointer(OffsetStr)^, 18);

      EndOffset := StrToInt64Def(Trim(string(OffsetStr)), FSize + 1);

    end

    else

      EndOffset := FSize + 1;



    LineLength := EndOffset - StartOffset;

    if LineLength <= 0 then Exit;



    // 3. Extração dos Bytes Puros (Sem conversão aqui)

    ReadPos := StartOffset - 1; // Ajuste para 0-based

    SetLength(Buffer, LineLength);



    if Assigned(FMMFReader) then

    begin

      // Otimização: Tentar ler a linha inteira de uma vez se for contígua na janela MMF

      P := FMMFReader.PtrAt(ReadPos, LineLength, Contiguous);

      if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then

      begin

        Move(P^, Pointer(Buffer)^, LineLength);

      end

      else

      begin

        // Caso a linha cruze a borda da janela MMF, usa o fallback seguro

        FMMFReader.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);

      end;

    end

    else

    begin

      FSourceFileStream.Seek(ReadPos, soFromBeginning);

      FSourceFileStream.ReadBuffer(Pointer(Buffer)^, LineLength);

    end;



    // 4. Limpeza de caracteres de controle

    while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do

      SetLength(Buffer, Length(Buffer) - 1);



    // Retorna string bruta (UTF-8). A tradução ocorre apenas na UI.

    Result := string(Buffer);

  finally

  end;

end;


function TfrmReadFileThread.GetLineStartOffset(LineIndex: Integer): Int64;
var
  OffsetStr: AnsiString;
begin
  Result := -1;
  if (not Assigned(FIndexFileStream)) then Exit;

  try
    FIndexFileStream.Seek(Int64(LineIndex) * INDEX_RECORD_SIZE, soFromBeginning);
    SetLength(OffsetStr, 18);
    FIndexFileStream.Read(Pointer(OffsetStr)^, 18);
    Result := StrToInt64Def(Trim(string(OffsetStr)), -1);
  except
    Result := -1;
  end;
end;

function TfrmReadFileThread.BlendColors(const BaseColor, OverlayColor: TColor; const Alpha: Byte): TColor;
var
  B, O: Longint;
  br, bg, bb: Byte;
  orr, og, ob: Byte;
  r, g, b2: Integer;
begin
  // Alpha: 0 = BaseColor, 255 = OverlayColor
  B := ColorToRGB(BaseColor);
  O := ColorToRGB(OverlayColor);

  br := GetRValue(B); bg := GetGValue(B); bb := GetBValue(B);
  orr := GetRValue(O); og := GetGValue(O); ob := GetBValue(O);

  r := (Integer(br) * (255 - Alpha) + Integer(orr) * Alpha) div 255;
  g := (Integer(bg) * (255 - Alpha) + Integer(og) * Alpha) div 255;
  b2 := (Integer(bb) * (255 - Alpha) + Integer(ob) * Alpha) div 255;

  Result := RGB(Byte(r), Byte(g), Byte(b2));
end;

procedure TfrmReadFileThread.ListView1AdvancedCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: Boolean);
var
  R: TRect;
  S: String;
  LineStart: Int64;
  MatchStart, MatchLen: Integer;
  X, Y: Integer;
  Prefix, MatchText, Suffix: String;
  Canvas: TCanvas;
  BaseBk, HlBk: TColor;
begin
  DefaultDraw := True;

  // Só no PrePaint e na coluna "Content" (2ª coluna = SubItem 1)
  if (Stage <> cdPrePaint) then Exit;
  if (SubItem <> 1) then Exit;
  if (Item = nil) then Exit;

  // Só desenha especial para a linha do último match
  if (Item.Index <> FLastFoundLine) then Exit;
  if (FFindText = '') then Exit;

  // Retângulo do subitem
  R := Rect(0, 0, 0, 0);
  if not ListView_GetSubItemRect(Sender.Handle, Item.Index, SubItem, LVIR_LABEL, @R) then Exit;

  Canvas := Sender.Canvas;
  S := GetLineContent(Item.Index);

  LineStart := GetLineStartOffset(Item.Index);
  if LineStart < 0 then Exit;

  MatchStart := Integer(FLastFoundFilePos - LineStart); // 0-based
  MatchLen := FLastFoundMatchLen;
  if MatchLen <= 0 then MatchLen := Length(FFindText);

  if MatchStart < 0 then MatchStart := 0;
  if MatchStart > Length(S) then Exit;
  if MatchStart + MatchLen > Length(S) then
    MatchLen := Length(S) - MatchStart;

  // Fundo base (seleção do Windows, se estiver selecionado)
  if cdsSelected in State then
    BaseBk := clHighlight
  else
    BaseBk := clWindow;

  // Highlight suave: fora da seleção usa clInfoBk; na seleção mistura para ficar leve
  if cdsSelected in State then
    HlBk := BlendColors(clHighlight, clInfoBk, 80)
  else
    HlBk := clInfoBk;

  Prefix := Copy(S, 1, MatchStart);
  MatchText := Copy(S, MatchStart + 1, MatchLen);
  Suffix := Copy(S, MatchStart + 1 + MatchLen, MaxInt);

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BaseBk;
  Canvas.FillRect(R);

  if cdsSelected in State then
    Canvas.Font.Color := clHighlightText
  else
    Canvas.Font.Color := clWindowText;

  X := R.Left + 2;
  Y := R.Top + 1;

  Canvas.TextOut(X, Y, Prefix);
  Inc(X, Canvas.TextWidth(Prefix));

  Canvas.Brush.Color := HlBk;
  Canvas.FillRect(Rect(X, R.Top, X + Canvas.TextWidth(MatchText), R.Bottom));
  Canvas.TextOut(X, Y, MatchText);
  Inc(X, Canvas.TextWidth(MatchText));

  Canvas.Brush.Color := BaseBk;
  Canvas.TextOut(X, Y, Suffix);

  DefaultDraw := False;
end;

{ ============================================================================ }

// SELEÇÃO VERTICAL (BLOCK SELECTION) - HOOK E LÓGICA

{ ============================================================================ }



procedure TfrmReadFileThread.CalculateFontMetrics;

var

  Bmp: TBitmap;

begin

  Bmp := TBitmap.Create;

  try

    Bmp.Canvas.Font.Assign(ListView1.Font);

    FCharWidth := Bmp.Canvas.TextWidth('W');

    FLineHeight := Abs(Bmp.Canvas.Font.Height);

    

    if FLineHeight < 14 then FLineHeight := 14; 

    if FCharWidth <= 0 then FCharWidth := 8;

  finally

    Bmp.Free;

  end;

end;



function TfrmReadFileThread.GetRowIndexAt(X, Y: Integer): Integer;

var

  HitInfo: TLVHitTestInfo;

begin

  if ListView1.Columns.Count > 0 then

    HitInfo.pt.x := ListView1.Columns[0].Width + 5

  else

    HitInfo.pt.x := 20;

    

  HitInfo.pt.y := Y;

  HitInfo.flags := LVHT_ONITEM; 

  

  Result := SendMessage(ListView1.Handle, LVM_HITTEST, 0, Longint(@HitInfo));

end;

function TfrmReadFileThread.IsClickInFirstColumn(X: Integer): Boolean;

var

  Col0Width, ScrollOffset: Integer;

begin

  if (ListView1 = nil) or (ListView1.Columns.Count = 0) then

  begin

    Result := False;

    Exit;

  end;



  Col0Width := ListView1.Columns[0].Width;

  ScrollOffset := GetScrollPos(ListView1.Handle, SB_HORZ);



  // Compensa scroll horizontal: o X recebido é na área visível

  Result := (X + ScrollOffset) <= Col0Width;

end;



procedure TfrmReadFileThread.CopyMultiSelectionToClipboard;

var

  ClipList: TStringList;

  Item: TListItem;

  CopiedCount: Integer;

  LineText, ClipText: String;

begin

  if (ListView1 = nil) or (ListView1.SelCount = 0) then Exit;



  ClipList := TStringList.Create;

  try

    CopiedCount := 0;



    Item := ListView1.Selected;

    while Item <> nil do

    begin

      // IMPORTANTE:

      // Para copiar o conteúdo REAL (linha completa do arquivo) e não depender do que o ListView "renderiza",

      // usamos GetLineContent(Item.Index).

      LineText := GetLineContent(Item.Index);



      // Segurança: evitar caracteres nulos que podem "cortar" o texto em alguns destinos ao colar

      while PosBMH(#0, LineText) > 0 do

        Delete(LineText, PosBMH(#0, LineText), 1);



      ClipList.Add(LineText);

      Inc(CopiedCount);



      Item := ListView1.GetNextItem(Item, sdAll, [isSelected]);

    end;



    if CopiedCount > 0 then

    begin

      ClipText := ClipList.Text;



      // Remover apenas o CRLF final (TStringList.Text sempre adiciona um)

      if (Length(ClipText) >= 2) and (Copy(ClipText, Length(ClipText) - 1, 2) = #13#10) then

        SetLength(ClipText, Length(ClipText) - 2);



      Clipboard.AsText := ClipText;

      ShowAppMessage(Format('%d linha(s) copiada(s) para a área de transferência.', [CopiedCount]));

    end;

  finally

    ClipList.Free;

  end;

end;



procedure TfrmReadFileThread.DrawSelectionRect;

var

  L, T, W, H: Integer;

  R: TRect;

begin

  L := Min(FBlockStartPoint.X, FBlockEndPoint.X);

  T := Min(FBlockStartPoint.Y, FBlockEndPoint.Y);

  W := Abs(FBlockEndPoint.X - FBlockStartPoint.X);

  H := Abs(FBlockEndPoint.Y - FBlockStartPoint.Y);

  

  R := Rect(L, T, L + W, T + H);



  ListView1.Canvas.Brush.Style := bsClear; 

  ListView1.Canvas.Pen.Color   := clHighlight;

  ListView1.Canvas.Pen.Style   := psSolid;

  ListView1.Canvas.Pen.Width   := 1;

  ListView1.Canvas.Pen.Mode    := pmCopy;

  

  ListView1.Canvas.Rectangle(R);

end;



procedure TfrmReadFileThread.HookedListViewWndProc(var Message: TMessage);

begin

  if Assigned(FOldListViewWndProc) then

    FOldListViewWndProc(Message);

  

  if (Message.Msg = WM_PAINT) and (FHasSelection) then

  begin

    DrawSelectionRect;

  end;

end;



procedure TfrmReadFileThread.ListView1MouseDown(Sender: TObject;

  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

begin

  // 1) NOVO: seleção múltipla SOMENTE se (Ctrl) + clique na 1ª coluna (Line #)

  if (Button = mbLeft) and (ssCtrl in Shift) and IsClickInFirstColumn(X) then

  begin

    // Se havia seleção vertical ativa, limpa para não "misturar" modos

    if FHasSelection then

    begin

      FHasSelection := False;

      FIsDragging := False;

      if GetCapture = ListView1.Handle then ReleaseCapture;

      ListView1.Repaint;

    end;



    // Deixa o próprio ListView (MultiSelect=True) alternar seleção do item

    Exit;

  end;



  // 2) Seleção vertical (existente): Ctrl/Alt + arrastar em qualquer coluna (exceto o caso acima)

  if (Button = mbLeft) and ((ssCtrl in Shift) or (ssAlt in Shift)) then

  begin

    FHasSelection := True;

    FIsDragging := True;

    

    SetCapture(ListView1.Handle); 

    if ListView1.CanFocus then ListView1.SetFocus;

    

    FBlockStartPoint := Point(X, Y);

    FBlockEndPoint := Point(X, Y);



    // Para não misturar com seleção múltipla do ListView

    ListView1.Selected := nil;

    ListView1.Repaint;

  end

  else

  begin

    if FHasSelection then

    begin

      FHasSelection := False;

      FIsDragging := False;

      if GetCapture = ListView1.Handle then ReleaseCapture;

      ListView1.Repaint;

    end;

  end;

end;



procedure TfrmReadFileThread.ListView1MouseMove(Sender: TObject;

  Shift: TShiftState; X, Y: Integer);

begin

  if FIsDragging then

  begin

    FBlockEndPoint := Point(X, Y);

    ListView1.Repaint; 

  end;

end;



procedure TfrmReadFileThread.ListView1MouseUp(Sender: TObject;

  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

begin

  if FIsDragging then

  begin

    FIsDragging := False;

    ReleaseCapture; 

    FBlockEndPoint := Point(X, Y);

    ListView1.Repaint;

  end;

end;



procedure TfrmReadFileThread.ListView1KeyDown(Sender: TObject; var Key: Word;

  Shift: TShiftState);

var

  StartPos: Int64;

  LineStart, NextLineStart: Int64;
begin

  if (Key = Ord('C')) and (ssCtrl in Shift) then

  begin

    // Prioridade: seleção vertical (retângulo) já existente

    if FHasSelection then

      CopyVerticalSelectionToClipboard

    else

    // NOVO: se houver itens selecionados (Ctrl+clique na 1ª coluna), copia as linhas selecionadas

    if (ListView1 <> nil) and (ListView1.SelCount > 0) then

      CopyMultiSelectionToClipboard;

  end;

  

  



  // ==== BUSCA (arquivos grandes: roda em thread) ====

  if (Key = Ord('F')) and (ssCtrl in Shift) then

  begin

    DoFindDialog;

    Key := 0;

    Exit;

  end;



  if (Key = VK_F3) then

  begin
    if Assigned(ListView1) then
      ListView1.SetFocus;


    // Mesmo comportamento do ListViewKeyDown: pular para próxima/anterior linha.
    if ssShift in Shift then
    begin
      StartPos := FLastFoundFilePos - 1;
      LineStart := GetLineStartOffset(FLastFoundLine); // 1-based
      if LineStart > 1 then
        StartPos := LineStart - 2; // 0-based
      if StartPos < 0 then StartPos := 0;
      StartFindFromPos(StartPos, -1);
    end
    else
    begin
      StartPos := FLastFoundFilePos + 1;
      NextLineStart := GetLineStartOffset(FLastFoundLine + 1); // 1-based
      if NextLineStart > 0 then
      begin
        if (NextLineStart - 1) > StartPos then
          StartPos := NextLineStart - 1; // 0-based
      end;
      StartFindFromPos(StartPos, +1);
    end;

    Key := 0;
    Exit;
  end;

  // Ir para linha (Ctrl+G)

  if (Key = Ord('G')) and (ssCtrl in Shift) then

  begin

    DoGotoLine;

    Key := 0;

    Exit;

  end;

if Key = VK_ESCAPE then

  begin

    FHasSelection := False;

    FIsDragging := False;

    ListView1.Repaint;

  end;

end;





procedure TfrmReadFileThread.CopyVerticalSelectionToClipboard;

var

  R: TRect;

  StartRowIdx, EndRowIdx: Integer;

  StartCharIdx, EndCharIdx, CopyLen: Integer;

  Col0Width, ScrollOffset: Integer;

  PixelTextStart, PixelTextEnd: Integer;

  i, Tmp: Integer;

  LineText, BlockText: String;

  ClipList: TStringList;

  

  const TEXT_PADDING = 3; 

begin

  if not FHasSelection then Exit;

  

  R.Left   := Min(FBlockStartPoint.X, FBlockEndPoint.X);

  R.Right  := Max(FBlockStartPoint.X, FBlockEndPoint.X);

  R.Top    := Min(FBlockStartPoint.Y, FBlockEndPoint.Y);

  R.Bottom := Max(FBlockStartPoint.Y, FBlockEndPoint.Y);

  

  StartRowIdx := GetRowIndexAt(5, R.Top);

  EndRowIdx := GetRowIndexAt(5, R.Bottom - 1);

  

  if (StartRowIdx = -1) or (EndRowIdx = -1) then

  begin

     if ListView1.TopItem <> nil then

     begin

       if StartRowIdx = -1 then StartRowIdx := ListView1.TopItem.Index;

       if EndRowIdx = -1 then EndRowIdx := ListView1.Items.Count - 1;

     end;

  end;

    

  if StartRowIdx > EndRowIdx then 

  begin

    Tmp := StartRowIdx; StartRowIdx := EndRowIdx; EndRowIdx := Tmp;

  end;

  

  if StartRowIdx < 0 then StartRowIdx := 0;

  if EndRowIdx >= ListView1.Items.Count then EndRowIdx := ListView1.Items.Count - 1;



  Col0Width := ListView1.Columns[0].Width;

  ScrollOffset := Abs(GetScrollPos(ListView1.Handle, SB_HORZ)); 

  

  PixelTextStart := (R.Left + ScrollOffset) - Col0Width - TEXT_PADDING;

  PixelTextEnd   := (R.Right + ScrollOffset) - Col0Width - TEXT_PADDING;

  

  if PixelTextStart < 0 then PixelTextStart := 0;

  if PixelTextEnd < 0 then PixelTextEnd := 0;

  

  StartCharIdx := (PixelTextStart div FCharWidth) + 1;

  EndCharIdx   := (PixelTextEnd div FCharWidth) + 1;

  

  if StartCharIdx < 1 then StartCharIdx := 1;

  CopyLen := EndCharIdx - StartCharIdx;

  

  if CopyLen <= 0 then CopyLen := 1;



  ClipList := TStringList.Create;

  try

    for i := StartRowIdx to EndRowIdx do

    begin

      LineText := GetLineContent(i); 

      

      if StartCharIdx > Length(LineText) then

      begin

        BlockText := StringOfChar(' ', CopyLen);

      end

      else

      begin

        BlockText := Copy(LineText, StartCharIdx, CopyLen);

        if Length(BlockText) < CopyLen then

          BlockText := BlockText + StringOfChar(' ', CopyLen - Length(BlockText));

      end;

        

      ClipList.Add(BlockText);

    end;

    

    if ClipList.Count > 0 then

    begin

      Clipboard.AsText := ClipList.Text;

      ShowAppMessage(Format('Copiado!'#13#10'Linhas: %d-%d'#13#10'Cols: %d-%d', 

        [StartRowIdx+1, EndRowIdx+1, StartCharIdx, EndCharIdx]));

    end;

  finally

    ClipList.Free;

  end;

end;



{ ============================================================================ }

// THREADS (MANTIDAS)

{ ============================================================================ }



































procedure TfrmReadFileThread.FormCreate(Sender: TObject);

begin

  if Assigned(ListView1) then

  begin

    ListView1.OwnerData := True;

    ListView1.ViewStyle := vsReport;

    ListView1.GridLines := True;

    ListView1.ReadOnly := True;

    ListView1.RowSelect := True;

    ListView1.MultiSelect := True; // habilita seleção múltipla (Ctrl+clique)

    

    // ATIVA DOUBLE BUFFERING

    ListView1.DoubleBuffered := True;


    // Evento para destacar a ocorrência encontrada na coluna "Content"
    ListView1.OnAdvancedCustomDrawSubItem := ListView1AdvancedCustomDrawSubItem;
    

    ListView1.Font.Name := 'Courier New';

    ListView1.Font.Size := 10;

    

    // HOOK

    FOldListViewWndProc := ListView1.WindowProc;

    ListView1.WindowProc := HookedListViewWndProc;

  end;

end;



procedure TfrmReadFileThread.DoFindDialog;

var

  S: string;

  Resp: Integer;

begin

  S := FFindText;

  if not InputQuery(TrText('Procurar'), TrText('Digite o texto para procurar:'), S) then Exit;

  S := Trim(S);

  if S = '' then Exit;



  FFindText := S;



  Resp := AppMessageDlg(TrText('Diferenciar maiúsculas/minúsculas?') + #13#10 +

                     TrText('(Yes = Case Sensitive / No = Ignorar)'), mtConfirmation, [mbYes, mbNo, mbCancel], 0);

  if Resp = mrCancel then Exit;



  FFindCaseSensitive := (Resp = mrYes);



  // inicia do item atual (se houver), senão do começo

  if ListView1.ItemIndex >= 0 then

    StartFindFromPos(FLastFoundFilePos, +1)
  else

    StartFindFromPos(0, +1);

end;





procedure TfrmReadFileThread.DoGotoLine;

var

  S: string;

  N: Integer;

begin

  S := '';

  if InputQuery(TrText('Ir para linha'), TrText('Número da linha (1..') + IntToStr(ListView1.Items.Count) + '):', S) then

  begin

    N := StrToIntDef(Trim(S), -1);

    if (N >= 1) and (N <= ListView1.Items.Count) then

    begin

      ListView1.ItemIndex := N - 1;

      ListView1.Items[N - 1].Selected := True;

      ListView1.Items[N - 1].Focused := True;

      ListView1.Items[N - 1].MakeVisible(False);

    end;

  end;

end;



procedure TfrmReadFileThread.StartFindFromPos(const AStartPos: Int64; const ADirection: Integer);

var

  IndexFileName: string;

begin

  FLastFindDirection := ADirection;
  FFindAutoRetry := False;

  if Trim(FFindText) = '' then Exit;

  if Trim(edtFileName.Text) = '' then Exit;

  if not FileExists(edtFileName.Text) then Exit;



  // encerra busca anterior rapidamente (sem travar a UI por muito tempo)

  if Assigned(FFindThread) then

  begin

    FFindThread.Terminate;

    try

      FFindThread.WaitFor;

    except

      // ignora

    end;

    FFindThread := nil;

  end;



  IndexFileName := FastFileExeDirPath(TEMPFILE);

  if not FileExists(IndexFileName) then

  begin

    AppMessageDlg(TrText('Arquivo de índice não encontrado (temp.txt). Releia o arquivo primeiro.'), mtWarning, [mbOK], 0);

    Exit;

  end;



  // inicia thread (não bloqueia UI)

  FFindThread := TFindInFileThread.Create(Self, edtFileName.Text, IndexFileName, FFindText, FFindCaseSensitive, AStartPos, ADirection);
end;



procedure TfrmReadFileThread.FindThreadDone(const AFound: Boolean; const ALineIndex: Integer; const AFilePos: Int64);

var
  LineStart: Int64;
begin

  // thread já terminou (FreeOnTerminate), então limpamos o ponteiro

  FFindThread := nil;



  if not AFound then

  begin
    AppMessageDlg(TrText('Texto não encontrado.'), mtInformation, [mbOK], 0);
    // Reset para permitir nova busca do topo se desejar
    FLastFoundFilePos := 0; 
    Exit;
  end;



  
  // Evita o "F3 duas vezes": às vezes o overlap devolve a mesma ocorrência.
  // Se isso acontecer, fazemos 1 retry automático avançando 1 byte (ou voltando 1 byte).
  if (ALineIndex = FLastFoundLine) and (AFilePos = FLastFoundFilePos) and (not FFindAutoRetry) then
  begin
    FFindAutoRetry := True;
    if FLastFindDirection >= 0 then
      StartFindFromPos(AFilePos + 1, +1)
    else
    begin
      if AFilePos > 0 then
        StartFindFromPos(AFilePos - 1, -1)
      else
        StartFindFromPos(0, -1);
    end;
    Exit;
  end;

// Esta linha é vital para o próximo F3 
  FLastFoundLine := ALineIndex;
  FLastFoundFilePos := AFilePos;



  if (ALineIndex >= 0) and (ALineIndex < ListView1.Items.Count) then

  begin

    ListView1.ItemIndex := ALineIndex;

    ListView1.Items[ALineIndex].Selected := True;

    ListView1.Items[ALineIndex].Focused := True;

    ListView1.Items[ALineIndex].MakeVisible(False);

  end;

  

  CalculateFontMetrics;

end;



procedure TfrmReadFileThread.finishFileNameRead(const timer: string; LineCount: Int64);

begin

  mmTimer.Lines.Add(timer);

  OpenFileStreams(edtFileName.Text);

  if Assigned(ListView1) then

  begin

    ListView1.Items.Count := LineCount;

    ListView1.Invalidate;

  end;

  CalculateFontMetrics;

end;



// ===========================================================================

// NOVO: EVENTO ONRESIZE PARA AJUSTAR COLUNAS

// ===========================================================================

procedure TfrmReadFileThread.FormResize(Sender: TObject);

var

  TotalW, Col0W: Integer;

begin

  if Assigned(ListView1) and (ListView1.Columns.Count >= 2) then

  begin

    TotalW := ListView1.ClientWidth;

    Col0W := ListView1.Columns[0].Width;

    // Ajusta a coluna 1 para ocupar o restante da tela

    if TotalW > Col0W then

      ListView1.Columns[1].Width := TotalW - Col0W - 25; // -25 para barra de rolagem

  end;

end;





{ TFindInFileThread }



constructor TFindInFileThread.Create(AOwner: TfrmReadFileThread; const AFileName, AIndexFileName: string;

  const ANeedle: string; ACaseSensitive: Boolean; const AStartPos: Int64; const ADirection: Integer);

begin

  inherited Create(True);

  FreeOnTerminate := True;

  Priority := tpLower;



  FOwner := AOwner;

  FFileName := AFileName;

  FIndexFileName := AIndexFileName;

  FNeedle := AnsiString(ANeedle);

  FCaseSensitive := ACaseSensitive;

  FStartPos := AStartPos;

  FDirection := ADirection;



  if not FCaseSensitive then

    FNeedleUpper := AnsiUpperCase(FNeedle)

  else

    FNeedleUpper := FNeedle;



  FFound := False;

  FFoundLine := -1;

  FFoundPos := -1;



  Resume;

end;



procedure TFindInFileThread.NotifyOwner;

begin

  if Assigned(FOwner) then

    FOwner.FindThreadDone(FFound, FFoundLine, FFoundPos);

end;



function TFindInFileThread.RPosA(const SubStr, S: AnsiString): Integer;

var

  i, LSub, LS: Integer;

begin

  Result := 0;

  LSub := Length(SubStr);

  LS := Length(S);

  if (LSub = 0) or (LS = 0) or (LSub > LS) then Exit;



  for i := LS - LSub + 1 downto 1 do

    if CompareMem(@S[i], @SubStr[1], LSub) then

    begin

      Result := i;

      Exit;

    end;

end;



function TFindInFileThread.OffsetToLineIndex(AIndexStream: TFileStream; const APos1Based: Int64): Integer;

var

  LowIdx, HighIdx, MidIdx: Int64;

  OffMid, OffNext: Int64;

  Buf: AnsiString;



  function ReadOffset(const RecIndex: Int64): Int64;

  begin

    AIndexStream.Seek(RecIndex * INDEX_RECORD_SIZE, soFromBeginning);

    SetLength(Buf, 18);

    AIndexStream.ReadBuffer(Pointer(Buf)^, 18);

    Result := StrToInt64Def(Trim(string(Buf)), -1);

  end;



begin

  Result := -1;

  if (APos1Based <= 0) or (not Assigned(AIndexStream)) then Exit;



  HighIdx := (AIndexStream.Size div INDEX_RECORD_SIZE) - 1;

  if HighIdx < 0 then Exit;



  LowIdx := 0;



  // Se antes da 1ª linha

  OffMid := ReadOffset(0);

  if (OffMid = -1) or (APos1Based < OffMid) then

  begin

    Result := 0;

    Exit;

  end;



  // Busca pela maior offset <= APos1Based

  while LowIdx <= HighIdx do

  begin

    MidIdx := (LowIdx + HighIdx) div 2;

    OffMid := ReadOffset(MidIdx);



    if OffMid = -1 then

    begin

      HighIdx := MidIdx - 1;

      Continue;

    end;



    if OffMid <= APos1Based then

    begin

      // Checa se é a linha correta comparando com a próxima

      if (MidIdx + 1) <= ((AIndexStream.Size div INDEX_RECORD_SIZE) - 1) then

      begin

        OffNext := ReadOffset(MidIdx + 1);

        if (OffNext = -1) or (APos1Based < OffNext) then

        begin

          Result := MidIdx;

          Exit;

        end;

      end

      else

      begin

        Result := MidIdx;

        Exit;

      end;



      LowIdx := MidIdx + 1;

    end

    else

      HighIdx := MidIdx - 1;

  end;

end;



procedure TFindInFileThread.Execute;

const

  BUF_SIZE = 1024 * 1024; // 1MB por bloco
type
  TShiftTable = array[0..255] of Integer;
var

  M: TMMFReader;
  Idx: TFileStream;

  FileSize: Int64;

  NeedLen: Integer;

  CurPos: Int64;

  BlockStart: Int64;
  ReadSize: Integer;
  BytesRead: Integer;

  // buffers (bytes)
  BufRaw: array of Byte;
  WorkBuf: array of Byte;
  Tail: array of Byte;
  Head: array of Byte;
  TailLen, HeadLen: Integer;

  Shift: TShiftTable;
  Up: array[0..255] of Byte;
  Pat: array of Byte;
  PatU: array of Byte;

  FoundBaseAbs: Int64;
  CandidateAbs: Int64;


  StartIndex: Integer;
  FoundIdx: Integer;

  procedure BuildUpTable;
  var
    i: Integer;
    c: AnsiChar;
  begin
    for i := 0 to 255 do
    begin
      c := AnsiChar(i);
      CharUpperBuffA(@c, 1);
      Up[i] := Byte(c);
    end;
  end;

  procedure BuildPatternBytes;
  var
    i: Integer;
    b: Byte;
  begin
    SetLength(Pat, NeedLen);
    SetLength(PatU, NeedLen);
    for i := 0 to NeedLen - 1 do
    begin
      b := Byte(AnsiChar(FNeedle[i + 1]));
      Pat[i] := b;
      PatU[i] := Up[b];
    end;
  end;

  procedure BuildShiftTable;
  var
    i: Integer;
    b: Byte;
  begin
    for i := 0 to 255 do
      Shift[i] := NeedLen;

    for i := 0 to NeedLen - 2 do
    begin
      if FCaseSensitive then
        b := Pat[i]
      else
        b := PatU[i];
      Shift[b] := (NeedLen - 1) - i;
    end;
  end;

  function BMH_FindFirst(const Buf: PByte; const BufLen: Integer; const AStartIndex: Integer): Integer;
  // Retorna índice 0-based dentro de Buf, ou -1
  var
    i, j: Integer;
    tb: Byte;
    baseIdx: Integer;
  begin
    Result := -1;
    if (NeedLen <= 0) or (BufLen < NeedLen) then Exit;

    i := AStartIndex + (NeedLen - 1);
    while i < BufLen do
    begin
      j := NeedLen - 1;

      if FCaseSensitive then
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if PByteArray(Buf)^[baseIdx] <> PByteArray(Pat)^[j] then Break;
          Dec(j);
        end;
      end
      else
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if Up[PByteArray(Buf)^[baseIdx]] <> PByteArray(PatU)^[j] then Break;
          Dec(j);
        end;
      end;

      if j < 0 then
      begin
        Result := i - (NeedLen - 1);
        Exit;
      end;

      if FCaseSensitive then
        tb := PByteArray(Buf)^[i]
      else
        tb := Up[PByteArray(Buf)^[i]];

      Inc(i, Shift[tb]);
    end;
  end;

  function BMH_FindLastBefore(const Buf: PByte; const BufLen: Integer;
                             const LimitAbs: Int64; const BaseAbs: Int64): Int64;
  // Varre para frente e retorna a última ocorrência cuja posição absoluta < LimitAbs.
  var
    pos, found: Integer;
    lastAbs: Int64;
    absPos: Int64;
  begin
    Result := -1;
    lastAbs := -1;
    pos := 0;

    while True do
    begin
      found := BMH_FindFirst(Buf, BufLen, pos);
      if found < 0 then Break;

      absPos := BaseAbs + found;
      if absPos < LimitAbs then
        lastAbs := absPos
      else
        Break;

      pos := found + 1;
    end;

    Result := lastAbs;
  end;

begin

  M := nil;
  Idx := nil;

  try

    if (FNeedle = '') then Exit;



    // MMF (arquivo fonte)
    M := TMMFReader.Create(FFileName);
    FileSize := M.FileSize;

    // índice continua via TFileStream (pequeno)
    Idx := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);



    NeedLen := Length(FNeedle);
    if NeedLen <= 0 then Exit;



    if FStartPos < 0 then FStartPos := 0;

    if FStartPos > FileSize then FStartPos := FileSize;



    BuildUpTable;
    BuildPatternBytes;
    BuildShiftTable;

    SetLength(BufRaw, BUF_SIZE);

    if FDirection >= 0 then

    begin
      // ===== FORWARD SEARCH =====

      CurPos := FStartPos;

      TailLen := 0;
      SetLength(Tail, 0);


      while (not Terminated) and (CurPos < FileSize) and (not FFound) do

      begin

        ReadSize := BUF_SIZE;

        if CurPos + ReadSize > FileSize then

          ReadSize := Integer(FileSize - CurPos);


        if ReadSize <= 0 then Break;


        // lê bloco via MMF
        BytesRead := Integer(M.ReadBytes(CurPos, BufRaw[0], Cardinal(ReadSize)));
        if BytesRead <= 0 then Break;


        // monta WorkBuf = Tail + BufRaw
        if TailLen > 0 then
        begin

          SetLength(WorkBuf, TailLen + BytesRead);
          Move(Tail[0], WorkBuf[0], TailLen);
          Move(BufRaw[0], WorkBuf[TailLen], BytesRead);
          FoundBaseAbs := (CurPos - TailLen);
        end

        else

        begin

          SetLength(WorkBuf, BytesRead);
          Move(BufRaw[0], WorkBuf[0], BytesRead);
          FoundBaseAbs := CurPos;
        end;



        // startIndex relativo para garantir abs >= FStartPos
        StartIndex := 0;
        if FoundBaseAbs < FStartPos then
          StartIndex := Integer(FStartPos - FoundBaseAbs);


        FoundIdx := BMH_FindFirst(@WorkBuf[0], Length(WorkBuf), StartIndex);
        if FoundIdx >= 0 then
        begin
          CandidateAbs := FoundBaseAbs + FoundIdx;
          FFoundPos := CandidateAbs;
          FFoundLine := OffsetToLineIndex(Idx, CandidateAbs + 1);
          FFound := True;
          Break;
        end;



        // atualiza Tail
        if NeedLen > 1 then

        begin
          TailLen := NeedLen - 1;
          if TailLen > Length(WorkBuf) then TailLen := Length(WorkBuf);
          SetLength(Tail, TailLen);
          if TailLen > 0 then
            Move(WorkBuf[Length(WorkBuf) - TailLen], Tail[0], TailLen);
        end
        else

        begin
          TailLen := 0;
          SetLength(Tail, 0);
        end;


        CurPos := CurPos + BytesRead;
      end;

    end
    else
    begin
      // ===== BACKWARD SEARCH =====

      CurPos := FStartPos;

      HeadLen := 0;
      SetLength(Head, 0);


      while (not Terminated) and (CurPos > 0) and (not FFound) do

      begin

        ReadSize := BUF_SIZE;

        if ReadSize > CurPos then

          ReadSize := Integer(CurPos);


        if ReadSize <= 0 then Break;


        BlockStart := CurPos - ReadSize;


        BytesRead := Integer(M.ReadBytes(BlockStart, BufRaw[0], Cardinal(ReadSize)));
        if BytesRead <= 0 then Break;

        // WorkBuf = BufRaw + Head
        if HeadLen > 0 then
        begin

          SetLength(WorkBuf, BytesRead + HeadLen);
          Move(BufRaw[0], WorkBuf[0], BytesRead);
          Move(Head[0], WorkBuf[BytesRead], HeadLen);
        end

        else

        begin

          SetLength(WorkBuf, BytesRead);
          Move(BufRaw[0], WorkBuf[0], BytesRead);
        end;



        CandidateAbs := BMH_FindLastBefore(@WorkBuf[0], Length(WorkBuf), FStartPos, BlockStart);
        if CandidateAbs >= 0 then
        begin

          // garante que o match começa dentro do bloco (não dentro do Head)
          if CandidateAbs < (BlockStart + BytesRead) then
          begin

            FFoundPos := CandidateAbs;
            FFoundLine := OffsetToLineIndex(Idx, CandidateAbs + 1);
            FFound := True;
            Break;
          end;

        end;



        // atualiza Head
        if NeedLen > 1 then

        begin
          HeadLen := NeedLen - 1;
          if HeadLen > BytesRead then HeadLen := BytesRead;
          SetLength(Head, HeadLen);
          if HeadLen > 0 then
            Move(BufRaw[0], Head[0], HeadLen);
        end
        else

        begin
          HeadLen := 0;
          SetLength(Head, 0);
        end;


        CurPos := BlockStart;
      end;

    end;

  finally

    if Assigned(Idx) then Idx.Free;

    if Assigned(M) then M.Free;
    Synchronize(NotifyOwner);

  end;
end;

procedure TfrmReadFileThread.btnReadFileClick(Sender: TObject);

begin

  if Trim(edtFileName.Text) = '' then begin ShowAppMessage('Please select a file.'); Exit; end;

  if not FileExists(edtFileName.Text) then begin ShowAppMessage('File not found.'); Exit; end;



  CloseFileStreams;

  //TfrmSmoothLoading.ReadFile(edtFileName.Text);



  TReadFileThread.Create(False, edtFileName.Text);

end;



procedure TfrmReadFileThread.btnEditFileClick(Sender: TObject);

var Op: TOperationType; LineNum: Int64; Content: String;

begin

  if Trim(edtFileName.Text) = '' then begin ShowAppMessage('Please select a file.'); Exit; end;

  if not FileExists(edtFileName.Text) then begin ShowAppMessage('File not found.'); Exit; end;



  CloseFileStreams;



  if TfrmLineEditor.Execute(Op, LineNum, Content) then

  begin

    //TfrmSmoothLoading.EditFile(edtFileName.Text, Op, LineNum, Content);

    TEditFileThread.Create(edtFileName.Text, Op, LineNum, Content);

  end;

end;



procedure TfrmReadFileThread.ListView1DblClick(Sender: TObject);

var

  Op: TOperationType;

  LineNum: Int64;

  CurrentContent, OriginalContent: String;

begin

  if ListView1.ItemIndex = -1 then Exit;

  

  LineNum := ListView1.ItemIndex + 1;

  OriginalContent := UTF8ToAnsi(GetLineContent(ListView1.ItemIndex));

  CurrentContent := OriginalContent; 

  Op := otEdit;

  

  if TfrmLineEditor.Execute(Op, LineNum, CurrentContent) then

  begin

    if (Op = otEdit) and (CurrentContent = OriginalContent) then Exit;



    CloseFileStreams;

    TEditFileThread.Create(edtFileName.Text, Op, LineNum, CurrentContent);

end;

end;



procedure TfrmReadFileThread.ListView1Data(Sender: TObject; Item: TListItem);

begin

  if Assigned(FSourceFileStream) then

  begin
    Item.Caption := IntToStr(Item.Index + 1);
    if Item.SubItems.Count = 0 then Item.SubItems.Add('');
    // Converte o conteúdo para ANSI antes de exibir no grid 
    Item.SubItems[0] := UTF8ToAnsi(GetLineContent(Item.Index));
  end;

end;



procedure TfrmReadFileThread.FormMouseWheel(Sender: TObject; Shift: TShiftState;

  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);

var

  i: Integer;

  ScrollCode: Word;

begin

  if ListView1.Items.Count = 0 then Exit;

  if WheelDelta < 0 then ScrollCode := SB_LINEDOWN else ScrollCode := SB_LINEUP;

  for i := 1 to 3 do

    ListView1.Perform(WM_VSCROLL, ScrollCode, 0);

  Handled := True;

end;



procedure TfrmReadFileThread.FormDestroy(Sender: TObject);

begin

  if Assigned(ListView1) and Assigned(FOldListViewWndProc) then

    ListView1.WindowProc := FOldListViewWndProc;

    

  CloseFileStreams;

end; 



procedure TfrmReadFileThread.btnExportClick(Sender: TObject);

var

  Params: String;

  SaveToFile: Boolean;

  OutFile: String;

begin

  if ListView1.Items.Count = 0 then Exit;

  

  if TfrmExportDialog.Execute(Params, SaveToFile) then

  begin

    OutFile := '';

    if SaveToFile then

    begin

      if not SaveDialog1.Execute then Exit;

      OutFile := SaveDialog1.FileName;

    end;



    //TfrmSmoothLoading.ExportLines(Params, SaveToFile, OutFile);

    TExportFileThread.Create(Params, SaveToFile, OutFile, edtFileName.Text, ListView1.Items.Count);

end;

end;



procedure TfrmReadFileThread.dbgFilesKeyDown(Sender: TObject;

  var Key: Word; Shift: TShiftState);

begin

  if (shift = [ssCtrl]) and (key in [VK_DELETE]) then Abort;

end;



procedure TfrmReadFileThread.trkFilesChange(Sender: TObject);

begin

  lblTrackBarFileValueSplitFile.Caption := IntToStr(trkFiles.Position);

  tableTempFiles(trkFiles.Position);

end;



procedure TfrmReadFileThread.tableTempFiles(const totalFiles: Integer);

var

  i: integer;

  totalLines, totalLinesPerFile: integer;

  lastTargetLine, targetLine: Int64;

begin

  if Trim(edtFileName.Text) = '' then begin ShowAppMessage('Please select a file.'); Exit; end;

  if not FileExists(edtFileName.Text) then begin ShowAppMessage('File not found.'); Exit; end;

  if clFiles.Active then clFiles.EmptyDataSet else clFiles.CreateDataSet;

  totalLines := ListView1.Items.Count;

  totalLinesPerFile := Round(totalLines/totalFiles);

  lastTargetLine := 0;

  targetLine := 0;

  with clFiles do

  begin

    for i := 1 to totalFiles do

    begin

      if targetLine > totalLines then Break;

      Append;

      FieldByName('ID').AsInteger := i;

      FieldByName('FileName').AsString := Format('%s.%.03d-copy%s', [ExtractName(edtFileName.Text), i, ExtractFileExt(edtFileName.Text)]);

      case i of

        1: begin

             FieldByName('SourceLine').AsString := IntToStr(i);

             targetLine := totalLinesPerFile;

             FieldByName('TargetLine').AsString := IntToStr(targetLine);

           end;

        else

          begin

            FieldByName('SourceLine').AsString := IntToStr(lastTargetLine);

            targetLine := lastTargetLine + totalLinesPerFile;

            if i < totalFiles then

              FieldByName('TargetLine').AsString := IntToStr(targetLine)

            else

              FieldByName('TargetLine').AsString := IntToStr(totalLines);

          end;

      end; //end case

      lastTargetLine := targetLine + 1;

    end; //end for i := 1 to totalFiles do  

    if (State in [dsInsert, dsEdit]) then

    begin

      Post;

      First;

    end;

  end; //end with clFiles do

end;



procedure TfrmReadFileThread.btnExecuteFilesClick(Sender: TObject);

const

  MESSAGE_FILENAME = 'Writing %d of %d';

var

  ffileName: string;

  sourceLine, targetLine: Int64;

  id: integer;

  sw: TStopWatch;

begin

  if Trim(edtFileName.Text) = '' then begin ShowAppMessage('Please select a file.'); Exit; end;

  if not FileExists(edtFileName.Text) then begin ShowAppMessage('File not found.'); Exit; end;

  ffileName := '';

  sourceLine := 0;

  targetLine := 0;

  sw := TStopWatch.Create;

  try

    sw.Start;

    with clFiles do

    begin

      if not Active then Exit;

      if IsEmpty then Exit;

      First;

      while not Eof do

      begin

        id := FieldByName('ID').AsInteger;

        ffileName := FieldByName('Filename').AsString;

        sourceLine := FieldByName('SourceLine').AsInteger;

        targetLine := FieldByName('TargetLine').AsInteger;

        splitFileByLines(ffileName, sourceLine, targetLine, Format(MESSAGE_FILENAME, [id, trkFiles.Position]));

        Application.ProcessMessages;

        Next;

      end; //end while not Eof do

    end; //end with clFiles do

    sw.Stop;

  finally

    FreeAndNil(sw);

  end;

end;



procedure TfrmReadFileThread.splitFileByLines(

  const newTextFileName: string; const sourceLine: Int64;

  targetLine: Int64; const splittedFileName: string);

var

  i: Integer;

  F: Tform;

  MSG: TLabel;

  shape: TShape;

  progressBar: TProgressBar;

  W: TBufferedTextWriter;

  lineText: AnsiString;

  totalRange: Int64;

  doneRange: Int64;

  LastUI: Cardinal;

  filePathToSave: string;

begin

  if Trim(edtFileName.Text) = '' then begin ShowAppMessage('Please select a file.'); Exit; end;

  if not FileExists(edtFileName.Text) then begin ShowAppMessage('File not found.'); Exit; end;



  // Normaliza range (evita problemas se vier invertido)

  if targetLine < sourceLine then

    targetLine := sourceLine;



  totalRange := (targetLine - sourceLine) + 1;

  if totalRange <= 0 then

    totalRange := 1;



  F:= TForm.Create(Self);

  try

    F.Position := poScreenCenter;

    F.Width := round(Application.MainForm.Width/5);

    F.Height := round(Application.MainForm.Height/2);

    F.FormStyle   := fsNormal;

    F.BorderStyle := bsDialog;



    shape := TShape.Create(Self);

    shape.Parent := F;

    shape.Align := alClient;



    MSG:=  TLabel.Create(Self);

    MSG.Parent := F;

    MSG.Transparent := true;

    MSG.AutoSize := false;

    MSG.Width := F.Width;

    MSG.Top := MSG.Top + 20;

    MSG.Alignment := Classes.taCenter;

    MSG.Font.Style := [fsBold];

    MSG.Font.Name := 'Tahoma';

    MSG.Font.Size := 12;

    if (splittedFileName <> '') then

      MSG.Caption := splittedFileName

    else

      Msg.Caption := 'Writing';



    progressBar := TProgressBar.Create(Self);

    progressBar.Align := alBottom;

    progressBar.Top := MSG.Top + 14;

    progressBar.Height := 30;

    progressBar.parent := F;



    F.Show;

    progressBar.Position := 0;

    progressBar.Max := MAX_100_PERCENT;

    Application.ProcessMessages;



    Cursor := crSQLWait;



    filePathToSave := (ExtractFilePath(edtFileName.Text) + newTextFileName);



    // Escrita performática: não acumula tudo em memória

    W := TBufferedTextWriter.Create(filePathToSave, 4*1024*1024); // 4MB buffer (mais rpido)

    try

      doneRange := 0;

      LastUI := GetTickCount;



      for i := sourceLine to targetLine do

      begin

        // Conteúdo real da linha (não depende do render do ListView)

        lineText := AnsiString(GetLineContent(i));

        W.WriteLine(lineText);



        Inc(doneRange);



        // Atualiza a UI no máximo a cada 100ms.

        // (Evita chamar GetTickCount a cada linha para ganhar performance.)

        if (doneRange and 511) = 0 then // a cada 512 linhas

          if (GetTickCount - LastUI) >= 100 then

          begin

            progressBar.Position := Trunc((MAX_100_PERCENT * doneRange) / totalRange);

            Application.ProcessMessages;

            LastUI := GetTickCount;

          end;

      end;



      // update final

      progressBar.Position := MAX_100_PERCENT;

      Application.ProcessMessages;

    finally

      W.Free; // Flush automático

    end;

  finally

    Cursor := crDefault;

    F.Close;

    FreeAndNil(F);

  end;

end;



function TfrmReadFileThread.ExtractName(const Filename: String): String;

var

  aExt : String;

  aPos : Integer;

begin

  aExt := ExtractFileExt(Filename);

  Result := ExtractFileName(Filename);



  if aExt <> '' then

  begin

    aPos := PosBMH(aExt, Result);



    if aPos > 0 then

    begin

      Delete(Result,aPos,Length(aExt));

    end;

  end;

end;



procedure TfrmReadFileThread.RefreshFile;

begin

  // Recarrega o arquivo atual para refletir alterações (edit/export)

  if Trim(edtFileName.Text) = '' then Exit;

  if not FileExists(edtFileName.Text) then Exit;



  CloseFileStreams;



  // Limpa rapidamente para evitar exibir dados antigos enquanto recarrega

  if Assigned(ListView1) then

  begin

    ListView1.Items.Count := 0;

    ListView1.Invalidate;

  end;



  TReadFileThread.Create(False, edtFileName.Text);

end;





procedure TfrmReadFileThread.FormKeyDown(Sender: TObject; var Key: Word;

  Shift: TShiftState);

var

  StartPos, LineStart, NextLineStart: Int64;
begin
// Atalhos globais (independente do foco). Delphi 7: requer KeyPreview=True no Form.

  // Ctrl+F -> Buscar

  if (Key = Ord('F')) and (ssCtrl in Shift) then

  begin

    if Assigned(ListView1) then

      ListView1.SetFocus;

    DoFindDialog;

    Key := 0;

    Exit;

  end;



  // Ctrl+G -> Ir para linha

  if (Key = Ord('G')) and (ssCtrl in Shift) then

  begin

    if Assigned(ListView1) then

      ListView1.SetFocus;

    DoGotoLine;

    Key := 0;

    Exit;

  end;



  // F3 / Shift+F3 -> Próximo / Anterior (reusa o mecanismo existente)

  if (Key = VK_F3) then

  begin
    // F3: próximo | Shift+F3: anterior
    // Para evitar "teclar duas vezes" e para mudar a linha selecionada,
    // pulamos para o início da próxima linha (ou para antes do início da linha atual ao voltar).
    if ssShift in Shift then
    begin
      // BACKWARD: posiciona antes do início da linha atual (se possível)
      StartPos := FLastFoundFilePos - 1;
      LineStart := GetLineStartOffset(FLastFoundLine); // 1-based
      if LineStart > 1 then
        StartPos := LineStart - 2; // 0-based: byte anterior ao início da linha atual
      if StartPos < 0 then StartPos := 0;
      StartFindFromPos(StartPos, -1);
    end
    else
    begin
      // FORWARD: posiciona no início da próxima linha (se possível)
      StartPos := FLastFoundFilePos + 1;
      NextLineStart := GetLineStartOffset(FLastFoundLine + 1); // 1-based
      if NextLineStart > 0 then
      begin
        if (NextLineStart - 1) > StartPos then
          StartPos := NextLineStart - 1; // 0-based: início da próxima linha
      end;
      StartFindFromPos(StartPos, +1);
    end;


    Key := 0;
    Exit;
  end;
end;



function TfrmReadFileThread.UTF8ToAnsi(const S: AnsiString): string;

var

  L: Integer;
  TempW: WideString;
begin
  Result := S;
  if S = '' then Exit;
  
  // No Delphi 7, primeiro convertemos UTF-8 para WideString (Unicode)
  // E depois o Delphi converte automaticamente para ANSI ao atribuir para 'string'
  L := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(S), -1, nil, 0);
  if L > 0 then
  begin
    SetLength(TempW, L - 1);
    MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(S), -1, PWideChar(TempW), L);
    Result := TempW;
  end;

end;



function TfrmReadFileThread.AnsiToUTF8(const S: string): AnsiString;

var

  W: WideString;
  L: Integer;
begin
  Result := '';
  if S = '' then Exit;

  // 1. Converte ANSI (Delphi 7) para WideString (Unicode)
  W := S; 
  
  // 2. Calcula o tamanho necessário para UTF-8
  L := WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), -1, nil, 0, nil, nil);
  if L > 0 then
  begin
    SetLength(Result, L - 1);
    WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), -1, PAnsiChar(Result), L, nil, nil);
  end;

end;



end.

