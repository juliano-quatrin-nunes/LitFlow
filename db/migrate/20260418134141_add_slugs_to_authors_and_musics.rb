class AddSlugsToAuthorsAndMusics < ActiveRecord::Migration[8.1]
  def change
    add_column :repertoire_authors, :slug, :string
    add_index :repertoire_authors, :slug, unique: true

    add_column :repertoire_musics, :slug, :string
    add_index :repertoire_musics, :slug, unique: true
  end
end
