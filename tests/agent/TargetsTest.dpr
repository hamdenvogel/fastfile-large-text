program TargetsTest;

{$APPTYPE CONSOLE}

{ Which selected files a request is about. Selected: 1 clientes.csv, 2 log.txt, 3 unicode16.txt.
  Want = the 1-based files inferred, "-" when the position is not in the list. }

uses
  Windows, Classes, SysUtils, uAgentTargets;

type
  TCase = record
    Text, Want: string;
  end;

const
  CASES: array[0..63] of TCase = (
    (Text: 'Divida todos os arquivos em 2 partes, menos o último.'; Want: '12'),
    (Text: 'Remova as linhas duplicadas dos dois primeiros arquivos.'; Want: '12'),
    // all
    (Text: 'Dividir esse arquivo em 3 partes'; Want: '123'),
    (Text: 'leia todos os arquivos'; Want: '123'),
    (Text: 'Apague a primeira linha.'; Want: '123'),
    (Text: 'Mostre as 3 primeiras linhas.'; Want: '123'),
    (Text: 'Mostre as 5 últimas linhas'; Want: '123'),
    (Text: 'Insira a linha "# revisado" antes da linha 1.'; Want: '123'),
    (Text: 'Por último, divida em 2 partes.'; Want: '123'),
    (Text: 'a primeira e a segunda linha'; Want: '123'),
    (Text: 'Extraia as partes 1 a 2 de 4.'; Want: '123'),
    (Text: 'Show the last 5 lines'; Want: '123'),
    (Text: 'First read the lines, then count them'; Want: '123'),
    (Text: 'Remova as linhas duplicadas, pelo menos as do início'; Want: '123'),
    (Text: 'Exporte as linhas para um txt'; Want: '123'),
    (Text: 'quinta-feira'; Want: '123'),
    // by name
    (Text: 'Divida o log.txt em 2 partes.'; Want: '2'),
    (Text: 'Conte Bianca no clientes'; Want: '1'),
    (Text: 'Copie a linha 3 do log.txt para o clientes.csv'; Want: '12'),
    // by position, pt
    (Text: 'leia o primeiro arquivo'; Want: '1'),
    (Text: 'leia somente o último'; Want: '3'),
    (Text: 'Leia o último.'; Want: '3'),
    (Text: 'Dividir o último arquivo em 3 partes'; Want: '3'),
    (Text: 'Divida somente o último em 3 partes'; Want: '3'),
    (Text: 'leia o segundo arquivo'; Want: '2'),
    (Text: 'leia o primeiro e o último'; Want: '13'),
    (Text: 'leia o primeiro e último arquivo'; Want: '13'),
    (Text: 'leia os dois primeiros arquivos'; Want: '12'),
    (Text: 'leia os 2 últimos arquivos'; Want: '23'),
    (Text: 'leia o penúltimo arquivo'; Want: '2'),
    (Text: 'leia o arquivo 2'; Want: '2'),
    (Text: 'leia todos os arquivos menos o último'; Want: '12'),
    (Text: 'leia todos exceto o log.txt'; Want: '13'),
    (Text: 'leia o último arquivo selecionado'; Want: '3'),
    (Text: 'leia o quarto arquivo'; Want: '-'),
    (Text: 'leia o terceiro arquivo'; Want: '3'),
    (Text: 'Descaracterize os e-mails das linhas 2 a 9 do CSV.'; Want: '1'),
    (Text: 'Exporte os arquivos txt'; Want: '23'),
    // en
    (Text: 'read the first file'; Want: '1'),
    (Text: 'read only the last one'; Want: '3'),
    (Text: 'Split the second file into 4 parts.'; Want: '2'),
    (Text: 'read the last two files'; Want: '23'),
    (Text: 'read the second to last file'; Want: '2'),
    (Text: 'read all files except the first'; Want: '23'),
    // es / fr / de / it
    (Text: 'lee solo el último archivo'; Want: '3'),
    (Text: 'lee el primer archivo'; Want: '1'),
    (Text: 'lis le dernier fichier'; Want: '3'),
    (Text: 'lis l''avant-dernier fichier'; Want: '2'),
    (Text: 'lies die letzte Datei'; Want: '3'),
    (Text: 'lies alle Dateien außer der ersten'; Want: '23'),
    (Text: 'leggi il primo file'; Want: '1'),
    // pl / ro / hu / cs
    (Text: 'przeczytaj ostatni plik'; Want: '3'),
    (Text: 'przeczytaj tylko pierwszy plik'; Want: '1'),
    (Text: 'citește ultimul fișier'; Want: '3'),
    (Text: 'olvasd el az utolsó fájlt'; Want: '3'),
    (Text: 'olvasd el az első fájlt'; Want: '1'),
    (Text: 'přečti poslední soubor'; Want: '3'),
    (Text: 'přečti první soubor'; Want: '1'),
    // ja / zh
    (Text: '最後のファイルを読んで'; Want: '3'),
    (Text: '最初のファイルを読んで'; Want: '1'),
    (Text: '最初の3行を表示'; Want: '123'),
    (Text: '读取最后一个文件'; Want: '3'),
    (Text: '读取第二个文件'; Want: '2'),
    (Text: '讀取最後一個檔案'; Want: '3'));

var
  Files, Targets: TStringList;
  I, K, Fails: Integer;
  Got, Line: string;
  Mode: TAgentTargetMode;
  W: DWORD;
begin
  Files := TStringList.Create;
  Targets := TStringList.Create;
  try
    Files.Add('C:\w\clientes.csv');
    Files.Add('C:\w\log.txt');
    Files.Add('C:\w\unicode16.txt');
    Fails := 0;
    for I := 0 to High(CASES) do
    begin
      Mode := AgentInferTargets(CASES[I].Text, Files, Targets);
      Got := '';
      if Mode = tgtNone then
        Got := '-'
      else
        for K := 0 to Targets.Count - 1 do
          Got := Got + IntToStr(Files.IndexOf(Targets[K]) + 1);
      if Got = CASES[I].Want then
        Line := 'ok   '
      else
      begin
        Line := 'FAIL ';
        Inc(Fails);
      end;
      Line := Line + Format('want=%-4s got=%-4s %s', [CASES[I].Want, Got, CASES[I].Text]) + #13#10;
      WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), PChar(Line), Length(Line), W, nil);
    end;
    Writeln('fails=', Fails);
  finally
    Targets.Free;
    Files.Free;
  end;
end.
