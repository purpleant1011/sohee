# frozen_string_literal: true

# Api::V1::BaseController — Discord-Native 워커 → Rails 내부 API
# 원칙: 워커만 호출 가능, 외부 인터넷 노출 안 됨 (curl/health만 예외)
# 인증: DISCORD_GATEWAY_SERVICE_TOKEN (Gateway), HERMES_MCP_TOKEN (Hermes)
class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_internal_token!
  before_action :require_feature_flag!

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from FeatureFlags::DisabledError, with: :render_forbidden

  private

  def require_internal_token!
    expected = request_internal_token
    provided = request.headers["X-Internal-Token"].to_s
    unless ActiveSupport::SecurityUtils.secure_compare(expected, provided) && expected.present?
      render json: { error: "invalid_internal_token" }, status: :unauthorized
    end
  end

  def require_feature_flag!
    return if FeatureFlags.enabled?(:discord_native_enabled)
    render json: { error: "discord_native_disabled", flag: "discord_native_enabled" }, status: :forbidden
  end

  def request_internal_token
    # 컨트롤러별로 다른 토큰 사용 (Gateway vs Hermes)
    case controller_name
    when "invokes", "runtime_syncs"
      ENV["HERMES_MCP_TOKEN"].to_s
    else
      ENV["DISCORD_GATEWAY_SERVICE_TOKEN"].to_s
    end
  end

  def render_not_found(error)
    render json: { error: "not_found", message: error.message }, status: :not_found
  end

  def render_bad_request(error)
    render json: { error: "bad_request", message: error.message }, status: :bad_request
  end

  def render_forbidden(error)
    render json: { error: "forbidden", message: error.message }, status: :forbidden
  end
end