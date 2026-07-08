import { ImageMemoBlock, Memo, MemoBlock, TextMemoBlock, cloneMemoBlocks } from './MemoModel';

export interface TransferPackage {
  protocol: string;
  version: number;
  createdAt: number;
  source: string;
  memos: Memo[];
}

export interface TransferResult {
  success: boolean;
  message: string;
  memos: Memo[];
}

export interface TransferSummary {
  memoCount: number;
  textBlockCount: number;
  imageBlockCount: number;
  payloadBytes: number;
}

export interface TransferImportPreview {
  addCount: number;
  updateCount: number;
  imageBlockCount: number;
}

const TRANSFER_PROTOCOL: string = 'instant-note-lan';
const TRANSFER_VERSION: number = 1;
const SOURCE_NAME: string = 'InstantNote';
const MAX_TRANSFER_MEMOS: number = 500;
const MAX_TRANSFER_TEXT_LENGTH: number = 20000;
const MAX_SAFE_NUMBER: number = 9007199254740991;

export function createTransferPackage(memos: Memo[]): TransferPackage {
  return {
    protocol: TRANSFER_PROTOCOL,
    version: TRANSFER_VERSION,
    createdAt: Date.now(),
    source: SOURCE_NAME,
    memos: memos.map((memo: Memo) => cloneMemo(memo))
  };
}

export function encodeTransferPackage(memos: Memo[]): string {
  return JSON.stringify(createTransferPackage(memos));
}

export function summarizeTransferPayload(memos: Memo[], payload: string): TransferSummary {
  let textBlockCount = 0;
  let imageBlockCount = 0;
  for (let i = 0; i < memos.length; i++) {
    const blocks = memos[i].blocks;
    for (let j = 0; j < blocks.length; j++) {
      if (blocks[j].type === 'text') {
        textBlockCount += 1;
      } else {
        imageBlockCount += 1;
      }
    }
  }
  return {
    memoCount: memos.length,
    textBlockCount: textBlockCount,
    imageBlockCount: imageBlockCount,
    payloadBytes: payload.length
  };
}

export function decodeTransferPackage(raw: string): TransferResult {
  if (raw.trim().length === 0) {
    return failure('请先提供投送数据');
  }

  try {
    const parsed = JSON.parse(raw) as TransferPackage;
    if (!isValidPackage(parsed)) {
      return failure('投送数据格式无效');
    }
    return {
      success: true,
      message: `已接收 ${parsed.memos.length} 条便签`,
      memos: parsed.memos.map((memo: Memo) => cloneMemo(memo))
    };
  } catch (error) {
    return failure('投送数据无法解析');
  }
}

export function mergeReceivedMemos(current: Memo[], incoming: Memo[]): Memo[] {
  const merged: Memo[] = current.map((memo: Memo) => cloneMemo(memo));
  let nextMemoId = getMaxMemoId(merged) + 1;
  const importedAt = Date.now();
  for (let i = 0; i < incoming.length; i++) {
    const received = incoming[i];
    merged.push({
      id: nextMemoId,
      title: received.title,
      bodyPreview: received.bodyPreview,
      updatedAt: importedAt + i,
      isPinned: false,
      pinnedAt: undefined,
      unpinnedAt: undefined,
      tag: received.tag,
      blocks: cloneBlocksWithNewIds(received.blocks)
    });
    nextMemoId += 1;
  }
  return merged.sort((left: Memo, right: Memo) => right.updatedAt - left.updatedAt);
}

export function previewTransferImport(current: Memo[], incoming: Memo[]): TransferImportPreview {
  let imageBlockCount = 0;
  for (let i = 0; i < incoming.length; i++) {
    const received = incoming[i];
    for (let j = 0; j < received.blocks.length; j++) {
      if (received.blocks[j].type === 'image') {
        imageBlockCount += 1;
      }
    }
  }
  return {
    addCount: incoming.length,
    updateCount: 0,
    imageBlockCount: imageBlockCount
  };
}

function getMaxMemoId(memos: Memo[]): number {
  let maxId = 0;
  for (let i = 0; i < memos.length; i++) {
    if (memos[i].id > maxId) {
      maxId = memos[i].id;
    }
  }
  return maxId;
}

