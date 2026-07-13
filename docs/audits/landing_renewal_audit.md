# §1.1 랜딩 리뉴얼 audit (2026-07-13)

> 호스트 명세 §2 "공개 랜딩 리뉴얼" + §3 "로그인·도메인 구조" + §16 "랜딩과 실제 기능 일치" + §17 "보안" 의 전수 조사.

## 1. 공개 랜딩 파일

| 파일 | 위치 | 라인 | serve |
|---|---|---|---|
| `docs/index.html` | GitHub Pages root (sohee main) | 688 | `https://purpleant1011.github.io/sohee/` |
| `public/index.html` | Rails puma 정적 (trycloudflare) | 688 | `https://blast-twins-finish-polyphonic.trycloudflare.com/` |

두 파일은 **동일 내용** (양쪽 hash 동일). 차이 없음.

## 2. 명세 §2 — 공개 랜딩에서 제거해야 할 요소 (현재 잔존)

명세 §2 의 "공개 랜딩에서 제거하거나 운영자 문서로 이동" 항목 검사:

| 항목 | docs/index.html | public/index.html |
|---|---|---|
| `RAG` | 0건 (검색 OK) | 0건 |
| `sohee_basic` | 0건 (검색 OK) | 0건 |
| `sohee_salon` | 0건 | 0건 |
| `sohee_cafe` | 0건 | 0건 |
| `sohee_expert` | 0건 | 0건 |
| `Runtime` | 0건 (랜딩) | 0건 |
| `14일 무료` | **0건** (이미 제거됨) | **0건** |
| `셀프 회원가입` | **0건** (이미 제거됨) | **0건** |
| `Quick Tunnel` | 0건 | 0건 |
| 옛 trycloudflare URL | 0건 (peripheral 0) | 0건 (peripheral 0) |

✅ **내부 키/RAG/셀프 회원가입/14일 무료 체험 문구 = 0건** (랜딩에서). **이전 P0-2 리뉴얼에서 이미 처리됨**.

## 3. 명세 §3 — 로그인 URL 환경변수 처리

**현황**: 두 파일 모두 `<a class="nav-login" href="https://blast-twins-finish-polyphonic.trycloudflare.com/app/login">` 로 **하드코딩** 5곳 + JS `SOHEE_APP_HOST` 변수 1곳.

- ❌ **하드코딩 5건** (변경하려면 HTML 직접 수정)
- ❌ **GitHub Pages 빌드 시 환경변수 주입 안 됨**
- ❌ **`.env` 또는 `application.yml` 의 SOHEE_APP_URL 미정의**

**개선 필요**:
- HTML 빌드 시 환경변수 `SOHEE_APP_URL` 주입 (Jekyll 환경변수 또는 빌드 스크립트)
- 또는 GitHub Actions 에서 build 전 sed 치환
- 또는 정적 HTML → 정적 사이트 빌더로 전환 (의존성 ↑)

## 4. 명세 §16 — 공개 사이트와 실제 기능 일치

랜딩에서 "초기 적용" / "지원" 으로 표시된 채널/기능 검사:

| 랜딩 문구 | 실제 상태 | 일치 |
|---|---|---|
| Instagram / Threads / Naver Blog | Instagram/Threads 메타+본문 추출 가능, Naver Blog 2편 추출 OK | ⚠️ 실제 게시는 X, RAG context 용만 |
| Discord | 워커 proc 54013 동작 | ✅ |
| "RAG" (제거됨) | 사용 안 함 | ✅ |
| "스킬" (제거됨) | ContentSkill 모델 6건 draft | ✅ (랜딩에서 노출 X) |
| "자동화" | publisher_job 등 존재 | ✅ |
| "운영팀이 세팅" | SetupReadiness 자동 검사 | ✅ |

✅ **내부 키/메커니즘 = 랜딩에서 0건 노출**. 일관 OK.

## 5. 명세 §17 — 보안 (trycloudflare, 비밀번호, 토큰)

| 항목 | 상태 |
|---|---|
| trycloudflare URL 랜딩 노출 | ⚠️ 권장 X (영구 운영 X) — 현재 호스트 허용 |
| Discord Bot Token 노출 | `sohee_workers_env.sh` (로컬만), git 무추적 OK |
| 비밀번호 노출 (소스/문서) | ⚠️ **`docs/specs/sohee_renewal_2026_07_13.md` 와 다른 명세/audit 문서** 에 평문 (`OwnerPass!23`, `SuperSecret!23`, `pass1234!!`) 잔존. 시드 파일 `db/seeds.rb` 도 평문. |
| `reject_in_production!` 가드 | ✅ 존재 (`app/controllers/dev_overrides_controller.rb`) |
| 고객 개인정보/얼굴 | (별도 audit) |

**개선 필요 (P0)**:
- `docs/specs/sohee_renewal_2026_07_13.md` 의 평문 비밀번호 → **운영자가 보낸 원본이므로 유지하되, 이후 작성 문서는 평문 비밀번호 기록 금지** 정책
- `db/seeds.rb` 평문 = dev 시드 표준 (production deploy 시 별도 secret 사용)

## 6. 종합

| 항목 | 상태 |
|---|---|
| 내부 키 노출 | ✅ 0건 |
| 셀프 회원가입 / 14일 무료 | ✅ 0건 (P0-2 에서 제거) |
| 옛 trycloudflare URL | ✅ 0건 |
| 로그인 URL 하드코딩 | ❌ 5건 (env var 필요) |
| 비밀번호 평문 노출 | ⚠️ docs/specs + db/seeds.rb |
| dev_login production 차단 | ✅ reject_in_production! |
| 모바일 390px / OG metadata | (별도 캡처 후 audit 추가) |

**P0 조치 필요**:
1. HTML 빌드 시 SOHEE_APP_URL 환경변수 주입 (1회 작업, 이후 hostname 변경 자동)
2. (이미 완료) 옛 peripheral URL → blast-twins 로 5/5 변경
3. 정식 도메인 권장: cloudflare named tunnel 또는 정식 subdomain

## 7. 다음 단계

이 audit 결과로 P0 코드 수정 진행:
- §1.5: docs/specs 비밀번호 부분은 호스트가 보낸 원본 — **유지**, 향후 audit doc 은 redact
- P0 코드 수정 (HTML env var, layout flex, 모바일, 내부용어, production dev_login, 개인정보 검색)
