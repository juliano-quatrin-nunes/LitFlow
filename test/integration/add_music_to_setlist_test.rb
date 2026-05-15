require "test_helper"

class AddMusicToSetlistTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    post session_path, params: { email_address: @user.email_address, password: "password" }
    
    @setlist = Setlist.create!(
      user: @user,
      name: "Missa Teste",
      setlist_type: "missa"
    )
    
    @music = repertoire_musics(:one) # assuming we have a music fixture
  end

  test "user can add a music to a setlist from the music page" do
    get repertoire_music_by_author_show_path(@music.author, @music)
    assert_response :success
    assert_select "form[action=?]", setlist_items_path

    assert_difference("SetlistItem.count") do
      post setlist_items_path, params: {
        setlist_item: {
          setlist_id: @setlist.id,
          music_id: @music.id,
          key: "C"
        }
      }
    end

    assert_redirected_to setlist_path(@setlist)
    follow_redirect!
    assert_match @music.title, response.body
  end
end
