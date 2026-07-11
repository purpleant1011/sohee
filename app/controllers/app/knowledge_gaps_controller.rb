# frozen_string_literal: true
module App
  class KnowledgeGapsController < App::BaseController
    before_action :load_gap, only: [:show, :convert, :dismiss]

    def index
      @status_filter = params[:status].presence_in(%w[open converted_to_faq dismissed]) || "open"
      @gaps = @current_account.knowledge_gaps.where(status: @status_filter).order(created_at: :desc).limit(100)
      @stats = {
        open: @current_account.knowledge_gaps.where(status: "open").count,
        converted: @current_account.knowledge_gaps.where(status: "converted_to_faq").count,
        dismissed: @current_account.knowledge_gaps.where(status: "dismissed").count,
        total_7d: @current_account.knowledge_gaps.where("created_at >= ?", 7.days.ago).count
      }
      @faqs_for_convert = @current_account.faqs.where(active: true).order(created_at: :desc).limit(20)
    end

    def show
    end

    def create
      gap = @current_account.knowledge_gaps.new(
        question: params.require(:question).to_s.first(500),
        channel: params[:channel].presence || "chat",
        hit_kind: params[:hit_kind].presence_in(%w[no_hit low_score out_of_scope]) || "no_hit",
        answer_attempted: params[:answer_attempted],
        score: params[:score]
      )
      if gap.save
        audit!("knowledge_gap.recorded", payload: { channel: gap.channel, hit_kind: gap.hit_kind })
        redirect_to app_knowledge_gaps_path, notice: "지식 공백이 기록되었습니다. FAQ로 변환하세요."
      else
        redirect_to app_knowledge_gaps_path, alert: gap.errors.full_messages.to_sentence
      end
    end

    def convert
      faq = @current_account.faqs.find(params[:faq_id]) if params[:faq_id].present?
      faq ||= @current_account.faqs.create!(
        question: @gap.question.to_s,
        answer: params[:answer].to_s.presence || "(아직 답변을 작성하지 않았습니다)",
        active: false
      )
      @gap.mark_converted!(faq)
      audit!("knowledge_gap.converted", payload: { faq_id: faq.id, gap_id: @gap.id })
      redirect_to app_faqs_path, notice: "FAQ로 변환되었습니다. 검토 후 활성화하세요."
    end

    def dismiss
      @gap.dismiss!(params[:note])
      audit!("knowledge_gap.dismissed", payload: { gap_id: @gap.id })
      redirect_to app_knowledge_gaps_path, notice: "해당 항목을 무시 처리했습니다."
    end

    private

    def load_gap
      @gap = @current_account.knowledge_gaps.find(params[:id])
    end

    def audit!(action, payload: {})
      AuditEvent.create!(
        account: @current_account,
        actor_user: current_user,
        actor_kind: "operator",
        action: action,
        metadata: payload,
        occurred_at: Time.current
      )
    end
  end
end