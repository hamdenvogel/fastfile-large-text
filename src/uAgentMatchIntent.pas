unit uAgentMatchIntent;

{
  Exact or partial match, read from the user's request in any of the 14 UI languages.
  Partial is the default ("Allyne" also finds "Kallyne"); exact only when the request says so.
  This file is UTF-8 with BOM: the phrases below are written in their own scripts.
}

interface

{ True when the request asks for an exact / whole-word / not partial match. }
function AgentWantsExactMatch(const APrompt: string): Boolean;
{ Lower case, accents removed, punctuation as spaces, one space between words, padded with spaces. }
function AgentFoldText(const S: string): string;
{ Model answers, in any of the 14 languages (the answer follows the user's language). }
{ "I will do it" / "I am reading it" / "please wait": the model stopped before doing the work. }
function AgentAnswerPromisesWork(const S: string): Boolean;
{ Reports work as done, queued, enabled or pending. }
function AgentAnswerClaimsWork(const S: string): Boolean;
{ Says something waits for Accept. }
function AgentAnswerClaimsQueue(const S: string): Boolean;

implementation

uses
  Windows, SysUtils, Character;

const
  { "not partial": checked first, so "sem ser parcial" wins over the bare word "parcial". }
  NOT_PARTIAL: TArray<string> = [
    // pt-BR / pt-PT
    'sem ser parcial', 'sem parcial', 'não parcial', 'não seja parcial', 'não pode ser parcial',
    'não for parcial', 'não ser parcial', 'nada de parcial',
    // en
    'not partial', 'no partial', 'non partial', 'not a partial match',
    // es
    'no parcial', 'sin ser parcial', 'no sea parcial', 'sin coincidencia parcial',
    // fr
    'pas partiel', 'pas partielle', 'non partiel', 'non partielle', 'sans être partiel',
    'sans correspondance partielle',
    // de
    'nicht teilweise', 'nicht partiell', 'keine teilübereinstimmung', 'ohne teilübereinstimmung',
    // it
    'non parziale', 'senza essere parziale', 'senza corrispondenza parziale',
    // pl
    'nie częściowo', 'nie częściowe', 'nie częściowy', 'nie częściowa', 'bez dopasowania częściowego',
    // ro
    'nu parțial', 'nu parțială', 'fără potrivire parțială',
    // hu
    'nem részleges', 'ne részleges',
    // cs
    'ne částečně', 'ne částečný', 'ne částečné', 'bez částečné shody'];

  { Japanese and Chinese: no spaces between words, matched as plain substrings. }
  NOT_PARTIAL_CJK: TArray<string> = [
    // ja
    '部分一致ではなく', '部分一致でない', '部分一致ではない', '部分一致しない',
    // zh-CN / zh-TW
    '不要部分匹配', '非部分匹配', '不是部分匹配', '不要部份匹配', '不是部份匹配'];

  { The bare word "partial" (not negated): the user wants partial matches on purpose. }
  PARTIAL: TArray<string> = [
    'parcial', 'parciais', 'partial', 'partiel', 'partielle', 'teilweise', 'partiell', 'teilübereinstimmung',
    'parziale', 'częściowo', 'częściowe', 'częściowy', 'częściowa', 'parțial', 'parțială', 'részleges',
    'částečně', 'částečný', 'částečné'];

  PARTIAL_CJK: TArray<string> = ['部分一致', '部分匹配', '部份匹配', '模糊匹配'];

  { Exact / whole word. Adverbs like "exatamente", "exactly", "genau", "dokładnie", "pontosan" are left out:
    they are common in requests that do not mean whole-word matching. }
  EXACT: TArray<string> = [
    // pt-BR / pt-PT
    'exato', 'exata', 'exatos', 'exatas', 'exacto', 'exacta', 'palavra inteira', 'palavras inteiras',
    'palavra completa', 'correspondência exata',
    // en
    'exact', 'exact match', 'whole word', 'whole words', 'full word',
    // es
    'palabra completa', 'palabra entera', 'coincidencia exacta', 'exactos', 'exactas',
    // fr
    'exacte', 'mot entier', 'mot complet', 'mots entiers', 'correspondance exacte',
    // de
    'exakt', 'exakte', 'exakten', 'ganzes wort', 'ganze wörter',
    // it
    'esatto', 'esatta', 'esatti', 'esatte', 'parola intera', 'parola completa', 'corrispondenza esatta',
    // pl
    'dokładny', 'dokładna', 'dokładne', 'całe słowo', 'całe słowa', 'pełne słowo',
    // ro
    'exactă', 'cuvânt întreg', 'cuvinte întregi',
    // hu
    'pontos egyezés', 'egész szó', 'teljes szó', 'pontos név', 'pontos nevet', 'pontos szó', 'pontos szót',
    // cs
    'přesný', 'přesná', 'přesné', 'celé slovo', 'celá slova'];

  EXACT_CJK: TArray<string> = [
    // ja
    '完全一致', '単語全体', '単語単位',
    // zh-CN
    '完全匹配', '精确匹配', '全字匹配', '整词匹配', '精确',
    // zh-TW
    '完全符合', '精確匹配', '整詞匹配', '精確', '完全相符'];

  { Answer stems. A trailing space = whole word; otherwise the start of a word ("enfileir" = enfileirado...). }
  PROMISES: TArray<string> = [
    // pt-BR / pt-PT
    'vou ', 'irei ', 'aguarde', 'estou ', 'estamos ', 'vamos ', 'deixe-me', 'deixa eu', 'um momento',
    // en
    'i will ', 'i''ll ', 'please wait', 'i am ', 'i''m ', 'let me ', 'one moment',
    // es
    'voy a ', 'espere', 'estoy ', 'vamos a ', 'déjame', 'un momento',
    // fr
    'je vais ', 'je suis en train', 'veuillez patienter', 'patientez', 'un instant', 'laissez-moi',
    // de
    'ich werde ', 'ich bin dabei', 'bitte warten', 'einen moment', 'lass mich', 'ich prüfe ', 'ich suche ', 'ich lese ',
    // it
    'sto ', 'stiamo ', 'attendere', 'attendi ', 'lasciami', 'farò ', 'vado a ', 'controllerò',
    // pl
    'zaraz ', 'poczekaj', 'proszę czekać', 'sprawdzam', 'chwileczkę', 'pozwól mi', 'będę ',
    // ro
    'voi ', 'o să ', 'așteptați', 'un moment', 'lasă-mă', 'verific ',
    // hu
    'kérem várjon', 'egy pillanat', 'megnézem', 'ellenőrzöm', 'keresem',
    // cs
    'počkejte', 'moment ', 'zkontroluji', 'podívám se', 'budu '];

  PROMISES_CJK: TArray<string> = [
    // ja
    'これから', 'お待ちください', '少々お待ち', '確認します', '検索します', '読み込みます', '実行します',
    '確認中', '検索中', '処理中',
    // zh-CN / zh-TW
    '我将', '我將', '我会', '我會', '请稍候', '請稍候', '稍等', '正在', '让我', '讓我'];

  CLAIMS: TArray<string> = [
    // pt-BR / pt-PT
    'enfileir', 'agendad', 'propost', 'ativad', 'aplicad', 'realizad', 'preparad', 'pendente', 'aguardando',
    'foi criad', 'foi abert', 'foi salv', 'removid', 'dividid', 'marcad', 'convertid', 'exportad', 'aceit',
    // en
    'queued', 'scheduled', 'proposed', 'enabled', 'applied', 'pending', 'has been', 'was created', 'marked', 'accept',
    // es
    'encolad', 'programad', 'propuest', 'activad', 'pendiente', 'esperando', 'fue cread', 'eliminad', 'acept',
    // fr
    'en file', 'planifi', 'propos', 'activé', 'appliqu', 'en attente', 'a été', 'créé', 'supprimé', 'exporté',
    'marqué', 'accept',
    // de
    'eingereiht', 'geplant', 'vorgeschlagen', 'aktiviert', 'angewendet', 'ausstehend', 'wurde ', 'erstellt',
    'entfernt', 'exportiert', 'markiert', 'akzept', 'übernehm', 'bestätig',
    // it
    'in coda', 'pianificat', 'attivat', 'applicat', 'in attesa', 'è stato', 'è stata', 'creat', 'rimoss',
    'esportat', 'contrassegnat', 'accett',
    // pl
    'w kolejce', 'zaplanowan', 'zaproponowan', 'włączon', 'zastosowan', 'oczekuj', 'został', 'utworzon',
    'usunięt', 'wyeksportowan', 'oznaczon', 'zaakceptuj', 'akceptuj',
    // ro
    'în coadă', 'programat', 'propus', 'activat', 'aplicat', 'în așteptare', 'a fost', 'eliminat', 'exportat',
    'marcat', 'accept',
    // hu
    'sorba ', 'ütemez', 'javasol', 'bekapcsol', 'alkalmaz', 'függő', 'várakoz', 'létrehoz', 'töröl', 'exportál',
    'megjelöl', 'elfogad',
    // cs
    've frontě', 'naplánován', 'navržen', 'zapnut', 'použit', 'čeká', 'vytvořen', 'odstraněn', 'exportován',
    'označen', 'přijat', 'přijmout'];

  CLAIMS_CJK: TArray<string> = [
    // ja
    'キューに', '予定', '提案', '有効にしました', '適用', '保留', '作成しました', '削除しました',
    'エクスポートしました', '承認', '受け入れ', '実行しました',
    // zh-CN / zh-TW
    '已排队', '已排隊', '排程', '已提议', '已提議', '建议的', '建議的', '已启用', '已啟用', '已应用', '已套用',
    '待处理', '待處理', '已创建', '已建立', '已删除', '已刪除', '已导出', '已匯出', '接受'];

  QUEUE_CLAIMS: TArray<string> = [
    // pt-BR / pt-PT
    'enfileir', 'propost', 'aceit', 'marcad', 'pendente', 'aguardando',
    // en
    'queued', 'proposed', 'accept', 'pending', 'marked',
    // es
    'encolad', 'propuest', 'acept', 'pendiente',
    // fr
    'en file', 'propos', 'accept', 'en attente', 'marqué',
    // de
    'eingereiht', 'vorgeschlagen', 'akzept', 'ausstehend', 'markiert', 'übernehm',
    // it
    'in coda', 'accett', 'in attesa', 'contrassegnat',
    // pl
    'w kolejce', 'zaproponowan', 'zaakceptuj', 'akceptuj', 'oczekuj', 'oznaczon',
    // ro
    'în coadă', 'propus', 'accept', 'în așteptare', 'marcat',
    // hu
    'sorba ', 'javasol', 'elfogad', 'függő', 'várakoz', 'megjelöl',
    // cs
    've frontě', 'navržen', 'přijat', 'přijmout', 'čeká', 'označen'];

  QUEUE_CLAIMS_CJK: TArray<string> = [
    // ja
    '提案', '承認', '受け入れ', '適用', '保留', 'キュー',
    // zh-CN / zh-TW
    '排队', '排隊', '提议', '提議', '接受', '待处理', '待處理'];

function IsLatinMark(C: Char): Boolean;
begin
  Result := (Ord(C) >= $0300) and (Ord(C) <= $036F);
end;

function StripMarks(const S: string): string;
var
  N, I, J: Integer;
  Buf: string;
begin
  Result := S;
  if S = '' then Exit;
  { MAP_COMPOSITE splits "é" into "e" + combining accent; the Latin accents are then dropped. }
  N := FoldStringW(MAP_COMPOSITE, PChar(S), Length(S), nil, 0);
  if N <= 0 then Exit;
  SetLength(Buf, N);
  N := FoldStringW(MAP_COMPOSITE, PChar(S), Length(S), PChar(Buf), N);
  if N <= 0 then Exit;
  SetLength(Result, N);
  J := 0;
  for I := 1 to N do
    if not IsLatinMark(Buf[I]) then
    begin
      Inc(J);
      Result[J] := Buf[I];
    end;
  SetLength(Result, J);
end;

function AgentFoldText(const S: string): string;
var
  I: Integer;
  T: string;
begin
  T := StripMarks(AnsiLowerCase(S));
  { No decomposition for these. }
  T := StringReplace(T, 'ł', 'l', [rfReplaceAll]);
  T := StringReplace(T, 'ß', 'ss', [rfReplaceAll]);
  { Other combining marks (Japanese voicing marks after MAP_COMPOSITE) stay: they are part of the word. }
  for I := 1 to Length(T) do
    if not (T[I].IsLetterOrDigit or (T[I].GetUnicodeCategory in
      [TUnicodeCategory.ucNonSpacingMark, TUnicodeCategory.ucCombiningMark])) then
      T[I] := ' ';
  while Pos('  ', T) > 0 do
    T := StringReplace(T, '  ', ' ', [rfReplaceAll]);
  Result := ' ' + Trim(T) + ' ';
end;

{ Words: whole-word test on the folded text. CJK: substring test (no spaces between words). }
function HasPhrase(const AFolded: string; const AWords: TArray<string>; ACJK: Boolean): Boolean;
var
  W: string;
begin
  for W in AWords do
    if ACJK then
    begin
      if Pos(Trim(AgentFoldText(W)), AFolded) > 0 then
        Exit(True);
    end
    else if Pos(AgentFoldText(W), AFolded) > 0 then
      Exit(True);
  Result := False;
end;

function AgentWantsExactMatch(const APrompt: string): Boolean;
var
  L: string;
begin
  L := AgentFoldText(APrompt);
  if HasPhrase(L, NOT_PARTIAL, False) or HasPhrase(L, NOT_PARTIAL_CJK, True) then
    Exit(True);
  if HasPhrase(L, PARTIAL, False) or HasPhrase(L, PARTIAL_CJK, True) then
    Exit(False);
  Result := HasPhrase(L, EXACT, False) or HasPhrase(L, EXACT_CJK, True);
end;

{ Word stems on the folded text: a stem written with a trailing space must end the word there. }
function HasStem(const AFolded: string; const AStems: TArray<string>; ACJK: Boolean): Boolean;
var
  W, F: string;
begin
  for W in AStems do
  begin
    F := AgentFoldText(W);
    if ACJK then
      F := Trim(F)
    else if (W <> '') and (W[Length(W)] <> ' ') then
      F := TrimRight(F);
    if (F <> '') and (Pos(F, AFolded) > 0) then
      Exit(True);
  end;
  Result := False;
end;

function AgentAnswerPromisesWork(const S: string): Boolean;
var
  L: string;
begin
  L := AgentFoldText(S);
  Result := HasStem(L, PROMISES, False) or HasStem(L, PROMISES_CJK, True);
end;

function AgentAnswerClaimsWork(const S: string): Boolean;
var
  L: string;
begin
  L := AgentFoldText(S);
  Result := HasStem(L, CLAIMS, False) or HasStem(L, CLAIMS_CJK, True);
end;

function AgentAnswerClaimsQueue(const S: string): Boolean;
var
  L: string;
begin
  L := AgentFoldText(S);
  Result := HasStem(L, QUEUE_CLAIMS, False) or HasStem(L, QUEUE_CLAIMS_CJK, True);
end;

end.
