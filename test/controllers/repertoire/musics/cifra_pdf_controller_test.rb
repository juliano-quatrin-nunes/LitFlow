require "test_helper"

class Repertoire::Musics::CifraPdfControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    sign_in_as(@user)
    @music = repertoire_musics(:one)
    @author = @music.author
    # Ensure no attachments or fingerprint to force a cache miss
    @music.cifra_pdf.detach
    @music.update!(cifra_fingerprint: nil)
  end

  test "show enqueues job and returns turbo stream when cache miss" do
    assert_enqueued_with(job: GenerateMusicCifraJob, args: [@music.id, "G"]) do
      get repertoire_music_cifra_pdf_path(author_slug: @author.slug, id: @music.slug), params: { key: "G" }, as: :turbo_stream
    end

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /Gerando PDF.../, response.body
  end

  test "show returns download stream when cache hit" do
    fingerprint = Digest::SHA1.hexdigest("#{@music.content_json.to_json}-G-v1")
    @music.cifra_pdf.attach(io: StringIO.new("%PDF"), filename: "test.pdf", content_type: "application/pdf")
    @music.update!(cifra_fingerprint: fingerprint)

    get repertoire_music_cifra_pdf_path(author_slug: @author.slug, id: @music.slug), params: { key: "G" }, as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream/, response.body
    # It should have a download toast or similar
    assert_match /Pronto!/, response.body
  end
end
