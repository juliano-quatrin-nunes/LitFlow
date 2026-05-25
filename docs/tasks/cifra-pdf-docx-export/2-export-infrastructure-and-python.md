## Parent

PRD: [`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)
Index: [`docs/tasks/cifra-pdf-docx-export/README.md`](./README.md)

## What to build

Setup the infrastructure for PDF/DOCX generation. This includes database migrations for caching (fingerprints), Active Storage attachments, and the Python-based rendering scripts.

### Schema

Add caching columns to `repertoire_musics` and `setlists`:
- `cifra_fingerprint :string` (SHA1 of inputs + Formatter version).

### Attachments

- `Repertoire::Music`: `has_one_attached :cifra_pdf`, `has_one_attached :cifra_docx`.
- `Setlist`: `has_one_attached :cifra_pdf`, `has_one_attached :cifra_docx`.

### Python Renderers (`bin/`)

#### `bin/render_pdf.py`
- Library: `fpdf2` (fast, mono-font support).
- Reads JSON from `stdin`.
- Sets font to "Roboto Mono" (must embed the font file).
- Title: 14pt Bold.
- Content: 12pt.
- Chords: Bold.
- Lyrics: Regular.
- Writes binary to `stdout`.

#### `bin/render_docx.py`
- Library: `python-docx`.
- Similar logic to PDF: Styles for Title (14pt Bold), Chords (Bold), and Lyrics (Regular).
- Font: Roboto Mono.

### Assets
- Download and place Roboto Mono (Regular and Bold) TTF files in `vendor/fonts/` or `app/assets/fonts/` (ensure Python can access them).

### Requirements
- Update `requirements.txt`:
  - `fpdf2==2.7.8`
  - `python-docx==1.1.0`

## Acceptance criteria

- [x] Migrations run successfully, adding `cifra_fingerprint` to both tables.
- [x] `bin/render_pdf.py` exists and can generate a simple PDF with bold text and Roboto Mono when called manually.
- [x] `bin/render_docx.py` exists and can generate a simple DOCX with bold text and Roboto Mono.
- [x] `requirements.txt` is updated.
- [x] Roboto Mono font files are present in the repository and accessible by the Python scripts.
- [x] Dockerfile/CI steps (if any) are updated to include the new Python dependencies.

## Blocked by

- [1-core-formatting-and-clipboard.md](./1-core-formatting-and-clipboard.md) (Needs the formatter logic to know what JSON to send).
