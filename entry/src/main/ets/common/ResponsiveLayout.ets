export enum WindowClass {
  Compact = 'compact',
  Medium = 'medium',
  Expanded = 'expanded'
}

const MEDIUM_WIDTH: number = 600;
const EXPANDED_WIDTH: number = 960;
const COMPACT_SIDE_PADDING: number = 16;
const MEDIUM_SIDE_PADDING: number = 24;
const EXPANDED_SIDE_PADDING: number = 32;
const MEDIUM_CONTENT_WIDTH: number = 760;
const EXPANDED_CONTENT_WIDTH: number = 1180;
const EDITOR_EXPANDED_WIDTH: number = 1040;
const DIALOG_MAX_WIDTH: number = 620;

export function resolveWindowClass(width: number): WindowClass {
  if (width >= EXPANDED_WIDTH) {
    return WindowClass.Expanded;
  }
  if (width >= MEDIUM_WIDTH) {
    return WindowClass.Medium;
  }
  return WindowClass.Compact;
}

export function isExpandedWindow(width: number): boolean {
  return resolveWindowClass(width) === WindowClass.Expanded;
}

export function isMediumWindow(width: number): boolean {
  return resolveWindowClass(width) === WindowClass.Medium;
}

export function isCompactWindow(width: number): boolean {
  return resolveWindowClass(width) === WindowClass.Compact;
}

export function getPageSidePadding(width: number): number {
  const windowClass = resolveWindowClass(width);
  if (windowClass === WindowClass.Expanded) {
    return EXPANDED_SIDE_PADDING;
  }
  if (windowClass === WindowClass.Medium) {
    return MEDIUM_SIDE_PADDING;
  }
  return COMPACT_SIDE_PADDING;
}

export function getContentWidth(width: number): string | number {
  const windowClass = resolveWindowClass(width);
  if (windowClass === WindowClass.Expanded) {
    return EXPANDED_CONTENT_WIDTH;
  }
  if (windowClass === WindowClass.Medium) {
    return MEDIUM_CONTENT_WIDTH;
  }
  return '100%';
}

export function getEditorContentWidth(width: number): string | number {
  if (resolveWindowClass(width) === WindowClass.Expanded) {
    return EDITOR_EXPANDED_WIDTH;
  }
  if (resolveWindowClass(width) === WindowClass.Medium) {
    return MEDIUM_CONTENT_WIDTH;
  }
  return '100%';
}

export function getDialogWidth(width: number): string | number {
  if (width >= DIALOG_MAX_WIDTH + COMPACT_SIDE_PADDING * 2) {
    return DIALOG_MAX_WIDTH;
  }
  return '92%';
}
