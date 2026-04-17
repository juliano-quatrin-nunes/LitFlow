---
name: prd-to-tasks
description: Break a PRD into independently-implementable tasks using vertical slices (tracer bullets). Includes effort estimates. Use when a PRD is approved and the user wants to plan the implementation work.
---

# PRD to Tasks

## Philosophy

Tasks are **vertical slices** (tracer bullets). Each task cuts through ALL layers end-to-end — schema, backend, frontend, tests. Never horizontal slices like "write all migrations" or "build all mutations."

A completed task is demoable or verifiable on its own.

**Point scale (effort estimates):**

- 1 point = ~half a day of work
- 2 points = ~a full day of work
- 3 points = ~a day and a half of work

If a task feels bigger than 3 points, split it into smaller tasks.

## Process

### 1. Locate the PRD

Ask the user for the PRD. If it's a GitHub issue, fetch it. If it was produced in a previous conversation, ask the user to paste it or reference it.

Confirm with the user which priority levels are in scope for this round of work (typically all MUSTs, possibly some SHOULDs).

### 2. Explore the codebase (if not already done)

Understand the current state of the code to inform how slices should be cut.

### 3. Draft vertical slices

Break the in-scope PRD items into tracer bullet tasks. Each task should be:

- **Thin**: the narrowest complete path through every layer
- **Complete**: demoable or verifiable on its own
- **Independent where possible**: minimize blocking dependencies between tasks

For each task, determine:

- **Points**: effort estimate using the scale above
- **Type**: HITL (requires human decision/review mid-task) or AFK (can be fully implemented without stopping). Prefer AFK.
- **Blocked by**: which other tasks must complete first
- **User stories covered**: which user stories from the PRD this addresses

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- Never slice horizontally ("all migrations", "all mutations", "all UI")
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each task show:

- **Title**: short descriptive name
- **Points**: effort estimate
- **Type**: HITL / AFK
- **Blocked by**: which other tasks (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Also show the **total points** so the user can see the overall effort.

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the point estimates realistic?
- Are the dependency relationships correct?
- Should any tasks be merged or split further?
- Are the correct tasks marked as HITL and AFK?

Iterate until the user approves.

### 5. Write the task list

For each approved task, write it using the template below. Save the full task list to a local markdown file (e.g. `docs/tasks/<feature-name>.md`).

<task-template>
## Task N: [Title] — N points

**Type:** HITL / AFK
**Blocked by:** Task X, Task Y (or "None — can start immediately")
**User stories:** 3, 7, 12

### What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer steps. Reference specific sections of the parent PRD rather than duplicating content.

### Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
      </task-template>
