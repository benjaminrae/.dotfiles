---
name: outside-in-tdd
description: "Use when implementing a vertical slice or feature end-to-end using outside-in (London school) TDD with the double loop. Guides the acceptance test outer loop and classical TDD inner loop."
---

# Outside-In Double Loop TDD

## Overview

Guide implementation using the outside-in (London school) approach with a double loop: an outer acceptance test loop drives the feature, and an inner classical TDD loop builds each component. Use this when implementing vertical slices or features where the entry point and expected output are known.

**Gate (do not skip):** the outer loop has not started until you have run the acceptance test and observed it fail for the right reason. Proceed to the inner loop only when you can point to that recorded run output — the failure message and the failing assertion. No recorded failing run means no outer loop, regardless of schedule pressure. Write the acceptance test first; do not write inner-loop production code before this artifact exists.

## When to Use

- Implementing a vertical slice (e.g., API endpoint -> service -> repository)
- Building a feature where you know the entry point and expected behavior
- When the system design benefits from working from the outside in

## The Double Loop

```
OUTER LOOP (Acceptance Test)
  |
  +-- 1. Write failing acceptance test
  |     +-- Assert on the side effect (the observable outcome)
  |
  +-- 2. Run it -- verify it fails for the RIGHT reason
  |     +-- The failure message tells you where to go next
  |       (e.g., "method not implemented" in a collaborator)
  |
  +-- 3. PARK the acceptance test -> enter INNER LOOP
  |     |
  |     |  INNER LOOP (Classical TDD)
  |     |  +-----------------------------+
  |     |  | RED -> GREEN -> REFACTOR    |
  |     |  | (repeat for each component  |
  |     |  |  the acceptance test needs) |
  |     |  +-----------------------------+
  |     |
  |     +-- After each inner cycle, CHECK the acceptance test
  |     |   +-- If still failing: the failure tells you what's next
  |     |   +-- If passing: exit inner loop
  |     |
  |     +-- Stay in inner loop until acceptance test goes GREEN
  |
  +-- 4. COMMIT -- acceptance test is green
  |
  +-- 5. REFACTOR
  |
  +-- 6. Write next acceptance test -> repeat
```

## Process

### Step 1: Write the failing acceptance test

1. Identify the **side effect** -- what observable outcome does the feature produce?
2. Write the assertion on that side effect (this is your `then`/`assert`)
3. Identify what **triggers** the side effect (this is your `when`/`act`)
4. Set up the necessary context (this is your `given`/`arrange`)
5. Run the test and record the output -- it must fail for the **right reason**: missing or incorrect behavior in a collaborator the feature needs. Compilation errors, reference errors, and typos are wrong-reason failures -- fix the wiring and re-run until the failure is behavioral.
6. The recorded failure message is your guide and the artifact the gate requires: it tells you which collaborator or component to build next

### Step 2: Enter the inner loop

Use classical TDD (RED-GREEN-REFACTOR) to build the component that the acceptance test failure pointed to:

1. List test cases for this component using ZOMBIES
2. RED: write failing unit test
3. GREEN: minimum code to pass
4. COMMIT
5. REFACTOR
6. Triangulate next test

### Step 3: Check the acceptance test

After completing each component in the inner loop:

1. Run the acceptance test
2. If it **still fails**: confirm the failure message has moved on to the *next* missing component. If the same component is still failing after its inner cycle finished green, the inner cycle did not deliver what the acceptance test needs -- go back to the inner loop for that component rather than building something new.
3. If it **passes**: exit the inner loop, commit the acceptance test

### Step 4: Commit and refactor

1. COMMIT -- the acceptance test is green
2. REFACTOR both production and test code
3. COMMIT the refactoring

### Step 5: Next acceptance test

Write the next acceptance test for the next slice of behavior. Repeat the entire double loop.

## When Things Go Wrong

- **The acceptance test passes immediately.** The gate is violated -- there is no failing run to record. Either the behavior already exists (pick a slice that does not yet work) or the test asserts nothing meaningful (strengthen the assertion on the side effect until it fails). Do not enter the inner loop on a green acceptance test.
- **The acceptance test fails for the wrong reason.** A compile error, reference error, typo, or broken wiring is not a behavioral failure. Fix the wiring and re-run until the failure names a missing or incorrect collaborator behavior. Only that failure is a valid gate artifact.
- **The inner loop never turns the acceptance test green.** Each inner cycle should make the acceptance test failure move on to the next missing component. If it does not move after a component goes green, you built the wrong thing or asserted the wrong behavior in the unit test -- re-read the acceptance failure message and let it, not a guess, choose the next unit test. If the acceptance test is unreachable from the entry point, the slice is too large; split it.

## Testing Direction

| Activity | Direction |
|----------|-----------|
| Testing (adding tests) | Shallow to deep (start from the entry point, work inward) |
| Refactoring | Deep to shallow (start from the innermost component, work outward) |

## Key Differences from Classical TDD

| Classical (Chicago) | Outside-In (London) |
|---------------------|---------------------|
| Design emerges during refactoring | Design guided by acceptance test structure |
| Tests are usually state-based | Tests can be interaction-based (but prefer state) |
| Unit under test can grow to multiple classes | Each component tested in isolation |
| Mocks rarely used | Test doubles used at boundaries between components |
| Good for exploration | Good when entry point and output are known |

## Anti-Patterns

- Starting implementation without the acceptance test
- Staying in the inner loop too long without checking the acceptance test
- Writing the acceptance test after the implementation
- Using mocks everywhere instead of only at component boundaries
- Not letting the acceptance test failure guide you to the next component
