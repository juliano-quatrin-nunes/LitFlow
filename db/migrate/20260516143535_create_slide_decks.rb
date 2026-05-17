class CreateSlideDecks < ActiveRecord::Migration[8.1]
  def change
    create_table :slide_decks do |t|
      t.string :slideable_type, null: false
      t.bigint :slideable_id, null: false
      t.jsonb :slides_json, null: false, default: []
      t.jsonb :slide_sequence, null: false, default: []
      t.string :slides_generated_from
      t.string :pptx_fingerprint

      t.timestamps
    end

    add_index :slide_decks, [ :slideable_type, :slideable_id ], unique: true
  end
end
