class App::ChangeProposalsController < App::BaseController
  def index
    @pending = ChangeProposal.where(business_profile_id: @current_business_profile&.id)
                             .where(status: "pending")
                             .order(created_at: :desc)
                             .limit(50)
    @decided = ChangeProposal.where(business_profile_id: @current_business_profile&.id)
                             .where.not(status: "pending")
                             .order(decided_at: :desc)
                             .limit(50)
  end

  def show
    @proposal = ChangeProposal.where(business_profile_id: @current_business_profile&.id).find(params[:id])
  end

  def approve
    @proposal = ChangeProposal.where(business_profile_id: @current_business_profile&.id).find(params[:id])
    ok = @proposal.approve!(actor: current_user) if current_user
    flash[:notice] = ok ? "승인되었습니다" : "승인할 수 없는 상태입니다"
    redirect_to app_change_proposal_path(@proposal)
  end

  def reject
    @proposal = ChangeProposal.where(business_profile_id: @current_business_profile&.id).find(params[:id])
    ok = @proposal.reject!(actor: current_user, comment: params[:comment]) if current_user
    flash[:notice] = ok ? "거부되었습니다" : "거부할 수 없는 상태입니다"
    redirect_to app_change_proposal_path(@proposal)
  end
end