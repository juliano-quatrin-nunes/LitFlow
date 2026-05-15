class SetlistItemsController < ApplicationController
  def create
    @setlist = Current.user.setlists.find(params[:setlist_item][:setlist_id])
    @music = Repertoire::Music.find(params[:setlist_item][:music_id])
    
    @setlist_item = @setlist.items.new(setlist_item_params)

    if @setlist_item.save
      redirect_to setlist_path(@setlist), notice: "Música adicionada ao roteiro."
    else
      redirect_to repertoire_music_by_author_show_path(@music.author, @music), alert: "Não foi possível adicionar ao roteiro."
    end
  end

  def destroy
    @setlist_item = SetlistItem.joins(:setlist).where(setlists: { user_id: Current.user.id }).find(params[:id])
    @setlist = @setlist_item.setlist
    @setlist_item.destroy
    redirect_to setlist_path(@setlist), notice: "Música removida do roteiro."
  end

  private

  def setlist_item_params
    params.expect(setlist_item: [ :music_id, :key ])
  end
end
