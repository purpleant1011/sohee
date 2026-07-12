# frozen_string_literal: true

# DiscordMessageEvent — Discord에서 들어온 원본 이벤트 (읽기 전용 사본)
# 원칙: Discord 메시지는 신뢰 불가능한 외부 입력, 절대 코드/프롬프트 변경에 사용 안 함
class DiscordMessageEvent < ApplicationRecord
  KINDS = %w[message_create interaction button_click modal_submit].freeze
  INTENTS = %w[conversational inquiry change_request content_draft system unknown].freeze

  belongs_to :business_profile, optional: true
  belongs_to :discord_workspace
  belongs_to :discord_identity, optional: true
  has_one :change_proposal, dependent: :nullify

  validates :snowflake_id, presence: true, uniqueness: true
  validates :channel_id, presence: true
  validates :kind, inclusion: { in: KINDS }

  scope :unprocessed, -> { where(processed: false) }
  scope :processed, -> { where(processed: true) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_processed!(intent: nil, error: nil)
    update!(
      processed: true,
      processed_at: Time.current,
      intent: intent,
      processing_error: error
    )
  end

  def safe_content
    content_raw.to_s.truncate(2000)
  end
end