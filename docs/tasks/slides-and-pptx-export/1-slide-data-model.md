## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

Foundation for the slides feature: a polymorphic `SlideDeck` model that any "slideable" content can attach to, plus a pure-service pipeline that derives `slides_json` from a `Repertoire::Music`'s `content_json` whenever a Music is created. No user-facing UI in this slice. No PPTX rendering in this slice.

Verifiable end-to-end in rails console: `Repertoire::Music.create!(title: "X", author: ..., content_raw: "...")` and then `Repertoire::Music.last.slide_deck.slides_json` returns a populated array.

### Schema

Create `slide_decks` table:

- `slideable_type :string, null: false` + `slideable_id :bigint, null: false` — polymorphic association. Unique index on `[slideable_type, slideable_id]`.
- `slides_json :jsonb, null: false, default: []` — flat array of section objects.
- `slide_sequence :jsonb, null: false, default: []` — flat array of section ids.
- `slides_generated_from :string` — SHA1 of `content_raw` at last regeneration; powers the "cifra changed since slides" hint in slice 2.
- `pptx_fingerprint :string` — slice 3 populates this. Leave on the schema now so the migration is one-shot.
- `t.timestamps`.

### Section shape inside `slides_json`

```json
{
  "id": "verse_1",
  "type": "verse",
  "label": "Estrofe 1",
  "lines": ["Vem e eu mostrarei", "que o meu caminho é o melhor"]
}
```

- `id`: type-prefixed positional, immutable for the deck's lifetime. Types: `intro | verse | chorus | bridge | outro | label`.
- `type`: one of the section types above. Editable in slice 2.
- `label`: human-readable editor display (`"Refrão"`, `"Estrofe 2"`). Not rendered on the slide itself.
- `lines`: array of logical lyric lines. Empty array (`[]`) is valid — renders as a fully black blank slide in slice 3.

### `slide_sequence` shape

Flat array of section ids with repetition allowed:

```json
["chorus_1", "verse_1", "chorus_1", "verse_2", "chorus_1"]
```

Default sequence on first derivation: each section id once, in document order, with empty-lyric sections **excluded** by default.

### Modules to build

All pure services under `app/services/slides/`:

- **`Slides::PhoneticStrip`** — `.call(text) → cleaned_text`. Three rules:
  1. Collapse runs of 3+ identical adjacent letters (case-insensitive) to a single letter.
  2. Collapse multiple whitespace to a single space.
  3. Trim leading/trailing whitespace.
  No dash handling, no accent recovery — strip is best-effort mechanical cleanup. The cifra phonetic form is lossy (`"aaa aaa - meee m"` → `"a a - me m"`, not `"AMÉM"`); the user fixes accents manually in slice 2.

- **`Slides::Extractor`** — `.call(content_json) → slides_json`. Iterates sections of `content_json` (produced by the existing `Repertoire::MusicParserService`), drops the chord layer (`line[:parts].map { |p| p[:lyric] }.join.strip`), runs `Slides::PhoneticStrip` on each line, assigns `"#{type}_#{positional_index}"` ids, computes default Portuguese labels:
  - `intro` → `"Intro"`
  - `verse` → `"Estrofe #{N}"`
  - `chorus` → `"Refrão"`
  - `bridge` → `"Ponte"`
  - `outro` → `"Final"`
  - `label` → `"Marcador"`

  Empty-lyric sections **remain** in `slides_json` with `lines: []` (so ids stay stable across regeneration). They are **excluded** from the default sequence builder.

- **`Slides::Theme`** module: V1 constants and `VERSION`. Used by slices 2 and 3, but lives here. Values:
  - `ASPECT = [10.0, 7.5]` (inches, 4:3)
  - `BG_COLOR = "#000000"`
  - `TEXT_COLOR = "#FFFFFF"`
  - `FONT_FAMILY = "Calibri"`
  - `FONT_SIZE = 42`
  - `H_ALIGN = :center`
  - `V_ALIGN = :middle`
  - `MARGINS = 0.05`
  - `MAX_CHARS_PER_LINE = 32` (UI hint threshold; also used by paginator visual-cost in slice 3)
  - `MAX_VISUAL_LINES = 10`
  - `BOLD_SECTION_TYPES = ["chorus"]`
  - `VERSION = "v1"`

