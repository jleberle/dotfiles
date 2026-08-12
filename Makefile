DOTFILES := $(HOME)/git/dotfiles

# Every symlink this Makefile creates points into $(DOTFILES), hardcoded above —
# and so do git/gitconfig (hooksPath), paths.env, the launchd plists, and
# writing/pandoc/metadata.yaml.tmpl. Clone the repo anywhere else and `make install`
# happily builds a working-looking set of links to a directory that isn't there;
# the breakage shows up later, somewhere else, as missing config.
#
# This is a prerequisite rather than a top-of-file $(error) because a parse-time
# error fires on EVERY target, including the read-only lint ones. CI checks out
# to its own runner path and runs `make lint-shellcheck` there, so the parse-time
# form failed the whole build on a rule that has nothing to do with linting.
# Guard the targets that write to the machine; leave reading alone.
require-location :
	@[ "$$(cd "$(CURDIR)" && pwd -P)" = "$$(cd "$(DOTFILES)" 2>/dev/null && pwd -P)" ] || { \
	    echo "This repo must live at $(DOTFILES), but make is running in $(CURDIR)." >&2; \
	    echo "Move the clone there, or edit DOTFILES at the top of this Makefile." >&2; \
	    exit 1; }

LAUNCHD_UID := $(shell id -u)
LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
GHOSTTY_DIR := $(HOME)/Library/Application Support/com.mitchellh.ghostty

# Homebrew prefix (Apple Silicon).
HOMEBREW_PREFIX := /opt/homebrew

FIREFOX_DIR := $(HOME)/Library/Application Support/Firefox
SERVICES_DIR := $(HOME)/Library/Services

# How stale a restic verification may get before `make doctor` says so. The
# check runs weekly, so this allows the backup drive to stay unplugged for about
# a month without nagging — long enough not to be noise, short enough that an
# unverified backup cannot quietly become a year old. See the doctor rule.
RESTIC_VERIFY_MAX_AGE_DAYS := 35

