# P2 (Discord 완성) 갭 분석 — §13/§14 통합

**날짜**: 2026-07-13
**기준 명세**: P2 = `Discord 완성 (사업장별 채널, Gemini intent, DB Diff, 승인 카드, Runtime 반영, Hermes ACK, 양방향 동기화)`
**관련**: `docs/audits/discord_integration_audit.md` (P0)

## 1. 기존 인프라 (P0/P1 누적)

### 1.1 모델
- `DiscordWorkspace` (id, business_profile_id, guild_id, guild_name, default_channel_id, sohee_category_id, status)
- `DiscordIdentity` (user ↔ discord_user 연결, verified_at, role_in_business)
- `DiscordMessageEvent` (snowflake_id, kind, content_raw, intent, processed, processed_at, processing_error)
- `ChangeProposal` (target_kind, target_field, proposed_payload, reason, status, expires_at, decided_at, applied_runtime_config_id)
- `RuntimeConfig` (적용된 설정 스냅샷)

### 1.2 Jobs (5종)
- `ProcessDiscordEventJob` — 수신 이벤트 처리 + intent 분류 + ChangeProposal 생성
- `GenerateDiscordReplyJob` — Gemini 응답 생성
- `DiscordOutboundJob` — Discord 메시지 발송
- `DiscordNativeJob` — 네이티브 명령 (예: /sohee)
- `ReconcileDiscordMessagesJob` — 양방향 동기화 (5분 주기 cron 추정)

### 1.3 서비스 / 라우트
- AntigravityClient (Gemini OAuth 기반 의도 분류)
- 운영팀 Discord 워크스페이스 (별도 guild 추정)
- `change_approvals` 조인 테이블 (다중 승인자)

## 2. 갭 (통합 부족 영역)

### 2.1 운영팀 알림 흐름 부재
- ❌ handoff 발생 → 운영팀 Discord 자동 알림 없음
- ❌ ChangeProposal 결정 → 운영팀 가시 채널 없음
- ❌ 채널 연결 실패 → 운영팀 on-call 알림 없음
- ❌ 일일 운영 요약 → 운영 채널 자동 post 없음

### 2.2 사업자 포털 통합 부재
- ❌ 사업자 UI 에서 DiscordMessageEvent (소희와 대화한 메시지) 조회 불가
- ❌ 사업자 UI 에서 ChangeProposal (자동 수정 제안) 카드 없음
- ❌ DiscordIdentity verify 흐름 (사업자가 "이 사용자 = 나" 인증) UI 없음

### 2.3 Hermes ACK 부재
- ❌ `external_event_id` 기반 멱등 처리 검증 미흡
- ❌ Discord 메시지 → 우리 DB → 다시 Discord ACK 흐름 가시화 부족

### 2.4 양방향 동기화 가시화 부재
- ❌ Reconcile 결과 (어떤 메시지가 누락/순서 뒤바뀜) 사업자 노출 없음

## 3. P2 작업 항목 (자동 진행 계획)

### P2 step 1: 운영팀 Discord 알림 채널 (가장 시급)
- Discord `ops_workspaces` 테이블 (운영 guild + channel 매핑) — 기존 운영 워크스페이스가 별도로 존재할 가능성 있음
- `BusinessOpsNotifier` 서비스 — handoff / 채널 실패 / 일일 요약 → 운영 채널 post
- cron 잡 `DailyOpsSummaryJob` (매일 23:00)

### P2 step 2: 사업자 포털 — Discord 대화 카드
- `/app/discord` 라우트 추가
- 사업자 ↔ 소희 대화 로그 (DiscordMessageEvent) 카드 UI
- ChangeProposal 카드 (승인/거부 버튼)
- DiscordIdentity "내 계정 인증" 흐름

### P2 step 3: Hermes ACK 가시화
- `/app/integrity` 또는 `/app/reconcile` — 메시지 동기화 상태 (pending/acked/errored)
- 에러시 사업자 액션 (재시도/무시)

### P2 step 4: 통합 검증 보고서
- 모든 라우트 HTTP 200
- 운영 채널 post test
- 5개 Jobs 모두 동작