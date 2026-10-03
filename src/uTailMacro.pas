unit uTailMacro;

{ TTailMacroOnNewLinesThread — Tail macro via LINE (poucas linhas) ou RUNFILE (mmap, GB+). }

interface

uses
  Classes, Windows, SysUtils;

const
  TAIL_MACRO_PIPE_MAX_LINES = 32;

type
  TTailMacroOnNewLinesThread = class(TThread)
  private
    FOwner: TObject;
    FScriptB64: string;
    FSendScript: Boolean;
    FUseRunFile: Boolean;
    FFromLine1, FToLine1, FFileTotalLines: Int64;
    FSourceFileName: string;
    FIndexFileName: string;
    FDisplayEncoding: string;
    FSilentOutFile: string;
    FSourceStream: TFileStream;
    FIndexStream: TFileStream;
    FErrorText: string;
    procedure SyncBegin;
    procedure SyncEnd;
    procedure SyncEndEarly;
    function EncodeUtf8Base64(const S: string): string;
    function ExecuteRunFilePath: Boolean;
    function ExecuteLinePipePath: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TObject; const AScriptB64: string; ASendScript: Boolean;
      AUseRunFile: Boolean; AFromLine1, AToLine1, AFileTotalLines: Int64;
      const ASourceFileName, AIndexFileName, ADisplayEncoding,
      ASilentOutFile: string);
  end;

implementation

uses
  MainUnit, uI18n, uSmoothLoading, uTextEncoding;

function TailMacroOwnerForm(AOwner: TObject): TfrmMain;
begin
  Result := TfrmMain(AOwner);
end;

const
  INDEX_RECORD_SIZE = 20;
  MAX_LINE_LEN_DISPLAY = 2 * 1024 * 1024;

constructor TTailMacroOnNewLinesThread.Create(AOwner: TObject;
  const AScriptB64: string; ASendScript: Boolean; AUseRunFile: Boolean;
  AFromLine1, AToLine1, AFileTotalLines: Int64; const ASourceFileName,
  AIndexFileName, ADisplayEncoding, ASilentOutFile: string);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FOwner := AOwner;
  FScriptB64 := AScriptB64;
  FSendScript := ASendScript;
  FUseRunFile := AUseRunFile;
  FFromLine1 := AFromLine1;
  FToLine1 := AToLine1;
  FFileTotalLines := AFileTotalLines;
  FSourceFileName := ASourceFileName;
  FIndexFileName := AIndexFileName;
  FDisplayEncoding := ADisplayEncoding;
  FSilentOutFile := ASilentOutFile;
  FErrorText := '';
end;

procedure TTailMacroOnNewLinesThread.SyncBegin;
begin
  if Assigned(FOwner) then
    TailMacroOwnerForm(FOwner).BeginTailMacroBatch(Self);
end;

procedure TTailMacroOnNewLinesThread.SyncEnd;
begin
  if Assigned(FOwner) then
    TailMacroOwnerForm(FOwner).EndTailMacroSendPhase(FErrorText);
end;

procedure TTailMacroOnNewLinesThread.SyncEndEarly;
begin
  if Assigned(FOwner) and (FErrorText <> '') then
    TailMacroOwnerForm(FOwner).UpdateTailMacroStatus(FErrorText);
end;

function TTailMacroOnNewLinesThread.EncodeUtf8Base64(const S: string): string;
const
  B64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  SrcBytes: AnsiString;
  N, I2: Integer;
  B1, B2, B3: Byte;
