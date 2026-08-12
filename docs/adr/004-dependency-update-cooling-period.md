# ADR 004: Dependency Update Cooling Period

## Status

Accepted

## Context

Nixpkgs is a rolling channel. Pulling the latest revision without a stabilization
delay risks introducing regressions into the shared environment.
Before this ADR, updates were ad-hoc with no enforced waiting period.

## Decision

New nixpkgs revisions must pass a **14-day cooling period** before adoption.

The minimum age (in days) is defined in `scripts/check-security.sh` as
`MIN_NIXPKGS_AGE_DAYS=14`.

Dependency updates are deliberate, not automatic:

```bash
nix flake update     # intentionally bumps flake.lock
./scripts/check-security.sh  # enforces cooling period
```

## Consequences

- Environments stable — no surprise regressions from freshly-pinned nixpkgs.
- Updates are intentional, gated by a script check.
- Urgent security fixes bypass the policy via explicit maintainer override.
