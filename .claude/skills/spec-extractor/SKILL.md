# spec-extractor — PRD 派生 requirements-spec（精简版给研发）

> 2026-05-12 新建。承接 prd-writer-agent 产出 PRD 后从全量 PRD 派生研发可直接消化的精简需求 spec。
>
> **核心理念**：PRD 全量是给"全员 + 老板 + 跨团队"看的（含业务背景 / 决策上下文 / 视觉描述）；研发负责人 / 研发同学要的是**剥离了这些背景的纯需求 spec**——系统必须做什么的精简清单。

---

## 1. 触发时机

`prd-writer-agent` 完成 PRD 落盘后**自动触发**：

```
prd-writer-agent 完成 →
  自动调用 spec-extractor →
    读 PRD.md → 按剥离规则生成 → requirements-spec.md
  →
PRD 主目录有 4 份文件（PRD.md + .html + README.md + requirements-spec.md）
```

也可手动触发：用户说"给我派生研发版 spec"时。

---

## 2. 产出物

落点：`docs/{YYYYMMDD}/PRD/{需求名}/requirements-spec.md`

格式：**User Story + Gherkin Scenarios + 接口契约 YAML**（敏捷 / Scrum / BDD 业界标准）

---

## 3. 剥离规则（PRD 全量 → requirements-spec）

每章按以下规则取舍：

| 章节 | 剥离规则 | 原因 |
|---|---|---|
| 1. 产品概述 | **简化**为 1 段（背景 1-2 句 + 目标 1-2 句）| 研发要知道"为什么做"但不需要决策细节 |
| 2. 目标用户与场景 | **转 User Story 格式**：`As a [role] / I want [feature] / So that [benefit]` | BDD 标准格式 |
| 3. 核心用户动线 | **保留 Mermaid** | 系统行为图，研发实施时常用 |
| 4. 全局视觉与界面 | ❌ **跳过** | 研发看 .html 视觉版 |
| 5.x.1 定位 | **简化**为 1 行（模块名 + 一句话定位） | 系统范围标记 |
| 5.x.2 UI 长什么样 | ❌ **跳过** | 研发看 .html |
| 5.x.3 控件交互 YAML | ✅ **完整保留** | 系统行为定义 — 核心 spec 内容 |
| 5.x.4 弹窗 / 状态 / 异常 | ✅ **完整保留** | 系统行为定义 — 核心 spec 内容 |
| 5.x.5 数据规范 | ✅ **完整保留** | 接口契约 / 字段约束 |
| 5.x.6 验收 Gherkin | ✅ **完整保留** | 测试驱动核心 |
| 6. 文案规范 | ✅ **保留**（终端用户文案部分）| UI 文案约束需要 |
| 7. 非功能性需求 | ✅ **保留** | 性能 / 兼容 / 可访问性 |
| 8.1 影响范围概览 | ✅ **保留** | 工程范围 |
| 8.2-8.7 各子节 | ✅ **保留** | 研发工程拆分依据 |
| 8.3.1 错误场景 | ✅ **保留**（PM 草稿格式）| 研发深化具体错误码 |
| 8.4 数据库 | ✅ **保留**（业务字段需求）| 研发深化具体表设计 |
| 9. 待确认问题 | ❌ **跳过** | PM 工作流，研发不需要 |
| 10. 上线指标 | ✅ **保留** | 上线后验证需要 |
| 11. 红线 | ✅ **保留** | 实施硬约束 |
| 12. 工时预估 | ❌ **跳过** | PM 估算，研发会自己评估 |

---

## 4. requirements-spec.md 输出模板

