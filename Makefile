default :
	@echo "There is no default for your own safety."

misc :
	@echo "Symlinking Git Files"
	ln -s $(HOME)/.dotfiles/general/gitconfig $(HOME)/.gitconfig
	ln -s $(HOME)/.dotfiles/general/gitignore $(HOME)/.gitignore
	@echo "Symlinking ZSH Files"
	ln -s $(HOME)/.dotfiles/zsh/zshrc.zsh $(HOME)/.zshrc
	ln -s $(HOME)/.dotfiles/zsh/zshenv.zsh $(HOME)/.zshenv
	@echo "Symlinking SSH Configurations"
	ln -s $(HOME)/.dotfiles/general/ssh-config $(HOME)/.ssh/config
	@echo "Symlinking GPG Files"
  ln -s $(HOME)/.dotfiles/general/gpg.conf $(HOME)/.gnupg/gpg.conf
	@echo "Symlinking Misc Files"
	ln -s $(HOME)/.dotfiles/general/gemrc $(HOME)/.gemrc
	ln -s $(HOME)/.dotfiles/general/tmux.conf $(HOME)/.tmux.conf

neovim :
	@echo "Symlinking Neovim dotfiles"
	ln -s $(HOME)/.dotfiles/neovim $(HOME)/.config/nvim

all: misc neovim

.PHONY : all default git zsh neovim install
