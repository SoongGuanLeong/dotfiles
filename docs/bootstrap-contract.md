# Bootstrap Prerequisites Contract

**Status:** Active

## Purpose

This document records the explicit contract that `scripts/bootstrap.sh` validates
before proceeding. It defines what is required, what is optional, and what is
unsupported, so that contributors, CI designers, and agents can reason about
the bootstrap path without reading through script internals.

## Required Baseline

`bootstrap.sh` requires **all** of the following:

| Prerequisite | Check Method | Error If Missing |
|---|---|---|
| WSL2 | `grep -qi microsoft /proc/version` | `WSL2 is required. This environment does not appear to be WSL.` |
| systemd init | `[ -d /run/systemd/system ]` | `systemd is required. This environment does not use systemd as init.` |
| Ubuntu Linux | `grep -qi 'ID="?ubuntu"?' /etc/os-release` | `Ubuntu Linux is required. Other distributions are not supported.` |
| `git` | `command -v git` | `git is required` |
| Nix | `command -v nix` | `Nix is required. Install Nix before running bootstrap.sh.` |
| Nix flakes enabled | `nix flake metadata "$DOTFILES_DIRECTORY"` | `Nix flakes are not available. Enable flakes before running bootstrap.sh.` |

These checks are implemented in [`scripts/bootstrap.sh`](../scripts/bootstrap.sh).

## Optional / Auto-Detected

The following are not explicitly checked but are assumed by downstream steps:

- Home Manager (installed via flake, not a prerequisite)
- Nixpkgs (pinned by `flake.lock`, not a prerequisite)

## Unsupported Environments

`bootstrap.sh` explicitly does **not** support:

| Environment | Reason |
|---|---|
| Bare-metal Linux (non-WSL) | `/proc/version` check fails |
| WSL without systemd | `/run/systemd/system` check fails |
| Docker containers | WSL2 checks fail; no `/proc/version` Microsoft signature |
| Non-Ubuntu distributions | `/etc/os-release` ID check fails |
| macOS | No WSL2, no systemd |

## Canonical Entry Point

`scripts/bootstrap.sh` is the **one** supported entry point for a clean-machine
rebuild. It performs all prerequisite checks, runs `scripts/check.sh` for
validation, then calls `scripts/rebuild.sh` to apply the Home Manager
configuration via `nix run .#home-manager -- switch --flake .#default --impure`.

## Docker / Clean-Room Testing

Docker-based clean-room testing (defined in
[Map: Clean-machine rebuild test + CI](maps/clean-machine-rebuild-test-and-ci.md))
requires a **different entry point** that skips WSL2 checks. A Docker container
does not satisfy the WSL2 or systemd prerequisites. Running `bootstrap.sh`
inside Docker will fail at the WSL2 check.

For Docker integration testing, use either:

- A test-specific script that runs `scripts/check.sh` + `nix build` directly
- A modified `bootstrap.sh` with the WSL2 check bypassed

## Environment Contract

The flake exposes a machine-readable contract via `nix eval`:

```bash
nix eval --impure .#envContract
```

This returns the required environment variable names and the nixpkgs cooling-period
value. The [`scripts/lib.sh`](../scripts/lib.sh) library reads this contract to
fail fast when required variables are unset.

```json
{
  "requiredEnvVars": [
    "DOTFILES_USERNAME",
    "DOTFILES_HOME",
    "DOTFILES_DIRECTORY"
  ],
  "nixpkgsMinAgeDays": "14"
}
```

## Registry Invariant

The flake also exposes a registry check via `nix flake check` (implemented in
`checks.${system}.registry`). Every file under `home/` must have a corresponding
entry in `registry.json` (or an explicit exemption in `skip-list.json`). This
ensures symlinks are wired correctly and no file bypasses the registry invariant.

## References

- [`scripts/bootstrap.sh`](../scripts/bootstrap.sh) — prerequisite validation + activation
- [`scripts/lib.sh`](../scripts/lib.sh) — shared library consuming `envContract`
- [`flake.nix`](../flake.nix) — `envContract` and registry check definitions
- [`registry.json`](../registry.json) — home file registry
- [Map: Clean-machine rebuild test + CI](maps/clean-machine-rebuild-test-and-ci.md) — test strategy
