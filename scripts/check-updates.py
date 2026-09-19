#!/usr/bin/env python3
"""Scan soltros_nixpkgs for package version updates and generate reports."""

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, Any, Optional, List

def find_repo_root(custom_dir: Optional[str] = None) -> Path:
    if custom_dir:
        p = Path(custom_dir).resolve()
        if (p / "pkgs").is_dir():
            return p
    script_parent = Path(__file__).resolve().parent.parent
    if (script_parent / "pkgs").is_dir():
        return script_parent
    cwd = Path.cwd()
    if (cwd / "pkgs").is_dir():
        return cwd
    return script_parent


def get_headers(token: Optional[str] = None) -> Dict[str, str]:
    headers = {
        "User-Agent": "soltros-nixpkgs-update-scanner",
        "Accept": "application/vnd.github.v3+json",
    }
    tok = token or os.getenv("GITHUB_TOKEN")
    if tok:
        headers["Authorization"] = f"Bearer {tok}"
    return headers


def fetch_json(url: str, headers: Dict[str, str]) -> Any:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_head(url: str) -> Dict[str, str]:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "soltros-nixpkgs-update-scanner"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return dict(resp.headers)


class PackageChecker:
    def __init__(self, headers: Dict[str, str]):
        self.headers = headers

    def check_github_tag(self, owner: str, repo: str, current_version: str, tag_prefix: str = "v") -> Dict[str, Any]:
        url = f"https://api.github.com/repos/{owner}/{repo}/tags"
        tags = fetch_json(url, self.headers)
        if not tags:
            return {"status": "error", "error": "No tags found"}

        latest_tag = tags[0]["name"]
        clean_latest = latest_tag[len(tag_prefix):] if latest_tag.startswith(tag_prefix) else latest_tag
        clean_current = current_version[len(tag_prefix):] if current_version.startswith(tag_prefix) else current_version

        needs_update = (clean_latest != clean_current)
        return {
            "status": "update_available" if needs_update else "up_to_date",
            "current": current_version,
            "latest": clean_latest,
            "latest_tag": latest_tag,
            "url": f"https://github.com/{owner}/{repo}/releases/tag/{latest_tag}",
        }

    def check_github_commit(self, owner: str, repo: str, current_rev: str, branch: str = "main") -> Dict[str, Any]:
        url = f"https://api.github.com/repos/{owner}/{repo}/commits/{branch}"
        commit_data = fetch_json(url, self.headers)
        latest_sha = commit_data.get("sha", "")
        short_latest = latest_sha[:7]
        short_current = current_rev[:7]

        needs_update = not (latest_sha.startswith(current_rev) or current_rev.startswith(latest_sha[:7]))
        return {
            "status": "update_available" if needs_update else "up_to_date",
            "current": short_current,
            "latest": short_latest,
            "full_sha": latest_sha,
            "url": f"https://github.com/{owner}/{repo}/commit/{latest_sha}",
        }

    def check_waterfox(self, current_version: str) -> Dict[str, Any]:
        url = "https://api.github.com/repos/WaterfoxCo/Waterfox/releases/latest"
        try:
            rel = fetch_json(url, self.headers)
            latest_version = rel.get("tag_name", "").lstrip("v")
        except Exception:
            return self.check_github_tag("WaterfoxCo", "Waterfox", current_version, tag_prefix="G")

        needs_update = (latest_version != current_version)
        return {
            "status": "update_available" if needs_update else "up_to_date",
            "current": current_version,
            "latest": latest_version,
            "url": f"https://github.com/WaterfoxCo/Waterfox/releases/tag/{rel.get('tag_name', '')}",
        }

    def check_chatgpt(self, current_version: str) -> Dict[str, Any]:
        url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb"
        headers = fetch_head(url)
        last_modified = headers.get("Last-Modified", "unknown")
        etag = headers.get("etag", "unknown")
        return {
            "status": "info",
            "current": current_version,
            "latest": f"Latest binary (modified: {last_modified})",
            "url": url,
            "etag": etag,
        }


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def parse_version(content: str) -> Optional[str]:
    m = re.search(r'version\s*=\s*"([^"]+)"', content)
    return m.group(1) if m else None


def parse_rev(content: str) -> Optional[str]:
    m = re.search(r'rev\s*=\s*"([^"]+)"', content)
    return m.group(1) if m else None


