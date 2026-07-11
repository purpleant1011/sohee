class App::RuntimeConfigsController < App::BaseController
  before_action :load_config, only: [:show, :activate, :rollback, :destroy]

  def index
    @configs = @current_account.runtime_configs.recent.limit(30)
    @active = @current_account.runtime_configs.active.first
    @heartbeat_summary = RuntimeHeartbeat.summary_24h(@current_account)
    @latest_heartbeat = RuntimeHeartbeat.last_for(@current_account)
  end

  def show
    @heartbeat_summary = RuntimeHeartbeat.summary_24h(@current_account)
  end

  def new
    @snapshot = RuntimeConfig.snapshot_for(@current_account)
    @next_version = RuntimeConfig.next_version(@current_account)
  end

  def create
    snapshot = RuntimeConfig.snapshot_for(@current_account)
    bundle_json = snapshot.to_json
    cfg = RuntimeConfig.new(
      account: @current_account,
      version: RuntimeConfig.next_version(@current_account),
      status: "draft",
      bundle_json: snapshot,
      change_summary: params[:change_summary].to_s.strip.presence || "초안 생성"
    )
    cfg.compute_checksum!
    if cfg.save
      redirect_to app_runtime_config_path(cfg), notice: "런타임 설정 초안 (#{cfg.version})이 생성되었습니다."
    else
      redirect_to app_runtime_configs_path, alert: cfg.errors.full_messages.to_sentence
    end
  end

  def activate
    if @config.draft?
      @config.activate!(user: current_user)
      redirect_to app_runtime_configs_path, notice: "✅ #{@config.version} 활성화됨. 소희가 새 설정으로 동작합니다."
    else
      redirect_to app_runtime_config_path(@config), alert: "draft 상태에서만 활성화할 수 있습니다."
    end
  end

  def rollback
    if @config.active?
      reason = params[:reason].to_s.strip.presence || "운영팀 수동 롤백"
      @config.rollback!(user: current_user, reason: reason)
      redirect_to app_runtime_configs_path, notice: "⏪ #{@config.version} 롤백 처리 완료."
    else
      redirect_to app_runtime_config_path(@config), alert: "active 상태에서만 롤백할 수 있습니다."
    end
  end

  def destroy
    if %w[draft rolled_back archived].include?(@config.status)
      @config.destroy
      redirect_to app_runtime_configs_path, notice: "런타임 설정이 삭제되었습니다."
    else
      redirect_to app_runtime_config_path(@config), alert: "active 설정은 삭제할 수 없습니다. 먼저 롤백하세요."
    end
  end

  # 내부 ping — 스케줄러·운영팀·소희에서 호출
  def heartbeat
    source = params[:source].presence_in(RuntimeHeartbeat::SOURCES) || "sohee"
    status = params[:status].presence_in(RuntimeHeartbeat::STATUSES) || "ok"
    RuntimeHeartbeat.create!(
      account: @current_account,
      runtime_config: RuntimeConfig.current_for(@current_account),
      source: source,
      status: status,
      open_jobs: params[:open_jobs].to_i,
      failed_jobs_24h: params[:failed_jobs_24h].to_i,
      meta_json: { ua: request.user_agent.to_s[0, 60], note: params[:note].to_s[0, 120] },
      checked_at: Time.current
    )
    head :no_content
  end

  private

  def load_config
    @config = @current_account.runtime_configs.find(params[:id])
  end
end