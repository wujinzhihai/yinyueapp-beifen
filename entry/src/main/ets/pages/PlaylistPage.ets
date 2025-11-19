/**
 * 📀 歌单页面
 *
 * 功能: 显示所有本地音乐
 * - 显示本地音乐列表
 * - 支持播放本地音乐
 * - 支持刷新音乐库
 * - 支持编辑模式(删除音乐)
 * - 显示音乐数量统计
 */

import { MusicItem } from '../services/MusicApiService';
import { LocalMusicService } from '../services/LocalMusicService';
import AudioPlayerService, { PlayState } from '../services/AudioPlayerService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TimeUtil } from '../utils/TimeUtil';

@Component
export struct PlaylistPage {
  @State localMusicList: MusicItem[] = [];
  @State displayList: MusicItem[] = []; // 显示的列表(搜索结果或全部)
  @State isLoading: boolean = false;
  @State isEditMode: boolean = false; // 编辑模式
  @State selectedItems: Set<string> = new Set(); // 选中的音乐ID
  @State searchKeyword: string = ''; // 搜索关键词
  @StorageProp('currentSong') currentSong: MusicItem | null = null;
  @StorageProp('playState') playState: PlayState = PlayState.IDLE;

  async aboutToAppear() {
    await this.loadLocalMusic();
  }

  // 加载本地音乐
  async loadLocalMusic() {
    this.isLoading = true;
    try {
      this.localMusicList = await LocalMusicService.scanLocalMusic();
      this.displayList = this.localMusicList;
      if (this.localMusicList.length === 0) {
        promptAction.showToast({ message: '未找到本地音乐文件' });
      }
    } catch (error) {
      console.error('[PlaylistPage] 加载失败:', error);
      promptAction.showToast({ message: '加载本地音乐失败' });
    } finally {
      this.isLoading = false;
    }
  }

  // 刷新音乐库
  async refreshMusic() {
    this.isLoading = true;
    try {
      this.localMusicList = await LocalMusicService.refresh();
      this.displayList = this.localMusicList;
      this.searchKeyword = ''; // 清空搜索
      promptAction.showToast({ message: `刷新完成,共${this.localMusicList.length}首` });
      // 退出编辑模式
      this.isEditMode = false;
      this.selectedItems.clear();
    } catch (error) {
      console.error('[PlaylistPage] 刷新失败:', error);
      promptAction.showToast({ message: '刷新失败' });
    } finally {
      this.isLoading = false;
    }
  }

  // 搜索本地音乐
  performSearch() {
    if (!this.searchKeyword.trim()) {
      this.displayList = this.localMusicList;
      return;
    }

    const keyword = this.searchKeyword.toLowerCase();
    this.displayList = this.localMusicList.filter(song =>
      song.name.toLowerCase().includes(keyword) ||
      song.artist.toLowerCase().includes(keyword)
    );

    if (this.displayList.length === 0) {
      promptAction.showToast({ message: '未找到相关歌曲' });
    }
  }

  // 播放歌曲
  async playSong(song: MusicItem, index: number) {
    try {
      // 使用displayList作为播放列表
      await AudioPlayerService.getInstance().play(song, this.displayList, index);
      await router.pushUrl({ url: 'pages/PlayerPage' });
    } catch (error) {
      console.error('[PlaylistPage] 播放失败:', error);
      promptAction.showToast({ message: '播放失败' });
    }
  }

  // 切换编辑模式
  toggleEditMode() {
    this.isEditMode = !this.isEditMode;
    if (!this.isEditMode) {
      this.selectedItems.clear();
    }
  }

  // 切换选中状态
  toggleSelection(musicId: string) {
    if (this.selectedItems.has(musicId)) {
      this.selectedItems.delete(musicId);
    } else {
      this.selectedItems.add(musicId);
    }
    // 触发UI更新
    this.selectedItems = new Set(this.selectedItems);
  }

  // 全选/取消全选
  toggleSelectAll() {
    if (this.selectedItems.size === this.displayList.length) {
      this.selectedItems.clear();
    } else {
      this.selectedItems = new Set(this.displayList.map(item => item.id));
    }
  }

  // 删除选中的音乐
  deleteSelected() {
    if (this.selectedItems.size === 0) {
      promptAction.showToast({ message: '请选择要删除的音乐' });
      return;
    }

    const count = LocalMusicService.removeBatchFromList(Array.from(this.selectedItems));
    this.localMusicList = LocalMusicService.getLocalMusicList();
    this.displayList = this.localMusicList;
    this.searchKeyword = ''; // 清空搜索
    this.selectedItems.clear();
    this.isEditMode = false;
    promptAction.showToast({ message: `已从列表移除${count}首歌曲` });
  }

