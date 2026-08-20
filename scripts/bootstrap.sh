#!/usr/bin/env bash
# Supported baseline
# - OS:     Linux
# - Init:   systemd
# - Tools:  git, Nix (with flakes enabled)
#
# Bootstrap will fail with a clear message if any prerequisite is missing.
# This script supports Linux with systemd.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

DOTFILES_DIRECTORY="$(dotfiles_directory)"

# --- Prerequisite validation ---

[ -d /run/systemd/system ] ||
  die "systemd is required. This environment does not use systemd as init."

command -v git >/dev/null 2>&1 ||
  die "git is required"

command -v nix >/dev/null 2>&1 ||
  die "Nix is required. Install Nix before running bootstrap.sh."

nix flake metadata "$DOTFILES_DIRECTORY" >/dev/null 2>&1 ||
  die "Nix flakes are not available. Enable flakes before running bootstrap.sh."

printf 'Bootstrapping dotfiles from %s\n' "$DOTFILES_DIRECTORY"

"$DOTFILES_DIRECTORY/scripts/check.sh"

exec "$DOTFILES_DIRECTORY/scripts/rebuild.sh"
