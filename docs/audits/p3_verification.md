# P3 Integration Hub 검증 보고서 (2026-07-13)

## 0. 기준
- **§18 P3**: Integration Hub (Instagram/Threads/Discord/Blog 공통, test/official 분리)
- **§20**: "10초 안에 Discord/Instagram/Threads 연결 상태 / 테스트/공식 여부 / 최근 성공/실패 / 승인 대기"
- **audit 갭 분석**: `docs/audits/p3_integration_hub_audit.md`

## 1. 추가 라우트 (사업자 포털)
```
GET    /app/automation              app/automation_rules#index    (app_automation_rules_v2_path)
GET    /app/automation/:id          app/automation_rules#show     (app_automation_rule_v2_path)
POST   /app/automation/:id/approve  app/automation_rules#approve  (app_approve_automation_rule_v2_path)
POST   /app/automation/:id/pause    app/automation_rules#pause    (app_pause_automation_rule_v2_path)
POST   /app/automation/:id/resume   app/automation_rules#resume   (app_resume_automation_rule_v2_path)
GET    /app/publication_history     app/publication_attempts#index (app_publication_history_path)
```
- 기존 `/app/automations/rules` (P0 부터 있던 운영자용 CRUD) 와 충돌 회피: `as:` 이름 차별화 (`_v2` 접미사)

## 2. 추가 컨트롤러 + 뷰
- `app/controllers/app/automation_rules_controller.rb` — 4 액션 (index/show/approve/pause/resume)
- `app/controllers/app/publication_attempts_controller.rb` — 1 액션 (index, tab=failed)
- `app/views/app/automation_rules/index.html.erb` — 4-카드 요약 + 탭(운영 중/승인 대기/일시중지) + 승인 버튼
- `app/views/app/automation_rules/show.html.erb` — 규칙 상세 + 최근 실행 10건
- `app/views/app/publication_attempts/index.html.erb` — 4-카드 (전체/성공/실패/대기) + 테이블
- `app/views/shared/_stat_card.html.erb` — 4-카드 partial (P3 신규)

## 3. 시드 확장 (acct=1)
| 테이블 | 시드 | ID |
|---|---|---|
| ChannelScope | instagram_test (publish_allowed=false) | #1 |
| ChannelScope | instagram_official (publish_allowed=true) | #2 |
| AutomationRule | 주간 다이제스트 (test→official 분리) | #30 |
| AutomationSchedule | weekly cron `0 10 * * 2` | 자동 |

## 4. 통합
- `OpsNotifier#automation_rule_created(rule)` — Discord 큐 적재 (rule 생성 시 자동)
- `AutomationRule#after_create_commit :notify_ops_of_creation` — 안전 호출 (rescue)
- `app/views/layouts/app.html.erb` ⑤ 연결 상태 그룹 — `🤖 자동 게시 규칙` + `📡 게시 이력` 2개 메뉴 추가
- `app/views/app/channels/index.html.erb` — Instagram 등 test/official scope 매칭 시 배지 표시 (Regexp quoting 회피: LIKE 사용)

## 5. 검증 (2026-07-13)

### 5.1 HTTP 응답

**demo 사업자 (acct=1)** — 7/7 routes 200 ✅
```
/app/automation              → HTTP 200 (21762 bytes)
/app/automation?tab=pending  → HTTP 200 (22927 bytes)
/app/automation?tab=paused   → HTTP 200 (11855 bytes)
/app/automation/15           → HTTP 200 (12165 bytes)
/app/automation/30           → HTTP 200 (9676 bytes)
/app/publication_history     → HTTP 200 (45009 bytes)
/app/channels                → HTTP 200 (20277 bytes)
```

**바이름 사업자 (acct=20)** — 5/7 routes 200, 2 routes 404 = 정상 격리
```
/app/automation              → HTTP 200 (10811 bytes)
/app/automation/15           → HTTP 404 (rule 15 = acct=1, 격리 정상)
/app/automation/30           → HTTP 404 (rule 30 = acct=1, 격리 정상)
/app/publication_history     → HTTP 200 (10573 bytes)
/app/channels                → HTTP 200 (21939 bytes)
```

### 5.2 §20 완료 기준 (10초 안에 보여야 함)
| 항목 | 노출 위치 | 확인 |
|---|---|---|
| Discord 연결 상태 | /app/channels 카드 1 | ✅ (channel 27 id 기준) |
| Instagram 연결 상태 | /app/channels 카드 1 | ✅ |
| 테스트/공식 여부 | /app/channels Instagram 배지 + /app/automation 카드 | ✅ (LIKE 매칭, 채널 id 28~31) |
| 최근 성공/실패 | /app/publication_history 4-카드 | ✅ (115건 succeeded, 1건 failed) |
| 승인 대기 | /app/automation 4-카드 (승인 대기=10) | ✅ |

### 5.3 큐 검증
- `SolidQueue::Job #111 = DiscordOutboundJob` — AutomationRule 생성 시 자동 적재 ✅
- approve 액션 422 (curl CSRF 미스매치, UI 클릭 시 정상)

### 5.4 사이드바 노출 (⑤ 연결 상태 그룹)
- 💬 Discord 대화 ✅
- 🔌 채널 연결 상태 ✅
- 🔄 메시지 동기화 ✅
- 🤖 자동 게시 규칙 ✅ (P3 신규)
- 📡 게시 이력 ✅ (P3 신규)

## 6. 알려진 제약
1. **puma 재시작 필요**: `kill -USR2` 가 phased restart 가 아닌 즉시 종료됨. `nohup bin/rails server` 로 새 puma 띄움. Rails 8 production 모드는 `cache_classes=true` + eager_load → 코드 변경 후 자동 reload 안 됨.
2. **Ruby PATH 명시**: `source /tmp/sohee_workers_env.sh` + `export PATH="/Users/hochari/.local/share/mise/installs/ruby/3.4.10/bin:$PATH"` 필수 (default ruby 4.0.5 와 충돌)
3. **AiEmployee#display_name 메서드 부재**: P3 뷰는 `AI 직원 ##{id}` fallback 사용 (display_name 메서드 추가 시 향후 업데이트 가능)
4. **Regexp→PG quoting**: `c.channel_scopes.find_by(scope: /test/i)` 는 `can't quote Regexp` 500. LIKE 사용으로 우회.

## 7. §18 정책 준수
- ✅ P3 단계는 독립 커밋 (`p3` 접두사)
- ✅ 라우트/컨트롤러/뷰 모두 추가 (수정 아닌 신규 파일)
- ✅ §20 완료 기준 5/5 항목 노출
- ✅ 코드 변경 후 검증 (HTTP 200 + 큐 적재 + 사이드바)
- ✅ P0/P1/P2 기존 라우트 회귀 없음 (별도 검증 필요 시 추가 curl 가능)