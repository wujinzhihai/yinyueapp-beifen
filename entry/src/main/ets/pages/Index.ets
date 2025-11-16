import { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import MusicApiService from '../services/MusicApiService';
import { MiniPlayer } from '../components/MiniPlayer';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { LOCAL_PLAYLISTS, PlaylistItem } from '../constants/LocalData';
import { TimeUtil } from '../utils/TimeUtil';
import { Debounce } from '../utils/Debounce';
import { ErrorHandler, ErrorCode, AppError } from '../utils/ErrorHandler';

// 🔥 封面图片组件
@Component
struct SongCoverImage {
  @Prop song: MusicItem;
  @State coverUrl: string = '';
  @State isLoading: boolean = true;

  async aboutToAppear() {
    if (this.song.picId && this.song.source) {
      try {
        const url = await MusicApiService.getPicUrl(this.song.source, this.song.picId, 200);
        this.coverUrl = url;
      } catch (error) {
        console.error('[SongCoverImage] 加载封面失败');
      } finally {
        this.isLoading = false;
      }
    } else {
      this.isLoading = false;
    }
  }

  build() {
    if (this.coverUrl) {
      Image(this.coverUrl)
        .width('100%')
        .height('100%')
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
    } else {
      Column() {
        Text('🎵')
          .fontSize(24)
          .opacity(0.3)
      }
      .width('100%')
      .height('100%')
      .borderRadius(8)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)
    }
  }
}

@Entry
@Component
struct Index {
  @State searchKeyword: string = '';
  @State searchResults: MusicItem[] = [];
  @State isSearching: boolean = false;
  @StorageProp('currentSong') currentSong: MusicItem | null = null;
  @StorageProp('playState') playState: PlayState = PlayState.IDLE;
  @StorageProp('currentIndex') currentIndex: number = -1;

  aboutToAppear() {
    // 🔥 AudioPlayerService 现在直接更新 AppStorage,无需手动订阅
    console.info('[Index] 页面初始化完成');
  }

  async performSearch() {
    if (!this.searchKeyword.trim()) {
      promptAction.showToast({ message: '请输入搜索关键词' });
      return;
    }

    this.isSearching = true;
    this.searchResults = [];

    try {
      const results = await MusicApiService.searchMusic(this.searchKeyword, 'netease');
      this.searchResults = results;
      console.info('[Index] 搜索结果:', results.length);

      if (results.length === 0) {
        promptAction.showToast({ message: '未找到相关歌曲' });
      }
    } catch (error) {
      const context: Record<string, Object> = {
        'keyword': this.searchKeyword as Object
      };
      const appError = ErrorHandler.createNetworkError('搜索失败', context);
      ErrorHandler.handle(appError);
    } finally {
      this.isSearching = false;
    }
  }

  async playSong(song: MusicItem, index: number) {
    console.info('[Index] 点击播放:', song.name);

    try {
      // 🔥 修复：使用实例方法
      await AudioPlayerService.getInstance().play(song, this.searchResults, index);
      console.info('[Index] 播放服务调用成功');

      await router.pushUrl({
        url: 'pages/PlayerPage'
      });

    } catch (error) {
      const context: Record<string, Object> = {
        'songId': song.id as Object,
        'songName': song.name as Object
      };
      const appError = ErrorHandler.createAudioError('播放失败', context);
      ErrorHandler.handle(appError);
    }
  }

  formatDuration(seconds: number): string {
    return TimeUtil.formatTime(seconds);
  }

