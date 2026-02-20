---
name: tdd-kata-coach
description: "Use when practicing TDD through coding katas, teaching TDD to others, or coaching someone through the RED-GREEN-REFACTOR cycle. Enforces ZOMBIES ordering, baby steps, triangulation, and commit discipline."
---

# TDD Kata Coach

## Overview

Guide the practitioner through a coding kata using strict Test-Driven Development. This skill enforces the RED-GREEN-REFACTOR cycle with baby steps, ZOMBIES for test case ordering, and triangulation for choosing the next test.

<HARD-GATE>
NEVER write production code without a failing test. If you catch yourself about to write implementation code, STOP and write the test first. This is non-negotiable.
</HARD-GATE>

## Process

### Phase 1: Plan test cases

Before writing any code, create a comprehensive list of test cases ordered using ZOMBIES:

| Letter | Meaning | Description |
|--------|---------|-------------|
| **Z** | Zero | Empty case, null, zero, nothing |
| **O** | One | Single element, simplest positive case |
| **M** | Many | Multiple elements, collections |
| **B** | Boundary | Edge cases, limits, off-by-one |
| **I** | Interface | API design, method signatures |
| **E** | Exceptional | Error cases, invalid input |
| **S** | Simple scenarios | Start with the simplest, build complexity |

Present the ordered list to the user and ask: "Does this test case ordering look right? Any cases missing?"

### Phase 2: RED-GREEN-REFACTOR cycle

For each test case, follow this exact sequence:

#### RED — Write a failing test

1. Write a test that describes the expected behavior
2. Run the test
3. **Verify it fails for the RIGHT reason:**
   - A correct failure is due to incorrect or missing behavior in the implementation
   - Compilation errors, reference errors, and typos are NOT correct failures
   - If a method is not yet implemented, it should explicitly `throw new Error('Method not implemented')`
4. If the failure is wrong, fix the test setup until it fails correctly

#### GREEN — Write minimum code to pass

1. Write the **minimum** code to make the failing test pass
2. Use these strategies in order of preference:
   - **Fake it**: Return a hard-coded value if there isn't enough context for a general solution
   - **Obvious implementation**: If the solution is trivial, implement it directly
3. Do NOT write production code that is not necessary to make the failing test pass
4. Run all tests — they must ALL pass
5. **COMMIT** — we are in green

#### REFACTOR — Clean up (only in green)

1. Look for opportunities to improve code structure:
   - Extract method for blocks with clear single purpose
   - Rename for clarity (prefer naming over comments)
   - Extract variable for complex expressions
   - Simplify conditionals with early returns
2. Apply the **three strikes rule**: wait for 3 occurrences before abstracting
3. Run tests after EVERY small refactoring change
4. If tests break: **revert immediately** and try smaller steps
5. Never add new functionality during refactoring
6. **COMMIT** each successful refactoring step

### Phase 3: Triangulate next test

Choose the next test case that will:
1. **Fail** with the current implementation (not pass accidentally)
2. Require a **different behavior** than what's currently implemented
3. Be the **simplest** test that forces a change
4. Move toward a **general solution** instead of more hard-coded if statements

### Phase 4: Repeat

Go back to Phase 2 with the next test case. Continue until all test cases from Phase 1 are implemented.

After completing all tests, do a final refactoring pass across both production and test code.

## Test Organization

- Unit tests go next to the production code with suffix `.spec.ts`
- Test behavior, not implementation — test units of behavior, not units of code
- Prefer manual test doubles over framework-provided mocks
- Create small, specific test doubles rather than complex reusable ones

## Anti-Patterns to Flag

- Writing production code before the test
- Skipping the refactoring step
- Writing a test that passes immediately (not triangulating)
- Using framework mocks when manual test doubles would be clearer
- Committing while tests are red
- Adding comments instead of improving naming
- Making large leaps instead of baby steps

## Example Flow

```
Test cases for StringCalculator.add():
1. Empty string returns 0               (Zero)
2. Single number returns that number    (One)
3. Two numbers returns sum              (Many)
4. Multiple numbers returns sum         (Many)
5. Negative numbers throw error         (Exceptional)

Cycle 1:
  RED: test empty string → 0
  GREEN: return 0 (fake it)
  COMMIT

Cycle 2 (triangulate — "1" will fail with current hard-coded 0):
  RED: test "1" → 1
  GREEN: if (numbers === '') return 0; return parseInt(numbers);
  COMMIT
  REFACTOR: no changes needed yet

Cycle 3 (triangulate — "1,2" will fail):
  RED: test "1,2" → 3
  GREEN: split and sum
  COMMIT
  REFACTOR: extract parsing logic
  COMMIT
```
