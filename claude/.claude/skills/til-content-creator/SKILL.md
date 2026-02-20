---
name: til-content-creator
description: "Use when creating technical content: TIL videos, blog posts, newsletter sections, or short-form video scripts. Structures content with hook-context-technique-takeaway format."
---

# TIL Content Creator

## Overview

Turn a technical topic or discovery into structured content. Supports multiple formats: TIL (Today I Learned) short videos, blog posts, newsletter sections, and short-form video scripts.

## Process

### Step 1: Choose the format

| Format | Length | Structure |
|--------|--------|-----------|
| **TIL video** | 30-60 seconds | Hook -> Demo -> Takeaway |
| **Short video** | 1-3 minutes | Hook -> Context -> Technique -> Takeaway |
| **Blog post** | 500-1000 words | Problem -> Solution -> Example -> Summary |
| **Newsletter section** | 2-3 sentences + link | Curiosity hook -> Brief description -> Link |

### Step 2: Structure the content

#### TIL Video (30-60 seconds)

```
HOOK (5 sec): "TIL you can [surprising thing]"
DEMO (20-40 sec): Show it working, step by step
TAKEAWAY (5-10 sec): When to use it, why it matters
```

#### Short Video (1-3 minutes)

```
HOOK (10 sec): The problem or surprising discovery
CONTEXT (20-30 sec): Why this matters, when you'd need it
TECHNIQUE (60-90 sec): Step-by-step demonstration
TAKEAWAY (15 sec): Key lesson, when to apply it
```

#### Blog Post

```
TITLE: Clear, specific (include the technology/tool name)
PROBLEM: What situation led to this discovery? (2-3 sentences)
SOLUTION: What's the technique? (with code examples)
EXAMPLE: Complete, runnable example
GOTCHAS: Common mistakes or edge cases
SUMMARY: One-sentence takeaway
```

#### Newsletter Section

```
INTRO: One curious/interesting sentence
DESCRIPTION: 2-3 sentences explaining what it is
LINK: To the full resource
BONUS: Optional related rabbit hole
```

### Step 3: Write the content

Follow the chosen structure. Key principles:
- **Start with what's surprising or useful** -- don't bury the lead
- **Show, don't tell** -- use code examples, screenshots, demos
- **One idea per piece** -- resist the urge to cover everything
- **Use the reader's language** -- avoid jargon unless the audience expects it

## Inspiration Bank

Topics from the TIL backlog:

**Git**: `git checkout -` to switch to last branch, git config tips
**Node.js**: Write tests without dependencies using `node:test`, streams, event loop
**TypeScript**: Utility types, type declarations, erasable syntax
**Docker**: Layer caching optimization, Docker Compose
**CSS**: Native nesting, `height: auto` animation
**Tools**: Raycast, dependency-cruiser, Abracadabra refactor, Rancher Desktop
**Trivia**: "patch" comes from punch card days, Colors.js incident

## Bad Code Advice (Satirical Content)

For humorous content, use the "Bad Code Advice" format -- state terrible advice with a straight face:

- "Code Reviews? Ain't Nobody Got Time for That!"
- "Version Control? Just save as `final_final_v2_final.js`"
- "Deploy on Fridays -- best way to start your weekend"
- "Skip Testing Entirely -- users will let you know"
- "One Giant File to Rule Them All"

## Newsletter Format (Tinkerers)

```
Hey Tinkerers!

Welcome to issue #N

---

## What I've read this week

[Curated link 1]: [brief description]
[Curated link 2]: [brief description]

---

## Internet rabbit hole of the week

[Topic]: [engaging narrative about a fascinating discovery]
[Links to videos/articles]

**Bonus:** [Related tangent]
```
