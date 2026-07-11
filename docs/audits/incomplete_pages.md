# 미완성 페이지 전수 조사 (Incomplete Pages Audit)

조사 일시: 2026-07-12
검색 패턴: `"이 화면은 곧 실제 데이터로 채워집니다"`, `"이 화면은 준비 중입니다"`, `준비중`, `추후 제공`, `Coming soon`, `TBD`, `tbd:`
대상: `app/views/app/**/*.erb` (사업자 화면 전체)

---

## 1. 결과: placeholder 화면 19개 (사업자 영역)

모두 동일 패턴 (5번 줄 + 9번 줄):

```erb
<p class="mt-1 text-sm text-slate-500">이 화면은 곧 실제 데이터로 채워집니다. 페이지를 확인한 뒤 개선 사항을 알려주세요.</p>
...
<p class="text-sm text-slate-500">이 화면은 준비 중입니다.</p>
```

| # | 파일 | 컨트롤러 액션 | 신규 IA 매핑 | 처리 |
|--:|------|-------------|------------|------|
| 1 | `app/views/app/reports/show.html.erb` | `reports#show` | 보고서 상세 (신규) | **실제 구현** (일일/주간/월간 자연어) |
| 2 | `app/views/app/services/show.html.erb` | `services#show` | 매장 정보 > 서비스 상세 | **실제 구현** 또는 **삭제** (Product/Service 통합) |
| 3 | `app/views/app/services/index.html.erb` | `services#index` | 매장 정보 > 서비스 목록 | **실제 구현** 또는 **삭제** |
| 4 | `app/views/app/conversations/show.html.erb` | `conversations#show` | 고객 문의 상세 | **실제 구현** (필수) |
| 5 | `app/views/app/deletion_requests/index.html.erb` | `deletion_requests#index` | 계정·지원 > 데이터 삭제 요청 | **실제 구현** |
| 6 | `app/views/app/deletion_requests/new.html.erb` | `deletion_requests#new` | 계정·지원 > 데이터 삭제 신청서 | **실제 구현** |
| 7 | `app/views/app/deletion_requests/show.html.erb` | `deletion_requests#show` | 데이터 삭제 요청 상세 | **실제 구현** |
| 8 | `app/views/app/content_items/pending_for_review.html.erb` | `content_items#pending_for_review` | 확인할 일 (탭 통합) | **라우트 제거** (대시보드/콘텐츠/확인할 일로 흡수) |
| 9 | `app/views/app/automation_executions/index.html.erb` | `automation_executions#index` | 운영자 콘솔 > 모니터링 | **삭제** (라우트도 제거) |
| 10 | `app/views/app/automation_executions/show.html.erb` | `automation_executions#show` | 운영자 콘솔 > 모니터링 | **삭제** |
| 11 | `app/views/app/data_exports/new.html.erb` | `data_exports#new` | 계정·지원 > 데이터 내보내기 신청 | **실제 구현** |
| 12 | `app/views/app/terminations/new.html.erb` | `terminations#new` | 계정·지원 > 해지 신청서 | **실제 구현** (필수) |
| 13 | `app/views/app/automation_rules/dashboard.html.erb` | `automation_rules#dashboard` | 운영자 콘솔 > 자동화 | **삭제** (라우트도 제거) |
| 14 | `app/views/app/handoffs/show.html.erb` | `handoffs#show` | 확인할 일 상세 | **실제 구현** (필수) |
| 15 | `app/views/app/faqs/show.html.erb` | `faqs#show` | 매장 정보 > FAQ 상세 | **삭제** (FAQ 목록+편집만 매장 정보 안에) |
| 16 | `app/views/app/business_profiles/edit.html.erb` | `business_profiles#edit` | 매장 정보 수정 | **실제 구현** (필수) |
| 17 | `app/views/app/products/show.html.erb` | `products#show` | 매장 정보 > 상품 상세 | **삭제** (Product/Service 통합) |
| 18 | `app/views/app/referrals/index.html.erb` | `referrals#index` | (없음) | **삭제** (셀프 추천 제거) |
| 19 | `app/views/app/plans/index.html.erb` | `plans#index` | (없음) | **삭제** (셀프 결제 제거) |

**총 19개 중**:
- **실제 구현 필수**: 9개 (1, 4, 5, 6, 7, 11, 12, 14, 16)
- **삭제 (라우트 + 뷰)**: 9개 (2, 3, 8, 9, 10, 13, 15, 17, 18, 19)
- **신규 IA로 흡수 통합**: 1개 (8 — `pending_for_review`는 "확인할 일" 탭의 첫 항목으로)

