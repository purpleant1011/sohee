# frozen_string_literal: true

# P3-1 (2026-07-13): Integration Hub — 자동 게시 규칙 카드 (사업자 포털)
class App::AutomationRulesController < App::BaseController
  TAB_ACTIVE  = "active"
  TAB_PENDING = "pending"
  TAB_DRAFT   = "draft"
  TAB_PAUSED  = "paused"
  ALL_TABS    = [TAB_ACTIVE, TAB_PENDING, TAB_DRAFT, TAB_PAUSED].freeze

  def index
    @tab = ALL_TABS.include?(params[:tab]) ? params[:tab] : TAB_ACTIVE
    base = AutomationRule.where(account_id: @current_account.id).order(created_at: :desc)
    @rules = case @tab
             when TAB_PENDING then base.where(status: "draft")
             when TAB_DRAFT   then base.where(status: "draft")
             when TAB_PAUSED  then base.where(status: "paused")
             else                  base.where(status: "active")
             end.limit(50)
    @counts = {
      active:  base.where(status: "active").count,
      pending: base.where(status: "draft").count,
      draft:   base.where(status: "draft").count,
      paused:  base.where(status: "paused").count
    }
  end

  def show
    @rule = AutomationRule.where(account_id: @current_account.id).find(params[:id])
    @schedule = @rule.automation_schedules.first
    @recent_executions = @rule.automation_executions.order(created_at: :desc).limit(10)
  end

  def approve
    @rule = AutomationRule.where(account_id: @current_account.id).find(params[:id])
    actor = respond_to?(:current_user) ? current_user : nil
    if @rule.status == "draft"
      @rule.update!(
        status: "active",
        approved_by_user_id: actor&.id,
        approved_at: Time.current,
        approval_notes: "원장님 승인 (사업자 포털, #{Time.current.strftime('%Y-%m-%d %H:%M')})"
      )
      OpsNotifier.change_proposal_created(@rule) rescue nil
      redirect_to app_automation_rule_v2_path(@rule), notice: "자동 게시 규칙을 승인했습니다. 다음 예정 시간부터 실행됩니다."
    else
      redirect_to app_automation_rule_v2_path(@rule), alert: "이미 처리된 규칙입니다."
    end
  end

  def pause
    @rule = AutomationRule.where(account_id: @current_account.id).find(params[:id])
    @rule.update!(status: "paused") if @rule.status == "active"
    redirect_to app_automation_rules_v2_path, notice: "일시중지했습니다."
  end

  def resume
    @rule = AutomationRule.where(account_id: @current_account.id).find(params[:id])
    @rule.update!(status: "active") if @rule.status == "paused"
    redirect_to app_automation_rules_v2_path, notice: "재개했습니다."
  end
end