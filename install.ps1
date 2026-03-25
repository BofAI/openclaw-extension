# OpenClaw Extension Installer (by BANK OF AI) - Windows
# Installs MCP servers via npx add-mcp and skills via npx skills add

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- ANSI Colors & Styling ---

function Enable-VirtualTerminal {
    # Enable ANSI escape code processing on Windows 10+
    try {
        $signature = @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
        $WinAPI = Add-Type -MemberDefinition $signature -Name 'WinAPI' -Namespace 'Console' -PassThru
        $STD_OUTPUT_HANDLE = -11
        $ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
        $handle = $WinAPI::GetStdHandle($STD_OUTPUT_HANDLE)
        $mode = 0
        $null = $WinAPI::GetConsoleMode($handle, [ref]$mode)
        $null = $WinAPI::SetConsoleMode($handle, $mode -bor $ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        return $true
    }
    catch {
        return $false
    }
}

$script:VTEnabled = Enable-VirtualTerminal

# Use [char]27 for ESC - compatible with PowerShell 5.1+ (Win10 built-in)
$script:ESC = [char]27

if ($script:VTEnabled) {
    $script:BOLD       = "$($script:ESC)[1m"
    $script:ACCENT     = "$($script:ESC)[38;2;255;90;45m"
    $script:ACCENT_DIM = "$($script:ESC)[38;2;209;74;34m"
    $script:INFO       = "$($script:ESC)[38;2;0;145;255m"
    $script:SUCCESS    = "$($script:ESC)[38;2;0;200;83m"
    $script:WARN       = "$($script:ESC)[38;2;255;171;0m"
    $script:ERROR_CLR  = "$($script:ESC)[38;2;211;47;47m"
    $script:MUTED      = "$($script:ESC)[38;2;128;128;128m"
    $script:NC         = "$($script:ESC)[0m"
}
else {
    $script:BOLD       = ""
    $script:ACCENT     = ""
    $script:ACCENT_DIM = ""
    $script:INFO       = ""
    $script:SUCCESS    = ""
    $script:WARN       = ""
    $script:ERROR_CLR  = ""
    $script:MUTED      = ""
    $script:NC         = ""
}

# --- Configuration ---
$script:McpConfigDir  = Join-Path $env:USERPROFILE ".mcporter"
$script:McpConfigFile = Join-Path $script:McpConfigDir "mcporter.json"
$script:AgentWalletVersion = "2.3.1-beta.0"
$script:SkillsRepo    = "https://github.com/BofAI/skills/tree/v1.5.0"
$script:InstalledSkills = @()
$script:CleanInstall  = $false
$script:SkillsGlobalFlag = ""
$script:SkipMcp       = $false

# --- Taglines ---
$script:TAGLINES = @(
    "TRON agents: Low fees, high speeds, zero excuses."
    "Managing your wallet faster than SunPump drops a new meme."
    "Private keys stay private. We're a bank, not a billboard."
    "Energy rental? Bandwidth? I'll calculate it so you don't have to."
    "Your financial sovereignty, now with automated claws."
    "TRC-20 automation: Sending tokens like it's text messages."
    "Smart contracts, smarter agent. No more manual ABI guessing."
    "OpenClaw Extension: Where AI meets DeFi, and your portfolio thanks you."
)

function Get-Tagline {
    return $script:TAGLINES | Get-Random
}

# --- Node.js JSON Helpers ---

function Merge-NodeJson {
    param(
        [string]$ServerId,
        [string]$EnvJson,
        [string]$ConfigFile
    )
    $env:MCP_FILE = $ConfigFile
    $env:SERVER_ID = $ServerId
    $env:ENV_JSON = $EnvJson
    @'
const _fs = require("fs");
const f = process.env.MCP_FILE;
const sid = process.env.SERVER_ID;
const envData = JSON.parse(process.env.ENV_JSON);
let d = {};
if (_fs.existsSync(f)) {
    try { d = JSON.parse(_fs.readFileSync(f, "utf8")); } catch(e) {}
}
if (!d.mcpServers) d.mcpServers = {};
if (!d.mcpServers[sid]) d.mcpServers[sid] = {};
if (!d.mcpServers[sid].env) d.mcpServers[sid].env = {};
for (const [k, v] of Object.entries(envData)) {
    if (v === null || v === "") {
        delete d.mcpServers[sid].env[k];
    } else {
        d.mcpServers[sid].env[k] = v;
    }
}
_fs.writeFileSync(f, JSON.stringify(d, null, 2));
'@ | node --input-type=commonjs
    Remove-Item Env:\MCP_FILE -ErrorAction SilentlyContinue
    Remove-Item Env:\SERVER_ID -ErrorAction SilentlyContinue
    Remove-Item Env:\ENV_JSON -ErrorAction SilentlyContinue
}

function Write-NodeJson {
    param(
        [string]$FilePath,
        [string]$JsonContent
    )
    $env:FILE_PATH = $FilePath
    $env:JSON_CONTENT = $JsonContent
    @'
const _fs = require("fs");
const _path = require("path");
const f = process.env.FILE_PATH;
const dir = _path.dirname(f);
if (!_fs.existsSync(dir)) _fs.mkdirSync(dir, { recursive: true });
const data = JSON.parse(process.env.JSON_CONTENT);
_fs.writeFileSync(f, JSON.stringify(data, null, 2));
'@ | node --input-type=commonjs
    Remove-Item Env:\FILE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\JSON_CONTENT -ErrorAction SilentlyContinue
}

function Read-NodeJson {
    param(
        [string]$FilePath,
        [string]$Key
    )
    $env:FILE_PATH = $FilePath
    $env:JSON_KEY = $Key
    $result = @'
const _fs = require("fs");
const f = process.env.FILE_PATH;
const k = process.env.JSON_KEY;
try {
    const d = JSON.parse(_fs.readFileSync(f, "utf8"));
    const v = d[k];
    process.stdout.write(v ? String(v) : "");
} catch(e) {
    process.stdout.write("");
}
'@ | node --input-type=commonjs
    Remove-Item Env:\FILE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\JSON_KEY -ErrorAction SilentlyContinue
    return $result
}

function Reset-NodeJsonMcp {
    param(
        [string]$ConfigFile
    )
    $env:MCP_FILE = $ConfigFile
    @'
const _fs = require("fs");
const f = process.env.MCP_FILE;
let d = {};
if (_fs.existsSync(f)) {
    try { d = JSON.parse(_fs.readFileSync(f, "utf8")); } catch(e) {}
}
d.mcpServers = {};
_fs.writeFileSync(f, JSON.stringify(d, null, 2));
'@ | node --input-type=commonjs
    Remove-Item Env:\MCP_FILE -ErrorAction SilentlyContinue
}

# --- Input Helper ---

function Read-UserInput {
    param(
        [string]$Prompt,
        [bool]$IsSecret = $false,
        [string]$Description = ""
    )
    if ($Description) {
        Write-Host "  $Description" -ForegroundColor DarkGray
    }
    $displayPrompt = "${script:INFO}?${script:NC} $Prompt ${script:MUTED}(optional)${script:NC}: "
    Write-Host $displayPrompt -NoNewline
    if ($IsSecret) {
        $secure = Read-Host -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
    else {
        return Read-Host
    }
}

# --- File Permission Helper (chmod 600 equivalent) ---

function Set-FileOwnerOnly {
    param(
        [string]$FilePath
    )
    & icacls "$FilePath" /inheritance:r /grant:r "${env:USERNAME}:(R,W)" /remove "BUILTIN\Users" /remove "Everyone" 2>&1 | Out-Null
}

# --- Multiselect UI ---

function Show-MultiSelect {
    param(
        [string]$Prompt,
        [string[]]$Options
    )

    $selected = @()
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $selected += $true
    }
    $current = 0

    $termCols = 80
    try { $termCols = [Console]::WindowWidth } catch { $termCols = 80 }
    if ($termCols -lt 20) { $termCols = 80 }

    Write-Host "${script:INFO}?${script:NC} ${script:BOLD}$Prompt${script:NC} ${script:MUTED}(Space:toggle, Enter:confirm)${script:NC}"

    $previousFrameLines = 0

    try {
        [Console]::CursorVisible = $false

        while ($true) {
            # Move cursor up to overwrite previous frame
            if ($previousFrameLines -gt 0) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - $previousFrameLines)
            }

            $frameLines = 0

            for ($i = 0; $i -lt $Options.Count; $i++) {
                $raw = $Options[$i]
                $name = $raw
                $desc = ""

                if ($raw -match '\|\|') {
                    $parts = $raw -split '\|\|', 2
                    $name = $parts[0]
                    $desc = $parts[1]
                }

                $name = ($name -replace '\s+', ' ').Trim()
                $maxLen = $termCols - 6
                if ($name.Length -gt $maxLen) { $name = $name.Substring(0, $maxLen) }

                $checkbox = "[ ]"
                $color = $script:NC
                $pointer = "  "

                if ($selected[$i]) {
                    $checkbox = "${script:SUCCESS}[x]${script:NC}"
                    $color = $script:BOLD
                }

                if ($i -eq $current) {
                    $pointer = "${script:ACCENT}$([char]0x276F) ${script:NC}"
                    $color = $script:ACCENT
                    if ($selected[$i]) {
                        $checkbox = "${script:ACCENT}[x]${script:NC}"
                    }
                    else {
                        $checkbox = "${script:ACCENT}[ ]${script:NC}"
                    }
                }

                # Clear line and write
                Write-Host "`r$(' ' * ($termCols - 1))`r" -NoNewline
                Write-Host "${pointer}${checkbox} ${color}${name}${script:NC}"
                $frameLines++

                if ($i -eq $current -and $desc) {
                    $indent = "      "
                    $wrapWidth = $termCols - $indent.Length - 1
                    if ($wrapWidth -lt 20) { $wrapWidth = 20 }
                    $words = $desc.Trim() -split '\s+'
                    $line = ""
                    foreach ($word in $words) {
                        if ($line.Length -gt 0 -and ($line.Length + 1 + $word.Length) -gt $wrapWidth) {
                            Write-Host "`r$(' ' * ($termCols - 1))`r" -NoNewline
                            Write-Host "${script:MUTED}${indent}${line}${script:NC}"
                            $frameLines++
                            $line = $word
                        }
                        else {
                            if ($line.Length -gt 0) { $line += " " }
                            $line += $word
                        }
                    }
                    if ($line.Length -gt 0) {
                        Write-Host "`r$(' ' * ($termCols - 1))`r" -NoNewline
                        Write-Host "${script:MUTED}${indent}${line}${script:NC}"
                        $frameLines++
                    }
                }
            }

            # Clear any leftover lines from previous frame
            if ($frameLines -lt $previousFrameLines) {
                for ($j = $frameLines; $j -lt $previousFrameLines; $j++) {
                    Write-Host "`r$(' ' * ($termCols - 1))`r"
                }
                [Console]::SetCursorPosition(0, [Console]::CursorTop - ($previousFrameLines - $frameLines))
            }

            $previousFrameLines = $frameLines

            # Read key input
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'Enter' {
                    break
                }
                'Spacebar' {
                    $selected[$current] = -not $selected[$current]
                }
                'UpArrow' {
                    $current--
                    if ($current -lt 0) { $current = $Options.Count - 1 }
                }
                'DownArrow' {
                    $current++
                    if ($current -ge $Options.Count) { $current = 0 }
                }
            }

            if ($key.Key -eq 'Enter') { break }
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }

    # Return selected indices
    $indices = @()
    for ($i = 0; $i -lt $Options.Count; $i++) {
        if ($selected[$i]) {
            $indices += $i
        }
    }
    return , $indices
}

