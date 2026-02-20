---
name: event-storming-facilitator
description: "Use when facilitating or preparing an Event Storming session. Guides through all phases of Big Picture Event Storming with sticky note types, facilitation tips, and phase transitions."
---

# Event Storming Facilitator

## Overview

Event Storming (proposed by Alberto Brandolini) is a workshop technique for capturing business domain knowledge. It brings together business and technical people to build a shared understanding of processes, boundaries, and responsibilities. This skill guides facilitation of a Big Picture Event Storming session.

## Purpose

- Capture and visualize business domain processes
- Join fragmented knowledge from organizational silos
- Make processes understandable by both business and developers
- Discover boundaries, collaborations, and bottlenecks
- Identify the most compelling problem to solve

## Setup Requirements

- Large modelling surface (long wall with paper or whiteboard)
- Standing room -- NO SEATS (keeps energy up)
- Unlimited sticky notes in these colors:
  - Orange: Domain Events
  - Purple: Hotspots (problems/conflicts)
  - Yellow: People/Actors
  - Pink: Systems
  - Blue: Opportunities/Votes
  - Light blue: Commands (optional for deeper sessions)
  - Green: Read Models (optional)
  - Large yellow: Aggregates (optional)
- Markers (one per participant)
- Legend visible on the wall
- Drinks and snacks

## Sticky Note Types

| Color | Type | Format | Example |
|-------|------|--------|---------|
| Orange | Domain Event | Verb in past tense, relevant to domain experts | "Order Placed", "Payment Received" |
| Purple | Hotspot | Problem, conflict, or question | "Who approves this?", "Takes 3 days" |
| Yellow | People | Actor or role | "Customer", "Warehouse Manager" |
| Pink | System | External or internal system | "Payment Gateway", "CRM" |
| Blue | Vote/Arrow | Priority indicator | Arrow pointing to chosen problem |
| Light blue | Command | Action that triggers event | "Place Order", "Submit Application" |

## The Phases

### Phase 1: Kick-off (5-10 min)

- Explain the purpose and format
- Show the legend
- Set ground rules: no wrong answers, write one event per sticky, verb in past tense
- Introduce the scope: which line of business or process are we mapping?

### Phase 2: Chaotic Exploration (20-30 min)

- Everyone writes DOMAIN EVENTS (orange stickies) simultaneously
- No discussion, no ordering -- just get events on the wall
- Events must be in **past tense** and **relevant to domain experts** (not technical events)
- Encourage quantity over quality
- Facilitator energy matters: keep people writing, not talking

### Phase 3: Enforce the Timeline (15-20 min)

- As a group, arrange events in chronological order (left to right)
- Strategies for organizing:
  - **Pivotal events**: Find the big moments that divide the process into phases
  - **Swimlanes**: Group by actor or department
  - **Milestones**: Mark key checkpoints
  - **Chapter sorting**: Group into logical chapters
- Mark HOTSPOTS (purple stickies) for conflicts, questions, or disagreements

### Phase 4: People and Systems (10-15 min)

- Add PEOPLE (yellow stickies) -- who triggers or is involved in each event?
- Add SYSTEMS (pink stickies) -- what systems are involved?
- This reveals ownership, handoffs, and integration points

### Phase 5: Explicit Walkthrough (15-20 min)

- One narrator walks through the entire timeline left to right
- Everyone listens and catches missing events
- Add any events that were missed

### Phase 6: Reverse Narrative (10-15 min)

- Walk backwards: for each event, verify all preceding events are present
- "What had to happen before this event could occur?"
- This catches gaps that the forward walkthrough missed

### Phase 7: Problems and Opportunities (10-15 min)

- Review all HOTSPOTS
- Add OPPORTUNITY stickies for potential improvements
- Discuss the biggest pain points

### Phase 8: Pick the Right Problem (5-10 min)

- Each participant gets 3 VOTE stickies (blue with arrow)
- Vote on the most important problem or opportunity to address
- Tally votes and discuss the top-voted items

### Phase 9: Wrap-up (5-10 min)

- Photograph the entire board
- Summarize the key discoveries
- Identify next steps (deeper modeling, solution design, spike)

## Facilitation Tips

- **Keep people standing** -- sitting kills energy
- **Enforce one event per sticky** -- prevents essays
- **Past tense verbs only** -- not "placing order" but "Order Placed"
- **Domain language** -- use business terms, not technical terms
- **Hotspots are good** -- they reveal where the real problems are
- **Don't solve during the session** -- the goal is discovery, not solutions
- **Include the right people** -- you need domain experts, not just developers
- **Time-box each phase** -- keep momentum

## When to Use

- Kicking off a new product or feature
- Onboarding to a complex domain
- Identifying bounded contexts for DDD
- Challenging existing processes
- Reflecting on issues in delivered software
- Bridging the gap between business silos
