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

ActiveRecord::Schema.define(version: 26) do

  create_table "avatars", force: true do |t|
    t.string   "path"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bans", force: true do |t|
    t.string   "nick_pattern"
    t.string   "email_pattern"
    t.string   "ip_range"
    t.text     "reason"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "moderation", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "forum_id"
  end

  create_table "personal_messages", force: true do |t|
    t.string   "title"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "views",      default: 0
  end

  create_table "personal_posts", force: true do |t|
    t.text     "content"
    t.string   "markup_language"
    t.integer  "author_id"
    t.integer  "personal_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pm_access", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "personal_message_id"
  end

  create_table "posts", force: true do |t|
    t.text     "content"
    t.string   "markup_language", default: "BBCode"
    t.integer  "edits",           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "topic_id"
    t.integer  "author_id"
  end

  create_table "read_pms", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "personal_message_id"
  end

  create_table "read_topics", id: false, force: true do |t|
    t.integer "topic_id"
    t.integer "user_id"
  end

  create_table "registration_tokens", force: true do |t|
    t.datetime "expiration_date"
    t.string   "encrypted_tokenstr"
    t.string   "string"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: true do |t|
    t.text     "description"
    t.boolean  "closed",      default: false
    t.integer  "post_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: true do |t|
    t.boolean  "hide_status",               default: false
    t.boolean  "use_gravatar",              default: false
    t.string   "preferred_markup_language", default: "BBCode"
    t.string   "string",                    default: "BBCode"
    t.string   "language",                  default: "en"
    t.string   "time_format",               default: ""
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "views",        default: 0
  end

  create_table "users", force: true do |t|
    t.string   "nickname"
    t.string   "realname"
    t.string   "email"
    t.string   "homepage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.boolean  "admin",              default: false
    t.string   "signature"
    t.string   "location"
    t.string   "profession"
    t.string   "jabber_id"
    t.string   "pgp_key"
    t.datetime "last_login"
    t.boolean  "confirmed",          default: false
    t.string   "forced_rank"
  end

  create_table "warnings", force: true do |t|
    t.text     "reason"
    t.integer  "warned_user_id"
    t.integer  "warning_user_id"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
