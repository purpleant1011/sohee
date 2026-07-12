# frozen_string_literal: true

# DiscordWorkspace — Discord 서버 ↔ 사업자 1:1 연결
# 원칙: 1 사업자 = 1 서버 (필요 시 추후 확장)
class DiscordWorkspace < ApplicationRecord
  STATUSES = %w[pending active paused disconnected].freeze

  belongs_to :business_profile
  has_many :discord_identities, dependent: :restrict_with_error
  has_many :discord_message_events, dependent: :restrict_with_error

  validates :guild_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :pending, -> { where(status: "pending") }

  def active?
    status == "active"
  end

  def mark_event_received!
    update!(last_event_at: Time.current)
  end

  def display_label
    "#{business_profile.display_name} ↔ #{guild_name.presence || "Discord ##{guild_id}"}"
  end
end