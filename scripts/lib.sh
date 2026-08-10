#!/usr/bin/env bash
# Shared conventions for the dotfiles entry-point scripts.
#
# Sourced by bootstrap.sh, check.sh, check-security.sh and rebuild.sh.
# Provides three reusable conventions:
#
#   dotfiles_directory      print the absolute repository root path
#   die                     print an error to stderr and exit 1
#   ensure_dotfiles_symlink guard ~/.dotfiles against accidental overwrite

# Print the absolute path of the repository root.
dotfiles_directory() {
  printf '%s\n' "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
}

# Print an error message to stderr and exit with status 1.
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Refuse to run when ~/.dotfiles exists as a regular file or points at a
# different repository root. If ~/.dotfiles is missing or already points
# at this repository, do nothing.
ensure_dotfiles_symlink() {
  if [[ -e "$HOME/.dotfiles" && ! -L "$HOME/.dotfiles" ]]; then
    die "$HOME/.dotfiles exists and is not a symlink; refusing to overwrite it"
  fi

  if [[ -L "$HOME/.dotfiles" ]]; then
    local current_target
    current_target="$(readlink -f "$HOME/.dotfiles")"
    if [[ "$current_target" != "$(dotfiles_directory)" ]]; then
      die "$HOME/.dotfiles points to $current_target"
    fi
  fi
}
