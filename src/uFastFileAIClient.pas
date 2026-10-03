unit uFastFileAIClient;

{
  HTTPS POST to FastFile AI Gateway (JSON prompt -> JSON resposta).
  WinInet only — matches existing MainUnit download stack (no extra SSL DLLs).
}

interface

uses
  SysUtils;

type
  { Percent 0..100; APhase = connect|send|wait|recv. Called from WinInet / worker thread. }
  TFastFileAIProgressEvent = procedure(APercent: Integer; const APhase: string) of object;

function FastFileAIInvokePrompt(const APrompt: WideString; out AAnswer: WideString;
  out AErrMsg: string; AOnProgress: TFastFileAIProgressEvent = nil): Boolean;
{ Unicode JSON string field (decodes \n \t \uXXXX). }
function ExtractJsonStringFieldWide(const JsonWide: WideString; const KeyName: string): WideString;
{ Turn leftover \uXXXX sequences into characters (after a Latin-1/UTF-8 mix-up). }
function UnescapeJsonUnicodeWide(const S: WideString): WideString;

implementation

uses
  Windows, Winapi.WinInet, UnConsts;

const
  { WinInet: SSL hostname mismatch (proxy/antivirus MITM) — optional tolerance }
  FF_INET_FLAG_IGNORE_CERT_CN_INVALID = $00001000;
  FF_INET_STATUS_RESOLVING_NAME = 10;
  FF_INET_STATUS_CONNECTING_TO_SERVER = 20;
  FF_INET_STATUS_CONNECTED_TO_SERVER = 21;
  FF_INET_STATUS_SENDING_REQUEST = 30;
  FF_INET_STATUS_REQUEST_SENT = 31;
  FF_INET_STATUS_RECEIVING_RESPONSE = 40;
  FF_INET_STATUS_RESPONSE_RECEIVED = 41;

var
  GFastFileAIProgress: TFastFileAIProgressEvent;
  GFastFileAIProgTick: Cardinal;
  GFastFileAIProgPct: Integer;

procedure FastFileAIInetStatus(hInet: HINTERNET; dwContext: DWORD_PTR;
  dwInternetStatus: DWORD; lpvStatusInformation: Pointer;
  dwStatusInformationLength: DWORD); stdcall;
var
  Pct: Integer;
  Phase: string;
  NowTick: Cardinal;
begin
  if not Assigned(GFastFileAIProgress) then Exit;
  case dwInternetStatus of
    FF_INET_STATUS_RESOLVING_NAME,
    FF_INET_STATUS_CONNECTING_TO_SERVER:
      begin Pct := 8; Phase := 'connect'; end;
    FF_INET_STATUS_CONNECTED_TO_SERVER:
      begin Pct := 16; Phase := 'connect'; end;
    FF_INET_STATUS_SENDING_REQUEST:
      begin Pct := 22; Phase := 'send'; end;
    FF_INET_STATUS_REQUEST_SENT:
      begin Pct := 30; Phase := 'wait'; end;
    FF_INET_STATUS_RECEIVING_RESPONSE:
      begin Pct := 40; Phase := 'recv'; end;
    FF_INET_STATUS_RESPONSE_RECEIVED:
      begin Pct := 48; Phase := 'recv'; end;
  else
    Exit;
  end;
  NowTick := GetTickCount;
  if (Pct <= GFastFileAIProgPct) and (GFastFileAIProgTick <> 0) and
     ((NowTick - GFastFileAIProgTick) < 80) then
    Exit;
  if Pct < GFastFileAIProgPct then
    Pct := GFastFileAIProgPct;
  GFastFileAIProgPct := Pct;
  GFastFileAIProgTick := NowTick;
  try
    GFastFileAIProgress(Pct, Phase);
  except
  end;
end;

function WidePos(const SubStr, Str: WideString): Integer;
var
  i, Ls, L: Integer;
begin
  Result := 0;
  Ls := Length(SubStr);
  L := Length(Str);
  if (Ls = 0) or (Ls > L) then Exit;
  for i := 1 to L - Ls + 1 do
    if Copy(Str, i, Ls) = SubStr then
    begin
      Result := i;
      Exit;
    end;
end;

function Utf8EncodeWide(const W: WideString): AnsiString;
var
  n: Integer;
begin
  Result := '';
  if W = '' then Exit;
  n := WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  if n <= 0 then Exit;
  SetLength(Result, n);
  WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), Length(W), PAnsiChar(Result), n, nil, nil);
end;

function Utf8DecodeToWide(const U: AnsiString): WideString;
var
  n: Integer;
