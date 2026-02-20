---
name: refactoring-guide
description: "Use when refactoring code after reaching green in TDD, or when improving existing code structure. Enforces safety-first refactoring discipline with the three strikes rule."
---

# Refactoring Guide

## Overview

Refactoring improves code structure without changing external behavior. This skill enforces a disciplined approach: only refactor in green, make small changes, run tests frequently, and revert if anything breaks.

<HARD-GATE>
NEVER refactor when tests are RED. Get to green first, then refactor. If a refactoring breaks tests, REVERT immediately and try smaller steps.
</HARD-GATE>

## Core Rules

1. **Refactor only when all tests are GREEN**
2. **Never add new functionality during refactoring**
3. **Never change external behavior**
4. **Run tests after every small change**
5. **Make small, incremental changes**
6. **If tests break, revert and try smaller steps**
7. **COMMIT each successful refactoring**

## The Three Strikes Rule

Wait for the **third occurrence** of duplicated logic before abstracting:

- **First occurrence**: Write it
- **Second occurrence**: Note the duplication, but leave it
- **Third occurrence**: Now extract the abstraction

Why: Avoids premature abstraction. Two occurrences might be coincidence. Three confirms a real pattern.

## Refactoring Patterns

### Extract Method
- **When**: A block of code has a clear, single purpose
- **How**: Move the code to a new method with a descriptive name
- **Why**: Improves readability and reusability

### Rename
- **When**: A name doesn't clearly describe its purpose
- **How**: Change the name to be more descriptive
- **Why**: Makes code self-documenting

### Extract Variable
- **When**: A complex expression is hard to understand
- **How**: Assign the expression to a well-named variable
- **Why**: Improves readability and debugging

### Simplify Conditional
- **When**: A conditional expression is complex
- **How**: Extract to a method or use early returns
- **Why**: Makes logic easier to follow

## Choosing a Pattern

| Symptom | Pattern |
|---------|---------|
| Long method, hard to follow | Extract Method |
| Name doesn't convey intent | Rename |
| Complex boolean or arithmetic expression | Extract Variable |
| Nested if/else, multiple conditions | Simplify Conditional |

## Code Clarity Principles

**Prefer improving naming over adding comments.** Good code is self-documenting.

```typescript
// DO THIS
const isUserEligibleForDiscount = user.age >= 18 && user.purchaseHistory.length > 0;
const hasValidMembership = user.membershipStatus === 'active' && !user.membershipExpired;

if (isUserEligibleForDiscount && hasValidMembership) {
  applyDiscount(user);
}

// NOT THIS
// Check if user is eligible for discount based on age, purchase history, and membership status
if (user.age >= 18 && user.purchaseHistory.length > 0 &&
    user.membershipStatus === 'active' && !user.membershipExpired) {
  applyDiscount(user);
}
```

## Refactoring Checklist

After each refactoring session, verify:

- [ ] All tests are passing
- [ ] No new functionality added
- [ ] External behavior unchanged
- [ ] Code is more readable
- [ ] Names are descriptive
- [ ] Methods have single responsibilities
- [ ] No comments needed to explain code
- [ ] Tests still pass after refactoring

## When to Stop

- The code is clear and readable
- All tests pass consistently
- The next change would add new functionality
- Further refactoring wouldn't improve clarity

## Anti-Patterns

- Adding new functionality during refactoring
- Making large, sweeping changes
- Adding comments instead of improving code
- Refactoring without running tests
- Ignoring failing tests during refactoring
- Abstracting on the second occurrence (wait for three)
