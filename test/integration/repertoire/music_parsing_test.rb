require "test_helper"

class Repertoire::MusicIntegrationTest < ActiveSupport::TestCase
  test "should parse content_raw into content_json on save" do
    music = Repertoire::Music.new(
      title: "Vem e eu mostrarei",
      content_raw: "E                  C#m\nVem e eu mostrarei que o meu caminho"
    )

    music.save!

    assert_equal "[E]Vem e eu mostrarei [C#m]que o meu caminho", music.content_raw
    assert_not_nil music.content_json
    assert_equal "E", music.content_json.first["lines"].first["parts"].first["chord"]
  end
end
