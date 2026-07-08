import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { createTextBlock, generateNextMemoId, Memo, normalizeMemoPreview, normalizeMemoTitle } from '../../main/ets/common/MemoModel';
import { decodeTransferPackage, encodeTransferPackage, mergeReceivedMemos, summarizeTransferPayload } from '../../main/ets/common/MemoTransfer';
import { DeploymentStatus, PLATFORM_TARGETS, PlatformTarget, supportedPlatformSummary } from '../../main/ets/common/PlatformTargets';
import { isExpandedWindow, resolveWindowClass, WindowClass } from '../../main/ets/common/ResponsiveLayout';
import { createTransferQrMatrix } from '../../main/ets/common/TransferQrMatrix';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('memoModelNormalizesEmptyContent', 0, () => {
      expect(normalizeMemoTitle('  ')).assertEqual('未命名便签');
      expect(normalizeMemoTitle('  课程笔记  ')).assertEqual('课程笔记');
      expect(normalizeMemoPreview([])).assertEqual('空白便签');
      expect(normalizeMemoPreview([createTextBlock(1, '  第一段内容  ')])).assertEqual('第一段内容');
    });

    it('memoModelGeneratesNextId', 0, () => {
      const memos: Memo[] = [
        buildMemo(4, 'A', 100),
        buildMemo(9, 'B', 200)
      ];
      expect(generateNextMemoId(memos)).assertEqual(10);
    });

    it('responsiveLayoutResolvesWindowClass', 0, () => {
      expect(resolveWindowClass(375)).assertEqual(WindowClass.Compact);
      expect(resolveWindowClass(720)).assertEqual(WindowClass.Medium);
      expect(resolveWindowClass(1200)).assertEqual(WindowClass.Expanded);
      expect(isExpandedWindow(1200)).assertTrue();
    });

    it('transferPackageDecodesAndMergesLatestMemo', 0, () => {
      const local: Memo[] = [buildMemo(1, '旧标题', 100)];
      const incoming: Memo[] = [buildMemo(1, '新标题', 200), buildMemo(2, '新增', 150)];
      const encoded = encodeTransferPackage(incoming);
      const decoded = decodeTransferPackage(encoded);
      const merged = mergeReceivedMemos(local, decoded.memos);

      expect(decoded.success).assertTrue();
      expect(merged.length).assertEqual(2);
      expect(merged[0].title).assertEqual('新标题');
      expect(merged[1].title).assertEqual('新增');
    });

    it('transferPackageRejectsInvalidInput', 0, () => {
      expect(decodeTransferPackage('').success).assertFalse();
      expect(decodeTransferPackage('not-json').success).assertFalse();
      expect(decodeTransferPackage('{"protocol":"instant-note-lan","version":1,"memos":[{"id":1}]}').success).assertFalse();
    });

    it('transferSummaryCountsBlocksAndPayload', 0, () => {
      const memos: Memo[] = [buildMemo(1, '投送', 100)];
      const payload = encodeTransferPackage(memos);
      const summary = summarizeTransferPayload(memos, payload);

      expect(summary.memoCount).assertEqual(1);
      expect(summary.textBlockCount).assertEqual(1);
      expect(summary.imageBlockCount).assertEqual(0);
      expect(summary.payloadBytes > 0).assertTrue();
    });

    it('transferQrMatrixKeepsStableSize', 0, () => {
      const matrix = createTransferQrMatrix('payload');

      expect(matrix.length).assertEqual(33);
      expect(matrix[0].length).assertEqual(33);
      expect(matrix[0][0]).assertTrue();
      expect(matrix[6][6]).assertTrue();
    });

    it('platformTargetsExposeSupportedHarmonyDevices', 0, () => {
      const supported = PLATFORM_TARGETS.filter((target: PlatformTarget) => target.status === DeploymentStatus.Supported);

      expect(supported.length).assertEqual(3);
      expect(supportedPlatformSummary()).assertEqual('HarmonyOS Phone / HarmonyOS Tablet / HarmonyOS 2in1');
    });
  });
}

function buildMemo(id: number, title: string, updatedAt: number): Memo {
  return {
    id: id,
    title: title,
    bodyPreview: title,
    updatedAt: updatedAt,
    blocks: [createTextBlock(1, title)]
  };
}
