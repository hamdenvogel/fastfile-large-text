program NewLanguagesTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, uAgentMatchIntent, uAgentTargets;

var
  Checks, Fails: Integer;
  Files, Targets: TStringList;

procedure Check(const Name: string; Value: Boolean);
begin
  Inc(Checks);
  if not Value then
  begin
    Inc(Fails);
    Writeln('FAIL: ', Name);
  end;
end;

procedure Target(const Name, Prompt, Expected: string);
var
  Mode: TAgentTargetMode;
  Actual: string;
  I: Integer;
  C: Char;
begin
  Mode := AgentInferTargets(Prompt, Files, Targets);
  Actual := '';
  if Mode = tgtNone then Actual := '-'
  else
    for I := 0 to Targets.Count - 1 do
      Actual := Actual + IntToStr(Files.IndexOf(Targets[I]) + 1);
  Check(Name + ' expected=' + Expected + ' actual=' + Actual, Actual = Expected);
  if Actual <> Expected then
  begin
    Write('Folded UTF-16: ');
    for C in AgentFoldText(Prompt) do Write(IntToHex(Ord(C), 4), ' ');
    Writeln;
  end;
end;

procedure Intent(const Name, Exact, Partial, NotPartial, Promise, Claim, Queue: string);
begin
  Check(Name + ' exact', AgentWantsExactMatch(Exact));
  Check(Name + ' partial', not AgentWantsExactMatch(Partial));
  Check(Name + ' negated partial', AgentWantsExactMatch(NotPartial));
  Check(Name + ' promise', AgentAnswerPromisesWork(Promise));
  Check(Name + ' claim', AgentAnswerClaimsWork(Claim));
  Check(Name + ' queue', AgentAnswerClaimsQueue(Queue));
end;

begin
  Checks := 0;
  Fails := 0;
  Files := TStringList.Create;
  Targets := TStringList.Create;
  try
    Files.Add('C:\fixture\one.csv');
    Files.Add('C:\fixture\two.txt');
    Files.Add('C:\fixture\three.txt');
    Intent('hi', 'Allyne का सटीक मिलान खोजें', 'Allyne का आंशिक मिलान खोजें',
      'आंशिक मिलान नहीं, Allyne खोजें', 'कृपया प्रतीक्षा करें',
      'फ़ाइल सहेजी गई', 'प्रस्ताव स्वीकार करें');
    Intent('ru', 'Найди точное совпадение Allyne', 'Найди частичное совпадение Allyne',
      'Найди Allyne без частичного совпадения', 'Пожалуйста подождите',
      'Файл сохранён', 'Предложение в очереди, нажмите Принять');
    Intent('ko', 'Allyne를 정확한 일치로 검색', 'Allyne를 부분 일치로 검색',
      'Allyne를 부분 일치 말고 검색', '잠시만 기다려 주세요',
      '파일이 저장되었습니다', '제안되었습니다. 수락하세요');
    Intent('nl', 'Zoek Allyne als heel woord', 'Zoek een gedeeltelijke match voor Allyne',
      'Zoek Allyne, niet gedeeltelijk', 'Even wachten, ik zal het controleren',
      'Het bestand is opgeslagen', 'Het voorstel staat in de wachtrij');
    Intent('tr', 'Allyne için tam eşleşme ara', 'Allyne için kısmi eşleşme ara',
      'Allyne ara, kısmi değil', 'Lütfen bekleyin',
      'Dosya kaydedildi', 'Öneri beklemede, kabul et');
    Intent('uk', 'Знайди точний збіг Allyne', 'Знайди частковий збіг Allyne',
      'Знайди Allyne без часткового збігу', 'Будь ласка зачекайте',
      'Файл збережено', 'Пропозицію додано у черзі, прийняти');
    Target('hi first', 'पहली फ़ाइल पढ़ें', '1');
    Target('hi second', 'दूसरी फ़ाइल पढ़ें', '2');
    Target('hi last', 'अंतिम फ़ाइल पढ़ें', '3');
    Target('hi except last', 'अंतिम फ़ाइल छोड़कर सभी फ़ाइलों को पढ़ें', '12');
    Target('ru first', 'Прочитай первый файл', '1');
    Target('ru second', 'Прочитай второй файл', '2');
    Target('ru last', 'Прочитай последний файл', '3');
    Target('ru except last', 'Прочитай все файлы кроме последнего', '12');
    Target('ko first', '첫 번째 파일을 읽어', '1');
    Target('ko second', '두 번째 파일을 읽어', '2');
    Target('ko last', '마지막 파일을 읽어', '3');
    Target('ko except last', '마지막 파일을 제외하고 모든 파일을 읽어', '12');
    Target('nl first', 'Lees het eerste bestand', '1');
    Target('nl second', 'Lees het tweede bestand', '2');
    Target('nl last', 'Lees het laatste bestand', '3');
    Target('nl except last', 'Lees alle bestanden behalve het laatste', '12');
    Target('tr first', 'İlk dosyayı oku', '1');
    Target('tr second', 'İkinci dosyayı oku', '2');
    Target('tr last', 'Son dosyayı oku', '3');
    Target('tr except last', 'Son dosya hariç tüm dosyaları oku', '12');
    Target('uk first', 'Прочитай перший файл', '1');
    Target('uk second', 'Прочитай другий файл', '2');
    Target('uk last', 'Прочитай останній файл', '3');
    Target('uk except last', 'Прочитай усі файли крім останнього', '12');
    Check('ordinary text is not a work claim', not AgentAnswerClaimsWork('one.csv'));
  finally
    Targets.Free;
    Files.Free;
  end;
  Writeln('checks=', Checks, ' fails=', Fails);
  if Fails <> 0 then Halt(1);
end.
