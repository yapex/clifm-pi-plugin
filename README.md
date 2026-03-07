# CLIFM AI 查询插件

在 clifm 中快速调用 AI 查询的插件。

## 功能

- 使用 gum 弹窗输入问题
- 调用 `pi` 执行 AI 查询（RPC 模式，保持上下文）
- 实时流式显示响应
- Markdown 格式渲染
- 支持复制结果到剪贴板
- 支持多轮对话（上下文保持）
- 支持分析选中的文件

## 依赖

- `gum` - 终端 UI 工具 (`brew install gum`)
- `pi` - AI CLI 工具
- `jq` - JSON 处理 (`brew install jq`)
- `pbcopy` (macOS) 或 `xclip` (Linux) - 剪贴板工具

## 安装

```bash
ln -sf ~/workspace/clifm-ai-plugin/ai ~/.config/clifm/plugins/ai
chmod +x ~/workspace/clifm-ai-plugin/ai
```

## 使用

### 普通对话

在 clifm 中输入：
```
ai
```

### 分析选中的文件

1. 先用 `s` 选择文件（可多选）
2. 然后输入：
```
ai sel
```

AI 会读取选中文件的内容，你可以询问关于这些文件的问题。

## 交互

- 输入问题 → AI 回答
- 继续输入 → 追问（上下文保持）
- 按 Esc → 显示菜单（复制/退出）

## 示例

```
# 在 clifm 中
s file1.py file2.py    # 选择文件
ai sel                 # 启动 AI 分析
> 这两个文件有什么区别？
> 帮我重构一下 file1.py
```
