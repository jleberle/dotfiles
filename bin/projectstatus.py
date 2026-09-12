#!/usr/bin/env python3
"""projectstatus.py — one table for every project under ~/git.

Relationship to `gitstatus`
---------------------------
`gitstatus` stays the fast, offline, git-only check and is not replaced. This
adds the two things it cannot know, both of which need more than `git status`:

* **CI** — the last run's conclusion, via `gh` (network).
* **Pipeline** — whether a repo that GENERATES files into another repo is
  ahead of what it generated. Two repos do this: ~/git/cv owns
  website/content/cv, and ~/git/syllabi owns website/content/courses. Neither
  shows up as a dirty tree anywhere, because the generated files are committed
  in the *other* repo — which is exactly how those course pages drifted a full
  academic year behind their syllabi without anything reporting it.

Staleness is answered by ASKING EACH GENERATOR, not by comparing timestamps:
`make -q` and `publish-web.py --dry-run` already encode what is derived from
what, and a second guess at that would be one more thing to keep in sync.

Usage
-----
    projectstatus.py              # everything
    projectstatus.py --no-ci      # skip the network calls
    projectstatus.py --root DIR   # default ~/git
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# repo -> (probe, what it owns). Exit 0 = in sync, non-zero = stale. Every
# probe must be side-effect free outside a temp directory.
#
# Both probes compare CONTENT, and the two obvious cheaper checks are both
# wrong here:
#
#   * `make -q` compares mtimes, and git does not preserve mtimes -- a fresh
#     clone or checkout reorders them arbitrarily. It also reports every .PHONY
#     target as out of date forever, so `make -q build` is always "stale".
#   * Comparing last-commit times fails on cv specifically, because
#     `make publish` pushes the website repo FIRST and the source repo LAST
#     (see cv/CLAUDE.md) -- so the source commit is always the newer one, even
#     immediately after a successful publish.
#
# Known gap: the cv probe renders only index.md, because the PDF leg needs
# tectonic and takes orders of magnitude longer. A change that affects only PDF
# layout (template.tex, meta.yaml) will not show up here.
PIPELINES = {
    "cv": (
        'T=$(mktemp -d); make web BUNDLE="$T" >/dev/null 2>&1 '
        '&& cmp -s "$T/index.md" "$WEBSITE_CV/index.md"; rc=$?; rm -rf "$T"; exit $rc',
        "generates website/content/cv",
    ),
    "syllabi": ("./publish-web.py --dry-run --quiet",
                "generates website/content/courses"),
}

C = {
    "reset": "\033[0m", "dim": "\033[2m", "bold": "\033[1m",
    "red": "\033[31m", "green": "\033[32m", "yellow": "\033[33m",
}
if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    C = {k: "" for k in C}


def run(cmd: list[str] | str, cwd: Path, timeout: int = 20) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str), timeout=timeout,
                           capture_output=True, text=True)
        return p.returncode, (p.stdout + p.stderr).strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return 124, ""


def git_state(repo: Path) -> str:
    _, dirty = run(["git", "status", "--porcelain"], repo)
    n = len([l for l in dirty.splitlines() if l.strip()])
    rc, up = run(["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], repo)
    bits = []
    if n:
        bits.append(f"{C['yellow']}{n} dirty{C['reset']}")
    if rc == 0 and up:
        _, ahead = run(["git", "rev-list", "--count", f"{up}..HEAD"], repo)
        _, behind = run(["git", "rev-list", "--count", f"HEAD..{up}"], repo)
        if ahead.isdigit() and int(ahead):
            bits.append(f"{C['yellow']}{ahead} ahead{C['reset']}")
        if behind.isdigit() and int(behind):
            bits.append(f"{C['yellow']}{behind} behind{C['reset']}")
    else:
        bits.append(f"{C['dim']}no upstream{C['reset']}")
    return ", ".join(bits) if bits else f"{C['green']}clean{C['reset']}"


def slug(repo: Path) -> str | None:
    """owner/name from the origin remote, including ssh-alias remotes."""
    rc, url = run(["git", "remote", "get-url", "origin"], repo)
    if rc != 0:
        return None
    m = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?$", url.strip())
    return m.group(1) if m else None


def ci_state(repo: Path) -> str:
    if not (repo / ".github" / "workflows").is_dir():
        # Woodpecker repos have no gh-visible runs; say so rather than "none".
        return f"{C['dim']}woodpecker{C['reset']}" if list(repo.glob(".woodpecker*")) \
            else f"{C['dim']}—{C['reset']}"
    s = slug(repo)
    if not s:
        return f"{C['dim']}—{C['reset']}"
    rc, out = run(["gh", "run", "list", "-R", s, "-L", "1",
                   "--json", "conclusion,status,workflowName"], repo, timeout=25)
    if rc != 0 or not out:
        return f"{C['dim']}?{C['reset']}"
    try:
        runs = json.loads(out)
    except json.JSONDecodeError:
        return f"{C['dim']}?{C['reset']}"
    if not runs:
        return f"{C['dim']}no runs{C['reset']}"
    r = runs[0]
    if r.get("status") != "completed":
        return f"{C['yellow']}{r.get('status', 'running')}{C['reset']}"
    concl = r.get("conclusion") or "?"
    colour = C["green"] if concl == "success" else C["red"]
    return f"{colour}{concl}{C['reset']}"


def pipeline_state(repo: Path) -> str:
    entry = PIPELINES.get(repo.name)
    if not entry:
        return ""
    cmd, _ = entry
    env_hint = repo.parent / "website" / "content" / "cv"
    rc, _ = run(f'WEBSITE_CV="{env_hint}" {cmd}', repo, timeout=120)
    if rc == 0:
        return f"{C['green']}in sync{C['reset']}"
    if rc == 124:
        return f"{C['dim']}probe failed{C['reset']}"
    return f"{C['red']}STALE — regenerate{C['reset']}"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(Path.home() / "git"))
    ap.add_argument("--no-ci", action="store_true", help="skip the gh network calls")
    args = ap.parse_args()

    root = Path(args.root).expanduser()
    repos = sorted(p for p in root.iterdir() if (p / ".git").exists())
    if not repos:
        sys.exit(f"no git repos under {root}")

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        git = {r: ex.submit(git_state, r) for r in repos}
        ci = {r: ex.submit(ci_state, r) for r in repos} if not args.no_ci else {}
        pipe = {r: ex.submit(pipeline_state, r) for r in repos}
        rows = [(r.name, git[r].result(),
                 ci[r].result() if ci else f"{C['dim']}skipped{C['reset']}",
                 pipe[r].result()) for r in repos]

    def width(i: int) -> int:
        return max(len(re.sub(r"\033\[[0-9;]*m", "", r[i])) for r in rows)

    w0, w1, w2 = max(width(0), 4), max(width(1), 3), max(width(2), 2)
    print(f"{C['bold']}{'repo':<{w0}}  {'git':<{w1}}  {'ci':<{w2}}  pipeline{C['reset']}")
    for name, g, c, p in rows:
        pad = lambda s, w: s + " " * (w - len(re.sub(r"\033\[[0-9;]*m", "", s)))
        print(f"{name:<{w0}}  {pad(g, w1)}  {pad(c, w2)}  {p}")

    stale = [r[0] for r in rows if "STALE" in r[3]]
    if stale:
        print(f"\n{C['red']}stale:{C['reset']} " + ", ".join(stale) +
              " — run the generator, then ship from the website repo")
    return 0


if __name__ == "__main__":
    sys.exit(main())
