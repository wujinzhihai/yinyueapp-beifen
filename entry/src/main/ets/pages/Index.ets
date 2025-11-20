/**
 * 🏠 首页
 *
 * 功能: 应用主页
 * - 首页搜索框
 * - 显示推荐歌单
 * - 搜索结果覆盖层(无导航栏)
 * - 底部迷你播放器
 * - 底部导航栏(首页/本地音乐/我的)
 *
 * @author wujinzhihai
 * @github https://github.com/wujinzhihai
 */

import { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import MusicApiService from '../services/MusicApiService';
import { LocalMusicService } from '../services/LocalMusicService';
import { MiniPlayer } from '../components/MiniPlayer';
import { PlaylistPage } from './PlaylistPage';
import { MinePage } from './MinePage';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { LOCAL_PLAYLISTS, PlaylistItem } from '../constants/LocalData';
import { TimeUtil } from '../utils/TimeUtil';
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
  @State showSearchResults: boolean = false; // 是否显示搜索结果覆盖层
  @State currentTabIndex: number = 0; // 当前标签页索引
  @StorageProp('currentSong') currentSong: MusicItem | null = null;
  @StorageProp('playState') playState: PlayState = PlayState.IDLE;
  @StorageProp('currentIndex') currentIndex: number = -1;
  @State bannerIndex: number = 0;
  private bannerController: SwiperController = new SwiperController();

  async aboutToAppear() {
    console.info('[Index] 页面初始化完成');
    // 初始化本地音乐库
    await LocalMusicService.scanLocalMusic();
  }

  async performSearch() {
    if (!this.searchKeyword.trim()) {
      promptAction.showToast({ message: '请输入搜索关键词' });
      return;
    }

    // 显示搜索结果覆盖层
    this.showSearchResults = true;
    this.isSearching = true;
    this.searchResults = [];

    try {
      // 搜索网络音乐
      const results = await MusicApiService.searchMusic(this.searchKeyword, 'netease');
      this.searchResults = results;
      console.info('[Index] 网络搜索结果:', results.length);

      if (this.searchResults.length === 0) {
        promptAction.showToast({ message: '未找到相关歌曲' });
      }
    } catch (error) {
      const context: Record<string, Object> = {
        'keyword': this.searchKeyword as Object,
        'source': 'network' as Object
      };
      const appError = ErrorHandler.createNetworkError('搜索失败', context);
      ErrorHandler.handle(appError);
    } finally {
      this.isSearching = false;
    }
  }

  // 从首页触发搜索
  async searchFromHome(keyword: string) {
    this.searchKeyword = keyword;
    await this.performSearch();
  }

  closeSearchResults() {
    this.showSearchResults = false;
  }

  async playSong(song: MusicItem, index: number) {
    console.info('[Index] 点击播放:', song.name);

    try {
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
    Stack() {
      // 主内容区域 - 使用Tabs实现底部导航
      Column() {
        Tabs({ barPosition: BarPosition.End, index: $$this.currentTabIndex }) {
          // 首页标签
          TabContent() {
            Column() {
              // 首页搜索框
              Row() {
                TextInput({ placeholder: '搜索网络音乐', text: $$this.searchKeyword })
                  .layoutWeight(1)
                  .height(50)
                  .fontSize(16)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(25)
                  .padding({ left: 20, right: 20 })

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

              // 首页内容区域
              Column() {
                // 🎨 横幅图片展示区域
                Column() {
                  Row() {
                    Text('热门推荐')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333333')
                  }
                  .width('100%')
                  .padding({ left: 16, top: 12, bottom: 12 })

                  Swiper(this.bannerController) {
                    Image($r('app.media.pexels_steve'))
                      .width('100%')
                      .height(160)
                      .borderRadius(12)
                      .objectFit(ImageFit.Cover)
                      .shadow({
                        radius: 12,
                        color: 'rgba(0, 0, 0, 0.15)',
                        offsetX: 0,
                        offsetY: 4
                      })

                    Image($r('app.media.pexels_pixabay'))
                      .width('100%')
                      .height(160)
                      .borderRadius(12)
                      .objectFit(ImageFit.Cover)
                      .shadow({
                        radius: 12,
                        color: 'rgba(0, 0, 0, 0.15)',
                        offsetX: 0,
                        offsetY: 4
                      })

                    Image($r('app.media.pexels_juanpphotoandvideo'))
                      .width('100%')
                      .height(160)
                      .borderRadius(12)
                      .objectFit(ImageFit.Cover)
                      .shadow({
                        radius: 12,
                        color: 'rgba(0, 0, 0, 0.15)',
                        offsetX: 0,
                        offsetY: 4
                      })

                    Image($r('app.media.pexels_cottonbro'))
                      .width('100%')
                      .height(160)
                      .borderRadius(12)
                      .objectFit(ImageFit.Cover)
                      .shadow({
                        radius: 12,
                        color: 'rgba(0, 0, 0, 0.15)',
                        offsetX: 0,
                        offsetY: 4
                      })
                  }
                  .width('90%')
                  .height(180)
                  .autoPlay(true)
                  .interval(5000)
                  .loop(true)
                  .indicator(true)
                  .indicatorStyle({
                    bottom: 10,
                    color: Color.White,
                    selectedColor: '#FF6B6B'
                  })
                  .curve(Curve.Linear)
                  .onChange((index: number) => {
                    this.bannerIndex = index;
                  })
                }
                .width('100%')
                .backgroundColor('#FAFAFA')
                .padding({ bottom: 8 })

                // 精选推荐歌单
                Column() {
                  Row() {
                    Text('精选推荐')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333333')
                  }
                  .width('100%')
                  .padding({ left: 16, top: 12, bottom: 12 })

                  List({ space: 12 }) {
                    ForEach(LOCAL_PLAYLISTS, (playlist: PlaylistItem) => {
                      ListItem() {
                        Column() {
                          Image($r(`app.media.${playlist.cover}`))
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

                          Text(playlist.name)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#333333')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ top: 8 })
                            .width(140)

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
                          // 跳转到歌单详情页
                          router.pushUrl({
                            url: 'pages/PlaylistDetailPage',
                            params: {
                              name: playlist.name,
                              description: playlist.description,
                              cover: playlist.cover,
                              keywords: playlist.keywords,
                              songs: playlist.songs
                            }
                          });
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
                .padding({ bottom: 20 })
              }
              .width('100%')
              .layoutWeight(1)

              // 迷你播放器
              MiniPlayer()
            }
            .width('100%')
            .height('100%')
          }
          .tabBar(this.TabBuilder('首页', 0, '🏠'))

          // 本地音乐标签
          TabContent() {
            PlaylistPage()
          }
          .tabBar(this.TabBuilder('本地音乐', 1, '📀'))

          // 我的标签
          TabContent() {
            MinePage()
          }
          .tabBar(this.TabBuilder('我的', 2, '👤'))
        }
        .width('100%')
        .height('100%')
        .barMode(BarMode.Fixed)
        .animationDuration(0)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')

      // 搜索结果覆盖层 (无导航栏)
      if (this.showSearchResults) {
        Column() {
          // 搜索框 (带返回按钮)
          Row() {
            Button({ type: ButtonType.Circle }) {
              Text('←')
                .fontSize(24)
                .fontColor('#333333')
            }
            .width(50)
            .height(50)
            .backgroundColor('#F5F5F5')
            .onClick(() => {
              this.closeSearchResults();
            })

            TextInput({ placeholder: '搜索网络音乐', text: $$this.searchKeyword })
              .layoutWeight(1)
              .height(50)
              .fontSize(16)
              .backgroundColor('#F5F5F5')
              .borderRadius(25)
              .padding({ left: 20, right: 20 })
              .margin({ left: 12 })

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

          // 搜索结果内容
          Column() {
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
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            } else if (this.searchResults.length > 0) {
              // 搜索结果列表
              Column() {
                Text(`共找到 ${this.searchResults.length} 首歌曲`)
                  .fontSize(14)
                  .fontColor('#999999')
                  .width('100%')
                  .padding({ left: 16, right: 16, bottom: 12 })

                List({ space: 0 }) {
                  ForEach(this.searchResults, (item: MusicItem, index: number) => {
                    ListItem() {
                      Row() {
                        // 封面图片
                        SongCoverImage({ song: item })
                          .width(60)
                          .height(60)
                          .margin({ right: 12 })
  
                        // 播放状态图标
                        if (this.currentSong && this.currentSong.id === item.id && this.playState === PlayState.PLAYING) {
                          Text('♫')
                            .fontSize(20)
                            .fontColor('#FF6B6B')
                            .fontWeight(FontWeight.Bold)
                            .margin({ right: 12 })
                        }
  
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
              }
              .width('100%')
              .layoutWeight(1)
            } else {
              // 空状态
              Column() {
                Text('🔍')
                  .fontSize(80)
                  .opacity(0.3)
                Text('暂无搜索结果')
                  .fontSize(16)
                  .fontColor('#666666')
                  .margin({ top: 16 })
                Text('尝试其他关键词')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 8 })
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('100%')
          .layoutWeight(1)

          // 迷你播放器
          MiniPlayer()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBuilder(title: string, index: number, icon: string) {
    Column() {
      Text(icon)
        .fontSize(24)
        .fontColor(this.currentTabIndex === index ? '#FF6B6B' : '#999999')

      Text(title)
        .fontSize(12)
        .fontColor(this.currentTabIndex === index ? '#FF6B6B' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
  }
}
