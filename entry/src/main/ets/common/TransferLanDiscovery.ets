import { common } from '@kit.AbilityKit';
import { mdns } from '@kit.NetworkKit';
import { TransferLanSession } from './TransferLanSession';

const TRANSFER_PROTOCOL_VERSION: number = 1;
const TRANSFER_SERVICE_TYPE: string = '_instantnote._tcp';
const TRANSFER_SERVICE_PORT: number = 0;
const SERVICE_NAME_PREFIX: string = 'InstantNote';

let activeServiceInfo: mdns.LocalServiceInfo | undefined = undefined;
let activeContext: common.Context | undefined = undefined;
let activeDiscoveryService: mdns.DiscoveryService | undefined = undefined;
let activeSearchFinish: (() => void) | undefined = undefined;

export interface TransferDiscoveredPeer {
  sessionId: string;
  deviceName: string;
  transferCodeHint: string;
  expiresAt: number;
  memoCount: number;
  textBlockCount: number;
  imageBlockCount: number;
  charCount: number;
  protocolVersion: number;
  isCompatible: boolean;
}

export enum TransferDiscoveryState {
  Idle = 'idle',
  Advertising = 'advertising',
  Searching = 'searching',
  Stopped = 'stopped',
  Failed = 'failed'
}

export interface TransferDiscoveryError {
  code: string;
  message: string;
  recoverable: boolean;
}

export interface TransferDiscoveryOptions {
  serviceType: string;
  protocolVersion: number;
  searchTimeoutMs: number;
}

export async function startAdvertising(session: TransferLanSession): Promise<void> {
  await stopAdvertising();
  const context = getContext() as common.Context;
  const serviceInfo = createLocalServiceInfo(session);
  await mdns.addLocalService(context, serviceInfo);
  activeContext = context;
  activeServiceInfo = serviceInfo;
}

export async function stopAdvertising(): Promise<void> {
  if (activeContext === undefined || activeServiceInfo === undefined) {
    return;
  }
  try {
    await mdns.removeLocalService(activeContext, activeServiceInfo);
  } finally {
    activeContext = undefined;
    activeServiceInfo = undefined;
  }
}

export async function searchPeers(timeoutMs: number): Promise<TransferDiscoveredPeer[]> {
  await stopSearch();
  if (timeoutMs <= 0) {
    return [];
  }
  const context = getContext() as common.Context;
  const discoveryService = mdns.createDiscoveryService(context, TRANSFER_SERVICE_TYPE);
  const discoveredPeers: TransferDiscoveredPeer[] = [];
  activeDiscoveryService = discoveryService;

  return new Promise<TransferDiscoveredPeer[]>((resolve) => {
    let isFinished = false;
    const finishSearch = (): void => {
      if (isFinished) {
        return;
      }
      isFinished = true;
      clearTimeout(timerId);
      try {
        discoveryService.stopSearchingMDNS();
      } finally {
        if (activeDiscoveryService === discoveryService) {
          activeDiscoveryService = undefined;
          activeSearchFinish = undefined;
        }
        resolve(filterCurrentPeers(discoveredPeers));
      }
    };
    const timerId = setTimeout(() => {
      finishSearch();
    }, timeoutMs);

    activeSearchFinish = finishSearch;
    discoveryService.on('serviceFound', (serviceInfo: mdns.LocalServiceInfo) => {
      if (isFinished || serviceInfo.serviceType !== TRANSFER_SERVICE_TYPE) {
        return;
      }
      mdns.resolveLocalService(context, serviceInfo).then((resolvedInfo: mdns.LocalServiceInfo) => {
        if (isFinished) {
          return;
        }
        const peer = createDiscoveredPeer(resolvedInfo);
        if (peer === undefined) {
          return;
        }
        upsertDiscoveredPeer(discoveredPeers, peer);
      }).catch(() => {
        return;
      });
    });
    discoveryService.on('serviceLost', (serviceInfo: mdns.LocalServiceInfo) => {
      removeDiscoveredPeer(discoveredPeers, serviceInfo);
    });
    discoveryService.startSearchingMDNS();
  });
}

