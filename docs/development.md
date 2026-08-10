# Development

This document describes the normal workflow for maintaining and changing the dotfiles repository.

## Repository workflow

The repository follows a simple cycle:

```text
Edit
  ↓
Validate
  ↓
Rebuild
  ↓
Verify
  ↓
Commit
```

Keep changes small and focused so that each commit represents one logical change.

## Before making changes

Check the working tree:

```bash
git status
```

If there are existing changes, understand them before starting new work.

Check the current environment when necessary:

```bash
nix --version
nix flake metadata --json . | jq
```

## Changing Home Manager configuration

Most environment changes are made in `home.nix`.

For example, adding a Nixpkgs package:

```nix
home.packages = with pkgs; [
  git
  neovim
  ripgrep
  jq
];
```

After changing it, validate the Nix syntax:

```bash
nix-instantiate --parse home.nix >/dev/null
```

Then rebuild:

```bash
./scripts/rebuild.sh
```

## Changing shell configuration

Shell-specific configuration lives in:

```text
home/.zshrc
```

The file is sourced by the Home Manager-managed Zsh configuration.

After modifying it:

```bash
./scripts/rebuild.sh
exec zsh -l
```

Then verify the relevant commands or environment variables.

## Adding development runtimes

Do not automatically add language runtimes to `home.nix`.

Use the appropriate runtime manager:

```text
Python       → uv
Node.js      → NVM
Java/Scala   → SDKMAN
```

For example, Python versions should be managed through uv:

```bash
uv python install 3.13
```

Node.js versions should be managed through NVM:

```bash
nvm install <version>
```

Java and Scala versions should be managed through SDKMAN.

## Testing a change

At minimum, run:

```bash
git diff --check
```

For Nix configuration changes:

```bash
nix-instantiate --parse home.nix >/dev/null
```

For shell scripts:

```bash
bash -n scripts/rebuild.sh
bash -n scripts/bootstrap.sh
bash -n scripts/check-security.sh
```

Then perform a real rebuild:

```bash
./scripts/rebuild.sh
```

Finally verify the resulting environment.

For example:

```bash
uv --version
nvim --version | head -1
git --version
```

## Security checks

Before committing dependency-related changes:

```bash
./scripts/check-security.sh
```

The check reports:

* pinned nixpkgs revision
* revision age
* whether the revision has passed the cooling period
* known vulnerability metadata for managed packages

A new nixpkgs revision is not automatically considered eligible for adoption.

## Updating dependencies

Normal development should not update the flake lock file.

To deliberately update dependencies:

```bash
nix flake update
```

Then run:

```bash
./scripts/check-security.sh
./scripts/rebuild.sh
```

Review the resulting lock-file changes carefully.

If the security check reports known vulnerabilities, stop and investigate before committing.

## Checking the final diff

Before committing:

```bash
git diff --check
git diff
git status
```

Look for:

* accidental files
* secrets
* machine-specific paths
* unrelated changes
* unnecessary package additions
* changes that duplicate ownership between tools

## Commit conventions

Use small, descriptive commits.

Examples:

```text
feat: add uv to managed packages
fix: make SDKMAN initialization optional
docs: document dependency update policy
refactor: simplify shell initialization
chore: update nixpkgs lock
```

The commit message should describe the change, not the debugging process.

## What should not be committed

Do not commit:

* credentials
* API keys
* SSH private keys
* generated caches
* Python virtual environments
* NVM installations
* SDKMAN installations
* uv caches
* machine-specific generated files
* Home Manager build results

Use `.gitignore` for generated repository-local state where appropriate.

## Dependency update policy

Dependency updates should be intentional rather than automatic.

The preferred workflow is:

```bash
./scripts/check-security.sh
nix flake update
./scripts/check-security.sh
./scripts/rebuild.sh
git diff -- flake.lock
```

If the new revision has not passed the repository's cooling period, do not force the update simply because a newer revision exists.

## Maintainer principle

Prefer the smallest change that preserves the repository's ownership model.

When adding something, first ask:

1. Does this belong in Nix/Home Manager?
2. Does an existing runtime manager already own it?
3. Is it machine-specific state?
4. Does every user of the dotfiles need it?
5. Can the change remain optional?

The goal is a reproducible base environment without turning the dotfiles into a monolithic manager for every development tool.
