# scripts/ 目录使用说明

本目录存放跨需求复用的本地工具脚本，**仅本机执行**，不参与任何线上流程。

| 脚本 | 用途 | 状态 |
|---|---|---|
| `sync-to-prd-repo.sh` | 把对外可分享的 PRD / 决策 / ai-review / 反馈同步到 GitHub `Luxi-Nebula/prd-repo` | ✅ 日常使用 |
| `sync-to-pm-workflow.sh` | 把 PM 工具包同步到 GitHub `kevinford11/pm-workflow`（其他 PM 复用） | ✅ 日常使用 |
| `autoflow-pull.sh` | 拉 autoflow 主仓最新代码（产品总监 / PM 同事读 autoflow 代码做决策时确保最新）| ✅ 一次性配置后自动运行 |
| `install-autoflow-autopull.sh` | **一键安装** autoflow 自动 pull 系统（macOS launchd 每天 9/13/18 三次触发）| ✅ 首次使用跑一次 |

---

## sync-to-prd-repo.sh — 同步对外内容到 prd-repo（v3 按批次）

### 用途

把 `docs/{YYYYMMDD}/` 批次目录 + `docs/workflow-guide.md` + `docs/confirmed-decisions.md` 1:1 镜像同步到 staging 后 push 到 GitHub `Luxi-Nebula/prd-repo`。给研发 / 设计师 / 跨团队同事看需求。

### ⚠️ 默认行为（2026-05-12 起）

**默认 commit 后停，不自动 push** — 避免误推 demo / 测试内容到云端。需要 push 必须显式加 `--push` flag 或本地手动 push。

### 用法

```bash
# 1. 标准流程：sync（commit 后停在 staging，不 push）
bash scripts/sync-to-prd-repo.sh --batch 20260508 -m "feat: ..."

# 2. 审查 commit 内容
cd ~/prd-repo-staging
git show HEAD --stat
open ~/prd-repo-staging/20260508/  # 浏览器看实际文件

# 3. 审查 OK → 推送
cd ~/prd-repo-staging && git push origin main

# 4. 审查不 OK → 撤回
cd ~/prd-repo-staging && git reset --soft HEAD^   # 保留改动，回到 staging 未 commit 态
# 改完后重新跑 sync 产生新 commit
```

**或一步到位（仅用户已经审查过的情况）**：
```bash
# 显式 --push 一步推送（绕过审查步骤）
bash scripts/sync-to-prd-repo.sh --batch 20260508 --push -m "feat: ..."
```

**其他 flag**：
```bash
# Dry run：只看变化，rsync 加 -n 真不改 staging
bash scripts/sync-to-prd-repo.sh --batch 20260508 --dry-run

# --no-push 等同默认行为（保留向后兼容）
bash scripts/sync-to-prd-repo.sh --batch 20260508 --no-push
```

### 同步什么 / 不同步什么

| 类型 | 文件 / 路径 | 说明 |
|---|---|---|
| ✅ 1:1 镜像 | `docs/{batch}/` → staging `{batch}/` | 含 PRD `.md`+`.html` 双产物 / decision-making / ai-review / feedback / release-redline / README.md。PM 工作稿"产品答复草稿"自动排除 |
| ✅ 同步 | `docs/workflow-guide.md` | 产研协作 SOP |
| ✅ 同步（清理后）| `docs/confirmed-decisions.md` | 自动删决策 #3 限流告警章节（已转交另一位 PM）|
| ❌ 不同步 | `docs/团队工作流程.md` / `docs/decision-priority-queue.md` / `docs/autoflow-snapshot/` | PM 内部跨批次工具 |
| ❌ 不同步 | `CLAUDE.md` | 含产品总监个人工作流 |
| ❌ 不同步 | `scripts/` / `.claude/` | 工具脚本 + 个人 AI 配置 |
| ❌ 自动排除 | `*产品答复草稿*` / `.DS_Store` | PM 工作稿 + macOS 系统文件 |

### 安全核验

脚本同步完会自动核验：xlsx 仅允许在 `{batch}/feedback/` 下；旧结构残留路径（`docs/prd/AutoFlow/*` 等）会阻塞 push。

### staging 目录

脚本默认用 `~/prd-repo-staging/` 作为本地 staging。这是首次推送时手动 init 好的 git 仓，与 GitHub `Luxi-Nebula/prd-repo` 同步。

staging 内的 `README.md` / `AI_GUIDE.md` 是 staging 自有的（不在 product 仓内）—— 脚本**不会动这 2 个文件**。如要更新（如增新批次时改 README 的"当前批次"表），手动改 staging 内的对应文件即可。

### 常见问题

**Q: 第一次推送怎么办？**
A: 首次需手动在 GitHub 创空仓 `Luxi-Nebula/prd-repo`，然后 `cd ~/prd-repo-staging && git init && git remote add origin ...` 后再跑本脚本。

**Q: dry-run 时报"无变化"但我明明改了？**
A: dry-run 用 `rsync -n` 不真改 staging，所以 staging 没有新文件，自然 "无变化"——这是正常行为。

