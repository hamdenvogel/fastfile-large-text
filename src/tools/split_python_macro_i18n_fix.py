# -*- coding: utf-8 -*-
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / 'uI18n.pas'
MARK_START = "  Set11('Tail macro examples intro',"
MARK_END = "    'Pouzit v editoru');"
PROC_EXAMPLES = 'procedure AddCommonTranslationsPythonMacroExamples;'
PROC_UNDO = 'procedure AddCommonTranslationsUndoSearchSession;'
EMPTY_BEGIN = "begin\n\nend;\n\nprocedure AddCommonTranslationsUndoSearchSession;"


def extract_block(text: str, after: str) -> tuple[str, int, int]:
    pos = text.find(after)
    if pos < 0:
        raise SystemExit(f'Anchor not found: {after!r}')
    start = text.find(MARK_START, pos)
    end = text.find(MARK_END, start)
    if start < 0 or end < 0:
        raise SystemExit('Block markers not found after anchor')
    end += len(MARK_END)
    return text[start:end], start, end


def main() -> None:
    text = PATH.read_text(encoding='utf-8')
    block, start, end = extract_block(text, PROC_UNDO)

    empty = "procedure AddCommonTranslationsPythonMacroExamples;\n  procedure Set11"
    if EMPTY_BEGIN in text:
        # fill empty procedure body
        proc_start = text.find(PROC_EXAMPLES)
        body_begin = text.find('begin', proc_start)
        body_end = text.find('end;', body_begin)
        text = text[:body_begin + 5] + '\n' + block + '\n' + text[body_end:]
        # re-find block in undo (line numbers shifted)
        _, start, end = extract_block(text, PROC_UNDO)
        text = text[:start] + text[end:]
    else:
        raise SystemExit('Unexpected file state')

    PATH.write_text(text, encoding='utf-8', newline='\r\n')
    print('Fixed: moved', block.count('\n'), 'lines into PythonMacroExamples')


if __name__ == '__main__':
    main()
