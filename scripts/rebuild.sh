#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

exec nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake ~/.dotfiles#weeboppa