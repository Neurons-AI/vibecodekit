#!/usr/bin/env bash
set -euo pipefail

# Vibe Code Kit Installer
# https://github.com/Neurons-AI/vibecodekit

REPO_URL="https://github.com/Neurons-AI/vibecodekit/archive/refs/heads/main.tar.gz"
REPO_PREFIX="vibecodekit-main"
TMP_DIR=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Flags
TARGET_DIR=""
LIST_ONLY=false
FORCE=false
PICK_INDIVIDUAL=false
INSTALL_ALL=false

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "  ╦  ╦╦╔╗ ╔═╗  ╔═╗╔═╗╔╦╗╔═╗  ╦╔═╦╔╦╗"
  echo "  ╚╗╔╝║╠╩╗║╣   ║  ║ ║ ║║║╣   ╠╩╗║ ║ "
  echo "   ╚╝ ╩╚═╝╚═╝  ╚═╝╚═╝═╩╝╚═╝  ╩ ╩╩ ╩ "
  echo -e "${NC}"
  echo -e "  ${BOLD}Prebuilt skills for Vibe Coding${NC}"
  echo ""
}

usage() {
  echo -e "${BOLD}Usage:${NC}"
  echo "  curl -fsSL <url> | bash -s -- [options]"
  echo "  npx vibecodekit [options]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  --all            Install all skills to .claude (non-interactive)"
  echo "  --claude         Install all skills to .claude"
  echo "  --cursor         Install all skills to .cursor"
  echo "  --agent          Install all skills to .agent"
  echo "  --target <dir>   Set target directory (.claude, .cursor, .agent)"
  echo "  --list           List available skills"
  echo "  --pick           Pick individual skills to install"
  echo "  --force          Overwrite existing files without asking"
  echo "  -h, --help       Show this help message"
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo "  npx vibecodekit                    # Interactive mode"
  echo "  npx vibecodekit --all              # Install all to .claude"
  echo "  npx vibecodekit --claude           # Install to .claude"
  echo "  npx vibecodekit --agent            # Install to .agent"
  echo "  npx vibecodekit --list             # List available skills"
  echo ""
}

download_repo() {
  TMP_DIR=$(mktemp -d)
  echo -e "${BLUE}Downloading Vibe Code Kit...${NC}"
  if command -v curl &>/dev/null; then
    curl -fsSL "$REPO_URL" | tar -xz -C "$TMP_DIR"
  elif command -v wget &>/dev/null; then
    wget -qO- "$REPO_URL" | tar -xz -C "$TMP_DIR"
  else
    echo -e "${RED}Error: curl or wget is required${NC}"
    exit 1
  fi
  echo -e "${GREEN}Downloaded successfully.${NC}"
}

print_list() {
  local src="$1"
  local has_skills=false

  echo -e "${BOLD}Available skills:${NC}"
  echo ""

  if [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      if [ "$has_skills" = false ]; then
        has_skills=true
      fi
      local desc=""
      if [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      if [ -n "$desc" ]; then
        echo -e "  ${GREEN}$name${NC} — $desc"
      else
        echo -e "  ${GREEN}$name${NC}"
      fi
    done
  fi

  if [ "$has_skills" = false ]; then
    echo -e "  ${YELLOW}No skills found.${NC}"
  fi
  echo ""
}

copy_skill() {
  local src="$1"
  local name="$2"
  local src_path="$src/.claude/skills/$name"
  local dest_dir="$TARGET_DIR/skills/$name"

  if [ ! -e "$src_path" ]; then
    echo -e "${RED}  Not found: $name${NC}"
    return 1
  fi

  # Check for conflicts
  if [ -e "$dest_dir" ] && [ "$FORCE" = false ]; then
    if [ -d "$dest_dir" ]; then
      # Check individual files within
      local has_conflict=false
      while IFS= read -r -d '' file; do
        local rel="${file#$src_path/}"
        if [ -f "$dest_dir/$rel" ]; then
          has_conflict=true
          break
        fi
      done < <(find "$src_path" -type f -print0 2>/dev/null)

      if [ "$has_conflict" = true ]; then
        echo -e "${YELLOW}  Files in $dest_dir already exist.${NC}"
        read -rp "  Overwrite? [y/N/a(ll)] " answer
        case "$answer" in
          [yY]) ;;
          [aA]) FORCE=true ;;
          *) echo -e "  ${YELLOW}Skipped: $name${NC}"; return 0 ;;
        esac
      fi
    elif [ -f "$dest_dir/$name" ]; then
      echo -e "${YELLOW}  File $dest_dir/$name already exists.${NC}"
      read -rp "  Overwrite? [y/N/a(ll)] " answer
      case "$answer" in
        [yY]) ;;
        [aA]) FORCE=true ;;
        *) echo -e "  ${YELLOW}Skipped: $name${NC}"; return 0 ;;
      esac
    fi
  fi

  mkdir -p "$dest_dir"
  if [ -d "$src_path" ]; then
    cp -R "$src_path/"* "$dest_dir/" 2>/dev/null || cp -R "$src_path/". "$dest_dir/" 2>/dev/null || true
  else
    cp "$src_path" "$dest_dir/"
  fi
  echo -e "  ${GREEN}Installed: $name → $dest_dir${NC}"
}

