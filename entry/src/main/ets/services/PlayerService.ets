// entry/src/main/ets/services/PlayerService.ets

import { media } from '@kit.MediaKit'
import { Song } from '../models/Song'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 音乐播放服务 - 使用 AppStorage 全局状态
 */
export class PlayerService {
  private static instance: PlayerService | null = null
  private avPlayer: media.AVPlayer | null = null
  private progressTimer: number = -1

  private constructor() {
    this.initAppStorage()
  }

  /**
   * 初始化 AppStorage 全局状态
   */
  private initAppStorage(): void {
    AppStorage.setOrCreate('currentSong', null)
    AppStorage.setOrCreate('isPlaying', false)
    AppStorage.setOrCreate('currentTime', 0)
    AppStorage.setOrCreate('duration', 0)
    AppStorage.setOrCreate('playlist', [])
    AppStorage.setOrCreate('currentIndex', -1)
    console.info('[PlayerService] AppStorage 初始化完成')
  }

  /**
   * 获取单例
   */
  static getInstance(): PlayerService {
    if (!PlayerService.instance) {
      PlayerService.instance = new PlayerService()
    }
    return PlayerService.instance
  }

  /**
   * 播放歌曲
   */
  async play(song: Song, playlist: Song[] = [], index: number = -1): Promise<void> {
    console.info(`[PlayerService] 开始播放: ${song.name} - ${song.artist}`)
    console.info(`[PlayerService] 音频URL: ${song.audioUrl}`)

    if (!song.audioUrl || song.audioUrl === '') {
      console.error('[PlayerService] 音频URL无效，无法播放')
      return
    }

    try {
      // 更新状态
      AppStorage.set('currentSong', song)
      AppStorage.set('playlist', playlist)
      AppStorage.set('currentIndex', index)
      AppStorage.set('currentTime', 0)
      AppStorage.set('duration', 0)

      // 重置播放器
      await this.resetPlayer()

      // 创建播放器
      this.avPlayer = await media.createAVPlayer()
      console.info('[PlayerService] AVPlayer 创建成功')

      // 设置回调
      this.setupCallbacks()

      // 设置 URL
      this.avPlayer.url = song.audioUrl
      console.info('[PlayerService] 设置音频URL完成，等待播放...')

    } catch (error) {
      const err = error as BusinessError
      console.error(`[PlayerService] 播放失败: ${err.message}`)
      AppStorage.set('isPlaying', false)
    }
  }

  /**
   * 设置 AVPlayer 回调
   */
  private setupCallbacks(): void {
    if (!this.avPlayer) return

    // 状态变化回调
    this.avPlayer.on('stateChange', (state: string) => {
      console.info(`[PlayerService] 状态变化: ${state}`)

      if (state === 'prepared') {
        console.info('[PlayerService] 准备完成，开始播放')
        this.avPlayer?.play()
      } else if (state === 'playing') {
        console.info('[PlayerService] 正在播放')
        AppStorage.set('isPlaying', true)
        this.startProgressTimer()

        // 获取时长
        if (this.avPlayer?.duration) {
          const duration = this.avPlayer.duration / 1000
          AppStorage.set('duration', duration)
          console.info(`[PlayerService] 歌曲时长: ${duration}s`)
        }
      } else if (state === 'paused') {
        console.info('[PlayerService] 已暂停')
        AppStorage.set('isPlaying', false)
        this.stopProgressTimer()
      } else if (state === 'completed') {
        console.info('[PlayerService] 播放完成')
        AppStorage.set('isPlaying', false)
        this.stopProgressTimer()
        this.playNext()
      } else if (state === 'stopped' || state === 'released') {
        console.info('[PlayerService] 已停止/释放')
        AppStorage.set('isPlaying', false)
        this.stopProgressTimer()
      }
    })

    // 错误回调
    this.avPlayer.on('error', (error: BusinessError) => {
      console.error(`[PlayerService] 播放错误: ${error.message}`)
      AppStorage.set('isPlaying', false)
      this.stopProgressTimer()
    })
  }

