class SavedMusicsController < ApplicationController
  def index
    @saved_musics = Current.user.saved_musics.includes(music: :author)
  end

  def create
    @music = Repertoire::Music.find(params[:music_id])
    @saved_music = Current.user.saved_musics.find_or_initialize_by(music: @music)
    @saved_music.assign_attributes(saved_music_params)

    if @saved_music.save
      redirect_to repertoire_music_by_author_show_path(@music.author, @music), notice: "Música adicionada ao seu repertório."
    else
      redirect_to repertoire_music_by_author_show_path(@music.author, @music), alert: "Não foi possível salvar a música."
    end
  end

  def update
    @saved_music = Current.user.saved_musics.find(params[:id])
    if @saved_music.update(saved_music_params)
      redirect_to repertoire_music_by_author_show_path(@saved_music.music.author, @saved_music.music), notice: "Alterações salvas."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @saved_music = Current.user.saved_musics.find(params[:id])
    @saved_music.destroy
    redirect_to repertoire_musics_path, notice: "Música removida do seu repertório."
  end

  private

  def saved_music_params
    params.expect(saved_music: [ :preferred_key, :remarks ])
  end
end