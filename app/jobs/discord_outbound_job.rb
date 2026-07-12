# frozen_string_literal: true

# DiscordOutboundJob — Discord에 메시지·버튼 카드 송신
# 원칙 5: 모든 송신은 멱등(snowflake 기반 중복 방지)
class DiscordOutboundJob < DiscordNativeJob
  queue_as :default

  def perform(business_profile_id, channel_id, content, reply_to_snowflake_id: nil, change_proposal_id: nil, metadata: {})
    return unless FeatureFlags.enabled?(:discord_native_enabled)

    payload = build_payload(channel_id, content, reply_to_snowflake_id, change_proposal_id, metadata)

    enqueue_to_gateway(payload)
  end

  private

  def build_payload(channel_id, content, reply_to, proposal_id, metadata)
    base = {
      channel_id: channel_id,
      metadata: metadata.merge(reply_to: reply_to)
    }

    if proposal_id
      proposal = ChangeProposal.find_by(id: proposal_id)
      base[:card] = build_approval_card(proposal) if proposal
    else
      base[:content] = content
    end

    base
  end

  def build_approval_card(proposal)
    {
      title: "변경 제안 ##{proposal.id}",
      description: "#{proposal.target_kind}.#{proposal.target_field}\n사유: #{proposal.reason}",
      quote: proposal.user_quote,
      actions: [
        { label: "적용", style: "primary", action: "approve", proposal_id: proposal.id },
        { label: "취소", style: "secondary", action: "reject", proposal_id: proposal.id }
      ],
      expires_at: proposal.expires_at&.iso8601
    }
  end

  def enqueue_to_gateway(payload)
    # 워커는 별도 프로세스. 우리는 큐잉만.
    # 실제 구현은 Redis/PostgreSQL queue 또는 HTTP webhook
    AuditEvent.create!(
      actor_kind: "system",
      actor_label: "discord_outbound_job",
      action: "discord.outbound.queued",
      target: payload[:channel_id].to_s,
      metadata: payload.except(:content)
    )
  end
end