# Globbed, not listed. These were hand-maintained, which meant adding a script
# left it silently unlinted forever and CI still went green — the one failure a
# linter must not have. FISH_FILES and LUACHECK_DIR below already globbed.
SHELLCHECK_FILES := $(wildcard bin/*.sh) $(wildcard keynote/*.sh) $(wildcard git/hooks/*) $(wildcard tests/*.sh)
# Cannot glob cleanly: `waybackup` and `ipic` are extensionless Python, so they
# are named. Everything with a .py extension is picked up automatically.
PYTHON_FILES := $(wildcard bin/*.py) bin/waybackup bin/ipic
FISH_FILES := shell/fish/config.fish shell/fish/conf.d/*.fish shell/fish/functions/*.fish shell/fish/completions/*.fish
LUACHECK_DIR := writing/nvim/lua

# Managed macOS defaults, one row per line: domain|key|type|value.
# `make macos` writes every row; `make macos-check` reads each back and warns
# on drift — edit only this table to change either. Bools are written as
# true/false but read back as 1/0; the check target translates. Values must
# not contain `|` or spaces (rows are split on whitespace, then on `|`).
define MACOS_DEFAULTS
NSGlobalDomain|ApplePressAndHoldEnabled|bool|false
NSGlobalDomain|KeyRepeat|int|2
NSGlobalDomain|InitialKeyRepeat|int|15
NSGlobalDomain|AppleShowAllExtensions|bool|true
com.apple.finder|ShowPathbar|bool|true
com.apple.finder|ShowStatusBar|bool|true
com.apple.finder|_FXSortFoldersFirst|bool|true
com.apple.finder|FXDefaultSearchScope|string|SCcf
com.apple.finder|FXEnableExtensionChangeWarning|bool|false
com.apple.desktopservices|DSDontWriteNetworkStores|bool|true
com.apple.desktopservices|DSDontWriteUSBStores|bool|true
com.apple.dock|autohide|bool|true
com.apple.dock|show-recents|bool|false
com.apple.dock|minimize-to-application|bool|true
com.apple.screencapture|location|string|$(HOME)/Desktop/Screenshots
com.apple.screencapture|disable-shadow|bool|true
NSGlobalDomain|NSNavPanelExpandedStateForSaveMode|bool|true
NSGlobalDomain|NSNavPanelExpandedStateForSaveMode2|bool|true
NSGlobalDomain|PMPrintingExpandedStateForPrint|bool|true
NSGlobalDomain|PMPrintingExpandedStateForPrint2|bool|true
NSGlobalDomain|NSDocumentSaveNewDocumentsToCloud|bool|false
NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|bool|false
NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|bool|false
com.apple.screensaver|askForPassword|int|1
com.apple.screensaver|askForPasswordDelay|int|0
endef
# Newlines collapsed to spaces so the rows can be spliced into a recipe line.
# (Apple's make 3.81 cannot export a multi-line variable to recipe shells.)
MACOS_DEFAULT_ROWS := $(strip $(MACOS_DEFAULTS))

# Managed dotfiles symlinks, one row per line: group|source|target. `group` is
# the owning target's name (git, shell, security, nvim, neomutt) — each of
# those targets calls $(call install_symlinks,<group>) to create just its own
# rows, and `make doctor` loops over every row to check they're all still in
# place. Edit only this table to add, move, or remove a symlink; sources are
# relative to $(DOTFILES).
#
# Two destinations are deliberately NOT here (Ghostty, lazygit — both land
# under "Application Support"): this table is split on whitespace the same
# way MACOS_DEFAULTS is, so a literal space in a field would corrupt the
# split. Those two stay hand-written in the `shell`/`git` targets and in
# `doctor` below.
define SYMLINKS
git|git/gitconfig|$(HOME)/.gitconfig
git|git/gitignore|$(HOME)/.gitignore
git|git/gitmessage|$(HOME)/.gitmessage
shell|shell/fish|$(HOME)/.config/fish
shell|shell/tmux.conf|$(HOME)/.tmux.conf
shell|shell/bat/config|$(HOME)/.config/bat/config
security|security/ssh-config|$(HOME)/.ssh/config
security|security/known_hosts|$(HOME)/.ssh/known_hosts_pinned
security|security/gpg.conf|$(HOME)/.gnupg/gpg.conf
security|security/dirmngr.conf|$(HOME)/.gnupg/dirmngr.conf
security|security/common.conf|$(HOME)/.gnupg/common.conf
nvim|writing/nvim|$(HOME)/.config/nvim
neomutt|writing/neomutt/neomuttrc|$(HOME)/.config/neomutt/neomuttrc
neomutt|writing/neomutt/gpg.rc|$(HOME)/.config/neomutt/gpg.rc
neomutt|writing/neomutt/colors.rc|$(HOME)/.config/neomutt/colors.rc
neomutt|writing/neomutt/mailcap|$(HOME)/.config/neomutt/mailcap
endef
SYMLINK_ROWS := $(strip $(SYMLINKS))

# Canned recipe: $(call install_symlinks,<group>) — creates every SYMLINKS row
# tagged with <group>. mkdir -p covers a parent dir that doesn't exist yet
# (e.g. a clean ~/.config).
#
# The `-e && ! -L` guard is load-bearing, not belt-and-braces. `ln -sfn` replaces
# an existing *symlink*, but against an existing *real directory* it silently
# creates the link INSIDE it — so on a Mac that has already run fish or nvim,
# `ln -sfn .../shell/fish ~/.config/fish` yields ~/.config/fish/fish and the
# config never loads. `doctor` then reports "not symlinked (run: make shell)",
# and re-running make shell does the same nothing: a loop with no way out.
# Real files have the matching problem — an existing ~/.gitconfig would be
# replaced outright with no copy kept. So anything that is not already a symlink
# is moved aside to <target>.bak-<timestamp> first, and the move is announced.
define install_symlinks
@for row in $(foreach r,$(SYMLINK_ROWS),'$(r)'); do \
    IFS='|'; set -- $$row; unset IFS; \
    if [ "$$1" = "$(1)" ]; then \
        mkdir -p "$$(dirname "$$3")"; \
        target="$$3"; $(backup_if_real); \
        ln -sfn "$(DOTFILES)/$$2" "$$3"; \
        echo "  $$2 -> $$3"; \
    fi; \
done
endef

# Shell fragment: move "$$target" aside if it exists and is not a symlink. Set
# `target=...` first, then invoke. Used by install_symlinks above and by the two
# hand-written destinations under "Application Support" (Ghostty, lazygit) that
# cannot live in the SYMLINKS table because the split would break on the space.
backup_if_real = \
    if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
        backup="$$target.bak-$$(date +%Y%m%d-%H%M%S)"; \
        mv "$$target" "$$backup"; \
        echo "  NOTE: $$target already existed and was not a symlink"; \
        echo "        moved to $$backup"; \
    fi

# Shell fragment: warn unless "$$target" is a symlink that actually RESOLVES.
# Set `target=...` and `fix=...` first, then invoke. Used by every symlink check
# in `doctor`.
#
# A bare `test -L` was the bug this replaces. It is true for a DANGLING symlink,
# so a link left pointing at a previous checkout location passed the health check
# while nothing it named was loading. Found when all three ~/Library/Services
# links turned out to aim at a ~/.dotfiles path that had not existed since the
# repo moved to ~/git/dotfiles — `make doctor` had been reporting a clean machine
# the whole time. That is the same class of failure require-location guards on
# the WRITE side, missed here on the read side.
check_symlink = \
    if [ ! -L "$$target" ]; then \
        echo "WARNING: $$target not symlinked (run: $$fix)"; \
    elif [ ! -e "$$target" ]; then \
        echo "WARNING: $$target is a broken symlink -> $$(readlink "$$target") (run: $$fix)"; \
    fi

# Canned recipe: $(call install_agent,<source plist path>) — template __HOME__ /
# __HOMEBREW_PREFIX__ into ~/Library/LaunchAgents, lint, and (re)load it. The
# launchd label is the plist filename without its .plist suffix. Used by the
# brewauto / mailsync / resticcheck targets so the install dance lives once.
define install_agent
sed -e 's|__HOMEBREW_PREFIX__|$(HOMEBREW_PREFIX)|g' -e 's|__HOME__|$(HOME)|g' $(1) > $(LAUNCH_AGENTS)/$(notdir $(1))
plutil -lint $(LAUNCH_AGENTS)/$(notdir $(1))
-launchctl bootout gui/$(LAUNCHD_UID)/$(basename $(notdir $(1))) 2>/dev/null
launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/$(notdir $(1))
endef

.PHONY: default help require-location install git shell chsh security firefox betterfox-update apps brewauto nvim emacs vale neomutt mailsync resticcheck decksync services macos macos-check harden touchid update doctor check lint lint-shellcheck lint-fish lint-python lint-luacheck lint-secrets lint-plists writing-check nvim-check emacs-check brew-check brew-drift

# `make` alone still does nothing — running `install` by accident is the thing
# worth preventing — but refusing in silence taught the user nothing about what
# to type instead. It prints the target list now, rendered from the `## group |
# description` tags on the target lines themselves so it cannot go stale the way
# a hand-written help string would. Adding a target with a tag lists it; adding
# one without a tag leaves it deliberately unlisted (the lint-* variants).
default : help

help : ## Print this list
	@echo "dotfiles — make targets"
	@echo ""
	@echo "usage: make <target>     (or 'dots <target>' from any directory)"
	@awk 'BEGIN { \
	    n = split("setup link agents system check maintain", order, " "); \
	    title["setup"]   = "SETUP      first run on a new machine"; \
	    title["link"]    = "LINK       symlink one area of config"; \
	    title["agents"]  = "AGENTS     background launchd jobs"; \
	    title["system"]  = "SYSTEM     macOS defaults and hardening"; \
	    title["check"]   = "CHECK      read-only health and lint"; \
	    title["maintain"]= "MAINTAIN   occasional upkeep"; \
	  } \
	  /^[a-z][a-zA-Z0-9_-]* *:/ && /## .*\|/ { \
	    tgt = $$0; sub(/ *:.*/, "", tgt); \
	    rest = substr($$0, index($$0, "## ") + 3); \
	    split(rest, p, "|"); g = p[1]; d = p[2]; \
	    gsub(/^ +| +$$/, "", g); gsub(/^ +| +$$/, "", d); \
	    body[g] = body[g] sprintf("    %-16s %s\n", tgt, d); \
	  } \
	  END { \
	    for (i = 1; i <= n; i++) { k = order[i]; \
	      if (body[k] != "") printf "\n  %s\n%s", title[k], body[k]; } \
	  }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Each lint step also runs alone: lint-shellcheck, lint-fish,"
	@echo "lint-python, lint-luacheck, lint-secrets."
	@echo "Docs: docs/maintenance.md (targets), README.md (setup)."

