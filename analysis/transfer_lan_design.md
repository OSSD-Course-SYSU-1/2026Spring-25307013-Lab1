# InstantNote 局域网面对面投送设计

## 当前实现状态

### 已完成

- 投送中心 UI：已具备发送 / 接收切换，发送页有面对面投送会话 UI 雏形，接收页有本地搜索状态和空态提示。
- JSON 调试导入：已保留在高级 / 调试导入区域，用于备用验证，不作为主流程入口。
- 投送包编码 / 解码 / 预览 / 合并：已具备投送包生成、校验、导入预览和用户确认后合并能力。
- 面对面投送会话 UI 雏形：发送页可展示本机 InstantNote、6 位确认码、等待连接状态、剩余时间和投送摘要。

### 未完成

- 真实局域网设备发现。
- 真实设备连接。
- 文本 payload 局域网传输。
- 图片二进制跨设备传输。

当前面对面投送仍是会话流程预览，不代表已经支持真实两机传输；未完成真机跨设备验证，也不声称已经完成该能力。

### 下一步小任务（每项 8 分钟以内）

- 统一发送页和接收页的“真实局域网发现与传输待接入”提示文案。
- 为接收页空态补充更清晰的同一 Wi-Fi 检查提示，不接入网络 API。
- 为发送页会话卡片补充本地倒计时刷新，不传输 payload。
- 在文档中列出 HarmonyOS 局域网发现 API 候选方案，只做调研记录。
- 为图片跨设备传输待接入提示补充边界说明，不改 MemoTransfer 协议结构。

## 设计目标

两台安装 InstantNote 的设备在同一局域网内完成面对面投送：发送端开启投送，接收端搜索附近设备，用户确认后进入导入预览并合并便签。该方案不依赖扫码、不复制 JSON、不依赖系统分享，也不涉及云同步或跨公网传输。

## 用户流程

### 发送端流程

1. 用户在首页点击「投送」，进入「发送」页。
2. 用户选择投送范围：当前便签或全部便签。
3. 应用生成投送包摘要，展示便签数、文本块数、图片块数和预计大小。
4. 用户点击「开启面对面投送」。
5. 应用创建投送会话，显示设备名、6 位确认码、过期倒计时和等待接收状态。
6. 接收端连接后，发送端显示接收设备名与确认码校验状态。
7. 用户确认发送后，发送端传输投送 JSON。
8. 传输完成后，发送端显示成功；超时、取消或失败时显示明确原因。

### 接收端流程

1. 用户在首页点击「投送」，进入「接收」页。
2. 用户点击「搜索附近设备」。
3. 应用扫描同一局域网内的 InstantNote 投送会话。
4. 页面展示可用发送端列表：设备名、确认码后两位、剩余时间。
5. 接收端选择设备后，页面显示该会话对应的 6 位确认码核对入口。
6. 用户核对或输入发送端显示的 6 位确认码。
7. 确认码通过后，接收端请求投送包。
8. 接收端收到投送 JSON 后进入导入预览，不直接合并。

### 导入预览流程

1. 接收端调用 `MemoTransfer.decodeTransferPackage()` 解码并校验投送 JSON。
2. 调用 `previewTransferImport()` 计算新增便签数、更新便签数和不支持的图片块数量。
3. UI 展示导入预览：
   - 新增便签数
   - 更新便签数
   - 不支持的图片块数量
4. 用户点击「确认导入」后调用 `mergeReceivedMemos()` 合并。
5. 用户点击取消时丢弃待导入数据，不修改本地便签。

## 技术分层

### MemoTransfer 协议层

复用现有 `MemoTransfer.ets`：

- `encodeTransferPackage(memos)`：生成投送 JSON。
- `decodeTransferPackage(raw)`：解析、协议校验和基础数据校验。
- `previewTransferImport(current, incoming)`：生成导入预览。
- `mergeReceivedMemos(current, incoming)`：确认后合并。

第一阶段不修改协议结构。若后续要支持图片二进制传输，可新增传输层元数据，不直接破坏现有 JSON 协议。

### 会话层

会话层负责一次面对面投送的生命周期：

- 创建会话
- 维护等待、连接、确认、传输、完成、失败状态
- 管理确认码、token、过期时间
- 限制同一时刻只开启一个发送会话

建议新增独立模块，例如 `TransferLanSession.ets`，但第一阶段只先做 UI 和状态。

### 局域网发现层

发现层负责让接收端找到同一局域网内的发送端：

