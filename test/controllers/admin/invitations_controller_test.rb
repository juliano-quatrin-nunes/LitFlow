require "test_helper"

class Admin::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:user)
    sign_in_as @admin
  end

  test "should get index as admin" do
    get admin_invitations_url
    assert_response :success
  end

  test "should redirect index as guest" do
    sign_out
    get admin_invitations_url
    assert_redirected_to new_session_url
  end

  test "should redirect index as regular user" do
    sign_in_as @user
    get admin_invitations_url
    assert_redirected_to root_url
  end

  test "should create invitation" do
    assert_difference("Invitation.count") do
      post admin_invitations_url, params: { invitation: { email: "new@example.com" } }
    end
    assert_redirected_to admin_invitations_url
  end

  test "should destroy invitation" do
    invitation = Invitation.create!(email: "to_destroy@example.com")
    assert_difference("Invitation.count", -1) do
      delete admin_invitation_url(invitation)
    end
    assert_redirected_to admin_invitations_url
  end
end