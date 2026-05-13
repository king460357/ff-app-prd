# 产研协作工作流操作手册

给**产品**和**技术**两个角色的操作手册，看自己章节即可。

---

## 概览

```
┌─────────── 产品 ───────────┐                    ┌─────────── 技术 ───────────┐
│ ① 写 requirement.md + ui/  │  ─── git push ──▶  │ ② /ai-review <prd-path>    │
│    在 PRD 仓库 push        │                    │    复制 ai-review.md 回 PRD │
│                            │                    │                            │
│ ③ 编辑 ai-review.md        │  ─── git push ──▶  │ ④ /ai-review <prd-path>    │
│    [待对齐] → [已对齐]      │   (重复 ③ ④ 直到无 [待对齐])                   │
│    填"产品答复"            │                    │                            │
│                            │                    │                            │
│ ⑤ 文末追加                 │                    │ ⑥ /dev-plan <prd-path>     │
│   [需求已完全对齐] ...     │                    │ ⑦ 填 Owner                 │
│                            │                    │ ⑧ /gen-feishu-csv <plan>   │
│                            │                    │ ⑨ 开发 + PR review          │
│                            │                    │ ⑩ /gen-tests <prd-path>    │
└────────────────────────────┘                    └────────────────────────────┘
```

**核心约定**：
- **PRD 仓库** 只放文档，所有 Claude 命令在**代码仓库**执行
- ai-review.md 真相在 PRD 仓库；代码仓库 `ai_workflow/<feature>/` 是中间产物
- 命令统一接 `<prd-path>`（如 `E:\luxi\prd-repo\v1`），feature 名取最后一段

| 仓库 | 路径 | 主干 |
|---|---|---|
| PRD repo | `E:\luxi\prd-repo` | `main` |
| App repo (CineFlow) | `E:\luxi\CineFlow` | `main` |

| 命令 | 输入 | 输出 |
|---|---|---|
| `/ai-review <prd-path>` | PRD 目录 | `ai_workflow/<feature>/ai-review.md`（首次/增量自动识别） |
| `/dev-plan <prd-path>` | PRD 目录 | `ai_workflow/<feature>/dev-plan.md` |
| `/gen-feishu-csv <feature>/dev-plan.md` | dev-plan.md 完整路径 | 同目录下 `dev-plan-feishu.csv` |
| `/gen-tests <prd-path>` | PRD 目录 | `ai_workflow/<feature>/test-cases.md` + `tests/*.test.ts` |

PRD 仓库目录：
```
prd-repo/<feature>/
├── requirement.md       # 产品提交（必须）
├── ui/                  # 产品提交（必须，至少 1 张图）
└── ai-review.md         # 技术首轮生成 → 产品对齐
```

---

# 一、产品操作

> 全程只在 PRD 仓库工作，不需要打开代码仓库。

## 1.1 首次准备（一次性）

```bash
cd E:\luxi
git clone https://github.com/Luxi-Nebula/prd-repo.git
```

## 1.2 提交新需求

```bash
cd E:\luxi\prd-repo
git checkout main && git pull
git checkout -b feature/<你的名字>/<feature-name>     # 例：feature/ray/v1
```

新建 `<feature-name>/requirement.md` 和 `<feature-name>/ui/*.png`（写作规范见 PRD 仓库 README）。

```bash
git add <feature-name>/
git commit -m "feat(prd): add <feature-name>"
git push -u origin feature/<你的名字>/<feature-name>
```

📣 通知技术：「`<feature-name>` 已提交，请触发 AI Review」

## 1.3 回答 AI Review

技术 push ai-review.md 到分支后：

```bash
git pull
```

打开 `<feature-name>/ai-review.md`：
- §1 需求理解总结 — 看 Claude 是否理解对了
- §2 不确定点 Q1, Q2... — **逐条回答**
- §3-5 风险/边界/质疑 — 仅供参考

把每个 Q 的 `[待对齐]` 改成 `[已对齐]` 并填「产品答复」：

```markdown
### Q1. 登录失败次数限制策略
- **状态**：[已对齐] @ray 2026-05-04
- **产品答复**：5 次失败锁 15 分钟；累计 10 次锁 24 小时并发邮件
```

如果 review 暴露 requirement.md 不完整 → **直接编辑 requirement.md** 补齐。

```bash
git add <feature-name>/
git commit -m "docs(prd): align <feature-name>"
git push
```

📣 通知技术做增量 review。**重复**直到没有 `[待对齐]`。

## 1.4 全部对齐 → 追加完成标记

确认所有 Q 都是 `[已对齐]` 后，在 ai-review.md **最末尾**追加：

```
[需求已完全对齐] 2026-05-04 产品确认人:@产品名 技术确认人:@技术名
```

push，并合并 PR 到 `main`。需求即可进入开发。

---

# 二、技术操作

## 2.0 首次准备（一次性）

```powershell
cd E:\luxi
git clone https://github.com/Luxi-Nebula/prd-repo.git
git clone <代码仓库地址> CineFlow
```

