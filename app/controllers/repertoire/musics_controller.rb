module Repertoire
  class MusicsController < ApplicationController
    allow_unauthenticated_access only: %i[ index show ]
    before_action :set_music, only: %i[show edit update destroy]

    def index
      filter = Repertoire::MusicFilter.new(params, user: Current.user)
      @musics = filter.call
      @seasons = LiturgicalSeason.order(:name)
      @parts = MassPart.order(:position)
      @library_scope = filter.library_scope
      @user_saved_musics = authenticated? ? Current.user.saved_musics.index_by(&:music_id) : {}
    end

    def show
      @saved_music = Current.user&.saved_musics&.find_by(music: @music)
      @current_key = params[:key] || @saved_music&.preferred_key || @music.original_key
      @content_json = if @current_key != @music.original_key
        Repertoire::TranspositionService.call(@music.content_json, @music.original_key, @current_key)
      else
        @music.content_json
      end
    end

    def new
      @music = Music.new
    end

    def edit
    end

    def create
      @music = Music.new(music_params)

      if @music.save
        redirect_to repertoire_music_by_author_edit_path(@music.author, @music), notice: "Música criada com sucesso. Os slides foram gerados a partir da cifra — revise abaixo."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @music.update(music_params)
        redirect_to repertoire_music_by_author_show_path(@music.author, @music), notice: "Música atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @music.destroy
      redirect_to repertoire_musics_path, notice: "Música excluída com sucesso."
    end

    private

    def set_music
      author = Author.find_by!(slug: params[:author_slug])
      @music = author.musics.find_by!(slug: params[:id])
    end

    def music_params
      params.require(:repertoire_music).permit(
        :title, :author_id, :original_key, :content_raw, :youtube_url,
        slide_deck_attributes: [ :id, :slides_json, :slide_sequence ]
      )
    end
  end
end
