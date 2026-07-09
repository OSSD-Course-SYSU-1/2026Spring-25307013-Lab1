# 问题解决日志

## 2026-07-09 03:23 - 发送端 mDNS 发布复核构建验证

### 现象

用户重复要求确认发送端 mDNS 服务发布 / 移除实现，需要复核当前实现并验证构建。

### 原因分析

当前 `TransferLanDiscovery.ets` 已使用 `@kit.NetworkKit` 的 `mdns.addLocalService()` / `mdns.removeLocalService()`，本轮风险主要是确认实现仍满足不搜索、不接 UI、不传输 payload 的边界。

### 处理过程

执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 557 ms`。输出包含未配置 signingConfigs 的既有签名警告；本轮没有新增业务代码变更。

### 后续建议

下一步再实现接收端 mDNS 搜索时，继续限制为发现摘要解析，不传输 payload。

## 2026-07-09 03:21 - 发送端 mDNS 发布构建验证

### 现象

`TransferLanDiscovery.ets` 接入 `mdns.addLocalService()` / `mdns.removeLocalService()` 后，需要确认 ArkTS 类型和构建是否通过。

### 原因分析

本轮新增了 `@kit.NetworkKit` 的 mDNS 调用、`mdns.LocalServiceInfo`、TXT 记录和全局发布状态，主要风险是 API 类型、TXT 记录类型或上下文获取方式不匹配。

### 处理过程

执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 8 s 855 ms`。输出仍包含项目既有弃用 API 警告和未配置 signingConfigs 的签名警告，未发现本轮 mDNS 发布实现导致的编译错误。

### 后续建议

接收端搜索实现前，先保持 `searchPeers()` 返回空数组；下一步只接入 mDNS 搜索和 TXT 记录解析，不传输 payload。

## 2026-07-09 03:16 - 局域网发现层骨架构建验证

### 现象

新增 `TransferLanDiscovery.ets` 和 `ohos.permission.INTERNET` 后，需要确认工程是否仍可编译。

### 原因分析

本轮新增了 ArkTS 导出类型 / 函数和 `module.json5` 权限声明，主要风险是类型引用、未使用符号、JSON5 结构或 ArkTS 语法导致构建失败。

### 处理过程

执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 9 s 485 ms`。命令输出包含既有弃用 API 警告和未配置 signingConfigs 的签名警告，未发现本次新增发现层骨架导致的编译错误。

### 后续建议

后续接入 mDNS 实现时继续保持小步构建验证，并区分新引入错误与项目既有警告。

## 记录规范

- 记录时间、现象、原因分析、处理过程、结果与后续建议。
- 若问题未解决，必须说明阻塞点与下一步计划。

## 2026-07-09 02:18 - 投送中心面对面流程 UI 构建验证
### 现象
本轮需要将投送中心改为面对面投送流程 UI，同时不能让用户误解已经支持真实局域网搜索和两机传输。
### 原因分析
旧 UI 以调试 JSON 复制/粘贴为主，主流程不像真实产品；但当前工程只具备投送包编码、解码、导入预览与合并能力，真实 LAN 发现和传输层尚未实现。
### 处理过程
1. 在 `Index.ets` 内新增发送端会话状态、接收端搜索状态和高级调试入口折叠状态。
2. 发送页保留“选中便签 / 全部便签”，增加创建会话预览、确认码、倒计时、投送摘要、等待接收、完成/失败状态。
3. 接收页增加未搜索、搜索中、未发现和发现列表预览四态；发现列表明确标注“演示占位，真实发现待接入”。
4. 将粘贴 JSON 导入移动到“高级 / 调试导入”，并保留先预览再确认合并的导入链路。
5. 执行文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。
6. 第一次执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp` 在 124 秒超时；第二次延长超时后重新执行。
### 结果
第二次 `assembleApp` 构建成功；输出仅包含既有 deprecated API、Preferences 异常处理提示、混淆提示和未配置签名警告。
### 验证
已执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。
### 后续建议
在 DevEco Studio 中手动验证投送中心弹窗布局，重点检查小屏下四步状态、接收搜索态和高级导入区是否可读。

## 当前记录

- 暂无。

## 2026-06-02 02:29 - 首页搜索功能接入
### 现象
首页仅展示全部便签，无法按关键词快速定位内容。
### 原因分析
列表数据源直接使用 `memos`，缺少基于用户输入的过滤状态与过滤函数。
### 处理过程
1. 在 `Index.ets` 增加 `searchKeyword` 状态。
2. 在标题说明下、列表上方增加 `TextInput` 搜索框并实时更新关键词。
3. 新增 `getFilteredMemos()` 与 `buildMemoSearchText()`，按标题 + `bodyPreview` + 文本块内容做不区分大小写匹配。
4. 将 `ForEach` 数据源替换为 `filteredMemos`，空结果时显示无匹配提示。
### 结果
已实现实时搜索：输入为空显示全部，输入关键词按标题与正文内容过滤。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
补充一次手动回归：新增便签后立即搜索、删除后搜索结果同步、不同大小写关键词匹配。

## 2026-06-02 02:35 - Index.ets 编译报错修复
### 现象
Build 报错：
1. `Index.ets:258 Unexpected token`
2. `Index.ets:71 @Entry 组件 build 只能有一个根容器`
### 原因分析
在 `build()` 中加入了局部变量声明（`const filteredMemos = ...`），破坏了 ArkTS `@Entry` 组件对 build UI DSL 的约束，导致解析与根容器校验异常。
### 处理过程
1. 删除 `build()` 内的局部变量声明。
2. 将列表渲染改为 `ForEach(this.getFilteredMemos(), ...)`。
3. 将空态判断改为 `if (this.getFilteredMemos().length === 0)`。
4. 复查 `Index.ets` 引号与括号匹配，未发现额外语法异常。
### 结果
搜索功能保留，且所有搜索相关 UI 与渲染逻辑都在原有 `build()` 根容器内部。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
先重新 Build；若仍报行号偏移错误，清理构建缓存后再次编译确认。

## 2026-06-02 02:43 - 快捷便签入口改造
### 现象
首页“新建便签”走的是首页内弹窗流程，不是直达编辑页的新建路径。
### 原因分析
`Index.ets` 的 `startNewMemo()` 仅切换 `showNewMemoForm`，未调用编辑页路由。
### 处理过程
1. 将 `startNewMemo()` 改为异步路由跳转。
2. 使用 `router.pushUrl({ url: 'pages/EditMemo' })` 且不传 `memoId`，触发编辑页空白新建分支。
3. 增加跳转失败日志，保证异常可追踪。
### 结果
底部按钮已成为快捷新建入口：点击即进入新建页，且进入状态为新建而非编辑既有便签。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
回归验证“输入内容后返回首页”场景，确认新便签按现有自动保存机制正常出现在列表。

## 2026-06-02 02:50 - 置顶便签功能实现
### 现象
首页便签缺少“固定/置顶”能力，重要便签无法长期保持在列表顶部。
### 原因分析
`Memo` 数据模型中没有置顶字段，首页渲染也没有置顶入口和优先排序逻辑。
### 处理过程
1. 在 `Memo` 接口新增 `isPinned?: boolean`。
2. 首页卡片新增“置顶/取消置顶”按钮与“置顶”标签。
3. 新增 `togglePinned(id)`，切换后立即更新 `memos` 并同步 `AppStorage.SetOrCreate('memoList', updatedList)`。
4. 在 `getFilteredMemos()` 中先按关键词过滤，再按置顶分组拼接（置顶组在前，组内保持原有顺序）。
### 结果
已实现即时置顶排序：置顶后上移到顶部，取消置顶后回到普通区域；搜索功能和快捷便签入口保留可用。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
若需跨重启保留置顶状态，后续在置顶切换处补充 `saveMemos()` 持久化调用。

## 2026-06-02 02:55 - 置顶功能编译错误修复
### 现象
Build 报错：
1. `arkts-no-spread`（对象 spread）
2. `ClickEvent` 无 `stopPropagation`
### 原因分析
`togglePinned()` 使用了 `{ ...memo }` 对象展开；置顶按钮点击中调用了 `event.stopPropagation()`，均不符合 ArkTS/ArkUI 约束。
### 处理过程
1. 在 `togglePinned()` 中改为手动构造 `Memo`：`id/title/bodyPreview/updatedAt/isPinned/tag/blocks` 全字段显式赋值。
2. 删除置顶按钮 `stopPropagation()` 相关代码。
3. 为避免按钮点击触发卡片跳转，移除卡片整体 `.onClick`，改为卡片内独立 `Open` 按钮进入编辑页。
### 结果
两处报错对应代码已替换为 ArkTS 兼容写法，置顶/取消置顶功能保留。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
执行 Build 后回归点按路径：置顶按钮只切换置顶，Open 按钮才跳转编辑。

## 2026-06-02 12:42 - 首页 App 内磁吸悬浮便签入口
### 现象
本轮需要在首页增加一个悬浮在内容层之上的便签入口，点击后展示当前第一条置顶便签，同时尽量具备拖动与边缘吸附能力。
### 原因分析
首页现有根容器已经是 `Stack()`，适合直接保留第一层原始页面内容，在第二层叠加悬浮组件；这样可以避免改动搜索、快捷便签、置顶排序和存储逻辑。
另外，用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 处理过程
1. 在 `Index.ets` 新增悬浮状态：展开/收起、当前位置、视口尺寸、拖动起点。
2. 保持 `build()` 单根 `Stack()` 结构不变，在原有 `Column` 内容上方追加 `buildFloatingPinnedMemo()`。
3. 悬浮入口默认显示“便签”，点击后展开卡片并展示 `memos` 中当前第一条 `isPinned === true` 的便签标题和摘要。
4. 无置顶便签时显示“暂无置顶便签”和提示文案，不修改既有置顶逻辑本身。
5. 通过 `PanGesture` 实现拖动，结合 `onAreaChange` 记录页面宽高；松手后按中心点吸附到左侧或右侧边缘。
6. 未引入第三方依赖，未使用 `stopPropagation`，未使用对象 spread，未改搜索、快捷便签和存储实现。
### 结果
首页已具备 App 内悬浮便签入口，且不会挤压原有便签列表布局；交互上支持点击展开与拖动吸边。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build；若手势 API 在当前 API 版本上存在差异，再将拖动吸附降级为固定右上角悬浮按钮并保留展开能力。

## 2026-06-02 12:50 - 磁吸悬浮便签点击跳转与拖动范围修复
### 现象
1. 悬浮便签展开后只能看置顶内容摘要，点击不能进入详情/编辑页。
2. 悬浮便签只能在页面中间一块区域拖动，顶部和底部可达范围明显不足。
### 原因分析
1. 悬浮卡片点击逻辑只负责展开/收起，没有复用首页已有的 `openMemo(memoId)` 跳转。
2. 拖动边界里 `clampFloatingY()` 的最小值写死为 `96`，最大值还额外预留了较大底部空间，导致 Y 轴可移动区被压缩在页面中部。
3. 虽然悬浮组件已经写在首页根 `Stack()` 内，但这次进一步包进全屏第二层 `Stack`，明确让位置计算相对于整页可视区，而不是视觉上更像局部内容区。
4. 拖动结束后如果仍触发点击，会让交互误判，所以补了拖动与点击区分。
### 处理过程
1. 保持首页 `build()` 单根容器不变，在最外层 `Stack` 第二层加入全屏 `Stack` 容器承载悬浮卡片。
2. 新增 `floatingWasDragged` 状态，在 `PanGesture` 中记录是否发生过实际拖动，避免拖动后误触发点击。
3. 新增 `handleFloatingMemoTap()`：收起态点击继续展开；展开态且存在置顶便签时，直接复用 `openMemo(pinnedMemo.id)` 跳转到 `EditMemo`；无置顶便签时不跳转。
4. 将 Y 轴边界从 `96 ~ (viewportHeight - height - 24)` 放宽到 `12 ~ (viewportHeight - height - 12)`，让悬浮卡片可拖到页面更靠近顶部和底部的位置。
### 结果
悬浮卡片现在支持点击进入当前展示的置顶便签详情/编辑页，且拖动范围改为整页可视区域，覆盖标题区、搜索区、列表区与底部按钮上方区域。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
在 DevEco Studio 重新执行 Build + Run，重点回归：展开态点击跳转、拖动到顶部/底部后的吸边位置、以及拖动后不误触发跳转。

## 2026-06-02 12:57 - 修复悬浮层拦截底层按钮点击
### 现象
实现磁吸悬浮便签后，首页底层 `Pin`、`Open`、`New Note` 按钮全部失灵。
### 原因分析
1. 首页根 `Stack()` 第二层额外包了一层 `width('100%').height('100%')` 的全屏 `Stack` 作为悬浮层容器。
2. 这层覆盖容器虽然主要用于定位，但它本身覆盖全屏，空白区域也可能参与命中测试，导致触摸事件被拦截，底层按钮收不到点击。
3. 真正需要响应事件的只有蓝色悬浮卡片，不是整层全屏容器。
### 处理过程
1. 保持 `build()` 单根容器不变。
2. 删除承载悬浮卡片的全屏第二层 `Stack` 包裹。
3. 直接在首页根 `Stack` 中渲染 `this.buildFloatingPinnedMemo()`，让只有真实蓝色悬浮卡片参与点击/拖动命中。
4. 未改搜索、置顶、快捷便签、存储和详情页逻辑。
### 结果
空白覆盖层已移除，底层按钮理论上应恢复点击；悬浮卡片自身的点击进入详情与拖动/磁吸逻辑保留。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，实际回归 `Pin`、`Open`、`New Note` 是否恢复点击，并确认悬浮卡片仍可拖动和点击跳转。

