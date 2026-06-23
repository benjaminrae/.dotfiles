# Detectors

The audit merges results from multiple static detectors into a single candidate list. Each candidate carries the set of detectors that flagged it; multi-detector agreement raises confidence but does not bypass the reflection checklist.

## Primary: IntelliJ Headless Inspections

IntelliJ's Spring plugin understands DI entry points, SpEL, and many Spring conventions that standalone Java analysers miss. This is the strongest detector available without writing custom analysis.

### Locating the launcher

The launcher binary varies by install method:

| Install | Launcher path |
|---------|---------------|
| macOS app bundle | `/Applications/IntelliJ IDEA.app/Contents/MacOS/idea` and `bin/inspect.sh` inside the bundle |
| macOS Ultimate (toolbox) | `~/Library/Application Support/JetBrains/Toolbox/apps/IDEA-U/<version>/IntelliJ IDEA.app/Contents/MacOS/idea` |
| Linux tarball | `<install>/bin/idea.sh`, `<install>/bin/inspect.sh` |
| Windows | `bin\idea64.exe`, `bin\inspect.bat` |

The dedicated **`inspect`** script (`inspect.sh` / `inspect.bat`) is the supported headless entry point. Prefer it over the main launcher.

Detect with:

```bash
INSPECT_SH=""
for cand in \
  "/Applications/IntelliJ IDEA.app/Contents/bin/inspect.sh" \
  "/Applications/IntelliJ IDEA Ultimate.app/Contents/bin/inspect.sh" \
  "$HOME/Library/Application Support/JetBrains/Toolbox/apps/IDEA-U/ch-0/*/IntelliJ IDEA.app/Contents/bin/inspect.sh" \
  "$(command -v idea 2>/dev/null)" \
  "$(command -v idea.sh 2>/dev/null)"
do
  if [ -x "$cand" ]; then INSPECT_SH="$cand"; break; fi
done
```

If none is found, fall back to PMD + the reflection checklist and put a note in the report header.

### Running the inspection

```bash
"$INSPECT_SH" \
  "$PROJECT_DIR" \
  "$PROJECT_DIR/.dead-code-audit/inspection-profile.xml" \
  "$PROJECT_DIR/.dead-code-audit/intellij-output" \
  -format json \
  -v2
```

Notes:

- The first run will index the project. On a cold cache this can take 5–20 minutes for a medium service; set the timeout to comfortably exceed that (e.g. 30 minutes) and stream progress.
- The output directory must exist and be empty.
- `-format json` emits one JSON file per inspection. `-format plain` is the default and harder to parse — always pass `-format json`.
- `-v2` gives verbose progress.

### Running alongside an open IntelliJ GUI

By default `inspect.sh` shares the same config/system directories as a running IntelliJ instance. If the GUI is open, headless exits immediately with `Only one instance of IDEA can be run at a time.` and the output directory stays empty (with no clear error — the script must check that the output is non-empty before claiming IntelliJ ran).

Work around it by pointing headless at isolated paths via an `idea.properties` file and `IDEA_PROPERTIES`:

```bash
IDEA_HEADLESS_HOME="$OUTPUT_DIR/idea-headless"
mkdir -p "$IDEA_HEADLESS_HOME/config" "$IDEA_HEADLESS_HOME/system" "$IDEA_HEADLESS_HOME/log"
cat > "$IDEA_HEADLESS_HOME/idea.properties" <<EOF
idea.config.path=$IDEA_HEADLESS_HOME/config
idea.system.path=$IDEA_HEADLESS_HOME/system
idea.log.path=$IDEA_HEADLESS_HOME/log
EOF
export IDEA_PROPERTIES="$IDEA_HEADLESS_HOME/idea.properties"
```

The trade-off: isolated config means a fresh index on the first headless run (slower cold start), but subsequent runs reuse the cache in `idea-headless/system/`. The orchestrator script already does this; keep the pattern if writing alternatives.

### The curated inspection profile

Ship the profile at `assets/inspection-profile.xml`. Copy it into the target project as `.dead-code-audit/inspection-profile.xml` before running. The profile enables:

