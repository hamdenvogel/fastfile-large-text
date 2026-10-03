# -*- coding: utf-8 -*-
"""Fix U+FFFD mojibake in MainUnit.pas and wire Python examples to TrText."""
from pathlib import Path
import re

PATH = Path(__file__).resolve().parents[1] / 'MainUnit.pas'
REPL = '\ufffd'

TAIL_BLOCK_OLD = r"""    NL \+ SEP \+
    '# 1 .*? Convert to upper case' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    return line\.upper\(\)' \+ NL \+
    NL \+ SEP \+
    '# 2 .*? Add line number prefix' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    n = ctx\[''line_number''\]' \+ NL \+
    '    return f"\[\{n:06d\}\] \{line\}"' \+ NL \+
    NL \+ SEP \+
    '# 3 .*? Skip blank lines' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    if line\.strip\(\) == '''':' \+ NL \+
    '        return None  # blank line -> SKIP' \+ NL \+
    '    return line' \+ NL \+
    NL \+ SEP \+
    '# 4 .*? Filter: keep only lines containing a keyword' \+ NL \+
    'KEYWORD = ''error''' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    return line if KEYWORD\.lower\(\) in line\.lower\(\) else None' \+ NL \+
    NL \+ SEP \+
    '# 5 .*? Remove extra spaces \(normalise whitespace\)' \+ NL \+
    'import re' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    return re\.sub\(r'' \{2,\}'', '' '', line\.strip\(\)\)' \+ NL \+
    NL \+ SEP \+
    '# 6 .*? Reformat CSV fields \(separator = semicolon\)' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    parts = line\.split\('';''\)' \+ NL \+
    '    if len\(parts\) < 3:' \+ NL \+
    '        return None  # invalid -> skip' \+ NL \+
    '    name, date, value = parts\[0\], parts\[1\], parts\[2\]' \+ NL \+
    '    return f"\{name\.strip\(\)\} \| \{date\.strip\(\)\} \| R\$ \{value\.strip\(\)\}"' \+ NL \+
    NL \+ SEP \+
    '# 7 .*? Count words per line' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    words = line\.split\(\)' \+ NL \+
    '    return f"\{len\(words\):3d\} words: \{line\}"' \+ NL \+
    NL \+ SEP \+
    '# 8 .*? Multiple word replacement via dict' \+ NL \+
    'REPLACEMENTS = \{\''error\'': \''ERROR\'', \''warning\'': \''WARNING\'', \''info\'': \''INFO\'\}' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    result = line' \+ NL \+
    '    for old, new in REPLACEMENTS\.items\(\):' \+ NL \+
    '        result = result\.replace\(old, new\)' \+ NL \+
    '    return result' \+ NL \+
    NL \+ SEP \+
    '# 9 .*? Persistent counter using ctx.*?' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    count = ctx\.get\(''count'', 0\) \+ 1' \+ NL \+
    '    ctx\[''count''\] = count' \+ NL \+
    '    return f"#\{count\} \{line\}"' \+ NL \+
    NL \+ SEP \+
    '# 10 .*? Log only lines containing ERROR \(typical tail / log follow\)' \+ NL \+
    'def transform\(line, ctx\):' \+ NL \+
    '    return line if ''ERROR'' in line else None' \+ NL;"""

