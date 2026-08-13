#!/usr/bin/env pwsh
<#
.SYNOPSIS
    End-to-end WSL2 bootstrap test for dotfiles.

.DESCRIPTION
    Automates the full clean-machine WSL2 test procedure:
      1. Import clean base image as disposable WSL distro
      2. Configure systemd + non-root default user
      3. Install git/Nix prerequisites if missing
      4. Clone dotfiles repo
      5. Run bootstrap.sh
      6. Smoke-test activated environment
      7. Report structured pass/fail
      8. Cleanup (unless -SkipCleanup)

    Uses a dedicated distro name (default: "dotfiles-test").
    Will never touch a distro named "Ubuntu".

.PARAMETER BaseImage
    Path to exported clean WSL2 base image (.tar). Required.
    Should be fresh Ubuntu WSL2 export (no dotfiles applied).
    Git/Nix auto-installed if missing.

.PARAMETER RepoUrl
    Git URL for cloning dotfiles.
    Default: https://github.com/SoongGuanLeong/dotfiles.git

.PARAMETER LocalPath
    Local directory to copy into WSL instead of cloning.
    Overrides RepoUrl. Useful for testing uncommitted changes.

.PARAMETER DistroName
    WSL distro name for test instance.
    Default: dotfiles-test. Must not be "Ubuntu".

.PARAMETER InstallDir
    Directory to store WSL distro filesystem.
    Default: ./wsl-test-data

.PARAMETER TestUser
    Non-root username in base image. Auto-discovered from /etc/passwd
    if omitted (first user with UID >= 1000).

.PARAMETER SkipCleanup
    Leave test distro + install dir for post-mortem inspection.

.PARAMETER PassThru
    Return result object instead of exiting (programmatic use).

.EXAMPLE
    .\scripts\wsl-end-to-end-test.ps1 -BaseImage C:\WSL\images\clean-wsl-base.tar

.EXAMPLE
    .\scripts\wsl-end-to-end-test.ps1 -BaseImage .\clean-wsl-base.tar -LocalPath ..\dotfiles

.EXAMPLE
    .\scripts\wsl-end-to-end-test.ps1 -BaseImage .\clean-wsl-base.tar -SkipCleanup
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$BaseImage,

    [Parameter(Mandatory = $false)]
    [string]$RepoUrl = "https://github.com/SoongGuanLeong/dotfiles.git",

    [Parameter(Mandatory = $false)]
    [string]$LocalPath = "",

    [Parameter(Mandatory = $false)]
    [ValidateScript({
        $_ -notin @("Ubuntu", "ubuntu") -or
            (Write-Warning "DistroName 'Ubuntu' forbidden (safety guard). Use disposable name."
                -and $false)
    })]
    [string]$DistroName = "dotfiles-test",

    [Parameter(Mandatory = $false)]
    [string]$InstallDir = (Join-Path (Get-Location) "wsl-test-data"),

    [Parameter(Mandatory = $false)]
    [string]$TestUser = "",

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup,

    [Parameter(Mandatory = $false)]
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

# ─── state ────────────────────────────────────────────────────────────────

$results = [System.Collections.Generic.List[PSObject]]::new()
$globalStartTime = Get-Date
$overallStatus = "pass"
$failureMessage = $null
$commitSha = $null
$resultObj = $null

# ─── helpers ──────────────────────────────────────────────────────────────

function Add-Result($name, $status, $detail, $duration) {
    $results.Add([PSCustomObject]@{
        name     = $name
        status   = $status
        detail   = $detail
        duration = $duration
    })
}