install : require-location apps git shell security nvim vale neomutt services brewauto ## setup | Full setup: apps, symlinks, agents, then doctor
	@echo ""
	@echo "Run 'make firefox' after launching Firefox once."
	@echo "If you use NeoMutt, finish setup with: make mailsync"
	@echo "Optional system hardening (each needs sudo): make harden, make touchid"
	@echo "Optional backup integrity check: make resticcheck (after arch backup is set up)"
	@echo ""
	@$(MAKE) doctor

git : require-location ## link | gitconfig/gitignore/gitmessage, lazygit, git hooks
	@echo "Symlinking Git files"
	$(call install_symlinks,git)
	@echo "Symlinking lazygit config"
	mkdir -p "$(HOME)/Library/Application Support/lazygit"
	@target="$(HOME)/Library/Application Support/lazygit/config.yml"; $(backup_if_real)
	ln -sf $(DOTFILES)/git/lazygit.yml "$(HOME)/Library/Application Support/lazygit/config.yml"
	@echo "Ensuring git hooks are executable (core.hooksPath → git/hooks)"
	chmod +x $(DOTFILES)/git/hooks/pre-commit $(DOTFILES)/git/hooks/pre-push
	@command -v delta >/dev/null 2>&1 || echo "WARNING: delta not found — git diff/log will fail. Run: make apps"
	@command -v gitleaks >/dev/null 2>&1 || echo "WARNING: gitleaks not found — commits will NOT be scanned for secrets. Run: make apps"
chsh : require-location ## setup | Make fish the login shell (sudo)
	@grep -qF "$(HOMEBREW_PREFIX)/bin/fish" /etc/shells || \
	    { echo "Adding fish to /etc/shells"; echo "$(HOMEBREW_PREFIX)/bin/fish" | sudo tee -a /etc/shells; }
	@dscl . -read /Users/$(USER) UserShell 2>/dev/null | grep -qF "$(HOMEBREW_PREFIX)/bin/fish" && \
	    echo "fish is already the login shell" || \
	    { echo "Setting fish as login shell" && \
	      sudo dscl . -create /Users/$(USER) UserShell "$(HOMEBREW_PREFIX)/bin/fish" && \
	      echo "Done — open a new terminal to start using fish"; }
shell : require-location ## link | fish, Ghostty, tmux, bat
	@echo "Symlinking fish, tmux, and bat config"
	$(call install_symlinks,shell)
	@echo "Run 'make chsh' to set fish as your login shell (requires sudo)"
	@echo "Symlinking Ghostty config"
	mkdir -p "$(GHOSTTY_DIR)"
	@target="$(GHOSTTY_DIR)/config"; $(backup_if_real)
	ln -sf $(DOTFILES)/shell/ghostty/config "$(GHOSTTY_DIR)/config"
security : require-location ## link | SSH + GPG config; writes ~/.gnupg/gpg-agent.conf
	@echo "Creating SSH ControlPath directory"
	mkdir -p $(HOME)/.ssh
	chmod 700 $(HOME)/.ssh
	mkdir -p $(HOME)/.ssh/control
	chmod 700 $(HOME)/.ssh/control
	@echo "Creating GPG home directory"
	@[ ! -L "$(HOME)/.gnupg" ] || { echo "Removing broken .gnupg symlink"; rm "$(HOME)/.gnupg"; }
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking SSH/GPG config files"
	$(call install_symlinks,security)
	@echo "Writing gpg-agent.conf (pinentry path depends on Homebrew prefix: $(HOMEBREW_PREFIX))"
	@[ -f "$(DOTFILES)/security/gpg-agent.conf.tmpl" ] || \
	    { echo "ERROR: gpg-agent.conf.tmpl not found — run: git pull"; exit 1; }
	@[ -d "$(HOME)/.gnupg" ] && [ -w "$(HOME)/.gnupg" ] || \
	    { echo "ERROR: $(HOME)/.gnupg is not a writable directory — check for a broken symlink or permission issue"; exit 1; }
	rm -f $(HOME)/.gnupg/gpg-agent.conf
	sed 's|__HOMEBREW_PREFIX__|$(HOMEBREW_PREFIX)|g' $(DOTFILES)/security/gpg-agent.conf.tmpl > $(HOME)/.gnupg/gpg-agent.conf
	chmod 600 $(HOME)/.gnupg/gpg-agent.conf
