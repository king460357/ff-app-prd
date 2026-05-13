#!/bin/bash
# ════════════════════════════════════════════════════════════════
# sync-to-prd-repo.sh  (v3 — 直接镜像批次目录)
# 把 product/docs/{YYYYMMDD}/ 镜像同步到 prd-repo 的 {YYYYMMDD}/
# 因为 product 仓 v3 重构后已按批次组织，sync 不再需要拼装多个目录
# ════════════════════════════════════════════════════════════════
#
# 用法：
#   bash scripts/sync-to-prd-repo.sh --batch 20260508
#   bash scripts/sync-to-prd-repo.sh --batch 20260508 --dry-run
#   bash scripts/sync-to-prd-repo.sh --batch 20260508 -m "update: 改了 X"
#
# 参数：
#   --batch YYYYMMDD       批次日期目录（必填，如 20260508）
#   --dry-run              只看变化，不 commit / push
#   --no-push              commit 但不 push（同 默认行为）
#   --push                 commit 后立即推送（2026-05-12 起需要显式声明，默认 commit 即停）
#   -m <message>           自定义 commit message
#
# 同步什么（product → staging 1:1 镜像）：
#   ✅ docs/{batch}/                              → staging/{batch}/
#                                                 （含 PRD .md+.html 双产物 / decision-making /
#                                                  ai-review / feedback / release-redline /
#                                                  README.md，PM 工作稿"产品答复草稿"自动排除）
#   ✅ docs/workflow-guide.md                     → staging/workflow-guide.md
#   ✅ docs/confirmed-decisions.md                → staging/confirmed-decisions.md（清理后）
#
# 注：PM 工具包（CLAUDE.md / 团队工作流程.md / .claude/agents/ + skills/ / scripts/）
# 不在本脚本同步范围——这些是 PM 个人内部工作流，会单独同步到独立 GitHub 仓
# （与本 prd-repo 研发协作仓分离）。本脚本只负责"产研对外协作"的内容。
#
# 不传什么：
#   ❌ docs/团队工作流程.md / autoflow-snapshot/  PM 内部
#   ❌ scripts/ / .claude/ / CLAUDE.md            工具与 AI 配置
#   ❌ {batch}/ai-review/产品答复草稿_*.md        PM 工作稿
#
# staging 自有不被脚本动：
#   ★ staging/README.md / AI_GUIDE.md             入口由 staging 仓自维护
# ════════════════════════════════════════════════════════════════

set -e

# ──────────────────────────────────────────────────
# 配置
# ──────────────────────────────────────────────────
PRODUCT_DIR="/Applications/我的电脑/AI /product"
STAGING_DIR="$HOME/prd-repo-staging"

# ──────────────────────────────────────────────────
# 解析参数
# ──────────────────────────────────────────────────
BATCH=""
COMMIT_MESSAGE=""
DRY_RUN=0
NO_PUSH=0
AUTO_PUSH=0  # 2026-05-12 起：默认 commit 后停，不自动 push；要 push 必须 --push

while [[ $# -gt 0 ]]; do
  case "$1" in
    --batch) BATCH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-push) NO_PUSH=1; shift ;;
    --push) AUTO_PUSH=1; shift ;;
    -m|--message) COMMIT_MESSAGE="$2"; shift 2 ;;
    -h|--help)
      grep "^#" "$0" | head -40
      exit 0
      ;;
    *) echo "❌ 未知参数：$1（用 --help 看用法）"; exit 1 ;;
  esac
done

# ──────────────────────────────────────────────────
# 0. 前置检查
# ──────────────────────────────────────────────────
echo "═══ 0. 前置检查 ═══"

if [ -z "$BATCH" ]; then
  echo "❌ 缺 --batch 参数（如 --batch 20260508）"
  exit 1
fi

if [[ ! "$BATCH" =~ ^[0-9]{8}$ ]]; then
  echo "❌ --batch 必须是 8 位数字日期（YYYYMMDD），收到：$BATCH"
  exit 1
fi

if [ ! -d "$PRODUCT_DIR/docs/$BATCH" ]; then
  echo "❌ product 仓没有 docs/$BATCH/ 目录"
  echo "   先在 product 仓里建好批次内容再 sync"
  exit 1
fi

if [ ! -d "$STAGING_DIR/.git" ]; then
  echo "❌ staging 不是 git 仓：$STAGING_DIR"
  exit 1
fi

