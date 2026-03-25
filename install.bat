@echo off
REM OpenClaw Extension Installer (by BANK OF AI) - Windows Launcher
REM This is a thin launcher that invokes install.ps1 with the correct execution policy.
REM All installer logic resides in install.ps1.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%
