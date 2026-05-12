class CreateSavedMusics < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_musics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :music, null: false, foreign_key: { to_table: :repertoire_musics }
      t.string :preferred_key
      t.text :remarks

      t.timestamps
    end
  end
end
