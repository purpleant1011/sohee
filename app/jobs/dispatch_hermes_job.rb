# frozen_string_literal: true

# DispatchHermesJob — RuntimeSync 레코드 생성 후 워커로 송신 큐잉
# 원칙 11: Hermes 장애가 Rails 손상 안 시킴 — 큐잉 후 워커가 가져감
class DispatchHermesJob < DiscordNativeJob
  queue_as :default

  def perform(business_profile_id, topic, payload)
    return unless FeatureFlags.enabled?(:discord_native_enabled)

    sync = RuntimeSync.create!(
      business_profile_id: business_profile_id,
      direction: "rails_to_hermes",
      topic: topic,
      agent_id: "sohee-control-mcp",
      payload: payload,
      idempotency_key: "rails.#{topic}.#{business_profile_id}.#{SecureRandom.uuid}",
      status: "pending"
    )

    # 실제 송신은 워커가 큐를 poll — 우리는 큐잉만
    sync
  end
end