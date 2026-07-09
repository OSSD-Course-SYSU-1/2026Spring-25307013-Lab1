import { Memo } from './MemoModel';

const SESSION_DURATION_MS: number = 5 * 60 * 1000;

export interface TransferPayloadSummary {
  memoCount: number;
  textBlockCount: number;
  imageBlockCount: number;
  charCount: number;
}

export interface TransferLanSession {
  sessionId: string;
  deviceName: string;
  transferCode: string;
  token: string;
  createdAt: number;
  expiresAt: number;
  payloadSummary: TransferPayloadSummary;
}

export function createTransferPayloadSummary(memos: Memo[]): TransferPayloadSummary {
  let textBlockCount = 0;
  let imageBlockCount = 0;
  let charCount = 0;
  for (let i = 0; i < memos.length; i++) {
    const memo = memos[i];
    charCount += memo.title.length;
    charCount += memo.bodyPreview.length;
    if (memo.tag !== undefined) {
      charCount += memo.tag.length;
    }
    for (let j = 0; j < memo.blocks.length; j++) {
      const block = memo.blocks[j];
      if (block.type === 'text') {
        textBlockCount += 1;
        charCount += block.content.length;
      } else {
        imageBlockCount += 1;
        if (block.caption !== undefined) {
          charCount += block.caption.length;
        }
      }
    }
  }
  return {
    memoCount: memos.length,
    textBlockCount: textBlockCount,
    imageBlockCount: imageBlockCount,
    charCount: charCount
  };
}

export function createLocalTransferSession(memos: Memo[], deviceName: string): TransferLanSession {
  const createdAt = Date.now();
  return {
    sessionId: createSessionId(createdAt),
    deviceName: deviceName,
    transferCode: createTransferCode(),
    token: createSessionToken(createdAt),
    createdAt: createdAt,
    expiresAt: createdAt + SESSION_DURATION_MS,
    payloadSummary: createTransferPayloadSummary(memos)
  };
}

export function isTransferSessionExpired(session: TransferLanSession, now: number): boolean {
  return now >= session.expiresAt;
}

export function formatTransferCode(code: string): string {
  const digits = onlyDigits(code);
  if (digits.length <= 3) {
    return digits;
  }
  return `${digits.slice(0, 3)} ${digits.slice(3, 6)}`;
}

export function formatRemainingSeconds(session: TransferLanSession, now: number): string {
  const remainingMs = Math.max(0, session.expiresAt - now);
  const remainingSeconds = Math.ceil(remainingMs / 1000);
  const minutes = Math.floor(remainingSeconds / 60);
  const seconds = remainingSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

function createSessionId(createdAt: number): string {
  return `lan-${createdAt}-${randomDigits(6)}`;
}

function createTransferCode(): string {
  return randomDigits(6);
}

function createSessionToken(createdAt: number): string {
  return `token-${createdAt}-${randomDigits(12)}`;
}

function randomDigits(length: number): string {
  let value = '';
  for (let i = 0; i < length; i++) {
    value += Math.floor(Math.random() * 10).toString();
  }
  return value;
}

function onlyDigits(value: string): string {
  let digits = '';
  for (let i = 0; i < value.length; i++) {
    const char = value.charAt(i);
    if (char >= '0' && char <= '9') {
      digits += char;
    }
  }
  return digits;
}
