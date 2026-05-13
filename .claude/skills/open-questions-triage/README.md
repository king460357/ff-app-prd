# open-questions-triage

产品总监批量看 OPEN_QUESTIONS.md 时的分诊 + 回答起草工具。

## 一句话说明

**输入**：当期需求目录的 `OPEN_QUESTIONS.md`
**输出**：分诊报告（按紧急度排序 + 类型聚合 + 基于 PRD 起草的回答候选 + FAQ 候选）
**目的**：把产品总监每天答疑时间从 30 分钟压缩到 5 分钟

## 何时触发

用户说以下任一情况：

- "看下 OPEN_QUESTIONS" / "今天的问题"
- "批量答疑" / "OPEN_QUESTIONS 分诊"
- "扫一下当期 Q&A" / "把问题整理成可批量回答的报告"

## 主要步骤

1. 扫 `docs/prd/{项目}/{需求}/OPEN_QUESTIONS.md`（可多项目并行）
2. 解析每条 Q 的字段（类型 / 角色 / 模块 / 阻塞标记）
3. 按紧急度排序（🔴 阻塞 > 业务判断 > 冲突 > 歧义 > 缺漏 > 已裁定）
4. 读 PRD / 决策上下文 / confirmed-decisions 起草回答候选
5. 识别 FAQ 候选（重复 ≥ 3 次的问题）
6. 输出分诊报告
7. 用户确认后批量回写 OPEN_QUESTIONS.md

## 与其他工具的关系

```
开发端 5 角色 AI 写 OPEN_QUESTIONS.md
        ↓
   open-questions-triage ← 本 skill（产品总监触发）
        ↓ 输出"分诊报告 + 回答候选"
        ↓
   产品总监确认 / 修改 / 否决
        ↓
   本 skill 批量回写 OPEN_QUESTIONS.md
        ↓
   重复 ≥ 3 次的问题 → 升级到 01_决策上下文.md 第 6 章 FAQ
```

## 强制规则

- 回答候选是**草稿**，等用户确认才写入；禁止自动覆盖
- 必须读 PRD / 决策上下文才起草，禁止凭直觉编答案
- 硬约束冲突必须显式标注，不能默认建议绕开
- 保留所有原始 Q 内容，只追加裁定

## 详细规则

见 [`SKILL.md`](SKILL.md)。

## 示例

见 [`examples.md`](examples.md)。
