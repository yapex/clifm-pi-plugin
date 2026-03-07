# CLIFM AI 查询插件

在 clifm 中快速调用 AI 查询的插件。

## 功能

- 输入 `ai` 命令触发
- 使用 fzf 弹窗输入问题
- 调用 `pi -p` 执行 AI 查询
- 在预览窗口显示结果
- 支持复制结果到剪贴板

## 依赖

- `fzf` - 模糊搜索工具
- `pi` - AI CLI 工具
- `pbcopy` (macOS) 或 `xclip` (Linux) - 剪贴板工具

## 安装

1. 确保 `fzf` 和 `pi` 已安装
2. 创建符号链接到 clifm 插件目录：

```bash
ln -sf ~/workspace/clifm-ai-plugin/ai ~/.config/clifm/plugins/ai
chmod +x ~/workspace/clifm-ai-plugin/ai
```

## 使用

在 clifm 中输入：`ai`

然后输入你的问题，按 Enter 执行查询。

在结果预览中：
- `Ctrl+C` 复制选中行
- `Ctrl+A` 复制全部内容
- `Esc` 退出

## 自定义

你可以编辑 `ai` 脚本来调整：
- `--height` - 弹窗高度
- `--border` - 边框样式
- 其他 fzf 选项
