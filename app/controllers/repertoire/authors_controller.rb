module Repertoire
  class AuthorsController < ApplicationController
    allow_unauthenticated_access only: %i[ index ]
    def index
      @authors = Repertoire::Author.all.order(:name)
      if params[:q].present?
        @authors = @authors.where("name ILIKE ?", "%#{params[:q]}%")
      end

      respond_to do |format|
        format.html
        format.json do
          render json: @authors.map { |author| { value: author.id, label: author.name } }
        end
      end
    end

    def create
      @author = Repertoire::Author.new(author_params)

      respond_to do |format|
        if @author.save
          format.turbo_stream
        else
          # Fallback if creation fails (e.g. name already taken)
          format.turbo_stream { render turbo_stream: turbo_stream.append("error_explanation", "Error creating author: #{@author.errors.full_messages.join(', ')}") }
        end
      end
    end

    private

    def author_params
      params.require(:author).permit(:name)
    end
  end
end
