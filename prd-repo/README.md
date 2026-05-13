# prd-repo

> AutoFlow 产品需求 + 决策上下文 + 协作对齐文档同步仓库。所有协作角色（前端 / 后端 / 数据库 / QA / PM）的 AI 助手从本仓库读取需求上下文，避免乱开发、乱测试、设计意图丢失。
>
> 📖 **协作流程必读**：[`workflow-guide.md`](workflow-guide.md) — 产研协作 SOP（产品端 4 步 + 技术端 6 阶段 + 4 个 Claude 命令 `/ai-review` `/dev-plan` `/gen-feishu-csv` `/gen-tests` + FAQ）。

---

## 🚨 第一条规则（所有 AI 必读）

**PRD `.md` 是真理源，`.html` 是派生展示版。**

- PRD 主文档：`{YYYYMMDD}/PRD/{需求}/{日期}_{需求}_PRD.md` —— 唯一权威来源（AI 读这份）
- PRD 派生展示版：`{YYYYMMDD}/PRD/{需求}/{日期}_{需求}_PRD.html` —— 含 dark theme + 实物 UI 渲染 + 交互演示，给人类看（评审 / 自审 / 跨团队展示）
- 当 `.html` 与 `.md` 冲突时（理论上不应发生，因为 HTML 严格忠于 markdown），**一律以 `.md` 为准**
- 详细规则见每份 PRD 顶部的"真理源约定"banner 和 [`AI_GUIDE.md`](AI_GUIDE.md) 第 1-2 节

---

## 💡 如何打开 PRD（研发 / QA / 产品都要看）

每份 PRD 是 `.md`（AI 读）+ `.html`（人类读）双产物。

### `.md` 真理源
在 GitHub 上**直接点开就能渲染** — 这是研发 / QA / AI 的事实源。

### `.html` 派生展示版（dark theme + 实物 UI + 交互）

**⚠️ GitHub 不渲染 HTML 文件** — 在网页上点 `.html` 链接只会看到源码。**必须本地打开**。

```bash
# 1. clone 仓库（首次）
git clone https://github.com/Luxi-Nebula/prd-repo.git
cd prd-repo

# 2. 后续更新拉新版本
git pull

# 3. 用 open 命令（macOS）直接弹浏览器查看
open 20260508/PRD/提示词版权风控规避/20260507_提示词版权风控规避_PRD.html

# Linux / WSL：xdg-open ...
# Windows Git Bash：start ...
```

**或者**：Finder / 资源管理器进入对应目录 → 双击 `.html` 文件 → 默认浏览器弹出。

**修改 PRD 的正确做法**：直接告诉产品总监的 AI 哪里要改，AI 会**同时**更新 `.md` 和 `.html` 两份保持一致 — 不要单独手改 HTML。

---

## 📁 仓库结构（v3 按批次组织）

```
prd-repo/
├── README.md                          # 本文件（仓库入口）
├── AI_GUIDE.md                        # AI 助手通用阅读规范（PRD 章节结构 / 视觉规范 / 文件命名）
├── workflow-guide.md                  # 产研协作 SOP
├── confirmed-decisions.md             # 真理源速查表 + 决策历史（PM AI 用）
│
└── {YYYYMMDD}/                        # 批次目录（按首次发布日命名，如 20260508/）
    ├── README.md                      # 批次入口（本批次需求清单 + 关键决策汇总 + 阅读路径）
    ├── PRD/                           # 本批次 PRD 双产物
    │   └── {需求名}/
    │       ├── {日期}_*_PRD.md        # 真理源（AI 读）
    │       └── {日期}_*_PRD.html      # 派生展示版（人类读）
    ├── decision-making/               # 本批次决策上下文（PM 必读，了解"为什么"）
    │   ├── {需求名}/{日期}_*.md
    │   └── _汇总/{批次决策汇总}.md
    ├── ai-review/                     # 研发提问 + 产品答复对齐流程（最后一轮）
    │   └── {批次}_ai-review_v{N}.md
    ├── feedback/                      # 当期用户反馈原文（xlsx / md / 截图）
    └── release-redline/               # 跨 PRD 发布硬约束（多需求批次必有）
        └── 上线红线.md
```

