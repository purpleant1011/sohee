# §1.5 디자인 시스템 + 레이아웃 audit (2026-07-13)

> 호스트 명세 §4 "디자인 시스템과 레이아웃 수정" 의 전수 조사.

## 1. Tailwind / CSS 빌드

| 파일 | 상태 |
|---|---|
| `app/assets/stylesheets/application.css` | ✅ 존재 |
| `app/assets/stylesheets/application.tailwind.css` | ✅ 존재 |
| `tailwind.config.js` | ❌ 없음 (root) |
| `app/assets/builds/tailwind.css` | ✅ 빌드 결과 (이전 세션 빌드) |
| `app/views/layouts/app.html.erb:8` | ❌ `<script src="https://cdn.tailwindcss.com"></script>` |
| `app/views/layouts/public.html.erb:8` | ⚠️ 동일 CDN? (확인 필요) |

**개선**:
- `app/views/layouts/app.html.erb` L8 의 CDN script 제거
- `application.html.erb:22` 의 `stylesheet_link_tag "tailwind", "inter-font", ...` 만 사용
- `tailwind.config.js` 생성 (color palette, max-width 토큰 정의)

## 2. 공통 컴포넌트 partial

| partial | 위치 | 비고 |
|---|---|---|
| `_kpi.html.erb` | `app/views/app/dashboards/` | 1개만 |
| `app/views/shared/` | ❌ 없음 | |
| `app/views/components/` | ❌ 없음 | |

**필요 (명세 §4)**:
- `app/views/shared/_page_header.html.erb` — 페이지 제목 + breadcrumb + 액션
- `app/views/shared/_card.html.erb` — 카드 wrapper
- `app/views/shared/_status_badge.html.erb` — 상태 배지 (성공/경고/위험/정보)
- `app/views/shared/_empty_state.html.erb` — 빈 상태 (CTA 포함)
- `app/views/shared/_alert.html.erb` — 알림 박스
- `app/views/shared/_section_header.html.erb` — 섹션 제목
- `app/views/shared/_confirm_dialog.html.erb` — 확인 모달 (Turbo Frame)

**기존 partial 검토 후 재사용/이관**:
- `_kpi.html.erb` → `_card` 또는 `_status_badge` 로 통합

## 3. 색상/타이포그래피 (audit)

| 토큰 | 현재 | 명세 §4 |
|---|---|---|
| Primary | `text-emerald-500` (topbar), `text-rose-600` (CTA) | 차분한 teal |
| Accent | `bg-rose-500` (긴급) | rose 만 CTA |
| Semantic | `text-emerald-700` (성공), `text-amber-700` (경고), `text-rose-700` (위험) | 4개 |
| Surface | `bg-slate-50` (페이지), `bg-white` (카드) | 통일 |
| Border | `border-slate-200` (구분) | 통일 |

**명세 §4 "이모지를 모든 제목에 사용하지 않는다"** 위반:
- `app/views/app/ai_employees/index.html.erb:14` — `🌸 <strong>초기 파트너 매장</strong>...`
- `app/views/app/ai_employees/index.html.erb:22` — `<h2 ...>🌸 소희 페르소나 4가지 템플릿</h2>`
- `app/views/app/ai_employees/index.html.erb:26` — `["sohee_basic", "🌸", "소희 (기본)", ...]` (sohee_basic 키 + 🌸 동시)
- `app/views/app/dashboards/show.html.erb:9` — `<h1 ...>🌸 오늘의 운영실</h1>` (명세 §5 "오늘")
- `app/views/app/sessions/new.html.erb:9` — `<h1 ...>🔐 사업자 로그인</h1>`
- `app/views/app/business_profiles/show.html.erb:17` — `⚠️ 온보딩이 완료되지 않았습니다.`
- 기타 다수

**개선**:
- 아이콘 시스템 정착 (예: lucide-icons 또는 heroicons SVG)
- 제목에서 이모지 제거
- 상태 표현 (위험/경고/성공) 만 색상 + 아이콘

## 4. §4 — internal 키 / persona_preset 노출 (audit)

**사업자 포털에서 노출 (X) — 모두 §2 위반**:

| 파일 | 라인 | 키/키워드 |
|---|---|---|
| `app/views/app/ai_employees/index.html.erb` | 26, 55 | `sohee_basic`, `sohee_cafe`, `sohee_salon`, `sohee_expert` |
| `app/views/app/ai_employees/show.html.erb` | 19, 81 | `sohee_basic` 등 (있을 가능성) |
| `app/controllers/app/base_controller.rb` | (이전 diff 에서) | `persona_preset` 노출 가능 |

**개선**:
- 사업자 포털에서 AI 직원 메뉴 **제거** (명세 §5)
- 운영자 콘솔 (/platform) 으로 이동
- 운영자 콘솔에서만 persona_preset 표시

## 5. §4 — 아이콘 시스템 권장 (audit)

| 시스템 | 장점 | 비고 |
|---|---|---|
| Lucide icons (SVG) | 무료, 가벼움, tree-shakable | 권장 |
| Heroicons (Tailwind 공식) | Tailwind 와 잘 맞음 | 권장 |
| 인라인 SVG 직접 | 의존성 0 | 소규모에 적합 |
| Emoji | 무료, 즉시 | 명세 §4 "이모지 사용 X" 위반 |

**개선안**:
- `app/views/shared/_icon.html.erb` partial (lucide 인라인)
- 명세 §7 의 "원장님 확인 필요" 카드 → ⚠️ → SVG `<svg>` 아이콘

## 6. 종합 — P0/P1 우선순위

### P0 (즉시)
- §1.4: layout flex 구조 (`<div class="app-shell">`)
- §1.5: Tailwind CDN 제거 + 빌드된 tailwind.css link
- §1.5: 사업자 포털에서 persona_preset / sohee_* 키 노출 제거 (AI 직원 메뉴 자체 제거)
- §1.5: 제목/제목단의 이모지 제거 + 아이콘 시스템 도입 (P1)

### P1 (디자인 시스템)
- §1.5: 공통 partial 7종 (PageHeader/Card/StatusBadge/EmptyState/Alert/SectionHeader/ConfirmDialog)
- §1.5: tailwind.config.js 작성 (color palette, max-width 토큰)
- §1.5: 아이콘 시스템 (lucide 또는 heroicons)
- §1.5: 1440px / 768px / 390px 반응형 표준

### P2 (모바일)
- 사이드바 → drawer
- 하단 nav (오늘/확인/콘텐츠/문의/보고서)
- 44px 터치 영역
- sticky CTA
- 가로 스크롤 표 → 카드
- 긴 상태명 줄바꿈

## 7. 다음 단계

audit 6 (broken links + routes) 작성 후 호스트 검수 시점.
