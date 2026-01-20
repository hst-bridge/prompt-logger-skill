# Prompt Logger Skill

自动记录 Claude Code 对话（用户提示词 + Claude 响应）到项目目录的历史文件中。

## 特性

- ✅ 自动记录用户提示词和 Claude 响应
- ✅ 对话编号功能 (#1, #2, ...)
- ✅ 使用 emoji 区分用户 (👤) 和 Claude (🤖)
- ✅ 支持 macOS/Linux 和 Windows
- ✅ 支持 Docker/DevContainer
- ✅ 每个会话生成独立的日志文件

## 快速安装

### macOS / Linux

```bash
# 下载
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz

# 解压并安装
tar -xzf prompt-logger-macos.tar.gz
./install.sh
```

### Windows (PowerShell)

```powershell
# 下载并解压后运行
.\install.ps1
```

### Docker/DevContainer

```bash
# 在现有 DevContainer 项目中安装
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
chmod +x install-devcontainer.sh
./install-devcontainer.sh /path/to/your/devcontainer/project
```

更多选项参考 [docker/README.md](docker/README.md)

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

## 文件结构

```
prompt-logger-skill/
├── install.sh                   # macOS/Linux 安装脚本
├── install.ps1                  # Windows 安装脚本
├── settings.json                # macOS/Linux Hook 配置
├── settings-windows.json        # Windows Hook 配置
├── hooks/
│   ├── session-start.sh         # 会话启动脚本
│   ├── session-start.ps1
│   ├── log-prompt.sh            # 提示词记录脚本
│   ├── log-prompt.ps1
│   └── log-response.sh          # 响应记录脚本
├── skills/
│   └── prompt-logger/
│       └── SKILL.md             # Skill 定义文件
├── docker/                      # Docker/DevContainer 支持
└── postmortem/                  # 问题记录和预防
```

## 手动安装

### macOS / Linux

```bash
# 1. 复制 Skill 定义
mkdir -p ~/.claude/skills/prompt-logger
cp skills/prompt-logger/SKILL.md ~/.claude/skills/prompt-logger/

# 2. 复制 Hook 脚本
mkdir -p ~/.claude/hooks
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 3. 配置 settings.json
cp settings.json ~/.claude/settings.json
# 如已有配置，需手动合并 hooks 部分
```

### Windows

```powershell
# 1. 复制 Skill 定义
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills\prompt-logger" -Force
Copy-Item "skills\prompt-logger\SKILL.md" "$env:USERPROFILE\.claude\skills\prompt-logger\"

# 2. 复制 Hook 脚本
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\hooks" -Force
Copy-Item "hooks\*.ps1" "$env:USERPROFILE\.claude\hooks\"

# 3. 配置 settings.json
# 参考 settings-windows.json 合并到 ~/.claude/settings.json
```

## 生成的文件

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-*.md` | 对话历史记录 |
| `.claude_session_date` | 会话时间戳 |
| `.claude_msg_counter` | 消息编号计数器 |

## 依赖

### macOS / Linux
- `jq` - JSON 解析工具
  ```bash
  # macOS
  brew install jq
  # Linux
  sudo apt install jq
  ```

### Windows
- PowerShell 5.0+ (Windows 10/11 自带)

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

## License

MIT
