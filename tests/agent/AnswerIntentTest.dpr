program AnswerIntentTest;

{$APPTYPE CONSOLE}

{ Model answers in the 14 UI languages: a promise ("I will count"), a plain final result, and a claim that
  something waits for Accept. }

uses
  Windows, SysUtils, uAgentMatchIntent;

type
  TCase = record
    Lang, Promise, Final, Queue: string;
  end;

const
  CASES: array[0..13] of TCase = (
    (Lang: 'en'; Promise: 'I will count the lines with Allyne now.'; Final: 'There are 9 lines with Allyne.';
      Queue: 'The export was queued; click Accept in Proposed edits.'),
    (Lang: 'pt-BR'; Promise: 'Vou contar as linhas com Allyne agora.'; Final: 'Há 9 linhas com Allyne.';
      Queue: 'A exportação foi proposta; clique em Aceitar em Edições propostas.'),
    (Lang: 'es'; Promise: 'Voy a contar las líneas con Allyne.'; Final: 'Hay 9 líneas con Allyne.';
      Queue: 'La exportación quedó pendiente; haga clic en Aceptar.'),
    (Lang: 'fr'; Promise: 'Je vais compter les lignes avec Allyne.'; Final: 'Il y a 9 lignes avec Allyne.';
      Queue: 'L''export est en attente : cliquez sur Accepter.'),
    (Lang: 'de'; Promise: 'Ich werde die Zeilen mit Allyne zählen.'; Final: 'Es gibt 9 Zeilen mit Allyne.';
      Queue: 'Der Export ist vorgeschlagen; klicken Sie auf Übernehmen.'),
    (Lang: 'it'; Promise: 'Sto contando le righe con Allyne.'; Final: 'Ci sono 9 righe con Allyne.';
      Queue: 'L''esportazione è in attesa: fai clic su Accetta.'),
    (Lang: 'pl'; Promise: 'Zaraz policzę wiersze z Allyne.'; Final: 'Jest 9 wierszy z Allyne.';
      Queue: 'Eksport oczekuje; kliknij Akceptuj.'),
    (Lang: 'pt-PT'; Promise: 'Estou a contar as linhas com Allyne.'; Final: 'Existem 9 linhas com Allyne.';
      Queue: 'A exportação ficou pendente; clique em Aceitar.'),
    (Lang: 'ro'; Promise: 'Voi număra liniile cu Allyne.'; Final: 'Sunt 9 linii cu Allyne.';
      Queue: 'Exportul este în așteptare; faceți clic pe Acceptare.'),
    (Lang: 'hu'; Promise: 'Egy pillanat, megnézem az Allyne sorokat.'; Final: '9 sor tartalmazza: Allyne.';
      Queue: 'Az exportálás függőben van; kattintson az Elfogadás gombra.'),
    (Lang: 'cs'; Promise: 'Počkejte, spočítám řádky s Allyne.'; Final: 'Je 9 řádků s Allyne.';
      Queue: 'Export čeká; klikněte na Přijmout.'),
    (Lang: 'ja'; Promise: 'これからAllyneの行を数えます。'; Final: 'Allyneを含む行は9行です。';
      Queue: 'エクスポートを提案しました。「適用」をクリックしてください。'),
    (Lang: 'zh-CN'; Promise: '我将统计包含Allyne的行。'; Final: '共有9行包含Allyne。';
      Queue: '导出已排队，请点击“接受”。'),
    (Lang: 'zh-TW'; Promise: '請稍候，我會統計包含Allyne的行。'; Final: '共有9行包含Allyne。';
      Queue: '匯出已排隊，請按「接受」。'));

var
  I, Fails: Integer;
  Line: string;
  W: DWORD;

procedure Check(const ALang, AWhat, AText: string; AGot, AWant: Boolean);
begin
  if AGot = AWant then
    Line := 'ok   '
  else
  begin
    Line := 'FAIL ';
    Inc(Fails);
  end;
  Line := Line + Format('%-6s %-14s %s', [ALang, AWhat, AText]) + #13#10;
  WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), PChar(Line), Length(Line), W, nil);
end;

begin
  Fails := 0;
  for I := 0 to High(CASES) do
  begin
    Check(CASES[I].Lang, 'promise', CASES[I].Promise, AgentAnswerPromisesWork(CASES[I].Promise), True);
    Check(CASES[I].Lang, 'final/promise', CASES[I].Final, AgentAnswerPromisesWork(CASES[I].Final), False);
    Check(CASES[I].Lang, 'final/claims', CASES[I].Final, AgentAnswerClaimsWork(CASES[I].Final), False);
    Check(CASES[I].Lang, 'final/queue', CASES[I].Final, AgentAnswerClaimsQueue(CASES[I].Final), False);
    Check(CASES[I].Lang, 'queue', CASES[I].Queue, AgentAnswerClaimsQueue(CASES[I].Queue), True);
    Check(CASES[I].Lang, 'queue/claims', CASES[I].Queue, AgentAnswerClaimsWork(CASES[I].Queue), True);
  end;
  Writeln('fails=', Fails);
end.
