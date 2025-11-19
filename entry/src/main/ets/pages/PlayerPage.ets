/**
 * 🎵 播放器页面
 *
 * 功能: 完整的音乐播放页面
 * - 显示封面(带旋转动画)
 * - 显示歌词(实时高亮滚动)
 * - 播放控制(播放/暂停/上一曲/下一曲)
 * - 进度条拖动
 * - 音质切换
 * - 播放列表显示
 */

import MusicApiService, { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import { LyricParser, LyricLine } from '../utils/LyricParser';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TimeUtil } from '../utils/TimeUtil';

// 🔥 优化后的歌词列表项组件(使用@Reusable减少重渲染)
@Reusable
@Component
struct LyricItem {
  @Prop text: string;
  @Prop isActive: boolean;

  build() {
    Text(this.text)
      .fontSize(this.isActive ? 20 : 14)
      .fontColor(this.isActive ? '#1E90FF' : '#999999')
      .fontWeight(this.isActive ? FontWeight.Bold : FontWeight.Normal)
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .transition({ type: TransitionType.All, opacity: 1 })
      .animation({ duration: 300 })
  }
}

@Entry
@Component
struct PlayerPage {
  @Watch('onSongChange')
  @StorageLink('currentSong') currentSong: MusicItem | null = null;
  @Watch('onPlayStateChange')
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
  @State rotateAngle: number = 0;
  @State isRotating: boolean = false;
  @State showLyrics: boolean = false;

  private scroller: Scroller = new Scroller();
  private rotationTimer: number = -1;
  private rotationId: number = 0;
  private lastSongId: string = '';  // 🔥 记录上一首歌曲ID,防止重复触发
  private isInitializing: boolean = true;  // 🔥 标记是否正在初始化

  async aboutToAppear(): Promise<void> {
    console.info('[PlayerPage] ===== 页面加载 =====');
    console.info('[PlayerPage] 当前歌曲:', this.currentSong?.name);
    console.info('[PlayerPage] 播放状态:', this.playState);
    console.info('[PlayerPage] 当前索引:', this.currentIndex);

    // 🔥 记录当前歌曲ID,避免onSongChange重复处理
    this.lastSongId = this.currentSong?.id || '';

    // 🔥 立即加载封面
    if (this.currentSong?.picId && this.currentSong?.source) {
      try {
        const coverUrl = await MusicApiService.getPicUrl(
          this.currentSong.source,
          this.currentSong.picId,
          500
        );
        console.info('[PlayerPage] 初始封面加载成功');
        this.coverUrl = coverUrl;
      } catch (error) {
        const err = error as Error;
        console.error('[PlayerPage] 初始封面加载失败:', err.message);
        this.coverUrl = '';
      }
    }

    // 🔥 加载歌词
    await this.loadLyrics();

    // 🔥 延迟初始化,确保状态同步完成
    setTimeout(() => {
      this.isInitializing = false;
      console.info('[PlayerPage] 初始化完成,播放状态:', this.playState);
      
      // 如果正在播放,启动旋转
      if (this.playState === PlayState.PLAYING && this.currentSong) {
        console.info('[PlayerPage] 页面加载时启动旋转');
        this.startRotation();
      }
    }, 100);
  }

