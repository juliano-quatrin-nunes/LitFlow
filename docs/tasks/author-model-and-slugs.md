# Task List: Author Model and Human-Readable Slugs

## Task 1: Author Model & Data Migration — 2 points

**Type:** AFK
**Blocked by:** None
**User stories:** 1, 4

### What to build
Create the `Repertoire::Author` model and establish a `belongs_to` relationship in `Repertoire::Music`. This includes a database migration to create the `repertoire_authors` table and add `author_id` to `repertoire_musics`. A data migration script must be included to convert existing string-based authors into `Author` records and associate them with their respective musics.

### Acceptance criteria
- [ ] `Repertoire::Author` model created with `name` attribute.
- [ ] `Repertoire::Music` belongs to `Repertoire::Author`.
- [ ] Migration creates the `repertoire_authors` table and adds `author_id` to `repertoire_musics`.
- [ ] Data migration successfully converts all existing `author` strings into `Author` records.
- [ ] `Repertoire::Music#author` string column is removed after successful migration.
- [ ] The `show` and `index` views display the author's name from the associated model.

---

## Task 2: Native Slugging Implementation — 1 point

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 3

### What to build
Implement a native slugging mechanism for both `Author` and `Music` models. This involves adding `slug` columns to both tables and adding `before_validation` hooks to automatically generate parameterized slugs from the `name` (Author) and `title` (Music).

### Acceptance criteria
- [ ] `slug` column added to `repertoire_authors` and `repertoire_musics` with unique indexes.
- [ ] `Author` and `Music` models automatically generate slugs on save using `parameterize`.
- [ ] `to_param` is overridden in both models to return the `slug`.
- [ ] A maintenance task or migration ensures all existing records have valid slugs.

---

## Task 3: Human-Readable Nested Routing — 2 points

**Type:** AFK
**Blocked by:** Task 2
**User stories:** 2, 5

### What to build
Implement the nested, human-readable routing structure for songs. This requires defining a custom route in `routes.rb` and updating the `Repertoire::MusicsController#show` action to look up records using the `author_slug` and `music_slug`. All links in the application must be updated to use the new route helper.

### Acceptance criteria
- [ ] Custom route `get 'musics/:author_slug/:id', to: 'musics#show', as: :author_music` is defined.
- [ ] `Repertoire::MusicsController#show` finds the song using `params[:author_slug]` and `params[:id]` (the music slug).
- [ ] The `Author` name in the `show` view links to a (stubbed or simple) author index showing their songs.
- [ ] All `link_to` and `ui.btn` calls in the UI are updated to use the new `author_music_path` helper.
- [ ] URLs in the browser address bar show the human-readable format (e.g., `/repertoire/musics/padre-jonas-abib/vem-espirito-santo`).
