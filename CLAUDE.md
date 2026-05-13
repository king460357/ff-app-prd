# product 项目总规则

## 用户角色
用户是产品负责人/产品总监，主要负责需求判断、方案评审、优先级确认、PRD 输出，不直接写代码。

## 默认语言
默认使用中文输出。技术字段、文件名、代码字段可以保留英文。

## 固定智能体
本项目固定使用两个智能体：

1. demand-decision-agent
用于需求决策、用户反馈分析、问题判断、方案选择、需求决策表输出。

2. prd-writer-agent
用于完整 PRD 写作、页面交互补充、字段定义、异常状态、Mermaid 流程图、ASCII 界面图、验收标准输出。

## 每次开始任务前必须读取（2026-05-10 v3 扩 3→5 项）

⚠️ **触发场景**：用户启动 demand-decision-agent / prd-writer-agent，或说"写决策 / 写 PRD / 处理新需求"等需求侧任务。普通 bash / git / 阅读类任务**不触发**第 4-5 项。

1. **读 `docs/confirmed-decisions.md`**（顶部"当前真理源速查"表是判断现行方案的入口）
2. **读 `docs/decision-priority-queue.md`**
3. **读对应 skill**：`.claude/skills/` 下匹配的 skill（demand-solution-decision / prd-writer-master / open-questions-triage）
4. **★ 拉 autoflow 最新代码**（**只在需求决策 / PRD 写作时触发**）：
   - 提示用户跑 `cd "/Applications/我的电脑/AI /autoflow" && git pull origin main`
   - 若 autoflow 工作树有未提交修改 → **直接 abort 让用户处理**（不要自动 stash）
   - 目的：autoflow 是当前线上事实源，本地落后会让决策基于过时假设
5. **★ 看 autoflow-snapshot 对应模块**（**只在需求决策 / PRD 写作时触发**）：
   - 路径：`docs/autoflow-snapshot/已上线功能/{模块}.md`（product 仓内）
   - 步骤：① 找需求涉及的模块对应 snapshot；② 检查 frontmatter `最后验证日期`
   - **未过期（≤ 4 周）**：把 snapshot 第 5 节 ⚠️ 硬约束 + 第 6 节 🔗 设计模式作为决策 / PRD 上下文输入；新需求若改任何 hardcoded 约束必须在 PRD 第 8 章显式列出
   - **过期（> 4 周）**：先告知用户"snapshot 已过期 N 周，建议重做反推（5-10 分钟）vs 暂用旧 snapshot 完成本期决策再补"，由用户拍板
   - **该模块无 snapshot**：要么用 Explore agent 现做反推（约 10 分钟）写到 `docs/autoflow-snapshot/`，要么直接读 autoflow 代码（视决策紧迫度）

## 用户反馈 / 需求的接收方式（2026-05-06 v2 调整）

⚠️ **每期 1 份汇总文档**——用户按周/期把当期所有反馈和需求整理成 1 份文档（xlsx / md / 飞书表格导出 / 截图 / 任何格式）交给 agent。**不再要求按条粘贴，也不再强制 agent 拆出每条独立 md**。agent 收到一份汇总后必须：

1. **归档原始文档**到对应批次目录 `docs/{YYYYMMDD}/feedback/{反馈文件名}`（直接落到本批次目录）
2. **直接提取并归类**：按既定记忆规则"反馈决策按类不按案例"把全部条目归到 N 类（A/B/C/D…）。当某条信息严重不足、需要单独追问用户补充时，agent 直接在对话里追问，不额外落盘单条 md
3. **结合项目源码现状对每一类做需求决策**（autoflow 等项目的源码位置见跨会话长期记忆）。直接输出汇总决策表到 `docs/{YYYYMMDD}/decision-making/_汇总/{YYYYMMDD}_需求决策汇总.md`，每类含：问题陈述 + 现状（含代码路径:行号佐证）+ 3 个候选方案（A 快速 / B 完整 / C 长期）+ 推荐方案 + 优先级 / 涉及角色 / 验收标准 / 上线验证指标
4. **决策完成后**：① 真理源条目追加到 `confirmed-decisions.md`（更新顶部速查表 + 追加决策记录 #N）；② 在 `decision-priority-queue.md` 的"历史批次台账"追加一行；本队列不需要再登记本期"待决策"条目
5. **追加批次的处理**：若用户后续在同一期内追加新文档，按"补充批次"处理（同日期不同时间戳，文件名加 `_追加` 后缀）；不要把新批次塞进旧汇总文件

