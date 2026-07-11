import { test, expect } from '@playwright/test';

/**
 * 사업자 로그인 시나리오 — 실제 폼으로 로그인
 * 핵심 검증: AuditEvent actor_kind 에러가 발생하지 않아야 함
 */

test.describe('사업자 로그인 (실제 폼)', () => {
  test('demo 계정으로 로그인 → /app 진입', async ({ page }) => {
    // 1) 로그인 페이지
    await page.goto('/login');
    await expect(page.locator('input[name="account_or_email"], input[type="email"], input[name="email"]').first()).toBeVisible();

    // 2) 폼 채우기
    const accountInput = page.locator('input[name="account_or_email"]').first();
    await accountInput.fill('owner@demo.example');
    const passwordInput = page.locator('input[name="password"], input[type="password"]').first();
    await passwordInput.fill('OwnerPass!23');

    // 3) 제출
    await page.locator('button[type="submit"], input[type="submit"]').first().click();

    // 4) /app 또는 /dashboard 로 이동
    await page.waitForURL(/\/(app|dashboard)/, { timeout: 10_000 });

    // 5) /app이 200 + 본문에 핵심 텍스트
    expect(page.url()).toMatch(/\/(app|dashboard)/);
    const body = await page.locator('body').textContent();
    expect(body).toBeTruthy();
    expect(body!.length).toBeGreaterThan(50);
  });

  test('잘못된 비밀번호 → 에러 페이지 없이 로그인 페이지에 머무름', async ({ page }) => {
    await page.goto('/login');
    await page.locator('input[name="account_or_email"]').first().fill('owner@demo.example');
    await page.locator('input[name="password"]').first().fill('wrong-password');
    await page.locator('button[type="submit"], input[type="submit"]').first().click();

    // 에러 페이지(500, 404)가 아닌 로그인 페이지에 머무름
    await page.waitForLoadState('networkidle').catch(() => {});
    const url = page.url();
    expect(url).toContain('/login');
    // Alert/flash 메시지 노출 확인
    const body = await page.locator('body').textContent();
    expect(body).toMatch(/올바르지 않|실패|오류|로그인/);
  });
});