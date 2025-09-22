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

ActiveRecord::Schema[8.0].define(version: 2025_09_21_203325) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "anomalies", force: :cascade do |t|
    t.bigint "transaction_id", null: false
    t.string "anomaly_type"
    t.string "severity"
    t.text "description"
    t.boolean "resolved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["anomaly_type", "severity"], name: "idx_anomalies_type_severity"
    t.index ["transaction_id", "resolved"], name: "idx_anomalies_transaction_resolved"
    t.index ["transaction_id"], name: "index_anomalies_on_transaction_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "idx_categories_user_name"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categorization_rules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.bigint "category_id", null: false
    t.integer "priority"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "rule_predicate", default: {}, null: false
    t.index ["active", "priority"], name: "idx_rules_active_priority"
    t.index ["category_id"], name: "index_categorization_rules_on_category_id"
    t.index ["user_id", "active"], name: "index_categorization_rules_on_user_id_and_active"
    t.index ["user_id"], name: "index_categorization_rules_on_user_id"
  end

  create_table "csv_imports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "filename", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.integer "processed_rows", default: 0, null: false
    t.integer "error_rows", default: 0, null: false
    t.bigint "file_size"
    t.string "s3_key"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["s3_key"], name: "index_csv_imports_on_s3_key", unique: true
    t.index ["status"], name: "index_csv_imports_on_status"
    t.index ["user_id", "created_at"], name: "index_csv_imports_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_csv_imports_on_user_id_and_status"
    t.index ["user_id"], name: "index_csv_imports_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id"
    t.decimal "amount"
    t.text "description"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount", "date"], name: "idx_transactions_amount_date"
    t.index ["amount"], name: "index_transactions_on_amount"
    t.index ["category_id", "date"], name: "idx_transactions_category_date"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["user_id", "amount", "date"], name: "idx_transactions_user_amount_date"
    t.index ["user_id", "category_id", "date"], name: "idx_transactions_user_category_date"
    t.index ["user_id", "category_id"], name: "index_transactions_on_user_id_and_category_id"
    t.index ["user_id", "created_at"], name: "idx_transactions_user_created_at"
    t.index ["user_id", "date", "amount"], name: "idx_transactions_user_date_amount"
    t.index ["user_id", "date"], name: "index_transactions_on_user_id_and_date"
    t.index ["user_id"], name: "idx_transactions_user_uncategorized", where: "(category_id IS NULL)"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "anomalies", "transactions"
  add_foreign_key "categories", "users"
  add_foreign_key "categorization_rules", "categories"
  add_foreign_key "categorization_rules", "users"
  add_foreign_key "csv_imports", "users"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
end
