#!/usr/bin/env bash
# Supported baseline
# - OS:     Ubuntu Linux on WSL2
# - Init:   systemd
# - Tools:  git, Nix (with flakes enabled)
#
# Bootstrap will fail with a clear message if any prerequisite is missing.
# This script does NOT support bare-metal Linux, Docker, or WSL without
# systemd; if you need those, pre-install the prerequisites manually.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

DOTFILES_DIRECTORY="$(dotfiles_directory)"

# --- Prerequisite validation ---

grep -qi microsoft /proc/version 2>/dev/null ||
  die "WSL2 is required. This environment does not appear to be WSL."

[ -d /run/systemd/system ] ||
  die "systemd is required. This environment does not use systemd as init."

grep -qi 'ID="\?ubuntu"\?' /etc/os-release 2>/dev/null ||
  die "Ubuntu Linux is required. Other distributions are not supported."

command -v git >/dev/null 2>&1 ||
  die "git is required"

command -v nix >/dev/null 2>&1 ||
  die "Nix is required. Install Nix before running bootstrap.sh."

nix flake metadata "$DOTFILES_DIRECTORY" >/dev/null 2>&1 ||
  die "Nix flakes are not available. Enable flakes before running bootstrap.sh."

printf 'Bootstrapping dotfiles from %s\n' "$DOTFILES_DIRECTORY"

"$DOTFILES_DIRECTORY/scripts/check.sh"

exec "$DOTFILES_DIRECTORY/scripts/rebuild.sh"
