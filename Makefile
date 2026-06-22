LAUNCHD_UID := $(shell id -u)
LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
GHOSTTY_DIR := $(HOME)/Library/Application Support/com.mitchellh.ghostty

# Detect Homebrew prefix for cross-architecture installs.
HOMEBREW_PREFIX := $(shell \
	if [ -x /opt/homebrew/bin/brew ]; then echo /opt/homebrew; \
	elif [ -x /usr/local/bin/brew ]; then echo /usr/local; \
	elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then echo /home/linuxbrew/.linuxbrew; \
	else brew --prefix 2>/dev/null || echo /usr/local; fi)

FIREFOX_DIR := $(HOME)/Library/Application Support/Firefox
SERVICES_DIR := $(HOME)/Library/Services

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

.PHONY: default install git shell chsh security firefox betterfox-update apps brewauto nvim vale neomutt mailsync resticcheck services macos macos-check harden touchid update doctor check brew-check brew-drift tools-check clean

default :
	@echo "There is no default for your own safety."

install : apps git shell security nvim vale neomutt services brewauto
	@echo ""
	@echo "Run 'make firefox' after launching Firefox once."
	@echo "Optional system hardening (each needs sudo): make harden, make touchid"
	@echo "Optional backup integrity check: make resticcheck (after archbackup is set up)"
	@echo ""
	@$(MAKE) doctor

git :
	@echo "Symlinking Git files"
	ln -sf $(HOME)/.dotfiles/git/gitconfig $(HOME)/.gitconfig
	ln -sf $(HOME)/.dotfiles/git/gitignore $(HOME)/.gitignore
	ln -sf $(HOME)/.dotfiles/git/gitmessage $(HOME)/.gitmessage
	@echo "Symlinking lazygit config"
	mkdir -p "$(HOME)/Library/Application Support/lazygit"
	ln -sf $(HOME)/.dotfiles/git/lazygit.yml "$(HOME)/Library/Application Support/lazygit/config.yml"
	@echo "Ensuring git hooks are executable (core.hooksPath → git/hooks)"
	chmod +x $(HOME)/.dotfiles/git/hooks/pre-commit
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
	@echo "Symlinking fish config"
	mkdir -p $(HOME)/.config
	ln -sfn $(HOME)/.dotfiles/shell/fish $(HOME)/.config/fish
	@echo "Run 'make chsh' to set fish as your login shell (requires sudo)"
	@echo "Symlinking Ghostty config"
	mkdir -p "$(GHOSTTY_DIR)"
	ln -sf $(HOME)/.dotfiles/shell/ghostty/config "$(GHOSTTY_DIR)/config"
	@echo "Symlinking tmux config"
	mkdir -p $(HOME)/.tmux
	[ -d $(HOME)/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm
	ln -sf $(HOME)/.dotfiles/shell/tmux.conf $(HOME)/.tmux.conf
	@echo "Symlinking bat config"
	mkdir -p $(HOME)/.config/bat
	ln -sf $(HOME)/.dotfiles/shell/bat/config $(HOME)/.config/bat/config
security :
	@echo "Creating SSH ControlPath directory"
	mkdir -p $(HOME)/.ssh/control
	chmod 700 $(HOME)/.ssh/control
	@echo "Symlinking SSH Configurations"
	ln -sf $(HOME)/.dotfiles/security/ssh-config $(HOME)/.ssh/config
	@echo "Symlinking pinned known_hosts (GitHub/Codeberg host keys)"
	ln -sf $(HOME)/.dotfiles/security/known_hosts $(HOME)/.ssh/known_hosts_pinned
	@echo "Creating GPG home directory"
	@[ ! -L "$(HOME)/.gnupg" ] || { echo "Removing broken .gnupg symlink"; rm "$(HOME)/.gnupg"; }
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking GPG Files"
	ln -sf $(HOME)/.dotfiles/security/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Writing gpg-agent.conf (pinentry path depends on Homebrew prefix: $(HOMEBREW_PREFIX))"
	@[ -f "$(HOME)/.dotfiles/security/gpg-agent.conf.tmpl" ] || \
	    { echo "ERROR: gpg-agent.conf.tmpl not found — run: git pull"; exit 1; }
	@[ -d "$(HOME)/.gnupg" ] && [ -w "$(HOME)/.gnupg" ] || \
	    { echo "ERROR: $(HOME)/.gnupg is not a writable directory — check for a broken symlink or permission issue"; exit 1; }
	rm -f $(HOME)/.gnupg/gpg-agent.conf
	sed 's|__HOMEBREW_PREFIX__|$(HOMEBREW_PREFIX)|g' $(HOME)/.dotfiles/security/gpg-agent.conf.tmpl > $(HOME)/.gnupg/gpg-agent.conf
	chmod 600 $(HOME)/.gnupg/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/security/dirmngr.conf $(HOME)/.gnupg/dirmngr.conf
	ln -sf $(HOME)/.dotfiles/security/common.conf $(HOME)/.gnupg/common.conf
firefox :
	@PROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null) && \
	[ -n "$$PROFILE" ] || { echo "ERROR: Firefox profile not found — launch Firefox first"; exit 1; } && \
	[ -d "$(FIREFOX_DIR)/$$PROFILE" ] || { echo "ERROR: profile directory missing: $(FIREFOX_DIR)/$$PROFILE"; exit 1; } && \
	[ -f "$(HOME)/.dotfiles/security/betterfox/user.js" ] || { echo "ERROR: Betterfox user.js not found — run: git submodule update --init --recursive"; exit 1; } && \
	echo "Writing user.js → $$PROFILE (Betterfox + overrides)" && \
	cat $(HOME)/.dotfiles/security/betterfox/user.js \
	    $(HOME)/.dotfiles/security/user-overrides.js \
	    > "$(FIREFOX_DIR)/$$PROFILE/user.js" && \
	[ ! -f $(HOME)/.dotfiles/security/user.js ] || { echo "Removing stale security/user.js from repo directory"; rm $(HOME)/.dotfiles/security/user.js; }

