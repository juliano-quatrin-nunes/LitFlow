# Product Requirements Document: Musical Repertoire Setup

## Problem Statement
Musicians and liturgy planners need a central repertoire to store and retrieve songs. They need to easily input songs (usually copied from sources where chords are printed above lyrics) and the system needs to store this in a structured way that allows rendering chord sheets for musicians (with chords and lyrics), projection slides (lyrics only), and eventually transposing to different keys.

## Solution
Create the `Repertoire` bounded context. Implement a `Repertoire::Music` model that stores the raw ChordPro-style string and a parsed JSON structure. Build a service layer (`Repertoire::MusicParserService`) that takes pasted plain-text (chords over lyrics), converts it to the ChordPro format (`content_raw`), and generates the structured JSON cache (`content_json`). This allows fast rendering and easy extraction of just lyrics for projection. Use standard Rails namespaces for the domain isolation.

## User Stories
1. **[MUST]** As a user, I want to create a new Music entry with a title, author, and original tonality.
2. **[MUST]** As a user, I want to paste song lyrics with chords written on the line above the lyrics.
3. **[MUST]** As the system, I want to parse the pasted text to interleave the chords into the lyrics using bracket notation (e.g., `[E]Vem`) and save it as `content_raw`.
4. **[MUST]** As the system, I want to generate and save a JSON representation (`content_json`) of the song for fast rendering, splitting lines into fragments of `{ lyric: "...", chord: "..." }`.
5. **[MUST]** As a user, I want to view the full song with chords and lyrics properly aligned (using the JSON data).
6. **[MUST]** As a user, I want to view the song's lyrics without chords (for projection purposes, using the JSON data to exclude chord parts).
7. **[COULD]** As a user, I want to edit the `content_raw` directly using the bracket notation if the parser makes a mistake.
8. **[COULD]** As a user, I want to transpose the song to a different key when viewing. (Noted as a future requirement, but architecture must support it).

## Implementation Decisions
- **Namespacing:** All code for this domain will live under the `Repertoire` namespace (`app/models/repertoire`, `app/controllers/repertoire`, `app/services/repertoire`).
- **Models:**
  - `Repertoire::Music`:
    - Columns: `title` (string), `author` (string), `original_key` (string), `content_raw` (text), `content_json` (jsonb).
- **Services:**
  - `Repertoire::MusicParserService`:
    - Interface: `.call(text)` returns `{ raw: "[E]...", json: [...] }`.
    - Detects if input is already ChordPro format or "chords over lyrics" format.
    - Handles parsing text into the JSON array structure.
- **Views:**
  - Simple views for standard CRUD operations.
  - "Show" view will display the formatted chord sheet using `content_json`.
  - Provide a toggle or separate tab to view "Lyrics Only" (projection mode) using `content_json`.

## Testing Decisions
- Focus heavily on testing `Repertoire::MusicParserService`. It has complex pure logic and is deeply testable in isolation.
- Test cases must include:
  - Perfect chords-over-lyrics inputs.
  - Inputs with trailing spaces or misaligned chords.
  - Lines with only chords, or only lyrics.
  - Inputs that are already in `[Chord]Lyric` format.
- `Repertoire::Music` model should be tested for validations and successful saving of the json payload.

## Out of Scope
- Complex UI editors (e.g., drag and drop chord editing).
- Actual transposition implementation (will be handled in a separate PRD/task).
- Generating PDF files.
