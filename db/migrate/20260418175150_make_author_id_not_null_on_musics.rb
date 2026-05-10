class MakeAuthorIdNotNullOnMusics < ActiveRecord::Migration[8.1]
  def change
    change_column_null :repertoire_musics, :author_id, false
  end
end
