# == Schema Information
#
# Table name: invitations
# Database name: primary
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_invitations_on_token  (token) UNIQUE
#
require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "should generate token on create" do
    invitation = Invitation.create!(email: "test@example.com")
    assert_not_nil invitation.token
  end

  test "should set default expiration" do
    invitation = Invitation.create!(email: "test@example.com")
    assert invitation.expires_at > 23.hours.from_now
  end

  test "should be expired" do
    invitation = Invitation.create!(email: "test@example.com", expires_at: 1.hour.ago)
    assert invitation.expired?
  end

  test "should not be expired when new" do
    invitation = Invitation.create!(email: "test@example.com")
    assert_not invitation.expired?
  end

  test "should validate email format" do
    invitation = Invitation.new(email: "invalid")
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is invalid"
  end
end
