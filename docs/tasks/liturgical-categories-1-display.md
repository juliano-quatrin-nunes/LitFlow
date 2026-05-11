## Parent

`docs/prds/liturgical-categories.md`

## What to build

Create the foundational data structures for liturgical categorization and display them on the music details page. This includes the taxonomy models, association join tables, initial seed data for standard Catholic seasons and mass parts, and a read-only "Liturgical Context" section on the music show page.

## Acceptance criteria

- [ ] `Repertoire::LiturgicalSeason` and `Repertoire::MassPart` models exist.
- [ ] `Repertoire::MusicLiturgicalSeason` and `Repertoire::MusicMassPart` join models exist.
- [ ] Initial data for Seasons (Tempo Comum, Advento, Quaresma, etc.) and Parts (Entrada, Ato Penitencial, etc.) is populated via a migration or seeds.
- [ ] The `Repertoire::Music` show page displays a "Liturgical Context" section listing the associated seasons and parts.
- [ ] Associations can be tested via rails console (i.e., assigning a season to a music record makes it appear on the show page).

## Blocked by

- None - can start immediately