  formatDuration(seconds: number): string {
    return TimeUtil.formatTime(seconds);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        if (this.isEditMode) {
          // 编辑模式标题栏
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.toggleEditMode();
            })

          Text(`已选${this.selectedItems.size}首`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Button('删除')
            .fontSize(16)
            .fontColor('#FF6B6B')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.deleteSelected();
            })
        } else {
          // 正常模式标题栏
          Text('本地音乐')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)

          // 编辑按钮
          Button({ type: ButtonType.Circle }) {
            Text('✏️')
              .fontSize(18)
          }
          .width(44)
          .height(44)
          .backgroundColor('#F5F5F5')
          .margin({ right: 8 })
          .onClick(() => {
            if (this.localMusicList.length > 0) {
              this.toggleEditMode();
            } else {
              promptAction.showToast({ message: '暂无音乐可编辑' });
            }
          })

          // 刷新按钮
          Button({ type: ButtonType.Circle }) {
            Text('🔄')
              .fontSize(20)
          }
          .width(44)
          .height(44)
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.refreshMusic();
          })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      // 搜索栏 - 只在非编辑模式显示
      if (!this.isEditMode) {
        Row() {
          TextInput({ placeholder: '搜索本地音乐', text: $$this.searchKeyword })
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(22)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.performSearch();
            })

          Button({ type: ButtonType.Circle }) {
            Text('🔍')
              .fontSize(18)
          }
          .width(44)
          .height(44)
          .backgroundColor('#FF6B6B')
          .margin({ left: 8 })
          .onClick(() => {
            this.performSearch();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
      }

      // 统计信息和全选按钮
      Row() {
        if (this.isEditMode) {
          Checkbox()
            .select(this.selectedItems.size === this.displayList.length && this.displayList.length > 0)
            .onChange(() => {
              this.toggleSelectAll();
            })
          Text('全选')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
        }

        Text(`共 ${this.displayList.length} 首歌曲${this.searchKeyword ? ' (搜索结果)' : ''}`)
          .fontSize(14)
          .fontColor('#999999')
          .layoutWeight(1)
          .textAlign(this.isEditMode ? TextAlign.End : TextAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })

      // 加载状态
      if (this.isLoading) {
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
      } else if (this.displayList.length === 0 && !this.searchKeyword) {
        // 空状态
        Column() {
          Text('📁')
            .fontSize(80)
            .opacity(0.3)
          Text('暂无本地音乐')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 16 })
          Text('请将音乐文件放入Music或Download文件夹')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })

          Button('刷新')
            .margin({ top: 24 })
            .onClick(() => {
              this.refreshMusic();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.displayList.length === 0 && this.searchKeyword) {
        // 搜索无结果
        Column() {
          Text('🔍')
            .fontSize(80)
            .opacity(0.3)
          Text('未找到相关歌曲')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 16 })
          Text(`搜索"${this.searchKeyword}"无结果`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })

          Button('清空搜索')
            .margin({ top: 24 })
            .onClick(() => {
              this.searchKeyword = '';
              this.performSearch();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 音乐列表
        List({ space: 0 }) {
          ForEach(this.displayList, (item: MusicItem, index: number) => {
            ListItem() {
              Row() {
                // 编辑模式:显示复选框
                if (this.isEditMode) {
                  Checkbox()
                    .select(this.selectedItems.has(item.id))
                    .onChange(() => {
                      this.toggleSelection(item.id);
                    })
                    .margin({ right: 12 })
                } else {
                  // 正常模式:显示序号和播放状态
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
                  .width(50)
                }

                // 音乐图标
                Column() {
                  Text('🎵')
                    .fontSize(24)
                }
                .width(50)
                .height(50)
                .borderRadius(8)
                .backgroundColor('#F5F5F5')
                .justifyContent(FlexAlign.Center)
                .margin({ right: 12 })

                // 歌曲信息
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Text(item.artist)
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

                // 时长
                if (item.duration && !this.isEditMode) {
                  Text(this.formatDuration(item.duration))
                    .fontSize(12)
                    .fontColor('#999999')
                }
              }
              .width('100%')
              .height(70)
              .padding({ left: 16, right: 16 })
              .backgroundColor(
                this.isEditMode && this.selectedItems.has(item.id) ? '#FFF5F5' :
                this.currentSong && this.currentSong.id === item.id ? '#FFF5F5' : '#FFFFFF'
              )
              .onClick(() => {
                if (this.isEditMode) {
                  this.toggleSelection(item.id);
                } else {
                  this.playSong(item, index);
                }
              })
            }
          }, (item: MusicItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}