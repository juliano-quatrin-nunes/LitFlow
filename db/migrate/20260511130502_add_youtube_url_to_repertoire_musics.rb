class AddYoutubeUrlToRepertoireMusics < ActiveRecord::Migration[8.1]
  def change
    add_column :repertoire_musics, :youtube_url, :string
  end
end
