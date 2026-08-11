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

# Export the DOTFILES_* environment variables that direct flake evaluation
# requires, deriving them from the current shell session.
export_dotfiles_env_vars() {
  export DOTFILES_USERNAME="$USER"
  export DOTFILES_HOME="$HOME"
  export DOTFILES_DIRECTORY="$(dotfiles_directory)"
}

# Print an error message to stderr and exit with status 1.
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Print nothing when ~/.dotfiles is safe (missing, or a symlink to this
# repository root); otherwise print a description of the problem.
dotfiles_symlink_problem() {
  if [[ -e "$HOME/.dotfiles" && ! -L "$HOME/.dotfiles" ]]; then
    printf '%s\n' "$HOME/.dotfiles exists and is not a symlink; refusing to overwrite it"
    return
  fi

  if [[ -L "$HOME/.dotfiles" ]]; then
    local current_target
    current_target="$(readlink -f "$HOME/.dotfiles")"
    if [[ "$current_target" != "$(dotfiles_directory)" ]]; then
      printf '%s\n' "$HOME/.dotfiles points to $current_target"
    fi
  fi
}

# Refuse to run when ~/.dotfiles exists as a regular file or points at a
# different repository root. If ~/.dotfiles is missing or already points
# at this repository, do nothing.
ensure_dotfiles_symlink() {
  local problem
  problem="$(dotfiles_symlink_problem)"
  [[ -z "$problem" ]] || die "$problem"
}

# Refuse to run when ~/.dotfiles is missing, exists as a regular file, or
# points at a different repository root. This is the strict validation
# variant used by check.sh: the symlink must already point at this repo.
require_dotfiles_symlink() {
  local problem
  problem="$(dotfiles_symlink_problem)"
  [[ -z "$problem" ]] || die "$problem"

  if [[ ! -L "$HOME/.dotfiles" ]]; then
    die "$HOME/.dotfiles is missing; expected a symlink to $(dotfiles_directory)"
  fi
}
