class AiEmployee < ApplicationRecord
  include AccountScoped
  include JsonAttr

  # ActiveStorage 첨부 (비용 0: 로컬 디스크 사용)
  has_one_attached :avatar
  has_many_attached :reference_images

  # 사장님이 템플릿으로 빠르게 시작할 수 있는 페르소나 프리셋
  PERSONA_PRESETS = {
    "friendly_cafe" => {
      name: "카페 안내 담당",
      role_label: "카페 매장 안내",
      tone: "친근한",
      friendliness: 80,
      expertise_level: 70,
      proactiveness: 50,
      honorific: "습니다 체",
      sentence_length: "보통",
      persona_preset: "friendly_cafe",
      industry_expertise: "카페/음료",
      natural_language_instructions: "항상 따뜻하고 환하게 응대합니다. 메뉴 추천은 사장님의 베스트셀러 위주로 안내하고, 신메뉴나 시즌 음료를 먼저 언급합니다.",
      work_days_json: %w[mon tue wed thu fri sat sun],
      work_hours_json: { "start" => "08:00", "end" => "22:00" },
      vocabulary_phrases_json: ["오늘의 추천", "시즌 한정", "사장님 직접 로스팅"],
      forbidden_phrases_json: ["저희가 만든", "다른 집보다", "싸구려"],
      can_answer_topics_json: ["메뉴", "가격", "영업시간", "위치", "주차", "와이파이", "예약", "단체주문", "케이크주문"],
      must_handoff_topics_json: ["컴플레인", "환불", "민원", "개인정보수정"]
    },
    "pro_salon" => {
      name: "미용실 컨시어지",
      role_label: "미용실 컨시어지",
      tone: "격식 있는",
      friendliness: 60,
      expertise_level: 90,
      proactiveness: 40,
      honorific: "시 체",
      sentence_length: "보통",
      persona_preset: "pro_salon",
      industry_expertise: "미용/뷰티",
      natural_language_instructions: "20년 경력의 베테랑 스타일리스트처럼 전문적이지만 따뜻하게 응대합니다. 시술 추천은 고객의 모발 상태와 라이프스타일을 먼저 물어본 후 안내합니다.",
      work_days_json: %w[tue wed thu fri sat],
      work_hours_json: { "start" => "10:00", "end" => "20:00" },
      vocabulary_phrases_json: ["맞춤 상담", "모발 진단", "스타일링 제안"],
      forbidden_phrases_json: ["싸게", "저렴한", "무료"],
      can_answer_topics_json: ["시술가격", "소요시간", "스타일추천", "예약", "취소", "위치", "주차", "제품"],
      must_handoff_topics_json: ["환불", "민원", "시술실패", "부작용", "알레지"]
    },
    "warm_cafe_owner" => {
      name: "사장님 도우미",
      role_label: "사장님 대리인",
      tone: "캐주얼한",
      friendliness: 90,
      expertise_level: 60,
      proactiveness: 70,
      honorific: "요 체",
      sentence_length: "짧게",
      persona_preset: "warm_cafe_owner",
      industry_expertise: "소상공인 일반",
      natural_language_instructions: "사장님 본인이 직접 답하는 것처럼 친근하게 응대합니다. 단, 가격 협상이나 민감한 사안은 사장님께 인계합니다.",
      work_days_json: %w[mon tue wed thu fri sat],
      work_hours_json: { "start" => "09:00", "end" => "21:00" },
      vocabulary_phrases_json: ["제가 직접", "사장님이 알려주신", "한 번 와보세요"],
      forbidden_phrases_json: ["대리점", "프랜차이즈", "본사"],
      can_answer_topics_json: ["영업시간", "메뉴", "가격", "위치", "예약", "리뷰"],
      must_handoff_topics_json: ["가격협상", "민원", "환불", "개인정보"]
    },
    "expert_consultant" => {
      name: "전문 상담사",
      role_label: "전문 상담",
      tone: "격식 있는",
      friendliness: 40,
      expertise_level: 95,
      proactiveness: 30,
      honorific: "입니다 체",
      sentence_length: "길게",
      persona_preset: "expert_consultant",
      industry_expertise: "전문 서비스",
      natural_language_instructions: "20년 경력의 전문가로, 클라이언트의 상황을 먼저 파악한 뒤 깊이 있는 조언을 제공합니다. 모든 답변이 근거와 출처를 포함합니다.",
      work_days_json: %w[mon tue wed thu fri],
      work_hours_json: { "start" => "09:00", "end" => "18:00" },
      vocabulary_phrases_json: ["사례", "근거", "권장", "검토"],
      forbidden_phrases_json: ["단정", "확실히", "100%"],
      can_answer_topics_json: ["상담", "견적", "일정", "절차"],
      must_handoff_topics_json: ["계약", "수임료", "민원"]
    }
  }.freeze

  json_attr :vocabulary_phrases_json, default: ->{ [] }
  json_attr :forbidden_phrases_json, default: ->{ [] }
  json_attr :can_answer_topics_json, default: ->{ [] }
  json_attr :must_handoff_topics_json, default: ->{ [] }
  json_attr :work_days_json, default: ->{ %w[mon tue wed thu fri] }
  json_attr :work_hours_json, default: ->{ { "start" => "09:00", "end" => "18:00" } }
  json_attr :channel_behaviors_json, default: ->{ {} }
  json_attr :applied_to_channel_kind  # no-op placeholder; avoids method_missing

  # memory_json shape: { "notes" => [], "topics" => [], "style_examples" => [] }
  # Use #memory accessor for a normalized hash; raw column also accessible via `super`.
  def memory
    raw = self[:memory_json]
    raw.is_a?(Hash) ? raw : { "notes" => [], "topics" => [], "style_examples" => [] }
  end

  def append_memory!(kind:, value:)
    current = memory
    bucket  = Array(current[kind.to_s])
    entry   = { "v" => value.to_s, "at" => Time.current.iso8601 }
    bucket  << entry
    bucket  = bucket.last(50) # ring buffer
    current[kind.to_s] = bucket
    update_columns(memory_json: current, last_memory_extracted_at: Time.current)
    entry
  end

  # Light-touch heuristic extractor. Real Hermes adapter will replace this.
  def extract_memory_from_conversation!(conversation)
    return [] unless conversation
    text = conversation.messages.to_s
    saved = []

    if text.match?(/자주\s*묻는\s*질문|FAQ|자주/)
      saved << append_memory!(kind: "topics", value: "고객이 자주 묻는 질문을 정리")
    end
    if text.match?(/프로모션|이벤트|할인/)
      saved << append_memory!(kind: "topics", value: "프로모션/이벤트 관심 빈도")
    end
    if text.match?(/예약|방문|예약일|시간/)
      saved << append_memory!(kind: "topics", value: "예약/방문 시간 문의 빈번")
    end
    update_columns(last_memory_extracted_at: Time.current) if saved.any?
    saved
  end

  belongs_to :account
  has_many :ai_employee_versions, dependent: :destroy
  has_many :guardrail_policies, dependent: :destroy
  has_many :escalation_rules, dependent: :destroy
  has_many :automation_rules, dependent: :destroy
  has_many :content_items, dependent: :destroy
  has_many :conversations, dependent: :destroy

  validates :name, presence: true
  validates :role_label, presence: true

  # 사장님이 보는 한국어 라벨 ↔ 내부 enum 매핑
  TONE_LABELS = {
    "calm_professional" => "격식 있는",
    "warm_casual" => "친근한",
    "bright_active" => "밝고 활발한"
  }.freeze
  TONE_LABELS_REVERSE = TONE_LABELS.invert.freeze

  HONORIFIC_LABELS = {
    "formal" => "습니다 체",
    "semi" => "시 체",
    "casual" => "요 체"
  }.freeze
  HONORIFIC_LABELS_REVERSE = HONORIFIC_LABELS.invert.freeze

  SENTENCE_LENGTH_LABELS = {
    "short" => "짧게",
    "medium" => "보통",
    "long" => "길게"
  }.freeze
  SENTENCE_LENGTH_LABELS_REVERSE = SENTENCE_LENGTH_LABELS.invert.freeze

  def tone_label = TONE_LABELS[tone] || tone
  def honorific_label = HONORIFIC_LABELS[honorific] || honorific
  def sentence_length_label = SENTENCE_LENGTH_LABELS[sentence_length] || sentence_length

  validates :tone, inclusion: { in: %w[calm_professional warm_casual bright_active] }
  validates :honorific, inclusion: { in: %w[formal semi casual] }
  validates :approval_mode, inclusion: { in: %w[none owner_review staff_review] }

  STATUSES = %w[active paused archived].freeze

  def pause!; update!(status: "paused"); end
  def resume!; update!(status: "active"); end

  def snapshot_for_version
    {
      name: name, role_label: role_label, industry_expertise: industry_expertise,
      tone: tone, friendliness: friendliness, expertise_level: expertise_level,
      proactiveness: proactiveness, honorific: honorific, sentence_length: sentence_length,
      vocabulary_phrases_json: vocabulary_phrases_json,
      forbidden_phrases_json: forbidden_phrases_json,
      can_answer_topics_json: can_answer_topics_json,
      must_handoff_topics_json: must_handoff_topics_json,
      work_days_json: work_days_json, work_hours_json: work_hours_json,
      daily_post_quota: daily_post_quota, weekly_post_quota: weekly_post_quota,
      approval_mode: approval_mode, channel_behaviors_json: channel_behaviors_json,
      monthly_token_budget: monthly_token_budget, daily_token_budget: daily_token_budget,
      monthly_cost_budget_krw: monthly_cost_budget_krw, daily_cost_budget_krw: daily_cost_budget_krw,
      natural_language_instructions: natural_language_instructions,
      status: status,
    }
  end

  def work_days_list
    Array(work_days_json).map(&:to_s)
  end
end
