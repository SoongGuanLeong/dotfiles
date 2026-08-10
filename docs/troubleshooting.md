# Troubleshooting

Use this guide when the dotfiles setup, rebuild, shell, or development tools are not behaving as expected.

## First checks

Start with:

```bash
git status
git diff --check
nix --version
uv --version
```

Then try a rebuild:

```bash
./scripts/rebuild.sh
```

If the rebuild succeeds, start a fresh shell:

```bash
exec zsh -l
```

---

## Home Manager rebuild fails

Run the rebuild directly:

```bash
./scripts/rebuild.sh
```

Look for the first actual error rather than warnings appearing afterward.

Check the Nix configuration syntax:

```bash
nix-instantiate --parse home.nix >/dev/null
```

Check the flake:

```bash
nix flake check
```

If the working tree is dirty, that is normally only a warning:

```text
warning: Git tree '...' is dirty
```

It does not by itself indicate a failed rebuild.

---

## `uv` is not found

Check where it comes from:

```bash
type -a uv
```

The expected result should point to the Home Manager/Nix installation:

```text
/home/<user>/.nix-profile/bin/uv
```

Check the version:

```bash
uv --version
```

If `uv` is missing after changing `home.nix`, rebuild:

```bash
./scripts/rebuild.sh
exec zsh -l
```

Do not reinstall the standalone uv binary into `~/.local/bin` unless there is a deliberate reason to override the Nix-managed installation.

---

## Python points to the wrong installation

The repository intentionally uses uv for Python development.

Check:

```bash
type -a python3
uv python list
```

The system may still contain:

```text
/usr/bin/python3
```

That is normal. The system Python is not the project's Python environment.

For project work, prefer:

```bash
uv run python
```

or an environment created by uv.

Do not remove the distribution's system Python just to enforce the repository's Python workflow. System utilities may depend on it.

---

## Python version is missing

List available uv-managed versions:

```bash
uv python list
```

Install the required version:

```bash
uv python install 3.13
```

For a project, select the version explicitly:

```bash
uv python pin 3.13
```

Then use:

```bash
uv run python
```

---

## NVM is not working

Check whether NVM is installed:

```bash
test -s "$HOME/.nvm/nvm.sh" && echo "NVM installed"
```

Check initialization:

```bash
echo "$NVM_DIR"
command -v nvm
```

The shell configuration treats NVM as optional. If NVM is not installed, the shell should still start normally.

If NVM is installed but unavailable:

```bash
exec zsh -l
```

Then:

```bash
command -v nvm
node --version
npm --version
```

---

## Node.js is missing

NVM owns Node.js versions.

Check:

```bash
nvm ls
```

Install/select a version through NVM rather than adding Node.js to `home.nix`.

For example:

```bash
nvm install <version>
nvm use <version>
```

The exact version should be chosen according to the project's requirements.

---

## SDKMAN is not working

Check whether SDKMAN is installed:

```bash
test -s "$HOME/.sdkman/bin/sdkman-init.sh" && echo "SDKMAN installed"
```

Check:

```bash
echo "$SDKMAN_DIR"
command -v sdk
```

Reload the shell:

```bash
exec zsh -l
```

Then verify:

```bash
java -version
scala -version
```

SDKMAN is optional. Its absence should not prevent the base shell from starting.

---

## Java or Scala is missing

SDKMAN owns Java and Scala versions.

Check installed candidates:

```bash
sdk list java
sdk list scala
```

Check currently selected versions:

```bash
sdk current java
sdk current scala
```

Install and select versions through SDKMAN rather than adding individual JDK or Scala versions to `home.nix`.

---

## Shell configuration is not applied

Check which Zsh is running:

```bash
echo "$SHELL"
command -v zsh
```

Reload the shell:

```bash
exec zsh -l
```

Check the managed file:

```bash
readlink -f ~/.zshrc
```

The Home Manager configuration sources the repository's:

```text
home/.zshrc
```

If the file was changed, rebuild first:

```bash
./scripts/rebuild.sh
```

---

## PATH contains unexpected entries

Inspect the PATH:

```bash
printf '%s\n' "$PATH" | tr ':' '\n'
```

Check specific runtime managers:

```bash
printf '%s\n' "$PATH" | grep -E 'nvm|sdkman|local/bin'
```

Remember the ownership model:

```text
~/.local/bin                         → user-installed executables
NVM paths                            → Node.js
SDKMAN Java/Scala paths              → Java/Scala
Nix/Home Manager paths                → declaratively managed tools
```

Avoid manually adding duplicate paths to `.zshrc` when Home Manager already manages them.

---

## A managed file has the wrong contents

Check the repository version:

```bash
git diff
```

Check the generated link:

```bash
readlink -f ~/.zshrc
```

For Home Manager-managed files, do not manually edit the generated target in `$HOME`.

Edit the source inside the repository and rebuild:

```bash
./scripts/rebuild.sh
```

---

## Security check reports a new nixpkgs revision as too young

Run:

```bash
./scripts/check-security.sh
```

If it reports:

```text
Status: TOO NEW FOR UPDATE
```

this is expected when the pinned revision is younger than the configured cooling period.

The repository currently uses a 14-day cooling period.

This is a policy guardrail, not an indication that the revision is malicious or vulnerable.

Wait until the revision becomes eligible before performing the normal dependency update.

---

## Security check reports a vulnerability

The security check reads vulnerability metadata from Nixpkgs.

If it reports a vulnerable package:

1. Identify the affected package.
2. Check whether the vulnerability is still applicable.
3. Determine whether a newer safe package is available.
4. Consider updating the nixpkgs revision when policy permits.
5. Re-run the security check.
6. Rebuild and verify the environment.

Do not simply remove the security check or suppress the package's vulnerability metadata.

---

## Flake evaluation uses the wrong user or home directory

The repository passes these values to the flake:

```text
DOTFILES_USERNAME
DOTFILES_HOME
DOTFILES_DIRECTORY
```

Check them:

```bash
printf '%s\n' \
  "$DOTFILES_USERNAME" \
  "$DOTFILES_HOME" \
  "$DOTFILES_DIRECTORY"
```

The normal scripts set them automatically.

Prefer using:

```bash
./scripts/rebuild.sh
```

instead of invoking the Home Manager flake manually.

---

## The repository is dirty

Check:

```bash
git status
```

A dirty tree is not automatically a problem.

Nix may print:

```text
warning: Git tree '...' is dirty
```

This simply means there are uncommitted changes.

Before committing, inspect them:

```bash
git diff
git diff --check
```

---

## Rebuild succeeds but a command is still missing

First determine which executable is being used:

```bash
type -a <command>
```

Then inspect the Home Manager package set:

```bash
nix eval --impure \
  '.#homeConfigurations.default.config.home.packages'
```

Reload the shell:

```bash
exec zsh -l
```

If the command belongs to a runtime ecosystem, verify its dedicated manager instead of assuming Home Manager should provide it.

---

## When to stop and investigate

Do not blindly keep rebuilding if:

* a configuration file is unexpectedly replaced
* a package reports a known vulnerability
* a runtime manager points to an unexpected installation
* a command resolves to an unexpected binary
* a dependency update produces a large unexplained change
* credentials or secrets appear in the repository
* the rebuild wants to remove something you still need

Inspect the diff and current state first.

Useful commands:

```bash
git status
git diff
git diff --check
type -a <command>
readlink -f "$(command -v <command>)"
```

The goal is to understand **which layer owns the problem** before changing anything.
