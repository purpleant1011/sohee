module Platform
  module Accounts
    # Base for /platform/accounts/:id/* (per-account operator console).
    # Subclasses define one action per console page (setup, persona, knowledge,
    # channels, automations, runtime, audit, content, inquiries, monitoring, safety).
    class ConsolesController < BaseController
      before_action :set_account
      before_action :collect_setup_summary, only: %i[setup]

      # GET /platform/accounts/:id/setup
      # Single-pane readiness view — 6 readiness cards + small status badges.
      def setup
        @setup_status = build_setup_status
        @pending_actions = pending_change_proposals.limit(5)
        @recent_incidents = recent_incidents.limit(5)
        @recent_runtime_heartbeats = recent_runtime_heartbeats.limit(5)
        @recent_executions = recent_automation_executions.limit(5)
      end

      # ---- shared "console" actions (full impl in P4-4) ----
      def persona
        @ai_employees = @account.ai_employees.order(created_at: :desc).limit(20)
        render "platform/accounts/consoles/persona"
      end

      def knowledge
        @knowledge_documents = account_knowledge_documents&.order(created_at: :desc)&.limit(20)
        @faqs = account_faqs&.order(created_at: :desc)&.limit(20)
        render "platform/accounts/consoles/knowledge"
      end

      def channels
        @channel_connections = @account.channel_connections.includes(:channel_scopes).order(created_at: :desc)
        @channel_stats = {
          total:    @channel_connections.count,
          discord:  @channel_connections.where(kind: "discord").count,
          active:   @channel_connections.where(status: "active").count,
          test:     @channel_connections.where("scopes_json::text LIKE ?", "%test_mode%").count,
          official: @channel_connections.where(status: "active").count
        }
        render "platform/accounts/consoles/channels"
      end

      def sync_channel
        ch = @account.channel_connections.find(params[:channel_id])
        DiscordOutboundJob.perform_later(channel_connection_id: ch.id, kind: "resync") if defined?(DiscordOutboundJob)
        redirect_to platform_account_console_channels_path(@account), notice: "채널 ##{ch.id} 동기화 요청됨"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#sync_channel] #{e.class}: #{e.message}")
        redirect_to platform_account_console_channels_path(@account), alert: "동기화 실패: #{e.message}"
      end

      def toggle_channel
        # ChannelConnection has no test_mode column. Toggle a marker in scopes_json instead.
        ch = @account.channel_connections.find(params[:channel_id])
        current = ch.scopes_json.is_a?(Hash) ? ch.scopes_json["test_mode"] : false
        new_scopes = (ch.scopes_json.is_a?(Hash) ? ch.scopes_json.dup : {})
        new_scopes["test_mode"] = !current
        ch.update!(scopes_json: new_scopes)
        new_state = new_scopes["test_mode"] ? "테스트" : "공식"
        redirect_to platform_account_console_channels_path(@account), notice: "채널 ##{ch.id} → #{new_state} 모드"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#toggle_channel] #{e.class}: #{e.message}")
        redirect_to platform_account_console_channels_path(@account), alert: "전환 실패: #{e.message}"
      end

      def disconnect_channel
        ch = @account.channel_connections.find(params[:channel_id])
        ch.update!(status: "disconnected")
        redirect_to platform_account_console_channels_path(@account), notice: "채널 ##{ch.id} 연결 해제됨"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#disconnect_channel] #{e.class}: #{e.message}")
        redirect_to platform_account_console_channels_path(@account), alert: "해제 실패: #{e.message}"
      end

      def automations
        @automation_rules = @account.automation_rules.includes(:automation_executions, :automation_schedules).order(created_at: :desc).limit(50)
        @automation_stats = {
          total:     @automation_rules.count,
          active:    @automation_rules.where(status: "active").count,
          paused:    @automation_rules.where(status: "paused").count,
          ran_24h:   AutomationExecution.where(automation_rule_id: @automation_rules.pluck(:id)).where("created_at > ?", 24.hours.ago).count
        }
        render "platform/accounts/consoles/automations"
      end

      def toggle_automation
        rule = @account.automation_rules.find(params[:rule_id])
        rule.update!(status: rule.status == "active" ? "paused" : "active")
        new_state = rule.status == "active" ? "재개" : "일시중지"
        redirect_to platform_account_console_automations_path(@account), notice: "규칙 ##{rule.id} → #{new_state}"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#toggle_automation] #{e.class}: #{e.message}")
        redirect_to platform_account_console_automations_path(@account), alert: "전환 실패: #{e.message}"
      end

      def run_automation
        rule = @account.automation_rules.find(params[:rule_id])
        AutomationExecution.create!(
          account: @account,
          automation_rule: rule,
          state: "pending",
          schedule_kind: "manual",
          trigger_kind: "manual",
          idempotency_key: "manual-#{rule.id}-#{Time.current.to_i}"
        )
        redirect_to platform_account_console_automations_path(@account), notice: "규칙 ##{rule.id} 수동 실행 큐에 등록됨"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#run_automation] #{e.class}: #{e.message}")
        redirect_to platform_account_console_automations_path(@account), alert: "실행 실패: #{e.message}"
      end

      def runtime
        @runtime_configs = @account.runtime_configs.order(version: :desc).limit(20)
        @runtime_heartbeats = account_runtime_heartbeats&.order(checked_at: :desc)&.limit(20)
        render "platform/accounts/consoles/runtime"
      end

      def audit
        scope = @account.audit_events
        @audit_filter = params[:filter].presence || "all"
        scope = case @audit_filter
                when "today"   then scope.where("occurred_at > ?", 24.hours.ago)
                when "logins"  then scope.where(action: "login")
                when "changes" then scope.where("action LIKE ? OR action LIKE ?", "%change%", "%update%")
                else scope
                end
        @audit_events = scope.order(occurred_at: :desc).limit(100)
        @audit_stats = {
          total:     @account.audit_events.count,
          today:     @account.audit_events.where("occurred_at > ?", 24.hours.ago).count,
          errors:    @account.audit_events.where("action LIKE ? OR action LIKE ?", "%error%", "%fail%").count,
          logins:    @account.audit_events.where(action: "login").count
        }
        render "platform/accounts/consoles/audit"
      end

      def content
        scope = @account.content_items
        @content_filter = params[:filter].presence || "all"
        scope = case @content_filter
                when "draft"     then scope.where(state: "draft")
                when "approved"  then scope.where(state: "approved")
                when "scheduled" then scope.where(state: "scheduled")
                when "published" then scope.where(state: "published")
                when "rejected"  then scope.where(safety_state: "rejected")
                else scope
                end
        @content_items = scope.order(created_at: :desc).limit(50)
        @content_stats = {
          total:     @account.content_items.count,
          draft:     @account.content_items.where(state: "draft").count,
          approved:  @account.content_items.where(state: "approved").count,
          scheduled: @account.content_items.where(state: "scheduled").count,
          published: @account.content_items.where(state: "published").count,
          failed:    @account.content_items.where(safety_state: "rejected").count
        }
        render "platform/accounts/consoles/content"
      end

      # POST /platform/accounts/:account_id/content/:content_id/approve
      def approve_content
        item = @account.content_items.find(params[:content_id])
        item.update!(state: "approved")
        redirect_to platform_account_console_content_path(@account), notice: "콘텐츠 ##{item.id} 승인됨"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#approve_content] #{e.class}: #{e.message}")
        redirect_to platform_account_console_content_path(@account), alert: "승인 실패: #{e.message}"
      end

      # POST /platform/accounts/:account_id/content/:content_id/reject
      def reject_content
        item = @account.content_items.find(params[:content_id])
        item.update!(safety_state: "rejected", state: "draft")
        redirect_to platform_account_console_content_path(@account), notice: "콘텐츠 ##{item.id} 거부됨 (초안으로 되돌림)"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#reject_content] #{e.class}: #{e.message}")
        redirect_to platform_account_console_content_path(@account), alert: "거부 실패: #{e.message}"
      end

      # POST /platform/accounts/:account_id/content/:content_id/publish
      def publish_content
        item = @account.content_items.find(params[:content_id])
        item.update!(state: "published", published_at: Time.current)
        redirect_to platform_account_console_content_path(@account), notice: "콘텐츠 ##{item.id} 게시 완료"
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#publish_content] #{e.class}: #{e.message}")
        redirect_to platform_account_console_content_path(@account), alert: "게시 실패: #{e.message}"
      end

      def inquiries
        # Inquiry has no account_id or business_profile_id FK in current schema.
        # It's a generic lead capture table — fallback to .none for safety.
        @inquiries = Inquiry.order(created_at: :desc).limit(50)
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#inquiries] #{e.class}: #{e.message}")
        @inquiries = Inquiry.none
      ensure
        render "platform/accounts/consoles/inquiries"
      end

      def monitoring
        @automation_executions = account_automation_executions&.order(created_at: :desc)&.limit(50)
        @publication_attempts = account_publication_attempts&.order(created_at: :desc)&.limit(50)
        render "platform/accounts/consoles/monitoring"
      end

      def safety
        @safety_logs = account_safety_logs&.order(created_at: :desc)&.limit(50)
        render "platform/accounts/consoles/safety"
      end

      private

      def set_account
        @account = Account.find(params[:account_id])
      end

      # ---- safe accessors ----
      # Account has_many lines exist for many models but some reference columns
      # that aren't in the schema (legacy). Wrap each in rescue so a missing
      # column doesn't blow up the operator's whole console page.
      def account_knowledge_documents
        return nil unless @account.respond_to?(:knowledge_documents) && Account.reflect_on_association(:knowledge_documents)
        @account.knowledge_documents
      rescue StandardError
        nil
      end

      def account_faqs
        return nil unless @account.respond_to?(:faqs) && Account.reflect_on_association(:faqs)
        @account.faqs
      rescue StandardError
        nil
      end

      def account_inquiries
        return Inquiry.none unless Account.reflect_on_association(:inquiries)
        @account.inquiries
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#account_inquiries] #{e.class}: #{e.message}")
        Inquiry.none
      end

      def safe_inquiry_count
        account_inquiries.count
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#safe_inquiry_count] #{e.class}: #{e.message}")
        0
      end

      def account_change_proposals
        return ChangeProposal.none unless Account.reflect_on_association(:change_proposals)
        @account.change_proposals
      rescue Exception => e
        Rails.logger.warn("[ConsolesController#account_change_proposals] #{e.class}: #{e.message}")
        ChangeProposal.none
      end

      def account_safety_logs
        return nil unless @account.respond_to?(:safety_logs) && Account.reflect_on_association(:safety_logs)
        @account.safety_logs
      rescue StandardError
        nil
      end

      def account_runtime_heartbeats
        return nil unless @account.respond_to?(:runtime_heartbeats) && Account.reflect_on_association(:runtime_heartbeats)
        @account.runtime_heartbeats
      rescue StandardError
        nil
      end

      def account_incidents
        return nil unless @account.respond_to?(:incidents) && Account.reflect_on_association(:incidents)
        @account.incidents
      rescue StandardError
        nil
      end

      def account_automation_executions
        return nil unless @account.respond_to?(:automation_executions) && Account.reflect_on_association(:automation_executions)
        @account.automation_executions
      rescue StandardError
        nil
      end

      def account_publication_attempts
        return nil unless @account.respond_to?(:publication_attempts) && Account.reflect_on_association(:publication_attempts)
        @account.publication_attempts
      rescue StandardError
        nil
      end

      # P0-P3 friendly "6-card" readiness summary, mirrored in views via @setup_status.
      def collect_setup_summary
        @setup_counts = {
          ai_employees: @account.ai_employees.count,
          knowledge_documents: account_knowledge_documents&.count || 0,
          faqs: account_faqs&.count || 0,
          channel_connections: @account.channel_connections.count,
          automation_rules: @account.automation_rules.count,
          runtime_configs: @account.runtime_configs.count,
          users: @account.users.count,
          content_items: @account.content_items.count,
          inquiries: safe_inquiry_count,
          publication_attempts: account_publication_attempts&.count || 0
        }
      end

      def build_setup_status
        {
          persona: @account.ai_employees.exists?,
          knowledge: (@setup_counts[:knowledge_documents].to_i + @setup_counts[:faqs].to_i) > 0,
          channels: @account.channel_connections.exists?,
          runtime: @account.runtime_configs.exists?,
          automations: @account.automation_rules.exists?,
          discord: @account.channel_connections.where(kind: "discord").exists?
        }
      end

      def pending_change_proposals
        scope = account_change_proposals
        return ChangeProposal.none if scope == ChangeProposal.none
        scope.where(status: "pending").order(created_at: :desc)
      end

      def recent_incidents
        scope = account_incidents
        return Incident.none if scope.nil?
        scope.order(opened_at: :desc)
      end

      def recent_runtime_heartbeats
        scope = account_runtime_heartbeats
        return RuntimeHeartbeat.none if scope.nil?
        scope.order(checked_at: :desc)
      end

      def recent_automation_executions
        scope = account_automation_executions
        return AutomationExecution.none if scope.nil?
        scope.order(created_at: :desc)
      end
    end
  end
end