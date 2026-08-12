# ADR 001: Remove `~/.dotfiles` symlink

## Status

Proposed

## Context

The dotfiles repository previously maintained a `~/.dotfiles` symlink pointing to the repository root as a convenience.

Scripts (`scripts/lib.sh`, `scripts/rebuild.sh`) implemented logic to guard this symlink (`ensure_dotfiles_symlink`) and recreate it.

However, no part of the dotfiles or its managed configuration actually consumes this symlink. The repository location is already correctly determined via environment variables (`DOTFILES_DIRECTORY`) and script-relative path resolution.

## Decision

We will remove the `~/.dotfiles` symlink and the associated guarding logic in `scripts/`.

The symlink provides no functional benefit to the managed environment and introduces unnecessary state management in the setup scripts.

## Consequences

- The `~/.dotfiles` symlink will no longer exist automatically.
- Scripts in `scripts/` will be simplified by removing `ensure_dotfiles_symlink` and its usage.
- Documentation referencing the symlink will be updated.
