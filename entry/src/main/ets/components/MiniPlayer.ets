/**
 * 🎵 迷你播放器组件
 *
 * 功能: 底部迷你播放器
 * - 显示当前播放歌曲信息
 * - 显示封面图片(带旋转动画)
 * - 播放/暂停控制
 * - 点击跳转到完整播放页面
 *
 * @author wujinzhihai
 * @github https://github.com/wujinzhihai
 */

import { MusicItem } from '../models/MusicModels';
import MusicApiService from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import router from '@ohos.router';

@Component
export struct MiniPlayer {
  @Watch('onSongChange')
  @StorageLink('currentSong') currentSong: MusicItem | null = null;
  @Watch('onPlayStateChange')
  @StorageLink('playState') playState: PlayState = PlayState.IDLE;
  @State coverUrl: string = '';
  @State rotateAngle: number = 0;

  private rotationTimer: number = -1;

  async onSongChange() {
    if (this.currentSong?.picId && this.currentSong?.source) {
      try {
        this.coverUrl = await MusicApiService.getPicUrl(
          this.currentSong.source,
          this.currentSong.picId,
          200
        );
      } catch (error) {
        console.error('[MiniPlayer] 获取封面失败:', error);
        this.coverUrl = '';
      }
    } else {
      this.coverUrl = '';
    }

    // 切歌时继续保持旋转（如果正在播放）
    if (this.playState === PlayState.PLAYING) {
      this.startRotation();
    }
  }

  onPlayStateChange() {
    if (this.playState === PlayState.PLAYING) {
      this.startRotation();
    } else {
      this.stopRotation();
    }
  }

  startRotation() {
    if (this.rotationTimer !== -1) {
      return; // 已在旋转
    }

    this.rotationTimer = setInterval(() => {
      this.rotateAngle += 2;
      if (this.rotateAngle >= 360) {
        this.rotateAngle -= 360;
      }
    }, 16);
  }

  stopRotation() {
    if (this.rotationTimer !== -1) {
      clearInterval(this.rotationTimer);
      this.rotationTimer = -1;
    }
  }

  togglePlay() {
    AudioPlayerService.getInstance().togglePlay();
  }

  openPlayerPage() {
    try {
      router.pushUrl({
        url: 'pages/PlayerPage'
      });
    } catch (error) {
      console.error('[MiniPlayer] 路由跳转失败:', error);
    }
  }

  aboutToDisappear() {
    this.stopRotation();
  }

  build() {
    Row() {
      // 封面 - 圆形持续旋转
      if (this.currentSong && this.coverUrl) {
        Image(this.coverUrl)
          .width(50)
          .height(50)
          .borderRadius(25)
          .backgroundColor('#F0F0F0')
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: this.rotateAngle
          })
          .onClick(() => {
            if (this.currentSong) {
              this.openPlayerPage();
            }
          })
      } else {
        Column() {
          Text('🎵')
            .fontSize(20)
            .opacity(0.5)
        }
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor('#F0F0F0')
        .justifyContent(FlexAlign.Center)
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.rotateAngle
        })
        .onClick(() => {
          if (this.currentSong) {
            this.openPlayerPage();
          }
        })
      }

      // 歌曲信息
      Column() {
        Text(this.currentSong ? this.currentSong.name : '暂无播放')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.currentSong ? this.currentSong.artist : '点击搜索歌曲')
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12, right: 12 })
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        if (this.currentSong) {
          this.openPlayerPage();
        }
      })

      // 播放/暂停按钮
      Button({ type: ButtonType.Circle }) {
        Text(this.playState === PlayState.PLAYING ? '⏸' : '▶')
          .fontSize(20)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor(this.currentSong ? '#FF6B6B' : '#CCCCCC')
      .onClick(() => {
        if (this.currentSong) {
          this.togglePlay();
        }
      })
    }
    .width('100%')
    .height(70)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetY: -4
    })
    .border({
      width: { top: 1 },
      color: '#F0F0F0'
    })
  }
}
