require "test_helper"

class SetlistItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @music = repertoire_musics(:one)
    @other_music = repertoire_musics(:two)
    @setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")
    sign_in_as @user
  end

  test "reorder updates item positions according to provided order" do
    item_a = @setlist.items.create!(music: @music, key: "C")
    item_b = @setlist.items.create!(music: @other_music, key: "G")
    item_c = @setlist.items.create!(music: @music, key: "D")

    patch reorder_setlist_items_url, params: { ids: [ item_c.id, item_a.id, item_b.id ] }

    assert_response :success
    assert_equal 1, item_c.reload.position
    assert_equal 2, item_a.reload.position
    assert_equal 3, item_b.reload.position
  end

  test "reorder only affects items belonging to current user" do
    other_user = users(:admin)
    other_setlist = Setlist.create!(user: other_user, name: "Outra", setlist_type: "missa")
    foreign_item = other_setlist.items.create!(music: @music, key: "C")
    own_item = @setlist.items.create!(music: @music, key: "G")
    original_position = foreign_item.position

    patch reorder_setlist_items_url, params: { ids: [ foreign_item.id, own_item.id ] }

    assert_equal original_position, foreign_item.reload.position
  end

  test "update changes only the setlist item key without touching saved_music" do
    saved = SavedMusic.create!(user: @user, music: @music, preferred_key: "C")
    item = @setlist.items.create!(music: @music, key: "C")

    patch setlist_item_url(item), params: { setlist_item: { key: "F" } }

    assert_redirected_to setlist_url(@setlist)
    assert_equal "F", item.reload.key
    assert_equal "C", saved.reload.preferred_key
  end

  test "create accepts mass_part_id" do
    entrada = repertoire_mass_parts(:two)

    assert_difference("SetlistItem.count") do
      post setlist_items_url, params: {
        setlist_item: {
          setlist_id: @setlist.id,
          music_id: @music.id,
          key: "G",
          mass_part_id: entrada.id
        }
      }
    end

    assert_equal entrada, SetlistItem.last.mass_part
  end

  test "create on missa setlist auto-assigns mass_part from music's first mass_part" do
    entrada = repertoire_mass_parts(:two)
    Repertoire::MusicMassPart.create!(music: @music, mass_part: entrada)

    assert_difference("SetlistItem.count") do
      post setlist_items_url, params: {
        setlist_item: {
          setlist_id: @setlist.id,
          music_id: @music.id,
          key: "G"
        }
      }
    end

    assert_equal entrada, SetlistItem.last.mass_part
  end

  test "create on non-missa setlist leaves mass_part nil when not provided" do
    evento = Setlist.create!(user: @user, name: "Evento", setlist_type: "evento")
    entrada = repertoire_mass_parts(:two)
    Repertoire::MusicMassPart.create!(music: @music, mass_part: entrada)

    post setlist_items_url, params: {
      setlist_item: { setlist_id: evento.id, music_id: @music.id, key: "G" }
    }

    assert_nil SetlistItem.last.mass_part_id
  end

  test "destroy removes the setlist item" do
    item = @setlist.items.create!(music: @music, key: "C")

    assert_difference("SetlistItem.count", -1) do
      delete setlist_item_url(item)
    end
    assert_redirected_to setlist_url(@setlist)
  end

  test "create on existing music shows duplicate flash and does not insert" do
    @setlist.items.create!(music: @music, key: "C")

    assert_no_difference("SetlistItem.count") do
      post setlist_items_url, params: {
        setlist_item: { setlist_id: @setlist.id, music_id: @music.id, key: "C" }
      }
    end

    follow_redirect!
    assert_match /já está no roteiro/i, response.body
    assert_match /Adicionar mesmo assim/, response.body
  end

  test "create with force=true adds even when music is already in setlist" do
    @setlist.items.create!(music: @music, key: "C")

    assert_difference("SetlistItem.count") do
      post setlist_items_url(force: true), params: {
        setlist_item: { setlist_id: @setlist.id, music_id: @music.id, key: "D" }
      }
    end

    assert_redirected_to setlist_url(@setlist)
  end

  test "destroy is scoped to current user" do
    other_user = users(:admin)
    other_setlist = Setlist.create!(user: other_user, name: "Outra", setlist_type: "missa")
    foreign_item = other_setlist.items.create!(music: @music, key: "C")

    assert_no_difference("SetlistItem.count") do
      delete setlist_item_url(foreign_item)
      assert_response :not_found
    end
  end

  test "new filters by part when part param is set (matching the slot)" do
    entrada = repertoire_mass_parts(:two)
    Repertoire::MusicMassPart.create!(music: @music, mass_part: entrada)

    get new_setlist_item_url, params: { setlist_id: @setlist.id, mass_part_id: entrada.id, part: entrada.slug }

    assert_response :success
    assert_match @music.title, response.body
    assert_no_match /#{@other_music.title}/, response.body
  end

  test "new searches across all songs when part filter is cleared" do
    entrada = repertoire_mass_parts(:two)

    get new_setlist_item_url, params: { setlist_id: @setlist.id, mass_part_id: entrada.id, q: @other_music.title.split.first }

    assert_response :success
    assert_match @other_music.title, response.body
  end

  test "new with library=mine filters by the user's saved repertoire" do
    SavedMusic.create!(user: @user, music: @music)

    get new_setlist_item_url, params: { setlist_id: @setlist.id, library: "mine" }

    assert_response :success
    assert_match @music.title, response.body
    assert_no_match /#{@other_music.title}/, response.body
  end
end
