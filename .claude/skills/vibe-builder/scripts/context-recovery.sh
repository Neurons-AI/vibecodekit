#!/bin/bash
# Context Recovery Script for Vibe Builder
# This script is triggered after context compaction to remind agent of workflow

# Check if we're in a Vibe Builder project (has PRD.md or IMPLEMENTATION_PLAN.md)
if [ ! -f "PRD.md" ] && [ ! -f "IMPLEMENTATION_PLAN.md" ]; then
    exit 0  # Not a Vibe Builder project, skip
fi

echo "=== VIBE BUILDER CONTEXT RECOVERY ==="
echo ""
echo "Context was compacted. Re-reading critical files to stay on track."
echo ""

# Remind about workflow checkpoints
echo "### WORKFLOW CHECKPOINTS (MANDATORY - DO NOT SKIP!)"
echo "| After Phase | Action |"
echo "| --- | --- |"
echo "| Phase 3 (Coding) complete | -> Create TEST_PLAN.md -> STOP for Human review |"
echo "| Phase 4 (Test Plan) approved | -> Execute tests autonomously |"
echo "| Phase 5 (Testing) complete | -> Report results -> Enter Phase 6 loop |"
echo ""

# Check current progress
if [ -f "IMPLEMENTATION_PLAN.md" ]; then
    echo "### Current Progress (from IMPLEMENTATION_PLAN.md):"
    # Count completed vs total tasks
    TOTAL=$(grep -c '^\s*- \[' IMPLEMENTATION_PLAN.md 2>/dev/null || echo "0")
    DONE=$(grep -c '^\s*- \[x\]' IMPLEMENTATION_PLAN.md 2>/dev/null || echo "0")
    echo "Tasks: $DONE / $TOTAL completed"

    # Check if all tasks are done
    if [ "$TOTAL" -gt 0 ] && [ "$DONE" -eq "$TOTAL" ]; then
        echo ""
        echo "*** ALL IMPLEMENTATION TASKS COMPLETE ***"
        echo "NEXT STEP: Create TEST_PLAN.md and STOP for Human review!"
    fi
    echo ""
fi

# Check if TEST_PLAN.md exists
if [ -f "TEST_PLAN.md" ]; then
    echo "### TEST_PLAN.md exists"
    # Count test status
    TESTS_TOTAL=$(grep -c '^\s*- \[' TEST_PLAN.md 2>/dev/null || echo "0")
    TESTS_DONE=$(grep -c '^\s*- \[x\]' TEST_PLAN.md 2>/dev/null || echo "0")
    echo "Tests: $TESTS_DONE / $TESTS_TOTAL completed"
    echo ""
fi

echo "### CRITICAL REMINDER:"
echo "1. Re-read skill file: .claude/skills/vibe-builder/SKILL.md"
echo "2. Re-read IMPLEMENTATION_PLAN.md for current progress"
echo "3. Re-read TEST_PLAN.md (if exists) for test status"
echo "4. Follow workflow strictly - especially checkpoints!"
echo ""
echo "=== END CONTEXT RECOVERY ==="
