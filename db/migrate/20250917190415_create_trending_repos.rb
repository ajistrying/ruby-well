class CreateTrendingRepos < ActiveRecord::Migration[8.0]
  def change
    create_table :trending_repos do |t|
      t.string :github_id, null: false
      t.string :name, null: false
      t.string :owner, null: false
      t.string :full_name, null: false
      t.text :description
      t.string :url, null: false
      t.integer :stars_today, default: 0
      t.integer :total_stars, default: 0
      t.integer :forks, default: 0
      t.string :language
      t.date :trending_date, null: false
      t.integer :position
      t.json :contributors, default: []

      t.timestamps
    end

    add_index :trending_repos, :github_id
    add_index :trending_repos, [ :github_id, :trending_date ], unique: true
    add_index :trending_repos, :trending_date
    add_index :trending_repos, [ :trending_date, :position ]
  end
end
