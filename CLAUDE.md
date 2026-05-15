# FlareFlow App · 仓库规则（精简）

本仓库**仅保留 FlareFlow App** 相关产品文档与历史需求资产。

## 协作助手总规则

**产品 / 需求协作助手**的完整工作方式（优先级 0～5、真理源先行、Skill 路由、子 Agent 策略、输出与冲突处理）见根目录 **`AGENTS.md`**。  
冲突时顺序：**用户当轮明确指令** > **`CLAUDE.md` + `AGENTS.md`** > **Skill 默认习惯**。

## 默认语言

中文为主；技术字段、文件名、代码可保留英文。

## 用户提需求时 · AI 强制顺序（门禁）

**默认流程**（除非用户在本轮对话里**明确说**可以跳过，例如「不用确认，直接写 PRD」）：

1. **先分析与决策草案**：用 **open-questions-triage**（必要时）+ **Demand Solution Decision** 产出：问题澄清、做/不做、优先级、范围边界、候选方案与推荐；可辅以 **spec-extractor** 从现有文档抽规格。  
2. **停下等你确认**：把决策要点用**短清单或表格**列给你，并**明确提问**（例如：是否同意推荐方案？范围是否包含 A/B？有无必须改的项？）。**在你给出显性确认之前**，不得进入完整 PRD 撰写。  
3. **确认后再写需求**：你回复已拍板（例如「按推荐方案写 PRD」「第 2 点改成…其余确认」）后，再启用 **prd-writer-master** 落盘 PRD；之后可用 **prd-test-validator** 做完整性校验。

**禁止**：在用户未确认决策前，**擅自**生成长篇 PRD 或写入 `docs/{YYYYMMDD}/PRD/...` 主文档（避免返工）。

**例外**：用户一句话指令已等价于确认（例如「就按你刚才表里写的，直接出 PRD」）或用户明确要求跳过确认。

## PRD · Markdown 与 HTML（本仓库约定）

- **真理源**：始终以 **`docs/{YYYYMMDD}/PRD/{需求名}/*_PRD.md`** 为准。  
- **未定稿阶段**：在 `.md` **尚未完全确认**（仍有开放问题、待 PM 拍板、分群/矩阵未填满等）时，**不创建、不更新** 同名的 **`_PRD.html`**。  
- **定稿后**：由 AI **提醒**你是否需要生成或更新 HTML；**每次**生成或重大更新 `.html` 前，须先获得你的**显性确认**（当轮回复「确认生成 HTML」或等价表述）。  
- **已定稿后的修改**：若你改需求涉及 PRD 事实变更，优先改 `.md`；是否同步改 `.html` 仍按上条 **每次确认**。  
- **改 `.md` 的许可（与 `AGENTS.md` §4 一致）**：无论当轮指令如何，须**先**列出拟改清单（文件、段落、准备删/改内容及改后效果），经用户**确认该清单**后，再取得 **「同意修改」「可以修改」**（或等价显性落盘许可）方可写入 `*_PRD.md`；**未确认准备修改的内容前不得改**需求文档。  
- **App PRD 正文写法**：通俗命名、标题、线框位置、服务端白话等见 **`prd-writer-master` →「FlareFlow App PRD 写作约定」**（适用于本仓全部 App `*_PRD.md`，非仅顺读版）。  
- **与通用 Skill 的关系**：若 `.claude/skills/prd-writer-master` 写「必须双产物」，在**本仓库**以本节为准。

## 原型 / mockup · 移动端规范（本仓库 · FlareFlow App）

本仓库需求对象为 **原生 iOS / Android 竖屏 App**，因此：

- **ASCII 线框、HTML mockup、评审用示意图**：默认按 **移动端设计规范** 呈现（竖屏优先、触控热区、安全区与刘海/底部手势区占位、系统状态栏/导航逻辑）；**禁止**默认使用桌面 Web 多栏布局，除非当期需求明确为 Web/H5。  
- **弹窗与线框**：PRD 若描述**弹窗、BottomSheet、多步同意/挽留**等 UI，须在**与需求逻辑同一节**内附 ASCII 线框，且 **线框写在逻辑之前**（主隐私弹窗 + 二次挽留等各有一框）；**禁止**只用文末单独「线框章」而与逻辑脱节。详见 **`prd-writer-master` →「FlareFlow App PRD 写作约定」**。  
- **授权 / 隐私首屏文案**：以**一屏可读**为原则（短标题 + 少量短句 + 政策链接 + 勾选 + **同意/不同意**等主操作）；**长类目与细则**放 **Privacy Policy / Terms 全文** 或次级页；与当期 PRD（如访客 **§3.0** 两弹窗体例）冲突时以 PRD 为准。  
- **画幅与视觉事实源**：与 **`flareflow-app-snapshot/KNOWLEDGE_BASE.md`** §1.1 对齐（逻辑 **390×844 pt**、Figma 当期 Page）；HTML 派生物须用 **手机机壳/单列宽度**，不得用宽屏桌面稿冒充 App 评审。  
- **横屏**：若某页支持横屏，须在 PRD 中单独说明布局与断点，不得静默按 PC 比例出图。

