require "test_helper"

class PublicSetlistTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:user)
    @setlist = Setlist.create!(user: @owner, name: "Missa Pública", setlist_type: "missa")
    @setlist.items.create!(music: repertoire_musics(:one), key: "G")
  end

  test "guest can view setlist by uid without authentication" do
    get public_setlist_path(uid: @setlist.uid)

    assert_response :success
    assert_match @setlist.name, response.body
    assert_match @setlist.items.first.music.title, response.body
  end

  test "guest cannot edit setlist via public view" do
    get public_setlist_path(uid: @setlist.uid)

    assert_no_match /Editar Roteiro/, response.body
    assert_no_match /Excluir Roteiro/, response.body
  end

  test "invalid uid returns 404" do
    get public_setlist_path(uid: "non-existent-uid")
    assert_response :not_found
  end
end
