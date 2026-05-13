# pm-workflow — 产品经理 AI 工作流复用包

> **Remote：** `ff-app-prd`（GitHub）。含 FlareFlow 等产品 PRD 批次（`docs/`）与本 PM 工作流模板（`.claude/`、`scripts/` 等）。

> 这是产品总监维护的"PM AI 工作流共享仓"，给组内其他产品经理用。
>
> 拿到本仓库的内容（agents + skills + SOP + 工具脚本）接到你自己的工作仓后，**你的 Claude Code 立刻按同一套规则工作**——同样的决策流程、同样的 PRD 写作风格、同样的研发对齐协议。
>
> 总监每次更新这套配置（agent 升级 / SOP 调整 / sync 脚本演进），通过自动同步推到这里。**你 `git pull` 就拿到最新版**。

---

## 仓库结构

```
pm-workflow/
├── README.md                          ← 你正在读的这一份（入门指南）
├── CLAUDE.md                          AI 助手项目总规则（落盘路径 / 命名约定 / 输出格式）
├── 团队工作流程.md                     团队 SOP（产品经理日常 / 6 岗位配合 / 跨平台操作手册）
├── decision-priority-queue.md         待决策优先队列（每期反馈进来后归类的台账模板）
│
├── .claude/
│   ├── agents/
│   │   ├── demand-decision-agent.md   反馈分析 + 三轮决策 agent
│   │   └── prd-writer-agent.md        PRD 编写 agent
│   └── skills/
│       ├── Demand Solution Decision/  反馈→决策的方案对比 skill
│       ├── open-questions-triage/     OPEN_QUESTIONS 批量答疑 skill
│       └── prd-writer-master/         PRD 写作大师 skill（含 36KB 详细 SOP + 模板）
│
└── scripts/
    ├── README.md                      脚本说明
    └── sync-to-prd-repo.sh            把你的需求批次同步到 prd-repo（让研发拉取）
```

---

## 怎么开始用（5 分钟上手）

### 第一步：clone 本仓库

```bash
cd ~/  # 或你想放的位置
git clone https://github.com/kevinford11/pm-workflow.git
```

### 第二步：建你自己的 product 工作仓

参考总监的 `product` 仓结构（按批次目录组织，详见 `CLAUDE.md`），**在你自己的本地路径**建一个 git 仓：

```bash
mkdir -p ~/my-product-repo/docs ~/my-product-repo/scripts ~/my-product-repo/.claude
cd ~/my-product-repo
git init
```

### 第三步：把本仓库内容拷进你的 product 仓

```bash
cd ~/pm-workflow/

# 拷 AI 配置（agents + skills）—— 这是核心
cp -r .claude/agents ~/my-product-repo/.claude/
cp -r .claude/skills ~/my-product-repo/.claude/

# 拷脚本
cp -r scripts/ ~/my-product-repo/

# 拷 PM 核心文档
cp CLAUDE.md ~/my-product-repo/
cp 团队工作流程.md ~/my-product-repo/docs/
cp decision-priority-queue.md ~/my-product-repo/docs/
```

### 第四步：装 Claude Code（如果还没装）

参考官方文档：https://docs.claude.com/claude-code

### 第五步：打开你的 product 仓启动 Claude

```bash
cd ~/my-product-repo/
claude  # 或者用你习惯的方式启动 Claude Code
```

Claude 会自动加载 `CLAUDE.md`（项目总规则）+ `.claude/agents/`（agent 定义）+ `.claude/skills/`（skill 定义）。

### 第六步：试跑一次

对话："收到本期反馈表 ~/my-feedback.xlsx，帮我做决策"

Claude 应该自动调用 `demand-decision-agent`，按 SOP 三轮决策，把决策汇总落到 `docs/{今天日期}/decision-making/_汇总/`。

---

## 修改前必读：这些是产品总监本人的配置，你要改的地方

### 1. `scripts/sync-to-prd-repo.sh` 里的硬编码路径

打开看顶部：

```bash
PRODUCT_DIR="/Applications/我的电脑/AI /product"   # ← 这是总监本人的路径，改成你自己的
STAGING_DIR="$HOME/prd-repo-staging"               # ← 这是 staging 路径，可保留也可改
```

**改成你自己的 product 仓绝对路径**。

