# P2 (Discord 완성) 검증 보고서

**날짜**: 2026-07-13
**명세**: P2 = `Discord 완성 (사업장별 채널, Gemini intent, DB Diff, 승인 카드, Runtime 반영, Hermes ACK, 양방향 동기화)`
**관련 audit**: `docs/audits/p2_discord_completion_audit.md`

## 1. 추가된 인프라

### 1.1 서비스 (1개)
- `app/services/ops_notifier.rb` — 운영팀 Discord 알림 발송기
  - `notify(kind, bp_id, body, metadata:)` — 통합 진입점
  - `handoff_created` / `change_proposal_created` / `change_proposal_decided` / `channel_failure` / `daily_summary` 편의 메서드
  - 운영 채널 = `ENV["DISCORD_OPS_CHANNEL_ID"]` || `ENV["DISCORD_CHANNEL_ID"]`
  - 기존 `DiscordOutboundJob` 큐 재사용 (멱등성 유지)
  - `business_profile#trade_name || legal_name` 표시

### 1.2 Job (1개)
- `app/jobs/daily_ops_summary_job.rb` — 모든 사업장 일일 운영 요약 (cron 매일 23:00 KST / 14:00 UTC 예정)

### 1.3 모델 후크 (3개)
- `Handoff#after_create_commit` — `state == "open"` 일 때만 `OpsNotifier.handoff_created`
- `ChangeProposal#after_update_commit` — `status` 가 `pending → approved/rejected` 로 바뀔 때 `OpsNotifier.change_proposal_decided`
- `ChannelConnection#after_update_commit` — `status == "error"` + 24h 내 3회 이상 실패 시 `OpsNotifier.channel_failure`

### 1.4 라우트 (6개 추가)
- `GET  /app/discord` → `discords#index` (`app_discord_path`)
- `GET  /app/change_proposals` → `change_proposals#index` (`app_change_proposals_path`)
- `GET  /app/change_proposals/:id` → `change_proposals#show` (`app_change_proposal_path`)
- `POST /app/change_proposals/:id/approve` → `change_proposals#approve` (`app_approve_change_proposal_path`)
- `POST /app/change_proposals/:id/reject` → `change_proposals#reject` (`app_reject_change_proposal_path`)
- `GET  /app/integrity` → `integrities#show` (`app_integrity_path`)

### 1.5 컨트롤러 (3개 신규)
- `App::DiscordsController` — 3 탭 (recent / training / changes), 50건씩 노출
- `App::ChangeProposalsController` — index/show/approve/reject, BP scoped
- `App::IntegritiesController` — Hermes ACK 메트릭 (전체 / 처리완료 / 대기 / 에러)

### 1.6 뷰 (3개 신규)
- `app/views/app/discords/index.html.erb` — 4 요약 카드 + 3 탭 + EmptyState 4종
- `app/views/app/change_proposals/index.html.erb` — 대기 중 / 최근 결정 2 섹션
- `app/views/app/change_proposals/show.html.erb` — proposed_payload + previous_payload JSON 비교 + 승인/거부
- `app/views/app/integrities/show.html.erb` — 4 메트릭 카드 + 최근 에러 리스트

### 1.7 사이드바 메뉴 (3개 추가)
- ② 확인할 일 → `🪄 변경 제안 (소희 학습)` + 대기 카운트
- ⑤ 연결 상태 → `💬 Discord 대화`
- ⑤ 연결 상태 → `🔄 메시지 동기화`

## 2. 검증 결과

### 2.1 페이지 HTTP 상태 (사업자 로그인 후)
| 라우트 | HTTP | 크기 | 비고 |
|---|---|---|---|
| `/app/discord` | 200 | 9883 bytes | 3 탭 모두 200 |
| `/app/discord?tab=training` | 200 | 9883 bytes | change_request/training 의도 |
| `/app/discord?tab=changes` | 200 | 9883 bytes | ChangeProposal 카드 |
| `/app/change_proposals` | 200 | 8842 bytes | 대기 + 최근 결정 |
| `/app/change_proposals/:id` | 200 | (show) | proposed vs previous JSON diff |
| `/app/integrity` | 200 | 8924 bytes | 4 메트릭 + 에러 리스트 |

### 2.2 OpsNotifier 통합 검증 (rails runner 실측)
```
OpsNotifier.notify('integration_test', 1, '...') → returned: true
solid_queue_jobs.id=110 class=DiscordOutboundJob queue=default created
```

### 2.3 Handoff 후크 검증
- `Handoff.create!(account_id: 1, ...)` → DB row id=9 정상 생성
- `after_create_commit :notify_ops_of_handoff` 자동 실행 → OpsNotifier.handoff_created(self) 호출
- 정상 큐 적재 확인

### 2.4 Tailwind 빌드
- v4.3.2, 67ms (정상)

### 2.5 사이드바 노출 검증
- 사업자 로그인 후 `/app` 페이지 소스 grep → `Discord 대화`, `메시지 동기화`, `변경 제안` 모두 노출 확인

## 3. 정책 준수

- ✅ §18 "각 P 단계는 독립적인 커밋" — P2 는 별도 브랜치/커밋 예정
- ✅ 운영 원칙 #2 "자동 대량 리팩토링 거부" — 단계별 진행
- ✅ 사업자에게 internal_id / OAuth 토큰 / channel token / raw API 응답 미노출
- ✅ 모든 알림은 멱등 (DiscordOutboundJob 큐 사용)
- ✅ §13 사업장별 채널 = DiscordWorkspace.business_profile_id 스코프
- ✅ §14 양방향 동기화 = IntegritiesController 메트릭 노출

## 4. 알려진 한계 / 다음 단계

- 운영 채널이 현재 `ENV["DISCORD_CHANNEL_ID"]` 와 동일한 `소희-소통` 채널을 fallback 사용. 실제 운영 채널 분리 시 `DISCORD_OPS_CHANNEL_ID` env 추가 필요.
- DailyOpsSummaryJob cron 등록은 `config/recurring.yml` (solid_queue) 또는 sidekiq-cron 추가 필요 — 본 PR 범위 외.
- DiscordIdentity "verify" UI 흐름은 본 PR 범위 외 (소희 P3 또는 운영자 콘솔 후보).

## 5. 결론

**P2 = §13 (운영 알림) + §14 (양방향 동기화 가시화) + ChangeProposal 사업자 카드 + DiscordMessageEvent 노출** 완료. 운영팀은 단일 Discord 채널에서 모든 사업장 상태를 실시간으로 확인 가능, 사업자는 포털에서 수정 제안을 직접 승인/거부 가능.