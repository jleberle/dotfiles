# Automation: bin scripts, launchd agents, and macOS Services

Three kinds of automation live here: standalone scripts in `bin/` (on `PATH`,
run by name from any shell), **launchd agents** (macOS's built-in scheduler —
the equivalent of cron — running the recurring jobs below), and Automator
workflows that add entries to the macOS Services menu.

## Bin

Scripts in `bin/` are on `PATH` via `shell/fish/conf.d/env.fish`. Every Python
script here (`ipic`, `waybackup`, `citecheck.py`, `zotcheck.py`, `readnote.py`,
`mdlinks.py`) is stdlib-only — no third-party packages, no venv, no `uv`.
`citecheck.py` / `zotcheck.py` / `readnote.py` / `mdlinks.py` are the extracted
logic behind the same-named fish functions (see
[Writing](writing.md#writing-functions-and-aliases-fish)) — the fish wrappers
validate args/env and invoke them.

| Script                              | Purpose                                                                                                              |
|-------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `ipic -i\|-m\|-a\|-f\|-t\|-b TERM`  | Build an HTML gallery of iTunes/App Store artwork and open it. Flags: `-i` iOS app, `-m` Mac app, `-a` album, `-f` film, `-t` TV, `-b` book. |
| `waybackup <URL>`                   | Save a URL to the Internet Archive Wayback Machine; prints the snapshot URL.                                         |
| `homebrewupdate.sh`                 | `brew update` + `outdated` + `upgrade`, with timestamped log output; caps its own log at 1 MB.                        |
| `mailsync.sh`                       | `mbsync -a` + `notmuch new` with timestamped log output; invoked by the mailsync launchd agent. Tracks each step's exit status and sends a macOS notification when sync starts failing (and again when it recovers) — the log alone was never read. |
| `citecheck.py` / `zotcheck.py` / `readnote.py` | Logic behind the `citecheck` / `zotcheck` / `readnote` fish functions; exercised by `make writing-check`. |
| `mdlinks.py`                        | Logic behind the `mdlinks` fish function: turns a list of browser tabs into Markdown reference definitions. Reads URLs on stdin (Safari), or decodes Firefox's `recovery.jsonlz4` session store with `--firefox` — Firefox exposes no AppleScript tab list, so the session store is the only way to read its tabs without simulating keystrokes. Exercised by `make writing-check`. |

## Launchd

`make brewauto`, `make mailsync`, `make resticcheck`, and `make decksync`
install user LaunchAgents (`__HOME__` is substituted with your real home at
install time):

| Agent                             | Schedule         | Runs                                                                  |
|-----------------------------------|------------------|-----------------------------------------------------------------------|
| `org.jaredeberle.brewupdate`      | Mondays 09:00    | `bin/homebrewupdate.sh`                                               |
| `org.jaredeberle.mailsync`        | Every 5 minutes  | `bin/mailsync.sh`                                                     |
| `org.jaredeberle.resticcheck`     | Sundays 10:00    | `arch backup check` (restic integrity; no-op if the drive is unmounted) |
| `org.jaredeberle.decksync`        | On volume mount  | `keynote/sync_slides_drive.sh` (via `DeckSync.app`) — pushes `.pptx` + PDF exports of the Keynote lecture decks to the "R2-D2" flash drive (`WatchPaths` on `/Volumes`; no-op unless that drive appeared) |

Logs: `~/.local/brew_update_logs.txt` (newest run first),
`~/.local/mail_sync_logs.txt`, `~/.local/restic_check_logs.txt`. Trigger a run
on demand:

```sh
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.brewupdate
launchctl kickstart -k gui/$(id -u)/org.jaredeberle.mailsync
```

## macOS Services

`make services` (run automatically by `make install`) symlinks every Automator
workflow in `macos/services/` into `~/Library/Services`. Only one remains, and
it earns the format: it acts on the page in front of you and is driven by a
hotkey, which is what the Services menu is for.

| Service           | Does                                            |
|-------------------|-------------------------------------------------|
| `Open in Firefox` | Opens the frontmost Safari tab's URL in Firefox |

`Open in Firefox` is meant to be bound to a hotkey (System Settings → Keyboard →
Keyboard Shortcuts → Services). Because that hotkey uses Option — which triggers
Firefox's Troubleshoot/safe mode if held during a cold launch — the script only
launches the binary directly (with `MOZ_DISABLE_SAFE_MODE_KEY=1`) when Firefox is
closed; when it's already running it hands the URL off with `open -a Firefox`,
which opens a new tab reliably and skips the startup modifier check entirely. The
cold-start path passes `-new-tab` so the URL isn't swallowed by session restore.

To add another, drop the `.workflow` bundle into `macos/services/` and re-run
`make services`; `make doctor` then verifies the symlink. Restart the target
app (or `killall Finder`) if the Services menu doesn't refresh.

> The Markdown Service Tools this setup once carried are all gone now, for the
> same reason: macOS Services only fire from a GUI app's menu, and this is a
> Neovim/NeoMutt/Pandoc setup, so they had nowhere useful to fire. The text
> transforms went first (they duplicated `pandoc`/Neovim). The two tab-listers
> followed — they declared `service input: nothing` and `service output: text`,
> meaning they typed their result at the cursor of a GUI text field, which a
> draft open in Neovim never is. Their logic lived as ~90 lines of Ruby each
> inside a `.workflow` plist, where `git diff` showed only a blob and no
> `make lint-*` target could read it; two latent crashes had sat there unseen
> for years. Both now live in `mdlinks`, which writes to stdout and composes:
> `mdlinks firefox | pbcopy`. See [Shell → Functions](shell.md#functions-shellfishfunctions).
