export enum DeploymentStatus {
  Supported = 'supported',
  Limited = 'limited',
  Planned = 'planned'
}

export interface PlatformTarget {
  name: string;
  status: DeploymentStatus;
  note: string;
}

export const PLATFORM_TARGETS: PlatformTarget[] = [
  { name: 'HarmonyOS Phone', status: DeploymentStatus.Supported, note: '当前工程原生支持' },
  { name: 'HarmonyOS Tablet', status: DeploymentStatus.Supported, note: '当前工程原生支持' },
  { name: 'HarmonyOS 2in1', status: DeploymentStatus.Supported, note: '当前工程原生支持' },
  { name: 'Android', status: DeploymentStatus.Planned, note: '需要独立 Android/Flutter 工程' },
  { name: 'Windows', status: DeploymentStatus.Planned, note: '需要桌面端工程' },
  { name: 'Linux', status: DeploymentStatus.Planned, note: '需要桌面端工程' },
  { name: 'macOS', status: DeploymentStatus.Planned, note: '需要桌面端工程' },
  { name: 'Web', status: DeploymentStatus.Planned, note: '需要 Web 工程' }
];

export function supportedPlatformSummary(): string {
  const supported: string[] = [];
  for (let i = 0; i < PLATFORM_TARGETS.length; i++) {
    if (PLATFORM_TARGETS[i].status === DeploymentStatus.Supported) {
      supported.push(PLATFORM_TARGETS[i].name);
    }
  }
  return supported.join(' / ');
}
