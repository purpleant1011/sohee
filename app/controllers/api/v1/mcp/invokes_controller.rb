# frozen_string_literal: true

# Api::V1::Mcp::InvokesController — Hermes Agent → Rails MCP 도구 라우터
# 원칙: 도구는 화이트리스트만, 멱등키 필수, 감사 로그 자동
module Api
  module V1
    module Mcp
      class InvokesController < Api::V1::BaseController
        TOOL_WHITELIST = %w[
          get_active_runtime_config
          list_pending_jobs
          claim_job
          submit_job_result
          request_human_review
          save_content_draft
          report_knowledge_gap
          post_discord_report
          report_agent_health
          recall_business_memory
        ].freeze

        # POST /api/v1/mcp/invoke
        # body: { tool, idempotency_key, params: {...} }
        def create
          tool = params[:tool].to_s
          unless TOOL_WHITELIST.include?(tool)
            return render json: { error: "tool_not_whitelisted", tool: tool }, status: :bad_request
          end

          sync = RuntimeSync.create!(
            business_profile_id: business_profile_id_from_params,
            direction: "hermes_to_rails",
            topic: tool_to_topic(tool),
            agent_id: params[:agent_id] || "sohee-control-mcp",
            payload: params[:params]&.to_unsafe_h || {},
            idempotency_key: params[:idempotency_key].presence || SecureRandom.uuid,
            status: "pending"
          )

          result = execute_tool(tool, sync)

          sync.mark_ack!(response: result) unless sync.status == "nack"

          render json: { tool: tool, result: result, sync_id: sync.id }, status: :ok
        rescue StandardError => e
          sync&.mark_nack!(response: { error: e.class.name }, error: e.message)
          render json: { error: e.class.name, message: e.message }, status: :internal_server_error
        end

        private

        def execute_tool(tool, sync)
          case tool
          when "get_active_runtime_config"
            get_active_runtime_config(sync)
          when "list_pending_jobs"
            { jobs: [] } # stub — P3에서 실제 큐 연동
          when "claim_job"
            { claimed: 0 } # stub
          when "submit_job_result"
            { accepted: true }
          when "request_human_review"
            request_human_review(sync)
          when "save_content_draft"
            save_content_draft(sync)
          when "report_knowledge_gap"
            report_knowledge_gap(sync)
          when "post_discord_report"
            post_discord_report(sync)
          when "report_agent_health"
            { health: params[:params]&.to_unsafe_h || {} }
          when "recall_business_memory"
            recall_business_memory(sync)
          else
            raise "Unknown tool #{tool}"
          end
        end

        def get_active_runtime_config(sync)
          config = RuntimeConfig.where(business_profile_id: sync.business_profile_id, status: "active").order(version: :desc).first
          return { runtime_config: nil } unless config
          { runtime_config: { id: config.id, version: config.version, bundle: config.bundle_json } }
        end

        def request_human_review(sync)
          payload = sync.payload.with_indifferent_access
          proposal = ChangeProposal.create!(
            business_profile_id: sync.business_profile_id,
            target_kind: payload[:target_kind] || "runtime_config",
            target_field: payload[:target_field],
            proposed_payload: payload[:proposed_payload] || {},
            previous_payload: payload[:previous_payload] || {},
            reason: payload[:reason],
            user_quote: payload[:user_quote]
          )
          { proposal_id: proposal.id, status: proposal.status }
        end

        def save_content_draft(sync)
          payload = sync.payload.with_indifferent_access
          draft = ContentItem.create!(
            business_profile_id: sync.business_profile_id,
            kind: "draft",
            title: payload[:title] || "(초안)",
            body: payload[:body] || "",
            metadata: { source: "mcp", agent_id: sync.agent_id }
          )
          { content_item_id: draft.id }
        end

        def report_knowledge_gap(sync)
          payload = sync.payload.with_indifferent_access
          KnowledgeGap.create!(
            business_profile_id: sync.business_profile_id,
            summary: payload[:summary] || "(보강 필요)",
            context: payload[:context] || {}
          )
          { recorded: true }
        end

        def post_discord_report(sync)
          payload = sync.payload.with_indifferent_access
          # OutboundJob 큐잉 — Discord에 메시지 보내기 (P1.5)
          DiscordOutboundJob.perform_later(
            sync.business_profile_id,
            payload[:channel_id],
            payload[:content]
          )
          { queued: true }
        end

        def recall_business_memory(sync)
          payload = sync.payload.with_indifferent_access
          memories = BusinessMemory.recall(
            business_profile: BusinessProfile.find(sync.business_profile_id),
            kinds: payload[:kinds]
          )
          { memories: memories.map { |m| { id: m.id, scope: m.scope, kind: m.memory_kind, content: m.content, weight: m.weight } } }
        end

        def tool_to_topic(tool)
          {
            "get_active_runtime_config" => "runtime_config_update",
            "save_content_draft" => "content_draft",
            "report_knowledge_gap" => "knowledge_gap",
            "post_discord_report" => "health",
            "request_human_review" => "change_proposal_applied"
          }.fetch(tool, "health")
        end

        def business_profile_id_from_params
          params[:business_profile_id].presence ||
            (params[:params]&.dig(:business_profile_id)) ||
            raise(ActionController::ParameterMissing, "business_profile_id")
        end
      end
    end
  end
end