---
模块: /admin/observability — 可观测性聚合面板（路由 + 持久侧边栏）
最后验证日期: 2026-05-10
最后验证 commit: 7b70f34（autoflow main 分支）
反推方法: 代码扫描（前端 + 后端契约 + migrations + git log），未读 PRD
---

> 📌 **本文档是从 autoflow 代码反推的"现状速查"**——
> 只写代码 100% 反推可信的事实 + 代码可见的设计模式。
> 不写业务 why / 用户场景——那是 PRD 的活。
> 写新需求前重新 pull autoflow + 检查最后验证日期是否过期 4 周+。

---

## 1. 模块定位

`/admin/observability` — 可观测性聚合面板（Phase B 骨架已上线，3 个 Phase C 子页 WIP）。本身**不含独立业务逻辑**，主要是把分散在 admin 各处的运维入口聚合到一个持久侧边栏。

权限：`canViewServiceHealth`（admin / developer）。

---

## 2. 模块路由（7 个子路由）

| 路径 | 用途 | 状态 | 复用自 |
|---|---|---|---|
| `/admin/observability` | 首页重定向 → `/overview` | ✅ Ready | — |
| `/admin/observability/overview` | 项目列表 + KPI 头 | ✅ Ready | `/admin` 根 dashboard |
| `/admin/observability/tasks` | 批任务调试 | ✅ Ready | `/admin/debug/batch-tasks` |
| `/admin/observability/exceptions` | 反馈历史 + 事件时间线 | ✅ Ready | `/admin/feedback-history` |
| `/admin/observability/workflow` | 健康检查 4 tab | ✅ Ready | `/admin/health` |
| `/admin/observability/projects` | 项目维度聚合（热力图 / 成本 / SLA）| 🟡 Phase C WIP | — |
| `/admin/observability/metrics` | 质量指标 dashboard（QC 率 / 审核率 / 成本 / SLA）| 🟡 Phase C WIP | — |
| `/admin/observability/config` | Feature flag + 全局开关 + Quota 配置 | 🟡 Phase C WIP | — |

导航：`ObservabilitySidebar`（w-44，fixed @left-16）+ 7 nav items（4 ready + 3 wip）。

---

## 3. UI 单元清单

**Ready（4 个子页都是复用现有组件）**：
- GlobalMetricsHeader（KPI 板）
- ProjectCard + ProjectCardSkeleton（卡片网格）
- ErrorsLineChart + QuotaTrendBar（图表）
- FilterPills（筛选）
- Tabs（4-tab health page）
- AlertDialog（强制 cancel workflow 二次确认）

**WIP Placeholder（3 个）**：BarChart3 icon + dashed border card + "Phase C 待实装" 文案（共用 `PlaceholderShell` 组件）。

---

## 4. 接口清单

> 大部分复用其他 admin 模块的接口，本模块只做路由聚合。

| 路由 | 用途 | 来源模块 |
|---|---|---|
| `/api/admin/health/services` | provider 状态快照 | admin/health |
| `/api/admin/health/errors?since=24h` | 24h 错误事件 | admin/health |
| `/api/admin/health/projects` | 在跑项目列表 | admin/health |
| `/api/admin/health/quota` | RPM 配额状态 | admin/health |
| `/api/admin/circuit-breaker` | 全部 provider 熔断器状态 | admin/health |
| `/api/admin/circuit-breaker/{provider}` | 手动开/关 breaker | admin/health |
| `/api/admin/workflows?status=RUNNING&stats=1` | 运行中 workflow 列表 | admin/health |
| `/api/admin/workflows/{id}/cancel` | 强制取消 workflow | admin/health |
| `/api/admin/feedback-history?...` | 反馈历史 | admin/feedback-history |

---

