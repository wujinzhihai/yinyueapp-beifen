import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import AudioPlayerService from '../services/AudioPlayerService'; // 🔥 新增

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');

    // 🔥 关键：应用销毁时释放播放器
    AudioPlayerService.getInstance().release()
      .then(() => {
        hilog.info(0x0000, 'testTag', 'AudioPlayer released successfully');
      })
      .catch((error: Error) => {
        hilog.error(0x0000, 'testTag', 'AudioPlayer release failed: %{public}s', error.message);
      });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');

    // 🔥 可选：后台时暂停播放
    const playerService = AudioPlayerService.getInstance();
    playerService.togglePlay().catch((error: Error) => {
      hilog.error(0x0000, 'testTag', 'Pause failed: %{public}s', error.message);
    });
  }
}
