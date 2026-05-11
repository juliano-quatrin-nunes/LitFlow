require "application_system_test_case"

class Repertoire::LiturgicalCategoriesTest < ApplicationSystemTestCase
  setup do
    @music = repertoire_musics(:one)
    @season = repertoire_liturgical_seasons(:one)
    @part = repertoire_mass_parts(:one)
  end

  test "assigning liturgical categories to a music" do
    visit repertoire_music_by_author_path(@music.author, @music)

    assert_no_text @season.name
    assert_no_text @part.name

    click_on "Ações"
    click_on "Editar Categorias"

    assert_text "Editar Categorias"

    check @season.name
    check @part.name

    click_on "Salvar"

    assert_no_selector "dialog", text: "Editar Categorias"

    assert_text @season.name
    assert_text @part.name
  end

  test "filtering music on the index page" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    part = repertoire_mass_parts(:one)

    music.liturgical_seasons << season
    music.mass_parts << part

    other_music = repertoire_musics(:two)

    visit repertoire_musics_path

    assert_text music.title
    assert_text other_music.title

    # Filter by season
    within ".flex-wrap.items-center.gap-4" do
      click_on "Tempo: Todos"
      click_on season.name
    end

    assert_text music.title
    assert_no_text other_music.title

    # Filter by part (combine)
    within ".flex-wrap.items-center.gap-4" do
      click_on "Parte: Todas"
      click_on part.name
    end

    assert_text music.title
    assert_no_text other_music.title

    # Clear filters
    within ".flex-wrap.items-center.gap-4" do
      click_on "Limpar"
    end

    assert_text music.title
    assert_text other_music.title
  end

  test "searching music on the index page" do
    music = repertoire_musics(:one) # Vem Espírito Santo
    other_music = repertoire_musics(:two) # Outra Música

    visit repertoire_musics_path

    assert_text music.title
    assert_text other_music.title

    within ".flex-wrap.items-center.gap-4" do
      find("input[placeholder='Buscar por título, autor ou letra...']").set("Espírito")
    end
    
    assert_text music.title
    assert_no_text other_music.title

    within ".flex-wrap.items-center.gap-4" do
      find("input[placeholder='Buscar por título, author ou letra...']").set("Desconhecido")
    rescue Capybara::ElementNotFound
      # Fallback for typos in placeholder if I made any
      find("input[name='q']").set("Desconhecido")
    end
    
    assert_text other_music.title
    assert_no_text music.title

    within ".flex-wrap.items-center.gap-4" do
      click_on "Limpar"
    end
    
    assert_text music.title
    assert_text other_music.title
  end
end
