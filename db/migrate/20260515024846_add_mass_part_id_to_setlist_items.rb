class AddMassPartIdToSetlistItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :setlist_items, :mass_part, foreign_key: { to_table: :repertoire_mass_parts }
  end
end
