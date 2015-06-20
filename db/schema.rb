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

ActiveRecord::Schema.define(version: 41) do

  create_table "attachments", force: :cascade do |t|
    t.string   "filename",    limit: 255
    t.text     "description"
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "avatars", force: :cascade do |t|
    t.string   "path",       limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bans", force: :cascade do |t|
    t.string   "nick_pattern",    limit: 255
    t.string   "email_pattern",   limit: 255
    t.string   "ip_range",        limit: 255
    t.text     "reason"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ordernum",               default: 0
  end

  create_table "forums", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "description",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_group_id"
    t.integer  "ordernum",                   default: 0
  end

  create_table "global_configurations", force: :cascade do |t|
    t.string   "default_time_format",           limit: 255, default: ""
    t.integer  "maximum_avatar_dimension",                  default: 80
    t.integer  "warning_expiration",                        default: 31536000
    t.integer  "registration_expiration",                   default: 86400
    t.boolean  "registration",                              default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_post_num",                             default: 15
    t.integer  "page_topic_num",                            default: 15
    t.integer  "maximum_attachment_size",                   default: 1048576
    t.string   "allowed_attachment_mime_types", limit: 255, default: "text/plain, image/jpeg, image/png, application/x-gzip, application/zip"
    t.text     "plugin_data"
  end

  create_table "moderation", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "forum_id"
  end

  create_table "moderations", force: :cascade do |t|
    t.integer  "moderator_id"
    t.integer  "targetted_user_id"
    t.integer  "post_id"
    t.string   "action"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "topic_id"
  end

  create_table "personal_messages", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "views",                  default: 0
  end

  create_table "personal_posts", force: :cascade do |t|
    t.text     "content"
    t.string   "markup_language",     limit: 255
    t.integer  "author_id"
    t.integer  "personal_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pm_access", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "personal_message_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text     "content"
    t.string   "markup_language", limit: 255, default: "BBCode"
    t.integer  "edits",                       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "topic_id"
    t.integer  "author_id"
    t.string   "ip",              limit: 255
    t.text     "plugin_data"
  end

  create_table "read_pms", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "personal_message_id"
  end

  create_table "read_topics", id: false, force: :cascade do |t|
    t.integer "topic_id"
    t.integer "user_id"
  end

  create_table "registration_tokens", force: :cascade do |t|
    t.datetime "expiration_date"
    t.string   "encrypted_tokenstr", limit: 255
    t.string   "string",             limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: :cascade do |t|
    t.text     "description"
    t.boolean  "closed",      default: false
    t.integer  "post_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean  "hide_status",                           default: false
    t.boolean  "use_gravatar",                          default: false
    t.string   "preferred_markup_language", limit: 255, default: "BBCode"
    t.string   "string",                    limit: 255, default: "BBCode"
    t.string   "language",                  limit: 255, default: "en"
    t.string   "time_format",               limit: 255, default: ""
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hide_email",                            default: true
    t.boolean  "auto_watch",                            default: false
  end

  create_table "topics", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.boolean  "sticky",                   default: false
    t.boolean  "announcement",             default: false
    t.boolean  "locked",                   default: false
    t.integer  "forum_id"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "views",                    default: 0
  end

  create_table "users", force: :cascade do |t|
    t.string   "nickname",           limit: 255
    t.string   "realname",           limit: 255
    t.string   "email",              limit: 255
    t.string   "homepage",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password", limit: 255
    t.boolean  "admin",                          default: false
    t.string   "location",           limit: 255
    t.string   "profession",         limit: 255
    t.string   "jabber_id",          limit: 255
    t.string   "pgp_key",            limit: 255
    t.datetime "last_login"
    t.boolean  "confirmed",                      default: false
    t.string   "forced_rank",        limit: 255
    t.text     "signature"
    t.text     "plugin_data"
  end

  create_table "warnings", force: :cascade do |t|
    t.text     "reason"
    t.integer  "warned_user_id"
    t.integer  "warning_user_id"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "watchers", id: false, force: :cascade do |t|
    t.integer "topic_id"
    t.integer "user_id"
  end

end
