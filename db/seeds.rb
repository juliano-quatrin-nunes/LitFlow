# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Liturgical Seasons
seasons = [
  { name: "Tempo Comum", slug: "tempo-comum" },
  { name: "Advento", slug: "advento" },
  { name: "Quaresma", slug: "quaresma" },
  { name: "Tempo Pascal", slug: "tempo-pascal" },
  { name: "Natal", slug: "natal" },
  { name: "Geral", slug: "geral" }
]

seasons.each do |season_attrs|
  Repertoire::LiturgicalSeason.find_or_create_by!(slug: season_attrs[:slug]) do |season|
    season.name = season_attrs[:name]
  end
end

# Mass Parts
parts = [
  { name: "Entrada", slug: "entrada", position: 1 },
  { name: "Ato Penitencial", slug: "ato-penitencial", position: 2 },
  { name: "Hino de Louvor", slug: "hino-de-louvor", position: 3 },
  { name: "Salmo", slug: "salmo", position: 4 },
  { name: "Aclamação", slug: "aclamacao", position: 5 },
  { name: "Ofertório", slug: "ofertorio", position: 6 },
  { name: "Santo", slug: "santo", position: 7 },
  { name: "Cordeiro", slug: "cordeiro", position: 8 },
  { name: "Comunhão", slug: "comunhao", position: 9 },
  { name: "Pós-Comunhão", slug: "pos-comunhao", position: 10 },
  { name: "Saída", slug: "saida", position: 11 },
  { name: "Outros / Devocional", slug: "outros", position: 12 }
]

parts.each do |part_attrs|
  Repertoire::MassPart.find_or_create_by!(slug: part_attrs[:slug]) do |part|
    part.name = part_attrs[:name]
    part.position = part_attrs[:position]
  end
end

# Admin User
User.find_or_create_by!(email_address: "admin@litflow.com") do |user|
  user.password = "password123"
  user.role = :admin
end
