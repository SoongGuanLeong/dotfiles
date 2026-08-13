# WSL Harness Test Scenarios
# Run this on Windows host with PowerShell 5.1+

$baseImage = "C:\path\to\clean-wsl-base.tar" # UPDATE THIS
$testScript = ".\scripts\wsl-end-to-end-test.ps1"

function Run-Scenario($name, $params) {
    Write-Host "=== Running Scenario: $name ===" -ForegroundColor Cyan
    & $testScript @params
    Write-Host "Scenario $name exit code: $LASTEXITCODE"
}

# 1. Clean pass
Run-Scenario "Clean pass" @{
    BaseImage = $baseImage
}

# 2. Missing base image
Run-Scenario "Missing base image" @{
    BaseImage = "C:\nonexistent.tar"
}

# 3. Existing test distro (Run once to create, then again to test replacement)
Write-Host "=== Setup for Existing test distro ==="
& $testScript -BaseImage $baseImage
Run-Scenario "Existing test distro" @{
    BaseImage = $baseImage
}

# 4. Bootstrap failure (Corrupt lock - simulate by providing empty file if possible? 
# Maybe pass invalid RepoUrl to force failure)
Run-Scenario "Bootstrap failure" @{
    BaseImage = $baseImage
    RepoUrl = "https://github.com/invalid/url"
}

# 5. -SkipCleanup
Run-Scenario "SkipCleanup" @{
    BaseImage = $baseImage
    SkipCleanup = $true
}

# 6. Safety guard
Run-Scenario "Safety guard" @{
    BaseImage = $baseImage
    DistroName = "Ubuntu"
}
