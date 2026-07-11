# frozen_string_literal: true
module App
  class SafetyLogsController < App::BaseController
    def index
      @filter = params[:filter].presence_in(%w[all blocked passed needs_review]) || "all"
      scope = @current_account.safety_logs.order(created_at: :desc)
      scope = scope.where(verdict: @filter) unless @filter == "all"
      @safety_logs = scope.limit(100)
      @stats = {
        blocked_7d:     @current_account.safety_logs.where(verdict: "blocked").where("created_at >= ?", 7.days.ago).count,
        needs_review_7d: @current_account.safety_logs.where(verdict: "needs_review").where("created_at >= ?", 7.days.ago).count,
        passed_7d:       @current_account.safety_logs.where(verdict: "passed").where("created_at >= ?", 7.days.ago).count
      }
    end
  end
end