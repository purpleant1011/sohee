#!/usr/bin/env ruby
# 바이름 청라점 데모 시드 — 운영형 AI 마케팅 직원 모델
# 실행: bin/rails runner script/seed_byreum.rb

puts "[byreum] starting seed..."

# 1. Account
acct = Account.find_or_initialize_by(slug: "byreum-cheongna")
acct.assign_attributes(
  name: "바이름 청라점",
  status: "active",
  settings_json: {
    region: "인천 청라",
    representative: "이아름",
    years_experience: 25,
    channels: {
      instagram: "https://www.instagram.com/studio_by.reum/",
      threads: "https://www.threads.com/@studio_by.reum",
      daangn: "https://www.daangn.com/kr/local-profile/%EB%B0%94%EC%9D%B4%EB%A6%84-qfm5ujuvd65o/",
      blog: "https://blog.naver.com/larlds",
      place: "https://naver.me/5xgJJEBa",
      kakao: "kakao_1on1"
    },
    test_accounts_only: true,
    official_accounts_locked: true
  }
)
acct.save!
puts "✓ Account: #{acct.name} (id=#{acct.id})"

# 2. User (원장)
owner = acct.users.find_or_initialize_by(email_address: "byreum@soheeproject.example")
owner.assign_attributes(
  role: "owner",
  name: "이아름",
  password: "OwnerPass!23",
  password_confirmation: "OwnerPass!23",
  last_login_at: Time.current
)
owner.save!
puts "✓ Owner: #{owner.email_address} / OwnerPass!23"

# 2-1. Membership (Account.owner_user fallback이 정상 동작하도록 필수)
membership = acct.memberships.find_or_initialize_by(user: owner)
membership.role = "owner"
membership.save!
puts "✓ Membership: role=owner user=#{owner.email_address}"

# 3. BusinessProfile (RAG 기반)
bp = BusinessProfile.find_or_initialize_by(account_id: acct.id)
bp.assign_attributes(
  legal_name: "바이름 청라점",
  industry_code: "beauty",
  region_label: "인천 청라",
  owner_name: "이아름",
  address: "인천광역시 서구 청라동",
  business_hours_json: {
    "mon" => ["10:00", "20:00"],
    "tue" => ["10:00", "20:00"],
    "wed" => ["10:00", "20:00"],
    "thu" => ["10:00", "20:00"],
    "fri" => ["10:00", "20:00"],
    "sat" => ["10:00", "18:00"],
    "sun" => ["closed"]
  },
  holidays_json: ["매주 일요일", "법정공휴일"],
  products_json: [
    { "name" => "자연 눈썹", "price" => 150000, "duration" => "2시간", "description" => "얼굴형과 모발 상태에 맞춘 퍼스널 디자인" },
    { "name" => "퍼스널 디자인 눈썹", "price" => 250000, "duration" => "2.5시간", "description" => "25년 경력 대표 원장 직접 시술" },
    { "name" => "잔흔 보정", "price" => 200000, "duration" => "2시간", "description" => "기존 눈썹 시술의 색상·형태 조정" },
    { "name" => "눈썹 리터치", "price" => 80000, "duration" => "1시간", "description" => "시술 후 4~6주 보정" }
  ],
  services_json: ["눈썹 디자인 상담", "시술", "후기 관리", "사진 상담", "잔흔 보정"],
  faqs_json: [
    { "q" => "얼굴형에 맞게 디자인해 주시나요?", "a" => "네, 25년 경력의 대표 원장이 직접 얼굴형과 모발 상태를 분석한 뒤 퍼스널 디자인을 제안드립니다." },
    { "q" => "시술 시간이 얼마나 걸리나요?", "a" => "디자인 + 시술 포함 평균 2~2.5시간 정도 소요됩니다." },
    { "q" => "잔흔이 있어도 가능한가요?", "a" => "잔흔 상태에 따라 보정이 가능합니다. 사진으로 먼저 상담 후 결정하시는 것을 권합니다." },
    { "q" => "통증은 어느 정도인가요?", "a" => "개인차가 있지만, 마취 크림을 충분히 바른 뒤 시술해 대부분 편안하게 받으십니다." },
    { "q" => "회복기간이 얼마나 걸리나요?", "a" => "당일 일상생활은 가능하고, 색상이 안정화되는 데 약 2~3주 정도 소요됩니다." },
    { "q" => "예약은 어떻게 하나요?", "a" => "당근 프로필 또는 카카오 1:1 상담으로 사진과 함께 문의 주시면 맞춤 일정을 안내드립니다." }
  ],
  customer_anxieties_json: ["자연스러울까", "잔흔이 있을까", "어떤 디자인이 맞을까", "가격대가 궁금해", "회복기간이 얼마나 될까", "통증이 클까"],
  escalation_rules_json: ["잔흔 판단 요청", "피부 상태 상담", "시술 가능 여부 판단", "가격 조정 요청", "클레임", "환불 요청"],
  preferred_channels_json: ["instagram", "threads", "blog", "naver_place", "daangn", "kakao"],
  forbidden_phrases_json: ["100% 안전", "부작용 없음", "완벽 보장", "최저가", "무조건 가능", "즉시 시술"],
  forbidden_topics_json: ["경쟁 매장 비교", "타 시술 부작용 단정"],
  target_audience: "20-40대 여성, 인천 청라 지역 + 자연스러운 눈썹을 원하는 고객",
  differentiators: "25년 경력의 이아름 원장 직접 시술 · 얼굴형 맞춤 퍼스널 디자인 · 청라 지역 토종 매장"
)
bp.save!
puts "✓ BusinessProfile saved (id=#{bp.id})"

