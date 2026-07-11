# 중복 데이터 모델 조사 (Duplicate Data Sources Audit)

조사 일시: 2026-07-12
대상: `app/models/*.rb`, `db/schema.rb`

---

## 1. 결론 요약

**핵심 문제**: 동일한 개념이 두 곳에 저장되어 있다.
- 정식 모델 (`Product`, `Service`, `Faq`, `ChannelConnection`, `RuntimeConfig`, ...) — 별도 테이블, 검증·관계·조회 가능
- `BusinessProfile.products_json` / `services_json` / `faqs_json` (TEXT 컬럼) — 동일 정보를 문자열로 저장

이 중복은 **검수 흐름과 운영자 콘솔 추가를 막는 가장 큰 기술 부채**다.

---

## 2. 중복 매트릭스

| 데이터 | 정식 모델 | json 컬럼 (BusinessProfile) | 동시 사용? | 누가 쓰나 |
|--------|---------|--------------------------|----------|---------|
| 가격표 (Product) | ✅ `Product` (id, account_id, name, price, ...) | ✅ `BusinessProfile.products_json` | **둘 다** | Products 컨트롤러 + BusinessProfile 컨트롤러 |
| 서비스 (Service) | ✅ `Service` | ✅ `BusinessProfile.services_json` | **둘 다** | Services 컨트롤러 + BusinessProfile 컨트롤러 |
| FAQ | ✅ `Faq` (active, risk_level, question, answer, tags_json) | ✅ `BusinessProfile.faqs_json` | **둘 다** | Faqs 컨트롤러 + BusinessProfile 컨트롤러 |
| 영업시간 | ❌ 모델 없음 | ✅ `BusinessProfile.business_hours_json` | json만 | BusinessProfile |
| 휴일 | ❌ 모델 없음 | ✅ `BusinessProfile.holidays_json` | json만 | BusinessProfile |
| 금지어 | ❌ 모델 없음 | ✅ `BusinessProfile.forbidden_phrases_json` | json만 | BusinessProfile + 셋업 준비도 |
| 금지 주제 | ❌ 모델 없음 | ✅ `BusinessProfile.forbidden_topics_json` | json만 | BusinessProfile |
| 인계 규칙 | ❌ 모델 없음 | ✅ `BusinessProfile.escalation_rules_json` | json만 | BusinessProfile + 셋업 준비도 |
| 선호 채널 | ✅ `ChannelConnection` | ✅ `BusinessProfile.preferred_channels_json` | **둘 다** | Channels + BusinessProfile |
| 페르소나 주제 (can_answer/must_handoff) | ❌ 모델 없음 | ❌ json 없음 — **AiEmployee**에 있음 | AiEmployee만 | ai_employees 컨트롤러 |

---

## 3. BusinessProfile 스키마 (`db/schema.rb:285-315`)

```ruby
create_table "business_profiles", force: :cascade do |t|
  t.bigint "account_id"
  t.string "legal_name"               # 운영 등록명
  t.string "trade_name"               # 상호
  t.string "industry_code"            # 미용/네일/...
  t.string "industry_subcategory"
  t.string "owner_name"
  t.string "business_registration_number"
  t.string "phone"
  t.string "public_email"
  t.text "address"
  t.string "region_label"
  t.text "business_hours_json", default: "{}"   # ← json
  t.text "holidays_json", default: "[]"          # ← json
  t.text "timezone", default: "Asia/Seoul"
  t.text "brand_intro"
  t.text "products_json", default: "[]"          # ← Product 중복
  t.text "services_json", default: "[]"          # ← Service 중복
  t.text "faqs_json", default: "[]"              # ← Faq 중복
  t.text "customer_anxieties_json", default: "[]"
  t.text "target_audience"
  t.text "differentiators"
  t.text "forbidden_phrases_json", default: "[]"  # ← 정규화 후보
  t.text "forbidden_topics_json", default: "[]"   # ← 정규화 후보
  t.text "escalation_rules_json", default: "[]"   # ← 정규화 후보
  t.text "preferred_channels_json", default: "[]" # ← ChannelConnection 중복
  t.integer "onboarding_step"
  t.boolean "onboarding_complete"
  t.boolean "operator_managed"
  t.datetime "created_at", updated_at
end
```

**모델 정의** (`app/models/business_profile.rb`):

