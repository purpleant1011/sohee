# frozen_string_literal: true

# ChangeApproval — Discord 승인/거부 버튼 응답 기록
# 원칙: 모든 결정은 기록되어야 함 (감사 추적)
class ChangeApproval < ApplicationRecord
  ACTIONS = %w[approve reject edit expire].freeze

  belongs_to :change_proposal

  validates :action, inclusion: { in: ACTIONS }

  scope :approvals, -> { where(action: "approve") }
  scope :rejections, -> { where(action: "reject") }

  def approval?
    action == "approve"
  end

  def rejection?
    action == "reject"
  end
end