# Architecture

This repository separates the **base development environment** from **language-specific runtime management**.

The goal is to keep the environment reproducible without forcing every developer to install runtimes they do not need.

## Overview

```text
                         dotfiles
                            │
                            ▼
                    Nix flake + lockfile
                            │
                            ▼
                     Home Manager
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
       Base environment             Shell configuration
              │                           │
       ┌──────┼──────┐              ┌─────┴─────┐
       ▼      ▼      ▼              ▼           ▼
      git    nvim    CLI tools     zsh        starship
              │
              ▼
       Specialized runtimes
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
      uv      NVM   SDKMAN
       │       │       │
    Python   Node.js  Java/Scala
```

## Layer 1: Nix + Home Manager

Nix is responsible for the reproducible base environment.

Home Manager manages:

* CLI tools
* Neovim
* Zsh configuration
* Starship
* Eza
* Zoxide
* `uv`
* Pi configuration
* Other repository-owned configuration

The versions of Nix packages are determined by the pinned `flake.lock`.

This layer should contain tools that are broadly useful to the environment.

## Layer 2: Specialized runtime managers

Language ecosystems have their own version-management requirements.

We therefore do not make Home Manager responsible for every runtime.

### Python → uv

`uv` owns:

* Python versions
* Python virtual environments
* Python project dependencies
* Python CLI tools

Home Manager only provides the `uv` executable.

Example:

```text
Home Manager
    │
    └── uv
         │
         ├── Python versions
         ├── virtual environments
         ├── project dependencies
         └── Python tools
```

### Node.js → NVM

NVM owns Node.js versions and npm-related runtime state.

The dotfiles only initialize NVM when it exists:

```zsh
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
fi
```

NVM is therefore optional.

### Java / Scala → SDKMAN

SDKMAN owns Java and Scala installations.

The dotfiles only initialize SDKMAN when it exists:

```zsh
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
```

SDKMAN is therefore optional.

## Why runtimes are optional

A shared development environment should not force every user to install every language ecosystem.

For example:

```text
Python developer
    → uv

Frontend developer
    → NVM

JVM developer
    → SDKMAN

General shell user
    → none of the above
```

The base environment remains usable in all four cases.

This also reduces unnecessary installation time, disk usage, and maintenance.

## Configuration ownership

Each piece of configuration should have one clear owner.

| Resource              | Owner                              |
| --------------------- | ---------------------------------- |
| Base packages         | Nix / Home Manager                 |
| Zsh configuration     | Home Manager (fully managed via Nix) |
| Python                | uv                                 |
| Node.js               | NVM                                |
| Java / Scala          | SDKMAN                             |
| Project dependencies  | Individual project                 |
| Secrets               | External secret management         |
| Windows configuration | Windows / WSL integration          |

Avoid having multiple systems manage the same resource.

### Zsh init fragment merge order

Home Manager assembles the final `~/.zshrc` by concatenating fragments in this order:

1. **Home Manager preamble** — autosuggestion, syntax highlighting, and other `programs.zsh` enable flags.
2. **`programs.zsh.initContent`** — user-defined content (`home.nix`). This contains oh-my-zsh bootstrap, NVM init, SDKMAN init, and `BROWSER` export.
3. **Zsh integrations** — `eza.enableZshIntegration` and `zoxide.enableZshIntegration` append their init lines after `initContent`.

Starship is initialised separately via `programs.starship.enable` and does not appear in the zsh fragment chain.

## Repository state vs runtime state

The repository contains configuration and reproducible declarations.

It does **not** contain:

* Python virtual environments
* uv caches
* downloaded Python interpreters
* NVM installations
* SDKMAN installations
* package-manager caches
* credentials
* secrets

For example:

```text
Repository
├── home.nix
├── flake.nix
├── flake.lock
├── scripts/
├── home/
└── docs/

Outside repository
├── ~/.cache/
├── ~/.local/share/uv/
├── ~/.nvm/
└── ~/.sdkman/
```

This keeps Git history small and prevents machine-specific runtime state from becoming part of the environment definition.

## Dependency management

`flake.lock` pins the exact dependency revisions used by the environment.

Normal rebuilds consume the existing lockfile:

```bash
./scripts/rebuild.sh
```

They do not update dependencies.

Dependency updates are deliberate:

```bash
nix flake update
```

The repository also provides:

```bash
./scripts/check-security.sh
```

which checks Nixpkgs revision age and Nixpkgs vulnerability metadata.

## Reproducibility boundary

The repository aims to make the following reproducible:

```text
Base tools
Shell configuration
Editor configuration
CLI configuration
Nix package versions
Home Manager version
```

It intentionally does not attempt to make every external runtime completely reproducible.

Instead, specialized managers provide the appropriate lifecycle for their ecosystems.

## Design rule

When adding a new tool, ask:

> Does this belong to the base environment, or does its ecosystem already have a specialized runtime manager?

Use Nix/Home Manager for broadly shared infrastructure.

Use the ecosystem's runtime manager for language-specific runtime state.

This keeps the architecture understandable as the environment grows.