## 2026-06-02 13:10 - 首页 Floral 轻量便签风格优化
### 现象
1. 首页仍保留英文标题、搜索占位符和操作按钮文案。
2. 便签卡片、按钮和置顶标识层级较平，缺少课堂展示需要的轻量纸张感。
3. 悬浮便签尺寸偏大，默认位置更容易压到标题区和搜索区。
### 原因分析
1. 现有首页样式主要是基础卡片布局，文案和视觉细节没有统一到中文移动端展示。
2. 卡片背景、边框、阴影和按钮样式缺少明显的“便签纸”层次。
3. 悬浮便签宽高与默认 Y 值偏保守，没有围绕首页头部留出足够呼吸空间。
4. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 处理过程
1. 保持 `build()` 单根容器与全部业务方法不变，仅重写首页展示层结构和样式。
2. 将首页文案更新为“灵感便签”“记录灵感，整理思绪。”和“搜索标题或内容”。
3. 将按钮文案更新为“置顶 / 取消置顶”“打开”“快速记录”，不改原有点击行为。
4. 为首页增加柔和纸张配色字段，统一卡片、标签、按钮、悬浮便签的浅暖色风格，并在深色模式下提供对应配色。
5. 优化卡片圆角、边框、阴影、内边距和信息层级；将置顶标签调整为“📌 置顶”。
6. 缩小悬浮便签尺寸并提高默认起始 Y 值，让它更偏右侧中下区域，减少对标题区和搜索框的遮挡。
### 结果
首页视觉已切换到更适合课堂展示的中文轻量便签风格；搜索、快捷便签、置顶、悬浮交互和存储逻辑保持不变。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
在 DevEco Studio 重新执行 Build + Run，重点回归首页中文显示、按钮排版、悬浮便签遮挡情况，以及深浅色模式下的可读性。

## 2026-06-02 13:28 - 快速记录编辑页 UI 统一到花笺风格
### 现象
1. 首页已经是浅暖色花笺风格，但 `EditMemo.ets` 仍是原始英文编辑器界面。
2. 顶部按钮、输入框和正文区域样式较硬，进入“快速记录”后与首页视觉脱节。
3. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 编辑页仍沿用旧的 `EditorTheme` 配色与英文占位符，未复用首页的浅米色、柔和边框和强调色方向。
2. 顶部 5 个按钮单排布局更像默认工具栏，不像移动端便签页。
3. 正文区只是普通输入框，没有“便签纸”层次，和首页卡片纸张感不一致。
### 处理过程
1. 仅在 `entry/src/main/ets/pages/EditMemo.ets` 内扩展主题字段，改为与首页接近的浅米色背景、暖白卡片、珊瑚色主按钮和柔和蓝色次强调色。
2. 保持 `build()` 单根容器，新增头部说明卡片，并把工具栏改为两行按钮布局：`返回 / 撤销 / 重做` 与 `+ / 插入`。
3. 将标题输入框、标签输入框包装为独立圆角卡片，统一圆角、边框和阴影风格。
4. 将正文区重做为大圆角便签纸容器，正文 `TextArea` 使用更柔和的纸张底色、较轻边框和更高可读性行高，不压缩输入高度。
5. 完成指定中文文案替换：`Back / Undo / Redo / Insert / Memo Title / Tag (optional) / Memo Content / Autosave enabled / Capture your thoughts...`，并顺手将保存状态与删除确认弹窗一并中文化。
6. 未改新建便签、编辑已有便签、自动保存、撤销重做、图片插入、存储等业务逻辑；未引入第三方依赖；未使用对象 spread 和 `stopPropagation`。
### 结果
编辑页已切换为与首页一致的花笺风格，视觉上更接近“快速记录”而非默认表单，同时原有业务逻辑路径保持不变。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，手动检查中文字体显示、键盘弹起后的输入区域高度、插图块显示和撤销/重做按钮状态切换是否正常。

## 2026-06-02 13:40 - 首页便签卡片交互改为主体点击打开 + 右上角图钉置顶
### 现象
1. 首页卡片底部单独存在 `打开` 按钮，占用一整行空间，显得重复。
2. 便签卡片本身缺少“点卡片进入详情”的直接交互。
3. `置顶` 按钮放在卡片底部，状态入口不够直观，也容易挤压卡片内容区。
4. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 现有卡片结构把操作集中在底部 `Row`，导致卡片主体只负责展示，不负责打开详情。
2. 由于不能使用 `stopPropagation`，如果简单把图钉按钮塞进卡片点击区域，容易出现点图钉时误触打开详情。
3. 当前首页已经是花笺风格，适合把置顶入口收纳到右上角小图钉位置，减少底部按钮负担。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 中便签列表渲染区，不改 `MemoModel`、`EditMemo`、存储与悬浮便签逻辑。
2. 将单张便签卡片从普通 `Column` 调整为 `Stack({ alignContent: Alignment.TopEnd })`。
3. 把原底部 `置顶` / `打开` 按钮行整体移除。
4. 将卡片主体 `Column` 绑定 `.onClick(() => { this.openMemo(memo.id); })`，实现点击卡片主体直接进入详情/编辑页。
5. 在 `Stack` 右上角新增独立图钉按钮：未置顶显示 `○`，已置顶显示 `📌`，并根据状态切换背景与文字颜色。
6. 图钉按钮作为独立覆盖点击区，不放到需要打开详情的主体点击链路里，因此不依赖 `stopPropagation`；点击图钉只触发 `togglePinned(memo.id)`。
7. 保留 `getFilteredMemos()` 的置顶优先排序与搜索过滤逻辑，保留 `startNewMemo()` 和磁吸悬浮便签相关方法不变。
### 结果
首页卡片现在符合“点卡片打开、点右上角图钉置顶”的直觉交互；底部按钮区已被移除，卡片更紧凑，且搜索、快速记录、置顶排序、磁吸悬浮便签和存储逻辑保持不变。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，重点回归：图钉点击是否只切换置顶、卡片主体点击是否稳定进入详情、长按删除是否仍可用，以及悬浮便签是否仍正确展示首条置顶内容。

## 2026-06-02 14:02 - 首页图钉状态强化与 EditMemo 轻工具栏整理
### 现象
1. 首页右上角图钉虽然可以切换置顶，但已置顶/未置顶的状态差异不够明显，用户不容易一眼判断。
2. `EditMemo.ets` 已经中文化，但顶部按钮尺寸、视觉层级和排列方式仍偏散，不够像移动端文档/便签类应用的轻工具栏。
3. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 首页图钉按钮此前主要依赖字符差异和轻微底色变化，缺少足够强的高亮反馈。
2. 编辑页工具区是两排不同规格按钮的拼接，按钮尺寸和视觉主次不够统一。
3. 在不修改业务逻辑前提下，最合适的方式是只重写展示层样式和按钮排布。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 和 `entry/src/main/ets/pages/EditMemo.ets`，不改 `MemoModel`、搜索、置顶排序、磁吸悬浮便签和存储逻辑。
2. 首页图钉按钮改为：未置顶显示 `📍`，使用浅色底 + 细边框 + 深灰图标；已置顶显示 `📌`，使用强调色高亮底 + 白色图标 + 阴影，提升状态辨识度。
3. `EditMemo.ets` 保留全部现有编辑能力，但重整头部为“标题说明 + 自动保存状态”卡片，并把工具栏整理为两行、六个统一高度的轻量按钮。
4. 工具栏按钮改为更接近移动端文档类应用的风格：`← / ↶ / ↷ / ＋ / ＋ 插入 / ✓ 完成`，其中“完成”为主强调按钮，复用现有 `navigateBack()` 路径，不改保存逻辑。
5. 标题、标签、正文卡片和便签纸区域继续保留浅米色花笺风格，不引入第三方依赖，不使用对象 spread，不使用 `stopPropagation`，`build()` 仍保持单根容器。
### 结果
首页置顶状态现在有更强的视觉反馈；`EditMemo` 顶部工具栏更整齐、按钮触达面积更统一，整体更接近移动端便签/文档应用，同时核心业务逻辑保持不变。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，重点回归：首页图钉状态切换是否清晰、编辑页 `✓ 完成` 是否按预期返回并触发原有保存流程、以及深浅色模式下按钮文字对比度是否足够。

## 2026-06-02 14:10 - 首页未置顶圆钮填充修正与编辑页插入按钮文案区分
### 现象
1. 首页右上角未置顶按钮虽然已经独立出来，但当前仍偏浅、偏空心，状态不够明确。
2. 编辑页工具栏里存在两个 `+` 相关按钮，用户难以一眼区分哪个是新增段落、哪个是插入图片。
3. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 未置顶按钮此前主要依赖浅底色与图标差异，缺少“灰色填充圆钮”这种更直接的视觉信号。
2. 编辑页按钮功能本身已分开，但文案仍然不够语义化，导致认知成本偏高。
3. 这类问题适合只做最小样式和文案修正，不需要改动任何业务方法。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 和 `entry/src/main/ets/pages/EditMemo.ets`，不改搜索、置顶排序、磁吸悬浮便签、自动保存、插图和存储逻辑。
2. 首页图钉按钮保持圆形与原有点击逻辑不变，只调整视觉：
   未置顶态改为浅灰填充圆钮 `#E2DED8`，图标色改为更深的灰色；
   已置顶态继续保持强调色高亮与白色图标。
3. 编辑页中原本负责新增文本块的按钮，按原有 `handleInsertTextBlock()` 逻辑改名为 `+ 段落`。
4. 编辑页中原本负责插入图片的按钮，按原有 `handleInsertPhoto()` 逻辑改名为 `+ 图片`。
5. 所有按钮原有 `onClick` 逻辑保持不变，未使用对象 spread，未使用 `stopPropagation`，未做大规模结构调整。
### 结果
首页未置顶状态现在更像明确的灰色填充圆钮；编辑页两个 `+` 按钮已经形成清晰语义区分，用户能直接识别“新增段落”和“插入图片”。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，重点回归：首页图钉状态在不同背景上的识别度，以及编辑页 `+ 段落 / + 图片` 在小屏设备上的文案是否会被压缩。

## 2026-06-02 14:16 - 首页置顶入口去图标化，改为纯几何状态圆钮
### 现象
1. 首页右上角置顶入口里的图钉字符显示效果很差，看起来像破损图标，不适合课堂展示。
2. 用户要求保留右上角圆钮交互，但不要再使用任何图钉字符、文字或复杂符号。
3. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 字符图标受字体与编码显示影响较大，在当前环境下容易出现观感异常。
2. 这个入口本质上只需要表达“未置顶 / 已置顶”两种状态，用纯几何形态更稳定，也更适合当前花笺风格。
3. 在不使用 `stopPropagation` 的前提下，继续保留独立点击区即可，不需要改任何业务逻辑。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 中卡片右上角置顶入口，不改 `EditMemo.ets`、搜索、排序、悬浮便签和存储逻辑。
2. 将原先带图钉字符的 `Button` 替换为 `Stack({ alignContent: Alignment.Center })`。
3. 外层使用固定 `40x40` 的浅色圆钮，带轻微描边与阴影，保持点击区域充足。
4. 未置顶时只显示外层浅色圆钮，不显示任何字符或文字。
5. 已置顶时在圆钮中心显示一个较小的深灰实心圆点，形成明确但克制的状态差异。
6. `.onClick(() => { this.togglePinned(memo.id); })` 保持不变，因此只切换置顶状态，不会触发卡片打开。
### 结果
首页右上角置顶入口已从“图钉字符按钮”改为“纯几何圆钮状态按钮”；未置顶和已置顶通过是否出现中心灰色实心圆点来区分，视觉更稳定，也不会再出现破损图标问题。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，重点检查圆钮在深浅色模式、不同屏幕密度下的显示效果，以及中心圆点在已置顶状态下是否足够清晰。

## 2026-06-02 14:22 - 首页置顶状态从“小圆点提示”修正为“整颗实心圆”
### 现象
1. 首页卡片右上角置顶入口虽然已经去掉图钉字符，但运行时未置顶和已置顶仍然都像浅色空心圆。
2. 置顶逻辑实际上已经生效，因为被置顶的便签可以出现在悬浮便签中。
3. 用户要求优先读取 `analysis/project_index.md`，但当前仓库中该文件不存在。
### 原因分析
1. 之前的几何方案只在已置顶时额外显示一个较小的中心圆点，外层圆钮本身的底色没有随状态充分拉开。
2. 在实际设备上，小圆点的对比度和存在感太弱，因此视觉上看不出“已置顶”。
3. 最直接的修复方式是让整个圆钮本身根据 `memo.isPinned === true` 切换成深灰实心态，而不是只改内层装饰。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 中卡片右上角置顶圆钮的外层样式，不改 `MemoModel`、排序、搜索、悬浮便签和存储逻辑。
2. 保留原有 `Stack` 结构与 `.onClick(() => { this.togglePinned(memo.id); })` 行为不变。
3. 将外层圆钮颜色改为条件判断：
   `memo.isPinned === true` 时使用 `backgroundColor('#6F6A60')` 和同色描边；
   否则使用 `backgroundColor('#FFFDF8')` 与 `borderColor('#E6DCCB')`。
