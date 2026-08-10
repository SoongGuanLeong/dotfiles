# Onboarding

This guide gets a new WSL2 environment from zero to a working development shell.

## 1. Prerequisites

Install and verify:

* WSL2 with a Linux distribution
* Git
* Nix with flakes enabled

Check:

```bash
wsl --version
git --version
nix --version
```

Nix should support flakes.

## 2. Clone the repository

```bash
mkdir -p ~/projects
cd ~/projects

git clone <YOUR_REPOSITORY_URL> dotfiles
cd dotfiles
```

## 3. Activate the environment

Run:

```bash
./scripts/rebuild.sh
```

The script:

1. Determines the repository location.
2. Exports the environment variables required by the flake.
3. Maintains `~/.dotfiles` as a convenience symlink.
4. Activates Home Manager using the pinned flake inputs.

Start a fresh shell afterward:

```bash
exec zsh -l
```

## 4. Verify the base environment

Run:

```bash
echo "=== shell ==="
echo "$SHELL"

echo
echo "=== core tools ==="
git --version
nvim --version | head -1
uv --version
```

The commands should resolve successfully.

## 5. Python

Python is intentionally managed through `uv`.

Check:

```bash
uv --version
uv python list
```

Do not add Python itself to `home.nix`.

For a project:

```bash
uv init my-project
cd my-project
uv add pandas
uv run python
```

Project dependencies and environments belong to the project, not the dotfiles repository.

## 6. Optional runtimes

Node.js and Java/Scala are not required by the base environment.

### Node.js

If Node.js is needed, use NVM.

The shell automatically initializes NVM when it is installed:

```bash
node --version
npm --version
```

If NVM is not installed, the shell continues normally.

### Java / Scala

If Java or Scala is needed, use SDKMAN.

The shell automatically initializes SDKMAN when it is installed:

```bash
java -version
scala -version
```

If SDKMAN is not installed, the shell continues normally.

## 7. Verify optional runtimes

Only run these checks if the corresponding runtime manager is installed:

```bash
node --version
npm --version

java -version
scala -version
```

A missing optional runtime is not an onboarding failure.

## 8. Daily workflow

After changing dotfiles:

```bash
./scripts/rebuild.sh
```

Then start a new shell if necessary:

```bash
exec zsh -l
```

Check the repository:

```bash
git status
```

## 9. Dependency updates

Normal rebuilds do **not** update dependencies.

Before updating:

```bash
./scripts/check-security.sh
```

The repository uses a 14-day cooling period for new nixpkgs revisions.

When an update becomes eligible:

```bash
nix flake update
./scripts/check-security.sh
./scripts/rebuild.sh
```

Review the resulting `flake.lock` changes before committing.

## 10. If something fails

Do not immediately modify the configuration.

First check:

```bash
git status
git diff
./scripts/check-security.sh
```

Then consult:

* [Architecture](architecture.md) to understand ownership.
* [Development](development.md) for normal workflows.
* [Troubleshooting](troubleshooting.md) for known problems.

## 11. Onboarding is complete when

The following work:

```bash
./scripts/rebuild.sh
exec zsh -l

git --version
nvim --version
uv --version
```

Optional runtimes may be absent.

The important invariant is that the **base environment works without requiring NVM or SDKMAN**.
