# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_03_185547) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "number"
    t.string "complement"
    t.string "cep"
    t.string "district"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.string "state"
    t.boolean "selected", default: false, null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.boolean "accepted"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_previous", default: false
    t.bigint "material_value"
    t.bigint "tax_value"
    t.bigint "value_with_tax"
    t.bigint "budget"
    t.index ["order_id"], name: "index_budgets_on_order_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chats", force: :cascade do |t|
    t.text "message"
    t.boolean "is_read", default: false, null: false
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "order_id"
    t.index ["order_id"], name: "index_chats_on_order_id"
    t.index ["receiver_id"], name: "index_chats_on_receiver_id"
    t.index ["sender_id"], name: "index_chats_on_sender_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.integer "rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "documents", force: :cascade do |t|
    t.integer "nr"
    t.bigint "client_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["client_id"], name: "index_documents_on_client_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "category_id"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "order_status", default: 0
    t.bigint "professional"
    t.datetime "start_order"
    t.datetime "end_order"
    t.integer "price", default: 0, null: false
    t.boolean "paid", default: false, null: false
    t.bigint "address_id"
    t.string "images", default: [], array: true
    t.integer "urgency", default: 1
    t.decimal "rate", precision: 2, scale: 1, default: "0.0"
    t.string "order_wirecard_own_id"
    t.string "order_wirecard_id"
    t.string "payment_wirecard_id"
    t.string "hora_inicio"
    t.string "hora_fim"
    t.decimal "user_rate", precision: 2, scale: 1, default: "0.0"
    t.boolean "previous_budget", default: false
    t.bigint "previous_budget_value"
    t.bigint "filtered_professional_id"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["category_id"], name: "index_orders_on_category_id"
    t.index ["filtered_professional_id"], name: "index_orders_on_filtered_professional_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "reschedulings", force: :cascade do |t|
    t.datetime "date_order"
    t.string "hora_inicio"
    t.string "hora_fim"
    t.bigint "order_id", null: false
    t.boolean "user_accepted"
    t.boolean "professional_accepted"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["order_id"], name: "index_reschedulings_on_order_id"
  end

  create_table "subcategories", force: :cascade do |t|
    t.string "name"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
  end

  create_table "user_profile_photos", force: :cascade do |t|
    t.string "photo"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profile_photos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.string "telephone"
    t.string "cellphone"
    t.string "cpf"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_type"
    t.string "cep"
    t.string "cidade"
    t.string "complemento"
    t.string "estado"
    t.string "numero"
    t.string "rua"
    t.string "customer_wirecard_id"
    t.string "birthdate"
    t.string "own_id_wirecard"
    t.string "bairro"
    t.string "player_ids", default: [], null: false, array: true
    t.string "surname"
    t.string "mothers_name"
    t.string "id_wirecard_account"
    t.string "token_wirecard_account"
    t.string "refresh_token_wirecard_account"
    t.string "set_account", default: ""
    t.boolean "is_new_wire_account", default: false
    t.decimal "rate", precision: 2, scale: 1, default: "0.0"
    t.boolean "activated", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "budgets", "orders"
  add_foreign_key "chats", "orders"
  add_foreign_key "chats", "users", column: "receiver_id"
  add_foreign_key "chats", "users", column: "sender_id"
  add_foreign_key "documents", "clients"
  add_foreign_key "orders", "addresses"
  add_foreign_key "orders", "categories"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "filtered_professional_id"
  add_foreign_key "orders", "users", column: "professional"
  add_foreign_key "reschedulings", "orders"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "user_profile_photos", "users"
end
