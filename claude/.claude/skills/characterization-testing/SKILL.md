---
name: characterization-testing
description: "Use when approaching untested legacy code that needs a safety net before refactoring. Guides the 5-step characterization testing process to discover and lock down existing behavior."
---

# Characterization Testing

## Overview

When you need to change legacy code that has no tests, no documentation, and the original author is gone -- you need a safety net. Characterization tests capture what the code **actually does** (not what it's supposed to do), preserving current behavior before you make changes.

<HARD-GATE>
Do NOT attempt to refactor or change legacy code until you have a sufficient characterization test suite covering the code paths you intend to modify. The safety net comes FIRST.
</HARD-GATE>

## The Mindset

> What the code is supposed to do is much less important than what the code actually does. This code holds business value. If we write tests based on what the system is supposed to do, we are bug hunting. We need to guarantee preservation of current behavior.

## The 5-Step Process

### Step 1: Select a piece of code to test

Start with the code you need to modify. Focus on the specific area where your change will go.

### Step 2: Write an assertion you believe will fail

Write a test with an assertion that you expect to be wrong. Use an obviously incorrect expected value.

```typescript
it('should do something', () => {
  const result = legacyFunction(input);
  expect(result).toBe('WRONG_VALUE_ON_PURPOSE');
});
```

### Step 3: Let the failure message tell you the behavior

Run the test. The failure message reveals what the code actually does:

```
Expected: 'WRONG_VALUE_ON_PURPOSE'
Received: 'actual_behavior_here'
```

The failure message IS the documentation.

### Step 4: Update the test to expect the actual behavior

```typescript
it('should return the actual behavior', () => {
  const result = legacyFunction(input);
  expect(result).toBe('actual_behavior_here');
});
```

### Step 5: Repeat

Continue steps 1-4 until you have sufficient coverage over the code paths you need to modify.

## Using Code Coverage as a Guide

Run tests with coverage enabled. The coverage report shows you:

- **Covered lines**: you have a test that exercises this code
- **Uncovered lines**: potential behavior you haven't captured yet
- **Branch coverage**: conditional paths you haven't tested

Use coverage to navigate to untested paths and write characterization tests for them.

## Testing and Refactoring Directions

| Activity | Direction |
|----------|-----------|
| **Adding characterization tests** | Shallow to deep -- start from the shallowest (outermost) branch and work inward |
| **Refactoring after safety net** | Deep to shallow -- start from the deepest (innermost) branch and work outward |

This is critical. Testing shallow-to-deep builds your understanding gradually. Refactoring deep-to-shallow means each refactoring step affects the smallest possible scope.

## Anti-Patterns

- Treating these as black box tests — look at the code, use it to guide your tests
- Writing tests based on intended behavior instead of actual behavior
- Fixing bugs discovered during characterization testing — capture the current behavior, bugs and all
- Using generic test names — give tests meaningful names that describe the behavior you discovered
- Starting refactoring before the safety net is complete

## When is the Safety Net Sufficient?

- All code paths you intend to modify are covered
- Branch coverage covers the conditionals in your target area
- You can confidently describe what the current code does based on your tests
- Running the tests gives you confidence that refactoring won't break existing behavior
