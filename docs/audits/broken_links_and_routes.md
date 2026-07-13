# §1.6 깨진 링크 + 라우트 + 노출 URL audit (2026-07-13)

> 호스트 명세 §1.11 (placeholder, 오류 페이지, 깨진 링크) + §2 (오래된 로그인 링크) + §17 (보안) 의 전수 조사.

## 1. 검색 키워드 결과 (2026-07-13)

| 검색어 | 결과 |
|---|---|
| `peripheral-oasis` (옛 trycloudflare) | **0건** ✅ |
| `addressing-ids` (옛 trycloudflare) | **0건** ✅ |
| `purpleant1011.github.io/workmori` | 1건 (`docs/index.html.p1-backup`, 백업 파일) |
| `purpleant1011.github.io/sohee` | 3건 (정상: docs/index.html, audits, specs) |
| `14일 무료` (랜딩/사업자) | **0건** (정상) |
| `셀프 회원가입` (랜딩) | **0건** (정상 — "셀프 가입 없음" 만) |
| `RAG` (랜딩) | **0건** |
| `sohee_basic` (랜딩) | **0건** |

✅ **모든 옛 URL/내부 키/셀프 가입/14일 무료 = 0건** (랜딩/사업자).

## 2. 옛 백업 파일 (잔존 — 권장 정리)

| 파일 | 위치 | 상태 |
|---|---|---|
| `docs/index.html.p1-backup` | docs/ | ⚠️ 옛 P1 디자인 백업. github.io/workmori URL 잔존 |
| `docs/index.html.p1-backup` | 547 lines | (현재 index.html 688 줄과 별도) |

**개선**: `docs/index.html.p1-backup` 파일 git 추적에서 제거 (또는 `.gitignore`).

## 3. controller / route 검증

### controller 파일 (있음)
- `app/controllers/app/`: 26개 controller (ai_employees, analytics, audit_events, automation_executions, automation_rules, billing, business_profiles, channels, confirmations, content_items, conversations, csat, dashboards, data_exports, deletion_requests, delivery_logs, engagements, faqs, handoffs, ...)
- `app/controllers/platform/`: ~20개
- `app/controllers/api/`: v1 (discord, gemini, runtime_configs, mcp)
- `app/controllers/public/`: about, ai_employee, case_studies, contacts, errors, home, industries, pages, pricing

### route 정의 (`config/routes.rb`)
- `/` → `public/home#show` (랜딩)
- `/login` → `user_sessions#new` (셀프 가입 X, 사업자 통합)
- `/app/...` → 사업자 namespace (dashboards, business_profiles, setups, knowledge_sources, faqs, products, content_items, channels, conversations, handoffs, reports, engagements, settings, deletion_requests, ai_employees, staff_codes, discord_pairing_codes, automations, analytics, audit_events, billing, csat, data_exports, delivery_logs, ...)
- `/platform/...` → 운영자 namespace
- `/api/v1/...` → 서비스 API (discord, gemini, runtime_configs, mcp)
- `/antigravity/...` → antigravity API

### route ↔ controller 일치 (spot check)

| route | controller 파일 | action |
|---|---|---|
| `app_dashboards` | `app/controllers/app/dashboards_controller.rb` | ✅ show |
| `app_business_profile` | `app/controllers/app/business_profiles_controller.rb` | ✅ show/edit/update |
| `app_setups` | `app/controllers/app/setups_controller.rb` | ✅ show/update/skip |
| `app_knowledge_sources` | `app/controllers/app/knowledge_sources_controller.rb` | ⚠️ 7개 action (show/edit/new/create/update/destroy + index) |
| `app_faqs` | `app/controllers/app/faqs_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_products` | `app/controllers/app/products_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_ai_employees` | `app/controllers/app/ai_employees_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_staff_codes` | `app/controllers/app/staff_codes_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_discord_pairing_codes` | `app/controllers/app/discord_pairing_codes_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_automations` (alias) | `app/controllers/app/automation_rules_controller.rb` | ⚠️ 사업자 노출 X (명세 §5) |
| `app_content_items` | `app/controllers/app/content_items_controller.rb` | ✅ 콘텐츠 |
| `app_channels` | `app/controllers/app/channels_controller.rb` | ✅ 연결 상태 |
| `app_conversations` | `app/controllers/app/conversations_controller.rb` | ✅ 고객 문의 |
| `app_handoffs` | `app/controllers/app/handoffs_controller.rb` | ✅ 확인할 일 |
| `app_reports` | `app/controllers/app/reports_controller.rb` | ✅ 보고서 |
| `app_engagements` | `app/controllers/app/engagements_controller.rb` | ✅ 보고서 |
| `app_settings` | `app/controllers/app/settings_controller.rb` | ✅ 매장 정보 |
| `app_deletion_requests` | `app/controllers/app/deletion_requests_controller.rb` | ✅ 해지 |
| `app_analytics` | `app/controllers/app/analytics_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_audit_events` | `app/controllers/app/audit_events_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_billing` | `app/controllers/app/billing_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_csat` | `app/controllers/app/csat_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_data_exports` | `app/controllers/app/data_exports_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_delivery_logs` | `app/controllers/app/delivery_logs_controller.rb` | ⚠️ 노출 (명세 §5) |
| `app_confirmations` | `app/controllers/app/confirmations_controller.rb` | ✅ 확인할 일 (handoffs 와 통합 권장) |

