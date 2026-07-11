module App
  class KnowledgeSourcesController < BaseController
    before_action :load_source, only: [:show, :edit, :update, :destroy, :sync, :mark_failed, :reindex]

    # 사장님이 사업장의 지식 베이스를 관리합니다.
    # 종류: upload (PDF/문서), text (직접 입력), url (웹페이지), faq (자주 묻는 질문), product (상품)
    def index
      @sources = @current_account.knowledge_sources.order(:kind, :title)
      @documents = @current_account.knowledge_documents.order(created_at: :desc).limit(20)
      @stats = {
        total: @current_account.knowledge_sources.count,
        ready: @current_account.knowledge_sources.where(status: "ready").count,
        processing: @current_account.knowledge_sources.where(status: "processing").count,
        failed: @current_account.knowledge_sources.where(status: "failed").count
      }
    end

    def show
      @documents = @source.knowledge_documents.order(created_at: :desc).limit(50)
    end

    def new
      @source = @current_account.knowledge_sources.build(kind: "upload", language: "ko")
      @ai_employees = @current_account.ai_employees.order(:name)
    end

    def create
      @source = @current_account.knowledge_sources.build(source_params)
      @source.status = "pending"
      if @source.save
        # 파일 첨부
        if params[:knowledge_source][:file].present?
          @source.file.attach(params[:knowledge_source][:file])
        end
        # 자동 처리 큐잉 (RAG 학습)
        KnowledgeIngestJob.perform_later(@source.id) if defined?(KnowledgeIngestJob)
        AuditEvent.create!(account: @current_account, action: "knowledge.created", resource_type: "KnowledgeSource", resource_id: @source.id, metadata: { kind: @source.kind, title: @source.title }, occurred_at: Time.current)
        redirect_to app_knowledge_source_path(@source), notice: "지식 소스가 추가되었습니다. 자동 처리 중입니다."
      else
        @ai_employees = @current_account.ai_employees.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @ai_employees = @current_account.ai_employees.order(:name)
    end

    def update
      if @source.update(source_params)
        if params[:knowledge_source][:file].present?
          @source.file.attach(params[:knowledge_source][:file])
        end
        AuditEvent.create!(account: @current_account, action: "knowledge.updated", resource_type: "KnowledgeSource", resource_id: @source.id, occurred_at: Time.current)
        redirect_to app_knowledge_source_path(@source), notice: "지식 소스가 수정되었습니다."
      else
        @ai_employees = @current_account.ai_employees.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @source.destroy
      AuditEvent.create!(account: @current_account, action: "knowledge.deleted", resource_type: "KnowledgeSource", resource_id: @source.id, metadata: { title: @source.title }, occurred_at: Time.current)
      redirect_to app_knowledge_sources_path, notice: "지식 소스가 삭제되었습니다."
    end

    # 재처리 (RAG 재학습)
    def sync
      @source.update!(status: "pending", error_message: nil)
      KnowledgeIngestJob.perform_later(@source.id) if defined?(KnowledgeIngestJob)
      redirect_to app_knowledge_source_path(@source), notice: "재처리가 시작되었습니다."
    end

    def mark_failed
      @source.update!(status: "failed", error_message: "사용자 수동 실패 처리")
      redirect_to app_knowledge_source_path(@source), notice: "실패 처리되었습니다."
    end

    # 인덱스 재생성 (전문가용)
    def reindex
      @source.update!(status: "pending")
      redirect_to app_knowledge_source_path(@source), notice: "인덱스 재생성이 큐잉되었습니다."
    end

    private

    def load_source
      @source = @current_account.knowledge_sources.find(params[:id])
    end

    def source_params
      params.require(:knowledge_source).permit(
        :title, :kind, :url, :ai_employee_id, :language, :ai_training_allowed,
        :contains_personal_data, :rights_confirmation, :valid_from, :valid_until,
        :status, :error_message, :tags,
        tags_json: []
      )
    end
  end
end