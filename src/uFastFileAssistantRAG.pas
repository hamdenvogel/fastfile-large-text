unit uFastFileAssistantRAG;

{
  Lightweight operational help snippets for the assistant prompt (no source code).
  Keyword match on the user question; capped size to limit Lambda payload.
}

interface

function BuildAssistantHelpRAG(const UserQuestion: string): string;

implementation

uses
  SysUtils, uPosBMH, uFastFileAssistantMap;

const
  RAG_MAX_CHARS = 1800;

function ContainsAny(const S, Sub: string): Boolean;
begin
  Result := ContainsBMHCi(Sub, S);
end;

function BuildAssistantHelpRAG(const UserQuestion: string): string;
var
  SB: string;
  Q: string;
  Any: Boolean;
begin
  Result := '';
  Q := Trim(UserQuestion);
  if Q = '' then Exit;
  SB := BuildCapabilityMapRAG(UserQuestion);
  Any := SB <> '';

  if ContainsAny(Q, 'split') or ContainsAny(Q, 'divid') or ContainsAny(Q, 'part') or
     ContainsAny(Q, 'teile') or ContainsAny(Q, 'parti') then
  begin
    Any := True;
    SB := SB +
      '[SPLIT] Ctrl+Shift+P: split file into equal LF-safe parts (Tools > Split/merge).' + #13#10 +
      'Ctrl+Shift+Q: extract a subset of parts (e.g. parts 2-4 of 10) without re-splitting the whole file.' + #13#10 +
      'Large files: progress dialog; disk space check before write.' + #13#10;
  end;

  if ContainsAny(Q, 'tail') or ContainsAny(Q, 'follow') or ContainsAny(Q, 'monitor') then
  begin
    Any := True;
    SB := SB +
      '[TAIL] Ctrl+T: Tail/Follow mode (live append like tail -f). Ctrl+Shift+T: pause/resume.' + #13#10 +
      'Ctrl+Shift+L: export tail session lines. Tail macro (Python) is under Tools > Tail.' + #13#10;
  end;

  if ContainsAny(Q, 'find') or ContainsAny(Q, 'search') or ContainsAny(Q, 'replace') or
     ContainsAny(Q, 'localiz') or ContainsAny(Q, 'buscar') or ContainsAny(Q, 'procur') then
  begin
    Any := True;
    SB := SB +
      '[FIND] With search words: execute find_text (first match, case_insensitive default), NOT open_find only.' + #13#10 +
      'Ctrl+F find; F3 next; Shift+F3 previous; Esc cancels in-flight find.' + #13#10 +
      'Ctrl+Shift+F: Find in Files. Zero Scan: may need index build before line-accurate find.' + #13#10;
  end;

  if ContainsAny(Q, 'linha') or ContainsAny(Q, 'line') or ContainsAny(Q, 'goto') or
     ContainsAny(Q, 'ir para') then
  begin
    Any := True;
    SB := SB +
      '[GOTO] "ir para linha N" -> execute goto_line line_no=N (Ctrl+G, ListView scroll+select).' + #13#10 +
      '"editar linha N" -> execute edit_line line_no=N (goto + line editor modal).' + #13#10;
  end;

  if ContainsAny(Q, 'zero') or ContainsAny(Q, 'huge') or ContainsAny(Q, 'gb') or ContainsAny(Q, 'instant') then
  begin
    Any := True;
    SB := SB +
      '[ZERO SCAN] View > Force Zero Scan or very large files: instant open without full index.' + #13#10 +
      'Ctrl+G physical line; Shift+End last line; Ctrl+Shift+Q extract parts still LF-safe.' + #13#10 +
      'F1 help and DOC_ZS_ATALHOS.md describe full shortcut matrix.' + #13#10;
  end;

  if ContainsAny(Q, 'consumer') or ContainsAny(Q, 'sql') or ContainsAny(Q, 'rag') or
     ContainsAny(Q, 'chat') and ContainsAny(Q, 'ai') then
  begin
    Any := True;
    SB := SB +
      '[CONSUMER AI] SQL and file-content questions stay in this Assistant (Ctrl+Alt+A); Python engines run in the background.' + #13#10;
  end;

  if ContainsAny(Q, 'compare') or ContainsAny(Q, 'merge') or ContainsAny(Q, 'diff') then
  begin
    Any := True;
    SB := SB +
      '[COMPARE] Ctrl+Shift+H: Compare/merge + session history tab (two-file diff).' + #13#10 +
      'Ctrl+Shift+M merge lines; Ctrl+Shift+J merge files.' + #13#10;
  end;

  if ContainsAny(Q, 'assistant') or ContainsAny(Q, 'ai menu') or ContainsAny(Q, 'help') or
     ContainsAny(Q, 'ajuda') or ContainsAny(Q, 'f1') then
  begin
    Any := True;
    SB := SB +
      '[ASSISTANT] AI menu > What would you like to do? — operational help and safe actions.' + #13#10 +
      'F1: full shortcuts. Startup assistant optional (ASkin.ini AssistantShowOnStartup).' + #13#10;
  end;

  if ContainsAny(Q, 'export') or ContainsAny(Q, 'guardar') or ContainsAny(Q, 'save') or
     ContainsAny(Q, 'gerar') or ContainsAny(Q, 'criar') or ContainsAny(Q, 'somente') then
  begin
    Any := True;
    SB := SB +
      '[EXPORT] Ctrl+Shift+O export file; export_lines (range e.g. 500-1000); ' +
      'gerar/criar um novo arquivo com linhas entre N a M (inclusive) = export_lines + path; ' +
      'export_matching_lines (text); Ctrl+Shift+L export tail/filtered.' + #13#10 +
      '[REPLACE] replace_all find+replace runs streaming Replace All; Ctrl+H opens dialog.' + #13#10;
  end;

  if ContainsAny(Q, 'filter') or ContainsAny(Q, 'grep') or ContainsAny(Q, 'filtr') then
  begin
    Any := True;
    SB := SB +
      '[FILTER] Ctrl+L filter/grep; Esc clears filter when active. apply_filter needs filter_text.' + #13#10;
  end;

  if ContainsAny(Q, 'duplicate') or ContainsAny(Q, 'dedup') or ContainsAny(Q, 'frequent') or
     ContainsAny(Q, 'string') then
  begin
    Any := True;
    SB := SB +
      '[TOOLS] Tools > Filter and analysis: Extract Frequent Strings; Delete Duplicate Lines.' + #13#10 +
      'View > Character Code Value for selected line. Disk space confirmed before rewrite.' + #13#10;
  end;

  if ContainsAny(Q, 'read') or ContainsAny(Q, 'open') or ContainsAny(Q, 'load') or ContainsAny(Q, 'f5') then
  begin
    Any := True;
    SB := SB +
      '[READ] With a full path in the question: assistant must execute open_and_read_file (FastFile F5), not explain only.' + #13#10 +
      'Ctrl+O open; F5 Read/load on Read tab; Ctrl+1 show Read tab; Ctrl+R recent files; drag-drop.' + #13#10 +
      'Without path: explain Ctrl+O/F5 OR execute show_tab_read for "open load file screen".' + #13#10;
  end;

  if ContainsAny(Q, 'atalho') or ContainsAny(Q, 'shortcut') or ContainsAny(Q, 'ctrl+') or
     ContainsAny(Q, 'f5') or ContainsAny(Q, 'f3') or ContainsAny(Q, 'zero scan') then
  begin
    Any := True;
    SB := SB +
      '[SECURITY] Never map to execute for OS/shell/format disk/run .exe/malware; intent=unknown + short refusal. App whitelist only — no ShellExecute.' + #13#10 +
      '[SHORTCUTS] Full action catalog in prompt (DOC_ZS_ATALHOS): return intent=execute with action id; app runs real command.' + #13#10 +
      'Examples: find_text, goto_line, edit_line, find_next, goto_file_end, apply_filter, start_tail.' + #13#10;
  end;

  if not Any then
    Exit;

  Result := 'HELP_SNIPPETS (operational, from F1 topics — no source):' + #13#10 + SB;
  if Length(Result) > RAG_MAX_CHARS then
    SetLength(Result, RAG_MAX_CHARS);
end;

end.
