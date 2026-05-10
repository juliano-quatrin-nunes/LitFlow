# frozen_string_literal: true

class MigrateAuthorsToModel < ActiveRecord::Migration[8.1]
  def up
    Repertoire::Music.reset_column_information
    
    # Get all unique author names currently in the string column
    author_names = Repertoire::Music.pluck(:author).uniq.compact

    author_names.each do |name|
      # Find or create the Author record
      author = Repertoire::Author.find_or_create_by!(name: name)
      
      # Update all musics that had this string author
      # Use update_all to be fast and skip callbacks/validations
      Repertoire::Music.where(author: name).update_all(author_id: author.id)
    end
  end

  def down
    Repertoire::Music.reset_column_information
    
    Repertoire::Music.find_each do |music|
      if music.author_id.present?
        # Copy the name back to the string column
        music.update_column(:author, music.author&.name)
      end
    end
  end
end
