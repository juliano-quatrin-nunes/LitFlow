class RemoveAuthorStringColumnFromMusics < ActiveRecord::Migration[8.1]
  def up
    remove_column :repertoire_musics, :author
  end

  def down
    add_column :repertoire_musics, :author, :string
    
    # Restore data
    Repertoire::Music.reset_column_information
    Repertoire::Music.find_each do |music|
      music.update_column(:author, music.author&.name)
    end
  end
end
