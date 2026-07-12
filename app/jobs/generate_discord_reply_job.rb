# frozen_string_literal: true

# GenerateDiscordReplyJob — Gemini 호출 → 응답 → Outbound 큐잉
# 원칙: Discord 응답은 항상 OutboundJob을 통해 비동기 송신 (메인 스레드 블로킹 안 함)
class GenerateDiscordReplyJob < DiscordNativeJob
  queue_as :default

  def perform(event_id)
    return unless FeatureFlags.enabled?(:discord_native_enabled)
    event = DiscordMessageEvent.find(event_id)
    business = event.business_profile
    return unless business

    # BusinessMemory recall
    memories = BusinessMemory.recall(business_profile: business, limit: 5)

    # Gemini 워커 호출 (HTTP)
    response = call_gemini_worker(event: event, memories: memories)

    # 결과를 Discord로 송신
    DiscordOutboundJob.perform_later(
      business.id,
      event.channel_id,
      response[:text],
      reply_to_snowflake_id: event.snowflake_id,
      metadata: response[:metadata]
    )
  end

  private

  def call_gemini_worker(event:, memories:)
    base = ENV["RAILS_INTERNAL_API_BASE"].presence || "http://localhost:3000"
    # 실제 워커는 별도 프로세스 — 우리는 결과를 받는 측이므로 워커가 직접 호출
    # 여기서는 워커가 결과를 /api/v1/gemini/call에 보고한다고 가정하고 stub 응답
    {
      text: "(stub) 메모리 #{memories.size}개 반영해 답변합니다. 원문: #{event.safe_content}",
      metadata: { intent: event.intent, memory_ids: memories.map(&:id) }
    }
  end
end