| Inspection | Why |
|------------|-----|
| `UnusedDeclaration` (`unused`) | Core: unused classes, methods, fields, parameters |
| `EmptyMethod` | Often paired with unused declarations |
| `RedundantThrows` | Indicates dead exception-handling code |
| `ConstantConditions` | Flags unreachable branches |
| `UNUSED_IMPORT` | Cheap signal of dead-code-adjacent churn |
| `SpringJavaInjectionPointsAutowiringInspection` | Helps surface dangling injection targets |

Disable all noisy style inspections — the profile should be tight, not exhaustive.

### Parsing the JSON output

IntelliJ writes a separate file per inspection (`unused.xml` historically, `unused.json` with `-format json`). Even with a tight profile, **IntelliJ writes a result file for every inspection it ran**, not just the ones flagged as enabled — including large noisy ones the profile disables for safety (SpellChecking, HTML/CSS/JS, Markdown, Grazie).

The skill consumes **only** these files (others are ignored even if present):

| File | Inspection | Tag in candidate list |
|------|------------|----------------------|
| `unused.json` | `unused` (UnusedDeclaration) | `intellij:unused` |
| `UnusedReturnValue.json` | `UnusedReturnValue` | `intellij:UnusedReturnValue` |
| `RedundantThrows.json` | `RedundantThrows` | `intellij:RedundantThrows` |
| `EmptyMethod.json` | `EmptyMethod` | `intellij:EmptyMethod` |

`UNUSED_IMPORT.json` is intentionally excluded: unused imports are style smells, not dead-code candidates, and IntelliJ emits them at file granularity (no FQN).

Each entry contains `file`, `line`, `entry_point.FQNAME`, `entry_point.TYPE`, `module`, `package`, and `description`.

The script [scripts/parse-intellij.py](../scripts/parse-intellij.py) reads these files, merges duplicates by `(id, file, line)`, splits findings by source set (`main` vs `test` vs `integrationTest`), and writes a unified `candidates.json` to the parent of the intellij output dir. Downstream verification works from `candidates.json`, not the raw IntelliJ output.

`run-audit.sh` invokes the parser automatically after IntelliJ completes.

## Secondary: PMD via Gradle

PMD complements IntelliJ for cases where IntelliJ is unavailable, and as a sanity check otherwise. Use a one-shot Gradle invocation that does not require modifying the project:

```bash
./gradlew pmdMain pmdTest \
  -PpmdRules=category/java/bestpractices.xml/UnusedPrivateMethod,\
category/java/bestpractices.xml/UnusedPrivateField,\
category/java/bestpractices.xml/UnusedLocalVariable,\
category/java/bestpractices.xml/UnusedFormalParameter \
  --console=plain
```

If the project does not have the `pmd` Gradle plugin applied, ask the user before adding it (a temporary `--init-script` is acceptable — see `scripts/run-audit.sh`).

PMD reports go to `build/reports/pmd/`. Parse the XML report and merge candidates by file+line+symbol.

## Secondary: Dependency Analysis Plugin

`com.autonomousapps.dependency-analysis` reports unused and misdeclared dependencies. These are **separate from Java dead code** — they live in a distinct section of the report.

```bash
./gradlew buildHealth --console=plain
```

If the plugin is not applied, ask before adding it (again, an `--init-script` is acceptable).

Output goes to `build/reports/dependency-analysis/build-health-report.txt` (and JSON). Surface its summary verbatim in the report under "Dependency hygiene".

## Graceful Degradation

| Detector available | Coverage note in report header |
|--------------------|--------------------------------|
| IntelliJ + PMD + dependency-analysis | "Full detector coverage." |
| IntelliJ + PMD | "Full Java code coverage; dependency analysis skipped." |
| IntelliJ only | "Java code coverage from IntelliJ only; PMD and dependency analysis skipped." |
| PMD only | "**Reduced coverage**: IntelliJ not available. Spring-aware analysis is limited to this skill's manual reflection checklist." |
| None | "**Severely reduced coverage**: relying entirely on the skill's reflection checklist. Treat all Tier 1 findings as Tier 3." |

The "None" case should additionally prompt the user before continuing.

## Merging Candidates

Each candidate's identity is `(file, line, symbol)` where symbol is the class/method/field qualified name. When the same symbol is flagged by multiple detectors, merge into one candidate with a list of detector tags. Multi-detector hits become more confident Tier 1/Tier 2 candidates; single-detector hits with no checklist evidence remain Tier 1 only if the reflection checklist comes back clean.
