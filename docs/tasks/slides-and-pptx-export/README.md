# Slides and PPTX Export — Task Index

Parent PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)

Six vertical slices delivered in two phases. Each task is self-contained and grabbable independently once its blockers complete.

## v1.0 — Per-music slides + PPTX

| # | Task | Type | Blocked by |
|---|---|---|---|
| 1 | [Slide data model + auto-derivation](./1-slide-data-model.md) | AFK | — |
| 2 | [Music form slide editor + regenerate flow](./2-music-form-slide-editor.md) | AFK | 1 |
| 3 | [Per-music PPTX generation + download](./3-music-pptx-download.md) | AFK | 1, 2 |

## v1.1 — Per-setlist composition

| # | Task | Type | Blocked by |
|---|---|---|---|
| 4 | [SetlistItem polymorphism refactor](./4-setlist-item-polymorphism.md) | AFK | — (parallel-safe with v1.0) |
| 5 | [SetlistItem slide overrides + orphan warnings](./5-setlist-slide-overrides.md) | AFK | 2, 4 |
| 6 | [Per-setlist PPTX composition](./6-setlist-pptx-composition.md) | AFK | 3, 4 |

## Dependency graph

```
v1.0:  1 ──> 2 ──> 3
                    \
v1.1:  4 ────────────> 6
        \
         > 5 (needs 2 and 4)
```

Slice 4 has no blockers, so it can land in parallel with v1.0 if a second contributor is free.

## Locked global decisions

These cross all six slices — restated here so each task file stays self-contained.

### Theme V1 (`Slides::Theme::V1`, version constant `"v1"`)

| Setting | Value |
|---|---|
| Aspect ratio | 10" × 7.5" (4:3) |
| Background | `#000000` |
| Text color | `#FFFFFF` |
| Font family | Calibri |
| Font size | 42pt |
| H-align / V-align | center / middle |
| Margins | 5% all sides |
| Max chars per logical line (UI hint threshold) | 32 |
| Max visual lines per slide | 10 |
| Bold section types | `["chorus"]` |

### Section ids

Type-prefixed positional, immutable for the deck's lifetime:
`intro_1`, `verse_1`, `verse_2`, `chorus_1`, `bridge_1`, `outro_1`, `label_1`, …

### Section types

`intro | verse | chorus | bridge | outro | label`. Editable in the section editor (slice 2) — the parser's heuristic is imperfect. New liturgical types (`resposta_eucaristica`, etc.) added as the parser gains awareness.

### Polymorphic SlideDeck adopted from day one

Only `Repertoire::Music` is slideable in v1.0. The next slideable (`Oracao`, of multiple types) is concretely planned for v1.2+. Retrofitting polymorphism later would require migrating attachments, so we pay the cost up front.

### Cifra-to-slides direction

Cifra (`content_raw`) is canonical for **structure** — sections exist because the cifra parses them. SlideDeck is canonical for **presented content** — lyrics may diverge from the cifra's phonetic form. Edits flow cifra → slides via `Slides::Extractor` only on Music create or explicit "Regenerar". Slide-side edits never flow back to the cifra.

### Regenerate is destructive

The "Regenerar slides" action overwrites both `slides_json` and `slide_sequence` and updates `slides_generated_from`. Surfaced via a confirmation modal. No content-similarity id preservation — orphaned sequence references in `SetlistItem` overrides (slice 5) are render-skipped and flagged with a warning chip.

### Phonetic strip is conservative

`Slides::PhoneticStrip` applies only:
1. Collapse 3+ identical adjacent letters → 1.
2. Collapse multiple whitespace → single space.
3. Trim leading/trailing whitespace.

No dash handling, no accent recovery. The cifra phonetic form is lossy — the strip does the cheap mechanical cleanup; the user fixes accents and punctuation manually in the section editor.

### Pagination is greedy with visual cost

Each logical line costs 1 unit; lines exceeding 32 characters cost 2 (they'll wrap visually). Greedy fill against the 10-visual-line budget. No stanza awareness, no soft page breaks.

### PPTX is lazy + cached by fingerprint

`pptx_fingerprint = SHA1(canonicalize(slides_json, slide_sequence, Theme::VERSION))` on `SlideDeck`. Per-setlist fingerprint includes each item's effective slides + position + mass_part_id. Job no-ops on cache hit; renders on miss; clears fingerprint on final failure. Theme version bump invalidates all caches.

### Download UX

Cache hit → Turbo Stream auto-download link + one "Pronto! Baixando..." toast. Cache miss → "Gerando seu PPTX..." spinner + toast, ActionCable broadcast replaces spinner with auto-download link + appends "Pronto!" toast. Final failure → error toast. No polling.

### Out of scope across all slices

Per-paróquia themes, custom intro/avisos/closing slides, title cards, end cards, HTML preview of slides in the form, cifra syntax extensions, second source-of-truth lyrics field, content-similarity id preservation, soft page breaks within sections, stanza-aware pagination, sync PPTX generation, per-statement blank slides inside an oração.
