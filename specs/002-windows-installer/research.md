# Research: Windows Installer (install.bat)

## R-001: Batch vs PowerShell vs Hybrid

**Decision**: Use a hybrid approach — `install.bat` as a thin launcher that delegates to an embedded PowerShell script.

**Rationale**:
- Pure batch (cmd.exe) cannot implement arrow-key multiselect menus, lacks native ANSI color support on older Windows, and has extremely limited string/array handling.
- Pure PowerShell (.ps1) requires execution policy changes (`Set-ExecutionPolicy`) or explicit bypass (`powershell -ExecutionPolicy Bypass -File install.ps1`), which is a friction point for users.
- A `.bat` file can invoke PowerShell inline with `powershell -ExecutionPolicy Bypass -Command "& { ... }"` — no execution policy barrier and the user just double-clicks or runs `install.bat`.
- However, embedding a full 700-line PowerShell script inside a `.bat` is unwieldy. The practical approach: `install.bat` is a short launcher that invokes `install.ps1` with bypass, and `install.ps1` contains all logic.

**Revised Decision**: Ship **two files** — `install.bat` (thin cmd launcher, ~10 lines) + `install.ps1` (all logic). This aligns with the constitution's "single-script architecture" spirit: `install.ps1` is the Windows equivalent of `install.sh`, and `install.bat` is a convenience launcher (analogous to how `curl | bash` is the launcher for `install.sh`).

**Alternatives considered**:
- Pure `.bat` only: Rejected — cannot do multiselect UI, limited ANSI support, arrays extremely painful.
- Pure `.ps1` only: Rejected — execution policy friction. Users would need `powershell -ep bypass -f install.ps1` which is not as clean as double-click.
- Node.js script: Rejected — adds a different paradigm and doesn't align with the bash installer's shell-native approach.

## R-002: Pipe-Install on Windows

**Decision**: Support `irm <url> | iex` (Invoke-RestMethod piped to Invoke-Expression) as the PowerShell equivalent of `curl | bash`.

**Rationale**:
- `irm | iex` is the standard PowerShell pipe-install pattern (used by rustup, volta, scoop, etc.).
- When stdin is a pipe, interactive prompts must read from the console directly using `[Console]::ReadLine()` or `Read-Host` (which always reads from the console, not stdin) — this is the Windows equivalent of `/dev/tty`.
- `Read-Host` in PowerShell always reads from the attached console, making it naturally pipe-safe (unlike bash's `read` which reads from stdin by default).

**Alternatives considered**:
- `curl | cmd /c` for batch: Rejected — cmd.exe pipe-install is not a standard pattern and is fragile.
- Download-then-run: A fallback, not a replacement. The pipe-install flow should work directly.

## R-003: Windows ANSI Color Support

**Decision**: Use ANSI escape codes with a startup check that enables Virtual Terminal Processing.

**Rationale**:
- Windows 10 1511+ (November 2015 Update) supports ANSI escape codes in both cmd.exe and PowerShell, but Virtual Terminal Processing must be enabled.
- In PowerShell, this can be done by setting `$Host.UI.SupportsVirtualTerminal` or calling the Win32 API `SetConsoleMode` with `ENABLE_VIRTUAL_TERMINAL_PROCESSING`.
- Simpler approach: `$env:TERM` or just outputting `$PSStyle` (PowerShell 7.2+). For compatibility with Windows PowerShell 5.1, use `[Console]::OutputEncoding` and write a small enable-VT function.
- Fallback: If VT processing cannot be enabled (Windows Server 2012, older Windows), strip ANSI codes and output plain text.

**Alternatives considered**:
- Write-Host with -ForegroundColor: Works but limited to 16 colors, cannot match the exact RGB values used in install.sh.
- No colors on Windows: Rejected — spec requires matching the bash installer's output.

## R-004: File Permission Restriction (chmod 600 equivalent)

**Decision**: Use `icacls` to remove inherited permissions and grant only the current user full control.

**Rationale**:
- Windows doesn't have Unix permissions. The equivalent of `chmod 600` is:
  ```
  icacls "$filePath" /inheritance:r /grant:r "${env:USERNAME}:(R,W)" /remove "BUILTIN\Users" /remove "Everyone"
  ```
- This removes inherited ACLs, grants the current user read+write, and explicitly removes common groups.
- PowerShell-native alternative using `Set-Acl` is more verbose but more reliable:
  ```powershell
  $acl = New-Object System.Security.AccessControl.FileSecurity
  $acl.SetAccessRuleProtection($true, $false)  # disable inheritance, remove inherited rules
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "ReadWrite", "Allow")
  $acl.AddAccessRule($rule)
  Set-Acl -Path $filePath -AclObject $acl
  ```

**Alternatives considered**:
- Skip permission restriction on Windows: Rejected — constitution Principle VI requires credential security.
- Use attrib +H (hidden): Insufficient — hidden is not access control.

## R-005: Interactive Multiselect in PowerShell

**Decision**: Implement multiselect using `[Console]::ReadKey()` in PowerShell, mirroring the bash installer's TUI.

**Rationale**:
- `[Console]::ReadKey($true)` (intercept=true) reads individual keystrokes without echo — exactly what's needed for arrow-key navigation.
- Arrow keys produce `[ConsoleKey]::UpArrow`, `[ConsoleKey]::DownArrow`, etc.
- Space toggles selection, Enter confirms — same UX as the bash version.
- Cursor hiding/showing: `[Console]::CursorVisible = $false` / `$true`.
- This is a direct port of the bash multiselect function.

**Alternatives considered**:
- `choice.exe` (cmd built-in): Only supports single-key choices (A/B/C), not multiselect.
- Out-GridView (PowerShell): GUI popup, not console-based. Doesn't work in pipe-install or headless scenarios.

## R-006: Ctrl+C Handling

**Decision**: Use PowerShell's `try/finally` block and `[Console]::TreatControlCAsInput` for cleanup.

**Rationale**:
- `try { ... } finally { [Console]::CursorVisible = $true }` ensures cursor is restored on any exit.
- For the multiselect function specifically, set `[Console]::TreatControlCAsInput = $true` during key reading, then restore it after.
- Global script level: `trap` equivalent is `Register-EngineEvent PowerShell.Exiting -Action { cleanup }` or simply wrapping main logic in try/finally.

**Alternatives considered**:
- `SetConsoleCtrlHandler` via P/Invoke: Overkill for this use case.
- No cleanup: Rejected — leaving cursor hidden is a bad UX.

## R-007: Constitution Compliance — Single-Script Principle

**Decision**: The constitution's Principle I needs a justified extension. `install.ps1` is the Windows equivalent of `install.sh` — it IS the single script for Windows. `install.bat` is a thin launcher (analogous to the `curl | bash` invocation itself).

**Rationale**:
- The spirit of Principle I is auditability: "users can read one file to understand everything." For Windows users, that one file is `install.ps1`.
- `install.bat` contains zero logic — it simply calls `install.ps1` with the correct execution policy. It is a delivery mechanism, not a second script.
- A formal constitution amendment (MINOR version bump to 1.1.0) should add Windows to the Technology Constraints section and clarify that each OS has its single-script equivalent.

**Required constitution updates**:
- Technology Constraints: Add "PowerShell 5.1+ on Windows 10+" alongside "Bash on Linux and macOS"
- Principle I: Clarify that each supported OS has its own single-script installer
- Quality Gates: Add Windows equivalents (syntax check, lint, direct run, pipe run)
