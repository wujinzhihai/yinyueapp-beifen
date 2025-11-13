import http from '@ohos.net.http';
import { MusicItem } from '../models/MusicModels';

// 🔥 定义缓存数据接口
interface CacheData {
  data: string;
  timestamp: number;
}

// 🔥 定义 HTTP 请求选项接口
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  connectTimeout: number;
  readTimeout: number;
}

class MusicApiService {
  private static readonly BASE_URL: string = 'https://music-api.gdstudio.xyz/api.php';
  private static readonly DEFAULT_SOURCE: string = 'netease';

  // 🔥 限流配置
  private static readonly MAX_REQUESTS: number = 60;
  private static readonly TIME_WINDOW: number = 5 * 60 * 1000; // 5分钟
  private static readonly CACHE_DURATION: number = 10 * 60 * 1000; // 10分钟

  private static requestQueue: number[] = [];
  private static cache: Map<string, CacheData> = new Map();

  /**
   * 🔥 检查并等待请求许可
   */
  private static async checkRateLimit(): Promise<void> {
    const now: number = Date.now();

    // 移除5分钟之前的记录
    MusicApiService.requestQueue = MusicApiService.requestQueue.filter(
      (timestamp: number) => now - timestamp < MusicApiService.TIME_WINDOW
    );

    // 如果达到限制，等待
    if (MusicApiService.requestQueue.length >= MusicApiService.MAX_REQUESTS) {
      const oldestRequest: number = MusicApiService.requestQueue[0];
      const waitTime: number = MusicApiService.TIME_WINDOW - (now - oldestRequest);

      console.warn(`[MusicAPI] 请求频率限制，等待 ${Math.ceil(waitTime/1000)} 秒`);
      await MusicApiService.delay(waitTime);

      // 递归检查
      return MusicApiService.checkRateLimit();
    }

    // 记录本次请求
    MusicApiService.requestQueue.push(now);
    console.info(`[MusicAPI] 请求计数: ${MusicApiService.requestQueue.length}/${MusicApiService.MAX_REQUESTS}`);
  }

