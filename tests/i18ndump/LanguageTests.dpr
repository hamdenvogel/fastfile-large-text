program LanguageTests;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.JSON,
  System.IOUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics,
  uI18n, uBidiLayout, uAgentProtocol;

type
  TLanguageCase = record
    Language: TAppLanguage;
    Code, RegionalCode, Name, Sample, Describe, Macro: string;
  end;
  PTextSize = ^TSize;

const
  Cases: array[0..11] of TLanguageCase = (
    (Language: alHindi; Code: 'hi'; RegionalCode: 'HI_IN'; Name: 'Hindi';
      Sample: 'हिन्दी फ़ाइल क्षेत्र';
      Describe: 'यह फ़ाइल क्या है';
      Macro: 'प्रत्येक पंक्ति पर पायथन मैक्रो चलाएँ'),
    (Language: alRussian; Code: 'ru'; RegionalCode: 'RU_RU'; Name: 'Russian';
      Sample: 'Русский файл сохранён';
      Describe: 'Что это за файл';
      Macro: 'Выполни макрос Python на каждой строке'),
    (Language: alKorean; Code: 'ko'; RegionalCode: 'KO_KR'; Name: 'Korean';
      Sample: '한국어 파일 저장';
      Describe: '이 파일은 무엇인가요';
      Macro: '모든 줄에서 파이썬 매크로 실행'),
    (Language: alDutch; Code: 'nl'; RegionalCode: 'NL_BE'; Name: 'Dutch';
      Sample: 'Nederlands geëxporteerd';
      Describe: 'Wat is dit bestand';
      Macro: 'Voer een Python-macro uit op elke regel'),
    (Language: alTurkish; Code: 'tr'; RegionalCode: 'TR_TR'; Name: 'Turkish';
      Sample: 'Türkçe İı Şş Ğğ Çç Öö Üü';
      Describe: 'Bu dosya nedir';
      Macro: 'Her satır için Python betiğini çalıştır'),
    (Language: alUkrainian; Code: 'uk'; RegionalCode: 'UK_UA'; Name: 'Ukrainian';
      Sample: 'Українська ї є ґ файл';
      Describe: 'Що це за файл';
      Macro: 'Виконай макрос Python у кожному рядку'),
    (Language: alThai; Code: 'th'; RegionalCode: 'TH_TH'; Name: 'Thai';
      Sample: 'ภาษาไทย';
      Describe: 'ไฟล์นี้คืออะไร';
      Macro: 'เรียกใช้แมโคร python ในทุกบรรทัด'),
    (Language: alGreek; Code: 'el'; RegionalCode: 'EL_GR'; Name: 'Greek';
      Sample: 'Ελληνικά αρχείο';
      Describe: 'Τι είναι αυτό το αρχείο';
      Macro: 'Εκτέλεσε μακροεντολή Python σε κάθε γραμμή'),
    (Language: alNorwegian; Code: 'nb'; RegionalCode: 'NB_NO'; Name: 'Norwegian';
      Sample: 'Norsk fil lagret';
      Describe: 'Hva er denne filen';
      Macro: 'Kjør en Python-makro på hver linje'),
    (Language: alSwedish; Code: 'sv'; RegionalCode: 'SV_SE'; Name: 'Swedish';
      Sample: 'Svensk fil sparad';
      Describe: 'Vad är den här filen';
      Macro: 'Kör ett Python-makro på varje rad'),
    (Language: alDanish; Code: 'da'; RegionalCode: 'DA_DK'; Name: 'Danish';
      Sample: 'Dansk fil gemt æ ø å';
      Describe: 'Hvad er denne fil';
      Macro: 'Kør en Python-makro på hver linje'),
    (Language: alIcelandic; Code: 'is'; RegionalCode: 'IS_IS'; Name: 'Icelandic';
      Sample: 'Íslensk skrá vistuð ð þ';
      Describe: 'Hvað er þessi skrá';
      Macro: 'Keyrðu Python-fjölva á hverri línu'));
  SSA_FALLBACK = $00000020;
  SSA_GLYPHS = $00000080;

