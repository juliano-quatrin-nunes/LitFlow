class CreateSetlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :setlist_items do |t|
      t.references :setlist, null: false, foreign_key: true
      t.references :music, null: false, foreign_key: { to_table: :repertoire_musics }
      t.string :key
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
