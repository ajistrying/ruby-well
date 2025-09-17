# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_17_190415) do
  create_table "entries", force: :cascade do |t|
    t.integer "feed_id", null: false
    t.string "title", null: false
    t.text "content"
    t.text "summary"
    t.string "url", null: false
    t.string "author"
    t.datetime "published_at"
    t.string "guid"
    t.text "tags"
    t.string "entry_type", default: "article"
    t.integer "duration"
    t.binary "embedding"
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "enclosure_url"
    t.index [ "entry_type" ], name: "index_entries_on_entry_type"
    t.index [ "feed_id", "published_at" ], name: "index_entries_on_feed_id_and_published_at"
    t.index [ "feed_id" ], name: "index_entries_on_feed_id"
    t.index [ "guid" ], name: "index_entries_on_guid", unique: true
    t.index [ "processed" ], name: "index_entries_on_processed"
    t.index [ "published_at" ], name: "index_entries_on_published_at"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.string "feedback_type", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "email"
    t.string "feed_url"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "created_at" ], name: "index_feedbacks_on_created_at"
    t.index [ "feedback_type" ], name: "index_feedbacks_on_feedback_type"
    t.index [ "status" ], name: "index_feedbacks_on_status"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "name", null: false
    t.string "url"
    t.string "feed_url", null: false
    t.string "category", default: "personal"
    t.text "description"
    t.datetime "last_fetched_at"
    t.datetime "last_successful_fetch_at"
    t.integer "fetch_interval", default: 3600
    t.integer "fetch_failures", default: 0
    t.boolean "active", default: true
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "active" ], name: "index_feeds_on_active"
    t.index [ "category" ], name: "index_feeds_on_category"
    t.index [ "feed_url" ], name: "index_feeds_on_feed_url", unique: true
    t.index [ "last_fetched_at" ], name: "index_feeds_on_last_fetched_at"
  end

  create_table "trending_repos", force: :cascade do |t|
    t.string "github_id", null: false
    t.string "name", null: false
    t.string "owner", null: false
    t.string "full_name", null: false
    t.text "description"
    t.string "url", null: false
    t.integer "stars_today", default: 0
    t.integer "total_stars", default: 0
    t.integer "forks", default: 0
    t.string "language"
    t.date "trending_date", null: false
    t.integer "position"
    t.json "contributors", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "github_id", "trending_date" ], name: "index_trending_repos_on_github_id_and_trending_date", unique: true
    t.index [ "github_id" ], name: "index_trending_repos_on_github_id"
    t.index [ "trending_date", "position" ], name: "index_trending_repos_on_trending_date_and_position"
    t.index [ "trending_date" ], name: "index_trending_repos_on_trending_date"
  end

  add_foreign_key "entries", "feeds"
end
