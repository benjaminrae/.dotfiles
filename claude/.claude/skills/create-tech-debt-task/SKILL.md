---
name: create-tech-debt-task
description: Use when creating tech debt tasks for SitesDB or SubjectsDB. Automatically links to the tech debt epic EP-928.
---

# Create Tech Debt Task

Quickly create a tech debt task in the SD (Sites DB) project, automatically linked to **EP-928** (Tech Debt - SubjectsDB and SitesDB).

## Required Information

| Field | Required | Default |
|-------|----------|---------|
| Summary | Yes | - |
| Description | No | - |
| Project Key | No | "SD" |

## Process

**REQUIRED SKILL:** Use `create-jira-task` with these defaults:
- `epicKey`: EP-928
- `projectKey`: SD (unless user specifies SDB for SubjectsDB)
- `issueType`: Task

## Example

User: "Add a tech debt task to fix the response codes"

Create using `create-jira-task` with:
- summary: "Fix response codes"
- projectKey: "SD"
- parent: "EP-928"

## When Epic EP-928 Closes

Update this skill with the new tech debt epic key.