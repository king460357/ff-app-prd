---
模块: /admin/access — 权限管理（RBAC + 多租户 + 跨企业）
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

`/admin/access` — RBAC 权限管理系统，6 Tab 模式：成员（members）/ 自定义角色（roles）/ 企业（tenants）/ 跨企业连接（cross）/ 飞书部门映射（departments）/ 权限审计（audit）。

权限：分级到操作级（如 `roles.read` / `roles.create` / `users.role.grant` / `users.role.revoke` 等），前端按 `canXxx` 渲染按钮可见性，后端同名校验。

---

## 2. UI 单元清单

| 单元 | 用途 | 关键字段 |
|---|---|---|
| 成员列表 | 按部门/角色分组 + 搜索 | id / name / department / roles[] |
| 角色列表 | 系统/自定义角色 + 权限编辑 | key / display_name / permission_keys / member_count |
| 权限编辑 Dialog | 勾选权限（按 8 类资源分组）| permission_keys: string[] |
| 企业列表 | 企业卡片 + 成员/角色预览 | name / status / member_count / custom_role_count / connections |
| 部门映射表 | 飞书部门 → 默认企业 + 默认角色 | feishu_department_id / priority / default_tenant_id / default_role_id |
| 跨企业连接 | 单/双向 connection + 审批 | source_tenant_id / target_tenant_id / direction / scope / status |
| 权限申请审批 | 成员发起 + 管理员批/拒 | requester_id / target_role_id / status |
| 审计日志 | 权限变更 timeline + 跨企业周报 | action / target_type / actor_name / cross_tenant / ip |
| 批量角色分配 | 多成员 + 单角色 grant/revoke | action: grant\|revoke |

控件：列表搜索 / 虚拟滚动（Virtuoso）/ 复制角色或企业 / Dialog 模态创建编辑。

---

## 3. 接口清单

| 路由 | 方法 | 权限门票 | 出参顶层 |
|---|---|---|---|
| `/api/admin/permissions` | GET | `roles.read` | { permissions[] } |
| `/api/admin/roles` | GET / POST | `roles.read` / `roles.create` | { roles[] } / { role } |
| `/api/admin/roles/[roleId]/permissions` | PUT | `roles.permission.manage` | success ack |
| `/api/admin/user-roles` | GET / POST / DELETE | `users.read` / `users.role.grant` / `users.role.revoke` | { user_roles[] } |
| `/api/admin/user-roles/bulk` | POST | `users.role.grant` 或 `revoke` | { action, role_name, updated, skipped } |
| `/api/admin/tenants` | GET / POST / PATCH / DELETE | `tenants.*` 系列 | { tenants[] } / { tenant } |
| `/api/admin/tenant-connections` | GET / POST / PATCH | `tenant_connections.*` | { connections[] } |
| `/api/admin/department-mapping` | GET / POST | `department.mapping.manage` | { items[] } |
| `/api/admin/permission-requests` | GET | `permission_request.read` | { requests[] } |
| `/api/admin/permission-audit` | GET | `admin.audit` | { events[], summary } |

---

## 4. 数据表清单

| 表 | 关键字段 | 用途 |
|---|---|---|
| `core_pipeline.tenants` | id, key, name, type（enterprise/system/personal）, plan, status | 多租户容器 |
| `core_pipeline.roles` | id, tenant_id（NULL=系统共享）, key, is_system, is_assignable, priority | 角色定义 |
| `core_pipeline.user_roles` | user_id, tenant_id, role_id, expires_at | 用户→角色（含过期）|
| `core_pipeline.permissions` | id, key, resource, action, is_cross_tenant, is_system | 权限 catalog |
| `core_pipeline.role_permissions` | role_id, permission_id | 角色→权限（多对多）|
| `core_pipeline.user_tenants` | user_id, tenant_id, is_default, status | 用户成员资格 |
| `core_pipeline.permission_requests` | id, tenant_id, requester_id, target_role_id, status | 自助权限申请 |
| `core_pipeline.feishu_department_role_map` | feishu_department_id, default_tenant_id, default_role_id, priority | 飞书部门映射 |
| `core_pipeline.tenant_connections` | source_tenant_id, target_tenant_id, direction, connection_type, status | 跨企业关系 |
| `core_pipeline.permission_audit_log` | tenant_id, actor_id, action, target_type, cross_tenant, ip, user_agent | 权限变更审计 |

---

## 5. ⚠️ 关键硬约束（PM 写新需求前必读）

