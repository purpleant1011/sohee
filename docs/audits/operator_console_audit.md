# 운영자 콘솔 전수 조사 (Operator Console Audit)

조사 일시: 2026-07-12
대상: `/platform/*` (운영자 콘솔)
레이아웃: `app/views/layouts/platform.html.erb`
인증: `Platform::SessionsController`, `dev_login/platform`

---

## 1. 라우트 규모

`bin/rails routes` 기준 `/platform` 네임스페이스 = **107 라우트**, 컨트롤러 20개, 뷰 50 파일.

상위 액션 수 (컨트롤러별):

| 액션 수 | 컨트롤러 | 비고 |
|--------:|---------|------|
| 7 | `accounts` | 표준 CRUD + suspend/reactivate |
| 7 | `contracts`, `incidents`, `industries`, `industry_templates`, `inquiries`, `model_catalog_entries`, `plans`, `prompt_templates`, `feature_flags`, `announcements` | 표준 CRUD |
| 3 | `billings`, `reports` | 표준 CRUD |
| 2 | `platform_staff`, `magic_links` | 인덱스/쇼 |
| 1 | `dashboards#show` | 단일 |
| (별도) | `hermes_controller` | **3개 별도 페이지**: `index`, `audit`, `executions` |
| (별도) | `sessions`, `magic_links` | 인증 |

**문제 1: 고객사별 운영 콘솔 부재**
- `accounts/:id/setup`, `accounts/:id/persona`, `accounts/:id/knowledge`, `accounts/:id/skills`, `accounts/:id/channels`, `accounts/:id/automations`, `accounts/:id/test_lab`, `accounts/:id/content`, `accounts/:id/inquiries`, `accounts/:id/runtime`, `accounts/:id/monitoring`, `accounts/:id/audit` — **0개 라우트**
- 현재 운영자는 글로벌 리소스(전체 accounts, 전체 inquiries, 전체 prompt_templates)만 봄
- 고객사 1개에 들어가면 어떤 화면이 어떤 흐름으로 구성되는지 없음

**문제 2: layout 정보 밀도 부족**
- 사이드바 없음, 상단 nav만 (`app/views/layouts/platform.html.erb:14-26`)
- 7개 링크만 노출 (대시보드, 계정, 문의, 산업, 기능, 보고, Hermes, 공지)
- 운영자 콘솔에서 가장 자주 쓰일 "고객사 선택 → 페르소나/지식/채널/자동화/테스트 랩" 흐름이 없음

---

## 2. 현재 운영자 nav

`app/views/layouts/platform.html.erb:14-26`:

```erb
<nav class="text-sm flex gap-4">
  <a href="<%= platform_root_path %>">대시보드</a>
  <a href="<%= platform_accounts_path %>">계정</a>
  <a href="<%= platform_inquiries_path %>">문의</a>
  <a href="<%= platform_industries_path %>">산업</a>
  <a href="<%= platform_feature_flags_path %>">기능</a>
  <a href="<%= platform_reports_path %>">보고</a>
  <a href="<%= platform_hermes_path %>">Hermes</a>
  <a href="<%= platform_announcements_path %>">공지</a>
  ...
</nav>
```

**부족한 링크** (현재 없음):
- `platform_contracts_path` (계약 관리) — 라우트는 존재하지만 nav 누락
- `platform_billings_path` (결제/요금) — 라우트 존재, nav 누락
- `platform_plans_path` (플랜 정의) — 라우트 존재, nav 누락
- `platform_prompt_templates_path` (프롬프트 템플릿) — 라우트 존재, nav 누락
- `platform_model_catalog_entries_path` (모델 카탈로그) — 라우트 존재, nav 누락
- `platform_industry_templates_path` (산업별 템플릿) — 라우트 존재, nav 누락
- `platform_platform_staff_path` (운영자 staff 관리) — 라우트 존재, nav 누락

**리뉴얼 결정**: nav → 사이드바 + breadcrumb 구조로 변경. 고객사 선택 시 `/platform/accounts/:id/{setup,persona,knowledge,skills,channels,automations,test_lab,content,inquiries,runtime,monitoring,audit}` 12개 페이지 노출.

---

## 3. 컨트롤러 ↔ 뷰 매핑 (운영자 화면 50개)

### 3.1 유지 (글로벌 리소스 / 운영자 콘솔 자체)

| 컨트롤러 | 화면 | 신규 위치 |
|---------|------|----------|
| `dashboards#show` | `/platform` | 운영자 콘솔 대시보드 (고객사 선택/알림/사고 큐) |
| `accounts#*` (CRUD + suspend/reactivate) | `/platform/accounts` | 고객사 목록 + 신규 생성 (운영팀이 직접) |
| `accounts#show` | `/platform/accounts/:id` | 고객사 요약 + **고객사별 콘솔 진입점** |
| `contracts#*` | `/platform/contracts` | 계약 관리 (pricing 정해지기 전 read-only) |
| `billings#*` | `/platform/billings` | 결제/요금 |
| `plans#*` | `/platform/plans` | 플랜 정의 |
| `inquiries#*` | `/platform/inquiries` | 외부 문의 (랜딩 contact form) |
| `industries#*`, `industry_templates#*` | `/platform/industries` | 산업 분류 + 템플릿 |
| `prompt_templates#*` | `/platform/prompt_templates` | 프롬프트 템플릿 |
| `model_catalog_entries#*` | `/platform/model_catalog_entries` | LLM 모델 카탈로그 |
| `feature_flags#*` | `/platform/feature_flags` | 기능 플래그 |
| `incidents#*` | `/platform/incidents` | 사고 |
| `announcements#*` | `/platform/announcements` | 공지 |
| `reports#*` | `/platform/reports` | 운영 보고 |
| `platform_staff#*` | `/platform/platform_staff` | 운영자 staff 관리 |
| `magic_links#*` | `/platform/magic_link` | 매직 링크 인증 |
| `sessions#*` | `/platform/login`, `/platform/logout` | 인증 |
| `hermes#*` (3 페이지) | `/platform/hermes`, `/platform/hermes/audit`, `/platform/hermes/executions` | Hermes 글로벌 (통합 Runtime/Audit) |