function Step($name, [ScriptBlock]$block) {
    $s = Get-Date
    try {
        & $block
        $d = (Get-Date) - $s
        Add-Result -name $name -status "pass" -detail "" -duration [math]::Round($d.TotalSeconds, 1)
        Write-Host "  ✓ $name" -ForegroundColor Green
    }
    catch {
        $d = (Get-Date) - $s
        Add-Result -name $name -status "fail" -detail $_.Exception.Message -duration [math]::Round($d.TotalSeconds, 1)
        Write-Host "  ✗ $name : $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Require-Command($name) {
    if (!(Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command '$name' not found in PATH."
    }
}

# Resolve-Path wrapper: returns resolved path string or $null
function Resolve-PathSafe($path) {
    $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
    if ($resolved) { return $resolved.ProviderPath }
    return $null
}

# Convert Windows path (C:\foo) to WSL path (/mnt/c/foo)
function ConvertTo-WslPath($winPath) {
    $drive = $winPath.Substring(0, 1).ToLower()
    $rest = $winPath.Substring(2) -replace '\\', '/'
    return "/mnt/$drive$rest"
}

# Run a command inside the test WSL distro. Returns trimmed stdout.
# Sets $script:wslLastExit for the caller to inspect.
function Invoke-Wsl([string]$cmd) {
    $raw = & wsl -d $DistroName -- bash -c $cmd 2>&1
    $script:wslLastExit = $LASTEXITCODE
    return ($raw | Out-String).Trim()
}

# Run command inside WSL; throw on non-zero exit.
function Invoke-WslChecked($label, [string]$cmd) {
    $out = Invoke-Wsl $cmd
    if ($script:wslLastExit -ne 0) {
        throw "$label failed (exit $script:wslLastExit): $out"
    }
    return $out
}

# ─── main flow ────────────────────────────────────────────────────────────

try {

Write-Host "=== WSL End-to-End Test ===" -ForegroundColor Cyan
Write-Host "Distro:  $DistroName"
Write-Host "Image:   $BaseImage"
Write-Host ""

# ── step 0: validate host prerequisites ───────────────────────────────────

Step "validate-prerequisites" {
    Require-Command wsl

    $ver = & wsl --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL not available. Install WSL2 first."
    }
    # WSL 2.x.y.z or WSL 1.x.y.z — warn if 1.x
    if ($ver -match 'WSL 1\.') {
        Write-Warning "WSL1 detected. Test requires WSL2."
    }
}

# ── step 1: unregister any existing test distro ───────────────────────────

Step "unregister-existing" {
    $existing = & wsl --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { $existing = "" }

    if ($existing -match [regex]::Escape($DistroName)) {
        Write-Host "    Removing existing '$DistroName' distro..."
        & wsl --unregister $DistroName 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to unregister existing distro '$DistroName'."
        }
    }
    else {
        Write-Host "    No existing '$DistroName' distro."
    }
}

# ── step 2: prepare install directory ─────────────────────────────────────

$installDirFull = $null

Step "prepare-install-dir" {
    $resolved = Resolve-PathSafe $InstallDir
    if (-not $resolved) {
        $resolved = (New-Item -ItemType Directory -Path $InstallDir -Force).FullName
    }
    $script:installDirFull = $resolved
    Write-Host "    Install dir: $resolved"
}

# ── step 3: import base image ─────────────────────────────────────────────

Step "import-image" {
    $imgPath = Resolve-PathSafe $BaseImage
    & wsl --import $DistroName $script:installDirFull $imgPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "wsl --import failed."
    }
    Write-Host "    Imported to $script:installDirFull"
}

# ── step 4: ensure WSL2 ───────────────────────────────────────────────────

Step "ensure-wsl2" {
    & wsl --set-version $DistroName 2 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
        # Exit code 1 often means "already WSL2" — only fail on other codes
        Write-Warning "wsl --set-version returned $LASTEXITCODE (may already be WSL2)"
    }
    Write-Host "    WSL2 version ensured."
}

# ── step 5: configure wsl.conf (systemd + non-root user) ──────────────────

Step "configure-wslconf" {
    # Discover non-root user if not provided
    if ([string]::IsNullOrEmpty($TestUser)) {
        $passwd = & wsl -d $DistroName -- cat /etc/passwd 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot read /etc/passwd inside imported distro."
        }
        $candidates = $passwd -split "`n" | ForEach-Object {
            $parts = $_ -split ":"
            if ($parts.Count -ge 3) {
                $uid = 0
                if ([int]::TryParse($parts[2], [ref]$uid) -and $uid -ge 1000 -and $parts[0] -notin @('nobody', 'nogroup')) {
                    $parts[0]
                }
            }
        }
        if (-not $candidates) {
            throw "No non-root user (UID >= 1000) found in base image /etc/passwd."
        }
        $TestUser = $candidates[0]
        Write-Host "    Discovered user: $TestUser"
    }

    # Write /etc/wsl.conf via heredoc inside WSL
    $wslConf = @"
