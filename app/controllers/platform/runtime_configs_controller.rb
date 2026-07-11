# frozen_string_literal: true
module Platform
  # 운영자 콘솔에서 사업장별 런타임 설정을 조회/관리한다 (P0-4).
  class RuntimeConfigsController < BaseController
    before_action :load_account, only: [:index]
    before_action :load_config, only: [:show]

    def index
      @configs = (@account&.runtime_configs || RuntimeConfig).recent.limit(30)
      @active  = @account&.runtime_configs&.active&.first
    end

    def show
      @heartbeat_summary = RuntimeHeartbeat.summary_24h(@config.account)
    end

    private

    def load_account
      account_id = params[:account_id].presence
      @account = account_id ? Account.find(account_id) : nil
    end

    def load_config
      scope = @account ? @account.runtime_configs : RuntimeConfig
      @config = scope.find(params[:id])
    end
  end
end