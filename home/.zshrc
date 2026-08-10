export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# Optional: Node.js via NVM.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
fi

export BROWSER=wslview

# Optional: Java/Scala via SDKMAN.
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
