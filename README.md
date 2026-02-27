# Prompt Logger Skill

**中文** | [日本語](./README_ja.md)

自动记录 Claude Code 对话（用户提示词 + Claude 响应）到项目目录的历史文件中。

## 特性

- 自动记录用户提示词和 Claude 响应
- 对话编号功能 (#1, #2, ...)
- 使用 emoji 区分用户 (👤) 和 Claude (🤖)
- 支持 macOS/Linux 和 Windows
- 支持 Docker/DevContainer
- 每个会话生成独立的日志文件

## 平台差异

| 平台 | 实现方式 | 生成文件 |
|------|---------|---------|
| macOS/Linux | Bash 脚本 | `claude_prompt-history-*.md` (含用户提示词 + Claude 响应) |
| Windows | PowerShell + Node.js | `claude_prompt-history-*.md` (用户提示词) |
| DevContainer | Bash 脚本 | 同 macOS/Linux |

## 安装

### 方式 1: Plugin 安装（推荐）

使用 Claude Code 的 Plugin 系统一键安装：

```bash
# 添加 marketplace
/plugin marketplace add hst-bridge/prompt-logger-skill

# 安装插件
/plugin install prompt-logger@ligl-plugins
```

### 方式 2: 本地安装 (macOS / Linux)

```bash
curl -LO https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz
tar -xzf prompt-logger-macos.tar.gz
cd prompt-logger-skill-package
./install.sh
```

### 方式 3: 本地安装 (Windows)

```powershell
# 下载并解压 prompt-logger-macos.tar.gz 后
.\install.ps1
```

**Windows 依赖:**
- PowerShell 5.0+ (系统自带)
- Node.js (用于导出完整对话)

### 方式 4: DevContainer 安装

#### 宿主机配置（推荐，永久生效）

**macOS / Linux:**
```bash
curl -LO https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
chmod +x install-devcontainer.sh
./install-devcontainer.sh /path/to/your/devcontainer/project
# 然后在 VS Code 中 Rebuild Container
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
.\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"
# 然后在 VS Code 中 Rebuild Container
```

#### 容器内安装（临时）

```bash
# 进入容器后执行
curl -fsSL https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash
```

#### 手动配置 devcontainer.json

```json
{
  "postCreateCommand": "curl -fsSL https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash",
  "containerEnv": {
    "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"
  }
}
```

## 日志格式示例

### macOS/Linux/DevContainer

```markdown
# Claude Code 对话历史记录

**会话启动时间**: 2026-01-19 17:00:00
**工作目录**: /Users/ligl/my-project

---

### 👤 用户 #1 (2026-01-19 17:00:15)

帮我写一个 Hello World 程序

### 🤖 Claude #1 (2026-01-19 17:00:30)

好的，这是一个简单的 Python Hello World 程序：
...
```

### Windows

```markdown
# Claude Code Test Log

---

## 2026-01-19 17:00:15

```
帮我写一个 Hello World 程序
```
```

## 生成的文件

| 文件 | 平台 | 说明 |
|------|------|------|
| `claude_prompt-history-YYYYMMDD_HHMMSS.md` | 全平台 | 对话历史记录 |
| `.claude_session_date` | 全平台 | 会话时间戳（隐藏文件） |
| `.claude_msg_counter` | macOS/Linux | 消息编号计数器（隐藏文件） |

## 依赖

| 环境 | 依赖 |
|------|------|
| macOS | `jq` (`brew install jq`) |
| Linux | `jq` (`apt install jq`) |
| Windows | PowerShell 5.0+ + Node.js |
| DevContainer | 自动安装 `jq` |

## 文件结构

```
prompt-logger-skill/
├── .claude-plugin/
│   ├── plugin.json              # Plugin 清单
│   └── marketplace.json         # Marketplace 清单
├── skills/
│   └── prompt-logger/
│       └── SKILL.md             # Skill 定义
├── hooks/
│   ├── session-start.sh         # 会话启动 (macOS/Linux)
│   ├── session-start.ps1        # 会话启动 (Windows)
│   ├── log-prompt.sh            # 记录提示词 (macOS/Linux)
│   ├── log-prompt.ps1           # 记录提示词 (Windows)
│   ├── log-response.sh          # 记录响应 (macOS/Linux)
│   └── auto-export.js           # 导出对话 (Windows)
├── install.sh                   # 本地安装 (macOS/Linux)
├── install.ps1                  # 本地安装 (Windows)
├── install-devcontainer.sh      # DevContainer 配置 (macOS/Linux)
├── install-devcontainer.ps1     # DevContainer 配置 (Windows)
├── install-in-container.sh      # 容器内安装
└── docker/                      # Docker/DevContainer 参考配置
```

## 卸载

### Plugin 卸载

```bash
/plugin uninstall prompt-logger
```

### 本地卸载 (macOS / Linux)

```bash
rm -rf ~/.claude/skills/prompt-logger
rm ~/.claude/hooks/session-start.sh
rm ~/.claude/hooks/log-prompt.sh
rm ~/.claude/hooks/log-response.sh
# 手动编辑 ~/.claude/settings.json 移除 hooks 配置
```

### 本地卸载 (Windows)

```powershell
Remove-Item -Recurse "$env:USERPROFILE\.claude\skills\prompt-logger"
Remove-Item "$env:USERPROFILE\.claude\hooks\session-start.ps1"
Remove-Item "$env:USERPROFILE\.claude\hooks\log-prompt.ps1"
Remove-Item "$env:USERPROFILE\.claude\hooks\auto-export.js"
# 手动编辑 settings.json 移除 hooks 配置
```

### DevContainer 卸载

从 `devcontainer.json` 中移除 `postCreateCommand` 和 `containerEnv.CLAUDE_PROJECT_DIR`。

## License

MIT