cd "$STAGING_DIR"
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "未设置")
echo "✓ product 仓：$PRODUCT_DIR"
echo "✓ staging 仓：$STAGING_DIR"
echo "✓ 远程 URL：$REMOTE_URL"
echo "✓ 同步批次：docs/$BATCH/ → staging/$BATCH/"
echo ""

# ──────────────────────────────────────────────────
# 1. 镜像同步批次目录
# ──────────────────────────────────────────────────
# dry-run 模式下 rsync 加 -n（真的不改 staging，只统计差异）
RSYNC_FLAGS="-aq --delete"
[ "$DRY_RUN" -eq 1 ] && RSYNC_FLAGS="-aqn --delete"

echo "═══ 1. 镜像批次目录 ═══"
mkdir -p "$STAGING_DIR/$BATCH"
rsync $RSYNC_FLAGS \
  --exclude=".DS_Store" \
  --exclude="*产品答复草稿*" \
  "$PRODUCT_DIR/docs/$BATCH/" \
  "$STAGING_DIR/$BATCH/"
echo "✓ 已同步 $BATCH/（自动排除 .DS_Store + 产品答复草稿）"
echo ""

# ──────────────────────────────────────────────────
# 2. 同步根级文档（workflow-guide + confirmed-decisions）
# ──────────────────────────────────────────────────
echo "═══ 2. 同步根级文档 ═══"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "  (dry-run 跳过根级文档复制；真跑时会同步 workflow-guide.md / confirmed-decisions.md)"
else
  if [ -f "$PRODUCT_DIR/docs/workflow-guide.md" ]; then
    cp "$PRODUCT_DIR/docs/workflow-guide.md" "$STAGING_DIR/workflow-guide.md"
    echo "✓ workflow-guide.md"
  fi

  # confirmed-decisions（清理决策 #3 限流告警）
  SRC_CD="$PRODUCT_DIR/docs/confirmed-decisions.md"
  DST_CD="$STAGING_DIR/confirmed-decisions.md"
  if [ -f "$SRC_CD" ]; then
    cp "$SRC_CD" "$DST_CD"
    sed -i '' '/^| AutoFlow \/ 限流告警与/d' "$DST_CD"
    awk '
      /^## 决策记录 #3/ { in_section = 1; next }
      /^## 决策记录 #/ && in_section { in_section = 0 }
      !in_section { print }
    ' "$DST_CD" > "${DST_CD}.tmp" && mv "${DST_CD}.tmp" "$DST_CD"

    if grep -qE "决策记录 #3|限流告警与 AI 自动调度|限流告警与AI自动调度" "$DST_CD"; then
      echo "❌ 清理 confirmed-decisions.md 失败"
      exit 1
    fi
    echo "✓ confirmed-decisions.md（已清理决策 #3）"
  fi
fi
echo ""

# ──────────────────────────────────────────────────
# 3. 安全核验
# ──────────────────────────────────────────────────
echo "═══ 3. 安全核验 ═══"

FORBIDDEN_PATTERNS=(
  "团队工作流程.md"
  "*产品答复草稿*"
  "decision-priority-queue.md"
  "settings.local.json"
)
FORBIDDEN_PATHS=(
  "*/docs/prd/*"           # 旧结构残留
  "*/docs/ai-reviews/*"    # 旧结构残留
)

