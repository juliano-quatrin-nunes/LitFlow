class Ui::KeyMutator::Component < ApplicationComponent
  def initialize(music:, current_key:, turbo_frame: "music_display", setlist_id: nil, **options)
    @music = music
    @current_key = current_key
    @turbo_frame = turbo_frame
    @setlist_id = setlist_id
    @options = options
  end

  private

  def is_original?
    @current_key == @music.original_key
  end
end