function cloneBlocksWithNewIds(blocks: MemoBlock[]): MemoBlock[] {
  const clonedBlocks: MemoBlock[] = [];
  for (let i = 0; i < blocks.length; i++) {
    const block = blocks[i];
    const nextBlockId = i + 1;
    if (block.type === 'text') {
      const textBlock = block as TextMemoBlock;
      clonedBlocks.push({
        id: nextBlockId,
        type: 'text',
        content: textBlock.content
      });
    } else {
      const imageBlock = block as ImageMemoBlock;
      clonedBlocks.push({
        id: nextBlockId,
        type: 'image',
        asset: imageBlock.asset,
        uri: imageBlock.uri,
        caption: imageBlock.caption
      });
    }
  }
  return clonedBlocks;
}

function cloneMemo(memo: Memo): Memo {
  return {
    id: memo.id,
    title: memo.title,
    bodyPreview: memo.bodyPreview,
    updatedAt: memo.updatedAt,
    isPinned: memo.isPinned,
    pinnedAt: memo.pinnedAt,
    unpinnedAt: memo.unpinnedAt,
    tag: memo.tag,
    blocks: cloneMemoBlocks(memo.blocks)
  };
}

function isValidPackage(value: TransferPackage): boolean {
  if (value === undefined ||
    value.protocol !== TRANSFER_PROTOCOL ||
    value.version !== TRANSFER_VERSION ||
    typeof value.createdAt !== 'number' ||
    typeof value.source !== 'string' ||
    !Array.isArray(value.memos) ||
    value.memos.length > MAX_TRANSFER_MEMOS) {
    return false;
  }

  for (let i = 0; i < value.memos.length; i++) {
    if (!isValidMemo(value.memos[i])) {
      return false;
    }
  }
  return true;
}

function isValidMemo(memo: Memo): boolean {
  if (memo === undefined ||
    !isPositiveNumber(memo.id) ||
    typeof memo.title !== 'string' ||
    typeof memo.bodyPreview !== 'string' ||
    !isNonNegativeNumber(memo.updatedAt) ||
    !Array.isArray(memo.blocks)) {
    return false;
  }

  if (memo.tag !== undefined && typeof memo.tag !== 'string') {
    return false;
  }
  if (memo.isPinned !== undefined && typeof memo.isPinned !== 'boolean') {
    return false;
  }
  if (memo.pinnedAt !== undefined && !isNonNegativeNumber(memo.pinnedAt)) {
    return false;
  }
  if (memo.unpinnedAt !== undefined && !isNonNegativeNumber(memo.unpinnedAt)) {
    return false;
  }

  for (let i = 0; i < memo.blocks.length; i++) {
    if (!isValidBlock(memo.blocks[i])) {
      return false;
    }
  }
  return true;
}

function isValidBlock(block: MemoBlock): boolean {
  if (block === undefined || !isPositiveNumber(block.id)) {
    return false;
  }
  if (block.type === 'text') {
    const textBlock = block as TextMemoBlock;
    return typeof textBlock.content === 'string' && textBlock.content.length <= MAX_TRANSFER_TEXT_LENGTH;
  }
  if (block.type === 'image') {
    const imageBlock = block as ImageMemoBlock;
    return (imageBlock.asset === undefined ||
      imageBlock.asset === 'background' ||
      imageBlock.asset === 'foreground' ||
      imageBlock.asset === 'startIcon') &&
      (imageBlock.uri === undefined || typeof imageBlock.uri === 'string') &&
      (imageBlock.caption === undefined || typeof imageBlock.caption === 'string');
  }
  return false;
}

function isPositiveNumber(value: number): boolean {
  return typeof value === 'number' && value > 0 && value <= MAX_SAFE_NUMBER;
}

function isNonNegativeNumber(value: number): boolean {
  return typeof value === 'number' && value >= 0 && value <= MAX_SAFE_NUMBER;
}

function failure(message: string): TransferResult {
  return {
    success: false,
    message: message,
    memos: []
  };
}
