import router from '@ohos.router';
import prompt from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemePalette, UI_TOKENS, resolveTheme } from '../common/AppTheme';
import { getContentWidth, getDialogWidth, getPageSidePadding, isCompactWindow, isExpandedWindow } from '../common/ResponsiveLayout';
import {
  DEFAULT_MEMOS,
  MEMO_STORAGE_KEY,
  Memo,
  createTextBlock,
  ensureMemoStoreInitialized,
  generateNextMemoId,
  memoPreviewFromBlocks,
  normalizeMemoPreview,
  normalizeMemoTitle
} from '../common/MemoModel';
import { loadMemos, saveMemos } from '../common/MemoStorage';
import { TransferImportPreview, decodeTransferPackage, encodeTransferPackage, mergeReceivedMemos, previewTransferImport, summarizeTransferPayload } from '../common/MemoTransfer';
import { supportedPlatformSummary } from '../common/PlatformTargets';

const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = 'InstantNote';
const MAX_TRANSFER_IMPORT_CHARS: number = 20000;

interface TransferHeader {
  protocol?: string;
  version?: number;
}

ensureMemoStoreInitialized();

@Entry
@Component
struct Index {
  @StorageLink('memoList') memos: Memo[] = DEFAULT_MEMOS;
  @StorageLink('systemColorMode') colorMode: string = 'light';
  @State private searchKeyword: string = '';
  @State private showNewMemoForm: boolean = false;
  @State private showTransferPanel: boolean = false;
  @State private transferMode: string = 'send';
  @State private transferScope: string = 'all';
  @State private selectedTransferMemoId: number = -1;
  @State private showTransferMemoPicker: boolean = false;
  @State private draftTitle: string = '';
  @State private draftTag: string = '';
  @State private draftBodyPreview: string = '';
  @State private transferPayload: string = '';
  @State private transferImportText: string = '';
  @State private pendingImportMemos: Memo[] = [];
  @State private pendingImportPreview: TransferImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
  @State private feedbackMessage: string = '';
  @State private formError: string = '';
  @State private viewportWidth: number = 0;
  @State private viewportHeight: number = 0;
  @State private floatingExpanded: boolean = false;
  @State private floatingX: number = 0;
  @State private floatingY: number = 220;
  @State private dragStartFloatingX: number = 0;
  @State private dragStartFloatingY: number = 220;
  @State private floatingWasDragged: boolean = false;
  @State private floatingInitialized: boolean = false;
  @State private searchFocused: boolean = false;
  @State private quickButtonPressed: boolean = false;
  @State private pressedPinMemoId: number = -1;
  @State private memosInitialized: boolean = false;

  aboutToAppear(): void {
    if (!this.memosInitialized) {
      void this.loadPersistentMemosForInitialAppear();
    }
  }

  onPageShow(): void {
    this.syncMemosFromAppStorage();
    setTimeout(() => {
      this.syncMemosFromAppStorage();
    }, 120);
  }

