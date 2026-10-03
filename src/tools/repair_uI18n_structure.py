# -*- coding: utf-8 -*-
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / 'uI18n.pas'
SET11_IMPL = """    GTextEnglish.Values[K] := EN;
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
"""

BROKEN_FROM_LINE = """    'Od wiersza:end;

procedure AddCommonTranslationsUndoSearchSessionPart2;
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
',
    'Da linha:',
    'De la linia:',
    'Sortol:',
    'Od radku:');"""

FIXED_FROM_LINE = """    'Od wiersza:',
    'Da linha:',
    'De la linia:',
    'Sortol:',
    'Od radku:');
end;

procedure AddCommonTranslationsUndoSearchSessionPart2;
  procedure Set11(const K: string;
    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);
  begin
""" + SET11_IMPL + """  end;
begin
"""


def main() -> None:
    text = PATH.read_text(encoding='utf-8')

    # 1) PythonMacroExamples: nested Set11 missing body
    bad = (
        "procedure AddCommonTranslationsPythonMacroExamples;\n"
        "  procedure Set11(const K: string;\n"
        "    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);\n"
        "  begin\n"
        "  Set11('Tail macro examples intro',"
    )
    good = (
        "procedure AddCommonTranslationsPythonMacroExamples;\n"
        "  procedure Set11(const K: string;\n"
        "    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);\n"
        "  begin\n"
        + SET11_IMPL
        + "  end;\n"
        "begin\n"
        "  Set11('Tail macro examples intro',"
    )
    if bad not in text:
        raise SystemExit('PythonMacroExamples pattern not found')
    text = text.replace(bad, good, 1)

    # 2) orphan begin/end after PythonMacroExamples
    text = text.replace(
        "    'Pouzit v editoru');\nend;\nbegin\n\nend;\n\nprocedure AddCommonTranslationsUndoSearchSessionPart1;",
        "    'Pouzit v editoru');\nend;\n\nprocedure AddCommonTranslationsUndoSearchSessionPart1;",
        1,
    )

    # 3) Part1 duplicate Set11 body before Nothing to undo
    garbage = (
        "begin\n\n"
        + SET11_IMPL
        + "  end;\nbegin\n"
        "  Set11('Nothing to undo',"
    )
    fixed = "begin\n  Set11('Nothing to undo',"
    if garbage not in text:
        raise SystemExit('Part1 garbage block not found')
    text = text.replace(garbage, fixed, 1)

    # 4) Part1/Part2 split corruption at From line
    if BROKEN_FROM_LINE not in text:
        raise SystemExit('From line break not found')
    text = text.replace(BROKEN_FROM_LINE, FIXED_FROM_LINE, 1)

    PATH.write_text(text, encoding='utf-8', newline='\r\n')
    print('Repair OK')


if __name__ == '__main__':
    main()
