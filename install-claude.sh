#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/benjaminrae/.dotfiles/main/claude/.claude"
CLAUDE_DIR="$HOME/.claude"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Helper functions
info() {
    printf "${GREEN}[INFO]${RESET} %s\n" "$1"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2
}

# Flag parsing
INSTALL_CLAUDE_MD=false
INSTALL_SKILLS=false
INSTALL_AGENTS=false
INSTALL_SETTINGS=false
EXPLICIT_FLAG=false

for arg in "$@"; do
    case "$arg" in
        --claude-only)
            INSTALL_CLAUDE_MD=true
            EXPLICIT_FLAG=true
            ;;
        --skills-only)
            INSTALL_SKILLS=true
            EXPLICIT_FLAG=true
            ;;
        --agents-only)
            INSTALL_AGENTS=true
            EXPLICIT_FLAG=true
            ;;
        *)
            error "Unknown flag: $arg"
            exit 1
            ;;
    esac
done

# Default: install everything when no specific flag is given
if [ "$EXPLICIT_FLAG" = false ]; then
    INSTALL_CLAUDE_MD=true
    INSTALL_SKILLS=true
    INSTALL_AGENTS=true
    INSTALL_SETTINGS=true
fi

# Always install settings.json unless a specific --*-only flag was used
if [ "$EXPLICIT_FLAG" = false ]; then
    INSTALL_SETTINGS=true
fi

# Backup a file or directory with a timestamp before overwriting
backup_file() {
    local target="$1"
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"

    if [ -f "$target" ]; then
        local backup="${target}.bak.${timestamp}"
        warn "Backing up existing file: $target -> $backup"
        cp "$target" "$backup"
    elif [ -d "$target" ]; then
        local backup="${target}.bak.${timestamp}"
        warn "Backing up existing directory: $target -> $backup"
        cp -r "$target" "$backup"
    fi
}

# Download a single file from the remote repo into CLAUDE_DIR
download_file() {
    local relative_path="$1"
    local dest="${CLAUDE_DIR}/${relative_path}"
    local dest_dir
    dest_dir="$(dirname "$dest")"
    local url="${REPO_URL}/${relative_path}"

    mkdir -p "$dest_dir"
    backup_file "$dest"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest"
    else
        error "Neither curl nor wget is available. Cannot download files."
        exit 1
    fi

    info "Installed: $dest"
}

# Track installed items for the summary
INSTALLED=()

# Main installation logic
mkdir -p "$CLAUDE_DIR"

if [ "$INSTALL_SETTINGS" = true ]; then
    download_file "settings.json"
    INSTALLED+=("settings.json")
fi

if [ "$INSTALL_CLAUDE_MD" = true ]; then
    download_file "CLAUDE.md"
    INSTALLED+=("CLAUDE.md")
fi

