default :
	@echo "There is no default for your own safety."

git :
	@echo "Symlinking git dotfiles"
	ln -s $(HOME)/Git/Dotfiles/git/gitconfig $(HOME)/.gitconfig 
	ln -s $(HOME)/Git/Dotfiles/git/gitignore $(HOME)/.gitignore

zsh :
	@echo "Symlinking ZSH dotfiles"
	ln -s $(HOME)/Git/Dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc 

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/Git/Dotfiles/neovim $(HOME)/.config/nvim
	
firstrun :
	@echo "Symlinking Miscellenous dotfiles"
	ln -s $(HOME)/Git/Dotfiles/misc/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -s $(HOME)/Git/Dotfiles/misc/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/Git/Dotfiles/misc/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/Git/Dotfiles/misc/.tmux.conf $(HOME)/.tmux.conf

all : git zsh neovim 

.PHONY : all default git zsh neovim install