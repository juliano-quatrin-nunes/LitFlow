class CreateRepertoireMusics < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_musics do |t|
      t.string :title
      t.string :author
      t.string :original_key
      t.text :content_raw
      t.jsonb :content_json

      t.timestamps
    end
  end
end
