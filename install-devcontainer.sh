#!/bin/bash
# Prompt Logger Skill - DevContainer 安装脚本
# 用于在现有 DevContainer 项目中添加 Prompt Logger Skill
#
# 使用方法:
#   curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
#   chmod +x install-devcontainer.sh
#   ./install-devcontainer.sh /path/to/your/devcontainer/project

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查参数
PROJECT_DIR="${1:-.}"
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

info "安装 Prompt Logger Skill 到 DevContainer 项目: $PROJECT_DIR"

# 检查必要文件
DEVCONTAINER_DIR="$PROJECT_DIR/.devcontainer"
CLAUDE_DIR="$PROJECT_DIR/.claude"

if [ ! -d "$DEVCONTAINER_DIR" ]; then
    error "未找到 .devcontainer 目录: $DEVCONTAINER_DIR"
fi

if [ ! -f "$DEVCONTAINER_DIR/Dockerfile" ]; then
    error "未找到 Dockerfile: $DEVCONTAINER_DIR/Dockerfile"
fi

if [ ! -f "$DEVCONTAINER_DIR/devcontainer.json" ]; then
    error "未找到 devcontainer.json: $DEVCONTAINER_DIR/devcontainer.json"
fi

# 创建 .claude 目录（如果不存在）
mkdir -p "$CLAUDE_DIR"

# 备份原文件
info "备份原文件..."
cp "$DEVCONTAINER_DIR/Dockerfile" "$DEVCONTAINER_DIR/Dockerfile.bak"
cp "$DEVCONTAINER_DIR/devcontainer.json" "$DEVCONTAINER_DIR/devcontainer.json.bak"
[ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"

# ============================================
# 1. 修改 Dockerfile
# ============================================
info "修改 Dockerfile..."

# 检查是否已安装
if grep -q "Prompt Logger Skill" "$DEVCONTAINER_DIR/Dockerfile"; then
    warn "Dockerfile 中已包含 Prompt Logger Skill 安装，跳过"
else
    # 检测用户名（vscode 或 root）
    if grep -q "USER vscode" "$DEVCONTAINER_DIR/Dockerfile"; then
        CONTAINER_USER="vscode"
        CLAUDE_HOME="/home/vscode/.claude"
    else
        CONTAINER_USER="root"
        CLAUDE_HOME="/root/.claude"
    fi

    info "检测到容器用户: $CONTAINER_USER"

    # 创建安装代码块
    INSTALL_BLOCK="
# ==== Prompt Logger Skill インストール ====
USER $CONTAINER_USER
RUN curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz \\
    && tar -xzf prompt-logger-macos.tar.gz \\
    && cd prompt-logger-skill-package \\
    && mkdir -p $CLAUDE_HOME/hooks $CLAUDE_HOME/skills/prompt-logger \\
    && cp hooks/*.sh $CLAUDE_HOME/hooks/ \\
    && cp skills/prompt-logger/SKILL.md $CLAUDE_HOME/skills/prompt-logger/ \\
    && chmod +x $CLAUDE_HOME/hooks/*.sh \\
    && cd .. \\
    && rm -rf prompt-logger-skill-package prompt-logger-macos.tar.gz
"

    # 在 Dockerfile 末尾添加（在最后一个 USER 或 WORKDIR 之前）
    # 简单方案：直接追加到文件末尾
    echo "$INSTALL_BLOCK" >> "$DEVCONTAINER_DIR/Dockerfile"

    info "Dockerfile 已更新"
fi

# ============================================
# 2. 修改 devcontainer.json
# ============================================
info "修改 devcontainer.json..."

# 检查是否已有 containerEnv
if grep -q "CLAUDE_PROJECT_DIR" "$DEVCONTAINER_DIR/devcontainer.json"; then
    warn "devcontainer.json 中已包含 CLAUDE_PROJECT_DIR，跳过"
else
    # 使用 jq 添加 containerEnv（如果有 jq）
    if command -v jq &> /dev/null; then
        jq '. + {"containerEnv": {"CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"}}' \
            "$DEVCONTAINER_DIR/devcontainer.json" > "$DEVCONTAINER_DIR/devcontainer.json.tmp"
        mv "$DEVCONTAINER_DIR/devcontainer.json.tmp" "$DEVCONTAINER_DIR/devcontainer.json"
        info "devcontainer.json 已更新 (使用 jq)"
    else
        # 没有 jq，使用 sed 简单插入
        # 在第一个 { 后插入 containerEnv
        sed -i.tmp 's/^{$/{\n  "containerEnv": {\n    "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"\n  },/' \
            "$DEVCONTAINER_DIR/devcontainer.json"
        rm -f "$DEVCONTAINER_DIR/devcontainer.json.tmp"
        warn "devcontainer.json 已更新 (使用 sed，请检查格式)"
    fi
fi

# ============================================
# 3. 修改/创建 .claude/settings.json
# ============================================
info "配置 .claude/settings.json..."

# 检测用户名
if grep -q "USER vscode" "$DEVCONTAINER_DIR/Dockerfile"; then
    CLAUDE_HOME="/home/vscode/.claude"
else
    CLAUDE_HOME="/root/.claude"
fi

HOOKS_CONFIG='{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/session-start.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/log-prompt.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/log-response.sh"
          }
        ]
      }
    ]
  }
}'

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    # 检查是否已有 hooks
    if grep -q '"hooks"' "$CLAUDE_DIR/settings.json"; then
        warn "settings.json 中已包含 hooks 配置，跳过"
    else
        # 合并配置
        if command -v jq &> /dev/null; then
            jq -s '.[0] * .[1]' "$CLAUDE_DIR/settings.json" <(echo "$HOOKS_CONFIG") > "$CLAUDE_DIR/settings.json.tmp"
            mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
            info "settings.json 已合并 hooks 配置"
        else
            warn "未安装 jq，无法自动合并 settings.json"
            warn "请手动将 hooks 配置添加到 $CLAUDE_DIR/settings.json"
            echo "$HOOKS_CONFIG"
        fi
    fi
else
    # 创建新的 settings.json
    echo "$HOOKS_CONFIG" > "$CLAUDE_DIR/settings.json"
    info "已创建 settings.json"
fi

# ============================================
# 完成
# ============================================
echo ""
info "=========================================="
info "Prompt Logger Skill 安装完成！"
info "=========================================="
echo ""
info "下一步:"
info "  1. 在 VS Code 中按 F1"
info "  2. 选择 'Dev Containers: Rebuild Container'"
info "  3. 容器重建后，Claude Code 对话将自动记录到工作目录"
echo ""
info "备份文件位置:"
info "  - $DEVCONTAINER_DIR/Dockerfile.bak"
info "  - $DEVCONTAINER_DIR/devcontainer.json.bak"
[ -f "$CLAUDE_DIR/settings.json.bak" ] && info "  - $CLAUDE_DIR/settings.json.bak"
echo ""
