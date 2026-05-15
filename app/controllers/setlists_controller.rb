class SetlistsController < ApplicationController
  allow_unauthenticated_access only: :public_show
  before_action :set_setlist, only: %i[ show edit update destroy ]

  def index
    @setlists = Current.user.setlists.order(date: :desc, created_at: :desc)
  end

  def show
  end

  def public_show
    @setlist = Setlist.find_by!(uid: params[:uid])
  end

  def new
    @setlist = Current.user.setlists.new
  end

  def edit
  end

  def create
    @setlist = Current.user.setlists.new(setlist_params)

    if @setlist.save
      if params[:music_id].present? && params[:key].present?
        music = Repertoire::Music.find_by(id: params[:music_id])
        if music
          @setlist.items.create!(music: music, key: params[:key])
          redirect_to @setlist, notice: "Roteiro criado e música adicionada com sucesso."
          return
        end
      end
      
      redirect_to setlists_path, notice: "Roteiro criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @setlist.update(setlist_params)
      redirect_to @setlist, notice: "Roteiro atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @setlist.destroy
    redirect_to setlists_path, notice: "Roteiro excluído."
  end

  private

  def set_setlist
    @setlist = Current.user.setlists.find(params[:id])
  end

  def setlist_params
    params.expect(setlist: [ :name, :date, :location, :setlist_type ])
  end
end
