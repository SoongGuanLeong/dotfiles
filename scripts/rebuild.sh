#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

export_dotfiles_env_vars

ensure_dotfiles_symlink

ln -sfn "$DOTFILES_DIRECTORY" "$HOME/.dotfiles"

exec nix run "$DOTFILES_DIRECTORY#home-manager" -- \
  switch --flake "$DOTFILES_DIRECTORY#default" --impure
