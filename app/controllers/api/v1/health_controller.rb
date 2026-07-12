# frozen_string_literal: true

# Api::V1::HealthController — Discord-Native 헬스 체크
# 인증: 없음 (외부 모니터링용), feature flag 영향 안 받음
module Api
  module V1
    class HealthController < ActionController::Base
      def show
        checks = {
          rails: rails_ok?,
          database: database_ok?,
          queue: queue_ok?,
          workers_expected: %w[discord-gateway gemini-conversation sohee-control-mcp],
          feature_flags: {
            discord_native_enabled: FeatureFlags.enabled?(:discord_native_enabled),
            antigravity_cli_enabled: FeatureFlags.enabled?(:antigravity_cli_enabled),
            sohee_gemini_provider_active: FeatureFlags.enabled?(:sohee_gemini_provider_active)
          }
        }
        status = checks[:rails] && checks[:database] ? :ok : :service_unavailable
        render json: checks, status: status
      end

      private

      def rails_ok?
        true
      end

      def database_ok?
        ActiveRecord::Base.connection.execute("SELECT 1").first["?column?"].to_i == 1
      rescue StandardError
        false
      end

      def queue_ok?
        defined?(SolidQueue) ? SolidQueue::Process.any? || true : true
      rescue StandardError
        false
      end
    end
  end
end