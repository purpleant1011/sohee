# frozen_string_literal: true

# P3-1 (2026-07-13): Integration Hub — 자동/수동 게시 이력 (사업자 포털)
class App::PublicationAttemptsController < App::BaseController
  TAB_RECENT = "recent"
  TAB_FAILED = "failed"
  ALL_TABS   = [TAB_RECENT, TAB_FAILED].freeze

  def index
    @tab = ALL_TABS.include?(params[:tab]) ? params[:tab] : TAB_RECENT
    base = PublicationAttempt.where(account_id: @current_account.id)
    @attempts = case @tab
                when TAB_FAILED then base.where(state: "failed").order(created_at: :desc).limit(50)
                else                 base.order(created_at: :desc).limit(50)
                end
    @counts = {
      total:   base.count,
      succeeded: base.where(state: "succeeded").count,
      failed:  base.where(state: "failed").count,
      pending: base.where(state: "pending").count
    }
    @last_success = base.where(state: "succeeded").maximum(:created_at)
    @last_failure = base.where(state: "failed").maximum(:created_at)
  end
end