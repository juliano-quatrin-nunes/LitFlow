# frozen_string_literal: true

class SetInitialSlugs < ActiveRecord::Migration[8.1]
  def up
    Repertoire::Author.reset_column_information
    Repertoire::Music.reset_column_information

    Repertoire::Author.find_each do |author|
      author.send(:generate_slug)
      author.save!(validate: false)
    end

    Repertoire::Music.find_each do |music|
      music.send(:generate_slug)
      music.save!(validate: false)
    end
  end

  def down
    # Nothing to do
  end
end