def scan_all_packages(token: Optional[str] = None, repo_root: Optional[Path] = None) -> List[Dict[str, Any]]:
    root = repo_root or find_repo_root()
    headers = get_headers(token)
    checker = PackageChecker(headers)
    results = []

    # 1. Addwater
    addwater_nix = root / "pkgs" / "addwater" / "default.nix"
    if addwater_nix.is_file():
        v = parse_version(read_file(addwater_nix)) or "unknown"
        try:
            info = checker.check_github_tag("largestgithubuseronearth", "addwater", v, tag_prefix="v")
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": v, "latest": "?"}
        info["package"] = "addwater"
        info["type"] = "GitHub Tag"
        results.append(info)

    # 2. ChatGPT
    chatgpt_nix = root / "pkgs" / "chatgpt.nix"
    if chatgpt_nix.is_file():
        v = parse_version(read_file(chatgpt_nix)) or "unknown"
        try:
            info = checker.check_chatgpt(v)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": v, "latest": "?"}
        info["package"] = "chatgpt"
        info["type"] = "Upstream Binary"
        results.append(info)

    # 3. Flakebuilder
    flakebuilder_nix = root / "pkgs" / "flakebuilder.nix"
    if flakebuilder_nix.is_file():
        rev = parse_rev(read_file(flakebuilder_nix)) or "main"
        try:
            info = checker.check_github_commit("soltros", "Flakebuilder", rev)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": rev, "latest": "?"}
        info["package"] = "flakebuilder"
        info["type"] = "GitHub Commit"
        results.append(info)

    # 4. Flakebuilder-GUI
    flakebuilder_gui_nix = root / "pkgs" / "flakebuilder-gui.nix"
    if flakebuilder_gui_nix.is_file():
        rev = parse_rev(read_file(flakebuilder_gui_nix)) or "main"
        try:
            info = checker.check_github_commit("soltros", "Flakebuilder", rev)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": rev, "latest": "?"}
        info["package"] = "flakebuilder-gui"
        info["type"] = "GitHub Commit"
        results.append(info)

    # 5. Hideout
    hideout_nix = root / "pkgs" / "hideout" / "default.nix"
    if hideout_nix.is_file():
        v = parse_version(read_file(hideout_nix)) or "unknown"
        try:
            info = checker.check_github_tag("trikko", "hideout", v, tag_prefix="v")
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": v, "latest": "?"}
        info["package"] = "hideout"
        info["type"] = "GitHub Tag"
        results.append(info)

    # 6. Nixboutique
    nixboutique_nix = root / "pkgs" / "nixboutique.nix"
    if nixboutique_nix.is_file():
        rev = parse_rev(read_file(nixboutique_nix)) or "main"
        try:
            info = checker.check_github_commit("soltros", "Nixboutique", rev)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": rev, "latest": "?"}
        info["package"] = "nixboutique"
        info["type"] = "GitHub Commit"
        results.append(info)

    # 7. Quick Settings Tray
    qst_nix = root / "pkgs" / "quick-settings-tray" / "default.nix"
    if qst_nix.is_file():
        rev = parse_rev(read_file(qst_nix)) or "main"
        try:
            info = checker.check_github_commit("soltros", "quick-settings-tray", rev)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": rev, "latest": "?"}
        info["package"] = "quick-settings-tray"
        info["type"] = "GitHub Commit"
        results.append(info)

    # 8. Waterfox
    waterfox_nix = root / "pkgs" / "waterfox.nix"
    if waterfox_nix.is_file():
        v = parse_version(read_file(waterfox_nix)) or "unknown"
        try:
            info = checker.check_waterfox(v)
        except Exception as e:
            info = {"status": "error", "error": str(e), "current": v, "latest": "?"}
        info["package"] = "waterfox"
        info["type"] = "Release Tag"
        results.append(info)

    # 9. Local packages (Pantheon Studio, Termsmith, VPN Manager)
    for local_pkg in ["pantheon-studio", "termsmith", "vpn-manager"]:
        pkg_dir = root / "pkgs" / local_pkg
        if pkg_dir.is_dir():
            results.append({
                "package": local_pkg,
                "type": "Local Package",
                "status": "up_to_date",
                "current": "bundled in repo",
                "latest": "bundled in repo",
                "url": f"pkgs/{local_pkg}",
            })

    return results


def format_markdown_report(results: List[Dict[str, Any]]) -> str:
    updates = [r for r in results if r.get("status") == "update_available"]
    errors = [r for r in results if r.get("status") == "error"]

    lines = []
    lines.append("# 📦 Package Update Scan Report\n")
    if updates:
        lines.append(f"> ⚠️ **{len(updates)} package update(s) available!**\n")
    else:
        lines.append("> ✅ **All packages are up to date!**\n")

    lines.append("| Package | Type | Status | Current | Latest | Link |")
    lines.append("|---|---|---|---|---|---|")

    for r in results:
        status_icon = {
            "up_to_date": "✅ Up to date",
            "update_available": "🔄 **Update Available**",
            "info": "ℹ️ Tracked",
            "error": "❌ Error",
        }.get(r.get("status", ""), "❓ Unknown")

        pkg = f"`{r['package']}`"
        ptype = r.get("type", "-")
        cur = f"`{r.get('current', '-')}`"
        lat = f"`{r.get('latest', '-')}`"
        url = r.get("url")
        link = f"[Upstream]({url})" if url else "-"
        lines.append(f"| {pkg} | {ptype} | {status_icon} | {cur} | {lat} | {link} |")

    if updates:
        lines.append("\n### 🔄 Action Required\n")
        lines.append("The following packages have newer upstream versions or commits:")
        for u in updates:
            lines.append(f"- **{u['package']}**: `{u.get('current')}` → `{u.get('latest')}` ({u.get('url', '')})")

    if errors:
        lines.append("\n### ⚠️ Scan Warnings\n")
        for e in errors:
            lines.append(f"- **{e['package']}**: {e.get('error')}")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Scan soltros_nixpkgs for package updates.")
    parser.add_argument("--repo-dir", help="Path to soltros_nixpkgs repository root", default=None)
    parser.add_argument("--token", help="GitHub token for API access", default=None)
    parser.add_argument("--json", action="store_true", help="Output JSON results")
    parser.add_argument("--output-file", help="Write report to file", default=None)
    args = parser.parse_args()

    repo_root = find_repo_root(args.repo_dir)
    results = scan_all_packages(args.token, repo_root=repo_root)
    updates = [r for r in results if r.get("status") == "update_available"]

    report_md = format_markdown_report(results)

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print(report_md)

    if args.output_file:
        Path(args.output_file).write_text(report_md, encoding="utf-8")

    # Set GitHub Actions output & step summary if in GHA environment
    gha_output = os.getenv("GITHUB_OUTPUT")
    if gha_output:
        with open(gha_output, "a", encoding="utf-8") as f:
            f.write(f"updates_available={'true' if updates else 'false'}\n")
            f.write(f"update_count={len(updates)}\n")

    gha_summary = os.getenv("GITHUB_STEP_SUMMARY")
    if gha_summary:
        with open(gha_summary, "a", encoding="utf-8") as f:
            f.write(report_md + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
