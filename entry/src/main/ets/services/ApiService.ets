import { Song } from '../models/Song';
import { MOCK_SONGS } from '../common/constants/ApiConstants';

/**
 * API服务类（当前使用Mock数据）
 */
export class ApiService {
  /**
   * 搜索歌曲（模拟异步请求）
   */
  static async searchSongs(keyword: string): Promise<Song[]> {
    // 模拟网络延迟
    await new Promise<void>((resolve: (value: void) => void) => {
      setTimeout((): void => resolve(), 500);
    });

    // 模拟搜索过滤
    if (!keyword || keyword.trim() === '') {
      return MOCK_SONGS;
    }

    return MOCK_SONGS.filter((song: Song): boolean =>
    song.name.toLowerCase().includes(keyword.toLowerCase()) ||
    song.artist.toLowerCase().includes(keyword.toLowerCase())
    );
  }

  /**
   * 获取歌曲详情
   */
  static async getSongDetail(id: number): Promise<Song | null> {
    await new Promise<void>((resolve: (value: void) => void) => {
      setTimeout((): void => resolve(), 300);
    });

    const song = MOCK_SONGS.find((s: Song): boolean => s.id === id);
    return song !== undefined ? song : null;
  }

  /**
   * 获取推荐歌曲
   */
  static async getRecommendSongs(): Promise<Song[]> {
    await new Promise<void>((resolve: (value: void) => void) => {
      setTimeout((): void => resolve(), 500);
    });
    return MOCK_SONGS;
  }
}
