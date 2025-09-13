class CreateFeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :feeds do |t|
      t.string :name, null: false
      t.string :url                          # Blog homepage URL
      t.string :feed_url, null: false       # RSS/Atom feed URL
      t.string :category, default: 'personal'
      t.text :description
      t.datetime :last_fetched_at
      t.datetime :last_successful_fetch_at
      t.integer :fetch_interval, default: 3600  # seconds
      t.integer :fetch_failures, default: 0
      t.boolean :active, default: true
      t.text :error_message
      t.timestamps
    end

    add_index :feeds, :feed_url, unique: true
    add_index :feeds, :category
    add_index :feeds, :active
    add_index :feeds, :last_fetched_at
  end
end
