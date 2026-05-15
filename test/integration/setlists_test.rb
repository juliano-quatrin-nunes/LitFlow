require "test_helper"

class SetlistsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    post session_path, params: { email_address: @user.email_address, password: "password" }
  end

  test "unauthenticated user is redirected to login when accessing setlists" do
    delete session_path # sign out
    get setlists_path
    assert_redirected_to new_session_path
  end

  test "after signing in, user is redirected back to original setlist destination" do
    delete session_path # sign out
    get setlists_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to setlists_url
  end

  test "user can create a new setlist and see it on the index" do
    get setlists_path
    assert_response :success
    assert_select "h1", "Meus Roteiros"

    get new_setlist_path
    assert_response :success

    assert_difference("Setlist.count") do
      post setlists_path, params: {
        setlist: {
          name: "Missa de Domingo",
          date: Date.tomorrow.to_s,
          location: "Paróquia São Paulo",
          setlist_type: "missa"
        }
      }
    end

    assert_redirected_to setlists_path
    follow_redirect!
    assert_select "h2", "Missa de Domingo"
  end

  test "user can delete a setlist" do
    setlist = Setlist.create!(
      user: @user,
      name: "Missa Antiga",
      date: Date.yesterday,
      location: "Paróquia São Paulo",
      setlist_type: "missa"
    )

    get setlists_path
    assert_match setlist.name, response.body
    
    assert_difference("Setlist.count", -1) do
      delete setlist_path(setlist)
    end
    
    assert_redirected_to setlists_path
    follow_redirect!
    assert_no_match setlist.name, response.body
  end
end
