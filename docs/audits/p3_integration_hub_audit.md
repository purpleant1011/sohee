# P3 Integration Hub 갭 분석 (2026-07-13)

## 0. 기준
- **§18 명세 P3**: Integration Hub (Instagram/Threads/Discord/Blog 공통, test/official 분리)
- **§20 완료 기준**: "Integration Hub는 10초 안에 다음을 보여야 한다. Discord/Instagram/Threads 연결 상태 / 테스트/공식 여부 / 최근 성공/실패 / 승인 대기"

## 1. 데이터 정합성 (2026-07-13)

### 1.1 ChannelConnection — 6개 (BP#1)
| id | kind | status | scopes |
|---|---|---|---|
| 1 | instagram | active | publish_posts, read_mentions |
| 2 | instagram | ready | (empty) |
| 3 | mastodon | active | (empty) |
| 4 | naver_place | active | (empty) |
| 5 | kakao_channel | active | (empty) |
| 6 | email | active | (empty) |

- ⚠️ **threads / naver_blog / x_twitter / discord / daangn 없음** (BP#1 한정, 시드 부족)
- ⚠️ **scopes_json** = `publish_posts, read_mentions` 외 모두 비어있음 — **test/official 분기 데이터 부재**

### 1.2 ChannelScope — 0개 (전체)
- ❌ **테스트/공식 분기 데이터 0건** — 시드 누락 또는 기능 미사용

### 1.3 AutomationRule — 15개 (acct=1)
- intent_kind = `post`(자동 게시), `report`(보고서), `reply`(FAQ 응답), `faq_update`, `data_export`
- status = `active`(5), `draft`(10), `paused`(1)
- ❌ **자동 게시 규칙 카드/승인 UI 없음**

### 1.4 PublicationAttempt — 115건
- 대부분 `succeeded`, 1건 `failed` (Email handle에 '@' 필요)
- ❌ **자동 게시 이력 페이지 없음** — §20 "최근 성공/실패" 가시화 부족

### 1.5 /app/channels 현재 (P1 step 4)
- 4 카드 (정상 운영 / 승인 대기 / 일시중지 / 운영팀 점검 중) ✅
- 자동 게시 규칙 카드 ❌
- 게시 이력 ❌
- test/official 토글 ❌

## 2. P3 핵심 갭

| # | 갭 | §20 매핑 | 우선순위 |
|---|---|---|---|
| 2.1 | 자동 게시 규칙(AutomationRule) 카드 | "승인 대기" | P3 step 1 |
| 2.2 | 자동 게시 이력(PublicationAttempt) 페이지 | "최근 성공/실패" | P3 step 1 |
| 2.3 | test/official 분기(ChannelScope) 토글 | "테스트/공식 여부" | P3 step 2 |
| 2.4 | 규칙 추가/승인 UI | "승인 대기" | P3 step 2 |
| 2.5 | /app/channels 4-카드에 test/official 표시 | "10초 안에" | P3 step 3 |
| 2.6 | DiscordMessageEvent 와 PublicationAttempt 통합 카드 | §13/§14 | P3 step 3 |

## 3. P3 step 계획

### step 1: 백엔드 확장
- `AutomationRule` association 검증 (`belongs_to :account`, `has_many :automation_executions`)
- `PublicationAttempt#recent_successes`/`recent_failures` scope 추가
- seed 확장: ChannelScope test/official 시드 5개, AutomationRule 1개 추가

### step 2: UI 페이지
- `/app/automation_rules` (index/show/approve/reject 4 액션)
- `/app/publication_attempts` (index 1 액션)
- `/app/channels/test_official` (분리 토글)

### step 3: 통합
- `/app/channels` 4-카드에 test/official 배지
- 사이드바 ⑤ 연결 상태 그룹에 `/app/automation_rules` + `/app/publication_attempts` 2개 링크 추가
- OPS_NOTIFIER 트리거: AutomationRule 승인 시 Discord 알림

### step 4: 검증
- 6 routes 정상 등록 확인
- 6 routes 200 확인
- AutomationRule approve → Discord 큐 적재 확인
- §P3 검증 보고서 작성

## 4. 정책 준수
- §18 "각 P 단계는 독립적인 커밋"
- 영구 #2 "호스트 단계 지시할 때까지 코드 자동 수정 안 함" — P3 전체 자동 진행은 호스트 "다음" 활성으로 정당화
- 영구 #3 명세 문서 = `docs/specs/` 유지