### Rails plumbing

- **`Slideable` concern** (`app/models/concerns/slideable.rb`):
  - `has_one :slide_deck, as: :slideable, dependent: :destroy`
  - `after_create_commit :seed_slide_deck`
  - `seed_slide_deck`: build the SlideDeck; if `content_raw` is present, run `Slides::Extractor.call(content_json)`, populate `slides_json` and default `slide_sequence` (each non-empty section once, in order), stamp `slides_generated_from = Digest::SHA1.hexdigest(content_raw)`. No-op when `content_raw` is blank.

- **`SlideDeck`** model (`app/models/slide_deck.rb`):
  - `belongs_to :slideable, polymorphic: true`.
  - No validations beyond the schema NOT NULL constraints.
  - Convenience reader `sections` aliased to `slides_json`.

- **`Repertoire::Music`** includes `Slideable`.

### Backfill task

`bin/rails repertoire:slides:backfill`:

- For each `Repertoire::Music` lacking a `slide_deck`, build one and run the extractor.
- Idempotent — running twice is a no-op.
- Does NOT trigger PPTX generation. PPTX is lazy-on-download in slice 3.

## Acceptance criteria

- [x] `slide_decks` table exists with all columns above; unique index on `[slideable_type, slideable_id]`.
- [x] `Slides::PhoneticStrip` exists with unit tests covering:
  - `"aaa"` → `"a"`; `"aaaa"` → `"a"`
  - `"aa"` stays `"aa"` (only collapses 3+)
  - `"  a  b  "` → `"a b"`
  - Case-insensitive: `"AAAA"` → `"A"`
  - Unicode preserved and collapses: `"ééé"` → `"é"`
  - Trims edges
- [x] `Slides::Extractor` exists with table-style fixture tests (modeled after `test/services/repertoire/music_parser_service_test.rb`) covering:
  - A multi-section cifra produces correct ids, labels, and stripped lines.
  - Sections with empty lyrics remain in `slides_json` with `lines: []`.
  - Ids are deterministic across runs.
  - Default sequence builder excludes empty-lyric sections.
- [x] `Slides::Theme::V1` and `Slides::Theme::VERSION` exposed and value-checked in a test.
- [x] `Slideable` concern auto-creates `slide_deck` on Music create when `content_raw` is present, populates `slides_json` and `slide_sequence`, and stamps `slides_generated_from`.
- [x] Creating a Music with blank `content_raw` still creates a `slide_deck` row but with `slides_json: []`, `slide_sequence: []`, and `slides_generated_from: nil`.
- [x] `bin/rails repertoire:slides:backfill` creates `slide_deck` records for all existing musics; running it twice is a no-op.
- [x] `SlideDeck` model has tests verifying the polymorphic association resolves to a `Repertoire::Music`.

## Blocked by

- None - can start immediately.

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.

## Status

**Completed** — 2026-05-16.

Files added/changed:

- `db/migrate/20260516143535_create_slide_decks.rb` — new
- `app/models/slide_deck.rb` — new
- `app/models/concerns/slideable.rb` — new
- `app/models/repertoire/music.rb` — `include Slideable`
- `app/services/slides/phonetic_strip.rb` — new
- `app/services/slides/theme.rb` — new
- `app/services/slides/extractor.rb` — new (incl. `Slides::Extractor.default_sequence`)
- `lib/tasks/repertoire_slides.rake` — new (`repertoire:slides:backfill`)
- `test/services/slides/phonetic_strip_test.rb` — 8 tests
- `test/services/slides/theme_test.rb` — 2 tests
- `test/services/slides/extractor_test.rb` — 5 tests
- `test/models/slide_deck_test.rb` — 4 tests
- `test/lib/tasks/repertoire_slides_backfill_test.rb` — 1 test

End-to-end probe (rails runner) returned:

```
slides_json: [{"id"=>"verse_1", "type"=>"verse", "label"=>"Estrofe 1", "lines"=>["Vem e eu mostrarei"]}]
slide_sequence: ["verse_1"]
slides_generated_from: "a6d88fed978c3249043988f48c2c460eb6615946"
```

Full suite: 115 runs, 349 assertions, 0 failures.