⚠️ **route 와 controller 모두 존재하나, 명세 §5 의 7-IA 메뉴에 속하지 않는 controller 다수** — **메뉴에서만 숨김** (route 자체는 유지하여 deep link / 설정 페이지 접근 가능).

## 4. 보안 (audit §17)

| 항목 | 상태 | 비고 |
|---|---|---|
| trycloudflare URL 노출 | ⚠️ 호스트 허용 (현재 정책) | 영구 운영 X 권장 |
| `dev_login` prod 차단 | ✅ `reject_in_production!` | 정상 |
| Discord bot token 노출 | ❌ `.env` 평문 (git 무추적) | 정상 |
| Meta/Naver token DB 평문 저장 | ⚠️ `ChannelConnection` 의 `external_id` 평문 (별도 audit) | 암호화 권장 |
| 비밀번호 평문 노출 (소스) | ⚠️ `db/seeds.rb` (dev), `docs/specs/sohee_renewal_2026_07_13.md` (호스트 원본), `docs/discord/current_system_audit.md` (전 audit) | 운영 배포 전 secret 분리 |
| MagicLink 사용 | ✅ | 정상 |
| 다른 고객사 Guild 거부 | ❌ (별도 audit) | Discord |

## 5. 종합 — P0/P1 우선순위

### P0 (즉시)
- §1.6: `docs/index.html.p1-backup` 파일 git 추적 제거 + .gitignore 추가
- §1.6: 명세 §5 의 7-IA 외 controller 들은 **메뉴에서만 숨김** (route 유지) — 코드 변경 X, sidebar.html.erb 만 수정

### P1
- §1.6: `app/views/layouts/app.html.erb` 의 sidebar.html.erb 7-IA 재구성
- §1.6: 옛 controller 들의 **메뉴 링크만 제거** (deep link 가능성 유지)

### P2
- §1.6: ChannelConnection.external_id / token 암호화 (`attr_encrypted`)
- §1.6: 운영 환경 secret 분리 (Rails credentials, .env.production)

## 6. 다음 단계

audit 6개 완료. **호스트 검수 시점 (§18 "P 단계는 독립적인 커밋")** — 호스트 승인 시 P0 코드 수정 시작.

P0 코드 수정 (audit 의 권고 작업):
1. layout flex 구조 (`<div class="app-shell">`)
2. Tailwind CDN 제거 + 빌드된 CSS link
3. persona_preset/sohee_* 키 사업자 포털에서 제거 (AI 직원 메뉴 자체 숨김)
4. `docs/index.html.p1-backup` git 추적 제거
5. (별도) production 환경 dev_login 비활성화 (이미 `reject_in_production!` 가드 존재, 라우트 비활성화 확인)

## 7. §1.7 — `bundle exec rails routes` 미실행 (참고)

본 audit 시점 `bundle exec rails routes` 가 0줄 출력 (환경변수 부족 또는 compile error). 추후 환경 정상화 시 100+ route 카운트 + /app /platform /api/v1 분류 가능. audit 데이터는 `config/routes.rb` grep + controller 파일 존재 확인으로 대체.