# 4. AI 직원 소희
emp = acct.ai_employees.find_or_initialize_by(persona_preset: "sohee_basic")
emp.assign_attributes(
  name: "소희",
  role_label: "바이름 AI 마케팅 직원",
  tone: "calm_professional",
  friendliness: 70,
  expertise_level: 90,
  proactiveness: 50,
  honorific: "semi",
  sentence_length: "medium",
  industry_expertise: "눈썹/문신, 뷰티",
  natural_language_instructions: <<~TXT.strip,
    바이름 청라점의 AI 마케팅 직원입니다.

    【페르소나】
    25년 경력의 이아름 원장님의 시술 철학을 기반으로 정중하고 차분하게 응대합니다.
    자연스러운 눈썹, 얼굴형 맞춤 디자인, 퍼스널 뷰티 컨설팅을 강조합니다.
    청라 지역 토종 매장이라는 점을 자부심으로 갖고, 단골 관계를 소중히 합니다.

    【응대 원칙】
    - 모르는 것은 솔직히 모른다고 답하고, 사진 상담을 통해 원장님께 인계한다
    - 잔흔·피부 상태·시술 가능 여부에 대한 판단은 절대 단정하지 않고 원장님께 인계한다
    - 가격은 "범위"로 안내하고 정확한 견적은 원장님께 인계한다
    - 25년 경력의 무게를 자신감 있게, 그러나 오만하지 않게 전달한다
    - 청라 지역 고객과의 관계를 소중히 여기며, 따뜻하지만 과하지 않게

    【절대 금지】
    "100% 안전", "부작용 없음", "무조건 자연스러움", "완벽 보장", "최저가", "싸게", "저렴이", "무조건 가능" 표현 금지.
  TXT
  work_days_json: %w[mon tue wed thu fri sat],
  work_hours_json: { "start" => "10:00", "end" => "20:00" },
  vocabulary_phrases_json: ["자연스러운", "퍼스널 디자인", "25년 경력", "얼굴형에 맞게", "잔흔 상담", "사진 상담", "청라 눈썹", "원장님이 직접", "퍼스널 뷰티 컨설팅"],
  forbidden_phrases_json: ["100% 안전", "부작용 없음", "무조건 자연스러움", "완벽 보장", "최저가", "싸게", "저렴이", "무조건 가능"],
  can_answer_topics_json: ["영업시간", "위치", "주차", "예약 방법", "가격 범위", "시술 시간", "블로그 글감", "전후사진 사용 동의"],
  must_handoff_topics_json: ["잔흔 판단", "피부 상태", "시술 가능 여부", "클레임", "가격 조정", "환불", "의료적 판단", "특이 체질/알레르기"],
  status: "active"
)
emp.save!
puts "✓ AI Employee (소희): #{emp.name} (id=#{emp.id})"

