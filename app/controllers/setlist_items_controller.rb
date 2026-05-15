class SetlistItemsController < ApplicationController
  before_action :set_setlist_item, only: %i[update destroy]

  def new
    @setlist = Current.user.setlists.find(params[:setlist_id])
    @mass_part = Repertoire::MassPart.find_by(id: params[:mass_part_id])

    filter = Repertoire::MusicFilter.new(params, user: Current.user)
    @musics = filter.call.includes(:author).order(:title)
    @seasons = Repertoire::LiturgicalSeason.order(:name)
    @parts = Repertoire::MassPart.order(:position)
    @library_scope = filter.library_scope
    @user_saved_musics = Current.user.saved_musics.index_by(&:music_id)
  end

  def create
    @setlist = Current.user.setlists.find(params[:setlist_item][:setlist_id])
    @music = Repertoire::Music.find(params[:setlist_item][:music_id])

    attrs = setlist_item_params
    if attrs[:mass_part_id].blank? && @setlist.missa?
      attrs[:mass_part_id] = @music.mass_parts.first&.id
    end

    if params[:force] != "true" && @setlist.items.exists?(music_id: @music.id)
      flash[:alert] = render_to_string(
        partial: "setlist_items/duplicate_flash",
        locals: { setlist: @setlist, music: @music, key: attrs[:key], mass_part_id: attrs[:mass_part_id] }
      )
      redirect_back(fallback_location: repertoire_music_by_author_show_path(@music.author, @music))
      return
    end

    @setlist_item = @setlist.items.new(attrs)

    if @setlist_item.save
      redirect_to setlist_path(@setlist), notice: "Música adicionada ao roteiro \"#{@setlist.name}\"."
    else
      redirect_to repertoire_music_by_author_show_path(@music.author, @music), alert: "Não foi possível adicionar ao roteiro."
    end
  end

  def update
    if @setlist_item.update(setlist_item_update_params)
      redirect_to setlist_path(@setlist_item.setlist), notice: "Item atualizado."
    else
      redirect_to setlist_path(@setlist_item.setlist), alert: "Não foi possível atualizar o item."
    end
  end

  def destroy
    setlist = @setlist_item.setlist
    @setlist_item.destroy
    redirect_to setlist_path(setlist), notice: "Música removida do roteiro."
  end

  def reorder
    ids = Array(params[:ids]).map(&:to_i)
    return head(:ok) if ids.empty?

    scoped = SetlistItem.joins(:setlist).where(setlists: { user_id: Current.user.id }, id: ids)

    SetlistItem.transaction do
      scoped.find_each do |item|
        item.update_column(:position, ids.index(item.id) + 1)
      end
    end

    head :ok
  end

  private

  def set_setlist_item
    @setlist_item = SetlistItem.joins(:setlist).where(setlists: { user_id: Current.user.id }).find(params[:id])
  end

  def setlist_item_params
    params.expect(setlist_item: [ :music_id, :key, :mass_part_id ])
  end

  def setlist_item_update_params
    params.expect(setlist_item: [ :key, :mass_part_id, :position ])
  end
end
