# Daemon Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 ai 命令从"每次启动新 pi 进程"改为"复用持久化 daemon"，实现多轮对话上下文保持和进程复用。

**Architecture:** 通过 PID 文件和 FIFO 实现 daemon 管理，启动时检查现有 daemon 是否存活，超时自动退出。

**Tech Stack:** Bash, pi --mode rpc --continue, jq, FIFO, PID 文件

---

## 实现步骤

### Task 1: 添加常量和配置

**Files:**
- Modify: `ai:1-20`

**Step 1: 添加常量定义**

在脚本开头添加以下常量：

```bash
# Daemon 配置
DAEMON_DIR="/tmp/clifm-pi-daemon"
PID_FILE="$DAEMON_DIR/pid"
FIFO_IN="$DAEMON_DIR/in"
FIFO_OUT="$DAEMON_DIR/out"
SESSION_FILE="$DAEMON_DIR/session.json"
IDLE_TIMEOUT=600  # 10 分钟

# 确保目录存在
mkdir -p "$DAEMON_DIR"
```

**Step 2: 验证脚本仍能正常运行**

Run: `./ai --help`
Expected: 显示帮助信息

**Step 3: Commit**

```bash
git add ai && git commit -m "config: 添加 daemon 配置常量"
```

---

### Task 2: 添加 daemon 管理函数

**Files:**
- Modify: `ai:25-40` (在 print_info 函数后添加)

**Step 1: 添加 daemon 检查函数**

在 `print_info` 函数后添加：

```bash
# ============== Daemon Management ==============

# 检查 daemon 是否存活
is_daemon_alive() {
    [ -f "$PID_FILE" ] || return 1
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || return 1
    
    # 检查空闲超时
    if [ -f "$SESSION_FILE" ]; then
        local last_activity
        last_activity=$(jq -r '.last_activity // 0' "$SESSION_FILE" 2>/dev/null)
        [ -n "$last_activity" ] && [ "$last_activity" != "null" ] || return 1
        local now current_idle
        now=$(date +%s)
        current_idle=$((now - last_activity))
        [ "$current_idle" -lt "$IDLE_TIMEOUT" ] || return 1
    fi
    
    return 0
}

# 启动 daemon
start_daemon() {
    # 清理旧文件
    rm -f "$PID_FILE" "$FIFO_IN" "$FIFO_OUT" "$SESSION_FILE"
    
    # 创建 FIFO
    mkfifo "$FIFO_IN" "$FIFO_OUT"
    
    # 启动 pi daemon，使用 --continue 保持会话
    [ "$MODE" = "gen" ] && PI_ARGS="--thinking off --no-tools" || PI_ARGS="--thinking off --tools read"
    pi --mode rpc --continue $PI_ARGS < "$FIFO_IN" > "$FIFO_OUT" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    # 初始化会话文件
    echo "{\"messages\":0,\"last_activity\":$(date +%s)}" > "$SESSION_FILE"
    
    # 等待 daemon 准备好
    sleep 1
    
    # 验证 daemon 启动成功
    if ! kill -0 "$pid" 2>/dev/null; then
        print_error "Daemon 启动失败"
        rm -f "$PID_FILE" "$FIFO_IN" "$FIFO_OUT" "$SESSION_FILE"
        exit 1
    fi
    
    print_info "Daemon 已启动 (PID: $pid)"
}

# 停止 daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            print_info "Daemon 已停止"
        fi
    fi
    rm -f "$PID_FILE" "$FIFO_IN" "$FIFO_OUT" "$SESSION_FILE"
}

# 获取 daemon 状态
get_daemon_status() {
    if is_daemon_alive; then
        local pid messages idle last_activity now
        pid=$(cat "$PID_FILE")
        messages=$(jq -r '.messages // 0' "$SESSION_FILE" 2>/dev/null || echo 0)
        last_activity=$(jq -r '.last_activity // 0' "$SESSION_FILE" 2>/dev/null || echo 0)
        now=$(date +%s)
        idle=$((now - last_activity))
        local idle_min=$((idle / 60))
        
        echo "Daemon: running (PID: $pid)"
        echo "Messages: $messages"
        echo "Idle: ${idle_min}m"
    else
        echo "Daemon: not running"
    fi
}

# 更新会话活动时间
update_activity() {
    local msg_count
    msg_count=$(jq -r '.messages // 0' "$SESSION_FILE" 2>/dev/null || echo 0)
    echo "{\"messages\":$((msg_count + 1)),\"last_activity\":$(date +%s)}" > "$SESSION_FILE"
}
```

