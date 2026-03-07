# CLIFM AI 查询插件设计文档

**日期**: 2026-03-07  
**项目**: clifm-ai-plugin

## 概述

为 clifm 文件管理器创建一个插件，通过快捷命令呼出终端 UI 弹窗，输入问题后调用 `pi -p` 执行 AI 查询，并在预览窗口显示结果，支持手动复制。

## 功能需求

1. **触发方式**: 在 clifm 命令行输入 `ai` 触发插件
2. **输入界面**: 使用 fzf 提供输入框，用户输入要查询的 AI 问题
3. **执行**: 调用 `pi -p "用户输入的消息"` 执行 AI 查询
4. **预览输出**: 在 fzf 的预览窗口中显示 AI 返回的结果
5. **复制功能**: 用户可选择复制结果到剪贴板

## 技术方案

### 工具选择
- **UI 框架**: fzf（已推荐并获确认）
- **剪贴板**: pbcopy（macOS）/ xclip（Linux）
- **执行命令**: `pi -p "<message>"`

### 工作流程

```
1. 用户在 clifm 输入: ai
2. 插件启动 fzf 输入框
3. 用户输入问题，按 Enter
4. 脚本执行: pi -p "用户问题"
5. fzf 预览窗口显示结果
6. 用户可按 Ctrl+C 复制结果，或 Ctrl+Q 退出
```

### 核心脚本逻辑

1. 读取用户输入
2. 验证输入非空
3. 执行 pi 命令并捕获输出
4. 将输出传递给 fzf 预览

## 文件结构

```
~/workspace/clifm-ai-plugin/
├── README.md              # 使用说明
├── ai                     # 主脚本（可执行）
└── install.sh            # 安装脚本（可选）
```

## 实现细节

### ai 脚本

```bash
#!/usr/bin/env bash

# 1. 使用 fzf 获取用户输入
query=$(fzf --prompt="Ask AI: " --height=40% --border)

# 2. 如果用户取消或为空，退出
if [ -z "$query" ]; then
    exit 0
fi

# 3. 执行 pi 命令
response=$(pi -p "$query" 2>&1)

# 4. 使用 fzf 预览结果，允许复制
echo "$response" | fzf --preview="echo {}" --preview-window=up:80% \
    --prompt="AI Response (Ctrl+C to copy, Esc to quit): " \
    --bind="ctrl-c:execute-silent(echo -n {} | pbcopy)+abort" \
    --bind="esc:abort"
```

## 配置说明

1. 将脚本放到 clifm 的插件目录或系统 PATH 中
2. 或者在 clifm 中创建 alias: `alias ai="/path/to/ai"`
3. 确保 `pi` 命令可用

## 后续可能的扩展

- 支持自定义 pi 参数
- 添加历史记录功能
- 支持多轮对话
