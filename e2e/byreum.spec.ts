import { test, expect } from '@playwright/test';

const BASE = 'http://127.0.0.1:3001';

test('소희 프로젝트: 바이름 청라점 대시보드/사이드바/사업장', async ({ page }) => {
  // 1. 사업자 로그인
  await page.request.post(`${BASE}/dev_login/business`, { form: { email: 'byreum@soheeproject.example' } });

  // 2. 대시보드
  await page.goto(`${BASE}/app`);
  await expect(page.locator('h1')).toContainText('운영 대시보드');
  await expect(page.locator('body')).toContainText('바이름 청라점');
  await expect(page.locator('body')).toContainText('오늘 소희가 한 일');
  await expect(page.locator('body')).toContainText('원장님 확인 필요');

  // 3. 사이드바 13개 메뉴 확인
  const menuItems = [
    '대시보드', 'AI 직원 (소희)', '사업장 프로필', '지식베이스', 'FAQ', '가격표',
    '채널 관리', '콘텐츠 캘린더', '문의 응대', '원장님 확인 필요', '자동화 루틴', '리포트', '운영 로그'
  ];
  for (const item of menuItems) {
    await expect(page.locator('aside').getByText(item, { exact: false }).first()).toBeVisible();
  }

  // 4. 사업장 프로필
  await page.goto(`${BASE}/app/business_profile`);
  await expect(page.locator('h1')).toContainText('사업장 프로필');
  await expect(page.locator('body')).toContainText('청라');
  await expect(page.locator('body')).toContainText('원장님께 인계');

  // 5. AI 직원
  await page.goto(`${BASE}/app/ai_employees`);
  await expect(page.locator('body')).toContainText('소희 페르소나 4가지');
  await expect(page.locator('body')).toContainText('소희 (기본)');

  // 6. 문의 응대
  await page.goto(`${BASE}/app/conversations`);
  await expect(page.locator('body')).toContainText('기초 안내');
  await expect(page.locator('body')).toContainText('원장님 확인');

  // 7. 원장님 확인 필요
  await page.goto(`${BASE}/app/handoffs`);
  await expect(page.locator('body')).toContainText('잔흔');
  await expect(page.locator('body')).toContainText('가격 조정');
});
