# -*- coding: utf-8 -*-
"""Split AddCommonTranslationsUndoSearchSession into Part1 and Part2."""
from pathlib import Path
import re

PATH = Path(__file__).resolve().parents[1] / 'uI18n.pas'
PROC = 'procedure AddCommonTranslationsUndoSearchSession;'
HEADER = """  procedure Set11(const K: string;
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
"""


def find_set11_positions(seg: str) -> list[int]:
    return [m.start() for m in re.finditer(r"\n  Set11\('", seg)]


def main() -> None:
    text = PATH.read_text(encoding='utf-8')
    if 'AddCommonTranslationsUndoSearchSessionPart1' in text:
        print('Already split')
        return

    a = text.find(PROC)
    nxt = text.find('\nprocedure AddCommonTranslations;', a)
    seg = text[a:nxt]
    positions = find_set11_positions(seg)
    if len(positions) < 4:
        raise SystemExit('Too few Set11 calls')
    mid = len(positions) // 2
    split_at = positions[mid]

    head = seg[: seg.find('begin') + len('begin')]
    body = seg[seg.find('begin') + len('begin') : seg.rfind('end;')]
    part1_body = body[:split_at]
    part2_body = body[split_at:]

    part1 = (
        'procedure AddCommonTranslationsUndoSearchSessionPart1;\n'
        + HEADER
        + 'begin\n'
        + part1_body
        + 'end;\n\n'
    )
    part2 = (
        'procedure AddCommonTranslationsUndoSearchSessionPart2;\n'
        + HEADER
        + 'begin\n'
        + part2_body
        + 'end;\n\n'
    )
    wrapper = (
        'procedure AddCommonTranslationsUndoSearchSession;\n'
        + 'begin\n'
        + '  AddCommonTranslationsUndoSearchSessionPart1;\n'
        + '  AddCommonTranslationsUndoSearchSessionPart2;\n'
        + 'end;\n\n'
    )

    text = text[:a] + part1 + part2 + wrapper + text[nxt + 1 :]
    PATH.write_text(text, encoding='utf-8', newline='\r\n')
    print('Split at Set11 index', mid, 'of', len(positions))


if __name__ == '__main__':
    main()
