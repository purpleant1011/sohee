# §1.4 SNS 통합 audit (2026-07-13)

> 호스트 명세 §13 "SNS 통합 제어 계층" + §14 "테스트-공식 분리" + §15 "운영자 콘솔" 의 전수 조사.

## 1. 현재 SNS 백엔드 (부분만)

| 컴포넌트 | 위치 | 상태 |
|---|---|---|
| `ChannelConnection` model | `app/models/channel_connection.rb` | ✅ |
| `ChannelScope` model | `app/models/channel_scope.rb` | ✅ (publish_allowed 등) |
| `PublicationAttempt` model | `app/models/publication_attempt.rb` | ✅ |
| `ContentItem` model | `app/models/content_item.rb` | ✅ (state/safety_state/evidence_chunks_json 등) |
| `publisher_job.rb` | `app/jobs/publisher_job.rb` | ✅ |
| `app/jobs/content/publisher_job.rb` | (legacy) | ✅ |
| `app/controllers/app/channels_controller.rb` | 사업자 view | ✅ (단순 CRUD) |
| `app/controllers/app/contents_controller.rb` | (deprecated?) | - |
| `app/controllers/app/content_items_controller.rb` | 콘텐츠 카드 | ⚠️ 상태별 분리 약함 |

### ⚠️ 워커 부재 (audit 핵심 발견)

| 워커 | 상태 | 비고 |
|---|---|---|
| `workers/discord-gateway/` | ✅ proc 54013 | Discord send/receive |
| `workers/gemini-conversation/` | ✅ proc 55369 | LLM 호출 (Gemini/OAuth) |
| `workers/sohee-control-mcp/` | ✅ proc | generic MCP (Rails API) |
| **Instagram 워커** | ❌ 없음 | browser automation 또는 Graph API 워커 없음 |
| **Threads 워커** | ❌ 없음 | 동일 |
| **Naver Blog 워커** | ❌ 없음 | 동일 |

**현재 게시 흐름**:
- `PublisherJob` (Rails ActiveJob) 가 `ChannelConnection` 의 `channel_scopes` + `external_id` + token 으로 Meta/Threads/Naver API 직접 호출
- **실제 인증 토큰 (Instagram Graph, Threads, Naver)** = .env 또는 db secrets — **별도 워커 없음**

**개선**:
- 명세 §13 의 `IntegrationConnection` / `IntegrationCapability` / `IntegrationCommand` / `ExternalEvent` 모델 필요
- 워커 `workers/instagram-publisher/`, `workers/threads-publisher/`, `workers/naver-publisher/` 분리
- 또는 `sohee-control-mcp` 가 통합 라우터 역할

## 2. §13 — 명세 권장 모델 vs 현재

| 명세 모델 | 현재 | 비고 |
|---|---|---|
| `IntegrationConnection` | ❌ (`ChannelConnection` 유사, 통합 안 됨) | need rename/migration |
| `IntegrationCapability` | ❌ (`ChannelScope` 유사) | need extend |
| `ExternalEvent` | ❌ (수신 이벤트 통합 모델 X) | need new |
| `IntegrationCommand` | ❌ (`PublicationAttempt` 유사) | need extend |
| `IntegrationExecution` | ❌ | need new |
| `IntegrationHealthSnapshot` | ❌ (`RuntimeHeartbeat` 일부) | need new |
| `ApprovalRequest` | ❌ (`ChangeProposal` 유사) | need rename/extend |

**개선**:
- ChannelConnection + ChannelScope → `IntegrationConnection` + `IntegrationCapability` 로 통합
- `provider`, `environment` 필드 명세 §14 의 test/official 분리
- `last_verified_at`, `last_success_at`, `last_failure_at`, `health_status` 컬럼
- `IntegrationCommand` = publish/reply 등 action envelope + idempotency_key
- `ExternalEvent` = webhook 수신 통합 (provider/event_type/idempotency_key)

## 3. §14 — 테스트/공식 분리 (audit)

