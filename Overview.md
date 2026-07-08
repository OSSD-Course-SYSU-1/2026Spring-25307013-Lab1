# InstantNote 概览（Overview）

## 1. 界面设计与布局（ArkUI）
- 页面结构
  - 首页 `entry/src/main/ets/pages/Index.ets`
    - 最外层使用 `Stack` + `Column` 组织页面，`Scroll` 搭配 `Column({ space })` 实现备忘录列表的垂直滚动。
    - 卡片：每条备忘录用 `Column` + 圆角 + 阴影表现。文本用 `Text`，时间/标签用 `Row` 对齐。
    - 操作：底部使用 `Button('New Note')` 作为主要按钮；弹窗表单用 `Stack` 叠加半透明遮罩层，再用 `Column` 作为对话框容器。
  - 编辑页 `entry/src/main/ets/pages/EditMemo.ets`
    - 顶部工具栏用 `Row`：返回、撤销、重做、插入文本块、插入图片。
    - 主体区使用 `Scroll` + `Column` 渲染区块列表；文本区块用 `TextArea`，图片区块用 `Image`。
    - 焦点高亮：当前输入的区块外层 `Column` 配置边框（`border`）与圆角（`borderRadius`），通过状态判断是否高亮。
- 关键 ArkUI 组件与模式
  - 容器：`Stack | Column | Row | Scroll`
  - 文本与输入：`Text | TextInput | TextArea`
  - 交互：`Button | Image | LongPressGesture`
  - 列表：`ForEach(this.blocks, (block) => ...)` 根据 `id` 作为 key，保证稳定渲染。
  - 事件：`.onClick() .onChange() .onFocus() .onBlur()` 等，直接驱动状态更新。

## 2. 功能逻辑说明（交互与小巧思）
- 列表与导航
  - 首页长按卡片可删除，点击卡片通过 `@ohos.router.pushUrl({ url: 'pages/EditMemo', params })` 进入编辑页。
- 编辑体验
  - 文本块编辑：`TextArea` 绑定状态，`.onChange()` 即时更新；`.onFocus()` 记录当前活动区块，触发高亮。
  - 图片插入：调用 `@ohos.file.picker.PhotoViewPicker` 选择图片；若无选择则按固定顺序插入内置占位资源。
  - 自动保存：输入变更触发 `queueAutosave()`，通过 `setTimeout` 做轻量防抖；离开页面前 `flushPendingSave()` 确保落盘到 `AppStorage`。
  - 撤销/重做：维护 `undoStack`/`redoStack`，每次编辑前快照 `blocks`（`JSON.stringify`），并限制栈深，保证性能与可逆性。
  - 空白块清理：当焦点离开某文本块时，若该块为空且非活动块，触发清理，避免残留空区块；最后一个区块始终保证存在。
  - 长按删除：统一弹出确认对话框（`@ohos.promptAction.showDialog`），避免误删。
- 预览与卡片摘要
  - `memoPreviewFromBlocks(blocks)` 提取第一个非空文本作为首页卡片预览；若无则回退到默认文案。

## 3. 主题与暗色模式适配
- 系统模式感知
  - 在 `EntryAbility` 的 `onCreate` 与 `onConfigurationUpdate` 中读取系统 `Configuration.colorMode`，并将 `'light' | 'dark'` 写入 `AppStorage('systemColorMode')`，供全局组件订阅。
- 页面侧主题选择
  - 首页与编辑页分别定义亮/暗两套调色板（背景、卡片、输入、主文本、次文本、描边、强调色等）。
  - 通过 `@StorageLink('systemColorMode')` 读取模式，并使用本地 `resolvePalette()`/`resolveEditorPalette()` 方法做健壮性归一（默认亮色）。
  - 所有 UI 颜色均来源于调色板，亮色外观保持不变，切到系统暗色时自动切换到暗色外观。

## 4. 数据管理与状态
- 数据结构（见 `entry/src/main/ets/common/MemoModel.ets`）
  - `Memo`: `{ id, title, bodyPreview, updatedAt, tag?, blocks: MemoBlock[] }`
  - `MemoBlock`（联合类型）
    - `TextBlock`: `{ id, type: 'text', content }`
    - `ImageBlock`: `{ id, type: 'image', asset?, uri?, caption? }`
  - 工具函数
    - `createTextBlock(id, content)` / `createImageBlock(id, asset?, uri?)`
    - `getNextBlockId(blocks)` 计算递增区块 ID
    - `cloneMemoBlocks(blocks)` 深克隆用于持久化与撤销快照
    - `memoPreviewFromBlocks(blocks)` 生成首页预览文本
- 状态来源与同步
  - 全局：`AppStorage` + `@StorageLink('memoList')` 绑定首页与编辑页，实现列表/编辑的单一真相源。
  - 页面级：`@State` 管理标题、标签、区块、活动区块、撤销状态等。
  - 持久化：编辑页的 `persistChanges()` 将规范化后的 `Memo` 回写 `AppStorage`；首页读取同一存储即可实时刷新。

## 5. 路由、交互与生命周期
- 路由导航：`@ohos.router` 的 `pushUrl/back` 实现列表→编辑与返回。
- 生命周期：
  - `aboutToAppear()`：编辑页解析路由参数并装载对应 `Memo`。
  - `aboutToDisappear()`：编辑页确保写回（`flushPendingSave()`）。
- 手势与键盘：
  - 长按（`LongPressGesture`）统一入口做删除确认。
  - 文本焦点变化（`onFocus/onBlur`）控制高亮与空白清理。

## 6. 技术选型与实践要点
- ArkTS + ArkUI 声明式编程：通过装饰器 `@Entry/@Component/@State/@StorageLink` 构建响应式 UI。
- 低耦合数据模型：UI 组件只依赖 `Memo`/`MemoBlock` 与模型工具函数，便于扩展（如音频块/AI 摘要块）。
- 友好体验的小技巧：
  - 自动保存 + 撤销/重做 提升安全感；
  - 空白块自动清理 保持页面整洁；
  - 预览文本抽取 让列表信息更有用；
  - 调色板统一管理 便于主题切换与品牌色维护。

## 7. 可扩展方向
- 新区块类型：音频记录+转写、AI 摘要块（与现有 Union 类型无缝对接）。
- 搜索与过滤：按课程/标签/时间检索；笔记内关键字跳转。
- 媒体能力：拍照、裁剪与批量导入；图片说明文字。
- 同步与备份：引入本地数据库/云同步；多设备一致性。

> 本文档旨在帮助快速理解 InstantNote 的界面布局、交互逻辑与数据设计，便于继续演进或团队协作。