# --- Pre-flight Checks ---

function Test-Environment {
    # Check Node.js
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        throw "Node.js is not installed. Please install Node.js v18+ from https://nodejs.org/"
    }
    # Check Node.js version >= 18
    try {
        $nodeVersion = (node --version) -replace '^v', ''
        $major = [int]($nodeVersion -split '\.')[0]
        if ($major -lt 18) {
            throw "Node.js v18+ is required (found v${nodeVersion})."
        }
    }
    catch [System.Management.Automation.RuntimeException] {
        throw
    }
    catch {
        Write-Host "${script:WARN}Warning: Could not determine Node.js version.${script:NC}"
    }

    # Check npx
    if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
        throw "'npx' is not found. It should come with Node.js — try reinstalling Node.js."
    }

    # Check git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is not installed. Please install Git from https://git-scm.com/"
    }

    # Check OpenClaw
    $openclawDir = Join-Path $env:USERPROFILE ".openclaw"
    if (-not (Test-Path $openclawDir -PathType Container)) {
        Write-Host "${script:WARN}Warning: OpenClaw doesn't appear to be installed.${script:NC}"
        Write-Host "${script:WARN}This installer requires OpenClaw to be installed first.${script:NC}"
        Write-Host "${script:INFO}Install OpenClaw from: https://github.com/openclaw${script:NC}"
        Write-Host ""
        Write-Host "${script:INFO}?${script:NC} Continue anyway? ${script:MUTED}(y/N)${script:NC}: " -NoNewline
        $continueChoice = Read-Host
        if ($continueChoice -notmatch '^[Yy]$') {
            return
        }
    }
}

