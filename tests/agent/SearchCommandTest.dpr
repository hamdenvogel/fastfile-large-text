program SearchCommandTest;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, IOUtils, uSearchCommands, uI18n, uAgentProtocol;

procedure Check(Ok: Boolean; const Name: string);
begin
  if not Ok then raise Exception.Create(Name);
end;

procedure Bad(const S: string);
begin
  try
    ParseSearchCommand(S);
  except
    on E: ESearchCommand do Exit;
  end;
  raise Exception.Create('accepted: ' + S);
end;

procedure BadAdvice(const S: string);
begin
  try
    ParseSearchCommandAdvice(S);
  except
    on E: ESearchCommand do Exit;
  end;
  raise Exception.Create('accepted AI reply: ' + S);
end;

var
  C: TSearchCommand;
  M: TSearchMatcher;
  F: TStringList;
  R: TSearchResult;
  Dir, Path: string;
  Cancel: Integer;
  Language: TAppLanguage;
  Turn: TAgentTurn;
  Key: string;
  English: TStringList;
  Advice: TSearchCommandAdvice;
  Stream: TFileStream;
  BytesReturned: DWORD;
  Bytes: TBytes;
  Started: UInt64;
  Canceller: TThread;
const
  Keys: array[0..37] of string = ('Queued', 'Hint', 'Quotes', 'Option', 'Limit',
    'Arguments', 'Pattern', 'Regex', 'Read', 'Failed', 'Results', 'Partial',
    'Stopped', 'Mark', 'Marked', 'Index', 'NoSources', 'Scanning', 'Help',
    'AIRequest', 'AIGenerate', 'AISuggestions', 'Run', 'AIReview', 'AIPrivacy',
    'AIWaiting', 'AIStopping', 'AIInvalid', 'LaunchHint', 'LaunchQueued', 'BookmarkUnavailable',
    'OutsideSources', 'LongLine', 'FileHelp', 'LargeHelp', 'WorkflowHelp',
    'GroupColumns', 'File');
