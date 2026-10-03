from pathlib import Path
import re

text = (Path(__file__).resolve().parents[1] / 'uI18n.pas').read_text(encoding='utf-8')
for name in [
    'AddCommonTranslationsPythonMacroExamples',
    'AddCommonTranslationsUndoSearchSessionPart1',
    'AddCommonTranslationsUndoSearchSessionPart2',
]:
    a = text.find('procedure ' + name + ';')
    nxt = text.find('\nprocedure ', a + 10)
    seg = text[a:nxt]
    print(name, seg.count("Set11('"))