旧的逐条接收规则（v1，2026-05-06 上半天）已被本规则取代；更早的"用户反馈表 + 待实现需求池"两份 xlsx 汇总表的废弃决策不变。

## 目录组织规范（按"批次日期"组织 — 2026-05-08 v3 重构）

> v3 重构（2026-05-08）：从"按资产类型分目录"改为"按批次日期组织（docs/{YYYYMMDD}/{资产类型}/{需求}/）"，与 GitHub `prd-repo` 的 `{YYYYMMDD}/` 批次目录 1:1 对齐。优势：① PM 本地 ↔ GitHub 远端结构一致便于对比；② 一个批次的所有内容（PRD/决策/ai-review/反馈/红线）打包在同一目录，研发一次拉全；③ sync 脚本逻辑简化为 1:1 镜像。

| 资产类型 | 路径模板 | 说明 |
|---|---|---|
| **批次目录**（一期需求的完整内容）| `docs/{YYYYMMDD}/` | 日期 = 该批次首次落盘日；后续同批次更新覆盖此目录不改名 |
| 批次入口 README | `docs/{YYYYMMDD}/README.md` | 给研发 AI 看：本批次需求清单 + 关键决策摘要 + 阅读路径 |
| PRD 主文档 | `docs/{YYYYMMDD}/PRD/{需求名}/{YYYYMMDD}_{需求名}_PRD.md` | 命名约定见后文 |
| PRD HTML 派生产物 | `docs/{YYYYMMDD}/PRD/{需求名}/{YYYYMMDD}_{需求名}_PRD.html` | dark theme + 实物 UI 渲染 + 顶部"怎么打开"段；事实严格忠于 markdown |
| 需求决策表（单条）| `docs/{YYYYMMDD}/decision-making/{需求名}/{YYYYMMDD}_{需求简称}.md` | 含问题陈述 / 候选方案 / 推荐方案 / 优先级 / 涉及角色 / 验收标准 |
| 需求决策汇总（批量）| `docs/{YYYYMMDD}/decision-making/_汇总/{YYYYMMDD}_需求决策汇总.md` | 一期多需求时使用 |
| ai-review（研发反馈+产品答复）| `docs/{YYYYMMDD}/ai-review/{YYYYMMDD}_{批次说明}_ai-review_v{N}.md` | 双轮对齐：v1 / v2 / 研发原版 / 产品答复草稿（草稿是 PM 工作稿，sync 时自动排除）|
| 上线红线（跨 PRD 发布硬约束）| `docs/{YYYYMMDD}/release-redline/上线红线.md` | migration 顺序号 / 24h smoke / 整批回滚条款 |
| 用户反馈（直接落到本批次）| `docs/{YYYYMMDD}/feedback/{反馈文件名}` | xlsx / md / 截图任意格式，跟随批次同步给研发 |
| **跨批次复用**（不属于任何单批次）| | |
| 项目级跨批次文档 | `docs/` 根目录 | `confirmed-decisions.md`、`decision-priority-queue.md`、`workflow-guide.md` |
| 跨批次 autoflow snapshot | `docs/autoflow-snapshot/` | 已上线功能反推 snapshot，给 PM 同事用 |

> **流程边界**：上线节奏由研发方负责规划与追踪，**产品方不做版本规划与执行追踪**。产品方只对接需求落盘（决策 + PRD 双产物）。

**核心约定**：
- 同一批次后续更新（如 PRD 升版 / ai-review 增轮 / 新增反馈）→ **直接覆盖** `docs/{YYYYMMDD}/` 目录，**不**改日期、**不**新建子版本目录
- 跨批次新需求 → 建新的 `docs/{YYYYMMDD}/` 目录与本目录并存
- 旧的"按资产类型组织"路径（`docs/prd/{项目}/{需求}/`、`docs/decision-making/{项目}/{需求}/`、`docs/ai-reviews/{版本}/`、`docs/release-schedule/{版本}/`）已**全部废弃**，agents 不要再按这些路径写文件

新增需求时，agents 必须按此结构创建子目录，禁止把文件直接平铺在 `docs/{YYYYMMDD}/` 或 `docs/` 根目录。

