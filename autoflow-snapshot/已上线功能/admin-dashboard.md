---
模块: /admin — 主 admin dashboard（剧集生产中心）
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

`/admin` — 后台 dashboard 根页面，**剧集生产进度中心**。

主要功能：项目列表（按权限过滤 mine / all）+ 5 种筛选 + 派活管理 + KPI 北星指标。

权限：`admin` 或 `developer` 角色（详见 `global-nav-sidebar.tsx:35-38`）。

---

## 2. 左侧栏 Admin 子页面导航（18 项 — 其他 PM 写 admin 类需求时必看的"现状清单"）

| 分组 | 子项 |
|---|---|
| **全员可见** | 生成（/generate）/ 统计（/admin/generate-stats）|
| **Admin + Developer** | 剧集（/admin 当前）/ 数据（/admin/observability）/ 团队（/admin/access）/ 验收（/review/art-assets）/ 冲刺（/admin/sprint）/ 健康（/admin/health）/ 调试（/admin/debug）/ 技能（/admin/skills）/ 分镜（/admin/storyboard）/ 路由（/admin/routes）/ Prompt 库（/admin/prompts）|
| **Admin + Manager + Developer** | 权限申请（/admin/permission-requests）/ 任务（/tasks）|

> ⚠️ 生产环境对非 admin 用户**只显示** generate / generate-stats / access 三项（`global-nav-sidebar.tsx:194,236`）

---

## 3. UI 单元清单

| 单元 | 用途 |
|---|---|
| 顶部栏（sticky）| 刷新 + 新建项目 + 状态标签（real-db / load-error）|
| 视野 chip | "我的项目 ⟷ 所有项目" 切换（仅 canViewAllProjects 显示）|
| 筛选条 | 桌面 inline / 移动端 sheet drawer（高 60vh）；5 种 + 计数 |
| 搜索框 | 实时过滤（lowercase）|
| 项目网格 | 1 / md:2 / lg:3 / xl:4 列响应式；20 卡/页分页 |
| AssignmentDrawer | 全局派活抽屉 |
| DepartureBanner | 离职员工待派活告警 |
| RoleMismatchBanner | 角色异常分配告警 |
| 分页控件 | 中心对齐，仅 >1 页时显示 |

---

## 4. 接口清单

| 路由 | 方法 | 用途 |
|---|---|---|
| `/api/projects?scope={mine\|all}` | GET | 项目列表（支持权限过滤）|
| `/api/orchestrator/data-center/summary` | GET | 北星 KPI（成本 / 吞吐 / 反馈）|
| `/api/orchestrator/p05-status?project_id=<id>` | GET | gate 审批状态 |

**KPI 数据源映射**（`_dashboard-content.tsx:87-108`）：
- `cost.avg_cost_per_node_run` → `avgComputeCost`
- `throughput.avg_node_duration_seconds` → `avgProductionTime`（分钟制）
- `throughput.pending_review_tasks` → `pendingQC`
- `feedback.open_return_tickets` → `pendingAssets`

---

## 5. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `core_pipeline.projects` | id, name, status, created_by, p_chain_progress_json, e_chain_progress_json | 项目主表 |
| `core_pipeline.episode_assignments` | assignee_user_id, project_id | 派活关联 |
| `core_pipeline.users` | id, is_active, last_login_at | 用户表（is_active=FALSE 用于离职检测）|
| `core_pipeline.project_briefs` | project_id, brief_json | 项目简介（新建页用）|

---

## 6. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| **无 mock 数据回退** | 失败显示 EMPTY_METRICS 零值 + 红色 Alert，禁止演示态混真态 | `_dashboard-content.tsx:25-28, 111-112` |
| **每页项目数** | 20（ITEMS_PER_PAGE 硬编码）| `_dashboard-content.tsx:55` |
| **scope 权限门** | canViewAllProjects 决定 mine/all 可见性；director 角色默认 mine | `_dashboard-content.tsx:74-84, 119` |
| **`/admin` 不重定向** | 红线 #8（保持独立 URL）| `page.tsx:5-10` |
| **生产环境非 admin 仅看 3 项** | generate / generate-stats / access | `global-nav-sidebar.tsx:194, 236` |
| **tap target ≥ 44px** | 所有按钮 h-10 min-h-[44px]（移动端可达性）| `_dashboard-content.tsx` 各 button |

---

## 7. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **状态三态** | `dataSource: "loading" \| "real" \| "error"` 替代 mock-real-loading（audit-round2 P1）| 新数据接入用相同三态，禁止 mock 回退 |
| **幂等派活** | `assignmentRefreshKey` 强制 ComponentKey 刷新 | 加新强制刷新场景用相同 key 模式 |
| **声明式过滤链** | filter → search → pagination 三链式 memoized 计算 | 加新筛选维度插入此链 |
| **Promise.allSettled 并发** | projects + metrics 并行拉取，metrics 失败不阻塞 projects | 加新数据源走 allSettled，关键失败可独立兜底 |
| **响应式 1/2/3/4 列网格** | grid 1 / md:2 / lg:3 / xl:4 + Skeleton 8 卡占位 → 真实网格 | 加新卡片列表用相同响应式 |
| **权限层叠** | roles check → permissionAny check → permissionMode OR/AND 分叉 | 加新页面权限走相同层叠 |
| **导航匹配** | getIsActive() 多路径汇聚（drama / projects 都 → 剧集 tab）| 加新页面/子路径用相同 active 判定 |

---

## 8. 最近 3 个月活跃改动

| commit | PM 视角描述 |
|---|---|
| dea463b (#444) | admin observability 路由 + 持久侧边栏 |
| 59c0291 | Sprint 4 F4-3/F4-4/F4-5/F4-6（移动端适配 + 权限差异化）|
| 76f1ae9 (#277) | Sprint 3 新建项目向导 + 剧本流式解析 + projects CRUD |
| d33423e ~ 50c94cc | admin-stats 成本构成 / 饼图 / 排版 / 拆分（×15 fix）|

---

## 9. 📍 反推可能不准的点

- 18 项导航是否完整列出 —— 仅 grep `global-nav-sidebar.tsx`，可能漏新增项
- 角色权限矩阵（如 manager 能看哪些）—— 仅看到分组规则，未深挖每项的具体角色集
- "scope=mine" 时 director 默认行为是否所有 director 都一样
