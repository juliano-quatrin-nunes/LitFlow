require "test_helper"

class GenerateSetlistCifraJobTest < ActiveJob::TestCase
  setup do
    @setlist = setlists(:one)
    @setlist.cifra_pdf.detach
    @setlist.cifra_docx.detach
    @setlist.update!(cifra_fingerprint: nil)
  end

  test "generates and attaches PDF and DOCX for setlist" do
    assert_nothing_raised do
      GenerateSetlistCifraJob.perform_now(@setlist.id, format: :pdf)
    end

    @setlist.reload
    assert @setlist.cifra_pdf.attached?
    assert @setlist.cifra_docx.attached?
    assert_not_nil @setlist.cifra_fingerprint
  end
end
