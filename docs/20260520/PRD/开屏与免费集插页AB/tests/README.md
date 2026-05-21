# Tests · 开屏与免费集插页 AB

本目录为 PRD Gherkin 派生的 **Playwright 骨架**，需在集成真实 App 或 staging 环境后补充 selector 与 **AB 参数 mock**（0/1）。

**阅读顺序**：先跑/先 mock **开屏实验（S-01）**，再 **插页实验（I-01）**——与主 PRD 第 5 章一致。

```bash
# 安装后于本目录执行（需项目已配置 Playwright）
npx playwright test playwright-e2e.spec.ts
```

## 环境变量

### 实验参数（0 = 对照组，1 = 实验组 A）

| 变量 | 说明 | 示例 |
|------|------|------|
| `AB_SPLASH_PARAM` | `ios/android_open_ads-test` 下发值 | `0` 或 `1` |
| `AB_INTERSTITIAL_PARAM` | `ios/android_free_interstitial-test` 下发值 | `0` 或 `1` |

### 可选 fixture（否则对应用例 test.skip）

| 变量 | 对应用例 |
|------|----------|
| `E2E_NO_SPLASH_CACHE=1` | 参数1无缓存直进首页且无运营开屏 |
| `E2E_NO_INTERSTITIAL_CACHE=1` | 无缓存不挡播放 |

## 示例

```bash
# 只测开屏实验 · 参数 1
AB_SPLASH_PARAM=1 npx playwright test playwright-e2e.spec.ts -g "开屏实验"

# 只测插页实验 · 参数 0
AB_INTERSTITIAL_PARAM=0 npx playwright test playwright-e2e.spec.ts -g "插页实验"
```

## data-testid（占位，实现时以 App 为准）

| testid | 含义 |
|--------|------|
| `splash-ad` | 开屏广告全屏 |
| `splash-ad-close` | 关闭开屏广告 |
| `ops-splash` | 运营开屏 |
| `home` | 首页 |
| `immersion-interstitial` | 播放页全屏插页 |
| `immersion-interstitial-close` | 关闭插页 |
| `player-episode` / `player-playing` | 播放页集数/正片播放中 |
