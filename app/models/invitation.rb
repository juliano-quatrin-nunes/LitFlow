# == Schema Information
#
# Table name: invitations
# Database name: primary
#
#  id         :bigint           not null, primary key
#  email      :string
#  expires_at :datetime
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_invitations_on_token  (token) UNIQUE
#
class Invitation < ApplicationRecord
  has_secure_token

  before_create :set_expiration

  def expired?
    expires_at < Time.current
  end

  private

  def set_expiration
    self.expires_at ||= 24.hours.from_now
  end
end
