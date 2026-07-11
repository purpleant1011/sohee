# frozen_string_literal: true
class KnowledgeGap < ApplicationRecord
  belongs_to :account
  belongs_to :ai_employee, optional: true

  HIT_KINDS = %w[no_hit low_score out_of_scope].freeze
  STATUSES  = %w[open converted_to_faq dismissed].freeze
  CHANNELS  = %w[chat comment dm in_store].freeze

  validates :question, presence: true
  validates :channel, inclusion: { in: CHANNELS }
  validates :hit_kind, inclusion: { in: HIT_KINDS }
  validates :status,  inclusion: { in: STATUSES }

  scope :open_first, -> { where(status: "open").order(created_at: :desc) }
  scope :recent,     -> { order(created_at: :desc) }

  def self.record(account:, question:, hit_kind:, channel: "chat", answer_attempted: nil, score: nil, ai_employee: nil)
    create!(
      account: account,
      ai_employee: ai_employee || account.ai_employees.where(status: "active").first,
      channel: channel,
      question: question.to_s.first(500),
      answer_attempted: answer_attempted.to_s.first(1000),
      hit_kind: hit_kind,
      score: score
    )
  end

  def mark_converted!(faq)
    update!(status: "converted_to_faq", resolved_by_faq_id: faq.id)
  end

  def dismiss!(note = nil)
    update!(status: "dismissed", note: note)
  end
end