# --- Clean Install ---

function Invoke-CleanInstall {
    Write-Host ""
    Write-Host "${script:ERROR_CLR}${script:BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${script:NC}"
    Write-Host "${script:ERROR_CLR}${script:BOLD}!!!                    CLEAN INSTALL MODE                    !!!${script:NC}"
    Write-Host "${script:ERROR_CLR}${script:BOLD}!!!                  THIS ACTION IS IRREVERSIBLE             !!!${script:NC}"
    Write-Host "${script:ERROR_CLR}${script:BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${script:NC}"
    Write-Host ""
    Write-Host "${script:WARN}The following data will be permanently deleted:${script:NC}"
    Write-Host "  ${script:WARN}$([char]0x2022)${script:NC} ALL MCP entries in: ${script:INFO}$($script:McpConfigFile)${script:NC}"
    Write-Host "  ${script:WARN}$([char]0x2022)${script:NC} ALL installed skills (global and workspace)"
    Write-Host "  ${script:WARN}$([char]0x2022)${script:NC} x402 config file: ${script:INFO}$(Join-Path $env:USERPROFILE '.x402-config.json')${script:NC}"
    Write-Host "  ${script:WARN}$([char]0x2022)${script:NC} BANK OF AI local config: ${script:INFO}$(Join-Path $env:USERPROFILE '.mcporter\bankofai-config.json')${script:NC}"
    Write-Host "  ${script:WARN}$([char]0x2022)${script:NC} AgentWallet config will be overwritten by: ${script:INFO}agent-wallet start --override --save-runtime-secrets${script:NC}"
    Write-Host ""
    Write-Host "${script:ERROR_CLR}?${script:NC} Continue with CLEAN install? ${script:MUTED}(y/N)${script:NC}: " -NoNewline
    $cleanConfirm = Read-Host
    if ($cleanConfirm -notmatch '^[Yy]$') {
        Write-Host "${script:MUTED}Clean install cancelled.${script:NC}"
        Write-Host ""
        return
    }

    Write-Host "${script:ERROR_CLR}?${script:NC} Type ${script:BOLD}CLEAN${script:NC}${script:ERROR_CLR} to confirm permanent deletion${script:NC}: " -NoNewline
    $cleanWord = Read-Host
    if ($cleanWord -ne "CLEAN") {
        Write-Host "${script:WARN}Confirmation text mismatch. Clean install cancelled.${script:NC}"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "${script:INFO}Running cleanup...${script:NC}"
    Reset-NodeJsonMcp -ConfigFile $script:McpConfigFile
    try { npx.cmd -y skills remove -a openclaw --all -y -g 2>$null } catch {}
    try { npx.cmd -y skills remove -a openclaw --all -y 2>$null } catch {}
    Remove-Item (Join-Path $env:USERPROFILE ".x402-config.json") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:USERPROFILE ".mcporter\bankofai-config.json") -ErrorAction SilentlyContinue
    Write-Host "${script:SUCCESS}$([char]0x2713) Clean install cleanup completed.${script:NC}"
    Write-Host ""
}

