# WSL Clean-Machine Rebuild Test Procedure

**Status:** Active
**Domain:** WSL2, Ubuntu, Nix, Home Manager
**Strategy layer:** Full validation (automated via `scripts/wsl-end-to-end-test.ps1`, manual fallback available)

## Purpose

This procedure validates the full dotfiles bootstrap from a truly clean WSL2
instance — the outermost validation layer of the three-tier test strategy
([map](maps/clean-machine-rebuild-test-and-ci.md)). It proves the entire
setup works in the real target environment end-to-end.

Since [issue #37](https://github.com/SoongGuanLeong/dotfiles/issues/37), this
procedure is **automated** via `scripts/wsl-end-to-end-test.ps1`. Run one command
for a complete test cycle. Manual steps retained as fallback for debugging.

---

## Quick Start

```powershell
# One-shot: export clean image, then run the automated harness
wsl --export Ubuntu C:\WSL\images\clean-wsl-base.tar
.\scripts\wsl-end-to-end-test.ps1 -BaseImage C:\WSL\images\clean-wsl-base.tar
```

See [Harness Validation](wsl-harness-validation.md) for test scenarios.

---

## Automated Procedure (Primary)

### Prerequisites

| Item | Required |
|---|---|
| Windows host with WSL2 installed | yes |
| Default WSL2 distro (Ubuntu) registered and working | yes |
| Clean WSL2 base image exported to `.tar` | yes (one-time setup) |
| PowerShell 5.1+ | yes |
| Bootstrap prerequisites contract (see [bootstrap-contract.md](bootstrap-contract.md)) | yes |

### One-Time Setup: Export Clean Base Image

After a fresh Ubuntu WSL2 install (no dotfiles applied), export the clean state
as a portable tar archive. This image is reused across all test cycles.

```powershell
wsl --export Ubuntu C:\WSL\images\clean-wsl-base.tar
```

Store the image in a durable location such as an external drive or a network
share. The file is a multi-gigabyte binary — do **not** commit it to the
dotfiles repository.

#### Image Rotation

Keep multiple snapshots if you test across different WSL2 base versions.

```powershell
wsl --export Ubuntu C:\WSL\images\clean-wsl-base-2024Q4.tar
```

Label each image with the Ubuntu release and the date of the base install.

### Run the Automated Test

```powershell
# Basic usage (uses default repo URL, disposable distro name)
.\scripts\wsl-end-to-end-test.ps1 -BaseImage C:\WSL\images\clean-wsl-base.tar

# Test with local uncommitted changes
.\scripts\wsl-end-to-end-test.ps1 -BaseImage C:\WSL\images\clean-wsl-base.tar -LocalPath ..\dotfiles

# Preserve distro for post-mortem inspection
.\scripts\wsl-end-to-end-test.ps1 -BaseImage C:\WSL\images\clean-wsl-base.tar -SkipCleanup
```

The script automates all 10 manual steps:
1. Unregister any existing test distro (`dotfiles-test` — never touches `Ubuntu`)
2. Prepare install directory
3. Import clean base image
4. Ensure WSL2 version
5. Configure `wsl.conf` (systemd + non-root user)
6. Restart WSL to apply config
7. Install prerequisites (git, Nix, flakes) if missing
8. Clone or copy the dotfiles repo
9. Run `bootstrap.sh`
10. Smoke-test: git, nix, nvim, uv, SHELL, zsh aliases

Output: structured JSON with per-step pass/fail + duration.

### Run the Scenario Suite

For comprehensive regression testing, use the test runner:

```powershell
# Update $baseImage path in scripts/wsl-test-scenarios.ps1 first
.\scripts\wsl-test-scenarios.ps1
```

Runs 6 scenarios: clean pass, missing base image, existing distro replacement,
bootstrap failure, SkipCleanup, safety guard.

### Validation

See [Harness Validation](wsl-harness-validation.md) for complete acceptance
criteria.

---

## Manual Procedure (Fallback / Debugging)

Use these manual steps when debugging a failure or when the automated script
cannot be used.

### Prerequisites

| Item | Required |
|---|---|
| Windows host with WSL2 installed | yes |
| Default WSL2 distro (Ubuntu) registered and working | yes |
| Sufficient disk space for base image + test clone | ~4 GB per image |
| `dotfiles` repository cloned on the Windows host or accessible via `git clone` | yes |
| Bootstrap prerequisites contract satisfied (see [bootstrap-contract.md](bootstrap-contract.md)) | yes |

### Step 1: Unregister Existing Distro

```powershell
wsl --terminate Ubuntu
wsl --unregister Ubuntu
```

### Step 2: Reimport from Clean Base Image

```powershell
wsl --import Ubuntu C:\WSL\clean-test C:\WSL\images\clean-wsl-base.tar
```

### Step 3: Configure Non-Root User

Set default user in `wsl.conf`:

```powershell
wsl -d Ubuntu -- bash -c "
  echo '[user]' > /etc/wsl.conf
  echo 'default=<your-username>' >> /etc/wsl.conf
"
wsl --terminate Ubuntu
wsl -d Ubuntu
```

Replace `<your-username>` with the non-root username.

### Step 4: Set Environment Variables

```bash
export DOTFILES_USERNAME=$(whoami)
export DOTFILES_HOME=$HOME
export DOTFILES_DIRECTORY=$HOME/projects/dotfiles
```

### Step 5: Clone the Repository

```bash
git clone https://github.com/SoongGuanLeong/dotfiles.git $DOTFILES_DIRECTORY
```

### Step 6: Run Bootstrap

```bash
cd $DOTFILES_DIRECTORY
./scripts/bootstrap.sh
```

### Step 7: Verify the Environment

```bash
git --version
nix --version
nvim --version | head -1
uv --version
echo $SHELL              # expect /run/current-system/sw/bin/zsh or similar
ls -la ~/.config/nvim    # expect managed Neovim config
```

### Step 8: Record Results

| Date | Commit SHA | Bootstrap | Verify | Notes |
|---|---|---|---|---|
| 2025-01-15 | abc1234 | pass | pass | Nix store partially cached |

### Cleanup

```powershell
wsl --terminate Ubuntu
wsl --unregister Ubuntu
```

---

## Image Management

### Refresh the Base Image

```powershell
wsl --export Ubuntu C:\WSL\images\clean-wsl-base-ubuntu-2404.tar
```

### Retention

Keep at most two base images (current + one previous) to avoid disk bloat.
Delete stale images with:

```powershell
Remove-Item C:\WSL\images\clean-wsl-base-2023.tar
```

---

## Root-User Caveat

`wsl --import` creates the distro with **root** as default user.
`bootstrap.sh` needs a normal user context.

The automated script handles this automatically (discovers first non-root user
via `/etc/passwd`). For manual runs, set `default=<username>` in `/etc/wsl.conf`.

---

## Failure Modes

| Symptom | Likely Cause | Fix |
|---|---|---|
| `bootstrap.sh` fails at WSL2 check | Outside WSL or `/proc/version` mismatch | Run inside `wsl -d Ubuntu` |
| `bootstrap.sh` fails at systemd check | systemd not enabled | `wsl --set-version Ubuntu 2`, check `wsl.conf` |
| `nix build` fails `DOTFILES_USERNAME` unset | Env vars not exported | Re-export or let script handle it |
| HM activation fails as root | No non-root user | Apply `wsl.conf` workaround |
| Git clone fails | No network | Check internet / proxy |
| `wsl --import` access denied | Path permissions or WSL service | Run PowerShell as Administrator |

## References

- [Harness Script](scripts/wsl-end-to-end-test.ps1) — automated WSL test
- [Test Runner](scripts/wsl-test-scenarios.ps1) — scenario suite
- [Harness Validation](wsl-harness-validation.md) — acceptance criteria
- [Bootstrap Prerequisites Contract](bootstrap-contract.md) — required baseline
- [Map: Clean-machine rebuild test + CI](maps/clean-machine-rebuild-test-and-ci.md) — test strategy
- [Architecture](architecture.md) — Nix + Home Manager layering
- [Development](development.md) — validation workflow
