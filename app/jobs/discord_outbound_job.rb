# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

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
    # Rails → 워커 송신 (DiscordOutboundJob → discord-gateway :7300/send)
    # 워커는 discord.js channel.send() 로 실제 메시지/카드 송신
    sender_url = ENV["DISCORD_GATEWAY_OUTBOUND_URL"].to_s.presence || "http://localhost:7300/send"
    token = ENV["DISCORD_GATEWAY_SERVICE_TOKEN"].to_s

    uri = URI.parse(sender_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 3
    http.read_timeout = 10
    req = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "X-Internal-Token" => token,
    })
    req.body = payload.to_json
    res = http.request(req)

    if res.is_a?(Net::HTTPSuccess)
      body = (JSON.parse(res.body) rescue {})
      AuditEvent.create!(
        actor_kind: "system",
        actor_label: "discord_outbound_job",
        action: "discord.outbound.sent",
        target: payload[:channel_id].to_s,
        metadata: payload.except(:content).merge(sent_message_id: body["message_id"], response: body)
      )
    else
      AuditEvent.create!(
        actor_kind: "system",
        actor_label: "discord_outbound_job",
        action: "discord.outbound.failed",
        target: payload[:channel_id].to_s,
        metadata: payload.except(:content).merge(http_status: res.code, body: res.body.to_s[0, 500])
      )
      Rails.logger.error("[DiscordOutboundJob] gateway returned #{res.code}: #{res.body.to_s[0, 200]}")
    end
  end
end