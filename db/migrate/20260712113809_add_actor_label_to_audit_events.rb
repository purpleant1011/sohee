class AddActorLabelToAuditEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :audit_events, :actor_label, :string
    add_index :audit_events, :actor_label
  end
end
