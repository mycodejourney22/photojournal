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

ActiveRecord::Schema[7.1].define(version: 2025_09_19_210624) do
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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointment_notes", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.text "content", null: false
    t.string "note_type", null: false
    t.string "title"
    t.bigint "created_by_id"
    t.integer "priority", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "actioned", default: false, null: false
    t.datetime "actioned_at"
    t.integer "actioned_by_id"
    t.index ["actioned"], name: "index_appointment_notes_on_actioned"
    t.index ["actioned_by_id"], name: "index_appointment_notes_on_actioned_by_id"
    t.index ["appointment_id", "note_type"], name: "idx_appointment_notes_on_appointment_and_type"
    t.index ["appointment_id"], name: "index_appointment_notes_on_appointment_id"
    t.index ["created_by_id"], name: "idx_appointment_notes_on_created_by"
    t.index ["created_by_id"], name: "index_appointment_notes_on_created_by_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", null: false
    t.boolean "no_show", default: false
    t.boolean "status", default: true
    t.string "channel"
    t.integer "price"
    t.bigint "price_id"
    t.boolean "payment_status", default: false
    t.string "referral_source"
    t.bigint "studio_id"
    t.string "coupon_code"
    t.integer "coupon_discount", default: 0
    t.index ["coupon_code"], name: "index_appointments_on_coupon_code"
    t.index ["price_id"], name: "index_appointments_on_price_id"
    t.index ["start_time"], name: "index_appointments_on_start_time"
    t.index ["studio_id"], name: "index_appointments_on_studio_id"
    t.index ["uuid"], name: "index_appointments_on_uuid", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "campaign_customers", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "customer_id", null: false
    t.string "status", default: "pending"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.integer "open_count", default: 0
    t.integer "click_count", default: 0
    t.json "clicked_links", default: []
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "customer_id"], name: "index_campaign_customers_on_campaign_id_and_customer_id", unique: true
    t.index ["campaign_id"], name: "index_campaign_customers_on_campaign_id"
    t.index ["customer_id"], name: "index_campaign_customers_on_customer_id"
    t.index ["status"], name: "index_campaign_customers_on_status"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "subject", null: false
    t.text "preheader"
    t.text "body", null: false
    t.string "campaign_type", default: "greeting", null: false
    t.string "template"
    t.string "sender_name", default: "363 Photography"
    t.string "sender_email", default: "noreply@363photography.org"
    t.integer "status", default: 0
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_type"], name: "index_campaigns_on_campaign_type"
    t.index ["name"], name: "index_campaigns_on_name"
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code", null: false
    t.string "coupon_type", default: "fixed_amount", null: false
    t.text "description"
    t.integer "discount_amount", default: 0
    t.integer "discount_percentage", default: 0
    t.integer "max_uses", default: 1000
    t.integer "usage_count", default: 0
    t.datetime "expires_at"
    t.string "status", default: "active"
    t.boolean "customer_restrictions", default: false
    t.text "campaign_notes"
    t.string "minimum_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.index ["coupon_type"], name: "index_coupons_on_coupon_type"
    t.index ["status", "expires_at"], name: "index_coupons_on_status_and_expires_at"
    t.index ["status"], name: "index_coupons_on_status"
  end

  create_table "credit_usages", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "appointment_id", null: false
    t.integer "amount", null: false
    t.datetime "used_at", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_credit_usages_on_appointment_id"
    t.index ["customer_id", "used_at"], name: "index_credit_usages_on_customer_id_and_used_at"
    t.index ["customer_id"], name: "index_credit_usages_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.date "date_of_birth"
    t.integer "visits_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "credits", default: 0, null: false
    t.string "referral_source"
    t.boolean "email_opt_out", default: false
    t.datetime "email_opt_out_date"
    t.json "email_preferences"
    t.index ["phone_number"], name: "index_customers_on_phone_number", unique: true
  end

  create_table "editor_assignments", force: :cascade do |t|
    t.bigint "photo_shoot_id", null: false
    t.bigint "editor_id", null: false
    t.bigint "assigned_by_id"
    t.datetime "assigned_at", null: false
    t.string "status", default: "active", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_at"], name: "index_editor_assignments_on_assigned_at"
    t.index ["assigned_by_id"], name: "index_editor_assignments_on_assigned_by_id"
    t.index ["editor_id", "assigned_at"], name: "index_editor_assignments_on_editor_id_and_assigned_at"
    t.index ["editor_id"], name: "index_editor_assignments_on_editor_id"
    t.index ["photo_shoot_id", "status"], name: "index_editor_assignments_on_photo_shoot_id_and_status"
    t.index ["photo_shoot_id"], name: "index_editor_assignments_on_photo_shoot_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.date "date"
    t.string "description"
    t.string "category"
    t.string "staff"
    t.decimal "amount"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gadgets", force: :cascade do |t|
    t.string "name"
    t.datetime "date"
    t.string "location"
    t.integer "amount"
    t.integer "quantity"
    t.string "descriptions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "galleries", force: :cascade do |t|
    t.string "title"
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "share_token"
    t.string "smugmug_status", default: "pending"
    t.string "smugmug_url"
    t.string "smugmug_key"
    t.datetime "last_sync_at"
    t.index ["appointment_id"], name: "index_galleries_on_appointment_id"
    t.index ["smugmug_key"], name: "index_galleries_on_smugmug_key", unique: true, where: "(smugmug_key IS NOT NULL)"
    t.index ["smugmug_status"], name: "index_galleries_on_smugmug_status"
  end

  create_table "gallery_mappings", force: :cascade do |t|
    t.bigint "gallery_id", null: false
    t.bigint "customer_id"
    t.string "smugmug_key"
    t.string "smugmug_url"
    t.string "folder_path"
    t.integer "status", default: 0
    t.text "error_message"
    t.string "share_token"
    t.string "share_url"
    t.datetime "share_token_expires_at"
    t.integer "views_count", default: 0
    t.datetime "last_accessed_at"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_gallery_mappings_on_customer_id"
    t.index ["gallery_id"], name: "index_gallery_mappings_on_gallery_id"
    t.index ["status"], name: "index_gallery_mappings_on_status"
  end

  create_table "photo_shoots", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.date "date"
    t.integer "photographer_id"
    t.integer "editor_id"
    t.integer "customer_service_id"
    t.integer "number_of_selections"
    t.string "status", default: "New"
    t.string "type_of_shoot"
    t.integer "number_of_outfits"
    t.date "date_sent"
    t.decimal "payment_total"
    t.string "payment_method"
    t.string "payment_type"
    t.string "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notes"
    t.index ["appointment_id"], name: "index_photo_shoots_on_appointment_id"
  end

  create_table "prices", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "amount"
    t.decimal "discount"
    t.integer "duration"
    t.string "included"
    t.string "shoot_type"
    t.boolean "still_valid"
    t.text "icon"
    t.string "outfit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "period"
  end

  create_table "questions", force: :cascade do |t|
    t.string "answer"
    t.integer "position"
    t.string "question"
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_questions_on_appointment_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "referrer_id", null: false
    t.bigint "referred_id"
    t.string "code", null: false
    t.string "status", default: "active", null: false
    t.datetime "converted_at"
    t.datetime "rewarded_at"
    t.datetime "expires_at"
    t.integer "reward_amount", default: 10000
    t.integer "referred_discount", default: 5000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "parent_code"
    t.index ["code"], name: "index_referrals_on_code", unique: true
    t.index ["parent_code"], name: "index_referrals_on_parent_code"
    t.index ["referred_id"], name: "index_referrals_on_referred_id"
    t.index ["referrer_id"], name: "index_referrals_on_referrer_id"
  end

  create_table "refund_requests", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.integer "status", default: 0, null: false
    t.string "reason", null: false
    t.decimal "refund_amount", precision: 10, scale: 2, null: false
    t.text "customer_notes"
    t.text "admin_notes"
    t.string "account_name", null: false
    t.string "account_number", null: false
    t.string "bank_name", null: false
    t.bigint "processed_by_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_refund_requests_on_appointment_id"
    t.index ["processed_by_id"], name: "index_refund_requests_on_processed_by_id"
    t.index ["status"], name: "index_refund_requests_on_status"
  end

  create_table "sales", force: :cascade do |t|
    t.datetime "date"
    t.decimal "amount_paid"
    t.string "payment_method"
    t.string "payment_type"
    t.string "customer_name"
    t.string "customer_phone_number"
    t.string "customer_service_officer_name"
    t.string "product_service_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.bigint "photo_shoot_id"
    t.string "reference"
    t.bigint "appointment_id"
    t.integer "staff_id"
    t.integer "customer_id"
    t.boolean "void", default: false
    t.string "void_reason"
    t.integer "discount", default: 0
    t.string "discount_reason"
    t.bigint "studio_id"
    t.index ["appointment_id"], name: "index_sales_on_appointment_id"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["photo_shoot_id"], name: "index_sales_on_photo_shoot_id"
    t.index ["studio_id"], name: "index_sales_on_studio_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.string "name"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
  end

  create_table "studios", force: :cascade do |t|
    t.string "name", null: false
    t.string "location", null: false
    t.string "address", null: false
    t.string "phone", null: false
    t.string "email", null: false
    t.boolean "active", default: true
    t.text "description"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "password_setup_token"
    t.datetime "password_setup_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "appointment_notes", "appointments"
  add_foreign_key "appointment_notes", "users", column: "actioned_by_id"
  add_foreign_key "appointment_notes", "users", column: "created_by_id"
  add_foreign_key "appointments", "prices"
  add_foreign_key "appointments", "studios"
  add_foreign_key "campaign_customers", "campaigns"
  add_foreign_key "campaign_customers", "customers"
  add_foreign_key "credit_usages", "appointments"
  add_foreign_key "credit_usages", "customers"
  add_foreign_key "editor_assignments", "photo_shoots"
  add_foreign_key "editor_assignments", "staffs", column: "assigned_by_id"
  add_foreign_key "editor_assignments", "staffs", column: "editor_id"
  add_foreign_key "galleries", "appointments"
  add_foreign_key "gallery_mappings", "customers"
  add_foreign_key "gallery_mappings", "galleries"
  add_foreign_key "photo_shoots", "appointments"
  add_foreign_key "questions", "appointments"
  add_foreign_key "referrals", "customers", column: "referred_id"
  add_foreign_key "referrals", "customers", column: "referrer_id"
  add_foreign_key "refund_requests", "appointments"
  add_foreign_key "refund_requests", "users", column: "processed_by_id"
  add_foreign_key "sales", "appointments"
  add_foreign_key "sales", "photo_shoots"
  add_foreign_key "sales", "studios"
end
