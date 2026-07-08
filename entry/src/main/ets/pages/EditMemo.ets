import router from '@ohos.router';
import filePicker from '@ohos.file.picker';
import prompt from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemePalette, UI_TOKENS, resolveTheme } from '../common/AppTheme';
import { getEditorContentWidth, getPageSidePadding, isExpandedWindow } from '../common/ResponsiveLayout';
import {
  DEFAULT_MEMOS,
  MEMO_STORAGE_KEY,
  ImageMemoBlock,
  Memo,
  MemoBlock,
  MemoImageAsset,
  cloneMemoBlocks,
  createImageBlock,
  createTextBlock,
  ensureMemoStoreInitialized,
  generateNextMemoId,
  getNextBlockId,
  normalizeMemoPreview,
  normalizeMemoTitle
} from '../common/MemoModel';
import { saveMemos } from '../common/MemoStorage';

const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = 'InstantNote';
const AUTOSAVE_DELAY_MS: number = 800;
const SAVE_MESSAGE_RESET_MS: number = 1200;
const UNDO_LIMIT: number = 20;
const PHOTO_ASSET_SEQUENCE: MemoImageAsset[] = ['background', 'foreground', 'startIcon'];

interface MemoRouteParams {
  memoId?: number;
}

@Entry
@Component
struct EditMemo {
  @StorageLink('memoList') memoList: Memo[] = DEFAULT_MEMOS;
  @StorageLink('systemColorMode') colorMode: string = 'light';
  @State private title: string = '';
  @State private tag: string = '';
  @State private blocks: MemoBlock[] = [createTextBlock(1, '')];
  @State private lastSavedMessage: string = '自动保存已开启';
  @State private canUndo: boolean = false;
  @State private canRedo: boolean = false;
  @State private activeBlockId: number = -1;
  @State private viewportWidth: number = 0;
  @State private titleFocused: boolean = false;
  @State private tagFocused: boolean = false;
  @State private pressedTool: string = '';
  private memoId: number = 0;
  private autoSaveTimer: number = -1;
  private undoStack: string[] = [];
  private redoStack: string[] = [];
  private nextBlockId: number = 2;
  private photoAssetIndex: number = 0;
  private isNavigatingBack: boolean = false;
  private saveFailed: boolean = false;

  aboutToAppear(): void {
    ensureMemoStoreInitialized();
    this.loadMemoFromParams();
  }

  aboutToDisappear(): void {
    void this.flushPendingSave();
  }

