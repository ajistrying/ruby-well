class CreateEntries < ActiveRecord::Migration[8.0]
  def change
  create_table :entries do |t|
      t.references :feed, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content
      t.text :summary
      t.string :url, null: false
      t.string :author
      t.datetime :published_at
      t.string :guid                         # RSS GUID for deduplication
      t.text :tags                          # JSON array of tags
      t.string :entry_type, default: 'article'  # 'article', 'podcast', 'video'
      t.integer :duration                   # For podcasts (seconds)
      t.binary :embedding                   # Vector embedding for semantic search
      t.boolean :processed, default: false  # Whether AI processing is complete
      t.timestamps
    end

    add_index :entries, :published_at
    add_index :entries, :guid, unique: true
    add_index :entries, [:feed_id, :published_at]
    add_index :entries, :processed
    add_index :entries, :entry_type
  end
end
