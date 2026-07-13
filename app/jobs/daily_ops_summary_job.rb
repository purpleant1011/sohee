# frozen_string_literal: true

# DailyOpsSummaryJob — 모든 사업장에 일일 운영 요약을 운영 Discord 채널로 발송.
# §13: 매일 23:00 KST (14:00 UTC) 에 cron 실행.
class DailyOpsSummaryJob < ApplicationJob
  queue_as :default

  def perform
    BusinessProfile.find_each do |bp|
      OpsNotifier.daily_summary(bp)
    rescue StandardError => e
      Rails.logger.warn("[DailyOpsSummaryJob] bp=#{bp.id} failed: #{e.message}")
      next
    end
    Rails.logger.info("[DailyOpsSummaryJob] done for #{BusinessProfile.count} profiles")
  end
end