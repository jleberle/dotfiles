default :
	@echo "There is no default for your own safety."

linux :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/Linux/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/zsh/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/.dotfiles/Linux/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/.dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/.dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/.dotfiles/General/tmux.conf $(HOME)/.tmux.conf        

osx :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/General/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/zsh/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/.dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/.dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/.dotfiles/General/tmux.conf $(HOME)/.tmux.conf

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/.dotfiles/neovim $(HOME)/.config/nvim

alllinux : linux neovim 

allmac: osx neovim

.PHONY : all default git zsh neovim install
