# CLIFM PI 插件

在 clifm 中快速调用 pi（AI 编程助手）的插件。

## 功能

- 使用 `@file` 语法指定要分析的文件
- 命令生成模式 (`gen`)
- Markdown 渲染输出

## 依赖

- `pi` - AI CLI 工具
- `gum` - 终端 UI 工具，用于 Markdown 渲染 (`brew install gum`)

## 安装

```bash
./install.sh
```

## 使用

```bash
# 分析文件（支持多个 @file）
ai @file1.py @file2.py 解释这些文件

# 生成命令
ai gen 查找所有 .md 文件

# 普通对话
ai 解释一下什么是 bash
```

## Zsh 补全

安装后自动启用 `ai @` 文件名补全。按 Tab 补全。