```ruby
json_attr :business_hours_json, default: {}
json_attr :holidays_json, default: ->{ [] }
json_attr :products_json, default: ->{ [] }
json_attr :services_json, default: ->{ [] }
json_attr :faqs_json, default: ->{ [] }
json_attr :customer_anxieties_json, default: ->{ [] }
json_attr :forbidden_phrases_json, default: ->{ [] }
json_attr :forbidden_topics_json, default: ->{ [] }
json_attr :escalation_rules_json, default: ->{ [] }
json_attr :preferred_channels_json, default: ->{ [] }
json_attr :settings_json, default: ->{ {} }
```

---

## 4. Product / Service / Faq 정식 모델 (현재 사용)

### Product (`app/models/product.rb`)

```ruby
class Product < ApplicationRecord
  include AccountScoped
  belongs_to :account
  validates :name, presence: true
end
```

테이블 컬럼 (schema 확인):
- id, account_id, name, price_cents, description, position, etc.

→ CRUD 라우트: `GET/POST /app/products`, `GET/PATCH/DELETE /app/products/:id`
→ 9 액션, 9 뷰 (new/edit/show/index 포함)
→ 사업자가 가격표 입력 → 표시 가능
→ **그런데** BusinessProfile.products_json에도 같은 데이터 저장 (운영팀이 채움)

### Service (`app/models/service.rb`)

```ruby
class Service < ApplicationRecord
  include AccountScoped
  belongs_to :account
  validates :name, presence: true
end
```

→ 동일 패턴, 9 액션, 9 뷰

### Faq (`app/models/faq.rb`)

```ruby
class Faq < ApplicationRecord
  include AccountScoped
  json_attr :tags_json, default: ->{ [] }
  belongs_to :account
  belongs_to :ai_employee, optional: true
  validates :question, :answer, presence: true
  validates :risk_level, inclusion: { in: %w[low medium high] }
end
```

→ 위험도 라벨 (low/medium/high) — 매장 정보 섹션에 자연어 노출 필요

---

## 5. 셋업 준비도가 의존하는 JSON 컬럼 (`App::BaseController#load_setup_readiness`)

```ruby
bp_ok = bp.persisted? &&
        bp.brand_intro.to_s.length > 10 &&
        bp.forbidden_phrases_json.to_s.length > 5 &&
        bp.operator_managed

# RAG 카운트
rag_count = @current_account.knowledge_sources.where(status: "ready").count

# 페르소나 카운트
persona_ok = @current_account.ai_employees.where(status: "active").any? do |emp|
  emp.persona_preset.present? && emp.natural_language_instructions.to_s.length > 50
end

# 채널 카운트
channel_ok = @current_account.channel_connections.where(status: "connected").count >= 1

# FAQ 카운트
faq_count = @current_account.faqs.where(active: true).count >= 3

# 인계 규칙 (json 문자열 길이 검사)
handoff_ok = bp.escalation_rules_json.to_s.length > 5

# 콘텐츠 검수 카운트
review_ok = @current_account.content_items.where(state: "approved").count >= 5
```

**문제**:
- `bp.escalation_rules_json.to_s.length > 5` — 데이터 구조를 안 보고 길이만 검사. 빈 배열도 통과.
- `bp.forbidden_phrases_json.to_s.length > 5` — 동일. **"\"\""도 길이 2라 통과**

---

## 6. 데이터 정합성 시나리오

### 시나리오 A: Product는 있지만 BusinessProfile.products_json은 비어있음
- 사업자 화면 `/app/products`에서 5개 상품 보임
- 매장 정보 `/app/business_profile`에서 가격표 0건 (json 비어있음)
- 컨텐츠 생성 시점 → 둘 다 읽으면 어느 쪽이 우선? (현재 코드 추적 필요)
- 운영팀이 셋업 시 json만 채우고 Product 미생성 가능 → 가격표 화면 비어있음

### 시나리오 B: BusinessProfile.faqs_json은 있지만 Faq 모델은 비어있음
- 셋업 준비도 `faq_count >= 3` → 실패
- 매장 정보 FAQ 섹션 → 표시 안 됨
- 운영자 콘솔 검수 큐에 안 잡힘

### 시나리오 C: 동일 FAQ가 두 곳에 저장되어 운영자가 수정
- Faq 모델에서 수정 → BusinessProfile.faqs_json은 그대로
- 답변 변경 시 어느 쪽이 우선? (`content_items` 생성 시 두 곳 모두 읽을 가능성)

---

## 7. 리뉴얼 결정

### 7.1 단일 진실 공급원 (Single Source of Truth)