- 发送端开启投送后广播服务信息。
- 接收端搜索附近设备并展示候选列表。
- 发现信息只包含非敏感摘要，不包含完整便签内容。

可选技术方向需后续根据 HarmonyOS SDK 能力确认，例如 mDNS、UDP 广播或平台网络发现 API。

### 数据传输层

传输层负责在确认码校验通过后传输投送内容：

- 发送端提供临时传输端点。
- 接收端携带 `sessionId` 和 `token` 请求投送包。
- 发送端校验 token 后返回投送 JSON。
- 传输完成或超时后关闭会话。

第一阶段只传标题、标签和文本块。图片块不传输，或在导入预览中标记为不支持。

### 导入合并层

导入合并层继续由现有 `MemoTransfer` 和页面状态负责：

- 扫描或局域网传输得到的 raw payload 都必须走同一解码入口。
- 解码成功后必须先进入预览。
- 用户确认后才合并到 `memoList` 并持久化。

## 真实局域网接入调研

当前工程目标为 HarmonyOS，`targetSdkVersion` / `compatibleSdkVersion` 为 `6.0.0(20)`，模块面向 phone、tablet、2in1。`oh-package.json5` 暂无第三方网络依赖，`module.json5` 暂未声明网络、局域网发现或设备发现相关权限。因此真实局域网接入前，需要先查 DevEco Studio / HarmonyOS SDK 文档确认可用 API、权限声明、真机调试限制和上架限制。

### 本地 SDK 能力确认

本轮只检索当前工程配置和本机 DevEco Studio / HarmonyOS SDK 文档索引，未写网络代码，未做真机跨设备验证。

检索范围：

- 当前工程：`entry/src/main/module.json5`、`oh-package.json5`、`build-profile.json5`，以及工程内现有 import / 权限声明关键词。
- 本机目录：`C:\Users\Euphoria\AppData\Local\Huawei\Sdk`、`D:\DevEcoStudio\plugins\openharmony\ohos-info-center-view\static\hos\JsEtsAPIReference`。

确认结果：

- TCP Socket 客户端：已确认本地 DevEco 文档索引存在 `@ohos.net.socket (Socket连接)`，描述中包含 `TCPSocket`、`UDPSocket`、`WebSocket`、`TLSSocket`。具体 ArkTS import 写法、构造方法和权限仍待打开官方 SDK 文档页确认。
- 监听本机 TCP 端口 / 轻量 HTTP 服务：未确认。当前本地索引只确认 socket 模块存在，未在本轮确认普通应用可监听 TCP 端口或启动 HTTP Server；`@ohos.net.webSocket` 索引提到服务端限制信息，是否适合 phone/tablet/2in1 仍待官方文档确认。
- UDP 广播 / 组播：部分确认。`@ohos.net.socket` 索引确认存在 `UDPSocket`，但本轮未确认广播、组播、端口绑定、同 Wi-Fi 隔离和权限细节。
- mDNS / DNS-SD / 服务发现：已确认本地 DevEco 文档索引存在 `@ohos.net.mdns (MDNS管理)`，描述为多播 DNS，提供局域网本地服务添加、移除、发现、解析能力。具体方法签名、权限和 HarmonyOS 6.0.0(20) 适配情况仍待官方文档页确认。
- Nearby / 分布式设备发现：部分确认。本地索引存在 `@ohos.distributedDeviceManager (设备管理)` 和 `gameNearbyTransfer(游戏近场快传)` 条目，但本轮未确认它们是否适合普通便签 App 的局域网面对面投送，也未确认权限、账号、设备组网或服务开通要求。
- 当前工程权限：已确认 `module.json5` 暂未声明网络相关权限；工程内未发现已有网络 import 或 `ohos.permission` 声明。

可能需要的权限名称：

- `ohos.permission.INTERNET`：已在本地 DevEco 文档索引中出现，后续接入普通网络访问时优先确认是否需要声明。
- 分布式设备、Nearby、mDNS、UDP 广播 / 组播相关权限：未确认，必须继续查 DevEco Studio / HarmonyOS SDK 官方文档，不能直接写入 `module.json5`。

下一步 8 分钟以内小任务：

- 打开 `@ohos.net.socket` 官方文档页，只确认 TCP 客户端、TCP 监听、UDP 绑定 / 广播的具体 API 名称和权限。
- 打开 `@ohos.net.mdns` 官方文档页，只确认添加服务、搜索服务、解析服务的 API 名称和权限。
- 打开 `@ohos.distributedDeviceManager` 官方文档页，只确认是否适合三方应用发现附近设备及所需权限。
- 打开 `gameNearbyTransfer` 官方文档页，只判断它是否限定游戏场景，是否应排除在 InstantNote 方案之外。
- 只更新文档中的权限候选清单，不修改 `module.json5`。