  /**
   * 切换播放/暂停
   */
  async togglePlay(): Promise<void> {
    const isPlaying = AppStorage.get<boolean>('isPlaying') || false
    console.info(`[PlayerService] 切换播放状态: ${isPlaying ? '暂停' : '播放'}`)

    if (!this.avPlayer) {
      console.warn('[PlayerService] 播放器未初始化')
      return
    }

    try {
      if (isPlaying) {
        await this.avPlayer.pause()
        console.info('[PlayerService] 暂停成功')
      } else {
        await this.avPlayer.play()
        console.info('[PlayerService] 播放成功')
      }
    } catch (error) {
      const err = error as BusinessError
      console.error(`[PlayerService] 切换播放状态失败: ${err.message}`)
    }
  }

  /**
   * 播放下一首
   */
  async playNext(): Promise<void> {
    const playlist = AppStorage.get<Song[]>('playlist') || []
    const currentIndex = AppStorage.get<number>('currentIndex') || -1

    if (playlist.length === 0 || currentIndex === -1) {
      console.warn('[PlayerService] 播放列表为空或索引无效')
      return
    }

    const nextIndex = (currentIndex + 1) % playlist.length
    console.info(`[PlayerService] 播放下一首: 索引 ${nextIndex}`)
    await this.play(playlist[nextIndex], playlist, nextIndex)
  }

  /**
   * 播放上一首
   */
  async playPrevious(): Promise<void> {
    const playlist = AppStorage.get<Song[]>('playlist') || []
    const currentIndex = AppStorage.get<number>('currentIndex') || -1

    if (playlist.length === 0 || currentIndex === -1) {
      console.warn('[PlayerService] 播放列表为空或索引无效')
      return
    }

    const prevIndex = (currentIndex - 1 + playlist.length) % playlist.length
    console.info(`[PlayerService] 播放上一首: 索引 ${prevIndex}`)
    await this.play(playlist[prevIndex], playlist, prevIndex)
  }

  /**
   * 跳转到指定时间
   */
  async seek(time: number): Promise<void> {
    if (!this.avPlayer) {
      console.warn('[PlayerService] 播放器未初始化')
      return
    }

    try {
      const seekTime = Math.floor(time * 1000) // 转为毫秒
      await this.avPlayer.seek(seekTime)
      AppStorage.set('currentTime', time)
      console.info(`[PlayerService] 跳转到: ${time}s`)
    } catch (error) {
      const err = error as BusinessError
      console.error(`[PlayerService] 跳转失败: ${err.message}`)
    }
  }

  /**
   * 启动进度定时器
   */
  private startProgressTimer(): void {
    this.stopProgressTimer()

    this.progressTimer = setInterval(() => {
      if (this.avPlayer && this.avPlayer.currentTime !== undefined) {
        const currentTime = this.avPlayer.currentTime / 1000
        AppStorage.set('currentTime', currentTime)
      }
    }, 500) // 每 500ms 更新一次
  }

  /**
   * 停止进度定时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer)
      this.progressTimer = -1
    }
  }

  /**
   * 重置播放器
   */
  private async resetPlayer(): Promise<void> {
    this.stopProgressTimer()

    if (this.avPlayer) {
      try {
        await this.avPlayer.reset()
        console.info('[PlayerService] 播放器重置成功')
      } catch (error) {
        console.warn('[PlayerService] 播放器重置失败，尝试释放')
        try {
          await this.avPlayer.release()
        } catch (e) {
          console.error('[PlayerService] 播放器释放失败')
        }
      }
      this.avPlayer = null
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    console.info('[PlayerService] 释放资源')
    this.stopProgressTimer()

    if (this.avPlayer) {
      try {
        await this.avPlayer.release()
        console.info('[PlayerService] 播放器释放成功')
      } catch (error) {
        console.error('[PlayerService] 播放器释放失败')
      }
      this.avPlayer = null
    }

    AppStorage.set('isPlaying', false)
    AppStorage.set('currentTime', 0)
  }
}
