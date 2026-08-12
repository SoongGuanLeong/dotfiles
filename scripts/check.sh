#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

export_dotfiles_env_vars

cd "$DOTFILES_DIRECTORY"

printf '%s\n' '=== Git diff check ==='
git diff --check

printf '%s\n' '=== Shell syntax ==='
bash -n scripts/*.sh

printf '%s\n' '=== Nix syntax ==='
nix-instantiate --parse home.nix >/dev/null

printf '%s\n' '=== Flake check ==='
nix flake check --impure

printf '%s\n' '=== Flake env precondition ==='
check_dotfiles_env_vars
# Direct flake evaluation must fail fast when DOTFILES_* vars are unset.
if output="$(env -u DOTFILES_USERNAME -u DOTFILES_HOME -u DOTFILES_DIRECTORY \
    nix eval --impure .#homeConfigurations.default 2>&1)"; then
  die "flake evaluated with DOTFILES_* vars unset; env precondition missing"
fi
# Empty string must be treated as unset, not defaulted silently.
if output="$(DOTFILES_USERNAME= nix eval --impure .#homeConfigurations.default 2>&1)"; then
  die "flake evaluated with empty DOTFILES_USERNAME; empty string must be treated as unset"
fi

printf '%s\n' '=== Security audit ==='
./scripts/check-security.sh

printf '%s\n' '=== Validation passed ==='
