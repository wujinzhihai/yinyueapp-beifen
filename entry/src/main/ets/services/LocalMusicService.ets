/**
 * 📁 本地音乐服务
 *
 * 功能: 扫描和管理本地音乐文件
 * - 扫描本地音乐目录
 * - 解析音频文件信息
 * - 提供本地音乐搜索
 * - 管理本地音乐列表
 */

import fileIo from '@ohos.file.fs';
import { MusicItem } from '../models/MusicModels';

export class LocalMusicService {
  private static localMusicList: MusicItem[] = [];
  private static isScanned: boolean = false;

  /**
   * 扫描本地音乐
   * @returns 本地音乐列表
   */
  static async scanLocalMusic(): Promise<MusicItem[]> {
    if (LocalMusicService.isScanned) {
      return LocalMusicService.localMusicList;
    }

    try {
      console.info('[LocalMusic] 开始扫描本地音乐...');

      // 扫描音乐目录
      const musicPaths = [
        '/storage/media/100/local/files/Music',
        '/storage/media/100/local/files/Download'
      ];

      LocalMusicService.localMusicList = [];

      for (const path of musicPaths) {
        try {
          const files = await LocalMusicService.scanDirectory(path);
          LocalMusicService.localMusicList.push(...files);
        } catch (error) {
          console.warn('[LocalMusic] 跳过目录:', path);
        }
      }

      LocalMusicService.isScanned = true;
      console.info('[LocalMusic] 扫描完成,共', LocalMusicService.localMusicList.length, '首');

      return LocalMusicService.localMusicList;
    } catch (error) {
      console.error('[LocalMusic] 扫描失败:', error);
      return [];
    }
  }

  /**
   * 扫描指定目录
   * @param path 目录路径
   * @returns 音乐文件列表
   */
  private static async scanDirectory(path: string): Promise<MusicItem[]> {
    const musicList: MusicItem[] = [];

    try {
      const files = fileIo.listFileSync(path);

      for (const file of files) {
        const fullPath = `${path}/${file}`;

        if (LocalMusicService.isAudioFile(file)) {
          const musicItem = LocalMusicService.createMusicItem(fullPath, file);
          musicList.push(musicItem);
        }
      }
    } catch (error) {
      console.error('[LocalMusic] 扫描目录失败:', path, error);
    }

    return musicList;
  }

  /**
   * 判断是否为音频文件
   * @param filename 文件名
   * @returns 是否为音频文件
   */
  private static isAudioFile(filename: string): boolean {
    const audioExtensions = ['.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg'];
    return audioExtensions.some(ext => filename.toLowerCase().endsWith(ext));
  }

  /**
   * 创建音乐项
   * @param filePath 文件路径
   * @param filename 文件名
   * @returns 音乐项
   */
  private static createMusicItem(filePath: string, filename: string): MusicItem {
    // 去除文件扩展名
    const nameWithoutExt = filename.replace(/\.[^/.]+$/, '');

    // 尝试从文件名解析歌手和歌名 (格式: 歌手 - 歌名)
    let name = nameWithoutExt;
    let artist = '未知艺术家';

    if (nameWithoutExt.includes(' - ')) {
      const parts = nameWithoutExt.split(' - ');
      artist = parts[0].trim();
      name = parts[1].trim();
    }

    const musicItem: MusicItem = {
      id: `local_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: name,
      artist: artist,
      album: '本地音乐',
      source: 'local',
      localPath: filePath,
      duration: 0
    };
    
    return musicItem;
  }

  /**
   * 搜索本地音乐
   * @param keyword 搜索关键词
   * @returns 匹配的音乐列表
   */
  static searchLocalMusic(keyword: string): MusicItem[] {
    const lowerKeyword = keyword.toLowerCase();
    return LocalMusicService.localMusicList.filter(song =>
      song.name.toLowerCase().includes(lowerKeyword) ||
      song.artist.toLowerCase().includes(lowerKeyword)
    );
  }

  /**
   * 获取所有本地音乐
   * @returns 本地音乐列表
   */
  static getLocalMusicList(): MusicItem[] {
    return LocalMusicService.localMusicList;
  }

  /**
   * 刷新本地音乐库
   * @returns 更新后的音乐列表
   */
  static async refresh(): Promise<MusicItem[]> {
    LocalMusicService.isScanned = false;
    LocalMusicService.localMusicList = [];
    return await LocalMusicService.scanLocalMusic();
  }

  /**
   * 获取本地音乐数量
   * @returns 音乐数量
   */
  static getCount(): number {
    return LocalMusicService.localMusicList.length;
  }

  /**
   * 从应用列表中移除音乐(不删除手机文件)
   * @param musicId 音乐ID
   * @returns 是否成功
   */
  static removeFromList(musicId: string): boolean {
    const index = LocalMusicService.localMusicList.findIndex(item => item.id === musicId);
    if (index > -1) {
      LocalMusicService.localMusicList.splice(index, 1);
      console.info('[LocalMusic] 已从列表移除:', musicId);
      return true;
    }
    return false;
  }

  /**
   * 批量从应用列表中移除音乐
   * @param musicIds 音乐ID数组
   * @returns 移除的数量
   */
  static removeBatchFromList(musicIds: string[]): number {
    let count = 0;
    for (const id of musicIds) {
      if (LocalMusicService.removeFromList(id)) {
        count++;
      }
    }
    console.info('[LocalMusic] 批量移除完成,共', count, '首');
    return count;
  }

  /**
   * 清空应用音乐列表(不删除手机文件)
   */
  static clearList(): void {
    LocalMusicService.localMusicList = [];
    console.info('[LocalMusic] 已清空列表');
  }
}