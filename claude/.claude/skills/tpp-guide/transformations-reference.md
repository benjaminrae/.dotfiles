# TPP Worked Example: Prime Factors

This walkthrough shows the Transformation Priority Premise applied step-by-step to the Prime Factors kata. Each step identifies which transformation is used and why.

## TPP 1: `{} -> nil`

First test: `primeFactorsOf(1)` should return an empty list.

```java
@Test
public void factors() {
    assertEquals(listOf(), primeFactorsOf(1));
}

private List<Integer> primeFactorsOf(int number) {
    return null;
}
```

Transform from no implementation to returning null.

## TPP 2: `nil -> constant`

Make the test pass by returning an actual empty list.

```java
private List<Integer> primeFactorsOf(int number) {
    return new ArrayList<>();
}
```

## TPP 4: `constant -> scalar`

New test: `primeFactorsOf(2)` should return `[2]`.

First, introduce a variable (this doesn't pass the test alone but enables the next transformation):

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();
    return factors;
}
```

> **Note:** Changing a constant to a variable doesn't directly alter behavior, but it enables it. Now that we have the variable, we can change its state.

## TPP 6: `unconditional -> conditional`

Add a conditional to handle the case where number > 1:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        factors.add(2);
    }

    return factors;
}
```

> **Key insight:** The condition `number > 1` is more general than `number == 2`. Using `number == 2` would mirror the test (too specific). `number > 1` allows for future possibilities.

## TPP 4: `constant -> scalar` (again)

New test: `primeFactorsOf(3)` should return `[3]`. Replace the hard-coded `2` with the variable `number`:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        factors.add(number);
    }

    return factors;
}
```

> **Note:** `constant -> scalar` (replacing `2` with `number`) was able to cause a behavior change this time because it's coupled to something that's already changing (the argument `number`).

## TPP 6: `unconditional -> conditional` (again)

New test: `primeFactorsOf(4)` should return `[2, 2]`. Add another conditional:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        if (number % 2 == 0) {
            factors.add(2);
            number /= 2;
        }

        if (number > 1) {
            factors.add(number);
        }
    }

    return factors;
}
```

## TPP 10: `conditional -> loop`

New test: `primeFactorsOf(8)` should return `[2, 2, 2]`. The inner `if` needs to repeat, so transform it to a `while`:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        while (number % 2 == 0) {
            factors.add(2);
            number /= 2;
        }
    }

    if (number > 1) {
        factors.add(number);
    }

    return factors;
}
```

> **Key insight:** A `while` is just a general form of an `if`, and an `if` is a specific form of a `while`.

Tests for `primeFactorsOf(5)`, `primeFactorsOf(6)`, and `primeFactorsOf(7)` all pass with this implementation.

The `while` can be refactored to a `for`:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        for (; number % 2 == 0; number /= 2) {
            factors.add(2);
        }
    }

    if (number > 1) {
        factors.add(number);
    }

    return factors;
}
```

## Non-TPP Step (Duplication as stepping stone)

New test: `primeFactorsOf(9)` should return `[3, 3]`. Add a second loop for divisor 3:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        for (; number % 2 == 0; number /= 2) {
            factors.add(2);
        }
        for (; number % 3 == 0; number /= 3) {
            factors.add(3);
        }
    }

    if (number > 1) {
        factors.add(number);
    }

    return factors;
}
```

> **Note:** This step doesn't follow TPP because it introduces duplication. Duplication is never general -- it's always specific and often tightly coupled to the test code. But as a stopgap it can reveal interesting information about how to generalize.

## TPP 4: `constant -> scalar` (enabling generalization)

Extract the hard-coded `2` into a variable `divisor`:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    if (number > 1) {
        int divisor = 2;
        for (; number % divisor == 0; number /= divisor) {
            factors.add(divisor);
        }
    }

    if (number > 1) {
        factors.add(number);
    }

    return factors;
}
```

This doesn't make the test pass yet, but it enables the next transformation.

## TPP 10: `conditional -> loop` (generalization)

Transform the outer `if` into a `while` that increments the divisor:

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();
    int divisor = 2;

    while (number > 1) {
        for (; number % divisor == 0; number /= divisor) {
            factors.add(divisor);
        }
        divisor++;
    }

    return factors;
}
```

## Final Refactor: `while` to `for`

```java
private List<Integer> primeFactorsOf(int number) {
    ArrayList<Integer> factors = new ArrayList<>();

    for (int divisor = 2; number > 1; divisor++) {
        for (; number % divisor == 0; number /= divisor) {
            factors.add(divisor);
        }
    }

    return factors;
}
```

That's the complete Prime Factors algorithm, arrived at purely through TPP-guided transformations.

## TPP Summary Table

| # | Transformation | Description |
|---|----------------|-------------|
| 1 | `{} -> nil` | Transform a function that isn't a function into one that returns null or 0 |
| 2 | `nil -> constant` | Transform to return a static constant |
| 3 | `constant -> constant+` | Add one or two simple computations |
| 4 | `constant -> scalar` | Transform a constant into a variable, using an argument |
| 5 | `statement -> statements` | Add more statements |
| 6 | `unconditional -> conditional` | Split the flow into two paths of execution |
| 7 | `scalar -> array` | Transform a variable to an array |
| 8 | `array -> container` | Transform an array into a dictionary or set |
| 9 | `statement -> tail recursion` | Add tail recursion |
| 10 | `conditional -> loop` | Transform `if` to `while` when a split flow must repeat |
| 11 | `tail recursion -> full recursion` | Transform tail recursion to full recursion |
| 12 | `expression -> function` | Extract expression into a function |
| 13 | `variable -> mutation` | Change the state of a previously existing variable |
| 14 | `switch/case` | Split the flow further with multiple branches |