# 5. 바이름 채널 (운영형 설정)
byreum_channels = [
  { kind: "instagram", handle: "studio_by.reum", status: "active" },
  { kind: "threads", handle: "@studio_by.reum", status: "active" },
  { kind: "mastodon", handle: "byreum_cheongna@mastodon.social", status: "planned" },
  { kind: "blog", handle: "blog.naver.com/larlds", status: "active" },
  { kind: "naver_place", handle: "바이름 청라점", status: "active" },
  { kind: "daangn", handle: "바이름 청라점", status: "active" },
  { kind: "kakao_channel", handle: "바이름 청라점", status: "planned" }
]
byreum_channels.each do |attrs|
  ch = acct.channel_connections.find_or_initialize_by(kind: attrs[:kind], handle: attrs[:handle])
  ch.assign_attributes(
    status: attrs[:status],
    ai_employee: emp,
    connected_by_kind: "operator",
    scopes_json: attrs[:status] == "active" ? [{ "scope_kind" => "publish", "publish_allowed" => true }, { "scope_kind" => "comment_reply", "publish_allowed" => true }] : []
  )
  ch.save!
end
puts "✓ Channels: #{acct.channel_connections.count} (active=#{acct.channel_connections.where(status: 'active').count})"

# 6. 바이름 지식베이스 시드
byreum_ks = [
  { title: "바이름 가격표 (2026년 봄 업데이트)", kind: "product", tags: ["가격", "메뉴", "눈썹"], url: "https://blog.naver.com/larlds" },
  { title: "시술 전 안내 (준비물, 통증, 회복)", kind: "text", tags: ["FAQ", "시술 전", "안내"], url: nil },
  { title: "시술 후 관리 가이드", kind: "text", tags: ["후기", "회복", "관리"], url: nil },
  { title: "바이름 시술 후기 모음 (네이버 블로그)", kind: "url", tags: ["후기", "레퍼런스", "블로그"], url: "https://blog.naver.com/larlds" },
  { title: "바이름 인스타그램 레퍼런스", kind: "url", tags: ["인스타", "레퍼런스", "콘텐츠"], url: "https://www.instagram.com/studio_by.reum/" },
  { title: "잔흔 보정 상담 스크립트", kind: "text", tags: ["잔흔", "상담", "스크립트"], url: nil },
  { title: "자연 눈썹 FAQ", kind: "faq", tags: ["FAQ", "자연스러움"], url: nil },
  { title: "청라 지역 주차/오시는 길 안내", kind: "text", tags: ["위치", "주차", "청라"], url: nil }
]
byreum_ks.each do |attrs|
  ks = acct.knowledge_sources.find_or_initialize_by(title: attrs[:title])
  ks.assign_attributes(
    kind: attrs[:kind],
    url: attrs[:url],
    ai_employee: emp,
    language: "ko",
    ai_training_allowed: true,
    contains_personal_data: false,
    rights_confirmation: true,
    status: "ready",
    tags_json: attrs[:tags]
  )
  ks.save!
end
puts "✓ Knowledge Sources: #{acct.knowledge_sources.count}"

# 7. 바이름 어제/오늘 콘텐츠 시드
today = Time.current.to_date
7.times do |i|
  d = today - i
  state = case i
          when 0 then "scheduled"        # 오늘 게시 예정
          when 1 then "approved"          # 내일 게시 예정
          when 2..3 then "draft"           # 초안
          else "published"
          end
  kind = ["feed", "reel_script", "blog", "place_post"].sample
  ci = acct.content_items.find_or_initialize_by(title: "[바이름] #{d.strftime('%m/%d')} #{kind} 초안")
  ci.assign_attributes(
    body: "[바이름 청라점] 25년 경력 이아름 원장이 직접 시술하는 자연스러운 눈썹 디자인.\n얼굴형과 모발 상태에 맞춘 퍼스널 디자인으로, 청라 지역 고객분들의 단골 신뢰를 받고 있습니다.\n#청라눈썹 #자연스러운눈썹 #바이름청라점 #눈썹시술 #25년경력 #퍼스널디자인",
    content_kind: kind,
    state: state,
    safety_state: "passed",
    ai_employee: emp,
    scheduled_at: d.to_time + 14.hours,
    published_at: state == "published" ? d.to_time + 14.hours : nil,
    metadata_json: { auto_generated: true, persona: "sohee_basic" }
  )
  ci.save!
