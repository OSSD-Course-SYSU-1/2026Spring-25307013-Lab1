export type MemoImageAsset = 'background' | 'foreground' | 'startIcon';

export interface TextMemoBlock {
  id: number;
  type: 'text';
  content: string;
}

export interface ImageMemoBlock {
  id: number;
  type: 'image';
  asset?: MemoImageAsset;
  uri?: string;
  caption?: string;
}

export type MemoBlock = TextMemoBlock | ImageMemoBlock;

export interface Memo {
  id: number;
  title: string;
  bodyPreview: string;
  updatedAt: number;
  isPinned?: boolean;
  pinnedAt?: number;
  unpinnedAt?: number;
  tag?: string;
  blocks: MemoBlock[];
}

export const DEFAULT_MEMOS: Memo[] = [
  {
    id: 1,
    title: '人工智能系统课程',
    bodyPreview: 'Transformer 原理、注意力机制与实验提醒。',
    updatedAt: Date.now() - 1000 * 60 * 20,
    tag: 'CS402',
    blocks: [
      createTextBlock(1, 'Transformer 原理、注意力机制与实验提醒。'),
      createImageBlock(2, 'background'),
      createTextBlock(3, '实验三作业需要在周五中午前提交。')
    ]
  },
  {
    id: 2,
    title: '近现代史复习',
    bodyPreview: '博物馆参观照片与复习要点整理。',
    updatedAt: Date.now() - 1000 * 60 * 60 * 5,
    tag: 'HIST210',
    blocks: [
      createTextBlock(1, '博物馆参观照片与复习要点整理。'),
      createImageBlock(2, 'foreground'),
      createTextBlock(3, '记得补充新档案资料的引用。')
    ]
  },
  {
    id: 3,
    title: '化学实验准备',
    bodyPreview: '滴定实验器材检查与试剂记录。',
    updatedAt: Date.now() - 1000 * 60 * 60 * 24,
    tag: 'CHEM130',
    blocks: [
      createTextBlock(1, '滴定实验器材检查与试剂记录。'),
      createImageBlock(2, 'startIcon'),
      createTextBlock(3, '携带护目镜、实验服，并先校准 pH 探头。')
    ]
  }
];

export const MEMO_STORAGE_KEY: string = 'memoList';

export function ensureMemoStoreInitialized(): void {
  if (!AppStorage.Has(MEMO_STORAGE_KEY)) {
    AppStorage.SetOrCreate(MEMO_STORAGE_KEY, DEFAULT_MEMOS);
  }
}

export function generateNextMemoId(memos: Memo[]): number {
  let highest = 0;
  for (let i = 0; i < memos.length; i++) {
    const memo = memos[i];
    if (memo.id > highest) {
      highest = memo.id;
    }
  }
  return highest + 1;
}

export function createTextBlock(id: number, content: string): TextMemoBlock {
  return {
    id: id,
    type: 'text',
    content: content
  };
}

export function createImageBlock(id: number, asset?: MemoImageAsset, uri?: string): ImageMemoBlock {
  return {
    id: id,
    type: 'image',
    asset: asset,
    uri: uri
  };
}

export function cloneMemoBlocks(blocks: MemoBlock[]): MemoBlock[] {
  return blocks.map((block: MemoBlock) => {
    if (block.type === 'text') {
      return {
        id: block.id,
        type: 'text',
        content: block.content
      } as TextMemoBlock;
    }
    return {
      id: block.id,
      type: 'image',
      asset: block.asset,
      uri: block.uri,
      caption: block.caption
    } as ImageMemoBlock;
  });
}

export function memoPreviewFromBlocks(blocks: MemoBlock[]): string {
  for (let i = 0; i < blocks.length; i++) {
    const block = blocks[i];
    if (block.type === 'text' && block.content.trim().length > 0) {
      return block.content.trim();
    }
  }
  return '';
}

export function normalizeMemoTitle(title: string): string {
  const trimmed = title.trim();
  return trimmed.length > 0 ? trimmed : '未命名便签';
}

export function normalizeMemoPreview(blocks: MemoBlock[]): string {
  const preview = memoPreviewFromBlocks(blocks);
  return preview.length > 0 ? preview : '空白便签';
}

export function getNextBlockId(blocks: MemoBlock[]): number {
  let highest = 0;
  for (let i = 0; i < blocks.length; i++) {
    const block = blocks[i];
    if (block.id > highest) {
      highest = block.id;
    }
  }
  return highest + 1;
}
