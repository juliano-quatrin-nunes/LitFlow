## Problem Statement

Musicians often need to transpose a song from its original key to a better fit for the singer or the available instruments. Currently, the system only displays the song in its original key, forcing musicians to transpose mentally, which can lead to errors during performance.

## Solution

Implement a comprehensive transposition system within the `Repertoire` domain. This system will allow users to dynamically change the key of a song on the `show` page.

The solution consists of:
1.  **Backend:** A robust `Repertoire::TranspositionService` to handle chord transposition logic, including support for complex chords, bass notes, and intelligent enharmonic selection based on the target key.
2.  **Frontend:** An interactive UI component using Hotwire (Turbo Frames) to update the song content without a full page reload. The UI will feature a key selector popover and buttons for incremental transposition (higher/lower).

## User Stories

1.  **[MUST]** As a musician, I want to see the current key of the song displayed clearly.
2.  **[MUST]** As a musician, I want to click a "Higher" button to raise the song's key by one semitone.
3.  **[MUST]** As a musician, I want to click a "Lower" button to lower the song's key by one semitone.
4.  **[MUST]** As a musician, I want to select a specific key from a list (Popover) to transpose the song directly to that key.
5.  **[MUST]** As a musician, I want the lyrics to remain unchanged while the chords are transposed correctly.
6.  **[MUST]** As a musician, I want the system to handle complex chords (e.g., `Am7`, `G/B`, `F#m7(b5)`) correctly during transposition.
7.  **[SHOULD]** As a musician, I want the system to choose the correct enharmonic representation (e.g., `Bb` instead of `A#` when transposing to `F major`) to follow musical conventions.

## Implementation Decisions

### 1. Transposition Service (`Repertoire::TranspositionService`)
-   **Input:** `content_json` (the structured song data), `from_key` (original or current), and `to_key` (target).
-   **Logic:**
    -   Calculate the semitone offset between `from_key` and `to_key`.
    -   Iterate through the `content_json` fragments.
    -   For each `chord` fragment, identify the root note, suffix, and optional bass note.
    -   Transpose the root and bass notes by the calculated offset.
    -   Apply an enharmonic mapping based on the `to_key` (e.g., target keys with flats should result in flat chords where ambiguous).
-   **Enharmonic Mapping:**
    -   Define sets of "Sharp Keys" (G, D, A, E, B, F#) and "Flat Keys" (F, Bb, Eb, Ab, Db, Gb).
    -   Default to a neutral representation (preferring sharps for everything else, or standard convention).

### 2. Controller & Routing
-   **`Repertoire::MusicsController#show`:**
    -   Accept an optional `key` parameter.
    -   If `params[:key]` is present, invoke `Repertoire::TranspositionService.call` on the music's `content_json`.
    -   Expose the transposed content to the view.
    -   The `original_key` remains the source of truth for the base key.

### 3. Frontend (UI/UX)
-   **Turbo Frame:** Wrap the entire music display (including the controls) in a `<turbo-frame id="music_display">`.
-   **Controls:**
    -   Use `JR UI` components: `btn` for buttons, `popover` for the key selector.
    -   **Lower Button:** Links to `repertoire_music_path(@music, key: previous_key)`.
    -   **Key Popover:** Contains a grid of 12 keys (C, Db, D, Eb, E, F, F#, G, Ab, A, Bb, B). Each key links to `repertoire_music_path(@music, key: selected_key)`.
    -   **Higher Button:** Links to `repertoire_music_path(@music, key: next_key)`.
-   **Transitions:** The Turbo Frame will handle the asynchronous update of the chord sheet.

## Testing Decisions

### Unit Tests (`test/services/repertoire/transposition_service_test.rb`)
-   **Simple Transposition:** Verify `C -> D` (+2 semitones).
-   **Complex Chords:** Verify `Am7 -> Bm7` (+2 semitones).
-   **Bass Notes:** Verify `G/B -> A/C#` (+2 semitones).
-   **Enharmonics:** Verify `C -> F` result includes `Bb` if present (e.g., if the song had a flattened 7th).
-   **Full Structure:** Verify the entire `content_json` array is processed correctly.
-   **Boundary Cases:** Transposing up from `B` to `C`, down from `C` to `B`.

### Integration Tests (`test/controllers/repertoire/musics_controller_test.rb`)
-   Verify that providing a `key` parameter results in the correct transposed chords appearing in the response HTML.
-   Ensure the "original key" is used as the default if no parameter is provided.

## Out of Scope
-   Persisting the transposed key in the `repertoire_musics` table (it should be ephemeral/contextual).
-   Transposing to/from Nashville Number System or Roman Numerals.
-   Support for Capo position display (future feature).
-   Interactive chord editing within the transposed view.

## Further Notes
-   The list of 12 keys in the popover should be: `C, Db, D, Eb, E, F, F#, G, Ab, A, Bb, B`.
-   If the `original_key` is minor (e.g., `Am`), the popover should still show the 12 chromatic roots, and the logic should preserve the "m" suffix on chords.
