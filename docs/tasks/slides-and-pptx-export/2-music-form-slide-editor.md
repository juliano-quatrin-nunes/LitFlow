## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

A slide editor inside the existing `Repertoire::Music` form. The user pastes a cifra, clicks "Gerar slides a partir da cifra", reviews and edits the derived slides + sequence inline, then saves the Music together with its `slide_deck` updates. The cifra and slides live on the same page.

Slice 1 already auto-derives slides on Music **create**. This slice adds the user surface to *edit* what was derived and to *regenerate* after cifra changes.

### Form layout (single vertical column)

In order:

1. **Existing cifra textarea** (unchanged) — `content_raw`.
2. **"Gerar slides a partir da cifra"** button — submits to `Repertoire::Musics::SlideDecksController#create`. Server runs `Slides::Extractor` on the current cifra and returns a Turbo Frame populating the editor area. Hidden when `slide_deck.slides_json` is already populated (in which case the editor area is visible directly).
3. **Cifra-changed hint banner** (visible when `SHA1(current content_raw) != slide_deck.slides_generated_from`): "A cifra mudou desde a última geração dos slides. Regenerar?"
4. **Section editor** (hidden until first generation, then always visible):
   - One card per section in document order.
   - Inline `label` text input.
   - `type` dropdown: `intro | verse | chorus | bridge | outro | label`.
   - `lines` textarea (one line per row, auto-sized to content). Each line in the textarea maps to one entry in `lines`.
   - Char-overflow hint chips beside each line exceeding 32 characters: small yellow chip "Esta linha pode quebrar visualmente". Pure UI nudge — no enforcement, no auto-pagination preview.
   - **No add / delete / reorder controls** in the section editor. The set of sections is defined by the cifra. To add a section: edit cifra + click "Regenerar". To remove from rendering: drop the id from the sequence editor below.
5. **"Regenerar slides a partir da cifra"** button: opens a confirmation modal *"Regenerar irá substituir o conteúdo dos slides e redefinir a sequência. Continuar?"*. On confirm: runs `Slides::Extractor` again on the current `content_json`, overwrites both `slides_json` and `slide_sequence` (default sequence — each non-empty section once), updates `slides_generated_from`.
6. **Sequence editor** (collapsible section, collapsed by default):
   - Drag-and-drop chips reusing the existing `sortable` Stimulus controller at `app/javascript/controllers/sortable_controller.js` (used today on `app/views/setlists/show.html.erb:128`).
   - Each chip shows the section's `label` plus a small subscript with its `id`.
   - `+ duplicar` button per chip inserts another copy of that id in-place.
   - Remove via small `x` button on each chip.
   - Empty sequence is a valid state (will produce an empty PPTX in slice 3 — acceptable).
7. **Form submit** persists Music and SlideDeck atomically.

### Editor constraints

| Action | Allowed? | How |
|---|---|---|
| Edit `lines` of a section | ✅ | Inline textarea |
| Edit `label` | ✅ | Inline input |
| Edit `type` | ✅ | Dropdown |
| Add a new section | ❌ | Edit cifra + click "Regenerar" |
| Delete a section | ❌ | Remove its id from `slide_sequence` |
| Reorder sections | ❌ | Reorder via `slide_sequence` only |

### Lifecycle rules

- **Music update with `content_raw` changed:** never auto-regenerate. Only the explicit "Regenerar" action overwrites `slides_json` / `slide_sequence`. The cifra-changed hint banner is the UI nudge.
- **Music update with slide edits:** persist `slides_json` and `slide_sequence` as edited. Do NOT update `slides_generated_from` (it tracks the last *regeneration* hash, not the last *edit* hash).
- **Any mutation of `slides_json` or `slide_sequence`:** clear `slide_deck.pptx_fingerprint` to nil (forces lazy re-render in slice 3). Implement via an `after_save` hook on `SlideDeck` that nils the fingerprint when either jsonb column was changed.

### Controllers and Stimulus

- **`Repertoire::Musics::SlideDecksController`**:
  - `create` — runs the extractor on the unsaved cifra, returns a Turbo Frame containing the section + sequence editors. Does not persist yet.
  - `update` — accepts slide edits (`slides_json` and `slide_sequence`) and persists them. Returns a Turbo Stream confirming save.
  - `regenerate` — equivalent of clicking "Regenerar"; overwrites `slides_json` / `slide_sequence` / `slides_generated_from`.
- Stimulus controllers under `app/javascript/controllers/`:
  - `slide_section_editor_controller.js` — manages a section card, dispatches char-overflow chip toggling on lines > 32 chars on input.
  - Reuse `sortable_controller.js` for the sequence chip list (URL value points to the persistence endpoint; payload shape: `{ slide_sequence: [id, id, ...] }`).
  - `confirm_modal_controller.js` if no equivalent exists; minimal — opens, confirms or cancels.

### Reusable for slice 5

The section editor and sequence editor partials must be reusable from a SetlistItem context in slice 5 (they'll be bound to override fields instead of the SlideDeck's columns). Build the partials accepting an explicit form-builder local so they're not hardcoded to a SlideDeck form.

## Acceptance criteria