begin
  SrcBytes := UTF8Encode(S);
  N := Length(SrcBytes);
  Result := '';
  I2 := 1;
  while I2 <= N do
  begin
    B1 := Ord(SrcBytes[I2]); Inc(I2);
    if I2 <= N then begin B2 := Ord(SrcBytes[I2]); Inc(I2); end else B2 := 0;
    if I2 <= N then begin B3 := Ord(SrcBytes[I2]); Inc(I2); end else B3 := 0;
    Result := Result +
      B64Chars[((B1 shr 2) and $3F) + 1] +
      B64Chars[(((B1 and $03) shl 4) or ((B2 shr 4) and $0F)) + 1] +
      B64Chars[(((B2 and $0F) shl 2) or ((B3 shr 6) and $03)) + 1] +
      B64Chars[(B3 and $3F) + 1];
  end;
  case N mod 3 of
    1: begin Result[Length(Result) - 1] := '='; Result[Length(Result)] := '='; end;
    2: Result[Length(Result)] := '=';
  end;
end;

function TTailMacroOnNewLinesThread.ExecuteRunFilePath: Boolean;
var
  PayloadText: string;
begin
  Result := False;
  PayloadText :=
    'SOURCE=' + FSourceFileName + #10 +
    'INDEX=' + FIndexFileName + #10 +
    'ENC=' + FDisplayEncoding + #10 +
    'FROM_LINE=' + IntToStr(FFromLine1) + #10 +
    'TO_LINE=' + IntToStr(FToLine1) + #10 +
    'TOTAL=' + IntToStr(FFileTotalLines) + #10 +
    'MAX_LINE_LEN=' + IntToStr(MAX_LINE_LEN_DISPLAY);
  if FSilentOutFile <> '' then
    PayloadText := PayloadText + #10 +
      'OUTFILE=' + FSilentOutFile + #10 +
      'SILENT_OUT=1';
  Result := TailMacroOwnerForm(FOwner).ScriptEngineWriteLine(
    'RUNFILE:' + EncodeUtf8Base64(PayloadText));
end;

