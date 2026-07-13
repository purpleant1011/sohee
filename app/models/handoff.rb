class Handoff < ApplicationRecord
  include AccountScoped
  belongs_to :account
  belongs_to :conversation
  belongs_to :message, optional: true
  belongs_to :assigned_to_user, class_name: "User", optional: true

  STATES = %w[open acknowledged resolved abandoned].freeze
  validates :reason, presence: true
  validates :state, inclusion: { in: STATES }

  # account → business_profile (Handoff 는 BP 미보유, account 통해 조회)
  def business_profile
    account&.business_profile
  end

  after_create_commit :notify_ops_of_handoff

  private

  def notify_ops_of_handoff
    return unless state == "open"
    OpsNotifier.handoff_created(self)
  rescue StandardError => e
    Rails.logger.warn("[Handoff#notify_ops] #{e.message}")
  end
end