betterfox-update :
	@echo "Updating Betterfox submodule to latest upstream..."
	git submodule update --remote security/betterfox
	@echo "Done. Review changes with: git diff security/betterfox"
	@echo "Then re-run 'make firefox' to rebuild the profile user.js."
services :
	@echo "Symlinking macOS Services (Automator workflows)"
	mkdir -p "$(SERVICES_DIR)"
	@for wf in "$(HOME)"/.dotfiles/macos/services/*.workflow; do \
	    name=$$(basename "$$wf"); \
	    target="$(SERVICES_DIR)/$$name"; \
	    if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
	        echo "  removing existing non-symlink: $$name"; rm -rf "$$target"; \
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
	brew bundle install --file=$(HOME)/.dotfiles/homebrew/brewfile
brewauto :
	@echo "Installing Homebrew auto-update LaunchAgents"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(HOME)/.dotfiles/homebrew/org.jaredeberle.brewupdate.plist)
	$(call install_agent,$(HOME)/.dotfiles/homebrew/org.jaredeberle.brewlogclean.plist)
	@echo "Installed. Logs at $(HOME)/.local/brew_update_logs.txt (newest run first)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate"
macos :
	@echo "Keyboard"
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 15
	@echo "Finder"
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write com.apple.finder ShowPathbar -bool true
	defaults write com.apple.finder ShowStatusBar -bool true
	defaults write com.apple.finder _FXSortFoldersFirst -bool true
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
	@echo "Dock"
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.dock minimize-to-application -bool true
	@echo "Screenshots"
	mkdir -p $(HOME)/Desktop/Screenshots
	defaults write com.apple.screencapture location -string "$(HOME)/Desktop/Screenshots"
	defaults write com.apple.screencapture disable-shadow -bool true
	@echo "System"
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 0
	@echo "Applying changes..."
	killall Finder
	killall Dock
	killall SystemUIServer
	@echo "Done. Some keyboard changes require a logout to take effect."
macos-check :
	@echo "Checking macOS defaults..."
	@echo "  Keyboard"
	@VAL=$$(defaults read NSGlobalDomain ApplePressAndHoldEnabled 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: press-and-hold not disabled (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null); \
	[ "$$VAL" = "2" ] || echo "WARNING: KeyRepeat not set to 2 (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null); \
	[ "$$VAL" = "15" ] || echo "WARNING: InitialKeyRepeat not set to 15 (run: make macos)"
	@echo "  Finder"
	@VAL=$$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: show all extensions not enabled (run: make macos)"
	@VAL=$$(defaults read com.apple.finder ShowPathbar 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: Finder path bar not shown (run: make macos)"
	@VAL=$$(defaults read com.apple.finder ShowStatusBar 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: Finder status bar not shown (run: make macos)"
	@VAL=$$(defaults read com.apple.finder _FXSortFoldersFirst 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: Finder folders not sorted first (run: make macos)"
	@VAL=$$(defaults read com.apple.finder FXDefaultSearchScope 2>/dev/null); \
	[ "$$VAL" = "SCcf" ] || echo "WARNING: Finder search scope not set to current folder (run: make macos)"
	@VAL=$$(defaults read com.apple.finder FXEnableExtensionChangeWarning 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: Finder extension change warning not disabled (run: make macos)"
	@VAL=$$(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: .DS_Store on network volumes not disabled (run: make macos)"
	@VAL=$$(defaults read com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: .DS_Store on USB volumes not disabled (run: make macos)"
	@echo "  Dock"
	@VAL=$$(defaults read com.apple.dock autohide 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: Dock autohide not enabled (run: make macos)"
	@VAL=$$(defaults read com.apple.dock show-recents 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: Dock recent apps not hidden (run: make macos)"
	@VAL=$$(defaults read com.apple.dock minimize-to-application 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: Dock minimize-to-app not enabled (run: make macos)"
	@echo "  Screenshots"
	@test -d $(HOME)/Desktop/Screenshots || echo "WARNING: Screenshots folder missing (run: make macos)"
	@VAL=$$(defaults read com.apple.screencapture location 2>/dev/null); \
	[ "$$VAL" = "$(HOME)/Desktop/Screenshots" ] || echo "WARNING: screenshot location not set (run: make macos)"
	@VAL=$$(defaults read com.apple.screencapture disable-shadow 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: screenshot shadow not disabled (run: make macos)"
	@echo "  System"
	@VAL=$$(defaults read NSGlobalDomain NSNavPanelExpandedStateForSaveMode 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: save panel not expanded by default (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: save panel (2) not expanded by default (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain PMPrintingExpandedStateForPrint 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: print panel not expanded by default (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain PMPrintingExpandedStateForPrint2 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: print panel (2) not expanded by default (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain NSDocumentSaveNewDocumentsToCloud 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: new documents saving to iCloud not disabled (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: smart quotes not disabled (run: make macos)"
	@VAL=$$(defaults read NSGlobalDomain NSAutomaticDashSubstitutionEnabled 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: smart dashes not disabled (run: make macos)"
	@VAL=$$(defaults read com.apple.screensaver askForPassword 2>/dev/null); \
	[ "$$VAL" = "1" ] || echo "WARNING: screensaver password not required (run: make macos)"
	@VAL=$$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null); \
	[ "$$VAL" = "0" ] || echo "WARNING: screensaver password delay not set to 0 (run: make macos)"
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
	ln -sfn $(HOME)/.dotfiles/writing/nvim $(HOME)/.config/nvim
vale :
	@command -v vale >/dev/null 2>&1 || { echo "ERROR: vale not found — install it first (make apps)"; exit 1; }
	@echo "Installing global Vale config (used by nvim-lint for prose)"
	mkdir -p $(HOME)/.local/share/vale/styles
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/writing/vale/vale.ini > $(HOME)/.vale.ini
	@echo "Wrote $(HOME)/.vale.ini (StylesPath: $(HOME)/.local/share/vale/styles)"
	@echo "Symlinking the Academic vocabulary"
	mkdir -p $(HOME)/.local/share/vale/styles/config/vocabularies
	ln -sfn $(HOME)/.dotfiles/writing/vale/vocab/Academic \
	    $(HOME)/.local/share/vale/styles/config/vocabularies/Academic
	vale sync
neomutt :
	@echo "Setting up NeoMutt"
	mkdir -p $(HOME)/.config/neomutt/accounts
	mkdir -p $(HOME)/.cache/neomutt/headers
	mkdir -p $(HOME)/.cache/neomutt/messages
	mkdir -p $(HOME)/.mail/proton
	ln -sf $(HOME)/.dotfiles/writing/neomutt/neomuttrc $(HOME)/.config/neomutt/neomuttrc
	ln -sf $(HOME)/.dotfiles/writing/neomutt/gpg.rc    $(HOME)/.config/neomutt/gpg.rc
	ln -sf $(HOME)/.dotfiles/writing/neomutt/colors.rc $(HOME)/.config/neomutt/colors.rc
	ln -sf $(HOME)/.dotfiles/writing/neomutt/mailcap   $(HOME)/.config/neomutt/mailcap
	@[ -f "$(HOME)/.config/neomutt/accounts/local.rc" ] || \
	    { printf '# NeoMutt account config — fill in your details.\n# See ~/.dotfiles/writing/neomutt/accounts/example.rc\n' \
	        > "$(HOME)/.config/neomutt/accounts/local.rc"; \
	      echo "REMINDER: edit ~/.config/neomutt/accounts/local.rc with your account details"; }
	@[ -f "$(HOME)/.mbsyncrc" ] || \
	    { cp $(HOME)/.dotfiles/writing/neomutt/mbsyncrc $(HOME)/.mbsyncrc; \
	      echo "REMINDER: edit ~/.mbsyncrc and set User to your Proton Bridge email"; }
	@[ -f "$(HOME)/.notmuch-config" ] || \
	    { sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/writing/neomutt/notmuch-config > $(HOME)/.notmuch-config; \
	      echo "REMINDER: edit ~/.notmuch-config with your name and email, then run: notmuch new"; }
	@echo "NeoMutt configured."
mailsync :
	@echo "Installing mail sync LaunchAgent"
	mkdir -p $(LAUNCH_AGENTS)
	chmod +x $(HOME)/.dotfiles/bin/mailsync.sh
	$(call install_agent,$(HOME)/.dotfiles/writing/neomutt/org.jaredeberle.mailsync.plist)
	@echo "Mail sync running every 5 minutes."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.mailsync"
resticcheck :
	@echo "Installing weekly restic integrity-check LaunchAgent"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	$(call install_agent,$(HOME)/.dotfiles/backup/org.jaredeberle.resticcheck.plist)
	@echo "Runs 'archbackup check' every Sunday 10:00 (no-op when the drive is unmounted)."
	@echo "Requires ARCHIVE_RESTIC_REPO + RESTIC_PASSWORD_FILE universal vars (see archbackup)."
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.resticcheck"
update :
	@echo "Updating Neovim plugins (Lazy sync)..."
	@if command -v nvim >/dev/null 2>&1; then nvim --headless "+Lazy! sync" +qa; \
	    else echo "  (nvim not installed; run: make apps)"; fi
	@echo "Updating tmux plugins (TPM)..."
	@if [ -x "$(HOME)/.tmux/plugins/tpm/bin/update_plugins" ]; then \
	    "$(HOME)/.tmux/plugins/tpm/bin/update_plugins" all; \
	    else echo "  (TPM not installed; run: make shell)"; fi
	@echo "Syncing Vale styles..."
	@if command -v vale >/dev/null 2>&1; then vale sync; \
	    else echo "  (vale not installed; run: make apps)"; fi
	@echo ""
	@echo "Not auto-run here (deliberately):"
	@echo "  * Homebrew updates weekly via launchd — run 'brewup' to update now."
	@echo "  * Betterfox is review-gated — run 'make betterfox-update', review, then 'make firefox'."
	@echo "Review and commit writing/nvim/lazy-lock.json if Lazy changed it."
clean :
	@echo "Removing stale artifacts from old repo layouts..."
	@# fish/ at root — predates shell/fish/ (renamed 2026-06-08)
	@[ -d $(HOME)/.dotfiles/fish ] && \
	    echo "Removing stale fish/ at repo root" && \
	    rm -rf $(HOME)/.dotfiles/fish || true
	@# general/ — renamed to security/ (2026-06-08); gpg-agent.conf was gitignored
	@[ -d $(HOME)/.dotfiles/general ] && \
	    echo "Removing stale general/ at repo root" && \
	    rm -rf $(HOME)/.dotfiles/general || true
	@# Python bytecode cache left by running bin/ scripts (ipic/waybackup via uv)
	@[ -d $(HOME)/.dotfiles/bin/__pycache__ ] && \
	    echo "Removing bin/__pycache__" && \
	    rm -rf $(HOME)/.dotfiles/bin/__pycache__ || true
	@echo "Done."
brew-check :
	@echo "Checking Brewfile packages..."
	@brew bundle check --file=$(HOME)/.dotfiles/homebrew/brewfile --no-upgrade || \
	    echo "Run 'make apps' to install missing packages."

brew-drift :
	@echo "Checking for formulae/casks installed but not in the Brewfile..."
	@brew bundle cleanup --file=$(HOME)/.dotfiles/homebrew/brewfile || true
	@echo ""
	@echo "Nothing listed above = no drift. To add a package, edit the Brewfile;"
	@echo "to uninstall the drift instead, run: brew bundle cleanup --force --file=$(HOME)/.dotfiles/homebrew/brewfile"
tools-check :
	@echo "Checking tools..."
	@command -v delta      >/dev/null 2>&1 || echo "WARNING: delta not found (run: make apps)"
	@command -v vale       >/dev/null 2>&1 || echo "WARNING: vale not found (run: make apps)"
	@command -v pandoc     >/dev/null 2>&1 || echo "WARNING: pandoc not found (run: make apps)"
	@command -v pandoc-crossref >/dev/null 2>&1 || echo "WARNING: pandoc-crossref not found (run: make apps)"
	@command -v tectonic   >/dev/null 2>&1 || echo "WARNING: tectonic not found — PDF export will fail (run: make apps)"
	@command -v lazygit    >/dev/null 2>&1 || echo "WARNING: lazygit not found (run: make apps)"
	@command -v lua-language-server >/dev/null 2>&1 || echo "WARNING: lua-language-server not found (run: make apps)"
	@command -v pyright    >/dev/null 2>&1 || echo "WARNING: pyright not found (run: make apps)"
	@command -v bash-language-server >/dev/null 2>&1 || echo "WARNING: bash-language-server not found (run: make apps)"
	@command -v harper-ls  >/dev/null 2>&1 || echo "WARNING: harper-ls not found (run: make apps)"
	@command -v marksman   >/dev/null 2>&1 || echo "WARNING: marksman not found (run: make apps)"
	@command -v stylua     >/dev/null 2>&1 || echo "WARNING: stylua not found (run: make apps)"
	@command -v black      >/dev/null 2>&1 || echo "WARNING: black not found (run: make apps)"
	@command -v prettier   >/dev/null 2>&1 || echo "WARNING: prettier not found (run: make apps)"
	@echo "Done."
doctor :
	@echo "Checking symlinks..."
	@test -L $(HOME)/.gitconfig                || echo "WARNING: .gitconfig not symlinked (run: make git)"
	@test -L $(HOME)/.gitignore                || echo "WARNING: .gitignore not symlinked (run: make git)"
	@test -L $(HOME)/.gitmessage               || echo "WARNING: .gitmessage not symlinked (run: make git)"
	@test -L "$(HOME)/Library/Application Support/lazygit/config.yml" || echo "WARNING: lazygit config not symlinked (run: make git)"
	@test -L $(HOME)/.config/fish              || echo "WARNING: fish config not symlinked (run: make shell)"
	@test -L "$(GHOSTTY_DIR)/config"           || echo "WARNING: ghostty config not symlinked (run: make shell)"
	@HP=$$(git config --global core.hooksPath); \
	case "$$HP" in \
	    "$(HOME)/.dotfiles/git/hooks"|"~/.dotfiles/git/hooks") ;; \
	    *) echo "WARNING: git core.hooksPath not set to dotfiles hooks (run: make git)" ;; \
	esac
	@command -v gitleaks >/dev/null 2>&1 || echo "WARNING: gitleaks not installed — pre-commit secret scan inactive (run: make apps)"
	@test -L $(HOME)/.tmux.conf               || echo "WARNING: .tmux.conf not symlinked (run: make shell)"
	@test -L $(HOME)/.config/bat/config       || echo "WARNING: bat config not symlinked (run: make shell)"
	@test -L $(HOME)/.ssh/config              || echo "WARNING: ssh config not symlinked (run: make security)"
	@test -L $(HOME)/.ssh/known_hosts_pinned  || echo "WARNING: pinned known_hosts not symlinked (run: make security)"
	@test -L $(HOME)/.gnupg/gpg.conf          || echo "WARNING: gpg.conf not symlinked (run: make security)"
	@if [ -L "$(HOME)/.gnupg/gpg-agent.conf" ]; then echo "WARNING: gpg-agent.conf is a broken symlink (run: make security)"; elif [ ! -f "$(HOME)/.gnupg/gpg-agent.conf" ]; then echo "WARNING: gpg-agent.conf not written (run: make security)"; fi
	@test -L $(HOME)/.gnupg/common.conf       || echo "WARNING: common.conf not symlinked (run: make security)"
	@test -L $(HOME)/.config/nvim             || echo "WARNING: nvim config not symlinked (run: make nvim)"
	@test -L $(HOME)/.config/neomutt/neomuttrc || echo "WARNING: neomuttrc not symlinked (run: make neomutt)"
	@test -f $(HOME)/.mbsyncrc        || echo "WARNING: ~/.mbsyncrc not found (run: make neomutt)"
	@test -f $(HOME)/.notmuch-config  || echo "WARNING: ~/.notmuch-config not found (run: make neomutt)"
	@test -f $(LAUNCH_AGENTS)/org.jaredeberle.mailsync.plist || echo "WARNING: mail sync LaunchAgent not installed (run: make mailsync)"
	@test -f $(HOME)/.vale.ini                || echo "WARNING: .vale.ini not generated (run: make vale)"
	@test -d $(HOME)/.local/share/vale/styles && \
	    ls $(HOME)/.local/share/vale/styles | grep -q . || \
	    echo "WARNING: vale styles directory empty (run: make vale)"
	@FFPROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null); \
	[ -z "$$FFPROFILE" ] || \
	test -f "$(FIREFOX_DIR)/$$FFPROFILE/user.js" || \
	echo "WARNING: Firefox user.js not written (run: make firefox)"
	@for wf in "$(HOME)"/.dotfiles/macos/services/*.workflow; do \
	    name=$$(basename "$$wf"); \
	    test -L "$(SERVICES_DIR)/$$name" || \
	        echo "WARNING: Service '$$name' not symlinked (run: make services)"; \
	done
	@echo "Checking SSH keys..."
	@test -f $(HOME)/.ssh/id_github           || echo "WARNING: ~/.ssh/id_github not found — generate or copy your key"
	@test -f $(HOME)/.ssh/id_codeberg        || echo "WARNING: ~/.ssh/id_codeberg not found — generate or copy your key"
	@echo "Checking shell..."
	@dscl . -read /Users/$(USER) UserShell 2>/dev/null | grep -qF "$(HOMEBREW_PREFIX)/bin/fish" || \
	    echo "WARNING: fish is not the login shell (run: make chsh)"
	@test -d $(HOME)/.tmux/plugins/tpm       || echo "WARNING: TPM not cloned (run: make shell)"
	@echo "Checking GPG..."
	@gpg --list-secret-keys 2>/dev/null | grep -q "sec" || \
	    echo "WARNING: no GPG secret key found — import your key"
	@echo "Checking background agents..."
	@for agent in org.jaredeberle.mailsync org.jaredeberle.brewupdate org.jaredeberle.brewlogclean org.jaredeberle.resticcheck; do \
	    if [ -f "$(LAUNCH_AGENTS)/$$agent.plist" ]; then \
	        launchctl print gui/$(LAUNCHD_UID)/$$agent >/dev/null 2>&1 || \
	            echo "WARNING: $$agent plist installed but not loaded (run: launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/$$agent.plist)"; \
	    fi; \
	done
	@echo "Done."
check : doctor macos-check brew-check tools-check
	@echo ""
	@echo "All health checks complete. Run 'make brew-drift' to also list untracked installs."