  async onSongChange(): Promise<void> {
    // 🔥 初始化期间跳过处理
    if (this.isInitializing) {
      console.info('[PlayerPage] 初始化期间,跳过onSongChange');
      return;
    }

    // 🔥 防止重复触发
    const currentSongId = this.currentSong?.id || '';
    if (currentSongId === this.lastSongId) {
      console.info('[PlayerPage] 相同歌曲,跳过处理');
      return;
    }
    this.lastSongId = currentSongId;

    console.info('[PlayerPage] ===== 切歌触发 =====');
    console.info('[PlayerPage] 歌曲名:', this.currentSong?.name);
    console.info('[PlayerPage] 歌曲ID:', this.currentSong?.id);
    console.info('[PlayerPage] 当前索引:', this.currentIndex);
    console.info('[PlayerPage] 播放状态:', this.playState);

    // 先停止旋转
    this.stopRotation();
    
    // 立即重置角度为0
    animateTo({ duration: 0 }, () => {
      this.rotateAngle = 0;
    });
    console.info('[PlayerPage] 角度已重置为0');
    
    this.coverUrl = '';

    if (this.currentSong?.picId && this.currentSong?.source) {
      try {
        const newCover = await MusicApiService.getPicUrl(
          this.currentSong.source,
          this.currentSong.picId,
          500
        );
        console.info('[PlayerPage] 封面加载成功');
        this.coverUrl = newCover;
      } catch (error) {
        const err = error as Error;
        console.error('[PlayerPage] 获取封面失败:', err.message);
        this.coverUrl = '';
      }
    }

    await this.loadLyrics();
    this.currentLyricIndex = -1;

    console.info('[PlayerPage] 切歌完成');
  }


  onPlayStateChange(): void {
    console.info('[PlayerPage] ===== 播放状态变化 =====');
    console.info('[PlayerPage] 新状态:', this.playState);
    console.info('[PlayerPage] 当前旋转状态:', this.isRotating);

    if (this.playState === PlayState.PLAYING) {
      console.info('[PlayerPage] 状态变为 PLAYING，启动旋转');
      this.startRotation();
    } else if (this.playState === PlayState.PAUSED) {
      console.info('[PlayerPage] 状态变为 PAUSED，停止旋转');
      this.stopRotation();
    } else if (this.playState === PlayState.LOADING) {
      console.info('[PlayerPage] 状态变为 LOADING，停止旋转');
      this.stopRotation();
    } else {
      console.info('[PlayerPage] 状态变为其他:', this.playState);
      this.stopRotation();
    }
  }

  startRotation(): void {
    console.info('[PlayerPage] ===== startRotation 调用 =====');
    console.info('[PlayerPage] 当前 isRotating:', this.isRotating);
    console.info('[PlayerPage] 当前 rotateAngle:', this.rotateAngle);

    // 🔥 如果已经在旋转，直接返回
    if (this.isRotating) {
      console.info('[PlayerPage] 已在旋转，跳过重复启动');
      return;
    }

    this.isRotating = true;
    this.rotationId++;  // 生成新的旋转ID
    const currentRotationId = this.rotationId;
    console.info('[PlayerPage] 启动新旋转任务, ID:', currentRotationId);

    // 🔥 递归函数实现无限旋转
    const rotate = () => {
      // 检查是否应该停止
      if (!this.isRotating || this.rotationId !== currentRotationId) {
        console.info('[PlayerPage] 旋转任务', currentRotationId, '已取消');
        return;
      }

      console.info('[PlayerPage] 开始旋转动画, 从', this.rotateAngle, '度到 360 度');
      
      animateTo({
        duration: 60000,  // 60秒转360度
        curve: Curve.Linear,
        onFinish: () => {
          console.info('[PlayerPage] 动画完成回调, ID:', currentRotationId);
          // 检查是否应该继续
          if (this.rotationId === currentRotationId && this.isRotating) {
            console.info('[PlayerPage] 完成一圈，重置角度并继续');
            // 立即重置角度
            animateTo({ duration: 0 }, () => {
              this.rotateAngle = 0;
            });
            // 短暂延迟后继续下一圈
            setTimeout(() => {
              if (this.rotationId === currentRotationId && this.isRotating) {
                rotate();
              }
            }, 50);
          } else {
            console.info('[PlayerPage] 旋转任务', currentRotationId, '在回调中被取消');
          }
        }
      }, () => {
        this.rotateAngle = 360;
        console.info('[PlayerPage] 设置目标角度: 360');
      });
    };

    // 立即启动第一圈
    console.info('[PlayerPage] 立即启动第一圈旋转');
    rotate();
  }


