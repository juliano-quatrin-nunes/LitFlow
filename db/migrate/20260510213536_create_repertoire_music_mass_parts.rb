class CreateRepertoireMusicMassParts < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_music_mass_parts do |t|
      t.references :music, null: false, foreign_key: { to_table: :repertoire_musics }
      t.references :mass_part, null: false, foreign_key: { to_table: :repertoire_mass_parts }

      t.timestamps
    end
  end
end
