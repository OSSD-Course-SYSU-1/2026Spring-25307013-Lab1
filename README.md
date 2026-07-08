# InstantNote

InstantNote 是一个 HarmonyOS / ArkTS 便签课程项目，聚焦快速记录、分块编辑、本地持久化、响应式布局和跨设备投送。

## 功能

- 便签列表：搜索、置顶、长按删除、桌面宽屏预览。
- 便签编辑：标题、标签、文本块、图片块、撤销/重做、自动保存。
- 本地存储：通过 Preferences 保存便签列表，并同步到 AppStorage。
- 投送中心：已完成投送 JSON 协议、发送/接收 UI 和导入预览；真实两机传输待接入。
- 响应式布局：Compact / Medium / Expanded 三档适配手机、平板和 2in1 窗口。
- 主题：跟随系统浅色/深色模式。

## 主要目录

- `entry/src/main/ets/pages/Index.ets`：首页、搜索、列表、置顶、投送中心、宽屏预览。
- `entry/src/main/ets/pages/EditMemo.ets`：便签编辑器。
- `entry/src/main/ets/common/MemoModel.ets`：便签数据模型和默认数据。
- `entry/src/main/ets/common/MemoStorage.ets`：Preferences 存储封装。
- `entry/src/main/ets/common/MemoTransfer.ets`：投送 JSON 协议、校验、摘要和合并逻辑。
- `entry/src/main/ets/common/PlatformShare.ets`：系统分享能力隔离。
- `entry/src/main/ets/common/ResponsiveLayout.ets`：响应式断点和宽度工具。
- `entry/src/main/ets/common/PlatformTargets.ets`：当前支持平台和规划平台声明。
- `analysis/`：开发记录、变更日志、排障日志和测试记录。

## 支持平台

当前工程原生支持 HarmonyOS `phone`、`tablet`、`2in1`，配置见 `entry/src/main/module.json5`。

Android、Windows、Linux、macOS、Web 尚无独立工程或打包目标。如果需要这些平台，应新增对应平台工程或迁移到跨端框架，并复用 `MemoModel` / `MemoTransfer` 等业务协议设计。

## 开发与验证

推荐使用 DevEco Studio 打开项目并运行 `entry` 模块。

命令行可使用 DevEco Studio 自带 Hvigor：

```bash
D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp
```

本仓库当前没有独立 `lint` 任务；可执行 `hvigorw.bat tasks` 查看可用任务。

## 投送流程

当前已完成：

- 投送 JSON 协议
- 投送包校验
- 发送 / 接收 UI
- 粘贴导入
- 导入预览
- 确认导入
- 外来副本追加导入，避免本地 id 冲突

当前可用验证流程：

发送端：

1. 点击首页右上角「投送」。
2. 在「发送」页选择当前便签或全部便签，查看待投送内容摘要。
3. 打开「调试 JSON」。
4. 复制完整投送内容。

接收端：

5. 进入「投送 -> 接收」。
6. 粘贴完整投送内容。
7. 点击「预览导入」。
8. 确认导入。

尚未完成：

- 局域网发现附近设备
- 真正两机自动连接
- 面对面传输层
- 扫码导入
- 图片块跨设备恢复

后续规划：

- 局域网面对面投送
- 设备发现
- 会话确认码
- 文本便签传输
- 图片块传输
