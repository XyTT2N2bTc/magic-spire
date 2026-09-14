from pathlib import Path
import subprocess
import tempfile
import unittest

from check_agents import discover, validate


class InstructionGateTests(unittest.TestCase):
    def test_line_limit(self):
        self.assertEqual(validate("module/AGENTS.md", b"x\n" * 500), [])
        self.assertTrue(any("exceeds 500" in e for e in
                            validate("module/AGENTS.md", b"x\n" * 501)))

    def test_root_minimum(self):
        self.assertEqual(validate("AGENTS.md", b"x\n" * 200), [])
        self.assertTrue(validate("AGENTS.md", b"x\n" * 199))

    def test_byte_limit(self):
        self.assertEqual(validate("module/AGENTS.md", b"x" * 9998 + b"\n"), [])
        self.assertTrue(validate("module/AGENTS.md", b"x" * 9999 + b"\n"))
        self.assertTrue(validate("module/AGENTS.md", ("字" * 3334 + "\n").encode()))

    def test_encoding_and_whitespace(self):
        for data in [b"\xff\n", b"x", b"x \n", b"\tx\n"]:
            with self.subTest(data=data):
                self.assertTrue(validate("module/AGENTS.md", data))
        self.assertEqual(validate("module/AGENTS.md", b"x\r\n"), [])

    def test_discovery_includes_new_modules_not_ignored_dependencies(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / ".gitignore").write_text("cache/\n", encoding="utf-8")
            for name in ["AGENTS.md", "new/AGENTS.md", "cache/AGENTS.md"]:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("x\n", encoding="utf-8")
            subprocess.run(["git", "add", "AGENTS.md"], cwd=root, check=True)
            self.assertEqual(discover(root), ["AGENTS.md", "new/AGENTS.md"])


if __name__ == "__main__":
    unittest.main()
