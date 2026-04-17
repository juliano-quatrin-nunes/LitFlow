---
name: implement-task
description: Implement a vertical slice from tasks with pragmatic testing and iterative refinement. Optimized for Rails full-stack development.
---

# Implement Task

## Philosophy

Tasks are **vertical slices** — complete, end-to-end features that cut through all layers:

- domain
- persistence
- controller
- view
- interaction (if needed)

The goal is to **deliver working behavior quickly**, then refine.

Testing is **pragmatic**, not dogmatic:

- test what is complex or critical
- avoid testing trivial Rails glue
- prioritize domain logic and transformations

Prefer **clarity and progress over perfection**.

---

## Workflow

### 0. Understand the task

Before writing code:

- Read the task description and acceptance criteria
- Identify which bounded context this belongs to
- Identify the core behavior being delivered
- Confirm what “done” looks like from a user perspective

Ask:

> What is the smallest version of this that works end-to-end?

---

### 1. Explore the codebase

- Identify similar features or patterns
- Reuse existing approaches when possible
- Follow naming and structural conventions already in use

Avoid introducing new patterns unless necessary.

---

### 2. Define the slice

Clarify:

- What data is needed?
- What user action triggers this?
- What is rendered in the UI?
- What is persisted?

Keep the slice **thin but complete**.

Avoid:

- building abstractions for future use
- implementing multiple variations at once

---

### 3. Implement end-to-end

Build the feature across all necessary layers:

- domain/model (if needed)
- persistence (migration if needed)
- controller/action
- view (ERB/Herb)
- minimal interaction (Stimulus if needed)

Guidelines:

- prefer simple Rails conventions
- keep controllers thin
- keep views readable
- avoid premature presenters unless formatting is complex

---

### 4. Verify behavior manually

Before writing tests:

- run the feature locally
- validate acceptance criteria
- check edge cases manually

Examples:

- form submission works
- data persists correctly
- UI updates correctly
- flow makes sense

---

### 5. Add pragmatic tests

Add tests **only where they provide value**.

### MUST test:

- domain logic
- data transformations (e.g. chord formatting, slide generation)
- non-trivial business rules

### SHOULD test:

- critical flows (happy path integration)

### SKIP or defer:

- trivial CRUD
- simple controllers
- basic rendering

Test guidelines:

- test through public interfaces
- avoid mocking internal implementation
- tests should survive refactors

---

### 6. Refine

After the slice works:

- extract presenters if view logic becomes complex
- extract helpers for small reusable logic
- simplify code paths
- remove duplication

Do not over-refactor early.

---

### 7. Run quality checks

Before finishing:

```bash
bin/rails test
bin/rubocop
bin/brakeman
bundle exec herb format --check .
bundle exec herb lint .
```