4. 移除中心小圆点做法，避免“状态变更只靠小点提示”的弱反馈。
5. 由此形成明确的两态：
   未置顶是浅色空心圆；
   已置顶是深灰色整颗实心圆。
### 结果
首页右上角置顶入口现在能直接通过整颗圆钮的填充差异区分状态，且该差异明确基于 `memo.isPinned === true` 判断，不依赖悬浮便签或其他状态推断。
### 验证
未验证，由用户在 DevEco Studio 中验证。
### 后续建议
优先在 DevEco Studio 执行 Build + Run，重点查看首页普通列表、搜索结果列表和置顶后悬浮便签联动场景下，这个深灰实心圆是否都能稳定显示。
## 2026-06-23 15:55 - 响应式与跨设备投送补强验证
### 现象
本轮需要完成响应式、多端目标说明和跨设备投送相关补强，并按要求执行编译、Lint 和 QA 检查。
### 原因分析
当前仓库是 HarmonyOS ArkTS 工程，已有 phone/tablet/2in1 设备类型与响应式布局工具，但没有 Android、Windows、Linux、macOS、Web 对应工程或打包目标；已有投送包协议模型，但没有真实 LAN 自动发现/传输层。命令行环境也缺少 Hvigor 可执行入口。
### 处理过程
1. 加固 `MemoTransfer.ets` 的解码校验，避免空输入、错误协议、超量数据、缺字段便签、非法块和超长文本进入合并流程。
2. 新增 `PlatformTargets.ets`，集中声明当前支持与规划中的平台目标。
3. 首页投送说明接入平台目标摘要，并明确真实 LAN 传输层仍需后续接入。
4. 补充本地单元测试用例，覆盖异常投送数据和平台目标声明。
5. 尝试执行 `hvigor --version`，失败：当前环境无法识别 `hvigor` 命令。
6. 尝试执行 `.\\hvigorw.bat lint`，失败：仓库根目录不存在 `hvigorw.bat`。
### 结果
代码级补强已完成，命令行编译与 Lint 未能执行。
### 验证
未验证，由用户在 DevEco Studio 中验证。需要在 DevEco Studio 中执行 Build、Lint、手机/平板/2in1 预览或真机运行。
### 后续建议
补齐项目命令行构建入口，或在 DevEco Studio 中导出可用的 Hvigor wrapper；若要达到真正局域网跨设备直连体验，继续实现网络发现、连接、超时、重试和失败 UI，并复用现有投送包协议核心。
## 2026-06-23 17:19 - 投送中心重构与干净构建验证
### 现象
本轮需要将 JSON 粘贴式投送升级为可展示的投送中心，并验证响应式、多端边界和构建状态。
### 原因分析
当前仓库是 HarmonyOS / ArkTS 工程，不是 Flutter 工程，因此不能直接使用 `qr_flutter`、`mobile_scanner`、`share_plus`。原投送协议核心可继续复用，但 UI 需要避免普通用户直接看到 JSON；平台支持也必须明确限定为 HarmonyOS phone/tablet/2in1。
### 处理过程
1. 重构首页投送面板为「二维码投送 / 系统分享 / 接收导入 / 高级模式」。
2. 新增 `TransferQrMatrix.ets` 生成投送码矩阵，并在普通二维码投送入口隐藏原始 JSON。
3. 新增 `PlatformShare.ets` 封装系统分享，页面只负责传入上下文和投送数据。
4. 加固 `MemoTransfer.ets`，增加协议字段、便签字段、块字段校验和投送摘要。
5. 统一 `ResponsiveLayout.ets` 的断点、内容宽度和弹窗宽度。
6. 修复 `README.md`、`MemoModel.ets` 和 `LocalUnit.test.ets` 的中文编码损坏。
7. 执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat tasks`，确认项目没有独立 `lint` 任务。
8. 执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat clean` 后再执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。
### 结果
干净构建成功，`CompileArkTS`、`PackageHap`、`PackageApp` 均完成。
### 验证
已验证：命令行干净构建通过。
未验证：DevEco Preview、真机/模拟器运行、真实相机扫码、系统分享到微信/QQ/Nearby Share/邮件/Telegram 等目标应用。
### 后续建议
1. 在 DevEco Studio 执行手机、平板、2in1 的横竖屏预览和真机运行。
2. 迁移项目仍在使用的 deprecated API：`AppStorage.Has/Set/SetOrCreate`、`router.pushUrl/back/getParams`、`promptAction.showDialog`、旧 Photo Picker API 和 Preferences 上下文获取。
3. 若要真正支持 Android、Windows、Linux、macOS、Web，需要新增对应平台工程或跨端壳层。

## 2026-06-23 17:44 - 投送码文案修正验证
### 现象
投送面板和 README 中存在“二维码投送”“扫描此码即可导入”等表述，但当前 `TransferQrMatrix.ets` 生成的不是标准二维码。
### 原因分析
现有能力只能生成投送包视觉矩阵，并通过系统分享或 JSON 文本复制粘贴完成导入闭环；未接入标准二维码生成、扫码、相机或二维码库。
### 处理过程
1. 仅修改用户指定的 `README.md`、`entry/src/main/ets/pages/Index.ets`、`analysis/change_log.md`、`analysis/solve_logs.md`。
2. 将首页投送摘要从“二维码或系统分享”改为“系统分享或复制投送包”，并注明投送码仅作视觉预览。
3. 将投送模式按钮从「二维码投送」改为「投送码预览」。
4. 将“扫描此码即可导入”“刷新二维码”“扫描或分享得到的投送内容”等文案改为投送码预览、刷新投送码、粘贴完整投送内容。
5. README 投送流程改为当前可用闭环：系统分享 / 高级模式复制 / 接收端粘贴导入，并保留高级模式 JSON 调试说明。
### 结果
用户界面和 README 不再声称支持真实二维码扫码导入；当前能力边界已明确为实验性投送码视觉预览和文本投送包导入。
### 验证
已执行文本关键词检查和改动文件范围检查。已执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未在 DevEco Studio、Preview、真机或模拟器中运行验证。
### 后续建议
如需上线真实扫码导入，先接入标准二维码生成与扫码能力，再补充权限、异常处理和真机验证记录。

## 2026-06-23 17:58 - 投送中心弹窗 UI 闭环修复验证
### 现象
点击首页「投送」后，弹窗在小屏上容易只看到四个很大的模式入口，用户选择模式后不容易看出下方内容区发生了变化。
### 原因分析
原紧凑屏模式栏使用纵向 `Column` 布局，模式按钮占据过多视觉空间；下方内容直接放在滚动区里，没有独立标题和面板边界。同时弹窗默认进入投送码预览，容易让用户误以为扫码导入已经可用。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 的投送弹窗相关函数，没有改首页列表、搜索、置顶、快速记录逻辑。
2. 将 `transferMode` 默认值和 `openTransferPanel()` 默认入口改为 `share`，打开弹窗优先展示系统分享闭环。
3. 将 `buildTransferModeBar()` 固定为横向紧凑分段按钮，避免小屏展示成四个竖向大按钮。
4. 在滚动内容区顶部增加当前模式标题，并用带边框的内容面板包住四个 pane，让模式切换后的内容变化更明确。
5. 保留并复用 `buildQrTransferPane()`、`buildSharePane()`、`buildReceivePane()`、`buildAdvancedPane()`；未接入真实扫码、相机、二维码库或新依赖。
6. 将投送码说明改为“仅为视觉预览，不是标准二维码，不能扫码导入”。
### 结果
投送中心现在在同一个弹窗中提供四个紧凑模式入口和对应内容区：投送码预览显示矩阵，系统分享有「打开系统分享」按钮，接收导入有 TextArea 与「导入便签」按钮，高级模式有 JSON TextArea 与「重新生成 JSON」按钮。
### 验证
已执行文本关键词检查和模式函数检查。已执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未在 DevEco Studio、Preview、真机或模拟器中点击验证。
### 后续建议
在 DevEco Studio 中进行手机小屏和低高度窗口预览，重点验证四个模式切换是否清晰、滚动区是否能露出底部按钮，以及系统分享目标应用是否可正常弹出。

## 2026-06-27 00:33 - 统一 UI 设计系统 Token 初始化验证
### 现象
页面样式存在颜色、按钮高度、圆角和间距硬编码分散的问题，本轮要求先建立统一 token/theme，不重写页面。
### 原因分析
现有 `AppTheme.ets` 只集中管理颜色，缺少圆角、按钮高度和间距 token；页面后续接入时没有稳定的统一来源。
### 处理过程
1. 阅读 `README_DEVLOG.md`、`analysis/project_overview.md` 和 `entry/src/main/ets/common/AppTheme.ets`。
2. 在 `AppTheme.ets` 中保留 `ThemePalette` 与 `resolveTheme()` 对外接口，避免破坏现有页面引用。
3. 将浅色主题调整为暖米白背景、纸张白卡片、低饱和陶土红主色、灰棕弱文本和浅米灰边框。
4. 保留深色模式，并按同一语义提供深色背景、纸张面、弱文本、主色和边框。
5. 新增 `UI_TOKENS`，统一页面卡片圆角 20、输入框 16、小按钮 14、大按钮 18、主操作按钮 48、工具按钮 40、模式切换按钮 36、页面边距 20、卡片内边距 16、卡片间距 12。
6. 未修改业务逻辑、页面布局、投送协议、存储、路由和 Memo 数据结构。
### 结果
统一设计系统入口已建立，页面可继续使用现有 `palette()`，也可在下一轮导入 `UI_TOKENS` 替换硬编码尺寸。
### 验证
已执行主题文件文本检查与关键 token 搜索。未执行 build、Preview、真机或模拟器运行；未验证，由用户在 DevEco Studio 中验证。
### 后续建议
下一步按页面逐个接入 `UI_TOKENS`，每轮只替换一类样式 token，避免大范围重构。

## 2026-06-27 00:49 - 首页现代便签 UI 收紧验证
### 现象
首页存在排版松散、按钮尺寸不协调、置顶空圆点状态不清楚、悬浮便签默认位置遮挡列表等展示问题。
### 原因分析
首页多个 UI 细节仍使用局部硬编码样式，卡片信息层级依赖大间距和空圆点，缺少明确的现代便签应用状态表达。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 的首页展示 builder 和少量展示状态。
2. 顶部保留「灵感便签」，弱化副标题，将「投送」改为右侧小胶囊按钮。
3. 搜索框高度统一为 44，使用更轻边框，并增加聚焦时的轻微边框/阴影动画。
4. 便签卡片改为更紧凑的纸张卡片：标题、摘要、标签胶囊和右下时间分层展示。
5. 置顶入口由空圆点改为「置顶 / 已置顶」状态胶囊，已置顶使用主色高亮。
6. 快速记录按钮接入统一高度和圆角，并增加按下时的轻微缩放/透明度反馈。
7. 悬浮置顶便签缩小并初始化到右下角，底部预留快速记录按钮空间，保留点击展开、拖动和打开置顶便签行为。
8. 未修改搜索、置顶、删除、新建、投送、存储、路由、投送协议和 Memo 数据结构。
### 结果
首页视觉层级更集中，置顶状态更清晰，底部主按钮与搜索框/卡片尺寸更统一；业务行为保持原路径。
### 验证
已执行文本级检查，确认未新增对象 spread 和 `stopPropagation`。已执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
优先在小屏手机预览中回归：卡片标题长文本、标签长文本、置顶胶囊点击、长按删除、快速记录按钮点击和悬浮便签拖动/展开。