---

## 2. 기타 placeholder 후보

### 2.1 form input placeholder (정상)
form input 예시 텍스트는 placeholder가 아니므로 정상. 예: `placeholder: "예: 가격, 영업시간, 예약"` (FAQs new), `placeholder: "예: 2026 봄 시즌 메뉴판"` (KnowledgeSources new) 등.

### 2.2 AI 직원 편집 페이지 (placeholder 아님, 정상 구현)

`app/views/app/ai_employees/new.html.erb`, `edit.html.erb`는 placeholder가 아니지만 **사장님이 직접 페르소나 빌더를 사용**하는 구조. 리뉴얼 후 운영자 콘솔로 이동.

### 2.3 사업장 프로필 신규 (아직 라우트 없음)

현재 `BusinessProfile`은 show/edit만 있고 신규 생성 라우트 없음. account 생성 시 자동 빌드 (`@current_account.build_business_profile`). 신규 IA에서 "매장 정보" 페이지 진입 시 자동 생성/로드.

### 2.4 셋업 마법사 (전혀 없음)

`/app/onboarding/wizard` 라우트 없음. 신규 IA에서 신규 구축.

### 2.5 "소희 소개" 페이지 (전혀 없음)

`/app/sohee` 또는 `/app/store_infos#sohee` 라우트 없음. 신규 IA에서 신규 구축.

### 2.6 오늘의 보고 (자연어 요약)

`/app/dashboard`에 자연어 요약 영역 없음. `DailyReport` 또는 `WeeklyReport` 모델은 존재하지만 뷰 미연결. 신규 IA에서 자연어 요약 3~5줄 카드 신설.

---

## 3. 우선순위

### P0 (리뉴얼 1차 — 즉시 구현)
- `business_profiles/edit.html.erb` → 실제 폼
- `terminations/new.html.erb` → 실제 신청서
- `conversations/show.html.erb` → 실제 상세
- `handoffs/show.html.erb` → 실제 상세
- `pending_for_review.html.erb` → 라우트 제거 (확인할 일 탭으로 흡수)
- `plans/index.html.erb` → 라우트/뷰 제거

### P1 (리뉴얼 2차)
- `data_exports/new.html.erb` → 실제 폼
- `deletion_requests/{new,show,index}.html.erb` → 실제 폼/목록
- `reports/show.html.erb` → 실제 상세

### P2 (리뉴얼 3차)
- `services/{show,index}.html.erb` → 삭제 (Product로 통합)
- `products/show.html.erb` → 삭제 (인덱스 + 매장 정보 통합 뷰)
- `faqs/show.html.erb` → 삭제
- `referrals/index.html.erb` → 삭제
- `automation_rules/dashboard.html.erb` + 라우트 삭제
- `automation_executions/{index,show}.html.erb` + 라우트 삭제

---

## 4. 운영자 콘솔 placeholder (별도 검토 필요)

운영자 콘솔은 별도 검색 필요. `/platform` 하위 placeholder 패턴은 동일 패턴 사용 가능. 본 audit에서는 사업자 영역에 집중.

---

## 5. 신규 추가 페이지 (placeholder 아님, 신규 구축)

| 신규 페이지 | 위치 | 핵심 기능 |
|------------|------|----------|
| 오늘 | `app/views/app/dashboards/show.html.erb` (재구성) | 소희 상태 + 4개 카드 + 타임라인 + 오늘의 보고 |
| 확인할 일 | `app/views/app/confirmations/index.html.erb` | 탭 3개 + 7개 항목 유형 |
| 콘텐츠 (재구성) | `app/views/app/content_items/index.html.erb` | 탭 4개 + 수정 요청 사유 |
| 고객 문의 (재구성) | `app/views/app/conversations/index.html.erb` | 탭 3개 + 자연어 인계 사유 |
| 보고서 (재구성) | `app/views/app/reports/index.html.erb` | 일일/주간/월간, AI 비용/raw 점수 삭제 |
| 매장 정보 | `app/views/app/store_infos/show.html.erb` | 10개 섹션 |
| 소희 소개 | `app/views/app/sohee/show.html.erb` | 이름/역할/말투/담당/최근 업데이트 |
| 셋업 마법사 | `app/views/app/onboarding/wizard.html.erb` | 10단계 |