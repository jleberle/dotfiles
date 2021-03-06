# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Antigen
source /usr/local/share/antigen/antigen.zsh

# Aliases
source ${DOTFILES}/zsh/mac-aliases.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Oh-My-ZSH Configurations
ENABLE_CORRECTION="true"
HIST_STAMPS="yyyy-mm-dd"

# Antigen Bundles
antigen bundle git
antigen bundle pip
antigen bundle cabal
antigen bundle osx
antigen bundle command-not-found
antigen bundle joel-porquet/zsh-dircolors-solarized.git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme romkatv/powerlevel10k
antigen apply

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

