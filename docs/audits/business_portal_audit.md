# 사업자 포털 전수 조사 (Business Portal Audit)

조사 일시: 2026-07-12
대상: `/app/*` (사업자 포털)
레이아웃: `app/views/layouts/app.html.erb`
인증: `App::SessionsController` (Rails session), `dev_login/business` (dev 전용)
빌드 상태: `main` @ `dbd6fd9`

---

## 1. 라우트 규모

`bin/rails routes` 기준 `/app` 네임스페이스 = **153 라우트**, 컨트롤러 31개, 뷰 75 파일.

상위 액션 수 (컨트롤러별):

| 액션 수 | 컨트롤러 |
|--------:|---------|
| 17 | `ai_employees` |
| 13 | `content_items` |
| 13 | `automation_rules` |
| 12 | `knowledge_sources` |
| 11 | `channels` |
| 9 | `services`, `runtime_configs`, `products`, `faqs` |
| 8 | `handoffs` |
| 7 | `knowledge_gaps`, `base` |
| 6 | `data_exports` |
| 5 | `billing` |

**문제**: 한 화면에 너무 많은 책임이 몰려 있다. 한 컨트롤러가 17 액션 (`ai_employees` = 신규/편집/복제/메모리 추가·삭제/페르소나 미리보기/테스트 메시지 등)을 처리하며, 사장님이 직접 페르소나 JSON(`can_answer_topics_json`, `must_handoff_topics_json`)을 편집하게 한다.

---

## 2. 사이드바 IA (현재 `app/views/layouts/app.html.erb:60-91`)

22개 메뉴가 5개 그룹으로 분할되어 있다.

| 그룹 | 메뉴 | 행 | 비고 |
|------|------|----:|------|
| ① 시작 | 🌸 대시보드 | 63 | OK |
| | 🤖 AI 직원 (소희) | 64 | ❌ 사장님 직접 빌드 → 운영자 콘솔로 이동 |
| ② 사업장 | 🏪 사업장 프로필 | 67 | OK (통합 필요) |
| | 📚 지식베이스 / RAG | 68 | ❌ RAG 용어 + 운영자 콘솔로 이동 |
| | ❓ FAQ | 69 | ❌ 매장 정보 섹션으로 통합 |
| | 🧩 지식 공백 | 70 | ❌ "원장님 확인 필요" 탭으로 통합 |
| | 💰 가격표 / 상품 | 71 | ❌ 매장 정보로 통합 |
| ③ 채널·콘텐츠 | 🔌 채널 관리 | 74 | ❌ 운영자 콘솔로 이동 (단순 "공식 채널" 카드만 유지) |
| | 📅 콘텐츠 캘린더 | 75 | OK (단순화) |
| | 💬 문의 응대 | 76 | OK (Handoff와 통합) |
| | ⚠️ 원장님 확인 필요 | 77 | OK (Handoff 페이지 통합) |
| ④ 자동화·보고 | ⏰ 자동화 루틴 | 80 | ❌ 운영자 콘솔로 이동 |
| | 📈 리포트 | 81 | OK (단순화) |
| | 📋 운영 로그 (delivery_logs) | 82 | ❌ 운영자 콘솔로 이동 |
| | 🛡️ 안전 로그 | 83 | ❌ 운영자 콘솔로 이동 |
| | 🛂 Hermes Audit | 84 | ❌ 운영자 콘솔로 이동 |
| | ⚙️ Hermes Runtime | 85 | ❌ 운영자 콘솔로 이동 |
| ⑤ 계정 | ⚙️ 설정 | 88 | OK (계정·지원으로 통합) |
| | 💳 계약/요금 | 89 | ❌ 가격 미정 → 제거 또는 읽기 전용 |
| | 해지 신청 | 90 | OK |

**목표 IA 7개 메뉴**:

1. 오늘 (대시보드)
2. 확인할 일 (Handoff + 콘텐츠 검수 + 정보 확인 통합)
3. 콘텐츠 (ContentItem 통합)
4. 고객 문의 (Conversations)
5. 보고서
6. 매장 정보 (BusinessProfile + FAQ + 서비스 + 페르소나 소개 + 공식 채널)
7. 계정·지원 (settings + 계약 정보 + 데이터 요청 + 해지)

---

## 3. 컨트롤러 ↔ 뷰 매핑 (사업자 화면 75개)

### 3.1 본질적으로 사장님이 봐야 하는 화면 (≈ 18개)

