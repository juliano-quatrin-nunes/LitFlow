require "test_helper"

class Repertoire::MusicCifraRendererTest < ActiveSupport::TestCase
  test "renders a PDF from a payload" do
    payload = {
      title: "Test Music",
      author: "Test Author",
      sections: [
        {
          type: "verse",
          lines: [
            { chords: "G  C", lyrics: "Hello world" }
          ]
        }
      ]
    }

    pdf_binary = Repertoire::MusicCifraRenderer.render_pdf(payload)

    assert_not_nil pdf_binary
    assert pdf_binary.start_with?("%PDF")
  end

  test "renders a DOCX from a payload" do
    payload = {
      title: "Test Music",
      author: "Test Author",
      sections: [
        {
          type: "verse",
          lines: [
            { chords: "G  C", lyrics: "Hello world" }
          ]
        }
      ]
    }

    docx_binary = Repertoire::MusicCifraRenderer.render_docx(payload)

    assert_not_nil docx_binary
    # ZIP signature for docx
    assert docx_binary.start_with?("PK\x03\x04")
  end
end
