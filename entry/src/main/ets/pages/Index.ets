import { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import MusicApiService from '../services/MusicApiService';
import { MiniPlayer } from '../components/MiniPlayer';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

// 🔥 定义明确的状态接口
interface PlayerState {
  currentSong: MusicItem | null;
  playState: PlayState;
  currentTime: number;
  duration: number;
  playlist: MusicItem[];
  currentIndex: number;
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
    // 🔥 修复：使用实例方法 + 明确类型
    AudioPlayerService.getInstance().subscribe((state: PlayerState) => {
      AppStorage.setOrCreate('currentSong', state.currentSong);
      AppStorage.setOrCreate('playState', state.playState);
      AppStorage.setOrCreate('currentTime', state.currentTime);
      AppStorage.setOrCreate('duration', state.duration);
      AppStorage.setOrCreate('playlist', state.playlist);
      AppStorage.setOrCreate('currentIndex', state.currentIndex);
    });
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
      console.error('[Index] 搜索失败:', error);
      promptAction.showToast({ message: '搜索失败，请检查网络' });
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
      console.error('[Index] 播放失败:', JSON.stringify(error));
      promptAction.showToast({
        message: '播放失败'
      });
    }
  }

  formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索歌曲、歌手', text: $$this.searchKeyword })
          .layoutWeight(1)
          .height(50)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(25)
          .padding({ left: 20, right: 20 })
          .onSubmit(() => {
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
              .height(70)
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
          Text('暂无搜索结果')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
          Text('试试搜索你喜欢的歌曲')
            .fontSize(14)
            .fontColor('#CCCCCC')
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
