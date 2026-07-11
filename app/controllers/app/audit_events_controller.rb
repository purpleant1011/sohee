# frozen_string_literal: true
module App
  class AuditEventsController < App::BaseController
    def index
      @events = @current_account.audit_events.order(created_at: :desc).limit(200)
      @stats = {
        today:    @current_account.audit_events.where("created_at >= ?", Time.current.beginning_of_day).count,
        week:     @current_account.audit_events.where("created_at >= ?", 7.days.ago).count,
        total:    @current_account.audit_events.count,
        operator: @current_account.audit_events.where(actor_kind: "operator").count,
        system:   @current_account.audit_events.where(actor_kind: "system").count
      }
      @actor_kinds = @current_account.audit_events.distinct.pluck(:actor_kind).compact
    end
  end
end