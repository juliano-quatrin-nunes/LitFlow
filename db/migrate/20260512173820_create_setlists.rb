class CreateSetlists < ActiveRecord::Migration[8.1]
  def change
    create_table :setlists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :date
      t.string :location
      t.integer :setlist_type, null: false, default: 0

      t.timestamps
    end
  end
end
