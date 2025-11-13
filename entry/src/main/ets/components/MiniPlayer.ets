import { MusicItem } from '../models/MusicModels';
import MusicApiService from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import router from '@ohos.router';

@Component
export struct MiniPlayer {
  @Watch('onSongChange')
  @StorageLink('currentSong') currentSong: MusicItem | null = null;
  @StorageLink('playState') playState: PlayState = PlayState.IDLE;
  @State coverUrl: string = '';

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
  }

  // 🔥 修复：使用实例方法
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

  build() {
    if (this.currentSong) {
      Row() {
        // 封面
        if (this.coverUrl) {
          Image(this.coverUrl)
            .width(50)
            .height(50)
            .borderRadius(8)
            .backgroundColor('#F0F0F0')
        } else {
          Column() {
            Text('🎵')
              .fontSize(20)
              .opacity(0.5)
          }
          .width(50)
          .height(50)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')
          .justifyContent(FlexAlign.Center)
        }

        // 歌曲信息
        Column() {
          Text(this.currentSong.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.currentSong.artist)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 12, right: 12 })
        .alignItems(HorizontalAlign.Start)
        .onClick(() => {
          this.openPlayerPage();
        })

        // 播放按钮
        Button({ type: ButtonType.Circle }) {
          Text(this.playState === PlayState.PLAYING ? '⏸' : '▶')
            .fontSize(20)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor('#FF6B6B')
        .onClick(() => {
          this.togglePlay();
        })
      }
      .width('100%')
      .height(70)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
    }
  }
}