export async function stopSearch(): Promise<void> {
  if (activeSearchFinish !== undefined) {
    activeSearchFinish();
    return;
  }
  if (activeDiscoveryService === undefined) {
    return;
  }
  try {
    activeDiscoveryService.stopSearchingMDNS();
  } finally {
    activeDiscoveryService = undefined;
  }
}

function createLocalServiceInfo(session: TransferLanSession): mdns.LocalServiceInfo {
  return {
    serviceName: createServiceName(session),
    serviceType: TRANSFER_SERVICE_TYPE,
    port: TRANSFER_SERVICE_PORT
  };
}

function createServiceName(session: TransferLanSession): string {
  const safeId = createSafeShortId(session.sessionId);
  const codeHint = createTransferCodeHint(session.transferCode);
  return `${SERVICE_NAME_PREFIX}-${safeId}-${codeHint}`;
}

function createSafeShortId(value: string): string {
  let safeValue = '';
  for (let i = 0; i < value.length; i++) {
    const char = value.charAt(i);
    if ((char >= '0' && char <= '9') || (char >= 'A' && char <= 'Z') || (char >= 'a' && char <= 'z')) {
      safeValue += char;
    }
  }
  if (safeValue.length <= 8) {
    return safeValue;
  }
  return safeValue.slice(safeValue.length - 8);
}

function createTransferCodeHint(code: string): string {
  if (code.length <= 2) {
    return code;
  }
  return code.slice(code.length - 2);
}

function createDiscoveredPeer(serviceInfo: mdns.LocalServiceInfo): TransferDiscoveredPeer | undefined {
  if (serviceInfo.serviceType !== TRANSFER_SERVICE_TYPE) {
    return undefined;
  }
  const sessionId = createSessionIdFromServiceName(serviceInfo.serviceName);
  if (sessionId.length === 0) {
    return undefined;
  }
  const transferCodeHint = createCodeHintFromServiceName(serviceInfo.serviceName);
  return {
    sessionId: sessionId,
    deviceName: createDeviceNameFromServiceName(serviceInfo.serviceName),
    transferCodeHint: transferCodeHint,
    expiresAt: Date.now() + 60 * 1000,
    memoCount: 0,
    textBlockCount: 0,
    imageBlockCount: 0,
    charCount: 0,
    protocolVersion: TRANSFER_PROTOCOL_VERSION,
    isCompatible: true
  };
}

function createSessionIdFromServiceName(serviceName: string): string {
  if (!serviceName.startsWith(`${SERVICE_NAME_PREFIX}-`)) {
    return '';
  }
  return serviceName;
}

function upsertDiscoveredPeer(peers: TransferDiscoveredPeer[], peer: TransferDiscoveredPeer): void {
  for (let i = 0; i < peers.length; i++) {
    if (peers[i].sessionId === peer.sessionId) {
      peers[i] = peer;
      return;
    }
  }
  peers.push(peer);
}

function removeDiscoveredPeer(peers: TransferDiscoveredPeer[], serviceInfo: mdns.LocalServiceInfo): void {
  const sessionId = createSessionIdFromServiceName(serviceInfo.serviceName);
  if (sessionId.length === 0) {
    return;
  }
  for (let i = peers.length - 1; i >= 0; i--) {
    if (peers[i].sessionId === sessionId) {
      peers.splice(i, 1);
    }
  }
}

function createCodeHintFromServiceName(serviceName: string): string {
  const lastDashIndex = serviceName.lastIndexOf('-');
  if (lastDashIndex < 0 || lastDashIndex >= serviceName.length - 1) {
    return '--';
  }
  const value = serviceName.slice(lastDashIndex + 1);
  if (value.length === 0 || value.length > 2) {
    return '--';
  }
  return value;
}

function createDeviceNameFromServiceName(serviceName: string): string {
  if (serviceName.startsWith(SERVICE_NAME_PREFIX)) {
    return 'InstantNote 设备';
  }
  return '附近设备';
}

function filterCurrentPeers(peers: TransferDiscoveredPeer[]): TransferDiscoveredPeer[] {
  const currentPeers: TransferDiscoveredPeer[] = [];
  const now = Date.now();
  for (let i = 0; i < peers.length; i++) {
    if (peers[i].expiresAt > now) {
      currentPeers.push(peers[i]);
    }
  }
  return currentPeers;
}
