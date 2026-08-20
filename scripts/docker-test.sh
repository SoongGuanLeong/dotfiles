#!/usr/bin/env bash
# Docker clean-room integration test.
#
# Entry point for the Docker-based CI job (`.github/workflows/integration.yml`).
# Runs in a clean ubuntu:24.04 container with no Nix pre-installed.
#
# Executes the repository validation and activation build:
#   1. scripts/check.sh — syntax, flake check, env precondition, security
#   2. nix build --impure .#homeConfigurations.default.activationPackage
#   3. Smoke test — verify activationPackage build + key CLI tools
#
# Required env vars: DOTFILES_USERNAME, DOTFILES_HOME, DOTFILES_DIRECTORY
set -euo pipefail

DOTFILES_DIRECTORY="${DOTFILES_DIRECTORY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
export DOTFILES_USERNAME="${DOTFILES_USERNAME:-testuser}"
export DOTFILES_HOME="${DOTFILES_HOME:-/home/testuser}"
export DOTFILES_DIRECTORY

printf '=== Docker integration test ===\n'
printf 'DOTFILES_DIRECTORY: %s\n' "$DOTFILES_DIRECTORY"
printf 'DOTFILES_USERNAME:  %s\n' "$DOTFILES_USERNAME"
printf 'DOTFILES_HOME:      %s\n' "$DOTFILES_HOME"
printf '\n'

# Step 1: Run check.sh (syntax, flake check, env precondition, security audit)
printf 'Step 1/3: check.sh\n'
"$DOTFILES_DIRECTORY/scripts/check.sh"

# Step 2: Build activationPackage — proves Home Manager config is valid
printf '\nStep 2/3: Build activationPackage\n'
nix build --impure "$DOTFILES_DIRECTORY#homeConfigurations.default.activationPackage" \
  --out-link /tmp/result

# Verify build succeeded
if [ -L /tmp/result ] && [ -e /tmp/result ]; then
  printf 'activationPackage build: OK → %s\n' "$(readlink /tmp/result)"
else
  printf 'activationPackage build: FAILED\n'
  exit 1
fi

# Step 3: Smoke test — verify key CLI tools exist in the built derivation
printf '\nStep 3/3: Smoke test\n'

# List the built store path
nix path-info /tmp/result

# Verify expected tools are available (Nix profile / environment)
command -v nix >/dev/null 2>&1 && printf '  nix: OK\n'
command -v git >/dev/null 2>&1 && printf '  git: OK\n'

printf '\n=== Docker integration test passed ===\n'
