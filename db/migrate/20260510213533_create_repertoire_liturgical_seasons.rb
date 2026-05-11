class CreateRepertoireLiturgicalSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_liturgical_seasons do |t|
      t.string :name
      t.string :slug
      t.string :color

      t.timestamps
    end
    add_index :repertoire_liturgical_seasons, :slug, unique: true
  end
end