| 데이터 | 진실 공급원 (리뉴얼) | json 컬럼 처리 |
|--------|------------------|-------------|
| 가격표 | **`Product` 모델** | `BusinessProfile.products_json` 제거 + 마이그레이션 |
| 서비스 | **`Service` 모델** | `BusinessProfile.services_json` 제거 + 마이그레이션 |
| FAQ | **`Faq` 모델** | `BusinessProfile.faqs_json` 제거 + 마이그레이션 |
| 영업시간 | **`BusinessHour` 모델** (신규) | json → 정규화 |
| 휴일 | **`BusinessHoliday` 모델** (신규) | json → 정규화 |
| 금지어 | **`ForbiddenPhrase` 모델** (신규) | json → 정규화 |
| 금지 주제 | **`ForbiddenTopic` 모델** (신규) | json → 정규화 |
| 인계 규칙 | **`EscalationRule` 모델** (신규) | json → 정규화 |
| 선호 채널 | **`ChannelConnection` 모델** | json 제거 |

### 7.2 신규 모델 (마이그레이션 + 인덱스)

```ruby
# db/migrate/xxx_create_business_hours.rb
create_table :business_hours do |t|
  t.references :business_profile, null: false
  t.integer :day_of_week, null: false   # 0=Sun..6=Sat
  t.time :open_time, null: false
  t.time :close_time, null: false
  t.boolean :closed, default: false
  t.timestamps
end

create_table :business_holidays do |t|
  t.references :business_profile, null: false
  t.date :date, null: false
  t.string :label
  t.timestamps
end

create_table :forbidden_phrases do |t|
  t.references :business_profile, null: false
  t.string :phrase, null: false
  t.string :reason
  t.timestamps
end

create_table :forbidden_topics do |t|
  t.references :business_profile, null: false
  t.string :topic, null: false
  t.text :reason
  t.timestamps
end

create_table :escalation_rules do |t|
  t.references :business_profile, null: false
  t.string :trigger, null: false   # "pricing", "medical", "complaint", ...
  t.text :message_to_user
  t.text :internal_note
  t.integer :position, default: 0
  t.timestamps
end
```

### 7.3 마이그레이션 전략

```ruby
# db/migrate/yyy_backfill_business_profile_jsons.rb
class BackfillBusinessProfileJsons < ActiveRecord::Migration[8.0]
  def up
    BusinessProfile.reset_column_information
    BusinessProfile.find_each do |bp|
      # products_json → Product
      Array(bp.products_json).each do |p|
        bp.account.products.create!(
          name: p["name"] || p[:name] || "이름 없음",
          price_cents: p["price_cents"] || p[:price_cents] || 0,
          description: p["description"] || p[:description]
        )
      end

      # faqs_json → Faq
      Array(bp.faqs_json).each do |f|
        bp.account.faqs.create!(
          question: f["question"] || f[:question] || "질문 없음",
          answer: f["answer"] || f[:answer] || "",
          risk_level: f["risk_level"] || "low"
        )
      end

      # forbidden_phrases_json → ForbiddenPhrase
      Array(bp.forbidden_phrases_json).each do |phrase|
        bp.forbidden_phrases.create!(phrase: phrase.to_s)
      end

      # forbidden_topics_json → ForbiddenTopic
      Array(bp.forbidden_topics_json).each do |topic|
        bp.forbidden_topics.create!(topic: topic.to_s)
      end

      # escalation_rules_json → EscalationRule
      Array(bp.escalation_rules_json).each_with_index do |r, i|
        bp.escalation_rules.create!(
          trigger: r["trigger"] || r[:trigger] || "general",
          message_to_user: r["message_to_user"] || r[:message_to_user],
          internal_note: r["internal_note"] || r[:internal_note],
          position: i
        )
      end

      # business_hours_json → BusinessHour
      parsed = bp.business_hours_json.is_a?(String) ? JSON.parse(bp.business_hours_json) : bp.business_hours_json
      (parsed || {}).each do |day, hours|
        bp.business_hours.create!(
          day_of_week: %w[sun mon tue wed thu fri sat].index(day.to_s[0..2]),
          open_time: hours["open"] || hours[:open] || "09:00",
          close_time: hours["close"] || hours[:close] || "18:00",
          closed: hours["closed"] || false
        )
      end
    end
  end

  def down
    # 롤백은 별도 마이그레이션에서 처리
  end
end
```

### 7.4 컬럼 제거 (다음 단계)

