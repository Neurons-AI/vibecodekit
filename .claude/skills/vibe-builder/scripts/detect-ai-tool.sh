#!/bin/bash
# Detect which AI coding tool is currently running
# Returns: CLAUDE, GEMINI, or UNKNOWN

# Check for Claude Code
if [ "$CLAUDECODE" = "1" ] || [ -n "$CLAUDE_CODE_ENTRYPOINT" ]; then
    echo "CLAUDE"
    exit 0
fi

# Check for Antigravity (Gemini)
if [ "$__CFBundleIdentifier" = "com.google.antigravity" ]; then
    echo "GEMINI"
    exit 0
fi

if [[ "$PATH" == *".antigravity"* ]]; then
    echo "GEMINI"
    exit 0
fi

# Fallback: check for config directories in current project
if [ -d ".claude" ]; then
    echo "CLAUDE"
    exit 0
fi

if [ -d ".agent" ]; then
    echo "GEMINI"
    exit 0
fi

# Unknown
echo "UNKNOWN"
exit 0
