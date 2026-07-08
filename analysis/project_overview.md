# 项目总览（初始化）

## 项目主要功能

- 便签列表、搜索、置顶、删除与快速新建。
- 分块编辑：文本块、图片块、撤销/重做与自动保存。
- Preferences 本地持久化。
- 响应式布局：手机单列、平板自适应、展开窗口双栏预览。
- 跨设备投送包：生成、校验、导入并合并便签数据。

## 技术栈

- HarmonyOS
- ArkTS
- DevEco Studio

## 主要目录结构

- `entry/`：应用主模块，包含 ArkTS 页面、公共业务模块、资源与测试。
- `AppScope/`：应用级配置资源
- `assets/`：静态资源
- `analysis/`：分析文档、日志、测试记录与会话记录

## 页面结构

- `pages/Index.ets`：首页列表、搜索、置顶、悬浮便签、投送面板与展开窗口预览。
- `pages/EditMemo.ets`：便签编辑页，负责标题、标签、文本块、图片块和自动保存。

## 组件关系

- 页面层复用 `common/AppTheme.ets` 管理浅/深色配色。
- 页面层复用 `common/ResponsiveLayout.ets` 管理窗口分级、内容宽度和边距。
- 投送面板复用 `common/MemoTransfer.ets` 做协议编码、解码、校验和合并。
- 平台目标状态集中在 `common/PlatformTargets.ets`，避免页面硬编码。

## 数据模型

- `Memo`：便签主体，包含标题、预览、更新时间、标签、置顶状态和块列表。
- `MemoBlock`：文本块或图片块。

## 状态管理方式

- 页面使用 ArkUI `@State` 管理局部交互状态。
- 便签列表通过 `@StorageLink('memoList')` 与 `AppStorage` 同步。

## 当前存储方式

- `MemoStorage.ets` 基于 Preferences 保存和读取便签列表。

## 可改进点

- 接入真实 LAN 发现与传输层，目前已具备可复用投送包协议核心。
- 当前 HarmonyOS 工程目标为 phone/tablet/2in1；Android、Windows、Linux、macOS、Web 需要独立平台工程或跨端壳层。
- 补齐命令行 Hvigor 构建脚本，降低 DevEco Studio 之外的验证成本。
