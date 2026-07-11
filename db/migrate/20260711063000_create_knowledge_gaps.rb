class CreateKnowledgeGaps < ActiveRecord::Migration[8.0]
  def change
    create_table :knowledge_gaps do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ai_employee, foreign_key: true
      t.string  :channel, default: "chat", null: false
      t.text    :question, null: false
      t.text    :answer_attempted
      t.string  :hit_kind, default: "no_hit", null: false  # no_hit|low_score|out_of_scope
      t.float   :score
      t.string  :status, default: "open", null: false      # open|converted_to_faq|dismissed
      t.bigint  :resolved_by_faq_id
      t.text    :note
      t.timestamps
    end
    add_index :knowledge_gaps, [:account_id, :status]
    add_index :knowledge_gaps, [:account_id, :created_at]
  end
end