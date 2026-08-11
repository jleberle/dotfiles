DOTFILES := $(HOME)/git/dotfiles

# Every symlink this Makefile creates points into $(DOTFILES), which is
# hardcoded above. Clone the repo anywhere else and `make install` happily
# builds a working-looking set of links to a directory that isn't there — the
# breakage shows up later, somewhere else, as missing config. Refuse instead.
ifneq ($(realpath $(CURDIR)),$(realpath $(DOTFILES)))
$(error This repo must live at $(DOTFILES), but make is running in $(CURDIR). Move the clone there, or edit DOTFILES at the top of this Makefile)
endif

LAUNCHD_UID := $(shell id -u)
LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
GHOSTTY_DIR := $(HOME)/Library/Application Support/com.mitchellh.ghostty

# Homebrew prefix (Apple Silicon).
HOMEBREW_PREFIX := /opt/homebrew

FIREFOX_DIR := $(HOME)/Library/Application Support/Firefox
SERVICES_DIR := $(HOME)/Library/Services

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

.PHONY: default install git shell chsh security firefox betterfox-update apps brewauto nvim vale neomutt mailsync resticcheck decksync services macos macos-check harden touchid update doctor check lint lint-shellcheck lint-fish lint-python lint-luacheck lint-secrets lint-plists writing-check nvim-check brew-check brew-drift

default :
	@echo "There is no default for your own safety."

install : apps git shell security nvim vale neomutt services brewauto
	@echo ""
	@echo "Run 'make firefox' after launching Firefox once."
	@echo "If you use NeoMutt, finish setup with: make mailsync"
	@echo "Optional system hardening (each needs sudo): make harden, make touchid"
	@echo "Optional backup integrity check: make resticcheck (after archbackup is set up)"
	@echo ""
	@$(MAKE) doctor

git :
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
chsh :
	@grep -qF "$(HOMEBREW_PREFIX)/bin/fish" /etc/shells || \
	    { echo "Adding fish to /etc/shells"; echo "$(HOMEBREW_PREFIX)/bin/fish" | sudo tee -a /etc/shells; }
	@dscl . -read /Users/$(USER) UserShell 2>/dev/null | grep -qF "$(HOMEBREW_PREFIX)/bin/fish" && \
	    echo "fish is already the login shell" || \
	    { echo "Setting fish as login shell" && \
	      sudo dscl . -create /Users/$(USER) UserShell "$(HOMEBREW_PREFIX)/bin/fish" && \
	      echo "Done — open a new terminal to start using fish"; }
shell :
	@echo "Symlinking fish, tmux, and bat config"
	$(call install_symlinks,shell)
	@echo "Run 'make chsh' to set fish as your login shell (requires sudo)"
	@echo "Symlinking Ghostty config"
	mkdir -p "$(GHOSTTY_DIR)"
	@target="$(GHOSTTY_DIR)/config"; $(backup_if_real)
	ln -sf $(DOTFILES)/shell/ghostty/config "$(GHOSTTY_DIR)/config"
security :
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
firefox :
	@PROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null) && \
	[ -n "$$PROFILE" ] || { echo "ERROR: Firefox profile not found — launch Firefox first"; exit 1; } && \
	[ -d "$(FIREFOX_DIR)/$$PROFILE" ] || { echo "ERROR: profile directory missing: $(FIREFOX_DIR)/$$PROFILE"; exit 1; } && \
	[ -f "$(DOTFILES)/security/betterfox/user.js" ] || { echo "ERROR: Betterfox user.js not found — run: git submodule update --init --recursive"; exit 1; } && \
	echo "Writing user.js → $$PROFILE (Betterfox + overrides)" && \
	cat $(DOTFILES)/security/betterfox/user.js \
	    $(DOTFILES)/security/user-overrides.js \
	    > "$(FIREFOX_DIR)/$$PROFILE/user.js"

betterfox-update :
	@echo "Updating Betterfox submodule to latest upstream..."
	git submodule update --remote security/betterfox
	@echo "Done. Review changes with: git diff security/betterfox"
	@echo "Then re-run 'make firefox' to rebuild the profile user.js."