### socket / mDNS 官方文档确认

本轮只阅读本机 DevEco 官方文档页：

- `D:\DevEcoStudio\plugins\openharmony\ohos-info-center-view\static\hos\JsEtsAPIReference\zh-cn_topic_0000002497445470.html`
- `D:\DevEcoStudio\plugins\openharmony\ohos-info-center-view\static\hos\JsEtsAPIReference\zh-cn_topic_0000002529445413.html`

已确认：

- `@ohos.net.socket` 对应当前文档导入方式为 `import { socket } from '@kit.NetworkKit';`。
- socket 模块支持 `TCPSocket`、`UDPSocket`、`WebSocket`、`TLSSocket`，系统能力为 `SystemCapability.Communication.NetStack`。
- TCP 客户端能力存在：`socket.constructTCPSocketInstance(): TCPSocket`，`TCPSocket.connect(options: TCPConnectOptions, ...)`，`TCPSocket.send(options: TCPSendOptions, ...)`。
- TCP 服务端 / 监听本机端口能力存在：文档页包含 `listen(address: NetAddress, ...)`、`listen(address: NetAddress): Promise<void>`，以及 `on(type: 'connect', callback: Callback<TCPSocketConnection>): void`。
- UDP 能力存在：`socket.constructUDPSocketInstance(): UDPSocket`，`UDPSocket.bind(address: NetAddress, ...)`，`UDPSocket.send(options: UDPSendOptions, ...)`，`on(type: 'message', callback: Callback<SocketMessageInfo>): void`。
- UDP 广播有明确配置项：`UDPExtraOptions.broadcast`，说明为是否可以发送广播，默认 `false`。
- 组播能力存在：`socket.constructMulticastSocketInstance(): MulticastSocket`，并包含 `addMembership()`、`dropMembership()`、`setMulticastTTL()` 等接口。
- socket 相关方法文档多处标注需要权限 `ohos.permission.INTERNET`；本轮不修改 `module.json5`。
- `@ohos.net.mdns` 对应当前文档导入方式为 `import { mdns } from '@kit.NetworkKit';`。
- mDNS 支持添加 / 发布本地服务：`mdns.addLocalService(context, serviceInfo, ...)` 和 Promise 重载。
- mDNS 支持移除本地服务：`mdns.removeLocalService(context, serviceInfo, ...)` 和 Promise 重载。
- mDNS 支持创建发现服务：`mdns.createDiscoveryService(context, serviceType): DiscoveryService`。
- mDNS 支持开始 / 停止发现：`startSearchingMDNS()`、`stopSearchingMDNS()`。
- mDNS 支持发现事件：`on('serviceFound', ...)`、`on('serviceLost', ...)`，并有 discovery start / stop 事件。
- mDNS 支持解析服务：`mdns.resolveLocalService(context, serviceInfo, ...)` 和 Promise 重载。
- mDNS 文档页标注系统能力为 `SystemCapability.Communication.NetManager.MDNS`。

未确认：

- socket 文档已确认 API 和 `ohos.permission.INTERNET`，但未进行真机验证，不能确认 phone / tablet / 2in1 上监听端口、广播、组播在同一 Wi-Fi 下的实际可用性。
- 本轮未确认 socket 监听端口在后台、息屏、网络切换、热点隔离、端口占用时的行为。
- 本轮未在 mDNS 页面命中明确的 `ohos.permission.*` 权限名称；只确认了系统能力，是否还需要 `ohos.permission.INTERNET` 或其他权限必须继续查权限文档 / 示例工程。
- 本轮未确认 mDNS 在模拟器与真机、多设备同 Wi-Fi、路由器禁用组播等场景下的实际表现。

下一步：

- 在不写业务代码的前提下，查权限文档，确认 `@ohos.net.mdns` 是否需要显式权限声明。
- 单独记录 socket / mDNS 最小实验清单：一个发送端、一个接收端、同 Wi-Fi、端口监听、mDNS 发布 / 发现 / 解析。
- 后续如要修改 `module.json5`，先只添加经官方文档确认的权限，并单独记录变更。

### 局域网发现层

可调研路线：

