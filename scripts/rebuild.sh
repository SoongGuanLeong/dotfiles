#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

export DOTFILES_USERNAME="$USER"
export DOTFILES_HOME="$HOME"
export DOTFILES_DIRECTORY

if [[ -e "$HOME/.dotfiles" && ! -L "$HOME/.dotfiles" ]]; then
  printf 'error: %s exists and is not a symlink; refusing to overwrite it\n' \
  "$HOME/.dotfiles" >&2
  exit 1
fi

if [[ -L "$HOME/.dotfiles" ]]; then
  current_target="$(readlink -f "$HOME/.dotfiles")"
  if [[ "$current_target" != "$DOTFILES_DIRECTORY" ]]; then
    printf 'error: %s points to %s\n' \
    "$HOME/.dotfiles" "$current_target" >&2
    exit 1
  fi
fi

ln -sfn "$DOTFILES_DIRECTORY" "$HOME/.dotfiles"

exec nix run "$DOTFILES_DIRECTORY#home-manager" -- \
  switch --flake "$DOTFILES_DIRECTORY#default" --impure