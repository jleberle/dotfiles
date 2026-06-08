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

.PHONY: default install git shell chsh security firefox betterfox-update apps brewauto nvim vale latex macos macos-check doctor brew-check tools-check clean

default :
	@echo "There is no default for your own safety."

install : git shell security nvim vale brewauto
	@echo ""
	@echo "Run 'make firefox' after launching Firefox once."
	@echo "Run 'make latex' to install LaTeX packages. Will load slowly"
	@echo ""
	@$(MAKE) doctor

git :
	@echo "Symlinking Git files"
	ln -sf $(HOME)/.dotfiles/git/gitconfig $(HOME)/.gitconfig
	ln -sf $(HOME)/.dotfiles/git/gitignore $(HOME)/.gitignore
	@echo "Symlinking lazygit config"
	mkdir -p "$(HOME)/Library/Application Support/lazygit"
	ln -sf $(HOME)/.dotfiles/git/lazygit.yml "$(HOME)/Library/Application Support/lazygit/config.yml"
	@command -v delta >/dev/null 2>&1 || echo "WARNING: delta not found — git diff/log will fail. Run: make apps"
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
	@echo "Creating GPG home directory"
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking GPG Files"
	ln -sf $(HOME)/.dotfiles/security/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Writing gpg-agent.conf (pinentry path depends on Homebrew prefix: $(HOMEBREW_PREFIX))"
	@[ -f "$(HOME)/.dotfiles/security/gpg-agent.conf.tmpl" ] || \
	    { echo "ERROR: gpg-agent.conf.tmpl not found — run: git pull"; exit 1; }
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
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/homebrew/org.jaredeberle.brewupdate.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/homebrew/org.jaredeberle.brewlogclean.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
	plutil -lint $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	plutil -lint $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
	-launchctl bootout gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate 2>/dev/null
	-launchctl bootout gui/$(LAUNCHD_UID)/org.jaredeberle.brewlogclean 2>/dev/null
	launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
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
	@echo "Done."
latex :
	@command -v tlmgr >/dev/null 2>&1 || { echo "ERROR: tlmgr not found — install BasicTeX first (make apps)"; exit 1; }
	tlmgr install \
	    tex-gyre xcharter sourcesans microtype geometry \
	    titlesec titling parskip enumitem fancyhdr \
	    booktabs adjustbox xcolor float listings \
	    tools graphics ec collection-fontsrecommended \
	    xstring fontaxes ly1
nvim :
	@echo "Symlinking nvim config"
	ln -sfn $(HOME)/.dotfiles/writing/nvim $(HOME)/.config/nvim
vale :
	@echo "Installing global Vale config (used by nvim-lint for prose)"
	mkdir -p $(HOME)/.local/share/vale/styles
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/writing/vale/vale.ini > $(HOME)/.vale.ini
	@echo "Wrote $(HOME)/.vale.ini (StylesPath: $(HOME)/.local/share/vale/styles)"
	vale sync
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
	@echo "Done."
brew-check :
	@echo "Checking Brewfile packages..."
	@brew bundle check --file=$(HOME)/.dotfiles/homebrew/brewfile --no-upgrade || \
	    echo "Run 'make apps' to install missing packages."
tools-check :
	@echo "Checking tools..."
	@command -v delta      >/dev/null 2>&1 || echo "WARNING: delta not found (run: make apps)"
	@command -v vale       >/dev/null 2>&1 || echo "WARNING: vale not found (run: make apps)"
	@command -v pandoc     >/dev/null 2>&1 || echo "WARNING: pandoc not found (run: make apps)"
	@command -v pandoc-crossref >/dev/null 2>&1 || echo "WARNING: pandoc-crossref not found (run: make apps)"
	@command -v lazygit    >/dev/null 2>&1 || echo "WARNING: lazygit not found (run: make apps)"
	@command -v lua-language-server >/dev/null 2>&1 || echo "WARNING: lua-language-server not found (run: make apps)"
	@command -v pyright    >/dev/null 2>&1 || echo "WARNING: pyright not found (run: make apps)"
	@command -v bash-language-server >/dev/null 2>&1 || echo "WARNING: bash-language-server not found (run: make apps)"
	@command -v stylua     >/dev/null 2>&1 || echo "WARNING: stylua not found (run: make apps)"
	@command -v black      >/dev/null 2>&1 || echo "WARNING: black not found (run: make apps)"
	@command -v prettier   >/dev/null 2>&1 || echo "WARNING: prettier not found (run: make apps)"
	@echo "Done."
doctor :
	@echo "Checking symlinks..."
	@test -L $(HOME)/.gitconfig                || echo "WARNING: .gitconfig not symlinked (run: make git)"
	@test -L $(HOME)/.gitignore                || echo "WARNING: .gitignore not symlinked (run: make git)"
	@test -L "$(HOME)/Library/Application Support/lazygit/config.yml" || echo "WARNING: lazygit config not symlinked (run: make git)"
	@test -L $(HOME)/.config/fish              || echo "WARNING: fish config not symlinked (run: make shell)"
	@test -L "$(GHOSTTY_DIR)/config"           || echo "WARNING: ghostty config not symlinked (run: make shell)"
	@test -L $(HOME)/.tmux.conf               || echo "WARNING: .tmux.conf not symlinked (run: make shell)"
	@test -L $(HOME)/.config/bat/config       || echo "WARNING: bat config not symlinked (run: make shell)"
	@test -L $(HOME)/.ssh/config              || echo "WARNING: ssh config not symlinked (run: make security)"
	@test -L $(HOME)/.gnupg/gpg.conf          || echo "WARNING: gpg.conf not symlinked (run: make security)"
	@test -f $(HOME)/.gnupg/gpg-agent.conf    || echo "WARNING: gpg-agent.conf not written (run: make security)"
	@test -L $(HOME)/.gnupg/common.conf       || echo "WARNING: common.conf not symlinked (run: make security)"
	@test -L $(HOME)/.config/nvim             || echo "WARNING: nvim config not symlinked (run: make nvim)"
	@test -f $(HOME)/.vale.ini                || echo "WARNING: .vale.ini not generated (run: make vale)"
	@test -d $(HOME)/.local/share/vale/styles && \
	    ls $(HOME)/.local/share/vale/styles | grep -q . || \
	    echo "WARNING: vale styles directory empty (run: make vale)"
	@FFPROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null); \
	[ -z "$$FFPROFILE" ] || \
	test -f "$(FIREFOX_DIR)/$$FFPROFILE/user.js" || \
	echo "WARNING: Firefox user.js not written (run: make firefox)"
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
	@echo "Done."
