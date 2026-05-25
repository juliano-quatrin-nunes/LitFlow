# Cifra PDF/DOCX Export & Enhanced Copy

This series of tasks implements the ability to export song sheets (cifras) in PDF and DOCX formats, along with an enhanced "Copy Chords" feature that supports rich-text formatting (bold chords).

## Parent PRD
[`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)

## Implementation Plan

The work is broken into 6 vertical slices (tracer bullets):

1. **[1-core-formatting-and-clipboard.md](./1-core-formatting-and-clipboard.md)** (DONE)
   Foundation slice building the `Repertoire::CifraFormatterService` to handle aligned chord/lyric formatting and updating the `ClipboardController` for rich-text copying.

2. **[2-export-infrastructure-and-python.md](./2-export-infrastructure-and-python.md)** (DONE)
   Infrastructure for background generation: schema fingerprints, Active Storage attachments, and the Python-based renderers (`fpdf2`, `python-docx`).

3. **[3-music-pdf-export.md](./3-music-pdf-export.md)** (DONE)
   End-to-end PDF export for individual songs, including background jobs, controllers, and UI integration in the "Ações" dropdown.

4. **[4-music-docx-export.md](./4-music-docx-export.md)** (DONE)
   End-to-end DOCX export for individual songs, reusing the infrastructure from slice 3.

5. **[5-setlist-pdf-export.md](./5-setlist-pdf-export.md)** (AFK)
   End-to-end PDF export for entire setlists, generating a consolidated booklet with all songs in their respective keys.

6. **[6-setlist-docx-export.md](./6-setlist-docx-export.md)** (AFK)
   Final slice providing DOCX export for setlists.

## Context

This feature follows the architectural patterns established by the **Slides and PPTX Export** project:
- **Asynchronous generation:** Long-running document renders happen in background jobs.
- **Fingerprinted caching:** Files are attached to models and only regenerated when inputs (content, key, theme) change.
- **Turbo Stream feedback:** Users get immediate feedback ("Gerando...") and auto-downloads when ready via ActionCable/Turbo.
- **Python boundary:** High-fidelity document rendering is offloaded to mature Python libraries.

## Key Constraints
- **Font:** Roboto Mono (Mono-spaced is required for chord/lyric alignment).
- **Size:** 12pt for content, 14pt Bold for titles.
- **Styling:** Chords MUST be bold.
- **Copy:** Must preserve bolding when pasted into word processors.
