## Parent

PRD: [`docs/prds/slides-and-pptx-export.md`](../../prds/slides-and-pptx-export.md)
Index: [`docs/tasks/slides-and-pptx-export/README.md`](./README.md)

## What to build

The Python rendering pipeline plus a "Baixar PPTX" download flow on the Music show page. Clicking the button cache-checks the fingerprint and either delivers the cached file (one toast) or enqueues a background job that broadcasts a Turbo Stream when ready (two toasts).

This slice completes v1.0: by the end, a music author can paste a cifra, edit slides, and download a PowerPoint file the church can project.

### Python boundary

- **`bin/render_pptx.py`** — reads JSON from stdin, writes binary `.pptx` to stdout, prints errors to stderr. ~150 lines. One dep: `python-pptx`.
- **Input payload shape** built by Ruby:
  ```json
  {
    "theme": {
      "aspect": [10.0, 7.5],
      "bg": "#000000",
      "text": "#FFFFFF",
      "font": "Calibri",
      "size": 42,
      "h_align": "center",
      "v_align": "middle",
      "margins": 0.05,
      "bold_section_types": ["chorus"]
    },
    "slides": [
      { "type": "chorus", "lines": ["AMÉM", "AMÉM"] },
      { "type": "verse",  "lines": ["Vem e eu mostrarei", "..."] },
      { "type": "blank",  "lines": [] }
    ]
  }
  ```
- **Output:** binary `.pptx` content on stdout. Each slides entry produces one physical slide. `type: "blank"` or any entry with empty `lines` renders as a fully black blank slide.
- **Bold:** when slide `type` is in `theme.bold_section_types`, render its text bold; otherwise regular weight.
- **`requirements.txt`** at repo root, pinned to `python-pptx==1.0.2`.
- **Dockerfile:** add a venv layer. Approximate diff (adapt to existing Dockerfile structure at `/Dockerfile`):
  ```dockerfile
  RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv \
      && rm -rf /var/lib/apt/lists/*
  COPY requirements.txt /tmp/
  RUN python3 -m venv /opt/python && \
      /opt/python/bin/pip install --no-cache-dir -r /tmp/requirements.txt
  ENV PATH="/opt/python/bin:$PATH"
  ```
  Adds ~100MB to the image.
- **Local dev (macOS):** document `brew install python@3.11 && pip3 install python-pptx==1.0.2` in `README.md` (and `CLAUDE.md` if that file is added later).

### Services

All under `app/services/slides/`:

- **`Slides::Paginator`** — `.call(lines, max_visual: 10, char_threshold: 32) → [[line, ...], [line, ...]]`. Greedy fill where each line costs 1 unit normally and 2 units if `line.length > char_threshold`. Empty `lines` returns `[[]]` (one blank physical slide). Reference implementation from the PRD:
  ```ruby
  def paginate(lines, max_visual: 10, char_threshold: 32)
    pages, current, used = [], [], 0
    lines.each do |line|
      cost = line.length > char_threshold ? 2 : 1
      if used + cost > max_visual
        pages << current
        current, used = [line], cost
      else
        current << line
        used += cost
      end
    end
    pages << current if current.any?
    pages
  end
  ```

- **`Slides::Fingerprint`** — `.call(slides_json, slide_sequence, theme_version) → sha1_string`. Canonicalize inputs (sort hash keys deeply, normalize types) before hashing so logically equivalent payloads collide. Used by both this slice and slice 6 (per-setlist variant).

