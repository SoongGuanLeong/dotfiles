#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 ||
  die "git is required"

command -v nix >/dev/null 2>&1 ||
  die "Nix is required. Install Nix before running bootstrap.sh."

nix flake metadata "$DOTFILES_DIRECTORY" >/dev/null 2>&1 ||
  die "Nix flakes are not available. Enable flakes before running bootstrap.sh."

if [[ -e "$HOME/.dotfiles" && ! -L "$HOME/.dotfiles" ]]; then
  die "$HOME/.dotfiles exists and is not a symlink; refusing to overwrite it"
fi

if [[ -L "$HOME/.dotfiles" ]]; then
  current_target="$(readlink -f "$HOME/.dotfiles")"
  if [[ "$current_target" != "$DOTFILES_DIRECTORY" ]]; then
    die "$HOME/.dotfiles points to $current_target"
  fi
fi

printf 'Bootstrapping dotfiles from %s\n' "$DOTFILES_DIRECTORY"

exec "$DOTFILES_DIRECTORY/scripts/rebuild.sh"