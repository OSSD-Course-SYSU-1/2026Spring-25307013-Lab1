import { encodeTransferPackage } from './MemoTransfer';
import { Memo, MemoBlock, TextMemoBlock } from './MemoModel';
import { TransferLanSession } from './TransferLanSession';

export const TRANSFER_TEXT_PORT: number = 39127;

const REQUEST_TYPE_TEXT_PAYLOAD: string = 'instant-note-text-payload';
const ERROR_NOT_IMPLEMENTED: string = 'transport_not_implemented';
const ERROR_SESSION_MISMATCH: string = 'session_mismatch';
const ERROR_CODE_MISMATCH: string = 'transfer_code_mismatch';

export interface TransferTransportRequest {
  type: string;
  sessionId: string;
  transferCode: string;
}

export interface TransferTransportResponse {
  ok: boolean;
  message: string;
  payload: string;
  errorCode: string;
}

export enum TransferTransportServerState {
  Idle = 'idle',
  Listening = 'listening',
  Stopped = 'stopped',
  Failed = 'failed'
}

let currentServerState: TransferTransportServerState = TransferTransportServerState.Idle;
let currentSession: TransferLanSession | undefined = undefined;
let currentPayload: string = '';

export function sanitizeMemosForTextTransfer(memos: Memo[]): Memo[] {
  const sanitizedMemos: Memo[] = [];
  for (let i = 0; i < memos.length; i++) {
    const memo = memos[i];
    sanitizedMemos.push({
      id: memo.id,
      title: memo.title,
      bodyPreview: memo.bodyPreview,
      tag: memo.tag,
      updatedAt: memo.updatedAt,
      isPinned: memo.isPinned,
      blocks: sanitizeTextBlocks(memo.blocks)
    });
  }
  return sanitizedMemos;
}

export function createTextTransferPayload(memos: Memo[]): string {
  return encodeTransferPackage(sanitizeMemosForTextTransfer(memos));
}

export async function startTransferServer(session: TransferLanSession, memos: Memo[]): Promise<TransferTransportResponse> {
  currentSession = session;
  currentPayload = createTextTransferPayload(memos);
  currentServerState = TransferTransportServerState.Failed;
  return createFailureResponse(
    'TCP 监听服务尚未接入：本轮未猜测 @kit.NetworkKit socket server 的完整监听、连接和流式读写签名。',
    ERROR_NOT_IMPLEMENTED
  );
}

export async function stopTransferServer(): Promise<void> {
  currentServerState = TransferTransportServerState.Stopped;
  currentSession = undefined;
  currentPayload = '';
}

export async function requestTransferPayload(
  host: string,
  port: number,
  sessionId: string,
  transferCode: string
): Promise<TransferTransportResponse> {
  const request: TransferTransportRequest = {
    type: REQUEST_TYPE_TEXT_PAYLOAD,
    sessionId: sessionId,
    transferCode: transferCode
  };
  return createFailureResponse(
    `TCP 客户端尚未接入：未向 ${host}:${port} 发送 ${request.type} 请求，避免在 socket API 签名未完全确认前伪造传输成功。`,
    ERROR_NOT_IMPLEMENTED
  );
}

export function getTransferServerState(): TransferTransportServerState {
  return currentServerState;
}

export function createTransferResponseForRequest(request: TransferTransportRequest): TransferTransportResponse {
  if (currentSession === undefined) {
    return createFailureResponse('投送服务未开启。', ERROR_NOT_IMPLEMENTED);
  }
  if (request.sessionId !== currentSession.sessionId) {
    return createFailureResponse('投送会话不匹配。', ERROR_SESSION_MISMATCH);
  }
  if (request.transferCode !== currentSession.transferCode) {
    return createFailureResponse('确认码不匹配。', ERROR_CODE_MISMATCH);
  }
  return {
    ok: true,
    message: '文本投送 payload 已生成。',
    payload: currentPayload,
    errorCode: ''
  };
}

function sanitizeTextBlocks(blocks: MemoBlock[]): MemoBlock[] {
  const textBlocks: MemoBlock[] = [];
  for (let i = 0; i < blocks.length; i++) {
    const block = blocks[i];
    if (block.type === 'text') {
      const textBlock = block as TextMemoBlock;
      textBlocks.push({
        id: textBlock.id,
        type: 'text',
        content: textBlock.content
      });
    }
  }
  return textBlocks;
}

function createFailureResponse(message: string, errorCode: string): TransferTransportResponse {
  return {
    ok: false,
    message: message,
    payload: '',
    errorCode: errorCode
  };
}