- 平台提供的局域网服务发现能力：确认是否支持 mDNS / DNS-SD 或等价 API，用于发布和发现 `InstantNote` 会话摘要。
- UDP 广播或组播：确认 HarmonyOS SDK 是否允许应用在同一 Wi-Fi 内发送 / 接收局域网广播，及后台、权限、网络隔离限制。
- 手动地址兜底：若自动发现能力受限，可后续设计手动输入局域网地址和确认码，但不作为主流程。

待确认事项：

- 需要声明哪些权限或 capabilities。
- phone、tablet、2in1 是否能力一致。
- 模拟器是否支持局域网发现；真机是否需要同一 Wi-Fi、关闭热点隔离或额外调试配置。

### 设备连接层

可调研路线：

- 发送端临时监听本机局域网端口，接收端连接后先做 `sessionId` 和 6 位确认码校验。
- 接收端只在用户选择设备并确认后建立连接，避免发现阶段传输完整便签内容。
- 连接生命周期继续遵循当前会话字段：`sessionId`、`transferCode`、`token`、`expiresAt`。

待确认事项：

- HarmonyOS ArkTS 中可用的 TCP Socket / HTTP Server / WebSocket 等能力及 API 名称。
- 是否允许普通应用监听局域网端口，以及所需权限和系统版本限制。
- 连接超时、取消、端口占用和同 Wi-Fi 隔离的错误码表现。

### 文本 payload 传输层

可调研路线：

- 第一阶段只传现有 `MemoTransfer` 生成的文本投送 JSON，接收端仍走解码、预览、用户确认合并流程。
- 传输请求携带 `sessionId` 和校验后的临时 `token`，发送端只返回当前会话对应 payload。
- 对 payload 大小设置上限，超出时提示减少投送范围，后续再设计分片。

待确认事项：

- ArkTS 网络请求 / 监听 API 的流式读取、超时和取消能力。
- 局域网明文传输是否满足课程项目阶段目标；若需要加密，再单独设计密钥协商。
- 文本 payload 的大小上限和错误恢复策略。

### 图片传输后续阶段

可调研路线：

- 文本闭环稳定后，再设计图片二进制传输，不复用本机图片 URI 作为跨设备结果。
- 图片传输层需要支持单图大小限制、总大小限制、分片、重试、校验和失败回滚。
- 导入预览需要区分文本已可导入、图片待接入、图片部分失败等状态。

待确认事项：

- HarmonyOS 文件读取、沙箱路径授权和图片二进制读取 API。
- 局域网大文件传输的内存占用、分片大小和断开恢复策略。
- 接收端保存图片到应用沙箱后的路径持久化方式。

### 下一轮 8 分钟以内小任务

- 只查 DevEco Studio / HarmonyOS SDK 文档，确认 ArkTS 是否有可用的局域网服务发现 API，并把结果补到本文档。
- 只查 SDK 文档，确认普通 HarmonyOS 应用是否能监听 TCP 端口及所需权限。
- 在 `module.json5` 中调研记录需要的网络权限名称，但不实际修改配置。
- 为文本 payload 传输设计最小握手字段表，只写文档，不写代码。
- 为图片传输阶段补充限制清单：单图大小、总大小、失败回滚，不改协议。

## 会话字段

### sessionId

- 由发送端点击「开启面对面投送」时生成。
- 用于标识一次投送会话。
- 建议格式：`lan-<createdAt>-<random>`。
- 只在局域网发现信息和后续传输请求中使用。

### deviceName

- 发送端在发现信息中暴露的设备名，例如 `InstantNote - MatePad`。
- 优先使用系统设备名；不可用时使用应用内默认名。
- 接收端设备列表展示 `deviceName`，帮助用户识别目标发送端。

### transferCode

- 6 位确认码，例如 `482913`。
- 发送端创建会话时生成并在发送端页面展示。
- 接收端选择设备后要求用户核对或输入 `transferCode`。
- 用于降低同一 Wi-Fi 下误连其他设备的风险。

### token

- 发送端创建会话时生成的临时访问令牌。
- 发现阶段不暴露完整 token。
- 接收端通过 `transferCode` 校验后，后续数据请求必须携带 token。
- 传输完成、用户取消或会话过期后 token 立即失效。

### createdAt

- 会话创建时间。
- 用于展示“已等待多久”和辅助生成 `sessionId`。
- 接收端可用它判断发现信息是否过旧。

### expiresAt

- 会话过期时间。
- 建议第一阶段设置为创建后 5 分钟。
- 过期后发送端停止广播并拒绝新连接，接收端隐藏该会话。

### payloadSummary

- 投送内容摘要，不包含完整便签内容。
- 建议字段：
  - `memoCount`
  - `textBlockCount`
  - `imageBlockCount`
  - `payloadBytes`
