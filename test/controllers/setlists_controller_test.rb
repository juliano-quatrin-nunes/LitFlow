require "test_helper"

class SetlistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    sign_in_as @user
  end

  test "show renders missa setlist with mass part headings" do
    setlist = Setlist.create!(user: @user, name: "Missa Show", setlist_type: "missa")
    entrada = repertoire_mass_parts(:two)
    setlist.items.create!(music: repertoire_musics(:one), mass_part: entrada, key: "C")

    get setlist_url(setlist)

    assert_response :success
    assert_match "Entrada", response.body
    assert_match repertoire_musics(:one).title, response.body
  end

  test "show renders share link button for owners" do
    setlist = Setlist.create!(user: @user, name: "Outra Coisa", setlist_type: "evento")

    get setlist_url(setlist)

    assert_response :success
    assert_match "Compartilhar", response.body
  end

  test "show is forbidden when accessed by a different user" do
    other_user = users(:admin)
    setlist = Setlist.create!(user: other_user, name: "Privado", setlist_type: "missa")

    get setlist_url(setlist)
    assert_response :not_found
  end
end
