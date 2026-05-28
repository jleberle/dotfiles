LAUNCHD_UID := $(shell id -u)
LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
GHOSTTY_DIR := $(HOME)/Library/Application Support/com.mitchellh.ghostty

.PHONY: default git zsh auth apps brewauto ghostty tmux

default :
	@echo "There is no default for your own safety."

git :
	@echo "Symlinking Git Files"
	ln -sf $(HOME)/.dotfiles/Git/gitconfig $(HOME)/.gitconfig
	ln -sf $(HOME)/.dotfiles/Git/gitignore $(HOME)/.gitignore
zsh :	
	@echo "Symlinking ZSH Files"
	ln -sf $(HOME)/.dotfiles/zsh/zshrc $(HOME)/.zshrc
	ln -sf $(HOME)/.dotfiles/zsh/zshenv $(HOME)/.zshenv
	ln -sf $(HOME)/.dotfiles/zsh/zprofile $(HOME)/.zprofile
auth :
	@echo "Creating SSH ControlPath directory"
	mkdir -p $(HOME)/.ssh/control
	chmod 700 $(HOME)/.ssh/control
	@echo "Symlinking SSH Configurations"
	ln -sf $(HOME)/.dotfiles/General/ssh-config $(HOME)/.ssh/config
	@echo "Creating GPG home directory"
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking GPG Files"
	ln -sf $(HOME)/.dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -sf $(HOME)/.dotfiles/General/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/General/dirmngr.conf $(HOME)/.gnupg/dirmngr.conf
apps :
	brew bundle install --file=$(HOME)/.dotfiles/Homebrew/brewfile
brewauto :
	@echo "Installing Homebrew auto-update LaunchAgents"
	mkdir -p $(HOME)/.local
	mkdir -p $(LAUNCH_AGENTS)
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/launchd/org.jaredeberle.brewupdate.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewupdate.plist
	sed 's|__HOME__|$(HOME)|g' $(HOME)/.dotfiles/launchd/org.jaredeberle.brewlogclean.plist > $(LAUNCH_AGENTS)/org.jaredeberle.brewlogclean.plist
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
	ln -sf $(HOME)/.dotfiles/General/tmux.conf $(HOME)/.tmux.conf
