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

ActiveRecord::Schema[8.1].define(version: 2026_02_08_113628) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audiences", force: :cascade do |t|
    t.integer "bhk_type_id"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "furnishing_type_id"
    t.integer "location_id"
    t.string "name"
    t.integer "organization_id"
    t.integer "power_backup_type_id"
    t.integer "property_type_id"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_audiences_on_deleted_at"
    t.index ["organization_id"], name: "index_audiences_on_organization_id"
  end

  create_table "bhk_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_bhk_types_on_name", unique: true
  end

  create_table "common_email_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "email_type_id", null: false
    t.string "from_email", limit: 255, null: false
    t.string "from_name", limit: 150, null: false
    t.text "html_body", null: false
    t.string "name", limit: 150
    t.string "preheader", limit: 255
    t.string "reply_to", limit: 255
    t.string "subject", limit: 255
    t.text "text_body"
    t.datetime "updated_at", null: false
    t.index ["email_type_id"], name: "index_common_email_templates_on_email_type_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "organization_id"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "email_type_id", null: false
    t.string "from_email"
    t.string "from_name", limit: 150
    t.text "html_body"
    t.string "name", limit: 150
    t.bigint "organization_id", null: false
    t.string "preheader"
    t.string "reply_to"
    t.string "subject"
    t.text "text_body"
    t.datetime "updated_at", null: false
    t.index ["email_type_id"], name: "index_email_templates_on_email_type_id"
    t.index ["organization_id"], name: "index_email_templates_on_organization_id"
  end

  create_table "email_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_email_types_on_key", unique: true
  end

  create_table "furnishing_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_furnishing_types_on_name", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
  end

  create_table "power_backup_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_power_backup_types_on_name", unique: true
  end

  create_table "preferences", force: :cascade do |t|
    t.integer "bhk_type_id"
    t.integer "contact_id"
    t.datetime "created_at", null: false
    t.integer "furnishing_type_id"
    t.integer "location_id"
    t.integer "power_backup_type_id"
    t.integer "property_type_id"
    t.datetime "updated_at", null: false
  end

  create_table "property_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_property_types_on_name", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "super_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "full_name"
    t.bigint "organization_id", null: false
    t.string "password_digest"
    t.string "phone"
    t.bigint "role_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "email_templates", "email_types"
  add_foreign_key "email_templates", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
end
