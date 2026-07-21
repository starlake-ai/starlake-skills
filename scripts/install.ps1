#Requires -Version 5.1
<#
.SYNOPSIS
    Install starlake-skills by symlinking into AI coding assistant directories.
.PARAMETER Global
    Install to ~/.<platform>/skills/ (default)
.PARAMETER Local
    Install to ./.<platform>/skills/ in current directory
.PARAMETER Update
    Remove existing starlake symlinks, then re-install
.PARAMETER Uninstall
    Remove all starlake-skills symlinks
.PARAMETER Platforms
    Comma-separated list: claude,copilot,gemini (default: all)
.PARAMETER Channel
    Switch the repo before installing: 'stable' (newest vX.Y.Z tag) or 'latest'
    (main branch). Without this parameter the repo's git state is never touched.
.PARAMETER Pin
    Switch the repo to an exact tag (e.g. v1.2.0)
.PARAMETER Version
    Print the installed version and exit
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Platforms "claude"
    .\install.ps1 -Local
    .\install.ps1 -Update
    .\install.ps1 -Update -Channel stable
    .\install.ps1 -Pin v1.2.0
    .\install.ps1 -Uninstall
#>
param(
    [switch]$Global,
    [switch]$Local,
    [switch]$Update,
    [switch]$Uninstall,
    [string]$Platforms = "claude,copilot,gemini",
    [ValidateSet("stable", "latest")]
    [string]$Channel = "",
    [string]$Pin = "",
    [switch]$Version,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Constants ──────────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$AgentsDir = Join-Path $RepoDir ".agents"

# ── Counters ───────────────────────────────────────────────────────────
$script:Installed = 0
$script:Skipped = 0
$script:Warnings = 0
$script:Removed = 0
$script:Errors = 0

# ── Usage ──────────────────────────────────────────────────────────────
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# ── Determine mode and action ──────────────────────────────────────────
$Mode = if ($Local) { "local" } else { "global" }
$Action = if ($Uninstall) { "uninstall" } elseif ($Update) { "update" } else { "install" }

# ── Validation ─────────────────────────────────────────────────────────
if (-not (Test-Path $AgentsDir)) {
    Write-Error ".agents/ directory not found at $AgentsDir"
    exit 1
}

if ($Channel -and $Pin) {
    Write-Error "-Channel and -Pin are mutually exclusive"
    exit 1
}

# ── Versioning helpers ─────────────────────────────────────────────────
function Get-RepoVersion {
    # Relax EAP locally: under "Stop", redirected native stderr can become a
    # terminating error in Windows PowerShell 5.1.
    $ErrorActionPreference = "Continue"
    $v = git -C $RepoDir describe --tags --always 2>$null
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0 -and $v) { return $v }
    # Archive installs (install-remote.ps1) have no .git but carry a stamped VERSION file.
    $versionFile = Join-Path $RepoDir "VERSION"
    if (Test-Path $versionFile) { return (Get-Content $versionFile -First 1) }
    "unknown"
}

# Switch the repo to the requested channel or pinned tag.
# Only called when -Channel or -Pin was passed explicitly.
function Switch-Version {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required for -Channel / -Pin"
        exit 1
    }
    # Relax EAP for the native git calls below (see Get-RepoVersion).
    $ErrorActionPreference = "Continue"
    git -C $RepoDir rev-parse --git-dir 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$RepoDir is not a git repository (release-archive install? switch versions with install-remote.ps1 -Pin instead)"
        exit 1
    }

    git -C $RepoDir fetch --tags --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Warning: could not fetch from remote, using local refs"
        $script:Warnings++
    }

    $ref = ""
    if ($Pin) {
        $ref = $Pin
    } elseif ($Channel -eq "stable") {
        $ref = git -C $RepoDir tag --list 'v[0-9]*' --sort=-v:refname 2>$null | Select-Object -First 1
        if (-not $ref) {
            Write-Error "no vX.Y.Z tags found; the stable channel requires at least one release tag"
            exit 1
        }
    } else { # latest
        $ref = "main"
    }

    Write-Host "Switching repo to $ref"
    git -C $RepoDir checkout --quiet $ref 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "could not check out '$ref' (uncommitted changes in $RepoDir?)"
        exit 1
    }
    if ($ref -eq "main") {
        git -C $RepoDir pull --ff-only --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Warning: could not fast-forward main, using local state"
            $script:Warnings++
        }
    }
    $ErrorActionPreference = "Stop"
    Write-Host "Installed version: $(Get-RepoVersion)"
}

