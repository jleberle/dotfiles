default :
	@echo "There is no default for your own safety."

misc :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/general/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/general/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc
	@echo "Symlinking SSH Configurations"
	ln -s $(HOME)/.dotfiles/general/ssh-config $(HOME)/.ssh/config
	@echo "Symlinking GPG Files"
  ln -s $(HOME)/.dotfiles/general/gpg.conf $(HOME)/.gnupg/gpg.conf