## 2026-06-27 01:06 - 编辑页现代便签 UI 收紧验证
### 现象
编辑页顶部工具按钮体量过大，标题/标签分成两个卡片导致纵向空间浪费，正文 TextArea 首屏可见空间不足。
### 原因分析
原布局把工具栏拆成两行等权重大按钮，并把标题和标签拆成独立大卡片；正文区域虽然可滚动，但首屏被上方控件挤压。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/EditMemo.ets` 的展示层和 UI 状态。
2. 顶部保留「快速记录」，将自动保存状态改为右侧弱提示，并增加轻微淡入淡出反馈。
3. 工具栏由两行大按钮改为单行轻工具条：返回、撤销、重做、+ 段落、+ 图片、完成，统一高度 40。
4. 次要按钮使用浅底/描边，完成按钮使用主色；按钮按下时有轻微 scale 和 opacity 反馈。
5. 将标题和标签输入合并到一个紧凑卡片中，标题高度 42，标签高度 38。
6. 正文 TextArea 在手机上提升到 300 高，聚焦状态改为轻描边和阴影，不再使用粗强调边框。
7. 图片块统一边距和圆角，弱化「设备图片 / 内置图片」说明文字。
8. 未修改自动保存、撤销、重做、插入段落、插入图片、删除块、存储、路由返回或 MemoModel。
### 结果
编辑页首屏空间更偏向正文输入，工具栏更轻，标题/标签区域更紧凑；原业务方法调用路径保持不变。
### 验证
已执行文本级检查，确认未新增对象 spread 和 `stopPropagation`。已执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中回归键盘弹起、撤销/重做可用态、图片选择失败回退内置图、长按删除块和完成返回后的自动保存。

## 2026-06-27 01:27 - 投送中心弹窗 UI 紧凑化验证
### 现象
投送中心四个模式按钮在小屏显示为省略号，高级模式 JSON 文本区域容易撑破卡片，弹窗整体留白偏多。
### 原因分析
原分段按钮使用「投送码预览 / 系统分享 / 接收导入 / 高级模式」长文案，按钮等分后宽度不足；内容区和滚动高度也偏大，高级 JSON TextArea 缺少明确的紧凑展示约束。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 中投送中心相关 Builder 和样式。
2. 顶部标题保留「投送中心」，摘要字体压低，关闭按钮改为小胶囊。
3. 模式切换改为紧凑 segmented control，文案改为「分享 / 导入 / 预览 / 高级」，当前模式用主色高亮。
4. 内容区继续根据 `transferMode` 切换分享、导入、预览和高级 pane，并加轻微 opacity/transition。
5. 分享模式保留说明和「打开系统分享」按钮。
6. 导入模式保留 TextArea 和「导入便签」按钮。
7. 预览模式保留投送码视觉矩阵，并明确写明不是标准二维码、不能扫码导入，本版本使用分享或粘贴导入。
8. 高级模式 JSON TextArea 限制高度为 136，使用等宽字体风格和纸张底色，避免撑破卡片，并保留「重新生成 JSON」按钮。
9. 未修改投送协议、扫码、相机、二维码库、首页列表、搜索、置顶或新建逻辑。
### 结果
投送中心更紧凑，模式按钮不再使用长文案，高级 JSON 区域被限制在固定高度内，内容切换路径更清晰。
### 验证
已执行关键词检查，确认没有“二维码投送”“扫描即可”等误导文案。已执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在手机小屏和低高度窗口中点击验证四个模式：分享按钮是否可触发系统面板、导入 TextArea 是否可输入、高级 JSON 是否内部可编辑且不撑破弹窗、预览文案是否不造成扫码误解。

## 2026-06-27 02:01 - 工具栏省略号与置顶反馈修复验证
### 现象
1. `EditMemo.ets` 顶部工具栏六个按钮在小屏被等分压缩，文字显示成「...」。
2. 首页置顶按钮虽然能切换状态和排序，但置顶成功的视觉反馈不够明显。
### 原因分析
1. 编辑页工具栏使用等权重按钮承载较长文案，小屏宽度不足时 ArkUI 按钮文字被省略。
2. 首页置顶按钮虽有「置顶 / 已置顶」文案，但尺寸、阴影、卡片内标签和状态提示仍不足以形成强反馈。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/EditMemo.ets` 和 `entry/src/main/ets/pages/Index.ets`。
2. 编辑页工具栏改为横向 `Scroll` + `Row`，每个按钮固定宽度 58、高度 40，避免被窄屏等分压缩。
3. 工具栏文案改为短中文：「返回 / 撤销 / 重做 / 段落 / 图片 / 完成」，未使用 emoji 或特殊字体图标。
4. 工具栏按钮点击仍通过原有 `handleToolbarAction()` 分发到返回、撤销、重做、插入文本块、插入图片和完成返回逻辑。
5. 首页置顶按钮增加更明显的主色填充、阴影、按压 scale/opacity 反馈。
6. 已置顶卡片标题下方额外显示轻量「已置顶」标签。
7. `togglePinned()` 保持手动构造 `Memo`，仅将反馈文案改为「已置顶 / 已取消置顶」。
8. 未修改 MemoModel、MemoTransfer、MemoStorage、路由、投送协议、搜索、排序、卡片打开或长按删除逻辑。
### 结果
编辑页工具栏不再依赖窄按钮承载长文案；首页置顶状态有按钮、标签、提示和按压动效多层反馈。
### 验证
已执行文本级检查，确认未新增对象 spread、`stopPropagation` 或 emoji。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中检查极窄屏下工具栏横向滚动是否自然、置顶按钮点击是否不会误触卡片打开，以及状态提示是否能及时显示。

## 2026-06-27 02:14 - 编辑页正文输入被清空修复验证
### 现象
在编辑页正文 TextArea 输入中文、英文或数字后，输入内容会立刻回到空白/placeholder，正文编辑功能不可用。
### 原因分析
正文 TextArea 的 `text` 来自 `ForEach(this.blocks)` 当前文本块的 `content`。原 `onTextBlockChange()` 在更新文本前先调用 `recordUndoState()`，该方法会更新撤销/重做相关状态，可能触发 UI 使用旧的空 `block.content` 重建，导致刚输入的内容被旧状态覆盖。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/EditMemo.ets`。
2. 检查 `renderTextBlock()`，确认 TextArea 使用稳定 `block.id` 调用 `onTextBlockChange(block.id, value)`。
3. 检查 `ForEach(this.blocks, ..., block.id.toString())`，确认文本块 key 稳定。
4. 检查初始化逻辑，确认默认空文本块只在 `@State` 初始值、`loadMemoFromParams()` 新建路径和恢复兜底中创建，不在 build 或输入回调中反复创建。
5. 修改 `onTextBlockChange()`：先保存旧 blocks 快照，再构造 `updatedBlocks`，立即赋值给 `this.blocks`，确保 TextArea 的真实状态源先更新为最新输入。
6. 新增 `pushUndoSnapshot(snapshot)`，让 `onTextBlockChange()` 在 `this.blocks` 更新之后再写入旧快照到撤销栈，避免撤销状态更新抢先触发旧内容重建。
7. 自动保存仍调用 `queueAutosave()`，`persistChanges()` 继续从最新 `this.blocks` 克隆并保存。
8. 未修改首页、MemoModel、MemoStorage、MemoTransfer、路由、投送、标题/标签、撤销/重做、插入段落/图片或完成返回逻辑。
### 结果
正文输入回调现在会先同步更新对应文本块的真实 `content`，再记录撤销历史和自动保存，避免输入值被旧空块覆盖。
### 验证
已执行文本级检查，确认未新增对象 spread 和 `stopPropagation`。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中按验收路径手动验证：输入 `abc123测试`、收起键盘、等待自动保存、完成返回后重新打开、插入第二段并分别输入不同内容。

## 2026-06-27 02:26 - 插入段落后正文清空修复验证
### 现象
编辑页初始正文可以输入，但点击「+ 段落」后，已有正文内容会被清空，新段落和原段落也可能继续输入不稳定。
### 原因分析
`handleInsertTextBlock()` 复用 `insertBlockAfterActive()`，并在插入前调用 `recordUndoState()`。该顺序会先更新撤销/重做状态，可能让 UI 在新段落加入前按旧 blocks 重新渲染；同时 activeBlock 插入链路不符合本轮要求的“只在当前 blocks 后追加新段落”。动态新增文本块本身的渲染 key 已经是稳定的 `block.id.toString()`，保存也已经读取 `this.blocks`。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/EditMemo.ets`。
2. 检查 `ForEach(this.blocks, ..., block.id.toString())`，确认文本块 key 使用稳定 id。
3. 检查 TextArea `onChange((value) => this.onTextBlockChange(block.id, value))`，确认每个文本块通过自己的 block id 更新内容。
4. 检查 `persistChanges()`，确认自动保存使用 `cloneMemoBlocks(this.blocks)`，即当前状态中的最新 blocks。
5. 修改 `handleInsertTextBlock()`：先保存旧 blocks 快照，再用 `Math.max(this.nextBlockId, getNextBlockId(this.blocks))` 生成唯一 id。
6. 手动构造 `updatedBlocks`：逐个 push 现有 block，最后 push 新的空文本块，不使用对象 spread，不重新初始化 blocks。
7. 将 `this.blocks` 赋为 `updatedBlocks`，更新 `nextBlockId` 和 `activeBlockId`，再调用 `pushUndoSnapshot(snapshot)` 与 `queueAutosave()`。
8. 未修改首页、MemoModel、MemoStorage、MemoTransfer、投送、标题/标签、撤销/重做、插入图片或完成返回逻辑。
### 结果
「+ 段落」现在只会在当前 blocks 末尾追加新文本块，已有段落内容保留；动态新增段落仍通过 `onTextBlockChange(block.id, value)` 独立更新。
### 验证
已执行文本级检查，确认未新增对象 spread 和 `stopPropagation`。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中手动验证：第一段输入、点击「+ 段落」、第二段输入、连续插入第三段、等待自动保存、完成返回后重新打开，确认所有段落内容都保留且互不覆盖。

