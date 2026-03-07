# AI 插件增强功能实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 clifm-pi-plugin 添加命令生成模式、智能上下文感知、改进的 UI 反馈和历史记录功能

**Architecture:** 在现有 bash 脚本基础上添加新功能模块，保持向后兼容。添加子命令解析、智能模式检测、彩色输出和历史记录功能。

**Tech Stack:** Bash, gum, pi (RPC 模式), jq

---

## 概述

本计划基于对 [zsh-github-copilot](https://github.com/loiccoyle/zsh-github-copilot) 项目的研究，借鉴其直接操作命令行缓冲区、优雅的 spinner 动画和智能上下文感知等特性。

**参考实现：**
- Spinner: 使用 `spin='⣾⣽⣻⢿⡿⣟⣯⣷'` 替代当前简单的 `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`
- 彩色输出: 使用 tput setaf 实现错误/成功/警告提示
- 依赖检查: 带彩色提示的优雅检查

---

## Task 1: 添加彩色输出辅助函数

**Files:**
- Modify: `ai:1-20`

**Step 1: 在脚本开头添加彩色输出函数**

在 `#!/opt/homebrew/bin/bash` 后添加：

```bash
# Color codes using tput (fallback to empty if not available)
if type tput >/dev/null 2>&1; then
    RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
else
    RESET=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
fi

# Colored output functions
print_error() { printf "%s%s%s\n" "$RED" "$@" "$RESET" >&2; }
print_success() { printf "%s%s%s\n" "$GREEN" "$@" "$RESET"; }
print_warning() { printf "%s%s%s\n" "$YELLOW" "$@" "$RESET"; }
print_info() { printf "%s%s%s\n" "$BLUE" "$@" "$RESET"; }
```

**Step 2: 验证修改**

Run: `head -30 ai`
Expected: 显示新的颜色函数定义

**Step 3: Commit**

```bash
git add ai
git commit -m "feat: add color output helper functions using tput"
```

---

## Task 2: 改进依赖检查

**Files:**
- Modify: `ai:30-45`

**Step 1: 用新函数替换现有的依赖检查**

替换现有检查代码：

```bash
# Check dependencies with colored output
if ! command -v gum &> /dev/null; then
    print_error "gum is not installed"
    echo "Run: brew install gum"
    exit 1
fi

if ! command -v pi &> /dev/null; then
    print_error "pi is not installed"
    echo "Please install pi CLI tool"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is not installed"
    echo "Run: brew install jq"
    exit 1
fi

print_success "✓ Dependencies check passed"
```

**Step 2: 测试依赖检查**

Run: `./ai`
Expected: 显示 "✓ Dependencies check passed"（如果依赖已安装）

**Step 3: Commit**

```bash
git add ai
git commit -m "feat: improve dependency checking with colored output"
```

---

## Task 3: 改进 Spinner 动画

**Files:**
- Modify: `ai:150-175`

**Step 1: 找到 read_response 函数中的 spinner 部分**

当前 spinner:
```bash
local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
```

**Step 2: 替换为更流畅的 spinner**

```bash
# Improved spinner using Unicode box drawing characters
local spinner="⣾⣽⣻⢿⡿⣟⣯⣷"
```

**Step 3: 改进 spinner 显示**

替换 spinner 显示逻辑：
```bash
# Show progress indicator
spinner_idx=$(( (spinner_idx + 1) % ${#spin} ))
local spin_char="${spin:spinner_idx:1}"
printf "\r\033[90m[%s] Processing... (%d chars)\033[0m" "$spin_char" "$char_count"
```

**Step 4: 验证修改**

Run: `./ai` 并发起查询
Expected: 显示新的 spinner 动画

**Step 5: Commit**

```bash
git add ai
git commit -m "feat: improve spinner animation with Unicode box drawing"
```

---

## Task 4: 添加 gen 子命令（生成命令模式）

**Files:**
- Modify: `ai:60-85`

**Step 1: 在参数解析中添加 gen 模式**

找到 `while [ $# -gt 0 ]; do` 部分，添加：

```bash
        gen)
            MODE="gen"
            USE_TOOLS=true
            shift
            ;;
```

**Step 2: 添加 gen 模式处理逻辑**

在 CONTEXT_FILE 构建逻辑后添加：

```bash
# Build prompt for gen mode
if [ "$MODE" = "gen" ]; then
    # Gen mode: generate shell command from natural language
    if [ -n "$SELECTED_FILES" ]; then
        # Include selected files in context
        CONTEXT_FILE=$(mktemp)
        {
            echo "Selected files:"
            echo "$SELECTED_FILES"
            echo ""
            echo "Generate a shell command to accomplish the user's goal."
            echo "Only output the command, no explanation."
        } > "$CONTEXT_FILE"
    fi
fi
```

**Step 3: 修改主查询逻辑支持 gen 模式**

在发送命令前添加：

```bash
# For gen mode, modify the prompt
if [ "$MODE" = "gen" ]; then
    if [ -n "$CONTEXT_FILE" ]; then
        cmd=$(jq -n -c --arg context "$(cat "$CONTEXT_FILE")" --arg q "$query" '{"type":"prompt","message":"Context:\n\($context)\n\nTask: Generate a shell command to: \($q)\n\nRespond with ONLY the command, no explanations or markdown."}')
    else
        cmd=$(jq -n -c --arg q "$query" '{"type":"prompt","message":"Generate a shell command to: \($q)\n\nRespond with ONLY the command, no explanations or markdown."}')
    fi
    print_info "Generating command..."
fi
```

**Step 4: 修改 read_response 处理 gen 模式**

在响应处理后添加命令提取：

```bash
# For gen mode, extract and display the command differently
if [ "$MODE" = "gen" ] && [ -n "$RESPONSE" ]; then
    # Extract just the command (first line, remove code blocks if any)
    CMD=$(echo "$RESPONSE" | sed 's/```//g' | head -1 | xargs)
    if [ -n "$CMD" ]; then
        echo ""
        print_success "Generated command:"
        echo ""
        gum style --foreground 2 "$CMD"
        echo ""
        read -p "Execute? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            eval "$CMD"
        fi
    fi
fi
```

**Step 5: 测试 gen 模式**

```bash
./ai gen 列出当前目录下的所有 txt 文件
```

**Step 6: Commit**

```bash
git add ai
git commit -m "feat: add gen subcommand for command generation"
```

---

## Task 5: 智能模式切换

**Files:**
- Modify: `ai:70-90`

**Step 1: 实现智能模式检测**

替换现有的模式检测逻辑：

```bash
# Smart mode detection
if [ "$MODE" = "chat" ] && [ -z "$SELECTED_FILES" ]; then
    # Check if CLIFM_SELFILE has content
    if [ -f "$CLIFM_SELFILE" ] && [ -s "$CLIFM_SELFILE" ]; then
        # Files are selected, use sel mode
        MODE="sel"
        USE_TOOLS=true
        print_info "Auto-detected selected files, using sel mode"
    fi
fi
```

**Step 2: 测试智能模式**

1. 不选择文件运行 `./ai` - 应该使用 chat 模式
2. 选择文件后运行 `./ai` - 应该自动使用 sel 模式

**Step 3: Commit**

```bash
git add ai
git commit -m "feat: add smart mode auto-detection"
```

---

## Task 6: 添加历史记录功能

**Files:**
- Modify: `ai:200-220`

**Step 1: 添加历史记录函数**

在脚本末尾、main loop 之前添加：

```bash
# History management
HISTORY_FILE="${HOME}/.config/clifm/ai_history.log"

log_history() {
    local query="$1"
    local response="$2"
    local mode="$3"
    
    # Create history file if not exists
    mkdir -p "$(dirname "$HISTORY_FILE")"
    touch "$HISTORY_FILE"
    
    # Append to history
    {
        echo "---"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Mode: $mode"
        echo "---"
        echo "Q: $query"
        echo "---"
        echo "A: $response"
        echo ""
    } >> "$HISTORY_FILE"
}
```

**Step 2: 在获取响应后调用历史记录**

在 read_response 函数结束处，在显示响应前添加：

```bash
# Log to history (truncate if too long - keep last 5000 chars)
if [ -n "$RESPONSE" ]; then
    log_history "$query" "${RESPONSE:0:5000}" "$MODE"
fi
```

**Step 3: 添加历史查看子命令**

在参数解析中添加：

```bash
        history)
            if [ -f "$HISTORY_FILE" ]; then
                tail -50 "$HISTORY_FILE"
            else
                print_info "No history yet"
            fi
            exit 0
            ;;
