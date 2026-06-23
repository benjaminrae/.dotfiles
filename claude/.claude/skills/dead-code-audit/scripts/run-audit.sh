#!/usr/bin/env bash
# Orchestrate detection for the dead-code-audit skill.
#
# Usage: run-audit.sh <project-dir> [output-dir]
#
# Runs each detector that is available and writes raw output under
# <output-dir>/ for the skill to parse:
#
#   <output-dir>/intellij/    IntelliJ headless inspection JSON
#   <output-dir>/pmd/         PMD XML reports
#   <output-dir>/deps/        Dependency-analysis build-health output
#   <output-dir>/coverage.txt One line describing which detectors ran
#
# This script never modifies the working tree. It only reads project files
# and writes under <output-dir>.

set -euo pipefail

PROJECT_DIR="${1:-}"
OUTPUT_DIR="${2:-$PROJECT_DIR/.dead-code-audit/run}"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo "usage: run-audit.sh <project-dir> [output-dir]" >&2
  exit 2
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE_SRC="$SKILL_DIR/assets/inspection-profile.xml"

mkdir -p "$OUTPUT_DIR/intellij" "$OUTPUT_DIR/pmd" "$OUTPUT_DIR/deps"

COVERAGE=""

# --- IntelliJ headless ------------------------------------------------------
INSPECT_SH=""
for cand in \
  "/Applications/IntelliJ IDEA.app/Contents/bin/inspect.sh" \
  "/Applications/IntelliJ IDEA Ultimate.app/Contents/bin/inspect.sh" \
  "/Applications/IntelliJ IDEA CE.app/Contents/bin/inspect.sh"
do
  if [ -x "$cand" ]; then INSPECT_SH="$cand"; break; fi
done

if [ -z "$INSPECT_SH" ]; then
  for tb in "$HOME/Library/Application Support/JetBrains/Toolbox/apps/IDEA-U" \
            "$HOME/Library/Application Support/JetBrains/Toolbox/apps/IDEA-C"; do
    if [ -d "$tb" ]; then
      cand=$(find "$tb" -maxdepth 5 -name inspect.sh -perm -u+x 2>/dev/null | head -n 1)
      if [ -n "$cand" ] && [ -x "$cand" ]; then INSPECT_SH="$cand"; break; fi
    fi
  done
fi

if [ -z "$INSPECT_SH" ]; then
  for cand in "$(command -v idea 2>/dev/null)" "$(command -v idea.sh 2>/dev/null)"; do
    if [ -n "$cand" ] && [ -x "$cand" ]; then
      side="$(dirname "$cand")/inspect.sh"
      if [ -x "$side" ]; then INSPECT_SH="$side"; break; fi
    fi
  done
fi

if [ -n "$INSPECT_SH" ]; then
  echo "[dead-code-audit] using IntelliJ inspect.sh: $INSPECT_SH"
  PROFILE_DST="$PROJECT_DIR/.dead-code-audit/inspection-profile.xml"
  mkdir -p "$(dirname "$PROFILE_DST")"
  cp "$PROFILE_SRC" "$PROFILE_DST"

  rm -rf "$OUTPUT_DIR/intellij"
  mkdir -p "$OUTPUT_DIR/intellij"

  # Use isolated config/system/log dirs so headless inspect.sh can run alongside
  # a running IntelliJ GUI ("Only one instance of IDEA can be run at a time"
  # otherwise).
  IDEA_HEADLESS_HOME="$OUTPUT_DIR/idea-headless"
  mkdir -p "$IDEA_HEADLESS_HOME/config" "$IDEA_HEADLESS_HOME/system" "$IDEA_HEADLESS_HOME/log"
  IDEA_PROPS="$IDEA_HEADLESS_HOME/idea.properties"
  cat > "$IDEA_PROPS" <<EOF
idea.config.path=$IDEA_HEADLESS_HOME/config
idea.system.path=$IDEA_HEADLESS_HOME/system
idea.log.path=$IDEA_HEADLESS_HOME/log
EOF
  export IDEA_PROPERTIES="$IDEA_PROPS"

  "$INSPECT_SH" \
    "$PROJECT_DIR" \
    "$PROFILE_DST" \
    "$OUTPUT_DIR/intellij" \
    -format json \
    -v2 || echo "[dead-code-audit] WARN: IntelliJ inspect.sh exited non-zero (partial results may still be usable)"

  if find "$OUTPUT_DIR/intellij" -mindepth 1 -print -quit | grep -q .; then
    COVERAGE="intellij"
  else
    echo "[dead-code-audit] WARN: IntelliJ produced no output (output dir empty)"
  fi
else
  echo "[dead-code-audit] IntelliJ not found, skipping headless inspection"
fi

# --- PMD --------------------------------------------------------------------
if [ -f "$PROJECT_DIR/gradlew" ]; then
  echo "[dead-code-audit] running PMD via Gradle"
  pushd "$PROJECT_DIR" >/dev/null
  if ./gradlew tasks --all --console=plain 2>/dev/null | grep -qE '^pmdMain( |$)'; then
    ./gradlew pmdMain pmdTest --console=plain || echo "[dead-code-audit] WARN: pmd Gradle tasks exited non-zero"
    find . -path '*/build/reports/pmd/*.xml' -print0 \
      | xargs -0 -I{} cp {} "$OUTPUT_DIR/pmd/" 2>/dev/null || true
    COVERAGE="${COVERAGE:+$COVERAGE,}pmd"
  else
    echo "[dead-code-audit] pmd Gradle plugin not applied; skipping (ask the user before adding)"
  fi
  popd >/dev/null
fi

# --- Dependency analysis ----------------------------------------------------
if [ -f "$PROJECT_DIR/gradlew" ]; then
  pushd "$PROJECT_DIR" >/dev/null
  if ./gradlew tasks --all --console=plain 2>/dev/null | grep -qE '^buildHealth( |$)'; then
    echo "[dead-code-audit] running ./gradlew buildHealth"
    ./gradlew buildHealth --console=plain || echo "[dead-code-audit] WARN: buildHealth exited non-zero"
    find . -path '*/build/reports/dependency-analysis/*' -print0 \
      | xargs -0 -I{} cp {} "$OUTPUT_DIR/deps/" 2>/dev/null || true
    COVERAGE="${COVERAGE:+$COVERAGE,}dependency-analysis"
  else
    echo "[dead-code-audit] dependency-analysis plugin not applied; skipping (ask the user before adding)"
  fi
  popd >/dev/null
fi

if [ -z "$COVERAGE" ]; then COVERAGE="(none)"; fi
echo "$COVERAGE" > "$OUTPUT_DIR/coverage.txt"

# --- Parse into a unified candidate list -----------------------------------
if [ -d "$OUTPUT_DIR/intellij" ] && find "$OUTPUT_DIR/intellij" -mindepth 1 -name '*.json' -print -quit | grep -q .; then
  "$SKILL_DIR/scripts/parse-intellij.py" "$OUTPUT_DIR/intellij" || echo "[dead-code-audit] WARN: parse-intellij.py failed"
fi

echo "[dead-code-audit] detectors ran: $COVERAGE"
echo "[dead-code-audit] output: $OUTPUT_DIR"