- **`Slides::PptxRenderer`** (boundary) — `.call(slide_deck) → binary_pptx`:
  1. Walk `slide_deck.slide_sequence`.
  2. For each id, look up the section in `slide_deck.slides_json`. Skip silently if not found (v1.0 doesn't surface orphans yet; slice 5 adds the warning chip).
  3. Paginate each section via `Slides::Paginator`.
  4. Flatten to `slides` array. Each physical slide carries its source section's `type` (so the renderer knows whether to bold).
  5. Build the payload (`theme: Slides::Theme::V1.to_h, slides: ...`).
  6. Invoke `Open3.capture3("python3", Rails.root.join("bin/render_pptx.py").to_s, stdin_data: payload.to_json, binmode: true)` wrapped in `Timeout.timeout(30)`.
  7. Non-zero exit → raise `Slides::RenderError` with captured stderr.
  8. Return the stdout binary.

### Job

`GenerateMusicPptxJob.perform_later(slide_deck_id)`:

1. Reload `slide_deck`.
2. Compute expected fingerprint via `Slides::Fingerprint.call(slides_json, slide_sequence, Slides::Theme::VERSION)`.
3. If `slide_deck.pptx_fingerprint == expected && slide_deck.pptx.attached?`, return early (idempotent / debounce-safe).
4. Else call `Slides::PptxRenderer`, purge prior attachment, attach binary with filename `"#{music.slug}.pptx"` and content type `application/vnd.openxmlformats-officedocument.presentationml.presentation`, update `pptx_fingerprint`.
5. Broadcast a Turbo Stream replacing the spinner frame with the auto-download link + appending a "Pronto! Baixando..." toast.
6. On render error, retry up to 3 times with exponential backoff. On final failure, clear `pptx_fingerprint`, broadcast an error toast Turbo Stream.

### Model wiring

- `SlideDeck`: add `broadcasts_to ->(d) { "slide_deck_#{d.id}" }` so the frame on the Music show page receives updates.

### Download controller

`Repertoire::Musics::PptxController#show`:

- Load music + slide_deck.
- Compute expected fingerprint.
- **Cache hit** (`pptx_fingerprint == expected && pptx.attached?`):
  - Respond with a Turbo Stream that:
    1. Replaces the download-button frame with an auto-clicking link `<a href=<active_storage_url> data-controller="auto-download" download="...pptx">`.
    2. Appends a toast "Pronto! Baixando..." to `#toasts`.
- **Cache miss** (fingerprint mismatch OR attachment missing):
  - Enqueue `GenerateMusicPptxJob.perform_later(slide_deck.id)`.
  - Respond with a Turbo Stream that:
    1. Replaces the download-button frame with a "Gerando seu PPTX..." spinner inside a frame subscribed to the SlideDeck broadcast channel via `<%= turbo_stream_from "slide_deck_#{@slide_deck.id}" %>`.
    2. Appends a toast "Gerando seu PPTX..." to `#toasts`.

### UI components

- **"Baixar PPTX" button** on the Music show page wrapped in a Turbo Frame that the controller and broadcasts can target.
- **`#toasts` container** in the application layout (if not already present), polled by a global Stimulus toast controller.
- **`toast_controller.js`** (global): on connect to a `[data-toast]` element, schedules `setTimeout` removal after 4000ms. Idempotent — multiple toasts stack.
- **`auto_download_controller.js`**: on `connect`, programmatically clicks the anchor target to trigger the browser download.

## Acceptance criteria

- [x] `bin/render_pptx.py` exists and produces a valid `.pptx` file from a sample JSON payload. `python3 bin/render_pptx.py < sample.json > out.pptx` opens in PowerPoint showing the theme (black bg, white text, Calibri 42pt, 4:3).
- [x] Empty `lines: []` or `type: "blank"` produces a fully black slide.
- [x] `chorus` (or any type in `bold_section_types`) renders bold; other types regular.
- [x] `requirements.txt` at repo root pins `python-pptx==1.0.2`.
- [x] Dockerfile adds a `/opt/python` venv layer that installs `python-pptx`; `python3 bin/render_pptx.py` runs in the built image.
- [x] Local dev setup documented in `README.md` (brew + pip3).
- [x] `Slides::Paginator` unit tests cover:
  - 4 short lines → 1 page.
  - 11 short lines → 10/1 split.
  - One 40-char line costs 2; 5 long lines + 1 short → splits.
  - Empty input returns `[]` (no pages) for a fully empty section is acceptable; `[[]]` (one blank page) for a section explicitly marked blank — pick one and document.
- [x] `Slides::Fingerprint` unit tests cover:
  - Identical input → identical hash.
  - Reordered hash keys inside `slides_json` → same hash (canonicalization works).
  - Changing one line → different hash.
  - Changing `Theme::VERSION` → different hash.
- [x] `Slides::PptxRenderer` unit test stubs `Open3.capture3` and asserts:
  - Payload includes correct theme constants.
  - Sections are paginated with source `type` preserved.
  - Orphaned sequence ids (not in `slides_json`) are skipped.
  - Non-zero exit raises `Slides::RenderError` with stderr.
- [x] `GenerateMusicPptxJob` integration tests cover:
  - Cache hit: job is a no-op when fingerprint matches and attachment exists.
  - Cache miss: job calls the renderer, attaches the result, updates fingerprint, broadcasts the ready Turbo Stream.
  - Render failure after retries: job clears fingerprint and broadcasts an error toast.
- [x] Music show page has a "Baixar PPTX" button wrapped in a Turbo Frame.
- [x] Cache-hit click triggers immediate download with exactly one "Pronto! Baixando..." toast.
- [x] Cache-miss click shows "Gerando seu PPTX..." toast + spinner; ActionCable broadcast on job completion swaps spinner for auto-download link and appends "Pronto! Baixando..." toast.
- [x] Final job failure broadcasts an error toast "Erro ao gerar PPTX. Tente novamente."
- [x] `SlideDeck` declares `broadcasts_to` and the channel name matches the frame subscription.

## Blocked by

- [`1-slide-data-model.md`](./1-slide-data-model.md)
- [`2-music-form-slide-editor.md`](./2-music-form-slide-editor.md)

## When done

After completing the work and getting tests green:

1. Mark each acceptance-criterion checkbox above as completed (`[x]`).
2. Append a `## Status` section recording: completion date, files added/changed, key verification output, and test suite totals.

## Status

**Completed** — 2026-05-16.

Decision documented for the empty-input paginator contract: `Slides::Paginator.call([])` returns `[[]]` (one blank physical page). This keeps the renderer code uniform — every section in the sequence yields at least one physical slide, and the renderer never has to special-case empty sections; the Python script paints them as a fully black blank slide.

Files added:

- `bin/render_pptx.py` — Python boundary (~140 lines, depends only on `python-pptx`).
- `requirements.txt` — pins `python-pptx==1.0.2`.
- `app/services/slides/paginator.rb` — greedy visual-cost paginator.
- `app/services/slides/fingerprint.rb` — canonicalized SHA1 of `(slides_json, slide_sequence, theme_version)`.
- `app/services/slides/render_error.rb` — exception class autoloaded for job retry_on.
- `app/services/slides/pptx_renderer.rb` — Open3-based renderer with 30s `Timeout`.
- `app/jobs/generate_music_pptx_job.rb` — idempotent job with `retry_on Slides::RenderError, attempts: 3`.
- `app/controllers/repertoire/musics/pptx_controller.rb` — cache-hit/miss Turbo Stream router.
- `app/views/repertoire/musics/pptx/cache_hit.turbo_stream.erb` and `cache_miss.turbo_stream.erb`.
- `app/views/repertoire/musics/slide_decks/_pptx_ready.html.erb` — auto-clicking download anchor partial.
- `app/views/shared/toasts/_toast.html.erb` — toast partial with `data-controller="toast"`.
- `app/javascript/controllers/toast_controller.js` — auto-dismiss after 4000ms.
- `app/javascript/controllers/auto_download_controller.js` — programmatic click on connect, idempotent via `data-auto-download-fired`.
- `test/services/slides/paginator_test.rb` — 4 tests.
- `test/services/slides/fingerprint_test.rb` — 7 tests.
- `test/services/slides/pptx_renderer_test.rb` — 6 tests (stubs `Open3.capture3`).
- `test/jobs/generate_music_pptx_job_test.rb` — 4 integration tests (cache hit no-op, cache miss render+attach+broadcast, retry exhaustion).
- `test/controllers/repertoire/musics/pptx_controller_test.rb` — 3 controller tests (cache hit, cache miss, fingerprint-match-but-missing-attachment).
- `db/migrate/20260516231553_create_active_storage_tables.active_storage.rb` — installed by `bin/rails active_storage:install` to support `has_one_attached :pptx`.

Files changed:

- `app/models/slide_deck.rb` — added `has_one_attached :pptx` and `broadcasts_to ->(deck) { "slide_deck_#{deck.id}" }`.
- `app/services/slides/theme.rb` — `Slides::Theme::V1.to_h` for the Python payload.
- `app/views/repertoire/musics/show.html.erb` — replaced the "Slides (PPTX) Em breve" dropdown placeholder with a turbo-frame-wrapped "Baixar PPTX" button hitting `repertoire_music_pptx_path`.
- `app/views/layouts/application.html.erb` — added `<div id="toasts">` container.
- `config/routes.rb` — added `get "pptx" → musics/pptx#show`.
- `Dockerfile` — installs `python3 python3-pip python3-venv`, creates `/opt/python` venv with `python-pptx`, prepends `/opt/python/bin` to `PATH`.
- `README.md` — local-dev Python setup section.
- `test/models/slide_deck_test.rb` — broadcasts_to smoke test.

Key verification output:

- `python3 bin/render_pptx.py < sample.json > out.pptx` produced a valid `Microsoft OOXML` file. Inspection showed 3 slides at 10×7.5 in, chorus runs `bold=True`, verse runs `bold=False`, blank slide has no text runs.
- End-to-end via Rails: `Slides::PptxRenderer.call(deck)` produced a 29 KB pptx with the expected Calibri/42pt/bold-chorus formatting.

Test suite totals:

- `bin/rails test`: **152 runs, 449 assertions, 0 failures, 0 errors, 0 skips**.
- Slice 3 tests in isolation:
  - `test/services/slides/paginator_test.rb` — 4 runs, 9 assertions.
  - `test/services/slides/fingerprint_test.rb` — 7 runs, 8 assertions.
  - `test/services/slides/pptx_renderer_test.rb` — 6 runs, 16 assertions.
  - `test/jobs/generate_music_pptx_job_test.rb` — 4 runs, 12 assertions.
  - `test/controllers/repertoire/musics/pptx_controller_test.rb` — 3 runs, 16 assertions.

Notes:

- `Slides::RenderError` lives in its own file under `app/services/slides/` so Zeitwerk autoloads it before the job class references it in `retry_on`.
- `retry_on Slides::RenderError, attempts: 3, wait: :polynomially_longer` with a block calls `on_render_failure` after attempts exhaust; the block clears `pptx_fingerprint` and broadcasts the error toast. Tested via `perform_enqueued_jobs`.
- The Music show page's "Baixar PPTX" entry submits via Turbo Stream — Turbo replaces the `pptx_download_#{deck.id}` frame either with an `auto-download` anchor (cache hit) or with a spinner that subscribes to `slide_deck_#{deck.id}` (cache miss). The broadcast on job completion swaps the spinner for the auto-download anchor and appends a "Pronto! Baixando..." toast.
- HTML preview / browser smoke testing of the toast and auto-download flows was not performed in this session; verification is limited to controller, model, job, and renderer tests plus the end-to-end Python smoke probe.
