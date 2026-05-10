# Task List: Musical Repertoire Transposition

## Task 1: Core Transposition Logic (Service & Unit Tests) — 2 points

**Type:** AFK
**Blocked by:** None
**User stories:** 5, 6, 7

### What to build
Implement the `Repertoire::TranspositionService` to handle the mathematical and musical logic of changing a song's key. This service must process the `content_json` structure, identifying and transposing every chord (including root, suffix, and bass notes) while maintaining the original lyric alignment. It should also include intelligent enharmonic selection (e.g., choosing Bb over A# in the key of F) based on the target key.

### Acceptance criteria
- [ ] `Repertoire::TranspositionService.call(content_json, from_key, to_key)` returns a new `content_json` with transposed chords.
- [ ] Handles simple chords (C, G, D) and complex suffixes (maj7, dim7, add9, etc.).
- [ ] Handles bass notes (e.g., G/B transposes to A/C# when moving +2 semitones).
- [ ] Correctly chooses between sharps and flats based on the target key's musical context.
- [ ] Unit tests cover various intervals, boundary cases (B to C), and all enharmonic variations.

---

## Task 2: Controller & Dynamic View (Turbo Frame Integration) — 1 point

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 1, 5

### What to build
Update the `Repertoire::MusicsController` and the `show` view to support dynamic transposition via Turbo Frames. The controller should accept a `key` parameter and use the `TranspositionService` to provide the view with transposed data. The view must be wrapped in a Turbo Frame so that changing the key doesn't require a full page refresh.

### Acceptance criteria
- [ ] `Repertoire::MusicsController#show` detects `params[:key]` and transposes the music if it differs from the original.
- [ ] The music display area in `app/views/repertoire/musics/show.html.erb` is wrapped in a `<turbo-frame id="music_display">`.
- [ ] Visiting the show page with a `?key=G` parameter correctly renders the song in G major.
- [ ] Integration tests verify that the `key` parameter successfully alters the rendered chords in the HTML response.

---

## Task 3: Transposition UI Controls (Popover & Buttons) — 1 point

**Type:** AFK
**Blocked by:** Task 2
**User stories:** 1, 2, 3, 4

### What to build
Add the user interface elements for transposition to the `show` page. This includes "Higher" and "Lower" buttons for step-by-step transposition and a Popover containing a grid of all 12 chromatic keys for direct selection. These controls should be part of the Turbo Frame to ensure seamless interaction.

### Acceptance criteria
- [ ] "Higher" and "Lower" buttons correctly link to the next/previous semitone relative to the currently viewed key.
- [ ] A "Key Selector" (using JR UI Popover) displays a grid of 12 keys (C, Db, D, Eb, E, F, F#, G, Ab, A, Bb, B).
- [ ] Clicking any control updates the song content via Turbo without a full page reload.
- [ ] The current viewing key is clearly indicated in the UI.
- [ ] The layout remains responsive and aligned with existing `JR UI` patterns.
