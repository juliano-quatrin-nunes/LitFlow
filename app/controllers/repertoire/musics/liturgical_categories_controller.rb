class Repertoire::Musics::LiturgicalCategoriesController < ApplicationController
  before_action :set_music

  def edit
  end

  def update
    if @music.update(liturgical_categories_params)
      flash.now[:notice] = "Categorias atualizadas com sucesso."
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("flash", helpers.ui.flash),
            turbo_stream.replace("music_header_tags", partial: "repertoire/musics/liturgical_tags", locals: { music: @music })
          ]
        end
        format.html { redirect_to repertoire_music_by_author_path(@music.author, @music), notice: "Categorias atualizadas com sucesso." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_music
    @author = Repertoire::Author.find_by!(slug: params[:author_slug])
    @music = @author.musics.find_by!(slug: params[:id])
  end

  def liturgical_categories_params
    params.require(:repertoire_music).permit(liturgical_season_ids: [], mass_part_ids: [])
  end
end
