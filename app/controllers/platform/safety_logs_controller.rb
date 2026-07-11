# frozen_string_literal: true
module Platform
  # 운영자 콘솔에서 전체 사업장 안전 로그를 조회한다 (P0-4).
  class SafetyLogsController < BaseController
    def index
      @filter = params[:filter].presence_in(%w[all blocked passed needs_review]) || "all"
      scope = SafetyLog.includes(:account).order(created_at: :desc)
      scope = scope.where(verdict: @filter) unless @filter == "all"
      @safety_logs = scope.limit(200)
      @stats = {
        blocked_7d:      SafetyLog.where(verdict: "blocked").where("created_at >= ?", 7.days.ago).count,
        needs_review_7d: SafetyLog.where(verdict: "needs_review").where("created_at >= ?", 7.days.ago).count,
        passed_7d:       SafetyLog.where(verdict: "passed").where("created_at >= ?", 7.days.ago).count
      }
    end

    def show
      @safety_log = SafetyLog.includes(:account).find(params[:id])
    end
  end
end