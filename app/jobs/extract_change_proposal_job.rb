# frozen_string_literal: true

# ExtractChangeProposalJob — Discord 메시지에서 영구 변경 후보 추출
# 원칙 9: 영구 변경은 제안으로 끝남 — 실제 적용은 사람 승인 후
class ExtractChangeProposalJob < DiscordNativeJob
  queue_as :default

  def perform(event_id)
    return unless FeatureFlags.enabled?(:discord_native_enabled)
    event = DiscordMessageEvent.find(event_id)
    business = event.business_profile
    ai_employee = business&.ai_employees&.first
    return unless business && ai_employee

    proposal = extract_proposal(event, business, ai_employee)
    return unless proposal

    proposal.save!

    # Discord 승인 카드 송신
    DiscordOutboundJob.perform_later(
      business.id,
      event.channel_id,
      nil, # content는 interaction 카드에 포함
      change_proposal_id: proposal.id
    )
  end

  private

  def extract_proposal(event, business, ai_employee)
    ChangeProposal.new(
      business_profile_id: business.id,
      discord_message_event_id: event.id,
      ai_employee_id: ai_employee.id,
      target_kind: detect_target_kind(event.content_raw.to_s),
      target_field: detect_target_field(event.content_raw.to_s),
      proposed_payload: { raw_change_request: event.content_raw },
      previous_payload: {},
      reason: "Discord 메시지에서 자동 추출 — 사람이 검토 필요",
      user_quote: event.content_raw.to_s.truncate(200),
      status: "pending"
    )
  end

  def detect_target_kind(text)
    case text
    when /(영업시간|운영시간)/ then "business_profile"
    when /(자동화|룰|규칙|트리거)/ then "automation_rule"
    when /(FAQ|자주|질문)/ then "faq"
    when /(학습|지식|문서)/ then "knowledge_source"
    when /(페르소나|말투|톤)/ then "runtime_config"
    else "runtime_config"
    end
  end

  def detect_target_field(text)
    text[/([가-힣A-Za-z_]+)(을|를)\s*(바꿔|수정|업데이트|변경)/, 1] || "unspecified"
  end
end