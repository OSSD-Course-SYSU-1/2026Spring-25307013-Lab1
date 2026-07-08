import common from '@ohos.app.ability.common';

export interface ShareResult {
  success: boolean;
  message: string;
}

const SHARE_ACTION: string = 'ohos.want.action.sendData';
const SHARE_TYPE: string = 'text/plain';

export async function shareTransferPayload(context: common.UIAbilityContext, payload: string): Promise<ShareResult> {
  if (payload.trim().length === 0) {
    return {
      success: false,
      message: '没有可分享的投送数据'
    };
  }

  try {
    await context.startAbility({
      action: SHARE_ACTION,
      type: SHARE_TYPE,
      parameters: {
        title: 'InstantNote 投送',
        content: payload,
        text: payload,
        summary: 'InstantNote 便签投送数据'
      }
    });
    return {
      success: true,
      message: '已打开系统分享'
    };
  } catch (error) {
    return {
      success: false,
      message: '当前设备未能打开系统分享，请使用高级模式复制数据'
    };
  }
}