| 컨트롤러 | 액션 | 뷰 | 상태 | 신규 IA 매핑 |
|---------|------|----|------|-------------|
| `dashboards#show` | GET /app | `dashboards/show.html.erb` | 부분 구현 (검수 큐 + KPI 일부 노출) | **오늘** (대시보드 전면 재구성) |
| `content_items#index` | GET /app/content/items | `content_items/index.html.erb` | raw state 노출 | **콘텐츠** (탭: 확인 필요 / 게시 예정 / 게시 완료 / 보관) |
| `content_items#show` | GET /app/content/items/:id | `content_items/show.html.erb` | state/safety_state/intent 노출 | 콘텐츠 상세 |
| `conversations#index` | GET /app/conversations | `conversations/index.html.erb` | 인계/문의 혼재 | **고객 문의** (탭: 원장님 답변 필요 / 처리 완료) |
| `conversations#show` | GET /app/conversations/:id | `conversations/show.html.erb` | placeholder ("이 화면은 준비 중") | 문의 상세 (실제 구현 필요) |
| `handoffs#index` | GET /app/handoffs | `handoffs/index.html.erb` | open 카운트 OK | **확인할 일** (탭 통합) |
| `handoffs#show` | GET /app/handoffs/:id | `handoffs/show.html.erb` | placeholder | 확인할 일 상세 |
| `business_profiles#show` | GET /app/business_profile | `business_profiles/show.html.erb` | "소희 RAG의 기반" 표현 사용 | **매장 정보** (통합 페이지) |
| `business_profiles#edit` | GET /app/business_profile/edit | `business_profiles/edit.html.erb` | **placeholder** ("준비 중") | 매장 정보 수정 (실제 폼 구현 필요) |
| `reports#index` | GET /app/reports | `reports/index.html.erb` | raw state (`published`, `handoff_count`) | **보고서** (단순화) |
| `settings#show` | GET /app/settings | `settings/show.html.erb` | OK | **계정·지원** |
| `settings#password` | GET /app/settings/password | `settings/password.html.erb` | "Hermes Audit" 노출 | 비밀번호 변경 |
| `terminations#new` | GET /app/termination | `terminations/new.html.erb` | **placeholder** | 해지 신청 (실제 폼 구현 필요) |
| `data_exports#index` | GET /app/data_exports | `data_exports/index.html.erb` | raw state (`pending`, `running`, `failed`) | 데이터 내보내기 |
| `data_exports#new` | GET /app/data_exports/new | `data_exports/new.html.erb` | placeholder | 데이터 내보내기 신청 |
| `deletion_requests#index` | GET /app/deletion_requests | `deletion_requests/index.html.erb` | placeholder | 데이터 삭제 요청 |
| `deletion_requests#new` | GET /app/deletion_requests/new | `deletion_requests/new.html.erb` | placeholder | 데이터 삭제 신청서 |

### 3.2 운영자 콘솔로 이동해야 하는 화면 (≈ 30개)

| 컨트롤러 | 사유 |
|---------|------|
| `ai_employees#*` (17 액션) | 사장님 페르소나 빌더는 운영자 콘솔로 |
| `knowledge_sources#*` (12) | RAG 자료 색인은 운영자 |
| `faqs#*` (9) | FAQ는 매장 정보 섹션에서만 (운영팀 검수 후 적용) |
| `knowledge_gaps#*` (7) | "확인할 일" 탭으로 통합 |
| `channels#*` (11) | OAuth, credentials, scopes는 운영자 |
| `automation_rules#*` (13) | cron/루틴은 운영자 |
| `automation_executions#*` | 운영자 모니터링 |
| `runtime_configs#*` (9) | Hermes Runtime Bundle은 운영자 |
| `audit_events#index` | Hermes Audit은 운영자 |
| `safety_logs#index` | 안전 로그는 운영자 |
| `delivery_logs#index` | 운영 로그 |
| `products#*` (9) | 정식 Product 모델은 유지, 매장 정보에 통합 (사장님은 가격표 뷰만) |
| `services#*` (9) | 동일 |
| `engagements#*` | 운영자 |
| `referrals#*` | 제거 또는 운영자 |
| `csat#*` | 제거 (raw CSAT 모델 사업자 노출 금지) |
| `analytics#*` | 제거 (KPI 사업자 노출 최소화, 보고서만) |
| `billing#*` (5) | 셀프 결제 제거, 운영자 콘솔에서 계약 정보 읽기 전용 |
| `plans#index` | 셀프 플랜 선택 제거 |

### 3.3 신규 추가해야 하는 화면