end
puts "✓ Content Items: #{acct.content_items.count}"

# 8. 바이름 문의 시드 (기초응대 vs 원장님 인계)
inquiries = [
  { kind: "faq", subject_kind: "가격", state: "replied", summary: "자연 눈썹 가격 문의", handled_by: "sohee" },
  { kind: "photo_consult", subject_kind: "잔흔", state: "new", summary: "기존 눈썹 잔흔 사진 상담 요청", handled_by: "handoff" },
  { kind: "pricing", subject_kind: "가격 조정", state: "new", summary: "가격 조정 가능한지 문의", handled_by: "handoff" },
  { kind: "faq", subject_kind: "영업시간", state: "replied", summary: "오늘 영업시간 문의", handled_by: "sohee" },
  { kind: "reservation", subject_kind: "예약", state: "replied", summary: "이번 주 토요일 예약 문의", handled_by: "sohee" },
  { kind: "spam", subject_kind: "광고", state: "spam", summary: "무관한 광고성 DM", handled_by: "blocked" }
]
inquiries.each do |attrs|
  inq = Inquiry.find_or_initialize_by(account: acct, summary: attrs[:summary])
  inq.assign_attributes(
    subject_kind: attrs[:subject_kind],
    state: attrs[:state],
    metadata_json: { kind: attrs[:kind], handled_by: attrs[:handled_by], source_channel: "instagram" }
  )
  inq.save!
end
puts "✓ Inquiries: #{acct.inquiries.count}"

# 9. 자동화 규칙 + 스케줄 (바이름 운영 루틴)
[
  { name: "바이름 매주 화/금 인스타 피드", intent_kind: "post", cron: "0 14 * * 2,5", kind: "instagram" },
  { name: "바이름 매주 목요일 스레드", intent_kind: "post", cron: "0 11 * * 4", kind: "threads" },
  { name: "바이름 매주 월요일 블로그 초안", intent_kind: "post", cron: "0 10 * * 1", kind: "blog" },
  { name: "바이름 매일 저녁 일일 보고", intent_kind: "report", cron: "0 21 * * *", kind: "report" },
  { name: "바이름 매주 일요일 주간 리포트", intent_kind: "report", cron: "0 20 * * 0", kind: "report" }
].each do |attrs|
  rule = acct.automation_rules.find_or_initialize_by(name: attrs[:name])
  rule.assign_attributes(
    ai_employee: emp,
    intent_kind: attrs[:intent_kind],
    natural_language: "바이름 청라점의 #{attrs[:name]} 운영 루틴입니다.",
    status: "active"
  )
  rule.save!
  sched = rule.automation_schedules.first || rule.automation_schedules.build
  sched.assign_attributes(
    account: acct,
    cadence: "cron",
    cron_expression: attrs[:cron],
    next_run_at: Time.current + 1.hour
  )
  sched.save!
end
puts "✓ Automation Rules: #{acct.automation_rules.count} / Schedules: #{AutomationSchedule.where(account_id: acct.id).count}"

puts "\n[byreum] ✅ 바이름 청라점 데모 시드 완료!"
puts "  사업장: #{acct.name}"
puts "  원장 로그인: #{owner.email_address} / OwnerPass!23"
puts "  AI 직원: #{emp.name} (#{emp.role_label})"
puts "  채널: #{acct.channel_connections.count} (active=#{acct.channel_connections.where(status: 'active').count})"
puts "  지식: #{acct.knowledge_sources.count}건"
puts "  콘텐츠: #{acct.content_items.count}건"
puts "  문의: #{acct.inquiries.count}건"
puts "  자동화: #{acct.automation_rules.count}건"