## 输出要求
1. 默认中文
2. 不要只输出大纲
3. 不要输出空泛建议
4. 内容必须可执行
5. 内容必须适合复制到飞书文档
6. 表格内容必须适合复制到飞书表格
7. 需要流程图时使用 Mermaid
8. 需要界面图时使用 ASCII
9. 不要删除已确认内容，只能增补、修正或标注调整原因
10. **决策表 / PRD 等"最终落盘交付物"涉及 UI 改动的，必须含 ASCII 界面图（before / after 对照）**——此类文件会被产品经理直接拿去给团队展示讨论，没有界面图无法理解和评审。配置类 / 后端定时任务等无界面改动的可省略
11. **ASCII 界面图必须紧贴对应"做什么"的文字描述（内联布局），不要把所有界面图集中堆在文档最后或单独章节**——否则读者读到下面的实现描述时，要回滚到上面找对应界面，体验非常糟糕。每个交付块（块 1 / 块 2…）的文字描述完，紧接着画该块涉及的界面图

## PRD 必含 7 项（本项目对 prd-writer-master skill 的强制扩展）

每份落地版 PRD 必须包含以下 7 大类内容，缺一不可（与 skill 的章节映射对应）：

| # | 必含项 | 落在 PRD 的章节 | 强制要求 |
|---|---|---|---|
| 1 | 背景 & 目标 | 第 1 章产品概述（含背景、问题、目标指标） | 必须 |
| 2 | 用户场景 | 第 2 章目标用户与使用场景（≥ 3 个具体场景） | 必须 |
| 3 | 功能描述 | 第 4 章功能清单 + 第 5 章功能详细描述 | 必须 |
| 4 | 交互说明 | 第 5 章 12 项必填中的按钮/弹窗/状态/异常/联动 | 必须 |
| 5 | 效果图 | 4.1 ASCII 线框图 + 4.2 UI 设计图英文提示词（HTML 实物 UI 渲染用），两者都要 | 必须 |
| 6 | 验收标准 | 第 5 章 12 项必填的第 12 项，可观察、可判定、不模糊 | 必须 |
| 7 | 影响范围 | 第 8 章影响范围矩阵（含前端/后端/数据库/第三方/上线顺序，独立章节聚合） | 必须 |

prd-writer-agent 在产出 PRD 后必须完成自检：上述 7 项任一缺失则返工。第 7 项「影响范围矩阵」是研发拿到 PRD 的第一阅读章节，必须按 8.1-8.7 七个子节齐全（详见 SKILL.md）。

⚠️ **PM 边界硬约束**（2026-05-11 起 — PM 不越界写技术 spec）：
- ✅ **PM 写**：第 1-7 / 8.1 / 9-12 章 + 第 5 章 5.x.1-5.x.4 + 5.x.6 + 5.x.5 「业务字段约束」（不是 DDL）
- ⚠️ **PM 写草稿，研发深化**：8.2 前端涉及模块 / 8.3 后端涉及接口 / 8.3.1 错误场景 + 用户文案（不是错误码命名）/ 8.4 业务字段需求（不是表设计）/ 8.7 业务上线约束（不是灰度配置）
- ❌ **PM 不写**：8.4.1 完整 DDL CREATE 语句 / 具体性能预算实现（如 Redis 缓存秒数）/ 类设计 / 时序图

完整边界规则 + PM 草稿模板见 `.claude/skills/prd-writer-master/prd_vs_techspec_boundary.md`。

**判断越界 3 个问题**：① 换不同技术栈研发实施这段还成立吗？② 研发能 100% 不动复制到代码吗？③ 描述的是用户能看到的还是系统内部怎么处理？— 任一答"越界"则改成草稿 + 标 ⚠️ 研发深化。

## PRD 双产物（markdown + HTML，2026-05-10 起）

每份 PRD **必须同时存在**两份文件，命名规则相同（仅扩展名不同）：

```
docs/{YYYYMMDD}/PRD/{需求名}/
  ├── {YYYYMMDD}_{需求名}_PRD.md     ← 真理源（AI 读这份）
  └── {YYYYMMDD}_{需求名}_PRD.html   ← 派生产物（人类读这份）
```

**分工**：

| 产物 | 受众 | 用途 |
|---|---|---|
| **markdown**（真理源）| 研发 AI / 决策 AI / prd-writer-agent / demand-decision-agent / sync 工具 | 所有 AI 协作链路、grep / diff / sync 全为 markdown 优化；事实层始终以 markdown 为准 |
| **HTML**（派生产物）| ① 产品经理自审稿 ② 老板 / 跨团队评审会 ③ 研发同事偶尔看全貌 ④ 其他 PM 同事看格式参考 | 含 dark theme + 实物 UI（CSS 渲染，非 ASCII），浏览器打开即产品级 demo |

