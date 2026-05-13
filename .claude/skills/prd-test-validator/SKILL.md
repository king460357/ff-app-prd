# prd-test-validator — PRD 测试用例生成 + 双向校验

> 2026-05-12 新建。承接 prd-writer-agent 产出 PRD 后的下游闭环：从 PRD 5.x.6 Gherkin Scenario 生成可运行 Playwright test + 反向校验 PRD 缺漏。
>
> **核心理念**（ATDD / 验收测试驱动）：测试用例不是验证代码用的辅助产物，而是**反向校验 PRD 完整性**的工具——test 要不到的字段 / 不明确的行为 = PRD 缺漏。

---

## 1. 触发时机

`prd-writer-agent` 完成 PRD 落盘（.md + .html + README.md）后**立即触发**本 skill：

```
prd-writer-agent 完成 →
  自动调用 prd-test-validator →
    1. 读 PRD.md
    2. 抽取 5.x.6 所有 Gherkin Scenario
    3. 生成 tests/playwright-e2e.spec.ts
    4. 反向 grep PRD，找缺漏 / 矛盾 / 模糊
    5. 输出 test-coverage-report.md
  →
agent 把校验结果汇报给 PM
```

也可手动触发：用户说"为这份 PRD 跑校验"时。

---

## 2. 产出物

落点：`docs/{YYYYMMDD}/PRD/{需求名}/`

```
{YYYYMMDD}/PRD/{需求名}/
├── tests/
│   ├── playwright-e2e.spec.ts        ← 主测试文件，可 npx playwright test 直接跑
│   ├── fixtures/                      ← 测试数据（如有）
│   └── README.md                      ← tests/ 目录说明（怎么跑 / 依赖 / 环境变量）
└── test-coverage-report.md            ← PRD ↔ test 双向校验报告
```

---

## 3. Gherkin → Playwright 转换规则

### 3.1 输入：PRD 5.x.6 Gherkin Scenario

```gherkin
Feature: Cluster 卡片快速复制 ID

Background:
  Given admin 登录后进入 /admin/generate-stats
  And 选择任一员工进入员工详情抽屉
  And 切到 Cluster Tab

Scenario: AC-5-1-001 正常复制
  When admin 点击任意 cluster 卡片右上角的 [📋] 按钮
  Then 按钮 200ms 内文案变为 "✓ 已复制"
  And 图标颜色变为 #10B981
  And navigator.clipboard 内容等于该卡片的 cluster_id 字符串
  And 1500ms 后按钮文案恢复 "📋"
```

### 3.2 输出：Playwright .spec.ts

```typescript
import { test, expect } from '@playwright/test';

test.describe('Cluster 卡片快速复制 ID', () => {
  // Background hooks
  test.beforeEach(async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await page.goto('/admin/generate-stats?user_id=42&tab=clusters');
    await expect(page.locator('[data-testid="cluster-tab"]')).toBeVisible();
  });

  test('AC-5-1-001 正常复制', async ({ page }) => {
    // When admin 点击任意 cluster 卡片右上角的 [📋] 按钮
    const copyBtn = page.locator('.cluster-card').first().locator('.copy-id-btn');
    await copyBtn.click();

    // Then 按钮 200ms 内文案变为 "✓ 已复制"
    await expect(copyBtn).toHaveText(/已复制/, { timeout: 200 });

    // And 图标颜色变为 #10B981
    await expect(copyBtn).toHaveCSS('color', 'rgb(16, 185, 129)');

    // And navigator.clipboard 内容等于该卡片的 cluster_id 字符串
    const expectedId = await page.locator('.cluster-card').first().locator('.cluster-id').textContent();
    const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
    expect(clipboardText).toBe(expectedId?.replace('#', '').trim());

    // And 1500ms 后按钮文案恢复 "📋"
    await expect(copyBtn).toHaveText(/📋/, { timeout: 1800 });
  });
});
```

### 3.3 转换约定（Given/When/Then 关键词映射）

