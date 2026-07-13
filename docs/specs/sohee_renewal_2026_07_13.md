# 소희 프로젝트 통합 운영 허브 대대적 리뉴얼 (2026-07-13 호스트 명세)

> 본 문서는 호스트(hochari) 가 2026-07-13 에 보낸 **명세(spec) 문서** 원본이다.
> 자동 작업은 수행하지 않으며, 호스트의 **단계별 승인**을 받은 후에만 해당 단계만 진행한다.
> 영구 운영 원칙 #2 (자동 대량 리팩토링 거부) 적용.

---

# 프로젝트
소희 프로젝트 통합 운영 허브 대대적 리뉴얼

# 대상 저장소
purpleant1011/sohee

# 공개 사이트
https://purpleant1011.github.io/sohee/

# 사업자 관리자
https://blast-twins-finish-polyphonic.trycloudflare.com/app/login

# 테스트 사업자 계정
이메일: byreum-cheongna@soheeproject.example
비밀번호: OwnerPass!23

비밀번호와 인증 정보는 코드, 문서, 커밋, 스크린샷, 로그에 기록하지 마라.

────────────────────────────────────
0. 이번 작업의 최종 목표
────────────────────────────────────

현재 소희 프로젝트는 다음 문제가 혼재되어 있다.

1. 랜딩페이지가 구매 설득, 기술 설명, 관리자 설명을 동시에 수행한다.
2. 공개 랜딩의 로그인 URL이 오래된 Quick Tunnel을 가리킬 수 있다.
3. 셀프 회원가입과 14일 무료 체험 문구가 실제 정책과 충돌한다.
4. 사업자 페이지에 원장이 관리할 필요가 없는 설정이 많다.
5. 앱 레이아웃과 페이지별 여백·폭·컴포넌트가 일관되지 않다.
6. Discord 연동 백엔드는 존재하지만 고객 경험과 운영 허브에 통합되지 않았다.
7. SNS 채널 페이지가 단순 CRUD 수준이며 운영 상태를 통합해서 보여주지 못한다.
8. Hermes, Discord, SNS, Rails DB의 상태가 하나의 화면에서 연결되지 않았다.

이번 리뉴얼의 목적은 다음과 같다.

- 공개 랜딩은 서비스의 가치와 도입 상담에만 집중한다.
- 사업자 포털은 원장이 결과를 확인하고 필요한 판단만 하는 공간이 된다.
- Discord는 원장과 소희가 대화하고 소희를 교육하는 공식 채널이 된다.
- Rails는 검증된 사업장 정보와 설정의 Source of Truth가 된다.
- Hermes는 Runtime Config에 따라 업무를 실행하는 오케스트레이터가 된다.
- Instagram, Threads, Blog, Discord를 하나의 Integration Hub에서 관리한다.
- 운영자 콘솔과 사업자 포털을 명확히 분리한다.

핵심 제품 원칙:

"복잡한 설정은 운영팀과 Hermes가 감당한다.
원장에게는 소희가 한 일과 원장이 판단해야 할 일만 보여준다."

────────────────────────────────────
1. 수정 전 전수 조사
────────────────────────────────────

수정하기 전에 다음을 수행하라.

1. 저장소 main 브랜치를 최신화한다.
2. 별도 feature branch를 만든다.
3. 현재 공개 랜딩을 데스크톱과 모바일에서 캡처한다.
4. 제공된 계정으로 관리자에 로그인한다.
5. 사업자 사이드바의 모든 페이지를 직접 연다.
6. 각 화면을 1440px, 768px, 390px에서 캡처한다.
7. Rails routes를 출력한다.
8. /app, /platform, /api/v1의 모든 라우트를 분류한다.
9. 현재 Discord 모델·Job·API·Worker 상태를 확인한다.
10. Instagram·Threads·Blog 관련 모델·서비스·워커를 확인한다.
11. placeholder, 오류 페이지, 깨진 링크를 전수 조사한다.
12. 공개 사이트의 모든 trycloudflare 링크를 검색한다.
13. 고객 계정이나 실제 비밀번호가 저장소에 포함됐는지 검색한다.

