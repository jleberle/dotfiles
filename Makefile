default :
	@echo "There is no default for your own safety."

linux :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/Dropbox/Dotfiles/Linux/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/Dropbox/Dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/Dropbox/Dotfiles/zsh/linux-zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/Dropbox/Dotfiles/zsh/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/Dropbox/Dotfiles/Linux/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/Dropbox/Dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/Dropbox/Dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/Dropbox/Dotfiles/General/tmux.conf $(HOME)/.tmux.conf        

osx :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/Dropbox/Dotfiles/Mac/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/Dropbox/Dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/Dropbox/Dotfiles/Mac/zsh/zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/Dropbox/Dotfiles/General/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/Dropbox/Dotfiles/Mac/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/Dropbox/Dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/Dropbox/Dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/Dropbox/Dotfiles/General/tmux.conf $(HOME)/.tmux.conf

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/Dropbox/Dotfiles/neovim $(HOME)/.config/nvim

alllinux : linux neovim 

allmac: mac neovim

.PHONY : all default git zsh neovim install
