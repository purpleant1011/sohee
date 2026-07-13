class App::IntegritiesController < App::BaseController
  def show
    bp = @current_business_profile
    @workspaces = bp ? bp.discord_workspaces : []

    @total_events = DiscordMessageEvent.where(business_profile_id: bp&.id).count
    @processed = DiscordMessageEvent.where(business_profile_id: bp&.id, processed: true).count
    @pending = DiscordMessageEvent.where(business_profile_id: bp&.id, processed: false, processing_error: nil).count
    @errored = DiscordMessageEvent.where(business_profile_id: bp&.id).where.not(processing_error: nil).count

    @recent_errors = DiscordMessageEvent.where(business_profile_id: bp&.id)
                                        .where.not(processing_error: nil)
                                        .order(created_at: :desc)
                                        .limit(10)
  end
end