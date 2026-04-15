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
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Platforms "claude"
    .\install.ps1 -Local
    .\install.ps1 -Update
    .\install.ps1 -Uninstall
#>
param(
    [switch]$Global,
    [switch]$Local,
    [switch]$Update,
    [switch]$Uninstall,
    [string]$Platforms = "claude,copilot,gemini",
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
