// 2026-07-12 P0-1 리뉴얼: 셀프 회원가입 + 14일 trial 폐쇄.
// 신규 고객사는 도입 상담(/contact) 후 운영팀이 Platform::AccountsController#create로 등록한다.
// → /signup GET은 /contact로 redirect, POST는 410 Gone으로 응답.
// 이 스펙은 더 이상 유효하지 않으므로 전체 비활성화. 운영자 시나리오 신규 스펙은 별도 작성 예정.
import { test, expect } from "@playwright/test";

test.describe.skip("사업자 셀프 회원가입 + 14일 trial (폐쇄됨)", () => {
  test("placeholder", async () => {
    expect(true).toBe(true);
  });
});