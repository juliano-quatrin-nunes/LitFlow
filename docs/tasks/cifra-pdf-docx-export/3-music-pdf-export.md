## Parent

PRD: [`docs/prds/cifra-pdf-docx-export.md`](../../prds/cifra-pdf-docx-export.md)
Index: [`docs/tasks/cifra-pdf-docx-export/README.md`](./README.md)

## What to build

End-to-end PDF export for individual songs. This involves the background job, controller, and UI integration.

### Modules to build

#### `Repertoire::MusicCifraRenderer` (`app/services/repertoire/music_cifra_renderer.rb`)
- Wrapper for calling `bin/render_pdf.py`.
- Encapsulates the `Open3` logic.

#### `GenerateMusicCifraJob` (`app/jobs/generate_music_cifra_job.rb`)
- Calculates the expected fingerprint: `SHA1(content_json, key, Formatter::VERSION)`.
- If cache hit (fingerprint matches and file attached): broadcast "Ready" and exit.
- If cache miss:
  - Run `Repertoire::CifraFormatterService.call`.
  - Call `Repertoire::MusicCifraRenderer.render_pdf`.
  - Attach the file to `music.cifra_pdf`.
  - Update `cifra_fingerprint`.
  - Broadcast "Ready" via Turbo Streams.

#### `Repertoire::Musics::CifraPdfController` (`app/controllers/repertoire/musics/cifra_pdf_controller.rb`)
- `show` action:
  - Check fingerprint.
  - If hit: Return Turbo Stream for auto-download.
  - If miss: Enqueue job, return Turbo Stream for "Gerando..." spinner.

### UI Changes

- Update `app/views/repertoire/musics/show.html.erb`:
  - Replace the "Em breve" PDF link with a `button_to` the new controller.
  - Ensure it uses `method: :get` and `data: { turbo_stream: true }`.

## Acceptance criteria

- [x] `GenerateMusicCifraJob` correctly handles cache hits and misses.
- [x] `Musics::CifraPdfController` returns the appropriate Turbo Streams.
- [x] Clicking "PDF (Cifra)" in the "Ações" menu triggers a "Gerando..." toast.
- [x] When ready, the PDF download starts automatically.
- [x] The PDF contains the song in the **currently selected key**.
- [x] Changing the key and clicking PDF again correctly regenerates the file.

## Blocked by

- [2-export-infrastructure-and-python.md](./2-export-infrastructure-and-python.md)