select_ai_tool() {
  echo -e "${BOLD}Which AI Coding tool are you using?${NC}"
  echo "  1) Claude Code"
  echo "  2) Cursor"
  echo "  3) Antigravity"
  echo "  4) Not sure"
  echo ""
  read -rp "Choose [1-4]: " tool_choice

  case "$tool_choice" in
    1) TARGET_DIR=".claude" ;;
    2) TARGET_DIR=".cursor" ;;
    3) TARGET_DIR=".agent" ;;
    4) TARGET_DIR=".agent" ;;
    *) echo -e "${RED}Invalid choice. Defaulting to .agent${NC}"; TARGET_DIR=".agent" ;;
  esac

  echo ""
  echo -e "${CYAN}Skills will be installed to: ${BOLD}$TARGET_DIR/skills/${NC}"
  echo ""
}

interactive_mode() {
  local src="$1"

  # Ask which AI tool
  select_ai_tool

  # Ask for installation granularity
  echo -e "${BOLD}Install full kit or pick individual skills?${NC}"
  echo "  1) Full kit"
  echo "  2) Pick individual"
  echo ""
  read -rp "Choose [1-2]: " granularity

  if [ "$granularity" = "2" ]; then
    PICK_INDIVIDUAL=true
  fi
}

pick_items() {
  local src="$1"
  local items=()
  local idx=1

  echo ""
  echo -e "${BOLD}Available skills:${NC}"

  if [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      local desc=""
      if [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      items+=("$name")
      if [ -n "$desc" ]; then
        echo -e "  ${BOLD}$idx)${NC} ${GREEN}$name${NC} — $desc"
      else
        echo -e "  ${BOLD}$idx)${NC} ${GREEN}$name${NC}"
      fi
      idx=$((idx + 1))
    done
  fi

  if [ ${#items[@]} -eq 0 ]; then
    echo -e "${YELLOW}  No skills available.${NC}"
    exit 0
  fi

  echo ""
  read -rp "Enter numbers to install (comma-separated, e.g. 1,3,5): " selections

  IFS=',' read -ra sel_arr <<< "$selections"
  local selected=()
  for s in "${sel_arr[@]}"; do
    s=$(echo "$s" | tr -d ' ')
    local i=$((s - 1))
    if [ "$i" -ge 0 ] && [ "$i" -lt ${#items[@]} ]; then
      selected+=("${items[$i]}")
    fi
  done

  echo ""
  echo -e "${BOLD}Installing ${#selected[@]} skill(s) to $TARGET_DIR/skills/...${NC}"
  for name in "${selected[@]}"; do
    copy_skill "$src" "$name"
  done
}

install_all() {
  local src="$1"

  if [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      copy_skill "$src" "$name"
    done
  fi
}

main() {
  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --target)
        shift
        if [ $# -eq 0 ]; then
          echo -e "${RED}Error: --target requires a value${NC}"
          exit 1
        fi
        TARGET_DIR="$1"
        shift
        ;;
      --all) INSTALL_ALL=true; TARGET_DIR=".claude"; shift ;;
      --claude) TARGET_DIR=".claude"; shift ;;
      --cursor) TARGET_DIR=".cursor"; shift ;;
      --agent) TARGET_DIR=".agent"; shift ;;
      --list) LIST_ONLY=true; shift ;;
      --pick) PICK_INDIVIDUAL=true; shift ;;
      --force) FORCE=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo -e "${RED}Unknown option: $1${NC}"; usage; exit 1 ;;
    esac
  done

  print_banner

  # Download repo
  download_repo
  local src="$TMP_DIR/$REPO_PREFIX"

  # List mode
  if [ "$LIST_ONLY" = true ]; then
    print_list "$src"
    exit 0
  fi

  # If no target specified, go interactive
  if [ -z "$TARGET_DIR" ]; then
    interactive_mode "$src"
  fi

  # Pick individual or install all
  if [ "$PICK_INDIVIDUAL" = true ]; then
    pick_items "$src"
  else
    echo -e "${BOLD}Installing skills to $TARGET_DIR/skills/...${NC}"
    install_all "$src"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}Done!${NC} Vibe Code Kit installed to ${CYAN}$TARGET_DIR/skills/${NC}"
  echo ""
}

main "$@"
