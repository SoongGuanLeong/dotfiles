# WSL Clean-Machine Rebuild Test Procedure

**Status:** Active
**Domain:** WSL2, Ubuntu, Nix, Home Manager
**Strategy layer:** Full validation (manual, before release or major env changes)

## Purpose

This procedure validates the full dotfiles bootstrap from a truly clean WSL2
instance — the outermost validation layer of the three-tier test strategy
([map](maps/clean-machine-rebuild-test-and-ci.md)). It proves the entire
setup works in the real target environment end-to-end.

## Prerequisites

| Item | Required |
|---|---|
| Windows host with WSL2 installed | yes |
| Default WSL2 distro (Ubuntu) registered and working | yes |
| Sufficient disk space for base image + test clone | ~4 GB per image |
| `dotfiles` repository cloned on the Windows host or accessible via `git clone` | yes |
| Bootstrap prerequisites contract satisfied (see [bootstrap-contract.md](bootstrap-contract.md)) | yes |

## One-Time Setup: Export Clean Base Image

After a fresh Ubuntu WSL2 install (no dotfiles applied), export the clean state
as a portable tar archive. This image is reused across all test cycles.

```powershell
# From PowerShell or CMD on Windows:
wsl --export Ubuntu C:\WSL\images\clean-wsl-base.tar
```

Store the image in a durable location such as an external drive or a network
share. The file is a multi-gigabyte binary — do **not** commit it to the
dotfiles repository.

### Image Rotation

Keep multiple snapshots if you test across different WSL2 base versions.

```powershell
wsl --export Ubuntu C:\WSL\images\clean-wsl-base-2024Q4.tar
```

Label each image with the Ubuntu release and the date of the base install.

## Per-Test Cycle

Each cycle starts from the same clean base image, runs the full bootstrap, and
validates the result. Repeat as needed.

### Step 1: Unregister Existing Distro

Remove any previously running instance of the distro under test.

```powershell
wsl --terminate Ubuntu
wsl --unregister Ubuntu
```

### Step 2: Reimport from Clean Base Image

Restore the pristine WSL2 instance from the exported base image.

```powershell
wsl --import Ubuntu C:\WSL\clean-test C:\WSL\images\clean-wsl-base.tar
```

### Step 3: Launch and Configure Non-Root User

`wsl --import` creates the distro running as **root** by default. The bootstrap
prerequisites (`bootstrap.sh`) expect a non-root user context. Apply the
workaround before proceeding.

**Option A — Default UID in wsl.conf (recommended):**

```powershell
wsl -d Ubuntu -- bash -c "
  echo '[user]' > /etc/wsl.conf
  echo 'default=<your-username>' >> /etc/wsl.conf
"
wsl --terminate Ubuntu
wsl -d Ubuntu
```

Replace `<your-username>` with the non-root username you want to use.

**Option B — First-boot script:**

Create `/etc/wsl.conf` with the same content inside a first-boot provisioning
step.

### Step 4: Set Environment Variables

The bootstrap process requires three environment variables defined in the
[envContract](maps/clean-machine-rebuild-test-and-ci.md#other-flake-outputs).

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

This validates all prerequisites (WSL2, systemd, Ubuntu, git, Nix, flakes),
runs `check.sh` for syntax and security checks, then rebuilds the Home Manager
configuration.

### Step 7: Verify the Environment

After bootstrap completes, confirm the key tools and configurations:

```bash
git --version
nix --version
nvim --version | head -1
uv --version
echo $SHELL              # expect /run/current-system/sw/bin/zsh or similar
echo $DOTFILES_USERNAME  # expect the configured username
ls -la ~/.config/nvim    # expect managed Neovim config
```

### Step 8: Smoke-Test a Shell

Launch a new login shell and confirm the environment is fully active:

```bash
exec zsh -l
```

### Step 9: Record Results

Log the test outcome:

| Date | Commit SHA | Bootstrap Result | Verification Result | Notes |
|---|---|---|---|---|
| 2025-01-15 | abc1234 | pass | pass | Nix store partially cached |

## Post-Test Cleanup

Remove the test instance to free disk space:

```powershell
wsl --terminate Ubuntu
wsl --unregister Ubuntu
```

The import directory (`C:\WSL\clean-test` in the examples above) can be deleted
manually if desired.

## Image Management

### Refresh the Base Image

When the WSL2 base OS (Ubuntu) receives a major update, or when you want to
test against a different Ubuntu release, export a fresh base image:

```powershell
wsl --export Ubuntu C:\WSL\images\clean-wsl-base-ubuntu-2404.tar
```

### Retention

Keep at most two base images (current + one previous) to avoid disk bloat.
Delete stale images with:

```powershell
Remove-Item C:\WSL\images\clean-wsl-base-2023.tar
```

## Root-User Caveat

`wsl --import` always creates the distro with **root** as the default user.
This is a known WSL2 behavior documented by Microsoft.

**Impact:** `bootstrap.sh` and the Home Manager activation run operations
that expect a normal user environment (e.g., `$HOME` resolution, systemd
user units). Running under root will cause failures or produce incorrect
configurations.

**Workaround:** Set `default=<username>` in `/etc/wsl.conf` under the `[user]`
section (shown in Step 3), then restart the WSL instance. This fix persists
across restarts and is the recommended approach.

## Failure Modes and Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `bootstrap.sh` fails at WSL2 check | Running outside WSL or `/proc/version` mismatch | Confirm the test runs inside `wsl -d Ubuntu` |
| `bootstrap.sh` fails at systemd check | systemd not enabled in WSL2 | `wsl --set-version Ubuntu 2` and verify `wsl.conf` has `systemd=true` |
| `nix build` fails with `DOTFILES_USERNAME` unset | Environment variables not exported | Re-run Step 4 `export` commands |
| Home Manager activation fails as root | No non-root user configured | Apply the `/etc/wsl.conf` workaround (Step 3) |
| Git clone fails | No network inside WSL2 | Verify Windows host has internet; check corporate proxy |
| `wsl --import` fails with access denied | Path permissions or WSL service issue | Run PowerShell as Administrator |

## References

- [Bootstrap Prerequisites Contract](bootstrap-contract.md) — required baseline
- [Map: Clean-machine rebuild test + CI](maps/clean-machine-rebuild-test-and-ci.md) — test strategy
- [Architecture](architecture.md) — Nix + Home Manager layering
- [Development](development.md) — validation workflow
- [scripts/bootstrap.sh](../scripts/bootstrap.sh) — prerequisite validation + activation
- [Issue #34](https://github.com/SoongGuanLeong/dotfiles/issues/34) — this ticket