  build() {
    Stack() {
      Column() {
        Column({ space: 14 }) {
          this.buildHeader();

          if (isExpandedWindow(this.viewportWidth)) {
            Row({ space: 20 }) {
              Column({ space: 14 }) {
                this.buildSearchBar();
                this.buildMemoList();
              }
              .layoutWeight(2);

              Column({ space: 14 }) {
                this.buildTransferSummary();
                this.buildDesktopPreview();
              }
              .layoutWeight(1);
            }
            .width('100%')
            .layoutWeight(1);
          } else {
            this.buildSearchBar();
            this.buildMemoList();
          }

          Button('快速记录')
            .width('100%')
            .height(UI_TOKENS.buttonHeight.primary)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.palette().accent)
            .fontColor('#FFFFFF')
            .borderRadius(UI_TOKENS.radius.largeButton)
            .scale({ x: this.quickButtonPressed ? 0.98 : 1, y: this.quickButtonPressed ? 0.98 : 1 })
            .opacity(this.quickButtonPressed ? 0.9 : 1)
            .animation({ duration: 120, curve: Curve.EaseOut })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.quickButtonPressed = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.quickButtonPressed = false;
              }
            })
            .onClick(() => {
              void this.startNewMemo();
            });
        }
        .width(getContentWidth(this.viewportWidth))
        .height('100%')
        .padding({
          left: getPageSidePadding(this.viewportWidth),
          right: getPageSidePadding(this.viewportWidth),
          top: UI_TOKENS.spacing.pageMargin,
          bottom: 18
        });
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.palette().background);

      if (this.showNewMemoForm) {
        this.buildNewMemoDialog();
      }

      if (this.showTransferPanel) {
        this.buildTransferDialog();
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, newValue: Area) => {
      this.viewportWidth = Number(newValue.width);
      this.viewportHeight = Number(newValue.height);
      if (!this.floatingInitialized) {
        this.floatingX = this.getRightSnapX();
        this.floatingY = this.getBottomSnapY();
        this.floatingInitialized = true;
      } else {
        this.floatingX = this.clampFloatingX(this.floatingX);
        this.floatingY = this.clampFloatingY(this.floatingY);
      }
    });
  }

  @Builder
  private buildHeader() {
    Row() {
      Column({ space: 3 }) {
        Text('灵感便签')
          .fontSize(isExpandedWindow(this.viewportWidth) ? 30 : 26)
          .fontWeight(FontWeight.Bolder)
          .fontColor(this.palette().textPrimary);
        Text('轻量记录，随手整理。')
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .opacity(0.78)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Button('投送')
        .height(34)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.palette().surface)
        .fontColor(this.palette().accentStrong)
        .fontSize(13)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(17)
        .onClick(() => this.openTransferPanel());
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private buildSearchBar() {
    Column({ space: 8 }) {
      TextInput({ placeholder: '搜索标题、内容或标签', text: this.searchKeyword })
        .height(44)
        .width('100%')
        .backgroundColor(this.palette().surface)
        .border({ color: this.searchFocused ? this.palette().accent : this.palette().border, width: 1 })
        .borderRadius(UI_TOKENS.radius.input)
        .padding({ left: 14, right: 14 })
        .fontColor(this.palette().textPrimary)
        .fontSize(14)
        .shadow({ radius: this.searchFocused ? 8 : 0, color: this.palette().noteShadow, offsetY: 2 })
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onFocus(() => {
          this.searchFocused = true;
        })
        .onBlur(() => {
          this.searchFocused = false;
        })
        .onChange((value: string) => {
          this.searchKeyword = value;
        });

      if (this.feedbackMessage.length > 0) {
        Text(this.feedbackMessage)
          .fontSize(12)
          .fontColor(this.palette().success)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
    }
    .width('100%');
  }

  @Builder
  private buildMemoList() {
    Scroll() {
      Column({ space: 12 }) {
        ForEach(this.filteredMemos(), (memo: Memo) => {
          this.buildMemoCard(memo);
        }, (memo: Memo) => this.memoRenderKey(memo));

        if (this.filteredMemos().length === 0) {
          this.buildEmptyState();
        }
      }
      .width('100%')
      .padding({ bottom: 74 });
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1);
  }

  @Builder
  private buildMemoCard(memo: Memo) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 9 }) {
        Column({ space: 5 }) {
          Text(memo.title)
            .fontSize(17)
            .fontWeight(memo.isPinned === true ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ right: memo.isPinned === true ? 84 : 62 });

          if (memo.isPinned === true) {
            Text('已置顶')
              .fontSize(10)
              .fontColor(this.palette().accentStrong)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(this.palette().accentSoft)
              .borderRadius(9)
              .alignSelf(ItemAlign.Start);
          }
        }
        .width('100%');

        Text(this.previewContent(memo))
          .fontSize(13)
          .lineHeight(20)
          .fontColor(this.palette().textMuted)
          .maxLines(isExpandedWindow(this.viewportWidth) ? 3 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Row() {
          if (memo.tag) {
            Text(memo.tag)
              .fontSize(11)
              .fontColor(this.palette().tagText)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(this.palette().tagBg)
              .border({ color: this.palette().border, width: 1 })
              .borderRadius(10)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          } else {
            Text(' ')
              .fontSize(11)
              .opacity(0);
          }

          Text(this.formatTimestamp(memo.updatedAt))
            .fontSize(11)
            .fontColor(this.palette().textMuted)
            .opacity(0.82);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center);
      }
      .padding({ left: 15, right: 15, top: 14, bottom: 12 })
      .width('100%')
      .backgroundColor(memo.isPinned === true ? this.palette().accentSoft : this.palette().notePaper)
      .border({ color: memo.isPinned === true ? this.palette().accent : this.palette().noteBorder, width: 1 })
      .borderRadius(UI_TOKENS.radius.pageCard)
      .shadow({ radius: 5, color: this.palette().noteShadow, offsetY: 2 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onClick(() => {
        void this.openMemo(memo.id);
      })
      .gesture(
        LongPressGesture()
          .onAction(() => {
            void this.confirmRemoveMemo(memo.id);
          })
      );

      Button(memo.isPinned === true ? '已置顶' : '置顶')
        .height(30)
        .fontSize(12)
        .fontWeight(memo.isPinned === true ? FontWeight.Medium : FontWeight.Regular)
        .padding({ left: 11, right: 11 })
        .backgroundColor(memo.isPinned === true ? this.palette().accent : this.palette().surface)
        .fontColor(memo.isPinned === true ? '#FFFFFF' : this.palette().textMuted)
        .border({ color: memo.isPinned === true ? this.palette().accent : this.palette().border, width: 1 })
        .borderRadius(15)
        .shadow({ radius: memo.isPinned === true ? 7 : 0, color: this.palette().noteShadow, offsetY: 2 })
        .scale({ x: this.pressedPinMemoId === memo.id ? 0.96 : 1, y: this.pressedPinMemoId === memo.id ? 0.96 : 1 })
        .opacity(this.pressedPinMemoId === memo.id ? 0.86 : 1)
        .animation({ duration: 120, curve: Curve.EaseOut })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.pressedPinMemoId = memo.id;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.pressedPinMemoId = -1;
          }
        })
        .margin({ top: 10, right: 10 })
        .onClick(() => this.togglePinned(memo.id));
    }
    .width('100%');
  }

  @Builder
  private buildEmptyState() {
    Column({ space: 8 }) {
      Text(this.searchKeyword.trim().length > 0 ? '没有找到匹配便签' : '还没有便签内容')
        .fontSize(16)
        .fontColor(this.palette().textPrimary)
        .textAlign(TextAlign.Center);
      Text('点击快速记录创建第一条便签。')
        .fontSize(13)
        .fontColor(this.palette().textMuted)
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .padding({ top: 44, bottom: 44 });
  }

  @Builder
  private buildTransferSummary() {
    Column({ space: 10 }) {
      Text('投送中心')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary);
      Text('面向两机投送：已准备投送包和导入预览；局域网发现与传输层待接入。')
        .fontSize(13)
        .fontColor(this.palette().textMuted)
        .lineHeight(20);
      Text(`当前原生目标：${supportedPlatformSummary()}`)
        .fontSize(12)
        .fontColor(this.palette().textMuted)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
      Button('打开投送中心')
        .height(42)
        .width('100%')
        .backgroundColor(this.palette().accentSoft)
        .fontColor(this.palette().accentStrong)
        .borderRadius(14)
        .onClick(() => this.openTransferPanel());
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.palette().card)
    .border({ color: this.palette().border, width: 1 })
    .borderRadius(18);
  }

  @Builder
  private buildDesktopPreview() {
    Column({ space: 12 }) {
      Text('当前预览')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary);
      if (this.previewMemoId() > 0) {
        Text(this.previewMemoTitle())
          .fontSize(22)
          .fontWeight(FontWeight.Bolder)
          .fontColor(this.palette().textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(this.previewMemoContent())
          .fontSize(14)
          .fontColor(this.palette().textMuted)
          .lineHeight(22)
          .maxLines(8)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Button('编辑这条便签')
          .height(42)
          .width('100%')
          .backgroundColor(this.palette().accent)
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => {
            void this.openMemo(this.previewMemoId());
          });
      } else {
        Text('暂无可预览内容')
          .fontSize(14)
          .fontColor(this.palette().textMuted);
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding(18)
    .backgroundColor(this.palette().card)
    .border({ color: this.palette().border, width: 1 })
    .borderRadius(18);
  }

  @Builder
  private buildNewMemoDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(this.palette().overlay)
        .onClick(() => this.cancelNewMemo());

      Column({ space: 14 }) {
        Text('新建便签')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().textPrimary);

        TextInput({ placeholder: '标题', text: this.draftTitle })
          .height(44)
          .backgroundColor(this.palette().surface)
          .border({ color: this.palette().border, width: 1 })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .fontColor(this.palette().textPrimary)
          .onChange((value: string) => {
            this.draftTitle = value;
            this.formError = '';
          });

        TextInput({ placeholder: '标签（可选）', text: this.draftTag })
          .height(44)
          .backgroundColor(this.palette().surface)
          .border({ color: this.palette().border, width: 1 })
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .fontColor(this.palette().textPrimary)
          .onChange((value: string) => {
            this.draftTag = value;
          });

        TextArea({ placeholder: '简短描述或预览内容', text: this.draftBodyPreview })
          .height(106)
          .backgroundColor(this.palette().surface)
          .border({ color: this.palette().border, width: 1 })
          .fontColor(this.palette().textPrimary)
          .borderRadius(12)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .maxLines(4)
          .onChange((value: string) => {
            this.draftBodyPreview = value;
          });

        if (this.formError.length > 0) {
          Text(this.formError)
            .fontSize(13)
            .fontColor(this.palette().danger);
        }

        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(Color.Transparent)
            .border({ color: this.palette().border, width: 1 })
            .borderRadius(14)
            .fontColor(this.palette().textPrimary)
            .onClick(() => this.cancelNewMemo());

          Button('添加')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.palette().accent)
            .borderRadius(14)
            .fontColor('#FFFFFF')
            .onClick(() => this.confirmNewMemo());
        }
      }
      .padding(22)
      .width(getDialogWidth(this.viewportWidth))
      .backgroundColor(this.palette().card)
      .borderRadius(20);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildTransferDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(this.palette().overlay)
        .onClick(() => this.closeTransferPanel());

      Column({ space: 10 }) {
        Row() {
          Column({ space: 3 }) {
            Text('投送中心')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary);
            Text(this.transferStatusText())
              .fontSize(11)
              .fontColor(this.palette().textMuted)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          Button('关闭')
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.palette().surface)
            .border({ color: this.palette().border, width: 1 })
            .fontColor(this.palette().textPrimary)
            .fontSize(12)
            .borderRadius(16)
            .onClick(() => this.closeTransferPanel());
        }
        .width('100%');

        this.buildTransferModeBar();

        Scroll() {
          Column({ space: 10 }) {
            Text(this.transferModeTitle())
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary)
              .width('100%');

            Column({ space: 10 }) {
              if (this.transferMode === 'send') {
                this.buildSendPane();
              } else if (this.transferMode === 'receive') {
                this.buildReceivePane();
              } else {
                this.buildDebugPane();
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.palette().surface)
            .border({ color: this.palette().border, width: 1 })
            .borderRadius(14)
            .opacity(0.98)
            .animation({ duration: 120, curve: Curve.EaseOut });

            if (this.feedbackMessage.length > 0) {
              Text(this.feedbackMessage)
                .fontSize(12)
                .fontColor(this.palette().success)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
          }
          .width('100%')
          .padding({ bottom: 4 });
        }
        .scrollBar(BarState.Off)
        .height(this.dialogBodyHeight());
      }
      .padding(16)
      .width(getDialogWidth(this.viewportWidth))
      .backgroundColor(this.palette().card)
      .borderRadius(20);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildTransferModeBar() {
    Row({ space: 4 }) {
      this.buildTransferModeButton('send', '发送');
      this.buildTransferModeButton('receive', '接收');
    }
    .width('100%')
    .padding(3)
    .backgroundColor(this.palette().surface)
    .border({ color: this.palette().border, width: 1 })
    .borderRadius(16);
  }

  @Builder
  private buildTransferModeButton(mode: string, label: string) {
    Button(label)
      .layoutWeight(1)
      .height(32)
      .fontSize(12)
      .backgroundColor(this.transferMode === mode ? this.palette().accent : this.palette().surface)
      .fontColor(this.transferMode === mode ? '#FFFFFF' : this.palette().textPrimary)
      .border({ color: this.transferMode === mode ? this.palette().accent : this.palette().border, width: 1 })
      .borderRadius(13)
      .opacity(this.transferMode === mode ? 1 : 0.82)
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onClick(() => {
        this.transferMode = mode;
        this.feedbackMessage = '';
      });
  }

  @Builder
  private buildSendPane() {
    Column({ space: 10 }) {
      Text('面对面投送')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%');

      Text('局域网发现与传输层待接入；当前可通过调试 JSON 完成投送验证。')
        .fontSize(12)
        .fontColor(this.palette().textMuted)
        .lineHeight(18)
        .width('100%');

      Row({ space: 8 }) {
        this.buildTransferScopeButton('selected', '选中便签');
        this.buildTransferScopeButton('all', '全部便签');
      }
      .width('100%');

      if (this.transferScope === 'selected') {
        this.buildSelectedTransferMemoCard();
      }

      Column({ space: 6 }) {
        Text(this.transferSendSummaryText())
          .fontSize(13)
          .fontColor(this.palette().textPrimary)
          .width('100%');
        if (this.selectedTransferSummary().imageBlockCount > 0) {
          Text('图片跨设备传输需要后续局域网传输层支持。')
            .fontSize(12)
            .fontColor(this.palette().textMuted)
            .lineHeight(18)
            .width('100%');
        }
      }
      .width('100%')
      .padding(10)
      .backgroundColor(this.palette().notePaper)
      .border({ color: this.palette().border, width: 1 })
      .borderRadius(12);

      Button('面对面投送待接入')
        .width('100%')
        .height(42)
        .backgroundColor(this.palette().disabledBg)
        .fontColor(this.palette().disabledText)
        .borderRadius(14)
        .enabled(false);

      Button('调试 JSON')
        .height(36)
        .width('100%')
        .backgroundColor(this.palette().surface)
        .fontColor(this.palette().textPrimary)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12)
        .onClick(() => {
          this.transferMode = 'debug';
          this.generateTransferPayload();
        });

      Text('调试 JSON 是当前可用验证入口，不是普通用户最终体验。可长按文本框复制完整投送包，再到接收端粘贴预览。')
        .fontSize(11)
        .fontColor(this.palette().textMuted)
        .lineHeight(16)
        .width('100%');
    }
    .width('100%');
  }

  @Builder
  private buildTransferScopeButton(scope: string, label: string) {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .fontSize(12)
      .backgroundColor(this.transferScope === scope ? this.palette().accent : this.palette().surface)
      .fontColor(this.transferScope === scope ? '#FFFFFF' : this.palette().textPrimary)
      .border({ color: this.transferScope === scope ? this.palette().accent : this.palette().border, width: 1 })
      .borderRadius(14)
      .onClick(() => {
        this.transferScope = scope;
        if (scope === 'selected') {
          this.ensureSelectedTransferMemo();
        } else {
          this.showTransferMemoPicker = false;
        }
        this.generateTransferPayload();
      });
  }

  @Builder
  private buildSelectedTransferMemoCard() {
    Column({ space: 8 }) {
      Text('当前选择')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%');

      if (this.hasSelectedTransferMemo()) {
        Text(this.selectedTransferMemoTitleText())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
        Text(this.selectedTransferMemoDetailText())
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .lineHeight(18)
          .width('100%');
        Text('默认选择最近更新的便签')
          .fontSize(11)
          .fontColor(this.palette().textMuted)
          .width('100%');
      } else {
        Text('暂无可投送便签')
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .width('100%');
      }

      Button(this.showTransferMemoPicker ? '收起列表' : '更换便签')
        .height(34)
        .width('100%')
        .backgroundColor(this.palette().surface)
        .fontColor(this.palette().accentStrong)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12)
        .enabled(this.getSortedTransferMemos().length > 0)
        .onClick(() => {
          this.showTransferMemoPicker = !this.showTransferMemoPicker;
        });

      if (this.showTransferMemoPicker) {
        this.buildTransferMemoPicker();
      }
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.palette().notePaper)
    .border({ color: this.palette().border, width: 1 })
    .borderRadius(12);
  }

  @Builder
  private buildTransferMemoPicker() {
    Column({ space: 6 }) {
      ForEach(this.getSortedTransferMemos(), (memo: Memo) => {
        this.buildTransferMemoPickerItem(memo);
      }, (memo: Memo) => memo.id.toString());
    }
    .width('100%')
    .constraintSize({ maxHeight: 220 });
  }

  @Builder
  private buildTransferMemoPickerItem(memo: Memo) {
    Button(`${this.transferMemoTitle(memo)}  ·  ${memo.tag ? memo.tag : '无标签'}  ·  ${this.formatTimestamp(memo.updatedAt)}`)
      .width('100%')
      .height(36)
      .fontSize(11)
      .backgroundColor(this.selectedTransferMemoId === memo.id ? this.palette().accentSoft : this.palette().surface)
      .fontColor(this.selectedTransferMemoId === memo.id ? this.palette().accentStrong : this.palette().textPrimary)
      .border({ color: this.palette().border, width: 1 })
      .borderRadius(10)
      .onClick(() => this.selectTransferMemo(memo.id));
  }

  @Builder
  private buildReceivePane() {
    Column({ space: 10 }) {
      Text('面对面接收')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%');

      Text('当前版本可通过粘贴投送内容完成导入验证；局域网搜索附近设备功能待接入。')
        .fontSize(12)
        .fontColor(this.palette().textMuted)
        .lineHeight(18)
        .width('100%');

      Button('搜索附近设备待接入')
        .width('100%')
        .height(42)
        .backgroundColor(this.palette().disabledBg)
        .fontColor(this.palette().disabledText)
        .borderRadius(14)
        .enabled(false);

      Text('备用：粘贴投送内容')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%');

      TextArea({ placeholder: '粘贴完整投送内容', text: this.transferImportText })
        .height(104)
        .backgroundColor(this.palette().notePaper)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12)
        .fontColor(this.palette().textPrimary)
        .fontSize(12)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onChange((value: string) => {
          this.transferImportText = value;
          this.pendingImportMemos = [];
          this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
        });

      Button('预览导入')
        .width('100%')
        .height(40)
        .backgroundColor(this.palette().accentSoft)
        .fontColor(this.palette().accentStrong)
        .borderRadius(14)
        .onClick(() => this.previewImportPayload());

      if (this.pendingImportMemos.length > 0) {
        Column({ space: 6 }) {
          Text('导入预览')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%');
          Text(this.importPreviewText())
            .fontSize(12)
            .fontColor(this.palette().textMuted)
            .lineHeight(18)
            .width('100%');
          this.buildImportPreviewTitles();
          Row({ space: 8 }) {
            Button('取消')
              .layoutWeight(1)
              .height(40)
              .backgroundColor(this.palette().surface)
              .fontColor(this.palette().textPrimary)
              .border({ color: this.palette().border, width: 1 })
              .borderRadius(14)
              .onClick(() => this.cancelImportPreview());

            Button('确认导入')
              .layoutWeight(1)
              .height(40)
              .backgroundColor(this.palette().accent)
              .fontColor('#FFFFFF')
              .borderRadius(14)
              .onClick(() => this.confirmImportPreview());
          }
          .width('100%');
        }
        .width('100%')
        .padding(10)
        .backgroundColor(this.palette().notePaper)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12);
      }
    }
    .width('100%');
  }

  @Builder
  private buildImportPreviewTitles() {
    Column({ space: 4 }) {
      Text('待导入便签')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%');
      ForEach(this.previewImportTitles(), (title: string) => {
        Text(title)
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');
      }, (title: string, index: number) => `${index}-${title}`);
      if (this.pendingImportMemos.length > 5) {
        Text(`还有 ${this.pendingImportMemos.length - 5} 条便签`)
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .width('100%');
      }
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor(this.palette().surface)
    .border({ color: this.palette().border, width: 1 })
    .borderRadius(10);
  }

  @Builder
  private buildDebugPane() {
    Column({ space: 10 }) {
      Text('完整投送包。可长按文本框全选复制，再到接收端粘贴预览导入。')
        .fontSize(12)
        .fontColor(this.palette().textMuted)
        .lineHeight(18)
        .width('100%');
      TextArea({ placeholder: '原始 JSON 投送包', text: this.transferPayload })
        .height(220)
        .backgroundColor(this.palette().notePaper)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12)
        .fontColor(this.palette().textPrimary)
        .fontSize(11)
        .fontFamily('monospace')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onChange((value: string) => {
          this.transferPayload = value;
        });
      Button('重新生成 JSON')
        .width('100%')
        .height(40)
        .backgroundColor(this.palette().accentSoft)
        .fontColor(this.palette().accentStrong)
        .borderRadius(14)
        .onClick(() => this.generateTransferPayload());
    }
    .width('100%');
  }


  @Builder
  private buildFloatingPinnedMemo() {
    Column({ space: 5 }) {
      if (this.floatingExpanded) {
        Text('已置顶')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().pinText);
        Text(this.floatingMemoTitle())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().pinText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(this.floatingMemoPreview())
          .fontSize(10)
          .fontColor(this.palette().pinText)
          .opacity(0.82)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      } else {
        Text('置顶')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().pinText);
      }
    }
    .width(this.floatingExpanded ? 156 : 58)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor(this.palette().pinBg)
    .border({ color: this.palette().noteBorder, width: 1 })
    .borderRadius(15)
    .shadow({ radius: 6, color: this.palette().noteShadow, offsetY: 2 })
    .position({ x: this.floatingX, y: this.floatingY })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 1 })
        .onActionStart(() => {
          this.dragStartFloatingX = this.floatingX;
          this.dragStartFloatingY = this.floatingY;
          this.floatingWasDragged = false;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (Math.abs(event.offsetX) > 1 || Math.abs(event.offsetY) > 1) {
            this.floatingWasDragged = true;
          }
          this.floatingX = this.clampFloatingX(this.dragStartFloatingX + event.offsetX);
          this.floatingY = this.clampFloatingY(this.dragStartFloatingY + event.offsetY);
        })
        .onActionEnd(() => {
          this.floatingX = this.getSnapX(this.floatingX);
          this.floatingY = this.clampFloatingY(this.floatingY);
        })
    )
    .onClick(() => this.handleFloatingMemoTap());
  }


  private palette(): ThemePalette {
    return resolveTheme(this.colorMode);
  }

  private async loadPersistentMemosForInitialAppear(): Promise<void> {
    const localMemos = await loadMemos();
    if (localMemos.length > 0) {
      const nextList = this.cloneMemoListForHome(localMemos);
      this.memos = nextList;
      this.updateMemoAppStorage(nextList);
      this.memosInitialized = true;
      return;
    }
    ensureMemoStoreInitialized();
    this.syncMemosFromAppStorage();
    this.memosInitialized = true;
  }

  private syncMemosFromAppStorage(): void {
    const storedMemos = AppStorage.Get<Memo[]>(MEMO_STORAGE_KEY);
    if (storedMemos !== undefined && storedMemos.length > 0) {
      this.memos = this.cloneMemoListForHome(storedMemos);
    }
  }

  private updateMemoAppStorage(nextList: Memo[]): void {
    if (AppStorage.Has(MEMO_STORAGE_KEY)) {
      AppStorage.Set(MEMO_STORAGE_KEY, nextList);
    } else {
      AppStorage.SetOrCreate(MEMO_STORAGE_KEY, nextList);
    }
  }

  private async startNewMemo(): Promise<void> {
    try {
      await router.pushUrl({ url: 'pages/EditMemo' });
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to navigate to new memo editor. Cause: %{public}s', JSON.stringify(error));
      this.showNewMemoForm = true;
    }
  }

  private cancelNewMemo(): void {
    this.resetNewMemoDraft();
    this.showNewMemoForm = false;
  }

  private confirmNewMemo(): void {
    const title = this.draftTitle.trim();
    if (title.length === 0) {
      this.formError = '请输入标题';
      return;
    }
    const preview = this.draftBodyPreview.trim().length > 0 ? this.draftBodyPreview.trim() : '空白便签';
    const textBlock = createTextBlock(1, preview);
    const newMemo: Memo = {
      id: generateNextMemoId(this.memos),
      title: normalizeMemoTitle(title),
      bodyPreview: preview,
      updatedAt: Date.now(),
      tag: this.draftTag.trim().length > 0 ? this.draftTag.trim() : undefined,
      blocks: [textBlock]
    };
    this.persistMemoList([newMemo].concat(this.memos), '已创建便签');
    this.cancelNewMemo();
  }

  private async confirmRemoveMemo(id: number): Promise<void> {
    try {
      const result = await prompt.showDialog({
        title: '删除便签？',
        message: '删除后将从当前设备移除。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#BA1A1A' }
        ]
      });
      if (result.index === 1) {
        this.removeMemo(id);
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Delete dialog failed. Cause: %{public}s', JSON.stringify(error));
    }
  }

  private removeMemo(id: number): void {
    this.persistMemoList(this.memos.filter((memo: Memo) => memo.id !== id), '已删除便签');
  }

  private togglePinned(id: number): void {
    let nextPinnedState: boolean = false;
    let beforePinnedAt: number = 0;
    let beforeUnpinnedAt: number = 0;
    let afterPinnedAt: number = 0;
    let afterUnpinnedAt: number = 0;
    let targetBeforePinned: boolean = false;
    let targetAfter: Memo | undefined = undefined;
    const changedAt = Date.now();
    const updatedList = this.memos.map((memo: Memo) => {
      if (memo.id !== id) {
        return this.cloneMemoForHome(memo);
      }
      targetBeforePinned = this.isMemoPinned(memo);
      beforePinnedAt = memo.pinnedAt === undefined ? 0 : memo.pinnedAt;
      beforeUnpinnedAt = memo.unpinnedAt === undefined ? 0 : memo.unpinnedAt;
      nextPinnedState = !targetBeforePinned;
      const updatedMemo: Memo = {
        id: memo.id,
        title: memo.title,
        bodyPreview: memo.bodyPreview,
        updatedAt: memo.updatedAt,
        isPinned: nextPinnedState,
        pinnedAt: nextPinnedState ? changedAt : memo.pinnedAt,
        unpinnedAt: nextPinnedState ? memo.unpinnedAt : changedAt,
        tag: memo.tag,
        blocks: memo.blocks
      };
      targetAfter = updatedMemo;
      afterPinnedAt = updatedMemo.pinnedAt === undefined ? 0 : updatedMemo.pinnedAt;
      afterUnpinnedAt = updatedMemo.unpinnedAt === undefined ? 0 : updatedMemo.unpinnedAt;
      return updatedMemo;
    });
    if (targetAfter === undefined) {
      return;
    }
    const message = this.isMemoPinned(targetAfter) ?
      `已置顶：${this.memoFeedbackLabel(targetAfter)}` :
      `已取消置顶：${this.memoFeedbackLabel(targetAfter)}`;
    this.logPinnedToggle(id, targetBeforePinned, beforePinnedAt, beforeUnpinnedAt, this.isMemoPinned(targetAfter), afterPinnedAt, afterUnpinnedAt, updatedList);
    this.persistMemoList(updatedList, message);
  }

  private persistMemoList(nextList: Memo[], message: string): void {
    this.memos = nextList;
    this.updateMemoAppStorage(nextList);
    if (message.length > 0) {
      this.feedbackMessage = message;
    }
    void saveMemos(nextList).catch((error: Error) => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to save memos. Cause: %{public}s', JSON.stringify(error));
      this.feedbackMessage = '保存失败，请稍后重试';
    });
  }

  private resetNewMemoDraft(): void {
    this.draftTitle = '';
    this.draftTag = '';
    this.draftBodyPreview = '';
    this.formError = '';
  }

  private async openMemo(memoId: number): Promise<void> {
    try {
      await router.pushUrl({
        url: 'pages/EditMemo',
        params: { memoId: memoId }
      });
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to navigate to EditMemo. Cause: %{public}s', JSON.stringify(error));
    }
  }

  private openTransferPanel(): void {
    this.transferMode = 'send';
    this.ensureSelectedTransferMemo();
    this.generateTransferPayload();
    this.transferImportText = '';
    this.pendingImportMemos = [];
    this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
    this.feedbackMessage = '';
    this.showTransferPanel = true;
  }

  private closeTransferPanel(): void {
    this.showTransferPanel = false;
  }

  private generateTransferPayload(): void {
    this.ensureSelectedTransferMemo();
    this.transferPayload = encodeTransferPackage(this.getTransferMemosForCurrentScope());
    this.feedbackMessage = '';
  }

  private previewImportPayload(): void {
    this.previewImportFromPayload(this.transferImportText.trim());
  }

  private previewImportFromPayload(payload: string): void {
    if (payload.length > MAX_TRANSFER_IMPORT_CHARS) {
      this.pendingImportMemos = [];
      this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
      this.feedbackMessage = '内容过大';
      return;
    }
    const result = decodeTransferPackage(payload);
    if (!result.success) {
      this.pendingImportMemos = [];
      this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
      this.feedbackMessage = this.classifyTransferDecodeFailure(payload);
      return;
    }
    this.pendingImportMemos = result.memos;
    this.pendingImportPreview = previewTransferImport(this.memos, result.memos);
    this.feedbackMessage = '请确认导入预览';
  }

  private classifyTransferDecodeFailure(payload: string): string {
    try {
      const parsed = JSON.parse(payload) as TransferHeader;
      if (parsed.protocol === 'instant-note-lan' && parsed.version !== 1) {
        return '投送协议版本不兼容';
      }
    } catch (error) {
      return '不是有效的 InstantNote 投送内容';
    }
    return '不是有效的 InstantNote 投送内容';
  }

  private cancelImportPreview(): void {
    this.pendingImportMemos = [];
    this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
    this.feedbackMessage = '已取消导入';
  }

  private confirmImportPreview(): void {
    if (this.pendingImportMemos.length === 0) {
      this.feedbackMessage = '请先预览投送内容';
      return;
    }
    const importedCount = this.pendingImportMemos.length;
    this.persistMemoList(mergeReceivedMemos(this.memos, this.pendingImportMemos), `导入成功：${importedCount} 条便签`);
    this.transferImportText = '';
    this.pendingImportMemos = [];
    this.pendingImportPreview = { addCount: 0, updateCount: 0, imageBlockCount: 0 };
  }

  private transferStatusText(): string {
    const summary = summarizeTransferPayload(this.getTransferMemosForCurrentScope(), this.transferPayload);
    return `${summary.memoCount} 条便签 / ${summary.textBlockCount} 段文本 / ${summary.imageBlockCount} 张图片 / ${summary.payloadBytes} 字符`;
  }

  private getTransferMemosForCurrentScope(): Memo[] {
    if (this.transferScope === 'selected') {
      const memo = this.getSelectedTransferMemo();
      return memo ? [memo] : [];
    }
    return this.memos;
  }

  private selectedTransferSummary() {
    const selectedMemos = this.getTransferMemosForCurrentScope();
    return summarizeTransferPayload(selectedMemos, encodeTransferPackage(selectedMemos));
  }

  private transferSendSummaryText(): string {
    const summary = this.selectedTransferSummary();
    return `${summary.memoCount} 条便签 / ${summary.textBlockCount} 段文本 / ${summary.imageBlockCount} 张图片 / ${summary.payloadBytes} 字符`;
  }

  private getSortedTransferMemos(): Memo[] {
    const sorted = this.memos.map((memo: Memo) => memo);
    return sorted.sort((left: Memo, right: Memo) => {
      if (right.updatedAt !== left.updatedAt) {
        return right.updatedAt - left.updatedAt;
      }
      return right.id - left.id;
    });
  }

  private getDefaultTransferMemo(): Memo | undefined {
    const sorted = this.getSortedTransferMemos();
    return sorted.length > 0 ? sorted[0] : undefined;
  }

  private getSelectedTransferMemo(): Memo | undefined {
    const selected = this.findMemoById(this.selectedTransferMemoId);
    if (selected) {
      return selected;
    }
    return this.getDefaultTransferMemo();
  }

  private ensureSelectedTransferMemo(): void {
    const selected = this.findMemoById(this.selectedTransferMemoId);
    if (selected) {
      return;
    }
    const fallback = this.getDefaultTransferMemo();
    this.selectedTransferMemoId = fallback ? fallback.id : -1;
  }

  private selectTransferMemo(memoId: number): void {
    this.selectedTransferMemoId = memoId;
    this.showTransferMemoPicker = false;
    this.generateTransferPayload();
  }

  private hasSelectedTransferMemo(): boolean {
    return this.getSelectedTransferMemo() !== undefined;
  }

  private selectedTransferMemoTitleText(): string {
    const memo = this.getSelectedTransferMemo();
    return memo ? this.transferMemoTitle(memo) : '暂无可投送便签';
  }

  private selectedTransferMemoDetailText(): string {
    const memo = this.getSelectedTransferMemo();
    if (!memo) {
      return '无标签 / 0 段文本 / 0 张图片';
    }
    const summary = summarizeTransferPayload([memo], encodeTransferPackage([memo]));
    const tagText = memo.tag && memo.tag.trim().length > 0 ? memo.tag : '无标签';
    return `${tagText} / ${summary.textBlockCount} 段文本 / ${summary.imageBlockCount} 张图片`;
  }

  private transferMemoTitle(memo: Memo): string {
    const title = memo.title.trim();
    return title.length > 0 ? title : '未命名便签';
  }

  private importPreviewText(): string {
    const imageText = this.pendingImportPreview.imageBlockCount > 0 ?
      `包含 ${this.pendingImportPreview.imageBlockCount} 个图片块；图片暂不支持跨设备恢复。` :
      '不包含图片块。';
    const total = this.pendingImportMemos.length;
    return `将导入 ${total} 条便签；新增 ${this.pendingImportPreview.addCount} 条，更新 ${this.pendingImportPreview.updateCount} 条。${imageText}`;
  }

  private previewImportTitles(): string[] {
    const titles: string[] = [];
    const count = Math.min(5, this.pendingImportMemos.length);
    for (let i = 0; i < count; i++) {
      titles.push(this.previewImportTitle(this.pendingImportMemos[i]));
    }
    return titles;
  }

  private previewImportTitle(memo: Memo): string {
    const title = memo.title.trim();
    if (title.length === 0) {
      return '未命名便签';
    }
    return title;
  }

  private dialogBodyHeight(): number {
    if (this.viewportHeight <= 0) {
      return 360;
    }
    return Math.max(260, Math.min(440, this.viewportHeight - 172));
  }

  private transferModeTitle(): string {
    if (this.transferMode === 'receive') {
      return '接收';
    }
    if (this.transferMode === 'debug') {
      return '调试 JSON';
    }
    return '发送';
  }

  private previewContent(memo: Memo): string {
    if (memo.blocks && memo.blocks.length > 0) {
      const preview = memoPreviewFromBlocks(memo.blocks);
      if (preview.length > 0) {
        return preview;
      }
      for (let i = 0; i < memo.blocks.length; i++) {
        if (memo.blocks[i].type === 'image') {
          return '图片便签';
        }
      }
    }
    if (memo.bodyPreview && memo.bodyPreview.length > 0) {
      return memo.bodyPreview;
    }
    return normalizeMemoPreview([]);
  }

  private isMemoPinned(memo: Memo): boolean {
    return memo.isPinned === true;
  }

  private memoRenderKey(memo: Memo): string {
    const pinnedKey = this.isMemoPinned(memo) ? 'pinned' : 'normal';
    const pinnedAtKey = memo.pinnedAt === undefined ? 0 : memo.pinnedAt;
    const unpinnedAtKey = memo.unpinnedAt === undefined ? 0 : memo.unpinnedAt;
    return `${memo.id}-${memo.updatedAt}-${pinnedKey}-${pinnedAtKey}-${unpinnedAtKey}`;
  }

  private cloneMemoForHome(memo: Memo): Memo {
    return {
      id: memo.id,
      title: memo.title,
      bodyPreview: memo.bodyPreview,
      updatedAt: memo.updatedAt,
      isPinned: memo.isPinned,
      pinnedAt: memo.pinnedAt,
      unpinnedAt: memo.unpinnedAt,
      tag: memo.tag,
      blocks: memo.blocks
    };
  }

  private cloneMemoListForHome(memos: Memo[]): Memo[] {
    return memos.map((memo: Memo) => this.cloneMemoForHome(memo));
  }

  private memoFeedbackLabel(memo: Memo): string {
    const title = normalizeMemoTitle(memo.title);
    if (memo.tag && memo.tag.trim().length > 0) {
      return `${title}（${memo.tag.trim()}）`;
    }
    return title;
  }

  private logPinnedToggle(
    id: number,
    beforePinned: boolean,
    beforePinnedAt: number,
    beforeUnpinnedAt: number,
    afterPinned: boolean,
    afterPinnedAt: number,
    afterUnpinnedAt: number,
    memos: Memo[]
  ): void {
    const sortedMemos = this.getSortedMemos(memos);
    let topItems = '';
    const count = Math.min(5, sortedMemos.length);
    for (let i = 0; i < count; i++) {
      const memo = sortedMemos[i];
      const item = `${memo.id}/${normalizeMemoTitle(memo.title)}/${this.isMemoPinned(memo) ? 'pinned' : 'normal'}`;
      topItems = topItems.length === 0 ? item : `${topItems}; ${item}`;
    }
    hilog.info(
      LOG_DOMAIN,
      LOG_TAG,
      'togglePinned id=%{public}d before=%{public}s/%{public}d/%{public}d after=%{public}s/%{public}d/%{public}d top=%{public}s',
      id,
      beforePinned ? 'true' : 'false',
      beforePinnedAt,
      beforeUnpinnedAt,
      afterPinned ? 'true' : 'false',
      afterPinnedAt,
      afterUnpinnedAt,
      topItems
    );
  }

  private compareMemosForHome(left: Memo, right: Memo): number {
    const leftPinned = this.isMemoPinned(left);
    const rightPinned = this.isMemoPinned(right);
    if (leftPinned !== rightPinned) {
      return leftPinned ? -1 : 1;
    }
    if (leftPinned && rightPinned) {
      const leftPinnedTime = left.pinnedAt === undefined ? left.updatedAt : left.pinnedAt;
      const rightPinnedTime = right.pinnedAt === undefined ? right.updatedAt : right.pinnedAt;
      const sortDiff = rightPinnedTime - leftPinnedTime;
      if (sortDiff !== 0) {
        return sortDiff;
      }
      return right.id - left.id;
    }
    const leftHasUnpinnedAt = left.unpinnedAt !== undefined;
    const rightHasUnpinnedAt = right.unpinnedAt !== undefined;
    if (leftHasUnpinnedAt !== rightHasUnpinnedAt) {
      return leftHasUnpinnedAt ? -1 : 1;
    }
    let leftNormalTime = left.updatedAt;
    let rightNormalTime = right.updatedAt;
    if (leftHasUnpinnedAt && left.unpinnedAt !== undefined) {
      leftNormalTime = left.unpinnedAt;
    }
    if (rightHasUnpinnedAt && right.unpinnedAt !== undefined) {
      rightNormalTime = right.unpinnedAt;
    }
    const sortDiff = rightNormalTime - leftNormalTime;
    if (sortDiff !== 0) {
      return sortDiff;
    }
    return right.id - left.id;
  }

  private getSortedMemos(memos: Memo[]): Memo[] {
    const sortedMemos = memos.map((memo: Memo) => memo);
    sortedMemos.sort((left: Memo, right: Memo) => {
      const sortDiff = this.compareMemosForHome(left, right);
      if (sortDiff !== 0) {
        return sortDiff;
      }
      return 0;
    });
    return sortedMemos;
  }

  private filteredMemos(): Memo[] {
    const keyword = this.searchKeyword.trim().toLowerCase();
    const filtered = keyword.length === 0 ?
      this.memos :
      this.memos.filter((memo: Memo) => this.memoSearchText(memo).includes(keyword));
    return this.getSortedMemos(filtered);
  }

  private memoSearchText(memo: Memo): string {
    let text = `${memo.title} ${memo.bodyPreview} ${memo.tag ? memo.tag : ''}`;
    for (let i = 0; i < memo.blocks.length; i++) {
      const block = memo.blocks[i];
      if (block.type === 'text') {
        text += ` ${block.content}`;
      }
    }
    return text.toLowerCase();
  }

  private firstPinnedMemo(): Memo | undefined {
    const sortedMemos = this.getSortedMemos(this.memos);
    for (let i = 0; i < sortedMemos.length; i++) {
      if (sortedMemos[i].isPinned === true) {
        return sortedMemos[i];
      }
    }
    return undefined;
  }

  private floatingMemoTitle(): string {
    const memo = this.firstPinnedMemo();
    return memo ? memo.title : '暂无置顶便签';
  }

  private floatingMemoPreview(): string {
    const memo = this.firstPinnedMemo();
    return memo ? this.previewContent(memo) : '点击便签卡片右上角圆点后，这里会显示摘要。';
  }

  private previewMemoId(): number {
    const memos = this.filteredMemos();
    return memos.length > 0 ? memos[0].id : 0;
  }

  private previewMemoTitle(): string {
    const memo = this.findMemoById(this.previewMemoId());
    return memo ? memo.title : '';
  }

  private previewMemoContent(): string {
    const memo = this.findMemoById(this.previewMemoId());
    return memo ? this.previewContent(memo) : '';
  }

  private findMemoById(id: number): Memo | undefined {
    for (let i = 0; i < this.memos.length; i++) {
      if (this.memos[i].id === id) {
        return this.memos[i];
      }
    }
    return undefined;
  }

  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    const pad = (value: number) => value.toString().padStart(2, '0');
    return `${pad(date.getMonth() + 1)}/${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  private getFloatingWidth(): number {
    return this.floatingExpanded ? 156 : 58;
  }

  private getFloatingHeight(): number {
    return this.floatingExpanded ? 76 : 36;
  }

  private clampFloatingX(value: number): number {
    const minX = 12;
    const maxX = this.viewportWidth > 0 ? Math.max(minX, this.viewportWidth - this.getFloatingWidth() - 12) : minX;
    if (value < minX) {
      return minX;
    }
    if (value > maxX) {
      return maxX;
    }
    return value;
  }

  private clampFloatingY(value: number): number {
    const minY = 12;
    const maxY = this.viewportHeight > 0 ? Math.max(minY, this.viewportHeight - this.getFloatingHeight() - 86) : minY;
    if (value < minY) {
      return minY;
    }
    if (value > maxY) {
      return maxY;
    }
    return value;
  }

  private getSnapX(currentX: number): number {
    if (this.viewportWidth <= 0) {
      return currentX;
    }
    const currentCenter = currentX + this.getFloatingWidth() / 2;
    return currentCenter < this.viewportWidth / 2 ? 12 : this.getRightSnapX();
  }

  private getRightSnapX(): number {
    if (this.viewportWidth <= 0) {
      return 12;
    }
    return Math.max(12, this.viewportWidth - this.getFloatingWidth() - 12);
  }

  private getBottomSnapY(): number {
    if (this.viewportHeight <= 0) {
      return 220;
    }
    return Math.max(12, this.viewportHeight - this.getFloatingHeight() - 86);
  }

  private handleFloatingMemoTap(): void {
    if (this.floatingWasDragged) {
      this.floatingWasDragged = false;
      return;
    }
    const pinnedMemo = this.firstPinnedMemo();
    if (this.floatingExpanded && pinnedMemo) {
      void this.openMemo(pinnedMemo.id);
      return;
    }
    this.floatingExpanded = !this.floatingExpanded;
    this.floatingX = this.clampFloatingX(this.floatingX);
    this.floatingY = this.clampFloatingY(this.floatingY);
  }
}
