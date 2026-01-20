# Postmortem: Windows PowerShell Working Directory is Null

## Basic Information

| Field | Content |
|-----|------|
| **ID** | PM-2026-002 |
| **Title** | PowerShell scripts fail to get working directory on Windows |
| **Severity** | High |
| **Discovery Date** | 2026-01-20 |
| **Fix Date** | 2026-01-20 |
| **Fix Commit** | 1e9c43c |
| **Impact Scope** | All Windows users - prompts not being logged |

## Problem Summary

PowerShell hook scripts failed to obtain the working directory, causing `$WorkDir` to be null. This resulted in `Join-Path` failing and prompts not being recorded to the log file.

## Timeline

| Time | Event |
|-----|------|
| 2026-01-20 13:55 | User reported prompts were not being recorded |
| 2026-01-20 13:56 | Started investigation |
| 2026-01-20 14:00 | Identified that `$WorkDir` was null |
| 2026-01-20 14:05 | Found root cause - `$env:CLAUDE_PROJECT_DIR` not set, `Get-Location` returns null in hook context |
| 2026-01-20 14:08 | Discovered Claude Code passes `cwd` in JSON input |
| 2026-01-20 14:10 | Fix deployed - use `cwd` from JSON input |

## Root Cause Analysis (RCA)

### Direct Cause

The scripts relied on `$env:CLAUDE_PROJECT_DIR` environment variable which is not set by Claude Code on Windows. The fallback `Get-Location` also returns null when PowerShell is invoked as a subprocess via stdin pipe.

### Root Cause

1. **Incorrect assumption**: The original code assumed Claude Code sets `CLAUDE_PROJECT_DIR` environment variable, but this is not the case.

2. **Missing JSON input parsing**: Claude Code actually passes the working directory via the `cwd` field in the JSON input to hooks, but the original scripts did not read this field in `session-start.ps1`.

3. **PowerShell context issue**: When PowerShell is invoked with `powershell -File script.ps1` and receives input via stdin pipe, `Get-Location` and `[System.IO.Directory]::GetCurrentDirectory()` may return null or empty string.

### Code Changes

**session-start.ps1** - Before:
```powershell
$WorkDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
```

**session-start.ps1** - After:
```powershell
# Read JSON input from stdin to get working directory
$input_text = [Console]::In.ReadToEnd()
$WorkDir = $null

try {
    $json = $input_text | ConvertFrom-Json
    if ($json.cwd) {
        $WorkDir = $json.cwd
    }
} catch {}

# Fallback methods if cwd not in JSON
if ([string]::IsNullOrEmpty($WorkDir)) {
    if ($env:CLAUDE_PROJECT_DIR) { $WorkDir = $env:CLAUDE_PROJECT_DIR }
    elseif ($PWD) { $WorkDir = $PWD.Path }
    # ... more fallbacks
}
```

**log-prompt.ps1** - Similar change:
```powershell
# Extract cwd from JSON input
$WorkDir = $data.cwd

# Fallback methods if cwd not in JSON
if ([string]::IsNullOrEmpty($WorkDir)) {
    # ... fallback chain
}
```

## Impact Assessment

### Impact Scope
- All Windows users using prompt-logger skill
- Session start hook failed to create `.claude_session_date` file
- Log prompt hook failed to create/append to log file

### Impact Severity
- **Complete failure**: No prompts were being logged on Windows
- Users had no visibility into their conversation history

## Lessons Learned

### What Went Well
- Debug output helped quickly identify the null `$WorkDir` issue
- Claude Code documentation confirmed the JSON input format with `cwd` field

### Areas for Improvement
- Should have tested on Windows environment before release
- Need better error handling and logging in hook scripts
- Should document the expected JSON input format from Claude Code

## Preventive Measures (Action Items)

| Priority | Measure | Owner | Due Date | Status |
|-------|------|-------|---------|------|
| P0 | Add `cwd` extraction from JSON input | - | 2026-01-20 | Done |
| P1 | Add fallback chain for working directory | - | 2026-01-20 | Done |
| P2 | Add Windows CI/CD testing | - | TBD | Pending |
| P2 | Document JSON input format in README | - | TBD | Pending |

## Detection Rules

### Code Patterns
```powershell
# Problematic pattern - relying only on environment variable
$WorkDir = if ($env:CLAUDE_PROJECT_DIR) { ... } else { Get-Location }

# Better pattern - read from JSON input first
$WorkDir = $data.cwd
if ([string]::IsNullOrEmpty($WorkDir)) { /* fallbacks */ }
```

### Detection Keywords
- `$env:CLAUDE_PROJECT_DIR`
- `Get-Location`
- `GetCurrentDirectory`

### Auto-detection Script
```powershell
# Check if hook scripts use cwd from JSON input
Select-String -Path "hooks/*.ps1" -Pattern '\$data\.cwd|\$json\.cwd' -Quiet
```

## Related Links

- Claude Code Hooks Documentation: JSON input includes `cwd` field
- Previous PM: PM-2026-001-cwd-vs-project-dir.md
