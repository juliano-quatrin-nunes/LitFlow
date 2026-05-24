require "test_helper"

class Setlists::PptxControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:user)
    @user = users(:user)
    @music = repertoire_musics(:one)
    @music.slide_deck.update!(
      slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha" ] } ],
      slide_sequence: [ "verse_1" ]
    )
    @setlist = Setlist.create!(user: @user, name: "Celebração", setlist_type: "evento")
    @setlist.items.create!(item: @music)
  end

  test "cache hit responds with auto-download turbo stream and a ready toast" do
    expected = Slides::Fingerprint.for_setlist(@setlist)
    @setlist.pptx.attach(io: StringIO.new("PRECACHED"), filename: "celebracao.pptx", content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation")
    @setlist.update_column(:pptx_fingerprint, expected)

    assert_no_enqueued_jobs only: GenerateSetlistPptxJob do
      get setlist_pptx_path(@setlist),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "auto-download", response.body
    assert_match "Pronto!", response.body
  end

  test "cache miss enqueues the job and responds with a generating toast + stream source" do
    @setlist.update_column(:pptx_fingerprint, nil)

    assert_enqueued_with(job: GenerateSetlistPptxJob, args: [ @setlist.id ]) do
      get setlist_pptx_path(@setlist),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_match "Gerando seu PPTX", response.body
    assert_match "turbo-cable-stream-source", response.body
  end

  test "fingerprint matches but attachment missing still triggers a cache miss" do
    expected = Slides::Fingerprint.for_setlist(@setlist)
    @setlist.update_column(:pptx_fingerprint, expected)

    assert_enqueued_with(job: GenerateSetlistPptxJob, args: [ @setlist.id ]) do
      get setlist_pptx_path(@setlist),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  test "only the owner can request a setlist PPTX" do
    other = users(:admin)
    foreign = Setlist.create!(user: other, name: "Outro", setlist_type: "evento")

    get setlist_pptx_path(foreign), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :not_found
  end
end
