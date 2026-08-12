# Environment Context

## Contract

This repo defines a reproducible **base development environment** via Nix + Home Manager.
Language-specific runtimes are optional, managed by dedicated tools.

| Resource | Owner | Required |
|---|---|---|
| Base packages, shell, CLI tools | Nix / Home Manager | yes |
| Python | `uv` | yes (in base) |
| Node.js | NVM | no |
| Java / Scala | SDKMAN | no |

## Machine-managed files

The repo owns: `flake.nix`, `home.nix`, `flake.lock`, `scripts/`, `home/`, `docs/`.

Not in repo (machine-local, gitignored):
- `~/.cache/`, `~/.local/share/uv/`, `~/.nvm/`, `~/.sdkman/`
- Python virtualenvs, project dependencies

## ADRs

See [docs/adr/](docs/adr/).

| # | Title | Status |
|---|---|---|
| 001 | Remove `~/.dotfiles` symlink | Accepted |
| 002 | Herdr Extension Seam | Accepted |
| 003 | Optional Runtimes Policy | Accepted |
| 004 | Dependency Update Cooling Period | Accepted |
| 005 | Zsh Owned by Nix | Accepted |
