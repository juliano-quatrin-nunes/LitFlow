class Setlists::PptxController < ApplicationController
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
    @setlist = Current.user.setlists.find(params[:setlist_id])
  end
end