function Select-InstallMode {
    Write-Host ""
    Write-Host "${script:BOLD}Installation Mode${script:NC}"
    Write-Host "  ${script:INFO}1)${script:NC} Normal install ${script:SUCCESS}[Recommended]${script:NC}"
    Write-Host "  ${script:INFO}2)${script:NC} Clean install ${script:WARN}(full cleanup: MCP/skills/local config files)${script:NC}"
    Write-Host ""
    Write-Host "${script:INFO}?${script:NC} Enter choice ${script:MUTED}(1-2, default: 1)${script:NC}: " -NoNewline
    $installModeChoice = Read-Host
    if (-not $installModeChoice) { $installModeChoice = "1" }

    if ($installModeChoice -eq "2") {
        $script:CleanInstall = $true
        Invoke-CleanInstall
        Write-Host "${script:SUCCESS}Clean complete - proceeding with fresh setup...${script:NC}"
        Write-Host ""
    }
}

# --- AgentWallet ---

function Install-AgentWalletCli {
    $currentVersion = ""
    try {
        $npmListOutput = npm.cmd list -g --depth=0 @bankofai/agent-wallet 2>$null
        if ($npmListOutput) {
            $match = [regex]::Match(($npmListOutput -join "`n"), '@bankofai/agent-wallet@([^\s]+)')
            if ($match.Success) {
                $currentVersion = $match.Groups[1].Value
            }
        }
    }
    catch {}

    if ($currentVersion -eq $script:AgentWalletVersion) {
        return
    }

    if ($currentVersion) {
        Write-Host "${script:INFO}Updating AgentWallet CLI to $($script:AgentWalletVersion)...${script:NC}"
    }
    else {
        Write-Host "${script:INFO}Installing AgentWallet CLI $($script:AgentWalletVersion)...${script:NC}"
    }

    npm.cmd install -g "@bankofai/agent-wallet@$($script:AgentWalletVersion)" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${script:INFO}Try manually: npm install -g @bankofai/agent-wallet@$($script:AgentWalletVersion)${script:NC}"
        throw "Failed to install AgentWallet CLI $($script:AgentWalletVersion)."
    }

    # Verify
    $currentVersion = ""
    try {
        $npmListOutput = npm.cmd list -g --depth=0 @bankofai/agent-wallet 2>$null
        if ($npmListOutput) {
            $match = [regex]::Match(($npmListOutput -join "`n"), '@bankofai/agent-wallet@([^\s]+)')
            if ($match.Success) {
                $currentVersion = $match.Groups[1].Value
            }
        }
    }
    catch {}

    if ($currentVersion -ne $script:AgentWalletVersion) {
        throw "Expected AgentWallet $($script:AgentWalletVersion), but got '$currentVersion'."
    }
}

function Invoke-AgentWallet {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    & agent-wallet.cmd @Arguments 2>&1
}

function Initialize-AgentWallet {
    Write-Host ""
    Write-Host "${script:BOLD}Step 0: AgentWallet Setup${script:NC}"
    Write-Host ""

    Install-AgentWalletCli

    if ($script:CleanInstall) {
        Write-Host "${script:INFO}Launching: agent-wallet reset${script:NC}"
        Invoke-AgentWallet reset
        # reset failure is non-fatal
        Write-Host ""
        Write-Host "${script:INFO}Launching: agent-wallet start --override --save-runtime-secrets${script:NC}"
        Write-Host "${script:MUTED}Please complete initialization in the CLI prompts.${script:NC}"
        Write-Host ""
        Invoke-AgentWallet start --override --save-runtime-secrets
        if ($LASTEXITCODE -ne 0) {
            throw "AgentWallet initialization failed in CLEAN mode."
        }
    }
    else {
        Write-Host "${script:INFO}Launching: agent-wallet start --save-runtime-secrets${script:NC}"
        Write-Host "${script:MUTED}Please complete initialization in the CLI prompts.${script:NC}"
        Write-Host ""
        Invoke-AgentWallet start --save-runtime-secrets
        if ($LASTEXITCODE -ne 0) {
            throw "AgentWallet initialization failed."
        }
    }

    Write-Host ""
    Write-Host "${script:SUCCESS}$([char]0x2713) AgentWallet setup completed${script:NC}"
    Write-Host ""
}

# --- Skill Configuration Functions ---

