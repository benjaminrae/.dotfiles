# Development Guidelines For Claude

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE**. Every single line of production code must be written in response to a failing test. No exceptions. This is not a suggestion or a preference - it is the fundamental practice that enables all other principles in this document.

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing and object oriented programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Quick Reference

**Key Principles**: 
- Write tests first (TDD)
- Test behaviour not implementation
- **NEVER** commit in red
- **ONLY** refactor in green

## Test Driven Development

Use outside-in TDD with a double loop where possible. This is especially useful when working on a vertical slice. Use classical TDD in other circumstances.

### Core TDD Principles

- Always write tests before production
- Follow RED-GREEN-REFACTOR cycle strictly
- Use baby steps to make small logical changes
- Verify tests fail for the right reason before trying to make tests pass
- Verify tests pass before moving on to refactoring
- Always try to stay green by using small safe refactors

### Classical TDD workflow

1. Write a comprehensive list of possible test cases
    - Order the test cases by priority (use [ZOMBIES](https://blog.wingman-sw.com/tdd-guided-by-zombies))
2. RED - Write enough code to see the first test case fail for the right reason 
    - A correct failure is due to incorrect or missing behaviour in the implementation
    - Compilation errors, reference errors, and typos are not correct failures
    - If a method is not yet implemented it should explicitly throw `throw new Error('Method not implemented')`
3. GREEN - Write the minimum code to make the test pass based on the context we have
    - Do not write production code that is not necessary to make the failing test pass
    - Use fake it when there is not enough context to go towards a generic solution
    - Commit while we are in green
4. REFACTOR - Clean up the code for readability and maintainability
    - Refactor both production code and test code 
    - Never add new funcionality during refactoring
    - Remove duplication with a 3 strikes rule 
    - If the refactor breaks tests revert to our green state and try smaller steps
    - Commit each small refactor as long as tests pass
5. TRIANGULATE to choose the next test case
    - Select a test that will fail with the current implementation
    - Select the simplest test that requires a change in behaviour
    - Move towards general solutions instead of many if statements with hard coded solutions
6. REPEAT steps 2 - 5  until completion

### Outside in double loop TDD workflow

1. RED Write a failing acceptance test
    - Make sure the test fails for the right reason (not meeting acceptance criteria)
    - The failure should tell us where to go next, e.g a method not implemented error in a collaborator tells us we need to implement that first
2. Move to the inner loop and stay there till the acceptance test becomes green
    - The inner loop is the classical TDD workflow
    - Frequently check the acceptance test to check where we should move the double loop next. 
3. GREEN Once you see the test pass commit the acceptance test
4. REFACTOR 
5. Repeat 1 - 4 for each acceptance test


### Example TDD Workflow

First create a list of test scenarios

#### Feature: String Calculator

#### Test Cases:

1. Empty string returns 0
2. Single number returns that number
3. Two numbers separated by comma returns sum
4. Multiple numbers separated by commas returns sum


#### TDD Cycle:

Then move on to the TDD cycle

```typescript
// RED Phase - Test 1
describe('StringCalculator', () => {
  it('should return 0 for empty string', () => {
    const calculator = new StringCalculator();
    expect(calculator.add('')).toBe(0);
  });
});

// GREEN Phase - Minimal implementation
class StringCalculator {
  add(numbers: string): number {
    return 0; // Hard-coded to pass
  }
}

// COMMIT now we are in green

// REFACTOR Phase - No changes needed yet

// RED Phase - Test 2 (chosen via triangulation)
it('should return the number for single number', () => {
  const calculator = new StringCalculator();
  expect(calculator.add('1')).toBe(1);
});

// GREEN Phase - Update implementation
class StringCalculator {
  add(numbers: string): number {
    if (numbers === '') return 0;
    return parseInt(numbers);
  }
}

// COMMIT now we are in green

// REFACTOR and commit in green

```

### Test Organization

Write unit tests next to the production code. Not every piece of production code needs a unit test. Prefer testing units of behaviour instead of units of code. 

Unit tests should use the suffix `.spec.ts`
Integration tests shouuld use the suffix `.integration.spec.ts`
End-to-End tests should use the suffix `.e2e.spec.ts`

### Triangulation and Choosing the Next Test Case

#### What is Triangulation?

Triangulation is the practice of choosing the next test case that will force you to change the production code, moving away from hard-coded implementations toward more general solutions.

#### Choosing the Next Test Case

- Select a test that will fail with the current implementation
- Choose the simplest test that requires a different behavior
- Avoid tests that would pass with the current hard-coded solution
- Use triangulation to drive the implementation toward generality

#### When to Remove "Method not implemented"

- Remove the error throw once you have a working implementation for the current test case
- The next test case should fail because it requires different behavior, not because of the error throw
- This ensures you're using triangulation to drive the design

#### Example of Triangulation

```
// Test 1: 0 → ""
// Implementation: if (number === 0) return "";

// Test 2: 1 → "I" (chosen because it will fail with current implementation)
// This forces us to handle the case where number === 1
// Implementation: if (number === 0) return ""; if (number === 1) return "I";

// Test 3: 2 → "II" (chosen because it will fail with current implementation)
// This forces us to handle repetition
// Implementation: if (number === 0) return ""; if (number === 1) return "I"; if (number === 2) return "II";
```

### Test Doubles

- Avoid using test doubles given by the testing framework
- Prefer manual test doubles
- Prefer creating many smaller, more specific test doubles than complicated test doubles to reuse in many test suites
- Avoid using test doubles to test implementation details (this can be used as a stepping stone but should not be in the final test)


## Refactoring Rules

### Core Principles
- **Refactor only when all tests are GREEN**
- **Never add new functionality during refactoring**
- **Never change external behavior**
- **Run tests frequently during refactoring**
- **Make small, incremental changes**
- **If tests break, revert and try smaller steps**

### Code Clarity Principles
- **Prefer improving naming** over adding comments
- **Make code self-documenting** through clear method and variable names
- **Avoid comments** - they often indicate unclear code
- **Don't add comments** as a substitute for better code structure
- JSDOC can be added if but only if representing a public API

```typescript
// ✅ Do This
const isUserEligibleForDiscount = user.age >= 18 && user.purchaseHistory.length > 0;
const hasValidMembership = user.membershipStatus === 'active' && !user.membershipExpired;

if (isUserEligibleForDiscount && hasValidMembership) {
  applyDiscount(user);
}

// ❌ Don't Do This
// Check if user is eligible for discount based on age, purchase history, and membership status
if (user.age >= 18 && user.purchaseHistory.length > 0 && 
    user.membershipStatus === 'active' && !user.membershipExpired) {
  applyDiscount(user);
}
```

### Refactoring Patterns

#### Extract Method
- **When**: A block of code has a clear, single purpose
- **How**: Move the code to a new method with a descriptive name
- **Why**: Improves readability and reusability
- **Guidelines**: Keep methods small and focused on a single responsibility

#### Rename
- **When**: A name doesn't clearly describe its purpose
- **How**: Change the name to be more descriptive
- **Why**: Makes code self-documenting

#### Extract Variable
- **When**: A complex expression is hard to understand
- **How**: Assign the expression to a well-named variable
- **Why**: Improves readability and debugging

#### Simplify Conditional
- **When**: A conditional expression is complex
- **How**: Extract to a method or use early returns
- **Why**: Makes logic easier to follow

### Three Strikes Rule
- **When**: You see the same logic or code pattern repeated
- **How**: Wait for the third occurrence before refactoring
- **Why**: Avoids premature abstraction and ensures refactoring is based on real, repeated patterns
- **Example**: If you see similar code in three places, extract it into a shared function or abstraction
- **Note**: If you only see it in two places, wait for a third before refactoring

### Anti-Patterns to Avoid
- ❌ Adding new functionality during refactoring
- ❌ Changing external behavior
- ❌ Making large, sweeping changes
- ❌ Adding comments instead of improving code
- ❌ Refactoring without running tests
- ❌ Ignoring failing tests during refactoring

### When to Stop Refactoring
- **When the code is clear and readable**
- **When all tests pass consistently**
- **When the next change would be a new feature**
- **When the refactoring doesn't improve clarity**

### Refactoring Checklist
- [ ] All tests are passing
- [ ] No new functionality added
- [ ] External behavior unchanged
- [ ] Code is more readable
- [ ] Names are descriptive
- [ ] Methods have single responsibilities
- [ ] No comments needed to explain code
- [ ] Tests still pass after refactoring

### Remember
- **Refactoring is about improving code quality**
- **Good code is self-documenting**
- **Small changes are safer than large ones**
- **Tests are your safety net**
- **When in doubt, make the code clearer**


## Typescript

- Always use erasable syntax
- All functions and methods should have return types
- Prefer the highest lowest level of visibilty and change only as needed (`private readonly`, `private`, `protected`, `public`)
- Never use `any`
- Use interface for defining behaviour (methods)
- Use type for defining data structures (dtos)

## Manual Verification

After implementation is complete and automated tests pass, ALWAYS perform manual verification against the running system before claiming work is done.

### Test Categories
Design tests for each changed endpoint or feature covering:

1. **Happy path** — valid request with correct fields → expected success response
2. **Breaking changes** — if a field was renamed/removed, send the OLD field name → confirm it's rejected
3. **Input validation** — empty body, invalid formats, blank required fields, boundary values → expect 400
4. **Not found** — non-existent entity IDs → expect 404
5. **Business rule violations** — self-references, invalid state transitions, duplicate operations → expect appropriate error

### Process
1. **Check prerequisites** — verify infrastructure (DB, message queues, external services) and the app are running
2. **Gather test data** — query existing data or create test entities via the API
3. **Execute tests** — use `curl` with `-s -w "\nHTTP %{http_code}"` for clean output
4. **Clean up** — always delete/reset test data after tests complete
5. **Report** — summarise results in a table with test number, description, and result

### Principles
- Test the actual HTTP API, not just unit tests
- Cover both positive and negative scenarios
- Verify error messages reference the correct field names (especially after renames)
- Never claim work is done without evidence from the running system

## Working with Claude

### Expectations

When working with my code:

1. **ALWAYS FOLLOW TDD** - No production code without a failing test. This is not negotiable.
2. **Think deeply** before making any edits
3. **Understand the full context** of the code and requirements
4. **Ask clarifying questions** when requirements are ambiguous
5. **Think from first principles** - don't make assumptions
6. **Assess refactoring after every green** - Look for opportunities to improve code structure, but only refactor if it adds value
7. **Keep project docs current** - update them whenever you introduce meaningful changes
8. Commit atomic changes as long as the tests are in green

### Code Changes

When suggesting or making changes:

- **Start with a failing test** - always. No exceptions.
- After making tests pass, always assess refactoring opportunities (but only refactor if it adds value)
- After refactoring, verify all tests and static analysis pass, then commit
- Respect the existing patterns and conventions
- Maintain test coverage for all behavior changes
- Keep changes small and incremental
- Ensure all TypeScript strict mode requirements are met
- Provide rationale for significant design decisions

**If you find yourself writing production code without a failing test, STOP immediately and write the test first.**

### Communication

- Be explicit about trade-offs in different approaches
- Explain the reasoning behind significant design decisions
- Flag any deviations from these guidelines with justification
- Suggest improvements that align with these principles
- When unsure, ask for clarification rather than assuming