## 2026-06-27 02:33 - 正文焦点自动清理导致 blocks 丢失修复验证
### 现象
上轮修复后，初始正文可以输入，但点击「+ 段落」后已有正文仍会清空，新旧段落会回到 placeholder，无法稳定输入。
### 原因分析
`renderTextBlock()` 的 TextArea `onBlur` 会调用 `cleanupInactiveEmptyTextBlocks()`；`setFocusedBlock()` 也会调用同一清理函数。点击「+ 段落」会触发当前 TextArea blur、新块 activeBlockId 变化和后续 focus，清理函数会过滤掉 inactive 的空文本块。由于插入的新段落合法地为空，且焦点变化发生在输入状态更新附近，这个自动清理会删除合法块或造成 blocks 回滚。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/EditMemo.ets`。
2. 检查 TextArea `onFocus`，确认其调用 `setFocusedBlock(block.id)`。
3. 检查 TextArea `onBlur`，确认此前会在清除 activeBlockId 后调用 `cleanupInactiveEmptyTextBlocks()`。
4. 检查 `setFocusedBlock()`，确认此前会设置 activeBlockId 后立即调用 `cleanupInactiveEmptyTextBlocks()`。
5. 检查 `cleanupInactiveEmptyTextBlocks()`，确认它会 filter 掉 inactive 且内容为空的文本块。
6. 移除 TextArea `onBlur` 中的自动清理调用，只保留 activeBlockId 清除。
7. 移除 `setFocusedBlock()` 中的自动清理调用，只保留 activeBlockId 设置。
8. 保留长按删除路径 `confirmBlockRemoval()` / `deleteBlock()`，空段落只能通过显式删除移除。
9. 未修改首页、MemoModel、MemoStorage、MemoTransfer、UI 样式、投送、标题/标签、撤销/重做、插入图片或完成返回逻辑。
### 结果
focus/blur 不再自动删除 blocks；空文本块是合法编辑状态，点击「+ 段落」后新段落可保持为空直到用户输入或显式删除。
### 验证
已执行文本级检查，确认 `cleanupInactiveEmptyTextBlocks()` 不再由 focus、blur、输入或插入段落触发。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中按验收路径验证多段输入、连续插入空段落、等待自动保存、完成返回和重新打开后的内容保留情况。

## 2026-06-27 02:41 - 正文 TextArea 受控数据源修复验证
### 现象
输入法候选/预览中可以看到输入内容，但文字真正进入正文 TextArea 后立刻回退为空，说明 TextArea 重建时仍绑定到旧的空字符串。
### 原因分析
正文 TextArea 原来使用 `TextArea({ text: block.type === 'text' ? block.content : '' })`，其中 `block` 是 `ForEach(this.blocks)` 的局部参数；`onChange` 则更新 `this.blocks` 中的新数组。显示值和更新值存在局部对象与真实状态源不一致的风险，组件重建时可能继续读取旧局部 block 的空 content。
### 处理过程
1. 搜索 `EditMemo.ets` 中所有 TextArea，确认正文 TextArea 是唯一绑定 blocks 内容的 TextArea。
2. 将正文 TextArea 的 `text` 改为 `this.getTextBlockContent(block.id)`，每次 build 都从当前 `this.blocks` 按 id 读取真实 content。
3. 将正文 TextArea 的 `onChange` 改为 `this.updateTextBlockContent(block.id, value)`。
4. `updateTextBlockContent()` 遍历当前 `this.blocks`，按 block id 只替换对应文本块，并通过 `this.blocks = updatedBlocks` 触发状态更新。
5. 保留 `ForEach(this.blocks, ..., block.id.toString())` 作为稳定 key。
6. 确认自动保存仍使用 `cloneMemoBlocks(this.blocks)`，不会从旧 memo 或 snapshot 反向覆盖编辑态 blocks。
7. 新增 `getBlocksDebugText()`，摘要格式为 `blockId:type:contentLength`。
8. 新增 blocks before/after 输出，覆盖 `loadMemoFromParams()`、`handleInsertTextBlock()`、`insertBlockAfterActive()`、`updateTextBlockContent()`、`cleanupInactiveEmptyTextBlocks()`、`deleteBlock()`、`restoreBlocksFromSnapshot()`。
9. 未修改首页、MemoModel、MemoStorage、MemoTransfer、UI 样式或投送功能。
### 结果
正文 TextArea 的显示值和输入更新现在都指向 `this.blocks` 这一唯一编辑态数据源；如果仍有函数覆盖内容，可通过 `[EditMemo] 函数名 before=... after=...` 日志定位。
### 验证
已执行文本级检查，确认未新增对象 spread 和 `stopPropagation`。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
在真机或预览中输入 `第一段测试abc123`，插入第二段输入 `第二段测试def456`，等待自动保存并重新打开；如失败，查看 `[EditMemo] updateTextBlockContent` 之后是否有其它函数把同一 block 的 contentLength 改回 0。

## 2026-06-27 02:56 - 投送中心发送接收骨架与导入预览验证
### 现象
原投送中心以系统分享、粘贴导入、视觉预览和高级 JSON 为主，普通用户难以理解两台设备之间应该如何完成投送；同时视觉预览不是标准二维码，不能声称扫码导入。
### 原因分析
当前项目尚未接入标准二维码生成、扫码解析、相机能力或局域网传输；继续把系统分享或 JSON 粘贴作为主流程不符合“两机扫码投送”的产品目标，也容易让用户误解未实现能力已经可用。
### 处理过程
1. 仅修改 `entry/src/main/ets/pages/Index.ets` 和 `entry/src/main/ets/common/MemoTransfer.ets`。
2. 将投送中心默认模式改为 `send`，普通分段只保留「发送 / 接收」。
3. 发送模式增加「当前便签 / 全部便签」范围选择，并显示便签数、文本块数、图片块数和字符数。
4. 发送模式在存在图片块时提示：当前扫码投送优先支持标题、标签和文本内容，图片跨设备传输需后续局域网能力。
5. 「生成投送码」按钮置灰，并明确写明标准二维码生成能力待接入，不显示不可扫码的假二维码。
6. 接收模式增加「扫一扫接收」置灰按钮，并明确扫码能力待接入。
7. 保留粘贴导入为备用入口，但改为「预览导入」先解析，不再直接合并。
8. 新增 `TransferImportPreview` 与 `previewTransferImport()`，计算将新增几条便签、更新几条便签、包含多少图片块。
9. 用户点击「确认导入」后才调用 `mergeReceivedMemos()` 合并数据。
10. 调试 JSON 收纳为发送页中的「调试 JSON」入口，不作为普通用户主入口。
11. 未修改首页搜索、置顶、快速记录、MemoStorage、EditMemo 或投送协议格式。
### 结果
投送中心已形成面向用户的发送/接收骨架；未实现的二维码和扫码能力都明确显示待接入；备用粘贴导入具备预览与确认步骤，避免一粘贴就合并。
### 验证
已执行关键词检查，确认没有“系统分享”主流程、“投送码预览”“二维码投送”“扫描即可”“扫码即可”等误导文案。已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、未配置签名等警告。未执行 DevEco Preview、真机或模拟器运行。
### 后续建议
下一步若要真正扫码投送，应接入标准二维码生成、扫码解析和相机权限；若要支持图片跨设备传输，应设计局域网或近场传输层，并继续复用现有投送包协议和导入预览。

## 2026-06-28 13:51 - 投送中心标准二维码生成验证
### 现象
投送中心发送端需要生成可被普通扫码器识别的标准二维码，不能继续使用旧的视觉矩阵伪二维码。
### 原因分析
项目依赖清单中没有第三方二维码库，但 `Index.ets` 当前可使用 ArkUI 标准 `QRCode` 组件。旧 `TransferQrMatrix.ets` 只按 payload hash 填充布尔矩阵，不是二维码编码算法，必须删除或废弃。
### 处理过程
1. 检查 `oh-package.json5` 和 `entry/oh-package.json5`，确认未引入二维码依赖。
2. 检查投送中心代码，确认发送端已有 ArkUI `QRCode(this.transferPayload)` 组件入口。
3. 新增 `TransferQrCode.ets`，集中准备二维码 payload：复用 `MemoTransfer.encodeTransferPackage()` 输出投送 JSON，剔除图片块并统计图片数量。
4. 设置安全阈值 `1200` 字符，超过阈值时阻止生成并提示“内容过大，请减少投送范围或使用后续局域网投送”。
5. 首页生成二维码前调用 `prepareTransferQrPayload()`，只在 `canGenerate` 为 true 时展示 `QRCode`。
6. 删除 `TransferQrMatrix.ets`，避免伪矩阵入口继续存在。
7. 未修改 `EditMemo.ets`、`MemoStorage`，未接入扫码相机、局域网或新依赖。
### 结果
发送端二维码由 ArkUI 标准 `QRCode` 组件生成，内容为当前投送协议 JSON；图片块不会携带本机 URI 进入扫码投送 payload。
### 验证
已按要求仅执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。未执行 DevEco Preview、真机、模拟器或普通扫码器实扫验证。
### 后续建议
在真机上用普通扫码器实扫小 payload 二维码，确认读取结果是完整投送 JSON；后续再接入接收端扫码解析和图片/局域网投送能力。

## 2026-06-28 13:59 - 投送中心接收端扫码入口接入验证
### 现象
发送端已能展示标准二维码，但接收端“扫一扫接收”仍不可用，无法形成两台设备扫码导入闭环。
### 原因分析
本机 DevEco SDK 中存在 HMS ScanKit：`@kit.ScanKit` 暴露 `scanBarcode.startScanForResult(context, options)`，并支持 `scanCore.ScanType.QR_CODE`；扫码相机需要声明并请求 `ohos.permission.CAMERA`。现有投送导入已有 `decodeTransferPackage()`、`previewTransferImport()` 与 `mergeReceivedMemos()`，可以复用，避免扫码后直接合并。
### 处理过程
1. 新增 `TransferScanner.ets`，封装相机权限请求和 ScanKit QR 扫描。
2. 在 `module.json5` 增加 `ohos.permission.CAMERA` 权限声明，并在 `string.json` 增加权限原因文案。
3. 将接收面板“扫一扫接收”从禁用按钮改为可点击按钮，点击后进入扫码流程。
4. 扫码成功后把原始内容写入 `transferImportText`，再交给 `decodeTransferPackage()` 校验。
5. 解码成功后只写入 `pendingImportMemos` 和 `pendingImportPreview`，显示新增/更新/图片块数量，不直接合并。
6. 用户点击“确认导入”后才调用既有 `mergeReceivedMemos()` 合并。
7. 增加失败提示：无相机权限、扫码取消、不是 InstantNote 投送码、协议版本不兼容、内容过大。
8. 保留手动粘贴导入作为备用方案。
### 结果
代码层已接入扫码入口和导入预览闭环；未修改 `EditMemo.ets`、`MemoStorage`、`MemoTransfer` 协议结构，未接入局域网，未引入新三方依赖，未伪造扫码成功。
### 验证
已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建失败。失败原因为 `TransferScanner.ets` 使用的 `Permissions` 类型名在当前编译上下文不可见。已将权限请求改为 `context.requestPermissionsFromUser([CAMERA_PERMISSION], requestCode)`，移除 `Permissions` 类型依赖。受“最多执行一次 assembleApp”限制，未二次构建验证；未执行 DevEco Preview、真机、模拟器或实际扫码验证。
### 后续建议
用户在 DevEco Studio 中重新 Build；若仍有 ScanKit syscap 或签名相关问题，优先确认目标设备是否支持 `SystemCapability.Multimedia.Scan.ScanBarcode`，以及 HMS ScanKit 在当前工程目标中的可用性。

## 2026-06-28 14:08 - 停止扫码接入后的构建修复
### 现象
用户要求停止扫码接入，修复第三步导致的 build 失败，并将投送中心方向调整为面对面局域网投送。当前不再继续尝试扫码 API，也不实现真实局域网通信。
### 原因分析
上轮扫码封装引入了 ScanKit、相机权限请求和页面扫码调用，和当前路线不一致。继续保留这些代码会增加编译风险，也会让普通用户误以为扫码接收已经可用。
### 处理过程
1. 删除 `TransferScanner.ets`，移除 ScanKit 与权限请求封装。
2. 从 `Index.ets` 移除 `scanTransferQrCode` 导入、扫码状态、`scanAndPreviewImport()` 方法和扫码按钮。
3. 从 `module.json5` 移除 `ohos.permission.CAMERA` 权限声明。
4. 发送页改为“面对面投送”，说明当前已准备投送包和导入预览，局域网发现与传输层待接入。
5. 接收页改为“搜索附近设备”待接入按钮，并保留粘贴投送内容的备用验证路径。
6. 调试 JSON 保留为小入口，不作为默认主流程。
7. README 更新为当前已完成/未完成/下一步建议。
### 结果
投送中心不再暴露不可用的扫码主流程；页面方向已明确转为面对面局域网投送；手动粘贴导入仍可用于验证协议和导入预览。
### 验证
已执行文本检查，确认 `Index.ets` 与 `module.json5` 中不再出现 `context.requestPermissionsFromUser`、ScanKit、`TransferScanner`、相机权限、`any` 或 `unknown`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建失败，报错为 `Index.ets` 中残留 `isQrPayloadTooLarge()` 引用已移除的 `prepareTransferQrPayload()`。已删除该残留方法；受“最多执行一次 assembleApp”限制，未二次构建验证。
### 后续建议
重新执行 Build 验证残留引用已清除；若通过，再进入局域网面对面投送设计，不再回到扫码路线。

## 2026-06-28 14:23 - 局域网面对面投送方案整理
### 现象
投送中心方向已经从扫码改为面对面局域网投送，但还缺少明确的用户流程、技术分层和实施阶段文档。
### 原因分析
面对面投送需要先定义会话、发现、传输和导入边界。如果直接写代码，容易再次混入未确认 API 或伪实现。
### 处理过程
1. 新增 `analysis/transfer_lan_design.md`。
2. 文档定义发送端、接收端和导入预览流程。
3. 文档拆分 `MemoTransfer` 协议层、会话层、局域网发现层、数据传输层和导入合并层。
4. 文档明确会话字段：`sessionId`、6 位确认码、设备名、过期时间和 token。
5. 文档约定第一阶段只传标题、标签和文本块，图片块暂不传输或标记为不支持。
6. 文档列出失败处理和四阶段实现计划。
### 结果
局域网面对面投送路线已有独立设计文档，可作为后续实现依据。
### 验证
未执行 build；本轮只新增文档和日志，未修改 ArkTS 业务代码。
### 后续建议
后续实现应严格按阶段推进：先 UI 和会话状态，再确认局域网发现 API，最后接入文本投送和图片投送。

## 2026-06-28 14:37 - 备用 JSON 投送闭环补齐
### 现象
面对面局域网投送尚未实现时，用户仍需要一个可验证的两端投送路径；原“调试 JSON”入口可以看到 JSON，但接收端预览信息不够完整，也缺少取消导入入口。
### 原因分析
当前最稳妥的验证路径是复用 `MemoTransfer.encodeTransferPackage()` 和 `decodeTransferPackage()`，让发送端展示完整 JSON，接收端粘贴后先预览，再确认合并。剪贴板能力未确认，因此不接 API，只保留可选中文本框。
### 处理过程
1. 在发送页“调试 JSON”按钮下增加说明，明确可长按复制完整投送包。
2. 将调试 JSON 文本框高度调整为 220，方便查看和复制完整 JSON。
3. 接收端粘贴输入继续使用 `TextArea`，可输入完整 JSON。
4. 点击“预览导入”只调用解码和 `previewTransferImport()`，不直接合并。
5. 导入预览文案补充导入总数、新增数、更新数、图片块数量和“图片暂不支持跨设备恢复”。
6. 预览区增加“取消”和“确认导入”两个按钮。
7. 确认导入后才调用 `mergeReceivedMemos()`，随后清空输入和预览状态，并提示导入成功。
8. 非法 JSON 提示“不是有效的 InstantNote 投送内容”；协议版本不匹配提示“投送协议版本不兼容”。
### 结果
备用投送路径形成完整闭环：发送端拿到 JSON，接收端粘贴，预览后确认合并。
### 验证
已执行文本检查，确认未引入扫码、局域网、第三方依赖、`any`、`unknown`、`stopPropagation` 或对象 spread。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
下一步进行真机手动验证备用路径；通过后再进入局域网面对面投送阶段 1 的会话状态 UI。

## 2026-06-28 14:40 - 局域网面对面投送设计字段补齐
### 现象
用户要求新增局域网面对面投送设计文档，并明确会话字段、第一阶段限制和失败处理。仓库中已存在同名设计文档，但字段命名需要按本轮清单进一步补齐。
### 原因分析
后续实现会直接依赖会话字段。如果设计文档只写“确认码、设备名、过期时间”，实现时容易出现命名不统一；需要明确为 `transferCode`、`deviceName`、`createdAt`、`expiresAt` 和 `payloadSummary`。
### 处理过程
1. 保留现有 `analysis/transfer_lan_design.md`，不新建重复文档。
2. 更新用户流程，强调接收端选择设备后显示并核对 6 位确认码。
3. 将会话字段整理为 `sessionId`、`deviceName`、`transferCode`、`token`、`createdAt`、`expiresAt`、`payloadSummary`。
4. 补充第一阶段限制：只传标题、标签、文本块，不做图片跨设备传输、公网同步、扫码和蓝牙。
5. 补充失败处理：发送端取消、接收端超时、用户拒绝导入。
6. 将阶段 1 调整为“会话状态和 UI”。
### 结果
设计文档已按最新要求补齐，可以作为后续阶段 1 的实现依据。
### 验证
未执行 build；本轮只修改设计文档和日志，未修改 ArkTS 业务代码。
### 后续建议
下一步如需实现，先从纯 UI 会话状态开始，不接入真实局域网发现和传输。

## 2026-06-28 15:07 - 投送导入 id 冲突导致未新增的修复
### 现象
粘贴同一份投送 JSON 后，导入预览可能显示更新而不是新增；确认导入后本地便签被同 id 外来便签覆盖，用户看起来像“没有真正导入新便签”。
### 原因分析
`mergeReceivedMemos()` 只按 `memo.id` 查找已有便签。不同设备或默认数据很容易生成相同 id，这类 id 冲突不代表同一真实便签，按更新覆盖会造成导入结果不明显甚至覆盖本地内容。
### 处理过程
1. 保留 `decodeTransferPackage()` 校验逻辑不变。
2. 将 `previewTransferImport()` 改为短期追加策略预览：`addCount = incoming.length`，`updateCount = 0`，图片块数量仍按原逻辑统计。
3. 将 `mergeReceivedMemos()` 改为先克隆当前本地便签，再把每条 incoming 作为外来副本追加。
4. 新导入便签 id 从当前本地最大 id + 1 开始递增。
5. 新导入便签保留 title、bodyPreview、tag、blocks。
6. 新导入便签 `isPinned` 固定为 false，避免外来便签扰乱置顶区。
7. 新导入便签 `updatedAt` 使用 `Date.now() + i`，确保导入内容显示靠前。
8. 每条 incoming 的 blocks 重新分配 block id，从 1 开始递增。
### 结果
导入逻辑不再按外来 memo id 覆盖本地便签；同一份投送 JSON 多次导入也会追加为新副本。
### 验证
已执行静态检查，确认未引入 `any`、`unknown`、对象 spread 或第三方依赖。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。未执行真机手动导入验证。
### 后续建议
当前是短期策略。长期应在投送协议中增加 uuid、sourceDevice、sourceMemoId 或等价字段，用于真正跨设备合并，避免只能追加副本。

## 2026-06-28 15:21 - 投送中心 MVP 展示增强验证
### 现象
投送导入已经可以真正新增副本便签，但导入预览只显示数量摘要，用户无法确认即将导入哪些便签；同时“面对面投送 / 搜索附近设备”需要更明确标注为待接入。
### 原因分析
当前可用链路是调试 JSON、粘贴导入、预览确认。局域网发现和传输层还没有实现，如果按钮和说明不够明确，容易让用户误解为已经支持真正面对面投送。
### 处理过程
1. 发送页说明改为“局域网发现与传输层待接入；当前可通过调试 JSON 完成投送验证”。
2. 发送页禁用按钮改为“面对面投送待接入”。
3. 接收页说明改为“当前版本可通过粘贴投送内容完成导入验证；局域网搜索附近设备功能待接入”。
4. 接收页禁用按钮改为“搜索附近设备待接入”。
5. 导入预览增加待导入便签标题列表，最多显示 5 条。
6. 超过 5 条时显示“还有 n 条便签”。
7. 空标题显示“未命名便签”。
8. README 更新当前已完成、可用验证流程、尚未完成和后续规划。
### 结果
投送中心展示更清晰：真实可用的是调试 JSON / 粘贴导入 / 预览确认；面对面投送和搜索附近设备明确是后续能力。
### 验证
已执行文本检查，确认未出现“扫码即可导入”“已经支持附近设备搜索”“已经支持面对面投送”等误导文案，且未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动验证导入预览列表在 1、5、6 条便签时的显示；下一步若继续开发，先做面对面投送的会话状态 UI，不接入真实网络。

## 2026-06-28 17:09 - 投送范围“当前便签”改造验证
### 现象
发送页提供“当前便签 / 全部便签”切换，但首页没有明确当前便签上下文，用户无法知道投送目标是哪一条。
### 原因分析
原逻辑实际用首页预览 id 作为当前便签来源，容易被理解为置顶便签、第一条便签或最近编辑便签。投送范围必须显式展示和可更换，避免投送目标不透明。
### 处理过程
1. 新增 `selectedTransferMemoId` 和 `showTransferMemoPicker` 状态。
2. 将范围按钮文案从“当前便签”改为“选中便签”。
3. 打开投送中心时，如果选中 id 无效，自动选择最近更新的便签。
4. 选中便签模式显示当前选择卡片，包含标题、标签、文本块数和图片块数。
5. 增加“更换便签”按钮，在投送面板内展开便签列表。
6. 列表按 `updatedAt` 倒序、id 倒序稳定排序，点击后更新选中 id 并收起列表。
7. 新增统一的 `getTransferMemosForCurrentScope()`，调试 JSON 和摘要都通过它取数据。
8. 切换到全部便签时隐藏选择列表。
### 结果
投送范围从含糊的“当前便签”变成明确的“选中便签”；默认规则明确为最近更新便签，不使用置顶便签作为默认投送目标。
### 验证
已执行文本检查，确认发送页不再出现“当前便签”，未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归投送面板：选中便签、全部便签、调试 JSON、删除被选中便签后的默认回退。

## 2026-06-28 17:36 - 首页置顶状态与排序验证
### 现象
首页置顶操作依赖顶部短反馈提示状态，且置顶列表只做简单分组，后置顶便签可能无法排到置顶区第一位；取消置顶后也不会排到普通区第一位。
### 原因分析
原数据模型只有 `isPinned`，没有记录置顶和取消置顶发生时间；排序逻辑依赖数组原始顺序，无法表达最近一次置顶或取消置顶的优先级。
### 处理过程
1. 在 `Memo` 模型中新增可选 `pinnedAt` 和 `unpinnedAt` 字段，兼容旧数据。
2. `togglePinned` 手动构造 Memo 对象，置顶时写入 `pinnedAt`，取消置顶时写入 `unpinnedAt`。
3. 置顶操作调用现有持久化流程，但不再设置顶部“已置顶 / 已取消置顶”反馈。
4. 新增 `getMemoPinSortTime`、`getMemoNormalSortTime`、`getSortedMemos`，统一处理首页和搜索排序。
5. 置顶卡片增加背景、边框、标题字重和“已置顶”标签区分，按钮文案改为“置顶 / 取消”。
### 结果
新置顶便签按 `pinnedAt` 排在置顶区第一位；取消置顶便签按 `unpinnedAt` 排在普通区第一位；旧数据缺少新字段时回退到 `updatedAt`。
### 验证
已执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`，置顶逻辑不再设置顶部置顶反馈文字。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归首页：A 置顶、B 置顶、B 取消置顶、搜索过滤、关闭重启后的排序和卡片高亮状态。

