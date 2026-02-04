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
npx vibecodekit

# Install all skills to .claude
npx vibecodekit --claude

# Install all skills to .cursor
npx vibecodekit --cursor

# Install all skills to .agent (Antigravity)
npx vibecodekit --agent

# List available skills
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
| **vibe-builder** | Solo Builder agent — builds complete applications from scratch using 6-phase Agentic Coding workflow with deep research, PRD creation, autonomous coding, testing, and human-in-the-loop checkpoints. |
| **vibe-debugger** | Structured debugging workflow — researches bugs, writes a BUG_REPORT.md with root cause analysis and proposed fixes, asks for human review, implements the fix, and verifies it. |

### Vibe Builder Features

The `vibe-builder` skill is a comprehensive Solo Builder agent that:

**6-Phase Workflow:**
1. **Research & Product Spec** — Deep web research (5-8 searches), creates PRD.md with wireframes, flowcharts, ER diagrams
2. **Planning & Review** — Human reviews PRD, agent updates CLAUDE.md/GEMINI.md with project summary
3. **Agentic Coding** — Fully autonomous coding with context sync every 3-5 tasks
4. **Testing Setup** — Creates TEST_PLAN.md, stops for human review
5. **Testing Execution** — Autonomous test execution with auto-fix loop
6. **Fine-tune & Loop** — Iterative refinement based on human feedback

**Key Features:**
- **Context Recovery** — Hooks for Claude Code to recover workflow after context compaction
- **Docker-First** — Prioritizes Docker images for infrastructure (postgres, redis, supabase, etc.)
- **Typed Languages** — Enforces TypeScript, Rust, or Python with type hints
- **Human Checkpoints** — Mandatory stops at Phase 1, 2, and 4 for human approval
- **Self-Setup** — Agent sets up everything (Docker, dependencies, configs) autonomously

**Usage:**
```
/vibe-builder <describe the app you want to build>
```

## How It Works

The installer downloads the latest kit from GitHub and copies the selected skills/agents into your project's `.claude/` and `.agent/` directories. It only warns about individual files that would be overwritten — it won't touch your existing config.

## Contributing

To add a new skill or agent:

1. **Claude Code skill** — Create a new directory under `.claude/skills/<skill-name>/` with a `SKILL.md` file. Use the [Claude Code skill format](https://docs.anthropic.com/en/docs/claude-code).

2. **Antigravity agent** — Create a new directory or file under `.agent/`.

3. Submit a pull request.

## License

MIT
