@echo off
rem Link the skills from a git clone - Windows, cmd.exe entry point.
rem Wraps scripts\install.ps1 with a per-process -ExecutionPolicy Bypass:
rem no administrator rights needed (links are directory junctions).
rem All arguments pass through (-Platforms claude, -Local, -Update, -Uninstall...).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%
