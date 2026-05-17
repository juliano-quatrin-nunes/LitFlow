class Repertoire::Musics::SlideDecksController < ApplicationController
  before_action :set_music

  def create
    preview_music = @music.dup
    if params[:repertoire_music]
      preview_music.content_raw = params[:repertoire_music][:content_raw]
    end
    preview_music.content_json = nil

    @preview_sections = Slides::Extractor.call(preview_music.content_json)
    @preview_sequence = Slides::Extractor.default_sequence(@preview_sections)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to repertoire_music_by_author_edit_path(@music.author, @music) }
    end
  end

  def update
    deck = @music.slide_deck
    deck.update!(slide_deck_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to repertoire_music_by_author_edit_path(@music.author, @music), notice: "Slides atualizados." }
    end
  end

  def regenerate
    slides = Slides::Extractor.call(@music.content_json)
    sequence = Slides::Extractor.default_sequence(slides)
    generated_from = @music.content_raw.present? ? Digest::SHA1.hexdigest(@music.content_raw) : nil

    @music.slide_deck.update!(
      slides_json: slides,
      slide_sequence: sequence,
      slides_generated_from: generated_from
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to repertoire_music_by_author_edit_path(@music.author, @music) }
    end
  end

  private

  def slide_deck_params
    raw = params.require(:slide_deck).permit(:slides_json, :slide_sequence)
    {
      slides_json: raw[:slides_json].is_a?(String) ? JSON.parse(raw[:slides_json]) : raw[:slides_json],
      slide_sequence: raw[:slide_sequence].is_a?(String) ? JSON.parse(raw[:slide_sequence]) : raw[:slide_sequence]
    }
  end

  def set_music
    @author = Repertoire::Author.find_by!(slug: params[:author_slug])
    @music = @author.musics.find_by!(slug: params[:id])
  end
end