function Set-BankOfAiApiKeyConfig {
    Write-Host ""
    Write-Host "${script:BOLD}recharge-skill API Key Configuration${script:NC}"
    Write-Host "${script:MUTED}recharge-skill uses your local BANK OF AI API key for balance and order queries.${script:NC}"
    Write-Host "${script:MUTED}Recharge requests use the remote BANK OF AI recharge MCP endpoint.${script:NC}"
    Write-Host ""

    $bankofaiConfig = Join-Path $env:USERPROFILE ".mcporter\bankofai-config.json"
    $hasKey = ""

    if (Test-Path $bankofaiConfig) {
        $hasKey = Read-NodeJson -FilePath $bankofaiConfig -Key "api_key"
    }

    if ($hasKey) {
        Write-Host "${script:SUCCESS}$([char]0x2713) BANK OF AI API key already configured${script:NC}"
        Write-Host "${script:MUTED}  Config: $bankofaiConfig${script:NC}"
        Write-Host ""
        Write-Host "${script:INFO}?${script:NC} Reconfigure BANK OF AI API key? ${script:MUTED}(y/N)${script:NC}: " -NoNewline
        $reconfigBankofai = Read-Host
        if ($reconfigBankofai -notmatch '^[Yy]$') {
            Write-Host ""
            return
        }
    }

    Write-Host "${script:INFO}?${script:NC} Enter BANKOFAI_API_KEY ${script:MUTED}(optional, hidden)${script:NC}: " -NoNewline
    $secureKey = Read-Host -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        $bankofaiApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    if ($bankofaiApiKey) {
        $env:BANKOFAI_API_KEY = $bankofaiApiKey
        $jsonContent = node -e 'const k = process.env.BANKOFAI_API_KEY; console.log(JSON.stringify({ api_key: k, base_url: "https://chat.ainft.com" }));'
        Remove-Item Env:\BANKOFAI_API_KEY -ErrorAction SilentlyContinue
        Write-NodeJson -FilePath $bankofaiConfig -JsonContent $jsonContent
        Set-FileOwnerOnly -FilePath $bankofaiConfig
        Write-Host "${script:SUCCESS}$([char]0x2713) BANK OF AI config saved to $bankofaiConfig${script:NC}"
        Write-Host "${script:MUTED}  File permissions: owner read/write only${script:NC}"
    }
    else {
        Write-Host "${script:WARN}No BANK OF AI API key entered, skipping local BANK OF AI configuration${script:NC}"
        Write-Host "${script:INFO}Configure later by creating ${bankofaiConfig}:${script:NC}"
        Write-Host "${script:MUTED}  {`"api_key`": `"YOUR_BANKOFAI_API_KEY`"}${script:NC}"
    }

    Write-Host ""
}

function Set-TronscanApiKeyConfig {
    Write-Host ""
    Write-Host "${script:BOLD}TronScan API Key Configuration${script:NC}"
    Write-Host "${script:MUTED}tronscan-skill requires TRONSCAN_API_KEY in the shell environment.${script:NC}"
    Write-Host ""

    if ($env:TRONSCAN_API_KEY) {
        Write-Host "${script:SUCCESS}$([char]0x2713) TRONSCAN_API_KEY already set in environment${script:NC}"
        Write-Host ""
        return
    }

    Write-Host "${script:INFO}Add this to your PowerShell profile ($PROFILE):${script:NC}"
    Write-Host "${script:MUTED}`$env:TRONSCAN_API_KEY = `"your-api-key-here`"${script:NC}"
    Write-Host "${script:MUTED}Get a free key at: https://tronscan.org/#/myaccount/apiKeys${script:NC}"
    Write-Host ""
}

function Set-X402GasfreeConfig {
    Write-Host ""
    Write-Host "${script:BOLD}Gasfree API Configuration${script:NC}"
    Write-Host "${script:MUTED}x402-payment uses Gasfree API for gasless transactions on TRON${script:NC}"
    Write-Host ""

    $x402Config = Join-Path $env:USERPROFILE ".x402-config.json"
    $hasKeys = ""
    $reconfigGasfree = "N"

    if (Test-Path $x402Config) {
        $gasfreeKey = Read-NodeJson -FilePath $x402Config -Key "gasfree_api_key"
        $gasfreeSecret = Read-NodeJson -FilePath $x402Config -Key "gasfree_api_secret"

        if ($gasfreeKey -and $gasfreeSecret) {
            $hasKeys = "yes"
            Write-Host "${script:SUCCESS}$([char]0x2713) Gasfree API credentials already configured${script:NC}"
            Write-Host "${script:MUTED}  Config: $x402Config${script:NC}"
            Write-Host ""
            Write-Host "${script:INFO}?${script:NC} Reconfigure Gasfree API credentials? ${script:MUTED}(y/N)${script:NC}: " -NoNewline
            $reconfigGasfree = Read-Host
            if ($reconfigGasfree -notmatch '^[Yy]$') {
                Write-Host ""
                return
            }
        }
    }

    if ((-not (Test-Path $x402Config)) -or ($hasKeys -ne "yes") -or ($reconfigGasfree -match '^[Yy]$')) {
        Write-Host "${script:INFO}?${script:NC} Enter GASFREE_API_KEY ${script:MUTED}(optional)${script:NC}: " -NoNewline
        $gasfreeApiKey = Read-Host

        Write-Host "${script:INFO}?${script:NC} Enter GASFREE_API_SECRET ${script:MUTED}(optional, hidden)${script:NC}: " -NoNewline
        $secureSecret = Read-Host -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
        try {
            $gasfreeApiSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }

        if ($gasfreeApiKey -and $gasfreeApiSecret) {
            $env:GASFREE_KEY = $gasfreeApiKey
            $env:GASFREE_SECRET = $gasfreeApiSecret
            $jsonContent = node -e 'console.log(JSON.stringify({ gasfree_api_key: process.env.GASFREE_KEY, gasfree_api_secret: process.env.GASFREE_SECRET }));'
            Remove-Item Env:\GASFREE_KEY -ErrorAction SilentlyContinue
            Remove-Item Env:\GASFREE_SECRET -ErrorAction SilentlyContinue
            Write-NodeJson -FilePath $x402Config -JsonContent $jsonContent
            Set-FileOwnerOnly -FilePath $x402Config
            Write-Host "${script:SUCCESS}$([char]0x2713) Gasfree API credentials saved to $x402Config${script:NC}"
            Write-Host "${script:MUTED}  File permissions: owner read/write only${script:NC}"
        }
        else {
            Write-Host "${script:WARN}Incomplete credentials, skipping Gasfree configuration${script:NC}"
            Write-Host "${script:INFO}Configure later by creating ${x402Config}:${script:NC}"
            Write-Host "${script:MUTED}  {`"gasfree_api_key`": `"YOUR_KEY`", `"gasfree_api_secret`": `"YOUR_SECRET`"}${script:NC}"
        }
    }

    Write-Host ""
}

