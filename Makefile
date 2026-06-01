LAUNCHD_UID := $(shell id -u)
LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
GHOSTTY_DIR := $(HOME)/Library/Application Support/com.mitchellh.ghostty

# Detect Homebrew prefix for cross-architecture installs.
HOMEBREW_PREFIX := $(shell \
	if [ -x /opt/homebrew/bin/brew ]; then echo /opt/homebrew; \
	elif [ -x /usr/local/bin/brew ]; then echo /usr/local; \
	elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then echo /home/linuxbrew/.linuxbrew; \
	else brew --prefix 2>/dev/null || echo /usr/local; fi)

.PHONY: default git fish auth apps brewauto ghostty tmux nvim vale doctor

default :
	@echo "There is no default for your own safety."

git :
	@echo "Symlinking Git Files"
	ln -sf $(HOME)/.dotfiles/git/gitconfig $(HOME)/.gitconfig
	ln -sf $(HOME)/.dotfiles/git/gitignore $(HOME)/.gitignore
	@command -v delta >/dev/null 2>&1 || echo "WARNING: delta not found — git diff/log will fail. Run: make apps"
fish :
	@echo "Symlinking fish config"
	mkdir -p $(HOME)/.config
	ln -sfn $(HOME)/.dotfiles/fish $(HOME)/.config/fish
	ln -sf $(HOME)/.dotfiles/fish/starship.toml $(HOME)/.config/starship.toml
	@echo "Config symlinked. To use fish as your login shell (optional):"
	@echo "  echo $(HOMEBREW_PREFIX)/bin/fish | sudo tee -a /etc/shells"
	@echo "  chsh -s $(HOMEBREW_PREFIX)/bin/fish"
auth :
	@echo "Creating SSH ControlPath directory"
	mkdir -p $(HOME)/.ssh/control
	chmod 700 $(HOME)/.ssh/control
	@echo "Symlinking SSH Configurations"
	ln -sf $(HOME)/.dotfiles/general/ssh-config $(HOME)/.ssh/config
	@echo "Creating GPG home directory"
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking GPG Files"
	ln -sf $(HOME)/.dotfiles/general/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Generating gpg-agent.conf (pinentry path depends on Homebrew prefix: $(HOMEBREW_PREFIX))"
	sed 's|__HOMEBREW_PREFIX__|$(HOMEBREW_PREFIX)|g' $(HOME)/.dotfiles/general/gpg-agent.conf.tmpl > $(HOME)/.dotfiles/general/gpg-agent.conf
	chmod 600 $(HOME)/.dotfiles/general/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/general/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/general/dirmngr.conf $(HOME)/.gnupg/dirmngr.conf
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
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/launchd/org.jaredeberle.brewupdate.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/launchd/org.jaredeberle.brewlogclean.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
	plutil -lint $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	plutil -lint $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
	-launchctl bootout gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate 2>/dev/null
	-launchctl bootout gui/$(LAUNCHD_UID)/org.jaredeberle.brewlogclean 2>/dev/null
	launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	launchctl bootstrap gui/$(LAUNCHD_UID) $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
	@echo "Installed. Logs accumulate in $(HOME)/.local/brew_update_logs.txt"
	@echo "Test now: launchctl kickstart -k gui/$(LAUNCHD_UID)/org.jaredeberle.brewupdate"
ghostty :
	@echo "Symlinking Ghostty config"
	mkdir -p "$(GHOSTTY_DIR)"
	ln -sf $(HOME)/.dotfiles/ghostty/config "$(GHOSTTY_DIR)/config"
tmux :
	@echo "Symlinking tmux config"
	mkdir -p $(HOME)/.tmux
	[ -d $(HOME)/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm
	ln -sf $(HOME)/.dotfiles/general/tmux.conf $(HOME)/.tmux.conf
nvim :
	@echo "Symlinking nvim config"
	ln -sf $(HOME)/.dotfiles/nvim $(HOME)/.config/nvim
vale :
	@echo "Installing global Vale config (used by nvim-lint for prose)"
	mkdir -p $(HOME)/.local/share/vale/styles
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/general/vale.ini > $(HOME)/.vale.ini
	@echo "Wrote $(HOME)/.vale.ini (StylesPath: $(HOME)/.local/share/vale/styles)"
	vale sync
doctor :
	@echo "Checking symlinks..."
	@test -L $(HOME)/.gitconfig           || echo "WARNING: .gitconfig not symlinked (run: make git)"
	@test -L $(HOME)/.gitignore           || echo "WARNING: .gitignore not symlinked (run: make git)"
	@test -L $(HOME)/.config/fish         || echo "WARNING: fish config not symlinked (run: make fish)"
	@test -L $(HOME)/.config/starship.toml || echo "WARNING: starship.toml not symlinked (run: make fish)"
	@test -L $(HOME)/.ssh/config          || echo "WARNING: ssh config not symlinked (run: make auth)"
	@test -L $(HOME)/.gnupg/gpg.conf      || echo "WARNING: gpg.conf not symlinked (run: make auth)"
	@test -L $(HOME)/.gnupg/gpg-agent.conf || echo "WARNING: gpg-agent.conf not symlinked (run: make auth)"
	@test -L $(HOME)/.tmux.conf           || echo "WARNING: .tmux.conf not symlinked (run: make tmux)"
	@test -L $(HOME)/.config/nvim         || echo "WARNING: nvim config not symlinked (run: make nvim)"
	@test -L "$(GHOSTTY_DIR)/config"      || echo "WARNING: ghostty config not symlinked (run: make ghostty)"
	@test -f $(HOME)/.vale.ini            || echo "WARNING: .vale.ini not generated (run: make vale)"
	@echo "Done."
