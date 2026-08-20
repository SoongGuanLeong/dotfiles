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
| Linux with systemd | `[ -d /run/systemd/system ]` | `systemd is required. This environment does not use systemd as init.` |
| `git` | `command -v git` | `git is required` |
| Nix | `command -v nix` | `Nix is required. Install Nix before running bootstrap.sh.` |
| Nix flakes enabled | `nix flake metadata "$DOTFILES_DIRECTORY"` | `Nix flakes are not available. Enable flakes before running bootstrap.sh.` |

These checks are implemented in [`scripts/bootstrap.sh`](../scripts/bootstrap.sh).

## Optional / Auto-Detected

The following are not explicitly checked but are assumed by downstream steps:

- Home Manager (installed via flake, not a prerequisite)
- Nixpkgs (pinned by `flake.lock`, not a prerequisite)

## Unsupported Environments

`bootstrap.sh` is intended for Linux systems using systemd.

| Environment | Reason |
|---|---|
| Linux without systemd | systemd is required for the user services managed by Home Manager |
| macOS | This configuration targets Linux |

## Canonical Entry Point

`scripts/bootstrap.sh` is the **one** supported entry point for a clean-machine
rebuild. It performs all prerequisite checks, runs `scripts/check.sh` for
validation, then calls `scripts/rebuild.sh` to apply the Home Manager
configuration via `nix run .#home-manager -- switch --flake .#default --impure`.

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
