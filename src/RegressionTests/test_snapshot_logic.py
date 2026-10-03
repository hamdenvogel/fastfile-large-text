"""
Logic mirror for disk snapshot equality (size + last-write FILETIME).
Does not compile Delphi; run after Python 3 install: python test_snapshot_logic.py
"""
from __future__ import annotations


def lw_from_dwords(lo: int, hi: int) -> bytes:
    return int(lo & 0xFFFFFFFF).to_bytes(4, "little") + int(hi & 0xFFFFFFFF).to_bytes(4, "little")


def same_snapshot(size_a: int, lw_a: bytes, size_b: int, lw_b: bytes) -> bool:
    return size_a == size_b and lw_a == lw_b


def main() -> None:
    t0 = lw_from_dwords(100, 0)
    t1 = lw_from_dwords(101, 0)
    assert same_snapshot(10, t0, 10, t0)
    assert not same_snapshot(10, t0, 11, t0)
    assert not same_snapshot(10, t0, 10, t1)
    print("test_snapshot_logic: OK")


if __name__ == "__main__":
    main()
