default :
	@echo "There is no default for your own safety."

linux :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/Linux/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/linux-zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/zsh/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking Neovim Files"
	ln -s $(HOME)/.dotfiles/neovim ~/.config/nvim
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/.dotfiles/Linux/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/.dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/.dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/.dotfiles/General/tmux.conf $(HOME)/.tmux.conf        

osx :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/Mac/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/General/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/Mac/zsh/zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/General/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking GPG Files"
	ln -s $(HOME)/.dotfiles/Mac/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	ln -s $(HOME)/.dotfiles/General/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/.dotfiles/General/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/.dotfiles/General/tmux.conf $(HOME)/.tmux.conf

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/.dotfiles/neovim $(HOME)/.config/nvim

alllinux : linux neovim 

allmac: mac neovim

.PHONY : all default git zsh neovim install