```markdown
---
doc_type: requirements-spec
derived_from: {date}_{需求名}_PRD.md
generated_at: {now}
generated_by: spec-extractor skill
ai_consumption_format: structured
---

# Requirements Spec — {需求名}

> ⚠️ 本文件由 `spec-extractor` skill 从 [PRD 全量](./{date}_{需求名}_PRD.md) 自动派生 —— **请勿手改**。
> 如需调整，去 PRD.md 改，下次 sync 时本文件自动重生。
>
> **本文件目的**：给研发负责人 / QA / 研发同学的**精简需求 spec**，剥离了业务背景 / 视觉描述 / 决策上下文。系统行为 + 接口契约 + 验收测试 全部保留。

---

## User Story

As a {主要用户角色}
I want to {核心能力}
So that {业务价值}

---

## 1. 一句话背景

{从 PRD 1.1-1.2 压缩为 1-2 句}

---

## 2. 系统范围

模块清单：
- 5.1 {模块名} — {一句话定位}
- 5.2 {模块名} — {一句话定位}
- ...

---

## 3. 用户动线

{保留 PRD 第 3 章 Mermaid 流程图}

---

## 4. 系统行为定义（按模块展开）

### 4.1 {模块 1 名称}

#### 4.1.1 控件清单

{从 PRD 5.1.3 完整复制 YAML button_spec / control 定义}

#### 4.1.2 弹窗 / 状态 / 异常

{从 PRD 5.1.4 完整复制 — 含 stateDiagram + error_scenarios YAML}

#### 4.1.3 数据规范

{从 PRD 5.1.5 完整复制 — 含 endpoint / field / analytics_event YAML}

#### 4.1.4 验收测试（Gherkin）

{从 PRD 5.1.6 完整复制 — Gherkin Feature/Scenario}

### 4.2 {模块 2}
...

---

## 5. 文案规范（UI 文案约束）

{从 PRD 6.1 复制 — 终端用户文案部分；6.2 内部术语跳过}

---

## 6. 非功能需求

{从 PRD 第 7 章完整复制}

---

## 7. 工程影响范围

{从 PRD 8.1-8.7 完整复制 — 含 PM 草稿 + ⚠️ 研发深化标记}

---

## 8. 上线指标 + 红线

{从 PRD 第 10 + 11 章复制}

---

## 9. 跟 PRD 全量的回链

如需查看：
- **业务背景 / 决策上下文** → [PRD 第 1 章](./{date}_{需求名}_PRD.md#1-产品概述)
- **用户场景详述** → [PRD 第 2 章](./{date}_{需求名}_PRD.md#2-目标用户与使用场景)
- **视觉规范** → [PRD HTML 派生展示版](./{date}_{需求名}_PRD.html)
- **待确认问题** → [PRD 第 9 章](./{date}_{需求名}_PRD.md#9-待确认问题)
```

---

## 5. 跟 PRD 同步规则

| 触发场景 | 行为 |
|---|---|
| PRD 主文件改动 | 自动重生 requirements-spec.md（覆盖旧版）|
| PRD frontmatter `version` 升级 | 同步更新 requirements-spec `derived_from` 引用 |
| PRD 章节顺序变 | 重生时按新顺序剥离 |
| 研发反馈"需求 spec 缺 X" | 看 PRD 全量是否真有 X — 没有则 PM 补 PRD；有则调整剥离规则纳入本 skill |

⚠️ **绝对禁止**：手改 requirements-spec.md。如发现手改，下次 sync 自动覆盖丢失。

---

## 6. 失败模式

| 失败场景 | 处理 |
|---|---|
| PRD 缺 5.x.3 YAML button_spec | 警告"PRD 5.x.3 不是 AI-first 格式，无法机器抽取" — 让 prd-writer-agent 重写 |
| PRD 缺 5.x.6 Gherkin | 警告"PRD 5.x.6 不是 Gherkin，需求 spec 第 4 章验收测试段缺失" |
| PRD 含模糊词（流畅 / 美观 / 友好 / 顺畅 / 清晰 / 高效 / 良好）| 警告并标 ⚠️ 待 PM 修订 |

---

## 7. 跟其他 skill 的协作

| skill | 协作关系 |
|---|---|
| `prd-writer-master` | 上游：产出 PRD.md |
| `prd-writer-agent` | 触发器：落盘后调用本 skill |
| `spec-extractor`（本）| 主体：派生 requirements-spec.md |
| `prd-test-validator` | 平行：派生 tests/ + 校验报告 |
