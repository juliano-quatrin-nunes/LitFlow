class SetupAuthorModelAndAssociation < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_authors do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :repertoire_authors, :name, unique: true

    add_reference :repertoire_musics, :author, foreign_key: { to_table: :repertoire_authors }
  end
end
