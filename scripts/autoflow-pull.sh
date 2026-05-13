#!/bin/bash
# autoflow-pull.sh — 自动拉 autoflow 主仓最新代码
#
# 用法 1（手动）：bash scripts/autoflow-pull.sh
# 用法 2（自动调度）：由 launchd 定时任务调用（见 install-autoflow-autopull.sh）
#
# 配置：
# - 通过环境变量 AUTOFLOW_DIR 指定 autoflow 路径
# - 不指定时尝试常见路径自动检测
#
# 日志：~/.autoflow-pull.log（保留 ~200KB 自动截断）

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. 配置 autoflow 路径（环境变量优先，否则自动检测常见路径）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOFLOW_DIR="${AUTOFLOW_DIR:-}"

if [ -z "$AUTOFLOW_DIR" ]; then
  # 自动检测常见路径
  CANDIDATES=(
    "$HOME/autoflow"
    "$HOME/code/autoflow"
    "$HOME/projects/autoflow"
    "$HOME/workspace/autoflow"
    "/Applications/我的电脑/AI /autoflow"
  )
  for path in "${CANDIDATES[@]}"; do
    if [ -d "$path/.git" ]; then
      AUTOFLOW_DIR="$path"
      break
    fi
  done
fi

LOG="$HOME/.autoflow-pull.log"

# 限制日志大小（防膨胀）— 超 200KB 截断保留尾部 100KB
if [ -f "$LOG" ] && [ "$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)" -gt 204800 ]; then
  tail -c 102400 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

echo "" >> "$LOG"
echo "═══════════════════════════════════════════" >> "$LOG"
echo "▶ $(date '+%Y-%m-%d %H:%M:%S') autoflow auto-pull 触发" >> "$LOG"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. 核验目录
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -z "$AUTOFLOW_DIR" ] || [ ! -d "$AUTOFLOW_DIR/.git" ]; then
  echo "❌ autoflow 目录不存在或不是 git 仓" >> "$LOG"
  echo "   AUTOFLOW_DIR=$AUTOFLOW_DIR" >> "$LOG"
  echo "   → 请设置环境变量：export AUTOFLOW_DIR=/path/to/autoflow" >> "$LOG"
  exit 1
fi

cd "$AUTOFLOW_DIR" || { echo "❌ 无法 cd 到 $AUTOFLOW_DIR" >> "$LOG"; exit 1; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. 核验本地是否有未 commit 改动（autoflow 是 read-only 看代码用）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "⚠️ 本地有未 commit 改动 — 跳过 pull 防止覆盖你的在途修改" >> "$LOG"
  git status -sb >> "$LOG" 2>&1
  echo "→ 请用户手动处理后再重试" >> "$LOG"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. 拉最新
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>&1)
BEFORE=$(git rev-parse HEAD 2>&1)
git pull origin "$BRANCH" >> "$LOG" 2>&1
PULL_EXIT=$?
AFTER=$(git rev-parse HEAD 2>&1)

if [ "$PULL_EXIT" -ne 0 ]; then
  echo "❌ git pull 失败（exit=$PULL_EXIT）" >> "$LOG"
  exit "$PULL_EXIT"
fi

if [ "$BEFORE" = "$AFTER" ]; then
  echo "✅ 已是最新，无新 commit" >> "$LOG"
else
  COUNT=$(git rev-list "$BEFORE..$AFTER" --count 2>&1)
  echo "✅ 已更新 $COUNT 个 commit：${BEFORE:0:7} → ${AFTER:0:7}" >> "$LOG"
  echo "   最新 commit：$(git log -1 --format='%h %s' 2>&1)" >> "$LOG"
fi
