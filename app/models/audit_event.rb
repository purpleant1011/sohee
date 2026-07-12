class AuditEvent < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :actor_user, class_name: "User", optional: true
  belongs_to :actor_platform_staff, class_name: "PlatformStaff", optional: true
  belongs_to :service_account, optional: true

  ACTOR_KINDS = %w[user anon automation system operator].freeze
  validates :actor_kind, inclusion: { in: ACTOR_KINDS }

  before_validation :default_occurred_at

  private

  def default_occurred_at
    self.occurred_at ||= Time.current
  end
end
