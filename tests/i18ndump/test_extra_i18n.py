import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import gen_extra_i18n as generator


class ExtraCatalogTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.data = Path(self.directory.name)
        patcher = patch.object(generator, "DATA", self.data)
        patcher.start()
        self.addCleanup(patcher.stop)

    def validate(self, source, value, **fields):
        entries = [{"kind": "T", "key": "test.key", "source": source}]
        digest = generator.fingerprint(entries)
        document = {"sha256": digest, "translations": {"0": value}, **fields}
        (self.data / "hi.json").write_text(
            json.dumps(document, ensure_ascii=False), encoding="utf-8",
        )
        return generator.translations_for("hi", entries, digest)

    def test_unicode_and_format(self):
        value = "  पंक्तियाँ: %d\r\nफ़ाइल: %s|उदाहरण  "
        self.assertEqual(self.validate(
            "  Lines: %d\r\nFile: %s|Example  ", value,
        )["0"], value)

    def test_literal_percent_is_not_a_format_parameter(self):
        self.validate("100% completed", "100% पूर्ण")
        self.validate("%d%% completed", "%d%% पूर्ण")

    def test_changed_format_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Format"):
            self.validate("Lines: %d, file: %s", "फ़ाइल: %s, पंक्तियाँ: %d")

    def test_changed_pipes_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "pipe"):
            self.validate("Description|Example", "विवरण")

    def test_changed_newlines_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "line breaks"):
            self.validate("First\r\nSecond", "पहला\nदूसरा")

    def test_changed_whitespace_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "whitespace"):
            self.validate(" File ", "फ़ाइल")

    def test_untranslated_prose_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "explicit reason"):
            self.validate("Open the file", "Open the file")

    def test_intentional_technical_identity(self):
        self.validate("UTF-8", "UTF-8", unchanged={"0": "Encoding identifier"})

    def test_stale_identity_reason_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "stale"):
            self.validate("File", "फ़ाइल", unchanged={"0": "Encoding identifier"})

    def test_damage_and_bidi_controls_are_rejected(self):
        for value in ("\ufffd", "\u202eफ़ाइल"):
            with self.subTest(value=value), self.assertRaisesRegex(
                ValueError, "damaged text or BiDi",
            ):
                self.validate("File", value)

    def test_missing_entry_is_rejected(self):
        entries = [{"kind": "T", "key": "File", "source": "File"}]
        digest = generator.fingerprint(entries)
        (self.data / "hi.json").write_text(json.dumps({
            "sha256": digest, "translations": {},
        }), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "missing"):
            generator.translations_for("hi", entries, digest)

    def test_duplicate_json_key_is_rejected(self):
        (self.data / "hi.json").write_text('{"a":1,"a":2}', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Duplicate JSON key"):
            generator.read_document(self.data / "hi.json")

    def test_pascal_unicode_and_surrogate_pairs(self):
        self.assertEqual(generator.pascal_literal("हिन्दी"), "#2361#2367#2344#2381#2342#2368")
        self.assertEqual(generator.pascal_literal("\U0001f680"), "#55357#56960")
        self.assertEqual(generator.pascal_literal("a'b\r\né"), "'a''b'#13#10#233")

    def test_fingerprint_rejects_stale_translations(self):
        entries = [{"kind": "T", "key": "File", "source": "File"}]
        (self.data / "hi.json").write_text(json.dumps({
            "sha256": "stale", "translations": {"0": "फ़ाइल"},
        }), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "different catalog"):
            generator.translations_for("hi", entries, generator.fingerprint(entries))

    def test_case_insensitive_aliases_must_agree(self):
        entries = [
            {"kind": "T", "key": "Delete", "source": "Delete"},
            {"kind": "T", "key": "delete", "source": "delete"},
        ]
        digest = generator.fingerprint(entries)
        (self.data / "hi.json").write_text(json.dumps({
            "sha256": digest, "translations": {"0": "हटाएँ", "1": "हटाना"},
        }), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "aliases"):
            generator.translations_for("hi", entries, digest)
        (self.data / "hi.json").write_text(json.dumps({
            "sha256": digest, "translations": {"0": "हटाएँ", "1": "हटाएँ"},
        }), encoding="utf-8")
        self.assertEqual(len(generator.translations_for("hi", entries, digest)), 2)


if __name__ == "__main__":
    unittest.main()
