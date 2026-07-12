# Seeds for development only. All synthetic data.

puts "[seeds] starting..."

# === Platform staff ===
admin = PlatformStaff.find_or_initialize_by(email_address: "platform-admin@workmori.example")
admin.assign_attributes(
  name: "가칭 운영자",
  role: "super_admin",
  password: "SuperSecret!23",
  password_confirmation: "SuperSecret!23"
)
admin.save! unless admin.persisted?

# Dev-login alias used by README / guides / verify scripts.
ops = PlatformStaff.find_or_initialize_by(email_address: "ops@workmori.example")
ops.assign_attributes(
  name: "데모 운영자",
  role: "ops",
  password: "OpsPass!23",
  password_confirmation: "OpsPass!23"
)
ops.save! unless ops.persisted?

puts "[seeds] platform-admin: platform-admin@workmori.example  (password: SuperSecret!23)"
puts "[seeds] platform-ops   : ops@workmori.example            (password: OpsPass!23)"

# === Industry templates (public, non-customer seeds) ===
INDUSTRY_SEEDS = [
  { code: "skincare",     industry_kind: "beauty",  name: "피부관리 / 화장품" },
  { code: "fnb-cafe",     industry_kind: "fnb",     name: "카페 / 음료" },
  { code: "shop-retail",  industry_kind: "retail",  name: "소매/편집숍" },
  { code: "bookkeeping",  industry_kind: "service", name: "세무 / 회계" },
  { code: "edu-local",    industry_kind: "edu",     name: "학원 / 교육" },
  { code: "etc-service",  industry_kind: "service", name: "기타 서비스" }
].freeze

INDUSTRY_SEEDS.each do |seed|
  rec = IndustryTemplate.find_or_initialize_by(industry_code: seed[:code])
      rec.assign_attributes(
    slug: seed[:code],
    industry_kind: seed[:industry_kind],
    display_name: seed[:name],
    version: "v1",
    starter_brand_profile: {},
    starter_ai_employee:    { display_name: "#{seed[:name]} AI 직원", tone: "calm_polite", honorific: "honorific" },
    starter_automations:    [{ name: "주간 다이제스트 자동 생성", intent_kind: "weekly_digest" }],
    starter_guardrails:     [{ patterns: %w[100% 즉시 확실 보장], action: "block" }]
  )
  rec.slug ||= seed[:code]
  rec.industry_kind ||= seed[:industry_kind]
  rec.save! unless rec.persisted?
end

# Backfill slug + industry_kind for any existing rows that pre-date the column adds.
IndustryTemplate.where(slug: nil).find_each do |rec|
  rec.update_column(:slug, rec.industry_code)
end
IndustryTemplate.where(industry_kind: nil).find_each do |rec|
  fallback = INDUSTRY_SEEDS.find { |s| s[:code] == rec.industry_code }
  rec.update_column(:industry_kind, fallback ? fallback[:industry_kind] : "general")
end
IndustryTemplate.where(display_name: nil).find_each do |rec|
  fallback = INDUSTRY_SEEDS.find { |s| s[:code] == rec.industry_code }
  rec.update_column(:display_name, fallback ? fallback[:name] : rec.industry_code)
end

# === Plans ===
plan_beta = Plan.find_or_initialize_by(code: "beta-monthly")
plan_beta.assign_attributes(
  name: "베타 월정액",
  description: "베타 기간 월정액 요금제 (가칭).",
  monthly_price_krw: 300_000,
  monthly_price_vat_krw: 30_000,
  features: %w[ai_employee accounts_1 weekly_reports basic_automation],
  active: true
)
plan_beta.save! unless plan_beta.persisted?

plan_addon = Plan.find_or_initialize_by(code: "add-on-pack")
plan_addon.assign_attributes(
  name: "월정액 + 추가 패키지",
  description: "월정액 + 추가 패키지.",
  monthly_price_krw: 450_000,
  monthly_price_vat_krw: 45_000,
  features: %w[ai_employee accounts_1 weekly_reports extended_automation priority_support],
  active: true
)
plan_addon.save! unless plan_addon.persisted?

# === 바이름 전용 사업자 계정 (byreum) ===
byreum_acct = Account.find_or_initialize_by(slug: "byreum")
byreum_acct.assign_attributes(
  name: "바이름",
  status: "active",
  operator_managed: true,
  operator_managed_by_email: "platform-admin@workmori.example",
  timezone: "Asia/Seoul",
  country: "KR",
  settings_json: { onboarding_state: "byreum-seed", consents: { marketing: false } }
)
byreum_acct.save! unless byreum_acct.persisted?

