# frozen_string_literal: true

# RuntimeSync — 워커 ↔ Hermes ACK 흐름
# 원칙: 모든 외부 호출은 멱등키 + 재시도 + 타임아웃
class RuntimeSync < ApplicationRecord
  DIRECTIONS = %w[rails_to_hermes hermes_to_rails hermes_ack hermes_nack].freeze
  TOPICS = %w[
    runtime_config_update
    content_draft
    inquiry_classified
    knowledge_gap
    change_proposal_applied
    health
  ].freeze
  STATUSES = %w[pending ack nack timeout retrying].freeze

  belongs_to :business_profile

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :topic, inclusion: { in: TOPICS }
  validates :status, inclusion: { in: STATUSES }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :payload, presence: true

  scope :pending_dispatch, -> { where(status: "pending") }
  scope :ready_for_retry, -> { where(status: %w[pending retrying]).where("next_retry_at IS NULL OR next_retry_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  before_validation :ensure_idempotency_key

  def pending?
    status == "pending" || status == "retrying"
  end

  def mark_delivered!
    update!(status: "retrying", delivered_at: Time.current, attempts: attempts + 1)
  end

  def mark_ack!(response:)
    update!(status: "ack", acked_at: Time.current, response_payload: response)
  end

  def mark_nack!(response:, error: nil)
    update!(status: "nack", acked_at: Time.current, response_payload: response, error_message: error)
  end

  def schedule_retry!(backoff:)
    update!(
      status: "retrying",
      next_retry_at: backoff.from_now,
      error_message: "scheduled retry ##{attempts + 1}"
    )
  end

  def exhausted?
    attempts >= max_attempts
  end

  private

  def ensure_idempotency_key
    self.idempotency_key ||= "#{direction}.#{topic}.#{business_profile_id}.#{SecureRandom.uuid}"
  end
end