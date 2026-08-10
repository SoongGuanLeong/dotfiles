#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

cd "$DOTFILES_DIRECTORY"

printf '%s\n' '=== Git diff check ==='
git diff --check

printf '%s\n' '=== Shell syntax ==='
bash -n scripts/*.sh

printf '%s\n' '=== Nix syntax ==='
nix-instantiate --parse home.nix >/dev/null

printf '%s\n' '=== Security audit ==='
./scripts/check-security.sh

printf '%s\n' '=== Validation passed ==='
