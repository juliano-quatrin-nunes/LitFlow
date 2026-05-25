class AddCifraFingerprintToRepertoireMusicsAndSetlists < ActiveRecord::Migration[8.1]
  def change
    add_column :repertoire_musics, :cifra_fingerprint, :string
    add_index :repertoire_musics, :cifra_fingerprint

    add_column :setlists, :cifra_fingerprint, :string
    add_index :setlists, :cifra_fingerprint
  end
end
