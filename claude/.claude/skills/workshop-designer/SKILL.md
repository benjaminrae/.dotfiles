---
name: workshop-designer
description: "Use when designing a technical workshop, coding dojo, or training session. Provides the 4-hour format template, pairing strategies, and lessons learned from past workshops."
---

# Workshop Designer

## Overview

Design a technical workshop using a proven format: structured time slots alternating between content delivery and hands-on practice, with retrospectives after each slot. Based on experience delivering workshops on TDD, Docker, Legacy Code, and Go.

## The Format Template

### Standard 4-Hour Workshop

| Start | End   | Slot          | Purpose           |
|-------|-------|---------------|-------------------|
| 0:00  | 0:15  | Ice Breakers  | Get people talking |
| 0:15  | 0:30  | Intro Slot 1  | Content delivery   |
| 0:30  | 1:30  | Slot 1        | Practice           |
| 1:30  | 1:40  | Retro Slot 1  | Reflect            |
| 1:40  | 1:55  | Break         |                    |
| 1:55  | 2:10  | Intro Slot 2  | Content delivery   |
| 2:10  | 3:10  | Slot 2        | Practice           |
| 3:10  | 3:20  | Retro Slot 2  | Reflect            |
| 3:20  | 3:35  | Intro Slot 3  | Content delivery   |
| 3:35  | 3:50  | Slot 3        | Practice           |
| 3:50  | 4:00  | Retro Slot 3  | Reflect + wrap up  |

### Key Ratios

- **Content delivery**: 15 min max per slot (keep it short)
- **Practice**: 60 min per slot (most of the time)
- **Retro**: 10 min per slot (short but important)

## Design Process

### Step 1: Define the learning objective

One sentence: "By the end of this workshop, participants will be able to ___."

### Step 2: Design the progression

Each slot should build on the previous one:
- **Slot 1**: Foundation concept + guided practice
- **Slot 2**: Build on slot 1 + more autonomy
- **Slot 3**: Apply everything + challenge

### Step 3: Choose the practice format

| Format | Best for | How it works |
|--------|----------|-------------|
| **Coding kata** | TDD, refactoring | Same problem, different constraints per slot |
| **Hands-on lab** | Docker, infra | Step-by-step guide to build something |
| **Mob programming** | Large groups, exploration | Whole group, one screen, rotate driver |

### Step 4: Choose pairing strategy

| Strategy | How it works | Best for |
|----------|-------------|----------|
| **Ping-pong** | One writes test, other implements, then swap | TDD katas |
| **Chess clock** | Fixed time per driver (e.g., 5 min), then swap | Balanced participation |
| **Pomodoro** | 25 min work, 5 min discuss, swap roles | Longer practice slots |
| **Navigator/Driver** | Navigator gives high-level direction, driver types | Mixed skill levels |

### Step 5: Design ice breakers

Quick activities (5-10 min) to get people comfortable:
- "What's the worst code you've ever seen?"
- Two truths and a lie (tech edition)
- "What's your hot take on [topic]?"

### Step 6: Plan retrospectives

Each slot retro should ask:
- What did you learn?
- What was confusing?
- What would you do differently?

## Lessons Learned

### From Docker Workshop V1
- **Problem**: Too much setup time, didn't finish on time
- **Fix**: Ask participants to complete setup BEFORE the workshop (provide materials/videos)
- **Fix**: Less theory, more practice -- get to the goal faster

### General Lessons
- **Estimate generously** -- things always take longer than planned
- **Have a fallback plan** -- if setup fails, have a backup environment
- **Material accessibility** -- share links/repos beforehand
- **Collect feedback** -- always end with a retro or feedback form
- **Iterate** -- V1 is never perfect, plan for V2

## Output

After the design process, produce:
1. Workshop outline (time slots filled in)
2. Materials list (repos, slides, links)
3. Setup instructions for participants
4. Facilitation notes for each slot
