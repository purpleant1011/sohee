# frozen_string_literal: true

# ChangeProposal — Gemini가 만든 영구 변경 후보
# 원칙 9: 영구 변경 = 제안 → 확인 → 적용. 이 모델은 "제안" 단계까지.
# 원칙 6: 시스템 프롬프트/도구 권한 변경 후보는 별도 검증 절차 후에만.
class ChangeProposal < ApplicationRecord
  TARGET_KINDS = %w[runtime_config business_profile knowledge_source automation_rule faq guardrail].freeze
  STATUSES = %w[pending approved rejected applied cancelled expired].freeze

  belongs_to :business_profile
  belongs_to :discord_message_event, optional: true
  belongs_to :ai_employee
  belongs_to :decided_by_user, class_name: "User", optional: true
  has_many :change_approvals, dependent: :destroy

  validates :target_kind, inclusion: { in: TARGET_KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :proposed_payload, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :awaiting_decision, -> { where(status: "pending").where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  before_create :set_expiry

  def pending?
    status == "pending"
  end

  def applied?
    status == "applied"
  end

  def approve!(actor:, discord_id: nil, payload_override: nil)
    return false unless pending?
    transaction do
      change_approvals.create!(
        discriminator_discord_id: discord_id,
        action: "approve",
        payload_override: payload_override
      )
      updates = {
        status: "approved",
        decided_at: Time.current,
        decided_by_user: actor,
        decided_by_discord_id: discord_id
      }
      updates[:proposed_payload] = payload_override if payload_override
      update!(updates)
    end
    true
  end

  def reject!(actor:, discord_id: nil, comment: nil)
    return false unless pending?
    transaction do
      change_approvals.create!(
        discriminator_discord_id: discord_id,
        action: "reject",
        comment: comment
      )
      update!(
        status: "rejected",
        decided_at: Time.current,
        decided_by_user: actor,
        decided_by_discord_id: discord_id
      )
    end
    true
  end

  def mark_applied!(runtime_config_id:)
    update!(status: "applied", applied_runtime_config_id: runtime_config_id.to_s)
  end

  def display_summary
    "#{target_kind}.#{target_field} — #{reason.to_s.truncate(80)}"
  end

  private

  def set_expiry
    self.expires_at ||= 24.hours.from_now
  end
end