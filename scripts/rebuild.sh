#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

export DOTFILES_USERNAME="$USER"
export DOTFILES_HOME="$HOME"
export DOTFILES_DIRECTORY

ln -sfn "$DOTFILES_DIRECTORY" "$HOME/.dotfiles"

exec nix run "$DOTFILES_DIRECTORY#home-manager" -- \
  switch --flake "$DOTFILES_DIRECTORY#default" --impure