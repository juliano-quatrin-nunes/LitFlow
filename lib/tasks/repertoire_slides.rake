namespace :repertoire do
  namespace :slides do
    desc "Build slide_deck records for repertoire musics that don't have one yet"
    task backfill: :environment do
      Repertoire::Music.left_joins(:slide_deck).where(slide_decks: { id: nil }).find_each do |music|
        music.seed_slide_deck
      end
    end
  end
end
