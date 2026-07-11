import { test, expect } from "@playwright/test";

/**
 * 외부 도메인에서 관리자 페이지 로그인이 정상 동작하는지 검증.
 *
 * 검증 케이스:
 *   1) cloudflared 도메인 + demo 계정 → /app 200
 *   2) cloudflared 도메인 + 바이름 계정 → /app 200
 *   3) ngrok 도메인 + 바이름 계정 → /app 200
 *
 * 사전 조건:
 *   - puma가 127.0.0.1:3001 살아있어야 함 (이미 외부 터널이 puma로 forward 중)
 */
const accounts = [
  { label: "demo (owner@demo.example)", slug: "owner@demo.example", expected: "오늘 소희가 한 일" },
  { label: "byreum (byreum@soheeproject.example)", slug: "byreum@soheeproject.example", expected: "바이름 청라점" },
];

const domains = [
  { name: "cloudflared", base: "https://mines-lightbox-seal-code.trycloudflare.com" },
  { name: "ngrok",       base: "https://luminance-suitor-garden.ngrok-free.dev" },
];

for (const domain of domains) {
  for (const acct of accounts) {
    test(`외부 로그인 - ${domain.name} - ${acct.label}`, async ({ page }) => {
      // ngrok 무료 도메인은 ERR_NGROK_6024 경고 페이지를 보냄.
      // 헤더 'ngrok-skip-browser-warning: true'로 우회 (ngrok 공식 지원).
      if (domain.name === "ngrok") {
        await page.setExtraHTTPHeaders({
          "ngrok-skip-browser-warning": "true",
        });
      }

      // 1) /login 페이지 진입
      await page.goto(`${domain.base}/login`, { waitUntil: "domcontentloaded" });
      // 로그인 폼이 보일 때까지 대기
      await page.waitForSelector('input[name="account_or_email"]', { timeout: 15_000 });
      await expect(page).toHaveTitle(/Sohee Project|로그인/);

      // 2) 폼 작성 + 제출 (rate limit 대비 1회 재시도)
      await page.fill('input[name="account_or_email"]', acct.slug);
      await page.fill('input[name="password"]', "OwnerPass!23");
      await page.click('input[type="submit"][value="로그인"]');

      // 429 (rate limit) 응답 시 잠시 대기 후 재시도
      for (let retry = 0; retry < 2; retry++) {
        try {
          await page.waitForURL(/\/app/, { timeout: 8_000 });
          break;
        } catch (e) {
          const body = await page.textContent("body").catch(() => "");
          if (body?.includes("요청이 너무 많습니다")) {
            await page.waitForTimeout(15_000);
            await page.goto(`${domain.base}/login`, { waitUntil: "domcontentloaded" });
            await page.waitForSelector('input[name="account_or_email"]', { timeout: 10_000 });
            await page.fill('input[name="account_or_email"]', acct.slug);
            await page.fill('input[name="password"]', "OwnerPass!23");
            await page.click('input[type="submit"][value="로그인"]');
          } else {
            throw e;
          }
        }
      }

      // 3) /app으로 redirect되어 도달해야 함
      await page.waitForURL(/\/app$/, { timeout: 10_000 });
      await expect(page).toHaveURL(new RegExp(`${domain.base.replace(/\//g, "\\/")}\/app`));

      // 4) 대시보드 핵심 텍스트 노출 확인
      const body = await page.textContent("body");
      expect(body).toContain("소희");
      expect(body).toContain(acct.expected);
    });
  }
}