### 3.2 신규 추가 (고객사별 운영 콘솔 12개 화면)

신규 라우트 그룹 `namespace :platform do; resources :accounts do; member do; ... end; end`:

| 신규 화면 | 경로 | 책임 |
|---------|------|------|
| 셋업 (요약/마법사 진행률) | `/platform/accounts/:account_id/setup` | 고객사 셋업 마법사 진행률, 마일스톤 |
| 페르소나 | `/platform/accounts/:account_id/persona` | 페르소나 버전 관리, 자연어 시스템 지시, 프리셋, persona key, 친근함/전문성/능동성 슬라이더 |
| 지식 | `/platform/accounts/:account_id/knowledge` | 지식 자료 처리·재색인, document chunk, embedding, knowledge gap 점수 |
| 스킬 | `/platform/accounts/:account_id/skills` | 답변 가능/인계 주제, FAQ 검수, 금지어/금지 주제 |
| 채널 | `/platform/accounts/:account_id/channels` | 채널 OAuth, credentials, external_id, scopes, 상태 모니터링 |
| 자동화 | `/platform/accounts/:account_id/automations` | 자동화 루틴, cron, retry 정책, 실패 정책, 실행 이력 |
| 테스트 랩 | `/platform/accounts/:account_id/test_lab` | 테스트 콘텐츠 생성, 테스트 문의 시뮬레이션, 페르소나 미리보기 |
| 콘텐츠 | `/platform/accounts/:account_id/content` | 전체 콘텐츠 (draft/scheduled/published), 발행 시도, 즉시 게시, 안전 로그 |
| 문의 | `/platform/accounts/:account_id/inquiries` | 전체 문의 (handoff 포함), 분류, 강제 라우팅 |
| Runtime | `/platform/accounts/:account_id/runtime` | Runtime Bundle 버전, checksum, 활성화/롤백, Heartbeat |
| 모니터링 | `/platform/accounts/:account_id/monitoring` | 채널 상태, 자동화 실행, 실패 알림, AI 비용 |
| Audit | `/platform/accounts/:account_id/audit` | 감사 로그, 안전 로그, 비즈니스 이벤트 |

**권한 가드**:
- 모든 controller `before_action :require_platform_operator!` 또는 `require_platform_admin!`
- 사업자 세션 차단 (`current_platform_staff` nil이면 `/platform/login`으로)
- 고객사 본인이 아닌 운영자만 접근

---

## 4. 운영자 Hermes 콘솔 (현재)

`app/controllers/platform/hermes_controller.rb` (3 페이지):

- `index` → `/platform/hermes` (글로벌 Runtime 개요)
- `audit` → `/platform/hermes/audit`
- `executions` → `/platform/hermes/executions`

**문제**:
- 고객사 필터링 없음 (전체 한 화면에 다 나옴)
- Runtime Bundle / Heartbeat / Audit이 한 화면에 혼합
- 사업자가 이 URL을 추측해 들어올 수 있음 (`/platform`은 운영자만, 사업자는 `/app`만)

**리뉴얼 결정**:
- 글로벌 `/platform/hermes`는 **운영자 admin 전용 통합 모니터링**으로 유지
- 고객사별 `/platform/accounts/:id/runtime`과 `/platform/accounts/:id/audit`로 분리
- AuditEvent 조회 필터: `account_id` 필수

---

## 5. 운영자 contracts / billings / plans

- `ContractsController` — 라우트 존재 (CRUD), nav 누락. 가격 정책 정해지기 전 read-only 또는 skeleton
- `BillingsController` — 라우트 존재, nav 누락
- `PlansController` — 라우트 존재, nav 누락

**리뉴얼 결정**:
- pricing 정책 정해지기 전 → 3개 모두 운영자 read-only
- 사업자 화면에서 `/app/billing`, `/app/plans` 제거 (셀프 결제 의존 X)
- 운영자 nav에 추가

---

## 6. 결론

1. **고객사별 운영 콘솔 12개 페이지 신규 추가** (`/platform/accounts/:id/*`)
2. **상단 nav → 사이드바 + breadcrumb**
3. **글로벌 리소스 (/platform/accounts, /platform/contracts, ...)** nav 보강
4. **Hermes 글로벌 + Runtime/Audit은 고객사별로 분리**
5. **모든 controller `before_action :require_platform_*!` 가드**
6. **pricing 정책 정해지기 전 → contracts/billings/plans read-only**