// 🔥 修复：正确导入 MusicApiService（default export）
import MusicApiService from '../services/MusicApiService';
import { MusicItem } from '../services/MusicApiService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct MusicListPage {
  @State musicList: MusicItem[] = [];
  @State isLoading: boolean = false;
  @StorageProp('currentSong') currentSong: MusicItem | null = null;

  aboutToAppear() {
    this.loadMusicList();
  }

  async loadMusicList() {
    this.isLoading = true;
    try {
      const results = await MusicApiService.searchMusic('热门', 'netease');
      this.musicList = results;
    } catch (error) {
      console.error('[MusicListPage] 加载失败:', error);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async playSong(song: MusicItem, index: number) {
    try {
      await AudioPlayerService.play(song, this.musicList, index);
      router.pushUrl({ url: 'pages/PlayerPage' });
    } catch (error) {
      promptAction.showToast({ message: '播放失败' });
    }
  }

  build() {
    Column() {
      Text('音乐列表')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .padding(16)

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
      } else {
        List({ space: 10 }) {
          ForEach(this.musicList, (item: MusicItem, index: number) => {
            ListItem() {
              Row() {
                Text(`${index + 1}`)
                  .fontSize(14)
                  .width(30)

                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text(item.artist)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                this.playSong(item, index);
              })
            }
          }, (item: MusicItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
