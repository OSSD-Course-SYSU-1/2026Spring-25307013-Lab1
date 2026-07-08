import { Memo, MemoBlock, createTextBlock } from './MemoModel';
import { encodeTransferPackage, summarizeTransferPayload, TransferSummary } from './MemoTransfer';

export const MAX_STANDARD_QR_PAYLOAD_CHARS: number = 1200;
export const QR_TOO_LARGE_MESSAGE: string = '内容过大，请减少投送范围或使用后续局域网投送';

export interface TransferQrPayload {
  payload: string;
  summary: TransferSummary;
  imageBlockCount: number;
  canGenerate: boolean;
  message: string;
}

export function prepareTransferQrPayload(memos: Memo[]): TransferQrPayload {
  const qrMemos = removeImageBlocks(memos);
  const payload = encodeTransferPackage(qrMemos);
  const summary = summarizeTransferPayload(qrMemos, payload);
  const imageBlockCount = countImageBlocks(memos);
  const canGenerate = payload.length <= MAX_STANDARD_QR_PAYLOAD_CHARS;
  return {
    payload: payload,
    summary: summary,
    imageBlockCount: imageBlockCount,
    canGenerate: canGenerate,
    message: canGenerate ? imageWarningText(imageBlockCount) : QR_TOO_LARGE_MESSAGE
  };
}

function removeImageBlocks(memos: Memo[]): Memo[] {
  const result: Memo[] = [];
  for (let i = 0; i < memos.length; i++) {
    const memo = memos[i];
    const blocks: MemoBlock[] = [];
    for (let j = 0; j < memo.blocks.length; j++) {
      const block = memo.blocks[j];
      if (block.type === 'text') {
        blocks.push(createTextBlock(block.id, block.content));
      }
    }
    result.push({
      id: memo.id,
      title: memo.title,
      bodyPreview: memo.bodyPreview,
      updatedAt: memo.updatedAt,
      isPinned: memo.isPinned,
      tag: memo.tag,
      blocks: blocks
    });
  }
  return result;
}

function countImageBlocks(memos: Memo[]): number {
  let count = 0;
  for (let i = 0; i < memos.length; i++) {
    for (let j = 0; j < memos[i].blocks.length; j++) {
      if (memos[i].blocks[j].type === 'image') {
        count += 1;
      }
    }
  }
  return count;
}

function imageWarningText(imageBlockCount: number): string {
  if (imageBlockCount > 0) {
    return '图片暂不随扫码投送';
  }
  return '';
}
