# frozen_string_literal: true

# Api::V1::Gemini::CallsController — Gemini Conversation 워커 → Rails 결과 보고
module Api
  module V1
    module Gemini
      class CallsController < Api::V1::BaseController
        # POST /api/v1/gemini/call
        # body: { provider, model, messages, intent, response_text, structured_payload, change_proposal_seed }
        def create
          payload = call_params

          case payload[:intent]
          when "change_request"
            seed = payload[:change_proposal_seed] || {}
            proposal = ChangeProposal.create!(
              business_profile_id: payload[:business_profile_id],
              ai_employee_id: payload[:ai_employee_id],
              target_kind: seed[:target_kind] || "runtime_config",
              target_field: seed[:target_field],
              proposed_payload: seed[:proposed_payload] || {},
              previous_payload: seed[:previous_payload] || {},
              reason: seed[:reason] || payload[:response_text].to_s.truncate(200),
              user_quote: seed[:user_quote]
            )
            render json: { proposal_id: proposal.id, status: proposal.status }, status: :created
          when "content_draft"
            item = ContentItem.create!(
              business_profile_id: payload[:business_profile_id],
              kind: "draft",
              title: payload.dig(:structured_payload, :title) || "(초안)",
              body: payload.dig(:structured_payload, :body) || payload[:response_text].to_s,
              metadata: { source: "gemini", provider: payload[:provider], model: payload[:model] }
            )
            render json: { content_item_id: item.id }, status: :created
          when "inquiry"
            classification = payload[:structured_payload] || {}
            render json: {
              classification: classification,
              suggestion: "CreateInquiryJob 큐잉"
            }, status: :ok
          else
            render json: {
              text: payload[:response_text],
              structured: payload[:structured_payload],
              note: "no_persist"
            }, status: :ok
          end
        end

        private

        def call_params
          params.permit(
            :provider, :model, :intent, :response_text,
            :business_profile_id, :ai_employee_id,
            messages: [],
            structured_payload: {},
            change_proposal_seed: {}
          ).to_h.deep_symbolize_keys
        end
      end
    end
  end
end