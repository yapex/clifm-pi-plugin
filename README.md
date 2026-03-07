# CLIFM PI 插件

在 clifm 中快速调用 pi（AI 编程助手）的插件。

## 功能

- 使用 `@file` 语法指定要分析的文件
- 命令生成模式 (`gen`)
- Markdown 渲染输出
- 自动传递当前工作目录作为上下文
- 支持剪贴板内容作为上下文 (`-c` 选项)
- Tab 补全菜单选择
- FZF 交互式选择模式

## 依赖

- `pi` - AI CLI 工具
- `gum` - 终端 UI 工具，用于 Markdown 渲染 (`brew install gum`)
- `fzf` - 模糊搜索工具（可选，用于交互式模式）

## 安装

```bash
./install.sh
```

## 使用

```bash
# 普通对话
ai 解释一下什么是 bash

# 分析文件（支持多个 @file）
ai @file1.py @file2.py 解释这些文件

# 生成命令
ai gen 查找所有 .md 文件

# 使用剪贴板内容
ai -c 解释这段代码

# 帮助
ai --help
```

## Tab 补全

输入 `ai <TAB>` 会显示下拉菜单，可以选择：
- `-c` / `--clipboard` - 使用剪贴板
- `-h` / `--help` - 帮助
- `gen` - 命令生成模式
- 文件名补全

## FZF 交互模式（可选）

如果安装了 fzf，可以使用 `ai-fzf` 命令进行交互式选择：

```bash
ai-fzf
```

这会显示一个菜单让你选择操作模式。

## 自动上下文

每次调用都会自动传递：
- 📂 当前工作目录
- 📋 剪贴板内容（使用 `-c` 时）
