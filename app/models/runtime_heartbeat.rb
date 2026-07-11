class RuntimeHeartbeat < ApplicationRecord
  belongs_to :account
  belongs_to :runtime_config, optional: true

  STATUSES = %w[ok degraded down].freeze
  SOURCES = %w[sohee operator scheduler].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }
  validates :checked_at, presence: true

  scope :recent, -> { order(checked_at: :desc) }
  scope :last_24h, -> { where("checked_at > ?", 24.hours.ago) }

  # 직전 heartbeat 조회
  def self.last_for(account)
    where(account_id: account.id).order(checked_at: :desc).first
  end

  # 24시간 상태 통계
  def self.summary_24h(account)
    beats = last_24h.where(account_id: account.id)
    {
      count: beats.count,
      ok: beats.where(status: "ok").count,
      degraded: beats.where(status: "degraded").count,
      down: beats.where(status: "down").count,
      last: beats.order(checked_at: :desc).first
    }
  end
end