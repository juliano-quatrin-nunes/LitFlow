## Parent

PRD: [`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)
Index: [`docs/tasks/cifra-pdf-docx-export/README.md`](./README.md)

## What to build

Consolidated DOCX for entire setlists.

### Modules to build

#### `GenerateSetlistCifraJob` Update
- Support `format: :docx`.

#### `Setlists::CifraDocxController` (`app/controllers/setlists/cifra_docx_controller.rb`)
- Standard cache-or-enqueue pattern.

#### Python Renderer Update (`bin/render_docx.py`)
- Support a list of songs with page breaks between them.

### UI Changes

- Update `app/views/setlists/show.html.erb`:
  - Add "DOCX (Cifra)" to the "Ações" menu.

## Acceptance criteria

- [ ] `GenerateSetlistCifraJob` handles `format: :docx`.
- [ ] The downloaded DOCX follows setlist order and includes page breaks.
- [ ] Formatting standards (Roboto Mono, Bold Chords) are maintained.

## Blocked by

- [4-music-docx-export.md](./4-music-docx-export.md)
- [5-setlist-pdf-export.md](./5-setlist-pdf-export.md)