TAIL_BLOCK_NEW = """    NL + SEP +
    TrText('PY_MACRO_EX_01') + NL +
    'def transform(line, ctx):' + NL +
    '    return line.upper()' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_02') + NL +
    'def transform(line, ctx):' + NL +
    '    n = ctx[''line_number'']' + NL +
    '    return f"[{n:06d}] {line}"' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_03') + NL +
    'def transform(line, ctx):' + NL +
    '    if line.strip() == '''':' + NL +
    '        return None  # blank line -> SKIP' + NL +
    '    return line' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_04') + NL +
    'KEYWORD = ''error''' + NL +
    'def transform(line, ctx):' + NL +
    '    return line if KEYWORD.lower() in line.lower() else None' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_05') + NL +
    'import re' + NL +
    'def transform(line, ctx):' + NL +
    '    return re.sub(r'' {2,}'', '' '', line.strip())' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_06') + NL +
    'def transform(line, ctx):' + NL +
    '    parts = line.split('';'')' + NL +
    '    if len(parts) < 3:' + NL +
    '        return None  # invalid -> skip' + NL +
    '    name, date, value = parts[0], parts[1], parts[2]' + NL +
    '    return f"{name.strip()} | {date.strip()} | R$ {value.strip()}"' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_07') + NL +
    'def transform(line, ctx):' + NL +
    '    words = line.split()' + NL +
    '    return f"{len(words):3d} words: {line}"' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_08') + NL +
    'REPLACEMENTS = {''error'': ''ERROR'', ''warning'': ''WARNING'', ''info'': ''INFO''}' + NL +
    'def transform(line, ctx):' + NL +
    '    result = line' + NL +
    '    for old, new in REPLACEMENTS.items():' + NL +
    '        result = result.replace(old, new)' + NL +
    '    return result' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_09') + NL +
    'def transform(line, ctx):' + NL +
    '    count = ctx.get(''count'', 0) + 1' + NL +
    '    ctx[''count''] = count' + NL +
    '    return f"#{count} {line}"' + NL +
    NL + SEP +
    TrText('PY_MACRO_EX_10_TAIL') + NL +
    'def transform(line, ctx):' + NL +
    '    return line if ''ERROR'' in line else None' + NL;"""


def main() -> None:
    text = PATH.read_text(encoding='utf-8')
    n_before = text.count(REPL)

    # Global: U+FFFD used as broken en-dash -> ASCII hyphen pair
    text = re.sub(
        r"('# \d+) " + REPL + r" ",
        r"\1 - ",
        text,
    )
    text = re.sub(
        r"('=== Script Engine) " + REPL + r" (Python Examples ===')",
        r"\1 - \2",
        text,
    )
    # TrText / other strings: U+FFFD surrounded by spaces -> ' - '
    text = text.replace(' ' + REPL + ' ', ' - ')

    # Tail suggestions block (after global fix, titles may already be fixed; still use TrText)
    m = re.search(
        r"(procedure TfrmMain\.TailMacroSuggestionsLoadContent;.*?FTailMacroSuggestionsMemo\.Lines\.Text :=\s*\n"
        r"    TrText\('Tail macro examples intro'\).*?)"
        r"    NL \+ SEP \+\n"
        r"    '# 1 - Convert to upper case'",
        text,
        re.DOTALL,
    )
    if not m:
        raise SystemExit('Tail block anchor not found')

    # Replace from NL + SEP after doc through end of procedure body assignments
    tail_pat = (
        r"(    NL \+ SEP \+\n)"
        r"    '# 1 - Convert to upper case'.*?return line if ''ERROR'' in line else None' \+ NL;"
    )
    text2, c1 = re.subn(tail_pat, TAIL_BLOCK_NEW, text, count=1, flags=re.DOTALL)
    if c1 != 1:
        raise SystemExit(f'Tail examples replace failed ({c1})')
    text = text2

    script_pat = (
        r"  FScriptSuggestionsMemo\.Lines\.Text :=\s*\n"
        r"    '=== Script Engine - Python Examples ===' \+ NL \+\n"
        r"    'Define:  def transform\(line, ctx\) -> str \| None'.*?return int\(line\)  # fails if line is not a number' \+ NL;"
    )
    script_new = (
        "  FScriptSuggestionsMemo.Lines.Text :=\n"
        "    TrText('SCRIPT_ENGINE_EXAMPLES_HEADER') + NL +\n"
        "    TrText('SCRIPT_ENGINE_EXAMPLES_DOC') + NL +\n"
        + TAIL_BLOCK_NEW.replace('PY_MACRO_EX_10_TAIL', 'PY_MACRO_EX_10_SCRIPT').replace(
            'return line if ''ERROR'' in line else None',
            'return int(line)  # fails if line is not a number',
        )
    )
    text2, c2 = re.subn(script_pat, script_new, text, count=1, flags=re.DOTALL)
    if c2 != 1:
        raise SystemExit(f'Script examples replace failed ({c2})')
    text = text2

    n_after = text.count(REPL)
    PATH.write_text(text, encoding='utf-8', newline='\r\n')
    print(f'U+FFFD: {n_before} -> {n_after}')
    print('Tail:', c1, 'Script:', c2)


if __name__ == '__main__':
    main()
