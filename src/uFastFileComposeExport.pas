unit uFastFileComposeExport;

{
  Plain-text -> RTF / DOCX / ODT / PDF for assistant compose.
  DOCX/ODT are minimal Office Open XML / ODF packages (System.Zip).
  PDF is a simple multi-page text PDF (WinAnsi / Latin-1).
}

interface

uses
  SysUtils, Classes, System.Zip;

type
  EPdfUnsupportedUnicode = class(Exception);

function WrapPlainTextAsRtf(const AText: string): string;
function BuildDocxPackage(const AText: string): TBytes;
function BuildOdtPackage(const AText: string): TBytes;
function BuildSimplePdf(const AText: string): TBytes;
function EncodeComposePayload(const AExt, APlainOrRaw: string): TBytes;
function TryExtractComposePlainText(const APath: string; out AText: string): Boolean;
function IsRichComposeExtension(const AExt: string): Boolean;

implementation

uses
  Windows;

function XmlEscape(const S: string): string;
var
  i: Integer;
  Ch: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    Ch := S[i];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&apos;';
    else
      if Ord(Ch) < 32 then
      begin
        if Ch = #9 then
          Result := Result + ' '
        else if (Ch = #10) or (Ch = #13) then
          { handled by line split }
        else
          Result := Result + ' ';
      end
      else
        Result := Result + Ch;
    end;
  end;
end;

function WrapPlainTextAsRtf(const AText: string): string;
var
  i, w: Integer;
  Ch: Char;
  Body: string;
begin
  Body := '';
  for i := 1 to Length(AText) do
  begin
    Ch := AText[i];
    if Ch = '\' then
      Body := Body + '\\'
    else if Ch = '{' then
      Body := Body + '\{'
    else if Ch = '}' then
      Body := Body + '\}'
    else if Ch = #13 then
      { skip }
    else if Ch = #10 then
      Body := Body + '\par' + #13#10
    else
    begin
      w := Ord(Ch);
      if w < 128 then
        Body := Body + Ch
      else
        Body := Body + '\u' + IntToStr(w) + '?';
    end;
  end;
  Result :=
    '{\rtf1\ansi\ansicpg1252\deff0{\fonttbl{\f0\fswiss Arial;}}' + #13#10 +
    '\f0\fs22 ' + Body + '}';
end;

function SplitLines(const S: string): TArray<string>;
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    SL.Text := StringReplace(S, #13#10, #10, [rfReplaceAll]);
    SL.Text := StringReplace(SL.Text, #13, #10, [rfReplaceAll]);
    SetLength(Result, SL.Count);
    for i := 0 to SL.Count - 1 do
      Result[i] := SL[i];
  finally
    SL.Free;
  end;
end;

procedure AppendPdfWrappedLine(var Dest: TArray<string>; const Line: string;
  MaxChars: Integer);
{ Word-wrap so PDF Helvetica lines stay inside the right margin (no silent trim). }
var
  Rest: string;
  n, Cut, i, MinCut: Integer;
begin
  if MaxChars < 20 then
    MaxChars := 20;
  Rest := Line;
  if Rest = '' then
  begin
    n := Length(Dest);
    SetLength(Dest, n + 1);
    Dest[n] := '';
    Exit;
  end;
  while Rest <> '' do
  begin
    if Length(Rest) <= MaxChars then
    begin
      n := Length(Dest);
      SetLength(Dest, n + 1);
      Dest[n] := Rest;
      Exit;
    end;
    MinCut := MaxChars div 2;
    if MinCut < 1 then
      MinCut := 1;
    Cut := 0;
    for i := MaxChars downto MinCut do
      if Rest[i] = ' ' then
      begin
        Cut := i;
        Break;
      end;
    n := Length(Dest);
    SetLength(Dest, n + 1);
    if Cut > 1 then
    begin
      Dest[n] := Copy(Rest, 1, Cut - 1);
      Rest := Copy(Rest, Cut + 1, MaxInt);
    end
    else
    begin
      Dest[n] := Copy(Rest, 1, MaxChars);
      Rest := Copy(Rest, MaxChars + 1, MaxInt);
    end;
  end;
end;

function WrapLinesForPdf(const Src: TArray<string>; MaxChars: Integer): TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  if Length(Src) = 0 then
  begin
    SetLength(Result, 1);
    Result[0] := '';
    Exit;
  end;
  for i := 0 to High(Src) do
    AppendPdfWrappedLine(Result, Src[i], MaxChars);
end;

function BuildDocxDocumentXml(const AText: string): UTF8String;
var
  Lines: TArray<string>;
  i: Integer;
  Body, Esc: string;
begin
  Lines := SplitLines(AText);
  Body := '';
  if Length(Lines) = 0 then
    Body := '<w:p><w:r><w:t></w:t></w:r></w:p>'
  else
    for i := 0 to High(Lines) do
    begin
      Esc := XmlEscape(Lines[i]);
      if Esc = '' then
        Body := Body + '<w:p/>'
      else
        Body := Body + '<w:p><w:r><w:t xml:space="preserve">' + Esc +
          '</w:t></w:r></w:p>';
    end;
  Result := UTF8String(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
    '<w:body>' + Body + '</w:body></w:document>');
end;

procedure ZipAddUtf8(Zip: TZipFile; const ArchiveName: string; const U: UTF8String;
  AStored: Boolean = False);
var
  St: TMemoryStream;
begin
  St := TMemoryStream.Create;
  try
    if Length(U) > 0 then
      St.WriteBuffer(U[1], Length(U));
    St.Position := 0;
    if AStored then
      Zip.Add(St, ArchiveName, zcStored)
    else
      Zip.Add(St, ArchiveName);
  finally
    St.Free;
  end;
end;

function BuildDocxPackage(const AText: string): TBytes;
var
  Zip: TZipFile;
  MS: TMemoryStream;
  ContentTypes, Rels, DocRels: UTF8String;
begin
  ContentTypes := UTF8String(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
    '</Types>');
  Rels := UTF8String(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
    '</Relationships>');
  DocRels := UTF8String(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>');

  MS := TMemoryStream.Create;
  Zip := TZipFile.Create;
  try
    Zip.Open(MS, zmWrite);
    ZipAddUtf8(Zip, '[Content_Types].xml', ContentTypes);
    ZipAddUtf8(Zip, '_rels/.rels', Rels);
    ZipAddUtf8(Zip, 'word/document.xml', BuildDocxDocumentXml(AText));
    ZipAddUtf8(Zip, 'word/_rels/document.xml.rels', DocRels);
    Zip.Close;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
  finally
    Zip.Free;
    MS.Free;
  end;
end;

function BuildOdtContentXml(const AText: string): UTF8String;
var
  Lines: TArray<string>;
  i: Integer;
  Body, Esc: string;
begin
  Lines := SplitLines(AText);
  Body := '';
  if Length(Lines) = 0 then
    Body := '<text:p text:style-name="Standard"/>'
  else
    for i := 0 to High(Lines) do
    begin
      Esc := XmlEscape(Lines[i]);
      if Esc = '' then
        Body := Body + '<text:p text:style-name="Standard"/>'
      else
        Body := Body + '<text:p text:style-name="Standard">' + Esc + '</text:p>';
    end;
  Result := UTF8String(
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" ' +
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.2">' +
    '<office:body><office:text>' + Body +
    '</office:text></office:body></office:document-content>');
end;

function BuildOdtPackage(const AText: string): TBytes;
var
  Zip: TZipFile;
  MS: TMemoryStream;
  Mime, Manifest, Meta, Styles: UTF8String;
begin
  Mime := UTF8String('application/vnd.oasis.opendocument.text');
  Manifest := UTF8String(
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">' +
    '<manifest:file-entry manifest:full-path="/" manifest:version="1.2" ' +
    'manifest:media-type="application/vnd.oasis.opendocument.text"/>' +
    '<manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>' +
    '<manifest:file-entry manifest:full-path="meta.xml" manifest:media-type="text/xml"/>' +
    '<manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>' +
    '</manifest:manifest>');
  Meta := UTF8String(
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<office:document-meta xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" ' +
    'office:version="1.2"><office:meta/></office:document-meta>');
  Styles := UTF8String(
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<office:document-styles xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" ' +
    'office:version="1.2"><office:styles/></office:document-styles>');

  MS := TMemoryStream.Create;
  Zip := TZipFile.Create;
  try
    Zip.Open(MS, zmWrite);
    ZipAddUtf8(Zip, 'mimetype', Mime, True);
    ZipAddUtf8(Zip, 'META-INF/manifest.xml', Manifest);
    ZipAddUtf8(Zip, 'content.xml', BuildOdtContentXml(AText));
    ZipAddUtf8(Zip, 'meta.xml', Meta);
    ZipAddUtf8(Zip, 'styles.xml', Styles);
    Zip.Close;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
  finally
    Zip.Free;
    MS.Free;
  end;
end;

function PdfOct3(const B: Byte): AnsiString;
{ PDF literal string octal escape \ddd — Delphi Format has no %o. }
begin
  Result := AnsiChar(Ord('0') + ((B shr 6) and 7)) +
            AnsiChar(Ord('0') + ((B shr 3) and 7)) +
            AnsiChar(Ord('0') + (B and 7));
end;

function PdfEscapeWinAnsi(const S: AnsiString): AnsiString;
var
  i: Integer;
  C: AnsiChar;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    C := S[i];
    if C in ['\', '(', ')'] then
      Result := Result + '\' + C
    else if (Ord(C) < 32) or (Ord(C) > 126) then
      Result := Result + '\' + PdfOct3(Byte(Ord(C)))
    else
      Result := Result + C;
  end;
end;

function ToWinAnsiBytes(const S: string): AnsiString;
var
  n: Integer;
  Buf: AnsiString;
  UsedDefault: BOOL;
begin
  if S = '' then
  begin
    Result := '';
    Exit;
  end;
  UsedDefault := False;
  n := WideCharToMultiByte(1252, WC_NO_BEST_FIT_CHARS, PWideChar(S), Length(S),
    nil, 0, nil, @UsedDefault);
  if UsedDefault then
    raise EPdfUnsupportedUnicode.Create('Text contains characters outside Windows-1252.');
  if n <= 0 then
    raise EPdfUnsupportedUnicode.Create('Text cannot be encoded as Windows-1252.');
  SetLength(Buf, n);
  if n > 0 then
  begin
    UsedDefault := False;
    WideCharToMultiByte(1252, WC_NO_BEST_FIT_CHARS, PWideChar(S), Length(S),
      PAnsiChar(Buf), n, nil, @UsedDefault);
    if UsedDefault then
      raise EPdfUnsupportedUnicode.Create('Text contains characters outside Windows-1252.');
  end;
  Result := Buf;
end;

function BuildSimplePdf(const AText: string): TBytes;
const
  LINES_PER_PAGE = 48;
  LEFT = 50;
  TOP = 780;
  LEAD = 14;
  { Letter 612pt, margins 50+50, Helvetica 11 ≈ 5.5pt/char → ~90 chars safe. }
  MAX_CHARS = 90;
var
  Lines: TArray<string>;
  Pages: TArray<UTF8String>;
  PageCount, p, i, LineIdx, Y, ObjCount: Integer;
  Content: UTF8String;
  Offsets: array of Integer;
  MS: TMemoryStream;
  U: UTF8String;
  StartXref: Integer;
  EncLine: AnsiString;
begin
  Lines := WrapLinesForPdf(SplitLines(AText), MAX_CHARS);
  if Length(Lines) = 0 then
  begin
    SetLength(Lines, 1);
    Lines[0] := '';
  end;
  PageCount := (Length(Lines) + LINES_PER_PAGE - 1) div LINES_PER_PAGE;
  if PageCount < 1 then
    PageCount := 1;
  SetLength(Pages, PageCount);
  for p := 0 to PageCount - 1 do
  begin
    Content := UTF8String('BT /F1 11 Tf 14 TL' + #10);
    Y := TOP;
    for i := 0 to LINES_PER_PAGE - 1 do
    begin
      LineIdx := p * LINES_PER_PAGE + i;
      if LineIdx > High(Lines) then
        Break;
      EncLine := PdfEscapeWinAnsi(ToWinAnsiBytes(Lines[LineIdx]));
      Content := Content + UTF8String(Format('1 0 0 1 %d %d Tm (', [LEFT, Y])) +
        UTF8String(EncLine) + UTF8String(') Tj' + #10);
      Dec(Y, LEAD);
    end;
    Content := Content + UTF8String('ET');
    Pages[p] := Content;
  end;

  { Objects: 1=Catalog 2=Pages 3=Font then per page: content + page }
  ObjCount := 3 + PageCount * 2;
  SetLength(Offsets, ObjCount + 1);
  MS := TMemoryStream.Create;
  try
    U := UTF8String('%PDF-1.4' + #10);
    MS.WriteBuffer(U[1], Length(U));

    Offsets[1] := MS.Position;
    U := UTF8String('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj' + #10);
    MS.WriteBuffer(U[1], Length(U));

    Offsets[2] := MS.Position;
    U := UTF8String('2 0 obj<< /Type /Pages /Count ' + UTF8String(IntToStr(PageCount)) +
      ' /Kids [');
    for p := 0 to PageCount - 1 do
      U := U + UTF8String(IntToStr(4 + p * 2)) + ' 0 R ';
    U := U + '] >>endobj' + #10;
    MS.WriteBuffer(U[1], Length(U));

    Offsets[3] := MS.Position;
    U := UTF8String('3 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica ' +
      '/Encoding /WinAnsiEncoding >>endobj' + #10);
    MS.WriteBuffer(U[1], Length(U));

    for p := 0 to PageCount - 1 do
    begin
      { content stream obj = 5+p*2, page obj = 4+p*2 }
      Offsets[5 + p * 2] := MS.Position;
      U := UTF8String(IntToStr(5 + p * 2) + ' 0 obj<< /Length ' +
        UTF8String(IntToStr(Length(Pages[p]))) + ' >>stream' + #10) +
        Pages[p] + UTF8String(#10 + 'endstream endobj' + #10);
      MS.WriteBuffer(U[1], Length(U));

      Offsets[4 + p * 2] := MS.Position;
      U := UTF8String(IntToStr(4 + p * 2) +
        ' 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] ' +
        '/Contents ' + UTF8String(IntToStr(5 + p * 2)) +
        ' 0 R /Resources << /Font << /F1 3 0 R >> >> >>endobj' + #10);
      MS.WriteBuffer(U[1], Length(U));
    end;

    StartXref := MS.Position;
    U := UTF8String('xref' + #10 + '0 ' + UTF8String(IntToStr(ObjCount + 1)) + #10 +
      '0000000000 65535 f ' + #10);
    MS.WriteBuffer(U[1], Length(U));
    for i := 1 to ObjCount do
    begin
      U := UTF8String(Format('%.10d 00000 n ' + #10, [Offsets[i]]));
      MS.WriteBuffer(U[1], Length(U));
    end;
    U := UTF8String('trailer<< /Size ' + UTF8String(IntToStr(ObjCount + 1)) +
      ' /Root 1 0 R >>' + #10 + 'startxref' + #10 +
      UTF8String(IntToStr(StartXref)) + #10 + '%%EOF' + #10);
    MS.WriteBuffer(U[1], Length(U));

    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
  finally
    MS.Free;
  end;
end;

function IsRichComposeExtension(const AExt: string): Boolean;
var
  E: string;
begin
  E := LowerCase(AExt);
  Result := (E = '.rtf') or (E = '.docx') or (E = '.odt') or (E = '.pdf');
end;

function EncodeComposePayload(const AExt, APlainOrRaw: string): TBytes;
var
  E, Body: string;
begin
  E := LowerCase(AExt);
  Body := APlainOrRaw;
  if E = '.rtf' then
  begin
    if Copy(Trim(Body), 1, 5) <> '{\rtf' then
      Body := WrapPlainTextAsRtf(Body);
    Result := TEncoding.UTF8.GetBytes(Body);
  end
  else if E = '.docx' then
    Result := BuildDocxPackage(Body)
  else if E = '.odt' then
    Result := BuildOdtPackage(Body)
  else if E = '.pdf' then
    Result := BuildSimplePdf(Body)
  else
    Result := TEncoding.UTF8.GetBytes(Body);
end;

function StripRoughRtf(const S: string): string;
var
  i: Integer;
  InCtrl: Boolean;
  Ch: Char;
begin
  Result := '';
  InCtrl := False;
  i := 1;
  while i <= Length(S) do
  begin
    Ch := S[i];
    if Ch = '\' then
    begin
      if (i < Length(S)) and (S[i + 1] in ['\', '{', '}']) then
      begin
        Result := Result + S[i + 1];
        Inc(i, 2);
        Continue;
      end;
      InCtrl := True;
      Inc(i);
      Continue;
    end;
    if Ch = '{' then
    begin
      Inc(i);
      Continue;
    end;
    if Ch = '}' then
    begin
      Inc(i);
      InCtrl := False;
      Continue;
    end;
    if InCtrl then
    begin
      if Ch in [' ', #13, #10] then
        InCtrl := False
      else if not (Ch in ['a'..'z', 'A'..'Z', '0'..'9', '-', '*']) then
        InCtrl := False;
      Inc(i);
      Continue;
    end;
    Result := Result + Ch;
    Inc(i);
  end;
  Result := Trim(Result);
end;

function ExtractTextFromXmlTags(const Xml: string): string;
var
  i, StartTag: Integer;
  InTag: Boolean;
  Acc: string;
begin
  Acc := '';
  InTag := False;
  StartTag := 1;
  i := 1;
  while i <= Length(Xml) do
  begin
    if Xml[i] = '<' then
    begin
      InTag := True;
      StartTag := i;
      Inc(i);
      Continue;
    end;
    if InTag then
    begin
      if Xml[i] = '>' then
      begin
        InTag := False;
        if (i > StartTag + 3) and
           ((Copy(Xml, StartTag, 4) = '</w:') or (Copy(Xml, StartTag, 7) = '</text:')) then
          Acc := Acc + #10;
      end;
      Inc(i);
      Continue;
    end;
    Acc := Acc + Xml[i];
    Inc(i);
  end;
  Result := Trim(StringReplace(Acc, '&amp;', '&', [rfReplaceAll]));
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
end;

function TryExtractComposePlainText(const APath: string; out AText: string): Boolean;
var
  Ext: string;
  FS: TFileStream;
  Bytes: TBytes;
  Zip: TZipFile;
  Data: TBytes;
  Xml: string;

  function ReadCapped(AStream: TFileStream; AMax: Integer): TBytes;
  var
    Sz: Int64;
    n: Integer;
  begin
    Sz := AStream.Size;
    if Sz <= 0 then
      n := 0
    else if Sz > AMax then
      n := AMax
    else
      n := Integer(Sz);
    SetLength(Result, n);
    if n > 0 then
      AStream.ReadBuffer(Pointer(Result)^, n);
  end;

begin
  Result := False;
  AText := '';
  Ext := LowerCase(ExtractFileExt(APath));
  if not FileExists(APath) then Exit;
  try
    if Ext = '.rtf' then
    begin
      FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
      try
        Bytes := ReadCapped(FS, 256 * 1024);
      finally
        FS.Free;
      end;
      AText := StripRoughRtf(TEncoding.UTF8.GetString(Bytes));
      Result := AText <> '';
      Exit;
    end;
    if (Ext = '.docx') or (Ext = '.odt') then
    begin
      Zip := TZipFile.Create;
      try
        Zip.Open(APath, zmRead);
        if Ext = '.docx' then
        begin
          if Zip.IndexOf('word/document.xml') < 0 then Exit;
          Zip.Read('word/document.xml', Data);
        end
        else
        begin
          if Zip.IndexOf('content.xml') < 0 then Exit;
          Zip.Read('content.xml', Data);
        end;
        Xml := TEncoding.UTF8.GetString(Data);
        AText := ExtractTextFromXmlTags(Xml);
        Result := AText <> '';
      finally
        Zip.Free;
      end;
      Exit;
    end;
    if Ext = '.pdf' then
    begin
      Result := False;
      Exit;
    end;
    FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      Bytes := ReadCapped(FS, 256 * 1024);
    finally
      FS.Free;
    end;
    AText := TEncoding.UTF8.GetString(Bytes);
    Result := True;
  except
    Result := False;
    AText := '';
  end;
end;

end.
