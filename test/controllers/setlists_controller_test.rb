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

  test "show displays orphaned-sequence warning chip with count when overrides reference unknown ids" do
    setlist = Setlist.create!(user: @user, name: "Quebrada", setlist_type: "evento")
    music = repertoire_musics(:one)
    setlist.items.create!(item: music, slide_sequence_override: [ "verse_1", "ghost_section" ])

    get setlist_url(setlist)

    assert_response :success
    assert_select "[data-role=orphaned-sequence-warning]" do
      assert_match /precisam de revisão/i, response.body
      assert_match /1/, response.body
    end
  end

  test "show hides orphaned-sequence warning chip when there are no orphans" do
    setlist = Setlist.create!(user: @user, name: "Limpa", setlist_type: "evento")
    music = repertoire_musics(:one)
    setlist.items.create!(item: music)

    get setlist_url(setlist)

    assert_response :success
    assert_select "[data-role=orphaned-sequence-warning]", false
  end

  test "show exposes 'Baixar PPTX' inside the Ações dropdown" do
    setlist = Setlist.create!(user: @user, name: "Para Baixar", setlist_type: "evento")
    setlist.items.create!(item: repertoire_musics(:one))

    get setlist_url(setlist)

    assert_response :success
    assert_match "Baixar PPTX", response.body
    assert_select "form[action=?]", setlist_pptx_path(setlist)
    assert_select "[data-controller~=dropdown]" do
      assert_select "form[action=?]", setlist_pptx_path(setlist)
    end
  end

  test "show shows a disabled 'PDF (Cifra)' export option under the Ações dropdown" do
    setlist = Setlist.create!(user: @user, name: "Com PDF", setlist_type: "evento")

    get setlist_url(setlist)

    assert_response :success
    assert_match "PDF (Cifra)", response.body
    assert_match "Em breve", response.body
  end
end
