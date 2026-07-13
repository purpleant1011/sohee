# frozen_string_literal: true

# OpsNotifier — 운영팀 Discord 채널 알림
# §13: 운영팀은 사업장 상태 변화 (handoff / 채널 실패 / ChangeProposal 결정 / 일일 요약) 를
#       단일 채널에서 실시간으로 받아야 한다.
#
# 운영 채널 = .env의 DISCORD_OPS_CHANNEL_ID (없으면 DISCORD_CHANNEL_ID fallback)
# 사업장별 X 표시, intent = 운영 요약.
class OpsNotifier
  # 알림 종류 (확장 가능)
  KIND_HANDOFF     = "handoff_created"        # 원장님 답변 필요 (state=open)
  KIND_CHANGE      = "change_proposal"        # 자동 수정 제안 (DB Diff)
  KIND_CHANGE_DONE = "change_proposal_decided" # 승인 / 거부 결정
  KIND_CHANNEL_ERR = "channel_failure"        # 채널 연결 실패 / 24h 내 N회 실패
  KIND_DAILY       = "daily_summary"          # 일일 운영 요약

  class << self
    # 운영 채널 ID (env 우선순위)
    def ops_channel_id
      ENV["DISCORD_OPS_CHANNEL_ID"].presence || ENV["DISCORD_CHANNEL_ID"].presence
    end

    # 발송 (실패해도 사업자 흐름은 중단 안 됨 — 운영 가시화는 부가 가치)
    def notify(kind, business_profile_id, body, metadata: {})
      channel_id = ops_channel_id
      return false if channel_id.blank?

      # 기존 DiscordOutboundJob 와 동일 큐 + 동일한 env 게이트 사용
      DiscordOutboundJob.perform_later(business_profile_id, channel_id, body, metadata: metadata.merge(kind: kind, source: "ops_notifier"))
      Rails.logger.info("[OpsNotifier] #{kind} enqueued bp=#{business_profile_id} channel=#{channel_id}")
      true
    rescue StandardError => e
      Rails.logger.warn("[OpsNotifier] #{kind} failed: #{e.message}")
      false
    end

    # ── 편의 메서드 ──
    def handoff_created(handoff)
      bp_name = handoff.business_profile&.trade_name.presence || handoff.business_profile&.legal_name.presence || "BP##{handoff.business_profile_id}"
      body = "🚨 *원장님 답변 필요*\n" \
             "사장님: `#{bp_name}`\n" \
             "이유: `#{handoff.reason}`\n" \
             "요약: #{handoff.summary.to_s.truncate(200)}\n" \
             "채널: `#{handoff.channel}`\n" \
             "→ https://blast-twins-finish-polyphonic.trycloudflare.com/app/handoffs/#{handoff.id}"
      notify(KIND_HANDOFF, handoff.business_profile_id, body, metadata: { handoff_id: handoff.id })
    end

    def change_proposal_created(proposal)
      bp_name = proposal.business_profile&.trade_name.presence || proposal.business_profile&.legal_name.presence || "BP##{proposal.business_profile_id}"
      body = "📝 *자동 수정 제안*\n" \
             "사장님: `#{bp_name}`\n" \
             "대상: `#{proposal.target_kind}.#{proposal.target_field}`\n" \
             "이유: #{proposal.reason.to_s.truncate(150)}\n" \
             "→ #{Rails.application.routes.url_helpers.app_change_proposals_url(host: 'blast-twins-finish-polyphonic.trycloudflare.com')}"
      notify(KIND_CHANGE, proposal.business_profile_id, body, metadata: { change_proposal_id: proposal.id })
    end

    def automation_rule_created(rule)
      bp_name = rule.account&.business_profile&.trade_name.presence || rule.account&.business_profile&.legal_name.presence || "BP##{rule.account_id}"
      body = "🤖 *자동 게시 규칙 승인 요청*\n" \
             "사장님: `#{bp_name}`\n" \
             "규칙: #{rule.name}\n" \
             "의도: #{rule.intent_kind}\n" \
             "→ #{Rails.application.routes.url_helpers.app_automation_rules_v2_url(host: 'blast-twins-finish-polyphonic.trycloudflare.com')}"
      notify(KIND_CHANGE, rule.account_id, body, metadata: { automation_rule_id: rule.id })
    end

    def change_proposal_decided(proposal)
      emoji = proposal.status == "approved" ? "✅" : "❌"
      bp_name = proposal.business_profile&.trade_name.presence || proposal.business_profile&.legal_name.presence || "BP##{proposal.business_profile_id}"
      body = "#{emoji} *수정 제안 결정*\n" \
             "사장님: `#{bp_name}`\n" \
             "대상: `#{proposal.target_kind}.#{proposal.target_field}`\n" \
             "결과: `#{proposal.status}`"
      notify(KIND_CHANGE_DONE, proposal.business_profile_id, body, metadata: { change_proposal_id: proposal.id, status: proposal.status })
    end

    def channel_failure(channel_connection, error_message)
      bp = channel_connection.account.business_profile rescue nil
      bp_name = bp&.trade_name.presence || bp&.legal_name.presence || "AC##{channel_connection.account_id}"
      body = "📡 *채널 연결 실패*\n" \
             "사장님: `#{bp_name}`\n" \
             "채널: `#{channel_connection.kind}` (#{channel_connection.handle})\n" \
             "오류: #{error_message.to_s.truncate(200)}"
      notify(KIND_CHANNEL_ERR, channel_connection.account_id, body, metadata: { channel_connection_id: channel_connection.id, kind: channel_connection.kind })
    end

    def daily_summary(business_profile)
      date = Date.current.strftime("%Y-%m-%d")
      account = business_profile.account
      inquiries_count = account.conversations.where("created_at >= ?", Date.current.beginning_of_day).count rescue 0
      contents_count   = account.content_items.where("published_at >= ?", Date.current.beginning_of_day).count rescue 0
      handoffs_count   = account.handoffs.where(state: %w[open acknowledged]).count rescue 0
      body = "📊 *일일 운영 요약* (#{date})\n" \
             "사장님: `#{business_profile.trade_name.presence || business_profile.legal_name}`\n" \
             "오늘 처리 문의: #{inquiries_count}건\n" \
             "오늘 게시: #{contents_count}건\n" \
             "원장님 대기: #{handoffs_count}건"
      notify(KIND_DAILY, business_profile.id, body, metadata: { date: date })
    end
  end
end