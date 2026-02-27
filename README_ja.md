# Prompt Logger Skill

[中文](./README.md) | **日本語**

Claude Code の会話（ユーザープロンプト + Claude の応答）をプロジェクトディレクトリの履歴ファイルに自動記録します。

## 特徴

- ユーザープロンプトと Claude の応答を自動記録
- 会話番号機能 (#1, #2, ...)
- 絵文字でユーザー (👤) と Claude (🤖) を区別
- macOS/Linux と Windows をサポート
- Docker/DevContainer をサポート
- セッションごとに独立したログファイルを生成

## プラットフォームの違い

| プラットフォーム | 実装方式 | 生成ファイル |
|------|---------|---------|
| macOS/Linux | Bash スクリプト | `claude_prompt-history-*.md`（ユーザープロンプト + Claude 応答） |
| Windows | PowerShell + Node.js | `claude_prompt-history-*.md`（ユーザープロンプト） |
| DevContainer | Bash スクリプト | macOS/Linux と同じ |

## インストール

### 方法 1: Plugin インストール（推奨）

Claude Code の Plugin システムでワンクリックインストール：

```bash
# marketplace を追加
/plugin marketplace add hst-bridge/prompt-logger-skill

# プラグインをインストール
/plugin install prompt-logger@ligl-plugins
```

### 方法 2: ローカルインストール (macOS / Linux)

```bash
curl -LO https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz
tar -xzf prompt-logger-macos.tar.gz
cd prompt-logger-skill-package
./install.sh
```

### 方法 3: ローカルインストール (Windows)

```powershell
# prompt-logger-macos.tar.gz をダウンロードして解凍後
.\install.ps1
```

**Windows の依存関係:**
- PowerShell 5.0+（システム標準搭載）
- Node.js（完全な会話のエクスポートに使用）

### 方法 4: DevContainer インストール

#### ホストマシン設定（推奨、永続的）

**macOS / Linux:**
```bash
curl -LO https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
chmod +x install-devcontainer.sh
./install-devcontainer.sh /path/to/your/devcontainer/project
# その後 VS Code で Rebuild Container
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
.\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"
# その後 VS Code で Rebuild Container
```

#### コンテナ内インストール（一時的）

```bash
# コンテナに入った後に実行
curl -fsSL https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash
```

#### devcontainer.json の手動設定

```json
{
  "postCreateCommand": "curl -fsSL https://github.com/hst-bridge/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash",
  "containerEnv": {
    "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"
  }
}
```

## ログ形式の例

### macOS/Linux/DevContainer

```markdown
# Claude Code 会話履歴

**セッション開始時刻**: 2026-01-19 17:00:00
**作業ディレクトリ**: /Users/ligl/my-project

---

### 👤 ユーザー #1 (2026-01-19 17:00:15)

Hello World プログラムを書いてください

### 🤖 Claude #1 (2026-01-19 17:00:30)

はい、シンプルな Python Hello World プログラムです：
...
```

### Windows

```markdown
# Claude Code Test Log

---

## 2026-01-19 17:00:15

```
Hello World プログラムを書いてください
```
```

## 生成されるファイル

| ファイル | プラットフォーム | 説明 |
|------|------|------|
| `claude_prompt-history-YYYYMMDD_HHMMSS.md` | 全プラットフォーム | 会話履歴 |
| `.claude_session_date` | 全プラットフォーム | セッションタイムスタンプ（隠しファイル） |
| `.claude_msg_counter` | macOS/Linux | メッセージ番号カウンター（隠しファイル） |

## 依存関係

| 環境 | 依存関係 |
|------|------|
| macOS | `jq` (`brew install jq`) |
| Linux | `jq` (`apt install jq`) |
| Windows | PowerShell 5.0+ + Node.js |
| DevContainer | `jq` を自動インストール |

## ファイル構成

```
prompt-logger-skill/
├── .claude-plugin/
│   ├── plugin.json              # Plugin マニフェスト
│   └── marketplace.json         # Marketplace マニフェスト
├── skills/
│   └── prompt-logger/
│       └── SKILL.md             # Skill 定義
├── hooks/
│   ├── session-start.sh         # セッション開始 (macOS/Linux)
│   ├── session-start.ps1        # セッション開始 (Windows)
│   ├── log-prompt.sh            # プロンプト記録 (macOS/Linux)
│   ├── log-prompt.ps1           # プロンプト記録 (Windows)
│   ├── log-response.sh          # 応答記録 (macOS/Linux)
│   └── auto-export.js           # 会話エクスポート (Windows)
├── install.sh                   # ローカルインストール (macOS/Linux)
├── install.ps1                  # ローカルインストール (Windows)
├── install-devcontainer.sh      # DevContainer 設定 (macOS/Linux)
├── install-devcontainer.ps1     # DevContainer 設定 (Windows)
├── install-in-container.sh      # コンテナ内インストール
└── docker/                      # Docker/DevContainer 参考設定
```

## アンインストール

### Plugin アンインストール

```bash
/plugin uninstall prompt-logger
```

### ローカルアンインストール (macOS / Linux)

```bash
rm -rf ~/.claude/skills/prompt-logger
rm ~/.claude/hooks/session-start.sh
rm ~/.claude/hooks/log-prompt.sh
rm ~/.claude/hooks/log-response.sh
# ~/.claude/settings.json から hooks 設定を手動で削除
```

### ローカルアンインストール (Windows)

```powershell
Remove-Item -Recurse "$env:USERPROFILE\.claude\skills\prompt-logger"
Remove-Item "$env:USERPROFILE\.claude\hooks\session-start.ps1"
Remove-Item "$env:USERPROFILE\.claude\hooks\log-prompt.ps1"
Remove-Item "$env:USERPROFILE\.claude\hooks\auto-export.js"
# settings.json から hooks 設定を手動で削除
```

### DevContainer アンインストール

`devcontainer.json` から `postCreateCommand` と `containerEnv.CLAUDE_PROJECT_DIR` を削除してください。

## License

MIT
