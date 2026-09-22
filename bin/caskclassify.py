#!/usr/bin/env python3
"""Split outdated Homebrew casks into "safe to upgrade unattended" and "needs you".

Called by bin/homebrewupdate.sh, the weekly launchd job. That job cannot upgrade
a cask that installs an app, for two independent reasons (both hit on
2026-09-21, see CLAUDE.md): a cask install ends in `sudo -E -- chgrp -hR admin
<app>` and launchd has no terminal to authenticate at, and modifying another
app's bundle needs the macOS App Management grant, which Homebrew's vendored
ruby does not have. The failure is not clean — that run left Bitwarden.app
group `staff` with its Caskroom version directory purged, so the app on disk was
current while `brew info` reported "Not installed".

But "cask" does not mean "app". Of 30 casks installed here, the ones brew would
actually upgrade were five fonts and three apps: fonts land in ~/Library/Fonts,
touch no bundle, and need no sudo, so refusing to upgrade them bought nothing.

So the split is by ARTIFACT, not by name. `font-*` is a reliable naming
convention today, but it is only a convention; the artifact list is the thing
that actually determines whether an upgrade writes into /Applications.

SAFE is an allowlist, deliberately, so an artifact type nobody here has seen
before is classified `manual` rather than silently automated. Adding one is a
decision, not an omission. The members:

    font                 ~/Library/Fonts
    binary               $HOMEBREW_PREFIX/bin symlink
    manpage              $HOMEBREW_PREFIX/share/man
    *_completion         $HOMEBREW_PREFIX/share/{bash,fish,zsh}...

Everything else needs you: `app` and `suite` write bundles, `pkg` and
`installer` run an installer as root, `preflight`/`postflight_steps` run
arbitrary code, and the plugin artifacts (`prefpane`, `qlplugin`, `mdimporter`,
`service`, `screen_saver`, `colorpicker`, `input_method`, `internet_plugin`,
`audio_unit_plugin`, `vst_plugin`, `vst3_plugin`, `dictionary`,
`keyboard_layout`) write into Library directories that are variously protected.

METADATA keys appear in a cask's artifact list but install nothing, so they
never decide the classification on their own.

Usage:
    caskclassify.py TOKEN...              ask brew about these casks
    caskclassify.py --from-json FILE ...  read `brew info --json=v2` output
                                          instead of shelling out (tests)

Output, one line per token, stable order:
    auto    <token>
    manual  <token>  <why>

`why` is the comma-separated artifact kinds that disqualified it, or `unknown`
for a token brew does not recognise — which is also `manual`, for the same
fail-safe reason.
"""

import argparse
import json
import subprocess
import sys

SAFE = {
    "font",
    "binary",
    "manpage",
    "bash_completion",
    "fish_completion",
    "zsh_completion",
}

# Present in `artifacts` but install nothing: uninstall/zap describe removal,
# target renames another artifact's destination, caveats is prose.
METADATA = {"zap", "uninstall", "target", "caveats"}


def installing_kinds(cask):
    """The artifact kinds this cask actually installs something for."""
    kinds = set()
    for artifact in cask.get("artifacts", []):
        # Entries are dicts keyed by artifact kind; older/newer shapes may
        # include bare strings, which carry no kind and are ignored.
        if isinstance(artifact, dict):
            kinds.update(artifact)
    return kinds - METADATA


def _brew_info_batch(tokens):
    out = subprocess.run(
        ["brew", "info", "--cask", "--json=v2", *tokens],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return json.loads(out)


def brew_info(tokens):
    """Ask brew about every token, tolerating ones it does not recognise.

    `brew info` fails the WHOLE invocation if any single token is unknown, so
    one cask renamed or dropped from the tap would otherwise take the weekly
    font upgrade down with it. Falling back to one query per token keeps the
    rest classifiable; the unknown one then simply never appears in the result
    and main() marks it `manual unknown`, which is the fail-safe answer anyway.
    """
    try:
        return _brew_info_batch(tokens)
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        pass

    casks = []
    for token in tokens:
        try:
            casks.extend(_brew_info_batch([token]).get("casks", []))
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            continue
    return {"casks": casks}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tokens", nargs="+")
    ap.add_argument("--from-json", metavar="FILE")
    args = ap.parse_args()

    try:
        if args.from_json:
            with open(args.from_json, encoding="utf-8") as fh:
                data = json.load(fh)
        else:
            data = brew_info(args.tokens)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"caskclassify: {exc}", file=sys.stderr)
        return 1

    by_token = {c["token"]: c for c in data.get("casks", []) if "token" in c}

    for token in args.tokens:
        cask = by_token.get(token)
        if cask is None:
            print(f"manual\t{token}\tunknown")
            continue
        kinds = installing_kinds(cask)
        unsafe = sorted(kinds - SAFE)
        if kinds and not unsafe:
            print(f"auto\t{token}")
        else:
            # A cask with no installing artifact at all is `manual` too: there
            # is nothing to gain by automating it and the shape is unexpected.
            print(f"manual\t{token}\t{','.join(unsafe) or 'no-artifacts'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
