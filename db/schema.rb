# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150721211924) do

  create_table "memberships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
  end

  add_index "memberships", ["team_id"], name: "index_memberships_on_team_id"
  add_index "memberships", ["user_id"], name: "index_memberships_on_user_id"

  create_table "pubkeys", force: :cascade do |t|
    t.string  "title"
    t.text    "key"
    t.integer "user_id"
  end

  add_index "pubkeys", ["user_id", "title"], name: "index_pubkeys_on_user_id_and_title"

  create_table "teams", force: :cascade do |t|
    t.string "name"
  end

  add_index "teams", ["name"], name: "index_teams_on_name"

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "role"
    t.string "password_digest"
  end

  add_index "users", ["name"], name: "index_users_on_name"

end