# ── Helpers ────────────────────────────────────────────────────────────
function Resolve-BaseDir {
    param([string]$Platform)
    if ($Mode -eq "global") {
        Join-Path $HOME ".$Platform"
    } else {
        ".$Platform"
    }
}

function Test-StarlakeLink {
    param([string]$Link)
    $item = Get-Item $Link -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $false }
    if ($item.LinkType -ne "SymbolicLink" -and $item.LinkType -ne "Junction") { return $false }
    $target = $item.Target
    if ($target -is [array]) { $target = $target[0] }
    return $target.StartsWith($RepoDir)
}

function New-SkillSymlink {
    param([string]$Source, [string]$Target)
    $name = Split-Path -Leaf $Target

    if (Test-Path $Target) {
        $item = Get-Item $Target
        if ($item.LinkType -eq "SymbolicLink" -or $item.LinkType -eq "Junction") {
            if (Test-StarlakeLink $Target) {
                $script:Skipped++
                return
            } else {
                Write-Host "  Warning: $Target is a symlink to a different source, skipping"
                $script:Warnings++
                return
            }
        } else {
            Write-Host "  Warning: $Target exists and is not a symlink, skipping"
            $script:Warnings++
            return
        }
    }

    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    $script:Installed++
}

function Remove-StarlakeLinks {
    param([string]$Dir)
    $skillsDir = Join-Path $Dir "skills"

    if (Test-Path $skillsDir) {
        Get-ChildItem $skillsDir | ForEach-Object {
            if (Test-StarlakeLink $_.FullName) {
                Remove-Item $_.FullName -Force
                $script:Removed++
            }
        }
    }

    $starflowLink = Join-Path $Dir "starflow"
    if ((Test-Path $starflowLink) -and (Test-StarlakeLink $starflowLink)) {
        Remove-Item $starflowLink -Force
        $script:Removed++
    }
}

function Install-Platform {
    param([string]$Platform)
    $baseDir = Resolve-BaseDir $Platform
    $skillsDir = Join-Path $baseDir "skills"

    Write-Host "Installing for $Platform -> $baseDir"

    try {
        if (-not (Test-Path $skillsDir)) {
            New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
        }
    } catch {
        Write-Host "  Error: cannot create $skillsDir"
        $script:Errors++
        return
    }

    # Symlink core skills
    Get-ChildItem (Join-Path $AgentsDir "skills") -Directory | ForEach-Object {
        New-SkillSymlink $_.FullName (Join-Path $skillsDir $_.Name)
    }

    # Symlink starflow skills
    Get-ChildItem (Join-Path $AgentsDir "starflow/skills") -Directory | ForEach-Object {
        New-SkillSymlink $_.FullName (Join-Path $skillsDir $_.Name)
    }

    # Symlink starflow directory (config + templates)
    New-SkillSymlink (Join-Path $AgentsDir "starflow") (Join-Path $baseDir "starflow")
}

function Uninstall-Platform {
    param([string]$Platform)
    $baseDir = Resolve-BaseDir $Platform

    Write-Host "Uninstalling for $Platform <- $baseDir"
    Remove-StarlakeLinks $baseDir
}

# ── Main ───────────────────────────────────────────────────────────────
$PlatformList = $Platforms -split ","

if ($Version) {
    Get-RepoVersion
    exit 0
}

# A channel/pin switch may add or remove skill folders, so re-link from scratch.
if (($Channel -or $Pin) -and ($Action -ne "uninstall")) {
    Switch-Version
    if ($Action -eq "install") { $Action = "update" }
}

switch ($Action) {
    "install" {
        foreach ($p in $PlatformList) {
            Install-Platform $p
        }
        Write-Host ""
        Write-Host "Done: $($script:Installed) installed, $($script:Skipped) already present, $($script:Warnings) warnings, $($script:Errors) errors"
    }
    "update" {
        foreach ($p in $PlatformList) {
            Uninstall-Platform $p
        }
        foreach ($p in $PlatformList) {
            Install-Platform $p
        }
        Write-Host ""
        Write-Host "Done: $($script:Removed) removed, $($script:Installed) installed, $($script:Warnings) warnings, $($script:Errors) errors"
    }
    "uninstall" {
        foreach ($p in $PlatformList) {
            Uninstall-Platform $p
        }
        Write-Host ""
        Write-Host "Done: $($script:Removed) symlinks removed"
    }
}

if ($script:Errors -gt 0) { exit 1 }