  stopRotation(): void {
    console.info('[PlayerPage] ===== stopRotation 调用 =====');
    console.info('[PlayerPage] 当前角度:', this.rotateAngle);
    console.info('[PlayerPage] 是否正在旋转:', this.isRotating);

    if (!this.isRotating) {
      console.info('[PlayerPage] 没有在旋转，无需停止');
      return;
    }

    console.info('[PlayerPage] 停止旋转动画');
    this.isRotating = false;

    // 🔥 修复：使用 animateTo 立即停止动画
    animateTo({ duration: 0 }, () => {
      // 保持当前角度不变
      console.info('[PlayerPage] 动画已停止，保持角度:', this.rotateAngle);
    });
  }


  onTimeChange(): void {
    // 🔥 添加日志,确认时间更新触发
    if (this.lyrics.length > 0) {
      this.updateLyricHighlight();
    }
  }

  async loadLyrics(): Promise<void> {
    if (!this.currentSong) {
      return;
    }

    try {
      const lyricData = await MusicApiService.getLyric(
        this.currentSong.source,
        this.currentSong.lyricId || this.currentSong.id
      );

      if (lyricData && lyricData.lyric) {
        this.lyrics = LyricParser.parse(lyricData.lyric);
        console.info('[PlayerPage] 歌词加载成功，行数:', this.lyrics.length);
      } else {
        this.lyrics = [];
        console.info('[PlayerPage] 没有歌词数据');
      }
    } catch (error) {
      const err = error as Error;
      console.error('[PlayerPage] 加载歌词失败:', err.message);
      this.lyrics = [];
    }
  }

  updateLyricHighlight(): void {
    if (this.lyrics.length === 0) {
      return;
    }

    const newIndex = LyricParser.getCurrentIndex(this.lyrics, this.currentTime);

    if (newIndex !== this.currentLyricIndex) {
      const oldIndex = this.currentLyricIndex;
      this.currentLyricIndex = newIndex;
      
      console.info('[PlayerPage] 歌词高亮更新:', oldIndex, '→', newIndex, '时间:', this.currentTime.toFixed(1));

      if (newIndex >= 0 && !this.isUserDragging && this.showLyrics) {
        this.scroller.scrollToIndex(newIndex, true, ScrollAlign.CENTER);
      }
    }
  }

  formatTime(seconds: number): string {
    return TimeUtil.formatTime(seconds);
  }

  togglePlay(): void {
    console.info('[PlayerPage] ===== 切换播放/暂停 =====');
    AudioPlayerService.getInstance().togglePlay();
  }

  previousSong(): void {
    console.info('[PlayerPage] ===== 点击上一曲 =====');
    console.info('[PlayerPage] 当前索引:', this.currentIndex);
    console.info('[PlayerPage] 播放列表长度:', this.playlist.length);

    if (this.currentIndex > 0) {
      const prevIndex = this.currentIndex - 1;
      const prevSong = this.playlist[prevIndex];

      console.info('[PlayerPage] 目标歌曲:', prevSong.name);
      console.info('[PlayerPage] 目标索引:', prevIndex);
      console.info('[PlayerPage] 目标歌曲ID:', prevSong.id);

      AudioPlayerService.getInstance().play(prevSong, this.playlist, prevIndex)
        .then(() => {
          console.info('[PlayerPage] ✅ 播放上一首成功');
        })
        .catch((error: Error) => {
          console.error('[PlayerPage] ❌ 播放上一首失败:', error.message);
          promptAction.showToast({ message: '播放失败' });
        });
    } else {
      console.warn('[PlayerPage] 已经是第一首歌曲');
      promptAction.showToast({ message: '已经是第一首歌曲' });
    }
  }

