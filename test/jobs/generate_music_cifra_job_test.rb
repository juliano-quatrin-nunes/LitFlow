require "test_helper"

class GenerateMusicCifraJobTest < ActiveJob::TestCase
  setup do
    @music = repertoire_musics(:one)
    @music.cifra_pdf.detach
    @music.cifra_docx.detach
    @music.update!(cifra_fingerprint: nil)
  end

  test "generates and attaches PDF and DOCX on cache miss" do
    target_key = "G"
    
    # We expect some calls to happen. We'll verify side effects.
    assert_nothing_raised do
      GenerateMusicCifraJob.perform_now(@music.id, target_key)
    end

    @music.reload
    assert @music.cifra_pdf.attached?
    assert @music.cifra_docx.attached?
    assert_not_nil @music.cifra_fingerprint
  end

  test "skips generation on cache hit" do
    target_key = "G"
    fingerprint = Digest::SHA1.hexdigest("#{@music.content_json.to_json}-#{target_key}-v1")
    
    @music.cifra_pdf.attach(io: StringIO.new("%PDF-1.4"), filename: "test.pdf", content_type: "application/pdf")
    @music.cifra_docx.attach(io: StringIO.new("PK"), filename: "test.docx", content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    @music.update!(cifra_fingerprint: fingerprint)

    # If it skips, the timestamp shouldn't change or it shouldn't be re-attached.
    # We can check that the blobs IDs remain the same.
    pdf_blob_id = @music.cifra_pdf.blob_id
    docx_blob_id = @music.cifra_docx.blob_id

    GenerateMusicCifraJob.perform_now(@music.id, target_key)

    @music.reload
    assert_equal pdf_blob_id, @music.cifra_pdf.blob_id
    assert_equal docx_blob_id, @music.cifra_docx.blob_id
  end
end
