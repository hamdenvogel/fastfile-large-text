unit uFileFormatConvert;
{ Line-ending and text-encoding detect + streaming convert (Notepad++-style). }

interface

uses
  SysUtils, Classes, Windows;

type
  TLineEndingKind = (lekUnknown, lekWindows, lekUnix, lekMac, lekMixed);

function DetectLineEndingFromFile(const AFileName: string): TLineEndingKind;
function DetectLineEndingFromBytes(const Sample: AnsiString): TLineEndingKind;
function LineEndingKindCaption(AKind: TLineEndingKind): string;
function LineEndingKindShort(AKind: TLineEndingKind): string;
function LineEndingBytesForKind(AKind: TLineEndingKind): AnsiString;
function DefaultEolKindFromName(const AName: string): TLineEndingKind;
function DefaultEolKindToName(AKind: TLineEndingKind): string;

function EncodingWantsBom(const Enc: string): Boolean;
function EncodingIdForConvert(const Enc: string; AWithBom: Boolean): string;
function EncodingDisplayCaption(const Enc: string): string;

function ConvertTextFileLineEndings(const ASrcPath, ADstPath: string;
  ATarget: TLineEndingKind; const AEncoding: string; out AError: string): Boolean;
function ConvertTextFileEncoding(const ASrcPath, ADstPath: string;
  const ASrcEnc, ADstEnc: string; out AError: string): Boolean;

{ Notepad++-style character-set groups (encode-in / convert-to). }
function FileFormatCharsetGroupCount: Integer;
function FileFormatCharsetGroupCaptionKey(AGroup: Integer): string;
function FileFormatCharsetCount(AGroup: Integer): Integer;
function FileFormatCharsetId(AGroup, AIndex: Integer): string;
function FileFormatCharsetCaption(AGroup, AIndex: Integer): string;

implementation

uses
  uTextEncoding, uI18n, uPosBMH;

const
  CHUNK_SIZE = 1024 * 1024;

type
  TCharsetEntry = record
    Id: string;
    Caption: string;
  end;
  TCharsetGroupDef = record
    CaptionKey: string;
    Items: array of TCharsetEntry;
  end;

var
  GCharsetGroups: array of TCharsetGroupDef;
  GCharsetReady: Boolean = False;

procedure EnsureCharsetCatalog;
  procedure AddGroup(const CapKey: string);
  var
    G: Integer;
  begin
    G := Length(GCharsetGroups);
    SetLength(GCharsetGroups, G + 1);
    GCharsetGroups[G].CaptionKey := CapKey;
    SetLength(GCharsetGroups[G].Items, 0);
  end;
  procedure AddItem(const AId, ACap: string);
  var
    G, N: Integer;
  begin
    G := High(GCharsetGroups);
    if G < 0 then Exit;
    N := Length(GCharsetGroups[G].Items);
    SetLength(GCharsetGroups[G].Items, N + 1);
    GCharsetGroups[G].Items[N].Id := AId;
    GCharsetGroups[G].Items[N].Caption := ACap;
  end;