byreum_user = User.find_or_initialize_by(email_address: "byreum@soheeproject.example")
byreum_user.assign_attributes(
  account: byreum_acct,
  name: "바이름",
  role: "owner",
  locale: "ko",
  password: "pass1234!!",
  password_confirmation: "pass1234!!"
)
byreum_user.save! unless byreum_user.persisted?

Membership.find_or_create_by!(user: byreum_user, account: byreum_acct) { |m| m.role = "owner" }

byreum_bp = BusinessProfile.find_or_initialize_by(account: byreum_acct)
byreum_bp.assign_attributes(
  industry_code: "beauty",
  industry_subcategory: "skincare",
  legal_name: "바이름",
  trade_name: "바이름",
  owner_name: "바이름",
  phone: "010-0000-0000",
  public_email: "byreum@example.com",
  address: "—",
  region_label: "초기 파트너 매장",
  timezone: "Asia/Seoul",
  brand_intro: "초기 파트너 사업장.",
  onboarding_step: 1,
  onboarding_complete: false,
  operator_managed: true,
  business_hours_json: { mon: "10:00-20:00", tue: "10:00-20:00", wed: "closed", thu: "10:00-20:00", fri: "10:00-20:00", sat: "10:00-18:00", sun: "closed" },
  products_json: [{ name: "기본관리", price_krw: 70000 }],
  services_json: [{ name: "기본관리", duration_min: 60 }],
  faqs_json: [{ q: "예약은 어떻게 하나요?", a: "전화 또는 카카오 채널로 안내드립니다." }],
  forbidden_phrases_json: %w[100% 안전 보장 의사의진료],
  forbidden_topics_json: %w[시술후100%안전 보장의료기관할인],
  preferred_channels_json: %w[blog naver],
  escalation_rules_json: [{ topic: "환불/클레임", handoff_to: "human" }]
)
byreum_bp.save! unless byreum_bp.persisted?

# === Demo account + owner (development only) ===
acct = Account.find_or_initialize_by(slug: "demo-skincare")
acct.assign_attributes(
  name: "데모 피부관리원",
  status: "active",
  operator_managed: true,
  operator_managed_by_email: "platform-admin@workmori.example",
  timezone: "Asia/Seoul",
  country: "KR",
  settings_json: { onboarding_state: "demo-seed", consents: { marketing: false } }
)
acct.save! unless acct.persisted?

owner = User.find_or_initialize_by(email_address: "owner@demo.example")
owner.assign_attributes(
  account: acct,
  name: "김사장",
  role: "owner",
  locale: "ko",
  password: "OwnerPass!23",
  password_confirmation: "OwnerPass!23"
)
owner.save! unless owner.persisted?

Membership.find_or_create_by!(user: owner, account: acct) { |m| m.role = "owner" }

bp = BusinessProfile.find_or_initialize_by(account: acct)
bp.assign_attributes(
  industry_code: "beauty",
  industry_subcategory: "skincare",
  legal_name: "데모피부관리원",
  trade_name: "데모 피부관리원",
  owner_name: "김사장",
  phone: "010-0000-0000",
  public_email: "demo-skincare@example.com",
  address: "강원도 청라시 가칭동 123",
  region_label: "강원 / 청라",
  timezone: "Asia/Seoul",
  brand_intro: "데모용 시드 데이터. 실제 계정과 분리해주세요.",
  onboarding_step: 2,
  onboarding_complete: false,
  operator_managed: true,
  business_hours_json: { mon: "10:00-20:00", tue: "10:00-20:00", wed: "closed", thu: "10:00-20:00", fri: "10:00-20:00", sat: "10:00-18:00", sun: "closed" },
  products_json: [{ name: "기본관리", price_krw: 70000 }],
  services_json: [{ name: "기본관리", duration_min: 60 }],
  faqs_json: [{ q: "예약은 어떻게 하나요?", a: "전화 또는 카카오 채널로 안내드립니다." }],
  forbidden_phrases_json: %w[100% 안전 보장 의사의진료],
  forbidden_topics_json: %w[시술후100%안전 보장의료기관할인],
  preferred_channels_json: %w[blog naver],
  escalation_rules_json: [{ topic: "환불/클레임", handoff_to: "human" }]
)
bp.save! unless bp.persisted?

