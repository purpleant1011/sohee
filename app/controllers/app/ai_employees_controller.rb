class App::AiEmployeesController < App::BaseController
  before_action :load_employee, only: [:show, :edit, :update, :destroy, :duplicate, :test_message, :add_memory, :remove_memory, :preview_persona]

  def index
    @employees = @current_account.ai_employees.order(:name)
  end

  def show
    @versions = @employee.ai_employee_versions.order(created_at: :desc).limit(20)
    @recent_executions = AutomationExecution.where(ai_employee_id: @employee.id).order(created_at: :desc).limit(10)
    @recent_messages = Conversation.where(ai_employee_id: @employee.id).order(last_message_at: :desc).limit(5)
  end

  def new
    @employee = @current_account.ai_employees.build
    @templates = AiEmployee::PERSONA_PRESETS.keys
  end

  def create
    @employee = @current_account.ai_employees.build(employee_params)
    @employee.status ||= "draft"
    if @employee.save
      AiEmployeeVersion.create!(
        account: @current_account, ai_employee: @employee,
        change_summary: "AI 직원 신규 생성 (#{@employee.name})",
        snapshot_json: @employee.attributes
      )
      AuditEvent.create!(account: @current_account, action: "ai_employee.created", resource_type: "AiEmployee", resource_id: @employee.id, occurred_at: Time.current)
      redirect_to app_ai_employee_path(@employee), notice: "AI 직원이 생성되었습니다."
    else
      @templates = AiEmployee::PERSONA_PRESETS.keys
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @templates = AiEmployee::PERSONA_PRESETS.keys
  end

  def update
    before_attrs = @employee.attributes.dup
    if @employee.update(employee_params)
      AiEmployeeVersion.create!(
        account: @current_account, ai_employee: @employee,
        change_summary: "AI 직원 설정 변경",
        snapshot_json: { before: before_attrs.slice(*employee_params.keys), after: @employee.attributes.slice(*employee_params.keys) }
      )
      audit_change!(@employee)
      redirect_to app_ai_employee_path(@employee), notice: "AI 직원 설정이 저장되었습니다."
    else
      @templates = AiEmployee::PERSONA_PRESETS.keys
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @employee.automation_rules.any? || @employee.channel_connections.any?
      redirect_to app_ai_employee_path(@employee), alert: "이 AI 직원을 사용하는 자동화 규칙이나 채널이 있어 삭제할 수 없습니다. 먼저 연결을 해제하세요."
    else
      @employee.destroy
      AuditEvent.create!(account: @current_account, action: "ai_employee.deleted", resource_type: "AiEmployee", resource_id: @employee.id, occurred_at: Time.current)
      redirect_to app_ai_employees_path, notice: "AI 직원이 삭제되었습니다."
    end
  end

  # 템플릿에서 빠른 생성
  def create_default
    preset = params[:preset].presence
    template = AiEmployee::PERSONA_PRESETS[preset]
    unless template
      redirect_to app_ai_employees_path, alert: "알 수 없는 템플릿입니다."
      return
    end

    # 한국어 라벨을 enum 값으로 변환
    tone_enum = AiEmployee::TONE_LABELS_REVERSE[template[:tone]] || "warm_casual"
    honorific_enum = AiEmployee::HONORIFIC_LABELS_REVERSE[template[:honorific]&.gsub(" 체", "")] || "casual"
    sentence_enum = AiEmployee::SENTENCE_LENGTH_LABELS_REVERSE[template[:sentence_length]] || "medium"

    @employee = @current_account.ai_employees.build(
      name: template[:name],
      role_label: template[:role_label],
      tone: tone_enum,
      friendliness: template[:friendliness],
      expertise_level: template[:expertise_level],
      proactiveness: template[:proactiveness],
      honorific: honorific_enum,
      sentence_length: sentence_enum,
      persona_preset: template[:persona_preset],
      industry_expertise: template[:industry_expertise],
      natural_language_instructions: template[:natural_language_instructions],
      status: "draft"
    )
    @employee.work_days_json = template[:work_days_json]
    @employee.work_hours_json = template[:work_hours_json]
    @employee.vocabulary_phrases_json = template[:vocabulary_phrases_json]
    @employee.forbidden_phrases_json = template[:forbidden_phrases_json]
    @employee.can_answer_topics_json = template[:can_answer_topics_json]
    @employee.must_handoff_topics_json = template[:must_handoff_topics_json]

    if @employee.save
      AiEmployeeVersion.create!(account: @current_account, ai_employee: @employee, change_summary: "템플릿에서 생성 (#{preset})", snapshot_json: template)
      AuditEvent.create!(account: @current_account, action: "ai_employee.created_from_template", resource_type: "AiEmployee", resource_id: @employee.id, metadata: { preset: preset }, occurred_at: Time.current)
      redirect_to app_ai_employee_path(@employee), notice: "AI 직원 '#{@employee.name}'이(가) 생성되었습니다. 세부 설정을 조정해보세요."
    else
      redirect_to app_ai_employees_path, alert: @employee.errors.full_messages.to_sentence
    end
  end

  # 기존 AI 직원 복제 (변형 시작점으로)
  def duplicate
    new_emp = @current_account.ai_employees.build(@employee.attributes.except("id", "created_at", "updated_at").merge(
      name: "#{@employee.name} (복제본)",
      status: "draft"
    ))
    if new_emp.save
      redirect_to edit_app_ai_employee_path(new_emp), notice: "AI 직원이 복제되었습니다. 설정을 조정한 뒤 활성화하세요."
    else
      redirect_to app_ai_employee_path(@employee), alert: new_emp.errors.full_messages.to_sentence
    end
  end

  # 테스트 메시지 — 사장님이 페르소나를 미리 검증
  def test_message
    user_msg = params[:message].to_s.strip
    if user_msg.blank?
      return redirect_to app_ai_employee_path(@employee), alert: "테스트 메시지를 입력해주세요."
    end
    @test_result = simulate_response(@employee, user_msg)
    AuditEvent.create!(account: @current_account, action: "ai_employee.tested", resource_type: "AiEmployee", resource_id: @employee.id, metadata: { user_message: user_msg[0,200], response: @test_result[:response]&.slice(0,300) }, occurred_at: Time.current)
    redirect_to app_ai_employee_path(@employee, anchor: "test-result"), notice: @test_result[:notice]
  end

  # 메모리 추가 (학습 노트)
  def add_memory
    kind = params[:memory_kind].to_s
    value = params[:memory_value].to_s.strip
    if kind.present? && value.present?
      @employee.append_memory!(kind: kind, value: value)
      AuditEvent.create!(account: @current_account, action: "ai_employee.memory_added", resource_type: "AiEmployee", resource_id: @employee.id, metadata: { kind: kind, value: value[0,200] }, occurred_at: Time.current)
      redirect_to app_ai_employee_path(@employee), notice: "메모리에 저장되었습니다."
    else
      redirect_to app_ai_employee_path(@employee), alert: "메모리 종류와 내용을 모두 입력해주세요."
    end
  end

  def remove_memory
    index = params[:memory_index].to_i
    current = @employee.memory
    [:notes, :topics, :style_examples].each do |bucket|
      arr = Array(current[bucket.to_s])
      next unless index < arr.size
      arr.delete_at(index)
      current[bucket.to_s] = arr
      @employee.update_column(:memory_json, current)
      break
    end
    redirect_to app_ai_employee_path(@employee), notice: "메모리 항목이 삭제되었습니다."
  end

  # 페르소나 미리보기 (실제 발행될 응답 톤 미리 생성)
  def preview_persona
    samples = [
      "가격이 얼마예요?",
      "예약 가능한가요?",
      "리뷰 잘 없어서 걱정이에요"
    ]
    @previews = samples.map { |s| { user: s, response: simulate_response(@employee, s)[:response] } }
    render :preview_persona
  end

  private

  def load_employee
    @employee = @current_account.ai_employees.find(params[:id])
  end

  def employee_params
    raw = params.require(:ai_employee).permit(
      :name, :role_label, :industry_expertise, :tone, :friendliness, :expertise_level, :proactiveness,
      :honorific, :sentence_length, :daily_post_quota, :weekly_post_quota, :approval_mode,
      :monthly_token_budget, :daily_token_budget, :monthly_cost_budget_krw, :daily_cost_budget_krw,
      :natural_language_instructions, :persona_preset, :preferred_locale, :fallback_locale,
      :supported_locales, :system_notes, :status, :avatar_url,
      work_days_json: [], work_hours_json: {},
      vocabulary_phrases_json: [], forbidden_phrases_json: [],
      can_answer_topics_json: [], must_handoff_topics_json: [],
      channel_behaviors_json: {}
    ).to_h

    # 한국어 → enum 변환
    raw["tone"] = AiEmployee::TONE_LABELS_REVERSE[raw["tone"]] if raw["tone"]
    raw["honorific"] = AiEmployee::HONORIFIC_LABELS_REVERSE[raw["honorific"]] if raw["honorific"]
    raw["sentence_length"] = AiEmployee::SENTENCE_LENGTH_LABELS_REVERSE[raw["sentence_length"]] if raw["sentence_length"]
    raw
  end

  def audit_change!(employee)
    AuditEvent.create!(account: @current_account, action: "ai_employee.updated", resource_type: "AiEmployee", resource_id: employee.id, occurred_at: Time.current)
  end

  # 응답 시뮬레이션 (실제 LLM 없이 톤/페르소나만 검증)
  def simulate_response(employee, user_msg)
    # 금지어 필터
    forbidden = Array(employee.forbidden_phrases_json)
    filtered = user_msg
    forbidden.each { |f| filtered = filtered.gsub(f, "•••") if f.present? }

    # handoff 트리거
    handoff_topics = Array(employee.must_handoff_topics_json)
    if handoff_topics.any? { |t| filtered.include?(t) }
      return {
        response: "[사람에게 인계] 이 주제는 사장님이 직접 응대하시는 게 좋겠습니다. 잠시만 기다려주세요.",
        action: "handoff",
        notice: "⚠️ handoff 트리거 — 사장님께 인계됩니다."
      }
    end

    # 톤/존칭 적용 (enum → 한국어 라벨)
    tone_label = employee.tone_label
    honorific = employee.honorific_label
    greeting = case tone_label
               when "친근한" then "안녕하세요"
               when "격식 있는" then "안녕하십니까"
               when "밝고 활발한" then "안녕하세요! 반갑습니다"
               else "안녕하세요"
               end

    # 어휘 매칭
    vocab = Array(employee.vocabulary_phrases_json).first(3)
    vocab_phrase = vocab.sample || "도와드릴게요"

    sentence_len = employee.sentence_length_label || "보통"

    response = "#{greeting}! #{greeting == "안녕" ? "" : "사장님을 대신해서 안내드릴게요."}\n\n"
    response += "[#{employee.name}/#{employee.role_label}] '#{user_msg}' 관련 답변 (톤: #{employee.tone}, #{sentence_len}, 존칭: #{honorific})\n\n"
    response += "자연어 지시: #{employee.natural_language_instructions.to_s[0, 200]}\n\n"
    response += "추천 어휘: #{vocab.join(', ')}\n"
    response += "(실제 LLM 응답이 아닌 페르소나 시뮬레이션입니다. 실제 응답은 OpenAI/Anthropic API로 생성됩니다.)"

    { response: response, action: "reply", notice: "✓ 시뮬레이션 응답 생성됨" }
  end
end