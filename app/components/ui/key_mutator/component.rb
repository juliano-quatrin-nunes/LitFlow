class Ui::KeyMutator::Component < ApplicationComponent
  def initialize(music:, current_key:, turbo_frame: "music_display", **options)
    @music = music
    @current_key = current_key
    @turbo_frame = turbo_frame
    @options = options
  end

  private

  def is_original?
    @current_key == @music.original_key
  end
end
