program AnonTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.Diagnostics,
  uAnonymize in '..\..\src\uAnonymize.pas',
  uTextEncoding in '..\..\src\uTextEncoding.pas',
  uFastFilePaths in '..\..\src\uFastFilePaths.pas';

var
  Fails: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then
    Writeln('  ok   ', Msg)
  else
  begin
    Writeln('  FAIL ', Msg);
    Inc(Fails);
  end;
end;

function Utf8(const S: string): AnsiString;
var
  B: TBytes;
begin
  B := TEncoding.UTF8.GetBytes(S);
  SetLength(Result, Length(B));
  if Length(B) > 0 then Move(B[0], Result[1], Length(B));
end;

function FromUtf8(const S: AnsiString): string;
var
  B: TBytes;
begin
  SetLength(B, Length(S));
  if Length(S) > 0 then Move(S[1], B[0], Length(S));
  Result := TEncoding.UTF8.GetString(B);
end;

function ReadAll(const F: string): AnsiString;
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(F, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Result[1], FS.Size);
  finally
    FS.Free;
  end;
end;

procedure WriteAll(const F: string; const S: AnsiString);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(F, fmCreate);
  try
    if Length(S) > 0 then FS.WriteBuffer(S[1], Length(S));
  finally
    FS.Free;
  end;
end;

function ValidUtf8(const S: AnsiString): Boolean;
var
  I, N, K: Integer;
  B: Byte;
begin
  Result := False;
  I := 1;
  while I <= Length(S) do
  begin
    B := Ord(S[I]);
    if B < $80 then N := 0
    else if (B >= $C2) and (B <= $DF) then N := 1
    else if (B >= $E0) and (B <= $EF) then N := 2
    else if (B >= $F0) and (B <= $F4) then N := 3
    else Exit;
    if I + N > Length(S) then Exit;
    for K := 1 to N do
      if (Ord(S[I + K]) and $C0) <> $80 then Exit;
    Inc(I, N + 1);
  end;
  Result := True;
end;

var
  PreviewLog: TStringList;

procedure TestPreview;
const
  Lines: array[0..11] of string = (
    'Dr. Fulano Beltrano mora aqui. Depois o Sr. Marcos ligou para Juliana.',
    'O cliente Pedro Henrique Gonçalves comprou 3 itens. Obrigado!',
    'Empresário Marcos Antônio da Silva pagou R$ 3.664,50 em 12/03/2024 às 14:35',
    'CPF 123.456.789-09 CNPJ 11.222.333/0001-81 email joao.pereira@empresa.com.br',
    'Cartão 4111 1111 1111 1111 IP 192.168.10.254 código ABX-99812-Z',
    'ID;Nome;Cidade;Valor',
    '00042;MARIA JOSÉ;São Paulo;-1.234,56',
    'Data ISO 2023-12-31T23:59:59Z, versão 10.4.2',
    'Привет Иван Петров 555-1234',
    '田中太郎 さん 電話 03-1234-5678',
    'Zoë Müller wohnt in Köln, Tel. +49 221 1234567',
    'plain line without digits or names?');
var
  Opt: TAnonOptions;
  E: TAnonEngine;
  I: Integer;
  Raw, Outp: AnsiString;
  Changed: Boolean;
begin
  Writeln('Preview (UTF-8):');
  Opt := AnonDefaultOptions;
  Opt.Key := $1234567890ABCDEF;
  Opt.TextMode := atmNames;
  E := TAnonEngine.Create(Opt, 'UTF-8');
  try
    for I := Low(Lines) to High(Lines) do
    begin
      Raw := Utf8(Lines[I]);
      Outp := AnonPreviewBytes(E, Raw, 1000 * I, Changed);
      PreviewLog.Add('< ' + Lines[I]);
      PreviewLog.Add('> ' + FromUtf8(Outp));
      Check(ValidUtf8(Outp), 'valid utf-8 line ' + IntToStr(I));
      Check(Length(Outp) = Length(Raw), 'byte length kept line ' + IntToStr(I));
      Check(Length(FromUtf8(Outp)) = Length(Lines[I]), 'char length kept line ' + IntToStr(I));
    end;
    Raw := Utf8(Lines[0]);
    Check(AnonPreviewBytes(E, Raw, 0, Changed) = AnonPreviewBytes(E, Raw, 99999, Changed),
      'consistent mode independent of offset');
  finally
    E.Free;
  end;
