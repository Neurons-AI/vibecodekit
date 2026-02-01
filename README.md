# Vibe Code Kit

Prebuilt skills and agents for **Vibe Coding** — ready to install into any project.

Supports:
- **Claude Code** skills (`.claude/skills/`)
- **Antigravity** agents (`.agent/`)

## Quick Install

```bash
# Install everything
curl -fsSL https://raw.githubusercontent.com/Neurons-AI/vibecodekit/main/install.sh | bash -s -- --all

# Or via npx
npx vibecodekit --all
```

## Usage

```bash
# Interactive mode — choose what to install
curl -fsSL https://raw.githubusercontent.com/Neurons-AI/vibecodekit/main/install.sh | bash

# Install only Claude Code skills
npx vibecodekit --claude

# Install only Antigravity agents
npx vibecodekit --agent

# List available skills and agents
npx vibecodekit --list

# Pick individual skills to install
npx vibecodekit --pick

# Force overwrite existing files
npx vibecodekit --all --force
```

## Included Skills

### Claude Code & Antigravity Skills

| Skill | Description |
|-------|-------------|
| **vibe-debugger** | Structured debugging workflow — researches bugs, writes a BUG_REPORT.md with root cause analysis and proposed fixes, asks for human review, implements the fix, and verifies it. |

## How It Works

The installer downloads the latest kit from GitHub and copies the selected skills/agents into your project's `.claude/` and `.agent/` directories. It only warns about individual files that would be overwritten — it won't touch your existing config.

## Contributing

To add a new skill or agent:

1. **Claude Code skill** — Create a new directory under `.claude/skills/<skill-name>/` with a `SKILL.md` file. Use the [Claude Code skill format](https://docs.anthropic.com/en/docs/claude-code).

2. **Antigravity agent** — Create a new directory or file under `.agent/`.

3. Submit a pull request.

## License

MIT