function TTailMacroOnNewLinesThread.ExecuteLinePipePath: Boolean;
  function TryReadIndexOffset(const ALineNumber1Based: Int64; out AOffset: Int64): Boolean;
  var
    OffsetBuf: array[0..17] of AnsiChar;
    OffsetText: AnsiString;
    ReadCount: Integer;
  begin
    Result := False;
    AOffset := 0;
    if not Assigned(FIndexStream) then Exit;
    try
      FIndexStream.Seek((ALineNumber1Based - 1) * INDEX_RECORD_SIZE, soFromBeginning);
      ReadCount := FIndexStream.Read(OffsetBuf, SizeOf(OffsetBuf));
      if ReadCount < SizeOf(OffsetBuf) then Exit;
      SetString(OffsetText, PAnsiChar(@OffsetBuf[0]), SizeOf(OffsetBuf));
      AOffset := StrToInt64Def(Trim(string(OffsetText)), -1);
      if AOffset = -1 then Exit;
      AOffset := Abs(AOffset);
      Result := True;
    except
      Result := False;
    end;
  end;

  function ReadLineText(const ALineNumber1Based: Int64): string;
  var
    StartOffset, EndOffset: Int64;
    FullLineLen: Int64;
    LineLength: Integer;
    Buffer: AnsiString;
    BytesRead2: Integer;
  begin
    Result := '';
    if not TryReadIndexOffset(ALineNumber1Based, StartOffset) then Exit;
    if not TryReadIndexOffset(ALineNumber1Based + 1, EndOffset) then
      EndOffset := FSourceStream.Size + 1;
    EndOffset := Abs(EndOffset);
    if (EndOffset <= StartOffset) then Exit;
    FullLineLen := EndOffset - StartOffset;
    if FullLineLen <= 0 then Exit;
    if FullLineLen > MAX_LINE_LEN_DISPLAY then
      LineLength := MAX_LINE_LEN_DISPLAY
    else
      LineLength := FullLineLen;
    FSourceStream.Seek(StartOffset - 1, soFromBeginning);
    SetLength(Buffer, LineLength);
    BytesRead2 := FSourceStream.Read(Pointer(Buffer)^, LineLength);
    while (BytesRead2 > 0) and (Buffer[BytesRead2] in [#10, #13]) do
      Dec(BytesRead2);
    SetLength(Buffer, BytesRead2);
    Result := DisplayTextFromFileBytes(Buffer, FDisplayEncoding);
  end;

var
  LineNum, Total, Done: Int64;
  LineText: string;
  BatchStream: TMemoryStream;
  BatchLineCount: Integer;
begin
  Result := True;
  FSourceStream := nil;
  FIndexStream := nil;
  BatchStream := nil;
  if (FIndexFileName = '') or (not FileExists(FIndexFileName)) then
  begin
    FErrorText := TrText('Tail macro: line index not found - read the file (F5) first.');
    Result := False;
    Exit;
  end;
  try
    FSourceStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
    FIndexStream := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);
    BatchStream := TMemoryStream.Create;
    BatchLineCount := 0;
    Total := FToLine1 - FFromLine1 + 1;
    if Total <= 0 then
    begin
      TailMacroOwnerForm(FOwner).ScriptEngineWriteLine('DONE');
      Exit;
    end;
    Done := 0;
    LineNum := FFromLine1;
    while (LineNum <= FToLine1) and (not Terminated) do
    begin
      if TfrmSmoothLoading.CancelRequested then
      begin
        FErrorText := TrText('Tail macro cancelled.');
        Result := False;
        Break;
      end;
      LineText := ReadLineText(LineNum);
      if not TailMacroOwnerForm(FOwner).ScriptEngineQueueStdInLine(
        'LINE:' + IntToStr(LineNum) + ':' + LineText, BatchStream, BatchLineCount) then
      begin
        FErrorText := TrText('Broken pipe while sending lines.');
        Result := False;
        Break;
      end;
      Inc(Done);
      Inc(LineNum);
    end;
    if Result then
      if not TailMacroOwnerForm(FOwner).ScriptEngineFlushStdInBatch(
        BatchStream, BatchLineCount) then
      begin
        FErrorText := TrText('Broken pipe while sending lines.');
        Result := False;
      end;
    if Result then
      if not TailMacroOwnerForm(FOwner).ScriptEngineWriteLine('DONE') then
      begin
        FErrorText := TrText('Broken pipe while sending lines.');
        Result := False;
      end;
  finally
    if Assigned(BatchStream) then FreeAndNil(BatchStream);
    if Assigned(FIndexStream) then FreeAndNil(FIndexStream);
    if Assigned(FSourceStream) then FreeAndNil(FSourceStream);
  end;
end;

procedure TTailMacroOnNewLinesThread.Execute;
begin
  inherited;
  if (not Assigned(FOwner)) or
     (not TailMacroOwnerForm(FOwner).CanStartTailMacroBatch(Self)) then
  begin
    FErrorText := TrText('Another script or tail macro is already running.');
    Synchronize(SyncEndEarly);
    Exit;
  end;
  Synchronize(SyncBegin);
  try
    if not Assigned(FOwner) then Exit;
    if not TailMacroOwnerForm(FOwner).IsScriptEngineProcessRunning then
      TailMacroOwnerForm(FOwner).StartScriptEngineProcess;
    if (not Assigned(FOwner)) or
       (not TailMacroOwnerForm(FOwner).IsScriptEngineProcessRunning) then
    begin
      FErrorText := TrText('Script engine is not running.');
      Exit;
    end;
    if FSendScript then
      if not TailMacroOwnerForm(FOwner).ScriptEngineWriteLine('SCRIPT:' + FScriptB64) then
      begin
        FErrorText := TrText('Could not send script to engine.');
        Exit;
      end;
    if FUseRunFile then
    begin
      if not ExecuteRunFilePath then
        FErrorText := TrText('Could not start fast tail processing in script engine.');
    end
    else
    begin
      if not ExecuteLinePipePath then
        if FErrorText = '' then
          FErrorText := TrText('Broken pipe while sending lines.');
    end;
  except
    on E: Exception do
      FErrorText := E.Message;
  end;
  Synchronize(SyncEnd);
end;

end.
