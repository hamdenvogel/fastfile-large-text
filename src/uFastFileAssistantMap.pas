unit uFastFileAssistantMap;

{
  Ingest / mapeamento de recursos do FastFile para o Assistente IA.
  Uma unica tabela: frases do utilizador -> action_id executavel.
  Fonte de verdade para: resolver local (score), whitelist e prompt da LLM.
}

interface

uses
  uFastFileAssistantHost;

function MapIsAllowedActionId(const AId: string): Boolean;
function BuildCapabilityMapKB: string;
function BuildCapabilityMapRAG(const UserQuestion: string): string;
function FoldDiacriticsForMatch(const S: string): string;
function TryScoreCapabilityMap(const AQuestion: string; out AActionId: string;
  out ABestScore, ASecondScore: Integer): Boolean;
function TryScoreCapabilityMapInFamily(const AQuestion, AFamilyIds: string;
  out AActionId: string; out ABestScore, ASecondScore: Integer): Boolean;
procedure MapApplyExtractedParams(const AQuestion: string; var AStep: TAssistantChainStep);

implementation

uses
  SysUtils, uPosBMH;

const
  MAP_MIN_SCORE = 6;
  MAP_MARGIN = 2;
  RAG_MAX_CHARS = 2200;
  { Folded ASCII politeness / filler stripped before capability scoring (11 langs). }
  SCORING_POLITENESS_TOKENS =
    'e possivel|por favor|tem como|da para|consegue |poderia |voce pode|eu quero |quero |' +
    'please|could you|can you|i want to|i would like to|i need to |would you |' +
    'quiero |necesito |puedes |puedo |' +
    's''il vous plait|je veux |pouvez vous |voudriez vous |je peux |est ce possible |' +
    'bitte |koennen sie |kannst du |kann ich |ich moechte |' +
    'vorrei |voglio |' +
    'prosim |prosze |prosim vas |czy mozesz |chce |chci |mohl byste |chcel by som |je mozne |' +
    'te rog |as vrea |as dori |poti |poti sa |pot sa |' +
    'kerlek |kerem |szeretnem |szeretnek |tudna |legyszives |' +
    'muzete ';

type
  TAssistantCapability = record
    ActionId: string;
    Category: string;
    Shortcut: string;
    Phrases: string;
    AntiPhrases: string;
    ParamsHint: string;
  end;

var
  GCaps: array of TAssistantCapability;
  GReady: Boolean;

