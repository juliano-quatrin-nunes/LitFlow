# Product Requirements Document: Slides and PPTX Export

## Problem Statement

Choir directors and liturgy planners need to project song lyrics during mass as PowerPoint slides. Today the system has a single `content_raw` / `content_json` per `Repertoire::Music` that encodes the cifra (chords + lyrics), but the cifra's lyrics are phonetically stretched for singers (e.g., `"aaa aaa - meee m"`) while the congregation's slides need clean, legible text (`"AMÉM"`). The cifra and the slide are coupled to the same source, so neither serves its audience well.

Beyond the per-song problem, planners want to generate one `.pptx` file for an entire celebration that they can hand to the projectionist — with all songs in setlist order, breath/transition slides between items, and (later) orações like the Pai Nosso interleaved with music.

## Solution

Introduce a polymorphic `SlideDeck` model that owns the slide-side representation of any "slideable" content (initially `Repertoire::Music`; later `Oracao` and other liturgical pieces). A `SlideDeck` stores `slides_json` (the logical slide content, derived from but independent of the cifra) and `slide_sequence` (the default playback order, supporting repetition for refrains). PPTX files are rendered by a Python script (`python-pptx`) called from Rails via `Open3`, cached as Active Storage attachments on the `SlideDeck`, and regenerated lazily when a fingerprint of inputs changes.

`SetlistItem` becomes polymorphic (Music | Oracao | ...) and gains nullable `slides_json_override` / `slide_sequence_override` columns — overrides for a single celebration that fall through to the underlying slideable's deck when null. Edits to a Music's slides propagate visibly to all setlists that haven't customized.

Ship in two phases:
- **v1.0** — per-music slide editor + per-music PPTX download.
- **v1.1** — `SetlistItem` polymorphism + per-setlist PPTX composition with blank black transition slides between items.

## User Stories

### Per-Music Slide Editing (v1.0)

1. **[MUST]** As a music author, when I paste a cifra into the Music form and save for the first time, the system auto-derives a slides representation (`slides_json`) so I don't have to author slides separately.
2. **[MUST]** As a music author, I want a "Gerar slides a partir da cifra" button on the Music form that previews the derived slides inline (Turbo Frame) before I save the music, so I can review them.
3. **[MUST]** As a music author, I want to edit each derived slide's lyrics, label, and section type (chorus / verse / bridge / etc.) inline in the form, so I can clean up phonetic stretching, fix accents, and correct misidentified section types.
4. **[MUST]** As a music author, I want a UI hint chip beside any line longer than 32 characters warning that it may wrap visually, so I can shorten it if I want.
5. **[MUST]** As a music author, once I have edited slides, future edits to `content_raw` must never silently overwrite my slide content — only an explicit "Regenerar slides" action overwrites, and only after a confirmation modal.
6. **[MUST]** As a music author, when the cifra has changed since my slides were last generated, the form surfaces a "cifra changed since slides — regenerar?" hint based on a stored `slides_generated_from` content hash.
7. **[MUST]** As a music author, regenerating slides is destructive: both `slides_json` and the default `slide_sequence` reset. I confirm this in a modal before it executes.
8. **[MUST]** As a music author, I want a drag-and-drop sequence editor (reusing the existing setlist `sortable` Stimulus controller) where I can reorder the default playback of sections, add a section multiple times (`+ duplicar`), or remove sections from the sequence.
9. **[MUST]** As a music author, the sequence editor is collapsed by default; most users won't customize it on the Music itself.
10. **[MUST]** As a music author, I want a "Baixar PPTX" action on the Music show page to download the song as a standalone PowerPoint file.
11. **[MUST]** As a music author, when I click "Baixar PPTX" and the file is already cached and current, the download starts immediately with one toast: "Pronto! Baixando...".
12. **[MUST]** As a music author, when I click "Baixar PPTX" and the file is missing or stale, I see a first toast "Gerando seu PPTX...", then a second toast when ready that triggers the download.
13. **[MUST]** As a music author, if PPTX generation fails after retries, I see an error toast: "Erro ao gerar PPTX. Tente novamente."
14. **[MUST]** As a music author, the generated PPTX uses black background, white text, Calibri 42pt, centered, 4:3 aspect ratio (10" × 7.5"), with refrão (chorus) sections rendered bold and other section types regular weight.
15. **[MUST]** As a music author, if a section in my sequence has empty `lines`, it renders as a fully black blank slide in the PPTX — so I can intentionally insert dramatic pauses.
16. **[COULD]** As a music author, I want to skip empty intro/outro sections from the auto-generated default sequence so they don't clutter the playback.
17. **[COULD]** As a music author, I want to edit section types via a dropdown so I can fix the parser's heuristic when it misidentifies a section.

### Per-Setlist Composition (v1.1)