검색 키워드:
trycloudflare, 14일 무료, 셀프 회원가입, RAG, sohee_basic, sohee_salon, quick tunnel,
DISCORD_CHANNEL_ID, DiscordWorkspace, DiscordIdentity, ChangeProposal, AntigravityClient,
instagram, threads, naver_blog, channel_connection, external_id, scope, runtime, heartbeat,
checksum, dev_login, OwnerPass, byreum-cheongna

다음 감사 문서를 먼저 작성한다.
- docs/audits/landing_renewal_audit.md
- docs/audits/business_portal_ui_audit.md
- docs/audits/discord_integration_audit.md
- docs/audits/social_integration_audit.md
- docs/audits/layout_design_system_audit.md
- docs/audits/broken_links_and_routes.md

감사 문서가 완료되기 전에는 대규모 코드를 수정하지 마라.

────────────────────────────────────
2. 공개 랜딩 리뉴얼
────────────────────────────────────

랜딩의 역할은 고객 설득과 도입 상담이다. 기술 설명서처럼 만들지 마라.

공개 랜딩에서 제거하거나 운영자 문서로 이동:
- RAG, 페르소나 내부 키, sohee_basic/sohee_cafe/sohee_salon/sohee_expert
- Runtime, 스킬 내부 구조, 운영 로그, 테스트 랩 기술 설명
- 자동화 엔진의 상세 설정, 관리자 내부 메뉴 나열
- 셀프 회원가입, 14일 무료 체험, Quick Tunnel 안내, 개발 환경 안내, 오래된 로그인 링크

랜딩의 최종 구성:
1. Hero
2. 원장님의 현실
3. 소희가 맡는 일
4. 교육·셀프툴·대행과의 차이
5. 소희와 일하는 방식
6. Discord에서 소희와 대화하는 모습
7. 안전한 테스트 → 공식 전환
8. 익명 파일럿 사례
9. 운영 가능한 채널
10. 가격 준비 중
11. FAQ
12. 도입 상담

────────────────────────────────────
3. 로그인·도메인 구조
────────────────────────────────────

공개 랜딩에 Quick Tunnel URL을 직접 하드코딩하지 마라.

권장 환경변수:
- SOHEE_PUBLIC_URL
- SOHEE_APP_URL
- SOHEE_OPERATOR_URL
- SOHEE_API_URL
- SOHEE_DISCORD_INVITE_URL

GitHub Pages 빌드 시 SOHEE_APP_URL을 주입한다.

────────────────────────────────────
4. 디자인 시스템과 레이아웃 수정
────────────────────────────────────

현재 app layout의 flex 구조를 수정한다 (셋업 준비도, aside, main 동일 flex 형제 문제).

최종 구조:
```
<body>
  <header class="topbar" />
  <div class="app-shell">
    <aside class="sidebar" />
    <main class="app-main">
      <%= render setup_status if onboarding? %>
      <%= yield %>
    </main>
  </div>
</body>
```

레이아웃 규칙:
- app-shell max-width: 1440px
- sidebar width: 240px
- main min-width: 0
- PageHeader / Card / StatusBadge / EmptyState / Alert / SectionHeader / ConfirmDialog 공통 컴포넌트
- 페이지별 임의 max-w-* / p-* / py-* 사용 제거
- Tailwind CDN을 프로덕션에서 제거, Rails asset pipeline 사용

────────────────────────────────────
5. 사업자 포털의 최종 IA
────────────────────────────────────

원장용 메뉴 7개로 제한:
1. 오늘
2. 확인할 일
3. 콘텐츠
4. 고객 문의
5. 연결 상태
6. 보고서
7. 매장 정보·지원

