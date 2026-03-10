# CLIFM PI Plugin - Daemon Mode 设计文档

**日期**: 2026-03-10
**目标**: 实现会话持久化 + 进程复用

## 概述

将 `ai` 命令从"每次启动新 pi 进程"改为"复用持久化 daemon"，实现：
- 多轮对话上下文保持
- 减少冷启动开销
- 自动生命周期管理

## 架构

```
┌─────────────────────────────────────────────────────────────┐
│  ai 命令                                                     │
│    │                                                         │
│    ├── ai "问题1"  ──┐                                       │
│    ├── ai "问题2"  ──┼──► pi daemon (FIFO + PID)            │
│    ├── ai --status ──┤      │                               │
│    ├── ai --reset  ──┤      ├── RPC 通信                     │
│    └── ai --stop   ──┘      └── 会话保持 (--continue)        │
└─────────────────────────────────────────────────────────────┘
```

## 核心机制

### 文件位置

| 文件 | 路径 | 用途 |
|------|------|------|
| PID 文件 | `/tmp/clifm-pi-daemon.pid` | 存储 daemon PID |
| 输入 FIFO | `/tmp/clifm-pi-in.fifo` | 客户端 → daemon |
| 输出 FIFO | `/tmp/clifm-pi-out.fifo` | daemon → 客户端 |
| 会话文件 | `/tmp/clifm-pi-session.json` | 消息计数、最后活动时间 |

### 生命周期

**启动检查：**
```
1. PID 文件存在？
   ├─ 否 → 启动新 daemon
   └─ 是 → 进程存活？
           ├─ 否 → 清理旧文件，启动新 daemon
           └─ 是 → 复用现有 daemon
```

**daemon 自动退出条件：**
1. 空闲超过 10 分钟（无请求）
2. 收到 SIGTERM/SIGINT

**清理机制：**
- daemon 退出时删除 PID 文件和 FIFO
- `/tmp` 文件在系统重启时自动清理

### 通信协议

复用现有 RPC 格式，增加心跳检测：

```json
// 客户端请求
{"type": "ping"}
{"type": "prompt", "message": "..."}

// daemon 响应
{"type": "pong", "messages": 5, "uptime": 120}
{"type": "response", ...}
{"type": "message_update", ...}
{"type": "agent_end", ...}
```

## 命令扩展

```bash
ai "问题"          # 复用或启动 daemon，发送请求
ai file1 解释这个  # 同上，带文件上下文
ai gen 生成命令    # 同上，命令生成模式

ai --status        # 显示 daemon 状态
                   # 输出: Daemon: running | Messages: 3 | Idle: 2m

ai --reset         # 强制重启 daemon（清空历史）
ai --stop          # 停止 daemon（不重启）
```

## 实现细节

### 1. daemon 启动函数

```bash
start_daemon() {
    # 清理旧文件
    rm -f "$PID_FILE" "$FIFO_IN" "$FIFO_OUT"
    
    # 创建 FIFO
    mkfifo "$FIFO_IN" "$FIFO_OUT"
    
    # 启动 pi daemon
    pi --mode rpc --continue < "$FIFO_IN" > "$FIFO_OUT" 2>&1 &
    echo $! > "$PID_FILE"
    
    # 初始化会话文件
    echo '{"messages":0,"last_activity":'$(date +%s)'}' > "$SESSION_FILE"
}
```

### 2. daemon 检查函数

```bash
check_daemon() {
    [ -f "$PID_FILE" ] || return 1
    
    local pid=$(cat "$PID_FILE")
    kill -0 "$pid" 2>/dev/null
    
    # 同时检查空闲超时
    if [ -f "$SESSION_FILE" ]; then
        local last=$(jq -r '.last_activity' "$SESSION_FILE")
        local now=$(date +%s)
        local idle=$((now - last))
        [ $idle -gt 600 ] && return 1  # 10 分钟超时
    fi
}
```

### 3. 空闲超时检测

两种方案：
- **A) 客户端检测** - 每次 `ai` 调用时检查 session 文件的时间戳
- **B) daemon 自检** - daemon 内部定期检查，超时自动退出

推荐 A，实现简单，无需修改 pi 行为。

### 4. 请求处理

```bash
send_request() {
    # 更新活动时间
    local msg_count=$(jq -r '.messages' "$SESSION_FILE" 2>/dev/null || echo 0)
    echo "{\"messages\":$((msg_count+1)),\"last_activity\":$(date +%s)}" > "$SESSION_FILE"
    
    # 发送请求
    jq -n -c --arg q "$MSG" '{"type":"prompt","message":$q}' > "$FIFO_IN"
    
    # 读取响应（复用现有逻辑）
    ...
}
```

## 错误处理

| 场景 | 处理 |
|------|------|
| daemon 崩溃 | 客户端检测到 PID 不存在，自动重启 |
| FIFO 阻塞 | 设置读取超时，超时后报错 |
| 请求超时 | 30 秒无响应，提示用户重试 |

## 改动范围

只需修改 `ai` 脚本，无需修改 clifm 或 pi：

1. 添加 daemon 管理 函数
2. 添加 `--status`、`--reset`、`--stop` 参数处理
3. 修改主流程：先检查/启动 daemon，再发送请求
4. 添加会话文件更新逻辑

## 测试用例

```bash
# 1. 首次调用 - 启动 daemon
ai "你好"
ai --status  # Daemon: running | Messages: 1 | Idle: 0m

# 2. 后续调用 - 复用 daemon
ai "继续刚才的话题"
ai --status  # Daemon: running | Messages: 2 | Idle: 0m

# 3. 空闲超时 - 自动重启
sleep 600
ai "新问题"   # 应该启动新 daemon
ai --status  # Daemon: running | Messages: 1 | Idle: 0m

# 4. 手动重置
ai --reset
ai --status  # Daemon: running | Messages: 0 | Idle: 0m

# 5. 停止
ai --stop
ai --status  # Daemon: not running
```