## 目录约定

| 路径 | 内容 |
|------|------|
| `flareflow-app-snapshot/` | 产品线知识库、历史 docx、抽取索引与维护脚本（见该目录 `README.md`） |
| `docs/{YYYYMMDD}/` | **按批次**落盘的新 PRD / 反馈等（当前示例：`docs/20260513/` 访客模式与游客身份） |
| `flareflow-app-snapshot/已上线功能/FF需求文档（App）/` | **历史版本** FF App 需求 docx + `_EXTRACTED_INDEX.md`（全文检索用） |

## 写新 PRD 时建议先读

1. `flareflow-app-snapshot/KNOWLEDGE_BASE.md` — 基线、历史索引、与现行 PRD 冲突说明  
2. `flareflow-app-snapshot/已上线功能/FF需求文档（App）/_EXTRACTED_INDEX.md` — 历史 docx 抽取速查  
3. 当期 `docs/{YYYYMMDD}/PRD/.../*.md` — **真理源**  
4. **历史交集**：与 **`AGENTS.md` §1「历史需求交叉检索」** 一致——新 PRD 须列**历史交集清单**并请你确认后，再把结论写入正文。

**冲突优先级**：当期 PRD `.md` > `KNOWLEDGE_BASE.md` 已写明的拍板 > 历史 docx 背景。

## 重建 FF 抽取索引

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File "flareflow-app-snapshot/tools/extract-archive-docx-index.ps1"
```

## 交付物红线

- PRD 等交付物**只写入本仓库**内上述路径，勿写到用户桌面或仓外（除非用户明确要求）。

---

## Cursor PM 工作流（五 Skill）

从模糊需求到可开发 PRD 的**推荐顺序**与每步产出说明见：

**[`docs/PM_WORKFLOW_CURSOR.md`](docs/PM_WORKFLOW_CURSOR.md)**

| Skill | 路径 |
|-------|------|
| open-questions-triage | `.claude/skills/open-questions-triage/SKILL.md` |
| Demand Solution Decision | `.claude/skills/Demand Solution Decision/SKILL.md` |
| spec-extractor | `.claude/skills/spec-extractor/SKILL.md` |
| prd-writer-master | `.claude/skills/prd-writer-master/SKILL.md`（**FlareFlow App PRD 写作约定** + 可选 **`_PRD_少跳转顺读版.md`**） |
| prd-test-validator | `.claude/skills/prd-test-validator/SKILL.md` |

### 扩展：superpowers-zh（编程 / 工程方法论 · 中文增强版）

- **来源**：本机仓库 `C:\Users\King\Downloads\需求skill\superpowers-zh`（上游说明见该目录 `README.md`）。  
- **本仓接入方式**：在仓库根目录执行 `powershell -ExecutionPolicy Bypass -File "scripts\link-superpowers-zh.ps1"`，会在 `.claude/skills/` 下为每个子技能创建 **目录联结**（不重拷文件）。联结列表见 **`.gitignore`** 中 `superpowers-zh` 段；换机或移动上游路径时，改 **`scripts/superpowers-zh.path`**（一行绝对路径，指向 `…\superpowers-zh\skills`）后重新执行脚本。  
- **入口技能**：`.claude/skills/using-superpowers/SKILL.md`（如何选用其它 superpowers 技能）。  
- **与 PM 五段工作流关系**：五 Skill 仍负责 **需求 / PRD**；superpowers-zh 侧重 **实现、调试、计划、Code Review、中文文档与 Git 规范** 等，按需 **Read** 对应 `SKILL.md` 即可（与 `AGENTS.md` 中「子 Agent 不滥用」原则一致）。

可选固定 Agent：`.claude/agents/demand-decision-agent.md`、`.claude/agents/prd-writer-agent.md`。