后续命令都在 `E:\luxi\CineFlow` 启动 Claude Code 执行。

## 阶段 A — AI Review

```bash
# 拉取产品需求
cd E:\luxi\prd-repo
git fetch && git checkout feature/<产品名>/<feature-name> && git pull
```

```
# 在代码仓库执行（首次/增量自动识别）
/ai-review E:\luxi\prd-repo\<feature-name>
```

打开 `ai_workflow/<feature>/ai-review.md` 自查质量；不满意直接告诉 Claude 改（"Q3 描述太模糊，重写"）。

```powershell
# 复制回 PRD + push（首轮）
Copy-Item ai_workflow\<feature-name>\ai-review.md `
          E:\luxi\prd-repo\<feature-name>\ai-review.md -Force

cd E:\luxi\prd-repo
git add <feature-name>/ai-review.md
git commit -m "docs(prd): ai-review for <feature-name>"
git push
```

📣 通知产品对齐。**重复**以下步骤直到所有 Q `[已对齐]` 且文末有 `[需求已完全对齐]`：

```bash
# 产品 push 对齐后，拉取最新 ai-review.md
cd E:\luxi\prd-repo && git pull
```

然后将更新后的 ai-review.md 重新复制到 CineFlow，再执行增量 `/ai-review`：

```
/ai-review E:\luxi\prd-repo\<feature-name>
```

## 阶段 B — 生成开发计划

```
/dev-plan E:\luxi\prd-repo\<feature-name>
```

校验通过后产出 `ai_workflow/<feature>/dev-plan.md`，含任务、优先级（P0/P1/P2）、工期、依赖、风险。

**Review dev-plan**：
- 任务粒度合理？P0 是否真的核心阻塞？
- 改动文件路径与现有代码结构匹配？
- 风险点是否回链 ai-review Q 编号？

不合理 → 让 Claude 调整。然后**填 Owner**。

## 阶段 C — 转飞书排期表

```
/gen-feishu-csv E:\luxi\CineFlow\ai_workflow\<feature-name>\dev-plan.md
```

输出 `dev-plan-feishu.csv`（UTF-8 BOM）。

**飞书操作**：
1. 多维表格 / 项目 → 新建 → 导入 CSV
2. 字段类型：「优先级」=单选、「工期(人日)」=数字、「Owner」=人员
3. 把飞书表格 URL 追加到 `dev-plan.md` 末尾的 `## 飞书排期` 段落
4. 复制 `dev-plan.md` 到 PRD 仓库方便产品看排期

## 阶段 D — 开发 + PR Review

按飞书排期推进，可让 Claude Code 写代码。PR 提交后**至少 1 人 review**：
- ✅ 与 requirement.md / ai-review.md 一致
- ✅ 边界场景已覆盖
- ✅ 类型完备无 `any`、无硬编码密钥

## 阶段 E — 测试

```
/gen-tests E:\luxi\prd-repo\<feature-name>
```

Claude 会读 PRD + dev-plan + 实现代码 → 生成 `test-cases.md` + vitest 代码 → 跑 `npm test` → **全过才标记完成**。

**失败处理**：
- 测试代码写错 → Claude 修测试
- 业务代码 bug → Claude 停止报告，**不会**自动改业务代码绕过；Owner 决定改代码还是回退需求

通过后：
```bash
git add ai_workflow/<feature-name>/test-cases.md tests/
git commit -m "test(<feature-name>): add test cases"
git push
```

## 阶段 F — 发布（人工把关，Claude 不介入）

```
feature/<name> → dev（测试环境冒烟）→ main（生产）
```

发布前必须：✅ `/gen-tests` 全过 ✅ Code review 通过 ✅ dev 环境冒烟通过

---

# 三、FAQ

**Q: ai-review.md 为什么要手动两端复制？不能自动同步？**
A: 避免误覆盖产品的编辑。手动让技术每次明确"现在把哪个版本盖到哪里"。

**Q: 产品改了 requirement 没通知，技术已跑 /dev-plan 怎么办？**
A: PRD `git pull` → 删 `ai_workflow/<feature>/dev-plan.md` → 重跑。

**Q: 某个 [已对齐] 落地时发现还是有歧义？**
A: **不要硬猜**。把那个 Q 改回 `[待对齐]` 补疑问，让产品再答一次。

**Q: feature 太大，dev-plan 拆出 20+ 任务？**
A: 拆子 feature（如 `user_login` 拆 `user_login_basic` / `user_login_oauth`），每个独立走完整流程。

**Q: 紧急 hotfix 也走这个流程吗？**
A: 不用。直接 `main → fix/xxx` 修复发布，完成后补 `requirement.md` 归档到 PRD。

**Q: requirement / UI 太大 token 消耗高？**
A: 单图 ≤200KB（TinyPNG）；requirement.md 用列表/表格代替段落（详见 PRD 仓库 README）；超 500 行强制拆子 feature。