  build() {
    Column() {
      // 搜索栏
      // 搜索栏
      Row() {
        // 🏠 返回首页按钮（仅在搜索结果页显示）
        if (this.searchResults.length > 0) {
          Button({ type: ButtonType.Circle }) {
            Text('🏠')
              .fontSize(20)
          }
          .width(50)
          .height(50)
          .backgroundColor('#F5F5F5')
          .margin({ right: 12 })
          .onClick(() => {
            // 清空搜索关键词和结果，回到首页歌单列表
            this.searchKeyword = '';
            this.searchResults = [];
          })
        }

        TextInput({ placeholder: '搜索歌曲、歌手', text: $$this.searchKeyword })
          .layoutWeight(1)
          .height(50)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(25)
          .padding({ left: 20, right: 20 })
          .onChange((value: string) => {
            // 🔥 使用防抖优化搜索,避免频繁触发API请求
            Debounce.execute('search', () => {
              if (value.trim().length > 0) {
                this.performSearch();
              }
            }, 500);
          })
          .onSubmit(() => {
            // 回车直接搜索,取消防抖
            Debounce.cancel('search');
            this.performSearch();
          })

        Button({ type: ButtonType.Circle }) {
          Text('🔍')
            .fontSize(20)
        }
        .width(50)
        .height(50)
        .backgroundColor('#FF6B6B')
        .margin({ left: 12 })
        .onClick(() => {
          this.performSearch();
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      // 推荐歌单横向滚动
      if (this.searchResults.length === 0 && !this.isSearching) {
        Column() {
          // 标题
          Row() {
            Text('精选推荐')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ left: 16, top: 12, bottom: 12 })

          // 横向滚动歌单
          List({ space: 12 }) {
            ForEach(LOCAL_PLAYLISTS, (playlist: PlaylistItem) => {
              ListItem() {
                Column() {
                  // 封面
                  Image(playlist.cover)
                    .width(140)
                    .height(140)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                    .shadow({
                      radius: 8,
                      color: 'rgba(0, 0, 0, 0.1)',
                      offsetX: 0,
                      offsetY: 2
                    })

                  // 歌单名称
                  Text(playlist.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 8 })
                    .width(140)

                  // 描述
                  Text(playlist.description)
                    .fontSize(12)
                    .fontColor('#999999')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                    .width(140)
                }
                .alignItems(HorizontalAlign.Start)
                .onClick(() => {
                  // 点击歌单，使用第一个关键词搜索
                  this.searchKeyword = playlist.keywords[0];
                  this.performSearch();
                })
              }
            }, (playlist: PlaylistItem) => playlist.id)
          }
          .width('100%')
          .height(230)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .backgroundColor('#FAFAFA')
        .padding({ bottom: 16 })
      }

      // 加载状态
      if (this.isSearching) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#FF6B6B')
          Text('搜索中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        // 搜索结果列表
        List({ space: 0 }) {
          ForEach(this.searchResults, (item: MusicItem, index: number) => {
            ListItem() {
              Row() {
                // 🔥 添加封面图片
                SongCoverImage({ song: item })
                  .width(60)
                  .height(60)
                  .margin({ right: 12 })

                Row() {
                  if (this.currentSong && this.currentSong.id === item.id && this.playState === PlayState.PLAYING) {
                    Text('♫')
                      .fontSize(16)
                      .fontColor('#FF6B6B')
                      .fontWeight(FontWeight.Bold)
                      .margin({ right: 8 })
                  }
                  Text(`${index + 1}`)
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width(40)

                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Text(`${item.artist} - ${item.album || '未知专辑'}`)
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

                if (item.duration) {
                  Text(this.formatDuration(item.duration))
                    .fontSize(12)
                    .fontColor('#999999')
                }
              }
              .width('100%')
              .height(80)
              .padding({ left: 16, right: 16 })
              .backgroundColor(this.currentSong && this.currentSong.id === item.id ? '#FFF5F5' : '#FFFFFF')
              .onClick(() => {
                this.playSong(item, index);
              })
            }
          }, (item: MusicItem) => item.id + item.source)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      } else {
        // 空状态
        Column() {
          Text('🎵')
            .fontSize(80)
            .opacity(0.3)
          Text('点击推荐歌单')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 16 })
          Text('开始探索音乐')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      // 迷你播放器
      if (this.currentSong) {
        MiniPlayer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
