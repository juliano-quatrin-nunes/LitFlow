class CreateRepertoireMusicLiturgicalSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_music_liturgical_seasons do |t|
      t.references :music, null: false, foreign_key: { to_table: :repertoire_musics }
      t.references :liturgical_season, null: false, foreign_key: { to_table: :repertoire_liturgical_seasons }

      t.timestamps
    end
  end
end
