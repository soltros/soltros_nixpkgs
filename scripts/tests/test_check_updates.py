"""Regression coverage for Canary's commit-based release tags."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "check_updates", Path(__file__).resolve().parents[1] / "check-updates.py"
)
scanner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scanner)


class XeniaReleaseTests(unittest.TestCase):
    def scan(self, response=None, error=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pkgs").mkdir()
            (root / "pkgs/xenia-canary.nix").write_text('version = "583528e";')
            with patch.object(scanner, "fetch_json", return_value=response, side_effect=error) as fetch:
                results = scanner.scan_all_packages(repo_root=root)
            fetch.assert_called_once_with(
                "https://api.github.com/repos/xenia-canary/xenia-canary/releases/latest",
                scanner.get_headers(),
            )
            self.assertEqual(len(results), 1)
            self.assertEqual(results[0]["package"], "xenia-canary")
            return results[0]

    def test_current_release(self):
        result = self.scan({"tag_name": "583528e", "html_url": "https://example.test/release"})
        self.assertEqual(result["status"], "up_to_date")

    def test_new_commit_tag_is_update(self):
        result = self.scan({"tag_name": "012abcd", "html_url": "https://example.test/release"})
        self.assertEqual(result["status"], "update_available")
        self.assertEqual(result["latest"], "012abcd")
        self.assertIn("xenia-canary", scanner.format_markdown_report([result]))

    def test_api_error_is_reported(self):
        result = self.scan(error=OSError("unavailable"))
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["current"], "583528e")


if __name__ == "__main__":
    unittest.main()
