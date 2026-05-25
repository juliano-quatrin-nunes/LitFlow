## Parent

PRD: [`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)
Index: [`docs/tasks/cifra-pdf-docx-export/README.md`](./README.md)

## What to build

Consolidated PDF booklet for entire setlists.

### Modules to build

#### `GenerateSetlistCifraJob` (`app/jobs/generate_setlist_cifra_job.rb`)
- Collects `content_json` and `key` for every song in the setlist.
- Runs `Repertoire::TranspositionService` for each song if needed.
- Runs `Repertoire::CifraFormatterService` for each song.
- Sends a bulk payload (array of song payloads) to the PDF renderer.
- Fingerprint based on the combination of all items and their keys.

#### `Setlists::CifraPdfController` (`app/controllers/setlists/cifra_pdf_controller.rb`)
- Standard cache-or-enqueue pattern.

#### Python Renderer Update (`bin/render_pdf.py`)
- Support a list of songs.
- Insert a page break between songs.

### UI Changes

- Update `app/views/setlists/show.html.erb`:
  - Replace the "Em breve" PDF link in the "Ações" menu with a `button_to` the new controller.

## Acceptance criteria

- [ ] `GenerateSetlistCifraJob` correctly aggregates all songs in the setlist.
- [ ] Each song in the PDF booklet starts on its own page.
- [ ] Songs appear in the correct setlist `position` order.
- [ ] Each song uses the key specified in its `SetlistItem`.
- [ ] The "Ações" menu on the Setlist page allows downloading the full booklet.

## Blocked by

- [3-music-pdf-export.md](./3-music-pdf-export.md)
