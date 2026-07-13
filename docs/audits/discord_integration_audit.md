# §1.3 Discord 통합 audit (2026-07-13)

> 호스트 명세 §11 "Discord를 핵심 인터페이스로 통합" + §12 "Discord UX" + §17 "보안" 의 전수 조사.

## 1. 현재 Discord 백엔드 (있음)

| 컴포넌트 | 위치 | 상태 |
|---|---|---|
| `DiscordWorkspace` model | `app/models/discord_workspace.rb` | ✅ |
| `DiscordIdentity` model | `app/models/discord_identity.rb` | ✅ |
| `DiscordMessageEvent` model | (`db/migrate/20260712100000`) | ✅ |
| `ChangeProposal` model | `app/models/change_proposal.rb` | ✅ |
| `/api/v1/discord/events` | `app/controllers/api/v1/discord/events_controller.rb` | ✅ |
| `ProcessDiscordEventJob` | `app/jobs/process_discord_event_job.rb` | ✅ |
| `GenerateDiscordReplyJob` | `app/jobs/generate_discord_reply_job.rb` | ✅ (send_reply 포함) |
| `DiscordOutboundJob` | `app/jobs/discord_outbound_job.rb` | ✅ |
| `AntigravityClient` (Gemini) | `app/services/antigravity_client.rb` | ✅ |
| 워커 gateway | workers/discord-gateway/ (proc 54013) | ✅ |
| `RuntimeConfig` Sync ACK API | `/api/runtime_configs` | ✅ |
| `SetupReadiness` (소희 셋업) | `app/services/setup_readiness.rb` | ✅ |

✅ **기반은 이미 있음**. 명세 §11 의 "처음부터 새로 만드는 상태는 아님" 일치.

## 2. 명세 §11 — 현재 문제 (확인)

### 2.1 키워드 정규식 intent 분류

`app/jobs/generate_discord_reply_job.rb:23` (system prompt):
```ruby
{ role: "system", content: "당신은 매장 안내 직원입니다. 친절하고 간결하게 한국어로 답하세요." }
```

- ❌ **고정 generic system prompt** (명세 §11 "Generic system prompt를 제거한다" 위반)
- ❌ **사업장별 페르소나 로딩 X** (활성 소희, FAQ, 금지어, 인계규칙, 캠페인, 권한)
- intent 분류는 `maybe_create_proposal` (자연어 의도 감지)에서 `modify_kw` 정규식으로 **rule-based** (Gemini 구조화 X)
- ChangeProposal 의 `target_field` 도 FIELD_LABEL_MAP 의 regex 매칭 → DB Diff 없음

### 2.2 전역 DISCORD_CHANNEL_ID

`app/jobs/discord_outbound_job.rb:12-44`:
```ruby
# 우선순위: (1) DB의 channel_id, (2) env의 DISCORD_CHANNEL_ID
ENV["DISCORD_CHANNEL_ID"].presence
```

- ❌ **env fallback 사용 중** (명세 §11 "전역 DISCORD_CHANNEL_ID를 프로덕션 응답 라우팅에 사용하지 않는다" 위반)
- ✅ 다만 코드 코멘트 "호철 메시지의 channel_id가 잘못 저장된 경우 .env의 DISCORD_CHANNEL_ID로 fallback" — 의도된 fallback 으로 보임. **다중 사업장 운영 시엔** DiscordWorkspace.channel_id 우선 + env fallback 제거 필요.

### 2.3 ChangeProposal.previous_payload

`app/jobs/extract_change_proposal_job.rb:38`:
```ruby
proposed_payload: { raw_change_request: event.content_raw }
```

- ❌ **이전 값 (existing value) 비어있음** (명세 §11 위반)
- 명세: "기존 DB 값 조회 → 기존값/새값 Diff 생성"

### 2.4 Discord IntentSchema 미구현

