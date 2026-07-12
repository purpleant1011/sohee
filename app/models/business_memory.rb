# frozen_string_literal: true

# BusinessMemory — 고객사 단위 누적 메모리
# 원칙: 고객사 간 격리 (모든 쿼리에 business_profile_id 강제)
# 원칙 10: 다른 사업자의 메모리는 절대 조회 불가
class BusinessMemory < ApplicationRecord
  SCOPES = %w[short_term long_term persona].freeze
  KINDS = %w[fact preference inquiry_pattern frequent_request guardrail].freeze
  SOURCE_KINDS = %w[discord api manual system].freeze

  belongs_to :business_profile

  validates :scope, inclusion: { in: SCOPES }
  validates :memory_kind, inclusion: { in: KINDS }
  validates :source_kind, inclusion: { in: SOURCE_KINDS }
  validates :content, presence: true
  validates :weight, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :short_term, -> { where(scope: "short_term") }
  scope :long_term, -> { where(scope: "long_term") }
  scope :persona, -> { where(scope: "persona") }
  scope :recent, -> { order(created_at: :desc) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def touch_recall!
    increment!(:recall_count)
    update_column(:last_recalled_at, Time.current)
  end

  def self.recall(business_profile:, kinds: nil, limit: 10)
    scope = active.where(business_profile_id: business_profile.id)
    scope = scope.where(memory_kind: kinds) if kinds.present?
    scope.order(weight: :desc, last_recalled_at: :desc).limit(limit)
  end
end