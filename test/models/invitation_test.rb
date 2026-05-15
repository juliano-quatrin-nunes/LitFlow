require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "should generate token on create" do
    invitation = Invitation.create!
    assert_not_nil invitation.token
  end

  test "should set default expiration" do
    invitation = Invitation.create!
    assert invitation.expires_at > 23.hours.from_now
  end

  test "should be expired when expires_at is in the past" do
    invitation = Invitation.create!(expires_at: 1.hour.ago)
    assert invitation.expired?
  end

  test "should not be expired when new" do
    invitation = Invitation.create!
    assert_not invitation.expired?
  end

  test "token is unique across invitations" do
    Invitation.create!
    Invitation.create!
    assert_equal 2, Invitation.distinct.count(:token)
  end
end
