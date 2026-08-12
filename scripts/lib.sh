#!/usr/bin/env bash
# Shared conventions for the dotfiles entry-point scripts.
#
# Sourced by bootstrap.sh, check.sh, check-security.sh and rebuild.sh.
# Provides two reusable conventions:
#
#   dotfiles_directory      print the absolute repository root path
#   die                     print an error to stderr and exit 1

# Print the absolute path of the repository root.
dotfiles_directory() {
  printf '%s\n' "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
}

# Export the DOTFILES_* environment variables that direct flake evaluation
# requires, deriving them from the current shell session.
export_dotfiles_env_vars() {
  export DOTFILES_USERNAME="${USER:?USER is not set}"
  export DOTFILES_HOME="${HOME:?HOME is not set}"
  export DOTFILES_DIRECTORY="$(dotfiles_directory)"
}

# Verify that all required DOTFILES_* environment variables are set and non-empty.
# Uses the source of truth exposed by the flake.
check_dotfiles_env_vars() {
  local root_dir
  root_dir="$(dotfiles_directory)"
  local required_vars
  required_vars_file=$(nix eval --raw "$root_dir#packages.$(uname -m)-linux.requiredEnvVars")
  required_vars=$(cat "$required_vars_file" | jq -r '.[]')

  for var in $required_vars; do
    if [[ -z "${!var:-}" ]]; then
      die "required environment variable $var is unset or empty"
    fi
  done
}

# Print an error message to stderr and exit with status 1.
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}
