class MakeSetlistItemsPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_column :setlist_items, :item_type, :string
    add_column :setlist_items, :item_id, :bigint

    SetlistItem.reset_column_information
    execute <<~SQL.squish
      UPDATE setlist_items
      SET item_type = 'Repertoire::Music', item_id = music_id
      WHERE music_id IS NOT NULL
    SQL

    change_column_null :setlist_items, :item_type, false
    change_column_null :setlist_items, :item_id, false

    add_index :setlist_items, [ :item_type, :item_id ]

    if foreign_key_exists?(:setlist_items, :repertoire_musics, column: :music_id)
      remove_foreign_key :setlist_items, column: :music_id
    end
    remove_index :setlist_items, :music_id if index_exists?(:setlist_items, :music_id)
    remove_column :setlist_items, :music_id

    SetlistItem.reset_column_information
  end

  def down
    add_column :setlist_items, :music_id, :bigint

    SetlistItem.reset_column_information
    execute <<~SQL.squish
      UPDATE setlist_items
      SET music_id = item_id
      WHERE item_type = 'Repertoire::Music'
    SQL

    change_column_null :setlist_items, :music_id, false
    add_index :setlist_items, :music_id
    add_foreign_key :setlist_items, :repertoire_musics, column: :music_id

    remove_index :setlist_items, [ :item_type, :item_id ] if index_exists?(:setlist_items, [ :item_type, :item_id ])
    remove_column :setlist_items, :item_id
    remove_column :setlist_items, :item_type
  end
end
