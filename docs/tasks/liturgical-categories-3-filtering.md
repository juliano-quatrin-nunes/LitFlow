## Parent

`docs/prds/liturgical-categories.md`

## What to build

Allow users to discover music by filtering the main repertoire index using the new liturgical categories. This includes adding UI filters to the index page, updating the controller to filter the results (including complex logic for the "Geral" season), and linking the badges on the show page to these filtered views.

## Acceptance criteria

- [ ] The music index page features filter inputs (dropdowns or chips) for `LiturgicalSeason` and `MassPart`.
- [ ] Selecting a filter updates the music list to show only relevant songs.
- [ ] Filtering by a specific season (e.g., "Lent") also includes songs tagged with the "General" (Geral) season.
- [ ] Multiple filters can be combined (e.g., "Easter" AND "Communion").
- [ ] Category badges on the music show page are clickable links that navigate to the music index with the corresponding filter applied.
- [ ] Controller and system tests verify the filtering logic.

## Blocked by

- `docs/tasks/liturgical-categories-1-display.md`