## 2026-06-28 17:49 - 首页置顶规则稳定化验证
### 现象
置顶功能存在多处反馈来源，且置顶组和普通组排序规则不够明确；同名便签多时，用户需要通过包含标题的反馈判断本次操作对象。
### 原因分析
仅按数组原顺序或单个时间 fallback 排序，会让刚取消置顶的便签不能稳定排到普通区第一位；悬浮置顶入口和顶部反馈同时存在时，用户容易误解状态来源。
### 处理过程
1. 置顶按钮按状态显示“置顶 / 已置顶”，卡片继续通过背景、边框、标题字重和“已置顶”标签表达状态。
2. `togglePinned` 手动构造新的 Memo，置顶写入 `pinnedAt`，取消置顶写入 `unpinnedAt`，不修改正文、标题、标签和 `updatedAt`。
3. 置顶操作反馈统一为“已置顶：便签标题”或“已取消置顶：便签标题”，空标题通过 `normalizeMemoTitle` 显示为未命名便签。
4. 移除首页悬浮置顶入口渲染，避免与卡片状态和顶部操作反馈冲突。
5. 新增 `compareMemosForHome`，置顶便签按 `pinnedAt` 新到旧，未置顶便签优先按 `unpinnedAt` 新到旧，无 `unpinnedAt` 再按 `updatedAt` 新到旧。
6. `filteredMemos` 先过滤再调用统一排序，搜索结果与首页排序一致。
7. `MemoTransfer` clone 保留 `pinnedAt`、`unpinnedAt`，校验字段类型；导入合并外来便签时强制 `isPinned = false` 并清空置顶排序字段。
### 结果
置顶、取消置顶、搜索结果和导入便签的状态规则已统一；导入便签默认不置顶，不会进入置顶组。
### 验证
已执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`，且不再出现“置顶状态已更新”。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归首页：置顶 A、置顶 B、取消 B、搜索同名便签、导入便签、重启 App 后检查状态和排序保持。

## 2026-06-28 20:39 - 首页置顶状态不一致修复验证
### 现象
截图中顶部反馈显示“已置顶：化学实验准备”，但“化学实验准备”卡片仍显示“置顶”，另一条“近现代史复习”显示已置顶高亮，说明反馈和卡片渲染状态不一致。
### 原因分析
置顶状态相关逻辑分散在按钮、样式、排序和反馈中，虽然都意图读取 `isPinned`，但缺少统一判断函数和更新后目标对象校验；同名或相邻卡片场景下不易确认实际更新的 id。
### 处理过程
1. 新增 `isMemoPinned(memo)`，唯一返回 `memo.isPinned === true`。
2. 卡片按钮文案、已置顶标签、背景、边框、字重和阴影全部改用 `isMemoPinned(memo)`。
3. `togglePinned(id)` 按 id 精确更新目标 Memo，并记录更新前后的 `isPinned`、`pinnedAt`、`unpinnedAt`。
4. 顶部反馈改为从更新后的目标 Memo 生成，标签存在时显示“标题（标签）”，空标题走 `normalizeMemoTitle`。
5. 保持 `persistMemoList` 同时更新 `this.memos`、`AppStorage` 和 Preferences。
6. 新增临时 `hilog.info` 调试日志，输出点击 id、前后状态和排序前 5 条 id/title/isPinned。
### 结果
已置顶视觉和按钮状态只能来自同一个 `isPinned === true` 判断；反馈不再使用旧对象或模糊标题生成。
### 验证
已执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`，并确认首页不再渲染悬浮置顶入口。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归“化学实验准备”置顶与取消置顶：确认按钮、卡片高亮、顶部反馈和排序移动同时变化；如仍不一致，优先查看本次新增的 `togglePinned` 日志。

## 2026-06-28 20:46 - 置顶卡片 UI 复用错位修复验证
### 现象
置顶或取消置顶后，列表顺序可能已经变化，但卡片按钮文案和已置顶样式仍显示旧状态，表现为 UI 状态与排序后的 memo 数据错位。
### 原因分析
首页列表 `ForEach` 原先使用 `memo.id` 作为 key。排序时 id 不变，ArkUI 可能复用旧卡片节点；如果置顶状态和时间字段变化没有进入 key，卡片实例可能保留旧视觉状态。
### 处理过程
1. 新增 `memoRenderKey(memo)`，key 包含 `id`、`pinned/normal`、`pinnedAt`、`unpinnedAt`。
2. 首页便签列表 `ForEach` 改用 `memoRenderKey(memo)`，不使用 index。
3. 新增 `cloneMemoForHome(memo)`。
4. `togglePinned` 中非目标 memo 也返回新 Memo 对象，确保 `this.memos` 收到新的 Memo[] 和新的对象引用。
5. 卡片按钮、背景、边框和“已置顶”标签保持直接读取 `memo.isPinned === true`，不引入局部置顶状态。
### 结果
置顶状态变化会改变对应卡片 key，排序后 ArkUI 更难复用旧视觉状态；同时列表整体对象引用也被刷新。
### 验证
已执行局部文本检查，确认 ForEach key 不使用 index，卡片 UI 直接读取 `memo.isPinned === true`，`getSortedMemos` 返回新数组，未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归首页和搜索结果：置顶、取消置顶、连续操作多张便签，确认按钮文案和卡片样式始终与排序后的 `memo.isPinned` 一致。

