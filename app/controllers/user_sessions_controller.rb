class UserSessionsController < ApplicationController
  # Rate limiting: 로그인 시도 5회/분 (브루트포스 방어)
  rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }, with: -> { render_rate_limited }

  def new
    @account_or_email = params[:account_or_email].to_s
  end

  def create
    raw = params.require(:account_or_email).to_s.strip
    password = params.require(:password).to_s

    # 1) 슬러그 또는 이메일로 먼저 user를 찾는다 (이메일이 더 직접적)
    user = User.find_by(email_address: raw)
    # 2) 슬러그로 찾으면, 그 account의 owner를 찾는다
    user ||= Account.find_by(slug: raw)&.owner_user
    # 3) 그래도 안 되면, 해당 account의 role="owner" user 또는 첫 번째 user를 fallback
    if user.nil? && (acct_fb = Account.find_by(slug: raw))
      user = acct_fb.users.find_by(role: "owner") || acct_fb.users.first
    end

    account = user&.account
    if user&.authenticate(password)
      start_user_session!(user)
      redirect_to app_root_path, notice: "로그인되었습니다."
    else
      AuditEvent.create!(
        account: account,
        action: "session.login_failed",
        resource_type: "User",
        resource_id: user&.id || 0,
        metadata: { ip: request.remote_ip, ua: request.user_agent.to_s[0, 100], account_or_email: raw[0, 100] },
        occurred_at: Time.current
      )
      flash.now[:alert] = "계정/이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unauthorized
    end
  end

  def destroy
    close_session!
    redirect_to public_root_path, notice: "로그아웃되었습니다."
  end

  private

  def render_rate_limited
    response.headers["Retry-After"] = "60"
    render plain: "요청이 너무 많습니다. 잠시 후 다시 시도해주세요.", status: :too_many_requests
  end

  def start_user_session!(user)
    token = SecureRandom.hex(32)
    Session.create!(user: user, token_hash: token, ip_address: request.remote_ip, user_agent: request.user_agent.to_s[0, 200], last_seen_at: Time.current, expires_at: 30.days.from_now)
    cookies.signed[:workmori_user_token] = { value: token, httponly: true, expires: 30.days.from_now, same_site: :lax }
    AuditEvent.create!(account: user.account, actor_kind: "user", action: "session.start", resource_type: "User", resource_id: user.id, occurred_at: Time.current)
  end

  def close_session!
    if (s = user_session)
      s.update!(revoked_at: Time.current)
    end
    cookies.delete(:workmori_user_token)
  end
end