  nextSong(): void {
    console.info('[PlayerPage] ===== 点击下一曲 =====');
    console.info('[PlayerPage] 当前索引:', this.currentIndex);
    console.info('[PlayerPage] 播放列表长度:', this.playlist.length);

    if (this.currentIndex < this.playlist.length - 1) {
      const nextIndex = this.currentIndex + 1;
      const nextSong = this.playlist[nextIndex];

      console.info('[PlayerPage] 目标歌曲:', nextSong.name);
      console.info('[PlayerPage] 目标索引:', nextIndex);
      console.info('[PlayerPage] 目标歌曲ID:', nextSong.id);

      AudioPlayerService.getInstance().play(nextSong, this.playlist, nextIndex)
        .then(() => {
          console.info('[PlayerPage] ✅ 播放下一首成功');
        })
        .catch((error: Error) => {
          console.error('[PlayerPage] ❌ 播放下一首失败:', error.message);
          promptAction.showToast({ message: '播放失败' });
        });
    } else {
      console.warn('[PlayerPage] 已经是最后一首歌曲');
      promptAction.showToast({ message: '已经是最后一首歌曲' });
    }
  }

  onProgressChange(value: number): void {
    this.isUserDragging = true;
    AudioPlayerService.getInstance().seek(value);
    setTimeout(() => {
      this.isUserDragging = false;
    }, 500);
  }

  changeQuality(quality: number): void {
    console.info('[PlayerPage] ===== 切换音质 =====');
    console.info('[PlayerPage] 新音质:', quality);

    this.selectedQuality = quality;
    AudioPlayerService.getInstance().setQuality(quality);

    if (this.currentSong) {
      const currentTime = this.currentTime;
      AudioPlayerService.getInstance().play(this.currentSong, this.playlist, this.currentIndex)
        .then(() => {
          AudioPlayerService.getInstance().seek(currentTime);
          promptAction.showToast({ message: '音质切换成功' });
        })
        .catch((error: Error) => {
          console.error('[PlayerPage] 切换音质失败:', error.message);
          promptAction.showToast({ message: '音质切换失败' });
        });
    }
    this.showQualityMenu = false;
  }

  aboutToDisappear(): void {
    console.info('[PlayerPage] ===== 页面销毁 =====');
    this.stopRotation();
  }