**硬约束**：

1. **markdown 是单一真理源**：所有事实（接口契约 / 字段值 / 阈值 / 红线）以 markdown 为准；HTML 内容必须严格忠于 markdown 不得自创/扩展
2. **HTML 内容必须忠于 markdown**：HTML 写作时禁止自由发挥扩展事实，必须严格按 markdown 描述渲染
3. **★ 用户提需求变化时，AI 必须一次同步两个文件**（2026-05-10 新增）：
   - 用户用自然语言提出"哪里变化"（如"5.1.5 SQL 改 success_rate 阈值 80% 改成 75%"）
   - AI 必须**同时改 `.md` 和 `.html`**两份，先后顺序不限，但最终必须一致
   - 一致性责任全在 AI，用户不必关心改顺序
   - 不允许只改一份后让用户"以后再 sync"
4. **HTML 内的 UI 区块用真实 HTML/CSS 渲染**（替代 ASCII 图）：dark theme 三锁色值 + shadcn 密度严格对齐 autoflow 现有代码（事实源 `frontend/app/globals.css:6-45` 等）
5. **HTML 可嵌 JS 但仅用于 UI 交互演示**（2026-05-10 修订，原"不嵌 JS"放宽）：每份 HTML 必须把"符合需求的交互效果"做出来——按钮可点切换激活态、下拉可展开、Tab 可切换、折叠区可展开收起、变体可切换查看、tooltip 可触发演示。**约束**：① 仅 vanilla JS（无外部依赖 / CDN 引入）；② JS 仅 toggle CSS class 或简单 DOM 改动，不能动态隐藏整段事实文字；③ 所有事实（接口路径 / 字段值 / 阈值 / 红线等）写在初始 DOM 里，AI 读 HTML 时直接抽取，不依赖执行 JS
6. **★ HTML 顶部必须含"怎么打开看"段**（2026-05-10 新增）：用 `<div class="notice notice-info">` 包裹，含 3 种打开方式（终端 `open` 命令 / Finder 双击 / 拖到浏览器）+ 1 句"修改需求直接告诉 AI"提示——给非技术受众（老板 / 跨团队评审）看到 HTML 文件时知道怎么处理
7. **★ 每份 PRD 主目录必须含 `README.md` 引导本地打开 HTML**（2026-05-11 新增）：在 `docs/{YYYYMMDD}/PRD/{需求名}/` 下与 `.md` + `.html` 并列建一份 `README.md`，含：① ⚠️ 警告「GitHub 不渲染 `.html` 文件，点开看到源码」；② 3 种打开方式（终端 `git clone` + `open` 完整命令 / Finder 双击 / 拖到浏览器）；③ 文件清单对照表（`.md` AI 读 / `.html` 人类读）；④ 修改 PRD 的正确流程（告诉 AI，不要手改 HTML）；⑤ 回链批次 README + 仓库首页 README。**为什么**：GitHub 在目录列表底部会自动渲染同目录 `README.md`，研发 / 产品 / PM 同事进入 PRD 目录第一眼就能看到打开方式，不必先翻批次 README 或仓库首页 README。**模板参考**：`docs/20260508/PRD/提示词版权风控规避/README.md`（每份 PRD 的 README 模板基本一致，仅 PRD 名 / 文件名 / 优先级 / 上线日不同）。
8. **★ HTML 禁用 ASCII 线框图，所有 UI mockup 必须真实 dark theme + shadcn 密度渲染**（2026-05-11 新增）：HTML 中**禁止**用 `<pre><code>┌──┐│└──┘</code></pre>` 这种 ASCII 字符画表达 UI（Dialog / AlertDialog / Popover / Calendar / Select 下拉 / 单选 radio / 输入框等都不允许）。**markdown 端可以保留 ASCII 草图**（开发 AI 读 markdown 时直观），但 **HTML 端必须用真实 HTML/CSS 渲染**。统一 CSS 类参考 `docs/20260508/PRD/提示词版权风控规避/20260507_提示词版权风控规避_PRD.html` 的 `.dialog-mockup` 系列：`.dialog-mockup` `.dialog-header` `.dialog-body` `.dialog-footer` `.dialog-row` `.dialog-field` `.dialog-switch` `.dialog-alert-body` + size 修饰 `.size-xs/sm/md/xl/2xl`。Popover / Calendar 用 inline style 加 `box-shadow: 0 4px 12px rgba(0,0,0,0.4)` 弹层效果。完整模板见 `.claude/skills/prd-writer-master/html_ui_rendering_standard.md`。**自检**：HTML 文件内 `grep -c '<pre><code>┌'` 必须为 0（不允许任何 box-drawing 字符 ASCII Dialog 框）。
9. **★ HTML 所有 mockup 元素必须可跳转到 PRD 章节（data-jump 三件套）**（2026-05-11 新增）：每个 UI mockup 中的按钮 / 控件 / 输入框 / Dialog 触发器 / Tab / Popover 触发器都必须含 `data-jump="{锚点 id}" data-jump-label="见 5.x.y 控件 N"` 属性，让评审者点击 mockup 元素即跳到对应 5.x.3 控件清单 / 5.x.4 弹窗详细描述。**三件套缺一不可**：① CSS 含 `[data-jump]` hover 样式 + `[data-jump]:hover::after` tooltip + `.jump-highlight` + `@keyframes jump-flash`；② JS 含 `document.querySelectorAll('[data-jump]')` click handler（`scrollIntoView` + 加 `.jump-highlight` 1.4s 后移除）；③ HTML 每个 mockup 元素加 `data-jump` 属性。**控件锚点 id 命名约定**：`sec-{N}-{N}-{N}-c{N}` 例如 `sec-5-3-3-c1` 表示 5.3.3 控件 1。**无对应章节的演示按钮**：用 `data-jump="无章节"` + `data-jump-label="演示态，PRD 未定义对应章节"`，JS 中 target 不存在时 fallback 显示 toast。完整 CSS+JS 模板见 `.claude/skills/prd-writer-master/html_ui_rendering_standard.md`。**自检**：HTML 文件内 `grep -c 'data-jump='` 数 ≥ ASCII 草图按钮数 + 表格行内操作按钮数；且 `grep 'querySelectorAll.*data-jump'` 必须命中（确认 JS handler 存在）。
10. **★ PRD 控件完整性自检（ASCII 画的每个控件都必须在 5.x.3 列出 6 项必填）**（2026-05-11 新增）：每个 5.x 模块的 ASCII 草图里画的**每一个**可交互元素，必须在 5.x.3 控件清单里有对应的 6 项必填描述。**常见漏列**：顶部 toolbar 的搜索框 / 筛选下拉、输入区的 textarea 本身、折叠区的展开收起、Tab 切换器。**自检方法**：写完 5.x 后逐一列出 ASCII 草图里的所有 `[xxx]` `{xxx ▼}` `◉/○` 控件标记，确认每个都在 5.x.3 控件清单中有对应 6 项必填段；漏一个就视为 PRD 不完整需返工。
11. **★ PRD 内部一致性自检（enum / 字段类型 / 默认值 在多处必须打通）**（2026-05-11 新增）：同一字段名（如 `category` / `source` / `status`）的 enum / 字段类型 / 默认值在以下位置必须**完全一致**：① 5.x.4 弹窗字段表；② 5.x.5 schema 字段表；③ 8.4.1 DDL 注释；④ ASCII 草图里的提示（如 `↑ celebrity/music/...`）；⑤ v0 mockup 实现（如有）。**自检方法**：写完 PRD 后 `grep -n "{字段名}" *.md` 列出所有出现位置，对照 enum 列表 / 默认值 / 字段类型——任一处不一致就是 bug，需补全或用 ⚠️ 块标记待用户裁决。**v0 ↔ PRD 冲突原则**：v0 mockup 与 PRD 文档冲突时，AI **不自决**——加 ⚠️ 块列出 4 处差异（v0 实际 / PRD 字段表 / schema / DDL）+ 建议方案 + 等用户拍板，禁止 AI 默认按 v0 改 PRD。
12. **★ PRD 必有 requirements-spec.md（spec-extractor 自动派生）**（2026-05-12 新增）：每份 PRD 落盘后**自动派生** `requirements-spec.md`（精简版给研发负责人快速读）——剥离业务背景 / 决策上下文 / 视觉描述 / 待确认问题，保留系统行为定义（5.x.3 / 5.x.4 / 5.x.5）+ 验收 Gherkin（5.x.6）+ 接口契约 + 非功能需求 + 影响范围。格式：**User Story + Gherkin Scenarios**（BDD / 敏捷业界标准）。**规则**：PM 不手改 requirements-spec.md，PRD 改了下次 sync 自动重生。完整剥离规则见 `.claude/skills/spec-extractor/SKILL.md`。
13. **★ PRD 必有 tests/ + test-coverage-report.md（prd-test-validator 自动派生）**（2026-05-12 新增）：每份 PRD 落盘后**自动派生** `tests/playwright-e2e.spec.ts`（从 5.x.6 Gherkin Scenario 转 Playwright，可直接 `npx playwright test` 跑）+ `tests/README.md`（怎么跑的说明）+ `test-coverage-report.md`（PRD ↔ test 双向校验报告）。**校验报告作用**：反向暴露 PRD 缺漏 / 矛盾 / 模糊处——test 要不到的字段 / 不明确的行为 = PRD 缺漏。**PM 决策路径**：报告有 ⚠️ 时 PM 选 A. 全部修订 / B. 部分修订 / C. 全部接受 / D. test 重生。完整规则见 `.claude/skills/prd-test-validator/SKILL.md`。

