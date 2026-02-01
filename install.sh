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
INSTALL_CLAUDE=false
INSTALL_AGENT=false
LIST_ONLY=false
FORCE=false
PICK_INDIVIDUAL=false

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
  echo "  --claude       Install Claude Code skills only"
  echo "  --agent        Install Antigravity agents only"
  echo "  --all          Install everything"
  echo "  --list         List available skills and agents"
  echo "  --pick         Pick individual skills/agents to install"
  echo "  --force        Overwrite existing files without asking"
  echo "  -h, --help     Show this help message"
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
  local has_claude=false
  local has_agent=false

  echo -e "${BOLD}Available items:${NC}"
  echo ""

  if [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      if [ "$has_claude" = false ]; then
        echo -e "  ${CYAN}${BOLD}Claude Code Skills (.claude/skills/)${NC}"
        has_claude=true
      fi
      local desc=""
      if [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      if [ -n "$desc" ]; then
        echo -e "    ${GREEN}$name${NC} — $desc"
      else
        echo -e "    ${GREEN}$name${NC}"
      fi
    done
  fi

  if [ -d "$src/.agent/skills" ]; then
    for agent_dir in "$src/.agent/skills"/*/; do
      [ -d "$agent_dir" ] || continue
      local name
      name=$(basename "$agent_dir")
      [ "$name" = ".DS_Store" ] && continue
      if [ "$has_agent" = false ]; then
        echo ""
        echo -e "  ${CYAN}${BOLD}Antigravity Agents (.agent/skills/)${NC}"
        has_agent=true
      fi
      local desc=""
      if [ -f "$agent_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$agent_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      if [ -n "$desc" ]; then
        echo -e "    ${GREEN}$name${NC} — $desc"
      else
        echo -e "    ${GREEN}$name${NC}"
      fi
    done
  fi

  if [ "$has_claude" = false ] && [ "$has_agent" = false ]; then
    echo -e "  ${YELLOW}No skills or agents found.${NC}"
  fi
  echo ""
}

copy_skill() {
  local src="$1"
  local type="$2"
  local name="$3"
  local dest_dir

  local src_path
  if [ "$type" = "claude" ]; then
    src_path="$src/.claude/skills/$name"
    dest_dir=".claude/skills/$name"
  else
    src_path="$src/.agent/skills/$name"
    dest_dir=".agent/skills/$name"
  fi

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
  echo -e "  ${GREEN}Installed: $name${NC}"
}

interactive_mode() {
  local src="$1"

  echo -e "${BOLD}What do you want to install?${NC}"
  echo "  1) Claude Code skills"
  echo "  2) Antigravity agents"
  echo "  3) Both"
  echo ""
  read -rp "Choose [1-3]: " scope_choice

  case "$scope_choice" in
    1) INSTALL_CLAUDE=true ;;
    2) INSTALL_AGENT=true ;;
    3) INSTALL_CLAUDE=true; INSTALL_AGENT=true ;;
    *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
  esac

  echo ""
  echo -e "${BOLD}Install full kit or pick individual items?${NC}"
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
  local display_items=()
  local idx=1

  echo ""
  echo -e "${BOLD}Available items:${NC}"

  if [ "$INSTALL_CLAUDE" = true ] && [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      local desc=""
      if [ -f "$skill_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      items+=("claude:$name")
      if [ -n "$desc" ]; then
        echo -e "  ${BOLD}$idx)${NC} ${CYAN}[claude]${NC} ${GREEN}$name${NC} — $desc"
      else
        echo -e "  ${BOLD}$idx)${NC} ${CYAN}[claude]${NC} ${GREEN}$name${NC}"
      fi
      idx=$((idx + 1))
    done
  fi

  if [ "$INSTALL_AGENT" = true ] && [ -d "$src/.agent/skills" ]; then
    for agent_dir in "$src/.agent/skills"/*/; do
      [ -d "$agent_dir" ] || continue
      local name
      name=$(basename "$agent_dir")
      [ "$name" = ".DS_Store" ] && continue
      local desc=""
      if [ -f "$agent_dir/SKILL.md" ]; then
        desc=$(grep -m1 "^description:" "$agent_dir/SKILL.md" 2>/dev/null | sed 's/^description: *//' || true)
      fi
      items+=("agent:$name")
      if [ -n "$desc" ]; then
        echo -e "  ${BOLD}$idx)${NC} ${CYAN}[agent]${NC} ${GREEN}$name${NC} — $desc"
      else
        echo -e "  ${BOLD}$idx)${NC} ${CYAN}[agent]${NC} ${GREEN}$name${NC}"
      fi
      idx=$((idx + 1))
    done
  fi

  if [ ${#items[@]} -eq 0 ]; then
    echo -e "${YELLOW}  No items available.${NC}"
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
  echo -e "${BOLD}Installing ${#selected[@]} item(s)...${NC}"
  for item in "${selected[@]}"; do
    IFS=':' read -r type name <<< "$item"
    copy_skill "$src" "$type" "$name"
  done
}

install_all_type() {
  local src="$1"
  local type="$2"

  if [ "$type" = "claude" ] && [ -d "$src/.claude/skills" ]; then
    for skill_dir in "$src/.claude/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      local name
      name=$(basename "$skill_dir")
      [ "$name" = ".DS_Store" ] && continue
      copy_skill "$src" "claude" "$name"
    done
  fi

  if [ "$type" = "agent" ] && [ -d "$src/.agent/skills" ]; then
    for agent_dir in "$src/.agent/skills"/*/; do
      [ -d "$agent_dir" ] || continue
      local name
      name=$(basename "$agent_dir")
      [ "$name" = ".DS_Store" ] && continue
      copy_skill "$src" "agent" "$name"
    done
  fi
}

main() {
  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --claude) INSTALL_CLAUDE=true; shift ;;
      --agent) INSTALL_AGENT=true; shift ;;
      --all) INSTALL_CLAUDE=true; INSTALL_AGENT=true; shift ;;
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

  # If no scope flags given, go interactive
  if [ "$INSTALL_CLAUDE" = false ] && [ "$INSTALL_AGENT" = false ]; then
    interactive_mode "$src"
  fi

  # Pick individual or install all
  if [ "$PICK_INDIVIDUAL" = true ]; then
    pick_items "$src"
  else
    echo -e "${BOLD}Installing...${NC}"
    [ "$INSTALL_CLAUDE" = true ] && install_all_type "$src" "claude"
    [ "$INSTALL_AGENT" = true ] && install_all_type "$src" "agent"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}Done!${NC} Vibe Code Kit installed successfully."
  echo ""
}

main "$@"
