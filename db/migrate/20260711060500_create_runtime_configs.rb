class CreateRuntimeConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :runtime_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.string :version, null: false, default: "v0"             # semver-like (v1, v2, ...)
      t.string :status, null: false, default: "draft"          # draft | active | archived | rolled_back
      t.string :checksum, null: false, default: ""             # SHA1 of bundle_json for quick diff
      t.json :bundle_json, null: false, default: {}            # persona + business + channels + faqs + routines + handoff
      t.text :change_summary                                   # 운영 노트 (rollback reason 등)
      t.references :activated_by, foreign_key: { to_table: :users }
      t.datetime :activated_at
      t.references :rolled_back_by, foreign_key: { to_table: :users }
      t.datetime :rolled_back_at
      t.timestamps
    end

    add_index :runtime_configs, [:account_id, :status]
    add_index :runtime_configs, [:account_id, :created_at]
    add_index :runtime_configs, [:account_id, :version]

    # Heartbeat — 가벼운 ping (last_seen_at 기록)
    create_table :runtime_heartbeats do |t|
      t.references :runtime_config, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :source, null: false, default: "sohee"   # sohee | operator | scheduler
      t.string :status, null: false, default: "ok"      # ok | degraded | down
      t.integer :open_jobs, default: 0
      t.integer :failed_jobs_24h, default: 0
      t.json :meta_json, default: {}
      t.datetime :checked_at, null: false
      t.timestamps
    end

    add_index :runtime_heartbeats, [:account_id, :checked_at]
    add_index :runtime_heartbeats, [:runtime_config_id, :checked_at]
  end
end