#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

DOTFILES_DIRECTORY="$(dotfiles_directory)"

command -v git >/dev/null 2>&1 ||
  die "git is required"

command -v nix >/dev/null 2>&1 ||
  die "Nix is required. Install Nix before running bootstrap.sh."

nix flake metadata "$DOTFILES_DIRECTORY" >/dev/null 2>&1 ||
  die "Nix flakes are not available. Enable flakes before running bootstrap.sh."

# check.sh requires ~/.dotfiles to point at this repository, so establish
# the symlink before validating. Refuse to repoint an existing symlink.
ensure_dotfiles_symlink
ln -sfn "$DOTFILES_DIRECTORY" "$HOME/.dotfiles"

printf 'Bootstrapping dotfiles from %s\n' "$DOTFILES_DIRECTORY"

"$DOTFILES_DIRECTORY/scripts/check.sh"

exec "$DOTFILES_DIRECTORY/scripts/rebuild.sh"
