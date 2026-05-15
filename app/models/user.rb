# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  role            :integer          default("user"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :saved_musics, dependent: :destroy
  has_many :repertoire, through: :saved_musics, source: :music

  has_many :setlists, dependent: :destroy

  enum :role, { user: 0, admin: 1 }, default: :user

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
