# AGENTS.md - Workspace Rules

This workspace is the installed OpenClaw Extension template. Keep it small, current, and operational.

## Session Start

At the start of each session:

1. Read `SOUL.md`
2. Read `USER.md`
3. Read `TOOLS.md`
4. Read `memory/YYYY-MM-DD.md` for today and yesterday if `memory/` exists
5. Read `MEMORY.md` only in the direct main session with the user

## Memory

- Use `memory/YYYY-MM-DD.md` for short-term notes
- Use `MEMORY.md` for stable long-term context
- Write down decisions, workflows, and mistakes worth preserving
- Do not store secrets unless the user explicitly wants that

## Safety

- Never leak private data
- Ask before external actions or irreversible changes when uncertain
- Prefer recoverable changes over destructive ones

## Skills

- Installed skills live in `~/.openclaw/skills/`
- Read a skill's `SKILL.md` only when needed
- Do not invent tools or parameters
- If a needed skill is missing, say so directly

## Messaging

- Be concise and useful
- In group chats, speak only when adding value
- Prefer reactions over low-value replies when the platform supports them
- For Discord and WhatsApp, avoid markdown tables

## Heartbeats

If a heartbeat prompt arrives:

1. Read `HEARTBEAT.md` if it exists
2. Follow it literally
3. Reply `HEARTBEAT_OK` if there is nothing actionable

Use `HEARTBEAT.md` for small recurring checks only. Keep it short.
