import { Song } from './Song';

/**
 * 播放模式枚举
 */
export enum PlayMode {
  SEQUENCE = 0,  // 顺序播放
  RANDOM = 1,    // 随机播放
  SINGLE = 2     // 单曲循环
}

/**
 * 播放列表模型
 */
export class Playlist {
  songs: Song[] = []              // 歌曲列表
  currentIndex: number = 0        // 当前播放索引
  playMode: PlayMode = PlayMode.SEQUENCE  // 播放模式

  constructor(songs?: Song[]) {
    if (songs) {
      this.songs = songs;
    }
  }

  /**
   * 获取当前歌曲
   */
  getCurrentSong(): Song | null {
    if (this.currentIndex >= 0 && this.currentIndex < this.songs.length) {
      return this.songs[this.currentIndex];
    }
    return null;
  }

  /**
   * 计算下一首索引
   */
  getNextIndex(): number {
    if (this.songs.length === 0) return -1;

    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return (this.currentIndex + 1) % this.songs.length;
      case PlayMode.RANDOM:
        return Math.floor(Math.random() * this.songs.length);
      case PlayMode.SINGLE:
        return this.currentIndex;
      default:
        return 0;
    }
  }

  /**
   * 计算上一首索引
   */
  getPreviousIndex(): number {
    if (this.songs.length === 0) return -1;

    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return this.currentIndex === 0 ? this.songs.length - 1 : this.currentIndex - 1;
      case PlayMode.RANDOM:
        return Math.floor(Math.random() * this.songs.length);
      case PlayMode.SINGLE:
        return this.currentIndex;
      default:
        return 0;
    }
  }
}
