# UX 용어 매핑 감사 (UX Terminology Audit)

조사 일시: 2026-07-12
대상: `app/views/app/**/*.erb`, `app/views/layouts/app.html.erb`, `app/controllers/app/base_controller.rb`, `docs/index.html`, `app/views/signups/new.html.erb`

---

## 1. 원칙

**사업자 화면에서 절대 노출 금지** (사용자 사양):
- RAG, Knowledge Gap, Hermes, Runtime, Bundle, Heartbeat, checksum, rollback, Audit, safety_state, state, intent, cron, external_id, scope, retry, embedding, token, prompt version, resource ID, AI 비용, E2E, 백엔드 URL, 데모 계정

**사업자용 자연어 매핑 표**:

| 기술 용어 (현재 노출) | 사업자용 자연어 라벨 (리뉴얼) | 노출 화면 (예) |
|--------------------|--------------------------|--------------|
| RAG (Retrieval-Augmented Generation) | "소희가 참고하는 매장 정보" / "소희가 참고하는 자료" | business_profiles/show, knowledge_sources/new, base_controller setup_readiness, base_controller 셋업 카드 |
| Knowledge Gap (지식 공백) | "소희가 더 알아야 할 질문" / "더 알아야 할 질문" | knowledge_gaps/index (h1, 카드) |
| Handoff (인계) | "원장님 확인 필요" / "원장님 답변 필요" | handoffs/index, handoffs/show, dashboard 카드 |
| Runtime | "현재 적용 중인 업무 설정" / "현재 업무 설정" | runtime_configs/* |
| Runtime Bundle | "업무 설정 묶음" | runtime_configs/index |
| Runtime Heartbeat | (사업자 노출 완전 금지, 운영자 콘솔에서만) | runtime_configs/* |
| checksum | (사업자 노출 완전 금지) | runtime_configs/*, data_exports/show |
| rollback (롤백) | (사업자 노출 완전 금지) | runtime_configs/index, show |
| Audit | (사업자 노출 완전 금지) | audit_events/index |
| safety_state | (사업자 노출 완전 금지, 운영자 콘솔에서만) | content_items/index, show |
| state (raw enum) | "콘텐츠 진행 상태" (한국어 매핑) | content_items/*, automation_rules/* |
| intent (콘텐츠 의도) | "콘텐츠 목적" | content_items/new |
| intent_kind (자동화 의도) | (운영자 콘솔로 이동) | automation_rules/index |
| cron | (운영자 콘솔로 이동) | automation_rules/new |
| external_id | (운영자 콘솔로 이동) | channels/* |
| scope (oauth scope) | (운영자 콘솔로 이동) | channels/* |
| retry | "재시도" (운영자 콘솔) | automation_rules/* |
| embedding | (사업자 노출 완전 금지) | (없음, 모델 내부) |
| token | "API 키" (운영자 콘솔) | (없음, 모델 내부) |
| prompt version | (사업자 노출 완전 금지) | (없음) |
| resource ID | (사업자 노출 완전 금지) | audit_events, runtime_configs |
| AI 비용 | (사업자 노출 완전 금지, AI 비용 페이지 별도 운영자만) | (없음) |
| E2E | (사업자 노출 완전 금지) | (없음, 개발자용) |
| 백엔드 URL | (사업자 노출 완전 금지) | (없음) |
| 데모 계정 | (사업자 노출 완전 금지) | login, README |
| Hermes | (사업자 노출 완전 금지, "소희"로 표기) | audit_events, runtime_configs, settings/password, platform layout |
| AI 직원 (현재 ai_employees 메뉴) | "소희" (1명 고정, 신규 생성 X) | ai_employees/index |
| 페르소나 (persona) | "소희 말투" / "소희 답변 스타일" | ai_employees/* |
| 자연어 시스템 지시 (natural_language_instructions) | "소희에게 알려주는 메모" | ai_employees/* |
| 사전지식 (knowledge_source) | "소희가 참고하는 자료" | knowledge_sources/* |
| 자동화 룰 (automation_rule) | "반복 업무 일정" / "소희가 자동으로 할 일" | automation_rules/* |
| 안전 로그 (safety_log) | "차단되거나 확인이 필요한 내용" / "검토 필요한 알림" | safety_logs/index |
| 운영 로그 (delivery_log) | (운영자 콘솔로 이동) | delivery_logs/index |
| 콘텐츠 상태 state | 진행 상태 → "초안 / 검수 요청 / 게시 예정 / 게시 완료 / 보관" | content_items/* |
| 채널 상태 status | 채널 상태 → "연결 안 됨 / 연결 중 / 연결됨 / 오류" | channels/index |
| 게시 시도 (publication_attempt) | (운영자 콘솔) | channels/show (line 43) |
| SHA-256 | (운영자 콘솔 또는 안전하게 "지문" 정도) | data_exports/show |

---

## 2. 사이드바 IA 라벨 변환

### 현재 (`app/views/layouts/app.html.erb:60-91`)

| 메뉴 (현재) | 자연어 변환 (리뉴얼) | 그룹 |
|-----------|---------------------|------|
| 🌸 대시보드 | "오늘" | ① 오늘 |
| 🤖 AI 직원 (소희) | "소희 소개" (편집 불가, 읽기 전용) | ② 매장 정보 섹션 내부로 이동 |
| 🏪 사업장 프로필 | "매장 정보" | ② 매장 정보 (그룹 헤더 제거, 페이지 단일) |
| 📚 지식베이스 / RAG | (삭제, 매장 정보 안에 "소희가 참고하는 자료" 카드) | (없음) |
| ❓ FAQ | (삭제, 매장 정보 안에 FAQ 섹션) | (없음) |
| 🧩 지식 공백 | (삭제, "확인할 일" 탭 안에 "더 알아야 할 질문") | (없음) |
| 💰 가격표 / 상품 | (삭제, 매장 정보 안에 "가격표") | (없음) |
| 🔌 채널 관리 | (삭제, 매장 정보 안에 "공식 채널") | (없음) |
| 📅 콘텐츠 캘린더 | "콘텐츠" | ③ 콘텐츠 |
| 💬 문의 응대 | "고객 문의" | ④ 고객 문의 |
| ⚠️ 원장님 확인 필요 | "확인할 일" (탭 통합) | ⑤ 확인할 일 |
| ⏰ 자동화 루틴 | (삭제, 운영자 콘솔) | (없음) |
| 📈 리포트 | "보고서" | ⑥ 보고서 |
| 📋 운영 로그 | (삭제, 운영자 콘솔) | (없음) |
| 🛡️ 안전 로그 | (삭제, 운영자 콘솔) | (없음) |
| 🛂 Hermes Audit | (삭제, 운영자 콘솔) | (없음) |
| ⚙️ Hermes Runtime | (삭제, 운영자 콘솔) | (없음) |
| ⚙️ 설정 | "계정·지원" | ⑦ 계정·지원 |
| 💳 계약/요금 | (삭제, 계정·지원 안에서 읽기 전용) | (없음) |
| 해지 신청 | (삭제, 계정·지원 안에 "서비스 해지 신청") | (없음) |

**최종 7개 메뉴**: 오늘 / 확인할 일 / 콘텐츠 / 고객 문의 / 보고서 / 매장 정보 / 계정·지원

---

## 3. 모바일 네비게이션

### 현재
- 모바일 대응 없음 (`layout/app.html.erb`의 `max-w-7xl mx-auto px-4`만 적용)
- 사이드바 22개가 좁은 화면에서 main을 가림
- 햄버거 메뉴 없음

### 리뉴얼 결정
- 모바일 (< 768px): **하단 nav 5개** (오늘 / 확인할 일 / 콘텐츠 / 문의 / 보고서)
- 태블릿/데스크톱 (≥ 768px): **사이드바 7개 메뉴** (매장 정보, 계정·지원 포함)
- 390px iPhone 시뮬레이션: 햄버거 토글 → 오버레이 nav
- 하단 nav active 상태 명확히 표시

---

## 4. 상태 라벨 자연어 매핑

### 4.1 콘텐츠 상태 (`ContentItem.state`)

| DB 값 | 한국어 라벨 (사업자) | 색상 | 노출 |
|------|------------------|------|------|
| `draft` | "초안" | slate | 콘텐츠 > 초안 탭 |
| `pending_review` | "검수 요청" | amber | 확인할 일 + 콘텐츠 > 검수 요청 탭 |
| `approved` | "게시 준비" | sky | 콘텐츠 > 게시 예정 탭 |
| `scheduled` | "게시 예정" | sky | 콘텐츠 > 게시 예정 탭 |
| `published` | "게시 완료" | emerald | 콘텐츠 > 게시 완료 탭 |
| `archived` | "보관" | slate | 콘텐츠 > 보관 탭 |
| `failed` | "다시 시도 필요" | rose | 확인할 일 (콘텐츠 + 함께) |
| `rejected` | "보류" | rose | 확인할 일 |

### 4.2 채널 상태 (`ChannelConnection.status`)

| DB 값 | 한국어 라벨 (사업자) | 색상 |
|------|------------------|------|
| `disconnected` | "연결 안 됨" | slate |
| `connecting` | "연결 중" | amber |
| `connected` | "연결됨" | emerald |
| `error` | "오류 — 운영팀 확인 중" | rose |
| `revoked` | "연결 해제됨 — 운영팀 확인 중" | slate |

### 4.3 자동화 상태 (`AutomationRule.status`)

| DB 값 | 한국어 라벨 (운영자) | 사업자 노출? |
|------|------------------|----------|
| `draft` | "초안" | ❌ |
| `active` | "활성" | ❌ |
| `paused` | "일시 중지" | ❌ |
| `failed` | "오류" | ❌ |
| `archived` | "보관" | ❌ |

→ 자동화 상태는 **사업자에게 노출 안 함** (운영자 콘솔만).

### 4.4 Handoff 상태 (`Handoff.state`)

| DB 값 | 한국어 라벨 (사업자) | 색상 |
|------|------------------|------|
| `open` | "확인 필요" | amber |
| `in_progress` | "처리 중" | sky |
| `resolved` | "처리 완료" | emerald |
| `dismissed` | "보류" | slate |

### 4.5 콘텐츠 안전 (`ContentItem.safety_state`)

| DB 값 | 한국어 라벨 (사업자) | 노출 |
|------|------------------|------|
| `safe` | (보이지 않음, 정상) | ❌ |
| `needs_review` | "검토 필요" (확인할 일 카드 제목) | ✅ (자연어) |
| `blocked` | "게시 불가" (확인할 일 카드 제목) | ✅ (자연어) |

→ DB 컬럼은 유지하되 뷰에서 raw enum 노출 금지.

### 4.6 FAQ 위험 (`Faq.risk_level`)

| DB 값 | 한국어 라벨 (사업자) | 노출 |
|------|------------------|------|
| `low` | "자동 응대 OK" | ✅ |
| `medium` | "소희 답변 + 운영팀 검수" | ✅ |
| `high` | "원장님 답변 필요" | ✅ |

---

## 5. 대시보드 자연어 ("오늘의 보고" 3~5줄)

리뉴얼 후 `/app/dashboard` 하단에 자연어 요약 영역 (모델 `DailyReport` 또는 `WeeklyReport`):

> 오늘은 메뉴 2개를 새로 올렸어요. "여름 헤어 케어" 게시물은 원장님 한 번 확인해 주세요. 그리고 어제 댓글로 온 후기 3건 모두 답했어요. 이번 주에 신규 예약 4건이 들어왔고, 모두 답했습니다. 다음 주 일정에 "7월 할인 안내"가 등록되어 있어요.

→ 줄 단위 카드, 시간순 아님, 자연스러운 한국어

---

## 6. 색상·아이콘 규약

| 용도 | 색상 | 아이콘 |
|------|------|-------|
| 정상 / 완료 | emerald | ✅ |
| 확인 필요 | amber | ⚠️ |
| 오류 / 차단 | rose | 🚫 |
| 진행 중 | sky | 🔵 |
| 보관 / 비활성 | slate | 📦 |
| 신규 / 추가 | indigo | ✨ |

**규약**: 색상으로만 상태 표현 금지. **텍스트 라벨 + 아이콘 동시 사용** (WCAG 1.4.1)

---

## 7. 접근성

### 7.1 키보드 nav
- 모든 인터랙티브 요소 tab 순서 논리적
- 사이드바/하단 nav `<nav>` `<a>` 사용, `aria-current="page"` 표시
- 모달 (현재 미사용 — 신규에도 X)

### 7.2 form label
- 모든 input에 `<label for="...">` 명시 (현재 placeholder만 의존 일부)
- required 표시 별도 + `aria-required="true"`

### 7.3 focus
- 포커스 링 명확 (`focus:ring-2 focus:ring-emerald-500`)
- skip to main content 링크

### 7.4 색상 대비
- 본문 4.5:1 이상, 큰 텍스트 3:1 이상
- slate-500 / slate-700 등 충분한 contrast 검증

### 7.5 오류 메시지
- `aria-invalid="true"` + 시각적 표시 + 텍스트 설명
- raw 오류 메시지 (예: PG card API error) 노출 금지, 한국어 변환

---

## 8. 문구 통일

| 사용 맥락 | 통일 문구 (사업자) |
|---------|------------------|
| 운영팀 연락 | "운영팀에 문의하기" (not "고객센터") |
| 셋업 진행 | "셋업 진행 중" / "셋업 준비도 N%" (only on onboarding) |
| 정식 전환 | "정식 서비스 이용 시작" |
| 정식 전환 후 | "정식 운영 중" |
| 데이터 요청 | "데이터 처리 요청" |
| 해지 | "서비스 해지 신청" |
| 자동 응대 | "소희가 바로 답한 문의" |
| 인계 | "원장님 답변 필요" |
| 검수 요청 | "소희가 작성하고 원장님 확인을 요청했어요" |
| 게시 실패 | "게시가 어려워요 — 운영팀이 확인 중이에요" |
| 빈 상태 | "아직 표시할 내용이 없어요. 다음에 다시 볼게요." (not "데이터 없음") |

---

## 9. 공개 사이트 (`docs/index.html`) 변경

### 9.1 삭제할 메시지
- "셀프 회원가입 후 14일 무료 체험" (line 666)
- "가입 즉시 사용" 류 카피
- "사장님이 직접 AI 직원 만들기" 류 카피
- "Quick Tunnel 개발 안내" (trycloudflare 관련)
- "임시 외부 도메인 설명"

### 9.2 대체 카피
- "도입 상담 연결" → "도입 상담 신청" 버튼 (sales@soheeproject.example 또는 contact form)
- 로그인 버튼 라벨 → "등록된 매장 운영 화면"
- "AI 직원 만들기" → "운영형 AI 직원 서비스" (소희 설명)
- 도메인 처리 → 정식 도메인 placeholder 또는 "도입 상담 시 안내"

### 9.3 회원가입 페이지 (`app/views/signups/new.html.erb`)

전체 변경:
- "회원가입" → "도입 상담 신청" (또는 라우트 자체 폐쇄 + contact form으로 redirect)
- "14일 무료 체험" → "운영팀이 매장을 셋업하는 동안 사용해 보세요 (상담 후 결정)"
- submit "14일 무료 체험 시작하기" → "도입 상담 신청하기"
- 폼 필드 단순화 (이름/매장명/연락처/메시지) — 결제 정보 X

또는 **완전 폐쇄**:
- `/signup` 라우트 410 Gone
- `/signups/new.html.erb` 삭제
- `SignupForm` 모델 + 컨트롤러 폐쇄 또는 운영자만 사용 (운영팀이 신규 고객사 등록 시 사용)

---

## 10. 검증 체크리스트 (리뉴얼 완료 후)

자동 검사 스크립트 `script/verify_renewal.rb`:

- [ ] 사업자 화면 (`/app/**`) 어디서도 다음 문자열 0건 노출: RAG, Knowledge Gap, Hermes, Runtime, Heartbeat, checksum, rollback, Audit, safety_state, state, intent, cron, external_id, scope, retry, embedding, token, prompt version, resource ID
- [ ] 사이드바 7개 (오늘 / 확인할 일 / 콘텐츠 / 고객 문의 / 보고서 / 매장 정보 / 계정·지원)
- [ ] AI 직원 신규 생성 UI 0개 (운영자 콘솔에만)
- [ ] 지식베이스 / FAQ / 상품 / 채널 / 자동화 / 런타임 / 안전 로그 / 감사 로그 0개 (사업자)
- [ ] 셀프 회원가입 페이지 0개 (`/signup` 410 or redirect)
- [ ] 14일 trial 강제 redirect 0개
- [ ] 백엔드 URL / AI 비용 / E2E / 데모 계정 / quick tunnel 문자열 0건
- [ ] placeholder "이 화면은 준비 중입니다" 0건 (또는 신규 IA에 실제 구현)
- [ ] 권한 가드: 4단계 (소유자/매니저/스태프/조회) — controller level
- [ ] 반응형: 390px / 768px / 1440px 모두 정상
- [ ] 키보드 nav / form label / focus / 색상 대비 / aria-current / aria-invalid 정상
- [ ] 공개 사이트 (`docs/index.html`) 셀프 가입 메시지 0건
- [ ] dev_login / trycloudflare 0건 공개 노출

→ 1건이라도 적발 시 리뉴얼 미완료로 표시.