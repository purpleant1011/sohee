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

ActiveRecord::Schema[8.0].define(version: 2026_07_11_063000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.string "timezone", default: "Asia/Seoul", null: false
    t.string "country", default: "KR", null: false
    t.boolean "operator_managed", default: false, null: false
    t.string "operator_managed_by_email"
    t.text "settings_json", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
    t.index ["status"], name: "index_accounts_on_status"
  end

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

  create_table "ai_employee_versions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id", null: false
    t.integer "version_number", null: false
    t.text "snapshot_json", null: false
    t.text "change_summary"
    t.bigint "changed_by_user_id"
    t.boolean "restored_from_previous", default: false, null: false
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ai_employee_versions_on_account_id"
    t.index ["ai_employee_id"], name: "index_ai_employee_versions_on_ai_employee_id"
    t.index ["changed_by_user_id"], name: "index_ai_employee_versions_on_changed_by_user_id"
  end

  create_table "ai_employees", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "avatar_url"
    t.string "role_label", default: "마케팅 직원", null: false
    t.text "industry_expertise"
    t.string "tone", default: "calm_professional", null: false
    t.integer "friendliness", default: 60, null: false
    t.integer "expertise_level", default: 70, null: false
    t.integer "proactiveness", default: 50, null: false
    t.string "honorific", default: "formal", null: false
    t.integer "sentence_length", default: 60, null: false
    t.text "vocabulary_phrases_json", default: "[]", null: false
    t.text "forbidden_phrases_json", default: "[]", null: false
    t.text "can_answer_topics_json", default: "[]", null: false
    t.text "must_handoff_topics_json", default: "[]", null: false
    t.text "work_days_json", default: "[\"mon\",\"tue\",\"wed\",\"thu\",\"fri\"]", null: false
    t.text "work_hours_json", default: "{\"start\":\"09:00\",\"end\":\"18:00\"}", null: false
    t.integer "daily_post_quota", default: 1, null: false
    t.integer "weekly_post_quota", default: 5, null: false
    t.string "approval_mode", default: "owner_review", null: false
    t.text "channel_behaviors_json", default: "{}", null: false
    t.integer "monthly_token_budget", default: 200000, null: false
    t.integer "daily_token_budget", default: 20000, null: false
    t.integer "monthly_cost_budget_krw", default: 50000, null: false
    t.integer "daily_cost_budget_krw", default: 5000, null: false
    t.text "natural_language_instructions"
    t.text "system_notes"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "memory_json", default: {"notes" => [], "topics" => [], "style_examples" => []}, null: false
    t.string "persona_preset"
    t.datetime "last_memory_extracted_at"
    t.string "preferred_locale", default: "auto", null: false
    t.string "supported_locales", default: "ko,en", null: false
    t.string "fallback_locale", default: "ko", null: false
    t.index ["account_id"], name: "index_ai_employees_on_account_id"
    t.index ["status"], name: "index_ai_employees_on_status"
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "account_id"
    t.string "kind", default: "info", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "audience", default: "all", null: false
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.bigint "created_by_platform_staff_id"
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_announcements_on_account_id_and_status"
    t.index ["account_id"], name: "index_announcements_on_account_id"
    t.index ["created_by_platform_staff_id"], name: "index_announcements_on_created_by_platform_staff_id"
    t.index ["status", "audience", "published_at"], name: "index_announcements_on_status_and_audience_and_published_at"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "service_account_id"
    t.bigint "user_id"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "token_prefix", default: "", null: false
    t.jsonb "scopes", default: [], null: false
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_api_tokens_on_account_id"
    t.index ["service_account_id"], name: "index_api_tokens_on_service_account_id"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "approval_requests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "automation_execution_id"
    t.bigint "content_item_id"
    t.string "state", default: "pending", null: false
    t.bigint "requested_from_user_id"
    t.bigint "decided_by_user_id"
    t.datetime "decided_at"
    t.text "decision_notes"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_approval_requests_on_account_id"
    t.index ["automation_execution_id"], name: "index_approval_requests_on_automation_execution_id"
    t.index ["content_item_id"], name: "index_approval_requests_on_content_item_id"
    t.index ["decided_by_user_id"], name: "index_approval_requests_on_decided_by_user_id"
    t.index ["requested_from_user_id"], name: "index_approval_requests_on_requested_from_user_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "actor_user_id"
    t.bigint "actor_platform_staff_id"
    t.bigint "service_account_id"
    t.string "action", null: false
    t.string "resource_type"
    t.bigint "resource_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "request_id"
    t.string "ip_address"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "actor_kind", default: "system", null: false
    t.index ["account_id", "actor_kind", "created_at"], name: "index_audit_events_on_account_id_and_actor_kind_and_created_at"
    t.index ["account_id"], name: "index_audit_events_on_account_id"
    t.index ["actor_platform_staff_id"], name: "index_audit_events_on_actor_platform_staff_id"
    t.index ["actor_user_id"], name: "index_audit_events_on_actor_user_id"
    t.index ["service_account_id"], name: "index_audit_events_on_service_account_id"
  end

  create_table "automation_executions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "automation_rule_id", null: false
    t.bigint "ai_employee_id", null: false
    t.string "state", default: "draft", null: false
    t.string "idempotency_key", null: false
    t.text "error_class"
    t.text "error_message"
    t.integer "attempts", default: 0, null: false
    t.integer "max_attempts", default: 3, null: false
    t.datetime "scheduled_at"
    t.datetime "claimed_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "worker_id"
    t.datetime "heartbeat_at"
    t.datetime "lease_expires_at"
    t.datetime "approval_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_kind", default: "manual", null: false
    t.string "trigger_kind", default: "time", null: false
    t.jsonb "input_json", default: {}
    t.jsonb "output_json", default: {}
    t.bigint "content_item_id"
    t.jsonb "result_payload_json", default: {}
    t.index ["account_id"], name: "index_automation_executions_on_account_id"
    t.index ["ai_employee_id"], name: "index_automation_executions_on_ai_employee_id"
    t.index ["automation_rule_id"], name: "index_automation_executions_on_automation_rule_id"
    t.index ["content_item_id"], name: "index_automation_executions_on_content_item_id"
    t.index ["idempotency_key"], name: "index_automation_executions_on_idempotency_key", unique: true
    t.index ["scheduled_at"], name: "index_automation_executions_on_scheduled_at"
    t.index ["state"], name: "index_automation_executions_on_state"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id", null: false
    t.string "name", null: false
    t.string "intent_kind", null: false
    t.text "natural_language"
    t.jsonb "structured_plan", default: {}, null: false
    t.jsonb "constraints", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.bigint "approved_by_user_id"
    t.datetime "approved_at"
    t.text "approval_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_automation_rules_on_account_id"
    t.index ["ai_employee_id"], name: "index_automation_rules_on_ai_employee_id"
    t.index ["approved_by_user_id"], name: "index_automation_rules_on_approved_by_user_id"
  end

  create_table "automation_schedules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "automation_rule_id", null: false
    t.string "cadence", null: false
    t.text "cron_expression"
    t.datetime "next_run_at"
    t.datetime "last_run_at"
    t.boolean "quiet_hours", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_automation_schedules_on_account_id"
    t.index ["automation_rule_id"], name: "index_automation_schedules_on_automation_rule_id"
    t.index ["next_run_at"], name: "index_automation_schedules_on_next_run_at"
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "scope", null: false
    t.string "metric", null: false
    t.integer "limit_value", null: false
    t.integer "warn_at_percent", default: 80, null: false
    t.integer "current_value", default: 0, null: false
    t.datetime "period_start"
    t.datetime "period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_budgets_on_account_id"
  end

  create_table "business_profiles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "legal_name", null: false
    t.string "trade_name"
    t.string "industry_code", default: "other", null: false
    t.string "industry_subcategory"
    t.string "owner_name"
    t.string "business_registration_number"
    t.string "phone"
    t.string "public_email"
    t.text "address"
    t.string "region_label"
    t.text "business_hours_json", default: "{}", null: false
    t.text "holidays_json", default: "[]", null: false
    t.text "timezone", default: "Asia/Seoul", null: false
    t.text "brand_intro"
    t.text "products_json", default: "[]", null: false
    t.text "services_json", default: "[]", null: false
    t.text "faqs_json", default: "[]", null: false
    t.text "customer_anxieties_json", default: "[]", null: false
    t.text "target_audience"
    t.text "differentiators"
    t.text "forbidden_phrases_json", default: "[]", null: false
    t.text "forbidden_topics_json", default: "[]", null: false
    t.text "escalation_rules_json", default: "[]", null: false
    t.text "preferred_channels_json", default: "[]", null: false
    t.integer "onboarding_step", default: 0, null: false
    t.boolean "onboarding_complete", default: false, null: false
    t.boolean "operator_managed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_business_profiles_on_account_id"
    t.index ["industry_code"], name: "index_business_profiles_on_industry_code"
  end

  create_table "channel_connections", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.string "kind", null: false
    t.string "handle"
    t.string "external_id"
    t.text "encrypted_token"
    t.string "status", default: "planned", null: false
    t.text "scopes_json", default: "[]", null: false
    t.text "error_message"
    t.string "connected_by_kind", default: "owner", null: false
    t.bigint "connected_by_user_id"
    t.datetime "last_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_channel_connections_on_account_id"
    t.index ["ai_employee_id"], name: "index_channel_connections_on_ai_employee_id"
    t.index ["connected_by_user_id"], name: "index_channel_connections_on_connected_by_user_id"
  end

  create_table "channel_scopes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "channel_connection_id", null: false
    t.string "scope", null: false
    t.string "label"
    t.boolean "publish_allowed", default: false, null: false
    t.boolean "read_allowed", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_channel_scopes_on_account_id"
    t.index ["channel_connection_id"], name: "index_channel_scopes_on_channel_connection_id"
  end

  create_table "content_items", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id", null: false
    t.bigint "automation_rule_id"
    t.string "title", null: false
    t.text "body"
    t.text "caption"
    t.text "hashtags_json", default: "[]", null: false
    t.string "content_kind", default: "feed", null: false
    t.string "state", default: "draft", null: false
    t.string "safety_state", default: "unchecked", null: false
    t.jsonb "safety_notes", default: [], null: false
    t.text "evidence_chunks_json", default: "[]", null: false
    t.string "target_channel_kind"
    t.bigint "target_channel_connection_id"
    t.datetime "scheduled_at"
    t.datetime "published_at"
    t.text "published_external_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_content_items_on_account_id"
    t.index ["ai_employee_id"], name: "index_content_items_on_ai_employee_id"
    t.index ["scheduled_at"], name: "index_content_items_on_scheduled_at"
    t.index ["target_channel_connection_id"], name: "index_content_items_on_target_channel_connection_id"
  end

  create_table "content_versions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "content_item_id", null: false
    t.integer "version_number", null: false
    t.text "body"
    t.text "caption"
    t.text "hashtags_json", default: "[]", null: false
    t.jsonb "diff_from_previous", default: {}, null: false
    t.bigint "changed_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_content_versions_on_account_id"
    t.index ["changed_by_user_id"], name: "index_content_versions_on_changed_by_user_id"
    t.index ["content_item_id"], name: "index_content_versions_on_content_item_id"
  end

  create_table "contract_terms", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "plan_id"
    t.string "contract_code", null: false
    t.integer "monthly_price_krw", default: 0, null: false
    t.integer "monthly_price_vat_krw", default: 0, null: false
    t.integer "deposit_amount_krw", default: 0, null: false
    t.integer "billing_anchor_day", default: 1, null: false
    t.date "test_started_on"
    t.date "test_ends_on"
    t.date "official_service_started_on"
    t.string "status", default: "draft", null: false
    t.jsonb "price_overrides", default: {}, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_contract_terms_on_account_id"
    t.index ["contract_code"], name: "index_contract_terms_on_contract_code", unique: true
    t.index ["plan_id"], name: "index_contract_terms_on_plan_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.string "kind", null: false
    t.string "display_name"
    t.text "encrypted_contact"
    t.boolean "remembered", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_conversation_participants_on_account_id"
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id", null: false
    t.bigint "channel_connection_id"
    t.string "channel_kind", null: false
    t.string "external_thread_id"
    t.string "customer_display_name"
    t.string "state", default: "open", null: false
    t.string "risk_level", default: "low", null: false
    t.datetime "last_message_at"
    t.datetime "escalated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "detected_locale", default: "ko", null: false
    t.string "response_locale", default: "ko", null: false
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["ai_employee_id"], name: "index_conversations_on_ai_employee_id"
    t.index ["channel_connection_id"], name: "index_conversations_on_channel_connection_id"
  end

  create_table "csat_responses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id"
    t.string "channel", default: "app", null: false
    t.integer "score", null: false
    t.text "comment"
    t.string "respondent_kind", default: "customer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_csat_responses_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_csat_responses_on_account_id"
    t.index ["conversation_id"], name: "index_csat_responses_on_conversation_id"
  end

  create_table "data_export_requests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "requested_by_user_id"
    t.string "state", default: "pending", null: false
    t.string "storage_path"
    t.datetime "ready_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "format", default: "json", null: false
    t.string "kind", default: "full"
    t.text "filters_json"
    t.bigint "file_size_bytes"
    t.text "row_counts_json"
    t.string "checksum_sha256"
    t.datetime "requested_at"
    t.datetime "started_at"
    t.text "error_message"
    t.index ["account_id"], name: "index_data_export_requests_on_account_id"
    t.index ["format"], name: "index_data_export_requests_on_format"
    t.index ["requested_by_user_id"], name: "index_data_export_requests_on_requested_by_user_id"
    t.index ["state"], name: "index_data_export_requests_on_state"
  end

  create_table "deletion_requests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "requested_by_user_id"
    t.string "state", default: "pending", null: false
    t.datetime "completed_at"
    t.text "deletion_summary_json", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_deletion_requests_on_account_id"
    t.index ["requested_by_user_id"], name: "index_deletion_requests_on_requested_by_user_id"
  end

  create_table "delivery_logs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "kind", default: "campaign", null: false
    t.string "subject", default: "", null: false
    t.text "body_excerpt"
    t.integer "recipient_count", default: 0, null: false
    t.datetime "delivered_at"
    t.string "external_provider"
    t.jsonb "result_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "kind", "delivered_at"], name: "index_delivery_logs_on_account_id_and_kind_and_delivered_at"
    t.index ["account_id"], name: "index_delivery_logs_on_account_id"
  end

  create_table "deposits", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "contract_term_id"
    t.integer "amount_krw", null: false
    t.string "state", default: "received", null: false
    t.date "received_on"
    t.date "refunded_on"
    t.text "refund_bank_info_encrypted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_deposits_on_account_id"
    t.index ["contract_term_id"], name: "index_deposits_on_contract_term_id"
  end

  create_table "document_chunks", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "knowledge_document_id", null: false
    t.integer "position", null: false
    t.text "content", null: false
    t.text "content_tsvector"
    t.string "content_sha256", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('simple'::regconfig, content)", name: "idx_doc_chunks_tsvector", using: :gin
    t.index ["account_id"], name: "index_document_chunks_on_account_id"
    t.index ["content_sha256"], name: "index_document_chunks_on_content_sha256"
    t.index ["knowledge_document_id"], name: "index_document_chunks_on_knowledge_document_id"
  end

  create_table "embeddings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "document_chunk_id", null: false
    t.string "provider", null: false
    t.string "model_code", null: false
    t.integer "dimensions", null: false
    t.text "vector_data"
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_embeddings_on_account_id"
    t.index ["document_chunk_id"], name: "index_embeddings_on_document_chunk_id"
  end

  create_table "escalation_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.string "topic", null: false
    t.text "handoff_message"
    t.string "handoff_channel", default: "kakao", null: false
    t.text "handoff_contact"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_escalation_rules_on_account_id"
    t.index ["ai_employee_id"], name: "index_escalation_rules_on_ai_employee_id"
  end

  create_table "execution_events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "automation_execution_id", null: false
    t.string "event_type", null: false
    t.text "message"
    t.jsonb "payload", default: {}, null: false
    t.string "actor_kind", default: "system", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_execution_events_on_account_id"
    t.index ["automation_execution_id"], name: "index_execution_events_on_automation_execution_id"
  end

  create_table "faqs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.string "question", null: false
    t.text "answer", null: false
    t.text "tags_json", default: "[]", null: false
    t.string "risk_level", default: "low", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_faqs_on_account_id"
    t.index ["ai_employee_id"], name: "index_faqs_on_ai_employee_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "key", null: false
    t.bigint "account_id"
    t.boolean "enabled", default: false, null: false
    t.jsonb "value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_feature_flags_on_account_id"
  end

  create_table "guardrail_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id", null: false
    t.string "kind", null: false
    t.string "pattern"
    t.text "description"
    t.string "severity", default: "block", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_guardrail_policies_on_account_id"
    t.index ["ai_employee_id"], name: "index_guardrail_policies_on_ai_employee_id"
  end

  create_table "handoffs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "message_id"
    t.string "reason", null: false
    t.text "summary"
    t.string "channel", null: false
    t.string "state", default: "open", null: false
    t.bigint "assigned_to_user_id"
    t.datetime "acknowledged_at"
    t.datetime "resolved_at"
    t.text "resolution_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_handoffs_on_account_id"
    t.index ["assigned_to_user_id"], name: "index_handoffs_on_assigned_to_user_id"
    t.index ["conversation_id"], name: "index_handoffs_on_conversation_id"
    t.index ["message_id"], name: "index_handoffs_on_message_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.bigint "account_id"
    t.string "severity", default: "low", null: false
    t.string "title", null: false
    t.text "description"
    t.string "state", default: "open", null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_incidents_on_account_id"
  end

  create_table "industry_templates", force: :cascade do |t|
    t.string "industry_code", null: false
    t.string "version", null: false
    t.jsonb "starter_brand_profile", default: {}, null: false
    t.jsonb "starter_ai_employee", default: {}, null: false
    t.jsonb "starter_automations", default: [], null: false
    t.jsonb "starter_guardrails", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "industry_kind"
    t.string "display_name"
    t.index ["slug"], name: "index_industry_templates_on_slug"
  end

  create_table "inquiries", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "subject", null: false
    t.text "body", null: false
    t.string "subject_kind"
    t.decimal "score", precision: 4, scale: 3
    t.string "status", default: "new", null: false
    t.boolean "consent_marketing", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_inquiries_on_status"
    t.index ["subject_kind"], name: "index_inquiries_on_subject_kind"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "contract_term_id"
    t.string "invoice_number", null: false
    t.date "billing_period_start", null: false
    t.date "billing_period_end", null: false
    t.integer "supply_amount_krw", default: 0, null: false
    t.integer "vat_amount_krw", default: 0, null: false
    t.integer "total_amount_krw", default: 0, null: false
    t.integer "discount_amount_krw", default: 0, null: false
    t.integer "final_amount_krw", default: 0, null: false
    t.string "state", default: "draft", null: false
    t.date "due_on"
    t.date "issued_on"
    t.date "paid_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["contract_term_id"], name: "index_invoices_on_contract_term_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
  end

  create_table "knowledge_documents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "knowledge_source_id", null: false
    t.string "version", default: "1.0", null: false
    t.text "raw_text"
    t.text "normalized_text"
    t.string "mime_type"
    t.integer "byte_size"
    t.string "checksum_sha256", null: false
    t.text "extraction_error"
    t.integer "pii_warnings_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "indexed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_knowledge_documents_on_account_id"
    t.index ["knowledge_source_id"], name: "index_knowledge_documents_on_knowledge_source_id"
  end

  create_table "knowledge_gaps", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.string "channel", default: "chat", null: false
    t.text "question", null: false
    t.text "answer_attempted"
    t.string "hit_kind", default: "no_hit", null: false
    t.float "score"
    t.string "status", default: "open", null: false
    t.bigint "resolved_by_faq_id"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_knowledge_gaps_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_knowledge_gaps_on_account_id_and_status"
    t.index ["account_id"], name: "index_knowledge_gaps_on_account_id"
    t.index ["ai_employee_id"], name: "index_knowledge_gaps_on_ai_employee_id"
  end

  create_table "knowledge_sources", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.string "kind", null: false
    t.string "title"
    t.text "url"
    t.string "language", default: "ko", null: false
    t.text "tags_json", default: "[]", null: false
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.text "rights_confirmation"
    t.boolean "contains_personal_data", default: false, null: false
    t.boolean "ai_training_allowed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_knowledge_sources_on_account_id"
    t.index ["ai_employee_id"], name: "index_knowledge_sources_on_ai_employee_id"
  end

  create_table "magic_links", force: :cascade do |t|
    t.string "email", null: false
    t.string "token_hash", null: false
    t.string "purpose", default: "user_login", null: false
    t.datetime "expires_at", null: false
    t.datetime "consumed_at"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "purpose"], name: "index_magic_links_on_email_and_purpose"
    t.index ["expires_at"], name: "index_magic_links_on_expires_at"
    t.index ["token_hash"], name: "index_magic_links_on_token_hash", unique: true
  end

  create_table "media_assets", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "content_item_id"
    t.string "kind", null: false
    t.string "filename", null: false
    t.string "storage_path"
    t.string "checksum_sha256"
    t.text "description"
    t.boolean "contains_personal_data", default: false, null: false
    t.boolean "ai_training_allowed", default: false, null: false
    t.string "consent_status", default: "unknown", null: false
    t.text "consent_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_media_assets_on_account_id"
    t.index ["content_item_id"], name: "index_media_assets_on_content_item_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "owner", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_memberships_on_account_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.string "direction", null: false
    t.string "author_kind", null: false
    t.text "body", null: false
    t.jsonb "redacted_body_json", default: {}, null: false
    t.text "ai_draft"
    t.jsonb "evidence_chunks_json", default: "[]", null: false
    t.string "state", default: "received", null: false
    t.text "error_message"
    t.datetime "redacted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "model_catalog_entries", force: :cascade do |t|
    t.string "code", null: false
    t.string "provider", null: false
    t.string "kind", null: false
    t.string "display_name"
    t.text "description"
    t.string "api_model_name"
    t.integer "context_window"
    t.integer "max_output_tokens"
    t.integer "input_price_per_1k_krw", default: 0, null: false
    t.integer "output_price_per_1k_krw", default: 0, null: false
    t.integer "image_price_per_unit_krw", default: 0, null: false
    t.boolean "training_opt_out", default: true, null: false
    t.string "data_residency_region"
    t.boolean "active", default: true, null: false
    t.jsonb "capabilities", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_model_catalog_entries_on_code", unique: true
  end

  create_table "model_policies", force: :cascade do |t|
    t.bigint "account_id"
    t.string "purpose", null: false
    t.string "primary_code", null: false
    t.string "fallback_code"
    t.integer "daily_token_cap", default: 100000, null: false
    t.integer "monthly_token_cap", default: 2000000, null: false
    t.integer "daily_cost_cap_krw", default: 10000, null: false
    t.integer "monthly_cost_cap_krw", default: 200000, null: false
    t.text "masking_rules_json", default: "[]", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_model_policies_on_account_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.bigint "actor_platform_staff_id"
    t.string "kind", null: false
    t.string "title", null: false
    t.text "body"
    t.string "severity", default: "info", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["actor_platform_staff_id"], name: "index_notifications_on_actor_platform_staff_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "invoice_id"
    t.string "provider", null: false
    t.string "provider_txn_id"
    t.integer "amount_krw", null: false
    t.string "state", default: "pending", null: false
    t.datetime "paid_at"
    t.text "memo"
    t.text "encrypted_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "monthly_price_krw", default: 0, null: false
    t.integer "monthly_price_vat_krw", default: 0, null: false
    t.jsonb "features", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plans_on_code", unique: true
  end

  create_table "platform_sessions", force: :cascade do |t|
    t.bigint "platform_staff_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revoked_at"
    t.string "token_hash"
    t.datetime "expires_at"
    t.index ["platform_staff_id"], name: "index_platform_sessions_on_platform_staff_id"
    t.index ["token_hash"], name: "index_platform_sessions_on_token_hash"
  end

  create_table "platform_staff", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", default: "", null: false
    t.string "role", default: "staff", null: false
    t.boolean "disabled", default: false, null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_platform_staff_on_email_address", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "base_price_krw"
    t.integer "duration_min"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_products_on_account_id"
  end

  create_table "prompt_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "version", null: false
    t.string "purpose"
    t.text "system_prompt"
    t.text "user_prompt_template"
    t.text "output_schema"
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "publication_attempts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "content_item_id", null: false
    t.bigint "channel_connection_id", null: false
    t.string "idempotency_key", null: false
    t.string "state", default: "pending", null: false
    t.integer "attempts", default: 0, null: false
    t.text "error_message"
    t.text "external_url"
    t.text "external_id"
    t.jsonb "request_payload", default: {}, null: false
    t.jsonb "response_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_publication_attempts_on_account_id"
    t.index ["channel_connection_id"], name: "index_publication_attempts_on_channel_connection_id"
    t.index ["content_item_id"], name: "index_publication_attempts_on_content_item_id"
    t.index ["idempotency_key"], name: "index_publication_attempts_on_idempotency_key", unique: true
  end

  create_table "referral_links", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "created_by_user_id"
    t.string "code", null: false
    t.string "target_industry_filter"
    t.boolean "active", default: true, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_referral_links_on_account_id"
    t.index ["code"], name: "index_referral_links_on_code", unique: true
    t.index ["created_by_user_id"], name: "index_referral_links_on_created_by_user_id"
  end

  create_table "referral_rewards", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "referral_id", null: false
    t.integer "discount_amount_krw_per_month", null: false
    t.integer "discount_months", null: false
    t.date "starts_on"
    t.date "ends_on"
    t.string "state", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_referral_rewards_on_account_id"
    t.index ["referral_id"], name: "index_referral_rewards_on_referral_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "referral_link_id", null: false
    t.bigint "referrer_account_id", null: false
    t.string "referred_business_name"
    t.string "referred_business_type"
    t.date "referred_contract_date"
    t.string "state", default: "lead", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referral_link_id"], name: "index_referrals_on_referral_link_id"
    t.index ["referrer_account_id"], name: "index_referrals_on_referrer_account_id"
  end

  create_table "runtime_configs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "version", default: "v0", null: false
    t.string "status", default: "draft", null: false
    t.string "checksum", default: "", null: false
    t.json "bundle_json", default: {}, null: false
    t.text "change_summary"
    t.bigint "activated_by_id"
    t.datetime "activated_at"
    t.bigint "rolled_back_by_id"
    t.datetime "rolled_back_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_runtime_configs_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_runtime_configs_on_account_id_and_status"
    t.index ["account_id", "version"], name: "index_runtime_configs_on_account_id_and_version"
    t.index ["account_id"], name: "index_runtime_configs_on_account_id"
    t.index ["activated_by_id"], name: "index_runtime_configs_on_activated_by_id"
    t.index ["rolled_back_by_id"], name: "index_runtime_configs_on_rolled_back_by_id"
  end

  create_table "runtime_heartbeats", force: :cascade do |t|
    t.bigint "runtime_config_id"
    t.bigint "account_id", null: false
    t.string "source", default: "sohee", null: false
    t.string "status", default: "ok", null: false
    t.integer "open_jobs", default: 0
    t.integer "failed_jobs_24h", default: 0
    t.json "meta_json", default: {}
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "checked_at"], name: "index_runtime_heartbeats_on_account_id_and_checked_at"
    t.index ["account_id"], name: "index_runtime_heartbeats_on_account_id"
    t.index ["runtime_config_id", "checked_at"], name: "index_runtime_heartbeats_on_runtime_config_id_and_checked_at"
    t.index ["runtime_config_id"], name: "index_runtime_heartbeats_on_runtime_config_id"
  end

  create_table "safety_logs", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "content_item_id"
    t.bigint "conversation_id"
    t.string "stage", default: "pre_publish", null: false
    t.string "verdict", default: "passed", null: false
    t.jsonb "rules_json", default: [], null: false
    t.jsonb "hits_json", default: [], null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_safety_logs_on_account_id"
    t.index ["content_item_id"], name: "index_safety_logs_on_content_item_id"
    t.index ["stage"], name: "index_safety_logs_on_stage"
    t.index ["verdict"], name: "index_safety_logs_on_verdict"
  end

  create_table "service_accounts", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.string "purpose", null: false
    t.string "role", default: "worker", null: false
    t.boolean "disabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_service_accounts_on_account_id"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_services_on_account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revoked_at"
    t.string "token_hash"
    t.datetime "last_seen_at"
    t.datetime "expires_at"
    t.index ["token_hash"], name: "index_sessions_on_token_hash"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "plan_id", null: false
    t.bigint "contract_term_id"
    t.string "state", default: "active", null: false
    t.date "started_on", null: false
    t.date "current_period_start", null: false
    t.date "current_period_end", null: false
    t.date "next_billing_on"
    t.date "ended_on"
    t.integer "monthly_price_krw", default: 0, null: false
    t.integer "monthly_price_vat_krw", default: 0, null: false
    t.integer "deposit_krw", default: 0, null: false
    t.boolean "auto_renew", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["state"], name: "index_subscriptions_on_state"
  end

  create_table "termination_requests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "requested_by_user_id"
    t.date "applied_on"
    t.date "requested_termination_on"
    t.text "reason"
    t.string "state", default: "received", null: false
    t.datetime "completed_at"
    t.text "revocation_checklist_json", default: "[]", null: false
    t.text "export_requested_json", default: "[]", null: false
    t.text "deletion_requested_json", default: "[]", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_termination_requests_on_account_id"
    t.index ["requested_by_user_id"], name: "index_termination_requests_on_requested_by_user_id"
  end

  create_table "usage_records", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ai_employee_id"
    t.bigint "automation_execution_id"
    t.bigint "content_item_id"
    t.bigint "message_id"
    t.string "purpose", null: false
    t.string "model_code", null: false
    t.string "provider", null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "image_count", default: 0, null: false
    t.integer "cost_krw", default: 0, null: false
    t.integer "latency_ms", default: 0, null: false
    t.string "result_state", default: "ok", null: false
    t.text "error_class"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_usage_records_on_account_id"
    t.index ["ai_employee_id"], name: "index_usage_records_on_ai_employee_id"
    t.index ["automation_execution_id"], name: "index_usage_records_on_automation_execution_id"
    t.index ["content_item_id"], name: "index_usage_records_on_content_item_id"
    t.index ["message_id"], name: "index_usage_records_on_message_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", default: "", null: false
    t.string "role", default: "owner", null: false
    t.string "locale", default: "ko", null: false
    t.datetime "last_login_at"
    t.boolean "disabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "kind", null: false
    t.string "url", null: false
    t.string "secret_digest", null: false
    t.string "state", default: "active", null: false
    t.datetime "last_called_at"
    t.string "last_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_webhook_endpoints_on_account_id"
  end

  create_table "weekly_reports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "week_start_on", null: false
    t.date "week_end_on", null: false
    t.integer "content_created_count", default: 0, null: false
    t.integer "content_approved_count", default: 0, null: false
    t.integer "content_published_count", default: 0, null: false
    t.integer "content_failed_count", default: 0, null: false
    t.integer "inquiry_count", default: 0, null: false
    t.integer "handoff_count", default: 0, null: false
    t.integer "ai_token_used", default: 0, null: false
    t.integer "ai_cost_krw", default: 0, null: false
    t.text "summary"
    t.text "improvement_suggestions"
    t.jsonb "top_topics", default: [], null: false
    t.jsonb "missing_knowledge", default: [], null: false
    t.string "state", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_weekly_reports_on_account_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_employee_versions", "accounts"
  add_foreign_key "ai_employee_versions", "ai_employees"
  add_foreign_key "ai_employee_versions", "users", column: "changed_by_user_id"
  add_foreign_key "ai_employees", "accounts"
  add_foreign_key "announcements", "accounts", on_delete: :cascade
  add_foreign_key "announcements", "platform_staff", column: "created_by_platform_staff_id", on_delete: :nullify
  add_foreign_key "api_tokens", "accounts"
  add_foreign_key "api_tokens", "service_accounts"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "approval_requests", "accounts"
  add_foreign_key "approval_requests", "automation_executions"
  add_foreign_key "approval_requests", "content_items"
  add_foreign_key "approval_requests", "users", column: "decided_by_user_id"
  add_foreign_key "approval_requests", "users", column: "requested_from_user_id"
  add_foreign_key "audit_events", "accounts"
  add_foreign_key "audit_events", "platform_staff", column: "actor_platform_staff_id"
  add_foreign_key "audit_events", "service_accounts"
  add_foreign_key "audit_events", "users", column: "actor_user_id"
  add_foreign_key "automation_executions", "accounts"
  add_foreign_key "automation_executions", "ai_employees"
  add_foreign_key "automation_executions", "automation_rules"
  add_foreign_key "automation_rules", "accounts"
  add_foreign_key "automation_rules", "ai_employees"
  add_foreign_key "automation_rules", "users", column: "approved_by_user_id"
  add_foreign_key "automation_schedules", "accounts"
  add_foreign_key "automation_schedules", "automation_rules"
  add_foreign_key "budgets", "accounts"
  add_foreign_key "business_profiles", "accounts"
  add_foreign_key "channel_connections", "accounts"
  add_foreign_key "channel_connections", "ai_employees"
  add_foreign_key "channel_connections", "users", column: "connected_by_user_id"
  add_foreign_key "channel_scopes", "accounts"
  add_foreign_key "channel_scopes", "channel_connections"
  add_foreign_key "content_items", "accounts"
  add_foreign_key "content_items", "ai_employees"
  add_foreign_key "content_items", "channel_connections", column: "target_channel_connection_id"
  add_foreign_key "content_versions", "accounts"
  add_foreign_key "content_versions", "content_items"
  add_foreign_key "content_versions", "users", column: "changed_by_user_id"
  add_foreign_key "contract_terms", "accounts"
  add_foreign_key "contract_terms", "plans"
  add_foreign_key "conversation_participants", "accounts"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversations", "accounts"
  add_foreign_key "conversations", "ai_employees"
  add_foreign_key "conversations", "channel_connections"
  add_foreign_key "data_export_requests", "accounts"
  add_foreign_key "data_export_requests", "users", column: "requested_by_user_id"
  add_foreign_key "deletion_requests", "accounts"
  add_foreign_key "deletion_requests", "users", column: "requested_by_user_id"
  add_foreign_key "delivery_logs", "accounts"
  add_foreign_key "deposits", "accounts"
  add_foreign_key "deposits", "contract_terms"
  add_foreign_key "document_chunks", "accounts"
  add_foreign_key "document_chunks", "knowledge_documents"
  add_foreign_key "embeddings", "accounts"
  add_foreign_key "embeddings", "document_chunks"
  add_foreign_key "escalation_rules", "accounts"
  add_foreign_key "escalation_rules", "ai_employees"
  add_foreign_key "execution_events", "accounts"
  add_foreign_key "execution_events", "automation_executions"
  add_foreign_key "faqs", "accounts"
  add_foreign_key "faqs", "ai_employees"
  add_foreign_key "feature_flags", "accounts"
  add_foreign_key "guardrail_policies", "accounts"
  add_foreign_key "guardrail_policies", "ai_employees"
  add_foreign_key "handoffs", "accounts"
  add_foreign_key "handoffs", "conversations"
  add_foreign_key "handoffs", "messages"
  add_foreign_key "handoffs", "users", column: "assigned_to_user_id"
  add_foreign_key "incidents", "accounts"
  add_foreign_key "invoices", "accounts"
  add_foreign_key "invoices", "contract_terms"
  add_foreign_key "knowledge_documents", "accounts"
  add_foreign_key "knowledge_documents", "knowledge_sources"
  add_foreign_key "knowledge_gaps", "accounts"
  add_foreign_key "knowledge_gaps", "ai_employees"
  add_foreign_key "knowledge_sources", "accounts"
  add_foreign_key "knowledge_sources", "ai_employees"
  add_foreign_key "media_assets", "accounts"
  add_foreign_key "media_assets", "content_items"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "accounts"
  add_foreign_key "messages", "conversations"
  add_foreign_key "model_policies", "accounts"
  add_foreign_key "notifications", "accounts"
  add_foreign_key "notifications", "platform_staff", column: "actor_platform_staff_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "invoices"
  add_foreign_key "platform_sessions", "platform_staff"
  add_foreign_key "products", "accounts"
  add_foreign_key "publication_attempts", "accounts"
  add_foreign_key "publication_attempts", "channel_connections"
  add_foreign_key "publication_attempts", "content_items"
  add_foreign_key "referral_links", "accounts"
  add_foreign_key "referral_links", "users", column: "created_by_user_id"
  add_foreign_key "referral_rewards", "accounts"
  add_foreign_key "referral_rewards", "referrals"
  add_foreign_key "referrals", "accounts", column: "referrer_account_id"
  add_foreign_key "referrals", "referral_links"
  add_foreign_key "runtime_configs", "accounts"
  add_foreign_key "runtime_configs", "users", column: "activated_by_id"
  add_foreign_key "runtime_configs", "users", column: "rolled_back_by_id"
  add_foreign_key "runtime_heartbeats", "accounts"
  add_foreign_key "runtime_heartbeats", "runtime_configs"
  add_foreign_key "service_accounts", "accounts"
  add_foreign_key "services", "accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "termination_requests", "accounts"
  add_foreign_key "termination_requests", "users", column: "requested_by_user_id"
  add_foreign_key "usage_records", "accounts"
  add_foreign_key "usage_records", "ai_employees"
  add_foreign_key "usage_records", "automation_executions"
  add_foreign_key "usage_records", "content_items"
  add_foreign_key "usage_records", "messages"
  add_foreign_key "users", "accounts"
  add_foreign_key "webhook_endpoints", "accounts"
  add_foreign_key "weekly_reports", "accounts"
end