```ruby
# db/migrate/zzz_remove_legacy_json_columns_from_business_profiles.rb
class RemoveLegacyJsonColumnsFromBusinessProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :business_profiles, :products_json
    remove_column :business_profiles, :services_json
    remove_column :business_profiles, :faqs_json
    remove_column :business_profiles, :forbidden_phrases_json
    remove_column :business_profiles, :forbidden_topics_json
    remove_column :business_profiles, :escalation_rules_json
    remove_column :business_profiles, :preferred_channels_json
    remove_column :business_profiles, :business_hours_json
    remove_column :business_profiles, :holidays_json
    remove_column :business_profiles, :customer_anxieties_json
  end
end
```

### 7.5 셋업 준비도 재작성

```ruby
def load_setup_readiness
  checks = []

  bp = @current_business_profile
  bp_ok = bp.persisted? && bp.brand_intro.to_s.length > 10 && bp.operator_managed
  checks << [t("setup.business_profile"), bp_ok]

  # 자료 N건
  doc_count = bp.knowledge_sources.where(status: "ready").count
  checks << [t("setup.knowledge_count", n: doc_count), doc_count >= 3]

  # 소희 페르소나
  persona_ok = bp.ai_employees.where(status: "active").any? do |emp|
    emp.persona_preset.present? && emp.natural_language_instructions.to_s.length > 50
  end
  checks << [t("setup.sohee_persona"), persona_ok]

  # 공식 채널
  channel_count = bp.channel_connections.where(status: "connected").count
  checks << [t("setup.channels_count", n: channel_count), channel_count >= 1]

  # FAQ 활성
  faq_count = bp.faqs.where(active: true).count
  checks << [t("setup.faqs_count", n: faq_count), faq_count >= 3]

  # 인계 규칙 (실제 row 존재)
  rule_count = bp.escalation_rules.count
  checks << [t("setup.handoff_rules", n: rule_count), rule_count >= 1]

  # 검수 합격
  review_count = bp.content_items.where(state: "approved").count
  checks << [t("setup.reviewed_count", n: review_count), review_count >= 5]

  ...
end
```

→ 라벨은 자연어 + 한국어 매핑 (i18n) + raw state 제거.

---

## 8. 우선순위

### P0 (즉시)
- Product / Service / Faq 이중 저장 통합 — 뷰·컨트롤러는 Product/Service/Faq만 사용
- BusinessProfile.products_json/services_json/faqs_json 컬럼 제거 (마이그레이션 후)

### P1 (신규 IA와 동시)
- 영업시간/휴일 정규화 → BusinessHour / BusinessHoliday
- 금지어/금지 주제 정규화 → ForbiddenPhrase / ForbiddenTopic
- 인계 규칙 정규화 → EscalationRule

### P2 (정식 셋업 마법사 시)
- 셋업 준비도 재작성 (실제 row count + i18n)

---

## 9. 기타 중복 후보

| 중복 | 정식 모델 | json 컬럼 | 처리 |
|------|---------|----------|------|
| 페르소나 주제 | ❌ | `AiEmployee.can_answer_topics_json`, `must_handoff_topics_json` | AiEmployee에 그대로 두되 라벨 자연어화 + 스킬 페이지로 분리 |
| 채널 scope | ❌ | `ChannelConnection.scopes_json` (line 144 schema) + business_profile.preferred_channels_json | ChannelConnection 단일 사용, business_profile에서 제거 |
| 메시지 vocab | ❌ | `AiEmployee.vocabulary_phrases_json` | AiEmployee에 유지 (페르소나 일부) |
| 채널 행동 | ❌ | `AiEmployee.channel_behaviors_json` | AiEmployee에 유지 (페르소나 일부) |
| 메모리 | ❌ | `AiEmployee.memory_json` (jsonb, schema:109) | AiEmployee에 유지 (대화 메모리) |
| 인풋/아웃풋 페이로드 | ❌ | `ExecutionEvent.input_json/output_json/result_payload_json` | 그대로 (실행 로그) |
| 구조화 플랜 | ❌ | `AutomationRule.structured_plan/constraints` (jsonb) | 그대로 (자동화 정의) |
| 인덱스 메타 | ❌ | `KnowledgeDocument.metadata` (jsonb) | 그대로 (RAG 검색 메타) |
| 안전 노트 | ❌ | `ContentItem.safety_notes` (jsonb) | 그대로 (콘텐츠 검수 메타) |

→ 위 jsonb는 **단일 모델 안의 구조화 데이터**라 정식 모델 분리는 과잉. 리뉴얼 후에도 유지.