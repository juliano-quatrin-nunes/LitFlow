module Repertoire
  class MusicsController < ApplicationController
    before_action :set_music, only: %i[show edit update destroy]

    def index
      @musics = Music.all
    end

    def show
    end

    def new
      @music = Music.new
    end

    def edit
    end

    def create
      @music = Music.new(music_params)

      if @music.save
        redirect_to repertoire_music_path(@music), notice: "Música criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @music.update(music_params)
        redirect_to repertoire_music_path(@music), notice: "Música atualizada com sucesso."
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
      @music = Music.find(params[:id])
    end

    def music_params
      params.expect(repertoire_music: [ :title, :author, :original_key, :content_raw ])
    end
  end
end
