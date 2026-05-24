## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

Per-celebration customization of slides. A `SetlistItem` can optionally override the underlying slideable's `slides_json` and/or `slide_sequence`. When the override is null, edits to the underlying Music propagate visibly to the setlist (no copies, no snapshots). When the override is set, that celebration's slides are independent. Orphaned section id references after a Music regeneration are render-skipped and surfaced as a warning chip on the Setlist page.

### Schema

Add to `setlist_items`:

- `slides_json_override :jsonb` — nullable, default null.
- `slide_sequence_override :jsonb` — nullable, default null.

Null = inherit from the slideable's SlideDeck. Non-null = override.

### Resolution helpers on SetlistItem

```ruby
def effective_slides_json
  slides_json_override.presence || item.slide_deck.slides_json
end

def effective_slide_sequence
  slide_sequence_override.presence || item.slide_deck.slide_sequence
end
```

`slice 6` consumes these helpers when composing the setlist PPTX.

### Override editor UI

Extend the existing `SetlistItem` edit view (the same view that today exposes `key` transposition). Add a "Personalizar slides" section with two collapsible toggles:

1. **"Personalizar conteúdo dos slides"** — when toggled on for the first time, populate `slides_json_override` with a deep copy of `item.slide_deck.slides_json`. Renders the same section editor partial from slice 2 (`label` / `type` / `lines` per section, char-overflow chips, no add/delete/reorder). When toggled off, prompt: *"Suas customizações serão perdidas. Continuar?"*. On confirm, set `slides_json_override = nil`.
2. **"Personalizar sequência"** — when toggled on for the first time, populate `slide_sequence_override` with a deep copy of `item.slide_deck.slide_sequence`. Renders the same sequence editor partial from slice 2 (drag-and-drop chips, `+ duplicar`, remove). When toggled off, prompt and set `slide_sequence_override = nil`.

The override editor is collapsed by default — most setlist items won't customize.

### Cache invalidation

- Any change to `slides_json_override` or `slide_sequence_override` clears `setlist.pptx_fingerprint` (so slice 6's job re-renders).
- Any change to an underlying Music's `slide_deck.slides_json` or `slide_sequence` clears `pptx_fingerprint` on every Setlist containing a SetlistItem pointing at that Music. Implement via an after-commit hook on `SlideDeck` that touches affected `setlists.pptx_fingerprint` (slice 6 wires this column; this slice only needs to be aware of the dependency).

### Orphaned id detection

When a Music's slides are regenerated (slice 2), section ids may shift (`verse_2` now points to what was `verse_3`). A SetlistItem's `slide_sequence_override` may reference ids that no longer exist in `effective_slides_json`.

- **At render time** (slice 6): orphaned ids are silently skipped — the corresponding slides simply don't appear in the output.
- **In the UI** (this slice): the Setlist page surfaces a warning chip *"Alguns slides precisam de revisão"* with a count and a link to the affected items.

Detection helper on Setlist:

```ruby
def items_with_orphaned_sequence_ids
  items.select { |item|
    available_ids = item.effective_slides_json.map { |s| s["id"] }
    (item.effective_slide_sequence - available_ids).any?
  }
end
```

The warning chip on `Setlist#show` shows when `items_with_orphaned_sequence_ids.any?`, displays the count, and links to each affected item's edit page (where the override editor exposes the broken references).

### Surface and propagation

- **Music slides edited (override null):** `effective_slides_json` immediately reflects the change. No snapshot, no sync. Verifiable in console: edit `music.slide_deck`, reload `setlist_item`, `effective_slides_json` shows new content.
- **Music slides edited (override set):** the override is untouched. The celebration's slides are independent.
- **Override cleared (toggle off):** the item falls back to the Music's current state on next read.

### Reusing slice 2 partials

The section editor and sequence editor partials from slice 2 must be parameterized so they bind to override fields (`slides_json_override` / `slide_sequence_override`) instead of `slide_deck.slides_json` / `slide_deck.slide_sequence`. The partials accept an explicit form-builder local and the bound attribute names. Slice 2's acceptance criteria require this parameterization to be in place.

## Acceptance criteria

- [x] `setlist_items.slides_json_override` and `setlist_items.slide_sequence_override` columns exist, both nullable jsonb.
- [x] `SetlistItem#effective_slides_json` and `#effective_slide_sequence` fall through to `item.slide_deck` when the corresponding override is null; return the override when non-null.
- [x] SetlistItem edit view exposes collapsible "Personalizar conteúdo dos slides" and "Personalizar sequência" toggles.
- [x] Toggling each override on for the first time populates the override with a deep copy of the current effective value.
- [x] Toggling each override off prompts for confirmation and sets the column back to null on confirm.
- [x] Editing the override uses the same section editor / sequence editor partials from slice 2, bound to the override fields.
- [x] Editing a Music's slides immediately changes `effective_slides_json` for setlist items with null `slides_json_override` (verifiable in console / model spec).
- [x] Editing a Music's slides does NOT change `effective_slides_json` for setlist items with non-null `slides_json_override`.
- [x] Any change to `slides_json_override` or `slide_sequence_override` clears the Setlist's `pptx_fingerprint` (column added in this slice; SetlistItem after_save clears parent).
- [x] `Setlist#items_with_orphaned_sequence_ids` returns the correct items in: no orphans, one orphan, all orphans.
- [x] `Setlist#show` displays a warning chip *"Alguns slides precisam de revisão"* with a count and links to affected items when orphans exist; chip is hidden otherwise.

## Blocked by

- [`2-music-form-slide-editor.md`](./2-music-form-slide-editor.md) — reuses its section + sequence editor partials.
- [`4-setlist-item-polymorphism.md`](./4-setlist-item-polymorphism.md) — needs the polymorphic SetlistItem.

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.

## Status

- Completed: 2026-05-17
- Files added:
  - `db/migrate/20260517073158_add_slide_overrides_to_setlist_items.rb`
  - `db/migrate/20260517073334_add_pptx_fingerprint_to_setlists.rb` (column added here to support cache invalidation; slice 6 wires the attachment + composer)
  - `app/views/setlist_items/edit.html.erb`
- Files changed:
  - `app/models/setlist_item.rb` — added `effective_slides_json` / `effective_slide_sequence` helpers; after_save/after_destroy hooks clear the parent Setlist's `pptx_fingerprint` on override or item-set changes.
  - `app/models/setlist.rb` — added `items_with_orphaned_sequence_ids`.
  - `app/models/slide_deck.rb` — added after-commit hook that nulls `pptx_fingerprint` on every Setlist with a SetlistItem pointing at this slideable when `slides_json` or `slide_sequence` changes.
  - `app/controllers/setlist_items_controller.rb` — added `edit` action and `resolve_override_changes` to translate the "personalize" toggles into deep-copied or nullified overrides on update.
  - `app/views/setlists/show.html.erb` — added warning chip with count and links to affected items when `items_with_orphaned_sequence_ids.any?`.
  - `config/routes.rb` — `setlist_items` now exposes `:edit`.
- Reuse: edit view renders the existing `repertoire/musics/slide_decks/_section_editor` and `_sequence_editor` partials with `hidden_field_name:` bound to `setlist_item[slides_json_override]` / `setlist_item[slide_sequence_override]`.
- Test totals: 177 runs, 512 assertions, 0 failures, 0 errors, 0 skips.
