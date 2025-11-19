/**
 * 🎵 歌单详情页
 *
 * 功能: 显示歌单的歌曲列表
 * - 显示歌单信息(名称/描述/封面)
 * - 使用本地歌曲数据(避免API频率限制)
 * - 点击歌曲播放
 * - 返回首页
 */

import { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import MusicApiService from '../services/MusicApiService';
import { MiniPlayer } from '../components/MiniPlayer';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TimeUtil } from '../utils/TimeUtil';
import { ErrorHandler } from '../utils/ErrorHandler';
import { LocalSongItem } from '../constants/LocalData';

// 🔥 本地歌曲显示项
interface DisplaySongItem {
  name: string;
  artist: string;
  album: string;
  duration: number;
}

@Entry
@Component
struct PlaylistDetailPage {
  @State playlistName: string = '';
  @State playlistDescription: string = '';
  @State playlistCover: string = '';
  @State localSongs: LocalSongItem[] = [];
  @State isLoading: boolean = false;
  @StorageProp('currentSong') currentSong: MusicItem | null = null;
  @StorageProp('playState') playState: PlayState = PlayState.IDLE;
  @StorageProp('currentIndex') currentIndex: number = -1;

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>;
    this.playlistName = params['name'] as string || '';
    this.playlistDescription = params['description'] as string || '';
    this.playlistCover = params['cover'] as string || '';
    this.localSongs = params['songs'] as LocalSongItem[] || [];

    console.info('[PlaylistDetail] 歌单信息:', this.playlistName);
    console.info('[PlaylistDetail] 本地歌曲数量:', this.localSongs.length);
  }

  async playSongByName(songName: string, artist: string, index: number) {
    console.info('[PlaylistDetail] ===== 点击播放 =====');
    console.info('[PlaylistDetail] 歌曲名:', songName);
    console.info('[PlaylistDetail] 歌手:', artist);

    // 显示加载提示
    promptAction.showToast({ message: '正在加载...' });

    try {
      // 使用歌曲名和歌手搜索
      const keyword = `${songName} ${artist}`;
      console.info('[PlaylistDetail] 搜索关键词:', keyword);

      const results = await MusicApiService.searchMusic(keyword, 'netease');
      console.info('[PlaylistDetail] 搜索结果数量:', results.length);
      
      if (results.length > 0) {
        // 🔥 优先选择原唱版本(歌手名匹配的)
        let selectedSong = results[0];
        
        // 尝试找到歌手名匹配的版本
        for (const song of results) {
          if (song.artist.includes(artist) || artist.includes(song.artist)) {
            selectedSong = song;
            console.info('[PlaylistDetail] 找到原唱版本:', song.name, '-', song.artist);
            break;
          }
        }
        
        console.info('[PlaylistDetail] 选择歌曲:', selectedSong.name, '-', selectedSong.artist);
        console.info('[PlaylistDetail] 歌曲ID:', selectedSong.id);
        console.info('[PlaylistDetail] 音乐源:', selectedSong.source);

        await AudioPlayerService.getInstance().play(selectedSong, results, 0);
        console.info('[PlaylistDetail] ✅ 播放服务调用成功');

        await router.pushUrl({
          url: 'pages/PlayerPage'
        });
        console.info('[PlaylistDetail] ✅ 已跳转到播放器页面');
      } else {
        console.warn('[PlaylistDetail] ❌ 未找到搜索结果');
        promptAction.showToast({ message: '未找到该歌曲,请稍后重试' });
      }

    } catch (error) {
      const err = error as Error;
      console.error('[PlaylistDetail] ❌ 播放失败:', err.message);
      console.error('[PlaylistDetail] 错误堆栈:', err.stack);
      
      promptAction.showToast({
        message: `播放失败: ${err.message}`,
        duration: 3000
      });
      
      const context: Record<string, Object> = {
        'songName': songName as Object,
        'artist': artist as Object,
        'error': err.message as Object
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

        Text(this.playlistName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 12, right: 12 })

        // 占位,保持标题居中
        Column()
          .width(40)
          .height(40)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      // 内容区域
      Column() {
        if (this.isLoading) {
          // 加载状态
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#FF6B6B')
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.localSongs.length > 0) {
          // 歌曲列表
          Column() {
            // 歌单头部信息
            Column() {
              // 封面
              Image($r(`app.media.${this.playlistCover}`))
                .width(120)
                .height(120)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .shadow({
                  radius: 12,
                  color: 'rgba(0, 0, 0, 0.15)',
                  offsetX: 0,
                  offsetY: 4
                })

              Text(this.playlistName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 16 })

              Text(this.playlistDescription)
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })

              Text(`共 ${this.localSongs.length} 首歌曲`)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FAFAFA')

            // 歌曲列表
            List({ space: 0 }) {
              ForEach(this.localSongs, (item: LocalSongItem, index: number) => {
                ListItem() {
                  Row() {
                    // 音乐图标
                    Column() {
                      Text('🎵')
                        .fontSize(32)
                        .opacity(0.6)
                    }
                    .width(60)
                    .height(60)
                    .borderRadius(8)
                    .backgroundColor('#F5F5F5')
                    .justifyContent(FlexAlign.Center)
                    .margin({ right: 12 })

                    // 播放状态图标
                    if (this.currentSong &&
                        this.currentSong.name === item.name &&
                        this.currentSong.artist === item.artist &&
                        this.playState === PlayState.PLAYING) {
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

                      Text(`${item.artist} - ${item.album}`)
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

                    Text(this.formatDuration(item.duration))
                      .fontSize(12)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .height(80)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(
                    this.currentSong &&
                    this.currentSong.name === item.name &&
                    this.currentSong.artist === item.artist
                      ? '#FFF5F5'
                      : '#FFFFFF'
                  )
                  .onClick(() => {
                    this.playSongByName(item.name, item.artist, index);
                  })
                }
              }, (item: LocalSongItem) => `${item.name}_${item.artist}`)
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
            Text('🎵')
              .fontSize(80)
              .opacity(0.3)
            Text('暂无歌曲')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 16 })
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
  }
}