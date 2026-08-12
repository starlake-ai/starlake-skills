@echo off
rem Bootstrap installer for starlake-skills - Windows, cmd.exe entry point.
rem
rem Why this file: on locked-down machines the PowerShell execution policy
rem blocks running .ps1 scripts directly. This wrapper launches the real
rem installer with a PER-PROCESS -ExecutionPolicy Bypass, which requires NO
rem administrator rights (the install itself only downloads a release into
rem %USERPROFILE%\.starlake-skills and creates directory JUNCTIONS - no
rem admin, no Developer Mode needed).
rem
rem Standalone (no clone needed) - two commands, from any cmd prompt:
rem   curl -fsSL -o "%TEMP%\sl-skills-install.cmd" https://raw.githubusercontent.com/starlake-ai/starlake-skills/main/scripts/install-remote.cmd
rem   "%TEMP%\sl-skills-install.cmd"
rem
rem All arguments pass through to install-remote.ps1 (-Pin vX.Y.Z, -Platforms
rem claude, -Local, -Uninstall...).
setlocal
set "PS1=%~dp0install-remote.ps1"
if exist "%PS1%" goto run
rem Running standalone (downloaded copy): fetch the matching .ps1 first.
set "PS1=%TEMP%\starlake-skills-install-remote.ps1"
curl -fsSL -o "%PS1%" https://raw.githubusercontent.com/starlake-ai/starlake-skills/main/scripts/install-remote.ps1
if errorlevel 1 (
  echo failed to download install-remote.ps1 - check network/proxy
  exit /b 1
)
:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