employee = AiEmployee.find_or_initialize_by(account: acct, name: "케이 마케팅")
employee.assign_attributes(
  role_label: "마케팅",
  industry_expertise: "skin_care",
  tone: "calm_professional",
  friendliness: 3,
  expertise_level: 3,
  proactiveness: 2,
  honorific: "formal",
  sentence_length: 60,
  forbidden_phrases_json: %w[100% 안전 보장 확실],
  can_answer_topics_json: %w[피부관리 예약 가격 FAQ 영업시간],
  must_handoff_topics_json: %w[환불 클레임 의료 민감피부],
  work_days_json: %w[mon tue wed thu fri sat],
  work_hours_json: { start: "10:00", end: "20:00" },
  daily_post_quota: 2,
  weekly_post_quota: 8,
  approval_mode: "owner_review",
  monthly_token_budget: 200_000,
  daily_token_budget: 10_000,
  monthly_cost_budget_krw: 50_000,
  daily_cost_budget_krw: 3_000,
  channel_behaviors_json: { blog: "long", naver: "short" },
  natural_language_instructions: "한국어로 정중하게 응답. 진실성 유지. 출처가 있으면 인용.",
  status: "active"
)
employee.save! unless employee.persisted?

# === Sample prompts (used by templates) ===
sample_prompts = [
  { code: "weekly_digest_v1", purpose: "weekly_digest", system_prompt: "주간 다이제스트 요원입니다.", user_prompt_template: "주제: {{topic}}", output_schema: "{ title: str, body: str, cta: str }" },
  { code: "reply_visitor_v1", purpose: "reply_visitor", system_prompt: "방문자 응대 요원입니다.", user_prompt_template: "방문자 메시지: {{message}}", output_schema: "{ reply: str, handoff: bool }" },
  { code: "classify_inquiry_v1", purpose: "classify_inquiry", system_prompt: "문의 분류 요원입니다.", user_prompt_template: "문의: {{body}}", output_schema: "{ kind: str, score: float }" }
]
sample_prompts.each do |cfg|
  rec = PromptTemplate.find_or_initialize_by(name: cfg[:code])
  rec.assign_attributes(
    version: "v1",
    purpose: cfg[:purpose],
    system_prompt: cfg[:system_prompt],
    user_prompt_template: cfg[:user_prompt_template],
    output_schema: cfg[:output_schema],
    active: true
  )
  rec.save! unless rec.persisted?
end

# === Model catalog (stub providers) ===
MODELS = [
  { code: "local-stub",         provider: "local", kind: "llm", display_name: "Local Stub",         active: true,
    api_model_name: "stub",     context_window: 4000,  max_output_tokens: 800,
    input_price_per_1k_krw: 0,  output_price_per_1k_krw: 0, image_price_per_unit_krw: 0,
    training_opt_out: true, data_residency_region: "kr", capabilities: { stub: true } },
  { code: "openai-gpt-4o",      provider: "openai", kind: "llm", display_name: "OpenAI gpt-4o",     active: false,
    api_model_name: "gpt-4o",   context_window: 128000, max_output_tokens: 4096,
    input_price_per_1k_krw: 5,  output_price_per_1k_krw: 15, image_price_per_unit_krw: 0,
    training_opt_out: true, data_residency_region: "us", capabilities: { vision: true } },
  { code: "anthropic-sonnet",   provider: "anthropic", kind: "llm", display_name: "Anthropic Sonnet", active: false,
    api_model_name: "claude-3-5-sonnet", context_window: 200000, max_output_tokens: 8000,
    input_price_per_1k_krw: 5, output_price_per_1k_krw: 25, image_price_per_unit_krw: 0,
    training_opt_out: true, data_residency_region: "us", capabilities: { vision: true } }
]
MODELS.each do |m|
  rec = ModelCatalogEntry.find_or_initialize_by(code: m[:code])
  rec.assign_attributes(m.except(:code))
  rec.save! unless rec.persisted?
end

# === Feature flags ===
[
  { key: "invite_only_signup",         enabled: false, value: false },
  { key: "show_ai_employee_v2",        enabled: true,  value: true },
  { key: "channels_blog_default",      enabled: true,  value: true },
  { key: "channels_instagram_default", enabled: true,  value: true }
].each do |flag|
  rec = FeatureFlag.find_or_initialize_by(key: flag[:key], account_id: nil)
  rec.assign_attributes(enabled: flag[:enabled], value: flag[:value])
  rec.save! unless rec.persisted?
end

# === Demo automation rule + schedule ===
rule = AutomationRule.find_or_initialize_by(account: acct, name: "주간 다이제스트 자동 게시")
rule.assign_attributes(
  ai_employee: employee,
  intent_kind: "post",
  natural_language: "매주 화요일 9시에 한 주 인기 FAQ를 정리해 초안을 작성해 검수 채널에 올려주세요.",
  structured_plan: { cadence: "weekly_tue_9am", topic: "popular_faqs" },
  constraints: { requires_human_approval: true, max_per_week: 1, channels: ["blog"] },
  status: "active"
)
rule.save! unless rule.persisted?

sched = AutomationSchedule.find_or_initialize_by(automation_rule: rule)
sched.assign_attributes(
  account: acct,
  cadence: "weekly",
  cron_expression: "30 9 * * MON",
  next_run_at: 7.days.from_now,
  quiet_hours: { start: "20:00", end: "09:00" }
)
sched.save! unless sched.persisted?

