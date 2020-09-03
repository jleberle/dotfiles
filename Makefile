default :
	@echo "There is no default for your own safety."

git :
	@echo "Symlinking git dotfiles"
	ln -s $(HOME)/Git/dotfiles/git/gitconfig $(HOME)/.gitconfig 
	ln -s $(HOME)/Git/dotfiles/git/gitignore $(HOME)/.gitignore

zsh :
	@echo "Symlinking ZSH dotfiles"
	ln -s $(HOME)/Git/dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc 

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/Git/dotfiles/neovim $(HOME)/.config/nvim
	
firstrun :
	@echo "Symlinking Miscellenous dotfiles"
	ln -s $(HOME)/Git/dotfiles/misc/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -s $(HOME)/Git/dotfiles/misc/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/Git/dotfiles/misc/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/Git/dotfiles/misc/tmux.conf $(HOME)/.tmux.conf

all : git zsh neovim 

.PHONY : all default git zsh neovim install
