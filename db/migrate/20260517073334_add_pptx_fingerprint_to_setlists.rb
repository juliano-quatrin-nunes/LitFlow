class AddPptxFingerprintToSetlists < ActiveRecord::Migration[8.1]
  def change
    add_column :setlists, :pptx_fingerprint, :string
  end
end
