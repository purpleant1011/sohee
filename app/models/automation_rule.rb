class AutomationRule < ApplicationRecord
  include AccountScoped
  belongs_to :account
  belongs_to :ai_employee
  belongs_to :approved_by_user, class_name: "User", optional: true
  has_many :automation_schedules, dependent: :destroy
  has_many :automation_executions, dependent: :destroy

  after_create_commit :notify_ops_of_creation

  def notify_ops_of_creation
    OpsNotifier.automation_rule_created(self)
  rescue StandardError => e
    Rails.logger.warn("[AutomationRule] notify_ops_of_creation failed: #{e.message}")
  end

  STATUSES = %w[draft active paused archived].freeze
  INTENT_KINDS = %w[post reply report faq_update data_export].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :intent_kind, inclusion: { in: INTENT_KINDS }

  scope :active, -> { where(status: "active") }
  scope :paused, -> { where(status: "paused") }
  scope :draft,  -> { where(status: "draft") }

  def structured_constraints
    constraints.presence || {}
  end

  def activate!(approver: nil)
    transaction do
      update!(status: "active", approved_by_user: approver, approved_at: Time.current)
    end
  end
end
