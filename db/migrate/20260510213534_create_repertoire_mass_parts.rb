class CreateRepertoireMassParts < ActiveRecord::Migration[8.1]
  def change
    create_table :repertoire_mass_parts do |t|
      t.string :name
      t.string :slug
      t.integer :position

      t.timestamps
    end
    add_index :repertoire_mass_parts, :slug, unique: true
  end
end
