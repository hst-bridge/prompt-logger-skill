# Prompt Logger Skill

自动记录 Claude Code 对话（用户提示词 + Claude 响应）到项目目录的历史文件中。

## 特性

- 自动记录用户提示词和 Claude 响应
- 对话编号功能 (#1, #2, ...)
- 使用 emoji 区分用户 (👤) 和 Claude (🤖)
- 支持 macOS/Linux 和 Windows
- 支持 Docker/DevContainer
- 每个会话生成独立的日志文件

## 安装

### 本地安装 (macOS / Linux)

```bash
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz
tar -xzf prompt-logger-macos.tar.gz
cd prompt-logger-skill-package
./install.sh
```

### 本地安装 (Windows)

```powershell
# 下载并解压 prompt-logger-macos.tar.gz 后
.\install.ps1
```

### DevContainer 安装

#### 方式 1: 宿主机配置（推荐，永久生效）

**macOS / Linux:**
```bash
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
chmod +x install-devcontainer.sh
./install-devcontainer.sh /path/to/your/devcontainer/project
# 然后在 VS Code 中 Rebuild Container
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
.\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"
# 然后在 VS Code 中 Rebuild Container
```

脚本会自动在 `devcontainer.json` 中添加：
- `postCreateCommand`: 容器创建时自动安装
- `containerEnv.CLAUDE_PROJECT_DIR`: 日志输出目录

#### 方式 2: 容器内安装（临时）

```bash
# 进入容器后执行
curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash
```

#### 方式 3: 手动配置 devcontainer.json

```json
{
  "postCreateCommand": "curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash",
  "containerEnv": {
    "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"
  }
}
```

## 日志格式示例

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

---

### 👤 用户 #2 (2026-01-19 17:01:00)

改成 JavaScript 版本

### 🤖 Claude #2 (2026-01-19 17:01:15)

好的，这是 JavaScript 版本：
...
```

## 生成的文件

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-YYYYMMDD_HHMMSS.md` | 对话历史记录 |
| `.claude_session_date` | 会话时间戳（隐藏文件） |
| `.claude_msg_counter` | 消息编号计数器（隐藏文件） |

## 依赖

| 环境 | 依赖 |
|------|------|
| macOS | `jq` (`brew install jq`) |
| Linux | `jq` (`apt install jq`) |
| Windows | PowerShell 5.0+ (系统自带) |
| DevContainer | 自动安装 `jq` |

## 文件结构

```
prompt-logger-skill/
├── install.sh                   # 本地安装 (macOS/Linux)
├── install.ps1                  # 本地安装 (Windows)
├── install-devcontainer.sh      # DevContainer 配置 (macOS/Linux 宿主机)
├── install-devcontainer.ps1     # DevContainer 配置 (Windows 宿主机)
├── install-in-container.sh      # 容器内安装
├── hooks/
│   ├── session-start.sh         # 会话启动
│   ├── log-prompt.sh            # 记录提示词
│   └── log-response.sh          # 记录响应
├── skills/
│   └── prompt-logger/
│       └── SKILL.md             # Skill 定义
└── docker/                      # Docker/DevContainer 参考配置
```

## 卸载

### macOS / Linux

```bash
rm -rf ~/.claude/skills/prompt-logger
rm ~/.claude/hooks/session-start.sh
rm ~/.claude/hooks/log-prompt.sh
rm ~/.claude/hooks/log-response.sh
# 手动编辑 ~/.claude/settings.json 移除 hooks 配置
```

### Windows

```powershell
Remove-Item -Recurse "$env:USERPROFILE\.claude\skills\prompt-logger"
Remove-Item "$env:USERPROFILE\.claude\hooks\session-start.ps1"
Remove-Item "$env:USERPROFILE\.claude\hooks\log-prompt.ps1"
# 手动编辑 settings.json 移除 hooks 配置
```

### DevContainer

从 `devcontainer.json` 中移除 `postCreateCommand` 和 `containerEnv.CLAUDE_PROJECT_DIR`。

## License

MIT