- [x] "Gerar slides a partir da cifra" button appears on the Music form when `slide_deck.slides_json` is empty; clicking it populates an inline Turbo Frame with the section + sequence editors.
- [x] When a Music already has slides, the editor area renders directly on form load (no "Gerar" click needed).
- [x] Section editor renders one card per section with `label` / `type` / `lines` editable. Add/delete/reorder controls are absent.
- [x] Char-overflow hint chip appears beside any line exceeding 32 characters; disappears when shortened (live on input).
- [x] Sequence editor is collapsed by default; opens to show drag-and-drop chips; supports `+ duplicar` and remove.
- [x] "Regenerar slides" opens a confirmation modal; on confirm overwrites both `slides_json` and `slide_sequence`, updates `slides_generated_from`.
- [x] Cifra-changed hint banner shows when `SHA1(content_raw) != slides_generated_from`, hidden otherwise.
- [x] Saving the Music form persists slide edits atomically alongside `content_raw`.
- [x] Saving Music with `content_raw` changed but without clicking "Regenerar" leaves `slides_json` untouched (no silent overwrite).
- [x] Any mutation of `slides_json` or `slide_sequence` clears `pptx_fingerprint` to nil (verifiable in tests).
- [x] Controller-level integration tests cover: generate preview, save edits, regenerate flow, attempt to save without regenerate.
- [x] Section editor and sequence editor partials are extracted in a way that allows reuse from a non-SlideDeck context (slice 5 will bind them to SetlistItem overrides).

## Blocked by

- [`1-slide-data-model.md`](./1-slide-data-model.md)

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.

## Status

**Completed** — 2026-05-16.

Files added/changed:

- `app/models/slide_deck.rb` — `after_save` clears `pptx_fingerprint` on `slides_json` / `slide_sequence` mutation; JSON-string-tolerant setters for both jsonb columns.
- `app/models/repertoire/music.rb` — `accepts_nested_attributes_for :slide_deck, update_only: true`.
- `app/controllers/repertoire/musics_controller.rb` — `music_params` permits `slide_deck_attributes`.
- `app/controllers/repertoire/musics/slide_decks_controller.rb` — new: `create` (preview), `update` (save edits), `regenerate` (destructive overwrite).
- `app/views/repertoire/musics/slide_decks/_editor.html.erb` — new (post-save Turbo Frame replacement).
- `app/views/repertoire/musics/slide_decks/_editor_preview.html.erb` — new (preview frame from create).
- `app/views/repertoire/musics/slide_decks/_section_editor.html.erb` — new (reusable; `form:` and `hidden_field_name:` locals).
- `app/views/repertoire/musics/slide_decks/_sequence_editor.html.erb` — new (reusable; same local convention).
- `app/views/repertoire/musics/slide_decks/_form_section.html.erb` — new (rendered inside the music form).
- `app/views/repertoire/musics/slide_decks/_form_actions.html.erb` — new (Gerar/Regenerar buttons, sibling forms outside the music form).
- `app/views/repertoire/musics/slide_decks/{create,update,regenerate}.turbo_stream.erb` — new.
- `app/views/repertoire/musics/_form.html.erb` — renders the slide editor inputs inside the form.
- `app/views/repertoire/musics/edit.html.erb` — renders the slide deck actions next to the form.
- `app/javascript/controllers/slide_section_editor_controller.js` — char-overflow chips on input.
- `app/javascript/controllers/slide_sections_controller.js` — serializes section UI into the hidden `slides_json` field.
- `app/javascript/controllers/slide_sequence_editor_controller.js` — duplicate, remove, serialize sequence into the hidden field.
- `app/javascript/controllers/confirm_modal_controller.js` — confirm dialog for the regenerate button.
- `config/routes.rb` — `POST/PATCH /repertoire/musics/:author_slug/:id/slide_deck` and `POST .../slide_deck/regenerate`.
- `test/fixtures/slide_decks.yml` — new (polymorphic fixture for the two music fixtures).
- `test/models/slide_deck_test.rb` — 3 new tests covering the fingerprint-clearing hook.
- `test/controllers/repertoire/musics/slide_decks_controller_test.rb` — new (create preview, update edits, regenerate).
- `test/controllers/repertoire/musics_controller_test.rb` — 5 new tests covering edit-page rendering, banner visibility, atomic save, and no-silent-overwrite.
- `test/lib/tasks/repertoire_slides_backfill_test.rb` — adjusted setup now that `slide_decks` fixture exists.

Key verification output:

- `bin/rails test` — `127 runs, 387 assertions, 0 failures, 0 errors, 0 skips`.
- Targeted: `bin/rails test test/controllers/repertoire/musics/slide_decks_controller_test.rb` — 3 runs, 14 assertions; `bin/rails test test/controllers/repertoire/musics_controller_test.rb` — 19 runs, 71 assertions; `bin/rails test test/models/slide_deck_test.rb` — 7 runs, 15 assertions.

Notes:

- Editor partials accept `form:` (auto-derives the hidden field name from the parent form's `object_name`) and `hidden_field_name:` (explicit override for slice 5's SetlistItem context).
- The "Gerar" / "Regenerar" buttons are sibling forms to the music form (not nested) to keep the HTML valid.
- `accepts_nested_attributes_for :slide_deck, update_only: true` + JSON-string setters on `SlideDeck` let the music form submit `slides_json` and `slide_sequence` as JSON-encoded hidden fields without bespoke controller deserialization.