**PRD 完整产出 6 份资产**（2026-05-12 起）：
```
docs/{YYYYMMDD}/PRD/{需求名}/
├── {date}_{需求名}_PRD.md            ← 真理源（PM 写，全量）
├── {date}_{需求名}_PRD.html          ← 视觉派生（给人类看）
├── README.md                          ← GitHub 自动渲染（打开方式引导）
├── requirements-spec.md               ← 精简派生（给研发负责人）
├── test-coverage-report.md            ← PRD ↔ test 校验报告（PM 自检）
└── tests/
    ├── playwright-e2e.spec.ts         ← 可跑测试（QA / 研发用）
    └── README.md                      ← tests 目录说明
```

**唯一真理源**：PM 只维护 `PRD.md` 一份；其他 5 份**全部自动派生**——PRD.md 改了，自动重生所有派生产物。

**触发时机**：

| 时机 | 谁 | 动作 |
|---|---|---|
| PRD 首次拍板（评审通过）后 | prd-writer-agent / 产品总监 | 出第一版 HTML（含顶部"怎么打开"段）|
| 用户提"需求变化"（任何形式）| AI（你） | 同时改 `.md` + `.html`，确保最终一致 |
| 评审会前 | 产品总监 | 不必检查同步——AI 已保证一致 |

