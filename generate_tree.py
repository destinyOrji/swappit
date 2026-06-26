#!/usr/bin/env python3
"""Generate a directory tree while ignoring patterns from .gitignore."""

from __future__ import annotations

import argparse
import fnmatch
import subprocess
import sys
from pathlib import Path


def get_git_root(path: Path) -> Path | None:
    try:
        output = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return Path(output.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def git_check_ignore(path: Path, repo_root: Path) -> bool:
    try:
        subprocess.check_call(
            ["git", "-C", str(repo_root), "check-ignore", "--quiet", "--", str(path.relative_to(repo_root))],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False


class IgnoreRule:
    def __init__(self, pattern: str, base: Path, negated: bool, dir_only: bool, anchored: bool):
        self.pattern = pattern
        self.base = base
        self.negated = negated
        self.dir_only = dir_only
        self.anchored = anchored

    def matches(self, rel_path: Path, is_dir: bool) -> bool:
        if self.dir_only and not is_dir:
            return False

        try:
            rel_to_base = rel_path.relative_to(self.base)
        except ValueError:
            return False

        candidate = rel_to_base.as_posix()
        if candidate == "":
            candidate = "."

        pattern = self.pattern
        if self.anchored:
            return fnmatch.fnmatchcase(candidate, pattern)

        if "/" in pattern:
            if fnmatch.fnmatchcase(candidate, pattern):
                return True
            return fnmatch.fnmatchcase(candidate, f"**/{pattern}")

        if fnmatch.fnmatchcase(candidate, pattern):
            return True
        if any(fnmatch.fnmatchcase(part, pattern) for part in candidate.split("/")):
            return True

        return False


def load_gitignore_rules(root: Path) -> list[IgnoreRule]:
    rules: list[IgnoreRule] = []
    gitignore_files = sorted(root.rglob(".gitignore"), key=lambda p: (len(p.parts), str(p)))
    for gitignore_path in gitignore_files:
        base = gitignore_path.parent
        try:
            lines = gitignore_path.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue
        for raw_line in lines:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            negated = line.startswith("!")
            if negated:
                line = line[1:].lstrip()
            anchored = line.startswith("/")
            if anchored:
                line = line[1:]
            dir_only = line.endswith("/")
            if dir_only:
                line = line.rstrip("/")
            if not line:
                continue
            rules.append(IgnoreRule(pattern=line, base=base, negated=negated, dir_only=dir_only, anchored=anchored))
    return rules


def ignored_by_gitignore(path: Path, root: Path, rules: list[IgnoreRule]) -> bool:
    rel_path = path.relative_to(root)
    if rel_path == Path("."):
        return False
    is_dir = path.is_dir()
    ignored = False
    for rule in rules:
        if rule.matches(rel_path, is_dir):
            ignored = not rule.negated
    return ignored


def build_tree(root: Path, verbose: bool = False) -> list[str]:
    git_root = get_git_root(root)
    rules = load_gitignore_rules(root)
    ignored_paths: dict[Path, bool] = {}

    def should_ignore(path: Path) -> bool:
        if path.name == ".git":
            return True
        if git_root is not None:
            if git_check_ignore(path, git_root):
                return True
        elif ignored_by_gitignore(path, root, rules):
            return True
        return False

    def walk(path: Path, prefix: str = "") -> list[str]:
        entries = []
        children = [item for item in sorted(path.iterdir(), key=lambda p: p.name.lower()) if not should_ignore(item)]
        for index, child in enumerate(children):
            connector = "└── " if index == len(children) - 1 else "├── "
            if child.is_dir():
                entries.append(f"{prefix}{connector}{child.name}")
                extension = "    " if index == len(children) - 1 else "│   "
                entries.extend(walk(child, prefix + extension))
            else:
                entries.append(f"{prefix}{connector}{child.name}")
        return entries

    root_label = root.name or root.as_posix()
    tree_lines = [root_label]
    tree_lines.extend(walk(root))
    return tree_lines


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a file tree while honoring .gitignore rules.")
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Root directory to scan (default: current directory).",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Write the generated tree to a file instead of stdout.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.path).resolve()
    if not root.exists() or not root.is_dir():
        print(f"Error: path does not exist or is not a directory: {root}", file=sys.stderr)
        return 1

    tree_lines = build_tree(root)
    output = "\n".join(tree_lines)
    if args.output:
        Path(args.output).write_text(output + "\n", encoding="utf-8")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