services :
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
apps :
	@command -v brew >/dev/null 2>&1 || { \
		echo "Homebrew not found. Installing..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	}
	@# Absolute path, not bare `brew`: the official installer doesn't add brew to
	@# the current process PATH, so a fresh-machine first run would otherwise fail.
	$(HOMEBREW_PREFIX)/bin/brew bundle install --file=$(DOTFILES)/homebrew/brewfile
brewauto :
	@echo "Installing Homebrew auto-update LaunchAgents"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(DOTFILES)/homebrew/org.jaredeberle.brewupdate.plist)
	@echo "Installed. Logs at $(HOME)/.local/brew_update_logs.txt (newest run first)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate"
macos :
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
macos-check :
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
harden :
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
touchid :
	@echo "Enabling Touch ID for sudo via /etc/pam.d/sudo_local (requires sudo)"
	@[ -f "$(HOMEBREW_PREFIX)/lib/pam/pam_reattach.so" ] || \
	    echo "NOTE: pam-reattach not installed — Touch ID won't work inside tmux (run: make apps)"
	@printf '# Managed by dotfiles `make touchid`. sudo_local survives OS updates.\n# pam_reattach must precede pam_tid so Touch ID works inside tmux.\nauth       optional       %s/lib/pam/pam_reattach.so\nauth       sufficient     pam_tid.so\n' \
	    "$(HOMEBREW_PREFIX)" | sudo tee /etc/pam.d/sudo_local >/dev/null
	@# Standard perms for a pam.d file (644) — not whatever umask 077 left it at,
	@# which would also block `make macos-check` from reading it back.
	sudo chmod 644 /etc/pam.d/sudo_local
	@echo "Done. Open a new shell and run any 'sudo' command to test (Touch ID prompt)."
nvim :
	@echo "Symlinking nvim config"
	$(call install_symlinks,nvim)
vale :
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
neomutt :
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
mailsync :
	@echo "Installing mail sync LaunchAgent"
	mkdir -p $(LAUNCH_AGENTS)
	chmod +x $(DOTFILES)/bin/mailsync.sh
	$(call install_agent,$(DOTFILES)/writing/neomutt/org.jaredeberle.mailsync.plist)
	@echo "Mail sync running every 5 minutes."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.mailsync"
resticcheck :
	@echo "Installing weekly restic integrity-check LaunchAgent"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(DOTFILES)/backup/org.jaredeberle.resticcheck.plist)
	@echo "Runs 'archbackup check' every Sunday 10:00 (no-op when the drive is unmounted)."
	@echo "Requires ARCHIVE_RESTIC_REPO + RESTIC_PASSWORD_FILE universal vars (see archbackup)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.resticcheck"
decksync :
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
update :
	@echo "Updating Neovim plugins (Lazy sync)..."
	@if command -v nvim >/dev/null 2>&1; then nvim --headless "+Lazy! sync" +qa; \
	    else echo "  (nvim not installed; run: make apps)"; fi
	@echo "Syncing Vale styles..."
	@if command -v vale >/dev/null 2>&1; then vale sync; \
	    else echo "  (vale not installed; run: make apps)"; fi
	@echo ""
	@echo "Not auto-run here (deliberately):"
	@echo "  * Homebrew updates weekly via launchd — run 'brewup' to update now."
	@echo "  * Betterfox is review-gated — run 'make betterfox-update', review, then 'make firefox'."
	@echo "  * CI's gitleaks is pinned by version AND checksum in"
	@echo "    .github/workflows/ci.yml. Local gitleaks comes from Homebrew, so the"
	@echo "    two drift apart silently. Current CI pin vs. local:"
	@printf '      CI:    %s\n' "$$(awk -F'v' '/releases\/download\/v/{split($$2,a,"/"); print a[1]; exit}' $(DOTFILES)/.github/workflows/ci.yml)"
	@printf '      local: %s\n' "$$(gitleaks version 2>/dev/null || echo '<not installed>')"
	@echo "    To bump: edit the three v8.x.y strings, then replace the sha256 with"
	@echo "    the one from that release's checksums.txt on GitHub."
	@echo "Review and commit writing/nvim/lazy-lock.json if Lazy changed it."
