require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = Invitation.create!(email: "invited@example.com")
  end

  test "should get new with valid token" do
    get new_registration_url(token: @invitation.token)
    assert_response :success
    assert_select "p", text: /invited@example.com/
  end

  test "should redirect new with invalid token" do
    get new_registration_url(token: "invalid")
    assert_redirected_to new_session_url
    assert_equal "Link de convite inválido.", flash[:alert]
  end

  test "should redirect new with expired token" do
    @invitation.update!(expires_at: 1.hour.ago)
    get new_registration_url(token: @invitation.token)
    assert_redirected_to new_session_url
    assert_equal "Este link de convite expirou.", flash[:alert]
  end

  test "should create user and destroy invitation" do
    assert_difference -> { User.count } => 1, -> { Invitation.count } => -1 do
      post registration_url(token: @invitation.token), params: {
        user: {
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    assert_not_nil cookies[:session_id]
    assert_equal "invited@example.com", User.last.email_address
  end

  test "should not create user with invalid data" do
    assert_no_difference "User.count" do
      post registration_url(token: @invitation.token), params: {
        user: {
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div", text: /too short|doesn't match/i
  end
end