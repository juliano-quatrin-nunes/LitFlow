## Parent

PRD: [`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)
Index: [`docs/tasks/cifra-pdf-docx-export/README.md`](./README.md)

## What to build

End-to-end DOCX export for individual songs. Reuses the infrastructure and patterns from slice 3.

### Modules to build

#### `Repertoire::MusicCifraRenderer` Update
- Add `.render_docx(payload) → binary_docx`.
- Calls `bin/render_docx.py`.

#### `GenerateMusicCifraJob` Update
- Support a `format` parameter (pdf or docx).
- Attach to the correct property (`cifra_pdf` or `cifra_docx`).

#### `Repertoire::Musics::CifraDocxController` (`app/controllers/repertoire/musics/cifra_docx_controller.rb`)
- Follows the same pattern as the PDF controller.

### UI Changes

- Update `app/views/repertoire/musics/show.html.erb`:
  - Add a "DOCX (Cifra)" link in the "Ações" menu.

## Acceptance criteria

- [x] `GenerateMusicCifraJob` handles `format: :docx`.
- [x] Clicking "DOCX (Cifra)" triggers a "Gerando..." toast.
- [x] The downloaded DOCX uses Roboto Mono and correctly bolds chords.
- [x] The DOCX layout matches the PDF layout.

## Blocked by

- [3-music-pdf-export.md](./3-music-pdf-export.md)
