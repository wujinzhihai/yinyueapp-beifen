/**
 * 👤 我的页面
 *
 * 功能: 用户信息和设置
 * - 显示播放统计
 * - 应用设置
 * - 关于信息
 */

import { LocalMusicService } from '../services/LocalMusicService';
import promptAction from '@ohos.promptAction';

@Component
export struct MinePage {
  @State localMusicCount: number = 0;

  aboutToAppear() {
    this.localMusicCount = LocalMusicService.getCount();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          Column() {
            Text('🎵')
              .fontSize(40)
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF6B6B')
          .justifyContent(FlexAlign.Center)

          // 用户信息
          Column() {
            Text('音乐爱好者')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')

            Text('享受音乐,享受生活')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 8 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(20)
      }
      .width('90%')
      .margin({ top: 16, left: '5%', right: '5%' })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 2
      })

      // 统计信息
      Row() {
        Column() {
          Text(`${this.localMusicCount}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('本地歌曲')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('0')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('播放次数')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('0')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('收藏歌曲')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('90%')
      .margin({ top: 16, left: '5%', right: '5%' })
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 2
      })

      // 功能列表
      Column() {
        // 设置项
        this.SettingItem('⚙️', '设置', () => {
          promptAction.showToast({ message: '设置功能开发中' });
        })

        Divider()
          .color('#F0F0F0')

        this.SettingItem('📊', '播放历史', () => {
          promptAction.showToast({ message: '播放历史功能开发中' });
        })

        Divider()
          .color('#F0F0F0')

        this.SettingItem('❤️', '我的收藏', () => {
          promptAction.showToast({ message: '收藏功能开发中' });
        })

        Divider()
          .color('#F0F0F0')

        this.SettingItem('ℹ️', '关于应用', () => {
          promptAction.showToast({ message: 'HarmonyOS音乐应用 v1.0.0' });
        })
      }
      .width('90%')
      .margin({ top: 16, left: '5%', right: '5%' })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 2
      })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SettingItem(icon: string, title: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 })

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      Text('›')
        .fontSize(24)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .onClick(onClick)
  }
}