begin
  if GCharsetReady then Exit;
  GCharsetReady := True;
  SetLength(GCharsetGroups, 0);
  AddGroup('FileFormat.CS.Western');
  AddItem('CP1252', 'Western European (Windows-1252)');
  AddItem('ISO-8859-1', 'Western European (ISO-8859-1)');
  AddItem('ISO-8859-15', 'Western European (ISO-8859-15)');
  AddItem('CP850', 'Western European (OEM 850)');
  AddItem('CP437', 'OEM-US');
  AddItem('MAC-ROMAN', 'Macintosh Roman');
  AddGroup('FileFormat.CS.Central');
  AddItem('CP1250', 'Central European (Windows-1250)');
  AddItem('ISO-8859-2', 'Central European (ISO-8859-2)');
  AddItem('CP852', 'Central European (OEM 852)');
  AddGroup('FileFormat.CS.Baltic');
  AddItem('CP1257', 'Baltic (Windows-1257)');
  AddItem('ISO-8859-13', 'Baltic (ISO-8859-13)');
  AddGroup('FileFormat.CS.Cyrillic');
  AddItem('CP1251', 'Cyrillic (Windows-1251)');
  AddItem('KOI8-R', 'Cyrillic (KOI8-R)');
  AddItem('KOI8-U', 'Cyrillic (KOI8-U)');
  AddItem('ISO-8859-5', 'Cyrillic (ISO-8859-5)');
  AddItem('CP866', 'Cyrillic (OEM 866)');
  AddGroup('FileFormat.CS.Greek');
  AddItem('CP1253', 'Greek (Windows-1253)');
  AddItem('ISO-8859-7', 'Greek (ISO-8859-7)');
  AddGroup('FileFormat.CS.Turkish');
  AddItem('CP1254', 'Turkish (Windows-1254)');
  AddItem('ISO-8859-9', 'Turkish (ISO-8859-9)');
  AddGroup('FileFormat.CS.Hebrew');
  AddItem('CP1255', 'Hebrew (Windows-1255)');
  AddItem('ISO-8859-8', 'Hebrew (ISO-8859-8)');
  AddGroup('FileFormat.CS.Arabic');
  AddItem('CP1256', 'Arabic (Windows-1256)');
  AddItem('ISO-8859-6', 'Arabic (ISO-8859-6)');
  AddGroup('FileFormat.CS.Vietnamese');
  AddItem('CP1258', 'Vietnamese (Windows-1258)');
  AddGroup('FileFormat.CS.Thai');
  AddItem('CP874', 'Thai (Windows-874)');
  AddGroup('FileFormat.CS.CJK');
  AddItem('CP932', 'Japanese (Shift-JIS)');
  AddItem('CP936', 'Chinese Simplified (GBK)');
  AddItem('GB18030', 'Chinese Simplified (GB18030)');
  AddItem('CP949', 'Korean (EUC-KR)');
  AddItem('CP950', 'Chinese Traditional (Big5)');
end;

function FileFormatCharsetGroupCount: Integer;
begin
  EnsureCharsetCatalog;
  Result := Length(GCharsetGroups);
end;

function FileFormatCharsetGroupCaptionKey(AGroup: Integer): string;
begin
  EnsureCharsetCatalog;
  if (AGroup < 0) or (AGroup >= Length(GCharsetGroups)) then
    Result := ''
  else
    Result := GCharsetGroups[AGroup].CaptionKey;
end;

function FileFormatCharsetCount(AGroup: Integer): Integer;
begin
  EnsureCharsetCatalog;
  if (AGroup < 0) or (AGroup >= Length(GCharsetGroups)) then
    Result := 0
  else
    Result := Length(GCharsetGroups[AGroup].Items);
end;

function FileFormatCharsetId(AGroup, AIndex: Integer): string;
begin
  EnsureCharsetCatalog;
  Result := '';
  if (AGroup < 0) or (AGroup >= Length(GCharsetGroups)) then Exit;
  if (AIndex < 0) or (AIndex >= Length(GCharsetGroups[AGroup].Items)) then Exit;
  Result := GCharsetGroups[AGroup].Items[AIndex].Id;
end;

function FileFormatCharsetCaption(AGroup, AIndex: Integer): string;
begin
  EnsureCharsetCatalog;
  Result := '';
  if (AGroup < 0) or (AGroup >= Length(GCharsetGroups)) then Exit;
  if (AIndex < 0) or (AIndex >= Length(GCharsetGroups[AGroup].Items)) then Exit;
  Result := GCharsetGroups[AGroup].Items[AIndex].Caption;
end;

function EncodingWantsBom(const Enc: string): Boolean;
begin
  Result := PosBMH('BOM', UpperCase(Trim(Enc))) > 0;
end;

function EncodingIdForConvert(const Enc: string; AWithBom: Boolean): string;
var
  U: string;
  CP: UINT;
