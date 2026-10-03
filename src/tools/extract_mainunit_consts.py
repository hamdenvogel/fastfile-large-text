#!/usr/bin/env python3
"""Extract and analyze constants from MainUnit.pas."""
import re
from collections import defaultdict
from pathlib import Path

MAIN = Path(__file__).resolve().parent.parent / "MainUnit.pas"


def main():
    lines = MAIN.read_text(encoding="utf-8", errors="replace").splitlines()

    in_interface = True
    in_implementation = False
    current_proc = None
    constants = []

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped == "implementation":
            in_interface = False
            in_implementation = True
            current_proc = None

        if re.match(r"^(procedure|function)\s+", stripped):
            current_proc = stripped.split()[1].split("(")[0]

        if re.match(r"^end;\s*$", stripped) and current_proc:
            current_proc = None

        is_const = stripped == "const" or re.match(r"^const\s", stripped)
        if is_const:
            indent = len(line) - len(line.lstrip())
            if in_interface:
                scope = "interface"
            elif current_proc:
                scope = current_proc
            else:
                scope = "implementation"

            j = i + 1
            block = []
            while j < len(lines):
                l = lines[j]
                ls = l.rstrip()
                if not ls.strip():
                    j += 1
                    continue
                li = len(l) - len(l.lstrip())
                if li < indent:
                    break
                if li == indent and re.match(
                    r"^(var|type|begin|procedure|function)\b", ls.lstrip()
                ):
                    break
                block.append(ls)
                j += 1

            text = " ".join(s.strip() for s in block)
            # crude split on ; between declarations
            chunks = text.split(";")
            for chunk in chunks:
                chunk = chunk.strip()
                if not chunk:
                    continue
                chunk = re.sub(r"\{.*?\}", "", chunk)
                chunk = re.sub(r"//.*$", "", chunk).strip()
                m = re.match(r"^(\w+(?::\s*\w+)?)\s*=\s*(.+)$", chunk, re.DOTALL)
                if m:
                    name, val = m.group(1).strip(), m.group(2).strip()
                    constants.append(
                        {
                            "scope": scope,
                            "name": name,
                            "value": val,
                            "line": i + 1,
                            "indent": indent,
                        }
                    )
            i = j
            continue
        i += 1

    by_name = defaultdict(list)
    for c in constants:
        by_name[c["name"]].append(c)

    conflicts = {
        n: items
        for n, items in by_name.items()
        if len({x["value"] for x in items}) > 1
    }

    print(f"Total declarations: {len(constants)}")
    print(f"Unique names: {len(by_name)}")
    print(f"Conflicts: {len(conflicts)}")
    for n in sorted(conflicts):
        vals = sorted({x["value"] for x in conflicts[n]})
        print(f"  {n}:")
        for v in vals:
            scopes = [x["scope"] for x in conflicts[n] if x["value"] == v]
            print(f"    {v[:80]}... scopes={scopes[:3]}")

    iface = [c for c in constants if c["scope"] == "interface"]
    impl_global = [c for c in constants if c["scope"] == "implementation"]
    proc = [c for c in constants if c["scope"] not in ("interface", "implementation")]
    print(f"\ninterface: {len(iface)}")
    print(f"implementation global: {len(impl_global)}")
    print(f"procedure-local: {len(proc)}")


if __name__ == "__main__":
    main()