function ScriptStringAnalyse(DC: HDC; Text: Pointer; TextLength, Glyphs, Charset: Integer;
  Flags: DWORD; Width: Integer; Control, State, Dx, Tabs, Classes: Pointer;
  var Analysis: Pointer): HRESULT; stdcall; external 'usp10.dll';
function ScriptStringFree(var Analysis: Pointer): HRESULT;
  stdcall; external 'usp10.dll';
function ScriptString_pSize(Analysis: Pointer): PTextSize;
  stdcall; external 'usp10.dll';
function ScriptStringOut(Analysis: Pointer; X, Y: Integer; Options: UINT;
  Clip: PRect; MinSelection, MaxSelection: Integer; Disabled: BOOL): HRESULT;
  stdcall; external 'usp10.dll';

var
  Checks, Fails: Integer;
  Root: string;

procedure Check(const Name: string; Ok: Boolean);
begin
  Inc(Checks);
  if not Ok then
  begin
    Inc(Fails);
    Writeln('FAIL: ', Name);
  end;
end;

function LoadObject(const Path: string): TJSONObject;
var
  Value: TJSONValue;
begin
  Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Path, TEncoding.UTF8), False, True);
  if not (Value is TJSONObject) then
  begin
    Value.Free;
    raise EInvalidOpException.Create('Expected JSON object: ' + Path);
  end;
  Result := TJSONObject(Value);
end;

procedure CheckGlyphShaping(const Code, Sample, FontName: string);
var
  Bitmap: TBitmap;
  Analysis: Pointer;
  Size: PTextSize;
  Status: HRESULT;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(800, 100);
    Bitmap.Canvas.Font.Name := FontName;
    Bitmap.Canvas.Font.Size := 12;
    Analysis := nil;
    Status := ScriptStringAnalyse(Bitmap.Canvas.Handle, PChar(Sample),
      Length(Sample), Length(Sample) * 3 + 16, -1, SSA_GLYPHS or SSA_FALLBACK,
      800, nil, nil, nil, nil, nil, Analysis);
    Check(Code + ' shaping ' + FontName, Status >= 0);
    if Analysis <> nil then
    try
      Size := ScriptString_pSize(Analysis);
      Check(Code + ' glyph extent ' + FontName,
        (Size <> nil) and (Size.cx > 0) and (Size.cy > 0));
      Check(Code + ' glyph drawing ' + FontName,
        ScriptStringOut(Analysis, 0, 0, 0, nil, 0, 0, False) >= 0);
    finally
      Check(Code + ' shaping cleanup', ScriptStringFree(Analysis) >= 0);
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure Run;
var
  Catalog, Document, Translations, Entry: TJSONObject;
  Entries: TJSONArray;
  C: TLanguageCase;
  I: Integer;
  Kind, Key, Expected, Actual: string;
  Form: TForm;
  Button: TButton;
  Previous: TAppLanguage;
