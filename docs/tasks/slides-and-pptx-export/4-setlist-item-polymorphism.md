## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

Pure refactor of `SetlistItem` to accept polymorphic content (Music | Oracao | ...) without adding any new user-facing features. Today `setlist_items.belongs_to :music`. After this slice, it `belongs_to :item, polymorphic: true`. This unblocks slices 5 and 6 (setlist slide overrides + per-setlist PPTX) and unblocks the eventual `Oracao` model.

No setlist UI behavior changes for end users. This is a data model migration plus all reference updates.

### Migration sequence

Single migration, executed in this order:

1. Add nullable columns: `item_type :string` and `item_id :bigint`.
2. Backfill in same migration:
   ```ruby
   SetlistItem.unscoped.where.not(music_id: nil).find_each do |row|
     row.update_columns(item_type: "Repertoire::Music", item_id: row.music_id)
   end
   ```
3. Add NOT NULL constraints on `item_type` and `item_id`.
4. Add polymorphic index on `[item_type, item_id]`.
5. Drop the `music_id` foreign key constraint, then drop the `music_id` column.

If the project has production data, split steps 1–3 from steps 4–5 into separate migrations deployed sequentially with model code that reads both columns during the transition. For dev-only data, single migration is fine.

### Model changes

- **`SetlistItem`**:
  - Replace `belongs_to :music` with `belongs_to :item, polymorphic: true`.
  - Validate `item_type` against a whitelist (`["Repertoire::Music"]` for v1.0; expand when `Oracao` lands).
  - Constrain `key` to be present only when the item is a Music: `validates :key, absence: true, unless: -> { item.is_a?(Repertoire::Music) }`.
  - Add a compatibility shim:
    ```ruby
    def music
      item if item.is_a?(Repertoire::Music)
    end
    ```
    Lets existing views that call `setlist_item.music` keep working through the transition. Remove the shim in a follow-up once all callers migrate.

- **`Repertoire::Music`**: replace `has_many :setlist_items` (or whatever it has today) with `has_many :setlist_items, as: :item, dependent: :destroy` (match the existing cascade behavior — destroy or delete_all). Verify nothing was relying on the old reflection name.

### View / controller cleanup

Audit and update every reference to `setlist_item.music`, `setlist_item.music_id`, `params[:music_id]`, and related foreign-key concepts across:

- `app/views/setlists/` (most touchpoints; especially the `_form` and `_item` partials).
- `app/controllers/setlists_controller.rb` and `app/controllers/setlist_items_controller.rb`.
- Any service objects, jobs, or tests referencing the old association.

Two acceptable patterns:

- Replace `setlist_item.music` with `setlist_item.item` where the polymorphism is meaningful (slice 6 will rely on this).
- Keep `setlist_item.music` via the shim where the call site genuinely cares about Music-specific behavior (e.g., transposition `key`).

For the "Adicionar Música" flow: the link at `new_setlist_item_path(music_id: ...)` becomes `new_setlist_item_path(item_type: "Repertoire::Music", item_id: ...)`. Or keep `music_id:` as a parameter that the controller translates into `item_type` + `item_id`. Pick whichever introduces the smaller diff.

### Validations and constraints

- `item_type` must be present and in the whitelist.
- `item_id` must be present.
- `key` (transposition) is rejected when `item_type != "Repertoire::Music"`. Today `key` is nullable; this validation just adds a constraint for the future.
- `mass_part_id` semantics are unchanged — both Music and (future) Oracao items can sit in any mass slot.

### What does NOT change in this slice

- No `Oracao` model — only the schema is ready for it.
- No `slides_json_override` / `slide_sequence_override` columns (slice 5).
- No setlist PPTX (slice 6).
- The `mass_part_id` concept, the section grouping on `Setlist#missa_slots`, and `Setlist#show` rendering are untouched.
- The existing `sortable` reorder controller and its endpoint continue to work — they operate on SetlistItem ids, which don't change.

## Acceptance criteria

- [ ] Migration adds `item_type` and `item_id`, backfills existing rows from `music_id`, drops `music_id` (and its FK constraint). Index on `[item_type, item_id]` exists.
- [ ] `SetlistItem belongs_to :item, polymorphic: true` and resolves to a `Repertoire::Music` for every existing row.
- [ ] `item_type` whitelist validation rejects non-allowed types.
- [ ] `key` absence validation rejects setting `key` on non-Music items (verifiable in a model spec).
- [ ] `setlist_item.music` shim returns the underlying Music when `item_type == "Repertoire::Music"`; returns nil otherwise.
- [ ] All existing views, controllers, and tests pass without changes to user-visible behavior.
- [ ] The "Adicionar Música" flow on the Setlist page continues to work end-to-end (Setlist#show, modal, form submission, redirect).
- [ ] The existing `sortable` reorder controller still reorders items correctly.
- [ ] `Repertoire::Music has_many :setlist_items, as: :item, dependent: :destroy` matches the prior cascade behavior on Music delete.
- [ ] No new user-facing feature is introduced — this is a refactor confirmed by a green test suite.

## Blocked by

- None - can start immediately. Parallel-safe with slices 1, 2, 3.

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.
