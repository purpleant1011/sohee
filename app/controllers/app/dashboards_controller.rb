class App::DashboardsController < App::BaseController
  def show
    @range = params[:range].presence_in(%w[7d 30d 90d]) || "7d"
    @days = { "7d" => 7, "30d" => 30, "90d" => 90 }[@range]
    @since = @days.days.ago.beginning_of_day
    @metrics = BusinessMetrics.call(account: @current_account, since: @since)
    @recent_automations = @current_account.automation_executions.where("created_at >= ?", @since).order(created_at: :desc).limit(8)
    @pending_contents   = @current_account.content_items.where(state: "pending_review").order(created_at: :desc).limit(5)
    @channel_breakdown  = @current_account.publication_attempts.where("created_at >= ?", @since).group(:channel_connection_id).count
    @announcements = Announcement.for_account(@current_account).recent.limit(5)
    @internal_info = build_internal_info

    # ── 소희 운영 대시보드 — 바이름형 운영 데이터 ──
    @sohei = @current_account.ai_employees.where(status: "active").first
    load_sohei_dashboard
  end

  private

  # 소희 운영 대시보드용 핵심 지표 (바이름 데모용 — 운영형 서비스 표준)
  def load_sohei_dashboard
    today_start = Time.current.beginning_of_day
    week_start = 7.days.ago.beginning_of_day

    @today = {
      contents_generated: @current_account.content_items.where("created_at >= ?", today_start).count,
      contents_scheduled: @current_account.content_items.where(state: "scheduled", scheduled_at: today_start.all_day).count,
      conversations_handled: @current_account.conversations.where("created_at >= ?", today_start).where(risk_level: "low").count,
      inquiries_basics_answered: @current_account.conversations.where(state: "closed", risk_level: "low").where("updated_at >= ?", today_start).count,
      handoffs_open: @current_account.handoffs.where(state: "open").count,
      automations_failed: @current_account.automation_executions.where(state: "failed").where("created_at >= ?", today_start).count
    }

    @week = {
      contents_generated: @current_account.content_items.where("created_at >= ?", week_start).count,
      contents_published: @current_account.content_items.where("published_at >= ?", week_start).count,
      conversations_total: @current_account.conversations.where("created_at >= ?", week_start).count,
      handoffs_resolved: @current_account.handoffs.where(state: "resolved").where("resolved_at >= ?", week_start).count
    }

    # 원장님 확인 필요 (상단 노출)
    @handoffs_pending = @current_account.handoffs.where(state: "open").order(created_at: :desc).limit(10)

    # 오늘 자동화 루틴 (예정된 schedule)
    @upcoming_routines = AutomationSchedule.where(account_id: @current_account.id)
                                          .where("next_run_at > ?", Time.current)
                                          .where("next_run_at < ?", 24.hours.from_now)
                                          .order(:next_run_at)
                                          .limit(10)

    # 오늘 일일 보고 (DeliveryLog)
    @daily_report = @current_account.delivery_logs.where(kind: "daily_report").order(created_at: :desc).first

    # 자동화 실패/주의
    @automations_needs_attention = @current_account.automation_executions.where(state: "failed").where("created_at >= ?", 7.days.ago).limit(5)

    # 초기 파트너 매장 demo 분기
    @is_byreum = @current_account.slug == "byreum-cheongna"
  end

  def build_internal_info
    {
      api_endpoints: {
        backend: ENV.fetch("PUBLIC_HOST", "127.0.0.1:3001"),
        local: "http://127.0.0.1:3001",
        tunnel: ENV["TUNNEL_URL"]
      }.compact,
      demo_accounts: {
        initial_partner: "partner@soheeproject.example",
        demo_skin: "owner@demo.example",
        demo_cafe: "cafe-owner@demo.example",
        demo_shop: "shop-owner@demo.example"
      },
      stack: "Rails 8 + Hotwire + Tailwind v3 + PG 16 + Solid Queue/Cable + ActiveStorage + Sentry",
      e2e_tests: "Playwright 16/16 PASS"
    }
  end
end