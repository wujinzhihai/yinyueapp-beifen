// entry/src/main/ets/components/SongListItem.ets

import { Song } from '../models/Song'

@Component
export struct SongListItem {
  @Prop song: Song
  @Prop isPlaying: boolean = false
  onItemClick: (song: Song) => void = () => {}

  build() {
    Row() {
      // ✅ 修复1：cove.audioUrl → coverUrl
      Image(this.song.coverUrl || 'https://via.placeholder.com/50')
        .width(50)
        .height(50)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      Column() {
        Row() {
          Text(this.song.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isPlaying ? '#FF1744' : '#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.isPlaying) {
            Text('♪')
              .fontSize(14)
              .fontColor('#FF1744')
              .margin({ left: 5 })
          }
        }
        .width('100%')

        Text(`${this.song.artist} - ${this.song.album}`)
          .fontSize(13)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12, right: 12 })
      .alignItems(HorizontalAlign.Start)

      // ✅ 修复2：使用 Song 类的方法
      Text(this.song.getFormattedDuration())
        .fontSize(13)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.isPlaying ? '#FFEBEE' : '#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.onItemClick(this.song)
    })
  }
}
