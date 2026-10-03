# -*- coding: utf-8 -*-
"""Move Python macro example Set11 block out of AddCommonTranslationsUndoSearchSession."""
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / 'uI18n.pas'
MARK_START = "  Set11('Tail macro examples intro',"
MARK_END = "    'Pouzit v editoru');"
NEW_PROC_HEADER = """procedure AddCommonTranslationsPythonMacroExamples;
  procedure Set11(const K: string;
    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);
  begin
    GTextEnglish.Values[K] := EN;
    GTextPortuguese.Values[K] := PT;
    GTextSpanish.Values[K] := ES;
    GTextFrench.Values[K] := FR;
    GTextGerman.Values[K] := DE;
    GTextItalian.Values[K] := IT;
    GTextPolish.Values[K] := PL;
    GTextPortuguesePT.Values[K] := PTPT;
    GTextRomanian.Values[K] := RO;
    GTextHungarian.Values[K] := HU;
    GTextCzech.Values[K] := CZ;
  end;
begin
"""
CALL_LINE = "  AddCommonTranslationsPythonMacroExamples;\n"


def main() -> None:
    text = PATH.read_text(encoding='utf-8')
    if 'procedure AddCommonTranslationsPythonMacroExamples;' in text:
        print('Already split')
        return

    start = text.find(MARK_START)
    end = text.find(MARK_END, start)
    if start < 0 or end < 0:
        raise SystemExit('Markers not found')
    end += len(MARK_END)

    block = text[start:end]
    if not block.strip():
        raise SystemExit('Empty block')

    new_proc = NEW_PROC_HEADER + block + '\nend;\n\n'
    insert_after = 'end;\n\nprocedure AddCommonTranslationsUndoSearchSession;'
    if insert_after not in text:
        raise SystemExit('Insert anchor not found')
    text = text.replace(insert_after, 'end;\n\n' + new_proc + 'procedure AddCommonTranslationsUndoSearchSession;', 1)

    # remove block from UndoSearchSession (re-find after insert)
    start2 = text.find(MARK_START)
    end2 = text.find(MARK_END, start2)
    if start2 < 0 or end2 < 0:
        raise SystemExit('Block still missing after insert?')
    end2 += len(MARK_END)
    text = text[:start2] + text[end2:]

    call_anchor = '  AddCommonTranslationsPythonMacroAI;\n  AddCommonTranslationsUndoSearchSession;'
    if call_anchor not in text:
        raise SystemExit('Call anchor not found')
    text = text.replace(
        call_anchor,
        '  AddCommonTranslationsPythonMacroAI;\n' + CALL_LINE + '  AddCommonTranslationsUndoSearchSession;',
        1,
    )

    PATH.write_text(text, encoding='utf-8', newline='\r\n')
    print('Split OK, block lines:', block.count('\n'))


if __name__ == '__main__':
    main()
