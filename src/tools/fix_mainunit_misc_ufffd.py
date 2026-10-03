from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / 'MainUnit.pas'
R = '\ufffd'
t = PATH.read_text(encoding='utf-8')
before = t.count(R)
t = t.replace(
    'do not rely on ' + R + 'split when the trailer changes' + R + ' until',
    "do not rely on ''split when the trailer changes'' until",
)
t = t.replace('starting with 1' + R + '9 (example', 'starting with 1-9 (example')
after = t.count(R)
PATH.write_text(t, encoding='utf-8', newline='\r\n')
print(f'U+FFFD {before} -> {after}')
