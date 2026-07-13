class ChannelConnection < ApplicationRecord
  include AccountScoped
  include JsonAttr
  json_attr :scopes_json, default: ->{ [] }
  encrypts :encrypted_token if respond_to?(:encrypts)

  belongs_to :account
  belongs_to :ai_employee, optional: true
  belongs_to :connected_by_user, class_name: "User", optional: true
  has_many :channel_scopes, dependent: :destroy

  KINDS = %w[discord instagram threads blog naver_place daangn kakao_channel email mastodon].freeze
  STATUSES = %w[planned ready active paused revoked error].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :connected_by_kind, inclusion: { in: %w[owner operator staff] }

  def ready_for_publish?
    status == "active" && channel_scopes.where(publish_allowed: true).exists?
  end

  # 24시간 내 3회 이상 실패 → 운영팀 알림
  after_update_commit :notify_ops_of_recurring_failure

  def recent_failure_count
    PublicationAttempt.where(channel_connection_id: id, state: "failed")
                      .where("created_at >= ?", 24.hours.ago).count
  rescue StandardError
    0
  end

  def notify_ops_of_recurring_failure
    return unless saved_change_to_status? && status == "error"
    return if recent_failure_count < 3
    OpsNotifier.channel_failure(self, error_message.presence || "24시간 내 3회 이상 게시 실패")
  rescue StandardError => e
    Rails.logger.warn("[ChannelConnection#notify_ops] #{e.message}")
  end
end
