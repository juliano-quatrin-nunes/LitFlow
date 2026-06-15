class Setlists::PptxController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_setlist

  def show
    @expected_fingerprint = Slides::Fingerprint.for_setlist(@setlist)

    if cache_hit?
      @download_url = rails_blob_path(@setlist.pptx, disposition: "attachment", only_path: true)
      @filename = @setlist.pptx.filename.to_s
      render :cache_hit, formats: [ :turbo_stream ]
    else
      GenerateSetlistPptxJob.perform_later(@setlist.id)
      render :cache_miss, formats: [ :turbo_stream ]
    end
  end

  private

  def cache_hit?
    @setlist.pptx_fingerprint == @expected_fingerprint && @setlist.pptx.attached?
  end

  def set_setlist
    @setlist =
      if params[:uid].present?
        Setlist.find_by!(uid: params[:uid])
      elsif authenticated?
        Current.user.setlists.find(params[:setlist_id])
      else
        raise ActiveRecord::RecordNotFound
      end
  end
end