begin
  Check('language count', Ord(High(TAppLanguage)) + 1 = 28);
  Check('old ordinals preserved',
    (Ord(alEnglish) = 0) and (Ord(alArabic) = 14) and (Ord(alHebrew) = 15));
  Check('unknown code preserves English fallback', AppLanguageFromCode('unknown') = alEnglish);
  Catalog := LoadObject(Root + 'tools\i18n\catalog.json');
  try
    Entries := Catalog.GetValue<TJSONArray>('entries');
    Check('catalog contains entries', Entries.Count > 0);
    SetCurrentLanguage(alEnglish);
    BidiClearManual;
    Form := TForm.CreateNew(nil);
    try
      Form.ClientWidth := 300;
      Form.ClientHeight := 100;
      Button := TButton.Create(Form);
      Button.Parent := Form;
      Button.SetBounds(17, 10, 80, 25);
      Button.Caption := TrText('Yes');
      ApplyTranslationsToForm(Form);
      Previous := alEnglish;
      for C in Cases do
      begin
        Check(C.Code + ' code', AppLanguageCode(C.Language) = C.Code);
        Check(C.Code + ' code roundtrip', AppLanguageFromCode(C.Code) = C.Language);
        Check(C.Code + ' regional alias', AppLanguageFromCode(C.RegionalCode) = C.Language);
        Check(C.Code + ' name alias', AppLanguageFromCode(C.Name) = C.Language);
        Check(C.Code + ' assistant name', AssistantLangPromptName(C.Language) = C.Name);
        Check(C.Code + ' describe intent', AgentAsksWhatFilesAre(C.Describe));
        Check(C.Code + ' macro intent', AgentAsksLineMacro(C.Macro));
        SetCurrentLanguage(C.Language);
        Check(C.Code + ' current', GetCurrentLanguage = C.Language);
        Check(C.Code + ' not RTL', not IsRtlLanguage(C.Language));
        Check(C.Code + ' message box direction', RtlMsgBoxFlags = 0);
        ApplyTranslationsToForm(Form);
        RetranslateForm(Form, Previous);
        Check(C.Code + ' existing caption updated', Button.Caption = TrText('Yes'));
        BidiApplyForm(Form);
        Check(C.Code + ' application LTR', Application.BiDiMode = bdLeftToRight);
        Check(C.Code + ' no mirror', Button.Left = 17);
        Previous := C.Language;
        Document := LoadObject(Root + 'tools\i18n\' + C.Code + '.json');
        try
          Check(C.Code + ' catalog fingerprint',
            Document.GetValue<string>('sha256') = Catalog.GetValue<string>('sha256'));
          Translations := Document.GetValue<TJSONObject>('translations');
          Check(C.Code + ' full catalog', Translations.Count = Entries.Count);
          for I := 0 to Entries.Count - 1 do
          begin
            Entry := Entries.Items[I] as TJSONObject;
            Kind := Entry.GetValue<string>('kind');
            Key := Entry.GetValue<string>('key');
            Expected := Translations.GetValue<string>(IntToStr(I));
            if Kind = 'K' then Actual := Tr(Key, '__missing_i18n_entry__')
            else Actual := TrText(Key);
            Check(C.Code + ' lookup ' + IntToStr(I), Actual = Expected);
          end;
        finally
          Document.Free;
        end;
        CheckGlyphShaping(C.Code, C.Sample, 'Tahoma');
        CheckGlyphShaping(C.Code, C.Sample, 'Segoe UI');
        CheckGlyphShaping(C.Code, C.Sample, 'Arial');
        SetCurrentLanguage(alArabic);
        BidiApplyForm(Form);
        Check(C.Code + ' Arabic mirrors', Button.Left = Form.ClientWidth - 17 - Button.Width);
        SetCurrentLanguage(C.Language);
        BidiApplyForm(Form);
        Check(C.Code + ' Arabic to LTR restores', Button.Left = 17);
      end;
      SetCurrentLanguage(alHebrew);
      BidiApplyForm(Form);
      Check('Hebrew still RTL', IsRtlLanguage(alHebrew) and BidiIsRtl);
      SetCurrentLanguage(alHindi);
      BidiApplyForm(Form);
      Check('Hebrew to Hindi restores LTR', Button.Left = 17);
      BidiSetManual(True);
      BidiApplyForm(Form);
      Check('Hindi manual override preserved', BidiIsRtl);
      SetCurrentLanguage(alRussian);
      BidiApplyForm(Form);
      Check('language change clears manual override', not BidiIsRtl and not BidiHasManual);
    finally
      Form.Free;
    end;
  finally
    Catalog.Free;
  end;
end;

begin
  try
    Application.Initialize;
    Root := IncludeTrailingPathDelimiter(ExpandFileName(ParamStr(1)));
    Run;
    Writeln('checks=', Checks, ' fails=', Fails);
    if Fails <> 0 then Halt(1);
  except
    on E: Exception do
    begin
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
