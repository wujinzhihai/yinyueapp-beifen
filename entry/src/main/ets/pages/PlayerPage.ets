import MusicApiService, { MusicItem, LyricData } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import { LyricParser, LyricLine } from '../utils/LyricParser';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct PlayerPage {
  @Watch('onSongChange')
  @StorageLink('currentSong') currentSong: MusicItem | null = null;
  @StorageLink('playState') playState: PlayState = PlayState.IDLE;
  @Watch('onTimeChange')
  @StorageLink('currentTime') currentTime: number = 0;
  @StorageLink('duration') duration: number = 0;
  @StorageLink('currentIndex') currentIndex: number = -1;
  @StorageLink('playlist') playlist: MusicItem[] = [];

  @State coverUrl: string = '';
  @State lyrics: LyricLine[] = [];
  @State currentLyricIndex: number = -1;
  @State selectedQuality: number = 320;
  @State isUserDragging: boolean = false;
  @State showQualityMenu: boolean = false;

  private scroller: Scroller = new Scroller();

  async onSongChange() {
    if (this.currentSong?.picId && this.currentSong?.source) {
      try {
        this.coverUrl = await MusicApiService.getPicUrl(
          this.currentSong.source,
          this.currentSong.picId,
          500
        );
      } catch (error) {
        console.error('[PlayerPage] 获取封面失败:', error);
        this.coverUrl = '';
      }
    } else {
      this.coverUrl = '';
    }

    await this.loadLyrics();
    this.currentLyricIndex = -1;
  }

  onTimeChange() {
    this.updateLyricHighlight();
  }

  async loadLyrics() {
    if (!this.currentSong) return;

    try {
      const lyricData = await MusicApiService.getLyric(
        this.currentSong.source,
        this.currentSong.lyricId || this.currentSong.id
      );

      if (lyricData && lyricData.lyric) {
        this.lyrics = LyricParser.parse(lyricData.lyric);
        console.info('[PlayerPage] 歌词加载成功');
      } else {
        this.lyrics = [];
      }
    } catch (error) {
      console.error('[PlayerPage] 加载歌词失败:', error);
      this.lyrics = [];
    }
  }

  updateLyricHighlight() {
    if (this.lyrics.length === 0) return;

    const newIndex = LyricParser.getCurrentIndex(this.lyrics, this.currentTime);

    if (newIndex !== this.currentLyricIndex) {
      this.currentLyricIndex = newIndex;

      if (newIndex >= 0 && !this.isUserDragging) {
        this.scroller.scrollToIndex(newIndex, true, ScrollAlign.CENTER);
      }
    }
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  togglePlay() {
    AudioPlayerService.getInstance().togglePlay();
  }
  previousSong() {
    if (this.currentIndex > 0) {
      AudioPlayerService.getInstance().previous();
    } else {
      promptAction.showToast({ message: '已经是第一首歌曲' });
    }
  }

  nextSong() {
    if (this.currentIndex < this.playlist.length - 1) {
      AudioPlayerService.getInstance().next();
    } else {
      promptAction.showToast({ message: '已经是最后一首歌曲' });
    }
  }

  onProgressChange(value: number) {
    this.isUserDragging = true;
    AudioPlayerService.getInstance().seek(value);
    setTimeout(() => {
      this.isUserDragging = false;
    }, 500);
  }

  // 🔥 修复：quality 参数改为 number 类型
  changeQuality(quality: number) {
    this.selectedQuality = quality;
    AudioPlayerService.getInstance().setQuality(quality);

    if (this.currentSong) {
      const currentTime = this.currentTime;
      AudioPlayerService.getInstance().play(this.currentSong, this.playlist, this.currentIndex)
        .then(() => {
          AudioPlayerService.getInstance().seek(currentTime);
          promptAction.showToast({ message: '音质切换成功' });
        });
    }
    this.showQualityMenu = false;
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text('←')
            .fontSize(24)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          router.back();
        })

        Text(this.currentSong?.name || '播放器')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 12, right: 12 })

        Button({ type: ButtonType.Normal }) {
          Row() {
            Text(this.selectedQuality === 128 ? '标准'
              : this.selectedQuality === 192 ? '较高'
                : this.selectedQuality === 320 ? '高品'
                  : '无损')
              .fontSize(12)
              .fontColor('#FF6B6B')
            Text(' ▼')
              .fontSize(10)
              .fontColor('#FF6B6B')
          }
        }
        .width(80)
        .height(36)
        .backgroundColor('#FFF0F0')
        .borderRadius(18)
        .onClick(() => {
          this.showQualityMenu = !this.showQualityMenu;
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .zIndex(10)

      // 音质选择菜单
      if (this.showQualityMenu) {
        Column() {
          Button('标准 128K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 128 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 128 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(128))

          Divider().height(1).color('#F0F0F0')

          Button('较高 192K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 192 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 192 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(192))

          Divider().height(1).color('#F0F0F0')

          Button('高品 320K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 320 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 320 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(320))

          Divider().height(1).color('#F0F0F0')

          Button('无损 FLAC')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 999 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 999 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(999))
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 16, color: '#1F000000' })
        .position({ x: '5%', y: 70 })
        .zIndex(20)
      }

      Scroll() {
        Column() {
          // 封面
          Column() {
            if (this.coverUrl) {
              Image(this.coverUrl)
                .width(280)
                .height(280)
                .borderRadius(20)
                .backgroundColor('#F0F0F0')
            } else {
              Column() {
                Text('🎵')
                  .fontSize(80)
                  .opacity(0.3)
              }
              .width(280)
              .height(280)
              .borderRadius(20)
              .backgroundColor('#F0F0F0')
              .justifyContent(FlexAlign.Center)
            }
          }
          .margin({ top: 40, bottom: 30 })

          // 歌曲信息
          Text(this.currentSong?.name || '未知歌曲')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('90%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 8 })

          Text(this.currentSong
            ? `${this.currentSong.artist} · ${this.currentSong.album || '未知专辑'}`
            : '未知歌手')
            .fontSize(14)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('90%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 30 })

          // 进度条
          Column() {
            Slider({
              value: this.currentTime,
              min: 0,
              max: this.duration || 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#FF6B6B')
              .trackColor('#EEEEEE')
              .selectedColor('#FF6B6B')
              .showSteps(false)
              .showTips(false)
              .onChange((value) => {
                this.onProgressChange(value);
              })

            Row() {
              Text(this.formatTime(this.currentTime))
                .fontSize(12)
                .fontColor('#999999')

              Text(this.formatTime(this.duration))
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 8 })
          }
          .width('90%')
          .margin({ bottom: 30 })

          // 控制按钮
          Row() {
            Button({ type: ButtonType.Circle }) {
              Text('⏮')
                .fontSize(24)
                .fontColor('#333333')
            }
            .width(50)
            .height(50)
            .backgroundColor('#F5F5F5')
            .enabled(this.currentIndex > 0)
            .opacity(this.currentIndex > 0 ? 1 : 0.5)
            .onClick(() => {
              this.previousSong();
            })

            Button({ type: ButtonType.Circle }) {
              Text(this.playState === PlayState.PLAYING ? '⏸' : '▶')
                .fontSize(32)
                .fontColor('#FFFFFF')
            }
            .width(70)
            .height(70)
            .backgroundColor('#FF6B6B')
            .margin({ left: 30, right: 30 })
            .onClick(() => {
              this.togglePlay();
            })

            Button({ type: ButtonType.Circle }) {
              Text('⏭')
                .fontSize(24)
                .fontColor('#333333')
            }
            .width(50)
            .height(50)
            .backgroundColor('#F5F5F5')
            .enabled(this.currentIndex < this.playlist.length - 1)
            .opacity(this.currentIndex < this.playlist.length - 1 ? 1 : 0.5)
            .onClick(() => {
              this.nextSong();
            })
          }
          .margin({ bottom: 40 })

          // 歌词区域
          Column() {
            Row() {
              Text('歌词')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)

              Text(`${this.currentIndex + 1} / ${this.playlist.length}`)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ left: 8 })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 16 })

            if (this.lyrics.length > 0) {
              List({ space: 12, scroller: this.scroller }) {
                ForEach(this.lyrics, (lyric: LyricLine, index: number) => {
                  ListItem() {
                    Text(lyric.text)
                      .fontSize(this.currentLyricIndex === index ? 18 : 14)
                      .fontColor(this.currentLyricIndex === index ? '#FF6B6B' : '#999999')
                      .fontWeight(this.currentLyricIndex === index ? FontWeight.Bold : FontWeight.Normal)
                      .textAlign(TextAlign.Center)
                      .width('100%')
                      .transition({ type: TransitionType.All, opacity: 1 })
                      .animation({ duration: 300 })
                  }
                }, (lyric: LyricLine) => lyric.time.toString())
              }
              .width('100%')
              .height(300)
              .scrollBar(BarState.Off)
            } else {
              Column() {
                Text('🎵')
                  .fontSize(40)
                  .opacity(0.3)
                Text('暂无歌词')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 12 })
              }
              .width('100%')
              .height(300)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('90%')
          .padding(20)
          .backgroundColor('#F9F9F9')
          .borderRadius(12)
          .margin({ bottom: 20 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
