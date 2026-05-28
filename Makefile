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
	ln -sf $(HOME)/.dotfiles/general/ssh-config $(HOME)/.ssh/config
	@echo "Creating GPG home directory"
	mkdir -p $(HOME)/.gnupg
	chmod 700 $(HOME)/.gnupg
	@echo "Symlinking GPG Files"
	ln -sf $(HOME)/.dotfiles/general/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -sf $(HOME)/.dotfiles/general/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -sf $(HOME)/.dotfiles/general/dirmngr.conf $(HOME)/.gnupg/dirmngr.conf
apps :
	brew bundle install --file=$(HOME)/.dotfiles/homebrew/brewfile