# === Notification ===
Notification.find_or_create_by!(account: acct, kind: "welcome") do |n|
  n.title = "소희 프로젝트 가입을 환영합니다"
  n.body = "데모 시드 데이터입니다. 실제 운영 계정과 분리하세요."
  n.severity = "low"
end

# === Announcements (전역 공지) ===
admin_staff = PlatformStaff.find_by(email_address: "platform-admin@workmori.example")

# 1) 환영 공지
ann_welcome = Announcement.find_or_initialize_by(kind: "info", title: "소희 프로젝트 정식 운영을 시작합니다")
ann_welcome.assign_attributes(
  body: "안녕하세요, 사장님.\n\n소희 프로젝트가 정식 운영을 시작합니다. 소희는 사장님의 일을 기억하고 스스로 이어가는 AI 직원입니다.\n\n• AI 직원 소희의 페르소나를 자유롭게 설정 (톤, 어휘, 금지어, 인계 규칙)\n• 사업장 자료 업로드 → 소희가 즉시 학습\n• AI 직원 자동 응대 (Instagram, Threads, Mastodon, Kakao, Naver)\n• 주간 자동 일정 + 검수 + 발행\n• 실시간 결과 리포트\n\n궁금한 점은 운영팀(support@soheeproject.example)으로 연락 주세요.",
  audience: "all",
  status: "published",
  published_at: Time.current,
  created_by_platform_staff: admin_staff,
  priority: 10
)
ann_welcome.save!

# 2) 신규 기능 안내
ann_feature = Announcement.find_or_initialize_by(kind: "changelog", title: "신규 기능: Instagram/Threads 자동 댓글 응대")
ann_feature.assign_attributes(
  body: "Instagram과 Threads 댓글에 AI 직원이 자동으로 응대하는 기능이 추가되었습니다.\n\n채널 설정 → 'Engagement 자동응대' 메뉴에서 활성화할 수 있습니다.\n\n• 자동 응대 톤은 AI 직원 페르소나를 따릅니다\n• 위험 키워드(환불, 부작용, 민원 등) 감지 시 사람에게 자동 인계됩니다\n• 인사이트(팔로워/리치/노출)는 6시간마다 자동 수집됩니다",
  audience: "all",
  status: "published",
  published_at: 1.day.ago,
  created_by_platform_staff: admin_staff,
  priority: 5
)
ann_feature.save!

# 3) 업로드 제한 안내
ann_limit = Announcement.find_or_initialize_by(kind: "warning", title: "이미지 업로드 권장 사양 안내")
ann_limit.assign_attributes(
  body: "Instagram 게시물의 최적 해상도는 1080×1080 (정사각형) 또는 1080×1350 (세로)입니다.\n\n더 큰 파일(2MB 이상)은 발행 시간이 길어질 수 있으니 가능하면 사전 최적화 부탁드립니다.\n\n질문: support@workmori.example",
  audience: "all",
  status: "published",
  published_at: 3.days.ago,
  created_by_platform_staff: admin_staff,
  priority: 0
)
ann_limit.save!

puts "[seeds] done. Sign-in (business app): owner@demo.example / OwnerPass!23"
puts "[seeds] done. Sign-in (byreum): byreum@soheeproject.example / pass1234!!  (slug: byreum)"
puts "[seeds] done. Sign-in (platform admin): platform-admin@workmori.example / SuperSecret!23"
puts "[seeds] Announcements: #{Announcement.count} (published: #{Announcement.where(status: 'published').count})"

# ============================================================
# Discord 워크스페이스 시드 (P3.5, 2026-07-12)
# ============================================================
# 사용자가 생성한 "소희" Discord 서버 (guild_id) ↔ 데모 사업장 연결.
# ENV DISCORD_GUILD_ID / DISCORD_CHANNEL_ID 가 .env에 있을 때만 활성.
if ENV["DISCORD_GUILD_ID"].present? && ENV["DISCORD_CHANNEL_ID"].present?
  ws = DiscordWorkspace.find_or_initialize_by(guild_id: ENV["DISCORD_GUILD_ID"])
  ws.assign_attributes(
    business_profile_id: bp.id,
    guild_name: "소희",
    default_channel_id: ENV["DISCORD_CHANNEL_ID"],
    default_channel_name: "소희-소통",
    status: "active",
    connected_at: Time.current
  )
  ws.save!
  puts "[seeds] DiscordWorkspace: ##{ws.id} guild=#{ws.guild_id} status=#{ws.status}"
else
  puts "[seeds] DiscordWorkspace skipped (DISCORD_GUILD_ID / DISCORD_CHANNEL_ID missing in ENV)"
end
