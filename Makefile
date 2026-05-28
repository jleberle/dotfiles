default :
	@echo "There is no default for your own safety."

git :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/general/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/general/gitignore $(HOME)/.gitignore
zsh :	
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/zshrc $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/zsh/zshenv $(HOME)/.zshenv
	ln -s $(HOME)/.dotfiles/zsh/zprofile $(HOME)/.zprofile
auth : 
	@echo "Symlinking SSH Configurations"
	ln -s $(HOME)/.dotfiles/general/ssh-config $(HOME)/.ssh/config
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/.dotfiles/general/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -s $(HOME)/.dotfiles/general/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/.dotfiles/general/dirmngr.conf ~/.gnupg/dirmngr.conf
apps :
	brew bundle install --file=$(HOME)/.dotfiles/homebrew/brewfile