**Step 2: 验证语法正确**

Run: `bash -n ai`
Expected: 无错误输出

**Step 3: Commit**

```bash
git add ai && git commit -m "feat: 添加 daemon 管理函数"
```

---

### Task 3: 修改参数解析支持新命令

**Files:**
- Modify: `ai:45-85` (修改 usage 和参数解析)

**Step 1: 更新 usage 函数**

将 usage 函数替换为：

```bash
# Usage helper
usage() {
    echo "Usage:"
    echo "  ai [options] [files] [query]"
    echo "    file1 file2 解释这些文件"
    echo "    gen 查找所有 .md 文件"
    echo "    -c 使用剪贴板内容"
    echo ""
    echo "Commands:"
    echo "  ai --status    查看 daemon 状态"
    echo "  ai --reset     重置 daemon（清空历史）"
    echo "  ai --stop      停止 daemon"
    echo ""
    echo "Options:"
    echo "  -c, --clipboard  使用剪贴板内容作为上下文"
    echo "  -h, --help       显示帮助"
}
```

**Step 2: 添加命令解析**

在参数解析部分，在 `gen)` 之前添加：

```bash
# 先检查特殊命令
case "$1" in
    --status)
        get_daemon_status
        exit 0
        ;;
    --reset)
        stop_daemon
        print_info "Daemon 已重置"
        exit 0
        ;;
    --stop)
        stop_daemon
        exit 0
        ;;
esac

# 然后解析参数
while [ $# -gt 0 ]; do
```

**Step 3: 验证参数解析**

Run: `./ai --status`
Expected: 显示 "Daemon: not running"

**Step 4: Commit**

```bash
git add ai && git commit -m "feat: 添加 --status/--reset/--stop 命令"
```

---

### Task 4: 修改主流程使用 daemon

**Files:**
- Modify: `ai:140-200` (原 Start pi 部分)

**Step 1: 替换 pi 启动逻辑**

将原 "Start pi" 部分替换为：

```bash
# ============== 主流程 ==============

# 检查或启动 daemon
if is_daemon_alive; then
    print_info "使用现有 daemon..."
else
    print_info "启动新 daemon..."
    start_daemon
fi

# 检查 FIFO 是否存在
if [ ! -p "$FIFO_IN" ] || [ ! -p "$FIFO_OUT" ]; then
    print_error "FIFO 不可用，请重试"
    exit 1
fi

# 更新活动时间
update_activity

# 发送请求
exec 3>"$FIFO_IN"
exec 4<"$FIFO_OUT"

jq -n -c --arg q "$MSG" '{"type":"prompt","message":$q}' >&3
```

**Step 2: 移除旧的清理逻辑**

删除原来的：
```bash
# Start pi
FIFO_DIR=$(mktemp -d)
trap 'kill $PI_PID 2>/dev/null; rm -rf "$FIFO_DIR"' EXIT
```

因为现在 daemon 持久运行，不需要每次都清理。

**Step 3: 验证 daemon 启动**

Run: `echo "你好" | ./ai /dev/stdin` (或实际测试)
Expected: 启动 daemon 并响应

**Step 4: Commit**

```bash
git add ai && git commit -m "feat: 修改主流程使用 daemon 模式"
```

---

### Task 5: 清理和测试

**Files:**
- Modify: `ai` (整体测试)

**Step 1: 测试完整流程**

```bash
# 1. 首次调用 - 启动 daemon
ai "你好"
# 预期: 启动新 daemon

# 2. 查看状态
ai --status
# 预期: Daemon: running | Messages: 1 | Idle: 0m

# 3. 再次调用 - 复用 daemon  
ai "继续"
# 预期: 使用现有 daemon

# 4. 再次查看状态
ai --status
# 预期: Daemon: running | Messages: 2 | Idle: 0m

# 5. 重置
ai --reset
# 预期: daemon 重置

# 6. 停止
ai --stop
# 预期: daemon 停止

# 7. 状态检查
ai --status
# 预期: Daemon: not running
```

**Step 2: 修复发现的问题**

根据测试结果修复 bug。

**Step 3: 最终提交**

```bash
git add ai && git commit -m "feat: 完成 daemon 模式实现"
```

---

## 预期产出

完成所有任务后，`ai` 命令将支持：
- `ai "问题"` - 复用或启动 daemon
- `ai file1 解释` - 带文件上下文的对话
- `ai gen 生成命令` - 命令生成模式
- `ai --status` - 查看 daemon 状态
- `ai --reset` - 重置 daemon
- `ai --stop` - 停止 daemon
