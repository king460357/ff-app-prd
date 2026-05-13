#!/bin/bash
# install-autoflow-autopull.sh — 一键安装 autoflow 自动 pull 系统（macOS launchd）
#
# 装完后每天 09:00 / 13:00 / 18:00 三次自动拉 autoflow 主仓最新代码
# 失败静默 + 写日志到 ~/.autoflow-pull.log
#
# 用法：bash scripts/install-autoflow-autopull.sh
#
# 卸载：见脚本尾部 "卸载方法" 注释

set -e

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "═══════════════════════════════════════════════════"
echo "  autoflow 自动 pull 系统 — 一键安装"
echo "═══════════════════════════════════════════════════"
echo ""

# 仅支持 macOS（launchd 是 macOS 原生）
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ 本脚本仅支持 macOS（依赖 launchd）"
  echo "   Linux 用户请用 cron / systemd 替代方案"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. 让用户确认 autoflow 本地路径
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "▶ 第 1 步：确认 autoflow 仓本地路径"
echo ""

# 尝试自动检测
CANDIDATES=(
  "$HOME/autoflow"
  "$HOME/code/autoflow"
  "$HOME/projects/autoflow"
  "$HOME/workspace/autoflow"
  "/Applications/我的电脑/AI /autoflow"
)

DETECTED=""
for path in "${CANDIDATES[@]}"; do
  if [ -d "$path/.git" ]; then
    DETECTED="$path"
    break
  fi
done

if [ -n "$DETECTED" ]; then
  echo "  自动检测到 autoflow 仓：$DETECTED"
  read -r -p "  使用此路径？[Y/n] " CONFIRM
  CONFIRM="${CONFIRM:-Y}"
  if [[ "$CONFIRM" =~ ^[Yy] ]]; then
    AUTOFLOW_DIR="$DETECTED"
  else
    read -r -p "  请输入 autoflow 本地路径： " AUTOFLOW_DIR
  fi
else
  echo "  未自动检测到 autoflow 仓"
  read -r -p "  请输入 autoflow 本地路径（如 ~/autoflow）： " AUTOFLOW_DIR
fi

# 展开 ~ / 变量
AUTOFLOW_DIR=$(eval echo "$AUTOFLOW_DIR")

# 核验
if [ ! -d "$AUTOFLOW_DIR/.git" ]; then
  echo "❌ $AUTOFLOW_DIR 不存在或不是 git 仓"
  echo "   请先 git clone autoflow 仓后重试"
  exit 1
fi

echo "  ✓ autoflow 仓：$AUTOFLOW_DIR"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. 复制 autoflow-pull.sh 到 ~/bin/
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "▶ 第 2 步：安装拉取脚本到 ~/bin/autoflow-pull.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/bin"
cp "$SCRIPT_DIR/autoflow-pull.sh" "$HOME/bin/autoflow-pull.sh"
chmod +x "$HOME/bin/autoflow-pull.sh"
echo "  ✓ $HOME/bin/autoflow-pull.sh"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. 生成 launchd plist
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "▶ 第 3 步：生成 launchd plist（每天 09:00 / 13:00 / 18:00 触发）"

PLIST_LABEL="com.$(whoami).autoflow-pull"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$PLIST_LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$HOME/bin/autoflow-pull.sh</string>
  </array>

  <!-- 注入 AUTOFLOW_DIR 环境变量 -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>AUTOFLOW_DIR</key>
    <string>$AUTOFLOW_DIR</string>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>

  <!-- 每天 09:00 / 13:00 / 18:00 三次触发 -->
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>13</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
  </array>

  <key>RunAtLoad</key>
  <false/>

  <key>StandardOutPath</key>
  <string>$HOME/.autoflow-pull.stdout</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.autoflow-pull.stderr</string>
</dict>
</plist>
EOF

echo "  ✓ $PLIST_PATH"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. 加载 launchd 任务
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "▶ 第 4 步：加载 launchd 任务"

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

if launchctl list | grep -q "$PLIST_LABEL"; then
  echo "  ✓ 已加载（$PLIST_LABEL）"
else
  echo "  ❌ 加载失败，请手动跑 launchctl load $PLIST_PATH"
  exit 1
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. 立即测试跑一次
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "▶ 第 5 步：立即测试跑一次"

AUTOFLOW_DIR="$AUTOFLOW_DIR" bash "$HOME/bin/autoflow-pull.sh"

echo "  ✓ 测试完成，看日志确认结果："
echo "    tail -15 ~/.autoflow-pull.log"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 完成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cat <<'EOF'
═══════════════════════════════════════════════════
✅ 安装完成！

⏰ 自动触发时间：
   - 09:00 开工前
   - 13:00 午饭后
   - 18:00 下班前

📋 验证方法：
   tail -15 ~/.autoflow-pull.log

🔧 手动触发一次：
   bash ~/bin/autoflow-pull.sh

🚫 卸载方法：
   launchctl unload ~/Library/LaunchAgents/com.$(whoami).autoflow-pull.plist
   rm ~/Library/LaunchAgents/com.$(whoami).autoflow-pull.plist
   rm ~/bin/autoflow-pull.sh
═══════════════════════════════════════════════════
EOF