found_forbidden=0
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  hits=$(find "$STAGING_DIR" -name "$pattern" -not -path "*/.git/*" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "❌ 发现禁传文件（pattern: $pattern）:"
    echo "$hits"
    found_forbidden=1
  fi
done
for pattern in "${FORBIDDEN_PATHS[@]}"; do
  hits=$(find "$STAGING_DIR" -path "$pattern" -not -path "*/.git/*" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "❌ 发现禁传路径（旧结构残留？pattern: $pattern）:"
    echo "$hits"
    found_forbidden=1
  fi
done

# xlsx 仅允许在 {batch}/feedback/ 下；其他位置视为误传
xlsx_outside_feedback=$(find "$STAGING_DIR" -name "*.xlsx" -not -path "*/.git/*" -not -path "*/[0-9]*/feedback/*" 2>/dev/null)
if [ -n "$xlsx_outside_feedback" ]; then
  echo "❌ 发现 xlsx 在 {batch}/feedback/ 之外（误传？）:"
  echo "$xlsx_outside_feedback"
  found_forbidden=1
fi

if [ "$found_forbidden" -eq 1 ]; then
  echo ""
  echo "❌ 安全核验失败，停止同步"
  exit 1
fi
echo "✓ 无敏感 / 旧结构残留文件"
echo ""

# ──────────────────────────────────────────────────
# 4. PRD ↔ test 真静态校验（C 方案 - 阻塞 sync）
# ──────────────────────────────────────────────────
echo "═══ 4. PRD ↔ test 真校验 ═══"
if command -v node >/dev/null 2>&1; then
  # 在 staging 目录下跑校验（已镜像的 PRD）
  if node "$PRODUCT_DIR/scripts/validate-prd-test.js" "$STAGING_DIR/$BATCH"; then
    echo "✓ 真校验通过"
  else
    VAL_EXIT=$?
    if [ $VAL_EXIT -eq 1 ]; then
      echo ""
      echo "❌ 真校验失败（有错误） — 停止 sync"
      echo "   修复 PRD / test 后重试。或加 --skip-validate 跳过（不推荐）"
      [ "$1" != "--skip-validate" ] && [ "$2" != "--skip-validate" ] && [ "$3" != "--skip-validate" ] && [ "$4" != "--skip-validate" ] && exit 1
      echo "⚠️  --skip-validate 已指定，强制继续"
    elif [ $VAL_EXIT -eq 2 ]; then
      echo "⚠️  真校验通过但有警告（不阻塞 sync）"
    fi
  fi
else
  echo "⚠️  未安装 node，跳过真校验"
fi
echo ""

# ──────────────────────────────────────────────────
# 5. git add + 显示变化
# ──────────────────────────────────────────────────
echo "═══ 5. 检查变化 ═══"
cd "$STAGING_DIR"
git add -A

if git diff --cached --quiet; then
  echo "═══ ✅ 无变化，无需 commit / push ═══"
  exit 0
fi

echo "变化清单："
git diff --cached --stat | head -30

CHANGED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo ""
echo "（共 $CHANGED_COUNT 个文件有变化）"

# ──────────────────────────────────────────────────
# 6. dry-run
# ──────────────────────────────────────────────────
if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "═══ ✅ DRY RUN 完成（未 commit / push）═══"
  exit 0
fi

# ──────────────────────────────────────────────────
# 7. commit
# ──────────────────────────────────────────────────
echo "═══ 6. commit ═══"
if [ -z "$COMMIT_MESSAGE" ]; then
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
  COMMIT_MESSAGE="sync: $BATCH 批次更新（$CHANGED_COUNT 个文件，$TIMESTAMP）"
fi

git -c i18n.commitEncoding=UTF-8 commit -q -m "$COMMIT_MESSAGE"
git log --oneline -1

# ──────────────────────────────────────────────────
# 8. push（2026-05-12 改 — 默认 commit 完即停，不自动 push；要 push 用 --push 显式声明）
# ──────────────────────────────────────────────────
if [ "$NO_PUSH" -eq 1 ] || [ "$AUTO_PUSH" -ne 1 ]; then
  echo ""
  echo "═══ ✅ 已 commit 到 staging（未 push）═══"
  echo ""
  echo "📋 已 commit 的内容："
  cd "$STAGING_DIR" && git log -1 --format='   %h %s' && echo ""
  echo "🔍 你可以现在审查内容："
  echo "   cd $STAGING_DIR && git show HEAD --stat"
  echo "   open $STAGING_DIR/$BATCH/"
  echo ""
  echo "✅ 确认无误后跑 push："
  echo "   cd $STAGING_DIR && git push origin main"
  echo ""
  echo "或下次跑 sync 时加 --push 自动推送："
  echo "   bash scripts/sync-to-prd-repo.sh --batch $BATCH --push -m \"...\""
  exit 0
fi

echo "═══ 7. push 到 GitHub ═══"
GIT_TERMINAL_PROMPT=0 git push origin main 2>&1 || {
  echo ""
  echo "❌ push 失败。可能原因："
  echo "   1. macOS Keychain 没缓存有效 PAT —— 在终端跑 'cd $STAGING_DIR && git push origin main' 输 PAT"
  echo "   2. 网络问题 —— 稍后重试"
  echo "   3. 远程被强制更新过 —— 跑 'git pull --rebase' 后重试"
  echo ""
  echo "本地 commit 已保留，重跑本脚本或手动 push 即可"
  exit 1
}

echo ""
echo "✅ 同步完成"
echo "→ 访问：https://github.com/Luxi-Nebula/prd-repo/tree/main/$BATCH"
