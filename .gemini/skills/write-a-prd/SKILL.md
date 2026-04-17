---
name: write-a-prd
description: Create a Product Requirements Document through relentless interviewing. Use when the user wants to spec a feature, scope work, or formalize what to build. Covers prioritization and scoping — no separate MoSCoW needed.
---

# Product Requirements Document

## Philosophy

A PRD answers **"what exactly are we building, and what are we not?"**. It combines discovery, scoping, and specification in one flow. Prioritization happens naturally during the interview — you don't need a separate artifact to decide what's in and what's out.

## Process

### 1. Understand the problem

Ask the user for a description of the problem they want to solve and any ideas for solutions. Accept whatever level of detail they give.

### 2. Explore the codebase

Read relevant code to understand:

- Existing models, services, and patterns that relate to the feature
- What infrastructure already exists that can be reused
- Naming conventions and architectural patterns in use

### 3. Interview relentlessly

Interview the user about every aspect of this plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Cover both **scoping** and **implementation**:

**Scoping (what and why):**

- What problem does this solve from the user's perspective?
- What are the must-haves vs nice-to-haves? Challenge every "must" — why can't it be deferred?
- What's explicitly out of scope? (Be aggressive here — a clear "won't" list prevents scope creep later)
- Are there product decisions that need to be made before implementation?

**Implementation (how):**

- What do the public APIs / mutations / queries look like?
- Where does new code live? What existing modules get modified?
- Schema details: column types, constraints, indexes
- Edge cases and error states
- Testing strategy: which behaviors get tested, what's the prior art in the codebase?

Identify opportunities for deep modules — small interface, deep implementation, testable in isolation.

### 4. Write the PRD

Use the template below. The PRD should be thorough enough that a developer can implement from it without further product questions.

### 5. Review with user

Present the PRD and iterate until approved. Then save it on `docs/prds/<prd-name>.md` or user-preferred location.

<prd-template>
## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

This list should be extremely extensive and cover all aspects of the feature. Mark each story with a priority:

- **[MUST]** — the feature doesn't work without this
- **[SHOULD]** — significantly enhances the feature but can ship without it
- **[COULD]** — nice to have, defer if time is tight

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

An explicit list of things this PRD does NOT cover. For each item, include a brief rationale for why it's excluded. This section is critical for preventing scope creep during implementation.

## Further Notes

Any further notes about the feature.

</prd-template>
