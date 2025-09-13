class AddMissingFieldsToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :enclosure_url, :string
  end
end
