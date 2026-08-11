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
# Direct flake evaluation must fail fast when DOTFILES_* vars are unset.
if output="$(env -u DOTFILES_USERNAME -u DOTFILES_HOME -u DOTFILES_DIRECTORY \
    nix eval --impure .#homeConfigurations.default 2>&1)"; then
  die "flake evaluated with DOTFILES_* vars unset; env precondition missing"
fi
for var in DOTFILES_USERNAME DOTFILES_HOME DOTFILES_DIRECTORY; do
  grep -q -- "$var" <<<"$output" ||
    die "env precondition error did not name missing variable $var"
done
# An empty string must be treated as unset, not defaulted silently.
if output="$(DOTFILES_USERNAME= nix eval --impure .#homeConfigurations.default 2>&1)"; then
  die "flake evaluated with empty DOTFILES_USERNAME; empty string must be treated as unset"
fi
grep -q -- 'DOTFILES_USERNAME' <<<"$output" ||
  die "env precondition error did not name empty DOTFILES_USERNAME"

printf '%s\n' '=== Security audit ==='
./scripts/check-security.sh

printf '%s\n' '=== Validation passed ==='
