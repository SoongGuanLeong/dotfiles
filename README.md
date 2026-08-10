# WSL2 Dotfiles

Personal WSL2 development environment managed with Nix flakes and Home Manager.

## What manages what

| Tool / area                           | Managed by         |
| ------------------------------------- | ------------------ |
| Shell, CLI tools, Neovim, WezTerm, Pi | Nix / Home Manager |
| `uv`                                  | Nix / Home Manager |
| Python versions and environments      | `uv`               |
| Node.js / npm                         | NVM (optional)     |
| Java / Scala                          | SDKMAN (optional)  |

The repository does not manage secrets, Windows configuration, or runtime-specific state.

## Setup

Requirements:

* WSL2 + Linux distribution
* Git
* Nix with flakes enabled

Clone the repository:

```bash
git clone <YOUR_REPOSITORY_URL> ~/projects/dotfiles
cd ~/projects/dotfiles
```

Activate the environment:

```bash
./scripts/rebuild.sh
```

Then start a fresh shell:

```bash
exec zsh -l
```

The rebuild script activates Home Manager for the current user. It does not install Nix or overwrite an unrelated `~/.dotfiles`.

## Daily use

After changing configuration:

```bash
./scripts/rebuild.sh
```

A rebuild uses the versions already pinned in `flake.lock`. It does not update dependencies automatically.

### Adding a tool

For a general CLI or development tool, add it to `home.nix`:

```nix
home.packages = with pkgs; [
  git
  neovim
  ripgrep
];
```

Then:

```bash
./scripts/rebuild.sh
```

Use the specialized runtime manager when the tool belongs to that ecosystem:

```text
Python       → uv
Node.js      → NVM
Java/Scala   → SDKMAN
```

Do not add Python, Node.js, Java, or Scala to `home.nix` merely to make them globally available.

## Python with uv

`uv` is managed by Home Manager, while Python itself is managed by `uv`.

Use `uv` for:

* Python versions
* virtual environments
* project dependencies
* Python CLI tools

For example:

```bash
uv python install 3.13
uv init my-project
cd my-project
uv add pandas
uv run python
```

Python versions, environments, and project dependencies should remain managed by `uv` rather than being committed to this repository.

The WSL distribution may provide a system `python3`. That is not managed by this repository and should not be treated as the project's Python runtime.

## Updating dependencies

Dependency updates are deliberate.

First check the current policy:

```bash
./scripts/check-security.sh
```

The repository requires a **14-day cooling period** for a new nixpkgs revision before it is considered eligible for an update.

When an update becomes eligible:

```bash
nix flake update
./scripts/check-security.sh
./scripts/rebuild.sh
```

Review `flake.lock` before committing.

Normal rebuilds never update dependencies.

## Security policy

The security check verifies:

1. The pinned nixpkgs revision has passed the 14-day cooling period before an update is considered.
2. Managed Nix packages have no vulnerabilities reported by Nixpkgs metadata.

This is a guardrail, not a complete vulnerability scanner.

If a package reports a known vulnerability, investigate the package or dependency state before proceeding.

## Runtime managers

NVM and SDKMAN are optional. The shell only initializes them when they are installed.

This means the base dotfiles can be used without Node.js, Java, or Scala.

The intended ownership is:

```text
Nix / Home Manager → user environment
uv                 → Python ecosystem
NVM                → Node.js ecosystem
SDKMAN             → Java / Scala ecosystem
```

Keep each tool in its appropriate layer rather than making Home Manager manage every runtime.

## Design principles

The environment follows a few simple rules:

* **Nix/Home Manager owns the base environment.**
* **Specialized managers own their ecosystems.**
* **Optional tools should not become mandatory dependencies.**
* **Dependencies are pinned and updated deliberately.**
* **Runtime state and caches stay outside the repository.**
* **Project-specific dependencies belong to the project, not the global environment.**