18. **[MUST]** As a celebration planner, I want a setlist to contain a polymorphic ordered list of items (Music or Oracao), so I can build a complete mass deck.
19. **[MUST]** As a celebration planner, I want a "Baixar PPTX da celebração" button on the Setlist page that produces one `.pptx` containing every item in `position` order.
20. **[MUST]** As a celebration planner, the deck must start with a blank black transition slide, insert a blank black transition slide between every item, and end with a blank black transition slide.
21. **[MUST]** As a celebration planner, I want each `SetlistItem` to optionally override its slideable's `slides_json` and/or `slide_sequence`, so I can customize a single celebration without touching the canonical Music.
22. **[MUST]** As a celebration planner, when I don't override, edits to the underlying Music's slides propagate visibly to my setlist (no silent copies).
23. **[MUST]** As a celebration planner, when a Music's slides are regenerated and a setlist's override references section ids that no longer exist, the orphaned ids are skipped at render time and the Setlist page shows a warning chip ("alguns slides precisam de revisão").
24. **[MUST]** As a celebration planner, the per-setlist download follows the same cache-and-toast pattern as the per-music download.

### Future / Per-Paróquia (out of scope; here for awareness)

25. **[WONT]** As a paróquia admin, I want to define custom opening, announcement (avisos), and closing slides specific to my paróquia.
26. **[WONT]** As a paróquia admin, I want to override the theme (font, colors, aspect ratio) per paróquia.
27. **[WONT]** As an oração author, I want per-statement blank transition slides within a single oração (e.g., Pai Nosso line-by-line projection).

## Implementation Decisions

### Schema

- **`slide_decks` table (new, v1.0):**
  - `slideable_type` / `slideable_id` — polymorphic association, unique on the pair.
  - `slides_json :jsonb` default `[]` — flat array of section objects.
  - `slide_sequence :jsonb` default `[]` — flat array of section ids.
  - `slides_generated_from :string` — SHA1 of `content_raw` at last regeneration; powers the "cifra changed since slides" hint.
  - `pptx_fingerprint :string` — SHA1 of canonicalized `(slides_json, slide_sequence, Theme::VERSION)`; controls PPTX cache validity.
  - `has_one_attached :pptx`.

- **Section shape inside `slides_json`:**
  ```json
  {
    "id": "verse_1",
    "type": "verse",
    "label": "Estrofe 1",
    "lines": ["Vem e eu mostrarei", "que o meu caminho é o melhor"]
  }
  ```
  - `id` is type-prefixed positional and immutable for the lifetime of the deck (`intro_1`, `verse_1`, `chorus_1`, `bridge_1`, `outro_1`, `label_1`).
  - `type` is one of `intro | verse | chorus | bridge | outro | label` and is editable in the section editor.
  - `label` is human-readable for the editor only; not rendered on the slide itself.
  - `lines` are logical lyric lines; an empty array renders as a blank black slide.

- **`slide_sequence` shape:** array of section ids. Repetition allowed via duplicate entries: `["chorus_1", "verse_1", "chorus_1", "verse_2", "chorus_1"]`.

- **`setlist_items` migration (v1.1):**
  - Rename `music_id` → `item_id`, add `item_type :string`. Backfill `item_type = "Repertoire::Music"`.
  - Add `slides_json_override :jsonb` (null = inherit) and `slide_sequence_override :jsonb` (null = inherit).
  - `key` column remains and is constrained to be null unless `item_type == "Repertoire::Music"`.

### Modules

- **`Slideable` concern** mounted on `Repertoire::Music` (and later `Oracao`): adds `has_one :slide_deck, as: :slideable, dependent: :destroy`, plus an `after_create_commit` hook that seeds `slide_deck` by running the extractor on `content_json` when `content_raw` is present and slides are absent.

- **`Slides::PhoneticStrip`** (pure service, deep): `.call(text) → cleaned_text`. Three rules:
  1. Collapse runs of 3+ identical adjacent letters (case-insensitive) to a single letter.
  2. Collapse multiple whitespace to a single space.
  3. Trim leading/trailing whitespace.
  No dash handling, no accent recovery — the strip is best-effort mechanical cleanup; the user fixes accents/punctuation manually.

- **`Slides::Extractor`** (pure service, deep): `.call(content_json) → slides_json`. Iterates sections, drops the chord layer, runs `PhoneticStrip` on each line, assigns type-positional ids, and computes default Portuguese labels (`Estrofe N`, `Refrão`, `Ponte`, `Final`, `Intro`, `Marcador`). Empty-lyric sections remain in `slides_json` with `lines: []` but are excluded from the default `slide_sequence`.

- **`Slides::Paginator`** (pure service, deep): `.call(lines, max_visual: 10, char_threshold: 32) → [[line, ...], [line, ...]]`. Greedy fill where each line costs 1 unit normally and 2 units if its length exceeds `char_threshold` (so long lines that will visually wrap count as two slide-lines).

