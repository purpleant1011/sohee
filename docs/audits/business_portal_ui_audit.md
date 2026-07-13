# §1.2 사업자 포털 UI audit (2026-07-13)

> 호스트 명세 §4 "디자인 시스템과 레이아웃" + §5 "사업자 포털 IA" + §6-§9 "대시보드/확인/콘텐츠/문의" 의 전수 조사.

## 1. 현재 app views

| 디렉토리 | view 파일 수 | 비고 |
|---|---|---|
| `app/views/app/` | 26개 |  |
| `app/views/app/dashboards/` | show.html.erb + `_kpi.html.erb` | |
| `app/views/app/ai_employees/` | 3 | index/edit/new (사업자 메뉴 — §5 에서 **제거 권장**) |
| `app/views/app/setups/` | 1+ | show |
| `app/views/app/sessions/` | new | 로그인 |
| `app/views/app/discord_pairing_codes/` | 1 | 이번 세션 추가 |
| `app/views/app/staff_codes/` | 1 | 이번 세션 추가 |

**26개 view 중 사업자 노출 권장: 7개 (오늘/확인/콘텐츠/문의/연결/보고서/매장정보)**.

## 2. §4 — layout flex 구조 오류 (확인)

`app/views/layouts/app.html.erb`:

```
Line 12: <div class="max-w-7xl mx-auto px-4 py-3 flex items-center gap-4">  <!-- topbar -->
Line 34: <div class="max-w-7xl mx-auto px-4 py-4 flex gap-4">                <!-- ❌ 셋업/aside/main 동일 flex 형제 -->
Line 60: <aside class="w-56 flex-shrink-0">                                  <!-- aside -->
Line 107: <main class="flex-1 min-w-0">                                       <!-- main -->
```

**문제**:
- L34 의 div 안에 셋업 준비도 카드(L36-59), aside(L60), main(L107) 모두 형제
- flex row 배치 — 셋업 카드가 aside 옆에 별도 열처럼 보일 수 있음
- 명세 §4 의 `<div class="app-shell"><aside/><main/></div>` 구조와 불일치

**개선안** (audit 결과):
```
<body>
  <header class="topbar" />
  <div class="app-shell max-w-[1440px] mx-auto flex gap-4 px-4 py-4">
    <aside class="w-60 flex-shrink-0">...</aside>
    <main class="flex-1 min-w-0">
      <% if @setup_readiness %><%= render "setup_status" %><% end %>
      <%= yield %>
    </main>
  </div>
</body>
```

## 3. §4 — 페이지별 임의 max-w/p/padding (audit)

`app/views/app/` 파일에서 grep 결과:

| 토큰 | 횟수 |
|---|---|
| `py-2` | 271 |
| `px-3` | 231 |
| `px-4` | 93 |
| `p-2` | 83 |
| `p-4` | 74 |
| `p-3` | 68 |
| `py-1` | 61 |
| `p-5` | 46 |
| `p-6` | 39 |
| `max-w-3xl` | 13 |
| `py-12` | 12 |

**문제**: 페이지마다 max-w-3xl, max-w-5xl, max-w-6xl 등이 임의로 사용 (일관 X).

**개선안**:
- PageHeader / Card / StatusBadge / EmptyState / Alert / SectionHeader / ConfirmDialog 공통 partial
- 페이지 자체는 컨테이너 width 토큰 1~2개만 사용 (예: `app-container`, `app-container--narrow`)

## 4. §4 — Tailwind CDN 사용 (위반)

`app/views/layouts/app.html.erb:8`:
```html
<script src="https://cdn.tailwindcss.com"></script>
```

**문제**: 프로덕션에서 CDN 사용 — 명세 §4 "Tailwind CDN을 프로덕션에서 제거, Rails asset pipeline 또는 Tailwind Rails 빌드 사용".

**현황**: `bundle exec rails tailwindcss:build` 가 동작함 (이전 세션에 빌드 확인). `app/assets/builds/tailwind.css` 생성됨. **CDN 제거 + 빌드된 CSS link** 필요.

**작업**:
- `application.html.erb` / `app.html.erb` / `public.html.erb` 의 `<script src="cdn.tailwindcss.com">` 제거
- `stylesheet_link_tag "tailwind", "data-turbo-track": "reload"` 만 사용 (이미 `app/views/layouts/application.html.erb:22` 존재)
- app.html.erb 도 같은 패턴

## 5. §5 — 사업자 메뉴 7개로 제한 (audit)

### 현재 routes (namespace :app)
namespace :app 안 라우트 (config/routes.rb 50-):