if [ "$INSTALL_SKILLS" = true ]; then
    download_file "skills/jira/SKILL.md"
    download_file "skills/jira/bug-template.md"
    download_file "skills/branch-review/SKILL.md"
    download_file "skills/tdd-kata-coach/SKILL.md"
    download_file "skills/outside-in-tdd/SKILL.md"
    download_file "skills/tpp-guide/SKILL.md"
    download_file "skills/tpp-guide/transformations-reference.md"
    download_file "skills/characterization-testing/SKILL.md"
    download_file "skills/object-calisthenics-review/SKILL.md"
    download_file "skills/refactoring-guide/SKILL.md"
    download_file "skills/hexagonal-module-scaffold/SKILL.md"
    download_file "skills/hexagonal-module-scaffold/directory-template.md"
    download_file "skills/event-storming-facilitator/SKILL.md"
    download_file "skills/workshop-designer/SKILL.md"
    download_file "skills/til-content-creator/SKILL.md"
    # Agent-associated skills
    download_file "skills/domain-driven-design/ddd-expert-knowledge-base.md"
    download_file "skills/cognitive-load-analyzer/cli-dimensions-and-formulas.md"
    download_file "skills/cognitive-load-analyzer/cli-tool-commands.md"
    download_file "skills/cognitive-load-analyzer/lib/__init__.py"
    download_file "skills/cognitive-load-analyzer/lib/cli_calculator.py"
    download_file "skills/cognitive-load-analyzer/lib/core.py"
    download_file "skills/cognitive-load-analyzer/lib/dimensions.py"
    download_file "skills/cognitive-load-analyzer/lib/aggregation.py"
    download_file "skills/cognitive-load-analyzer/lib/sampling.py"
    download_file "skills/test-design-reviewer/farley-properties-and-scoring.md"
    download_file "skills/test-design-reviewer/signal-detection-patterns.md"
    download_file "skills/system-walkthrough/analysis-pipeline.md"
    download_file "skills/system-walkthrough/narrative-structure.md"
    download_file "skills/system-walkthrough/slide-architecture.md"
    download_file "skills/system-walkthrough/code-validation.md"
    download_file "skills/system-walkthrough/comprehension-models.md"
    INSTALLED+=(
        "skills/jira/SKILL.md"
        "skills/jira/bug-template.md"
        "skills/branch-review/SKILL.md"
        "skills/tdd-kata-coach/SKILL.md"
        "skills/outside-in-tdd/SKILL.md"
        "skills/tpp-guide/SKILL.md"
        "skills/tpp-guide/transformations-reference.md"
        "skills/characterization-testing/SKILL.md"
        "skills/object-calisthenics-review/SKILL.md"
        "skills/refactoring-guide/SKILL.md"
        "skills/hexagonal-module-scaffold/SKILL.md"
        "skills/hexagonal-module-scaffold/directory-template.md"
        "skills/event-storming-facilitator/SKILL.md"
        "skills/workshop-designer/SKILL.md"
        "skills/til-content-creator/SKILL.md"
        "skills/domain-driven-design/ddd-expert-knowledge-base.md"
        "skills/cognitive-load-analyzer/cli-dimensions-and-formulas.md"
        "skills/cognitive-load-analyzer/cli-tool-commands.md"
        "skills/cognitive-load-analyzer/lib/__init__.py"
        "skills/cognitive-load-analyzer/lib/cli_calculator.py"
        "skills/cognitive-load-analyzer/lib/core.py"
        "skills/cognitive-load-analyzer/lib/dimensions.py"
        "skills/cognitive-load-analyzer/lib/aggregation.py"
        "skills/cognitive-load-analyzer/lib/sampling.py"
        "skills/test-design-reviewer/farley-properties-and-scoring.md"
        "skills/test-design-reviewer/signal-detection-patterns.md"
        "skills/system-walkthrough/analysis-pipeline.md"
        "skills/system-walkthrough/narrative-structure.md"
        "skills/system-walkthrough/slide-architecture.md"
        "skills/system-walkthrough/code-validation.md"
        "skills/system-walkthrough/comprehension-models.md"
    )
fi

if [ "$INSTALL_AGENTS" = true ]; then
    download_file "agents/code-reviewer.md"
    download_file "agents/typescript-expert.md"
    download_file "agents/debugger-specialist.md"
    download_file "agents/atdd-developer.md"
    download_file "agents/problem-analyst.md"
    download_file "agents/user-story-writer.md"
    download_file "agents/domain-driven-design.md"
    download_file "agents/clean-coder.md"
    download_file "agents/refactoring-expert.md"
    download_file "agents/code-smell-detector.md"
    download_file "agents/legacy-code-expert.md"
    download_file "agents/cognitive-load-analyzer.md"
    download_file "agents/test-design-reviewer.md"
    download_file "agents/system-walkthrough.md"
    INSTALLED+=(
        "agents/code-reviewer.md"
        "agents/typescript-expert.md"
        "agents/debugger-specialist.md"
        "agents/atdd-developer.md"
        "agents/problem-analyst.md"
        "agents/user-story-writer.md"
        "agents/domain-driven-design.md"
        "agents/clean-coder.md"
        "agents/refactoring-expert.md"
        "agents/code-smell-detector.md"
        "agents/legacy-code-expert.md"
        "agents/cognitive-load-analyzer.md"
        "agents/test-design-reviewer.md"
        "agents/system-walkthrough.md"
    )
fi

# Summary
printf "\n${GREEN}Installation complete.${RESET} The following files were installed to ${CLAUDE_DIR}:\n"
for item in "${INSTALLED[@]}"; do
    printf "  ${GREEN}+${RESET} %s\n" "$item"
done