lint : lint-shellcheck lint-fish lint-python lint-luacheck lint-secrets
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
lint-plists :
	@echo "Linting macOS plist/workflow files..."
	@command -v plutil >/dev/null 2>&1 || { echo "ERROR: plutil not found — macOS only"; exit 1; }
	@find backup homebrew keynote writing macos/services -type f \( -name '*.plist' -o -name '*.wflow' \) -print0 | xargs -0 -n1 plutil -lint
writing-check :
	@echo "Running writing workflow checks..."
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found"; exit 1; }
	@./tests/writing-check.sh
nvim-check :
	@echo "Running headless Neovim smoke test..."
	@command -v nvim >/dev/null 2>&1 || { echo "ERROR: nvim not found — install it first (make apps)"; exit 1; }
	@command -v fish >/dev/null 2>&1 || { echo "ERROR: fish not found — install it first (make apps)"; exit 1; }
	@tmp=$$(mktemp -d); \
	    trap 'rm -rf "$$tmp"' EXIT; \
	    mkdir -p "$$tmp/config" "$$tmp/data" "$$tmp/state" "$$tmp/cache"; \
	    cp -R "$(DOTFILES)/writing/nvim" "$$tmp/config/nvim"; \
	    XDG_CONFIG_HOME="$$tmp/config" XDG_DATA_HOME="$$tmp/data" XDG_STATE_HOME="$$tmp/state" XDG_CACHE_HOME="$$tmp/cache" \
	        fish -c 'source $(DOTFILES)/shell/fish/conf.d/paths.fish; nvim --headless -c "lua assert(require([[config.paths]]).zotero_library_bib():find([[Library.bib]], 1, true))" -c qa'
brew-check :
	@echo "Checking Brewfile packages..."
	@# The WARNING: prefix is the shared contract with `make check`, which
	@# counts and re-lists those lines in its summary — see the note there.
	@brew bundle check --file=$(DOTFILES)/homebrew/brewfile --no-upgrade || \
	    echo "WARNING: some Brewfile packages are missing (run: make apps)"

brew-drift :
	@echo "Checking for formulae/casks installed but not in the Brewfile..."
	@brew bundle cleanup --file=$(DOTFILES)/homebrew/brewfile || true
	@echo ""
	@echo "Nothing listed above = no drift. To add a package, edit the Brewfile;"
	@echo "to uninstall the drift instead, run: brew bundle cleanup --force --file=$(DOTFILES)/homebrew/brewfile"
doctor :
	@echo "Checking symlinks..."
	@for row in $(foreach r,$(SYMLINK_ROWS),'$(r)'); do \
	    IFS='|'; set -- $$row; unset IFS; \
	    test -L "$$3" || echo "WARNING: $$3 not symlinked (run: make $$1)"; \
	done
	@test -L "$(HOME)/Library/Application Support/lazygit/config.yml" || echo "WARNING: lazygit config not symlinked (run: make git)"
	@test -L "$(GHOSTTY_DIR)/config"           || echo "WARNING: ghostty config not symlinked (run: make shell)"
	@HP=$$(git config --global core.hooksPath); \
	case "$$HP" in \
	    "$(DOTFILES)/git/hooks"|"~/git/dotfiles/git/hooks") ;; \
	    *) echo "WARNING: git core.hooksPath not set to dotfiles hooks (run: make git)" ;; \
	esac
	@command -v gitleaks >/dev/null 2>&1 || echo "WARNING: gitleaks not installed — pre-commit secret scan inactive (run: make apps)"
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
	    name=$$(basename "$$wf"); \
	    test -L "$(SERVICES_DIR)/$$name" || \
	        echo "WARNING: Service '$$name' not symlinked (run: make services)"; \
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
	@echo "Done."
check :
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
	echo "Run 'make brew-drift' to also list untracked installs."; \
	rm -f "$$tmp"
