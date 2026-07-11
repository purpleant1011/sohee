import { test, expect } from '@playwright/test';

/**
 * 공개 사이트 핵심 여정 (3차 리뉴얼 정책)
 * 핵심 CTA = "초기 도입 상담 신청하기" → /contact
 * 회원가입 셀프 흐름은 비활성화 → 운영팀 초대 기반
 */

test.describe('공개 사이트 스모크', () => {
  test('랜딩 페이지가 200 + 핵심 CTA 노출', async ({ page, baseURL }) => {
    const isGhPages = baseURL?.includes('github.io');
    const url = isGhPages ? `${baseURL}/` : '/';
    const res = await page.goto(url);
    expect(res?.status()).toBe(200);
    if (isGhPages) {
      // GitHub Pages landing: "초기 도입 상담 신청하기"
      const cta = page.locator('text=/초기 도입 상담 신청/').first();
      await expect(cta).toBeVisible();
    } else {
      // 백엔드 landing: "초기 도입 상담 신청하기" 또는 contact 링크
      const cta = page.locator('a[href="/contact"], a[href*="contact"]').first();
      await expect(cta).toBeVisible();
    }
  });

  test('가격 페이지 핵심 섹션 표시 (정식 가격 정책 준비 중)', async ({ page }) => {
    await page.goto('/pricing');
    const body = await page.locator('body').textContent();
    expect(body).toMatch(/가격|요금|준비|협의/i);
    // 가격(원/월) 직접 표기 금지
    expect(body).not.toMatch(/월\s*\d{1,3}(,\d{3})*\s*원/);
  });

  test('회원가입 셀프 흐름은 /contact 로 안내', async ({ page }) => {
    const res = await page.goto('/signup');
    expect(res?.status()).toBeGreaterThanOrEqual(200);
    // /signup → /contact 301 또는 contact 안내 페이지
    await page.waitForLoadState('networkidle');
    const body = await page.locator('body').textContent();
    expect(body).toMatch(/상담|contact|초기 도입/i);
  });
});

test.describe('공개 사이트 위험 노출 방지', () => {
  test('운영사 이름/임시 도메인/데모계정이 공개 페이지에 노출되지 않음', async ({ page, request, baseURL }) => {
    const urls = ['/', '/pricing', '/case-studies', '/industries', '/contact', '/p/terms', '/p/privacy'];
    for (const path of urls) {
      const res = await page.goto(`${baseURL}${path}`);
      expect(res?.status()).toBe(200);
      const body = await page.locator('body').textContent();
      expect(body).not.toMatch(/바이름|청라|이아름|퍼플앤트|김선영|byreum|chungra/);
      expect(body).not.toMatch(/hello@soheeproject\.example|owner@demo\.example/);
      expect(body).not.toMatch(/trycloudflare|ngrok-free\.dev/);
    }
  });
});