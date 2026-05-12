class RemoveEmailFromInvitations < ActiveRecord::Migration[8.1]
  def change
    remove_column :invitations, :email, :string
  end
end
