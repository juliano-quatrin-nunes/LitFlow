require "test_helper"
require "rake"

class RepertoireSlidesBackfillTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["repertoire:slides:backfill"]
    @task.reenable
  end

  test "creates slide_deck for musics that lack one and is idempotent" do
    music = repertoire_musics(:one)
    music.slide_deck&.destroy
    music.reload
    assert_nil music.slide_deck, "Backfill scenario expects music without a slide_deck"

    @task.invoke

    music.reload
    assert_not_nil music.slide_deck
    assert_not_empty music.slide_deck.slides_json
    deck_id_before = music.slide_deck.id

    @task.reenable
    @task.invoke

    music.reload
    assert_equal deck_id_before, music.slide_deck.id, "Backfill must not replace existing slide_deck"
  end
end