end;

procedure TestFileRoundTrip(const ADir: string; ALines: Integer; const AEnc: string);
var
  F, J: string;
  SB: TStringBuilder;
  I: Integer;
  Orig, After, Undone, Redone: AnsiString;
  Opt: TAnonOptions;
  R: TAnonJobResult;
  Ranges: TAnonRanges;
  SW: TStopwatch;
begin
  Writeln(Format('Round trip %d lines (%s):', [ALines, AEnc]));
  F := ADir + 'rt.txt';
  J := ADir + 'rt.ffanon';
  SB := TStringBuilder.Create;
  try
    for I := 1 to ALines do
      SB.AppendFormat('%d;Cliente José %d;%s;R$ %d,%2.2d;%2.2d/%2.2d/2024;user%d@mail.com'#13#10,
        [I, I * 7, 'Rua Antônio Carlos ' + IntToStr(I mod 500), I * 13, I mod 100,
         1 + I mod 28, 1 + I mod 12, I]);
    Orig := Utf8(SB.ToString);
  finally
    SB.Free;
  end;
  WriteAll(F, Orig);
  Opt := AnonDefaultOptions;
  Opt.Key := 42;
  Opt.TextMode := atmNames;
  SetLength(Ranges, 0);
  SW := TStopwatch.StartNew;
  R := AnonApplyToFile(F, J, Opt, AEnc, Ranges, nil, nil);
  Writeln(Format('   apply: %d ms, changed=%d bytes, runs=%d', [SW.ElapsedMilliseconds, R.BytesChanged, R.RunCount]));
  Check(R.Success, 'apply success ' + R.ErrorMsg);
  After := ReadAll(F);
  Check(Length(After) = Length(Orig), 'size kept');
  Check(After <> Orig, 'content changed');
  R := AnonSwapFile(ajkUndo, F, J, nil);
  Check(R.Success, 'undo success ' + R.ErrorMsg);
  Undone := ReadAll(F);
  Check(Undone = Orig, 'undo restores original');
  R := AnonSwapFile(ajkRedo, F, J, nil);
  Check(R.Success, 'redo success ' + R.ErrorMsg);
  Redone := ReadAll(F);
  Check(Redone = After, 'redo restores anonymized');
  R := AnonSwapFile(ajkUndo, F, J, nil);
  Check(R.Success and (ReadAll(F) = Orig), 'second undo');

  { partial range: only line 2 }
  SetLength(Ranges, 1);
  Ranges[0].Start := Pos(#10, string(Orig));
  Ranges[0].Len := 40;
  DeleteFile(J);
  R := AnonApplyToFile(F, J, Opt, AEnc, Ranges, nil, nil);
  Check(R.Success, 'range apply');
  After := ReadAll(F);
  Check(After <> Orig, 'range changed something');
  Check(Copy(After, 1, Ranges[0].Start) = Copy(Orig, 1, Ranges[0].Start), 'line 1 untouched');
  Check(Copy(After, Ranges[0].Start + 200, MaxInt) = Copy(Orig, Ranges[0].Start + 200, MaxInt), 'tail untouched');
  AnonSwapFile(ajkUndo, F, J, nil);
  Check(ReadAll(F) = Orig, 'range undo');

  { mismatch detection: tamper then undo }
  DeleteFile(J);
  SetLength(Ranges, 0);
  AnonApplyToFile(F, J, Opt, AEnc, Ranges, nil, nil);
  After := ReadAll(F);
  After[3] := AnsiChar(Ord(After[3]) xor 1);
  WriteAll(F, After);
  R := AnonSwapFile(ajkUndo, F, J, nil);
  Check(not R.Success and R.Mismatch, 'tampered undo refused');
  Check(ReadAll(F) = After, 'tampered file left intact');
  DeleteFile(J);
  DeleteFile(F);
end;

procedure TestEngineSpeed;
var
  Line, Buf, Outp: AnsiString;
  SB: TStringBuilder;
  Opt: TAnonOptions;
  E: TAnonEngine;
  SW: TStopwatch;
  Changed: Boolean;
  I: Integer;
begin
  Line := Utf8('2024-05-17;Empresário Marcos Antônio;CPF 123.456.789-09;R$ 3.664,50;marcos@empresa.com.br;Obs: cliente antigo'#13#10);
  SetLength(Buf, Length(Line) * 300000);
  for I := 0 to 299999 do
    Move(Line[1], Buf[1 + I * Length(Line)], Length(Line));
  for I := 0 to 5 do
  begin
    Opt := AnonDefaultOptions;
    Opt.TextMode := atmNames;
    case I of
      1: begin Opt.Numbers := False; Opt.Dates := False; Opt.Emails := False; Opt.Codes := False; Opt.TextMode := atmNone; end;
      2: begin Opt.Dates := False; Opt.Emails := False; Opt.Codes := False; Opt.TextMode := atmNone; end;
      3: begin Opt.Numbers := False; Opt.Emails := False; Opt.Codes := False; Opt.TextMode := atmNone; end;
      4: begin Opt.Numbers := False; Opt.Dates := False; Opt.Codes := False; Opt.TextMode := atmNone; end;
      5: begin Opt.Numbers := False; Opt.Dates := False; Opt.Emails := False; Opt.Codes := False; end;
    end;
    E := TAnonEngine.Create(Opt, 'UTF-8');
    try
      SW := TStopwatch.StartNew;
      Outp := AnonPreviewBytes(E, Buf, 0, Changed);
      Writeln(Format('Engine single-thread case %d: %d MB in %d ms = %.1f MB/s',
        [I, Length(Buf) div 1048576, SW.ElapsedMilliseconds, Length(Buf) / 1048576 / (SW.ElapsedMilliseconds / 1000 + 0.001)]));
    finally
      E.Free;
    end;
  end;
  SB := nil;
  SB.Free;
end;

procedure TestBig(const ADir: string; AMB: Integer);
var
  F, J: string;
  FS: TFileStream;
  Line: AnsiString;
  Total, Need: Int64;
  Opt: TAnonOptions;
  R: TAnonJobResult;
  Ranges: TAnonRanges;
  SW: TStopwatch;
begin
  Writeln(Format('Big file %d MB:', [AMB]));
  F := ADir + 'big.txt';
  J := ADir + 'big.ffanon';
  Line := Utf8('2024-05-17;Empresário Marcos Antônio;CPF 123.456.789-09;R$ 3.664,50;marcos@empresa.com.br;Obs: cliente antigo'#13#10);
  Need := Int64(AMB) * 1024 * 1024;
  FS := TFileStream.Create(F, fmCreate);
  try
    Total := 0;
    while Total < Need do
    begin
      FS.WriteBuffer(Line[1], Length(Line));
      Inc(Total, Length(Line));
    end;
  finally
    FS.Free;
  end;
  Opt := AnonDefaultOptions;
  Opt.TextMode := atmNames;
  Opt.Key := 7;
  SetLength(Ranges, 0);
  SW := TStopwatch.StartNew;
  R := AnonApplyToFile(F, J, Opt, 'UTF-8', Ranges, nil, nil);
  Writeln(Format('   apply %d ms (%.1f MB/s) changed=%d runs=%d', [SW.ElapsedMilliseconds,
    AMB / (SW.ElapsedMilliseconds / 1000 + 0.001), R.BytesChanged, R.RunCount]));
  Check(R.Success, 'big apply ' + R.ErrorMsg);
  SW := TStopwatch.StartNew;
  R := AnonSwapFile(ajkUndo, F, J, nil);
  Writeln(Format('   undo %d ms', [SW.ElapsedMilliseconds]));
  Check(R.Success, 'big undo ' + R.ErrorMsg);
  DeleteFile(J);
  DeleteFile(F);
end;

var
  Dir: string;
  MB: Integer;
begin
  try
    Dir := ExtractFilePath(ParamStr(0)) + 'work\';
    ForceDirectories(Dir);
    PreviewLog := TStringList.Create;
    TestPreview;
    PreviewLog.SaveToFile(Dir + 'preview.txt', TEncoding.UTF8);
    TestFileRoundTrip(Dir, 50, 'UTF-8');
    TestFileRoundTrip(Dir, 200000, 'UTF-8');
    TestFileRoundTrip(Dir, 2000, 'Windows-1252');
    TestEngineSpeed;
    MB := StrToIntDef(ParamStr(1), 0);
    if MB > 0 then TestBig(Dir, MB);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Inc(Fails);
    end;
  end;
  Writeln;
  Writeln('Failures: ', Fails);
  ExitCode := Fails;
end.