## PRD 多角色服务（5 类专业 AI）— 主 PRD 自包含原则

每份 PRD 服务于 5 类专业 AI 角色：前端 / 后端 / 数据库 / QA / UI。

**默认假设：主 PRD 自身已自包含全部角色所需信息——默认不再单独建配套文件**（同样内容到处复制是画蛇添足，文档维护成本翻倍且必然不同步）。主 PRD 通过以下结构化章节直接服务 5 类角色：

| 章节 | 服务角色 | 内容 | 强制 |
|---|---|---|---|
| frontmatter `ai_context`（角色路由）| 全部 | 各角色 AI 应该读 PRD 哪几章 | 必须 |
| 第 1 章背景 + 决策上下文 | PM / 全部 | 为什么选这个方案、哲学边界 | 必须 |
| 第 4.3 节 UI 提示词（每模块自带 ABSOLUTE 段）| UI | HTML 实物 UI 渲染输入 | 必须 |
| 第 5 章每模块「目标读者」标签 | 全部 | 该模块给哪个角色看 | 必须 |
| 第 8.3.1 错误码全集 | 后端 | 错误码命名 + HTTP + 触发场景 | 必须 |
| 第 8.4.1 完整 DDL | 数据库 | CREATE / ALTER / 索引 / 回滚 | 必须 |
| 第 4.3.0 视觉系统（dark theme 三锁 + ABSOLUTE 段 + emoji 强制清单）| UI | 状态变体 / 动画 / a11y / 响应式 | 必须 |

### 配套文件 — 默认不建

单一需求 + 主 PRD 7 项必含齐全时，**不建任何配套**——这是常态。主 PRD 已通过 frontmatter `ai_context` 角色路由 + 第 1 章决策上下文 + 第 4.3 节 UI 提示词 + 第 5 章每模块「目标读者」标签 + 第 8.3.1 错误码 + 第 8.4.1 DDL 等结构化章节自包含全部 5 类角色所需信息。

### prd-writer-agent 自检（7 项 — 全部针对主 PRD 内章节）

