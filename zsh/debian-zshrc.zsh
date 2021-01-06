# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Paths
export ZSH="${HOME}/.oh-my-zsh"
export PATH="${HOME}/.local/bin:${HOME}/.cabal/bin:$PATH"

# Load Antigen
source /usr/share/zsh-antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Oh-My-ZSH Configurations
ENABLE_CORRECTION="true"
HIST_STAMPS="yyyy-mm-dd"

# Antigen Bundles
antigen bundle git
antigen bundle pip
antigen bundle cabal
antigen bundle debian
antigen bundle command-not-found
antigen bundle joel-porquet/zsh-dircolors-solarized.git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme romkatv/powerlevel10k
antigen apply

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Aliases
source ${HOME}/Git/dotfiles/zsh/debian-aliases.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