function Set-SkillConfig {
    param(
        [string]$SkillId
    )
    switch ($SkillId) {
        "sunperp" {
            Write-Host ""
            Write-Host "${script:WARN}sunperp depends on TRON_PRIVATE_KEY.${script:NC}"
            Write-Host "${script:MUTED}Please ensure TRON_PRIVATE_KEY is configured before using sunperp.${script:NC}"
            Write-Host ""
        }
        "x402-payment" {
            Set-X402GasfreeConfig
        }
        "recharge-skill" {
            Set-BankOfAiApiKeyConfig
        }
        "tronscan-skill" {
            Set-TronscanApiKeyConfig
        }
    }
}

# =============================================================================
# MAIN SCRIPT BODY
# =============================================================================

try {
    $tagline = Get-Tagline

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    Write-Host "${script:ACCENT}${script:BOLD}"
    $crab = [char]::ConvertFromUtf32(0x1F99E)
    Write-Host "  $crab OpenClaw Extension Installer (by BANK OF AI)"
    Write-Host "${script:NC}${script:ACCENT_DIM}  $tagline${script:NC}"
    Write-Host ""

    Test-Environment

    # Ensure config directory exists
    if (-not (Test-Path $script:McpConfigDir)) {
        New-Item -ItemType Directory -Path $script:McpConfigDir -Force | Out-Null
    }

    # Choose installation mode (Normal / Clean)
    Select-InstallMode

    # Step 0: AgentWallet setup
    Initialize-AgentWallet

    # --- Step 1: MCP Server Configuration ---

    Write-Host ""
    Write-Host "${script:BOLD}Step 1: MCP Server Configuration${script:NC}"
    Write-Host ""

    $serverOptions = @(
        "mcp-server-tron||Interact with TRON blockchain (wallets, transactions, smart contracts)."
        "bnbchain-mcp||BNB Chain official MCP (BSC, opBNB, Ethereum, Greenfield)."
        "bankofai-recharge||BANK OF AI recharge MCP (remote recharge tools)."
    )
    $serverIds = @(
        "mcp-server-tron"
        "bnbchain-mcp"
        "bankofai-recharge"
    )

    $selectedIndices = Show-MultiSelect -Prompt "Select MCP Servers to install:" -Options $serverOptions

    if (-not $selectedIndices -or $selectedIndices.Count -eq 0) {
        Write-Host "${script:WARN}No MCP servers selected.${script:NC}"
        $script:SkipMcp = $true
    }
    else {
        $script:SkipMcp = $false

        foreach ($idx in $selectedIndices) {
            $serverId = $serverIds[$idx]

            Write-Host ""
            Write-Host "${script:BOLD}Configuring $serverId...${script:NC}"

            switch ($serverId) {
                "mcp-server-tron" {
                    Write-Host "${script:INFO}This step configures network access for TRON MCP.${script:NC}"
                    $tronApiKey = Read-UserInput -Prompt "Enter TRONGRID_API_KEY" -IsSecret $true -Description "Optional but recommended for reliable network access."
                    Write-Host "${script:MUTED}Adding MCP server...${script:NC}"

                    try {
                        npx.cmd -y add-mcp -a mcporter -n mcp-server-tron -g -y "@bankofai/mcp-server-tron@1.1.7" 2>&1
                    }
                    catch {
                        Write-Host "${script:ERROR_CLR}$([char]0x2717) Failed to add mcp-server-tron via npx add-mcp${script:NC}"
                        continue
                    }

                    if ($tronApiKey) {
                        $env:TRON_KEY = $tronApiKey
                        $envJson = node -e 'console.log(JSON.stringify({ TRONGRID_API_KEY: process.env.TRON_KEY }))'
                        Remove-Item Env:\TRON_KEY -ErrorAction SilentlyContinue
                        Merge-NodeJson -ServerId "mcp-server-tron" -EnvJson $envJson -ConfigFile $script:McpConfigFile
                    }
                }
                "bnbchain-mcp" {
                    Write-Host "${script:WARN}bnbchain-mcp currently does not support AgentWallet.${script:NC}"
                    Write-Host "${script:WARN}This server still uses PRIVATE_KEY configuration.${script:NC}"
                    Write-Host ""
                    Write-Host "${script:WARN}$([char]0x26A0) Your PRIVATE_KEY will be stored in plaintext in: ${script:INFO}$($script:McpConfigFile)${script:NC}"
                    Write-Host "${script:WARN}  File permissions are set to owner-only, but take care with backups.${script:NC}"
                    Write-Host ""

                    $bnbKey = Read-UserInput -Prompt "Enter BNB Chain PRIVATE_KEY" -IsSecret $true -Description "Your BNB Chain wallet private key (with or without 0x prefix). Required for signing transactions."
                    $bnbLogLevel = Read-UserInput -Prompt "Enter LOG_LEVEL" -IsSecret $false -Description "Log level: DEBUG, INFO, WARN, ERROR (default: INFO)"

                    Write-Host "${script:MUTED}Adding MCP server...${script:NC}"

                    try {
                        npx.cmd -y add-mcp -a mcporter -n bnbchain-mcp -g -y "@bnb-chain/mcp@latest" 2>&1
                    }
                    catch {
                        Write-Host "${script:ERROR_CLR}$([char]0x2717) Failed to add bnbchain-mcp via npx add-mcp${script:NC}"
                        continue
                    }

                    # Ensure private key has 0x prefix
                    if ($bnbKey -and $bnbKey -notmatch '^0x') {
                        $bnbKey = "0x$bnbKey"
                        Write-Host "${script:INFO}Added 0x prefix to private key${script:NC}"
                    }

                    if ($bnbKey -or $bnbLogLevel) {
                        if (-not $bnbLogLevel) { $bnbLogLevel = "INFO" }
                        $env:BNB_PRIVATE_KEY = if ($bnbKey) { $bnbKey } else { "" }
                        $env:BNB_LOG = $bnbLogLevel
                        $envJson = node -e @'
const d = {};
if (process.env.BNB_PRIVATE_KEY) d.PRIVATE_KEY = process.env.BNB_PRIVATE_KEY;
d.LOG_LEVEL = process.env.BNB_LOG;
console.log(JSON.stringify(d));
'@
                        Remove-Item Env:\BNB_PRIVATE_KEY -ErrorAction SilentlyContinue
                        Remove-Item Env:\BNB_LOG -ErrorAction SilentlyContinue
                        Merge-NodeJson -ServerId "bnbchain-mcp" -EnvJson $envJson -ConfigFile $script:McpConfigFile
                    }
                }
                "bankofai-recharge" {
                    try {
                        npx.cmd -y add-mcp -a mcporter -n bankofai-recharge -g -t http -y "https://recharge.bankofai.io/mcp" 2>&1
                    }
                    catch {
                        Write-Host "${script:ERROR_CLR}$([char]0x2717) Failed to add bankofai-recharge via npx add-mcp${script:NC}"
                        continue
                    }
                }
            }

            Write-Host "${script:SUCCESS}$([char]0x2713) Configuration saved for $serverId.${script:NC}"
        }

        # Secure mcporter.json
        Set-FileOwnerOnly -FilePath $script:McpConfigFile
    }

    # --- Step 2: Skills Installation ---

    Write-Host ""
    Write-Host "${script:BOLD}Step 2: Skills Installation${script:NC}"
    Write-Host ""

    # Select install scope
    Write-Host "${script:BOLD}Select skills installation scope:${script:NC}"
    Write-Host "  ${script:INFO}1)${script:NC} User-level (global) ${script:SUCCESS}[Recommended]${script:NC}"
    Write-Host "     ${script:MUTED}Available to all OpenClaw workspaces${script:NC}"
    Write-Host "  ${script:INFO}2)${script:NC} Workspace-level (project)"
    Write-Host "     ${script:MUTED}Only available in current workspace${script:NC}"
    Write-Host ""
    Write-Host "${script:INFO}?${script:NC} Enter choice ${script:MUTED}(1-2, default: 1)${script:NC}: " -NoNewline

    $scopeChoice = Read-Host
    if (-not $scopeChoice) { $scopeChoice = "1" }

    if ($scopeChoice -eq "1") {
        $script:SkillsGlobalFlag = "-g"
        Write-Host "${script:MUTED}-> Installing globally (user-level)${script:NC}"
    }
    else {
        $script:SkillsGlobalFlag = ""
        Write-Host "${script:MUTED}-> Installing to workspace${script:NC}"
    }
    Write-Host ""

    # Snapshot installed skills before
    $beforeSkills = "[]"
    try {
        $beforeOutput = npx.cmd -y "skills@1.4.6" list $script:SkillsGlobalFlag -a openclaw --json 2>$null
        if ($beforeOutput) { $beforeSkills = $beforeOutput -join "" }
    }
    catch {}

    # Run interactive skills add
    Write-Host "${script:INFO}Select skills to install in the interactive prompt below:${script:NC}"
    Write-Host ""

    $skillsArgs = @("-y", "skills@1.4.6", "add", $script:SkillsRepo, "-a", "openclaw")
    if ($script:SkillsGlobalFlag) { $skillsArgs += $script:SkillsGlobalFlag }
    try { & npx.cmd @skillsArgs 2>&1 } catch {}
    Write-Host ""

    # Snapshot after and find newly installed skills
    $afterSkills = "[]"
    try {
        $afterOutput = npx.cmd -y "skills@1.4.6" list $script:SkillsGlobalFlag -a openclaw --json 2>$null
        if ($afterOutput) { $afterSkills = $afterOutput -join "" }
    }
    catch {}

    $env:BEFORE = $beforeSkills
    $env:AFTER = $afterSkills
    $installedRaw = node -e @'
const before = new Set(JSON.parse(process.env.BEFORE).map(s => s.name || s.skill || s));
const after = JSON.parse(process.env.AFTER).map(s => s.name || s.skill || s);
after.filter(s => !before.has(s)).forEach(s => console.log(s));
'@
    Remove-Item Env:\BEFORE -ErrorAction SilentlyContinue
    Remove-Item Env:\AFTER -ErrorAction SilentlyContinue

    $script:InstalledSkills = @()
    if ($installedRaw) {
        $script:InstalledSkills = @($installedRaw -split "`n" | Where-Object { $_.Trim() })
    }

    if ($script:InstalledSkills.Count -gt 0) {
        Write-Host "${script:SUCCESS}$([char]0x2713) Installed $($script:InstalledSkills.Count) skill(s)${script:NC}"
        Write-Host ""

        # Run post-install configuration for each new skill
        foreach ($skillId in $script:InstalledSkills) {
            Set-SkillConfig -SkillId $skillId
        }
    }
    else {
        Write-Host "${script:MUTED}No new skills were installed.${script:NC}"
    }

    # --- Final Summary ---
    Write-Host ""
    $border = [string]([char]0x2550) * 39
    Write-Host "${script:ACCENT}${script:BOLD}$border${script:NC}"
    Write-Host "${script:ACCENT}${script:BOLD}  Installation Complete!${script:NC}"
    Write-Host "${script:ACCENT}${script:BOLD}$border${script:NC}"
    Write-Host ""

    if (-not $script:SkipMcp) {
        Write-Host "${script:SUCCESS}$([char]0x2713)${script:NC} ${script:BOLD}MCP Server configured${script:NC}"
        Write-Host "  ${script:INFO}Config file: ${script:BOLD}$($script:McpConfigFile)${script:NC}"
        Write-Host "  ${script:MUTED}  File permissions: owner read/write only${script:NC}"
        Write-Host ""
    }

    if ($script:InstalledSkills.Count -gt 0) {
        Write-Host "${script:SUCCESS}$([char]0x2713)${script:NC} ${script:BOLD}Installed skills:${script:NC}"
        foreach ($skill in $script:InstalledSkills) {
            Write-Host "  ${script:SUCCESS}$([char]0x2022)${script:NC} ${script:INFO}$skill${script:NC}"
        }
        $verifyCmd = "npx skills list $($script:SkillsGlobalFlag)".Trim()
        Write-Host "  ${script:MUTED}Verify with: ${script:INFO}$verifyCmd${script:NC}"
        Write-Host ""
    }

    if ($script:InstalledSkills.Count -gt 0) {
        Write-Host "${script:BOLD}Next steps:${script:NC}"
        Write-Host ""
        Write-Host "  ${script:INFO}1.${script:NC} ${script:BOLD}Restart OpenClaw and start a new session${script:NC} to load new skills"
        Write-Host ""
        Write-Host "  ${script:INFO}2.${script:NC} ${script:BOLD}Test the skills:${script:NC}"

        foreach ($skill in $script:InstalledSkills) {
            switch ($skill) {
                "sunswap" {
                    Write-Host "     ${script:MUTED}`"Read the sunswap skill and help me swap 100 USDT to TRX`"${script:NC}"
                }
                "recharge-skill" {
                    Write-Host "     ${script:MUTED}`"Read the recharge-skill and recharge my BANK OF AI account with 1 USDT`"${script:NC}"
                }
                "tronscan-skill" {
                    Write-Host "     ${script:MUTED}`"Read the tronscan-skill and look up the latest TRON block`"${script:NC}"
                }
                "x402-payment" {
                    Write-Host "     ${script:MUTED}`"Read the x402-payment skill and explain how it works`"${script:NC}"
                }
            }
        }
        Write-Host ""
    }

    Write-Host "${script:MUTED}Repository: https://github.com/BofAI/openclaw-extension${script:NC}"
    Write-Host "${script:MUTED}Skills: https://github.com/BofAI/skills${script:NC}"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "${script:ERROR_CLR}${script:BOLD}Installation failed with error:${script:NC}" -ErrorAction SilentlyContinue
    Write-Host "${script:ERROR_CLR}$($_.Exception.Message)${script:NC}" -ErrorAction SilentlyContinue
    Write-Host "${script:MUTED}$($_.ScriptStackTrace)${script:NC}" -ErrorAction SilentlyContinue
    Write-Host ""
}
finally {
    # Cleanup: restore cursor visibility
    try { [Console]::CursorVisible = $true } catch {}
    # Pause so the user can read output when launched via .bat or double-click
    Write-Host ""
    Write-Host "Press any key to exit..." -NoNewline
    try { $null = [Console]::ReadKey($true) } catch { Read-Host }
}
