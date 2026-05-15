# Filters Repertoire::Music by query, season, mass part, and library scope.
#
# Used by both the public music library index and the setlist add-music modal.
class Repertoire::MusicFilter
  attr_reader :q, :season, :part, :library, :user

  def initialize(params, user: nil)
    @q       = params[:q].to_s.strip.presence
    @season  = params[:season].presence
    @part    = params[:part].presence
    @library = params[:library].presence
    @user    = user
  end

  def call
    scope = Repertoire::Music.all.joins(:author)
    scope = apply_query(scope)
    scope = apply_season(scope)
    scope = apply_part(scope)
    scope = apply_library(scope)
    scope
  end

  def library_scope
    return "all" if user.blank?
    library == "mine" ? "mine" : "all"
  end

  private

  def apply_query(scope)
    return scope unless q

    pattern = "%#{q}%"
    scope.where(
      "repertoire_musics.title ILIKE ? OR repertoire_authors.name ILIKE ? OR repertoire_musics.content_raw ILIKE ?",
      pattern, pattern, pattern
    )
  end

  def apply_season(scope)
    return scope unless season

    scope
      .joins(:liturgical_seasons)
      .where(repertoire_liturgical_seasons: { slug: [ season, "geral" ] })
      .distinct
  end

  def apply_part(scope)
    return scope unless part

    scope.joins(:mass_parts).where(repertoire_mass_parts: { slug: part })
  end

  def apply_library(scope)
    return scope unless library == "mine" && user

    scope.joins("INNER JOIN saved_musics ON saved_musics.music_id = repertoire_musics.id")
         .where(saved_musics: { user_id: user.id })
  end
end