| Gherkin 关键词 | Playwright 转换 |
|---|---|
| `Given` 进入 / 导航 | `page.goto(...)` |
| `Given` 选择 / 切到 | `page.click(...)` + `await expect(...).toBeVisible()` |
| `When` 点击 | `page.locator(...).click()` |
| `When` 输入 | `page.locator(...).fill(...)` |
| `Then` 文案变为 X | `await expect(...).toHaveText(X)` |
| `Then` 颜色变为 #XXX | `await expect(...).toHaveCSS('color', 'rgb(...)')` |
| `Then` N ms 内 | `{ timeout: N }` |
| `Then` 显示 toast X | `await expect(page.locator('.sonner-toast')).toContainText(X)` |
| `Then` clipboard 内容为 X | `page.evaluate(() => navigator.clipboard.readText())` |
| `And` | 继续追加上一个 `Then` 同类 assertion |

### 3.4 selector 推断规则

PM 在 PRD 不写具体 selector（这是研发实现细节），但 test 需要。本 skill 按以下规则推断：

| PRD 描述 | 推断 selector |
|---|---|
| "cluster 卡片右上角的 [📋] 按钮" | `.cluster-card .copy-id-btn`（基于 PRD UI 提示词或 v0 mockup）|
| "[+ 手动添加] 按钮" | `button:has-text("+ 手动添加")` |
| "类别下拉" | `[role="combobox"][aria-label*="类别"]` |
| 通用 fallback | 添加 `// TODO: 替换为实际 selector` 注释 |

**研发深化**：test 文件含 `// TODO` 注释，研发实施时替换为最终 selector（通常是 `data-testid="..."`）。

---

## 4. 双向校验报告（test-coverage-report.md）

### 4.1 正向校验：PRD 所有 Scenario 都生成了 test

```markdown
## ✅ PRD → test 覆盖（6/6 全覆盖）

| Scenario ID | PRD 位置 | Test 位置 | 状态 |
|---|---|---|---|
| AC-5-1-001 正常复制 | PRD.md:215 | tests/playwright-e2e.spec.ts:12 | ✅ |
| AC-5-1-002 连续点击 | PRD.md:221 | tests/playwright-e2e.spec.ts:34 | ✅ |
| ...
```

### 4.2 反向校验：test 暴露 PRD 缺漏

抽取 test 文件用到的所有：字段名 / selector / API 路径 / 错误码 / 状态值，跟 PRD 比对：

```markdown
## ⚠️ PRD 缺漏（test 需要但 PRD 没说）

### ⚠️ 1. toast 显示时长未明示
- **test 需要**：fallback toast 显示后多久消失？（影响 `await expect(...).not.toBeVisible({ timeout: ??? })`）
- **PRD 现状**：5.1.4 异常处理只说"显示 toast"未给时长
- **建议补充**：5.1.4 加 `toast_duration_ms: 2500` 到 error_scenarios YAML

### ⚠️ 2. cluster_id 复制时是否含 `#` 前缀
- **test 需要**：clipboard.readText() 期望 "8205" 还是 "#8205"？
- **PRD 现状**:  5.1.3 button_spec 写 `call: navigator.clipboard.writeText(cluster_id_string)` 但 `cluster_id_string` 未定义是否含 `#`
- **建议补充**：5.1.3 明示 `cluster_id_string = card.cluster_id.replace('#', '').trim()`

### ⚠️ 3. 网络异常处理未列入 error_scenarios
- **test 需要**：当 clipboard 因网络问题失败时（极少）应该怎么提示？
- **PRD 现状**：error_scenarios 只列 CLIPBOARD-DENIED / OLD-BROWSER，未列网络场景
- **建议补充**：加 `ERR-5-1-NETWORK` 场景 + 用户文案
```

### 4.3 矛盾检查：PRD 内部 enum / 字段类型 / 默认值 多处一致性

```markdown
## ⚠️ PRD 内部矛盾（多处描述不一）

### ⚠️ 1. 1500ms 延迟在 3 处描述
- 5.1.3 button_spec: `delay_1500ms` ✅
- 5.1.6 验收 AC-001: `1500ms 后按钮恢复` ✅
- 4. 全局视觉总览: `1500ms 后恢复` ✅
- **结论**：✅ 一致，无矛盾