[user]
default=$TestUser

[boot]
systemd=true
"@
    & wsl -d $DistroName -- bash -c "cat > /etc/wsl.conf << 'WSL_CONF_EOF'
$wslConf
WSL_CONF_EOF" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to write /etc/wsl.conf."
    }
    Write-Host "    wsl.conf: user=$TestUser, systemd=true"
}

# ── step 6: restart WSL to pick up wsl.conf ───────────────────────────────

Step "restart-wsl" {
    & wsl --terminate $DistroName 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    $user = & wsl -d $DistroName -- whoami 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL instance failed to start after restart."
    }
    Write-Host "    WSL restarted, default user: $($user.Trim())"
}

# ── step 7: install prerequisites (git, nix, flakes) if missing ───────────

Step "install-prerequisites" {
    $hasGit = (Invoke-Wsl "command -v git") -match "/"
    $hasNix = (Invoke-Wsl "command -v nix") -match "/"

    if (-not $hasGit) {
        Write-Host "    Installing git..."
        Invoke-WslChecked "git install" "sudo apt-get update -qq && sudo apt-get install -y -qq git"
    }
    else {
        Write-Host "    git: present"
    }

    if (-not $hasNix) {
        Write-Host "    Installing Nix (single-user)..."
        Invoke-WslChecked "nix prereqs" "sudo apt-get install -y -qq curl xz-utils"
        # --no-daemon: single-user mode, no systemd service needed
        Invoke-WslChecked "nix install" "sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon"
        Invoke-WslChecked "flakes enable" "mkdir -p /etc/nix && echo 'experimental-features = nix-command flakes' | sudo tee /etc/nix/nix.conf > /dev/null"
        Write-Host "    Nix installed, flakes enabled"
    }
    else {
        Write-Host "    nix: present"
        # Ensure flakes enabled
        $flakesOut = Invoke-Wsl "nix show-config 2>/dev/null | grep experimental-features || true"
        if ($script:wslLastExit -ne 0 -or $flakesOut -notmatch "flakes") {
            Invoke-WslChecked "flakes enable" "mkdir -p /etc/nix && echo 'experimental-features = nix-command flakes' | sudo tee /etc/nix/nix.conf > /dev/null"
            Write-Host "    Flakes enabled."
        }
    }
}

# ── step 8: clone or copy repo ────────────────────────────────────────────

Step "clone-repo" {
    if (-not [string]::IsNullOrEmpty($LocalPath)) {
        $localResolved = Resolve-PathSafe $LocalPath
        if (-not $localResolved) { throw "LocalPath '$LocalPath' not found." }
        Invoke-WslChecked "mkdir in WSL" "mkdir -p ~/projects"
        $wslSrc = ConvertTo-WslPath $localResolved
        Invoke-WslChecked "copy repo" "cp -r '$wslSrc' ~/projects/dotfiles"
        Write-Host "    Copied local repo from $localResolved"
    }
    else {
        Invoke-WslChecked "git clone" "cd ~ && mkdir -p ~/projects && git clone --depth 1 '$RepoUrl' ~/projects/dotfiles"
        Write-Host "    Cloned from $RepoUrl"
    }

    # Capture commit SHA
    $sha = Invoke-Wsl "cd ~/projects/dotfiles && git rev-parse --short HEAD 2>/dev/null || true"
    if ($script:wslLastExit -eq 0 -and -not [string]::IsNullOrEmpty($sha)) {
        $script:commitSha = $sha
    }
}

# ── step 9: run bootstrap ─────────────────────────────────────────────────

Step "bootstrap" {
    $bootstrapOut = Invoke-Wsl @"
export DOTFILES_USERNAME=\$(whoami)
export DOTFILES_HOME=\$HOME
export DOTFILES_DIRECTORY=\$HOME/projects/dotfiles
cd \$HOME/projects/dotfiles
./scripts/bootstrap.sh 2>&1
"@
    if ($script:wslLastExit -ne 0) {
        Write-Host "    Bootstrap output (last 20 lines):" -ForegroundColor Yellow
        $bootstrapOut -split "`n" | Select-Object -Last 20 | ForEach-Object { Write-Host "      $_" }
        throw "bootstrap.sh exited with code $($script:wslLastExit). See output above."
    }
    Write-Host "    bootstrap.sh: OK"
}