任意一项缺失则返工：
1. 主 PRD frontmatter `ai_context` 是否含 5 类角色路由
2. 主 PRD 第 5 章每个 🔴 模块是否有「目标读者」标签
3. 主 PRD 第 4.3 节 UI 提示词每段是否含 ABSOLUTE REQUIREMENTS 段（dark + emoji + 全文案 + shadcn 密度 + globals.css 色值五要点 + self-check 列表）
4. 主 PRD 第 8.3.1 错误码全集是否齐
5. 主 PRD 第 8.4.1 完整 DDL 是否齐
6. 主 PRD 第 4.3.0 视觉系统是否齐（dark theme 三锁 / 状态变体 / 动画 / a11y / 响应式）
7. **整洁自检**：是否存在"主 PRD 已含 X 但又单独建 X.md"的重复？有则删除冗余文件，保留主 PRD 单一权威源

## Sync 安全机制（2026-05-12 起 — 绝不自动 push）

⚠️ **核心红线**：所有 `sync-to-*.sh` 脚本**默认 commit 后停，不自动 push**。需要 push 必须显式加 `--push` flag 或用户口头确认。

**为什么**：避免误推 demo / 测试 / 在途稿件 / 未审查 commit 到云端。云端 commit 一旦推上去，删除虽可（force push 或新 commit 删），但**审计日志和 git history 永远留痕**，对外部协作者已经造成可见性影响。

### AI 助手的 sync 流程（强制遵守）

```
PM 说"同步给研发" / "同步给 PM 同事"
   ↓ AI 跑
sync-to-prd-repo.sh / sync-to-pm-workflow.sh
   ↓ 脚本默认行为
1. rsync 镜像到 staging
2. git add + git commit 到 staging
3. ⛔ STOP（不 push）+ 在终端输出 commit hash + 审查命令
   ↓ AI 汇报
"commit XXXXXX 已 commit 到 staging，未 push。审查命令：cd ... && git show HEAD --stat。
 你审查后告诉我 push / 调整 / 撤回。"
   ↓ 用户审查
A. 确认 → "push 到 prd-repo" / "push 到 pm-workflow" → AI 跑 git push origin main
B. 调整 → 改完再 sync 一次（产生新 commit）
C. 撤回 → 跑 git reset --soft HEAD^（不丢改动）或 git reset --hard HEAD^（丢改动）
```

### AI 助手判断口令

| 用户口令 | AI 行为 |
|---|---|
| "同步给研发" / "同步给 PM 同事" | 跑 sync 脚本 → **commit 后停** → 汇报 |
| "推 / push" | git push origin main |
| "撤回 / 别推 / 不要这个 commit" | git reset --soft HEAD^（保留改动，让用户改）|
| "全部撤回 / 撤回到 main" | git reset --hard HEAD^（丢改动 — **必须二次确认**）|

### 显式 --push flag 使用场景

仅在用户**口头明确说"直接 push"** 时才用 `--push`：
```bash
bash scripts/sync-to-prd-repo.sh --batch YYYYMMDD --push -m "..."
```
其他场景**永远不加** `--push`——保持安全默认。

### 历史背景

2026-05-12 之前 sync 默认自动 push，导致：
- demo 测试需求误推到 prd-repo（如 20260512 演示批次）
- PM 没机会审查 commit 内容就已推送
- 推完才发现要删 → 需 force push 或新 commit 删除

2026-05-12 起改为"commit 后停 + 用户审查 + 显式 push" 三步走，杜绝误推。

完整 sync 工作流详见 `scripts/README.md`。

---

## 上下文沉淀规则
每次完成需求决策或 PRD 后，需要询问是否写入对应 docs 文件。
已经确认的结论必须追加到 docs/confirmed-decisions.md。

## 文件落盘红线（全局禁令）

⚠️ **所有 agents 与 skills 严禁把交付物写入用户桌面 `~/Desktop/` 或项目目录之外的任何位置**。所有交付物必须落到本仓库 `docs/` 子目录下。

| 交付物 | 必落路径 |
|---|---|
| 需求决策方案（单条）| `docs/{YYYYMMDD}/decision-making/{需求名称}/{YYYYMMDD}_{需求简称}.md` |
| 需求决策汇总（批量）| `docs/{YYYYMMDD}/decision-making/_汇总/{YYYYMMDD}_需求决策汇总.md` |
| PRD 主文档及配套 | `docs/{YYYYMMDD}/PRD/{需求名称}/`（统一文件命名见下） |
| ai-review 对齐文档 | `docs/{YYYYMMDD}/ai-review/{YYYYMMDD}_{批次说明}_ai-review_v{N}.md` |
| 上线红线（跨 PRD）| `docs/{YYYYMMDD}/release-redline/上线红线.md` |
| 用户反馈（直接归档）| `docs/{YYYYMMDD}/feedback/{反馈文件名}` |