  onBackPress(): boolean {
    void this.navigateBack();
    return true;
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        this.renderHeader();

        if (isExpandedWindow(this.viewportWidth)) {
          Row({ space: 18 }) {
            Column({ space: 12 }) {
              this.renderMetaCard();
              this.renderToolbar();
            }
            .width(320);

            this.renderEditorBody();
          }
          .layoutWeight(1)
          .width('100%');
        } else {
          this.renderToolbar();
          this.renderMetaCard();
          this.renderEditorBody();
        }
      }
      .width(getEditorContentWidth(this.viewportWidth))
      .height('100%')
      .padding({
        left: getPageSidePadding(this.viewportWidth),
        right: getPageSidePadding(this.viewportWidth),
        top: 16,
        bottom: 12
      });
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.palette().background)
    .onAreaChange((_: Area, newValue: Area) => {
      this.viewportWidth = Number(newValue.width);
    });
  }

  @Builder
  private renderHeader() {
    Row() {
      Column({ space: 4 }) {
        Text('快速记录')
          .fontSize(isExpandedWindow(this.viewportWidth) ? 28 : 24)
          .fontWeight(FontWeight.Bolder)
          .fontColor(this.palette().textPrimary);
        Text('内容优先，自动保存。')
          .fontSize(12)
          .fontColor(this.palette().textMuted)
          .lineHeight(18);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text(this.lastSavedMessage)
        .fontSize(11)
        .fontColor(this.palette().textMuted)
        .opacity(this.lastSavedMessage === '刚刚已保存' ? 1 : 0.72)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.palette().surface)
        .border({ color: this.palette().border, width: 1 })
        .borderRadius(12)
        .animation({ duration: 180, curve: Curve.EaseOut });
    }
    .width('100%');
  }

  @Builder
  private renderEditorBody() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text('正文内容')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().textPrimary);
              Text('支持多段文本和图片块，长按块可删除。')
                .fontSize(11)
                .fontColor(this.palette().textMuted);
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
          }

          Column({ space: 12 }) {
            ForEach(this.blocks, (block: MemoBlock) => {
              if (block.type === 'text') {
                this.renderTextBlock(block);
              } else {
                this.renderImageBlock(block);
              }
            }, (block: MemoBlock) => block.id.toString());
          }
        }
        .padding(12)
        .backgroundColor(this.palette().card)
        .border({ color: this.palette().noteBorder, width: 1 })
        .borderRadius(UI_TOKENS.radius.pageCard);
      }
      .width('100%')
      .padding({ bottom: 18 });
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1);
  }

  @Builder
  private renderMetaCard() {
    Column({ space: 8 }) {
      TextInput({ placeholder: '便签标题', text: this.title })
        .height(42)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.palette().surface)
        .border({ color: this.titleFocused ? this.palette().accent : this.palette().border, width: 1 })
        .borderRadius(UI_TOKENS.radius.input)
        .padding({ left: 12, right: 12 })
        .fontColor(this.palette().textPrimary)
        .shadow({ radius: this.titleFocused ? 6 : 0, color: this.palette().noteShadow, offsetY: 2 })
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onFocus(() => {
          this.titleFocused = true;
        })
        .onBlur(() => {
          this.titleFocused = false;
        })
        .onChange((value: string) => {
          this.title = value;
          this.queueAutosave();
        });

      TextInput({ placeholder: '标签（可选）', text: this.tag })
        .height(38)
        .fontSize(13)
        .backgroundColor(this.palette().surface)
        .border({ color: this.tagFocused ? this.palette().accent : this.palette().border, width: 1 })
        .borderRadius(14)
        .padding({ left: 12, right: 12 })
        .fontColor(this.palette().textPrimary)
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onFocus(() => {
          this.tagFocused = true;
        })
        .onBlur(() => {
          this.tagFocused = false;
        })
        .onChange((value: string) => {
          this.tag = value;
          this.queueAutosave();
        });
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.palette().card)
    .border({ color: this.palette().noteBorder, width: 1 })
    .borderRadius(UI_TOKENS.radius.pageCard);
  }

  @Builder
  private renderToolbar() {
    Scroll() {
      Row({ space: 8 }) {
        this.renderToolbarButton('back', '返回', true, false);
        this.renderToolbarButton('undo', '撤销', this.canUndo, false);
        this.renderToolbarButton('redo', '重做', this.canRedo, false);
        this.renderToolbarButton('text', '段落', true, false);
        this.renderToolbarButton('image', '图片', true, false);
        this.renderToolbarButton('done', '完成', true, true);
      }
      .padding({ left: 2, right: 2 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding(6)
    .backgroundColor(this.palette().toolbarBg)
    .border({ color: this.palette().noteBorder, width: 1 })
    .borderRadius(UI_TOKENS.radius.largeButton);
  }

  @Builder
  private renderToolbarButton(action: string, label: string, enabled: boolean, primary: boolean) {
    Button(label)
      .height(UI_TOKENS.buttonHeight.tool)
      .width(58)
      .fontSize(12)
      .backgroundColor(primary ? this.palette().accent : (enabled ? this.palette().surface : this.palette().disabledBg))
      .border({ color: primary ? this.palette().accent : (enabled ? this.palette().border : this.palette().disabledBg), width: 1 })
      .fontColor(primary ? '#FFFFFF' : (enabled ? this.palette().textPrimary : this.palette().disabledText))
      .borderRadius(UI_TOKENS.radius.smallButton)
      .fontWeight(primary ? FontWeight.Medium : FontWeight.Regular)
      .enabled(enabled)
      .scale({ x: this.pressedTool === action ? 0.96 : 1, y: this.pressedTool === action ? 0.96 : 1 })
      .opacity(this.pressedTool === action ? 0.86 : 1)
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && enabled) {
          this.pressedTool = action;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedTool = '';
        }
      })
      .onClick(() => this.handleToolbarAction(action));
  }

  @Builder
  private renderTextBlock(block: MemoBlock) {
    Column() {
      TextArea({
        placeholder: '写下此刻的想法...',
        text: this.getTextBlockContent(block.id)
      })
        .fontSize(16)
        .lineHeight(24)
        .height(isExpandedWindow(this.viewportWidth) ? 320 : 300)
        .backgroundColor(this.palette().notePaper)
        .border({ color: this.activeBlockId === block.id ? this.palette().accent : this.palette().noteBorder, width: 1 })
        .borderRadius(UI_TOKENS.radius.input)
        .fontColor(this.palette().textPrimary)
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .shadow({ radius: this.activeBlockId === block.id ? 7 : 0, color: this.palette().noteShadow, offsetY: 2 })
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onFocus(() => this.setFocusedBlock(block.id))
        .onChange((value: string) => this.updateTextBlockContent(block.id, value))
        .onBlur(() => {
          if (this.activeBlockId === block.id) {
            this.activeBlockId = -1;
          }
        });
    }
    .width('100%')
    .padding(6)
    .backgroundColor(this.palette().card)
    .border({
      color: this.activeBlockId === block.id ? this.palette().accentSoft : this.palette().noteBorder,
      width: 1
    })
    .borderRadius(UI_TOKENS.radius.largeButton)
    .gesture(
      LongPressGesture()
        .onAction(() => {
          void this.confirmBlockRemoval(block.id);
        })
    );
  }

  @Builder
  private renderImageBlock(block: ImageMemoBlock) {
    Column({ space: 6 }) {
      Image(this.resolveImageSource(block))
        .width('100%')
        .height(isExpandedWindow(this.viewportWidth) ? 260 : 176)
        .objectFit(ImageFit.Cover)
        .borderRadius(UI_TOKENS.radius.input)
        .backgroundColor(this.palette().disabledBg)
        .onClick(() => this.setFocusedBlock(block.id));
      Text(block.uri && block.uri.length > 0 ? '设备图片' : '内置图片')
        .fontSize(11)
        .fontColor(this.palette().textMuted)
        .opacity(0.68)
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .padding(8)
    .backgroundColor(this.palette().card)
    .border({ color: this.palette().noteBorder, width: 1 })
    .borderRadius(UI_TOKENS.radius.largeButton)
    .gesture(
      LongPressGesture()
        .onAction(() => {
          void this.confirmBlockRemoval(block.id);
        })
    );
  }

  private palette(): ThemePalette {
    return resolveTheme(this.colorMode);
  }

  private handleToolbarAction(action: string): void {
    if (action === 'back') {
      void this.navigateBack();
      return;
    }
    if (action === 'undo') {
      this.undo();
      return;
    }
    if (action === 'redo') {
      this.redo();
      return;
    }
    if (action === 'text') {
      this.handleInsertTextBlock();
      return;
    }
    if (action === 'image') {
      void this.handleInsertPhoto();
      return;
    }
    void this.navigateBack();
  }

  private getTextBlockContent(blockId: number): string {
    for (let i = 0; i < this.blocks.length; i++) {
      const block = this.blocks[i];
      if (block.type === 'text' && block.id === blockId) {
        return block.content;
      }
    }
    return '';
  }

  private getBlocksDebugText(): string {
    return this.formatBlocksDebugText(this.blocks);
  }

  private formatBlocksDebugText(blocks: MemoBlock[]): string {
    const parts: string[] = [];
    for (let i = 0; i < blocks.length; i++) {
      const block = blocks[i];
      if (block.type === 'text') {
        parts.push(`${block.id}:text:${block.content.length}`);
      } else {
        const uriLength = block.uri ? block.uri.length : 0;
        parts.push(`${block.id}:image:${uriLength}`);
      }
    }
    return parts.join('|');
  }

  private logBlocksChange(functionName: string, before: string): void {
    console.info(`[EditMemo] ${functionName} before=${before} after=${this.getBlocksDebugText()}`);
  }

  private loadMemoFromParams(): void {
    const before = this.getBlocksDebugText();
    const params = router.getParams() as MemoRouteParams;
    if (params && params.memoId !== undefined) {
      const existing = this.memoList.find((memo: Memo) => memo.id === params.memoId);
      if (existing) {
        this.memoId = existing.id;
        this.title = existing.title;
        this.tag = existing.tag ? existing.tag : '';
        this.blocks = existing.blocks && existing.blocks.length > 0 ?
          cloneMemoBlocks(existing.blocks) :
          [createTextBlock(1, existing.bodyPreview)];
        this.nextBlockId = getNextBlockId(this.blocks);
        this.activeBlockId = this.blocks.length > 0 ? this.blocks[0].id : 1;
        this.logBlocksChange('loadMemoFromParams(existing)', before);
        return;
      }
    }
    this.memoId = 0;
    this.title = '';
    this.tag = '';
    this.blocks = [createTextBlock(1, '')];
    this.nextBlockId = 2;
    this.activeBlockId = 1;
    this.logBlocksChange('loadMemoFromParams(new)', before);
  }

  private queueAutosave(): void {
    this.lastSavedMessage = '正在保存...';
    if (this.autoSaveTimer !== -1) {
      clearTimeout(this.autoSaveTimer);
    }
    this.autoSaveTimer = setTimeout(() => {
      void this.persistChanges();
    }, AUTOSAVE_DELAY_MS);
  }

  private async persistChanges(): Promise<void> {
    const normalizedBlocks = cloneMemoBlocks(this.blocks);
    const preview = normalizeMemoPreview(normalizedBlocks);
    const trimmedTag = this.tag.trim();
    const title = normalizeMemoTitle(this.title);
    const savedAt = Date.now();
    let updatedList: Memo[] = [];

    if (this.memoId > 0) {
      updatedList = this.memoList.map((memo: Memo) => {
        if (memo.id !== this.memoId) {
          return memo;
        }
        return {
          id: memo.id,
          title: title,
          bodyPreview: preview,
          updatedAt: savedAt,
          isPinned: memo.isPinned,
          pinnedAt: memo.pinnedAt,
          unpinnedAt: memo.unpinnedAt,
          tag: trimmedTag.length > 0 ? trimmedTag : undefined,
          blocks: normalizedBlocks
        };
      });
    } else {
      const newId = generateNextMemoId(this.memoList);
      const newMemo: Memo = {
        id: newId,
        title: title,
        bodyPreview: preview,
        updatedAt: savedAt,
        tag: trimmedTag.length > 0 ? trimmedTag : undefined,
        blocks: normalizedBlocks
      };
      updatedList = [newMemo].concat(this.memoList);
      this.memoId = newId;
    }

    this.memoList = updatedList;
    this.updateMemoAppStorage(updatedList);
    this.autoSaveTimer = -1;
    try {
      await saveMemos(updatedList);
      this.saveFailed = false;
      this.lastSavedMessage = '刚刚已保存';
      setTimeout(() => {
        if (this.lastSavedMessage === '刚刚已保存') {
          this.lastSavedMessage = '自动保存已开启';
        }
      }, SAVE_MESSAGE_RESET_MS);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to save memo. Cause: %{public}s', JSON.stringify(error));
      this.saveFailed = true;
      this.lastSavedMessage = '保存失败';
    }
  }

  private async flushPendingSave(): Promise<void> {
    if (this.autoSaveTimer !== -1) {
      clearTimeout(this.autoSaveTimer);
      this.autoSaveTimer = -1;
    }
    await this.persistChanges();
  }

  private async navigateBack(): Promise<void> {
    if (this.isNavigatingBack) {
      return;
    }
    this.isNavigatingBack = true;
    await this.flushPendingSave();
    if (this.saveFailed) {
      this.isNavigatingBack = false;
      return;
    }
    router.back();
  }

  private updateMemoAppStorage(nextList: Memo[]): void {
    if (AppStorage.Has(MEMO_STORAGE_KEY)) {
      AppStorage.Set(MEMO_STORAGE_KEY, nextList);
    } else {
      AppStorage.SetOrCreate(MEMO_STORAGE_KEY, nextList);
    }
  }

  private handleInsertTextBlock(): void {
    const before = this.getBlocksDebugText();
    const snapshot = JSON.stringify(this.blocks);
    const nextId = Math.max(this.nextBlockId, getNextBlockId(this.blocks));
    const newBlock = createTextBlock(nextId, '');
    const updatedBlocks: MemoBlock[] = [];
    for (let i = 0; i < this.blocks.length; i++) {
      updatedBlocks.push(this.blocks[i]);
    }
    updatedBlocks.push(newBlock);
    this.blocks = updatedBlocks;
    this.nextBlockId = nextId + 1;
    this.activeBlockId = newBlock.id;
    this.pushUndoSnapshot(snapshot);
    this.logBlocksChange('handleInsertTextBlock', before);
    this.queueAutosave();
  }

  private async handleInsertPhoto(): Promise<void> {
    try {
      const uri = await this.pickPhotoFromDevice();
      this.insertPhotoBlock(uri);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Photo picker failed. Cause: %{public}s', JSON.stringify(error));
      this.insertPhotoBlock();
    }
  }

  private async pickPhotoFromDevice(): Promise<string | undefined> {
    const picker = new filePicker.PhotoViewPicker();
    const options = new filePicker.PhotoSelectOptions();
    options.MIMEType = filePicker.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const result = await picker.select(options);
    if (result && result.photoUris && result.photoUris.length > 0) {
      return result.photoUris[0];
    }
    return undefined;
  }

  private insertPhotoBlock(fileUri?: string): void {
    this.recordUndoState();
    let asset: MemoImageAsset | undefined = undefined;
    if (!fileUri) {
      asset = PHOTO_ASSET_SEQUENCE[this.photoAssetIndex % PHOTO_ASSET_SEQUENCE.length];
      this.photoAssetIndex += 1;
    }
    this.insertBlockAfterActive(createImageBlock(this.nextBlockId++, asset, fileUri));
  }

  private insertBlockAfterActive(newBlock: MemoBlock): void {
    const before = this.getBlocksDebugText();
    const insertIndex = this.blocks.findIndex((block: MemoBlock) => block.id === this.activeBlockId);
    const updatedBlocks: MemoBlock[] = [];
    for (let i = 0; i < this.blocks.length; i++) {
      updatedBlocks.push(this.blocks[i]);
      if (i === insertIndex) {
        updatedBlocks.push(newBlock);
      }
    }
    if (insertIndex < 0) {
      updatedBlocks.push(newBlock);
    }
    this.blocks = updatedBlocks;
    this.activeBlockId = newBlock.id;
    this.logBlocksChange('insertBlockAfterActive', before);
    this.queueAutosave();
  }

  private updateTextBlockContent(blockId: number, value: string): void {
    const before = this.getBlocksDebugText();
    const snapshot = JSON.stringify(this.blocks);
    let changed: boolean = false;
    const updatedBlocks: MemoBlock[] = this.blocks.map((block: MemoBlock) => {
      if (block.type === 'text' && block.id === blockId) {
        if (block.content === value) {
          return block;
        }
        changed = true;
        return createTextBlock(block.id, value);
      }
      return block;
    });
    if (!changed) {
      return;
    }
    this.blocks = updatedBlocks;
    this.pushUndoSnapshot(snapshot);
    this.logBlocksChange('updateTextBlockContent', before);
    this.queueAutosave();
  }

  private setFocusedBlock(blockId: number): void {
    this.activeBlockId = blockId;
  }

  private cleanupInactiveEmptyTextBlocks(): void {
    const before = this.getBlocksDebugText();
    const filtered = this.blocks.filter((block: MemoBlock) => {
      if (block.type === 'text' && block.id !== this.activeBlockId) {
        return block.content.trim().length > 0;
      }
      return true;
    });
    if (filtered.length === this.blocks.length || filtered.length === 0) {
      return;
    }
    this.recordUndoState();
    this.blocks = filtered;
    if (!this.blocks.some((block: MemoBlock) => block.id === this.activeBlockId)) {
      this.activeBlockId = this.blocks[0].id;
    }
    this.nextBlockId = getNextBlockId(this.blocks);
    this.logBlocksChange('cleanupInactiveEmptyTextBlocks', before);
    this.queueAutosave();
  }

  private async confirmBlockRemoval(blockId: number): Promise<void> {
    if (this.blocks.length <= 1) {
      return;
    }
    try {
      const action = await prompt.showDialog({
        title: '删除这段内容？',
        message: '删除后将从当前便签中移除。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#BA1A1A' }
        ]
      });
      if (action.index === 1) {
        this.deleteBlock(blockId);
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Dialog failed. Cause: %{public}s', JSON.stringify(error));
    }
  }

  private deleteBlock(blockId: number): void {
    if (this.blocks.length <= 1) {
      return;
    }
    const before = this.getBlocksDebugText();
    this.recordUndoState();
    const remaining = this.blocks.filter((block: MemoBlock) => block.id !== blockId);
    this.blocks = remaining.length > 0 ? remaining : [createTextBlock(this.nextBlockId++, '')];
    this.activeBlockId = this.blocks[this.blocks.length - 1].id;
    this.logBlocksChange('deleteBlock', before);
    this.queueAutosave();
  }

  private recordUndoState(): void {
    this.pushUndoSnapshot(JSON.stringify(this.blocks));
  }

  private pushUndoSnapshot(snapshot: string): void {
    if (this.undoStack.length > 0 && this.undoStack[this.undoStack.length - 1] === snapshot) {
      return;
    }
    this.undoStack.push(snapshot);
    if (this.undoStack.length > UNDO_LIMIT) {
      this.undoStack.shift();
    }
    this.canUndo = this.undoStack.length > 0;
    this.redoStack = [];
    this.canRedo = false;
  }

  private undo(): void {
    if (!this.canUndo) {
      return;
    }
    const last = this.undoStack.pop();
    if (last !== undefined) {
      this.redoStack.push(JSON.stringify(this.blocks));
      this.restoreBlocksFromSnapshot(last);
      this.queueAutosave();
    }
    this.canUndo = this.undoStack.length > 0;
    this.canRedo = this.redoStack.length > 0;
  }

  private redo(): void {
    if (!this.canRedo) {
      return;
    }
    const next = this.redoStack.pop();
    if (next !== undefined) {
      this.undoStack.push(JSON.stringify(this.blocks));
      this.restoreBlocksFromSnapshot(next);
      this.queueAutosave();
    }
    this.canUndo = this.undoStack.length > 0;
    this.canRedo = this.redoStack.length > 0;
  }

  private restoreBlocksFromSnapshot(snapshot: string): void {
    const before = this.getBlocksDebugText();
    try {
      const parsed = JSON.parse(snapshot) as MemoBlock[];
      const restored: MemoBlock[] = parsed.map((block: MemoBlock) => {
        if (block.type === 'text') {
          return createTextBlock(block.id, block.content ? block.content : '');
        }
        return createImageBlock(block.id, block.asset, block.uri);
      });
      this.blocks = restored.length > 0 ? restored : [createTextBlock(1, '')];
      this.nextBlockId = getNextBlockId(this.blocks);
      this.activeBlockId = this.blocks[0].id;
      this.logBlocksChange('restoreBlocksFromSnapshot(success)', before);
    } catch (error) {
      this.blocks = [createTextBlock(1, '')];
      this.nextBlockId = 2;
      this.activeBlockId = 1;
      this.logBlocksChange('restoreBlocksFromSnapshot(fallback)', before);
    }
  }

  private resolveImageSource(block: ImageMemoBlock): Resource | string {
    if (block.uri && block.uri.length > 0) {
      return block.uri;
    }
    if (block.asset === 'foreground') {
      return $r('app.media.foreground');
    }
    if (block.asset === 'startIcon') {
      return $r('app.media.startIcon');
    }
    return $r('app.media.background');
  }
}
