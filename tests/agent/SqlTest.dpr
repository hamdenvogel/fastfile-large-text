program SqlTest;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, uAgentSql;

var
  Fails, Runs: Integer;
  Log: TStringList;
  Csv: string;

procedure Check(const ASql: string; const AExpect: array of string; const ADelim: string = '';
  AHeader: Integer = -1);
var
  R: TAgentSqlResult;
  I: Integer;
  Txt: string;
  Ok: Boolean;
begin
  Inc(Runs);
  R := AgentToolSql(Csv, ASql, ADelim, AHeader, 200, nil);
  Txt := R.Text;
  for I := 0 to High(R.Changes) do
    Txt := Txt + #13#10 + Format('change %d-%d: %s', [R.Changes[I].LineStart, R.Changes[I].LineEnd,
      StringReplace(R.Changes[I].Text, #10, ' \n ', [rfReplaceAll])]);
  Ok := True;
  for I := 0 to High(AExpect) do
    if Pos(AExpect[I], Txt) = 0 then
    begin
      Ok := False;
      Log.Add('  MISSING: ' + AExpect[I]);
    end;
  if Ok then
    Log.Add('OK   ' + ASql)
  else
  begin
    Inc(Fails);
    Log.Add('FAIL ' + ASql);
  end;
  Log.Add(Txt);
  Log.Add('');
end;

procedure CheckDirect(const AText: string; AStarts, AParses: Boolean);
var
  Err: string;
  S, P: Boolean;
begin
  Inc(Runs);
  S := AgentSqlStartsLikeSql(AText);
  P := S and AgentSqlParses(AText, Err);
  if (S = AStarts) and (P = AParses) then
    Log.Add('OK   direct: ' + AText)
  else
  begin
    Inc(Fails);
    Log.Add(Format('FAIL direct: %s starts=%s parses=%s %s', [AText, BoolToStr(S, True), BoolToStr(P, True), Err]));
  end;
end;

begin
  Log := TStringList.Create;
  try
    Csv := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'work\sql.csv');
    Fails := 0;
    Runs := 0;
    Check('SELECT COUNT(*) FROM sql WHERE nome LIKE ''%Allyne%''', ['COUNT(*)' + #13#10 + '4', 'line_numbers=2,3,4,6']);
    Check('SELECT COUNT(*) AS total FROM sql WHERE WORD_MATCH(nome, ''Allyne'')', ['total' + #13#10 + '3']);
    Check('SELECT nome FROM sql WHERE nome = ''allyne''', ['result_rows=1', 'line_numbers=6']);
    Check('SELECT SUM(valor) AS soma, AVG(valor) media, MIN(valor), MAX(valor) FROM sql',
      ['soma | media | MIN(valor) | MAX(valor)', '1270.06 | 317.515 | 5 | 1234.56', 'were not numbers']);
    Check('SELECT cidade, COUNT(*) AS n FROM sql GROUP BY cidade ORDER BY n DESC, cidade',
      ['cidade | n', 'S'#$00E3'o Paulo | 3', 'result_rows=4']);
    Check('SELECT UPPER(cidade) c, COUNT(*) FROM sql GROUP BY 1 HAVING COUNT(*) > 1', ['result_rows=1', '| 3']);
    Check('SELECT nome, valor FROM sql WHERE NUM(valor) > 15 ORDER BY NUM(valor) DESC',
      ['Bianca Allyne | 1.234,56', 'Kallyne Lima | 20']);
    Check('SELECT YEAR(data) ano, COUNT(*) FROM sql GROUP BY YEAR(data) ORDER BY ano', ['2023 | 2', '2024 | 4']);
    Check('SELECT DISTINCT cidade FROM sql', ['result_rows=4']);
    Check('SELECT * FROM sql WHERE obs IS NULL', ['result_rows=1', 'line_numbers=4']);
    Check('SELECT obs FROM sql WHERE id IN (2, 5)', ['tem ; ponto e v'#$00ED'rgula', 'aspas "duplas"']);
    Check('SELECT nome FROM sql WHERE id BETWEEN 2 AND 3 ORDER BY nome LIMIT 1', ['result_rows=2 shown=1', 'Bianca']);
    Check('SELECT CASE WHEN NUM(valor) >= 20 THEN ''alto'' ELSE ''baixo'' END faixa, COUNT(*) FROM sql ' +
      'WHERE valor IS NOT NULL GROUP BY 1 ORDER BY 1', ['alto | 2', 'baixo | 3']);
    Check('SELECT "nome", c3 FROM sql WHERE "cidade" = "Recife"', ['Marcos | Recife', 'is not a column']);
    Check('SELECT nme FROM sql', ['error=sql: unknown column "nme"', 'columns=6']);
    Check('SELECT COUNT(*) FROM sql WHERE COUNT(*) > 1', ['error=sql: COUNT() is not allowed']);
    Check('SELECT a FROM x JOIN y', ['error=sql: JOIN']);
    Check('DROP TABLE x', ['error=sql: DROP is not supported']);
    Check('UPDATE sql SET cidade = ''Sao Paulo'' WHERE cidade = ''s'#$00E3'o paulo''',
      ['statement=update', 'lines_changed=3 blocks=3',
       'change 2-2: 1;Allyne Souza;Sao Paulo;10,50;2024-01-15;ok',
       'change 6-6: 5;Allyne;Sao Paulo;abc;2023-12-31;"aspas ""duplas"""']);
    Check('UPDATE sql SET obs = ''a;b'' WHERE id = 6', ['change 7-7: 6;Marcos;Recife;;2024-05-20;"a;b"']);
    Check('UPDATE sql SET obs = ''x'' WHERE id = 2', ['change 3-3: 2;Kallyne Lima;Rio de Janeiro;20;15/02/2024;"x"']);
    Check('DELETE FROM sql WHERE nome LIKE ''%allyne%''', ['statement=delete', 'lines_changed=4 blocks=2',
      'change 2-4: ', 'change 6-6: ']);
    Check('INSERT INTO sql (id, nome, valor) VALUES (7, ''Ana; Maria'', 3.5), (8, ''Rui'', NULL)',
      ['statement=insert', 'change 8-7: 7;"Ana; Maria";;3.5;; \n 8;Rui;;;;']);
    Check('SELECT line_no, line FROM sql WHERE line LIKE ''%Recife%''', ['7 | 6;Marcos;Recife;;2024-05-20;ok']);
    Check('SELECT c1, c2 FROM sql LIMIT 2', ['c1 | c2', 'id | nome', 'header=no'], ';', 0);
    Check('ALTER TABLE sql ADD COLUMN pais DEFAULT ''BR''', ['statement=alter', 'lines_changed=7 blocks=1',
      'change 1-7: id;nome;cidade;valor;data;obs;pais \n 1;Allyne Souza;S'#$00E3'o Paulo;10,50;2024-01-15;ok;BR',
      ' \n 3;Bianca Allyne;S'#$00E3'o Paulo;1.234,56;2024-03-01;;BR']);
    Check('ALTER TABLE sql ADD nome_up VARCHAR(50) DEFAULT UPPER(nome) AFTER nome',
      ['change 1-7: id;nome;nome_up;cidade;', '1;Allyne Souza;ALLYNE SOUZA;S'#$00E3'o Paulo;']);
    Check('ALTER TABLE sql ADD COLUMN flag FIRST', ['change 1-7: flag;id;nome;', ' \n ;1;Allyne Souza;']);
    Check('ALTER TABLE sql DROP COLUMN obs', ['change 1-7: id;nome;cidade;valor;data \n ',
      ' \n 2;Kallyne Lima;Rio de Janeiro;20;15/02/2024 \n ']);
    Check('ALTER TABLE sql DROP id', ['change 1-7: nome;cidade;valor;data;obs \n Allyne Souza;']);
    Check('ALTER TABLE sql RENAME COLUMN valor TO preco', ['lines_changed=1 blocks=1',
      'change 1-1: id;nome;cidade;preco;data;obs']);
    Check('ALTER TABLE sql ADD COLUMN Nome', ['error=sql: column "Nome" already exists']);
    Check('ALTER TABLE sql DROP COLUMN xyz', ['error=sql: unknown column "xyz"']);
    Check('ALTER TABLE sql MODIFY valor INT', ['error=sql: column types do not exist']);
    Check('TRUNCATE TABLE sql', ['statement=delete', 'lines_changed=6 blocks=1', 'change 2-7: ']);
    Check('CREATE TABLE x (a INT)', ['error=sql: CREATE is not supported']);
    CheckDirect('SELECT * FROM clientes', True, True);
    CheckDirect('  update clientes set cidade = ''SP'' where id = 1;', True, True);
    CheckDirect('alter table clientes add column pais', True, True);
    CheckDirect('Delete as linhas 5 a 7 do clientes.csv', True, False);
    CheckDirect('delete linhas duplicadas', True, False);
    CheckDirect('Update the city of Bianca to Recife', True, False);
    CheckDirect('Select the lines with Bianca', True, False);
    CheckDirect('quantos registros por cidade?', False, False);
    CheckDirect('Selecione os clientes de S'#$00E3'o Paulo', False, False);
    Log.Add(Format('runs=%d fails=%d', [Runs, Fails]));
    Log.SaveToFile(ExtractFilePath(ParamStr(0)) + 'sqltest_out.txt', TEncoding.UTF8);
    Writeln(Format('runs=%d fails=%d', [Runs, Fails]));
  finally
    Log.Free;
  end;
end.
