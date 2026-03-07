# CLIFM PI 插件

在 clifm 中快速调用 pi（AI 编程助手）的插件。

## 功能

- 使用 gum 弹窗输入问题
- 调用 `pi` 执行 AI 查询（RPC 模式，保持上下文）
- 响应完成后用 gum 渲染 Markdown 格式
- 支持多轮对话（上下文保持）
- 支持分析选中的文件

## 依赖

必需：
- `gum` - 终端 UI 工具，用于输入和 Markdown 渲染 (`brew install gum`)
- `pi` - AI CLI 工具
- `jq` - JSON 处理 (`brew install jq`)

## 安装

```bash
# 创建插件链接
ln -sf ~/workspace/clifm-pi-plugin/ai ~/.config/clifm/plugins/ai
chmod +x ~/workspace/clifm-pi-plugin/ai
```

**注意**：无需创建 actions 文件，clifm 会自动识别 `plugins` 目录中的可执行文件。

## 使用

### 方式 1：直接选择文件运行（推荐）
```bash
s file1.py file2.py    # 先选择文件
ai                     # 直接运行，clifm 会把选中的文件作为参数传递
```

### 方式 2：使用 sel 子命令
```bash
s file1.py file2.py    # 先选择文件
ai sel                 # 从 CLIFM_SELFILE 读取选中的文件
```

### 普通对话（不分析文件）
```bash
ai                     # 直接运行，不选择文件
```

## 交互

- gum 输入框默认显示 `解释一下`，可直接发送或修改
- AI 响应完成后用 gum 渲染 Markdown 格式（代码高亮、列表、标题等）
- 继续输入 → 追问（上下文保持）
- 空输入（按 Esc）→ 直接退出
