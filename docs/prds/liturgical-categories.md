# Design: Liturgical Categorization
Date: 2026-05-10

## Summary
Introduce the ability to categorize music by Liturgical Seasons (e.g., Lent, Easter) and Mass Parts (e.g., Offertory, Communion). This allows users to organize their repertoire for liturgical planning and easily discover suitable songs for specific moments in the mass.

## Problem Statement

Users currently have a library of music (`Repertoire::Music`) but no structured way to identify which songs are appropriate for specific parts of the Catholic mass or for particular liturgical seasons. This makes building a mass repertoire difficult and relies entirely on the user's memory or external notes.

## Solution

Implement two new taxonomies: `LiturgicalSeason` and `MassPart`. Allow users to associate music with these taxonomies via a dedicated UI on the music show page. Enhance the main music index to allow filtering by these new categories, enabling queries like "Show me all Offertory songs for Lent."

## User Stories

1. As a musician, I want to see the associated Liturgical Seasons and Mass Parts for a given song on its details page, so that I know when it is appropriate to play.
2. As a musician, I want to add or remove Liturgical Seasons from a song directly from its details page (via a modal or inline UI), so that I can keep my library organized without leaving the view.
3. As a musician, I want to add or remove Mass Parts from a song directly from its details page, so that I can categorize its liturgical function easily.
4. As a musician, I want to filter the main music list by Liturgical Season, so that I can find songs suitable for the current time of year (e.g., Advent).
5. As a musician, I want to filter the main music list by Mass Part, so that I can find a specific type of song (e.g., Entrance song).
6. As a musician, I want to combine filters (e.g., "Season: Easter" AND "Part: Communion"), so that I can pinpoint the exact songs I need for a specific slot in my mass repertoire.
7. As a musician, when I filter by a specific season, I want to also see songs categorized as "General" (Geral), so that I don't miss versatile songs that are always appropriate.
8. As a musician, I want to click a category badge on a song's details page and be redirected to the music index with that filter applied, so that I can find similar songs quickly.

## Implementation Decisions

- **Taxonomy Models:** 
  - Create `Repertoire::LiturgicalSeason` (name, slug, color).
  - Create `Repertoire::MassPart` (name, slug, position).
- **Association Models:**
  - Create `Repertoire::MusicLiturgicalSeason` (music_id, liturgical_season_id).
  - Create `Repertoire::MusicMassPart` (music_id, mass_part_id).
- **Data Initialization (Seeds/Migrations):**
  - **Seasons:** Tempo Comum, Advento, Quaresma, Tempo Pascal, Natal, Geral.
  - **Mass Parts:** Entrada, Ato Penitencial, Hino de Louvor, Salmo, Aclamação, Ofertório, Santo, Cordeiro, Comunhão, Pós-Comunhão, Saída, Outros/Devocional.
- **UI Modifications:**
  - **Music Show Page (`app/views/repertoire/musics/show.html.erb`):** Add a "Liturgical Context" section displaying badges for Seasons and Parts. Add an "Edit Categories" button that opens a modal (or inline form) to manage associations using checkboxes or multi-select inputs.
  - **Music Index Page (`app/views/repertoire/musics/index.html.erb`):** Add dropdown filters or chip filters for `LiturgicalSeason` and `MassPart`. Update the controller to handle these parameters.
  - **Category Links:** Badges on the show page will be simple links back to the index page with the corresponding query parameter (e.g., `/repertoire/musics?season=quaresma`).
- **"General" Handling:** The "Geral" season will be an explicit record. The controller filter logic needs to handle this (e.g., filtering by "Quaresma" should query for `liturgical_season_id IN (id_for_quaresma, id_for_geral)`).

## Testing Decisions

- **What makes a good test:** Tests should verify that the correct music is returned when filtering and that the associations can be successfully updated through the UI/controllers.
- **Modules to be tested:**
  - `Repertoire::Music` model (associations).
  - `Repertoire::MusicsController` (filtering logic, including the "General" season rule).
  - System test for updating categories on the music show page via the modal/form.
  - System test for filtering the index page.
- **Prior art:** Check existing system tests and controller tests in `test/controllers/repertoire/` and `test/integration/repertoire/` for conventions on how filtering or form submissions are tested.

## Out of Scope

- A dedicated "Liturgy Planner" or "Repertoire Builder" view (this will be a separate, future feature).
- Dedicated summary/detail pages for individual Seasons or Mass Parts (e.g., `/seasons/advent`).
- Allowing end-users to create, edit, or delete the base Liturgical Seasons or Mass Parts via the UI (these remain managed via seeds/migrations for now).

## Further Notes

- The `position` column on `MassPart` is critical to ensure dropdowns and lists are ordered liturgically (Entrance -> ... -> Exit), not alphabetically.
