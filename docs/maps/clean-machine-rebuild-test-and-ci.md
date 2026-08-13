# Map: Clean-machine rebuild test + CI

**Issue:** [#24](https://github.com/SoongGuanLeong/dotfiles/issues/24)
**Status:** Proposed
**Domain:** Nix flakes, Home Manager, WSL2, GitHub Actions

## Problem

The dotfiles repository needs a validated, automated pipeline proving it can
reproduce a working WSL2 agentic development environment from a clean machine,
and that every change is checked by CI before landing.

Two workstreams:

1. **A reproducible clean-machine rebuild test protocol** — prove the whole
   bootstrap works from zero on a fresh WSL2 instance.
2. **A GitHub Actions CI workflow** — run `./scripts/check.sh` on every push/PR
   (already done in [#21] / [#27]) plus a heavier `nix build` step ([#30]).

[#21]: https://github.com/SoongGuanLeong/dotfiles/issues/21
[#27]: https://github.com/SoongGuanLeong/dotfiles/issues/27
[#30]: https://github.com/SoongGuanLeong/dotfiles/issues/30

## Current state

### CI

`.github/workflows/check.yml` runs on ubuntu-latest:

1. `actions/checkout@v4`
2. `DeterminateSystems/determinate-nix-action@v3` — installs Nix
3. `DeterminateSystems/magic-nix-cache-action@v9` — caches Nix store
4. `./scripts/check.sh` — shell syntax, Nix syntax, flake check, env
   precondition check, security audit

### Local validation scripts

| Script | What it does |
|---|---|
| `check.sh` | Git diff, shell syntax, Nix syntax, flake check, env precondition, security audit |
| `check-security.sh` | Nixpkgs revision age check + known vulnerability scan |
| `bootstrap.sh` | Prerequisite validation (WSL2, systemd, Ubuntu, git, Nix, flakes) then check.sh then rebuild |
| `rebuild.sh` | `nix run .#home-manager -- switch --flake .#default --impure` |

### Gap

- No automated test that starts from a **truly clean WSL2 instance** and runs
  `bootstrap.sh` end-to-end.
- CI runs `check.sh` only; it does not build the Home Manager derivation.
- No documented procedure for a human to perform a clean-machine test.

## Workstream 1: Clean-machine rebuild test protocol

### Approaches

#### A. WSL snapshot/restore (recommended for manual testing)

Export a clean base WSL2 image, restore, run bootstrap, validate, repeat.

```text
wsl --export <distro> clean-base.tar
  ─────────────────────────────────────►
wsl --unregister <distro>
wsl --import <distro> <install-dir> clean-base.tar
wsl -d <distro> --exec bash -c "
  cd ~/projects/dotfiles && ./scripts/bootstrap.sh
"
```

**Pros:** Reflects real user workflow; catches OS-level issues.
**Cons:** Slow (minutes per cycle); requires WSL2 host (Windows); not
practical to run on every commit.

#### B. Docker-based clean-room test (recommended for CI/automation)

Use a Docker container with the same base OS (Ubuntu 24.04 LTS), no Nix
pre-installed. The Dockerfile:

1. Starts from `ubuntu:24.04`
2. Installs git + curl + xz-utils
3. Installs Nix via the Determinate Nix Installer (multi-user)
4. Clones the dotfiles repo at the tested revision
5. Runs `./scripts/bootstrap.sh`
6. Runs a post-bootstrap smoke test

Docker-based approach runs on any GitHub Actions runner (ubuntu-latest can
run Docker) and takes ~30-60s.

**Pros:** Fast; CI-runner-native; no Windows/WSL2 dependency.
**Pros:** Catches Nix install + flake eval + Home Manager activation issues.
**Cons:** Does not test WSL2-specific prerequisites (systemd, `/proc/version`
check); Docker container is not 1:1 with WSL2 kernel/subsystem.

#### C. Nix build-only test (simplest, already partially covered)

`nix build --impure .#homeConfigurations.default.activationPackage` evaluates the flake
and builds the derivation closure **without** activating. This proves the
configuration is valid and all dependencies are resolvable, but does not test
the bootstrap workflow or activation script execution.

**Pros:** Fast (~10-30s); no Docker or WSL2 needed; already fits CI.
**Pros:** Catches eval errors and missing derivations.
**Cons:** Does not exercise bootstrap.sh, WSL2 prerequisites, or Home
Manager activation.

### Recommended strategy

| Layer | Method | Where | Frequency |
|---|---|---|---|
| Fast gating | `nix build .#activationPackage` | CI (ubuntu-latest) | Every push/PR |
| Integration | Docker clean-room + bootstrap | CI (ubuntu-latest) | Nightly or pre-merge for sensitive changes |
| Full validation | WSL snapshot/restore | Manual (human) | Before release / major env changes |

### Manual WSL test procedure

```bash
# Export a clean base WSL2 image (one-time after fresh install)
wsl --export Ubuntu clean-wsl-base.tar

# For each test cycle:
wsl --unregister Ubuntu
wsl --import Ubuntu C:\WSL\clean-test clean-wsl-base.tar
wsl -d Ubuntu -- bash -c '
  git clone https://github.com/SoongGuanLeong/dotfiles.git ~/projects/dotfiles
  cd ~/projects/dotfiles
  ./scripts/bootstrap.sh
  exec zsh -l
  git --version
  nvim --version | head -1
  uv --version
'
```

Store `clean-wsl-base.tar` in a durable location (not in-repo; large binary).

## Workstream 2: CI pipeline

### Current CI

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/determinate-nix-action@v3
      - uses: DeterminateSystems/magic-nix-cache-action@v9
      - run: ./scripts/check.sh
        env:
          DOTFILES_USERNAME: runner
          DOTFILES_HOME: /home/runner
          DOTFILES_DIRECTORY: ${{ github.workspace }}
```

### Proposed CI structure

Two jobs:

```yaml
jobs:
  check:
    # Same as current — fast validation gate
    ...
  build:
    needs: check  # only runs if check passes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/determinate-nix-action@v3
      - uses: DeterminateSystems/magic-nix-cache-action@v9
      - name: Build activationPackage
        run: nix build --impure .#homeConfigurations.default.activationPackage
        env:
          DOTFILES_USERNAME: runner
          DOTFILES_HOME: /home/runner
          DOTFILES_DIRECTORY: ${{ github.workspace }}
```

### Rationale for separate job (not merging into check.sh)

Per issue #30 rationale: `check.sh` is a fast local validation gate. The Nix
build is heavier and should stay in CI only. Developers run `check.sh` locally
before committing; they do not need to wait for a full flake build.

### Future: Docker clean-room integration test

For a nightly or pre-merge job, add a third job:

```yaml
  integration:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Bootstrap in clean Ubuntu container
        run: |
          docker build -t dotfiles-test -f - .
          docker run dotfiles-test
```

With a Dockerfile equivalent to the manual WSL procedure above.

This is deferred because it requires:
- A Dockerfile checked into the repo (or generated inline)
- Handling the flake lock within the container
- Deciding whether to test the same revision or the merged master

## Decisions

1. **CI is separate from check.sh.** The script stays fast for local use;
   heavier validation lives in CI jobs only.
2. **activationPackage build is the next CI addition.** This is the simplest
   meaningful build test and unblocks the rest of the CI workstream.
3. **Docker clean-room testing is deferred.** Worth doing, but requires design
   decisions about the Dockerfile, test scope, and scheduling.
4. **WSL snapshot/restore is manual only.** The WSL2 dependency and cycle time
   make it impractical for CI. Document the procedure for pre-release
   validation.

## Remaining work

End state: "CI builds activationPackage, optional Docker clean-room for
integration."

### Phase 1 (this ticket)
- [x] Map document (this file)
- [ ] CI job: build activationPackage (issue #30)

### Phase 2 (future ticket)
- [ ] Dockerfile for clean-room bootstrap test
- [ ] CI job: Docker clean-room integration (nightly or on-demand)
- [ ] Document manual WSL snapshot/restore procedure in onboarding or
      troubleshooting doc

## References

- [Architecture](../architecture.md) — Nix + Home Manager layering
- [Development](../development.md) — validation workflow
- [Onboarding](../onboarding.md) — bootstrap steps
- [check.yml](../../.github/workflows/check.yml) — current CI
- [check.sh](../../scripts/check.sh) — validation script
- [bootstrap.sh](../../scripts/bootstrap.sh) — prerequisite validation + activation
- [Issue #30](https://github.com/SoongGuanLeong/dotfiles/issues/30) —
  activationPackage CI build
