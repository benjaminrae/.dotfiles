---
name: tpp-guide
description: "Use when teaching or applying the Transformation Priority Premise (TPP) during TDD. Guides choosing the simplest transformation at each RED-GREEN step to evolve code from specific to general."
---

# Transformation Priority Premise (TPP) Guide

## Overview

The Transformation Priority Premise helps you choose the simplest code change at each GREEN step of TDD. Instead of making arbitrary implementation choices, TPP provides a priority-ordered list of transformations. Always prefer higher-priority (simpler) transformations over lower-priority (more complex) ones.

## The 14 Transformations (Priority Order)

| # | Transformation | Description |
|---|----------------|-------------|
| 1 | `{} -> nil` | No code -> return null/0/empty |
| 2 | `nil -> constant` | Return null -> return a fixed value |
| 3 | `constant -> constant+` | Add simple computations to a constant |
| 4 | `constant -> scalar` | Replace a constant with a variable (e.g., use a function argument) |
| 5 | `statement -> statements` | Add more statements |
| 6 | `unconditional -> conditional` | Split flow into two paths (if) |
| 7 | `scalar -> array` | Replace a single value with a collection |
| 8 | `array -> container` | Replace array with richer structure (map, set) |
| 9 | `statement -> tail recursion` | Add recursion at the tail |
| 10 | `conditional -> loop` | Transform `if` to `while` when a split flow must repeat |
| 11 | `tail recursion -> full recursion` | Tail call -> full recursive call |
| 12 | `expression -> function` | Extract expression into a function |
| 13 | `variable -> mutation` | Change state of an existing variable |
| 14 | `switch/case` | Split flow further with multiple branches |

## How to Apply

At each GREEN step:

1. Look at the failing test
2. Consider which transformations could make it pass
3. **Choose the highest-priority (lowest number) transformation that works**
4. If a transformation doesn't directly change behavior, it may enable the next one (e.g., `constant -> scalar` enables state changes)
5. Avoid introducing duplication -- but duplication as a stopgap can reveal patterns for generalization

## Key Principles

- Higher-priority transformations produce **more general** code
- Lower-priority transformations produce **more specific** code
- Choosing simpler transformations first avoids over-engineering
- A `while` is a general form of `if`; an `if` is a specific form of `while`
- `constant -> scalar` doesn't always change behavior alone -- it enables future transformations when coupled with changing state

## Worked Example

See `transformations-reference.md` for a complete PrimeFactors walkthrough showing each transformation applied step by step.

## Anti-Patterns

- Jumping to loops or conditionals when a simpler constant/scalar transformation would work
- Introducing `switch/case` (priority 14) when `conditional` (priority 6) + `loop` (priority 10) would suffice
- Adding duplication without using it as a stepping stone to generalization
- Skipping the transformation analysis and guessing at implementation
