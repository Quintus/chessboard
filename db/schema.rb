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

ActiveRecord::Schema.define(version: 6) do

  create_table "forum_groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_group_id"
  end

  create_table "posts", force: true do |t|
    t.text     "content"
    t.string   "language",   default: "Markdown"
    t.integer  "edits",      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "topic_id"
    t.integer  "author_id"
  end

  create_table "topics", force: true do |t|
    t.string   "title"
    t.boolean  "sticky",       default: false
    t.boolean  "announcement", default: false
    t.boolean  "locked",       default: false
    t.integer  "forum_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "nickname"
    t.string   "realname"
    t.string   "email"
    t.string   "homepage"
    t.string   "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
  end

end
