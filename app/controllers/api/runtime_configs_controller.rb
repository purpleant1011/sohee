class Api::RuntimeConfigsController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_token!
  before_action :load_account

  # GET /api/runtime_configs/current — 활성 bundle + 최근 heartbeat
  def current
    cfg = RuntimeConfig.current_for(@account)
    hb = RuntimeHeartbeat.last_for(@account)
    render json: {
      ok: true,
      account: { id: @account.id, slug: @account.slug, name: @account.name },
      active_config: cfg ? {
        id: cfg.id,
        version: cfg.version,
        status: cfg.status,
        checksum: cfg.checksum,
        activated_at: cfg.activated_at,
        bundle: cfg.bundle_json
      } : nil,
      last_heartbeat: hb ? {
        source: hb.source,
        status: hb.status,
        open_jobs: hb.open_jobs,
        failed_jobs_24h: hb.failed_jobs_24h,
        checked_at: hb.checked_at
      } : nil,
      summary_24h: RuntimeHeartbeat.summary_24h(@account)
    }
  end

  # POST /api/runtime_configs — draft 생성
  def create
    snapshot = RuntimeConfig.snapshot_for(@account)
    cfg = RuntimeConfig.new(
      account: @account,
      version: RuntimeConfig.next_version(@account),
      status: "draft",
      bundle_json: snapshot,
      change_summary: params[:change_summary].to_s.strip.presence || "API 자동 초안"
    )
    cfg.compute_checksum!
    if cfg.save
      render json: { ok: true, id: cfg.id, version: cfg.version, checksum: cfg.checksum }, status: :created
    else
      render json: { ok: false, errors: cfg.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/runtime_configs/:id/activate
  def activate
    cfg = @account.runtime_configs.find(params[:id])
    if cfg.draft?
      cfg.activate!(user: nil)
      render json: { ok: true, version: cfg.version, status: cfg.status }
    else
      render json: { ok: false, error: "draft 상태에서만 활성화 가능" }, status: :unprocessable_entity
    end
  end

  # POST /api/runtime_configs/:id/rollback
  def rollback
    cfg = @account.runtime_configs.find(params[:id])
    if cfg.active?
      reason = params[:reason].to_s.strip.presence || "API 자동 롤백"
      cfg.rollback!(user: nil, reason: reason)
      render json: { ok: true, version: cfg.version, status: cfg.status }
    else
      render json: { ok: false, error: "active 상태에서만 롤백 가능" }, status: :unprocessable_entity
    end
  end

  # POST /api/runtime_configs/heartbeat
  def heartbeat
    source = params[:source].presence_in(RuntimeHeartbeat::SOURCES) || "sohee"
    status = params[:status].presence_in(RuntimeHeartbeat::STATUSES) || "ok"
    hb = RuntimeHeartbeat.create!(
      account: @account,
      runtime_config: RuntimeConfig.current_for(@account),
      source: source,
      status: status,
      open_jobs: params[:open_jobs].to_i,
      failed_jobs_24h: params[:failed_jobs_24h].to_i,
      meta_json: { note: params[:note].to_s[0, 120] },
      checked_at: Time.current
    )
    render json: { ok: true, id: hb.id, checked_at: hb.checked_at }
  end

  private

  def authenticate_token!
    authenticate_or_request_with_http_token do |token, options|
      @raw_token = token
      true
    end
  end

  def load_account
    # X-Account-Slug 헤더 우선, 없으면 쿼리 파라미터
    slug = request.headers["X-Account-Slug"].presence || params[:account_slug].to_s
    @account = Account.find_by(slug: slug)
    unless @account
      render json: { ok: false, error: "account not found" }, status: :not_found
    end
  end
end