begin
  Result := '';
  if U = '' then Exit;
  n := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(U), Length(U), nil, 0);
  if n <= 0 then Exit;
  SetLength(Result, n);
  MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(U), Length(U), PWideChar(Result), n);
end;

function HexVal(C: WideChar): Integer;
begin
  case C of
    '0'..'9': Result := Ord(C) - Ord('0');
    'a'..'f': Result := 10 + Ord(C) - Ord('a');
    'A'..'F': Result := 10 + Ord(C) - Ord('A');
  else
    Result := -1;
  end;
end;

function JsonEscapeWide(const W: WideString): WideString;
var
  i: Integer;
  c: WideChar;
begin
  Result := '';
  for i := 1 to Length(W) do
  begin
    c := W[i];
    case c of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      WideChar(#13): Result := Result + '\r';
      WideChar(#10): Result := Result + '\n';
      WideChar(#9): Result := Result + '\t';
    else
      if Ord(c) < 32 then
        Result := Result + WideString('\u') + WideString(IntToHex(Ord(c), 4))
      else
        Result := Result + c;
    end;
  end;
end;

function BuildJsonPromptPayload(const PromptWide: WideString): AnsiString;
var
  Core: WideString;
begin
  Core := WideString('{"' + FASTFILE_AI_JSON_FIELD_PROMPT + '":"') + JsonEscapeWide(PromptWide) +
    WideString('"}');
  Result := Utf8EncodeWide(Core);
end;

function StripUtf8Bom(const U: AnsiString): AnsiString;
begin
  Result := U;
  if (Length(U) >= 3) and (U[1] = AnsiChar($EF)) and (U[2] = AnsiChar($BB)) and (U[3] = AnsiChar($BF)) then
    Result := Copy(U, 4, MaxInt);
end;

function IsProbablyGzip(const U: AnsiString): Boolean;
begin
  Result := (Length(U) >= 2) and (Ord(U[1]) = $1F) and (Ord(U[2]) = $8B);
end;

function AnsiHexPrefix(const U: AnsiString; MaxBytes: Integer): string;
var
  i, n: Integer;
begin
  Result := '';
  if MaxBytes <= 0 then Exit;
  if Length(U) < MaxBytes then n := Length(U) else n := MaxBytes;
  for i := 1 to n do
    Result := Result + IntToHex(Ord(U[i]), 2) + ' ';
end;

function ExtractJsonStringFieldWide(const JsonWide: WideString; const KeyName: string): WideString;
var
  KeyW: WideString;
  p, i: Integer;
  Esc: Boolean;
  Ch: WideChar;
  Code, k, H: Integer;
begin
  Result := '';
  KeyW := WideString('"' + KeyName + '"');
  p := WidePos(KeyW, JsonWide);
  if p = 0 then Exit;
  i := p + Length(KeyW);
  while (i <= Length(JsonWide)) and (Ord(JsonWide[i]) <= 32) do Inc(i);
  if (i > Length(JsonWide)) or (JsonWide[i] <> ':') then Exit;
  Inc(i);
  while (i <= Length(JsonWide)) and (Ord(JsonWide[i]) <= 32) do Inc(i);
  if (i > Length(JsonWide)) or (JsonWide[i] <> '"') then Exit;
  Inc(i);
  Esc := False;
  while i <= Length(JsonWide) do
  begin
    Ch := JsonWide[i];
    if Esc then
    begin
      case Ch of
        'n': Result := Result + WideChar(10);
        'r': Result := Result + WideChar(13);
        't': Result := Result + WideChar(9);
        '\': Result := Result + '\';
        '"': Result := Result + '"';
        '/': Result := Result + '/';
        'u':
          begin
            { Require exactly 4 hex digits; otherwise emit literal 'u' (avoids ERangeError / bad skips). }
            Code := 0;
            if i + 4 <= Length(JsonWide) then
            begin
              for k := 1 to 4 do
              begin
                H := HexVal(JsonWide[i + k]);
                if H < 0 then
                begin
                  Code := -1;
                  Break;
                end;
                Code := Code * 16 + H;
              end;
            end
            else
              Code := -1;
            if Code >= 0 then
            begin
              Result := Result + WideChar(Word(Code));
              Inc(i, 5);
            end
            else
            begin
              Result := Result + 'u';
              Inc(i);
            end;
            Esc := False;
            Continue;
          end;
      else
        Result := Result + Ch;
      end;
      Esc := False;
      Inc(i);
      Continue;
    end;
    if Ch = '\' then
    begin
      Esc := True;
      Inc(i);
      Continue;
    end;
    if Ch = '"' then Break;
    Result := Result + Ch;
    Inc(i);
  end;
end;

function UnescapeJsonUnicodeWide(const S: WideString): WideString;
var
  i, k, H, Code: Integer;
begin
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = '\') and (i + 5 <= Length(S)) and (S[i + 1] = 'u') then
    begin
      Code := 0;
      for k := 1 to 4 do
      begin
        H := HexVal(S[i + 1 + k]);
        if H < 0 then
        begin
          Code := -1;
          Break;
        end;
        Code := Code * 16 + H;
      end;
      if Code >= 0 then
      begin
        Result := Result + WideChar(Word(Code));
        Inc(i, 6);
        Continue;
      end;
    end;
    Result := Result + S[i];
    Inc(i);
  end;
end;

function TryExtractAnswerFields(const JsonWide: WideString): WideString;
begin
  Result := ExtractJsonStringFieldWide(JsonWide, FASTFILE_AI_JSON_FIELD_RESPOSTA);
  if Result = '' then
    Result := ExtractJsonStringFieldWide(JsonWide, 'Resposta');
  if Result = '' then
    Result := ExtractJsonStringFieldWide(JsonWide, 'user_message');
  if Result = '' then
    Result := ExtractJsonStringFieldWide(JsonWide, 'content');
  if Result = '' then
    Result := ExtractJsonStringFieldWide(JsonWide, 'text');
  if Result <> '' then
    Result := UnescapeJsonUnicodeWide(Result);
end;

function FastFileAIInvokePrompt(const APrompt: WideString; out AAnswer: WideString;
  out AErrMsg: string; AOnProgress: TFastFileAIProgressEvent): Boolean;
var
  hInet, hConn, hReq: HINTERNET;
  Body: AnsiString;
  Headers: AnsiString;
  RespBuf: array[0..FASTFILE_AI_WININET_READBUF_BYTES - 1] of Byte;
  dwRead: DWORD;
  Resp: AnsiString;
  RespClean: AnsiString;
  Chunk: AnsiString;
  StatusCode, LenD, Idx, ContentLen: DWORD;
  StatusOk: Boolean;
  WJson: WideString;
  TimeOut: DWORD;
  PreMsg: string;
  InetFlags: DWORD;
  RecvPct: Integer;
  PrevProgress: TFastFileAIProgressEvent;

  procedure Report(APct: Integer; const APhase: string);
  begin
    if not Assigned(AOnProgress) then Exit;
    if APct < GFastFileAIProgPct then
      APct := GFastFileAIProgPct;
    if APct > 99 then APct := 99;
    GFastFileAIProgPct := APct;
    GFastFileAIProgTick := GetTickCount;
    try
      AOnProgress(APct, APhase);
    except
    end;
  end;

begin
  Result := False;
  AAnswer := '';
  AErrMsg := '';
  PreMsg := '';
  Body := BuildJsonPromptPayload(APrompt);
  PrevProgress := GFastFileAIProgress;
  GFastFileAIProgress := AOnProgress;
  GFastFileAIProgTick := 0;
  GFastFileAIProgPct := 0;
  Report(4, 'connect');

  hInet := InternetOpenA(PAnsiChar(AnsiString(FASTFILE_AI_USER_AGENT)), INTERNET_OPEN_TYPE_PRECONFIG,
    nil, nil, 0);
  if hInet = nil then
  begin
    AErrMsg := 'InternetOpen: ' + SysErrorMessage(GetLastError);
    GFastFileAIProgress := PrevProgress;
    Exit;
  end;
  TimeOut := FASTFILE_AI_GATEWAY_TIMEOUT_MS;
  InternetSetOption(hInet, INTERNET_OPTION_CONNECT_TIMEOUT, @TimeOut, SizeOf(TimeOut));
  InternetSetOption(hInet, INTERNET_OPTION_RECEIVE_TIMEOUT, @TimeOut, SizeOf(TimeOut));
  InternetSetOption(hInet, INTERNET_OPTION_SEND_TIMEOUT, @TimeOut, SizeOf(TimeOut));
  InternetSetOption(hInet, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, @TimeOut, SizeOf(TimeOut));
  InternetSetOption(hInet, INTERNET_OPTION_DATA_SEND_TIMEOUT, @TimeOut, SizeOf(TimeOut));
  try
    InternetSetStatusCallback(hInet, @FastFileAIInetStatus);
    hConn := InternetConnectA(hInet, PAnsiChar(AnsiString(FASTFILE_AI_GATEWAY_HOST)), INTERNET_DEFAULT_HTTPS_PORT,
      nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    if hConn = nil then
    begin
      AErrMsg := 'InternetConnect: ' + SysErrorMessage(GetLastError);
      Exit;
    end;
    try
      InetFlags := INTERNET_FLAG_SECURE or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_RELOAD or
        INTERNET_FLAG_KEEP_CONNECTION or FF_INET_FLAG_IGNORE_CERT_CN_INVALID;
      hReq := HttpOpenRequestA(hConn, PAnsiChar(AnsiString(FASTFILE_AI_HTTP_METHOD)),
        PAnsiChar(AnsiString(FASTFILE_AI_GATEWAY_PATH)), nil, nil, nil, InetFlags, 0);
      if hReq = nil then
      begin
        AErrMsg := 'HttpOpenRequest: ' + SysErrorMessage(GetLastError);
        Exit;
      end;
      try
        Headers := 'Content-Type: ' + AnsiString(FASTFILE_AI_JSON_MEDIA_TYPE) + #13#10 +
          'Accept: application/json'#13#10 +
          'Accept-Encoding: identity'#13#10 +
          'Content-Length: ' + AnsiString(IntToStr(Length(Body))) + #13#10;

        Report(18, 'send');
        if not HttpSendRequestA(hReq, PAnsiChar(Headers), Length(Headers),
          PAnsiChar(Body), Length(Body)) then
        begin
          AErrMsg := 'HttpSendRequest: ' + SysErrorMessage(GetLastError);
          Exit;
        end;
        Report(36, 'wait');

        StatusCode := 0;
        LenD := SizeOf(StatusCode);
        Idx := 0;
        StatusOk := HttpQueryInfo(hReq, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER,
          @StatusCode, LenD, Idx);
        if not StatusOk then
          PreMsg := 'HTTP status unavailable: ' + SysErrorMessage(GetLastError) + '. '
        else if (StatusCode < 200) or (StatusCode >= 300) then
          AErrMsg := Format('HTTP %u. ', [StatusCode]);

        ContentLen := 0;
        LenD := SizeOf(ContentLen);
        Idx := 0;
        HttpQueryInfo(hReq, HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,
          @ContentLen, LenD, Idx);

        Report(42, 'recv');
        Resp := '';
        while InternetReadFile(hReq, @RespBuf, SizeOf(RespBuf), dwRead) and (dwRead > 0) do
        begin
          SetLength(Chunk, dwRead);
          Move(RespBuf, Chunk[1], dwRead);
          Resp := Resp + Chunk;
          if ContentLen > 0 then
            RecvPct := 42 + MulDiv(Length(Resp), 52, ContentLen)
          else
            RecvPct := 42 + Length(Resp) div 1024;
          if RecvPct > 94 then RecvPct := 94;
          Report(RecvPct, 'recv');
        end;
        Report(96, 'recv');

        if AErrMsg <> '' then
        begin
          AErrMsg := PreMsg + AErrMsg + Copy(string(Resp), 1, FASTFILE_AI_ERROR_SNIPPET_HTTP_CHARS);
          Exit;
        end;

        if IsProbablyGzip(Resp) then
        begin
          AErrMsg := PreMsg + 'Response is gzip-compressed (' + IntToStr(Length(Resp)) +
            ' bytes). Try proxy/firewall or API binary mode.';
          Exit;
        end;

        RespClean := StripUtf8Bom(Resp);
        WJson := Utf8DecodeToWide(RespClean);
        if (Length(RespClean) > 0) and (Length(WJson) = 0) then
        begin
          AErrMsg := PreMsg + 'Body is not valid UTF-8 (len=' + IntToStr(Length(RespClean)) +
            '). Hex: ' + AnsiHexPrefix(RespClean, 36);
          Exit;
        end;

        AAnswer := TryExtractAnswerFields(WJson);
        if AAnswer = '' then
        begin
          if Trim(Copy(string(RespClean), 1, 800)) <> '' then
            AErrMsg := PreMsg + 'No "resposta" field. Snippet: ' +
              Copy(string(RespClean), 1, FASTFILE_AI_ERROR_SNIPPET_BODY_CHARS)
          else
            AErrMsg := PreMsg + 'Empty body or no "resposta" (length ' + IntToStr(Length(RespClean)) + ').';
          Exit;
        end;
        Result := True;
      finally
        InternetCloseHandle(hReq);
      end;
    finally
      InternetCloseHandle(hConn);
    end;
  finally
    GFastFileAIProgress := nil;
    InternetSetStatusCallback(hInet, nil);
    InternetCloseHandle(hInet);
    GFastFileAIProgress := PrevProgress;
  end;
end;

end.
