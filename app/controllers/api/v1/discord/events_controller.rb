# frozen_string_literal: true

# Api::V1::Discord::EventsController — Discord Gateway → Rails
# 워커가 Discord 이벤트를 수신해 Rails에 전달 (원본 사본 저장)
module Api
  module V1
    module Discord
      class EventsController < Api::V1::BaseController
        # POST /api/v1/discord/events
        # body: { snowflake_id, guild_id, channel_id, author_discord_id,
        #         kind, content_raw, attachments_meta, embeds_meta, mentions_meta }
        def create
          payload = event_params
          workspace = DiscordWorkspace.find_by!(guild_id: payload[:guild_id])
          identity = payload[:author_discord_id].present? ?
            DiscordIdentity.find_by(discord_user_id: payload[:author_discord_id], business_profile_id: workspace.business_profile_id) :
            nil

          event = DiscordMessageEvent.create!(
            business_profile_id: workspace.business_profile_id,
            discord_workspace_id: workspace.id,
            discord_identity_id: identity&.id,
            snowflake_id: payload[:snowflake_id],
            channel_id: payload[:channel_id],
            guild_id: payload[:guild_id],
            author_discord_id: payload[:author_discord_id],
            kind: payload[:kind] || "message_create",
            content_raw: payload[:content_raw],
            attachments_meta: payload[:attachments_meta] || {},
            embeds_meta: payload[:embeds_meta] || {},
            mentions_meta: payload[:mentions_meta] || {}
          )

          workspace.mark_event_received!

          # 비동기 처리 큐잉 (P1.5)
          ProcessDiscordEventJob.perform_later(event.id) if FeatureFlags.enabled?(:discord_native_enabled)

          AuditEvent.create!(
            actor_kind: "system",
            actor_label: "discord-gateway",
            action: "discord.event.received",
            target: "DiscordMessageEvent##{event.id}",
            metadata: { snowflake_id: event.snowflake_id, channel_id: event.channel_id }
          )

          render json: { id: event.id, status: "queued" }, status: :accepted
        end

        private

        def event_params
          params.permit(
            :snowflake_id, :guild_id, :channel_id, :author_discord_id,
            :kind, :content_raw,
            attachments_meta: {}, embeds_meta: {}, mentions_meta: {}
          ).to_h.deep_symbolize_keys
        end
      end
    end
  end
end