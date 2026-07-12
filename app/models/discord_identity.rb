# frozen_string_literal: true

# DiscordIdentity — Discord 사용자 ↔ 사업자 직원/소유자 1:1 연결
# 원칙: 사용자는 본인 사업자 안에서만 활동, 다른 사업자 ID로는 활동 불가
class DiscordIdentity < ApplicationRecord
  ROLE_IN_BUSINESS = %w[owner manager staff viewer].freeze

  belongs_to :business_profile
  belongs_to :user
  has_many :change_proposals, foreign_key: :decided_by_user_id, dependent: :nullify
  has_many :discord_message_events, dependent: :nullify

  validates :discord_user_id, presence: true, uniqueness: true
  validates :role_in_business, inclusion: { in: ROLE_IN_BUSINESS }

  scope :verified, -> { where.not(verified_at: nil) }
  scope :unverified, -> { where(verified_at: nil) }

  before_validation :generate_verification_code, on: :create

  def verified?
    verified_at.present?
  end

  def verify!
    return false if verified?
    update!(verified_at: Time.current, verification_code: nil)
  end

  def verification_expired?
    verification_expires_at.present? && verification_expires_at < Time.current
  end

  private

  def generate_verification_code
    return if verification_code.present?
    self.verification_code = SecureRandom.urlsafe_base64(24)
    self.verification_expires_at = 15.minutes.from_now
  end
end