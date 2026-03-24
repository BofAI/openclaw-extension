<!--
  Sync Impact Report
  ==================
  Version change: N/A → 1.0.0 (initial ratification)
  Added principles:
    - I. Single-Script Architecture
    - II. Pipe-Install Compatibility
    - III. Ecosystem-Standard Tooling
    - IV. No Python Dependency
    - V. Pinned Dependencies
    - VI. Credential Security
  Added sections:
    - Technology Constraints
    - Quality Gates
    - Governance
  Templates requiring updates:
    - .specify/templates/plan-template.md — ✅ no changes needed (generic gates)
    - .specify/templates/spec-template.md — ✅ no changes needed (generic structure)
    - .specify/templates/tasks-template.md — ✅ no changes needed (generic structure)
  Follow-up TODOs: none
-->

# OpenClaw Extension Constitution

## Core Principles

### I. Single-Script Architecture

All installer logic MUST reside in `install.sh`. There MUST NOT be
auxiliary scripts, modules, or helper files in the repository that are
invoked at runtime. This keeps the `curl | bash` delivery model simple
and auditable — users can read one file to understand everything the
installer does.

### II. Pipe-Install Compatibility (NON-NEGOTIABLE)

The installer MUST function correctly when executed via
`curl -fsSL <url> | bash`. All interactive prompts MUST read from
`/dev/tty`, never from stdin. All `npx` commands that require user
input MUST also be wired to `/dev/tty`. Every change MUST be validated
with `cat install.sh | bash` before merge.

**Rationale**: This is the primary distribution channel. Breaking pipe
mode silently degrades the experience for the majority of users.

### III. Ecosystem-Standard Tooling

MCP server registration MUST use `npx add-mcp` (the standard Neon
add-mcp package). Skill installation MUST use `npx skills add` (the
standard Vercel Labs skills package). Custom reimplementations of
functionality provided by these tools MUST NOT be introduced unless the
upstream tool has a confirmed, blocking deficiency with no workaround.

**Rationale**: Aligning with ecosystem tools reduces maintenance burden
and keeps the installer compatible with upstream improvements.

### IV. No Python Dependency

The installer MUST NOT depend on Python for any operation. All JSON
manipulation MUST use `node -e` one-liners or equivalent Node.js
invocations. Node.js is already a hard prerequisite (v18+), so no
additional runtime is introduced.

**Rationale**: Eliminating Python removes a prerequisite that users
frequently lack or have misconfigured, reducing installation failures.

### V. Pinned Dependencies

Every external package invoked via `npx` MUST specify an explicit
version or tag. Floating references like `@latest` MUST be used only
when the upstream maintainer (e.g., BNB Chain) does not publish stable
semver tags. The pinned versions table in `CLAUDE.md` MUST be updated
whenever a version changes.

**Rationale**: Reproducible installs prevent silent breakage when
upstream publishes breaking changes.

### VI. Credential Security

Configuration files containing secrets (API keys, private keys,
credentials) MUST be written with `chmod 600` permissions. The
installer MUST NOT echo, log, or store secrets in shell history. Secret
values MUST be passed to `node -e` via environment variables, never as
inline arguments visible in `ps` output.

**Rationale**: The installer handles blockchain private keys and API
credentials. Leaking these has direct financial consequences.

## Technology Constraints

- **Runtime**: Bash (POSIX-compatible with bashisms) on Linux and macOS.
- **Required prerequisites**: Node.js v18+, Git, OpenClaw (pre-installed).
- **JSON operations**: `node -e` one-liners only. No jq, no Python, no
  external JSON tools.
- **Package execution**: `npx -y` with the `-y` flag to skip download
  confirmation in non-interactive contexts.
- **Interactive I/O**: All user prompts MUST read from `/dev/tty`.
  Standard input is reserved for pipe delivery.
- **Config file format**: JSON files in `~/.mcporter/` and `~/`. No
  YAML, TOML, or INI.

## Quality Gates

Every pull request that modifies `install.sh` MUST pass these gates
before merge:

1. **Syntax validation**: `bash -n install.sh` MUST exit 0.
2. **Lint check**: `shellcheck install.sh` MUST produce no errors.
   Warnings MAY be suppressed with inline directives if justified.
3. **Direct execution test**: `./install.sh` MUST complete a full
   install flow (MCP servers + skills + configuration prompts).
4. **Pipe execution test**: `cat install.sh | bash` MUST complete the
   same flow without hanging or reading from stdin.

## Governance

This constitution is the authoritative source of non-negotiable project
constraints. All specification, planning, and implementation work MUST
comply with these principles.

**Amendment procedure**:

1. Propose the change with rationale in a PR description.
2. Update this file with the new or modified principle.
3. Increment the version per semantic versioning:
   - MAJOR: Principle removed or fundamentally redefined.
   - MINOR: New principle added or existing principle materially expanded.
   - PATCH: Wording clarification or typo fix.
4. Update `LAST_AMENDED_DATE` to the amendment date.
5. Verify no dependent templates or docs conflict with the change.

**Compliance review**: The plan template's "Constitution Check" section
MUST reference these principles. Any violation MUST be justified in the
plan's Complexity Tracking table before implementation proceeds.

**Version**: 1.0.0 | **Ratified**: 2026-03-24 | **Last Amended**: 2026-03-24