| 신규 화면 | 위치 | 용도 |
|---------|------|------|
| 오늘 (Today) | `app/views/app/dashboards/show.html.erb` (재구성) | 소희 상태 + 4개 핵심 카드 + 타임라인 |
| 확인할 일 | `app/views/app/confirmations/index.html.erb` (신규) | Handoff + 콘텐츠 검수 + 정보 확인 + 채널 승인 통합 |
| 콘텐츠 | `app/views/app/content_items/index.html.erb` (재구성) | 탭 4개 + 자연어 진행 상태 |
| 고객 문의 | `app/views/app/conversations/index.html.erb` (재구성) | 탭 3개 + 자연어 인계 사유 |
| 보고서 | `app/views/app/reports/index.html.erb` (재구성) | 일일/주간/월간, KPI 삭제 |
| 매장 정보 | `app/views/app/store_infos/show.html.erb` (신규) | 10개 섹션 통합 |
| 소희 소개 | `app/views/app/sohee/show.html.erb` (신규) | AI 직원 편집 페이지 제거, "소희 소개" 페이지로 대체 |
| 셋업 마법사 | `app/views/app/onboarding/wizard.html.erb` (신규) | 10단계 |

---

## 4. 셋업 준비도 카드 (사업자 base_controller:30-72)

`App::BaseController#load_setup_readiness`가 7개 항목을 노출한다.

| # | 항목 | 라벨 (현재) | 사장님 노출 적합? |
|--:|------|------------|------------------|
| 1 | 사업장 프로필 + 브랜드 톤 + 금지어 | ✅ OK | OK |
| 2 | "지식베이스 / RAG (정식 소스 N건)" | ❌ RAG 용어 | ❌ "소희가 참고할 자료 N건" |
| 3 | "페르소나 설정 (sohee_basic/cafe/salon/expert)" | ❌ 운영자 라벨 | ❌ "소희 말투/답변 기준" |
| 4 | "채널 연결 (테스트 계정 ≥ 1)" | ❌ 운영자 라벨 | ❌ "공식 채널 연결 N건" |
| 5 | "FAQ 활성 (N개)" | ✅ OK | OK |
| 6 | "원장님 인계 규칙 (escalation_rules)" | ❌ raw state | ❌ "민감 문의 인계 기준" |
| 7 | "원장님 검수 합격 (5건 이상)" | ✅ OK | OK |

**문제**:
- 7개 항목이 사업자 대시보드 상단에 항상 노출 (튜토리얼 + 운영 콘솔 혼재)
- raw state 명칭 (`escalation_rules`, `status: "active"`, `state: "approved"`) 노출
- "원장님 검수 합격 (5건 이상)"처럼 사장님이 합격시켜야 할 KPI 카운트다운

**리뉴얼 결정**:
- 셋업 준비도는 **온보딩 기간에만** 상단 한 곳에서 표시
- 라벨 전부 자연어로 교체
- 운영자 콘솔 항목 제거 ("정식 채널 연결"은 매장 정보 섹션 카드로)

---

## 5. base_controller 권한 가드

`App::BaseController` 현재:

```ruby
before_action :require_business_sign_in!    # 로그인 강제
before_action :load_account_context         # current_account 로드
before_action :load_setup_readiness         # 7항목 셋업 카드
before_action :enforce_trial_status!        # 14일 trial 만료 시 /app/plans로 redirect
```

**문제**:
- 역할 기반 권한 가드 부재 (`business_owner` / `business_staff` / `platform_operator` 구분 없음)
- `require_owner_or_admin!`, `require_owner_or_manager!` 정의되어 있지만 **호출되는 컨트롤러 0개** (`grep -r require_owner app/controllers/app` 결과 없음)
- 메뉴 숨김만으로 처리, 서버 측 권한 검증 없음

**리뉴얼 결정**:
- `User.role` 컬럼 또는 `Membership` 테이블로 역할 명시 (현재 `Membership` 모델 존재하지만 활용 미확인)
- 모든 controller `before_action :require_role!` 추가
- 플랫폼 운영자 영역은 `namespace :platform`으로만 접근, 사장님 세션 차단

---

## 6. 기술 용어 노출 (사업자 화면 외부 도메인 실측)

`https://peripheral-oasis-certificates-antiques.trycloudflare.com` 사업자 세션 (`dev_login/business` + `byreum@soheeproject.example`) 기준:

