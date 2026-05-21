# 写前规格摘要 · 开屏与免费集插页 AB

> 来源：用户确认草案（2026-05-20）+ 竞品 `AD_LOGIC_白话版` + 历史索引

## 历史交集

| 来源 | 摘要 | 本期 |
|------|------|------|
| `_EXTRACTED_INDEX` | `app_open`、`immersion_free_int` 等广告位 | 复用埋点/广告位命名 |
| `20260513_待解锁页广告解锁改插页_PRD` | 待解锁页插页解锁 | **不重叠** |
| `20260513_访客模式与游客身份_PRD` | 访客不 init 广告 | 豁免访客 |
| 竞品 ReelShort | 开屏 inter_time 1min、max 10/会话；免费剧隔集插屏 | 开屏 A：仅开屏广告；插页：1–10 集隔 2 集 |
| FF 1.1 次缓存兜底 | 请求限时 **2 秒** | 并入 1.2.6 的 2 秒段；adloading/Toast **本期未写入 PRD** |
| FF 1.2.6 开屏广告 | Logo **2s**；有缓存 **第 2s 后**展示；无缓存 **2s+延长 5s** | **已沿用**（PM 2026-05-20 确认） |

## 实验参数（默认 0）

### S-01 开屏 · `ios/android_open_ads-test`

| 参数 | 行为 |
|------|------|
| 0 | 仅运营开屏 |
| 1 | 仅开屏广告 |

**子开关默认**：`hot_start_enable=0`，`inter_time_sec=60`，`max_per_session=10`

### I-01 插页 · `ios/android_free_interstitial-test`

| 参数 | 行为 |
|------|------|
| 0 | 不插页 |
| 1 | 隔集插页 |

**子开关默认**：`start_episode=1`，`end_episode=10`，`interval_episodes=2`，`inter_time_sec=0`，`max_per_play_session=0`

## 豁免

有效订阅 / VIP、访客（未同意隐私）→ 两实验均不展示变现广告。
