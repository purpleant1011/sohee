class App::BaseController < ApplicationController
  layout "app"
  before_action :require_business_sign_in!
  before_action :load_account_context
  before_action :load_setup_readiness

  private

  def load_account_context
    @current_account = current_account
    @current_business_profile = @current_account.business_profile || @current_account.build_business_profile
    @current_ai_employees = @current_account.ai_employees
    redirect_to new_user_session_path and return unless @current_account
  end

  # 셋업 준비도 — 정식 계정 전환 전 체크리스트
  # 사업장 프로필 / RAG / 페르소나 / 채널 / FAQ / 인계 규칙 / 검수 합격
  def load_setup_readiness
    return unless @current_account

    checks = []
    bp = @current_business_profile
    bp_ok = bp.persisted? &&
            bp.brand_intro.to_s.length > 10 &&
            bp.forbidden_phrases_json.to_s.length > 5 &&
            bp.operator_managed
    checks << ["사업장 프로필 (브랜드 톤 + 금지어 + 운영사 관리)", bp_ok]

    rag_count = @current_account.knowledge_sources.where(status: "ready").count
    checks << ["지식베이스 / RAG (정식 소스 #{rag_count}건)", rag_count >= 3]

    persona_ok = @current_ai_employees.where(status: "active").any? do |emp|
      emp.persona_preset.present? && emp.natural_language_instructions.to_s.length > 50
    end
    checks << ["페르소나 설정 (sohee_basic/cafe/salon/expert)", persona_ok]

    channel_ok = @current_account.channel_connections.where(status: "connected").count >= 1
    checks << ["채널 연결 (테스트 계정 ≥ 1)", channel_ok]

    faq_count = @current_account.faqs.where(active: true).count
    checks << ["FAQ 활성 (#{faq_count}개)", faq_count >= 3]

    handoff_ok = bp.escalation_rules_json.to_s.length > 5
    checks << ["원장님 인계 규칙 (escalation_rules)", handoff_ok]

    review_ok = @current_account.content_items.where(state: "approved").count >= 5
    checks << ["원장님 검수 합격 (5건 이상)", review_ok]

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
