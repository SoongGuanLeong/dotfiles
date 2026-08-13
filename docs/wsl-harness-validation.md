# WSL End-to-End Harness Validation

This document outlines the validation procedure for `scripts/wsl-end-to-end-test.ps1`.

## Prerequisites

1. Windows 10/11 with WSL2 enabled.
2. PowerShell 5.1 or later.
3. A fresh exported WSL2 base image (e.g., `clean-wsl-base.tar`).

## Running Tests

Use the provided test runner script:

```powershell
# Update $baseImage path in scripts/wsl-test-scenarios.ps1 first
.\scripts\wsl-test-scenarios.ps1
```

## Test Scenarios

The runner automates the following scenarios:

1. **Clean pass:** Fresh image, bootstrap succeeds, cleanup runs, exit 0.
2. **Missing base image:** Invalid path, clear error, exit non-zero.
3. **Existing test distro:** Replace existing `dotfiles-test` cleanly.
4. **Bootstrap failure:** Invalid `RepoUrl` forces failure, shows last 20 lines.
5. **-SkipCleanup:** Preserves `dotfiles-test` distro and data dir for inspection.
6. **Safety guard:** Verifies `-DistroName Ubuntu` is rejected by parameter validation.

## Acceptance Criteria

- All scenarios pass as expected.
- Structured JSON output generated for each run.
- Errors are clear and diagnostic (especially for bootstrap failures).
