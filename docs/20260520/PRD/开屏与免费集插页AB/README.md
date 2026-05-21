# FlareFlow · 开屏与免费集插页 AB · PRD（P1 / 20260520）

| 文件 | 用途 |
|------|------|
| `20260520_开屏与免费集插页AB_PRD.md` | **真理源**（AI / 研发 / QA） |
| `requirements-spec.md` | 研发精简 spec（由 PRD 派生） |
| `test-coverage-report.md` | PRD ↔ 测试双向校验报告 |
| `tests/` | Playwright 骨架（Gherkin 派生） |

## 实验 Key 与参数速查

| 实验 | iOS key | Android key | 参数 0 | 参数 1 |
|------|---------|-------------|--------|--------|
| 开屏 S-01 | `ios_open_ads-test` | `android_open_ads-test` | 仅运营开屏 | 仅开屏广告 |
| 插页 I-01 | `ios_free_interstitial-test` | `android_free_interstitial-test` | 不插页 | **看几集弹**（默认 **看2集弹**，配置值 2） |

**子开关默认值**（未远程覆盖时）：开屏 `hot_start_enable=0`、`inter_time_sec=60`、`max_per_session=10`（**当天**开屏展示上限）；插页 `interval_episodes=2`（**看2集弹**）、`inter_time_sec=0`、`max_per_play_session=0`。详见 PRD **5.1.4 / 5.2.4**。

完整规则见 PRD **5.1** / **5.2**（分章阅读）。写作规范：`.claude/skills/prd-writer-master/ab_ad_experiment_prd_template.md`。测试环境变量见 `tests/README.md`。

## 修改 PRD

请改 `*_PRD.md` 真理源；`.html` 未定稿前不生成（见根目录 `CLAUDE.md`）。