function IsTokenWordChar(C: Char): Boolean;
begin
  Result := (C in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function ContainsTokenAsWord(const L, Tok: string): Boolean;
var
  p, LenT, StartAt: Integer;
begin
  Result := False;
  if (Tok = '') or (L = '') then Exit;
  LenT := Length(Tok);
  p := PosBMH(Tok, L);
  while p > 0 do
  begin
    if ((p = 1) or not IsTokenWordChar(L[p - 1])) and
       ((p + LenT - 1 = Length(L)) or not IsTokenWordChar(L[p + LenT])) then
    begin
      Result := True;
      Exit;
    end;
    StartAt := p + LenT;
    if StartAt > Length(L) then Break;
    p := PosBMH(Tok, Copy(L, StartAt, MaxInt));
    if p > 0 then Inc(p, StartAt - 1);
  end;
end;

function PhraseHits(const L, Tok: string): Boolean;
begin
  Result := False;
  if Tok = '' then Exit;
  if Length(Tok) <= 3 then
    Result := ContainsTokenAsWord(L, Tok)
  else
    Result := PosBMH(Tok, L) > 0;
end;

function ScorePhrases(const L, Phrases: string): Integer;
var
  i, p, Hit, Best, Extra: Integer;
  Tok: string;
begin
  { Longer / multi-word phrases weigh more than short tokens. }
  Result := 0;
  Best := 0;
  Extra := 0;
  if (L = '') or (Phrases = '') then Exit;
  i := 1;
  while i <= Length(Phrases) do
  begin
    p := i;
    while (p <= Length(Phrases)) and (Phrases[p] <> '|') do Inc(p);
    Tok := Trim(Copy(Phrases, i, p - i));
    if (Tok <> '') and PhraseHits(L, Tok) then
    begin
      if Length(Tok) <= 3 then
        Hit := 4
      else if Length(Tok) <= 8 then
        Hit := Length(Tok) + 4
      else if Pos(' ', Tok) > 0 then
        Hit := Length(Tok) * 2 + 10
      else
        Hit := Length(Tok) + 6;
      if Hit > Best then
      begin
        if Best > 0 then
          Inc(Extra, Best div 4);
        Best := Hit;
      end
      else
        Inc(Extra, Hit div 4);
    end;
    if p > Length(Phrases) then Break;
    i := p + 1;
  end;
  Result := Best + Extra;
end;

function FoldDiacriticsForMatch(const S: string): string;

  procedure Rep(const FromCh, ToStr: string);
  begin
    if FromCh <> '' then
      Result := StringReplace(Result, FromCh, ToStr, [rfReplaceAll]);
  end;

begin
  { Fold accents so phrase tokens stay ASCII (e.g. zusammenführen→zusammenfuehren,
    egyesítés→egyesites). Covers all 11 FastFile UI languages. }
  Result := LowerCase(Trim(S));

  { German digraphs before single-letter strip. }
  Rep(#228, 'ae');   { ä }
  Rep(#246, 'oe');   { ö }
  Rep(#252, 'ue');   { ü }
  Rep(#223, 'ss');   { ß }

  { Hungarian double acute → same digraphs as ö/ü. }
  Rep(#$0151, 'oe'); { ő }
  Rep(#$0171, 'ue'); { ű }

  { Polish. }
  Rep(#$0105, 'a');  { ą }
  Rep(#$0107, 'c');  { ć }
  Rep(#$0119, 'e');  { ę }
  Rep(#$0142, 'l');  { ł }
  Rep(#$0144, 'n');  { ń }
  Rep(#$015B, 's');  { ś }
  Rep(#$017A, 'z');  { ź }
  Rep(#$017C, 'z');  { ż }

  { Czech. }
  Rep(#$010D, 'c');  { č }
  Rep(#$010F, 'd');  { ď }
  Rep(#$011B, 'e');  { ě }
  Rep(#$0148, 'n');  { ň }
  Rep(#$0159, 'r');  { ř }
  Rep(#$0161, 's');  { š }
  Rep(#$0165, 't');  { ť }
  Rep(#$016F, 'u');  { ů }
  Rep(#$017E, 'z');  { ž }

  { Romanian (comma-below and cedilla). }
  Rep(#$0103, 'a');  { ă }
  Rep(#$0219, 's');  { ș }
  Rep(#$015F, 's');  { ş }
  Rep(#$021B, 't');  { ț }
  Rep(#$0163, 't');  { ţ }

  { Shared Latin-1 / Romance / HU / CZ vowels → base letter. }
  Rep(#225, 'a');    { á }
  Rep(#224, 'a');    { à }
  Rep(#226, 'a');    { â }
  Rep(#227, 'a');    { ã }
  Rep(#229, 'a');    { å }
  Rep(#233, 'e');    { é }
  Rep(#232, 'e');    { è }
  Rep(#234, 'e');    { ê }
  Rep(#235, 'e');    { ë }
  Rep(#237, 'i');    { í }
  Rep(#236, 'i');    { ì }
  Rep(#238, 'i');    { î }
  Rep(#239, 'i');    { ï }
  Rep(#243, 'o');    { ó }
  Rep(#242, 'o');    { ò }
  Rep(#244, 'o');    { ô }
  Rep(#245, 'o');    { õ }
  Rep(#250, 'u');    { ú }
  Rep(#249, 'u');    { ù }
  Rep(#251, 'u');    { û }
  Rep(#253, 'y');    { ý }
  Rep(#255, 'y');    { ÿ }
  Rep(#231, 'c');    { ç }
  Rep(#241, 'n');    { ñ }
end;

function NormalizeQuestionForScoring(const AQuestion: string): string;
var
  L: string;
  i, p: Integer;
  Tok: string;
begin
  L := FoldDiacriticsForMatch(AQuestion);
  i := 1;
  while i <= Length(SCORING_POLITENESS_TOKENS) do
  begin
    p := i;
    while (p <= Length(SCORING_POLITENESS_TOKENS)) and (SCORING_POLITENESS_TOKENS[p] <> '|') do
      Inc(p);
    Tok := Trim(Copy(SCORING_POLITENESS_TOKENS, i, p - i));
    if Tok <> '' then
      L := StringReplace(L, Tok, ' ', [rfReplaceAll]);
    if p > Length(SCORING_POLITENESS_TOKENS) then Break;
    i := p + 1;
  end;
  while Pos('  ', L) > 0 do
    L := StringReplace(L, '  ', ' ', [rfReplaceAll]);
  Result := Trim(L);
end;

function QuestionLooksLikePath(const L: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(L) - 2 do
    if (L[i] in ['a'..'z']) and (L[i + 1] = ':') and (L[i + 2] in ['\', '/']) then
    begin
      Result := True;
      Exit;
    end;
end;

function QuestionLooksLikeLineRange(const L: string): Boolean;
begin
  { Folded ASCII tokens — covers PT/EN/ES/FR/DE/IT/PL/RO/HU/CZ line-range export. }
  Result :=
    (PosBMH('linhas entre', L) > 0) or (PosBMH('linha ', L) > 0) or
    (PosBMH('somente com as linhas', L) > 0) or (PosBMH('primeiras linhas', L) > 0) or
    (PosBMH('line range', L) > 0) or (PosBMH('lines between', L) > 0) or
    (PosBMH('only the lines', L) > 0) or (PosBMH('only these lines', L) > 0) or
    (PosBMH('first lines', L) > 0) or (PosBMH('lines from', L) > 0) or
    (PosBMH('lineas entre', L) > 0) or (PosBMH('solo las lineas', L) > 0) or
    (PosBMH('primeras lineas', L) > 0) or (PosBMH('solo con las lineas', L) > 0) or
    (PosBMH('lignes entre', L) > 0) or (PosBMH('seulement les lignes', L) > 0) or
    (PosBMH('premieres lignes', L) > 0) or (PosBMH('plage de lignes', L) > 0) or
    (PosBMH('intervalle de lignes', L) > 0) or
    (PosBMH('zeilen zwischen', L) > 0) or (PosBMH('nur die zeilen', L) > 0) or
    (PosBMH('erste zeilen', L) > 0) or (PosBMH('zeilenbereich', L) > 0) or
    (PosBMH('nur diese zeilen', L) > 0) or
    (PosBMH('righe tra', L) > 0) or (PosBMH('solo le righe', L) > 0) or
    (PosBMH('prime righe', L) > 0) or
    (PosBMH('linie miedzy', L) > 0) or (PosBMH('tylko linie', L) > 0) or
    (PosBMH('pierwsze linie', L) > 0) or
    (PosBMH('linii intre', L) > 0) or (PosBMH('doar liniile', L) > 0) or
    (PosBMH('primele linii', L) > 0) or
    (PosBMH('sorok kozott', L) > 0) or (PosBMH('csak a sorok', L) > 0) or
    (PosBMH('elso sorok', L) > 0) or
    (PosBMH('radky mezi', L) > 0) or (PosBMH('pouze radky', L) > 0) or
    (PosBMH('prvni radky', L) > 0);
end;

function QuestionLooksLikeDocumentFormat(const L: string): Boolean;
begin
  { Word/PDF/ODT compose — folded tokens for 11 UI langs. }
  Result :=
    (PosBMH('formato word', L) > 0) or (PosBMH('formatos word', L) > 0) or
    (PosBMH('format word', L) > 0) or (PosBMH('word format', L) > 0) or
    (PosBMH('nos formatos', L) > 0) or (PosBMH('em word', L) > 0) or
    (PosBMH('en word', L) > 0) or (PosBMH('in word', L) > 0) or
    (PosBMH('word e odt', L) > 0) or (PosBMH('word e pdf', L) > 0) or
    (PosBMH('word et pdf', L) > 0) or (PosBMH('word en pdf', L) > 0) or
    (PosBMH('word und odt', L) > 0) or (PosBMH('word und pdf', L) > 0) or
    (PosBMH('documento word', L) > 0) or
    (PosBMH('document word', L) > 0) or (PosBMH('dokument word', L) > 0) or
    (PosBMH('dokumentum word', L) > 0) or (PosBMH('formato pdf', L) > 0) or
    (PosBMH('format pdf', L) > 0) or (PosBMH('em pdf', L) > 0) or
    (PosBMH('en pdf', L) > 0) or (PosBMH('formato odt', L) > 0) or
    (PosBMH('formatos odt', L) > 0) or (PosBMH('em odt', L) > 0) or
    (PosBMH('.docx', L) > 0) or (PosBMH('.rtf', L) > 0) or
    (PosBMH('.pdf', L) > 0) or (PosBMH('.odt', L) > 0);
end;

function ScoreCapability(const L: string; const Cap: TAssistantCapability): Integer;
var
  Anti: Integer;
begin
  Result := ScorePhrases(L, Cap.Phrases);
  if Cap.AntiPhrases <> '' then
  begin
    Anti := ScorePhrases(L, Cap.AntiPhrases);
    if Anti >= 10 then
    begin
      Result := 0;
      Exit;
    end;
    if Anti > 0 then
    begin
      Dec(Result, Anti * 2);
      if Result < 0 then Result := 0;
    end;
  end;
  if Cap.Shortcut <> '' then
  begin
    if PhraseHits(L, LowerCase(Cap.Shortcut)) then
      Inc(Result, 12);
  end;
  if QuestionLooksLikePath(L) and (PosBMH('path', LowerCase(Cap.ParamsHint)) > 0) then
    Inc(Result, 3);
  if QuestionLooksLikeLineRange(L) and SameText(Cap.ActionId, 'export_lines') then
    Inc(Result, 10);
  if QuestionLooksLikeDocumentFormat(L) then
  begin
    if SameText(Cap.ActionId, 'compose_document') then
      Inc(Result, 14)
    else if SameText(Cap.ActionId, 'consumer_rag') then
    begin
      Result := 0;
      Exit;
    end;
  end;
  if (PosBMH('gere um programa', L) > 0) or (PosBMH('gerar um programa', L) > 0) or
     (PosBMH('gere uma classe', L) > 0) or (PosBMH('gerar uma classe', L) > 0) or
     (PosBMH('programa em python', L) > 0) or (PosBMH('gere um .py', L) > 0) or
     (PosBMH('gere um .js', L) > 0) or (PosBMH('gere um .java', L) > 0) or
     (PosBMH('classe em java', L) > 0) or (PosBMH('componente react', L) > 0) then
  begin
    if SameText(Cap.ActionId, 'compose_document') then
      Inc(Result, 14)
    else if SameText(Cap.ActionId, 'show_script_engine') then
    begin
      Result := 0;
      Exit;
    end;
  end;
end;

procedure AddCap(const AId, ACat, AShortcut, APhrases, AParams: string);
var
  n: Integer;
begin
  n := Length(GCaps);
  SetLength(GCaps, n + 1);
  GCaps[n].ActionId := AId;
  GCaps[n].Category := ACat;
  GCaps[n].Shortcut := AShortcut;
  GCaps[n].Phrases := LowerCase(APhrases);
  GCaps[n].AntiPhrases := '';
  GCaps[n].ParamsHint := AParams;
end;

procedure CapAnti(const AAntiPhrases: string);
var
  n: Integer;
begin
  n := Length(GCaps);
  if n = 0 then Exit;
  GCaps[n - 1].AntiPhrases := LowerCase(AAntiPhrases);
end;

procedure EnsureMap;
begin
  if GReady then Exit;
  SetLength(GCaps, 0);

  { FILE }
  AddCap('open_and_read_file', 'FILE', 'F5',
    'ler o arquivo|leia o arquivo|carregar o arquivo|abrir o arquivo|quero ler|' +
    'read file|load file|open file|ler arquivo|leia arquivo|carregar arquivo|abrir arquivo|' +
    'carregar este arquivo|abrir este arquivo|ler este arquivo|' +
    'leer archivo|abrir archivo|cargar archivo|abrir el archivo|' +
    'lire le fichier|ouvrir le fichier|charger le fichier|' +
    'datei lesen|datei laden|datei oeffnen|diese datei oeffnen|' +
    'leggi file|apri file|carica file|aprire il file|' +
    'otworz plik|wczytaj plik|czytaj plik|otworz ten plik|' +
    'deschide fisier|citeste fisier|incarca fisier|' +
    'fajl megnyitasa|fajl betoltese|fajl olvasasa|' +
    'otevrit soubor|nacist soubor|precist soubor',
    'path');
  CapAnti('filtrar|dividir|exportar|python|resumo|formato word|gerar um|gere um|substituir|' +
    'pra que serve|quantas linhas|mesclar|comparar');

  AddCap('open_recent_file', 'FILE', 'Ctrl+R',
    'arquivo recente|ficheiros recentes|recent files|da lista de recentes|na lista de recentes|' +
    'abrir recente|abrir da lista|segundo da lista|primeiro da lista',
    'recent_index');
  AddCap('open_file_dialog', 'FILE', 'Ctrl+O',
    'ctrl+o|abrir dialogo|open file dialog|selecionar arquivo|escolher arquivo|file picker|' +
    'caixa de abrir',
    '');
  AddCap('reload_file', 'FILE', 'F5',
    'recarregar|reload|ler de novo|carregar de novo|f5|reler arquivo|releia o arquivo|atualizar leitura',
    '');
  AddCap('show_tab_read', 'FILE', 'Ctrl+1',
    'aba ler|read tab|tela de carregar|tela carregar arquivos|show read|ctrl+1|painel read|' +
    'tela de leitura|abrir tela de carregar',
    '');
  AddCap('show_tab_recent', 'FILE', 'Ctrl+R',
    'ctrl+r|aba recentes|recent files tab|ficheiros recentes|arquivos recentes|lista recente|' +
    'mostrar recentes|ver recentes|ficheiros recentes',
    '');
  AddCap('clear_file', 'FILE', 'Ctrl+Shift+X',
    'ctrl+shift+x|limpar arquivo|limpar ficheiro|clear file|esvaziar arquivo|esvaziar o arquivo|' +
    'borrar archivo|vaciar archivo|effacer le fichier|datei leeren|svuotare file|' +
    'wyczysc plik|sterge fisierul|fajl torlese|vymazat soubor',
    '');

  { FIND }
  AddCap('find_text', 'FIND', 'Ctrl+F',
    'procurar palavra|buscar palavra|find text|search text|localizar texto|' +
    'procurar o texto|buscar o texto|encontrar palavra|achar palavra',
    'search_text, case_sensitive');
  AddCap('open_find', 'FIND', 'Ctrl+F',
    'ctrl+f|abrir busca|find dialog|dialogo de procura|caixa de pesquisa|abrir procurar',
    '');
  AddCap('find_next', 'FIND', 'F3',
    'f3|proxima ocorrencia|proxima ocorr|next match|next find|seguinte ocorrencia|proximo resultado',
    '');
  AddCap('find_previous', 'FIND', 'Shift+F3',
    'shift+f3|ocorrencia anterior|previous match|prev find|ocorrencia previa|resultado anterior',
    '');
  AddCap('view_find_occurrences', 'FIND', '',
    'ver ocorrencias|recolher todas|view occurrences|find all|mostrar ocorrencias|' +
    'listar ocorrencias|ocorrencias na vista|ver resultados da busca',
    '');
  AddCap('clear_find', 'FIND', '',
    'limpar busca|clear find|limpar find|limpar ocorrencias|clear occurrences|' +
    'zerar busca|cancelar ocorrencias',
    '');
  AddCap('find_in_files', 'FIND', 'Ctrl+Shift+F',
    'ctrl+shift+f|find in files|procurar em ficheiros|procurar em arquivos|buscar em pastas|' +
    'procurar em pastas|buscar nos arquivos|buscar en archivos|rechercher dans fichiers|' +
    'in dateien suchen|cerca nei file|szukaj w plikach|cauta in fisiere|hledat v souborech',
    '');
  AddCap('cancel_search', 'FIND', 'Esc',
    'cancelar busca|cancel search|parar procura|esc find|interromper busca|parar a busca',
    '');
  AddCap('find_case_auto', 'FIND', '',
    'busca automatica|search automatic match case|case auto|detectar maiusculas na busca',
    '');
  AddCap('find_case_sensitive', 'FIND', '',
    'busca diferenciar maiusculas|search match case|find case sensitive|busca case sensitive',
    '');
  AddCap('find_case_ignore', 'FIND', '',
    'busca ignorar maiusculas|search ignore case|find ignore case|busca sem diferenciar',
    '');

  { NAV }
  AddCap('goto_line', 'NAV', 'Ctrl+G',
    'ir para linha|vai para linha|goto line|go to line|ctrl+g|saltar para linha|ir a linha|' +
    'ir a la linea|aller a la ligne|gehe zu zeile|vai alla riga|przejdz do linii',
    'line_no');
  AddCap('goto_byte_offset', 'NAV', 'Ctrl+Shift+G',
    'ctrl+shift+g|byte offset|offset byte|ir para byte|goto byte|deslocamento byte|ir ao byte|' +
    'ir al byte|aller au byte|zum byte|vai al byte',
    'byte_offset');
  AddCap('goto_file_start', 'NAV', 'Shift+Home',
    'shift+home|inicio do arquivo|inicio do ficheiro|topo do arquivo|go to top|ir ao inicio|primeira linha|' +
    'inicio del archivo|debut du fichier|dateianfang|inizio file',
    '');
  AddCap('goto_file_end', 'NAV', 'Shift+End',
    'shift+end|fim do arquivo|fim do ficheiro|final do arquivo|end of file|ir ao fim|ultima linha do arquivo|' +
    'fin del archivo|fin du fichier|dateiende|fine file',
    '');

  { EDIT }
  AddCap('edit_line', 'EDIT', 'Ctrl+Shift+E',
    'editar linha|edit line|ctrl+shift+e|alterar linha|modificar linha|edite a linha|' +
    'editar linea|modifier la ligne|zeile bearbeiten|modifica riga|edytuj linie|' +
    'editeaza linia|sor szerkesztese|upravit radek',
    'line_no');
  AddCap('insert_line', 'EDIT', 'Ctrl+Shift+I',
    'ctrl+shift+i|inserir linha|insert line|nova linha|adicionar linha|inserir uma linha|' +
    'insertar linea|inserer une ligne|zeile einfuegen|inserisci riga|wstaw linie|' +
    'insereaza linie|sor beszuras|vlozit radek',
    'line_no');
  AddCap('duplicate_line', 'EDIT', 'Ctrl+Shift+U',
    'ctrl+shift+u|duplicar linha|duplicate line|duplicar a linha|' +
    'duplicar linea|dupliquer la ligne|zeile duplizieren|duplica riga|duplikuj linie|' +
    'duplica linia|sor duplikalas|duplikovat radek',
    'line_no');
  AddCap('delete_line', 'EDIT', 'Ctrl+Shift+D',
    'ctrl+shift+d|apagar linha|delete line|excluir linha|remover linha|deletar linha|ultima linha|' +
    'eliminar linea|supprimer la ligne|zeile loeschen|elimina riga|usun linie|' +
    'sterge linia|sor torlese|smazat radek|last line|ultima linea|derniere ligne',
    'line_no (0=last)');
  AddCap('insert_multiple_lines', 'EDIT', 'Ctrl+Shift+N',
    'ctrl+shift+n|multiplas linhas|multiple lines|inserir varias linhas|varias linhas|colar varias linhas',
    '');
  AddCap('undo', 'EDIT', 'Ctrl+Z',
    'ctrl+z|desfazer|undo|desfazer alteracao',
    '');
  AddCap('redo', 'EDIT', 'Ctrl+Y',
    'ctrl+y|refazer|redo|refazer alteracao',
    '');
  AddCap('copy_selection', 'EDIT', 'Ctrl+C',
    'ctrl+c|copiar selecao|copy selection|copiar texto|copiar linhas selecionadas',
    '');
  AddCap('paste_lines', 'EDIT', 'Ctrl+V',
    'ctrl+v|colar linhas|paste lines|colar no ficheiro|colar no arquivo|colar texto',
    '');

  { FILTER }
  AddCap('open_filter', 'FILTER', 'Ctrl+L',
    'abrir filtro|filter dialog|dialogo de filtro|ctrl+l|caixa de filtro|abrir o grep|' +
    'mostrar filtro|mostrar barra de filtro|abrir barra de filtro|show filter bar|' +
    'abrir o filtro|abrir grep|filter bar|barra do filtro',
    '');
  AddCap('apply_filter', 'FILTER', 'Ctrl+L',
    'aplicar filtro|filtrar linhas|filter lines|grep linhas|quero filtrar|filtrar o arquivo|' +
    'filtrar arquivo|mostrar so linhas|so as linhas com|grep no arquivo|filtrar por|' +
    'filtrar lineas|filtrer les lignes|zeilen filtern|filtra righe|filtruj linie|' +
    'filtreaza linii|filtrovat radky',
    'filter_text');
  AddCap('clear_filter', 'FILTER', 'Esc',
    'limpar filtro|clear filter|remover filtro|tirar filtro|desativar filtro|' +
    'fechar filtro|desligar filtro|apagar filtro',
    '');
  AddCap('continue_filter', 'FILTER', '',
    'continuar filtro|continue filter|mais hits|more hits|carregar mais filtro|' +
    'load more filter|continuar stream|mais resultados do filtro|more filter results|' +
    'seguir filtrando|continue grep|mais resultados filtrados',
    '');
  AddCap('copy_filtered', 'FILTER', '',
    'copiar filtro|copiar resultados do filtro|copy filtered|copy filter results|' +
    'copiar hits|clipboard filter|copiar linhas filtradas|copy filtered lines|' +
    'copiar resultado do filtro|filter to clipboard',
    '');
  AddCap('filter_match_auto', 'FILTER', '',
    'filtro automatico|filter auto detect|auto detect mode filtro',
    '');
  AddCap('filter_match_contains', 'FILTER', '',
    'filtro contem|filter contains|linhas contem texto|filtro por conteudo',
    '');
  AddCap('filter_match_prefix', 'FILTER', '',
    'filtro comeca com|filter starts with|linha comeca com|prefixo do filtro',
    '');
  AddCap('count_line_prefixes', 'FILTER', '',
    'contar linhas prefixo|count lines starting with|linhas que iniciam|linhas que comecam|' +
    'how many lines start with|contagem por prefixo|somatório prefixo|somatorio prefixo',
    'filter_text');
  { AI-first tool id — phrases are capability labels for the LLM map, not NL host routing. }
  AddCap('count_matching_lines', 'FILTER', '',
    'count_matching_lines|count lines containing|substring line count|' +
    'count matching lines|lines containing needle',
    'filter_text');
  AddCap('filter_match_regex', 'FILTER', '',
    'filtro regex|filter regular expression|filtro expressao regular|grep regex',
    '');
  AddCap('filter_case_auto', 'FILTER', '',
    'filtro case auto|filter automatic match case',
    '');
  AddCap('filter_case_sensitive', 'FILTER', '',
    'filtro case sensitive|filter match case|filtro diferenciar maiusculas',
    '');
  AddCap('filter_case_ignore', 'FILTER', '',
    'filtro ignorar maiusculas|filter ignore case|filtro sem diferenciar',
    '');

  { TAIL }
  AddCap('start_tail', 'TAIL', 'Ctrl+T',
    'ctrl+t|iniciar tail|start tail|follow file|seguir arquivo|monitorar arquivo|tail follow|' +
    'modo follow|acompanhar o arquivo|seguir o ficheiro|quero o tail|watch file|monitor file|' +
    'iniciar seguimiento|seguir el archivo|monitorizar archivo|modo seguimiento|' +
    'demarrer tail|suivre le fichier|surveiller le fichier|mode suivi|suivre le ficher|' +
    'tail starten|datei verfolgen|datei ueberwachen|follow modus|datei beobachten|' +
    'avvia tail|segui file|monitora file|modalita follow|seguire il file|' +
    'uruchom tail|sledz plik|monitoruj plik|tryb sledzenia|' +
    'porneste tail|urmareste fisierul|monitorizeaza fisierul|mod urmarire|' +
    'tail inditasa|fajl kovetese|fajl figyelese|kovetes mod|' +
    'spustit tail|sledovat soubor|monitorovat soubor|rezim sledovani',
    '');
  AddCap('pause_tail', 'TAIL', 'Ctrl+Shift+T',
    'ctrl+shift+t|pausar tail|pause tail|retomar tail|resume tail|pausar follow|stop tail|' +
    'pausar seguimiento|reanudar tail|reanudar seguimiento|' +
    'mettre en pause tail|reprendre tail|pause suivi|' +
    'tail pausieren|tail fortsetzen|follow pausieren|' +
    'metti in pausa tail|riprendi tail|pausa follow|' +
    'wstrzymaj tail|wznow tail|zatrzymaj tail|' +
    'pauza tail|relua tail|opreste tail|' +
    'tail szuneteltetese|tail folytatasa|kovetes szuneteltetese|' +
    'pozastavit tail|obnovit tail|zastavit tail',
    '');
  AddCap('show_tail_macro', 'TAIL', '',
    'macro tail|tail macro|macro python tail|python tail|automacao tail|' +
    'python no tail|python no follow|macro no tail|script no tail|tail automation|' +
    'macro python en tail|automatizacion tail|python en tail|' +
    'macro python dans tail|automatisation tail|python dans tail|' +
    'tail makro|python tail makro|python im tail|automatisierung tail|' +
    'macro python nel tail|automazione tail|python nel tail|' +
    'makro tail|makro python tail|python w tail|automatyzacja tail|' +
    'macro python in tail|automatizare tail|python in tail|' +
    'tail makro python|python a tailben|tail automatizalas|' +
    'makro tail python|python v tail|automatizace tail',
    '');
  AddCap('tail_macro_reprocess', 'TAIL', 'Ctrl+Shift+R',
    'reprocessar tail|tail macro reprocess|reprocess new lines|reprocessar linhas novas|' +
    'ctrl+shift+r|reaplicar macro tail|reprocess tail|reapply tail macro|' +
    'reprocesar tail|reprocesar lineas nuevas|reaplicar macro tail|' +
    'retraiter tail|retraiter nouvelles lignes|reappliquer macro tail|' +
    'tail neu verarbeiten|neue zeilen verarbeiten|makro erneut anwenden|' +
    'riprocessa tail|riprocessa nuove righe|riapplica macro tail|' +
    'przetworz tail ponownie|przetworz nowe linie|ponownie zastosuj makro|' +
    'reproceseaza tail|reproceseaza linii noi|reaplica macro tail|' +
    'tail ujrafeldolgozas|uj sorok feldolgozasa|makro ujraalkalmazasa|' +
    'zpracovat tail znovu|zpracovat nove radky|znovu pouzit makro',
    '');

  { BOOKMARK }
  AddCap('toggle_bookmark', 'BOOKMARK', 'Ctrl+B',
    'ctrl+b|bookmark|marcador|marca linha|toggle bookmark|adicionar marcador|marcar linha|' +
    'mark line|add bookmark|set bookmark|' +
    'marcador de linea|marcar linea|anadir marcador|' +
    'signet|marquer la ligne|ajouter signet|marquer ligne|' +
    'lesezeichen|zeile markieren|lesezeichen setzen|' +
    'segnalibro|segna riga|aggiungi segnalibro|' +
    'zakladka|oznacz linie|dodaj zakladke|' +
    'semn de carte|marcheaza linia|adauga semn|' +
    'konyvjelzo|sor megjelolese|konyvjelzo hozzaadasa|' +
    'zalozka|oznacit radek|pridat zalozku',
    '');
  AddCap('next_bookmark', 'BOOKMARK', 'F2',
    'f2|proximo marcador|proxima marca|next bookmark|following bookmark|' +
    'siguiente marcador|marcador siguiente|' +
    'signet suivant|prochain signet|' +
    'naechstes lesezeichen|naechstes bookmark|' +
    'segnalibro successivo|prossimo segnalibro|' +
    'nastepna zakladka|kolejna zakladka|' +
    'urmatorul semn|semn urmator|' +
    'kovetkezo konyvjelzo|kovetkezo jel|' +
    'dalsi zalozka|nasledujici zalozka',
    '');
  AddCap('prev_bookmark', 'BOOKMARK', 'Shift+F2',
    'shift+f2|marcador anterior|previous bookmark|marca anterior|prior bookmark|' +
    'marcador previo|anterior marcador|' +
    'signet precedent|signet anterieur|' +
    'vorheriges lesezeichen|vorheriges bookmark|' +
    'segnalibro precedente|segnalibro anteriore|' +
    'poprzednia zakladka|wczesniejsza zakladka|' +
    'semn anterior|semn precedent|' +
    'elozo konyvjelzo|elozo jel|' +
    'predchozi zalozka|predchozi bookmark',
    '');
  AddCap('clear_bookmarks', 'BOOKMARK', 'Ctrl+Shift+B',
    'ctrl+shift+b|limpar marcadores|clear bookmarks|limpar marcas|limpar bookmark|' +
    'remove bookmarks|delete bookmarks|' +
    'limpiar marcadores|borrar marcadores|eliminar marcadores|' +
    'effacer signets|supprimer signets|effacer marque pages|' +
    'lesezeichen loeschen|alle lesezeichen entfernen|' +
    'cancella segnalibri|rimuovi segnalibri|elimina segnalibri|' +
    'wyczysc zakladki|usun zakladki|' +
    'sterge semnele|curata semnele|elimina semnele|' +
    'konyvjelzok torlese|osszes konyvjelzo torlese|' +
    'vymazat zalozky|odstranit zalozky|smazat vsechny zalozky',
    '');

  { VIEW }
  AddCap('toggle_word_wrap', 'VIEW', 'Ctrl+W',
    'ctrl+w|word wrap|quebra de linha|quebra linha|envolver texto|ativar quebra|line wrap|' +
    'wrap text|ajuste de linea|envolver texto|retour a la ligne|renvoi a la ligne|' +
    'zeilenumbruch|textumbruch|a capo automatico|zawijanie wierszy|impartire text|' +
    'sortores|szoveg torese|zalamovani radku',
    '');
  AddCap('show_checkboxes', 'VIEW', 'Ctrl+Shift+S',
    'ctrl+shift+s|select mode|modo select|checkbox|checklist|caixas de selecao|modo selecao|' +
    'modo seleccion|mode selection|auswahlmodus|modalita selezione|tryb zaznaczania|' +
    'mod selectie|kijelolesi mod|rezim vyberu',
    '');
  AddCap('zoom_in', 'VIEW', 'Ctrl+Num+',
    'zoom in|aumentar fonte|ctrl+num+|aproximar lista|aumentar zoom|aumentar a lista|' +
    'aumentar fuente|agrandir police|schrift vergrossern|aumenta font|powieksz czcionke|' +
    'marire font|betumeret novelese|zvetsit pismo',
    '');
  AddCap('zoom_out', 'VIEW', 'Ctrl+Num-',
    'zoom out|diminuir fonte|ctrl+num-|afastar lista|diminuir zoom|diminuir a lista|' +
    'reducir fuente|reduire police|schrift verkleinern|riduci font|pomniejsz czcionke|' +
    'micsorare font|betumeret csokkentese|zmensit pismo',
    '');
  AddCap('toggle_whitespace_marks', 'VIEW', 'Ctrl+Alt+M',
    'ctrl+alt+m|whitespace|marcas visiveis|espacos visiveis|mostrar espacos|show marks|' +
    'mostrar tab e crlf|marcas de espaco|visible spaces|show whitespace|tab marks|' +
    'marcas visibles|espacios visibles|mostrar espacios|' +
    'marques visibles|espaces visibles|afficher espaces|' +
    'leerzeichen anzeigen|sichtbare leerzeichen|tab anzeigen|' +
    'spazi visibili|mostra spazi|segni spazio|' +
    'widoczne spacje|pokaz spacje|znaki spacji|' +
    'spatii vizibile|afiseaza spatii|' +
    'lathato szokozok|szokozok megjelenitese|' +
    'viditelne mezery|zobrazit mezery|znacky mezer',
    '');
  AddCap('character_code_value', 'VIEW', '',
    'character code|codigo caractere|codigo do caractere|codigo ascii|ord caractere|valor do caractere|' +
    'char value|ascii value|ascii code|' +
    'codigo caracter|valor caracter|' +
    'code caractere|valeur caractere|code ascii|' +
    'zeichencode|ascii wert|zeichenwert|' +
    'codice carattere|valore carattere|' +
    'kod znaku|wartosc znaku|' +
    'cod caracter|valoare caracter|' +
    'karakter kod|karakter ertek|' +
    'kod znaku|hodnota znaku',
    '');
  AddCap('toggle_csv_mode', 'VIEW', 'Ctrl+Alt+V',
    'modo csv|csv mode|colunas csv|ativar csv|desativar csv|vista csv|ver como csv|' +
    'csv column mode|modo coluna|view as csv|column mode|' +
    'modo csv|columnas csv|ver como csv|vista columnas|' +
    'mode csv|colonnes csv|afficher csv|vue csv|' +
    'csv modus|spaltenmodus|csv ansicht|' +
    'modalita csv|colonne csv|vista csv|' +
    'tryb csv|kolumny csv|widok csv|' +
    'mod csv|coloane csv|vizualizare csv|' +
    'csv mod|oszlopok|csv nezet|' +
    'rezim csv|sloupce csv|zobrazeni csv',
    '');
  AddCap('toggle_csv_header', 'VIEW', '',
    'cabecalho csv|csv header|header as data|mostrar cabecalho como dados|' +
    'csv show header|linha de cabecalho csv|header row|' +
    'encabezado csv|cabecera csv|mostrar encabezado|' +
    'en tete csv|entete csv|entete comme donnees|' +
    'csv kopfzeile|header als daten|kopfzeile anzeigen|' +
    'intestazione csv|header csv|intestazione come dati|' +
    'naglowek csv|naglowek jako dane|' +
    'antet csv|header ca date|' +
    'csv fejlec|fejlec mint adat|' +
    'csv hlavicka|hlavicka jako data',
    '');
  AddCap('toggle_fullscreen', 'VIEW', 'F11',
    'tela cheia|full screen|fullscreen|f11|ecra completo|maximizar vista|' +
    'pantalla completa|modo pantalla completa|' +
    'plein ecran|mode plein ecran|' +
    'vollbild|vollbildmodus|' +
    'schermo intero|modalita schermo intero|' +
    'pelny ekran|tryb pelnoekranowy|' +
    'ecran complet|mod ecran complet|' +
    'teljes kepernyo|teljes kepernyos mod|' +
    'cela obrazovka|rezim cele obrazovky',
    '');
  AddCap('toggle_zero_scan', 'VIEW', '',
    'zero scan|force zero scan|abertura instantanea|instant open|modo instantaneo|' +
    'abrir sem indice|ultra large files|open without index|no index open|' +
    'apertura instantanea|abrir sin indice|apertura inmediata|' +
    'ouverture instantanee|ouvrir sans index|' +
    'sofort offnen|ohne index oeffnen|instantan oeffnen|' +
    'apertura istantanea|apri senza indice|' +
    'natychmiastowe otwarcie|otworz bez indeksu|' +
    'deschidere instantanee|deschide fara index|' +
    'azonnali megnyitas|index nelkuli megnyitas|' +
    'okamzite otevreni|otevrit bez indexu',
    '');
  AddCap('force_index_file', 'VIEW', '',
    'forcar indice|force index|indexar este arquivo|construir indice|index this file|' +
    'montar indice de linhas|gerar indice|build line index|create index|' +
    'forzar indice|indexar archivo|construir indice|generar indice|' +
    'forcer index|indexer fichier|construire index|generer index|' +
    'index erzwingen|index erstellen|zeilenindex bauen|' +
    'forza indice|indicizza file|crea indice|' +
    'wymus indeks|zbuduj indeks|utworz indeks|' +
    'forteaza index|construieste index|genereaza index|' +
    'index kenyszeritese|index letrehozasa|' +
    'vynutit index|vytvorit index|sestav index',
    '');
  AddCap('open_policy_auto', 'VIEW', '',
    'abertura automatica|open automatic|politica automatica de abertura|' +
    'open: automatic|automatic open policy|' +
    'apertura automatica|politica automatica|' +
    'ouverture automatique|politique automatique|' +
    'automatisches oeffnen|automatische oeffnung|' +
    'apertura automatica|politica automatica|' +
    'automatyczne otwieranie|polityka automatyczna|' +
    'deschidere automata|politica automata|' +
    'automatikus megnyitas|automatikus politika|' +
    'automaticke otevreni|automaticka politika',
    '');
  AddCap('open_policy_index', 'VIEW', '',
    'sempre indexar|always build line index|sempre construir indice|' +
    'open: always build line index|always index|' +
    'siempre indexar|siempre construir indice|' +
    'toujours indexer|toujours construire index|' +
    'immer indexieren|immer index erstellen|' +
    'sempre indicizzare|sempre costruire indice|' +
    'zawsze indeksuj|zawsze buduj indeks|' +
    'indexeaza mereu|construieste mereu index|' +
    'mindig indexel|mindig index epites|' +
    'vzdy indexovat|vzdy vytvorit index',
    '');
  AddCap('open_policy_instant', 'VIEW', '',
    'sempre instantaneo|always instant|sempre zero scan|open: always instant|' +
    'always zero scan|instant open always|' +
    'siempre instantaneo|siempre zero scan|' +
    'toujours instantane|toujours zero scan|' +
    'immer sofort|immer zero scan|' +
    'sempre istantaneo|sempre zero scan|' +
    'zawsze natychmiast|zawsze zero scan|' +
    'mereu instant|mereu zero scan|' +
    'mindig azonnali|mindig zero scan|' +
    'vzdy okamzite|vzdy zero scan',
    '');
  AddCap('configure_max_gb', 'VIEW', '',
    'limite gb|indexed file size limit|tamanho maximo indexado|configurar max gb|' +
    'limite de tamanho do indice|max index size|index size limit|' +
    'limite de tamano|tamano maximo indexado|configurar gb|' +
    'limite taille|taille max index|configurer gb|' +
    'groessenlimit|max index groesse|gb limit konfigurieren|' +
    'limite dimensione|dimensione max indice|configura gb|' +
    'limit gb|maksymalny rozmiar indeksu|konfiguruj gb|' +
    'limita gb|dimensiune max index|configureaza gb|' +
    'gb limit|max index meret|gb beallitas|' +
    'limit gb|max velikost indexu|nastavit gb',
    '');

  { TOOLS: split / merge / export / replace / python }
  AddCap('split_equal_parts', 'TOOLS', 'Ctrl+Shift+P',
    'ctrl+shift+p|partes iguais|equal parts|split equal|dividir em partes|particionar|' +
    'dividir o arquivo|dividir em|partir em|quero dividir|split into|em partes iguais|' +
    'partir o arquivo|dividir arquivo em|esse arquivo|this file|este archivo|ce fichier|' +
    'diese datei|questo file|ten plik|este ficheiro|acest fisier|ez a fajl|tento soubor|' +
    'dividir en partes|partir en partes|teilen in teile|dividi in parti|podziel na czesci|' +
    'imparte in parti|egyenlo reszek|rozdelit na casti|split file into|' +
    'pode dividir|can you split|puedes dividir|kannst du teilen|puoi dividere|' +
    'mozesz podzielic|poti imparti|fel tudod osztani|muzes rozdelit',
    'parts, path (optional if file open / this file)');
  AddCap('extract_file_parts', 'TOOLS', 'Ctrl+Shift+Q',
    'ctrl+shift+q|extrair partes|extract parts|fracao do arquivo|parte n de|' +
    'extrair parte do arquivo|extrair uma parte|' +
    'extraer partes|extraire parties|teile extrahieren|estrarre parti|wyodrebnij czesci|' +
    'extrage parti|resz kinyerese|extrahovat casti|' +
    'extract part|extraer parte|extraire une partie',
    'path, total_parts, part_from, part_to');
  AddCap('split_files', 'TOOLS', 'Ctrl+Shift+K',
    'ctrl+shift+k|split files|dividir ficheiros|dividir arquivos por tamanho|' +
    'dividir por tamanho|split by size|dividir por tamano|diviser par taille|' +
    'nach groesse teilen|dividi per dimensione|podziel wg rozmiaru|' +
    'imparte dupa dimensiune|meret szerint|rozdelit podle velikosti',
    '');
  AddCap('pattern_split', 'TOOLS', 'Ctrl+Alt+P',
    'ctrl+alt+p|split pattern|dividir padrao|regex split|dividir por regex|' +
    'dividir por padrao|partir por padrao|dividir por patron|diviser par motif|' +
    'nach muster teilen|dividi per pattern|podziel wg wzorca|' +
    'imparte dupa tipar|minta szerinti|rozdelit podle vzoru',
    '');
  AddCap('show_tab_merge_lines', 'TOOLS', 'Ctrl+Shift+M',
    'ctrl+shift+m|merge lines|unir linhas|juntar linhas|mesclar linhas|quero unir linhas|' +
    'unir lineas|fusionner lignes|zeilen zusammenfuehren|unisci righe|scal linie|' +
    'uneste linii|sorok egyesitese|sloucit radky|' +
    'juntar linhas|merge line|unir linhas do arquivo',
    '');
  AddCap('show_tab_merge_files', 'TOOLS', 'Ctrl+Shift+J',
    'ctrl+shift+j|merge files|unir ficheiros|juntar arquivos|mesclar arquivos|' +
    'quero mesclar arquivos|quero unir arquivos|quero juntar|juntar esse arquivo|' +
    'unir esse arquivo|mesclar esse arquivo|juntar o arquivo|unir o arquivo|' +
    'unir os arquivos|mesclar os arquivos|unir as partes|juntar as partes|' +
    'mesclar as partes|reunir as partes|reunir esse arquivo|unir dois arquivos|' +
    'quero mesclar|quero unir|pode juntar|pode unir|pode mesclar|can you join|' +
    'can you merge|puedes unir|puedes juntar|this file|este archivo|ce fichier|' +
    'diese datei|questo file|ten plik|este ficheiro|acest fisier|ez a fajl|tento soubor|' +
    'unir archivos|fusionner fichiers|dateien zusammenfuehren|unisci file|scal pliki|' +
    'uneste fisiere|fajlok egyesitese|sloucit soubory|join parts|join files|merge parts|' +
    'kannst du zusammenfuehren|puoi unire|mozesz scalic|poti uni|ossze tudod fuzni|' +
    'muzes sloucit|juntar ficheiros|unir ficheiros|diese datei zusammenfuehren|' +
    'datei zusammenfuehren|dateien zusammenfuehren|koennen sie zusammenfuehren',
    'path (optional if file open / this file)');
  AddCap('show_tab_compare', 'TOOLS', 'Ctrl+Shift+H',
    'ctrl+shift+h|comparar arquivos|compare merge|historico de merge|diff arquivos|' +
    'quero comparar|comparar dois arquivos|aba comparar|' +
    'comparar archivos|comparer fichiers|dateien vergleichen|confronta file|porownaj pliki|' +
    'compara fisiere|fajlok osszehasonlitasa|porovnat soubory|compare files|diff files|' +
    'comparar ficheiros|vergleichen|confrontare|porownac|compara|osszehasonlit|porovnat',
    '');
  AddCap('delete_duplicate_lines', 'TOOLS', '',
    'linhas duplicadas|delete duplicate|remover duplicadas|dedup|apagar duplicados|' +
    'apagar linhas duplicadas|eliminar duplicatas|' +
    'eliminar duplicados|supprimer doublons|duplikate entfernen|elimina duplicati',
    '');
  AddCap('extract_frequent_strings', 'TOOLS', '',
    'strings frequentes|frequent strings|extrair string|textos mais frequentes|' +
    'strings mais comuns|extrair strings frequentes|' +
    'cadenas frecuentes|chaines frequentes|haufige strings|string frequenti',
    '');
  AddCap('export_file', 'TOOLS', 'Ctrl+Shift+O',
    'ctrl+shift+o|exportar arquivo|export file|exportar ficheiro|quero exportar o arquivo|' +
    'exportar archivo|exporter fichier|datei exportieren|esporta file|eksportuj plik|' +
    'exporta fisier|fajl exportalasa|exportovat soubor',
    '');
  AddCap('export_lines', 'TOOLS', '',
    'exportar linhas|gerar um novo|criar um novo|somente com as linhas|linhas entre|line range|' +
    'gerar arquivo so com|novo arquivo com as linhas|extrair linhas de|' +
    'gerar um novo somente com|criar um novo com as linhas|export line range|' +
    'export lines|only the lines|only these lines|lines between|lines from|first lines|' +
    'create new file with|new file with lines|export only lines|extract lines from|' +
    'exportar lineas|solo las lineas|lineas entre|primeras lineas|crear un nuevo|generar un nuevo|' +
    'solo con las lineas|extraer lineas de|nuevo archivo con las lineas|exportar solo lineas|' +
    'exporter lignes|seulement les lignes|lignes entre|premieres lignes|creer un nouveau|' +
    'fichier avec les lignes|extraire les lignes|plage de lignes|intervalle de lignes|' +
    'exporter seulement les lignes|nouveau fichier avec les lignes|' +
    'zeilen exportieren|nur die zeilen|zeilen zwischen|erste zeilen|neue datei mit zeilen|' +
    'zeilenbereich|nur diese zeilen|nur zeilen exportieren|zeilen extrahieren|' +
    'esporta righe|solo le righe|righe tra|prime righe|nuovo file con righe|estrarre righe|' +
    'esportare solo righe|intervallo righe|' +
    'eksportuj linie|tylko linie|linie miedzy|pierwsze linie|nowy plik z liniami|' +
    'eksportuj tylko linie|zakres linii|' +
    'exportar so linhas|extrair linhas|ficheiro so com linhas|exportar so linhas|' +
    'exporta linii|doar liniile|linii intre|primele linii|fisier cu liniile|' +
    'exporta doar liniile|interval linii|' +
    'sorok exportalasa|csak a sorok|sorok kozott|elso sorok|uj fajl a sorokkal|' +
    'csak sorok exportalasa|sor tartomany|' +
    'exportovat radky|pouze radky|radky mezi|prvni radky|novy soubor s radky|' +
    'exportovat pouze radky|rozsah radku',
    'filter_text=N-M, path');
  CapAnti('formato word|documento word|programa em python|gere um programa|gerar um programa|' +
    'readme|gere um .py|gere um .pas|resumo no formato|gere uma classe|' +
    'formato pdf|em pdf|em docx|em odt|format word|document word|dokument word|' +
    'format pdf|format odt|word format|word und pdf');

  AddCap('export_matching_lines', 'TOOLS', '',
    'exportar linhas que|export matching|linhas que contenham|linhas com a palavra|' +
    'exportar as que tem|export lines that|lines containing|lines with the word|' +
    'lines that contain|export matching lines|' +
    'exportar lineas que|lineas que contengan|lineas con la palabra|exportar las que|' +
    'exporter lignes qui|lignes contenant|lignes avec le mot|exporter les lignes qui|' +
    'zeilen die|zeilen mit dem wort|zeilen enthalten|zeilen exportieren die|' +
    'esporta righe che|righe contenenti|righe con la parola|esporta righe che contengono|' +
    'eksportuj linie ktore|linie zawierajace|linie ze slowem|linie ktore zawieraja|' +
    'exporta linii care|linii care contin|linii cu cuvantul|exporta linii care contin|' +
    'sorok amelyek|sorok amely tartalmaz|sorok exportalasa amely|' +
    'radky ktere|radky obsahujici|radky s slovem|exportovat radky ktere',
    'filter_text');
  AddCap('export_filtered', 'TOOLS', 'Ctrl+Shift+L',
    'ctrl+shift+l|exportar filtro|export filtered|export tail|exportar tail|' +
    'exportar linhas filtradas|exportar filtrado|exporter filtre|gefiltert exportieren|' +
    'esporta filtrate|exportar resultados do filtro|exportar hits|export filter results|' +
    'salvar linhas filtradas|exportar grep|exportar o filtro',
    '');
  AddCap('replace_all', 'TOOLS', 'Ctrl+H',
    'substituir tudo|replace all|substituir por|replace with|quero substituir|trocar texto|' +
    'trocar por|reemplazar todo|remplacer tout|alles ersetzen|sostituisci tutto|' +
    'zamien wszystko|inlocuieste tot|csere mind|nahradit vse',
    'search_text, replace_text');
  AddCap('open_replace', 'TOOLS', 'Ctrl+H',
    'ctrl+h|replace dialog|find replace|dialogo substituir|abrir substituir|find and replace|' +
    'abrir reemplazar|ouvrir remplacer|ersetzen oeffnen|apri sostituisci',
    '');
  AddCap('show_script_engine', 'TOOLS', 'Ctrl+Alt+E',
    'script engine|motor de script|automacao script|executar script|' +
    'rodar python|executar python|run python|rodar um python|macros python|' +
    'ctrl+alt+e|python para linhas|quero rodar um python|' +
    'python para certas linhas|rodar um script|macros com python|painel python|' +
    'abrir script engine|quero o painel python|run script|execute script|python macro|' +
    'motor de scripts|ejecutar python|ejecutar script|panel python|macros con python|' +
    'moteur de script|executer python|lancer python|panneau python|macro python|' +
    'skript ausfuehren|python ausfuehren|python starten|skript engine oeffnen|' +
    'motore script|esegui python|esegui script|pannello python|macro python script|' +
    'silnik skryptow|uruchom python|wykonaj skrypt|panel pythona|' +
    'motor script|ruleaza python|executa script|panou python|' +
    'script motor|python futtatasa|szkript futtatasa|python makro panel|' +
    'spustit python|spustit skript|script engine panel|python makro',
    'path');
  CapAnti('gere um programa|gera um programa|gerar um programa|escreva um programa|' +
    'programa em python|programa python|gere um .py|gerar .py|escreva um .py|' +
    'generate a python program|create a python script|codigo fonte python|' +
    'generer un programme|programme python|generar programa|generar codigo python|' +
    'programm generieren|python programm erstellen|genera programma|codice sorgente python|' +
    'wygeneruj program|kod zrodlowy python|genereaza program|cod sursa python|' +
    'program generalasa|forraskod python|vygenerovat program|python zdrojovy kod|' +
    'formato word|resumo no formato word|documento word|gere um readme|format word|' +
    'formato pdf|document word|generer document|dokument erzeugen');

  AddCap('toggle_segmented_heavy_ops', 'TOOLS', '',
    'modo segmentado|line-segmented|heavy ops|operacoes pesadas segmentadas|' +
    'forcar modo segmentado',
    '');
  AddCap('segment_ops_auto', 'TOOLS', '',
    'segmented ops automatic|ops segmentadas automaticas|segmented automatic',
    '');
  AddCap('segment_ops_always', 'TOOLS', '',
    'segmented ops always|sempre usar segmentado|always use segmented',
    '');
  AddCap('segment_ops_never', 'TOOLS', '',
    'segmented ops never|nunca usar segmentado|never use segmented',
    '');

  { SESSION / OPTIONS }
  AddCap('open_options', 'SESSION', 'Ctrl+P',
    'ctrl+p|menu opcoes|options menu|abrir opcoes|open options|settings menu|' +
    'abrir opciones|menu opciones|configuracion|ajustes|' +
    'ouvrir options|menu options|parametres|reglages|' +
    'optionen oeffnen|einstellungen|optionen menu|' +
    'apri opzioni|menu opzioni|impostazioni|' +
    'otworz opcje|menu opcji|ustawienia|' +
    'deschide optiuni|meniu optiuni|setari|' +
    'beallitasok megnyitasa|opciok menu|beallitasok menu|' +
    'otevrit moznosti|menu moznosti|nastaveni',
    '');
  AddCap('toggle_readonly_session', 'SESSION', '',
    'somente leitura|read-only|readonly session|sessao somente leitura|sessao read only|' +
    'read only mode|modo leitura|' +
    'solo lectura|sesion solo lectura|modo solo lectura|' +
    'lecture seule|session lecture seule|mode lecture seule|' +
    'schreibgeschuetzt|nur lesen|lesemodus|schreibschutz|' +
    'sola lettura|sessione sola lettura|modalita sola lettura|' +
    'tylko do odczytu|sesja tylko odczyt|tryb tylko odczyt|' +
    'doar citire|sesiune doar citire|mod doar citire|' +
    'csak olvashato|olvasasi mod|irasvedelem|' +
    'pouze pro cteni|rezim pouze cteni|pouze cteni',
    '');
  AddCap('save_session', 'SESSION', 'Ctrl+Alt+S',
    'ctrl+alt+s|save session|guardar sessao|salvar sessao|gravar sessao|store session|' +
    'guardar sesion|salvar sesion|almacenar sesion|' +
    'enregistrer session|sauvegarder session|sauver session|' +
    'sitzung speichern|session speichern|' +
    'salva sessione|memorizza sessione|salvare sessione|' +
    'zapisz sesje|zachowaj sesje|zapis sesji|' +
    'salveaza sesiunea|pastreaza sesiunea|' +
    'munkamenet mentese|session mentese|' +
    'ulozit relaci|ulozit session|ulozit seanci',
    '');
  AddCap('load_session', 'SESSION', 'Ctrl+Alt+L',
    'ctrl+alt+l|load session|carregar sessao|abrir sessao|open session|restore session|' +
    'cargar sesion|abrir sesion|restaurar sesion|' +
    'charger session|ouvrir session|restaurer session|' +
    'sitzung laden|session laden|' +
    'carica sessione|apri sessione|ripristina sessione|' +
    'wczytaj sesje|otworz sesje|przywroc sesje|' +
    'incarca sesiunea|deschide sesiunea|restaureaza sesiunea|' +
    'munkamenet betoltese|session betoltese|' +
    'nacist relaci|otevrit relaci|obnovit relaci',
    '');

  { HELP / AI }
  AddCap('show_help', 'AI', 'F1',
    'f1|ajuda|help|abrir ajuda|manual|atalhos|mostrar atalhos|keyboard shortcuts|' +
    'ayuda|manual de ayuda|atajos|mostrar ayuda|' +
    'aide|manuel|raccourcis|ouvrir aide|afficher aide|' +
    'hilfe|handbuch|tastenkuerzel|kurzbefehle|hilfe oeffnen|' +
    'aiuto|manuale|scorciatoie|mostra aiuto|' +
    'pomoc|instrukcja|skroty|pokaz pomoc|' +
    'ajutor|manual|scurtaturi|deschide ajutor|' +
    'segitseg|kezikonyv|gyorsbillentyu|segitseg megnyitasa|' +
    'napoveda|prirucka|zkratky|zobrazit napovedu',
    '');
  AddCap('show_version_history', 'AI', '',
    'historico de versoes|version history|changelog|historico da versao|release notes|' +
    'historial de versiones|notas de version|registro de cambios|' +
    'historique des versions|journal des versions|notes de version|' +
    'versionshistorie|aenderungsprotokoll|versionsverlauf|' +
    'cronologia versioni|note di rilascio|registro modifiche|' +
    'historia wersji|dziennik zmian|notatki wydania|' +
    'istoric versiuni|jurnal modificari|note versiune|' +
    'verziotortenet|valtozasnaplo|kiadasi megjegyzesek|' +
    'historie verzi|protokol zmen|poznamky k vydani',
    '');
  AddCap('show_about', 'AI', '',
    'sobre o fastfile|about fastfile|mais info|splash|sobre o programa|about program|' +
    'acerca de fastfile|sobre el programa|informacion del programa|' +
    'a propos de fastfile|a propos du programme|informations sur fastfile|' +
    'ueber fastfile|ueber das programm|programminfo|' +
    'informazioni su fastfile|info programma|about fast file|' +
    'o fastfile|informacje o fastfile|o programie|' +
    'despre fastfile|despre program|informatii fastfile|' +
    'a fastfile rol|programrol|fastfile informacio|' +
    'o fastfile|o programu|informace o fastfile',
    '');
  CapAnti('gere um programa|programa em python|gerar codigo|generer programme|generar codigo|' +
    'programm generieren|genera programma|wygeneruj program|genereaza program|program generalasa');

  AddCap('consumer_ai', 'AI', '',
    'ctrl+shift+a|consumer ai|chat ia sql|chat sql|ia sql|ai chat sql|sql chat|' +
    'quantas linhas|how many lines|contar linhas|total de linhas|numero de linhas|' +
    'quantos registros|valores unicos|valores distintos|soma da coluna|' +
    'media da coluna|group by|consulta sql|how many rows|contar registros|' +
    'count lines|total lines|number of lines|unique values|distinct values|' +
    'sum column|average column|sql query|how many records|aggregate|' +
    'cuantas lineas|contar lineas|total de lineas|numero de lineas|valores unicos|' +
    'suma columna|promedio columna|consulta sql|contar registros|group by|' +
    'combien de lignes|compter lignes|nombre de lignes|valeurs uniques|valeurs distinctes|' +
    'somme colonne|moyenne colonne|requete sql|compter enregistrements|group by|' +
    'wie viele zeilen|zeilen zaehlen|anzahl zeilen|eindeutige werte|summe spalte|' +
    'durchschnitt spalte|sql abfrage|datensaetze zaehlen|group by|' +
    'quante righe|conta righe|numero righe|valori unici|somma colonna|media colonna|' +
    'query sql|conta record|group by|' +
    'ile linii|policz linie|liczba linii|unikalne wartosci|suma kolumny|srednia kolumny|' +
    'zapytanie sql|policz rekordy|group by|' +
    'cate linii|numara linii|total linii|valori unice|suma coloana|medie coloana|' +
    'interogare sql|numara inregistrari|group by|' +
    'hany sor|sorok szama|egyedi ertekek|oszlop osszeg|atlag oszlop|sql lekerdezes|' +
    'rekordok szama|group by|' +
    'kolik radku|pocet radku|unikatni hodnoty|soucet sloupce|prumer sloupce|sql dotaz|' +
    'pocet zaznamu|group by',
    'path, filter_text=original question forwarded to ConsumerAI Python');
  CapAnti('formato word|documento word|gere um programa|gerar um programa|pra que serve|' +
    'para que serve|resumo no formato|gere um readme|rodar python|format word|' +
    'generer document|generar documento|dokument erzeugen|genera documento|' +
    'wygeneruj dokument|genereaza document|dokumentum generalasa|vygenerovat dokument|' +
    'a quoi sert|wofuer ist|do czego sluzy|la ce serve|k cemu slouzi|' +
    'exportar linhas|export lines|exporter lignes|zeilen exportieren');

  AddCap('consumer_rag', 'AI', '',
    'consumer rag|chat avancado|advanced ai chat|chat do arquivo|ia do arquivo|' +
    'pra que serve|pra que ele serve|para que serve|para que ele serve|' +
    'o que e este arquivo|analisar o arquivo|about this file|what is this file|' +
    'resumo do arquivo|resumir o arquivo|explique o arquivo|descreva o arquivo|' +
    'do que se trata|com relacao ao arquivo|o que este arquivo faz|purpose of file|' +
    'what does this file do|explain this file|summarize this file|describe this file|' +
    'para que sirve|que es este archivo|resumir el archivo|explicar el archivo|' +
    'analizar el archivo|de que trata este archivo|proposito del archivo|' +
    'a quoi sert|pourquoi ce fichier|qu est ce que ce fichier|resumer le fichier|' +
    'expliquer le fichier|analyser le fichier|but de ce fichier|de quoi parle ce fichier|' +
    'wofuer ist diese datei|was ist diese datei|datei zusammenfassen|datei erklaeren|' +
    'datei analysieren|zweck dieser datei|worum geht es in dieser datei|' +
    'a cosa serve|cos e questo file|riassumi file|spiega file|analizza file|scopo del file|' +
    'do czego sluzy|co to za plik|podsumuj plik|wyjasnij plik|przeanalizuj plik|cel pliku|' +
    'la ce serve|ce este acest fisier|rezuma fisierul|explica fisierul|analizeaza fisierul|' +
    'mire valo ez a fajl|mi ez a fajl|fajl osszefoglalasa|fajl magyarazata|fajl elemzese|' +
    'k cemu slouzi|co je tento soubor|shrnout soubor|vysvetlit soubor|analyzovat soubor|ucel souboru',
    'path, filter_text=original question forwarded to ConsumerRAG Python');
  CapAnti('formato word|formatos word|nos formatos|em word|em docx|.docx|.rtf|documento word|word pra mim|' +
    'formato pdf|em pdf|.pdf|formato odt|formatos odt|em odt|.odt|word e odt|word e pdf|' +
    'format word|word format|word und odt|word und pdf|word et pdf|word en pdf|' +
    'gere um programa|gerar um programa|programa em python|gere um .py|' +
    'gere uma classe|classe em java|componente react|' +
    'quantas linhas|contar linhas|group by|consulta sql|rodar python|' +
    'exportar linhas|linhas entre|somente com as linhas|export lines|lines between|' +
    'only the lines|exporter lignes|seulement les lignes|lignes entre|' +
    'zeilen exportieren|nur die zeilen|zeilen zwischen|' +
    'esporta righe|solo le righe|righe tra|' +
    'eksportuj linie|tylko linie|linie miedzy|' +
    'exporta linii|doar liniile|linii intre|' +
    'sorok exportalasa|csak a sorok|sorok kozott|' +
    'exportovat radky|pouze radky|radky mezi');

  AddCap('compose_document', 'AI', '',
    'gere um documento|gera um documento|gerar um documento|documento avulso|' +
    'gere um readme|gera um readme|gerar codigo|gere um .pas|gere um .md|' +
    'gere um programa|gera um programa|gerar um programa|escreva um programa|' +
    'gere uma classe|gera uma classe|gerar uma classe|escreva uma classe|' +
    'programa em python|programa python|gere um .py|gerar .py|' +
    'classe em java|classe em javascript|classe em typescript|' +
    'componente react|componente angular|programa em go|programa em c++|' +
    'gere um .js|gere um .ts|gere um .go|gere um .java|gere um .cpp|' +
    'compose a document|generate a document|write a readme|generate a python program|' +
    'create a class|generate source code|write source code|' +
    'formato word|formatos word|nos formatos|resumo no formato word|documento word|resumo em word|' +
    'word pra mim|salvar como word|criar documento word|word e odt|word e pdf|' +
    'formato pdf|em pdf|resumo em pdf|documento pdf|' +
    'formato odt|formatos odt|em odt|resumo em odt|em docx|' +
    'arruma o codigo|conserta o codigo|corrigir o codigo|fix the generated|' +
    'e possivel gerar um programa|tem como gerar um programa|' +
    'generar documento|escribir readme|generar codigo|crear clase|resumen en word|formato pdf|' +
    'generar un programa|escribir un programa|crear documento word|resumen en pdf|' +
    'generer un document|ecrire readme|generer code|creer classe|resume en word|format pdf|' +
    'generer un programme|ecrire un programme|document word|resume en pdf|format odt|' +
    'dokument erzeugen|readme schreiben|code generieren|klasse erstellen|zusammenfassung word|' +
    'programm generieren|dokument word|zusammenfassung pdf|format pdf|' +
    'genera documento|scrivi readme|genera codice|crea classe|riassunto word|formato pdf|' +
    'genera programma|scrivi programma|documento word|riassunto pdf|' +
    'wygeneruj dokument|napisz readme|wygeneruj kod|utworz klase|podsumowanie word|format pdf|' +
    'wygeneruj program|dokument word|podsumowanie pdf|' +
    'genereaza document|scrie readme|genereaza cod|creeaza clasa|rezumat word|format pdf|' +
    'genereaza program|document word|rezumat pdf|' +
    'dokumentum generalasa|readme irasa|kod generalasa|osztaly letrehozasa|osszefoglalo word|format pdf|' +
    'program generalasa|word dokumentum|pdf osszefoglalo|' +
    'vygenerovat dokument|napsat readme|vygenerovat kod|vytvorit tridu|shrnuti word|format pdf|' +
    'vygenerovat program|word dokument|pdf shrnuti',
    'optional dest path; Word/PDF/ODT summaries use summarize-then-export pipeline');
  CapAnti('rodar python|executar python|run python|ctrl+alt+e|quero rodar um python|' +
    'macros python|script engine|quantas linhas|contar linhas|group by|' +
    'pra que serve|para que ele serve|somente com as linhas|linhas entre|' +
    'exportar linhas|ejecutar python|executer python|python ausfuehren|esegui python|' +
    'uruchom python|ruleaza python|python futtatasa|spustit python|' +
    'a quoi sert|wofuer ist|do czego sluzy|la ce serve|k cemu slouzi|' +
    'export lines|exporter lignes|zeilen exportieren|esporta righe|eksportuj linie|' +
    'exporta linii|sorok exportalasa|exportovat radky|' +
    'validar fonte|validar o codigo|validate source|check syntax');

  AddCap('validate_source', 'FILTER', '',
    'validar fonte|validar o fonte|validar o codigo|validar codigo|validar sintaxe|' +
    'verificar sintaxe|checar sintaxe|carregar o fonte pra validar|' +
    'carregar fonte para validar|carregar o fonte para validar|' +
    'recarregar o fonte|recarregar fonte|recarregar algum fonte|' +
    'validate source|validate the source|check syntax|syntax check|' +
    'load source to validate|load file to validate|reload source|' +
    'validar fuente|comprobar sintaxis|cargar fuente para validar|' +
    'valider le source|verifier la syntaxe|charger le source pour valider|' +
    'quellcode pruefen|syntax pruefen|quelldatei zum pruefen laden|' +
    'validare sorgente|controlla sintassi|carica sorgente da validare|' +
    'waliduj zrodlo|sprawdz skladnie|zaladuj zrodlo do walidacji|' +
    'valideaza sursa|verifica sintaxa|incarca sursa pentru validare|' +
    'forras ellenorzese|szintaxis ellenorzese|forras betoltese ellenorzeshez|' +
    'overit zdroj|zkontrolovat syntax|nacist zdroj k overeni|' +
    'quais linguagens valida|quais linguagens que a aplicacao valida|' +
    'which languages validate|linguagens suportadas validar|' +
    'linguagens de programacao valida',
    'params.path optional; opens file then syntax-checks .py/.js/.jsx/.ts/.tsx/.mjs/.cjs only');
  CapAnti('rodar python|executar python|run python|gere um programa|compose|' +
    'gerar codigo|show_script_engine|consumer_ai|consumer_rag');

  GReady := True;
end;

function MapIsAllowedActionId(const AId: string): Boolean;
var
  i: Integer;
begin
  EnsureMap;
  Result := False;
  if AId = '' then Exit;
  for i := 0 to High(GCaps) do
    if SameText(GCaps[i].ActionId, AId) then
    begin
      Result := True;
      Exit;
    end;
end;

function TryScoreCapabilityMap(const AQuestion: string; out AActionId: string;
  out ABestScore, ASecondScore: Integer): Boolean;
var
  L: string;
  i, Sc: Integer;
begin
  EnsureMap;
  Result := False;
  AActionId := '';
  ABestScore := 0;
  ASecondScore := 0;
  L := NormalizeQuestionForScoring(AQuestion);
  if L = '' then Exit;
  for i := 0 to High(GCaps) do
  begin
    Sc := ScoreCapability(L, GCaps[i]);
    if Sc > ABestScore then
    begin
      ASecondScore := ABestScore;
      ABestScore := Sc;
      AActionId := GCaps[i].ActionId;
    end
    else if Sc > ASecondScore then
      ASecondScore := Sc;
  end;
  Result := (ABestScore >= MAP_MIN_SCORE) and
    (ABestScore >= ASecondScore + MAP_MARGIN);
end;

function TryScoreCapabilityMapInFamily(const AQuestion, AFamilyIds: string;
  out AActionId: string; out ABestScore, ASecondScore: Integer): Boolean;
var
  L, Ids: string;
  i, Sc: Integer;
begin
  { Score only among pipe-separated action ids (intent family). }
  EnsureMap;
  Result := False;
  AActionId := '';
  ABestScore := 0;
  ASecondScore := 0;
  Ids := '|' + LowerCase(AFamilyIds) + '|';
  L := NormalizeQuestionForScoring(AQuestion);
  if (L = '') or (AFamilyIds = '') then Exit;
  for i := 0 to High(GCaps) do
  begin
    if Pos('|' + LowerCase(GCaps[i].ActionId) + '|', Ids) = 0 then
      Continue;
    Sc := ScoreCapability(L, GCaps[i]);
    if Sc > ABestScore then
    begin
      ASecondScore := ABestScore;
      ABestScore := Sc;
      AActionId := GCaps[i].ActionId;
    end
    else if Sc > ASecondScore then
      ASecondScore := Sc;
  end;
  Result := (ABestScore >= MAP_MIN_SCORE) and
    (ABestScore >= ASecondScore + MAP_MARGIN);
end;

procedure MapApplyExtractedParams(const AQuestion: string; var AStep: TAssistantChainStep);
begin
  { Catalog fills Path/LineNo/FilterText before calling this; keep as a hook. }
  if AStep.ActionId = '' then Exit;
  if AQuestion = '' then Exit;
end;

function FirstPhrase(const Phrases: string): string;
var
  p: Integer;
begin
  p := Pos('|', Phrases);
  if p > 0 then
    Result := Copy(Phrases, 1, p - 1)
  else
    Result := Phrases;
end;

function BuildCapabilityMapKB: string;
var
  i: Integer;
  LastCat, Line: string;
begin
  EnsureMap;
  Result :=
    'FASTFILE CAPABILITY MAP: user words -> one action id; the app EXECUTES it.' + #13#10 +
    'Never invent action ids. Paths go in params.path. Line range (entre N a M) = export_lines, never goto_line.' + #13#10 +
    'Conflicts: "resumo em Word" / "gerar programa .py" = compose_document; ' +
    '"rodar python nas linhas" = show_script_engine; "pra que serve" = consumer_rag.' + #13#10;
  LastCat := '';
  for i := 0 to High(GCaps) do
  begin
    if not SameText(GCaps[i].Category, LastCat) then
    begin
      LastCat := GCaps[i].Category;
      Result := Result + LastCat + ': ';
    end
    else
      Result := Result + ' | ';
    Line := GCaps[i].ActionId;
    if GCaps[i].Shortcut <> '' then
      Line := Line + '(' + GCaps[i].Shortcut + ')';
    if GCaps[i].ParamsHint <> '' then
      Line := Line + '{' + GCaps[i].ParamsHint + '}';
    Line := Line + '=' + FirstPhrase(GCaps[i].Phrases);
    Result := Result + Line;
    if (i = High(GCaps)) or (not SameText(GCaps[i + 1].Category, LastCat)) then
      Result := Result + #13#10;
  end;
end;

function BuildCapabilityMapRAG(const UserQuestion: string): string;
var
  L, Block: string;
  i, Sc, Total: Integer;
begin
  EnsureMap;
  Result := '';
  L := LowerCase(Trim(UserQuestion));
  if L = '' then Exit;
  Total := 0;
  Result := '[MAP matches]' + #13#10;
  for i := 0 to High(GCaps) do
  begin
    Sc := ScorePhrases(L, GCaps[i].Phrases);
    if Sc < MAP_MIN_SCORE then Continue;
    Block := GCaps[i].ActionId;
    if GCaps[i].Shortcut <> '' then
      Block := Block + ' ' + GCaps[i].Shortcut;
    if GCaps[i].ParamsHint <> '' then
      Block := Block + ' [' + GCaps[i].ParamsHint + ']';
    Result := Result + Block + #13#10;
    Inc(Total);
    if Length(Result) >= RAG_MAX_CHARS then
    begin
      Result := Copy(Result, 1, RAG_MAX_CHARS);
      Exit;
    end;
    if Total >= 12 then Exit;
  end;
  if Total = 0 then
    Result := '';
end;

end.
