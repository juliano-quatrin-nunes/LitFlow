# Task List: Musical Repertoire Setup

## Task 1: Basic Music Model & CRUD — 2 points

**Type:** AFK
**Blocked by:** None
**User stories:** 1

### What to build
Scaffold the base `Repertoire::Music` domain. This includes the database migration for `title`, `author`, `original_key`, `content_raw`, and `content_json`. Implement a namespaced controller `Repertoire::MusicsController` and basic views (index, new, show) using Tailwind CSS.

### Acceptance criteria
- [x] Migration creates `repertoire_musics` table with required columns.
- [x] `Repertoire::Music` model exists with basic validations (presence of title).
- [x] Users can create a music entry with title, author, and original key.
- [x] Namespaced routing works: `/repertoire/musics`.
- [x] Views follow the project's Tailwind styling.

---

## Task 2: Music Parser Service — 3 points

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 3, 4

### What to build
Implement `Repertoire::MusicParserService` to handle the conversion of plain text (chords above lyrics) into both ChordPro format and the structured JSON format described in the PRD. This service is the "brain" of the domain and must be robustly tested.

### Acceptance criteria
- [x] Service correctly identifies lines containing chords vs lines containing lyrics.
- [x] Service interleaves chords into lyrics: `[Chord]Lyric`.
- [x] Service produces a JSON array of lines, where each line is an array of fragments `{ chord: "...", lyric: "..." }`.
- [x] Exhaustive test suite covering:
    - Standard chord-over-lyric input.
    - Input with only chords or only lyrics.
    - Multiple chords per word.
    - Trailing/leading spaces.
    - Already-parsed ChordPro input.

---

## Task 3: Integrated Parsing Flow — 2 points

**Type:** AFK
**Blocked by:** Task 2
**User stories:** 2

### What to build
Enhance the Music creation and editing flow. Add a "Paste Content" textarea to the form. Before saving, the controller (or a callback) uses `Repertoire::MusicParserService` to populate `content_raw` and `content_json`.

### Acceptance criteria
- [x] The "New Music" form has a field for pasting the raw song.
- [x] Saving a song triggers the parser.
- [x] `content_raw` and `content_json` are correctly persisted in the database.
- [x] Errors from the parser service (if any) are handled and displayed to the user.

---

## Task 4: Formatted Rendering (Chord Sheet & Projection) — 2 points

**Type:** AFK
**Blocked by:** Task 3
**User stories:** 5, 6

### What to build
Build the "Show" view for a music entry. Use the `content_json` to render two modes:
1. **Musician Mode:** Chords displayed inline or above lyrics, perfectly aligned.
2. **Projection Mode:** Lyrics only, stripped of all chords, formatted for a slide.
Add a simple UI toggle (e.g., Stimulus-powered or simple tabs) to switch between modes.

### Acceptance criteria
- [x] "Show" view renders the song using data from `content_json`.
- [x] Chords are styled differently (e.g., bold, different color) to stand out.
- [x] "Projection" mode successfully hides all chords and maintains line structure.
- [x] Toggle between modes works instantly without full page reload (if using Stimulus) or via clean Rails navigation.
