## Parent

`docs/prds/liturgical-categories.md`

## What to build

Enable users to assign Liturgical Seasons and Mass Parts to a piece of music directly from the music details page. This involves building a UI (like a modal or an inline Turbo Frame form) to manage these associations and updating the controller to handle the persistence.

## Acceptance criteria

- [ ] The music show page has an "Edit Categories" button in the "Liturgical Context" section.
- [ ] Clicking the button reveals a form (modal or inline) with multi-select inputs or checkboxes for Seasons and Parts.
- [ ] Submitting the form updates the associations for the music without requiring a full page reload or navigating to a separate edit page.
- [ ] The UI immediately reflects the updated categories.
- [ ] System tests verify the successful assignment of categories via the UI.

## Blocked by

- `docs/tasks/liturgical-categories-1-display.md`
