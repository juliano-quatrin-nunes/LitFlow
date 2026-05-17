class Repertoire::Musics::PptxController < ApplicationController
  before_action :set_music

  def show
    @slide_deck = @music.slide_deck
    @expected_fingerprint = Slides::Fingerprint.call(
      @slide_deck.slides_json,
      @slide_deck.slide_sequence,
      Slides::Theme::VERSION
    )

    if cache_hit?
      @download_url = rails_blob_path(@slide_deck.pptx, disposition: "attachment", only_path: true)
      @filename = @slide_deck.pptx.filename.to_s
      render :cache_hit, formats: [ :turbo_stream ]
    else
      GenerateMusicPptxJob.perform_later(@slide_deck.id)
      render :cache_miss, formats: [ :turbo_stream ]
    end
  end

  private

  def cache_hit?
    @slide_deck.pptx_fingerprint == @expected_fingerprint && @slide_deck.pptx.attached?
  end

  def set_music
    @author = Repertoire::Author.find_by!(slug: params[:author_slug])
    @music = @author.musics.find_by!(slug: params[:id])
  end
end
