# ADR 005: Zsh Owned by Nix

## Status

Accepted

## Context

Zsh configuration previously had two owning interfaces:

- **Nix options** (`programs.zsh.*` in `home.nix`) — managed shell theme, plugins, history, syntax highlighting.
- **Raw rc file** (`home/.zshrc`) — injected via `programs.zsh.initContent` as a string literal. This file bypassed the home registry invariant (established by ADR 002), leaving `home/.zshrc` as the only `home/` entry not tracked in `registry.json`.

Issue #13 identified this dual ownership as a seam violation. Two resolution paths existed.

### Options considered

**Option A — Route rc through registry**

Keep `home/.zshrc` as the authoritative shell config. Register it in `registry.json` and source it from its installed location. Trim Nix-side shell options to enable-only flags (autosuggestion, syntax highlighting) without duplicating init logic.

**Option B — Fold rc content into Nix** (chosen)

Delete `home/.zshrc`. Move all init content (oh-my-zsh bootstrap, NVM init, SDKMAN init, `BROWSER` export) into `programs.zsh.initContent` in `home.nix`. Remove the stale `home/.zshrc` entry from `registry.json`. The merge order of init fragments is documented in `architecture.md`.

## Decision

Path B: fold rc content into Nix.

## Rationale

- **Simpler layout**: one less file to maintain. The init content lives alongside the rest of shell configuration in `home.nix`.
- **Stronger reproducibility**: Nix manages everything. No shell-level config escapes the Nix build.
- **Registry invariant reinforced**: with no rc file, there is nothing to bypass the registry. The invariant cannot be violated by a deleted file.
- **Lower cognitive load**: contributors edit `home.nix`, not a separate rc file. All shell config is discoverable in one place.

## Consequences

- `home/.zshrc` deleted in commit `4a10a89`.
- Init content moved to `programs.zsh.initContent` in `home.nix`.
- Stale registry entry for `.zshrc` removed in commit `60043ed`.
- Contributors must edit Nix to change shell init, not a raw rc file.
- Init fragment merge order documented in the [architecture.md "Zsh init fragment merge order"](../architecture.md#zsh-init-fragment-merge-order) section and the [configuration ownership table](../architecture.md#configuration-ownership).
- The decision was executed in issues #13 and the following commits:
  - `4a10a89` — consolidate zsh config into Nix, remove `.zshrc` from registry.
  - `60043ed` — remove stale registry entry, document merge order.
- ADR 004 established precedent for post-hoc formalisation of already-executed decisions; this ADR follows the same pattern.

## References

- Issue #13 — Give zsh one owning interface.
- Issue #19 — Record zsh ownership decision as ADR 005.
- Commit `4a10a89` — consolidation implementation.
- Commit `60043ed` — stale entry removal and merge order documentation.
- ADR 002 — Herdr extension registry invariant.
- [Configuration ownership table](../architecture.md#configuration-ownership) — "Zsh configuration: Home Manager (fully managed via Nix)".
- [Zsh init fragment merge order](../architecture.md#zsh-init-fragment-merge-order) — documented fragment chain.
