// entry/src/main/ets/services/MusicApiService.ets

import { http } from '@kit.NetworkKit'
import { Song } from '../models/Song'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * API 响应接口
 */
interface ApiResponse {
  code: number
  message: string
  data: SongData[]
}

/**
 * 歌曲数据接口
 */
interface SongData {
  id: number
  name: string
  artist: string
  album: string
  duration: number
  coverUrl: string
  audioUrl: string
}

export class MusicApiService {
  private static readonly BASE_URL: string = 'http://your-api-domain.com'

  /**
   * 获取热门歌曲
   */
  static async getHotSongs(limit?: number): Promise<Song[]> {
    try {
      const request = http.createHttp()
      const url = `${MusicApiService.BASE_URL}/hot?limit=${limit || 20}`

      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      })

      if (response.responseCode === 200) {
        const result: ApiResponse = JSON.parse(response.result as string)
        return result.data?.map((item: SongData): Song =>
        new Song(
          item.id,
          item.name,
          item.artist,
          item.album,
          item.duration,
          item.audioUrl,    // ⚠️ 注意：audioUrl 在 coverUrl 之前
          item.coverUrl
        )
        ) || []
      } else {
        throw new Error(`请求失败: ${response.responseCode}`)
      }
    } catch (error) {
      const err = error as BusinessError
      console.error('[MusicApiService] 获取热门歌曲失败:', err.message)
      throw new Error(`获取热门歌曲失败: ${err.message}`)
    }
  }

  /**
   * 搜索歌曲
   */
  static async searchSongs(keyword: string, limit?: number): Promise<Song[]> {
    try {
      const request = http.createHttp()
      const url = `${MusicApiService.BASE_URL}/search?keyword=${encodeURIComponent(keyword)}&limit=${limit || 20}`

      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      })

      if (response.responseCode === 200) {
        const result: ApiResponse = JSON.parse(response.result as string)
        return result.data?.map((item: SongData): Song =>
        new Song(
          item.id,
          item.name,
          item.artist,
          item.album,
          item.duration,
          item.audioUrl,
          item.coverUrl
        )
        ) || []
      } else {
        throw new Error(`搜索失败: ${response.responseCode}`)
      }
    } catch (error) {
      const err = error as BusinessError
      console.error('[MusicApiService] 搜索歌曲失败:', err.message)
      throw new Error(`搜索歌曲失败: ${err.message}`)
    }
  }

  /**
   * 根据 ID 获取歌曲详情
   */
  static async getSongById(id: number): Promise<Song | null> {
    try {
      const request = http.createHttp()
      const url = `${MusicApiService.BASE_URL}/song/${id}`

      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 10000,
        readTimeout: 10000
      })

      if (response.responseCode === 200) {
        const result: ApiResponse = JSON.parse(response.result as string)
        const item: SongData | undefined = result.data?.[0]
        if (item) {
          return new Song(
            item.id,
            item.name,
            item.artist,
            item.album,
            item.duration,
            item.audioUrl,
            item.coverUrl
          )
        }
      }
      return null
    } catch (error) {
      const err = error as BusinessError
      console.error('[MusicApiService] 获取歌曲详情失败:', err.message)
      return null
    }
  }
}
