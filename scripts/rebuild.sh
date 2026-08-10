#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

export DOTFILES_USERNAME="$USER"
export DOTFILES_HOME="$HOME"
export DOTFILES_DIRECTORY="$(dotfiles_directory)"

ensure_dotfiles_symlink

ln -sfn "$DOTFILES_DIRECTORY" "$HOME/.dotfiles"

exec nix run "$DOTFILES_DIRECTORY#home-manager" -- \
  switch --flake "$DOTFILES_DIRECTORY#default" --impure