- 接收端设备列表或确认页可展示摘要，帮助用户确认投送范围。

## 发现方式

### 自动发现

发送端开启面对面投送后，在同一局域网内发布轻量服务信息：

- 应用标识：`InstantNote`
- 协议版本
- `sessionId`
- `deviceName`
- `transferCode` 的部分展示值，例如后两位
- `expiresAt`
- `payloadSummary`
- 支持能力：文本投送、图片暂不支持

接收端点击「搜索附近设备」后监听或扫描这些服务信息，过滤出协议版本兼容的 InstantNote 发送端。

### 降级方案

如果无法自动发现：

1. 接收端提示“未发现附近设备，请确认两台设备连接同一 Wi-Fi”。
2. 保留粘贴投送内容作为备用验证入口。
3. 后续可设计手动输入发送端局域网地址和确认码，但不作为第一阶段主流程。

## 数据传输

### 第一阶段：文本投送

第一阶段只传：

- 标题
- 标签
- 文本块

发送端生成投送包前应过滤图片块，或保留图片块数量用于提示。

第一阶段不做：

- 图片块跨设备传输
- 公网同步
- 扫码
- 蓝牙

### 图片块处理

图片块第一阶段暂不传输：

- 不传本机图片 URI，避免接收端拿到无法访问的本地路径。
- 导入预览显示“不支持的图片块数量”。
- 确认导入后只导入文本内容。

阶段 4 再设计图片二进制传输、大小限制、分片和失败恢复。

## 安全与失败处理

### 不同 Wi-Fi

现象：接收端搜索不到发送端。

处理：

- 提示“两台设备需要连接同一 Wi-Fi”。
- 保留“粘贴投送内容”备用验证入口。

### 连接超时

现象：接收端发现设备但连接或传输超时。

处理：

- 接收端提示“连接超时，请重新搜索”。
- 发送端会话保持到过期时间，允许重新连接。

### 版本不兼容

现象：接收端发现协议版本高于当前支持版本，或投送 JSON 解码失败。

处理：

- 发现列表标记为“版本不兼容”或隐藏。
- 已接收 payload 解码失败时提示“协议版本不兼容”。

### 内容过大

现象：投送包超过当前安全阈值。

处理：

- 发送端生成前阻止开启投送。
- 提示“内容过大，请减少投送范围”。
- 后续传输层可支持分片后再放宽阈值。

### 用户取消

现象：发送端或接收端取消会话。

处理：

- 发送端取消后停止广播并使 token 失效。
- 接收端取消后丢弃待导入数据。
- 对端显示“对方已取消”。

### 发送端取消

现象：接收端已发现或正在连接时，发送端关闭面对面投送。

处理：

- 发送端立即停止广播并使 token 失效。
- 接收端提示“发送端已取消投送”，返回搜索状态。

### 接收端超时

现象：接收端搜索、连接或等待数据超过限定时间。

处理：

- 接收端提示“接收超时，请重新搜索附近设备”。
- 不保留半成品导入数据。

### 用户拒绝导入

现象：导入预览展示后，用户点击取消或关闭投送中心。

处理：

- 丢弃 `pendingImportMemos` 和预览摘要。
- 不调用 `mergeReceivedMemos()`。
- 不修改本地便签列表。

## 分阶段实现计划

### 阶段 1：会话状态和 UI

- 保留当前「发送 / 接收」入口。
- 增加发送会话状态：未开启、等待接收、已连接、传输中、完成、失败。
- 增加接收搜索状态：未搜索、搜索中、未发现、发现列表、连接中、等待预览。
- 生成 `sessionId`、6 位确认码、设备名、过期时间和 token。
- 不实现真实网络，只完成状态和文案。

### 阶段 2：局域网发现

- 发送端发布局域网发现信息。
- 接收端搜索附近 InstantNote 设备。
- 处理同 Wi-Fi、超时、版本不兼容和取消。
- 不传输便签内容，只验证发现和连接确认。

### 阶段 3：文本投送

- 发送端过滤图片块，生成文本投送 JSON。
- 接收端请求并接收投送 JSON。
- 复用现有解码、导入预览和确认合并。
- 完成基本两机投送闭环。

### 阶段 4：图片投送

- 设计图片块二进制传输。
- 增加单图大小、总大小、数量限制。
- 支持分片、重试和失败回滚。
- 导入预览区分已支持图片和未成功图片。

## 当前不实现的内容

- 云同步
- 扫码
- 蓝牙
- 跨公网传输
