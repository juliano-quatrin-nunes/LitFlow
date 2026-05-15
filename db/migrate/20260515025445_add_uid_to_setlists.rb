class AddUidToSetlists < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :setlists, :uid, :string

    reversible do |dir|
      dir.up do
        Setlist.reset_column_information
        Setlist.where(uid: nil).find_each do |setlist|
          setlist.update_column(:uid, SecureRandom.urlsafe_base64(16))
        end
      end
    end

    add_index :setlists, :uid, unique: true
  end
end