  build() {
    Column() {
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
          try {
            router.back();
          } catch (error) {
            const err = error as Error;
            console.error('[PlayerPage] 返回失败:', err.message);
          }
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

      if (this.showQualityMenu) {
        Column() {
          Button('标准 128K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 128 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 128 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(128))

          Divider().height(1).color($r('sys.color.ohos_id_color_list_separator'))

          Button('较高 192K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 192 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 192 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(192))

          Divider().height(1).color($r('sys.color.ohos_id_color_list_separator'))

          Button('高品 320K')
            .width('100%')
            .height(44)
            .backgroundColor(this.selectedQuality === 320 ? '#FFF0F0' : '#FFFFFF')
            .fontColor(this.selectedQuality === 320 ? '#FF6B6B' : '#333333')
            .fontSize(14)
            .onClick(() => this.changeQuality(320))

          Divider().height(1).color($r('sys.color.ohos_id_color_list_separator'))

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
          // 🔥 修复：封面和歌词区域切换
          Stack() {
            // 封面图片区域
            if (!this.showLyrics) {
              Stack() {
                if (this.coverUrl) {
                  Image(this.coverUrl)
                    .width(280)
                    .height(280)
                    .borderRadius(140)
                    .backgroundColor($r('sys.color.ohos_id_color_background'))
                    .rotate({
                      x: 0,
                      y: 0,
                      z: 1,
                      angle: this.rotateAngle
                    })
                    .shadow({
                      radius: 20,
                      color: '#40000000',
                      offsetX: 0,
                      offsetY: 10
                    })
                } else {
                  Column() {
                    Text('🎵')
                      .fontSize(80)
                      .opacity(0.3)
                  }
                  .width(280)
                  .height(280)
                  .borderRadius(140)
                  .backgroundColor($r('sys.color.ohos_id_color_background'))
                  .justifyContent(FlexAlign.Center)
                  .rotate({
                    x: 0,
                    y: 0,
                    z: 1,
                    angle: this.rotateAngle
                  })
                  .shadow({
                    radius: 20,
                    color: '#40000000',
                    offsetX: 0,
                    offsetY: 10
                  })
                }

                Column()
                  .width(50)
                  .height(50)
                  .borderRadius(25)
                  .backgroundColor('#FFFFFF')
                  .shadow({
                    radius: 5,
                    color: '#60000000',
                    offsetX: 0,
                    offsetY: 0
                  })
              }
              .width(280)
              .height(280)
            } else {
              // 歌词区域(替代封面位置)
              Column() {
                if (this.lyrics.length > 0) {
                  List({ space: 12, scroller: this.scroller }) {
                    ForEach(this.lyrics, (lyric: LyricLine, index: number) => {
                      ListItem() {
                        LyricItem({
                          text: lyric.text,
                          isActive: this.currentLyricIndex === index
                        })
                      }
                    }, (lyric: LyricLine) => lyric.time.toString())
                  }
                  .width('100%')
                  .height('100%')
                  .scrollBar(BarState.Off)
                } else {
                  Column() {
                    Text('🎵')
                      .fontSize(40)
                      .opacity(0.3)
                    Text('暂无歌词')
                      .fontSize(14)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .margin({ top: 12 })
                  }
                  .width('100%')
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                }
              }
              .width(280)
              .height(280)
              .backgroundColor('#F9F9F9')
              .borderRadius(12)
              .padding(16)
            }
          }
          .width(280)
          .height(280)
          .margin({ top: 40, bottom: 20 })

          // 🔥 切换按钮
          Button({ type: ButtonType.Normal }) {
            Row() {
              Text(this.showLyrics ? '📀 封面' : '📝 歌词')
                .fontSize(14)
                .fontColor('#FF6B6B')
            }
          }
          .width(100)
          .height(36)
          .backgroundColor('#FFF0F0')
          .borderRadius(18)
          .margin({ bottom: 10 })
          .onClick(() => {
            this.showLyrics = !this.showLyrics;
          })

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
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('90%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 30 })

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
              .onChange((value: number) => {
                this.onProgressChange(value);
              })

            Row() {
              Text(this.formatTime(this.currentTime))
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))

              Text(this.formatTime(this.duration))
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 8 })
          }
          .width('90%')
          .margin({ bottom: 30 })

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

          // 🔥 歌单列表(固定显示在底部)
          Column() {
            Row() {
              Text('播放列表')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)

              Text(`${this.currentIndex + 1} / ${this.playlist.length}`)
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ left: 8 })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 16 })

            List({ space: 8 }) {
              ForEach(this.playlist, (song: MusicItem, index: number) => {
                ListItem() {
                  Row() {
                    Text(`${index + 1}`)
                      .fontSize(14)
                      .fontColor('#999999')
                      .width(30)

                    Column() {
                      Text(song.name)
                        .fontSize(15)
                        .fontColor(index === this.currentIndex ? '#FF6B6B' : '#333333')
                        .fontWeight(index === this.currentIndex ? FontWeight.Bold : FontWeight.Normal)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      Text(song.artist)
                        .fontSize(12)
                        .fontColor('#999999')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 4 })
                        .width('100%')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })

                    if (index === this.currentIndex) {
                      Text('▶')
                        .fontSize(16)
                        .fontColor('#FF6B6B')
                        .margin({ left: 8 })
                    }
                  }
                  .width('100%')
                  .padding({ top: 12, bottom: 12, left: 8, right: 8 })
                  .backgroundColor(index === this.currentIndex ? '#FFF5F5' : 'transparent')
                  .borderRadius(8)
                  .onClick(() => {
                    console.info('[PlayerPage] 点击歌单项:', song.name, 'index:', index);
                    AudioPlayerService.getInstance().play(song, this.playlist, index)
                      .then(() => {
                        console.info('[PlayerPage] ✅ 播放成功');
                      })
                      .catch((error: Error) => {
                        console.error('[PlayerPage] ❌ 播放失败:', error.message);
                        promptAction.showToast({ message: '播放失败' });
                      });
                  })
                }
              }, (song: MusicItem) => song.id.toString())
            }
            .width('100%')
            .height(300)
            .scrollBar(BarState.Auto)
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