| 경로 | controller | 명세 §5 권장 |
|---|---|---|
| `app_root` (dashboards#show) | App::Dashboards | ✅ 1. 오늘 |
| `app_login` (sessions#new/create) | App::Sessions | (필수) |
| `app_business_profile` | App::BusinessProfiles | ✅ 7. 매장 정보 |
| `app_setups#show` | App::Setups | (1에 포함 또는 별도) |
| `app_staff_codes` (이번 세션) | App::StaffCodes | ❌ **제거** (사업자 노출 X) |
| `app_discord_pairing_codes` (이번 세션) | App::DiscordPairingCodes | ❌ **제거** (사업자 노출 X) |
| `app_ai_employees` (i/edit/update) | App::AiEmployees | ❌ **제거** (운영자 콘솔로) |
| `app_knowledge_sources` | App::KnowledgeSources | ❌ 제거 |
| `app_faqs` | App::Faqs | ❌ 제거 |
| `app_products` | App::Products | ❌ 제거 |
| `app_content_items` | App::ContentItems | ✅ 3. 콘텐츠 |
| `app_channels` | App::Channels | ✅ 5. 연결 상태 |
| `app_conversations` | App::Conversations | ✅ 4. 고객 문의 |
| `app_handoffs` | App::Handoffs | ✅ 2. 확인할 일 |
| `app_reports` | App::Reports | ✅ 6. 보고서 |
| `app_engagements` | App::Engagements | ✅ 6. 보고서 (내부) |
| `app_settings` | App::Settings | ✅ 7. 매장 정보·지원 |
| `app_discord_pairing` | (이번) | ❌ 제거 (Discord 통합은 운영자) |
| `app_automations` (alias) | App::Automations | ❌ 제거 (명세 §5) |
| `app_deletion_requests` | App::DeletionRequests | ✅ 7. 매장 정보·지원 (해지) |

**노출 권장 7개**:
1. 오늘 (dashboards)
2. 확인할 일 (handoffs)
3. 콘텐츠 (content_items)
4. 고객 문의 (conversations)
5. 연결 상태 (channels)
6. 보고서 (reports/engagements)
7. 매장 정보·지원 (business_profile/settings/deletion_requests + login)

**숨길/제거**:
- ai_employees, knowledge_sources, faqs, products, staff_codes, discord_pairing_codes, automations

## 6. §6 — 오늘 대시보드 audit

`app/views/app/dashboards/show.html.erb` head:
```erb
<h1 class="text-2xl font-bold">🌸 오늘의 운영실</h1>
<p class="text-xs text-slate-500 mt-0.5"><%= @current_account.name %> · <%= @today[:contents_generated] %></p>
```

**문제**:
- 이모지 제목 (`🌸`)
- "오늘의 운영실" 명세 §6 의 "오늘" 과 다름 (명세 권장: "오늘")
- 헤더에 "셋업 준비도 %%" 표시 — 명세 §5 의 상단 영역

**명세 §6 핵심 4 질문**:
- 소희 상태 / 오늘 한 일 / 볼 것 / 다음

`app/controllers/app/dashboards_controller.rb` 의 `@today` / `@range` 인스턴스 변수 확인 필요 — **다음 audit 에서**.

## 7. §7-§9 — 확인할 일/콘텐츠/문의 audit

§7 의 **3 탭 (지금 확인 / 운영팀 확인 중 / 처리 완료)** 통합 구조 미존재:
- `app/views/app/handoffs/index.html.erb` 가 handoffs 만 — **confirmations 분리**
- `app/controllers/app/confirmations_controller.rb` 별도 존재
- `app/controllers/app/content_items_controller.rb` 의 상태(state)별 분리 부족

§8 의 **카드 UI / 채널 아이콘 / 자료 첨부** 미구현 (table 형태)
§9 의 **3 탭 (원장님 답변 필요 / 소희가 처리함 / 처리 완료)** 미구현 (현재 conversations 단일)

## 8. 종합 — P0/P1/P2 우선순위

### P0 (즉시)
- §1.4: Tailwind CDN 제거, 빌드된 tailwind.css link
- §1.2: layout flex 구조 수정 (app-shell wrapper)

### P1 (사업자 UI)
- §1.5: 메뉴 7개 재구성 (sidebar.html.erb)
- §1.6: 대시보드 4 질문 Hero + 카드 재설계
- §1.7~§1.9: 확인할 일/콘텐츠/문의 3 탭 통합 + 카드 UI

### P2 (Discord)
- (별도 §1.3 audit)

## 9. 다음 단계

audit 3~6 작성 후, 호스트 검수 시점 (§18 "P 단계는 독립적인 커밋"). 호스트 승인 시 P0 코드 수정 시작.
