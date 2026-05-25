# Product Requirements Document: Cifra PDF/DOCX Export & Enhanced Copy

## Problem Statement

Musicians and liturgy planners need professional-looking song sheets (cifras) that they can print or edit. While the system currently provides a PPTX export for projection, it lacks a way to export the actual chords and lyrics for the musicians. Musicians need these in their preferred keys (transposed). Additionally, the existing "Copy Chords" functionality is limited to plain text, making it harder for musicians to distinguish chords from lyrics when pasting into their own documents.

## Solution

Introduce PDF and DOCX export capabilities for both individual songs and entire setlists. These exports will adhere to a strict formatting standard: Roboto Mono font, size 12 for content, size 14 bold for titles, and bold styling for chords. The "Copy Chords" button will be upgraded to support rich-text copying, ensuring chords remain bold when pasted. A central formatting service will handle the logic of aligning chords and lyrics, supporting transposed keys.

## User Stories

### Exporting Singular Music

1. **[MUST]** As a musician, I want to download a PDF of a song in the current selected key, so I can print it for my folder.
2. **[MUST]** As a musician, I want to download a DOCX of a song in the current selected key, so I can further customize it in a word processor.
3. **[MUST]** As a musician, the exported files must use Roboto Mono 12pt, with the Title in Roboto Mono 14pt Bold.
4. **[MUST]** As a musician, the exported files must have chords in bold and lyrics in regular weight.
5. **[MUST]** As a musician, the exported files must follow the "chord-on-top-of-lyric" alignment (Cifra format).
6. **[MUST]** As a musician, I want to trigger these exports from the "Ações" dropdown on the song page.
7. **[MUST]** As a musician, I want to see a "Gerando seu PDF/DOCX..." toast when the file is being prepared, and a "Pronto!" toast when the download starts, similar to the PPTX flow.
8. **[MUST]** As a musician, changing the key on the song page and then exporting should produce a file in that new key.

### Exporting Setlists

9. **[MUST]** As a liturgy planner, I want to download a single PDF containing all songs in a setlist in their specified keys, so I can print a complete booklet for the band.
10. **[MUST]** As a liturgy planner, I want to download a single DOCX containing all songs in a setlist, following the setlist order.
11. **[MUST]** As a liturgy planner, each song in the setlist export should start on a new page.
12. **[MUST]** As a liturgy planner, the setlist export should follow the same formatting standards as singular music exports.
13. **[MUST]** As a liturgy planner, I want to trigger these exports from the "Ações" dropdown on the setlist page.

### Enhanced Copy Chords

14. **[MUST]** As a musician, when I click "Copiar Cifras", the content in my clipboard should have bold formatting on the chords.
15. **[MUST]** As a musician, the "Copiar Cifras" action must preserve the section markers like `[Refrão]`.
16. **[MUST]** As a musician, the "Copiar Cifras" action must respect the current selected key.

## Implementation Decisions

### Schema Changes

- **`repertoire_musics` table:**
  - Add `cifra_fingerprint :string` — SHA1 of `(content_json, key, Formatter::VERSION)`.
  - `has_one_attached :cifra_pdf`.
  - `has_one_attached :cifra_docx`.
- **`setlists` table:**
  - Add `cifra_fingerprint :string` — SHA1 of `(items_data, Formatter::VERSION)`.
  - `has_one_attached :cifra_pdf`.
  - `has_one_attached :cifra_docx`.

### Modules

- **`Repertoire::CifraFormatterService` (new, deep):** `.call(content_json) → formatted_payload`.
  - This service is the "brain" of the feature. It takes a `content_json` (already transposed) and returns a structured representation of lines and segments.
  - Each segment identifies as "chord", "lyric", or "label".
  - It handles the padding/alignment logic previously found in `MusicParserService#generate_plain_text`.
  - This payload is used for both the HTML clipboard copy and the JSON sent to Python renderers.

- **`Repertoire::MusicCifraRenderer` (boundary service):** Calls Python scripts via `Open3`.
  - `.render_pdf(payload) → binary_pdf`.
  - `.render_docx(payload) → binary_docx`.

- **Python Boundary:**
  - `bin/render_pdf.py`: Uses `fpdf2` or `reportlab` to generate the PDF with the required font and styles.
  - `bin/render_docx.py`: Uses `python-docx` to generate the Word document.
  - `requirements.txt` will be updated with these libraries.

- **Background Jobs:**
  - `GenerateMusicCifraJob` and `GenerateSetlistCifraJob`.
  - These jobs will calculate the fingerprint, check cache, call renderers, and attach files.
  - They will broadcast status updates via Turbo Streams/ActionCable, exactly like the PPTX jobs.

### UI & UX

- **Clipboard Controller Update:** Enhance `app/javascript/controllers/clipboard_controller.js` to support `text/html` in addition to `text/plain` if a specific data attribute is present.
- **Actions Dropdown:** Update `app/views/repertoire/musics/show.html.erb` and `app/views/setlists/show.html.erb` to include the new export buttons.
- **Font Assets:** Ensure Roboto Mono is available for the Python renderers.

## Testing Decisions

- **`Repertoire::CifraFormatterService`**: Extensive unit tests checking alignment for various chord/lyric combinations, labels, and sections. Ensure transposition doesn't break alignment.
- **Fingerprinting**: Verify that changing the key or content correctly invalidates the cached PDF/DOCX.
- **Integration**: Verify the end-to-end flow from button click to job execution to file attachment and download trigger.
- **Prior Art**: Follow the patterns in `test/services/slides/pptx_renderer_test.rb` and `app/jobs/generate_music_pptx_job.rb`.

## Out of Scope

- Custom fonts or themes (fixed to Roboto Mono).
- Custom headers/footers/page numbers (beyond song title and author).
- Inline editing of the PDF/DOCX layout.
- Exporting to other formats (RTF, ODT, etc.).

## Further Notes

- Task List: [`docs/tasks/cifra-pdf-docx-export/README.md`](../tasks/cifra-pdf-docx-export/README.md)
- The decision to use Python for PDF/DOCX is for consistency with the existing PPTX renderer and to leverage the robust `python-docx` and `fpdf2` libraries.
- The "Copy Chords" button will now produce a rich-text payload. When pasted into Google Docs or Word, chords will appear bold. When pasted into a plain text editor, it will fall back to standard text (handled by the browser's clipboard API).
