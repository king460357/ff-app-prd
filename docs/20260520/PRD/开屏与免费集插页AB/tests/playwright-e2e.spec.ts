/**
 * 派生自 20260520_开屏与免费集插页AB_PRD.md
 * - 开屏实验验收：5.1.9
 * - 插页实验验收：5.2.8
 * TODO: 绑定 FlareFlow App 测试包与 AB 参数 mock 后再执行
 */
import { test, expect } from '@playwright/test';

/** 开屏实验参数：0=对照组，1=实验组 A（对应 ios/android_open_ads-test） */
const splashParam = Number(process.env.AB_SPLASH_PARAM ?? '0');
/** 插页实验参数：0=对照组，1=实验组 A（对应 ios/android_free_interstitial-test） */
const interstitialParam = Number(process.env.AB_INTERSTITIAL_PARAM ?? '0');

test.describe('开屏实验 S-01', () => {
  test('参数0不播开屏广告', async ({ page }) => {
    test.skip(splashParam !== 0, '仅参数 0（对照组）');
    await page.goto('/');
    await expect(page.locator('[data-testid="splash-ad"]')).toHaveCount(0);
    // 参数 0：若运营开屏命中可出现 ops-splash（由 fixture 控制）
  });

  test('参数1有缓存仅开屏广告且无运营开屏', async ({ page }) => {
    test.skip(splashParam !== 1, '仅参数 1（实验组 A）');
    await page.goto('/');
    await expect(page.locator('[data-testid="splash-ad"]')).toBeVisible();
    await page.locator('[data-testid="splash-ad-close"]').click();
    await expect(page.locator('[data-testid="home"]')).toBeVisible();
    await expect(page.locator('[data-testid="ops-splash"]')).toHaveCount(0);
  });

  test('参数1无缓存直进首页且无运营开屏', async ({ page }) => {
    test.skip(splashParam !== 1, '仅参数 1（实验组 A）');
    test.skip(!process.env.E2E_NO_SPLASH_CACHE, '需无开屏广告缓存 fixture');
    const t0 = Date.now();
    await page.goto('/');
    await expect(page.locator('[data-testid="home"]')).toBeVisible({ timeout: 7000 });
    expect(Date.now() - t0).toBeLessThanOrEqual(7000);
    await expect(page.locator('[data-testid="splash-ad"]')).toHaveCount(0);
    await expect(page.locator('[data-testid="ops-splash"]')).toHaveCount(0);
  });
});

test.describe('插页实验 I-01', () => {
  test('参数0播放免费剧集时不插页', async ({ page }) => {
    test.skip(interstitialParam !== 0, '仅参数 0（对照组）');
    await page.goto('/player?drama=fixture&ep=4');
    await expect(page.locator('[data-testid="immersion-interstitial"]')).toHaveCount(0);
  });

  test('参数1在第4集有缓存时插页', async ({ page }) => {
    test.skip(interstitialParam !== 1, '仅参数 1（实验组 A）');
    await page.goto('/player?drama=fixture&ep=4');
    await expect(page.locator('[data-testid="immersion-interstitial"]')).toBeVisible();
    await page.locator('[data-testid="immersion-interstitial-close"]').click();
    await expect(page.locator('[data-testid="player-episode"]')).toHaveAttribute(
      'data-episode',
      '4'
    );
  });

  test('参数1第3集不插页', async ({ page }) => {
    test.skip(interstitialParam !== 1, '仅参数 1（实验组 A）');
    await page.goto('/player?drama=fixture&ep=3');
    await expect(page.locator('[data-testid="immersion-interstitial"]')).toHaveCount(0);
  });

  test('无缓存不挡播放', async ({ page }) => {
    test.skip(interstitialParam !== 1, '仅参数 1（实验组 A）');
    test.skip(!process.env.E2E_NO_INTERSTITIAL_CACHE, '需无插页缓存 fixture');
    const t0 = Date.now();
    await page.goto('/player?drama=fixture&ep=2');
    await expect(page.locator('[data-testid="player-playing"]')).toBeVisible({ timeout: 500 });
    expect(Date.now() - t0).toBeLessThanOrEqual(500);
    await expect(page.locator('[data-testid="immersion-interstitial"]')).toHaveCount(0);
  });
});