## 2026-06-28 21:14 - 编辑返回后首页预览旧数据修复验证
### 现象
编辑页中正文已从“做题111”改为“做题222”，但返回首页后卡片仍显示旧摘要，说明保存返回和首页预览之间存在旧数据覆盖或旧摘要优先问题。
### 原因分析
1. 编辑页 `persistChanges` 使用 `void saveMemos(updatedList)`，返回首页时 Preferences 可能尚未写完。
2. `navigateBack` 只触发 `flushPendingSave`，没有等待异步保存完成。
3. 首页 `aboutToAppear` 会再次从 Preferences 加载，可能把旧数据覆盖到当前列表。
4. 首页 `previewContent` 优先读取 `bodyPreview`，即使 blocks 已更新，也可能显示旧摘要。
### 处理过程
1. `persistChanges` 改为 `async`，更新 AppStorage 后 `await saveMemos(updatedList)`。
2. `flushPendingSave` 改为 `async`，清理自动保存计时器后再次执行 `await this.persistChanges()`。
3. `navigateBack` 改为 `async`，返回前等待 `flushPendingSave` 完成。
4. 工具栏返回和完成使用 `void this.navigateBack()`。
5. 保存已有便签时保留 `isPinned`、`pinnedAt`、`unpinnedAt`。
6. 首页增加 `memosInitialized`，只在首次初始化时读取 Preferences。
7. 首页 `previewContent` 改为优先从 blocks 生成文本摘要，纯图片块显示“图片便签”，最后才回退到 `bodyPreview` 或空白便签。
### 结果
编辑页返回前会等待最新数据保存；首页不会在返回时用旧 Preferences 覆盖当前 AppStorage；卡片摘要优先来自最新 blocks。
### 验证
已执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示和未配置签名警告。
### 后续建议
手动回归标题、标签、正文、置顶便签编辑和 App 重启持久化，确认首页摘要与编辑页内容一致。

## 2026-06-28 21:59 - 返回首页内存态刷新修复验证
### 现象
编辑页修改内容后直接返回首页仍显示旧预览，但后台清理 App 后重新进入能显示最新内容。
### 原因分析
Preferences 已持久化成功，但 Index 页面返回时仍使用旧 `this.memos`。上一轮新增的 `memosInitialized` 阻止了返回时重新加载旧 Preferences，但也没有主动从 AppStorage 同步最新内存列表。
### 处理过程
1. 将 Index 的 `aboutToAppear` 改为调用 `refreshMemosForHome()`。
2. `refreshMemosForHome()` 首次进入时从 Preferences 加载并写回 AppStorage。
3. `memosInitialized` 为 true 时，不再读取 Preferences，而是调用 `syncMemosFromAppStorage()`。
4. `syncMemosFromAppStorage()` 从 `AppStorage.Get<Memo[]>(MEMO_STORAGE_KEY)` 读取当前内存列表并赋值给 `this.memos`。
5. Index 和 EditMemo 都新增 `updateMemoAppStorage()`，已有 key 时用 `AppStorage.Set`，否则用 `SetOrCreate`。
### 结果
编辑页保存后，Index 返回时会从 AppStorage 同步最新 Memo[]；Preferences 仍用于首次启动和后台重进后的持久化恢复。
### 验证
已执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、AppStorage deprecated 提示和未配置签名警告。
### 后续建议
手动回归直接返回和杀后台重进两条路径，确认首页卡片摘要、标题、标签和置顶状态都一致。

## 2026-06-28 22:16 - 页面恢复刷新修复验证
### 现象
编辑页保存成功后，杀后台重进能看到最新内容，但直接点击完成返回首页时仍可能显示旧预览，说明 Index 缓存页面没有及时刷新当前 `this.memos`。
### 原因分析
`aboutToAppear()` 不能覆盖所有从 `router.back()` 返回缓存首页的场景；同时旧的初始化标记可能阻止返回首页时重新读取 Preferences 中的最新数据。
### 处理过程
1. 在 Index 页面增加 `onPageShow()`，每次页面恢复显示时调用 `refreshMemosForHome()`。
2. `refreshMemosForHome()` 不再因为 `memosInitialized` 为 true 就跳过刷新，而是每次优先 `await loadMemos()`。
3. 从 Preferences 读取到数据后，通过 `cloneMemoListForHome()` 克隆成新数组再赋给 `this.memos`，并同步 AppStorage。
4. AppStorage 兜底同步也改为克隆新数组，避免复用旧引用导致 UI 不刷新。
5. 确认 EditMemo 返回前保存仍保持 `await saveMemos(updatedList)`，没有退回到 `void saveMemos(...)`。
### 结果
首页在页面恢复时会重新加载最新保存的 Memo[]；卡片标题、标签和 blocks 优先生成的摘要可以随编辑页保存结果立即更新。
### 验证
已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、AppStorage deprecated 提示和未配置签名警告。
### 后续建议
手动回归从编辑页直接返回、杀后台重进、已置顶便签编辑和投送导入后列表显示，确认首页状态一致。

## 2026-06-28 22:34 - 首页返回刷新数据源修正验证
### 现象
`onPageShow()` 触发后走 `refreshMemosForHome()`，该函数优先 `await loadMemos()`，从编辑页返回时可能用旧 Preferences 覆盖刚写入 AppStorage 的新 Memo[]。
### 原因分析
返回首页属于页面间即时同步场景，应以 AppStorage 为准；Preferences 是冷启动持久化恢复数据源，不应在每次页面显示时读取并覆盖内存态。
### 处理过程
1. `aboutToAppear()` 增加 `memosInitialized` 判断，仅首次进入时调用 `loadPersistentMemosForInitialAppear()`。
2. 将原刷新函数改为 `loadPersistentMemosForInitialAppear()`，只负责首次从 Preferences 加载并同步 AppStorage。
3. `onPageShow()` 改为只调用 `syncMemosFromAppStorage()`，不再触发 `loadMemos()`。
4. 保留 `syncMemosFromAppStorage()` 克隆新数组后赋值，确保首页列表 UI 可重新渲染。
5. 确认 `previewContent()` 仍优先从 blocks 生成摘要，没有退回到优先 `bodyPreview`。
### 结果
从 EditMemo 返回首页时不会再读取 Preferences；首页直接同步 AppStorage 中最新编辑结果。冷启动仍能通过 Preferences 恢复持久化数据。
### 验证
已执行文本检查，确认 `onPageShow()` 不再走 `loadMemos()` 路径，未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、AppStorage deprecated 提示和未配置签名警告。
### 后续建议
手动回归编辑正文、标题、标签后直接返回首页，以及杀后台重进后的持久化恢复；同时确认置顶状态和投送导入新增便签仍显示正常。

## 2026-06-28 23:55 - 编辑页返回保存时序修复验证
### 现象
编辑页修改内容后直接返回首页仍可能显示旧内容，但后台清理后重新进入能显示最新内容，说明最终持久化成功，但返回首页时保存未完成或首页同步早于 AppStorage 更新。
### 原因分析
顶部按钮已走 `navigateBack()` 的等待保存链路，但系统返回键、手势返回或底部返回可能只触发 `aboutToDisappear()`。`aboutToDisappear()` 中使用 `void this.flushPendingSave()` 无法阻止页面先返回，因此首页可能同步到旧数据。
### 处理过程
1. 在 EditMemo 中新增 `onBackPress()`，拦截默认返回并调用 `void this.navigateBack()`。
2. `navigateBack()` 增加 `isNavigatingBack` 重入保护，避免连续点击返回或完成造成重复保存和重复返回。
3. `persistChanges()` 保存成功时清除 `saveFailed`，保存失败时设置 `saveFailed` 并显示“保存失败”。
4. `navigateBack()` 在 `await this.flushPendingSave()` 后检查 `saveFailed`，失败时恢复可返回状态并留在编辑页。
5. Index 的 `onPageShow()` 保持 AppStorage 为即时同步源，并增加 120ms 延迟兜底同步；不读取 Preferences。
### 结果
顶部“完成”、顶部“返回”和系统返回都统一进入保存完成后再返回的路径；首页恢复时只从 AppStorage 同步最新列表，降低保存时序导致的旧预览风险。
### 验证
已执行文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、AppStorage deprecated 提示和未配置签名警告。
### 后续建议
手动回归三种返回方式：完成、返回、系统返回/手势返回；分别修改正文、标题、标签，确认首页立即显示最新内容，重启后仍一致。

## 2026-06-29 00:50 - ForEach key 复用旧预览修复验证
### 现象
编辑页修改标题、标签或正文后返回首页，首页卡片仍显示旧内容；杀后台重新进入后显示正确，说明持久化数据正确，但首页卡片 UI 可能被复用。
### 原因分析
首页列表 ForEach 使用 `memoRenderKey(memo)` 作为 key。原 key 只包含 `memo.id`、置顶状态、`pinnedAt` 和 `unpinnedAt`，不包含编辑保存时更新的 `updatedAt`。当内容变化但置顶状态不变时，ArkUI 可能复用旧卡片 UI。
### 处理过程
1. 检查首页 ForEach，确认使用 `memoRenderKey(memo)` 而不是 index。
2. 检查 `previewContent(memo)`，确认仍优先从 blocks 生成摘要。
3. 修改 `memoRenderKey(memo)`，将 `memo.updatedAt` 加入 key。
4. 保留原有置顶相关 key 字段，避免置顶 UI 复用问题复发。
### 结果
编辑页保存后 `updatedAt` 变化会带动 ForEach key 变化，首页卡片会重新渲染并显示最新标题、标签和正文预览。
### 验证
已执行文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。已按要求执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`，构建成功；输出包含既有 deprecated API、Preferences 异常处理提示、AppStorage deprecated 提示和未配置签名警告。
### 后续建议
手动回归编辑正文、标题、标签后返回首页，以及搜索结果中的卡片预览刷新；同时确认置顶/取消置顶 UI 仍随状态正确变化。

## 2026-07-09 14:37 - 接收端 mDNS 搜索构建验证超时

### 现象

本轮将 `searchPeers(timeoutMs)` / `stopSearch()` 接入真实 mDNS 搜索后，需要确认 `mdns.DiscoveryService`、发现事件、解析服务和 TXT 记录解析代码是否可编译。

### 原因分析

主要风险来自 HarmonyOS mDNS 发现服务的 ArkTS 类型签名、`serviceFound` / `serviceLost` 回调参数、`resolveLocalService()` 返回类型，以及计时停止搜索流程。

### 处理过程

1. 实现 `searchPeers()`：创建 `_instantnote._tcp` DiscoveryService，监听发现事件，解析服务摘要，不请求 payload。
2. 实现 `stopSearch()`：停止当前搜索并让等待中的 `searchPeers()` 返回当前发现列表。
3. 执行局部文本检查，确认未引入 `any`、`unknown`、对象 spread 或 `stopPropagation`。
4. 按本轮要求最多执行一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

`assembleApp` 命令在 124 秒后超时，没有获得构建成功或失败结果；本轮未重复执行构建。代码层面未接入 UI、未修改导入逻辑、未传输便签 JSON、未伪造设备。

### 验证

未完成构建验证；未执行 DevEco Studio Preview、真机或模拟器运行。未验证，由用户在 DevEco Studio 中验证。

### 后续建议

用户在 DevEco Studio 中重新构建；如果报错，优先检查 `mdns.DiscoveryService` 事件回调和 `LocalServiceInfo.txtRecord` 类型是否与当前 SDK 定义一致。

## 2026-07-09 14:42 - 投送中心接入发现层构建失败

### 现象

本轮将投送中心发送按钮接入 `startAdvertising()` / `stopAdvertising()`，接收搜索按钮接入 `searchPeers()` 后，执行一次 `assembleApp` 构建验证失败。

### 原因分析

构建错误集中在 `entry/src/main/ets/common/TransferLanDiscovery.ets`：当前 SDK 的 `mdns.LocalServiceInfo` 类型不包含 `txtRecord` 字段，导致创建本地服务和解析发现服务时类型不匹配，并触发 ArkTS `any/unknown` 相关报错。该文件不在本轮允许修改范围内。

### 处理过程

1. 在 `Index.ets` 导入发现层接口。
2. 发送端开启会话时创建 `TransferLanSession` 并调用 `startAdvertising(session)`。
3. 发送端取消投送和关闭面板时调用停止发布 / 停止搜索。
4. 接收端搜索按钮调用 `searchPeers(3000)`，将真实返回结果保存到 `discoveredPeers`。
5. UI 展示真实发现结果或空态，搜索异常时展示友好错误。
6. 执行本轮唯一一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建失败，输出包含 `LocalServiceInfo` 不存在 `txtRecord` 字段等错误。因本轮修改范围限定为 `Index.ets` 和日志文件，未修改 `TransferLanDiscovery.ets`。本轮未接入 payload 传输，未调用发现结果导入，未展示假设备。

### 验证

未完成构建验证；未执行 DevEco Studio Preview、真机或模拟器运行。未验证，由用户在 DevEco Studio 中验证。

### 后续建议

下一轮单独修复 `TransferLanDiscovery.ets` 的 mDNS TXT 记录字段适配，并重新执行构建。

## 2026-07-09 15:11 - 接收页演示模式构建失败

### 现象

本轮在接收页未发现空态下新增“演示：模拟发现设备”入口后，执行一次 `assembleApp` 构建验证失败。

### 原因分析

构建失败仍集中在 `entry/src/main/ets/common/TransferLanDiscovery.ets`：当前 SDK 的 `mdns.LocalServiceInfo` 类型不包含 `txtRecord` 字段，导致发现层编译失败，并触发 `any/unknown` 相关报错。该问题不是本轮 `Index.ets` 演示模式新增逻辑引入的错误。

### 处理过程

1. 在 `Index.ets` 新增 `isDemoDiscoveryMode` 状态。
2. 在接收页未发现附近设备空态下新增“演示：模拟发现设备”按钮。
3. 点击演示按钮后注入一条演示 `TransferDiscoveredPeer` 数据，只包含设备名、确认码后两位、摘要字段、协议版本和兼容状态。
4. 在发现列表标题、说明和设备卡片中明确标注“演示数据，非真实局域网发现”。
5. 执行本轮唯一一次 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建失败，输出包含 `LocalServiceInfo` 不存在 `txtRecord` 字段等错误。本轮未修改 `MemoTransfer.ets`，未删除真实搜索逻辑，演示入口不调用 mDNS、不传输 payload、不导入便签、不调用 `mergeReceivedMemos()`。

### 验证

未完成构建验证；未执行 DevEco Studio Preview、真机或模拟器运行。未验证，由用户在 DevEco Studio 中验证。

### 后续建议

先修复 `TransferLanDiscovery.ets` 与当前 SDK 的 mDNS TXT 记录类型不匹配问题，再重新构建并手动检查演示模式按钮和卡片标注。

## 2026-07-09 15:30 - TransferLanDiscovery 编译错误修复验证

### 现象

构建报错集中在 `TransferLanDiscovery.ets`：ArkTS 禁止 `any/unknown`，且当前 SDK 的 `mdns.LocalServiceInfo` 不支持 `txtRecord` 字段。

### 原因分析

发现层上一版尝试通过 mDNS TXT 记录发布和解析会话摘要，但当前 SDK 类型定义中没有 `txtRecord`，因此对象字面量和属性访问都会编译失败，并引发 ArkTS 类型规则错误。

### 处理过程

1. 删除 `LocalServiceInfo` 对象中的 `txtRecord` 字段。
2. 删除 `createTxtRecord()`、TXT 字段读取和所有 `serviceInfo.txtRecord` 访问。
3. 不猜测 `txtRecord` 替代字段名。
4. `startAdvertising()` 仅使用 `serviceName`、`serviceType`、`port`。
5. `searchPeers()` 发现服务后只基于 `serviceName` / `serviceType` 生成最小 `TransferDiscoveredPeer`，摘要字段填 0。
6. 搜索确认文件中不再存在 `any`、`unknown`、`txtRecord`。
7. 执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 8 s 785 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

如后续需要展示真实摘要，先确认当前 SDK 的 mDNS 服务附加信息能力；未确认前保持最小可编译发现实现。

## 2026-07-09 16:10 - 接收页演示连接 UI 构建验证

### 现象

本轮新增接收页演示设备选择、确认码核对和演示连接结果展示，需要确认 ArkTS 编译通过且未误接入真实传输。

### 原因分析

新增 UI 状态集中在 `Index.ets`，主要风险是 `@State` 类型、Builder 渲染条件、TextInput 绑定和按钮回调引发编译错误。

### 处理过程

1. 新增 `selectedDemoPeer`、`demoTransferCodeInput`、`demoConnectionState` 状态。
2. 演示设备卡片点击后进入“核对确认码”区域。
3. 新增 6 位确认码输入框和“演示连接”按钮。
4. 点击“演示连接”只显示演示成功状态，不调用网络或导入逻辑。
5. 执行局部文本检查。
6. 执行 `D:\DevEcoStudio\tools\hvigor\bin\hvigorw.bat assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 11 s 74 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

