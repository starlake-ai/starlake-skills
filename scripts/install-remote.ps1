#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap installer: downloads a starlake-skills release from GitHub
    Releases into an install directory, then runs the bundled install.ps1
    to link the skills. No git or Node required.
.PARAMETER Pin
    Install an exact release (e.g. v1.2.0). Default: latest release.
.PARAMETER Dir
    Install directory (default: ~/.starlake-skills)
.PARAMETER Platforms
    Comma-separated platforms forwarded to install.ps1
    (claude,copilot,gemini - default: install.ps1's default, i.e. all).
.PARAMETER Local
    Forwarded to install.ps1: link into ./.<platform>/skills of the current
    directory instead of the home directory.
.PARAMETER Uninstall
    Skip the download and run the already installed copy's uninstaller.
.EXAMPLE
    .\install-remote.ps1
    .\install-remote.ps1 -Pin v1.2.0
    .\install-remote.ps1 -Platforms "claude"
#>
param(
    [string]$Pin = "",
    [string]$Dir = "",
    [string]$Platforms = "",
    [switch]$Local,
    [switch]$Uninstall,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

$RepoSlug = if ($env:STARLAKE_SKILLS_REPO) { $env:STARLAKE_SKILLS_REPO } else { "starlake-ai/starlake-skills" }
$BaseUrl = if ($env:STARLAKE_SKILLS_BASE_URL) { $env:STARLAKE_SKILLS_BASE_URL } else { "https://github.com/$RepoSlug/releases/download" }
$ApiUrl = if ($env:STARLAKE_SKILLS_API_URL) { $env:STARLAKE_SKILLS_API_URL } else { "https://api.github.com/repos/$RepoSlug/releases/latest" }
$InstallDir = if ($Dir) { $Dir } elseif ($env:STARLAKE_SKILLS_DIR) { $env:STARLAKE_SKILLS_DIR } else { Join-Path $HOME ".starlake-skills" }

# Forward options to install.ps1 BY NAME (hashtable splat). Never splat an
# array here: array elements bind POSITIONALLY, so "-Platforms x" ended up as
# the literal value of install.ps1's first positional string parameters
# ($Platforms = "-Platforms", $Channel = "x") and died on the Channel
# ValidateSet.
$Forward = @{}
if ($Platforms) { $Forward["Platforms"] = $Platforms }
if ($Local)     { $Forward["Local"] = $true }

# In-process "&" of a .ps1 only sets $LASTEXITCODE when the child script calls
# exit; under Set-StrictMode reading it unset is an error. Default to 0.
function Get-ChildExitCode {
    if (Test-Path variable:global:LASTEXITCODE) { return $global:LASTEXITCODE }
    return 0
}

# Uninstall never needs a download.
if ($Uninstall) {
    $installer = Join-Path $InstallDir "scripts/install.ps1"
    if (-not (Test-Path $installer)) {
        Write-Error "no installation found at $InstallDir"
        exit 1
    }
    & $installer -Uninstall @Forward
    exit (Get-ChildExitCode)
}

# Never clobber a git clone: that workflow updates via git, not archives.
if (Test-Path (Join-Path $InstallDir ".git")) {
    Write-Error "$InstallDir is a git clone. Update it with 'git pull' + 'scripts/install.ps1 -Update' (or -Channel/-Pin), not with this script."
    exit 1
}

# Resolve the tag to install
$Tag = $Pin
if (-not $Tag) {
    try {
        $Tag = (Invoke-RestMethod -Uri $ApiUrl).tag_name
    } catch {
        Write-Error "could not resolve the latest release from $ApiUrl (no releases published yet? pass -Pin vX.Y.Z, or install via git clone)"
        exit 1
    }
}

$Asset = "starlake-skills-$Tag.zip"
$TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
    Write-Host "Downloading $Asset ($BaseUrl/$Tag/$Asset)"
    Invoke-WebRequest -Uri "$BaseUrl/$Tag/$Asset" -OutFile (Join-Path $TmpDir $Asset)
    Expand-Archive -Path (Join-Path $TmpDir $Asset) -DestinationPath $TmpDir

    $Unpacked = Join-Path $TmpDir "starlake-skills"
    if (-not (Test-Path (Join-Path $Unpacked "scripts/install.ps1"))) {
        Write-Error "unexpected archive layout in $Asset"
        exit 1
    }

    # Swap in the new version, then re-link from scratch (skills may have changed).
    if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
    $parent = Split-Path -Parent $InstallDir
    if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Move-Item $Unpacked $InstallDir

    Write-Host "Installed $Tag to $InstallDir"
    & (Join-Path $InstallDir "scripts/install.ps1") -Update @Forward
    $InstallExitCode = Get-ChildExitCode
} finally {
    if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }
}
exit $InstallExitCode