begin
  U := UpperCase(Trim(Enc));
  if IsUtf8Encoding(U) then
  begin
    if AWithBom then
      Result := 'UTF-8 (BOM)'
    else
      Result := 'UTF-8 (no BOM)';
  end
  else if IsUtf16BEEncoding(U) then
    Result := 'UTF-16 BE'
  else if IsUtf16LEEncoding(U) or (PosBMH('UTF-16', U) > 0) or (PosBMH('UCS-2', U) > 0) then
    Result := 'UTF-16 LE'
  else if IsUtf32BEEncoding(U) then
    Result := 'UTF-32 BE'
  else if IsUtf32LEEncoding(U) then
    Result := 'UTF-32 LE'
  else if TryGetCodePageFromEncoding(U, CP) then
  begin
    if CP = CP_ACP then
      Result := 'ANSI'
    else
      Result := NormalizeCodePageEncodingId(CP);
  end
  else
    Result := 'ANSI';
end;

function EncodingDisplayCaption(const Enc: string): string;
var
  U: string;
  CP: UINT;
begin
  U := UpperCase(Trim(Enc));
  if U = '' then
    Result := 'ANSI'
  else if PosBMH('UTF-8', U) > 0 then
  begin
    if EncodingWantsBom(U) then
      Result := 'UTF-8 BOM'
    else
      Result := 'UTF-8';
  end
  else if IsUtf16BEEncoding(U) then
    Result := 'UTF-16 BE'
  else if IsUtf16LEEncoding(U) or (PosBMH('UTF-16', U) > 0) then
    Result := 'UTF-16 LE'
  else if IsUtf32BEEncoding(U) then
    Result := 'UTF-32 BE'
  else if IsUtf32LEEncoding(U) then
    Result := 'UTF-32 LE'
  else if TryGetCodePageFromEncoding(U, CP) and (CP <> CP_ACP) then
    Result := NormalizeCodePageEncodingId(CP)
  else
    Result := Trim(Enc);
end;

function LineEndingKindShort(AKind: TLineEndingKind): string;
begin
  case AKind of
    lekWindows: Result := 'CR LF';
    lekUnix: Result := 'LF';
    lekMac: Result := 'CR';
    lekMixed: Result := 'Mixed';
  else
    Result := '?';
  end;
end;

