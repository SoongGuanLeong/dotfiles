# WSL2 Dotfiles

Reproducible WSL2 development environment using **Nix flakes + Home Manager**.

## Quick start

Requirements:

* WSL2
* Nix with flakes enabled
* Git

```bash
git clone <YOUR_REPOSITORY_URL> ~/projects/dotfiles
cd ~/projects/dotfiles
./scripts/rebuild.sh
exec zsh -l
```

## Documentation

* [Onboarding](docs/onboarding.md) — first-time setup and verification
* [Architecture](docs/architecture.md) — how the environment is structured
* [Development](docs/development.md) — daily workflow and dependency updates
* [Troubleshooting](docs/troubleshooting.md) — common problems and fixes

## Ownership

| Area             | Owner              |
| ---------------- | ------------------ |
| Base environment | Nix / Home Manager |
| Python           | `uv`               |
| Node.js          | NVM (optional)     |
| Java / Scala     | SDKMAN (optional)  |

The repository intentionally does not manage secrets, Windows configuration, or runtime-specific state.

## Design principles

* Keep the base environment reproducible.
* Let specialized tools manage their own ecosystems.
* Keep optional runtimes optional.
* Pin dependencies and update them deliberately.
* Keep project-specific dependencies inside projects.
* Keep caches and runtime state outside the repository.