```

**Step 4: 测试历史功能**

```bash
./ai history
./ai "Hello, what's up?"
# 再次运行 history 查看记录
```

**Step 5: Commit**

```bash
git add ai
git commit -m "feat: add conversation history logging"
```

---

## Task 7: 更新 README 文档

**Files:**
- Modify: `README.md`

**Step 1: 添加新功能文档**

在 Usage 部分后添加：

```markdown
## 新功能

### 命令生成模式 (gen)
```bash
ai gen 查找所有 .txt 文件    # 生成并执行命令
```

### 智能模式
- 自动检测选中的文件并切换到 sel 模式
- 无需手动指定子命令

### 历史记录
```bash
ai history    # 查看对话历史
```

### 改进的 UI
- 更流畅的 spinner 动画
- 彩色错误/成功/警告提示
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with new features"
```

---

## Task 8: 完整测试

**Files:**
- Test: 手动测试所有功能

**Step 1: 测试基本对话**

```bash
./ai
# 输入: 你好
```

**Step 2: 测试文件分析**

```bash
s ai
./ai
# 输入: 解释这个脚本
```

**Step 3: 测试命令生成**

```bash
./ai gen 列出所有 .md 文件
# 输入: y 执行或 n 取消
```

**Step 4: 测试历史**

```bash
./ai history
```

**Step 5: 测试智能模式**

```bash
# 选中文件后运行
s ai
./ai
```

**Step 6: 最终 commit**

```bash
git add .
git commit -m "feat: complete feature enhancement from zsh-github-copilot research"
```

---

## 执行选项

**Plan complete and saved to `docs/plans/2025-03-07-ai-plugin-enhancement.md`. Two execution options:**

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
