"""Regression coverage for Xenia's master-branch commit tracking."""
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


class XeniaCommitTests(unittest.TestCase):
    def scan(self, response=None, error=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pkgs").mkdir()
            (root / "pkgs/xenia.nix").write_text('rev = "95a5c3ee250f80c3b9d139658649d9ffb6db3eec";')
            with patch.object(scanner, "fetch_json", return_value=response, side_effect=error) as fetch:
                results = scanner.scan_all_packages(repo_root=root)
            fetch.assert_called_once_with(
                "https://api.github.com/repos/xenia-project/xenia/commits/master",
                scanner.get_headers(),
            )
            self.assertEqual(len(results), 1)
            self.assertEqual(results[0]["package"], "xenia")
            return results[0]

    def test_current_commit(self):
        result = self.scan({"sha": "95a5c3ee250f80c3b9d139658649d9ffb6db3eec"})
        self.assertEqual(result["status"], "up_to_date")

    def test_new_commit_is_update(self):
        result = self.scan({"sha": "012abcd345678901234567890123456789012345"})
        self.assertEqual(result["status"], "update_available")
        self.assertEqual(result["latest"], "012abcd")
        self.assertIn("xenia", scanner.format_markdown_report([result]))

    def test_api_error_is_reported(self):
        result = self.scan(error=OSError("unavailable"))
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["current"], "95a5c3e")



class BraveStableTests(unittest.TestCase):
    def scan(self, version="1.99.55", **changes):
        release = {
            "tag_name": f"v{version}",
            "html_url": f"https://github.com/brave/brave-browser/releases/tag/v{version}",
            "assets": [{"name": f"brave-browser_{version}_{arch}.deb"}
                       for arch in ("amd64", "arm64")],
        }
        release.update(changes)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pkgs/brave").mkdir(parents=True)
            (root / "pkgs/brave/default.nix").write_text('version = "1.99.55";')
            with patch.object(scanner, "fetch_json", return_value=release) as fetch:
                results = scanner.scan_all_packages(repo_root=root)
            fetch.assert_called_once_with(
                "https://api.github.com/repos/brave/brave-browser/releases/latest",
                scanner.get_headers(),
            )
            self.assertEqual(len(results), 1)
            self.assertEqual(results[0]["package"], "brave")
            return results[0]

    def test_current_stable(self):
        self.assertEqual(self.scan()["status"], "up_to_date")

    def test_new_stable(self):
        result = self.scan("1.99.56")
        self.assertEqual(result["status"], "update_available")
        self.assertEqual(result["latest"], "1.99.56")
        self.assertIn("brave", scanner.format_markdown_report([result]))

    def test_prerelease_is_rejected(self):
        self.assertEqual(self.scan(prerelease=True)["status"], "error")

    def test_missing_architecture_is_reported(self):
        self.assertEqual(self.scan(assets=[])["status"], "error")

    def test_beta_tag_is_rejected(self):
        self.assertEqual(self.scan("1.100.1-beta")["status"], "error")


class LichiiReleaseTests(unittest.TestCase):
    def scan(self, tag="build-117", error=None, **changes):
        release = {
            "tag_name": tag,
            "html_url": f"https://github.com/zortos293/Lichii/releases/tag/{tag}",
            "assets": [{"name": f"lichii-linux-{arch}-pgo.AppImage"}
                       for arch in ("x86_64", "aarch64")],
        }
        release.update(changes)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "pkgs").mkdir()
            (root / "pkgs/lichii.nix").write_text('version = "117";')
            with patch.object(scanner, "fetch_json", return_value=release, side_effect=error) as fetch:
                results = scanner.scan_all_packages(repo_root=root)
            fetch.assert_called_once_with(
                "https://api.github.com/repos/zortos293/Lichii/releases/latest",
                scanner.get_headers(),
            )
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["package"], "lichii")
        return results[0]

    def test_current_build(self):
        self.assertEqual(self.scan()["status"], "up_to_date")

    def test_new_build(self):
        result = self.scan("build-118")
        self.assertEqual(result["status"], "update_available")
        self.assertEqual(result["latest"], "118")
        self.assertIn("lichii", scanner.format_markdown_report([result]))

    def test_incomplete_release(self):
        self.assertEqual(self.scan(assets=[{"name": "lichii-linux-x86_64-pgo.AppImage"}])["status"], "error")

    def test_invalid_release(self):
        for changes in ({"tag": "nightly"}, {"prerelease": True}, {"draft": True}):
            with self.subTest(changes=changes):
                self.assertEqual(self.scan(**changes)["status"], "error")

    def test_api_error(self):
        result = self.scan(error=OSError("unavailable"))
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["current"], "117")


if __name__ == "__main__":
    unittest.main()
