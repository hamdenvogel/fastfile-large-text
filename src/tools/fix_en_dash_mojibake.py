# -*- coding: cp1252 -*-
"""Replace Windows-1252 0x97 (en dash saved wrong) with ASCII ' - ' in .pas sources."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / 'MainUnit.pas',
]


def fix_file(path: Path) -> int:
    data = path.read_bytes()
    count = data.count(b'\x97')
    if count:
        data = data.replace(b'\x97', b' - ')
        path.write_bytes(data)
    return count


def main() -> int:
    total = 0
    for p in FILES:
        if p.exists():
            n = fix_file(p)
            print(f'{p.name}: {n} replacements')
            total += n
    return 0


if __name__ == '__main__':
    sys.exit(main())
