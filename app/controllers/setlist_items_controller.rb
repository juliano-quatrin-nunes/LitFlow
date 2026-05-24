class SetlistItemsController < ApplicationController
  before_action :set_setlist_item, only: %i[edit update destroy]

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

    attrs = setlist_item_params.except(:music_id).merge(
      item_type: "Repertoire::Music",
      item_id: @music.id
    )
    if attrs[:mass_part_id].blank? && @setlist.missa?
      attrs[:mass_part_id] = @music.mass_parts.first&.id
    end

    if params[:force] != "true" && @setlist.items.exists?(item_type: "Repertoire::Music", item_id: @music.id)
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

  def edit
  end

  def update
    attrs = setlist_item_update_params.to_h
    attrs.merge!(resolve_override_changes(params[:setlist_item]))

    if @setlist_item.update(attrs)
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
    setlist_ids = scoped.distinct.pluck(:setlist_id)

    SetlistItem.transaction do
      scoped.find_each do |item|
        item.update_column(:position, ids.index(item.id) + 1)
      end
      Setlist.where(id: setlist_ids).where.not(pptx_fingerprint: nil).update_all(pptx_fingerprint: nil)
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
    params.fetch(:setlist_item, {}).permit(:key, :mass_part_id, :position)
  end

  def resolve_override_changes(raw)
    return {} unless raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)

    changes = {}
    if raw.key?(:slides_json_override_enabled)
      changes[:slides_json_override] = if truthy?(raw[:slides_json_override_enabled])
        parse_json_param(raw[:slides_json_override]) || @setlist_item.effective_slides_json.deep_dup
      end
    end
    if raw.key?(:slide_sequence_override_enabled)
      changes[:slide_sequence_override] = if truthy?(raw[:slide_sequence_override_enabled])
        parse_json_param(raw[:slide_sequence_override]) || @setlist_item.effective_slide_sequence.deep_dup
      end
    end
    changes
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def parse_json_param(value)
    return nil if value.blank?
    JSON.parse(value)
  rescue JSON::ParserError
    nil
  end
end