- **`Slides::Fingerprint`** (pure service, deep): `.call(slides_json, slide_sequence, theme_version) → sha1_string`. Canonicalizes the inputs before hashing so logically-equivalent payloads collide.

- **`Slides::Theme`** module: V1 constants — aspect `10" × 7.5"`, bg `#000000`, text `#FFFFFF`, font Calibri 42pt, h-align center, v-align middle, margins 5%, `max_chars_per_line: 32`, `max_visual_lines: 10`, `bold_section_types: ["chorus"]`. `Slides::Theme::VERSION = "v1"` — bumped manually when theme changes; triggers regen of all `pptx_fingerprint`s.

- **`Slides::PptxRenderer`** (boundary service): `.call(slide_deck) → binary_pptx`. Builds the payload (paginated, sequenced physical slides + theme), invokes `python3 bin/render_pptx.py` via `Open3.capture3` (`stdin_data` JSON, `binmode: true`), 30s timeout. Non-zero exit raises `Slides::RenderError` with captured stderr.

- **`GenerateMusicPptxJob`**: fingerprint-checks before rendering. Computes current fingerprint; if it matches `slide_deck.pptx_fingerprint` and an attachment exists, returns early. Otherwise calls `Slides::PptxRenderer`, attaches the binary via `slide_deck.pptx.attach(...)`, updates `pptx_fingerprint`, purges the prior attachment. 3 retries with backoff; on final failure, broadcasts an error toast Turbo Stream. Job is idempotent and debounce-safe.

### Cifra Lifecycle Rules

- On `Repertoire::Music.create` with `content_raw` present, the `Slideable` concern seeds `slide_deck` by running `Slides::Extractor` once, and sets `slides_generated_from` to the SHA1 of `content_raw`.
- On `Repertoire::Music.update`, the system does **not** auto-regenerate slides. The form surfaces a "cifra changed" hint whenever `SHA1(content_raw) != slides_generated_from`. Regeneration requires an explicit user action that resets both `slides_json` and `slide_sequence`.
- Any change that mutates `slides_json` or `slide_sequence` clears `pptx_fingerprint` (forces lazy re-render on next download). Theme version bump (rare, manual) implicitly invalidates all decks because the fingerprint includes `Theme::VERSION`.

### PPTX Download Flow (Turbo Streams + ActionCable)

- `Repertoire::Musics::PptxController#show` computes the expected fingerprint and compares against `slide_deck.pptx_fingerprint`.
- **Cache hit:** respond with a Turbo Stream that swaps in an auto-clicking link (`<a href=... data-controller="auto-download">`) plus a "Pronto! Baixando..." toast. One toast.
- **Cache miss:** enqueue `GenerateMusicPptxJob`, respond with a Turbo Stream containing a "Gerando seu PPTX..." spinner and toast.
- `SlideDeck` model uses `broadcasts_to ->(d) { "slide_deck_#{d.id}" }`. When the job finishes, it broadcasts a Turbo Stream replacing the spinner with the auto-download link + a "Pronto! Baixando..." toast. On final failure, broadcasts an error toast.
- No polling; no extra status endpoints.

### Python Boundary

- Single script `bin/render_pptx.py`. Reads JSON from stdin, writes binary `.pptx` to stdout, prints errors to stderr. ~150 lines, one dep.
- `requirements.txt` at repo root, pinned to `python-pptx==1.0.2`.
- Dockerfile installs Python 3.11 + a `/opt/python` venv layer with `python-pptx`; adds `/opt/python/bin` to `PATH`. ~100MB image growth.
- Local dev (macOS): `brew install python@3.11 && pip3 install python-pptx==1.0.2`. The renderer raises a friendly error pointing to setup docs when Python is unreachable.

### UI Composition

- Music form remains a single vertical page. Order: cifra textarea → "Gerar slides a partir da cifra" button → Turbo Frame containing the section editor (hidden until first generation) → collapsible sequence editor → form submit.
- Section editor: one card per section, label input, type dropdown, lyrics textarea sized to content, char-overflow hint chips inline beside lines > 32 chars. **No add/delete/reorder** in the section editor — order follows `content_raw`, structural changes route through "Regenerar slides".
- Sequence editor reuses the existing `sortable` Stimulus controller (`app/javascript/controllers/sortable_controller.js`). Chip-per-section with a `+ duplicar` action; remove via drag-out or an `x` button. Default collapsed.
- Toasts: a single global `toast_controller.js` listens for `<turbo-stream action="append" target="toasts">`, auto-dismiss after 4s.

### Phasing