firefox : require-location ## link | Write user.js (Betterfox + overrides) to the profile
	@PROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null) && \
	[ -n "$$PROFILE" ] || { echo "ERROR: Firefox profile not found — launch Firefox first"; exit 1; } && \
	[ -d "$(FIREFOX_DIR)/$$PROFILE" ] || { echo "ERROR: profile directory missing: $(FIREFOX_DIR)/$$PROFILE"; exit 1; } && \
	[ -f "$(DOTFILES)/security/betterfox/user.js" ] || { echo "ERROR: Betterfox user.js not found — run: git submodule update --init --recursive"; exit 1; } && \
	echo "Writing user.js → $$PROFILE (Betterfox + overrides)" && \
	{ printf '%s\n' \
	    '// GENERATED FILE — do not edit.' \
	    '//' \
	    '// `make firefox` overwrites this file entirely, by concatenating' \
	    '//   security/betterfox/user.js   (upstream submodule, never edited)' \
	    '//   security/user-overrides.js   (your prefs — edit THIS one)' \
	    '// from the dotfiles repo. Anything you change here is lost on the next run.' \
	    '//' \
	    '// The Betterfox header below says to edit this file to make lasting' \
	    '// changes. Ignore it — that is written for a hand-installed Betterfox.' \
	    '//' \
	    '// Removing a pref from user-overrides.js does NOT revert it. user.js only' \
	    '// SETS values at startup, and the last one set stays in prefs.js. To undo a' \
	    '// pref, set it explicitly to the value you want rather than deleting the line.' \
	    ''; \
	  cat $(DOTFILES)/security/betterfox/user.js \
	      $(DOTFILES)/security/user-overrides.js; \
	} > "$(FIREFOX_DIR)/$$PROFILE/user.js"

betterfox-update : ## maintain | Pull Betterfox upstream; re-run make firefox after
	@echo "Updating Betterfox submodule to latest upstream..."
	git submodule update --remote security/betterfox
	@echo "Done. Review changes with: git diff security/betterfox"
	@echo "Then re-run 'make firefox' to rebuild the profile user.js."