function LineEndingBytesForKind(AKind: TLineEndingKind): AnsiString;
begin
  case AKind of
    lekUnix: Result := AnsiChar(#10);
    lekMac: Result := AnsiChar(#13);
  else
    Result := AnsiString(#13#10);
  end;
end;

function DefaultEolKindFromName(const AName: string): TLineEndingKind;
var
  U: string;
begin
  U := UpperCase(Trim(AName));
  if (U = 'UNIX') or (U = 'LF') or (U = '1') then
    Result := lekUnix
  else if (U = 'MAC') or (U = 'MACINTOSH') or (U = 'CR') or (U = '2') then
    Result := lekMac
  else
    Result := lekWindows;
end;

function DefaultEolKindToName(AKind: TLineEndingKind): string;
begin
  case AKind of
    lekUnix: Result := 'Unix';
    lekMac: Result := 'Mac';
  else
    Result := 'Windows';
  end;
end;

function LineEndingKindCaption(AKind: TLineEndingKind): string;
begin
  case AKind of
    lekWindows:
      Result := TrText('FileFormat.EOL.Windows');
    lekUnix:
      Result := TrText('FileFormat.EOL.Unix');
    lekMac:
      Result := TrText('FileFormat.EOL.Mac');
    lekMixed:
      Result := TrText('FileFormat.EOL.Mixed');
  else
    Result := TrText('FileFormat.EOL.Unknown');
  end;
end;

function DetectLineEndingFromBytes(const Sample: AnsiString): TLineEndingKind;
var
  I, N: Integer;
  Crlf, Cr, Lf: Integer;
  B: Byte;
begin
  Result := lekUnknown;
  N := Length(Sample);
  if N = 0 then Exit;
  Crlf := 0;
  Cr := 0;
  Lf := 0;
  I := 1;
  while I <= N do
  begin
    B := Ord(Sample[I]);
    if B = 13 then
    begin
      if (I < N) and (Ord(Sample[I + 1]) = 10) then
      begin
        Inc(Crlf);
        Inc(I, 2);
        Continue;
      end;
      Inc(Cr);
    end
    else if B = 10 then
      Inc(Lf);
    Inc(I);
  end;
  if (Crlf = 0) and (Cr = 0) and (Lf = 0) then
    Exit;
  if (Crlf > 0) and (Cr = 0) and (Lf = 0) then
    Result := lekWindows
  else if (Lf > 0) and (Crlf = 0) and (Cr = 0) then
    Result := lekUnix
  else if (Cr > 0) and (Crlf = 0) and (Lf = 0) then
    Result := lekMac
  else if (Crlf >= Cr) and (Crlf >= Lf) then
  begin
    if (Cr + Lf) > (Crlf div 20 + 1) then
      Result := lekMixed
    else
      Result := lekWindows;
  end
  else if (Lf >= Cr) and (Lf >= Crlf) then
  begin
    if (Cr + Crlf) > (Lf div 20 + 1) then
      Result := lekMixed
    else
      Result := lekUnix;
  end
  else
  begin
    if (Lf + Crlf) > (Cr div 20 + 1) then
      Result := lekMixed
    else
      Result := lekMac;
  end;
end;

function DetectLineEndingFromFile(const AFileName: string): TLineEndingKind;
var
  F: TFileStream;
  Sample: AnsiString;
  N: Integer;
  Sz: Int64;
  SampleLen: Integer;
begin
  Result := lekUnknown;
  if (AFileName = '') or (not FileExists(AFileName)) then Exit;
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Sz := F.Size;
      if Sz <= 0 then Exit;
      if Sz > 65536 then SampleLen := 65536 else SampleLen := Integer(Sz);
      SetLength(Sample, SampleLen);
      N := F.Read(Pointer(Sample)^, SampleLen);
      SetLength(Sample, N);
      { Skip BOM for EOL scan on UTF-8 }
      if (N >= 3) and (Ord(Sample[1]) = $EF) and (Ord(Sample[2]) = $BB) and
         (Ord(Sample[3]) = $BF) then
        Sample := Copy(Sample, 4, MaxInt);
      Result := DetectLineEndingFromBytes(Sample);
    finally
      F.Free;
    end;
  except
    Result := lekUnknown;
  end;
end;

function EolBytes8(ATarget: TLineEndingKind): AnsiString;
begin
  case ATarget of
    lekUnix: Result := AnsiChar(#10);
    lekMac: Result := AnsiChar(#13);
  else
    Result := AnsiString(#13#10); { Windows default }
  end;
end;

function EolBytes16LE(ATarget: TLineEndingKind): AnsiString;
begin
  case ATarget of
    lekUnix: Result := AnsiChar(#10) + AnsiChar(#0);
    lekMac: Result := AnsiChar(#13) + AnsiChar(#0);
  else
    Result := AnsiChar(#13) + AnsiChar(#0) + AnsiChar(#10) + AnsiChar(#0);
  end;
end;

function EolBytes16BE(ATarget: TLineEndingKind): AnsiString;
begin
  case ATarget of
    lekUnix: Result := AnsiChar(#0) + AnsiChar(#10);
    lekMac: Result := AnsiChar(#0) + AnsiChar(#13);
  else
    Result := AnsiChar(#0) + AnsiChar(#13) + AnsiChar(#0) + AnsiChar(#10);
  end;
end;

function BomBytesForEncoding(const Enc: string): AnsiString;
var
  U: string;
begin
  Result := '';
  U := UpperCase(Trim(Enc));
  if not EncodingWantsBom(U) then
  begin
    { Convert targets that always include BOM in N++ style for UTF-16/32 }
    if IsUtf16BEEncoding(U) then
      Result := AnsiChar($FE) + AnsiChar($FF)
    else if IsUtf16LEEncoding(U) or ((PosBMH('UTF-16', U) > 0) and (PosBMH('BE', U) = 0)) then
      Result := AnsiChar($FF) + AnsiChar($FE)
    else if IsUtf32BEEncoding(U) then
      Result := AnsiChar(#0) + AnsiChar(#0) + AnsiChar($FE) + AnsiChar($FF)
    else if IsUtf32LEEncoding(U) then
      Result := AnsiChar($FF) + AnsiChar($FE) + AnsiChar(#0) + AnsiChar(#0)
    else if IsUtf8Encoding(U) and EncodingWantsBom(U) then
      Result := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF);
    Exit;
  end;
  if IsUtf8Encoding(U) then
    Result := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF)
  else if IsUtf16BEEncoding(U) then
    Result := AnsiChar($FE) + AnsiChar($FF)
  else if IsUtf16LEEncoding(U) or (PosBMH('UTF-16', U) > 0) then
    Result := AnsiChar($FF) + AnsiChar($FE)
  else if IsUtf32BEEncoding(U) then
    Result := AnsiChar(#0) + AnsiChar(#0) + AnsiChar($FE) + AnsiChar($FF)
  else if IsUtf32LEEncoding(U) then
    Result := AnsiChar($FF) + AnsiChar($FE) + AnsiChar(#0) + AnsiChar(#0);
end;

function SkipBomSize(const Enc: string; const Head: AnsiString): Integer;
var
  U: string;
begin
  Result := 0;
  U := UpperCase(Trim(Enc));
  if Length(Head) >= 3 then
    if (Ord(Head[1]) = $EF) and (Ord(Head[2]) = $BB) and (Ord(Head[3]) = $BF) then
      if IsUtf8Encoding(U) or (U = '') then
      begin
        Result := 3;
        Exit;
      end;
  if Length(Head) >= 2 then
  begin
    if (Ord(Head[1]) = $FF) and (Ord(Head[2]) = $FE) then
    begin
      if (Length(Head) >= 4) and (Ord(Head[3]) = 0) and (Ord(Head[4]) = 0) and
         IsUtf32LEEncoding(U) then
        Result := 4
      else
        Result := 2;
      Exit;
    end;
    if (Ord(Head[1]) = $FE) and (Ord(Head[2]) = $FF) then
    begin
      Result := 2;
      Exit;
    end;
  end;
  if Length(Head) >= 4 then
    if (Ord(Head[1]) = 0) and (Ord(Head[2]) = 0) and
       (Ord(Head[3]) = $FE) and (Ord(Head[4]) = $FF) then
      Result := 4;
end;

function ConvertEol8Bit(Src, Dst: TStream; ATarget: TLineEndingKind;
  out AError: string): Boolean;
var
  Buf: AnsiString;
  OutBuf, Eol: AnsiString;
  N, I, OutLen: Integer;
  B: Byte;
  PendCr: Boolean;

  procedure EnsureOut(ANeed: Integer);
  begin
    if OutLen + ANeed > Length(OutBuf) then
      SetLength(OutBuf, Length(OutBuf) + CHUNK_SIZE + ANeed);
  end;

  procedure EmitEol;
  begin
    EnsureOut(Length(Eol));
    Move(Pointer(Eol)^, OutBuf[OutLen + 1], Length(Eol));
    Inc(OutLen, Length(Eol));
  end;

begin
  Result := False;
  AError := '';
  Eol := EolBytes8(ATarget);
  PendCr := False;
  SetLength(Buf, CHUNK_SIZE);
  SetLength(OutBuf, CHUNK_SIZE + 16);
  try
    repeat
      N := Src.Read(Pointer(Buf)^, CHUNK_SIZE);
      if N <= 0 then Break;
      OutLen := 0;
      I := 1;
      while I <= N do
      begin
        B := Ord(Buf[I]);
        if PendCr then
        begin
          PendCr := False;
          if B = 10 then
          begin
            EmitEol;
            Inc(I);
            Continue;
          end;
          EmitEol;
        end;
        if B = 13 then
        begin
          PendCr := True;
          Inc(I);
          Continue;
        end;
        if B = 10 then
        begin
          EmitEol;
          Inc(I);
          Continue;
        end;
        EnsureOut(1);
        Inc(OutLen);
        OutBuf[OutLen] := Buf[I];
        Inc(I);
      end;
      if OutLen > 0 then
        Dst.WriteBuffer(OutBuf[1], OutLen);
    until N < CHUNK_SIZE;
    if PendCr then
      Dst.WriteBuffer(Pointer(Eol)^, Length(Eol));
    Result := True;
  except
    on E: Exception do
      AError := E.Message;
  end;
end;

function ConvertEolUtf16(Src, Dst: TStream; ATarget: TLineEndingKind;
  ABigEndian: Boolean; out AError: string): Boolean;
var
  Buf, OutBuf, Eol: AnsiString;
  N, I, OutLen: Integer;
  B0, B1: Byte;
  IsCr, IsLf, PendCr: Boolean;
begin
  Result := False;
  AError := '';
  if ABigEndian then
    Eol := EolBytes16BE(ATarget)
  else
    Eol := EolBytes16LE(ATarget);
  PendCr := False;
  SetLength(Buf, CHUNK_SIZE);
  if (CHUNK_SIZE mod 2) <> 0 then
    SetLength(Buf, CHUNK_SIZE - 1);
  SetLength(OutBuf, Length(Buf) + 32);
  try
    repeat
      N := Src.Read(Pointer(Buf)^, Length(Buf));
      if N <= 0 then Break;
      if (N mod 2) <> 0 then
      begin
        AError := 'Truncated UTF-16 data';
        Exit;
      end;
      OutLen := 0;
      I := 1;
      while I + 1 <= N do
      begin
        B0 := Ord(Buf[I]);
        B1 := Ord(Buf[I + 1]);
        if ABigEndian then
        begin
          IsCr := (B0 = 0) and (B1 = 13);
          IsLf := (B0 = 0) and (B1 = 10);
        end
        else
        begin
          IsCr := (B0 = 13) and (B1 = 0);
          IsLf := (B0 = 10) and (B1 = 0);
        end;
        if PendCr then
        begin
          PendCr := False;
          if IsLf then
          begin
            Move(Pointer(Eol)^, OutBuf[OutLen + 1], Length(Eol));
            Inc(OutLen, Length(Eol));
            Inc(I, 2);
            Continue;
          end;
          Move(Pointer(Eol)^, OutBuf[OutLen + 1], Length(Eol));
          Inc(OutLen, Length(Eol));
        end;
        if IsCr then
        begin
          PendCr := True;
          Inc(I, 2);
          Continue;
        end;
        if IsLf then
        begin
          Move(Pointer(Eol)^, OutBuf[OutLen + 1], Length(Eol));
          Inc(OutLen, Length(Eol));
          Inc(I, 2);
          Continue;
        end;
        if OutLen + 2 > Length(OutBuf) then
          SetLength(OutBuf, Length(OutBuf) + CHUNK_SIZE);
        OutBuf[OutLen + 1] := Buf[I];
        OutBuf[OutLen + 2] := Buf[I + 1];
        Inc(OutLen, 2);
        Inc(I, 2);
      end;
      if OutLen > 0 then
        Dst.WriteBuffer(OutBuf[1], OutLen);
    until N < Length(Buf);
    if PendCr then
      Dst.WriteBuffer(Pointer(Eol)^, Length(Eol));
    Result := True;
  except
    on E: Exception do
      AError := E.Message;
  end;
end;

function ConvertTextFileLineEndings(const ASrcPath, ADstPath: string;
  ATarget: TLineEndingKind; const AEncoding: string; out AError: string): Boolean;
var
  Src, Dst: TFileStream;
  Head: AnsiString;
  Skip: Integer;
  U: string;
  Bom: AnsiString;
  TmpUtf8, TmpEol: string;
begin
  Result := False;
  AError := '';
  if ATarget = lekUnknown then ATarget := lekWindows;
  if ATarget = lekMixed then ATarget := lekWindows;
  U := UpperCase(Trim(AEncoding));

  { UTF-32: bridge through UTF-8 (rare; keeps converter simple). }
  if IsUtf32LEEncoding(U) or IsUtf32BEEncoding(U) then
  begin
    TmpUtf8 := ADstPath + '.eol32.u8.tmp';
    TmpEol := ADstPath + '.eol32.eol.tmp';
    try
      if not ConvertTextFileEncoding(ASrcPath, TmpUtf8, AEncoding, 'UTF-8 (no BOM)', AError) then
        Exit;
      if not ConvertTextFileLineEndings(TmpUtf8, TmpEol, ATarget, 'UTF-8 (no BOM)', AError) then
        Exit;
      Result := ConvertTextFileEncoding(TmpEol, ADstPath, 'UTF-8 (no BOM)', AEncoding, AError);
    finally
      if FileExists(TmpUtf8) then SysUtils.DeleteFile(TmpUtf8);
      if FileExists(TmpEol) then SysUtils.DeleteFile(TmpEol);
    end;
    Exit;
  end;

  try
    Src := TFileStream.Create(ASrcPath, fmOpenRead or fmShareDenyNone);
    try
      Dst := TFileStream.Create(ADstPath, fmCreate);
      try
        SetLength(Head, 4);
        Skip := Src.Read(Pointer(Head)^, 4);
        SetLength(Head, Skip);
        Skip := SkipBomSize(AEncoding, Head);
        Bom := '';
        if Skip > 0 then
          Bom := Copy(Head, 1, Skip);
        if Bom <> '' then
          Dst.WriteBuffer(Pointer(Bom)^, Length(Bom));
        Src.Position := Skip;

        if IsUtf16BEEncoding(U) then
          Result := ConvertEolUtf16(Src, Dst, ATarget, True, AError)
        else if IsUtf16LEEncoding(U) or (PosBMH('UTF-16', U) > 0) then
          Result := ConvertEolUtf16(Src, Dst, ATarget, False, AError)
        else
          Result := ConvertEol8Bit(Src, Dst, ATarget, AError);
      finally
        Dst.Free;
      end;
    finally
      Src.Free;
    end;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;

function Utf8CarryBytes(const Buf: AnsiString): Integer;
{ How many trailing bytes of an incomplete UTF-8 sequence to keep. }
var
  N, I, Need: Integer;
  B: Byte;
begin
  Result := 0;
  N := Length(Buf);
  if N = 0 then Exit;
  I := N;
  while (I >= 1) and (I > N - 3) and ((Ord(Buf[I]) and $C0) = $80) do
    Dec(I);
  if I < 1 then Exit;
  B := Ord(Buf[I]);
  if (B and $80) = 0 then Exit;
  if (B and $E0) = $C0 then Need := 2
  else if (B and $F0) = $E0 then Need := 3
  else if (B and $F8) = $F0 then Need := 4
  else Exit;
  if (N - I + 1) < Need then
    Result := N - I + 1;
end;

function ConvertTextFileEncoding(const ASrcPath, ADstPath: string;
  const ASrcEnc, ADstEnc: string; out AError: string): Boolean;
var
  Src, Dst: TFileStream;
  Head, Chunk, Carry, Piece, OutBytes, Bom: AnsiString;
  Skip, N, Keep: Integer;
  WidePiece: string;
  SrcU, DstU: string;
  SrcCP: UINT;
  SrcIsCp: Boolean;
begin
  Result := False;
  AError := '';
  SrcU := Trim(ASrcEnc);
  DstU := Trim(ADstEnc);
  if SrcU = '' then SrcU := 'ANSI';
  if DstU = '' then DstU := 'ANSI';
  SrcIsCp := TryGetCodePageFromEncoding(SrcU, SrcCP) and (not IsUnicodeFileEncoding(SrcU));
  try
    Src := TFileStream.Create(ASrcPath, fmOpenRead or fmShareDenyNone);
    try
      Dst := TFileStream.Create(ADstPath, fmCreate);
      try
        SetLength(Head, 4);
        Skip := Src.Read(Pointer(Head)^, 4);
        SetLength(Head, Skip);
        Skip := SkipBomSize(SrcU, Head);
        Src.Position := Skip;

        Bom := '';
        if EncodingWantsBom(DstU) or IsUtf16LEEncoding(DstU) or IsUtf16BEEncoding(DstU) or
           IsUtf32LEEncoding(DstU) or IsUtf32BEEncoding(DstU) then
        begin
          if IsUtf8Encoding(DstU) and EncodingWantsBom(DstU) then
            Bom := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF)
          else if IsUtf8Encoding(DstU) then
            Bom := ''
          else
            Bom := BomBytesForEncoding(DstU);
          { UTF-16/32 convert always write BOM (Notepad++ style) }
          if IsUtf16BEEncoding(DstU) then
            Bom := AnsiChar($FE) + AnsiChar($FF)
          else if IsUtf16LEEncoding(DstU) or
                  ((PosBMH('UTF-16', UpperCase(DstU)) > 0) and
                   (PosBMH('BE', UpperCase(DstU)) = 0)) then
            Bom := AnsiChar($FF) + AnsiChar($FE)
          else if IsUtf32BEEncoding(DstU) then
            Bom := AnsiChar(#0) + AnsiChar(#0) + AnsiChar($FE) + AnsiChar($FF)
          else if IsUtf32LEEncoding(DstU) then
            Bom := AnsiChar($FF) + AnsiChar($FE) + AnsiChar(#0) + AnsiChar(#0);
        end
        else if IsUtf8Encoding(DstU) and EncodingWantsBom(DstU) then
          Bom := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF);

        if (PosBMH('UTF-8 (BOM)', UpperCase(DstU)) > 0) or
           (SameText(DstU, 'UTF-8 BOM')) then
          Bom := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF);

        if Bom <> '' then
          Dst.WriteBuffer(Pointer(Bom)^, Length(Bom));

        Carry := '';
        SetLength(Chunk, CHUNK_SIZE);
        repeat
          N := Src.Read(Pointer(Chunk)^, CHUNK_SIZE);
          if N <= 0 then Break;
          SetLength(Chunk, N);
          Piece := Carry + Chunk;
          Carry := '';
          if IsUtf8Encoding(SrcU) then
          begin
            Keep := Utf8CarryBytes(Piece);
            if Keep > 0 then
            begin
              Carry := Copy(Piece, Length(Piece) - Keep + 1, Keep);
              SetLength(Piece, Length(Piece) - Keep);
            end;
          end
          else if IsUtf16LEEncoding(SrcU) or IsUtf16BEEncoding(SrcU) or
                  (PosBMH('UTF-16', UpperCase(SrcU)) > 0) then
          begin
            if (Length(Piece) mod 2) <> 0 then
            begin
              Carry := Copy(Piece, Length(Piece), 1);
              SetLength(Piece, Length(Piece) - 1);
            end;
          end
          else if IsUtf32LEEncoding(SrcU) or IsUtf32BEEncoding(SrcU) then
          begin
            Keep := Length(Piece) mod 4;
            if Keep > 0 then
            begin
              Carry := Copy(Piece, Length(Piece) - Keep + 1, Keep);
              SetLength(Piece, Length(Piece) - Keep);
            end;
          end
          else if SrcIsCp then
          begin
            Keep := MbcsIncompleteTrailingBytes(Piece, SrcCP);
            if Keep > 0 then
            begin
              Carry := Copy(Piece, Length(Piece) - Keep + 1, Keep);
              SetLength(Piece, Length(Piece) - Keep);
            end;
          end;

          if Piece <> '' then
          begin
            WidePiece := FileBytesToUnicodeText(Piece, SrcU);
            OutBytes := UnicodeTextToFileBytes(WidePiece, DstU);
            if OutBytes <> '' then
              Dst.WriteBuffer(Pointer(OutBytes)^, Length(OutBytes));
          end;
          SetLength(Chunk, CHUNK_SIZE);
        until N < CHUNK_SIZE;

        if Carry <> '' then
        begin
          WidePiece := FileBytesToUnicodeText(Carry, SrcU);
          OutBytes := UnicodeTextToFileBytes(WidePiece, DstU);
          if OutBytes <> '' then
            Dst.WriteBuffer(Pointer(OutBytes)^, Length(OutBytes));
        end;
        Result := True;
      finally
        Dst.Free;
      end;
    finally
      Src.Free;
    end;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := False;
    end;
  end;
end;

end.