### 2. staging 仓首次推送到 prd-repo

如果你也想把自己的需求批次推到 `Luxi-Nebula/prd-repo`（让研发拉到统一仓库），首次需要 init 你自己的 staging：

```bash
mkdir -p ~/prd-repo-staging && cd ~/prd-repo-staging
git init && git remote add origin https://github.com/Luxi-Nebula/prd-repo.git
git fetch origin && git checkout -b main origin/main
# 之后就能跑 sync 脚本了
```

---

## 核心约定（产品总监 v3 工作流，2026-05-08）

> 进 `CLAUDE.md` + `团队工作流程.md` 看完整版；这里是速查。

### 目录组织：按批次日期，不按需求名

✅ `docs/{YYYYMMDD}/PRD/{需求名}/{需求}_PRD.md` + `.html`（双产物 — md AI 读 / html 人类读）
✅ `docs/{YYYYMMDD}/decision-making/{需求名}/...md`
✅ `docs/{YYYYMMDD}/ai-review/...md`
✅ `docs/{YYYYMMDD}/feedback/{反馈文件名}`
✅ `docs/{YYYYMMDD}/release-redline/上线红线.md`

❌ 不要再用 `docs/prd/{项目}/{需求}/`（v3 之前的旧结构，已废弃）

**同一批次后续更新**：覆盖该日期目录，**不**新建版本号子目录、**不**改日期。

### PM 工作边界：你只交付决策 + PRD 双产物 + ai-review 对齐

❌ 不做版本规划（已转交研发）
❌ 不维护排期表（已转交研发）
❌ 不追踪研发进度（看研发的项目管理工具）

### 用户反馈：每期 1 份汇总文档

✅ 收到反馈表（xlsx / md / 飞书 / 截图）→ 直接给 Claude 路径或 URL
✅ Claude 把反馈拷到 `docs/{YYYYMMDD}/feedback/`
✅ 三轮决策 → `docs/{YYYYMMDD}/decision-making/_汇总/{YYYYMMDD}_需求决策汇总.md`

❌ 不再按条粘贴单条反馈（旧 `_inbox/` 流程已废弃）

### 同步给研发：`bash scripts/sync-to-prd-repo.sh --batch YYYYMMDD`

一行命令把本批次内容推到 `Luxi-Nebula/prd-repo`。研发拉一个目录拿全套（PRD `.md` + `.html` 双产物 / ai-review / feedback / decision-making / release-redline）。

---

## 你的 AI 怎么"像总监的 AI 那样默契"

**不能直接复制的**：
- 总监本人的 `user memory`（在 `~/.claude/projects/` 下的私有文件）—— 这些是总监跟自己 AI 长期沉淀的"用户偏好 / 历史决策记录"，**不在本仓库**也不应该传。
- 你跟 AI 的 sense 是逐渐养出来的，第一周可能没那么默契。

**能直接复制的（已经在这个仓库里）**：
- 完整的 agents / skills 行为定义
- 完整的 PM SOP（CLAUDE.md + 团队工作流程.md）
- 工具脚本（飞书拉文档 + 同步研发）

**建议**：
1. 第一周按 SOP 严格走，让 AI 习惯你的项目风格
2. 你跟 AI 对话时**遇到反复纠正的点**（如"不要建配套文件"），跟 AI 说"以后记住这个"，让它沉淀到你自己的 user memory
3. 你的项目特殊约定（行业术语 / vendor 名 / 内部代号），明确告诉 AI 一次让它记住
4. 1-2 周后你的 AI 应该就能"像总监的 AI 一样"了

---

## 反馈与共建

**发现问题或想加功能**：
- SOP 描述不清 / 跟实际不符 → 在团队群里 @产品总监
- 某个 agent / skill 应该改 → 提建议，总监统一改后下个版本同步过来
- 自己有更好的工作流想加入 → 同上，总监评估后纳入

**不要在本仓库直接改内容**——下次总监同步会被覆盖。改建议永远走总监这一关，确保所有 PM 用同一套版本。

---

## 版本与更新

本仓库由产品总监的 `pm-workflow-staging` 自动同步推送。每次总监更新 PM 工作流 / agent / skill / 文档，下次推送后这个仓库就更新到最新。

你定期 `git pull` 就能拿到。
