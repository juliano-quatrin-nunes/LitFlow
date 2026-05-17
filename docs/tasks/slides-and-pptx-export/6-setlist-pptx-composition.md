## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

Per-setlist PPTX generation. A "Baixar PPTX da celebração" button on the Setlist page produces one `.pptx` covering every `SetlistItem` in `position` order, with a blank black transition slide at the deck start, between every item, and at the deck end. Reuses the cache-and-toast pattern from slice 3.

This slice completes v1.1: by the end, a celebration planner can hand the projectionist a single PPTX file for the entire mass.

### Schema

Add to `setlists`:

- `has_one_attached :pptx`.
- `pptx_fingerprint :string` (nullable).

### Composition logic

Build a service `Slides::SetlistComposer` (or compose inline in the job — pick whichever reads cleanly; the logic is small):

```
[ blank ]                                     # deck-start transition
[ item 1 physical slides ... ]                # using effective_slides_json / effective_slide_sequence
[ blank ]                                     # inter-item transition
[ item 2 physical slides ... ]
[ blank ]
...
[ item N physical slides ... ]
[ blank ]                                     # deck-end transition
```

- A "blank" slide is `{ "type": "blank", "lines": [] }` in the renderer payload. The Python renderer from slice 3 already treats empty `lines` as a fully black slide; this slice just ensures the composer emits these entries.
- For each item, walk `effective_slide_sequence`, look up each id in `effective_slides_json`, run `Slides::Paginator` on the section's lines, flatten the resulting physical slides into the deck. Carry the section's `type` so the renderer knows whether to bold (chorus → bold).
- **Orphaned sequence ids** (id present in `effective_slide_sequence` but absent from `effective_slides_json`) are silently skipped. Slice 5 already surfaces the warning chip on Setlist#show, so the user has visibility.
- Items are processed in `position` order (the existing setlist ordering — already wired via the `sortable` controller).

### Per-setlist fingerprint

`Slides::Fingerprint.for_setlist(setlist) → sha1_string`:

Canonical inputs:
- For each item, in `position` order: `[item_type, item_id, position, mass_part_id, effective_slides_json, effective_slide_sequence]`.
- `Slides::Theme::VERSION`.

A Music edit upstream changes the setlist fingerprint via `effective_*` even when overrides are null. This is the propagation mechanism: editing a Music's slides invalidates every Setlist's `pptx_fingerprint` if their items inherit (override null). Implemented via an `after_commit` hook on `SlideDeck` that touches `pptx_fingerprint = nil` on every Setlist with a SetlistItem pointing at the slideable.

For overrides (non-null), the same hook is unnecessary — slice 5's per-item callbacks already clear `setlist.pptx_fingerprint` when an override changes.

### Job

`GenerateSetlistPptxJob.perform_later(setlist_id)`:

Same shape as `GenerateMusicPptxJob` from slice 3:

1. Reload `setlist`.
2. Compute expected fingerprint via `Slides::Fingerprint.for_setlist(setlist)`.
3. If `setlist.pptx_fingerprint == expected && setlist.pptx.attached?`, return early.
4. Else build payload via the composer + paginator, call `Slides::PptxRenderer` (or a thin wrapper that takes a payload directly — refactor as needed), purge prior attachment, attach binary with filename `"#{setlist.name.parameterize}.pptx"` and content type `application/vnd.openxmlformats-officedocument.presentationml.presentation`, update `pptx_fingerprint`.
5. Broadcast a Turbo Stream replacing the spinner frame with the auto-download link + appending a "Pronto! Baixando..." toast.
6. On render error, retry up to 3 times with exponential backoff. On final failure, clear `pptx_fingerprint`, broadcast an error toast Turbo Stream.

### Model wiring

- `Setlist`: add `broadcasts_to ->(s) { "setlist_#{s.id}" }`.
- `SlideDeck` after-commit: touch `pptx_fingerprint = nil` on every Setlist containing an item that points at this slideable. Use `Setlist.joins(:items).where(setlist_items: { item_type: slideable.class.name, item_id: slideable.id }).distinct.update_all(pptx_fingerprint: nil)`.

### Download controller

`SetlistsController#download_pptx` (or a dedicated `SetlistPptxController#show`): mirrors `Repertoire::Musics::PptxController#show` from slice 3 with the per-setlist fingerprint helper. Same cache-hit / cache-miss / spinner / toast flow. Reuses `toast_controller.js` and `auto_download_controller.js`.

### UI

- **"Baixar PPTX da celebração"** button on the Setlist show page, wrapped in a Turbo Frame the controller and broadcasts target. Positioned near the existing setlist actions (alongside the missa_slots / item list).
- Toast container and auto-download controller already exist from slice 3.

### Cache invalidation summary

`Setlist#pptx_fingerprint` clears when:

- Any SetlistItem is added, removed, or reordered (existing `sortable` reorder endpoint must touch the setlist's fingerprint — add an `after_save`/`after_destroy` on SetlistItem).
- Any SetlistItem's `slides_json_override` or `slide_sequence_override` changes (slice 5 wires this).
- Any underlying slideable's `slide_deck.slides_json` or `slide_sequence` changes (propagated by SlideDeck after-commit, this slice).
- `Theme::VERSION` bumps (included in the fingerprint, so the next computation differs).

## Acceptance criteria

- [ ] `setlists.pptx_fingerprint` column exists; `has_one_attached :pptx` on `Setlist`.
- [ ] `Slides::SetlistComposer` (or equivalent logic) emits the blank-bookended-and-interleaved payload structure documented above.
- [ ] The Python renderer from slice 3 produces a fully black slide for `{ type: "blank", lines: [] }` entries (already true if slice 3 is complete; verify via integration test).
- [ ] A 3-item setlist produces a PPTX with exactly: 1 deck-start blank + item-1 slides + 1 transition blank + item-2 slides + 1 transition blank + item-3 slides + 1 deck-end blank. Total blank slides = items + 1 = 4 for a 3-item setlist.
- [ ] A 1-item setlist produces: 1 blank + item slides + 1 blank = 2 blanks total.
- [ ] `Slides::Fingerprint.for_setlist` is stable across re-runs and changes when any item's effective slides change (verified by mutating a Music's slide_deck and re-computing).
- [ ] Editing any Music's slides invalidates the `pptx_fingerprint` of every Setlist containing a SetlistItem pointing at that Music (verifiable in console / integration test).
- [ ] Editing a SetlistItem's override invalidates only the affected Setlist's fingerprint (slice 5 wires this; verify the wiring crosses the boundary).
- [ ] Adding / removing / reordering SetlistItems invalidates the parent Setlist's `pptx_fingerprint`.
- [ ] `GenerateSetlistPptxJob` has the same cache-hit / cache-miss / error-retry behavior as `GenerateMusicPptxJob`, with integration tests mirroring slice 3.
- [ ] Setlist page "Baixar PPTX da celebração" button works end-to-end: cache-hit one toast, cache-miss spinner + two toasts, error toast on failure.
- [ ] Orphaned sequence ids inside a SetlistItem override are silently skipped at render time without raising (slice 5's warning chip remains the user surface).
- [ ] `Setlist broadcasts_to` channel name matches the frame subscription on the Setlist show page.

## Blocked by

- [`3-music-pptx-download.md`](./3-music-pptx-download.md) — Python renderer, paginator, fingerprint service, job pattern, toast + auto-download Stimulus controllers all come from here.
- [`4-setlist-item-polymorphism.md`](./4-setlist-item-polymorphism.md) — composer relies on `SetlistItem#item` and `effective_*` helpers from slice 5 (which itself needs slice 4).

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.