명세 §11 의 schema:
```json
{
  "intent": "conversation | permanent_change | temporary_change | one_time_task | content_request | approval | feedback | sensitive_data",
  "confidence": 0.0,
  "target_domain": "",
  "requires_confirmation": true,
  "summary": "",
  "effective_from": null,
  "expires_at": null
}
```

- ❌ **현재 `event.intent` = 단순 keyword "change_request" | "conversational"** (string enum)
- Gemini structured output 미사용

## 3. 명세 §11 — 고객사별 채널 매핑 (audit)

**현황**:
- `DiscordWorkspace` model: `guild_id`, `default_channel_id` 2개 필드만
- `conversation_channel_id`, `approval_channel_id`, `content_review_channel_id`, `handoff_channel_id`, `report_channel_id`, `upload_channel_id`, `request_forum_channel_id` — **모두 미존재**

**개선 필요**:
- DiscordWorkspace 에 7개 채널 ID 컬럼 추가 (migration)
- 각 channel purpose 별 응답 라우팅

## 4. 명세 §12 — Discord UX (audit)

| 항목 | 현재 | 명세 |
|---|---|---|
| "Discord에서 소희에게 요청하기" CTA | ❌ (메뉴 없음) | ✅ 모든 주요 화면에 |
| Discord 채널 (소희-대화/확인-승인/콘텐츠-검수/문의-인계/일일보고/자료-업로드/요청-수정) | ❌ | ✅ 7개 |
| Discord ↔ Portal 양방향 동기화 | ❌ | ✅ |
| Discord 상태 Integration Hub 표시 | ❌ | ✅ |

**개선 필요**:
- 사업자 화면 상단 (topbar) 에 CTA 버튼 추가
- DiscordIntegrationHub 페이지 (운영자 콘솔)
- 7개 채널 ID 사업장별 설정 (DiscordWorkspace 마이그 + 폼)

## 5. 명세 §17 — 보안 (audit)

| 항목 | 상태 |
|---|---|
| Discord bot token 평문 노출 | ❌ `sohee_workers_env.sh` 에만 (git 무추적, OK) |
| 다른 고객사 Guild 거부 | ❌ 미구현 (DiscordNativeJob 의 guild_id 검증) |
| 메시지 = 명령 으로 처리 X | ✅ (maybe_create_proposal 의 자연어 정규식만) |
| system prompt 변경 시도 거부 | ⚠️ Gemini 는 입력으로 들어오지만 직접 무시는 안 함 (AntigravityClient 미검증) |
| 고객 개인정보 컨텍스트 포함 X | ⚠️ BusinessRagBuilder 에는 들어감 (의도) — 그러나 인스트 DM/메시지에 노출 X |
| owner → Runtime/token/audit 권한 | ❌ (owner 는 Runtime 안 봄) |
| 긴급 중지 즉시 게시 중단 | ❌ 미구현 (AutomationRule.pause 정도) |
| 긴급 중지 = 데이터 삭제 X | (별도 audit) |

## 6. 종합 — P0/P2 우선순위

### P0 (즉시) — 이 audit 에서 발견
- ⚠️ **전역 DISCORD_CHANNEL_ID fallback 코드** 코멘트 명료화 + 운영 가이드 추가 (P0 은 아님, 권장)
- (P0 코드 수정은 audit 외 작업으로 진행)

### P2 (Discord 완성)
- Gemini structured intent 출력 schema 추가 (`lib/generators/discord_intent_schema.json` 또는 AntigravityClient 확장)
- system prompt 동적 로딩 (페르소나 + FAQ + 금지어 + 인계규칙 + 캠페인)
- ChangeProposal.previous_payload 자동 채우기 (DB 조회)
- DiscordWorkspace 채널 매핑 7개 컬럼 추가 + 응답 라우팅
- Discord UX: CTA 버튼 + 7개 채널 가이드 + 양방향 동기화

## 7. 다음 단계

audit 4 (SNS), 5 (design system), 6 (broken links) 작성 후 호스트 검수 시점.