# ── step 10: smoke test ───────────────────────────────────────────────────

Step "smoke-test" {
    $smokeFailures = @()

    # Check each tool: returns (version_line, exit_code)
    function Check-Tool($tool, $versionFlag) {
        $out = Invoke-Wsl "$tool $versionFlag 2>&1 | head -1"
        $code = $script:wslLastExit
        $line = ($out -split "`n")[0].Trim()
        if ($code -ne 0 -or [string]::IsNullOrEmpty($line)) {
            $smokeFailures += "$tool: not found (exit $code)"
        }
        else {
            Write-Host "    $tool : $line"
        }
    }

    Check-Tool "git" "--version"
    Check-Tool "nix" "--version"
    Check-Tool "nvim" "--version"
    Check-Tool "uv" "--version"

    # Default shell
    $shell = Invoke-Wsl "echo \$SHELL"
    Write-Host "    SHELL : $shell"
    if ($shell -notmatch "zsh|bash") {
        $smokeFailures += "SHELL is not zsh or bash: $shell"
    }

    # Git alias (expect zsh with alias configured)
    $aliasOut = Invoke-Wsl "zsh -lic 'alias gst' 2>&1 || true"
    if ($aliasOut -match "gst='git status'|gst=git status") {
        Write-Host "    alias gst : OK"
    }
    else {
        Write-Host "    alias gst : $aliasOut"
        # Soft warning — alias may not load in non-interactive zsh -l
    }

    if ($smokeFailures.Count -gt 0) {
        throw "Smoke test failures: $($smokeFailures -join '; ')"
    }
    Write-Host "    All smoke tests passed" -ForegroundColor Green
}

# ── build report object ──────────────────────────────────────────────────

}
catch {
    $overallStatus = "fail"
    $failureMessage = $_.Exception.Message
}
finally {

$totalDuration = [math]::Round(((Get-Date) - $globalStartTime).TotalSeconds, 1)

$resultObj = [PSCustomObject]@{
    test        = "wsl-end-to-end"
    timestamp   = (Get-Date -Format "o")
    distro      = $DistroName
    baseImage   = (Resolve-PathSafe $BaseImage)
    commitSha   = $commitSha
    duration    = "$($totalDuration)s"
    steps       = [PSCustomObject[]]@($results)
    overall     = $overallStatus
    error       = $failureMessage
}

Write-Host ""
Write-Host "=== RESULTS ===" -ForegroundColor Cyan
$resultObj | ConvertTo-Json -Depth 3
Write-Host ""

# ─── cleanup ──────────────────────────────────────────────────────────────

if (-not $SkipCleanup -and $script:installDirFull) {
    Write-Host "=== Cleanup ===" -ForegroundColor Cyan
    try {
        & wsl --terminate $DistroName 2>&1 | Out-Null
        & wsl --unregister $DistroName 2>&1 | Out-Null
        if (Test-Path $script:installDirFull) {
            Remove-Item -Recurse -Force $script:installDirFull -ErrorAction SilentlyContinue
        }
        Write-Host "  Cleanup complete."
    }
    catch {
        Write-Warning "Cleanup issue: $_"
    }
}
elseif (-not $SkipCleanup) {
    Write-Host "=== Cleanup (skipped — no install dir) ===" -ForegroundColor Yellow
}
else {
    Write-Host "=== Cleanup skipped (-SkipCleanup) ===" -ForegroundColor Yellow
    if ($script:installDirFull) {
        Write-Host "  Distro '$DistroName' and data at '$script:installDirFull' preserved."
    }
}

Write-Host ""
if ($overallStatus -eq "pass") {
    Write-Host "OVERALL: PASS" -ForegroundColor Green
}
else {
    Write-Host "OVERALL: FAIL" -ForegroundColor Red
    Write-Host "Reason: $failureMessage"
}

}

# ─── exit ─────────────────────────────────────────────────────────────────

if ($PassThru) {
    return $resultObj
}

exit $(if ($overallStatus -eq "pass") { 0 } else { 1 })
