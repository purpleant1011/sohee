class App::BaseController < ApplicationController
  layout "app"
  before_action :require_business_sign_in!
  before_action :load_account_context
  before_action :load_setup_readiness
  before_action :enforce_trial_status!, unless: :skip_trial_check?

  private

  def skip_trial_check?
    # 플랜 페이지, 결제/구독 관련 페이지는 만료된 트라이얼도 접근 가능
    false # 추후 skip_controller로 확장
  end

  # 트라이얼 만료 체크 (lazy) — 만료 시 정식 플랜 안내 페이지로 리다이렉트.
  # 2026-07-12 리뉴얼: 셀프 가입 폐쇄로 trial_ends_at은 운영팀이 신규 고객사 등록 시점에 명시적으로 부여/해제한다.
  def enforce_trial_status!
    return unless @current_account
    return unless @current_account.trial_expired?
    redirect_to app_plans_path, alert: "도입 체험 기간이 종료되었습니다. 운영팀과 정식 운영 플랜을 협의해 주세요."
  end

  def load_account_context
    @current_account = current_account
    @current_business_profile = @current_account.business_profile || @current_account.build_business_profile
    @current_ai_employees = @current_account.ai_employees
    redirect_to new_user_session_path and return unless @current_account
  end

  # 셋업 준비도 — 정식 계정 전환 전 체크리스트 (사업자 친화 라벨)
  # 운영팀이 신규 고객사 등록 후 셋업이 끝나면 모두 ✅가 된다.
  def load_setup_readiness
    return unless @current_account

    checks = []
    bp = @current_business_profile
    bp_ok = bp.persisted? &&
            bp.brand_intro.to_s.length > 10 &&
            bp.forbidden_phrases_json.to_s.length > 5 &&
            bp.operator_managed
    checks << ["매장 소개글과 운영 규칙이 등록되어 있나요", bp_ok]

    rag_count = @current_account.knowledge_sources.where(status: "ready").count
    checks << ["매장 안내 자료가 충분히 등록되어 있나요 (현재 #{rag_count}건)", rag_count >= 3]

    persona_ok = @current_ai_employees.where(status: "active").any? do |emp|
      emp.persona_preset.present? && emp.natural_language_instructions.to_s.length > 50
    end
    checks << ["AI 직원 말투와 역할이 설정되어 있나요", persona_ok]

    channel_ok = @current_account.channel_connections.where(status: "connected").count >= 1
    checks << ["답변 채널 1개 이상이 연결되어 있나요", channel_ok]

    faq_count = @current_account.faqs.where(active: true).count
    checks << ["자주 받는 질문(FAQ)이 등록되어 있나요 (현재 #{faq_count}개)", faq_count >= 3]

    handoff_ok = bp.escalation_rules_json.to_s.length > 5
    checks << ["원장님께 인계해야 할 상황 기준이 정해져 있나요", handoff_ok]

    review_ok = @current_account.content_items.where(state: "approved").count >= 5
    checks << ["검수를 통과한 글이 5건 이상 모였나요", review_ok]

    total = checks.size
    passed = checks.count { |_, ok| ok }
    missing = checks.reject { |_, ok| ok }.map(&:first)
    percent = (passed * 100 / total)

    @setup_readiness = {
      percent: percent,
      ready: passed == total,
      total: total,
      passed: passed,
      missing: missing,
      checks: checks
    }
  end

  def render_business_forbidden
    render plain: "권한이 없습니다", status: :forbidden
  end

  def require_owner_or_admin!
    return if @current_account && current_user&.account_id == @current_account.id
    render_business_forbidden
  end

  def require_owner_or_manager!
    return if @current_account && current_user&.account_id == @current_account.id
    render_business_forbidden
  end
end
