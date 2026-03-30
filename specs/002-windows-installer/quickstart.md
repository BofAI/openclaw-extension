# Quickstart: Windows Installer

## Prerequisites

- Windows 10 (1511+) or Windows 11
- Node.js v18+ (with npm/npx in PATH)
- Git (in PATH)
- OpenClaw installed (`%USERPROFILE%\.openclaw` exists)
- PowerShell 5.1+ (included with Windows 10/11)

## Running the Installer

### Direct execution (recommended)

```cmd
install.bat
```

Or from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

### Pipe-install (one-liner)

```powershell
irm https://raw.githubusercontent.com/BofAI/openclaw-extension/main/install.ps1 | iex
```

## Development

### Validate syntax

```powershell
# Parse check (PowerShell syntax validation)
[System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$null, [ref]$null)
```

### Run locally

```cmd
install.bat
```

### Test pipe-install flow

```powershell
Get-Content install.ps1 -Raw | Invoke-Expression
```

## File Structure

```
install.bat    # Thin cmd.exe launcher (invokes install.ps1 with bypass)
install.ps1    # All installer logic (Windows equivalent of install.sh)
install.sh     # Original Linux/macOS installer (unchanged)
```