| 约束 | 当前值 | 来源 file:line |
|---|---|---|
| Role key 格式 | `^[a-z][a-z0-9_]{1,63}$` | `access-control-core.ts:1` |
| Role display_name 长度 | ≤80 字符 | `access-control-core.ts:21` |
| Role 描述长度 | ≤240 字符 | `access-control-core.ts:27` |
| Role priority 范围 | [0, 999] | `access-control-core.ts:63` |
| 批量角色分配上限 | 500 人 / 次 | `access-admin.ts:127` |
| Role key 唯一性 | 按 tenant 唯一（NULL=系统共享）| `migrations/096` |
| 用户默认 tenant | 一用户一默认（唯一索引）| `migrations/095` |
| Pending 申请唯一性 | (tenant_id, requester_id, target_role_id) WHERE status='pending' | `migrations/133:32-34` |
| 部门映射 priority | 整数无上限，高优先级先匹配 | `rbac_sync.py:68` |
| Tenant 状态枚举 | active / suspended / archived | `migrations/095` |
| Connection 状态枚举 | pending / accepted / rejected / revoked / expired | `migrations/145+` |
| Permission request 状态枚举 | pending / approved / rejected / cancelled | `migrations/133` |
| 资源 catalog（权限分类）| assets / departments / episodes / generate / projects / review / roles / stats / tasks / users（10 类）| `access-admin.ts:132-143` |
| 遗留基础角色（不能移除最后一个）| {admin, manager, developer, director, hub, partner, member} | `access-control-core.ts:4-12` |

---

## 6. 🔗 线上已有的设计模式（新需求要遵守）

| 模式 | 现状 | 新需求设计要点 |
|---|---|---|
| **两层权限校验** | 前端 `requirePermissionKey()` + 后端 `requirePermission()`，门票名相同 | 加新接口必须前后端两端都加同名权限 |
| **跨租户 bypass** | 系统角色 `bypasses_tenant_isolation=TRUE` 时后端 RLS 放行 | 新跨企业功能要明确是否走 bypass |
| **角色优先级拦截** | UI 不能授予同级或更高 priority 的角色 | 加新角色等级要算入 priority 拦截链 |
| **审计日志自动写** | 所有 mutation 通过 `writeAudit()` 记录（含 IP + User-Agent）| 加新 mutation 接口必须接入 writeAudit |
| **唯一 pending 申请** | (tenant_id, requester_id, target_role_id) 仅 1 条 pending（partial unique index）| 新申请类工作流要考虑这种 partial 唯一约束 |
| **部门多匹配按 priority 取最高** | 用户多部门时取 priority 最大的映射 | 新映射类规则可复用此模式 |
| **乐观更新 + 跳过冲突** | 批量操作返回 `{ updated, skipped }`，UI 显示跳过数 | 新批量接口要返回跳过明细 |
| **跨企业连接的 scope 配置** | 创建连接时可指定 scope（view_projects / review / users）| 加新跨企业功能要考虑 scope 隔离 |
| **6 Tab 共享 mode 状态** | searchParams 的 `mode` 切换 6 Tab，每 Tab 独立数据源 + 过滤器 | 加 Tab 用 searchParams 不要嵌套路由 |

---

## 7. 最近 3 个月活跃改动（PM 视角）

| commit | PM 视角描述 |
|---|---|
| 756ad75 | 权限中心信息架构优化 |
| 18dd4c9 | 租户边界 + 统计权限加固 |
| 6752b88 (#615) | 项目创建权限门控（fix(rbac)）|
| 052b213 (#613) | 企业管理员可维护自定义角色 |
| 82ea9c2 (#554) | 跨企业审计周报新增（本周/上周/24h 三指标）|
| fb80a04 (#553) | 审核人角色配置入口 |
| 0e46b05 (#550) | 项目访问权限展示（基于资源授权）|
| 3f0bff4 (#548) | 项目团队资源授权 API |
| 7c305cb (#525) | 权限申请自助工作流 |
| 1583963 (#524) | 部门映射 UI |
| 8d642fe (#523) | 租户访问管理基础 |

---

## 8. 📍 反推可能不准的点

- 各权限门票（如 `roles.permission.manage` / `tenant_connections.approve` 等）的全部分类和层级——只 grep 到使用点，未确认完整 catalog
- "10 类资源"是否真是 10 类（access-admin.ts:132-143 看到的是 10 项，可能后续已加）
- 跨企业连接的 scope 选项是否仅 `view_projects / review / users` 三种
