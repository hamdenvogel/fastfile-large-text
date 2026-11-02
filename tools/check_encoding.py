"""Compares every modified .pas file with HEAD: U+FFFD count, BOM, CR/LF style.
Run from the repo root: python tools/check_encoding.py"""
import subprocess
import sys

files = subprocess.run(["git", "diff", "--name-only"], capture_output=True, text=True).stdout.split()
files += subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], capture_output=True, text=True).stdout.split()
bad = 0
for f in sorted(set(files)):
    if not f.endswith((".pas", ".dpr")):
        continue
    try:
        new = open(f, "rb").read()
    except OSError:
        continue
    old = subprocess.run(["git", "show", "HEAD:" + f], capture_output=True).stdout
    fffd_new = new.count(b"\xef\xbf\xbd")
    fffd_old = old.count(b"\xef\xbf\xbd")
    bom_new = new.startswith(b"\xef\xbb\xbf")
    bom_old = old.startswith(b"\xef\xbb\xbf")
    crlf_new, lf_new = new.count(b"\r\n"), new.count(b"\n") - new.count(b"\r\n")
    crlf_old, lf_old = old.count(b"\r\n"), old.count(b"\n") - old.count(b"\r\n")
    flag = ""
    if fffd_new > fffd_old:
        flag += " FFFD+%d" % (fffd_new - fffd_old)
    if old and bom_new != bom_old:
        flag += " BOM-changed"
    if old and (lf_new > 0) != (lf_old > 0):
        flag += " EOL-changed(lf %d->%d)" % (lf_old, lf_new)
    if not old:
        flag += " NEW(crlf=%d lf=%d bom=%s)" % (crlf_new, lf_new, bom_new)
    if flag:
        bad += 1
        print(f, flag)
print("checked", len(set(files)), "files;", bad, "flagged")
