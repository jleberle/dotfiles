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

.PHONY: default install git shell security firefox apps brewauto nvim vale doctor

default :
	@echo "There is no default for your own safety."

install : git shell security nvim vale brewauto
	@echo ""
	@echo "Done. Run 'make firefox' after launching Firefox once."
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
shell :
	@echo "Symlinking fish config"
	mkdir -p $(HOME)/.config
	ln -sfn $(HOME)/.dotfiles/shell/fish $(HOME)/.config/fish
	@echo "Config symlinked. To use fish as your login shell (optional):"
	@echo "  echo $(HOMEBREW_PREFIX)/bin/fish | sudo tee -a /etc/shells"
	@echo "  chsh -s $(HOMEBREW_PREFIX)/bin/fish"
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
	sed 's|__HOMEBREW_PREFIX__|$(HOMEBREW_PREFIX)|g' $(HOME)/.dotfiles/security/gpg-agent.conf.tmpl > $(HOME)/.gnupg/gpg-agent.conf
	chmod 600 $(HOME)/.gnupg/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/security/dirmngr.conf $(HOME)/.gnupg/dirmngr.conf
	ln -sf $(HOME)/.dotfiles/security/common.conf $(HOME)/.gnupg/common.conf
firefox :
	@PROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null) && \
	[ -n "$$PROFILE" ] || { echo "ERROR: Firefox profile not found — launch Firefox first"; exit 1; } && \
	echo "Symlinking user.js → $$PROFILE" && \
	ln -sf $(HOME)/.dotfiles/security/user.js "$(FIREFOX_DIR)/$$PROFILE/user.js"
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
	@echo "Installed. Logs accumulate in $(HOME)/.local/brew_update_logs.txt"
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate"
nvim :
	@echo "Symlinking nvim config"
	ln -sfn $(HOME)/.dotfiles/writing/nvim $(HOME)/.config/nvim
vale :
	@echo "Installing global Vale config (used by nvim-lint for prose)"
	mkdir -p $(HOME)/.local/share/vale/styles
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/writing/vale/vale.ini > $(HOME)/.vale.ini
	@echo "Wrote $(HOME)/.vale.ini (StylesPath: $(HOME)/.local/share/vale/styles)"
	vale sync
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
	@FFPROFILE=$$(awk -F= '/^Default=/{print $$2; exit}' \
	    "$(FIREFOX_DIR)/installs.ini" 2>/dev/null); \
	[ -z "$$FFPROFILE" ] || \
	test -L "$(FIREFOX_DIR)/$$FFPROFILE/user.js" || \
	echo "WARNING: Firefox user.js not symlinked (run: make firefox)"
	@echo "Done."
