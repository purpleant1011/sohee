# frozen_string_literal: true

# ReconcileDiscordMessagesJob — 주기적 정합성 (워커 ↔ Rails)
# 원칙 11: 워커가 다운돼도 복구 가능
class ReconcileDiscordMessagesJob < DiscordNativeJob
  queue_as :low

  def perform
    return unless FeatureFlags.enabled?(:discord_native_enabled)

    # 1. 처리 안 된 이벤트 재처리
    DiscordMessageEvent.unprocessed.where("created_at > ?", 1.hour.ago).find_each do |event|
      next if event.processed?
      ProcessDiscordEventJob.perform_later(event.id)
    end

    # 2. 만료된 ChangeProposal 정리
    ChangeProposal.where(status: "pending").where("expires_at <= ?", Time.current).find_each do |p|
      p.update!(status: "expired")
    end

    # 3. RuntimeSync 재시도 큐
    RuntimeSync.ready_for_retry.where("next_retry_at <= ?", Time.current).find_each do |sync|
      if sync.exhausted?
        sync.update!(status: "timeout")
      else
        sync.schedule_retry!(backoff: [2 ** sync.attempts, 600].min)
      end
    end

    AuditEvent.create!(
      actor_kind: "system",
      actor_label: "reconcile_discord_messages_job",
      action: "reconcile.completed",
      target: "discord_native",
      metadata: { ran_at: Time.current.iso8601 }
    )
  end
end