在模拟器中手动验证演示路径，确认文案明确表达“未进行真实局域网连接”和“未传输便签内容”。

## 2026-07-09 16:25 - 投送倒计时与演示确认码构建验证

### 现象

投送中心发送页和接收页剩余时间不会实时刷新；接收页演示模式任意确认码都能显示成功，文案也容易被理解为真实连接成功。

### 原因分析

剩余时间函数使用当前时间计算，但没有定时更新的 `@State` 触发 ArkUI 重新渲染；演示连接按钮只切换成功状态，没有校验输入确认码。

### 处理过程

1. 新增 `transferClockNow` 状态和 `startTransferClock()` / `stopTransferClock()`。
2. 每秒更新 `transferClockNow`，驱动发送会话和发现设备剩余时间刷新。
3. 关闭投送中心、页面退出、取消投送时清理 timer；会话过期时停止发布并提示过期。
4. 演示设备保存完整 6 位确认码，只展示后两位。
5. 演示连接按钮增加空值、长度和完整匹配校验。
6. 执行文本检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 10 s 509 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

手动回归投送中心发送 / 接收两页，重点观察倒计时、过期状态和演示确认码错误提示。

## 2026-07-09 19:04 - 投送倒计时独立组件构建记录

### 现象

发送页倒计时通过 `sendRemainingText` 缓存字符串显示，运行时仍存在不稳定刷新问题。

### 原因分析

发送页倒计时状态链路较长，Text 没有直接依赖一个由倒计时组件自身维护的每秒刷新状态。

### 处理过程

1. 新增 `TransferCountdownText` 组件，内部维护 `@State now` 和 `timerId`。
2. 组件 `aboutToAppear()` 启动每秒刷新，`aboutToDisappear()` 清理 timer。
3. 发送页新增倒计时 info item，直接嵌入 `TransferCountdownText({ expiresAt })`。
4. 接收页 demoLocal 设备卡片也改用同一个 `TransferCountdownText`。
5. 删除 `sendRemainingText` 状态和 `updateTransferRemainingTexts()` 更新链路。
6. 执行关键词检查和一次 `assembleApp`。

### 结果

首次构建失败，错误为本轮引入：`Index.ets` 中直接读取 `this.transferSession.expiresAt` 时对象可能为 `undefined`。已改为通过 `sessionExpiresAt()` 返回安全的 `expiresAt` 值。按本轮一次构建限制，修复后未再次执行 `assembleApp`。

### 验证

已搜索确认 `Index.ets` 中没有 `any`、`unknown`、`stopPropagation`，也没有 `sendRemainingText`、`updateTransferRemainingTexts` 残留。未执行第二次构建。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

下一次构建或 DevEco Studio 验证时确认 `TransferCountdownText` 编译通过，并在发送页停留观察倒计时是否每秒刷新。

## 2026-07-09 18:51 - 真实搜索反馈与发送倒计时构建验证

### 现象

点击“搜索真实设备”后反馈不明显，搜索结束无结果时没有清楚地区分真实搜索空态和单机演示；发送页剩余时间仍可能只在切换页面后刷新。

### 原因分析

搜索中状态只替换了按钮，没有明确的搜索中标题和取消入口；发送页剩余时间仍通过计算方法返回，没有直接绑定独立字符串状态。

### 处理过程

1. 接收页搜索状态改为明确三态展示。
2. 搜索中显示“正在搜索真实设备”、mDNS 预计 3 秒结束说明和“取消搜索”按钮。
3. 新增 `cancelRealSearch()`，取消时调用 `stopSearch()` 并回到 empty 状态。
4. 搜索无结果时显示模拟器环境可能不支持 mDNS 的说明。
5. 新增 `sendRemainingText`，发送页剩余时间直接显示该状态。
6. 新增 `updateTransferRemainingTexts()`，在 timer 启动、每秒 tick、会话开启/失败/取消/过期时更新。
7. 执行关键词检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 11 s 515 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已搜索确认 `Index.ets` 中没有 `any`、`unknown`、`stopPropagation`。已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

在模拟器中手动验证真实搜索中、取消搜索、真实搜索无结果、单机演示和发送页倒计时持续刷新。

## 2026-07-09 18:42 - 拆分真实搜索与单机演示构建验证

### 现象

接收页真实 mDNS 搜索结果和单机演示结果仍混在一个入口中；真实发现结果没有完整验证码、payload 和摘要却显示“可连接”；发送端倒计时刷新仍不稳定。

### 原因分析

接收页没有把真实搜索入口和单机演示入口固定拆开；真实发现卡片复用了一部分演示卡片状态显示；倒计时只依赖时间戳状态，ArkUI 追踪不够稳定。

### 处理过程

1. 将接收页入口拆为“搜索真实设备”和“单机演示当前发送会话”。
2. 真实 mDNS 卡片只展示已发现服务、摘要待连接后获取、连接层与确认码校验待接入。
3. 隐藏真实 mDNS 路径的确认码输入、选择核对按钮和“可连接”状态。
4. 单机演示入口检查当前 `transferSession`，不存在或过期时只提示开启发送会话，不生成独立验证码。
5. 新增 `transferClockTick`，每次启动和每秒 tick 同步更新 `transferClockNow` 与 `transferClockTick`。
6. 发送页和接收页剩余时间通过 `currentTransferNow()` 读取当前时间。
7. 执行关键词检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 8 s 926 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已搜索确认 `Index.ets` 中没有 `any`、`unknown`、`stopPropagation`。已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

在模拟器中手动验证真实搜索和单机演示两条入口：真实搜索不出现验证码输入；单机演示必须先开启发送会话，并用发送页完整 6 位确认码通过演示校验。

## 2026-07-09 18:31 - 真实发现与本机演示收敛构建验证

### 现象

接收页把真实 mDNS 发现结果和本机演示结果混用，真实发现结果也可能进入验证码核对 UI；发送页倒计时刷新仍不稳定。

### 原因分析

接收页只用全局演示状态判断是否显示校验入口，没有明确区分真实 mDNS 和本机演示来源；发送页剩余时间虽然内部使用时钟，但 UI 调用没有显式传入 `transferClockNow`。

### 处理过程

1. 增加接收设备来源状态，真实搜索设置为 `mdnsReal`，本机演示设置为 `demoLocal`。
2. 真实 mDNS 设备只显示服务状态、摘要待获取和连接层待接入提示，不显示输入框或校验按钮。
3. 演示发现必须存在未过期发送会话，否则提示“请先到发送页开启面对面投送会话”，不再生成独立验证码。
4. 本机演示设备复用当前 `transferSession` 的确认码、摘要和过期时间。
5. 剩余时间方法显式接收 `transferClockNow`，发送页和接收页调用时直接传入该 `@State`。
6. 执行关键词检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 10 s 964 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已搜索确认 `Index.ets` 中没有 `any`、`unknown`、`stopPropagation`。已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

在模拟器中手动验证真实 mDNS 发现和本机演示两条路径：真实发现不出现验证码输入；本机演示必须先开启发送会话，并只能用发送页完整 6 位确认码通过演示校验。

## 2026-07-09 18:19 - 投送中心接收校验入口与倒计时构建验证

### 现象

接收页发现设备后验证码输入区域不明显；真实 mDNS 发现结果无摘要时显示 0 条便签 / 0 段文本 / 0 张图片 / 0 字符；发送页倒计时在部分路径下没有继续实时刷新。

### 原因分析

设备卡片只有点击行为，没有显式选择按钮；真实发现结果的摘要字段目前可能只能使用安全默认值，页面直接格式化默认 0 值；模式切换时没有主动确保已有会话或设备列表的倒计时 timer 已启动。

### 处理过程

1. 为设备卡片增加“选择并核对确认码”按钮，点击卡片或按钮都会选中设备。
2. 单个演示/本机绑定设备注入后自动选中，直接显示“核对确认码”区域。
3. 真实 mDNS 无摘要时显示“摘要待连接后获取”，不显示 0/0/0/0。
4. 模式切换到已有未过期发送会话或已有接收设备列表时，主动启动 `transferClockNow` timer。
5. 执行 `Index.ets` 关键词检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 10 s 935 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已搜索确认 `Index.ets` 中没有 `any`、`unknown`、`stopPropagation`。已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

在单模拟器中手动验证发送页倒计时、接收页单设备自动显示核对区域、演示确认码正确/错误输入结果，以及真实搜索无摘要时的“摘要待连接后获取”文案。

## 2026-07-09 17:56 - 演示确认码绑定发送会话构建验证

### 现象

发送页显示的确认码和接收页演示设备使用的确认码不是同一个，导致接收页卡片显示的后两位与实际可通过验证码不一致。

### 原因分析

接收页演示设备使用固定 `DEMO_TRANSFER_CODE`，没有优先复用当前发送页已经创建的 `transferSession.transferCode` 和会话摘要。

### 处理过程

1. 新增演示设备是否绑定发送会话的状态。
2. 点击“演示：模拟发现设备”时，优先读取未过期的 `transferSession`。
3. 绑定发送会话时，演示设备复用 `transferCode`、后两位、`payloadSummary`、`expiresAt` 和设备名。
4. 无发送会话时才使用独立演示数据，并显示未绑定提示。
5. 发送端取消投送或会话过期时，清理绑定的演示设备。
6. 执行文本检查和一次 `assembleApp`。

### 结果

构建成功，输出 `BUILD SUCCESSFUL in 11 s 843 ms`。输出仍包含项目既有 deprecated API、异常处理提示、混淆提示和未配置签名警告。

### 验证

已执行 `assembleApp`，构建成功。未执行 DevEco Studio Preview、真机或模拟器运行。

### 后续建议

手动验证单模拟器演示路径，确认发送端确认码、接收端后两位提示和接收端校验通过码完全一致。