### ⚠️ 2. 复制后的图标颜色
- 5.1.3 button_spec: `change_icon_color: var(--score-green)` (#10B981)
- 5.1.6 验收 AC-001: `图标颜色变为 #10B981 (score-green)`
- **结论**：✅ 一致
```

### 4.4 模糊词检查

```markdown
## ⚠️ 模糊词残留

未发现「流畅 / 美观 / 友好 / 顺畅 / 清晰 / 高效 / 良好」等模糊词。✅
```

### 4.5 综合评分

```markdown
## 综合评分

| 维度 | 分数 |
|---|---|
| Scenario 覆盖度 | 6/6 = 100% ✅ |
| 缺漏项 ⚠️ | 3 处（需 PM 补充）|
| 内部矛盾 ⚠️ | 0 处 ✅ |
| 模糊词 ⚠️ | 0 处 ✅ |
| **建议** | **轻度修订** — 补 3 处缺漏后再发研发 |
```

---

## 5. PM 决策路径

校验报告有 ⚠️ 时，PM 在聊天窗口选：

| 选项 | 行为 |
|---|---|
| **A. 全部修订** | AI 把每条 ⚠️ 转成 PRD 修订建议（如"5.1.4 加 toast_duration_ms: 2500"），等 PM 确认后改 PRD + html + 重跑校验 |
| **B. 部分修订** | PM 指定哪几条要补（如 "1 + 3 修，2 我接受"），剩下的标 `accepted_gap: ⚠️ 由研发实施时决定` |
| **C. 全部接受** | 不改 PRD，校验报告作为 PRD 已知缺漏清单一同交付研发，研发实施时再决策 |
| **D. 重写 test** | 测试用例本身有问题（如 selector 推断错），PM 给具体反馈让 AI 重生 test |

---

## 6. tests/README.md 自动产出

每份 PRD 的 tests/ 目录自带 README.md：

```markdown
# tests/ — Cluster 卡片复制 ID

## 怎么跑

```bash
# 1. 装 Playwright（如果还没装）
npm install -D @playwright/test
npx playwright install

# 2. 跑测试
npx playwright test docs/{YYYYMMDD}/PRD/{需求名}/tests/playwright-e2e.spec.ts

# 3. 看 HTML 测试报告
npx playwright show-report
```

## 测试覆盖

- ✅ AC-5-1-001 正常复制
- ✅ AC-5-1-002 连续快速点击
- ✅ AC-5-1-003 hover 显示 tooltip
- ✅ AC-5-1-004 clipboard 权限被拒（Safari 私密模式 fallback）
- ✅ AC-5-1-005 老浏览器不支持 clipboard API
- ✅ AC-5-1-006 不影响 v2.2.1 已上线功能

## 研发实施注意

- 文件含 `// TODO: 替换为实际 selector` 注释，研发实施时替换 `.copy-id-btn` 为最终的 `data-testid="copy-id-btn"`
- `await context.grantPermissions(['clipboard-read', 'clipboard-write'])` 是 Playwright 给浏览器授权 clipboard，生产环境不需要
```

---

## 7. 失败模式 + 处理

| 失败场景 | 处理 |
|---|---|
| PRD 5.x.6 没 Gherkin Scenario | 报错"PRD 缺少 5.x.6 验收 Gherkin，无法生成 test"，让 prd-writer-agent 补 |
| Gherkin Scenario 但用语含糊（如"看到正确结果"）| 在 test-coverage-report.md 列为 ⚠️ 模糊待澄清 |
| selector 完全推断不出 | 用 fallback selector + `// TODO: 研发提供 data-testid` 注释 |
| PRD 涉及后端接口 | 同步生成 `api-contract.spec.ts` 用 Playwright APIRequestContext 测接口 |

---

## 8. 跟其他 skill 的协作

| skill | 协作关系 |
|---|---|
| `prd-writer-master` | 上游：产出 PRD.md 含 Gherkin Scenario |
| `prd-writer-agent` | 触发器：完成 PRD 落盘后调用本 skill |
| `prd-test-validator`（本）| 主体：生成 test + 校验报告 |
| `spec-extractor`（下个建）| 平行：派生 requirements-spec.md（研发简化版）|

## 9. 与现有 skill 文件的关系

- `html_ui_rendering_standard.md`：html 渲染规范，跟 test 无关
- `prd_vs_techspec_boundary.md`：PM 边界，跟 test 无关（test 是 PM 的职责）
- `interaction_detail_standard.md`：按钮 6 项 / 弹窗 5 项 — test 校验时用作"必填项"参考