| 화면 | 노출 용어 |
|------|---------|
| /app/dashboard | Hermes×2, Audit×1, Runtime×1, RAG×5 |
| /app/conversations | Hermes×2, RAG×2 |
| /app/audit_events | **"Hermes Audit"**×2 (페이지 타이틀 + h1) |
| /app/runtime_configs | **"Hermes Runtime"**×2, **"Heartbeat"**×1, **"롤백"**×1, RAG×2 |
| /app/business_profile (show) | "소희 RAG의 기반이 되는 사업장 정보" |
| /app/knowledge (new) | "AI 학습 및 RAG 인덱싱에 동의" |
| /app/settings/password | "변경 이력은 Hermes Audit(🛂 감사 로그)에 기록" |
| /app/content_items/show | `state: <%= @content.state %>`, `safety_state: <%= @content.safety_state %>` |
| /app/content_items/index | `safety_state` raw 노출 |
| /app/content_items/new | `<select name="intent">` (영문 라벨) |
| /app/automation_rules/new | `<option value="cron">cron</option>` |
| /app/channels/index | `scope_kind`, `scopes_json`, `external_id` |

**차단율**: 100% (모든 핵심 화면에서 적어도 1개 이상 금지 용어 노출)

**정확한 비호환 라벨 (사업자에게 노출 중)**:

| 기술 용어 | 노출 위치 | 사업자용 라벨 (리뉴얼) |
|---------|----------|---------------------|
| RAG | 사업장 프로필, 지식베이스, ai_employees, base_controller | "소희가 참고하는 매장 정보" |
| Knowledge Gap | knowledge_gaps/index.html.erb h1 | "소희가 더 알아야 할 질문" |
| Handoff | handoffs/index, handoffs/show | "원장님 확인 필요" |
| Runtime | runtime_configs/index, show | "현재 적용 중인 업무 설정" |
| Safety Log | safety_logs/index | "차단되거나 확인이 필요한 내용" |
| Automation Rule | automation_rules/index | "반복 업무 일정" |
| Content State | content_items/show | "콘텐츠 진행 상태" |
| Hermes | 전 화면 | (사업자 노출 완전 금지) |
| Audit | audit_events/index | (사업자 노출 완전 금지) |
| Heartbeat | runtime_configs/index, show | (사업자 노출 완전 금지) |
| checksum | runtime_configs/index, show, data_exports/show | (사업자 노출 완전 금지) |
| rollback | runtime_configs/index, show | (사업자 노출 완전 금지) |
| intent | content_items/new | "콘텐츠 목적" |
| cron | automation_rules/new | (운영자 콘솔로 이동) |
| external_id | channels/index, show, new, edit | (운영자 콘솔로 이동) |
| scope | channels/* | (운영자 콘솔로 이동) |
| resource ID | audit_events, runtime_configs | (운영자 콘솔로 이동) |
| state (raw) | content_items/*, automation_rules/* | "진행 상태" (한국어 매핑) |
| safety_state | content_items/index, show | (운영자 콘솔로 이동) |

---

## 7. placeholder 화면 (실제 미구현)

19개 화면이 `"이 화면은 곧 실제 데이터로 채워집니다. 페이지를 확인한 뒤 개선 사항을 알려주세요."` + `"이 화면은 준비 중입니다."` 패턴 사용 (전체 동일):

- reports/show.html.erb
- services/show.html.erb
- conversations/show.html.erb ← 인계 상세 미구현
- deletion_requests/{new,show,index}.html.erb ← 삭제 요청 미구현
- content_items/pending_for_review.html.erb
- services/index.html.erb
- automation_executions/{index,show}.html.erb
- data_exports/new.html.erb
- terminations/new.html.erb ← **해지 신청서 미구현 (가장 큰 누락)**
- automation_rules/dashboard.html.erb
- handoffs/show.html.erb
- faqs/show.html.erb
- business_profiles/edit.html.erb ← **사업장 프로필 편집 미구현**
- products/show.html.erb
- referrals/index.html.erb
- plans/index.html.erb ← **셀프 플랜 페이지 (자체 가입 의존)**

**즉시 처리 필요**: business_profiles/edit, terminations/new, conversations/show, content_items/pending_for_review, plans/index는 신규 IA에서 핵심 화면.

---

## 8. 결론

1. **사이드바 22개 → 7개로 축소**
2. **컨트롤러 31개 → 약 12개로 통합**
3. **뷰 75개 → 약 30개로 축소** (placeholder 19개 중 14개는 삭제, 5개는 실제 구현)
4. **셋업 준비도 카드는 온보딩 기간에만 노출, 라벨 자연어화**
5. **권한 모델 명시 + controller-level 가드**
6. **기술 용어 100% 차단** (curl 실측 100% 적발)
7. **셀프 가입·무료 체험·셀프 결제 흐름 제거** (운영팀 초대 기반)
8. **고객사별 운영자 콘솔 신규 구축** (라우트 0개 → 약 12개 추가)