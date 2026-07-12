# frozen_string_literal: true

# CompileRuntimeConfigJob — 승인된 ChangeProposal → RuntimeConfig Draft 컴파일
# 원칙 3: RuntimeConfig v1 재사용 (Draft → Active 2-step)
class CompileRuntimeConfigJob < DiscordNativeJob
  queue_as :default

  def perform(proposal_id, actor_user_id)
    return unless FeatureFlags.enabled?(:discord_native_enabled)
    proposal = ChangeProposal.find(proposal_id)
    return unless proposal.status == "approved"

    current = RuntimeConfig.where(business_profile_id: proposal.business_profile_id, status: "active").order(version: :desc).first
    new_bundle = compose_bundle(current&.bundle_json, proposal)

    config = RuntimeConfig.create!(
      business_profile_id: proposal.business_profile_id,
      version: (current&.version || 0) + 1,
      status: "draft",
      bundle_json: new_bundle,
      compiled_at: Time.current,
      compiled_by_agent_id: "sohee-control-mcp",
      source_change_proposal_id: proposal.id,
      checksum: Digest::SHA256.hexdigest(new_bundle.to_json)
    )

    proposal.mark_applied!(runtime_config_id: config.id)

    # Hermes에 알림
    DispatchHermesJob.perform_later(
      proposal.business_profile_id,
      "runtime_config_update",
      { runtime_config_id: config.id, version: config.version, status: "draft" }
    )

    # Discord에 결과 보고
    business = proposal.business_profile
    workspace = business.discord_workspaces.active.first
    if workspace
      DiscordOutboundJob.perform_later(
        business.id,
        workspace.default_channel_id,
        "✅ 새 설정 초안이 만들어졌어요. 검토 후 운영팀이 적용합니다.\n설정 ##{config.version} (#{proposal.target_kind}.#{proposal.target_field})"
      )
    end

    config
  end

  private

  def compose_bundle(current_bundle, proposal)
    base = current_bundle.is_a?(Hash) ? current_bundle.deep_dup : {}
    field_key = proposal.target_field || "unspecified"
    base[field_key.to_s] = proposal.proposed_payload
    base
  end
end