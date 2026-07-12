# frozen_string_literal: true

# ProcessDiscordEventJob — Discord 이벤트 수신 → 의미 분류 → 다음 단계 분기
# 분기:
#  - conversational → BusinessMemory 조회 → Gemini 응답 호출
#  - change_request  → ExtractChangeProposalJob (P2)
#  - inquiry         → Inquiry 분류 → CreateHandoffJob
#  - content_draft   → ContentWriter → ContentItem(draft)
class ProcessDiscordEventJob < DiscordNativeJob
  queue_as :high

  def perform(event_id)
    return unless FeatureFlags.enabled?(:discord_native_enabled)
    event = DiscordMessageEvent.find(event_id)
    return if event.processed?

    intent = classify_intent(event)
    event.mark_processed!(intent: intent)
    dispatch_next(event, intent)
  end

  private

  def classify_intent(event)
    return "system" if event.kind != "message_create"
    text = event.content_raw.to_s.strip
    return "conversational" if text.empty?

    # 단순 분류 (실제 분류는 Gemini가 함 — 여기서는 키워드 폴백)
    if text.match?(/(문의|예약|가격|시간|연락|도와주세요|문의드려요)/)
      "inquiry"
    elsif text.match?(/(바꿔|수정|업데이트|추가해|삭제해|변경|바꾸어|정책|룰)/)
      "change_request"
    elsif text.match?(/(글|포스트|콘텐츠|작성|초안|카드|뉴스)/)
      "content_draft"
    else
      "conversational"
    end
  end

  def dispatch_next(event, intent)
    case intent
    when "conversational"
      GenerateDiscordReplyJob.perform_later(event.id)
    when "change_request"
      ExtractChangeProposalJob.perform_later(event.id)
    when "inquiry"
      GenerateDiscordReplyJob.perform_later(event.id) # 분류 결과 + 응답 동시
    when "content_draft"
      GenerateDiscordReplyJob.perform_later(event.id)
    end
  end
end