---

## sync-to-pm-workflow.sh — 同步 PM 工具包到 pm-workflow

### 用途

把 PM AI 工具包（`CLAUDE.md` / `.claude/agents` + `skills` / `scripts` / `docs/团队工作流程.md` / `docs/decision-priority-queue.md` / `docs/autoflow-snapshot/`）同步到 GitHub `kevinford11/pm-workflow`，给组内其他 PM 复用。

### 用法

```bash
bash scripts/sync-to-pm-workflow.sh                  # 默认 commit 后停（不 push）
bash scripts/sync-to-pm-workflow.sh --push           # 显式 push（已审查过）
bash scripts/sync-to-pm-workflow.sh --dry-run        # 只看变化
bash scripts/sync-to-pm-workflow.sh --no-push        # commit 但不 push（等同默认）
bash scripts/sync-to-pm-workflow.sh -m "update: ..."  # 自定义 commit message
```

### 同步什么 / 不同步什么

| 类型 | 文件 / 路径 | 说明 |
|---|---|---|
| ✅ 同步 | `CLAUDE.md` | AI 助手项目总规则 |
| ✅ 同步 | `docs/团队工作流程.md` → `团队工作流程.md` | 团队 SOP |
| ✅ 同步 | `docs/decision-priority-queue.md` → `decision-priority-queue.md` | 待决策队列 |
| ✅ 同步 | `docs/autoflow-snapshot/` → `autoflow-snapshot/` | PM 视角 autoflow 现状速查 |
| ✅ 同步 | `.claude/agents/` | demand-decision + prd-writer agent |
| ✅ 同步 | `.claude/skills/` | 3 个 PM skill |
| ✅ 同步 | `scripts/` | sync 脚本（排除本脚本自身防递归 + feishu_fetch.py 已删）|
| ❌ 不同步 | `docs/{YYYYMMDD}/` | 批次需求内容（应去 prd-repo 研发协作仓）|
| ❌ 不同步 | `docs/confirmed-decisions.md` | 项目级真理源（不属于 PM 工具包）|
| ❌ 不同步 | `docs/workflow-guide.md` | 产研协作 SOP（同上）|
| ❌ 自动排除 | `settings.local.json` / `.DS_Store` | PM 个人配置 + macOS 系统文件 |

### staging 目录

脚本默认用 `~/pm-workflow-staging/` 作为本地 staging，与 GitHub `kevinford11/pm-workflow` 同步。

staging 内的 `README.md` 由 staging 仓自维护，脚本**不会动它**。

---

## install-autoflow-autopull.sh — 一键安装 autoflow 自动 pull 系统（仅 macOS）

### 用途

产品总监 / PM 同事写 PRD / 决策时经常要读 autoflow 主仓代码核验事实（globals.css 色值 / 数据库 schema / 接口现状）。本脚本一次性安装 macOS launchd 定时任务，**每天 09:00 / 13:00 / 18:00 三次自动 pull autoflow 最新代码**，避免手动 pull 遗忘导致基于过时代码做决策。

### 首次使用（5 秒搞定）

```bash
# 1. 跑一次安装脚本（交互式询问 autoflow 路径）
bash scripts/install-autoflow-autopull.sh

# 脚本会自动：
# - 自动检测常见 autoflow 路径（~/autoflow / ~/code/autoflow 等）
# - 让用户确认或手动输入路径
# - 复制 autoflow-pull.sh 到 ~/bin/
# - 生成 ~/Library/LaunchAgents/com.{username}.autoflow-pull.plist
# - 加载 launchd 任务
# - 立即测试跑一次

# 2. 看测试结果
tail -15 ~/.autoflow-pull.log
```

### 自动触发时间

| 时间 | 场景 |
|---|---|
| **09:00** | 开工前最新 — 早上写 PRD / 决策时已是最新代码 |
| **13:00** | 午饭后 — 上午研发的新提交已同步 |
| **18:00** | 下班前 — 下午研发的新提交已同步 |

### 安全机制

- **不会覆盖本地未 commit 改动**：autoflow 本地有 modified 文件时跳过 pull
- **失败静默**：拉取失败只写日志不弹窗
- **错过时段不补跑**：关机时段错过的不会一次性触发多次

### 手动触发 / 取消

```bash
# 立即手动跑一次
bash ~/bin/autoflow-pull.sh

# 看日志
tail -15 ~/.autoflow-pull.log

# 卸载（取消自动 pull）
launchctl unload ~/Library/LaunchAgents/com.$(whoami).autoflow-pull.plist
rm ~/Library/LaunchAgents/com.$(whoami).autoflow-pull.plist
rm ~/bin/autoflow-pull.sh
```

### Linux / Windows 用户

本脚本仅支持 macOS（依赖 launchd）。Linux 用户用 cron / systemd timer 替代；Windows 用任务计划程序替代——核心逻辑 `autoflow-pull.sh` 跨平台可用。