## 5. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `core_pipeline.audit_events` | project_id, actor_user_id, action_kind, occurred_at | 审计日志（append-only）|
| `core_pipeline.feedback_history` | project_id, applied_at, status | 反馈生效结果汇总 |
| `core_pipeline.p_assets` | project_id, entity_id, archived_at | P 管线美术资产指纹（soft-delete）|
| `core_pipeline.preference_pairs` | project_id, asset_a_id, asset_b_id, chosen_at | DPO 偏好对 |
| `core_pipeline.gen_events` | user_id, workflow_id, node_id, model | 生成事件（含 observability 列）|

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| layout 默认 RSC（不加 use client）| 红线 #1 | `/admin/observability/layout.tsx:33` |
| Sidebar 7 nav items 固定配置 | 4 ready + 3 wip | `ObservabilitySidebar.tsx:37-44` |
| Active 状态判断 | 精确路径或子路径前缀 | `ObservabilitySidebar.tsx:63-65` |
| **EMPTY_METRICS 零值是显式信号**（禁止 demo data 回退）| audit-round2 P1 | `_dashboard-content.tsx:29-48` |
| 反馈写入失败必须返回 `ok:false` + error_type + 业务化文案 | P0 硬约束 ❌#1 | `/backend/api/routes/feedback.py:85-91` |
| force-cancel feedback_history audit 写入失败处理 | error 日志 + 计数 metric | `feedback.py:219-251` |
| audit_events.event_id 是行引用，**非幂等键** | idempotency_key 由调用方供应 | `migrations/137:12` |
| audit_events.actor_kind CHECK 枚举 | 8 值（user / admin / system_cron / system_recovery / system_workflow / system_agent 等）| `migrations/137:26-35` |
| feedback_history.intent_json schema 对齐源 | `aigc_video_pipeline/feedback/schemas.py` | `migrations/090:22-32` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **Re-export 路由聚合** | overview/tasks/exceptions/workflow 页无 render 逻辑，直接 `export default ComponentFromCorePageModule` | 加新观测子页用相同模式，不要 copy-paste |
| **RSC + Client 混合** | layout 是 RSC，子页面各自决定是否 use client（sidebar 只读，可 RSC）| 加新组件先想能否 RSC，能就别加 use client |
| **两层 Sidebar + Content Offset** | 全局 icon 栏 w-16 + 子 nav w-44 @left-16；main 通过 `md:pl-44` 让位（响应式 hidden@sm）| 加新 admin 模块用相同两层结构 |
| **SWR independent keys** | health page 4 个 useSWR 独立 cache key，错误时红色 banner 不阻塞其他 tab | 加新数据源用独立 key |
| **Placeholder Dashed UI** | 3 WIP 页共用 `PlaceholderShell`（icon + dashed border + 文案 + Phase tag）| 加新 WIP 页用此组件 |
| **Audit Event Immutable Log** | append-only，idempotency_key 去重，actor_kind 枚举防伪用户 UUID | 加新 audit 类型必须落 audit_events 表 |
| **Soft Delete** | p_assets.archived_at；preference_pairs 反向 FK 保证 DPO 数据指向真实资产 | 删除类操作走 archived_at，别 DELETE |

---

## 7. 最近 3 个月活跃改动

| commit / PR | PM 视角描述 |
|---|---|
| dea463b (#444) | admin observability 路由 + 持久侧边栏（Phase B 骨架）|
| #638 | CI guard p-pipeline audit event contract |
| #618 | 记录 P05 start production fanout audit |
| #616 | P04a face QC audit 埋点 |
| #614 | 集中化 p-pipeline audit event writes |
| #599 | P05 reviewer audit events |
| #591 | audit event write 基础设施 |

---

## 8. 📍 反推可能不准的点

- 3 个 WIP 页（projects / metrics / config）的最终设计 —— 当前是 Placeholder，实装时可能与现 Sidebar 描述出入
- audit_events.actor_kind 完整 8 值枚举 —— 只列举 6 种，未确认全集
- /admin/observability 在生产是否已对所有 admin 用户可见，或仍是 internal preview
