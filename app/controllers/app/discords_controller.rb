class App::DiscordsController < App::BaseController
  TAB_RECENT = "recent"
  TAB_TRAINING = "training"
  TAB_CHANGES = "changes"
  ALL_TABS = [TAB_RECENT, TAB_TRAINING, TAB_CHANGES].freeze

  def index
    @tab = ALL_TABS.include?(params[:tab]) ? params[:tab] : TAB_RECENT
    bp = @current_business_profile
    @workspace = bp ? bp.discord_workspaces.first : nil

    # @recent_events 는 Relation 유지 (탭별 .where(...) 분기 위해 limit 분리)
    base_events = @workspace ? DiscordMessageEvent.where(discord_workspace_id: @workspace.id) : DiscordMessageEvent.none
    @recent_events = base_events.order(created_at: :desc).limit(50)

    @training_events = base_events.where(intent: %w[change_request training]).order(created_at: :desc).limit(50)

    @pending_proposals = ChangeProposal.where(business_profile_id: bp&.id)
                                       .where(status: "pending")
                                       .order(created_at: :desc)
                                       .limit(20)
  end
end