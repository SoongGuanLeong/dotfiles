# Map: Clean-machine rebuild test + CI

## Problem

The dotfiles repository must be reproducible from a clean Linux machine.

The validation strategy should prove three things:

1. Repository validation passes.
2. The Home Manager configuration evaluates and builds successfully.
3. A clean Linux environment can bootstrap and activate the configuration.

Windows and WSL-specific integration are intentionally outside the project scope.

## Current state

### CI

The repository has two CI workflows.

#### Check workflow

`.github/workflows/check.yml` runs on pushes to `master` and pull requests.

It performs:

1. `scripts/check.sh`
2. Home Manager activation package build

The build uses:

```bash
nix build --impure .#homeConfigurations.default.activationPackage
```

Required `DOTFILES_*` environment variables are provided by the workflow.

#### Integration workflow

`.github/workflows/integration.yml` runs nightly and can also be triggered
manually.

It builds and runs the Docker integration test:

```bash
docker build -t dotfiles-test .
docker run dotfiles-test
```

### Local validation scripts

The primary validation entry points are:

* `scripts/check.sh` — static and repository validation
* `scripts/rebuild.sh` — apply the Home Manager configuration
* `scripts/bootstrap.sh` — validate prerequisites, run checks, then rebuild
* `scripts/docker-test.sh` — clean Linux container integration test

### Flake outputs

The flake provides:

* `packages.x86_64-linux.home-manager`
* `homeConfigurations.default`
* `checks.x86_64-linux.registry`
* `envContract`

The registry check validates that files managed under `home/` are represented
by `registry.json` or explicitly exempted through `skip-list.json`.

## Clean-machine validation

A clean-machine test should use a fresh Linux environment with:

* Linux
* systemd
* Git
* Nix with flakes enabled

The canonical entry point is:

```bash
./scripts/bootstrap.sh
```

The expected sequence is:

```text
clean Linux environment
        |
        v
bootstrap.sh
        |
        +--> prerequisite validation
        |
        +--> check.sh
        |
        +--> rebuild.sh
        |
        v
Home Manager activation
        |
        v
working development environment
```

After activation, verify:

```bash
git --version
nvim --version | head -1
uv --version
```

Optional runtime managers such as NVM and SDKMAN are not required for a
successful base installation.

## Clean-room testing approaches

### A. Docker integration test

Docker provides a fast, repeatable Linux clean-room environment.

Advantages:

* Fast
* Reproducible
* Easy to run in CI
* No special host setup

Limitations:

* Does not reproduce a complete systemd host
* Does not validate every host-level prerequisite
* Does not prove that the configuration works on a persistent Linux machine

The Docker test should therefore complement, rather than replace, real-machine
validation.

### B. Real Linux machine or VM

A clean Linux VM provides the strongest validation of the actual bootstrap
contract.

Test procedure:

1. Start from a fresh Linux installation.
2. Ensure systemd is running.
3. Install Git.
4. Install Nix with flakes enabled.
5. Clone the repository.
6. Run `./scripts/bootstrap.sh`.
7. Start a fresh shell.
8. Verify the base environment.
9. Repeat after destroying and recreating the VM when major bootstrap changes
   are made.

This is the authoritative clean-machine test.

### C. Nix build validation

CI should continue to build the Home Manager activation package:

```bash
nix build --impure .#homeConfigurations.default.activationPackage
```

This catches evaluation and build failures without requiring a complete machine
activation.

## Recommended validation strategy

Use four layers:

| Layer       | Mechanism              | Purpose                                        |
| ----------- | ---------------------- | ---------------------------------------------- |
| Static      | `scripts/check.sh`     | Fast repository validation                     |
| Build       | `nix build`            | Validate Nix/Home Manager evaluation and build |
| Integration | Docker test            | Validate clean Linux execution                 |
| Full        | Fresh Linux VM/machine | Validate complete bootstrap contract           |

The first three layers belong in normal development and CI.

The full Linux machine test should be performed before releases and after
significant changes to bootstrap, Home Manager activation, systemd integration,
or core environment configuration.

## CI responsibilities

CI should remain fast and deterministic.

Pull requests should run:

```text
check
  |
  v
activation build
```

The integration workflow should provide:

```text
Docker build
  |
  v
Docker integration test
```

The full clean-machine test does not need to run on every pull request because
it requires a real Linux system and has a higher execution cost.

## Failure boundaries

Failures should be diagnosed according to the layer that failed.

### `scripts/check.sh` failure

Repository or configuration validation failed.

Run:

```bash
./scripts/check.sh
```

### Nix build failure

The configuration cannot be evaluated or built.

Run:

```bash
nix build --impure .#homeConfigurations.default.activationPackage
```

### Docker integration failure

The configuration or runtime assumptions are incompatible with the clean
container environment.

Run:

```bash
./scripts/docker-test.sh
```

### Clean-machine bootstrap failure

The bootstrap contract or system integration is broken.

Run:

```bash
./scripts/bootstrap.sh
```

Inspect the first failing prerequisite or activation step.

## Design decisions

1. Linux is the supported operating-system target.
2. systemd is part of the supported baseline.
3. Docker is an integration-test environment, not the production target.
4. The real Linux clean-machine test is the strongest end-to-end validation.
5. CI should prioritize fast deterministic checks.
6. Project-specific dependencies remain inside individual projects.

## Remaining work

* Keep `scripts/check.sh` and the Nix build green in CI.
* Keep the Docker integration test green.
* Periodically perform a clean Linux VM/machine bootstrap.
* Update this document when the validation architecture changes.

## References

* [`scripts/bootstrap.sh`](../../scripts/bootstrap.sh)
* [`scripts/check.sh`](../../scripts/check.sh)
* [`scripts/rebuild.sh`](../../scripts/rebuild.sh)
* [`scripts/docker-test.sh`](../../scripts/docker-test.sh)
* [`docs/bootstrap-contract.md`](../bootstrap-contract.md)
* [`docs/architecture.md`](../architecture.md)
* [`docs/development.md`](../development.md)
