# frozen_string_literal: true

# Api::V1::RuntimeSyncsController — Hermes ACK / NACK 수신
module Api
  module V1
    class RuntimeSyncsController < Api::V1::BaseController
      # POST /api/v1/runtime_syncs/:id/ack
      def ack
        sync = RuntimeSync.find(params[:id])
        sync.mark_ack!(response: params[:response]&.to_unsafe_h || {})
        render json: { id: sync.id, status: sync.status }
      end

      # POST /api/v1/runtime_syncs/:id/nack
      def nack
        sync = RuntimeSync.find(params[:id])
        sync.mark_nack!(response: params[:response]&.to_unsafe_h || {}, error: params[:error])
        if sync.exhausted?
          sync.update!(status: "timeout")
        else
          sync.schedule_retry!(backoff: backoff_seconds(sync.attempts))
        end
        render json: { id: sync.id, status: sync.status, attempts: sync.attempts }
      end

      private

      def backoff_seconds(attempt)
        # 지수 백오프 (최대 5분)
        [2 ** attempt, 300].min
      end
    end
  end
end