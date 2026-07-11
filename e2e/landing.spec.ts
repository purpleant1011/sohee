import { test, expect } from '@playwright/test';

/**
 * 랜딩 페이지 정책 검증 (3차 리뉴얼 — 2026-07-11)
 * - 로고: GitHub Pages /workmori/ 경로로 이동
 * - 명칭: "소희 프로젝트" → "sohee"
 * - 로그인: nav + footer에서 로그인 모달 진입 가능 (단일 CTA 정책과 별도 — 회원 진입 보장)
 */

test.describe('랜딩 페이지 정책 (sohee)', () => {
  test('로고가 /workmori/ 경로로 이동', async ({ page, baseURL }) => {
    const isGhPages = baseURL?.includes('github.io');
    const url = isGhPages ? `${baseURL}/` : '/';
    await page.goto(url);
    const logo = page.locator('header a.logo').first();
    await expect(logo).toBeVisible();
    const href = await logo.getAttribute('href');
    expect(href).toMatch(/\/workmori\/?$/);
  });

  test('로고 텍스트가 sohee', async ({ page }) => {
    await page.goto('/');
    const logo = page.locator('header a.logo').first();
    const text = (await logo.textContent()) ?? '';
    expect(text).toMatch(/sohee/);
    // 옛 명칭 "소희 프로젝트"는 로고에서 제거
    expect(text).not.toMatch(/소희\s*프로젝트/);
  });

  test('nav에 로그인 버튼이 노출되고 모달을 연다', async ({ page }) => {
    await page.goto('/');
    const navLogin = page.locator('a.nav-login');
    await expect(navLogin).toBeVisible();
    await navLogin.click();
    const modal = page.locator('#login-modal');
    await expect(modal).toBeVisible();
    await expect(page.locator('#login-title')).toContainText(/소희 작업실 로그인/);
    await expect(page.locator('#login-account')).toBeVisible();
    await expect(page.locator('#login-password')).toBeVisible();
  });

  test('로그인 모달은 ESC로 닫힌다', async ({ page }) => {
    await page.goto('/');
    await page.locator('a.nav-login').click();
    await expect(page.locator('#login-modal')).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(page.locator('#login-modal')).toBeHidden();
  });

  test('footer에 회원 > 로그인 항목이 있다', async ({ page }) => {
    await page.goto('/');
    const footer = page.locator('footer');
    await expect(footer).toContainText('회원');
    await expect(footer.locator('a', { hasText: '로그인' })).toHaveCount(1);
  });
});