services : require-location ## link | Automator workflows -> ~/Library/Services
	@echo "Symlinking macOS Services (Automator workflows)"
	mkdir -p "$(SERVICES_DIR)"
	@# A real (non-symlink) workflow of the same name is someone's own work, not
	@# ours to replace: this used to `rm -rf` it, which inside `make install`'s
	@# output nobody reads, and it was already gone. Skip and say so instead —
	@# an unlinked service is a visible, fixable problem; a deleted one is not.
	@for wf in $(DOTFILES)/macos/services/*.workflow; do \
	    name=$$(basename "$$wf"); \
	    target="$(SERVICES_DIR)/$$name"; \
	    if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
	        echo "  SKIPPED $$name — a real file/folder is already there, not a symlink."; \
	        echo "          Move or delete '$$target' yourself, then re-run 'make services'."; \
	        continue; \
	    fi; \
	    ln -sfn "$$wf" "$$target"; \
	    echo "  $$name"; \
	done
	@echo "Restart target apps (or 'killall Finder') if the Services menu doesn't refresh."
apps : require-location ## setup | brew bundle against homebrew/brewfile
	@command -v brew >/dev/null 2>&1 || { \
		echo "Homebrew not found. Installing..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	}
	@# Absolute path, not bare `brew`: the official installer doesn't add brew to
	@# the current process PATH, so a fresh-machine first run would otherwise fail.
	@#
	@# umask 022, not the shell's 077 (env.fish). Homebrew installs software that
	@# is meant to be world-readable, and this recipe inherits whatever umask the
	@# calling shell had — so packages installed from fish landed in the Cellar as
	@# drwx------ while the same package installed by the launchd job landed as
	@# drwxr-xr-x. Harmless while brew runs as you, invisible, and impossible to
	@# trace back later. The umask stays 077 for everything you create yourself.
	umask 022 && $(HOMEBREW_PREFIX)/bin/brew bundle install --file=$(CURDIR)/homebrew/brewfile
brewauto : require-location ## agents | launchd agent: update Homebrew weekly
	@echo "Installing Homebrew auto-update LaunchAgents"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(DOTFILES)/homebrew/org.jaredeberle.brewupdate.plist)
	@echo "Installed. Logs at $(HOME)/.local/brew_update_logs.txt (newest run first)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate"
macos : require-location ## system | Write the managed macOS defaults
	@echo "Writing macOS defaults (MACOS_DEFAULTS table)..."
	mkdir -p $(HOME)/Desktop/Screenshots
	@for row in $(foreach r,$(MACOS_DEFAULT_ROWS),'$(r)'); do \
	    IFS='|'; set -- $$row; unset IFS; \
	    echo "  $$1 $$2 = $$4"; \
	    defaults write "$$1" "$$2" "-$$3" "$$4"; \
	done
	@echo "Applying changes..."
	killall Finder
	killall Dock
	killall SystemUIServer
	@echo "Done. Some keyboard changes require a logout to take effect."
macos-check : ## system | Read those defaults back and warn on drift
	@echo "Checking macOS defaults (MACOS_DEFAULTS table)..."
	@for row in $(foreach r,$(MACOS_DEFAULT_ROWS),'$(r)'); do \
	    IFS='|'; set -- $$row; unset IFS; \
	    expected="$$4"; \
	    if [ "$$3" = "bool" ]; then \
	        case "$$4" in true) expected=1 ;; false) expected=0 ;; esac; \
	    fi; \
	    actual=$$(defaults read "$$1" "$$2" 2>/dev/null); \
	    [ "$$actual" = "$$expected" ] || \
	        echo "WARNING: $$1 $$2 is '$${actual:-<unset>}' — want '$$expected' (run: make macos)"; \
	done
	@test -d $(HOME)/Desktop/Screenshots || echo "WARNING: Screenshots folder missing (run: make macos)"
	@echo "  Security"
	@fdesetup status 2>/dev/null | grep -q "FileVault is On" || \
	    echo "WARNING: FileVault is OFF — enable full-disk encryption in System Settings > Privacy & Security"
	@VAL=$$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null); \
	echo "$$VAL" | grep -q "enabled" || echo "WARNING: application firewall not enabled (run: make harden)"
	@VAL=$$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null); \
	echo "$$VAL" | grep -qiw on || echo "WARNING: firewall stealth mode not enabled (run: make harden)"
	@softwareupdate --schedule 2>/dev/null | grep -qi "turned on" || \
	    echo "WARNING: automatic update checks not enabled (run: make harden)"
	@VAL=$$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: automatic security-response install not enabled (run: make harden)"
	@[ -f /etc/pam.d/sudo_local ] && grep -q pam_tid.so /etc/pam.d/sudo_local || \
	    echo "WARNING: Touch ID for sudo not configured (run: make touchid)"
	@echo "Done."
harden : require-location ## system | Firewall, auto security updates, no diagnostics (sudo)
	@# macOS ships home directories as 0750 (group `staff`), which is what makes
	@# ~/Public and personal file sharing work. Nothing here uses either, and
	@# every future local account joins `staff` by default. 0700 does the
	@# keep-other-users-out job once, in a place you can actually SEE
	@# (`ls -ld ~`) and that `make doctor` re-checks — rather than relying on
	@# umask 077 to get every file right forever. The umask stays; this is the
	@# backstop for the files it misses (anything an app creates, anything
	@# restored from a backup, anything that predates the umask).
	@echo "Restricting the home directory to owner-only (0700)"
	chmod 700 $(HOME)
	@echo "Enabling the application firewall (inbound) + stealth mode (requires sudo)"
	sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
	sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
	@echo "Enabling automatic macOS update checks + security-response installs"
	sudo softwareupdate --schedule on
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
	sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
	@echo "Opting out of crash/diagnostic submission to Apple (may be SIP-restricted on newer macOS)"
	-sudo defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false
	-sudo defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" ThirdPartyDataSubmit -bool false
	@echo "Done. Verify with: make macos-check"
touchid : require-location ## system | Touch ID for sudo, tmux-safe (sudo)
	@echo "Enabling Touch ID for sudo via /etc/pam.d/sudo_local (requires sudo)"
	@[ -f "$(HOMEBREW_PREFIX)/lib/pam/pam_reattach.so" ] || \
	    echo "NOTE: pam-reattach not installed — Touch ID won't work inside tmux (run: make apps)"
	@printf '# Managed by dotfiles `make touchid`. sudo_local survives OS updates.\n# pam_reattach must precede pam_tid so Touch ID works inside tmux.\nauth       optional       %s/lib/pam/pam_reattach.so\nauth       sufficient     pam_tid.so\n' \
	    "$(HOMEBREW_PREFIX)" | sudo tee /etc/pam.d/sudo_local >/dev/null
	@# Standard perms for a pam.d file (644) — not whatever umask 077 left it at,
	@# which would also block `make macos-check` from reading it back.
	sudo chmod 644 /etc/pam.d/sudo_local
	@echo "Done. Open a new shell and run any 'sudo' command to test (Touch ID prompt)."
nvim : require-location ## link | writing/nvim -> ~/.config/nvim
	@echo "Symlinking nvim config"
	$(call install_symlinks,nvim)
emacs : require-location ## link | writing/emacs -> ~/.config/emacs (test config mirroring nvim; see docs/emacs.md — not part of `make install` or `make doctor`)
	@echo "Symlinking Emacs config (test setup; run explicitly, not part of make install)"
	@mkdir -p $(HOME)/.config
	@target="$(HOME)/.config/emacs"; $(backup_if_real)
	ln -sfn $(DOTFILES)/writing/emacs "$(HOME)/.config/emacs"
	@echo "  writing/emacs -> $(HOME)/.config/emacs"
vale : require-location ## link | Global ~/.vale.ini, then vale sync
	@command -v vale >/dev/null 2>&1 || { echo "ERROR: vale not found — install it first (make apps)"; exit 1; }
	@echo "Installing global Vale config (used by nvim-lint for prose)"
	mkdir -p $(HOME)/.local/share/vale/styles
	sed 's|__HOME__|$(HOME)|g' $(DOTFILES)/writing/vale/vale.ini > $(HOME)/.vale.ini
	@echo "Wrote $(HOME)/.vale.ini (StylesPath: $(HOME)/.local/share/vale/styles)"
	@echo "Symlinking the Academic vocabulary"
	mkdir -p $(HOME)/.local/share/vale/styles/config/vocabularies
	ln -sfn $(DOTFILES)/writing/vale/vocab/Academic \
	    $(HOME)/.local/share/vale/styles/config/vocabularies/Academic
	vale sync
neomutt : require-location ## link | NeoMutt config, cache dirs, mbsync/notmuch scaffolds
	@echo "Setting up NeoMutt"
	mkdir -p $(HOME)/.config/neomutt/accounts
	mkdir -p $(HOME)/.cache/neomutt/headers
	mkdir -p $(HOME)/.cache/neomutt/messages
	mkdir -p $(HOME)/.mail/proton
	$(call install_symlinks,neomutt)
	@[ -f "$(HOME)/.config/neomutt/accounts/local.rc" ] || \
	    { printf '# NeoMutt account config — fill in your details.\n# See ~/git/dotfiles/writing/neomutt/accounts/example.rc\n' \
	        > "$(HOME)/.config/neomutt/accounts/local.rc"; \
	      echo "REMINDER: edit ~/.config/neomutt/accounts/local.rc with your account details"; }
	@[ -f "$(HOME)/.mbsyncrc" ] || \
	    { cp $(DOTFILES)/writing/neomutt/mbsyncrc $(HOME)/.mbsyncrc; \
	      echo "REMINDER: edit ~/.mbsyncrc and set User to your Proton Bridge email"; }
	@[ -f "$(HOME)/.notmuch-config" ] || \
	    { sed 's|__HOME__|$(HOME)|g' $(DOTFILES)/writing/neomutt/notmuch-config > $(HOME)/.notmuch-config; \
	      echo "REMINDER: edit ~/.notmuch-config with your name and email, then run: notmuch new"; }
	@echo "NeoMutt configured."
mailsync : require-location ## agents | launchd agent: mbsync + notmuch every 5 minutes
	@echo "Installing mail sync LaunchAgent"
	mkdir -p $(LAUNCH_AGENTS)
	chmod +x $(DOTFILES)/bin/mailsync.sh
	$(call install_agent,$(DOTFILES)/writing/neomutt/org.jaredeberle.mailsync.plist)
	@echo "Mail sync running every 5 minutes."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.mailsync"
resticcheck : require-location ## agents | launchd agent: weekly restic integrity check
	@echo "Installing weekly restic integrity-check LaunchAgent"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(DOTFILES)/backup/org.jaredeberle.resticcheck.plist)
	@echo "Runs 'arch backup check' every Sunday 10:00 (no-op when the drive is unmounted)."
	@echo "Requires ARCHIVE_RESTIC_REPO + RESTIC_PASSWORD_FILE universal vars (see arch backup)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.resticcheck"
decksync : require-location ## agents | launchd agent: sync Keynote decks on volume mount
	@# The .app is a wrapper around keynote/sync_slides_drive.sh; if that ever
	@# moves again, fail here rather than installing an agent that no-ops
	@# silently on every volume mount while doctor reports it healthy.
	@[ -f "$(DOTFILES)/keynote/sync_slides_drive.sh" ] || \
	    { echo "ERROR: keynote/sync_slides_drive.sh not found — run: git pull"; exit 1; }
	chmod +x $(DOTFILES)/keynote/sync_slides_drive.sh
	@echo "Building DeckSync.app (thin wrapper so folder access is scoped to one app, not /bin/bash)"
	mkdir -p $(HOME)/Applications
	osacompile -o $(HOME)/Applications/DeckSync.app $(DOTFILES)/keynote/DeckSync.applescript
	@echo "Installing Keynote deck -> Slides flash drive sync LaunchAgent"
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(DOTFILES)/keynote/org.jaredeberle.decksync.plist)
	@echo "Fires whenever a volume is mounted; no-op unless it's the 'R2-D2' drive."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.decksync"
	@echo "Logs: ~/Library/Logs/deck-sync.log (script) and deck-sync-launchd.log (launchd)"
	@echo "NOTE: osacompile regenerates the app's signature every rebuild, which resets"
	@echo "its TCC grants -- if DeckSync.app was rebuilt just now, expect two one-time"
	@echo "prompts on the next run (Documents folder + removable volumes access)."
update : ## maintain | Neovim plugins + vale sync (not Homebrew)
	@echo "Updating Neovim plugins (Lazy sync)..."
	@if command -v nvim >/dev/null 2>&1; then nvim --headless "+Lazy! sync" +qa; \
	    else echo "  (nvim not installed; run: make apps)"; fi
	@echo "Syncing Vale styles..."
	@if command -v vale >/dev/null 2>&1; then vale sync; \
	    else echo "  (vale not installed; run: make apps)"; fi
	@echo ""
	@echo "Not auto-run here (deliberately):"
	@echo "  * Emacs (writing/emacs/) is a test config, not wired into make install/doctor/update —"
	@echo "    update its packages inside Emacs: M-x straight-pull-all, see docs/emacs.md."
	@echo "  * Homebrew updates weekly via launchd — run 'brewup' to update now."
	@echo "  * Betterfox is review-gated — run 'make betterfox-update', review, then 'make firefox'."
	@echo "  * CI's gitleaks is pinned by version AND checksum in"
	@echo "    .github/workflows/ci.yml. Local gitleaks comes from Homebrew, so the"
	@echo "    two drift apart silently. Current CI pin vs. local:"
	@printf '      CI:    %s\n' "$$(awk -F'v' '/releases\/download\/v/{split($$2,a,"/"); print a[1]; exit}' $(CURDIR)/.github/workflows/ci.yml)"
	@printf '      local: %s\n' "$$(gitleaks version 2>/dev/null || echo '<not installed>')"
	@echo "    To bump: edit the three v8.x.y strings, then replace the sha256 with"
	@echo "    the one from that release's checksums.txt on GitHub."
	@echo "Review and commit writing/nvim/lazy-lock.json if Lazy changed it."
lint : lint-shellcheck lint-fish lint-python lint-luacheck lint-secrets ## check | shellcheck, fish, python, luacheck, gitleaks
	@echo "Done."
lint-shellcheck :
	@echo "Running shellcheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "ERROR: shellcheck not found — install it first (make apps)"; exit 1; }
	@shellcheck $(SHELLCHECK_FILES)
lint-fish :
	@echo "Checking fish syntax..."
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@for f in $(FISH_FILES); do \
	    fish --no-execute "$$f" || exit 1; \
	done
lint-python :
	@echo "Checking Python syntax..."
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found"; exit 1; }
	@# Syntax-only check, no third-party linter: py_compile is stdlib and every
	@# script here is stdlib-only, so this needs nothing installed. -X
	@# pycache_prefix redirects the .pyc files it writes into a temp tree, which
	@# is why this leaves no bin/__pycache__ behind (needs Python 3.8+).
	@tmp=$$(mktemp -d); \
	    trap 'rm -rf "$$tmp"' EXIT; \
	    python3 -X pycache_prefix="$$tmp" -m py_compile $(PYTHON_FILES)
lint-luacheck :
	@echo "Running luacheck..."
	@command -v luacheck >/dev/null 2>&1 || { echo "ERROR: luacheck not found — install it first (make apps)"; exit 1; }
	@luacheck $(LUACHECK_DIR)/ --globals vim --no-unused-args
lint-secrets :
	@echo "Running gitleaks (full history)..."
	@command -v gitleaks >/dev/null 2>&1 || { echo "ERROR: gitleaks not found — install it first (make apps)"; exit 1; }
	@gitleaks git --no-banner
lint-plists : ## check | plutil -lint over tracked plists and workflows
	@echo "Linting macOS plist/workflow files..."
	@command -v plutil >/dev/null 2>&1 || { echo "ERROR: plutil not found — macOS only"; exit 1; }
	@find backup homebrew keynote writing macos/services -type f \( -name '*.plist' -o -name '*.wflow' \) -print0 | xargs -0 -n1 plutil -lint
writing-check : ## check | Smoke tests for citecheck/zotcheck/readnote/mdlinks
	@echo "Running writing workflow checks..."
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found"; exit 1; }
	@./tests/writing-check.sh
nvim-check : ## check | Headless Neovim startup test
	@echo "Running headless Neovim smoke test..."
	@command -v nvim >/dev/null 2>&1 || { echo "ERROR: nvim not found — install it first (make apps)"; exit 1; }
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@tmp=$$(mktemp -d); \
	    trap 'rm -rf "$$tmp"' EXIT; \
	    mkdir -p "$$tmp/config" "$$tmp/data" "$$tmp/state" "$$tmp/cache"; \
	    cp -R "$(CURDIR)/writing/nvim" "$$tmp/config/nvim"; \
	    XDG_CONFIG_HOME="$$tmp/config" XDG_DATA_HOME="$$tmp/data" XDG_STATE_HOME="$$tmp/state" XDG_CACHE_HOME="$$tmp/cache" \
	        fish -c 'source $(CURDIR)/shell/fish/conf.d/paths.fish; nvim --headless -c "lua assert(require([[config.paths]]).zotero_library_bib():find([[Library.bib]], 1, true))" -c qa'
emacs-check : ## check | Headless Emacs config smoke test (paths only — no package install, unlike nvim-check's plugin-lazy nvim)
	@echo "Running headless Emacs smoke test..."
	@command -v emacs >/dev/null 2>&1 || { echo "ERROR: emacs not found — install it first (make apps)"; exit 1; }
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@fish -c 'source $(CURDIR)/shell/fish/conf.d/paths.fish; \
	    emacs --batch --no-init-file \
	        --eval "(setq user-emacs-directory \"$(CURDIR)/writing/emacs/\")" \
	        --load "$(CURDIR)/writing/emacs/lisp/config/paths.el" \
	        --eval "(unless (string-match-p \"Library.bib\" (dotfiles/zotero-library-bib)) (error \"zotero-library-bib did not resolve\"))"'
brew-check : ## check | Verify every brewfile package is installed
	@echo "Checking Brewfile packages..."
	@# The WARNING: prefix is the shared contract with `make check`, which
	@# counts and re-lists those lines in its summary — see the note there.
	@brew bundle check --file=$(CURDIR)/homebrew/brewfile --no-upgrade || \
	    echo "WARNING: some Brewfile packages are missing (run: make apps)"
	@# Packages installed from a fish shell before `make apps` set umask 022 landed
	@# in the Cellar as drwx------ instead of drwxr-xr-x. Nothing breaks while brew
	@# runs as you, which is exactly why it needs saying out loud — otherwise the
	@# drift is only discoverable by a second account failing to run something.
	@# go+rX, capital X: adds execute to directories only, never to data files.
	@N=$$(find $(HOMEBREW_PREFIX)/Cellar -maxdepth 2 -type d ! -perm -005 2>/dev/null | wc -l | tr -d ' '); \
	[ "$$N" = 0 ] || \
	    echo "WARNING: $$N Cellar dirs are not world-readable — installed under a restrictive umask (run: chmod -R go+rX $(HOMEBREW_PREFIX)/Cellar)"

brew-drift : ## check | List installed packages missing from the brewfile
	@echo "Checking for formulae/casks installed but not in the Brewfile..."
	@brew bundle cleanup --file=$(CURDIR)/homebrew/brewfile || true
	@echo ""
	@echo "Nothing listed above = no drift. To add a package, edit the Brewfile;"
	@echo "to uninstall the drift instead, run: brew bundle cleanup --force --file=$(CURDIR)/homebrew/brewfile"
doctor : ## check | Symlinks, keys, permissions, shell, agents
	@echo "Checking symlinks..."
	@for row in $(foreach r,$(SYMLINK_ROWS),'$(r)'); do \
	    IFS='|'; set -- $$row; unset IFS; \
	    target="$$3"; fix="make $$1"; $(check_symlink); \
	done
	@target="$(HOME)/Library/Application Support/lazygit/config.yml"; fix="make git"; $(check_symlink)
	@target="$(GHOSTTY_DIR)/config"; fix="make shell"; $(check_symlink)
	@HP=$$(git config --global core.hooksPath); \
	case "$$HP" in \
	    "$(DOTFILES)/git/hooks"|"~/git/dotfiles/git/hooks") ;; \
	    *) echo "WARNING: git core.hooksPath not set to dotfiles hooks (run: make git)" ;; \
	esac
	@command -v gitleaks >/dev/null 2>&1 || echo "WARNING: gitleaks not installed — pre-commit secret scan inactive (run: make apps)"
	@# conf.d/paths.fish wraps its whole parse in `if test -f`, deliberately, since
	@# a missing paths.env means a broken checkout with no worthwhile fallback.
	@# But the else-branch is silence: every workflow function then fails one at a
	@# time with "not configured", which is a true message about the wrong layer.
	@test -f $(CURDIR)/paths.env || \
	    echo "WARNING: paths.env missing — every workflow location is unset (broken checkout? re-clone or restore the file)"
	@if [ -L "$(HOME)/.gnupg/gpg-agent.conf" ]; then echo "WARNING: gpg-agent.conf is a broken symlink (run: make security)"; elif [ ! -f "$(HOME)/.gnupg/gpg-agent.conf" ]; then echo "WARNING: gpg-agent.conf not written (run: make security)"; fi
	@test -f $(HOME)/.mbsyncrc        || echo "WARNING: ~/.mbsyncrc not found (run: make neomutt)"
	@test -f $(HOME)/.notmuch-config  || echo "WARNING: ~/.notmuch-config not found (run: make neomutt)"
	@test -f $(HOME)/.vale.ini                || echo "WARNING: .vale.ini not generated (run: make vale)"
	@test -d $(HOME)/.local/share/vale/styles && \
	    ls $(HOME)/.local/share/vale/styles | grep -q . || \
	    echo "WARNING: vale styles directory empty (run: make vale)"
	@FFPROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null); \
	[ -z "$$FFPROFILE" ] || \
	test -f "$(FIREFOX_DIR)/$$FFPROFILE/user.js" || \
	echo "WARNING: Firefox user.js not written (run: make firefox)"
	@for wf in $(DOTFILES)/macos/services/*.workflow; do \
	    target="$(SERVICES_DIR)/$$(basename "$$wf")"; fix="make services"; $(check_symlink); \
	done
	@echo "Checking SSH keys..."
	@test -f $(HOME)/.ssh/secretive_github.pub   || echo "WARNING: ~/.ssh/secretive_github.pub not found — ssh-config points at it; export this machine's Secretive key (see security/ssh-config)"
	@test -f $(HOME)/.ssh/secretive_codeberg.pub || echo "WARNING: ~/.ssh/secretive_codeberg.pub not found — ssh-config points at it; export this machine's Secretive key (see security/ssh-config)"
	@echo "Checking permissions (no group/other access on keys + secret dirs)..."
	@# %Lp = octal permission bits; owner-only means the group+other digits are 0
	@# (mode ends in "00"), e.g. 700, 600, 400 — anything else grants access.
	@for p in $(HOME)/.ssh $(HOME)/.gnupg $(HOME)/.config/restic/archive.pass; do \
	    [ -e "$$p" ] || continue; \
	    M=$$(stat -f '%Lp' "$$p"); \
	    case "$$M" in *00) ;; *) echo "WARNING: $$p is mode $$M — group/other access; tighten with: chmod go= $$p" ;; esac; \
	done
	@for k in $(HOME)/.ssh/id_*; do \
	    case "$$k" in *.pub) continue ;; esac; \
	    [ -f "$$k" ] || continue; \
	    M=$$(stat -f '%Lp' "$$k"); \
	    case "$$M" in *00) ;; *) echo "WARNING: private key $$k is mode $$M — want 600 (chmod 600 $$k)" ;; esac; \
	done
	@# The home directory itself. macOS ships it 0750, so `staff` — which every
	@# local account joins — can traverse it. `umask 077` in env.fish covers files
	@# this shell creates, but not what an app creates, what a backup restores, or
	@# anything predating the umask. This is the one mode that makes those moot,
	@# and unlike a umask you can see it: ls -ld ~
	@M=$$(stat -f '%Lp' "$(HOME)"); \
	case "$$M" in 700) ;; *) echo "WARNING: home directory is mode $$M — group/other can traverse it (run: make harden)" ;; esac
	@echo "Checking shell..."
	@dscl . -read /Users/$(USER) UserShell 2>/dev/null | grep -qF "$(HOMEBREW_PREFIX)/bin/fish" || \
	    echo "WARNING: fish is not the login shell (run: make chsh)"
	@echo "Checking GPG..."
	@gpg --list-secret-keys 2>/dev/null | grep -q "sec" || \
	    echo "WARNING: no GPG secret key found — import your key"
	@echo "Checking background agents..."
	@for agent in org.jaredeberle.mailsync org.jaredeberle.brewupdate org.jaredeberle.resticcheck org.jaredeberle.decksync; do \
	    if [ -f "$(LAUNCH_AGENTS)/$$agent.plist" ]; then \
	        launchctl print gui/$(LAUNCHD_UID)/$$agent >/dev/null 2>&1 || \
	            echo "WARNING: $$agent plist installed but not loaded (run: launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/$$agent.plist)"; \
	    fi; \
	done
	@# The loop above proves the backup check RAN. This proves it PASSED — a
	@# different question, and the only one that matters. `arch backup check`
	@# exits 0 when the drive is unmounted (deliberately: a weekly failure for a
	@# normally-unplugged drive would train you to ignore the job), so a loaded
	@# agent and a green `make check` read identically whether the backup was
	@# verified last Sunday or has never been verified at all. This machine's
	@# log held seven consecutive skips and zero passes when that was written.
	@# arch backup stamps ~/.local/.restic_verified on a success; this reads
	@# its age. Gated on the plist because `make resticcheck` is opt-in — a
	@# machine that never set up backups should not be nagged about them.
	@STAMP=$(HOME)/.local/.restic_verified; \
	if [ -f "$(LAUNCH_AGENTS)/org.jaredeberle.resticcheck.plist" ]; then \
	    if [ ! -f "$$STAMP" ]; then \
	        echo "WARNING: restic backup has never passed an integrity check (run: arch backup check with the drive mounted)"; \
	    else \
	        D=$$(( ($$(date +%s) - $$(stat -f %m "$$STAMP")) / 86400 )); \
	        [ "$$D" -le $(RESTIC_VERIFY_MAX_AGE_DAYS) ] || \
	            echo "WARNING: restic backup last verified $$D days ago (run: arch backup check with the drive mounted)"; \
	    fi; \
	fi
	@echo "Done."
check : ## check | Everything read-only: doctor + macos-check + brew-check
	@# Runs the three read-only check targets, then summarizes. The summary is
	@# the point: doctor + macos-check + brew-check emit ~30 lines of "Checking
	@# ..." headers, and a WARNING scrolls past in the middle of them. This used
	@# to end with an unconditional "All health checks complete", so a machine
	@# with a dozen real problems still signed off with a success line.
	@#
	@# Every check emits its problems as `WARNING: <what> (run: make <target>)`,
	@# so counting and re-listing those lines needs no other bookkeeping. Adding
	@# a check anywhere means matching that format and nothing else.
	@#
	@# Deliberately still exits 0: a non-zero exit here would print
	@# "make: *** [check] Error 1" under the summary, which reads as "the health
	@# check itself broke" rather than "your machine needs three fixes".
	@tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	$(MAKE) --no-print-directory doctor macos-check brew-check 2>&1 | tee "$$tmp"; \
	n=$$(grep -c '^WARNING:' "$$tmp" 2>/dev/null || true); \
	n=$${n:-0}; \
	echo ""; \
	echo "───────────────────────────────────────────────────────────────"; \
	if [ "$$n" -eq 0 ]; then \
	    echo "  ✓  All health checks passed — nothing to fix."; \
	else \
	    echo "  ✗  $$n problem(s) found:"; \
	    echo ""; \
	    grep '^WARNING:' "$$tmp" | sed 's/^WARNING: /     • /'; \
	    echo ""; \
	    echo "  Each line above ends with the command that fixes it."; \
	fi; \
	echo "───────────────────────────────────────────────────────────────"; \
	echo ""; \
	echo "Run 'make brew-drift' to also list untracked installs."
