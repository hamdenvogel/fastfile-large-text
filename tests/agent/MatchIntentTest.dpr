program MatchIntentTest;

{$APPTYPE CONSOLE}

{ The user's three requests in the 14 UI languages: plain -> partial, "partial" -> partial, "not partial / exact" -> exact. }

uses
  Windows, SysUtils, uAgentMatchIntent;

type
  TCase = record
    Lang, Text: string;
    Exact: Boolean;
  end;

const
  CASES: array[0..48] of TCase = (
    (Lang: 'hu'; Text: 'az Allyne nevet keresem, a pontos nevet'; Exact: True),
    (Lang: 'pt-BR'; Text: 'eu quero pesquisar o nome Allyne'; Exact: False),
    (Lang: 'pt-BR'; Text: 'eu quero pesquisar o nome Allyne que é parcial'; Exact: False),
    (Lang: 'pt-BR'; Text: 'eu quero pesquisar o nome Allyne sem ser parcial ou seja o nome exato'; Exact: True),
    (Lang: 'pt-PT'; Text: 'quero pesquisar o nome Allyne'; Exact: False),
    (Lang: 'pt-PT'; Text: 'quero pesquisar o nome Allyne, que é parcial'; Exact: False),
    (Lang: 'pt-PT'; Text: 'quero pesquisar o nome Allyne sem ser parcial, ou seja, o nome exacto'; Exact: True),
    (Lang: 'en'; Text: 'I want to search for the name Allyne'; Exact: False),
    (Lang: 'en'; Text: 'I want to search for the name Allyne, partial is fine'; Exact: False),
    (Lang: 'en'; Text: 'I want to search for the name Allyne, not partial, that is, the exact name'; Exact: True),
    (Lang: 'es'; Text: 'quiero buscar el nombre Allyne'; Exact: False),
    (Lang: 'es'; Text: 'quiero buscar el nombre Allyne, que es parcial'; Exact: False),
    (Lang: 'es'; Text: 'quiero buscar el nombre Allyne sin ser parcial, o sea, el nombre exacto'; Exact: True),
    (Lang: 'fr'; Text: 'je veux rechercher le nom Allyne'; Exact: False),
    (Lang: 'fr'; Text: 'je veux rechercher le nom Allyne, qui est partiel'; Exact: False),
    (Lang: 'fr'; Text: 'je veux rechercher le nom Allyne, pas partiel, c''est-à-dire le nom exact'; Exact: True),
    (Lang: 'de'; Text: 'ich möchte nach dem Namen Allyne suchen'; Exact: False),
    (Lang: 'de'; Text: 'ich möchte nach dem Namen Allyne suchen, auch teilweise'; Exact: False),
    (Lang: 'de'; Text: 'ich möchte nach dem Namen Allyne suchen, nicht teilweise, also den exakten Namen'; Exact: True),
    (Lang: 'it'; Text: 'voglio cercare il nome Allyne'; Exact: False),
    (Lang: 'it'; Text: 'voglio cercare il nome Allyne, che è parziale'; Exact: False),
    (Lang: 'it'; Text: 'voglio cercare il nome Allyne, non parziale, cioè il nome esatto'; Exact: True),
    (Lang: 'pl'; Text: 'chcę wyszukać imię Allyne'; Exact: False),
    (Lang: 'pl'; Text: 'chcę wyszukać imię Allyne, które jest częściowe'; Exact: False),
    (Lang: 'pl'; Text: 'chcę wyszukać imię Allyne, nie częściowo, czyli dokładne imię'; Exact: True),
    (Lang: 'ro'; Text: 'vreau să caut numele Allyne'; Exact: False),
    (Lang: 'ro'; Text: 'vreau să caut numele Allyne, care este parțial'; Exact: False),
    (Lang: 'ro'; Text: 'vreau să caut numele Allyne, nu parțial, adică numele exact'; Exact: True),
    (Lang: 'hu'; Text: 'az Allyne nevet szeretném keresni'; Exact: False),
    (Lang: 'hu'; Text: 'az Allyne nevet szeretném keresni, ami részleges'; Exact: False),
    (Lang: 'hu'; Text: 'az Allyne nevet szeretném keresni, nem részleges, vagyis a pontos nevet'; Exact: True),
    (Lang: 'cs'; Text: 'chci vyhledat jméno Allyne'; Exact: False),
    (Lang: 'cs'; Text: 'chci vyhledat jméno Allyne, které je částečné'; Exact: False),
    (Lang: 'cs'; Text: 'chci vyhledat jméno Allyne, ne částečně, tedy přesné jméno'; Exact: True),
    (Lang: 'ja'; Text: 'Allyneという名前を検索したい'; Exact: False),
    (Lang: 'ja'; Text: 'Allyneという名前を部分一致で検索したい'; Exact: False),
    (Lang: 'ja'; Text: 'Allyneという名前を部分一致ではなく、完全一致で検索したい'; Exact: True),
    (Lang: 'zh-CN'; Text: '我想搜索名字Allyne'; Exact: False),
    (Lang: 'zh-CN'; Text: '我想搜索名字Allyne，部分匹配'; Exact: False),
    (Lang: 'zh-CN'; Text: '我想搜索名字Allyne，不要部分匹配，也就是完全匹配'; Exact: True),
    (Lang: 'zh-TW'; Text: '我想搜尋名字Allyne'; Exact: False),
    (Lang: 'zh-TW'; Text: '我想搜尋名字Allyne，部分匹配'; Exact: False),
    (Lang: 'zh-TW'; Text: '我想搜尋名字Allyne，不要部分匹配，也就是完全相符'; Exact: True),
    { Words that only look like "exact": must stay partial. }
    (Lang: 'pt-BR'; Text: 'quero exatamente as linhas com Allyne'; Exact: False),
    (Lang: 'en'; Text: 'show me exactly the lines with Allyne'; Exact: False),
    (Lang: 'de'; Text: 'zeig mir genau die Zeilen mit Allyne'; Exact: False),
    (Lang: 'pl'; Text: 'pokaż dokładnie wiersze z Allyne'; Exact: False),
    (Lang: 'hu'; Text: 'mutasd pontosan az Allyne sorokat'; Exact: False),
    (Lang: 'en'; Text: 'count Allyne, whole word only'; Exact: True));

var
  I, Fails: Integer;
  Got: Boolean;
  Line: string;
  W: DWORD;
begin
  Fails := 0;
  for I := 0 to High(CASES) do
  begin
    Got := AgentWantsExactMatch(CASES[I].Text);
    if Got = CASES[I].Exact then
      Line := 'ok   '
    else
    begin
      Line := 'FAIL ';
      Inc(Fails);
    end;
    Line := Line + Format('%-6s exact=%-5s %s', [CASES[I].Lang, BoolToStr(Got, True), CASES[I].Text]) + #13#10;
    WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), PChar(Line), Length(Line), W, nil);
  end;
  Writeln('fails=', Fails);
end.
