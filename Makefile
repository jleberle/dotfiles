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
	ln -s $(HOME)/Git/Dotfiles/misc/tmux.conf $(HOME)/.tmux.conf

linux :
	@echo "Symlinking dotfiles"
	ln -s $(HOME)/Documents/dotfiles/misc/gpg.conf $(HOME)/.gnupg/gpg.conf
	ln -s $(HOME)/Documents/dotfiles/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/Documents/dotfiles/misc/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/Documents/dotfiles/tmux.conf $(HOME)/.tmux.conf
	ln -s $(HOME)/Documents/dotfiles/neovim $(HOME)/.config/nvim
	ln -s $(HOME)/Documents/dotfiles/git/gitconfig $(HOME)/.gitconfig 
	ln -s $(HOME)/Documents/dotfiles/git/gitignore $(HOME)/.gitignore
	ln -s $(HOME)/Documents/dotfiles/zsh/debian-zshrc.zsh $(HOME)/.zshrc

all : git zsh neovim 

.PHONY : all default git zsh neovim install
