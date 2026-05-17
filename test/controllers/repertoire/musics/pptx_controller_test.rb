require "test_helper"

class Repertoire::Musics::PptxControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:user)
    @music = repertoire_musics(:one)
    @slide_deck = @music.slide_deck
    @slide_deck.update!(
      slides_json: [
        { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha" ] }
      ],
      slide_sequence: [ "verse_1" ]
    )
  end

  test "cache hit responds with an auto-download turbo stream and a single ready toast" do
    expected = Slides::Fingerprint.call(@slide_deck.slides_json, @slide_deck.slide_sequence, Slides::Theme::VERSION)
    @slide_deck.pptx.attach(io: StringIO.new("PRECACHED"), filename: "vem-espirito-santo.pptx", content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation")
    @slide_deck.update_column(:pptx_fingerprint, expected)

    assert_no_enqueued_jobs only: GenerateMusicPptxJob do
      get repertoire_music_pptx_path(@music.author, @music),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "auto-download", response.body
    assert_match "Pronto!", response.body
    assert_match "O download do PPTX começou", response.body
  end

  test "cache miss enqueues the generation job and responds with a spinner + generating toast" do
    @slide_deck.update_column(:pptx_fingerprint, nil)

    assert_enqueued_with(job: GenerateMusicPptxJob, args: [ @slide_deck.id ]) do
      get repertoire_music_pptx_path(@music.author, @music),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "Gerando seu PPTX", response.body
    assert_match "turbo-cable-stream-source", response.body
  end

  test "cache miss when fingerprint matches but attachment is missing still enqueues a job" do
    expected = Slides::Fingerprint.call(@slide_deck.slides_json, @slide_deck.slide_sequence, Slides::Theme::VERSION)
    @slide_deck.update_column(:pptx_fingerprint, expected)
    # No attachment

    assert_enqueued_with(job: GenerateMusicPptxJob, args: [ @slide_deck.id ]) do
      get repertoire_music_pptx_path(@music.author, @music),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end
end