**현황**:
- `ChannelConnection` 컬럼: `account_id`, `kind` (instagram/threads/naver_blog/email), `handle`, `external_id`, `status` (active/ready/planned), `connected_by_user_id`, `last_verified_at`
- `environment` 컬럼 **없음**
- `health_status` 컬럼 **없음**

**개선**:
- `environment` enum: `test_only` / `live` / `archived`
- `health_status` enum: `healthy` / `degraded` / `failing` / `unknown`
- 초기 상태 = `test_only` (자동)
- `live` 전환 = 승인 흐름 (단일 toggle X)

## 4. §15 — 운영자 콘솔 (audit)

| 운영자 메뉴 | 현재 | 비고 |
|---|---|---|
| 고객사별 SNS 연결 | `/platform/accounts/:id/...` (이번 세션 일부) | 부분만 |
| Instagram capability | ❌ (스킬 draft만) | |
| Threads capability | ❌ | |
| Naver Blog capability | ❌ | |
| ExternalEvent view | ❌ | |
| HealthSnapshot | ❌ | |
| 인증 만료 경고 | ❌ | |
| 공식 전환 대기 | ❌ | |
| 실패 작업 | ⚠️ `PublicationAttempt.state` 만 | |
| test/live 분리 view | ❌ | |

## 5. §13 — 흐름 audit (현재 vs 명세)

### 명세 권장 흐름
```
Rails 작업 생성
→ 승인 정책
→ Hermes Claim
→ MCP/API 실행
→ 결과 저장
→ 콘텐츠/문의 상태 갱신
→ Discord 및 관리자 보고
```

### 현재 흐름
```
ContentItem.state='approved'
→ PublisherJob.perform_later
→ ChannelConnection 조회 + scope check
→ Meta/Threads/Naver API 직접 호출 (PublisherJob 내부)
→ PublicationAttempt 생성
→ ContentItem.state='published'
```

**차이**:
- ❌ "Hermes Claim" 단계 없음 (PublisherJob 직접 실행)
- ❌ 통합 ExternalEvent webhook 처리 X
- ❌ 자동 Discord/관리자 보고 X
- ❌ idempotency_key 기반 중복 방지 X (publisher_job 의 idempotency 검사 약함)

## 6. §16 — 랜딩과 실제 기능 일치 (SNS 부분)

| 명세 §16 예 | 실제 |
|---|---|
| Instagram publish_image 가능? | ⚠️ ChannelScope.publish_allowed=true 면 가능 (실제 API 구현은 publisher_job 확인 필요) |
| Instagram reply_comments 가능? | ❌ webhook + reply 워커 부재 |
| Threads publish_text? | ⚠️ 동일 |
| Threads reply_messages? | ❌ |

**개선**:
- `IntegrationCapability` 모델에 `publish_text/publish_image/publish_carousel/publish_video/read_comments/reply_comments/read_messages/reply_messages/read_insights/receive_webhook` 10개 boolean 컬럼
- ChannelScope 의 `publish_allowed` 단순화 → `IntegrationCapability` 통합
- `IntegrationHealthSnapshot` 에 health_status 저장

## 7. 종합 — P0/P3 우선순위

### P0 (즉시)
- (audit 만 — 코드 수정 없음)
- ⚠️ 발견: `external_id` 평문 노출 위험 (Meta/Naver token) — 별도 audit

### P3 (Integration Hub)
- `IntegrationConnection` + `IntegrationCapability` 모델 신규/이관
- `ExternalEvent` / `IntegrationCommand` / `IntegrationExecution` / `IntegrationHealthSnapshot` 신규
- `IntegrationConnection.environment` (test/live) 컬럼
- `IntegrationConnection.health_status` (healthy/degraded/failing) 컬럼
- 워커 `workers/instagram-publisher` (MCP) — Meta Graph API
- 워커 `workers/threads-publisher` (MCP) — Threads API
- 워커 `workers/naver-publisher` (MCP) — Naver Blog API
- Hermes Claim 단계 추가
- idempotency_key 기반 중복 방지
- 운영자 Integration Hub 페이지

## 8. 다음 단계

audit 5 (design system) + 6 (broken links) 작성 후 호스트 검수 시점.