AI 직원 생성, RAG, 자동화 설정, Runtime, Audit 등은 사업자 메뉴에서 제거.

상단 상시 표시:
- 소희 상태
- 원장님 확인 필요 건수
- Discord에서 소희와 대화하기
- 긴급 일시중지

────────────────────────────────────
6. 오늘 대시보드
────────────────────────────────────

대시보드 최종 질문 4개:
- 소희가 정상적으로 일하고 있는가?
- 오늘 무엇을 했는가?
- 내가 볼 것이 있는가?
- 다음 업무는 무엇인가?

소희 상태: 정상 운영 중 / 테스트 중 / 확인 필요 / 운영팀 점검 중 / 일시중지

────────────────────────────────────
7~17. 확인할 일 / 콘텐츠 / 고객 문의 / Integration Hub / Discord UX / SNS 통합 / 테스트-공식 분리
────────────────────────────────────

(원본 명세 참조 - 21섹션 전체)

────────────────────────────────────
18. 구현 우선순위
────────────────────────────────────

- P0: 즉시 수정 (오래된 로그인, 무료체험, layout flex 오류, 모바일, 내부용어, 개인정보 검색, production dev_login 차단)
- P1: 사업자 UI (사이드바 7개, 대시보드, 확인할 일, 콘텐츠, 문의, 연결 상태, 보고서, 매장정보, Discord CTA)
- P2: Discord 완성 (사업장별 채널, Gemini intent, DB Diff, 승인 카드, Runtime 반영, Hermes ACK, 양방향 동기화)
- P3: Integration Hub (Instagram/Threads/Discord/Blog 공통, test/official 분리)
- P4: 운영자 콘솔
- P5: 랜딩 동적 상태

────────────────────────────────────
19. 테스트
────────────────────────────────────

공개 랜딩 / 사업자 포털 / Discord / SNS 각각에 대한 시나리오 테스트.

────────────────────────────────────
20. 완료 기준
────────────────────────────────────

원장 포털은 5초 안에 다음을 이해할 수 있어야 한다.
- 소희가 정상인가
- 오늘 무엇을 했는가
- 내가 할 일이 있는가
- 다음 업무는 무엇인가
- 소희와 어디서 대화하는가

랜딩 방문자는 5초 안에 다음을 이해해야 한다.
- 누구를 위한 서비스인가
- 어떤 일을 대신하는가
- 교육이나 셀프툴과 어떻게 다른가
- 어떻게 도입하는가

Integration Hub는 10초 안에 다음을 보여야 한다.
- Discord/Instagram/Threads 연결 상태
- 테스트/공식 여부
- 최근 성공/실패
- 승인 대기
- 다음 실행
- 운영팀이 확인할 문제

────────────────────────────────────
21. 최종 보고
────────────────────────────────────

작업 완료 후 다음 21개 항목 형식으로 보고.

────────────────────────────────────
핵심 한 줄
────────────────────────────────────

> 소희 사이트는 설정이 많은 관리자 도구가 아니라,
> Discord에서 교육받은 소희가 SNS에서 일한 결과를 확인하고 통제하는 운영 허브가 되어야 합니다.

────────────────────────────────────
호스트의 메모 (2026-07-13, Hermes 작성)
────────────────────────────────────

- 본 명세는 영구 운영 원칙 #2 (자동 대량 리팩토링 거부) 적용 대상
- 자동 코드 수정 안 함
- 호스트의 단계별 승인 (예: "P0 부터 해", "audit 먼저 작성해") 대기
- 이전 자동 작업 (t1~t11) 의 산출물:
  - 바이름 계정 id=20, BP id=15, 시드 완료
  - 9개 신규 마이그 + 9 모델 + 4 컨트롤러 + 11 라우트 (바이름 참고 채널 분석)
  - 소희 외부 접속 URL: https://blast-twins-finish-polyphonic.trycloudflare.com/
