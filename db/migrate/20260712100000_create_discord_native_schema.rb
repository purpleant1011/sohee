# Discord-Native 신규 모델 마이그레이션 (P1)
# 7개 신규 테이블 + RuntimeConfig v2 확장
# 작성일: 2026-07-12

class CreateDiscordNativeSchema < ActiveRecord::Migration[8.0]
  def change
    # 1. DiscordWorkspace — Discord 서버 ↔ 사업자 연결
    create_table :discord_workspaces do |t|
      t.references :business_profile, null: false, foreign_key: true, index: true
      t.bigint :guild_id, null: false, index: { unique: true }
      t.string :guild_name
      t.bigint :default_channel_id
      t.string :default_channel_name
      t.bigint :sohee_category_id
      t.string :status, null: false, default: "pending" # pending|active|paused|disconnected
      t.datetime :connected_at
      t.datetime :last_event_at
      t.string :connected_by_discord_id # Discord 사용자 snowflake (식별자)
      t.jsonb :guild_meta # 권한·멤버 수 등 메타
      t.timestamps
    end
    add_index :discord_workspaces, :status

    # 2. DiscordIdentity — Discord 사용자 ↔ 사업자 직원/소유자 연결
    create_table :discord_identities do |t|
      t.references :business_profile, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.bigint :discord_user_id, null: false, index: { unique: true }
      t.string :discord_username
      t.string :discord_discriminator
      t.string :role_in_business, null: false, default: "staff" # owner|manager|staff|viewer
      t.datetime :verified_at
      t.string :verification_code
      t.datetime :verification_expires_at
      t.jsonb :metadata
      t.timestamps
    end
    add_index :discord_identities, [:business_profile_id, :user_id], unique: true

    # 3. DiscordMessageEvent — 원문 이벤트 (읽기 전용 사본)
    create_table :discord_message_events do |t|
      t.references :business_profile, foreign_key: true, index: true, null: true
      t.references :discord_workspace, foreign_key: true, index: true
      t.references :discord_identity, foreign_key: true, index: true, null: true
      t.bigint :snowflake_id, null: false, index: { unique: true } # Discord 메시지 ID
      t.bigint :channel_id, null: false, index: true
      t.bigint :guild_id
      t.bigint :author_discord_id
      t.string :kind, null: false, default: "message_create" # message_create|interaction|button_click|modal_submit
      t.text :content_raw
      t.string :intent # conversational|inquiry|change_request|content_draft|system
      t.jsonb :attachments_meta
      t.jsonb :embeds_meta
      t.jsonb :mentions_meta
      t.boolean :processed, null: false, default: false, index: true
      t.datetime :processed_at
      t.string :processing_error
      t.timestamps
    end
    add_index :discord_message_events, [:discord_workspace_id, :snowflake_id]
    add_index :discord_message_events, :created_at

    # 4. ChangeProposal — Gemini가 만든 영구 변경 후보
    create_table :change_proposals do |t|
      t.references :business_profile, null: false, foreign_key: true, index: true
      t.references :discord_message_event, foreign_key: true, index: true, null: true
      t.references :ai_employee, foreign_key: true, index: true
      t.string :target_kind, null: false # runtime_config|business_profile|knowledge_source|automation_rule|faq
      t.string :target_field # 예: business_hours, handoff_rule, persona_tone
      t.jsonb :proposed_payload, null: false # 변경할 값 (구조화)
      t.jsonb :previous_payload # 현재 값
      t.text :reason # 사람이 읽을 이유
      t.text :user_quote # 사용자가 실제로 뭐라고 했는지 (출처)
      t.string :status, null: false, default: "pending" # pending|approved|rejected|applied|cancelled|expired
      t.datetime :expires_at
      t.datetime :decided_at
      t.string :decided_by_discord_id
      t.references :decided_by_user, foreign_key: { to_table: :users }, index: true, null: true
      t.string :applied_runtime_config_id
      t.timestamps
    end
    add_index :change_proposals, :status
    add_index :change_proposals, [:business_profile_id, :status]
    add_index :change_proposals, :expires_at

    # 5. ChangeApproval — 승인/거부 카드 응답 (Discord 버튼 기록)
    create_table :change_approvals do |t|
      t.references :change_proposal, null: false, foreign_key: true, index: true
      t.bigint :discriminator_discord_id
      t.string :action, null: false # approve|reject|edit|expire
      t.jsonb :payload_override # 편집 시 payload 수정본
      t.text :comment
      t.string :interaction_token # Discord Interaction 응답 토큰 (3분 이내)
      t.string :message_snapshot # 카드 메시지 스냅샷 (감사용)
      t.timestamps
    end

    # 6. BusinessMemory — 고객사 단위 누적 메모리 (단기 컨텍스트 + 장기 사실)
    create_table :business_memories do |t|
      t.references :business_profile, null: false, foreign_key: true, index: true
      t.string :scope, null: false, default: "short_term" # short_term|long_term|persona
      t.string :memory_kind, null: false # fact|preference|inquiry_pattern|frequent_request|guardrail
      t.string :subject # 사람 이름, 서비스명, 정책 등
      t.text :content
      t.jsonb :structured_payload # {k: v} 구조화 데이터 (선택)
      t.string :source_kind, null: false, default: "discord" # discord|api|manual|system
      t.bigint :source_discord_event_id # 출처 이벤트
      t.float :weight, null: false, default: 1.0 # 0.0~1.0, retrieval 가중치
      t.datetime :expires_at # short_term 만료
      t.datetime :last_recalled_at
      t.integer :recall_count, null: false, default: 0
      t.timestamps
    end
    add_index :business_memories, [:business_profile_id, :scope]
    add_index :business_memories, [:business_profile_id, :memory_kind]
    add_index :business_memories, :expires_at

    # 7. RuntimeSync — 워커 ↔ Hermes ACK 흐름
    create_table :runtime_syncs do |t|
      t.references :business_profile, null: false, foreign_key: true, index: true
      t.string :direction, null: false # rails_to_hermes|hermes_to_rails|hermes_ack|hermes_nack
      t.string :topic, null: false # runtime_config_update|content_draft|inquiry_classified|knowledge_gap|health
      t.string :agent_id # hermes agent_id, "sohee-control-mcp" 등
      t.jsonb :payload, null: false
      t.jsonb :response_payload # ACK/NACK 응답
      t.string :status, null: false, default: "pending" # pending|ack|nack|timeout|retrying
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false, default: 3
      t.datetime :delivered_at
      t.datetime :acked_at
      t.datetime :next_retry_at
      t.text :error_message
      t.string :idempotency_key, null: false, index: { unique: true }
      t.timestamps
    end
    add_index :runtime_syncs, [:status, :next_retry_at]
    add_index :runtime_syncs, [:business_profile_id, :direction]

    # RuntimeConfig v2 확장 (P1.3 — Discord-Native 컴파일 결과 기록)
    add_column :runtime_configs, :compiled_at, :datetime
    add_column :runtime_configs, :compiled_by_agent_id, :string
    add_column :runtime_configs, :source_change_proposal_id, :bigint
    add_index :runtime_configs, :compiled_at
    add_index :runtime_configs, :source_change_proposal_id
  end
end