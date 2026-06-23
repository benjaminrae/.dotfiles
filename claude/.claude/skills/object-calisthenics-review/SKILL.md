---
name: object-calisthenics-review
description: "Evaluates code against all 9 Object Calisthenics rules with detect/fix heuristics and a standardized finding format. Use when reviewing code specifically for OO design quality, or as a design constraint during coding katas. Not for: general correctness or security review (use code-reviewer), post-green refactoring discipline (use refactoring-guide), or branch/PR QA test planning (use qa-report) — this skill only scores code against the 9 Object Calisthenics rules."
---

# Object Calisthenics Review

## Overview

Review code against the 9 Object Calisthenics rules. For each violation found, explain why it matters and how to fix it. These rules are design constraints that push toward better OO design -- small, focused objects that collaborate through messages.

## The 9 Rules

### Rule 1: Only one level of indentation per method

**Why:**
- Ensures methods focus on doing only one thing
- Reduces unit size, enabling easier reuse

**How to fix:** Extract Method (https://refactoring.guru/extract-method)

### Rule 2: Don't use the ELSE keyword

**Why:**
- Promotes a main execution lane with few special cases
- Suggests polymorphism for complex conditionals (e.g., State Pattern)
- Consider the Null Object pattern for "no value" cases

**How to fix:**
- Consolidate conditional expression
- Replace nested conditional with Guard Clauses
- Replace conditional with Polymorphism

### Rule 3: Wrap all primitives and strings

**Why:**
- Primitives are super types with only contextual meaning -- they can express anything, so we use them for everything
- Wrapping makes code explicit by expressing intent through types that become behavior attractors
- Objects have inherent meaning
- Cures Primitive Obsession code smell

**Rules:**
- No method arguments (except constructors) that are primitive types
- No method return values that are primitive types
- Create a class for each primitive to act as home for related behaviors
- Private primitive member variables are OK

### Rule 4: First-class collections

**Why:**
- Treats collections as primitives -- any behavior specific to the collection lives in one place
- Filters, joins, and special rules are contained within the class
- Changing internal representation doesn't affect clients (decoupling)

**Rules:**
- No method arguments (except constructors) that are collections
- Create a class for every collection, even if just a private member variable
- A class containing a collection should contain no other member variables

**How to fix:** Encapsulate Collection

### Rule 5: One dot per line

**Detect:** A statement that navigates across more than one object boundary, e.g. `dog.Body.Tail.Wag()` — each `.` reaches into a different object's internals (Law of Demeter violation), coupling the caller to classes far from it.

**Fix:** `dog.Body.Tail.Wag()` -> `dog.ExpressHappiness()` (Tell Don't Ask — let the nearest object do the work).

**Note:** This does not apply to fluent/builder chains or LINQ-style pipelines. The test: if each call returns the *same* object (or a stream/builder of one type) it is fluent and fine; if each `.` returns a *different* collaborator you are navigating someone else's structure — that is the violation.

### Rule 6: Don't abbreviate

**Detect:** Truncated or initialism identifiers (`calc`, `usr`, `mgr`, `tmp`, `i`/`j` outside trivial loops, `e` for exceptions in long handlers). A name so long it needs abbreviating is the signal — the entity is doing too much.

**Fix:** Spell the name out; if the full name reads awkwardly long, split the responsibility rather than shorten the word.

### Rule 7: Keep all entities small

**Detect:** Flag classes over ~50 lines or with more than ~10 methods, and methods over ~5 lines (rough thresholds — adjust to the project's language and conventions). Original guidance: no class over 50 lines, no package over 10 files.

**Fix:** Extract Class / Extract Method until each entity expresses one responsibility.

### Rule 8: No classes with more than two instance variables

**Detect:** Count instance fields per class; flag any class declaring 3 or more (exclude constants/statics).

**Fix:** Group related fields into a new class (the two surviving fields then reference cohesive concepts rather than loose data).

### Rule 9: No getters/setters/properties

**Why:**
- OOP is a network of entities that collaborate by passing messages
- Instead of asking an object for data and acting on it, tell the object what to do (Tell Don't Ask)
- Prefer not to add public getters solely for test assertions -- overriding equality is usually a cleaner alternative

## How to Review

For each file under review:

1. Scan for violations of each rule using the **Detect** cues above.
2. Report each violation in the output format below.
3. Order findings by severity (High before Medium before Low).
4. Acknowledge that these are aspirational constraints -- not every rule applies in every context.

**Severity scale:**
- **High** — directly harms collaboration or coupling (Rules 5, 9; Rules 3/4 primitive/collection obsession in public APIs).
- **Medium** — structural smell that will compound (Rules 7, 8; Rules 1, 2 in core logic).
- **Low** — readability or local clarity (Rule 6; minor Rule 1/2 cases).

**Output format (one block per finding):**

```
[Severity] Rule N: <rule name>
File: <path>:<line>
Issue: <what was detected, in one sentence>
Fix: <specific refactoring from this skill>
```

**Worked example:**

```
[Medium] Rule 8: No classes with more than two instance variables
File: src/checkout/Order.java:14
Issue: Order declares 5 instance fields (customer, items, address, total, status).
Fix: Extract a ShippingDetails class (address) and an OrderTotals class (total, status); Order then holds customer, items, and the two new collaborators.
```

## When to Use as Constraints

During coding katas, apply these rules strictly as design constraints. In production code reviews, treat them as guidelines that highlight design opportunities.