  /**
   * 🔥 HTTP请求封装（带缓存+限流）
   */
  private static async httpRequest(url: string, options?: HttpRequestOptions): Promise<http.HttpResponse> {
    const now: number = Date.now();

    // 🔥 检查缓存
    if (MusicApiService.cache.has(url)) {
      const cached: CacheData = MusicApiService.cache.get(url)!;
      if (now - cached.timestamp < MusicApiService.CACHE_DURATION) {
        console.info('[MusicAPI] 使用缓存，剩余有效期:',
          Math.ceil((MusicApiService.CACHE_DURATION - (now - cached.timestamp)) / 1000), '秒');

        // 🔥 返回模拟的 HttpResponse（补全所有必需属性）
        const mockResponse: http.HttpResponse = {
          result: cached.data,
          responseCode: 200,
          header: {},
          cookies: '',
          resultType: http.HttpDataType.STRING,
          performanceTiming: {
            dnsTiming: 0,
            tcpTiming: 0,
            tlsTiming: 0,
            firstSendTiming: 0,
            firstReceiveTiming: 0,
            totalFinishTiming: 0,
            redirectTiming: 0,
            responseHeaderTiming: 0,
            responseBodyTiming: 0,
            totalTiming: 0
          }
        };
        return mockResponse;
      } else {
        // 缓存过期，删除
        MusicApiService.cache.delete(url);
      }
    }

    // 检查频率限制
    await MusicApiService.checkRateLimit();

    // 发送请求
    const httpInstance: http.HttpRequest = http.createHttp();
    try {
      const requestOptions: HttpRequestOptions = options || {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'HarmonyOS-Music-App'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      };

      const response: http.HttpResponse = await httpInstance.request(url, requestOptions);

      // 🔥 缓存成功的响应
      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const cacheData: CacheData = {
          data: resultStr,
          timestamp: now
        };
        MusicApiService.cache.set(url, cacheData);
        console.info('[MusicAPI] 结果已缓存');
      }

      return response;
    } finally {
      httpInstance.destroy();
    }
  }

  /**
   * 获取音乐URL
   */
  static async getMusicUrl(
    source: string,
    id: string,
    quality: number = 320
  ): Promise<string> {
    console.info('[MusicAPI] 获取音频URL');

    try {
      const url: string = `${MusicApiService.BASE_URL}?types=url&source=${source || MusicApiService.DEFAULT_SOURCE}&id=${id}&br=${quality}`;
      const response: http.HttpResponse = await MusicApiService.httpRequest(url);

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const result: MusicUrlResponse = JSON.parse(response.result as string) as MusicUrlResponse;
      if (!result.url) {
        throw new Error('API 返回无效数据');
      }

      return result.url;
    } catch (error) {
      const err = error as Error;
      console.error('[MusicAPI] 获取URL失败:', err.message);
      throw new Error('获取音频地址失败: ' + err.message);
    }
  }

  /**
   * 搜索歌曲
   */
  static async searchSongs(
    keyword: string,
    source: string = 'netease',
    count: number = 20,
    pages: number = 1
  ): Promise<SearchResult[]> {
    try {
      const url: string = `${MusicApiService.BASE_URL}?types=search&source=${source}&name=${encodeURIComponent(keyword)}&count=${count}&pages=${pages}`;
      const response: http.HttpResponse = await MusicApiService.httpRequest(url);

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const results: SearchResponse[] = JSON.parse(response.result as string) as SearchResponse[];
      const searchResults: SearchResult[] = results.map((item: SearchResponse): SearchResult => {
        return {
          id: item.id,
          name: item.name,
          artist: Array.isArray(item.artist) ? item.artist.join(', ') : item.artist,
          album: item.album,
          picId: item.pic_id,
          lyricId: item.lyric_id,
          source: item.source
        };
      });

      return searchResults;
    } catch (error) {
      const err = error as Error;
      console.error('[MusicAPI] 搜索失败:', err.message);
      return [];
    }
  }

  /**
   * 兼容旧代码的搜索方法
   */
  static async searchMusic(
    keyword: string,
    source: string = 'netease'
  ): Promise<MusicItem[]> {
    const results: SearchResult[] = await MusicApiService.searchSongs(keyword, source);

    const musicItems: MusicItem[] = results.map((item: SearchResult): MusicItem => {
      return {
        id: item.id,
        name: item.name,
        artist: item.artist,
        album: item.album,
        source: item.source,
        picId: item.picId,
        lyricId: item.lyricId
      };
    });

    return musicItems;
  }

  /**
   * 获取封面 URL
   */
  static getCoverUrl(song: MusicItem): string {
    if (song.cover) {
      return song.cover;
    }
    return 'https://via.placeholder.com/300x300?text=Music';
  }

  /**
   * 获取专辑图
   */
  static async getPicUrl(
    source: string,
    picId: string,
    size: number = 300
  ): Promise<string> {
    try {
      const url: string = `${MusicApiService.BASE_URL}?types=pic&source=${source}&id=${picId}&size=${size}`;
      const response: http.HttpResponse = await MusicApiService.httpRequest(url);

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const result: PicResponse = JSON.parse(response.result as string) as PicResponse;
      if (!result.url) {
        throw new Error('获取专辑图失败');
      }

      return result.url;
    } catch (error) {
      const err = error as Error;
      console.error('[MusicAPI] 获取专辑图失败:', err.message);
      return '';
    }
  }

  /**
   * 获取歌词
   */
  static async getLyric(
    source: string,
    lyricId: string
  ): Promise<LyricResult> {
    try {
      const url: string = `${MusicApiService.BASE_URL}?types=lyric&source=${source}&id=${lyricId}`;
      const response: http.HttpResponse = await MusicApiService.httpRequest(url);

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const result: LyricResponse = JSON.parse(response.result as string) as LyricResponse;
      const lyricResult: LyricResult = {
        lyric: result.lyric || '',
        tlyric: result.tlyric || ''
      };

      return lyricResult;
    } catch (error) {
      const err = error as Error;
      console.error('[MusicAPI] 获取歌词失败:', err.message);
      const emptyResult: LyricResult = {
        lyric: '',
        tlyric: ''
      };
      return emptyResult;
    }
  }

  /**
   * 延迟函数
   */
  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => setTimeout(resolve, ms));
  }

  /**
   * 🔥 获取剩余请求次数
   */
  static getRemainingRequests(): number {
    const now: number = Date.now();
    MusicApiService.requestQueue = MusicApiService.requestQueue.filter(
      (timestamp: number) => now - timestamp < MusicApiService.TIME_WINDOW
    );
    return MusicApiService.MAX_REQUESTS - MusicApiService.requestQueue.length;
  }

  /**
   * 🔥 清除缓存
   */
  static clearCache(): void {
    MusicApiService.cache.clear();
    console.info('[MusicAPI] 缓存已清除');
  }

  /**
   * 🔥 获取缓存统计
   */
  static getCacheStats(): CacheStats {
    const stats: CacheStats = {
      size: MusicApiService.cache.size,
      urls: Array.from(MusicApiService.cache.keys())
    };
    return stats;
  }
}

// 🔥 接口定义
interface MusicUrlResponse {
  url: string;
  br: number;
  size: number;
}

interface SearchResponse {
  id: string;
  name: string;
  artist: string | string[];
  album: string;
  pic_id: string;
  url_id: string;
  lyric_id: string;
  source: string;
}

interface PicResponse {
  url: string;
}

interface LyricResponse {
  lyric: string;
  tlyric?: string;
}

export interface SearchResult {
  id: string;
  name: string;
  artist: string;
  album: string;
  picId: string;
  lyricId: string;
  source: string;
}

export interface LyricResult {
  lyric: string;
  tlyric: string;
}

export interface CacheStats {
  size: number;
  urls: string[];
}

// 导出类型别名
export { LyricResult as LyricData };
export { MusicItem };

export default MusicApiService;
