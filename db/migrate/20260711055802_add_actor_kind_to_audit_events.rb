class AddActorKindToAuditEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :audit_events, :actor_kind, :string, null: false, default: "system"
    add_index :audit_events, [:account_id, :actor_kind, :created_at]
  end
end