> **同一批次约定**：`{YYYYMMDD}/` 是首次发布日；后续同批次更新**直接覆盖该目录**，不改日期。跨批次新需求建新的日期目录。

---

## 🧑‍💻 各角色入口（AI 拿到任务时按这条路径读）

> 替换 `{当前批次}` 为最新的 `YYYYMMDD/` 目录（如 `20260508/`）。
> 所有角色都从主 PRD 的 frontmatter `ai_context` 读取自己应该看的章节路由——主 PRD 自包含，不再单独建配套文件。

### 前端 AI
1. `{当前批次}/PRD/{需求}/*PRD.md` 第 1-7 章 + 8.2 节
2. `{当前批次}/PRD/{需求}/*PRD.html`（含实物 UI 渲染，辅助理解视觉）

### 后端 AI
`{当前批次}/PRD/{需求}/*PRD.md` 第 1/3/5/7 章 + 8.3 节（含 8.3.1 错误码全集）

### 数据库 AI
1. `{当前批次}/PRD/{需求}/*PRD.md` 第 8.4 节（含 8.4.1 完整 DDL）
2. 各模块的 5.x.5 / 5.x.9 字段表

### QA AI
1. `{当前批次}/PRD/{需求}/*PRD.md` 全文（重点 5.x 验收标准 + 第 8.7 上线顺序 + 第 11 章红线）
2. `{当前批次}/release-redline/上线红线.md`（跨 PRD 发布硬约束）

### UI AI
1. `{当前批次}/PRD/{需求}/*PRD.md` 第 4 章（视觉系统 + 4.1.1 ABSOLUTE REQUIREMENTS 段）+ 各 5.x.2 节 UI 提示词
2. `{当前批次}/PRD/{需求}/*PRD.html`（参考实物 UI 渲染）

### 产品经理 AI（其他 PM 接手 / 制作新需求时参考）
1. `confirmed-decisions.md` —— 已落地决策真理源
2. `{当前批次}/decision-making/_汇总/*.md` —— 批次决策背景
3. `{当前批次}/decision-making/{需求}/*.md` —— 单需求决策上下文（含为什么砍 / 留 / 改的判断依据）
4. `{当前批次}/ai-review/*.md` —— 看研发以前问了什么、产品答了什么（避免重复对齐）

### 研发 AI（综合）
**先读 `{当前批次}/README.md`**——批次入口已含关键决策汇总 + 阅读路径 + 高优红线快速摘要。

---

## 📅 当前批次

| 批次目录 | 发布日 | 需求清单 | 优先级 / 版本 |
|---|---|---|---|
| [`20260508/`](20260508/) | 2026-05-08 | 提示词版权风控规避 / 通用参数校验框架 / Cluster 列表筛选升级 | P0 v1.2 / P1 v1.5 / P2 v1.5 |

**当前批次详情**：见 [`20260508/README.md`](20260508/README.md)。

---

## ⚠️ 安全约定

- 本仓库**不含**用户原始反馈表 / 内部追问稿 / 产品总监个人工作流文档
- 本仓库**仅含**已落盘的需求决策结果 + PRD 双产物 + 协作对齐文档
- vendor 内部细节（kaopuyun 聚合关系 / Volcengine 私域虚拟人像库等）已在 PRD 内，**仅供团队内部使用**
- API 字段名（`SUANLIX_API_KEY` 等）是字段名引用，**不是真实密钥值**

---

## 🔄 同步约定

本仓库由产品总监按需手动同步（不是自动）。每次新增 / 更新需求时：
1. 产品总监在 product 主仓完成需求落地（决策 + PRD `.md` + `.html` + ai-review 对齐）
2. 把对应批次内容同步到本仓库的 `{YYYYMMDD}/` 目录，commit message 说明"publish: {YYYYMMDD} 批次发布"或"update: {YYYYMMDD} 批次 - 改了什么"
3. 团队 AI 助手自动从本仓库拉取最新版本

如发现 PRD 内容不清晰或冲突，**通过常规协作渠道反馈给产品总监 + 在 ai-review.md 里用 `[待对齐]` 标记**，不要在本仓库直接改 PRD（产品总监才是真理源维护者）。
