unit uLineExtract;

{ Dialogo "Extrair" do editor de linha: filtra caracteres (digitos, letras...) ou
  extrai ocorrencias (e-mails, CPF, datas, colunas, regex propria) do texto. }

interface

uses
  Classes;

{ True = substituir a origem por AResult. }
function ShowLineExtractDialog(AOwner: TComponent; const ASource: string;
  AFromSelection: Boolean; out AResult: string): Boolean;

implementation

uses
  Windows, Types, SysUtils, Math, Controls, Forms, StdCtrls, ExtCtrls, Graphics, Clipbrd,
  Character, RegularExpressions, Generics.Collections, uI18n, uFastFileScale,
  uFastFileAIClient, uFastFilePaths, uUserPrefs, uMruFind, UnitPopupMruList;

const
  AI_RECENT_FILE = 'ExtractAIRecent.txt';

type
  TExtractKind = (ekDigits, ekLetters, ekAlNum, ekSpecial, ekNoDigits, ekNoSpecial,
    ekNumbers, ekWords, ekEmails, ekUrls, ekCpf, ekCnpj, ekDates, ekTimes, ekPhones,
    ekIps, ekCep, ekMoney, ekQuoted, ekColumns, ekCustom);

const
  FILTER_KINDS = [ekDigits..ekNoSpecial];
  REGEX_KINDS = [ekNumbers..ekQuoted, ekCustom];
  { filtros em que o normal e manter os espacos entre palavras }
  KEEP_SPACE_KINDS = [ekLetters, ekNoDigits, ekNoSpecial];

  { acima disto a previa espera uma pausa na digitacao/opcoes }
  LIVE_MAX_CHARS = 65536;
  PREVIEW_MAX_CHARS = 200000;
  EXAMPLE_MAX_CHARS = 120;
  MAX_MATCHES = 2000000;

  KIND_KEYS: array[TExtractKind] of string = (
    'Extract.Kind.Digits', 'Extract.Kind.Letters', 'Extract.Kind.AlNum',
    'Extract.Kind.Special', 'Extract.Kind.NoDigits', 'Extract.Kind.NoSpecial',
    'Extract.Kind.Numbers', 'Extract.Kind.Words', 'Anon.Emails', 'Extract.Kind.Urls',
    'Extract.Kind.Cpf', 'Extract.Kind.Cnpj', 'Extract.Kind.Dates', 'Extract.Kind.Times',
    'Extract.Kind.Phones', 'Extract.Kind.Ips', 'Extract.Kind.Cep', 'Extract.Kind.Money',
    'Extract.Kind.Quoted', 'Extract.Kind.Columns', 'Extract.Kind.Custom');

  KIND_PATTERNS: array[TExtractKind] of string = (
    '', '', '', '', '', '',
    '-?\d+(?:[.,]\d+)*',
    '[\p{L}\p{M}]+(?:[''\x{2019}-][\p{L}\p{M}]+)*',
    '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+',
    '(?:https?://|ftp://|www\.)[^\s"''<>,;]+',
    '(?<!\d)\d{3}\.?\d{3}\.?\d{3}-?\d{2}(?!\d)',
    '(?<!\d)\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}(?!\d)',
    '(?<!\d)(?:\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})(?!\d)',
    '(?<!\d)(?:[01]?\d|2[0-3]):[0-5]\d(?::[0-5]\d)?(?!\d)',
    '(?<!\d)(?:\+\d{1,3}\s?)?(?:\(\d{2,3}\)\s?|\d{2,3}[\s-])?\d{4,5}-?\d{4}(?!\d)',
    '(?<!\d)(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?!\d)',
    '(?<!\d)\d{5}-\d{3}(?!\d)',
    '(?:R\$|US\$|\x{20AC}|\x{00A3}|\$)\s?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?',
    '"([^"]*)"',
    '', '');

  KIND_SAMPLES: array[TExtractKind] of string = (
    'CPF 123.456.789-09',
    'Pedido #A-1203 (OK)',
    'Pedido #A-1203 (OK)',
    'a+b=c; x@y.z!',
    'Rua 7 de Setembro, 1200',
    'Ol'#$E1', mundo! (teste #1)',
    'Qtd 3; pre'#$E7'o 1.234,56; desconto -10',
    'S'#$E3'o Paulo, 2024 - SP',
    'ana.silva@empresa.com.br; ti@x.org',
    'Ver https://exemplo.com/a?b=1 e www.site.org',
    'CPF 123.456.789-09 e 98765432100',
    'CNPJ 12.345.678/0001-95',
    'Em 2024-05-17 e 17/05/2024',
    'In'#$ED'cio 08:30, fim 17:45:10',
    'Tel (11) 98765-4321 / +55 21 3456-7890',
    'De 192.168.0.1 para 10.0.0.254',
    'CEP 01310-100',
    'Total R$ 1.234,56 ou US$ 99.90',
    'nome="Ana" cidade="Belo Horizonte"',
    '712738,Dr.,Antonio Augusto,Belo Horizonte',
    'Pedido ABC-123 em 17/05/2024');

  SEP_VALUES: array[0..6] of string = ('', ' ', ',', ';', #9, #13#10, '|');
  SEP_KEYS: array[0..6] of string = ('Extract.Sep.None', 'Extract.Sep.Space',
    'Anon.Delimiter.Comma', 'Anon.Delimiter.Semicolon', 'Anon.Delimiter.Tab',
    'Extract.Sep.NewLine', 'Anon.Delimiter.Pipe');
  DELIM_VALUES: array[0..4] of Char = (#0, ',', ';', #9, '|');
  DELIM_KEYS: array[0..4] of string = ('Extract.Delim.Auto', 'Anon.Delimiter.Comma',
    'Anon.Delimiter.Semicolon', 'Anon.Delimiter.Tab', 'Anon.Delimiter.Pipe');

var
  GKind: TExtractKind = ekDigits;
  GSep: Integer = 0;
  GCase: Boolean = False;
  GUnique: Boolean = False;
  GGroup1: Boolean = False;
  GCustom: string = '';
  GColumns: string = '1';
  GDelim: Integer = 0;

{ ---------------------------------------------------------------------------- }
{ Extracao                                                                     }
{ ---------------------------------------------------------------------------- }

function IsDigitCh(C: Char): Boolean; inline;
begin
  if Ord(C) < 128 then
    Result := (C >= '0') and (C <= '9')
  else
    Result := C.IsDigit;
end;

function IsLetterCh(C: Char): Boolean; inline;
begin
  if Ord(C) < 128 then
    Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z'))
  else
    Result := C.IsLetter or (C.GetUnicodeCategory in [TUnicodeCategory.ucNonSpacingMark,
      TUnicodeCategory.ucCombiningMark, TUnicodeCategory.ucEnclosingMark]);
end;

function IsSpaceCh(C: Char): Boolean; inline;
begin
  if Ord(C) < 128 then
    Result := (C = ' ') or (C = #9)
  else
    Result := C.IsWhiteSpace;
end;

{ Mantem a ordem do texto; quebras de linha ficam, espacos seguidos viram um so. }
function FilterText(const S: string; AKind: TExtractKind; AKeepSpaces: Boolean): string;
var
  I, N: Integer;
  C: Char;
  Keep, PendingSpace: Boolean;
begin
  SetLength(Result, Length(S));
  N := 0;
  PendingSpace := False;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (C = #13) or (C = #10) then
    begin
      PendingSpace := False;
      Inc(N);
      Result[N] := C;
      Continue;
    end;
    if IsSpaceCh(C) then
    begin
      PendingSpace := AKeepSpaces;
      Continue;
    end;
    case AKind of
      ekDigits: Keep := IsDigitCh(C);
      ekLetters: Keep := IsLetterCh(C);
      ekAlNum: Keep := IsDigitCh(C) or IsLetterCh(C);
      ekSpecial: Keep := not (IsDigitCh(C) or IsLetterCh(C));
      ekNoDigits: Keep := not IsDigitCh(C);
      ekNoSpecial: Keep := IsDigitCh(C) or IsLetterCh(C);
    else
      Keep := True;
    end;
    if not Keep then Continue;
    if PendingSpace and (N > 0) and (Result[N] <> #10) and (Result[N] <> #13) then
    begin
      Inc(N);
      Result[N] := ' ';
    end;
    PendingSpace := False;
    Inc(N);
    Result[N] := C;
  end;
  SetLength(Result, N);
end;

function ExtractMatches(const S, APattern: string; ACase, AGroup1, AUnique: Boolean;
  const ASep: string; out ACount: Integer; out AErr: string): string;
var
  R: TRegEx;
  M: TMatch;
  Opt: TRegExOptions;
  SB: TStringBuilder;
  Seen: TDictionary<string, Boolean>;
  V: string;
begin
  Result := '';
  ACount := 0;
  AErr := '';
  SB := nil;
  Seen := nil;
  try
    try
      Opt := [roMultiLine];
      if not ACase then
        Include(Opt, roIgnoreCase);
      R := TRegEx.Create(APattern, Opt);
      SB := TStringBuilder.Create;
      if AUnique then
        Seen := TDictionary<string, Boolean>.Create;
      M := R.Match(S);
      while M.Success and (ACount < MAX_MATCHES) do
      begin
        if AGroup1 and (M.Groups.Count > 1) then
          V := M.Groups[1].Value
        else
          V := M.Value;
        if (V <> '') and ((Seen = nil) or not Seen.ContainsKey(V)) then
        begin
          if Seen <> nil then
            Seen.Add(V, True);
          if ACount > 0 then
            SB.Append(ASep);
          SB.Append(V);
          Inc(ACount);
        end;
        M := M.NextMatch;
      end;
      Result := SB.ToString;
    except
      on E: Exception do
      begin
        Result := '';
        ACount := 0;
        AErr := Format(TrText('Extract.BadRegex'), [E.Message]);
      end;
    end;
  finally
    Seen.Free;
    SB.Free;
  end;
end;

function ParseColumnSpec(const S: string; out ACols: TArray<Integer>): Boolean;
var
  L: TList<Integer>;
  T: string;
  D, A, B, I: Integer;
begin
  Result := False;
  ACols := nil;
  L := TList<Integer>.Create;
  try
    for T in S.Split([',', ';', ' ']) do
    begin
      if Trim(T) = '' then Continue;
      D := Pos('-', T);
      if D > 0 then
      begin
        A := StrToIntDef(Trim(Copy(T, 1, D - 1)), 0);
        B := StrToIntDef(Trim(Copy(T, D + 1, MaxInt)), 0);
        if (A < 1) or (B < A) or (B - A > 10000) then Exit;
        for I := A to B do
          L.Add(I);
      end
      else
      begin
        A := StrToIntDef(Trim(T), 0);
        if A < 1 then Exit;
        L.Add(A);
      end;
    end;
    if L.Count = 0 then Exit;
    ACols := L.ToArray;
    Result := True;
  finally
    L.Free;
  end;
end;

{ Campos separados por ADelim; aspas duplas no inicio do campo protegem o delimitador. }
function SplitFields(const ALine: string; ADelim: Char): TArray<string>;
var
  L: TList<string>;
  SB: TStringBuilder;
  I, N: Integer;
  C: Char;
  InQ: Boolean;
begin
  L := TList<string>.Create;
  SB := TStringBuilder.Create;
  try
    InQ := False;
    N := Length(ALine);
    I := 1;
    while I <= N do
    begin
      C := ALine[I];
      if InQ then
      begin
        if C = '"' then
        begin
          if (I < N) and (ALine[I + 1] = '"') then
          begin
            SB.Append('"');
            Inc(I);
          end
          else
            InQ := False;
        end
        else
          SB.Append(C);
      end
      else if (C = '"') and (SB.Length = 0) then
        InQ := True
      else if C = ADelim then
      begin
        L.Add(SB.ToString);
        SB.Clear;
      end
      else
        SB.Append(C);
      Inc(I);
    end;
    L.Add(SB.ToString);
    Result := L.ToArray;
  finally
    SB.Free;
    L.Free;
  end;
end;

function DetectDelim(const AText: string): Char;
const
  CANDS: array[0..3] of Char = (',', ';', #9, '|');
var
  Counts: array[0..3] of Integer;
  I, K, Lim, Best: Integer;
  InQ: Boolean;
begin
  FillChar(Counts, SizeOf(Counts), 0);
  InQ := False;
  Lim := Min(Length(AText), 65536);
  for I := 1 to Lim do
  begin
    if (AText[I] = #13) or (AText[I] = #10) then Break;
    if AText[I] = '"' then
      InQ := not InQ
    else if not InQ then
      for K := 0 to High(CANDS) do
        if AText[I] = CANDS[K] then
          Inc(Counts[K]);
  end;
  Best := 0;
  for K := 1 to High(CANDS) do
    if Counts[K] > Counts[Best] then
      Best := K;
  Result := CANDS[Best];
end;

function ExtractColumns(const AText, ASpec: string; ADelimIdx: Integer;
  const ASep: string; out ACount: Integer; out AErr: string): string;
var
  Cols: TArray<Integer>;
  Lines, F: TArray<string>;
  Delim: Char;
  SB: TStringBuilder;
  Li, K: Integer;
  First: Boolean;
begin
  Result := '';
  ACount := 0;
  AErr := '';
  if not ParseColumnSpec(ASpec, Cols) then
  begin
    AErr := TrText('Anon.ErrColumns');
    Exit;
  end;
  if (ADelimIdx > 0) and (ADelimIdx <= High(DELIM_VALUES)) then
    Delim := DELIM_VALUES[ADelimIdx]
  else
    Delim := DetectDelim(AText);
  Lines := AText.Replace(#13#10, #10).Replace(#13, #10).Split([#10]);
  SB := TStringBuilder.Create;
  try
    for Li := 0 to High(Lines) do
    begin
      if Li > 0 then
        SB.Append(#13#10);
      F := SplitFields(Lines[Li], Delim);
      First := True;
      for K in Cols do
        if K <= Length(F) then
        begin
          if not First then
            SB.Append(ASep);
          SB.Append(F[K - 1]);
          First := False;
          Inc(ACount);
        end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ ---------------------------------------------------------------------------- }
{ Dialogo                                                                      }
{ ---------------------------------------------------------------------------- }

type
  TExtractForm = class;

  { Pede uma regex a IA. Owner = nil quando o dialogo fecha antes da resposta. }
  TExtractAIThread = class(TThread)
  private
    FPrompt: WideString;
    FAnswer: WideString;
    FError: string;
    FOk: Boolean;
    procedure Deliver;
  protected
    procedure Execute; override;
  public
    Owner: TExtractForm;
    constructor Create(AOwner: TExtractForm; const APrompt: WideString);
  end;

  TExtractForm = class(TForm)
  private
    FSource: string;
    FFromSel: Boolean;
    FResult: string;
    FUpdating: Boolean;
    FTimer: TTimer;
    FAIThread: TExtractAIThread;
    FAICaption: string;
    lblSource, lblWhat, lblRegex, lblAI, lblAIInfo, lblSep, lblCols, lblDelim,
      lblExample, lblResult, lblCount: TLabel;
    cbKind, cbSep, cbDelim: TComboBox;
    edtRegex, edtCols, edtAI: TEdit;
    chkCase, chkGroup1, chkUnique, chkKeepSpaces: TCheckBox;
    mmResult: TMemo;
    btnReplace, btnCopy, btnCancel, btnAI, btnAIMru, btnCopyRegex: TButton;
    FAIRecent: TStringList;
    procedure CopyRegexClick(Sender: TObject);
    procedure LoadAIRecent;
    procedure SaveAIRecent;
    procedure RememberAIRequest(const S: string);
    procedure AIMruClick(Sender: TObject);
    procedure AIMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure AIMruRemove(Sender: TObject; const AValue: string);
    procedure AIMruClearAll(Sender: TObject);
    function Kind: TExtractKind;
    function TextW(const S: string): Integer;
    function TextH(const S: string; AWidth: Integer): Integer;
    procedure LayoutRows;
    procedure SetAIInfo(const S: string; AColor: TColor);
    procedure FormResizeExtract(Sender: TObject);
    function BuildAIPrompt: WideString;
    procedure AIClick(Sender: TObject);
    procedure AIEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AIFinished(AOk: Boolean; const AAnswer: WideString; const AError: string);
    function SepText: string;
    function NewLabel(X, Y: Integer; const AKey: string): TLabel;
    function NewCheck(X, Y, W: Integer; const AKey: string; AChecked: Boolean): TCheckBox;
    function NewCombo(X, Y, W: Integer): TComboBox;
    procedure BuildUi;
    procedure LayoutColumns;
    procedure UpdateControls;
    procedure Schedule(AForceDelay: Boolean);
    procedure Recompute;
    function RunOn(const AText: string; out ACount: Integer; out AErr: string): string;
    procedure KindChanged(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure RegexChanged(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure FormKeyDownExtract(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SaveSettings;
  public
    constructor CreateDlg(AOwner: TComponent; const ASource: string; AFromSel: Boolean);
    destructor Destroy; override;
  end;

const
  AI_SAMPLE_CHARS = 3000;
  { as instrucoes ficam em ingles; a explicacao vem no idioma da interface }
  AI_PROMPT_FMT =
    'You help a user of FastFile (a text editor) write ONE regular expression that EXTRACTS ' +
    'matches from a piece of text.'#13#10 +
    'Engine: PCRE (Delphi TRegEx), Unicode; the pattern is applied with multiline mode and is currently %s.'#13#10 +
    'Do not use / delimiters or inline flags. Lookbehind must have a fixed length.'#13#10 +
    'If the user wants only part of each match, put that part in capture group 1 and answer GROUP1: yes.'#13#10 +
    'If the request depends on letter case (e.g. only the uppercase letter "A"), answer MATCHCASE: yes; ' +
    'if it explicitly ignores case, answer MATCHCASE: no; otherwise keep the current setting.'#13#10 +
    'Answer EXACTLY in this format, with no other text:'#13#10 +
    'REGEX: <pattern>'#13#10 +
    'GROUP1: yes|no'#13#10 +
    'MATCHCASE: yes|no'#13#10 +
    'EXPLANATION: <one or two short sentences in %s, for an end user; do not mention ' +
    'the REGEX/GROUP1/MATCHCASE fields>'#13#10#13#10 +
    'User request:'#13#10'%s'#13#10#13#10 +
    'Current regular expression (may be empty or wrong):'#13#10'%s'#13#10#13#10 +
    'Sample of the text (first %d characters):'#13#10'%s'#13#10;

constructor TExtractAIThread.Create(AOwner: TExtractForm; const APrompt: WideString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  Owner := AOwner;
  FPrompt := APrompt;
end;

procedure TExtractAIThread.Execute;
begin
  try
    FOk := FastFileAIInvokePrompt(FPrompt, FAnswer, FError);
  except
    on E: Exception do
    begin
      FOk := False;
      FError := E.Message;
    end;
  end;
  Synchronize(Deliver);
end;

procedure TExtractAIThread.Deliver;
begin
  if Assigned(Owner) then
  begin
    Owner.FAIThread := nil;
    Owner.AIFinished(FOk, FAnswer, FError);
  end;
end;

{ Extrai REGEX / GROUP1 / EXPLANATION da resposta; aceita crases e /.../flags. }
procedure ParseAIAnswer(const AText: string; out APattern: string; out AGroup1: Boolean;
  out AMatchCase: Integer; out AExplanation: string);
var
  Lines: TStringList;
  I, P: Integer;
  L, U, T: string;
begin
  APattern := '';
  AGroup1 := False;
  AMatchCase := -1;
  AExplanation := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    I := -1;
    while I + 1 < Lines.Count do
    begin
      Inc(I);
      L := Trim(Lines[I]);
      while (L <> '') and CharInSet(L[1], ['*', '-', '>']) do
        L := Trim(Copy(L, 2, MaxInt));
      U := UpperCase(L);
      if (APattern = '') and U.StartsWith('REGEX') then
      begin
        P := Pos(':', L);
        if P > 0 then
          APattern := Trim(Copy(L, P + 1, MaxInt));
      end
      else if U.StartsWith('GROUP1') then
        AGroup1 := Pos('YES', U) > 0
      else if U.StartsWith('MATCHCASE') then
        AMatchCase := Ord(Pos('YES', U) > 0)
      else if U.StartsWith('EXPLANATION') then
      begin
        P := Pos(':', L);
        if P > 0 then
          AExplanation := Trim(Copy(L, P + 1, MaxInt));
        while (I + 1 < Lines.Count) and (Trim(Lines[I + 1]) <> '') and
          not UpperCase(Trim(Lines[I + 1])).StartsWith('REGEX') do
        begin
          Inc(I);
          AExplanation := AExplanation + ' ' + Trim(Lines[I]);
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
  T := APattern;
  { "**REGEX:** x" em markdown; uma regex valida nunca comeca por '*' }
  if (Length(T) >= 4) and T.StartsWith('**') and T.EndsWith('**') then
    T := Trim(Copy(T, 3, Length(T) - 4));
  while T.StartsWith('*') do
    T := Trim(Copy(T, 2, MaxInt));
  if (Length(T) >= 2) and (T[1] = '`') and (T[Length(T)] = '`') then
    T := Copy(T, 2, Length(T) - 2);
  if (Length(T) >= 2) and (T[1] = '/') then
  begin
    P := LastDelimiter('/', T);
    if P > 1 then
      T := Copy(T, 2, P - 2);
  end;
  APattern := T;
end;

constructor TExtractForm.CreateDlg(AOwner: TComponent; const ASource: string;
  AFromSel: Boolean);
var
  W: Integer;
begin
  inherited CreateNew(AOwner);
  FSource := ASource;
  FFromSel := AFromSel;
  if AOwner is TCustomForm then
    Font.Assign(TForm(AOwner).Font);
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu];
  Position := poDesigned;
  KeyPreview := True;
  OnKeyDown := FormKeyDownExtract;
  Caption := TrText('Extract.Title');
  ClientWidth := FfPx(680);
  ClientHeight := FfPx(610);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 180;
  FTimer.OnTimer := TimerTick;
  FAIRecent := TStringList.Create;
  LoadAIRecent;
  BuildUi;
  W := ClientWidth;
  FfPrepareDialog(Self, 680, 610);
  if ClientWidth < W then
    ClientWidth := W;
  LayoutRows;
  if mmResult.Height < FfPx(120) then
    ClientHeight := ClientHeight + FfPx(120) - mmResult.Height;
  Constraints.MinWidth := FfPx(560);
  Constraints.MinHeight := Max(FfPx(480), Height - mmResult.Height + FfPx(60));
  OnResize := FormResizeExtract;
end;

destructor TExtractForm.Destroy;
begin
  if Assigned(FAIThread) then
    FAIThread.Owner := nil;
  if Assigned(FormPopupMruList) and
     (TMethod(FormPopupMruList.OnPick).Data = Pointer(Self)) then
  begin
    FormPopupMruList.OnPick := nil;
    FormPopupMruList.OnRemove := nil;
    FormPopupMruList.OnClearAll := nil;
    if FormPopupMruList.Visible then
      FormPopupMruList.ClosePopup(False);
  end;
  FAIRecent.Free;
  inherited;
end;

procedure TExtractForm.LoadAIRecent;
var
  Path: string;
  I: Integer;
begin
  FAIRecent.Clear;
  Path := FastFileExeDirPath(AI_RECENT_FILE);
  if not FileExists(Path) then Exit;
  try
    FAIRecent.LoadFromFile(Path, TEncoding.UTF8);
  except
    FAIRecent.Clear;
  end;
  for I := FAIRecent.Count - 1 downto 0 do
    if Trim(FAIRecent[I]) = '' then
      FAIRecent.Delete(I);
  while FAIRecent.Count > PrefAssistantRecentMax do
    FAIRecent.Delete(FAIRecent.Count - 1);
end;

procedure TExtractForm.SaveAIRecent;
var
  Path: string;
begin
  Path := FastFileExeDirPath(AI_RECENT_FILE);
  try
    if FAIRecent.Count = 0 then
      DeleteFile(Path)
    else
      FAIRecent.SaveToFile(Path, TEncoding.UTF8);
  except
  end;
end;

procedure TExtractForm.RememberAIRequest(const S: string);
var
  Q: string;
  I: Integer;
begin
  Q := Trim(StringReplace(StringReplace(S, #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
  if Q = '' then Exit;
  for I := FAIRecent.Count - 1 downto 0 do
    if AnsiSameText(Trim(FAIRecent[I]), Q) then
      FAIRecent.Delete(I);
  FAIRecent.Insert(0, Q);
  while FAIRecent.Count > PrefAssistantRecentMax do
    FAIRecent.Delete(FAIRecent.Count - 1);
  SaveAIRecent;
end;

procedure TExtractForm.AIMruClick(Sender: TObject);
var
  CR: TRect;
  OwnerComp: TComponent;
begin
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    if TMethod(FormPopupMruList.OnPick).Data = Pointer(Self) then
      Exit;
  end;
  if FAIRecent.Count = 0 then
  begin
    SetAIInfo(TrText('Extract.AI.RecentEmpty'), clGrayText);
    Exit;
  end;
  if not edtAI.HandleAllocated then Exit;
  GetWindowRect(edtAI.Handle, CR);
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Extract.AI.Recent'),
    MruMoreCaption('Assistant.RecentQuestionsMore'), FAIRecent,
    btnAIMru.BoundsRect.Right - edtAI.Left, Point(CR.Left, CR.Bottom),
    AIMruPick, TrText('Assistant.RecentQuestionsMoreHint'),
    nil, AIMruRemove, btnAIMru, AIMruClearAll, Handle);
end;

procedure TExtractForm.AIMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  if not edtAI.Enabled then Exit;
  edtAI.Text := AValue;
  edtAI.SelStart := Length(edtAI.Text);
  if edtAI.CanFocus then
    edtAI.SetFocus;
end;

procedure TExtractForm.AIMruRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
begin
  I := FAIRecent.IndexOf(AValue);
  if I >= 0 then
  begin
    FAIRecent.Delete(I);
    SaveAIRecent;
  end;
end;

procedure TExtractForm.AIMruClearAll(Sender: TObject);
begin
  FAIRecent.Clear;
  SaveAIRecent;
end;

function TExtractForm.TextW(const S: string): Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    Result := Bmp.Canvas.TextWidth(S);
  finally
    Bmp.Free;
  end;
end;

function TExtractForm.TextH(const S: string; AWidth: Integer): Integer;
var
  Bmp: TBitmap;
  R: TRect;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    R := Rect(0, 0, Max(AWidth, 1), 0);
    if S = '' then
      Result := Bmp.Canvas.TextHeight('Wg')
    else
    begin
      DrawText(Bmp.Canvas.Handle, PChar(S), Length(S), R,
        DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
      Result := R.Bottom - R.Top;
    end;
  finally
    Bmp.Free;
  end;
end;

{ Empilha as linhas pela altura real dos controles e textos (fonte/DPI/traducao). }
procedure TExtractForm.LayoutRows;
var
  Y, G, LH, H: Integer;

  procedure Row(ALabel: TLabel; AControl: TControl);
  begin
    AControl.Top := Y;
    ALabel.Top := Y + (AControl.Height - ALabel.Height) div 2;
    Inc(Y, AControl.Height + G);
  end;

begin
  if not Assigned(mmResult) then Exit;
  G := FfPx(6);
  LH := TextH('', 0);
  Y := lblSource.Top + lblSource.Height + FfPx(10);
  Row(lblWhat, cbKind);
  btnCopyRegex.SetBounds(btnCopyRegex.Left, Y - FfPx(1), btnCopyRegex.Width, edtRegex.Height + FfPx(2));
  Row(lblRegex, edtRegex);
  edtAI.Top := Y;
  btnAI.SetBounds(btnAI.Left, Y - FfPx(1), btnAI.Width, edtAI.Height + FfPx(2));
  btnAIMru.SetBounds(btnAIMru.Left, Y, btnAIMru.Width, edtAI.Height);
  lblAI.Top := Y + (edtAI.Height - lblAI.Height) div 2;
  Inc(Y, edtAI.Height + FfPx(4));

  H := Min(TextH(lblAIInfo.Caption, lblAIInfo.Width), LH * 5);
  H := Max(H, LH);
  lblAIInfo.SetBounds(lblAIInfo.Left, Y, lblAIInfo.Width, H);
  Inc(Y, H + G);

  H := Max(FfPx(20), LH + FfPx(4));
  chkCase.SetBounds(chkCase.Left, Y, chkCase.Width, H);
  chkUnique.SetBounds(chkUnique.Left, Y, chkUnique.Width, H);
  Inc(Y, H + FfPx(2));
  chkGroup1.SetBounds(chkGroup1.Left, Y, chkGroup1.Width, H);
  chkKeepSpaces.SetBounds(chkKeepSpaces.Left, Y, chkKeepSpaces.Width, H);
  Inc(Y, H + G);

  Row(lblSep, cbSep);
  cbDelim.Top := Y;
  lblDelim.Top := Y + (cbDelim.Height - lblDelim.Height) div 2;
  Row(lblCols, edtCols);

  lblExample.SetBounds(lblExample.Left, Y, lblExample.Width, LH * 2);
  Inc(Y, LH * 2 + G);

  lblResult.Top := Y;
  lblCount.Top := Y;
  Inc(Y, lblResult.Height + FfPx(4));
  mmResult.SetBounds(mmResult.Left, Y, mmResult.Width,
    Max(btnCancel.Top - FfPx(12) - Y, FfPx(40)));
end;

procedure TExtractForm.SetAIInfo(const S: string; AColor: TColor);
begin
  lblAIInfo.Font.Color := AColor;
  lblAIInfo.Caption := S;
  lblAIInfo.Hint := S;
  LayoutRows;
end;

procedure TExtractForm.FormResizeExtract(Sender: TObject);
begin
  LayoutRows;
end;

function TExtractForm.NewLabel(X, Y: Integer; const AKey: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.Left := FfPx(X);
  Result.Top := FfPx(Y);
  if AKey <> '' then
    Result.Caption := TrText(AKey);
end;

function TExtractForm.NewCheck(X, Y, W: Integer; const AKey: string;
  AChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(FfPx(X), FfPx(Y), FfPx(W), FfPx(20));
  Result.Caption := TrText(AKey);
  Result.Checked := AChecked;
  Result.OnClick := OptionChanged;
end;

function TExtractForm.NewCombo(X, Y, W: Integer): TComboBox;
begin
  Result := TComboBox.Create(Self);
  Result.Parent := Self;
  Result.Style := csDropDownList;
  Result.SetBounds(FfPx(X), FfPx(Y), FfPx(W), Result.Height);
  Result.DropDownCount := 24;
end;

procedure TExtractForm.BuildUi;
var
  K: TExtractKind;
  I, W, H: Integer;
begin
  W := FfPx(680);
  H := FfPx(610);
  lblSource := NewLabel(12, 10, '');
  if FFromSel then
    lblSource.Caption := Format(TrText('Extract.SourceSel'), [Length(FSource)])
  else
    lblSource.Caption := Format(TrText('Extract.SourceAll'), [Length(FSource)]);

  lblWhat := NewLabel(12, 40, 'Extract.What');
  cbKind := NewCombo(150, 36, 498);
  cbKind.Anchors := [akLeft, akTop, akRight];
  for K := Low(TExtractKind) to High(TExtractKind) do
    cbKind.Items.Add(TrText(KIND_KEYS[K]));
  cbKind.OnChange := KindChanged;

  lblRegex := NewLabel(12, 70, 'Extract.Regex');
  edtRegex := TEdit.Create(Self);
  edtRegex.Parent := Self;
  edtRegex.SetBounds(FfPx(150), FfPx(66), FfPx(498), edtRegex.Height);
  edtRegex.Anchors := [akLeft, akTop, akRight];
  edtRegex.Font.Name := 'Consolas';
  edtRegex.OnChange := RegexChanged;
  btnCopyRegex := TButton.Create(Self);
  btnCopyRegex.Parent := Self;
  btnCopyRegex.Caption := TrText('Extract.CopyRegex');
  btnCopyRegex.Hint := TrText('Extract.CopyRegexHint');
  btnCopyRegex.ShowHint := True;
  btnCopyRegex.Anchors := [akTop, akRight];
  btnCopyRegex.OnClick := CopyRegexClick;

  lblAI := NewLabel(12, 100, 'Extract.AI.Label');
  edtAI := TEdit.Create(Self);
  edtAI.Parent := Self;
  edtAI.SetBounds(FfPx(150), FfPx(96), FfPx(340), edtAI.Height);
  edtAI.Anchors := [akLeft, akTop, akRight];
  edtAI.TextHint := TrText('Extract.AI.Placeholder');
  edtAI.Hint := TrText('Extract.AI.Placeholder');
  edtAI.ShowHint := True;
  edtAI.OnKeyDown := AIEditKeyDown;
  btnAIMru := TButton.Create(Self);
  btnAIMru.Parent := Self;
  btnAIMru.Caption := #$25BC;
  btnAIMru.Hint := TrText('Extract.AI.RecentHint');
  btnAIMru.ShowHint := True;
  btnAIMru.TabStop := False;
  btnAIMru.Anchors := [akTop, akRight];
  btnAIMru.OnClick := AIMruClick;
  btnAI := TButton.Create(Self);
  btnAI.Parent := Self;
  btnAI.Caption := TrText('Extract.AI.Button') + ' (Enter)';
  btnAI.Hint := TrText('Extract.AI.Hint');
  btnAI.ShowHint := True;
  btnAI.OnClick := AIClick;
  btnAI.Anchors := [akTop, akRight];
  FAICaption := btnAI.Caption;
  lblAIInfo := NewLabel(150, 124, '');
  lblAIInfo.AutoSize := False;
  lblAIInfo.WordWrap := True;
  lblAIInfo.SetBounds(FfPx(150), FfPx(124), W - FfPx(162), FfPx(32));
  lblAIInfo.Anchors := [akLeft, akTop, akRight];
  lblAIInfo.ShowHint := True;
  lblAIInfo.ShowAccelChar := False;
  lblAIInfo.Font.Color := clGrayText;
  lblAIInfo.Caption := TrText('Extract.AI.Hint');
  lblAIInfo.Hint := lblAIInfo.Caption;

  chkCase := NewCheck(150, 160, 240, 'Extract.MatchCase', GCase);
  chkUnique := NewCheck(400, 160, 248, 'Extract.Unique', GUnique);
  chkGroup1 := NewCheck(150, 182, 240, 'Extract.Group1', GGroup1);
  chkKeepSpaces := NewCheck(400, 182, 248, 'Extract.KeepSpaces', False);

  lblSep := NewLabel(12, 212, 'Extract.Separator');
  cbSep := NewCombo(150, 208, 200);
  for I := 0 to High(SEP_KEYS) do
    cbSep.Items.Add(TrText(SEP_KEYS[I]));
  cbSep.ItemIndex := EnsureRange(GSep, 0, High(SEP_KEYS));
  cbSep.OnChange := OptionChanged;

  lblCols := NewLabel(12, 242, 'Anon.Columns');
  edtCols := TEdit.Create(Self);
  edtCols.Parent := Self;
  edtCols.SetBounds(FfPx(150), FfPx(238), FfPx(120), edtCols.Height);
  edtCols.Text := GColumns;
  edtCols.Hint := TrText('Extract.Columns.Hint');
  edtCols.ShowHint := True;
  edtCols.OnChange := OptionChanged;
  lblDelim := NewLabel(290, 242, 'Extract.Delimiter');
  cbDelim := NewCombo(400, 238, 200);
  for I := 0 to High(DELIM_KEYS) do
    cbDelim.Items.Add(TrText(DELIM_KEYS[I]));
  cbDelim.ItemIndex := EnsureRange(GDelim, 0, High(DELIM_KEYS));
  cbDelim.OnChange := OptionChanged;

  lblExample := NewLabel(12, 272, '');
  lblExample.AutoSize := False;
  lblExample.WordWrap := True;
  lblExample.SetBounds(FfPx(12), FfPx(272), W - FfPx(24), FfPx(34));
  lblExample.Anchors := [akLeft, akTop, akRight];
  lblExample.Font.Color := clGrayText;

  lblResult := NewLabel(12, 314, 'Extract.Result');
  lblResult.Font.Style := [fsBold];
  lblCount := NewLabel(110, 314, '');
  lblCount.Anchors := [akLeft, akTop, akRight];

  mmResult := TMemo.Create(Self);
  mmResult.Parent := Self;
  mmResult.SetBounds(FfPx(12), FfPx(334), W - FfPx(24), H - FfPx(334) - FfPx(52));
  mmResult.Anchors := [akLeft, akTop, akRight, akBottom];
  mmResult.ReadOnly := True;
  mmResult.ScrollBars := ssVertical;
  mmResult.WordWrap := True;
  mmResult.Font.Name := 'Consolas';
  mmResult.Color := clBtnFace;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Caption := TrText('Cancel');
  btnCancel.Cancel := True;
  btnCancel.ModalResult := mrCancel;
  btnCopy := TButton.Create(Self);
  btnCopy.Parent := Self;
  btnCopy.Caption := TrText('Copy');
  btnCopy.OnClick := CopyClick;
  btnReplace := TButton.Create(Self);
  btnReplace.Parent := Self;
  if FFromSel then
    btnReplace.Caption := TrText('Extract.ReplaceSel') + ' (Ctrl+Enter)'
  else
    btnReplace.Caption := TrText('Extract.Replace') + ' (Ctrl+Enter)';
  btnReplace.ModalResult := mrOk;
  btnCancel.SetBounds(W - FfPx(12) - FfPx(110), H - FfPx(40), FfPx(110), FfPx(28));
  btnCopy.SetBounds(btnCancel.Left - FfPx(8) - FfPx(110), btnCancel.Top, FfPx(110), FfPx(28));
  btnReplace.SetBounds(btnCopy.Left - FfPx(8) - FfPx(210), btnCancel.Top, FfPx(210), FfPx(28));
  btnCancel.Anchors := [akRight, akBottom];
  btnCopy.Anchors := [akRight, akBottom];
  btnReplace.Anchors := [akRight, akBottom];

  LayoutColumns;
  FUpdating := True;
  try
    cbKind.ItemIndex := Ord(GKind);
  finally
    FUpdating := False;
  end;
  KindChanged(nil);
  ActiveControl := cbKind;
end;

{ Coluna dos controles alinhada ao maior rotulo (traducoes mais longas). }
procedure TExtractForm.LayoutColumns;
var
  X, R, BW, C1, C2, X2: Integer;
begin
  X := Max(Max(lblWhat.Width, lblRegex.Width), Max(Max(lblSep.Width, lblCols.Width), lblAI.Width));
  X := Max(FfPx(150), lblWhat.Left + X + FfPx(12));
  R := ClientWidth - FfPx(12);
  cbKind.SetBounds(X, cbKind.Top, R - X, cbKind.Height);
  BW := TextW(btnCopyRegex.Caption) + FfPx(32);
  btnCopyRegex.SetBounds(R - BW, edtRegex.Top - FfPx(1), BW, edtRegex.Height + FfPx(2));
  edtRegex.SetBounds(X, edtRegex.Top, btnCopyRegex.Left - FfPx(8) - X, edtRegex.Height);
  BW := TextW(btnAI.Caption) + FfPx(32);
  btnAI.SetBounds(R - BW, edtAI.Top - FfPx(1), BW, edtAI.Height + FfPx(2));
  btnAIMru.SetBounds(btnAI.Left - FfPx(8) - FfPx(26), edtAI.Top, FfPx(26), edtAI.Height);
  edtAI.SetBounds(X, edtAI.Top, btnAIMru.Left - X, edtAI.Height);
  lblAIInfo.SetBounds(X, lblAIInfo.Top, R - X, lblAIInfo.Height);

  { caixas de selecao: largura pelo texto; 2a coluna depois da mais larga da 1a }
  C1 := Max(TextW(chkCase.Caption), TextW(chkGroup1.Caption)) + FfPx(24);
  C2 := Max(TextW(chkUnique.Caption), TextW(chkKeepSpaces.Caption)) + FfPx(24);
  X2 := X + C1 + FfPx(24);
  chkCase.SetBounds(X, chkCase.Top, C1, chkCase.Height);
  chkGroup1.SetBounds(X, chkGroup1.Top, C1, chkGroup1.Height);
  chkUnique.SetBounds(X2, chkUnique.Top, C2, chkUnique.Height);
  chkKeepSpaces.SetBounds(X2, chkKeepSpaces.Top, C2, chkKeepSpaces.Height);
  if X2 + C2 > R then
  begin
    ClientWidth := ClientWidth + (X2 + C2 - R);
    LayoutColumns;
    Exit;
  end;

  cbSep.Left := X;
  edtCols.Left := X;
  lblDelim.Left := edtCols.Left + edtCols.Width + FfPx(20);
  cbDelim.Left := lblDelim.Left + lblDelim.Width + FfPx(8);
  LayoutRows;
end;

function TExtractForm.Kind: TExtractKind;
begin
  if cbKind.ItemIndex < 0 then
    Result := ekDigits
  else
    Result := TExtractKind(cbKind.ItemIndex);
end;

function TExtractForm.SepText: string;
begin
  if (cbSep.ItemIndex >= 0) and (cbSep.ItemIndex <= High(SEP_VALUES)) then
    Result := SEP_VALUES[cbSep.ItemIndex]
  else
    Result := '';
end;

procedure TExtractForm.UpdateControls;
var
  K: TExtractKind;
  IsRe, IsFilter, IsCols: Boolean;
begin
  K := Kind;
  IsRe := K in REGEX_KINDS;
  IsFilter := K in FILTER_KINDS;
  IsCols := K = ekColumns;
  lblRegex.Enabled := IsRe;
  edtRegex.Enabled := IsRe;
  chkCase.Enabled := IsRe;
  chkGroup1.Enabled := IsRe;
  chkUnique.Enabled := IsRe;
  chkKeepSpaces.Enabled := IsFilter;
  lblSep.Enabled := not IsFilter;
  cbSep.Enabled := not IsFilter;
  lblCols.Enabled := IsCols;
  edtCols.Enabled := IsCols;
  lblDelim.Enabled := IsCols;
  cbDelim.Enabled := IsCols;
end;

procedure TExtractForm.KindChanged(Sender: TObject);
var
  K: TExtractKind;
begin
  if FUpdating and (Sender <> nil) then Exit;
  K := Kind;
  FUpdating := True;
  try
    if K = ekCustom then
      edtRegex.Text := GCustom
    else
      edtRegex.Text := KIND_PATTERNS[K];
    if K = ekQuoted then
      chkGroup1.Checked := True
    else if K <> ekCustom then
      chkGroup1.Checked := False;
    chkKeepSpaces.Checked := K in KEEP_SPACE_KINDS;
  finally
    FUpdating := False;
  end;
  UpdateControls;
  Recompute;
end;

procedure TExtractForm.OptionChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  Schedule(Sender = edtCols);
end;

{ Editar o padrao de um item pronto passa para "Expressao regular personalizada". }
procedure TExtractForm.RegexChanged(Sender: TObject);
begin
  if FUpdating then Exit;
  if Kind <> ekCustom then
  begin
    FUpdating := True;
    try
      cbKind.ItemIndex := Ord(ekCustom);
    finally
      FUpdating := False;
    end;
    UpdateControls;
  end;
  GCustom := edtRegex.Text;
  Schedule(True);
end;

procedure TExtractForm.Schedule(AForceDelay: Boolean);
begin
  FTimer.Enabled := False;
  if (not AForceDelay) and (Length(FSource) <= LIVE_MAX_CHARS) then
    Recompute
  else
    FTimer.Enabled := True;
end;

procedure TExtractForm.TimerTick(Sender: TObject);
begin
  FTimer.Enabled := False;
  Recompute;
end;

function TExtractForm.RunOn(const AText: string; out ACount: Integer;
  out AErr: string): string;
var
  K: TExtractKind;
begin
  ACount := 0;
  AErr := '';
  Result := '';
  K := Kind;
  if K in FILTER_KINDS then
  begin
    Result := FilterText(AText, K, chkKeepSpaces.Checked);
    if Result <> '' then
      ACount := 1;
  end
  else if K = ekColumns then
    Result := ExtractColumns(AText, edtCols.Text, cbDelim.ItemIndex, SepText, ACount, AErr)
  else if edtRegex.Text <> '' then
    Result := ExtractMatches(AText, edtRegex.Text, chkCase.Checked, chkGroup1.Checked,
      chkUnique.Checked, SepText, ACount, AErr);
end;

procedure TExtractForm.Recompute;
var
  Count, ExCount: Integer;
  Err, ExErr, ExRes, Sample, Info: string;
  Cur: TCursor;
begin
  FTimer.Enabled := False;
  Cur := Screen.Cursor;
  if Length(FSource) > LIVE_MAX_CHARS then
    Screen.Cursor := crHourGlass;
  try
    FResult := RunOn(FSource, Count, Err);
  finally
    Screen.Cursor := Cur;
  end;

  Sample := KIND_SAMPLES[Kind];
  ExRes := RunOn(Sample, ExCount, ExErr);
  if (Kind = ekCustom) and (Trim(edtRegex.Text) = '') then
    lblExample.Caption := TrText('Extract.CustomHint')
  else if ExErr <> '' then
    lblExample.Caption := TrText('Extract.Example') + ' ' + Sample
  else
  begin
    ExRes := StringReplace(ExRes, #13#10, ' '#$21B5' ', [rfReplaceAll]);
    if Length(ExRes) > EXAMPLE_MAX_CHARS then
      ExRes := Copy(ExRes, 1, EXAMPLE_MAX_CHARS) + #$2026;
    lblExample.Caption := TrText('Extract.Example') + ' ' + Sample + '   ' + #$2192 + '   ' + ExRes;
  end;

  if Err <> '' then
  begin
    FResult := '';
    mmResult.Text := '';
    lblCount.Font.Color := clRed;
    lblCount.Caption := Err;
  end
  else
  begin
    lblCount.Font.Color := clWindowText;
    if Length(FResult) > PREVIEW_MAX_CHARS then
      mmResult.Text := Copy(FResult, 1, PREVIEW_MAX_CHARS)
    else
      mmResult.Text := FResult;
    if FResult = '' then
      Info := TrText('Extract.NotFound')
    else if Kind in FILTER_KINDS then
      Info := Format(TrText('Extract.CountChars'), [Length(FResult)])
    else
      Info := Format(TrText('Extract.Count'), [Count, Length(FResult)]);
    if Length(FResult) > PREVIEW_MAX_CHARS then
      Info := Info + ' ' + Format(TrText('Extract.PreviewCut'), [PREVIEW_MAX_CHARS]);
    lblCount.Caption := Info;
  end;
  lblCount.Left := lblResult.Left + lblResult.Width + FfPx(12);
  btnReplace.Enabled := (Err = '') and (FResult <> '');
  btnCopy.Enabled := btnReplace.Enabled;
end;

function TExtractForm.BuildAIPrompt: WideString;
var
  Sample, CaseTxt: string;
begin
  Sample := Copy(FSource, 1, AI_SAMPLE_CHARS);
  if chkCase.Checked then
    CaseTxt := 'case-sensitive'
  else
    CaseTxt := 'case-insensitive';
  Result := WideString(Format(AI_PROMPT_FMT, [CaseTxt,
    AssistantLangPromptName(GetCurrentLanguage), Trim(edtAI.Text), edtRegex.Text,
    AI_SAMPLE_CHARS, Sample]));
end;

procedure TExtractForm.AIClick(Sender: TObject);
begin
  if Assigned(FAIThread) then Exit;
  if Trim(edtAI.Text) = '' then
  begin
    SetAIInfo(TrText('Extract.AI.NeedText'), clRed);
    if edtAI.CanFocus then
      edtAI.SetFocus;
    Exit;
  end;
  RememberAIRequest(edtAI.Text);
  SetAIInfo(TrText('Assistant.Thinking'), clGrayText);
  btnAI.Caption := TrText('Assistant.Thinking');
  btnAI.Enabled := False;
  btnAIMru.Enabled := False;
  edtAI.Enabled := False;
  FAIThread := TExtractAIThread.Create(Self, BuildAIPrompt);
  FAIThread.Start;
end;

procedure TExtractForm.AIEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift * [ssCtrl, ssShift, ssAlt] = []) then
  begin
    Key := 0;
    AIClick(btnAI);
  end
  else if (Key = VK_F4) or ((Key = VK_DOWN) and (ssAlt in Shift)) then
  begin
    Key := 0;
    AIMruClick(btnAIMru);
  end;
end;

procedure TExtractForm.AIFinished(AOk: Boolean; const AAnswer: WideString;
  const AError: string);
var
  Pat, Expl, Info: string;
  G1, Valid: Boolean;
  MatchCase: Integer;
begin
  btnAI.Caption := FAICaption;
  btnAI.Enabled := True;
  btnAIMru.Enabled := True;
  edtAI.Enabled := True;
  if not AOk then
  begin
    SetAIInfo(Format(TrText('Extract.AI.Failed'), [AError]), clRed);
    Exit;
  end;
  ParseAIAnswer(string(AAnswer), Pat, G1, MatchCase, Expl);
  Valid := Pat <> '';
  if Valid then
  try
    TRegEx.Create(Pat).IsMatch('');
  except
    Valid := False;
  end;
  if not Valid then
  begin
    SetAIInfo(TrText('Extract.AI.NoRegex'), clRed);
    Exit;
  end;
  FUpdating := True;
  try
    cbKind.ItemIndex := Ord(ekCustom);
    edtRegex.Text := Pat;
    chkGroup1.Checked := G1;
    if MatchCase >= 0 then
      chkCase.Checked := MatchCase = 1;
  finally
    FUpdating := False;
  end;
  GCustom := Pat;
  UpdateControls;
  Info := Format(TrText('Extract.AI.Generated'), [Pat]);
  if chkCase.Checked then
    Info := Info + '   (' + chkCase.Caption + ')';
  if Expl <> '' then
    Info := Info + #13#10 + Format(TrText('Extract.AI.Explanation'), [Expl]);
  SetAIInfo(Info, clGrayText);
  Recompute;
end;

procedure TExtractForm.CopyRegexClick(Sender: TObject);
begin
  if edtRegex.Text = '' then Exit;
  Clipboard.AsText := edtRegex.Text;
  lblCount.Font.Color := clWindowText;
  lblCount.Caption := TrText('Extract.RegexCopied');
end;

procedure TExtractForm.CopyClick(Sender: TObject);
begin
  if FResult = '' then Exit;
  Clipboard.AsText := FResult;
  lblCount.Font.Color := clWindowText;
  lblCount.Caption := TrText('Extract.Copied');
end;

procedure TExtractForm.FormKeyDownExtract(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift * [ssCtrl, ssShift, ssAlt] = [ssCtrl]) then
  begin
    Key := 0;
    if FTimer.Enabled then
      Recompute;
    if btnReplace.Enabled then
      ModalResult := mrOk;
  end;
end;

procedure TExtractForm.SaveSettings;
begin
  GKind := Kind;
  GSep := cbSep.ItemIndex;
  GCase := chkCase.Checked;
  GUnique := chkUnique.Checked;
  if Kind = ekCustom then
    GGroup1 := chkGroup1.Checked;
  GColumns := edtCols.Text;
  GDelim := cbDelim.ItemIndex;
end;

function ShowLineExtractDialog(AOwner: TComponent; const ASource: string;
  AFromSelection: Boolean; out AResult: string): Boolean;
var
  F: TExtractForm;
begin
  AResult := '';
  F := TExtractForm.CreateDlg(AOwner, ASource, AFromSelection);
  try
    Result := F.ShowModal = mrOk;
    F.SaveSettings;
    if Result then
    begin
      if F.FTimer.Enabled then
        F.Recompute;
      AResult := F.FResult;
      Result := AResult <> '';
    end;
  finally
    F.Free;
  end;
end;

end.
