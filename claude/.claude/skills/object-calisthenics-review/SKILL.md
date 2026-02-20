---
name: object-calisthenics-review
description: "Use when reviewing code for OO design quality, or as a constraint during coding katas. Evaluates code against all 9 Object Calisthenics rules with explanations and refactoring suggestions."
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

**Why:**
- `dog.Body.Tail.Wag()` creates coupling to classes far from you
- Exposes intent, hides implementation (Tell Don't Ask)
- Reduces knowledge needed to enable a behavior

**Fix:** `dog.Body.Tail.Wag()` -> `dog.ExpressHappiness()`

**Note:** This does not apply to fluent APIs or LINQ-style chains.

### Rule 6: Don't abbreviate

**Why:**
- Abbreviations obscure intent
- If a name is too long, the method or class might have too many responsibilities

### Rule 7: Keep all entities small

**Why:**
- Small classes have single responsibilities
- Easier to understand, test, and reuse

### Rule 8: No classes with more than two instance variables

**Why:**
- Forces decomposition into smaller, more cohesive classes
- Each class represents a clear concept

### Rule 9: No getters/setters/properties

**Why:**
- OOP is a network of entities that collaborate by passing messages
- Instead of asking an object for data and acting on it, tell the object what to do (Tell Don't Ask)
- Do not add public getters just for test assertions -- override equality instead

## How to Review

For each file under review:

1. Scan for violations of each rule
2. For each violation found, report:
   - The rule number and name
   - The file and line number
   - Why this is a problem (from the Why section above)
   - A specific refactoring suggestion (from the How section above)
3. Prioritize violations by impact on design quality
4. Acknowledge that these are aspirational constraints -- not every rule applies in every context

## When to Use as Constraints

During coding katas, apply these rules strictly as design constraints. In production code reviews, treat them as guidelines that highlight design opportunities.
