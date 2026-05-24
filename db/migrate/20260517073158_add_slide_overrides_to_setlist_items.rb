class AddSlideOverridesToSetlistItems < ActiveRecord::Migration[8.1]
  def change
    add_column :setlist_items, :slides_json_override, :jsonb
    add_column :setlist_items, :slide_sequence_override, :jsonb
  end
end