- **v1.0 ships:** schema + concern, all `Slides::*` services, `bin/render_pptx.py`, Dockerfile/requirements changes, `GenerateMusicPptxJob`, form changes, per-music download endpoint and UI, backfill rake task that creates a `SlideDeck` with derived `slides_json` for every existing `Repertoire::Music` (lazy PPTX — no eager generation).
- **v1.1 ships:** `SetlistItem` polymorphic migration, overrides, `Setlist has_one_attached :pptx`, `GenerateSetlistPptxJob`, mass deck composition with blank black transition slides between items, orphaned-id warning chip on Setlist page.

## Testing Decisions

Tests target external behavior, not implementation details. The pure services are the highest-leverage targets because they encapsulate the trickiest logic behind tiny interfaces.

- **`Slides::PhoneticStrip`** — enumerate cases: `"aaa"` → `"a"`; `"aa"` stays `"aa"` (only collapses 3+); `"  a  b  "` → `"a b"`; `"AAAA"` collapses; preserves Unicode (e.g., `"ééé"` → `"é"`). Covers the entire rule surface.

- **`Slides::Extractor`** — fixture-based: feed sample `content_json` payloads, assert resulting `slides_json` (ids, labels, line content after stripping, empty section handling). Mirror the pattern from `test/services/repertoire/music_parser_service_test.rb` — table-style test cases.

- **`Slides::Paginator`** — visual-cost behavior: 4 short lines fit in one page; 11 short lines split 10/1; one 40-char line costs 2 (so 5 long lines + 1 short line = 11 cost and splits); empty input returns `[]`.

- **`Slides::Fingerprint`** — stability: same input → same output; reordering keys in `slides_json` (canonicalization) does not change the hash; changing any slide line does change the hash; changing `Theme::VERSION` does change the hash.

- **`SlideDeck` model** — validations (`slideable` presence, polymorphic uniqueness), attachment basics, the `broadcasts_to` declaration is wired (smoke test).

- **`GenerateMusicPptxJob`** — integration: (a) job is a no-op when current fingerprint matches stored value and attachment exists; (b) job invokes the renderer and attaches the result when fingerprint mismatches; (c) job broadcasts an error toast Turbo Stream on render failure after retries are exhausted.

- **`Slides::PptxRenderer`** — *not* covered by an end-to-end test against the real Python binary in v1.0 (slow, environment-dependent). A unit test stubs `Open3.capture3` and asserts payload shape + error mapping.

**Prior art:** `test/services/repertoire/music_parser_service_test.rb` is the closest model for pure-service testing in this codebase. Job and controller patterns are otherwise absent (clean slate).

## Out of Scope

- Per-paróquia themes, custom intro/avisos/closing slides, or a `Congregation` / `Paroquia` model.
- Title cards (song name + author) and end cards.
- HTML/CSS preview of slides inside the Music form. The preview signal is the char-overflow hint and the eventual downloaded PPTX.
- Cifra syntax extensions to encode clean lyrics inline (`[clean=AMÉM]aaa aaa[/clean]`). Cleanup happens only via post-derivation manual editing of `slides_json`.
- A second source-of-truth `slides_raw` field on Music. `slides_json` is the slide-side truth; `content_raw` remains the cifra-side truth.
- Content-similarity matching to preserve section ids across regenerate. Regenerate is destructive by design; manual recovery is the contract.
- Soft page breaks within a section (`---` marker or persisted break points). Pagination is fully system-decided.
- Stanza-aware pagination. Greedy fill only.
- Active Record validations on `slide_sequence` referencing existing section ids; orphaned ids are render-skipped, not rejected at save.
- Synchronous PPTX generation. All renders go through the job; the user always sees the cache-hit-or-spinner UI path.
- Per-statement blank slides inside an oração (deferred until oração model lands).
- Authorization model changes; reuses existing Music edit authorization.

## Further Notes

- The polymorphic `SlideDeck` is intentionally adopted from day one even though only `Repertoire::Music` is slideable in v1.0. The next slideable (`Oracao`, of multiple types) is concretely planned for v1.2+, and retrofitting polymorphism later would require migrating attachments.
- The `Slideable` concern is the recommended attachment point for new slideable models — a one-line `include Slideable` opt-in.
- The cifra is canonical for *structure* (sections exist because the cifra has sections); the slide deck is canonical for *presented content* (lyrics may diverge from the cifra's phonetic form). Edits flow in one direction: cifra → slides via extractor (only at create or explicit regenerate). Slide-side edits never flow back to the cifra.
- The decision to render with `python-pptx` rather than Marp, LibreOffice headless, or a Ruby PPTX library was driven by output fidelity to Microsoft PowerPoint (the projection target), image size (~100MB vs. 500–700MB), and library maturity. Documented for posterity in case future maintainers reconsider.
- The auto-inserted blank black slides between setlist items are intentionally featureless — no mass-part label, no song title. They function as visual pauses for the projectionist and the congregation, not as wayfinding.
