# CLIFM PI 插件

在 clifm 中快速调用 pi（AI 编程助手）的插件。

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
# 1. 创建插件链接
ln -sf ~/workspace/clifm-pi-plugin/ai ~/.config/clifm/plugins/ai
chmod +x ~/workspace/clifm-pi-plugin/ai

# 2. 创建 actions 配置
echo "ai /Users/yapex/.config/clifm/plugins/ai" >> ~/.config/clifm/actions
```

或者手动编辑 `~/.config/clifm/actions`：
```
ai /Users/yapex/.config/clifm/plugins/ai
```

## 使用

### 普通对话
```
ai
```

### 分析选中的文件
```
s file1.py file2.py    # 先选择文件
ai sel                 # 启动 AI 分析
```

## 交互

- 输入框默认显示 `解释一下`，可直接发送或继续补充
- 继续输入 → 追问（上下文保持）
- 按 Esc → 显示菜单（复制/退出）
