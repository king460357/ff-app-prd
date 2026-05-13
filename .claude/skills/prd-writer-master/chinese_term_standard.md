# 中文术语与英文说明标准

> 让产品/UI/QA/运营都能看懂——英文术语必须有中文说明。

---

## 1. 基本原则

1. **正文优先使用中文**
2. **英文术语首次出现时必须加中文说明**：使用 `中文（英文）` 格式，如 `提示词（prompt）`
3. **状态名优先使用中文**（详见第 3 节）
4. **字段表可保留英文**，但必须有中文说明列

---

## 2. 常用术语对照表

### 2.1 通用产品/技术术语

| 英文 | 推荐中文 |
|------|---------|
| PRD | 产品需求文档 |
| MVP | 最小可用版本 |
| UI | 用户界面 |
| UX | 用户体验 |
| QA | 测试 / 质量验收 |
| API | 接口 |
| Endpoint | 接口路径 |
| SDK | 开发工具包 |
| Webhook | 回调 |
| Token | 令牌 |
| Workflow | 工作流 |
| Pipeline | 流水线 |

### 2.2 状态与流程类

| 英文 | 推荐中文 |
|------|---------|
| Loading | 加载中 |
| Pending | 待处理 |
| Running | 进行中 / 生成中 |
| Success / Succeeded | 成功 / 已完成 |
| Failed | 失败 |
| Partial Failed | 部分失败 |
| Idle | 未开始 |
| Queued | 排队中 |
| Locked | 已锁定 |
| Readonly | 只读 |
| Disabled | 已禁用 / 置灰 |
| Fallback | 兜底 |
| Retry | 重试 |
| Timeout | 超时 |

### 2.3 内容/资源类

| 英文 | 推荐中文 |
|------|---------|
| Asset | 资产 |
| Resource | 资源 |
| Prompt | 提示词 |
| Template | 模板 |
| Variant | 变体 |
| Version | 版本 |
| Draft | 草稿 |
| Published | 已发布 |
| Archived | 已归档 |

### 2.4 权限/角色类

| 英文 | 推荐中文 |
|------|---------|
| Permission | 权限 |
| Role | 角色 |
| Group | 分组 |
| Owner | 拥有者 |
| Admin | 管理员 |
| Member | 成员 |
| Guest | 访客 |

### 2.5 交互/UI 类

| 英文 | 推荐中文 |
|------|---------|
| Tab | 标签页 |
| Tooltip | 浮窗提示 / 气泡提示 |
| Popover | 弹层 |
| Modal / Dialog | 弹窗 / 对话框 |
| Toast | 轻提示 |
| Banner | 横幅 |
| Drawer | 抽屉 |
| Canvas | 画布 |
| Node | 节点 |
| Workflow | 工作流 |

### 2.6 业务/数据类

| 英文 | 推荐中文 |
|------|---------|
| Scene | 场景 |
| Job | 异步任务 |
| Task | 任务 |
| Event | 事件 |
| Trigger | 触发器 |
| Filter | 筛选器 |
| Tag | 标签 |
| Category | 分类 |

---

## 3. 状态命名规范

正文中的状态**必须使用中文**：

| 推荐中文 | 对应英文枚举（仅字段表使用） |
|---------|--------------------------|
| 未开始 | idle / not_started |
| 排队中 | queued |
| 生成中 | running / processing |
| 已完成 | succeeded / success / done |
| 生成失败 | failed |
| 部分失败 | partial_failed |
| 已保存 | saved |
| 未保存 | unsaved |
| 只读 | readonly |
| 已锁定 | locked |
| 已禁用 / 置灰 | disabled |
| 已发布 | published |
| 已归档 | archived |

---

## 4. 字段表规范

字段表可以保留英文字段名（研发要用），但**必须有中文说明列**：

### 标准格式

| 字段名 | 中文说明 | 类型 | 取值 / 说明 |
|--------|---------|------|------------|
| job_status | 异步任务状态 | string | 未开始 / 排队中 / 生成中 / 已完成 / 生成失败 |
| user_role | 用户角色 | enum | 管理员 / 成员 / 访客 |
| created_at | 创建时间 | datetime | ISO 8601 格式 |

---

## 5. 写作示例

### ❌ 错误示例

> "用户进入 canvas 后，点击 node 触发 workflow，等待 job 完成。"

（一连串英文，非研发角色看不懂）

### ✅ 正确示例

> "用户进入画布（canvas）后，点击节点（node）触发工作流（workflow），等待异步任务（job）完成。"

（首次出现时加中文说明，后续可继续使用英文或中文）

### ✅ 更好的示例

> "用户进入画布后，点击节点触发工作流，等待异步任务完成。"

（如果团队对术语已有共识，全中文更友好）

---

## 6. 例外情况

以下场景**保留英文不必转换**：

1. 字段名（`user_id`、`created_at`）
2. 接口路径（`/api/v1/users`）
3. 配置项（`max_retry_count`）
4. 状态枚举值（数据库存储用）
5. 代码片段、SQL、JSON

但**首次出现**时仍建议在旁边加中文说明，例如：

```
GET /api/v1/jobs?status=running   # 查询正在生成中的异步任务
```
