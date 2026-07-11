class RuntimeConfig < ApplicationRecord
  belongs_to :account
  belongs_to :activated_by, class_name: "User", optional: true
  belongs_to :rolled_back_by, class_name: "User", optional: true
  has_many :runtime_heartbeats, dependent: :destroy

  STATUSES = %w[draft active archived rolled_back].freeze

  validates :version, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }

  def draft?
    status == "draft"
  end

  def active?
    status == "active"
  end

  # 현재 계정의 활성 bundle
  def self.current_for(account)
    active.where(account_id: account.id).first
  end

  # bundle_json 스냅샷 — 현재 DB 상태에서 직렬화
  def self.snapshot_for(account)
    bp = account.business_profile
    ai = account.ai_employees.where(status: "active").first
    {
      schema_version: "sohee.runtime/v1",
      generated_at: Time.current.iso8601,
      business: bp ? {
        trade_name: bp.trade_name,
        legal_name: bp.legal_name,
        owner_name: bp.owner_name,
        industry_code: bp.industry_code,
        region_label: bp.region_label.to_s.gsub(/청라|이아름|바이름|퍼플앤트|김선영|owner@/, "—"),
        brand_intro: bp.brand_intro,
        forbidden_phrases: Array(bp.forbidden_phrases_json),
        forbidden_topics: Array(bp.forbidden_topics_json),
        escalation_rules: Array(bp.escalation_rules_json),
        operator_managed: bp.operator_managed,
        public_email: bp.public_email,
        phone: bp.phone
      } : nil,
      persona: ai ? {
        key: ai.persona_preset,
        name: ai.name,
        role_label: ai.role_label,
        tone: ai.tone,
        friendliness: ai.friendliness,
        expertise_level: ai.expertise_level,
        proactiveness: ai.proactiveness,
        honorific: ai.honorific,
        sentence_length: ai.sentence_length,
        industry_expertise: ai.industry_expertise,
        natural_language_instructions: ai.natural_language_instructions,
        forbidden_phrases: Array(ai.forbidden_phrases_json),
        can_answer_topics: Array(ai.can_answer_topics_json),
        must_handoff_topics: Array(ai.must_handoff_topics_json),
        vocabulary_phrases: Array(ai.vocabulary_phrases_json),
        work_days: Array(ai.work_days_json),
        work_hours: ai.work_hours_json
      } : nil,
      channels: account.channel_connections.map { |c|
        { id: c.id, kind: c.kind, handle: c.handle, status: c.status, error_message: c.error_message }
      },
      faqs: account.faqs.where(active: true).map { |f| { id: f.id, question: f.question, answer: f.answer } },
      knowledge_sources: account.knowledge_sources.where(status: "ready").count,
      content_approved: account.content_items.where(state: "approved").count,
      automation_rules: account.automation_rules.where(status: "active").count
    }
  end

  # bundle_json 직렬화 + checksum 갱신
  def compute_checksum!
    raw = bundle_json.is_a?(String) ? bundle_json : bundle_json.to_json
    self.checksum = Digest::SHA1.hexdigest(raw).first(12)
  end

  # 다음 버전 번호
  def self.next_version(account)
    latest = where(account_id: account.id).order(created_at: :desc).first
    n = latest&.version.to_s.delete("v").to_i + 1
    "v#{n}"
  end

  # 이 bundle을 active로 만들기 (기존 active는 archived로)
  def activate!(user:)
    RuntimeConfig.transaction do
      RuntimeConfig.where(account_id: account_id, status: "active").update_all(status: "archived")
      update!(status: "active", activated_by: user, activated_at: Time.current)
      AuditEvent.create!(
        account_id: account_id,
        action: "runtime_config.activated",
        resource_type: "RuntimeConfig",
        resource_id: id,
        actor_kind: "user",
        metadata: { version: version, checksum: checksum },
        occurred_at: Time.current
      )
    end
  end

  # rollback: status=rolled_back, 직전 active를 다시 active로 복원
  def rollback!(user:, reason:)
    return false unless active?
    previous = RuntimeConfig.where(account_id: account_id, status: "active").where.not(id: id).first
    RuntimeConfig.transaction do
      update!(status: "rolled_back", rolled_back_by: user, rolled_back_at: Time.current, change_summary: [change_summary, "ROLLBACK: #{reason}"].compact.join("\n"))
      previous&.update!(status: "active")
      AuditEvent.create!(
        account_id: account_id,
        action: "runtime_config.rolled_back",
        resource_type: "RuntimeConfig",
        resource_id: id,
        actor_kind: "user",
        metadata: { reason: reason, restored_to: previous&.version },
        occurred_at: Time.current
      )
    end
    true
  end
end