如对话中用户明确指示"导出到桌面"等其他位置，可临时执行；默认行为始终是项目内。

## 每期需求 PRD 目录的文件命名

每期需求 PRD 目录 `docs/{YYYYMMDD}/PRD/{需求名}/` 下必有 3 份文件（双产物 + 同目录 README）——这是常态。

| 文件名 | 内容 | 是否必有 | 主要读者 |
|---|---|---|---|
| `{YYYYMMDD}_{需求名}_PRD.md` | 主 PRD 真理源（含 frontmatter ai_context 5 角色路由 / 7 项必含 / 第 1 章决策上下文 / 第 4.3 节 UI 提示词 / 第 8 章影响范围 / 第 8.3.1 错误码全集 / 第 8.4.1 DDL）| **必有** | 全部角色（AI 协作链路）|
| `{YYYYMMDD}_{需求名}_PRD.html` | HTML 派生产物（dark theme + 实物 UI 渲染 + 顶部"怎么打开"段；事实严格忠于 markdown）| **必有** | 人类受众（评审 / 自审 / 跨团队展示）|
| `README.md` | 引导本地打开 HTML（GitHub 不渲染 HTML，本 README 在目录列表底部被 GitHub 自动渲染）| **必有** | 进入 PRD 目录的人（研发 / 产品 / PM 同事）|
| `_archive/` | 历史版本归档子目录 | 视情况 | — |

命名规则：
- 主目录里**只允许存在一份"当前版"双产物**——出现 `xxx_PRD_v2.md` 这种是错误的，应把旧版移入 `_archive/` 并在文件名末尾加日期
- `.md` 与 `.html` 命名一致仅扩展名不同
- 用户提需求变化时 AI 必须**同时改两份**确保最终一致，不允许只改一份
- 文件名中的中文不替换为英文；空格统一替换为下划线
- 日期写在主文件名前缀（`{YYYYMMDD}_`）和 frontmatter `created` 字段同时
- `README.md` 是固定文件名（不加日期前缀，不加需求名），GitHub 自动渲染规则要求此命名；内容含 ⚠️ HTML 打开警告 + 3 种打开方式（终端 `git clone` + `open` 完整命令 / Finder 双击 / 拖到浏览器）+ 文件清单对照 + 改 PRD 流程 + 回链批次 README / 仓库首页；模板参考 `docs/20260508/PRD/提示词版权风控规避/README.md`

## 主 PRD frontmatter `ai_context` 角色路由（自包含的核心）

主 PRD frontmatter 的 `ai_context` 字段含 5 类角色应该读 PRD 哪几章的明确路由——这是单一 PRD 主目录**不需要**单独建路由文件的关键所在。

参考路由（每份 PRD 实际填写时按需求情况调整）：

```yaml
ai_context: |
  本 PRD 自包含 5 类专业 AI 角色所需信息：
  - 前端 AI：第 1/2/3/4/5/6 章 + 第 8.2 节（前端影响详情）
  - 后端 AI：第 1/3/5/7 章 + 第 8.3 节（含 8.3.1 错误码全集）
  - 数据库 AI：第 8.4 节（含 8.4.1 完整 DDL）+ 各 5.x.9 字段表
  - QA AI：全文（重点第 5 章各 5.x.10 验收标准 + 第 8 章上线顺序）
  - UI AI：第 4 章（线框图 + 视觉系统）+ 第 4.3 节 UI 提示词
```

每份 PRD 增量更新时同步更新 frontmatter 的 `last_updated` / `changelog` 字段，让各角色 AI 拉仓后能看到变更点。

---

## 历史规则演进说明

早期项目沉淀过"配套文件必有"规则（当时主 PRD 还未演化到自包含全部内容）。**项目演进后主 PRD 已通过 frontmatter ai_context + 第 4.3 节 UI 提示词 + 第 5 章目标读者标签等结构吸收了所有配套功能**。现行规则为"主 PRD 自包含"——单一主 PRD 即完整，默认不建任何配套，这是新规则下的常态。

如未来主 PRD 结构演变（如决策上下文需独立维护版本），再恢复"配套必有"规则。