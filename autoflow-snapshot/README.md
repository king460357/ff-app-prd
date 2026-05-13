# autoflow-snapshot — autoflow 线上现状速查

给其他 PM 写新需求前查阅 autoflow 已上线功能的速查文档库。

## 这是什么

每份 snapshot 文档对应 autoflow 的一个 **已上线模块**（admin 页面 / 创作者端 tab / cron 任务等），含：

- 模块定位（一句话 + 权限要求）
- UI 单元清单（用户能看到的每个块）
- 接口清单（API 路由 + 入参出参顶层）
- 数据表清单（关键字段 + 用途）
- ⚠️ **关键硬约束**（含 file:line 标注，PM 写新需求若改动必须在 PRD 第 8 章显式列出）
- 🔗 **线上已有的设计模式**（新需求要遵守，避免割裂一致性）
- 最近 3 个月活跃改动
- 📍 反推可能不准的点（自我标记）

## 这不是什么

- ❌ **不是 PRD**——没有业务背景 / 用户场景 / 设计动机
- ❌ **不是真理源**——内容从 autoflow main 分支代码反推，最终事实仍以 autoflow 仓代码为准
- ❌ **不是详尽规范**——是"速查"，不是 100% 全覆盖

## 何时更新

**触发 1：每个 batch 上线后**——产品总监把该 batch 涉及的功能"是什么 / 关键约束 / 设计模式"写到对应 snapshot 文件（5-10 分钟）。

**触发 2：开始写新需求前**——
1. `cd /Applications/我的电脑/AI /autoflow && git pull origin main`
2. 看本目录每份文件的 `最后验证日期`，过期 4 周+ 时重做反推

## 怎么用（其他 PM 写新需求）

1. **找对应模块**：你的需求涉及哪个 admin 页面 / 创作者端 tab？打开对应 `已上线功能/{模块}.md`
2. **必读 §5 ⚠️ 关键硬约束**：你的新需求若涉及任何 hardcoded 值（速率、容量、阈值等）的改动，必须在 PRD 第 8 章显式列出"从 X 改成 Y"
3. **必读 §6 🔗 线上已有的设计模式**：你的新功能要遵守同模块已有的设计模式（条件 Tab / 异步任务 / SSE 推送 / 租户隔离 / 权限二级化等）
4. **看 §8 📍 反推可能不准的点**：本文档的不确定项；遇到这些项需要回 autoflow 代码核对

## 当前 snapshot 清单

| 文件 | 模块 | 类型 |
|---|---|---|
| `已上线功能/admin-dashboard.md` | /admin | 后台主 dashboard（剧集生产中心 + 18 项导航）|
| `已上线功能/admin-generate-stats.md` | /admin/generate-stats | 后台数据统计 |
| `已上线功能/admin-access.md` | /admin/access | 后台权限管理（RBAC + 多租户 + permission-requests）|
| `已上线功能/admin-health.md` | /admin/health | 后台系统健康度巡检 |
| `已上线功能/admin-observability.md` | /admin/observability | 后台可观测性聚合（路由 + 持久侧边栏）|
| `已上线功能/generate.md` | /generate | 创作者端视频/图片生成 |
| `已上线功能/art-review.md` | /review/art-assets | 艺术素材审核（P01-P05 多阶段）|
| `已上线功能/review-multi-stage.md` | /review/visual + /audiovisual + /final | 多阶段审核（E14/E16/E18，合并 1 份）|

> **待补**（按需）：admin/feedback-history、admin/storyboard、admin/projects、admin/sprint、admin/debug、admin/skills、admin/routes、admin/prompts、tasks、profile/me、后端 cron、MCP vendor 集成。

## 工艺

每份 snapshot 反推工艺：

1. 用 Explore agent 扫 autoflow 仓的对应模块（前端 + 后端契约 + migrations + git log），输出结构化事实清单
2. 整理成 8 段 PM 视角文档（不写业务 why）
3. 标注每条 file:line 和"反推可能不准"
4. sync 到 pm-workflow GitHub 仓（顶层 `autoflow-snapshot/`）

详细规则见 product 仓 memory `feedback_prd_no_history_residue.md` + `project_product_repo_v3_batch_org.md` 第 4 节。