begin
  try
    English := TStringList.Create;
    try
      SetCurrentLanguage(alEnglish);
      for Key in Keys do
      begin
        Check(TrText('SearchCmd.' + Key) <> 'SearchCmd.' + Key, 'English ' + Key);
        English.Add(TrText('SearchCmd.' + Key));
      end;
      for Language := Succ(alEnglish) to High(TAppLanguage) do
      begin
        SetCurrentLanguage(Language);
        for Cancel := Low(Keys) to High(Keys) do
          Check((TrText('SearchCmd.' + Keys[Cancel]) <> English[Cancel]) and
            (TrText('SearchCmd.' + Keys[Cancel]) <> 'SearchCmd.' + Keys[Cancel]),
            AppLanguageCode(Language) + ' ' + Keys[Cancel]);
      end;
      SetCurrentLanguage(alEnglish);
      Writeln('PASS: 38 translation keys in all 14 languages');
    finally
      English.Free;
    end;
    Advice := ParseSearchCommandAdvice('{"command":"grep -i -F \"error\" --glob \"*.log\"",' +
      '"explanation":"Search log content.","suggestions":["glob \"*.log\"","grep --bookmarks -F \"error\""]}');
    Check((Advice.Command = 'grep -i -F "error" --glob "*.log"') and
      (Length(Advice.Suggestions) = 2), 'AI advice preserves full commands');
    Advice := ParseSearchCommandAdvice('{"command":"","explanation":"Which text?","suggestions":[]}');
    Check((Advice.Command = '') and (Advice.Explanation = 'Which text?'), 'AI clarification, no invented command');
    BadAdvice('not JSON');
    BadAdvice('[]');
    BadAdvice('{"command":"cmd /c dir","explanation":"x","suggestions":[]}');
    BadAdvice('{"command":"grep -z x","explanation":"x","suggestions":[]}');
    BadAdvice('{"command":"grep -E \"[\"","explanation":"x","suggestions":[]}');
    BadAdvice('{"command":"grep x\nwhoami","explanation":"x","suggestions":[]}');
    BadAdvice('{"command":"grep x","explanation":"","suggestions":[]}');
    BadAdvice('{"command":"grep x","explanation":"x","suggestions":["del *"]}');
    BadAdvice('{"command":"grep x","explanation":"x","suggestions":[1]}');
    BadAdvice('{"command":"grep x","explanation":"x","suggestions":["grep a","grep b","grep c","grep d"]}');
    Key := SearchCommandPrompt('encontre "erro" nos logs', 'grep --help', 'pt-BR');
    Check((Pos('response_language', Key) > 0) and (Pos('pt-BR', Key) > 0) and
      (Pos('backslashes are literal', Key) > 0) and (Pos('LITERAL by default', Key) > 0) and
      (Pos('--bookmarks', Key) > 0) and (Pos('Do not execute anything', Key) > 0),
      'AI dialect and locale contract');
    Writeln('PASS: AI command advice, validation and clarification');
    Turn := ParseAgentTurn('{"tool":"search_command","command":"grep -i \"error\" --glob \"**\\*.log\""}');
    Check((Turn.Tool = atkCommand) and
      (Turn.Command = 'grep -i "error" --glob "**\*.log"'), 'AI command JSON');
    Turn := ParseAgentTurn('{"tool":{"name":"search_command","arguments":{"command":"glob \"*.csv\""}}}');
    Check((Turn.Tool = atkCommand) and (Turn.Command = 'glob "*.csv"'), 'nested AI command');
    C := ParseSearchCommand('ordinary * text');
    Check(C.Kind = sckText, 'plain preserved');
    C := ParseSearchCommand('  GrEp '#9);
    Check((C.Kind = sckGrep) and C.Help and (C.Pattern = '') and
      IsSearchCommandLauncher('  GrEp '#9), 'bare grep opens help');
    C := ParseSearchCommand('glob');
    Check((C.Kind = sckGlob) and C.Help and IsSearchCommandLauncher('glob'),
      'bare glob opens help');
    Check(not IsSearchCommandLauncher('grep -i') and not IsSearchCommand('grepper'),
      'only exact command names launch');
    C := ParseSearchCommand('grep -inE "error|failure" --glob "**\*.log" --limit 100');
    Check((C.Kind = sckGrep) and C.IgnoreCase and C.Regex and
      (C.Pattern = 'error|failure') and (C.FileGlob = '**\*.log') and (C.Limit = 100), 'parse');
    C := ParseSearchCommand('grep -F ''C:\temp\foo''');
    Check(C.Pattern = 'C:\temp\foo', 'backslashes');
    C := ParseSearchCommand('grep -- "-i"');
    Check(C.Pattern = '-i', 'end options');
    Check(SearchGlobMatches('C:\logs\a.log', '**\*.log'), 'root log');
    Check(SearchGlobMatches('C:\logs\sub\a.LOG', '**\*.log'), 'nested log');
    Check(SearchGlobMatches('C:\logs\report_2026.csv', 'report_202?.csv'), 'question');
    Check(not SearchGlobMatches('C:\logs\report_20266.csv', 'report_202?.csv'), 'one char');
    Check(not SearchGlobMatches('C:\logs\sub\a.log', 'logs\*.log'), 'star excludes separator');
    Check(SearchGlobMatches('C:\logs\a.log', 'logs\**\*.log'), 'globstar zero dirs');
    Check(SearchGlobMatches('C:\logs\sub\a.log', 'logs\**\*.log'), 'globstar many dirs');
    Check(not SearchGlobMatches('C:\logs\a.txt', '*.log'), 'extension');
    Bad('grep "unterminated');
    Bad('grep -z text');
    Bad('grep --limit 10001 text');
    Bad('grep --limit nope text');
    C := ParseSearchCommand('grep "casa" "C:\temp\large file.txt"');
    Check((C.Pattern = 'casa') and (C.FilePath = 'C:\temp\large file.txt'), 'optional quoted file');
    C := ParseSearchCommand('glob "*.txt" file.txt');
    Check(C.FilePath = 'file.txt', 'glob optional file');
    Bad('grep one two three');
    Bad('grep one ""');
    Bad('grep one "bad'#0'file"');
    Bad('glob --mark "*.log"');
    Bad('grep -i');
    Bad('glob --limit 500');
    Bad('grep ""');
    Bad('grep --glob "" x');
    Bad('grep -E "a'#0'b"');
    C := ParseSearchCommand('grep -iw "Maria"');
    M := TSearchMatcher.Create(C);
    try
      Check(M.Matches('MARIA Silva'), 'whole ignore');
      Check(not M.Matches('Mariana'), 'whole boundary');
    finally
      M.Free;
    end;
    C := ParseSearchCommand('grep -E "["');
    try
      M := TSearchMatcher.Create(C);
      M.Free;
      raise Exception.Create('invalid regex accepted');
    except
      on E: ESearchCommand do ;
    end;
    Dir := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName);
    ForceDirectories(Dir);
    Path := TPath.Combine(Dir, 'sample.log');
    F := TStringList.Create;
    try
      F.Add(Path);
      TFile.WriteAllText(Path, 'error'#13#10#13#10'FAILURE'#13#10'DEBUG'#13#10'error', TEncoding.UTF8);
      Cancel := 0;
      C := ParseSearchCommand('grep -iE "error|failure"');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 3) and (R.Hits[1].Line = 3) and (R.Hits[2].Line = 5), 'scan physical lines');
      C := ParseSearchCommand('grep "error" "' + Path + '"');
      R := RunSearchCommand(F, C, @Cancel);
      Check(Length(R.Hits) = 2, 'explicit authorized file');
      C.FilePath := TPath.Combine(Dir, 'outside.txt');
      try
        R := RunSearchCommand(F, C, @Cancel);
        raise Exception.Create('explicit file bypassed authorized sources');
      except
        on E: ESearchCommand do
          Check(Pos('outside.txt', E.Message) > 0, 'unauthorized file reported');
      end;
      Check(ValidateSearchFile(Path) = Path, 'readable regular file validation');
      try
        ValidateSearchFile(Dir);
        raise Exception.Create('directory accepted as file operand');
      except
        on E: ESearchCommand do ;
      end;
      C := ParseSearchCommand('grep -E "^$"');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and (R.Hits[0].Line = 2), 'empty line');
      TFile.WriteAllText(Path, '10.1.1.1 ok 200'#13#10'nope'#13#10'10.2.2.2 bad 404', TEncoding.UTF8);
      C := ParseSearchCommand('grep -E "(?<ip>\d+\.\d+\.\d+\.\d+).*(?<status>\d{3})"');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.GroupNames) = 2) and (R.GroupNames[0] = 'ip') and
        (R.GroupNames[1] = 'status') and (Length(R.Hits) = 2) and
        (R.Hits[0].GroupValues[0] = '10.1.1.1') and (R.Hits[0].GroupValues[1] = '200') and
        (R.Hits[1].GroupValues[1] = '404'), 'named groups');
      Check(Pos('groups=ip'#9'status', SearchResultText(R)) > 0, 'group table text');
      TFile.WriteAllText(Path, 'error'#13#10#13#10'FAILURE'#13#10'DEBUG'#13#10'error', TEncoding.UTF8);
      C := ParseSearchCommand('grep -iE "error|failure" --limit 1');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and R.Partial, 'bounded');
      C := ParseSearchCommand('grep -iE "error|failure" --bookmarks');
      R := RunSearchCommand(F, C, @Cancel, Path, TArray<Int64>.Create(3));
      Check((Length(R.Hits) = 1) and (R.Hits[0].Line = 3), 'bookmarked only');
      R := RunSearchCommand(F, C, @Cancel, '', nil);
      Check(Length(R.Hits) = 0, 'no marks no results');
      C := ParseSearchCommand('grep -v -F "error"');
      R := RunSearchCommand(F, C, @Cancel);
      Check(Length(R.Hits) = 3, 'invert includes empty');
      TFile.WriteAllText(Path, 'error'#13#10'FAILURE'#13#10'error', TEncoding.Unicode);
      C := ParseSearchCommand('grep -iE "error|failure"');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 3) and (R.Hits[2].Line = 3), 'utf16le');
      TFile.WriteAllText(Path, #$4E0A#$010A' error'#13#10'FAILURE', TEncoding.Unicode);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 2) and (R.Hits[1].Line = 2), 'utf16 low byte 0A is not newline');
      TFile.WriteAllText(Path, #$4E0A' error'#13#10'FAILURE', TEncoding.BigEndianUnicode);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 2) and (R.Hits[1].Line = 2), 'utf16be');
      TFile.WriteAllBytes(Path, TBytes.Create($FF, $FE, 0, 0, $65, 0, 0, 0, $0A, 0, 0, 0));
      try
        R := RunSearchCommand(F, C, @Cancel);
        raise Exception.Create('UTF-32 silently searched with the wrong encoding');
      except
        on E: ESearchCommand do ;
      end;
      TFile.WriteAllText(Path, StringOfChar('x', 1024 * 1024 + 1) + 'error'#10'error', TEncoding.UTF8);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 2) and (R.Hits[1].Line = 2) and
        (Length(R.Hits[0].Text) = 403), 'buffer boundary and preview bound');
      TFile.WriteAllText(Path, StringOfChar('x', 65535) + #13#10'error'#13#10'error'#10, TEncoding.ASCII);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 2) and (R.Hits[0].Line = 2) and
        (R.Hits[1].Line = 3), 'CRLF across decoded block boundary, trailing newline');
      TFile.WriteAllText(Path, StringOfChar('x', 16 * 1024 * 1024) + #10'error', TEncoding.ASCII);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and (R.Hits[0].Line = 2), 'exact maximum line accepted');
      TFile.WriteAllText(Path, StringOfChar('x', 16 * 1024 * 1024 + 1), TEncoding.ASCII);
      try
        R := RunSearchCommand(F, C, @Cancel);
        raise Exception.Create('unbounded line accepted');
      except
        on E: ESearchCommand do
          Check(Pos('16777216', E.Message) > 0, 'explicit line capacity error');
      end;
      Stream := TFileStream.Create(Path, fmCreate);
      try
        Check(DeviceIoControl(Stream.Handle, $000900C4, nil, 0, nil, 0,
          BytesReturned, nil), 'filesystem must support sparse capacity test');
        Stream.Size := Int64(80) * 1024 * 1024 * 1024;
        Stream.Position := 0;
        Bytes := TEncoding.UTF8.GetBytes('error'#13#10);
        Stream.WriteBuffer(Bytes[0], Length(Bytes));
        Stream.Position := Stream.Size - Length(Bytes);
        Stream.WriteBuffer(Bytes[0], Length(Bytes));
        Check(Stream.Position = Int64(80) * 1024 * 1024 * 1024, '80 GiB 64-bit file offsets');
      finally
        Stream.Free;
      end;
      Started := GetTickCount64;
      C := ParseSearchCommand('glob "*.log" "' + Path + '"');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and (GetTickCount64 - Started < 2000), '80 GiB glob metadata only');
      C := ParseSearchCommand('grep "error" "' + Path + '" --limit 1');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and R.Partial and
        (GetTickCount64 - Started < 2000), '80 GiB grep stops at first requested hit');
      C := ParseSearchCommand('grep "not-in-sparse-file"');
      Canceller := TThread.CreateAnonymousThread(
        procedure
        begin
          Sleep(1);
          InterlockedExchange(Cancel, 1);
        end);
      Canceller.FreeOnTerminate := False;
      try
        Started := GetTickCount64;
        Canceller.Start;
        R := RunSearchCommand(F, C, @Cancel);
        Check(R.Cancelled and (GetTickCount64 - Started < 2000), '80 GiB cooperative cancellation');
      finally
        Canceller.WaitFor;
        Canceller.Free;
        Cancel := 0;
      end;
      Writeln('PASS: 80 GiB sparse metadata, 64-bit offsets, early hit cap and cancellation (not a full traversal)');
      TFile.WriteAllText(Path, StringOfChar('a', 2000) + '!', TEncoding.UTF8);
      C := ParseSearchCommand('grep -E "^(a+)+$"');
      try
        R := RunSearchCommand(F, C, @Cancel);
        raise Exception.Create('regex work limit silently returned no match');
      except
        on E: ESearchCommand do ;
      end;
      C := ParseSearchCommand('glob "C:\outside\*.log"');
      R := RunSearchCommand(F, C, @Cancel);
      Check(Length(R.Hits) = 0, 'glob never expands outside selection');
      C := ParseSearchCommand('glob "*.log" --limit 1');
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 1) and not R.Partial and (R.Hits[0].Line = 0), 'glob exact limit');
      C := ParseSearchCommand('grep "error"');
      Cancel := 1;
      R := RunSearchCommand(F, C, @Cancel);
      Check(R.Cancelled and (Length(R.Hits) = 0), 'cancel');
      Cancel := 0;
      TFile.WriteAllText(Path, 'error'#13'DEBUG'#13'error', TEncoding.UTF8);
      R := RunSearchCommand(F, C, @Cancel);
      Check((Length(R.Hits) = 2) and (R.Hits[1].Line = 3), 'CR only');
      DeleteFile(Path);
      try
        R := RunSearchCommand(F, C, @Cancel);
        raise Exception.Create('missing file silently accepted');
      except
        on E: EFOpenError do ;
      end;
    finally
      F.Free;
      DeleteFile(Path);
      RemoveDir(Dir);
    end;
    Writeln('PASS: search commands');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
