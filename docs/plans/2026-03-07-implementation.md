# CLIFM AI 查询插件 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 clifm 创建一个 AI 查询插件，通过 `ai` 命令呼出 fzf 弹窗，输入问题后执行 `pi -p` 并预览结果，支持复制。

**Architecture:** 使用 bash 脚本封装 fzf 交互流程，先获取用户输入，再调用 pi 命令，最后用 fzf 预览窗口显示结果并提供复制功能。

**Tech Stack:** Bash, fzf, pi (AI CLI), pbcopy (macOS 剪贴板)

---

## Task 1: 创建项目基础结构

**Files:**
- Create: `~/workspace/clifm-ai-plugin/README.md`
- Create: `~/workspace/clifm-ai-plugin/ai`

**Step 1: 创建 README.md**

```markdown
# CLIFM AI 查询插件

在 clifm 中快速调用 AI 查询的插件。

## 功能

- 输入 `ai` 命令触发
- 使用 fzf 弹窗输入问题
- 调用 `pi -p` 执行 AI 查询
- 在预览窗口显示结果
- 支持复制结果到剪贴板

## 安装

1. 确保 `fzf` 和 `pi` 已安装
2. 将 `ai` 脚本链接到 clifm 插件目录：

```bash
ln -s ~/workspace/clifm-ai-plugin/ai ~/.config/clifm/plugins/ai
chmod +x ~/workspace/clifm-ai-plugin/ai
```

## 使用

在 clifm 中输入：`ai`

然后输入你的问题，按 Enter 执行查询。

在结果预览中：
- `Ctrl+C` 复制选中内容
- `Esc` 退出
```

**Step 2: 创建主脚本 ai**

```bash
#!/usr/bin/env bash

# CLIFM AI Query Plugin
# Usage: In clifm, type 'ai' to trigger

set -e

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed. Please install fzf first."
    exit 1
fi

# Check if pi is available
if ! command -v pi &> /dev/null; then
    echo "Error: pi is not installed. Please install pi first."
    exit 1
fi

# Step 1: Get user input using fzf
query=$(echo "" | fzf \
    --prompt="Ask AI: " \
    --height=40% \
    --border=rounded \
    --header="Type your question and press Enter" \
    --print-query \
    --no-sort \
    | tail -n 1)

# Step 2: Exit if empty
if [ -z "$query" ]; then
    echo "No query provided. Exiting."
    exit 0
fi

# Step 3: Execute pi command and capture output
echo "Querying AI..."
response=$(pi -p "$query" 2>&1)

# Step 4: Display result in fzf preview with copy support
echo "$response" | fzf \
    --preview="echo {}" \
    --preview-window=up:80%:wrap \
    --prompt="AI Response | " \
    --header="Ctrl+C: copy selected | Ctrl+A: copy all | Esc: quit" \
    --height=90% \
    --border=rounded \
    --bind="ctrl-c:execute-silent(echo -n {} | pbcopy)+reload(echo 'Copied!')" \
    --bind="ctrl-a:execute-silent(echo '$response' | pbcopy)+reload(echo 'All copied!')" \
    --bind="esc:abort" \
    --no-sort \
    --no-multi
```

**Step 3: 设置脚本可执行权限**

Run: `chmod +x ~/workspace/clifm-ai-plugin/ai`

---

## Task 2: 安装到 clifm 插件目录

**Files:**
- Create symlink: `~/.config/clifm/plugins/ai` -> `~/workspace/clifm-ai-plugin/ai`

**Step 1: 创建符号链接**

Run: `ln -sf ~/workspace/clifm-ai-plugin/ai ~/.config/clifm/plugins/ai`

**Step 2: 验证链接**

Run: `ls -la ~/.config/clifm/plugins/`

Expected: 看到 `ai -> /Users/yapex/workspace/clifm-ai-plugin/ai`

---

## Task 3: 测试插件

**Step 1: 手动测试脚本**

Run: `~/workspace/clifm-ai-plugin/ai`

测试流程：
1. 输入一个简单问题，如 "what is 2+2"
2. 验证 fzf 弹窗显示
3. 验证 AI 响应显示在预览窗口
4. 测试 Ctrl+C 复制功能
5. 测试 Esc 退出功能

**Step 2: 在 clifm 中测试**

Run: `clifm`

在 clifm 中输入 `ai`，验证插件正常工作。

---

## Task 4: 初始化 Git 仓库

**Step 1: 初始化 git**

Run: `cd ~/workspace/clifm-ai-plugin && git init && git add . && git commit -m "feat: initial clifm ai plugin"`

---

## 完成标准

- [ ] `ai` 脚本可执行
- [ ] 符号链接正确指向脚本
- [ ] 在 clifm 中输入 `ai` 可触发插件
- [ ] fzf 弹窗正常显示
- [ ] AI 查询结果正确显示在预览窗口
- [ ] Ctrl+C 可复制选中内容
- [ ] Ctrl+A 可复制全部内容
- [ ] Esc 可退出
