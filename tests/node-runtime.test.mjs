import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { after, test } from 'node:test';

// Load only the real runtime guards and their callers; never run installer setup.
const bash = readFileSync(new URL('../install.sh', import.meta.url), 'utf8');
const powershell = readFileSync(new URL('../install.ps1', import.meta.url), 'utf8');
const temp = mkdtempSync(join(tmpdir(), 'openclaw-runtime-'));
const preload = join(temp, 'version.cjs');
writeFileSync(preload, 'Object.defineProperty(process.versions, "node", {value: process.env.TEST_NODE_VERSION});');
after(() => rmSync(temp, { recursive: true, force: true }));

function extract(source, pattern) {
    const match = source.match(pattern);
    assert.ok(match, `Missing installer section: ${pattern}`);
    return match[0];
}

const bashSetup = [
    extract(bash, /^NODE_RUNTIME_RANGE=.*$/m),
    extract(bash, /^X402_CLI_VERSION=.*$/m),
    ...['check_node_runtime', 'check_env', 'ensure_x402_cli'].map(name =>
        extract(bash, new RegExp(`^${name}\\(\\) \\{[\\s\\S]*?^\\}`, 'm'))),
    'npm() { echo "Unexpected npm mutation" >&2; return 99; }',
    'x402-cli() { echo "$X402_CLI_VERSION"; }',
].join('\n');

const psSetup = [
    "$ErrorActionPreference = 'Stop'",
    // Exercise Windows PowerShell 5.1-style native argument quoting on PowerShell 7 too.
    "$PSNativeCommandArgumentPassing = 'Legacy'",
    extract(powershell, /^\$script:NodeRuntimeRange =.*$/m),
    extract(powershell, /^\$script:X402CliVersion =.*$/m),
    ...['Assert-NodeRuntime', 'Test-Environment', 'Install-X402Cli'].map(name =>
        extract(powershell, new RegExp(`^function ${name} \\{[\\s\\S]*?^\\}`, 'm'))),
    'function npm.cmd { throw "Unexpected npm mutation" }',
    'function x402-cli.cmd { $script:X402CliVersion }',
].join('\n');

const cases = [
    ['18.20.8', false], ['20.20.0', false], ['22.23.0', false], ['22.23.3', false],
    ['22.23.4', true], ['22.23.5', true], ['22.24.0', true], ['23.11.0', false],
    ['24.22.0', false], ['24.22.1', true], ['24.23.0', true], ['25.9.0', false],
    ['26.12.0', false], ['26.12.1', true], ['26.13.0', true], ['27.0.0', true],
    ['28.0.0', true], ['26.12.1-rc.1', false], ['27.0.0-rc.1', false], ['invalid', false],
];
const pwsh = process.env.PWSH || 'pwsh';
const hasPowerShell = spawnSync(pwsh, ['-NoProfile', '-Command', 'exit 0']).status === 0;

for (const [version, supported] of cases) {
    for (const platform of ['Bash', 'PowerShell']) {
        test(`${platform}: ${version}`, { skip: platform === 'PowerShell' && !hasPowerShell }, () => {
            const env = {
                ...process.env,
                TEST_NODE_VERSION: version,
                NODE_OPTIONS: `${process.env.NODE_OPTIONS || ''} --require ${JSON.stringify(preload)}`,
            };
            const commands = platform === 'Bash'
                ? ['check_node_runtime', 'ensure_x402_cli', ...(!supported ? ['check_env'] : [])]
                : ['Assert-NodeRuntime', 'Install-X402Cli', ...(!supported ? ['Test-Environment'] : [])];
            for (const command of commands) {
                const result = platform === 'Bash'
                    ? spawnSync('bash', ['-c', `${bashSetup}\n${command}`], { env, encoding: 'utf8' })
                    : spawnSync(pwsh, ['-NoProfile', '-Command', `${psSetup}\ntry { ${command}; exit 0 } catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }`], { env, encoding: 'utf8' });
                assert.ifError(result.error);
                assert.equal(result.status, supported ? 0 : 1, `${command}: ${result.stdout}\n${result.stderr}`);
                if (!supported) assert.match(result.stderr, /Node\.js \^22\.23\.4/);
                assert.doesNotMatch(result.stderr, /Unexpected npm mutation/);
            }
        });
    }
}

test('PowerShell installer parses without executing setup', { skip: !hasPowerShell }, () => {
    const result = spawnSync(pwsh, ['-NoProfile', '-Command',
        '$errors = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($env:TEST_PS_INSTALLER, [ref]$null, [ref]$errors); if ($errors.Count) { $errors | Out-String | Write-Error; exit 1 }',
    ], { env: { ...process.env, TEST_PS_INSTALLER: new URL('../install.ps1', import.meta.url).pathname }, encoding: 'utf8' });
    assert.ifError(result.error);
    assert.equal(result.status, 0, result.stderr);
});
