/**
 * 🎵 音频播放服务
 *
 * 功能: 管理音乐播放的核心服务
 * - 单例模式,全局唯一播放器实例
 * - 播放/暂停/上一曲/下一曲控制
 * - 播放失败自动重试和跳过
 * - 状态管理和AppStorage同步
 * - 订阅/取消订阅机制
 * - AVSession媒体会话支持
 * - 通知栏音乐控制
 * - 后台播放支持
 */

import media from '@ohos.multimedia.media';
import avSession from '@ohos.multimedia.avsession';
import image from '@ohos.multimedia.image';
import MusicApiService from './MusicApiService';
import { MusicItem, PlayState, PlayMode } from '../models/MusicModels';
import { BusinessError } from '@ohos.base';

export { PlayState, PlayMode };

interface PlayerState {
  currentSong: MusicItem | null;
  playState: PlayState;
  currentTime: number;
  duration: number;
  playlist: MusicItem[];
  currentIndex: number;
  playMode: PlayMode;
}

type StateListener = (state: PlayerState) => void;

class AudioPlayerService {
  private static instance: AudioPlayerService | null = null;
  private avPlayer: media.AVPlayer | null = null;
  private session: avSession.AVSession | null = null; // 🎵 媒体会话
  private state: PlayerState = {
    currentSong: null,
    playState: PlayState.IDLE,
    currentTime: 0,
    duration: 0,
    playlist: [],
    currentIndex: -1,
    playMode: PlayMode.LOOP
  };
  private listeners: StateListener[] = [];
  private updateTimer: number = -1;
  private quality: number = 320;
  private isPlayingLock: boolean = false; // 🔒 播放锁，防止重复切歌
  private retryCount: number = 0; // 🔄 重试计数器
  private maxRetries: number = 1; // 🔄 最大重试次数

  private constructor() {
    // 延迟初始化AVSession,等待context设置
    setTimeout(() => {
      this.initAVSession();
    }, 500);
  }

  static getInstance(): AudioPlayerService {
    if (!AudioPlayerService.instance) {
      AudioPlayerService.instance = new AudioPlayerService();
    }
    return AudioPlayerService.instance;
  }

  subscribe(listener: StateListener): () => void {
    this.listeners.push(listener);
    listener(this.state);
    
    // 🔥 返回取消订阅函数
    return () => {
      this.unsubscribe(listener);
    };
  }

  unsubscribe(listener: StateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
      console.info('[AudioPlayer] 移除监听器,剩余:', this.listeners.length);
    }
  }

  private notifyListeners(): void {
    console.info('🔍 [AudioPlayer-Debug] 通知监听器，监听器数量:', this.listeners.length);
    console.info('🔍 [AudioPlayer-Debug] 当前状态 - 歌曲:', this.state.currentSong?.name || 'null');
    console.info('🔍 [AudioPlayer-Debug] 当前状态 - playState:', this.state.playState);
    console.info('🔍 [AudioPlayer-Debug] 当前状态 - currentIndex:', this.state.currentIndex);
    
    // 🔥 核心修复：直接更新 AppStorage，确保UI组件响应状态变化
    AppStorage.setOrCreate('currentSong', this.state.currentSong);
    AppStorage.setOrCreate('playState', this.state.playState);
    AppStorage.setOrCreate('currentTime', this.state.currentTime);
    AppStorage.setOrCreate('duration', this.state.duration);
    AppStorage.setOrCreate('playlist', this.state.playlist);
    AppStorage.setOrCreate('currentIndex', this.state.currentIndex);
    AppStorage.setOrCreate('playMode', this.state.playMode);
    
    console.info('✅ [AudioPlayer-Debug] AppStorage 已更新');
    
    this.listeners.forEach((listener, index) => {
      console.info(`🔍 [AudioPlayer-Debug] 调用监听器 ${index + 1}`);
      listener(this.state);
    });
  }

  /**
   * 🎵 初始化AVSession媒体会话
   */
  private async initAVSession(): Promise<void> {
    try {
      // 从AppStorage获取上下文
      const context = AppStorage.get('abilityContext') as Context;
      if (!context) {
        console.error('[AVSession] 无法获取abilityContext,延迟重试');
        // 延迟重试
        setTimeout(() => {
          this.initAVSession();
        }, 1000);
        return;
      }

      // 创建媒体会话
      this.session = await avSession.createAVSession(
        context,
        'MusicPlayer',
        'audio'
      );
      
      console.info('[AVSession] 媒体会话创建成功');

      // 激活会话
      await this.session.activate();
      console.info('[AVSession] 媒体会话已激活');

      // 监听播放控制命令
      this.session.on('play', () => {
        console.info('[AVSession] 收到播放命令');
        this.togglePlay();
      });

      this.session.on('pause', () => {
        console.info('[AVSession] 收到暂停命令');
        this.togglePlay();
      });

      this.session.on('stop', () => {
        console.info('[AVSession] 收到停止命令');
        this.togglePlay();
      });

      this.session.on('playNext', () => {
        console.info('[AVSession] 收到下一曲命令');
        this.next();
      });

      this.session.on('playPrevious', () => {
        console.info('[AVSession] 收到上一曲命令');
        this.previous();
      });

      this.session.on('seek', (time: number) => {
        console.info('[AVSession] 收到跳转命令:', time);
        this.seek(time / 1000);
      });

    } catch (error) {
      const err = error as BusinessError;
      console.error('[AVSession] 初始化失败:', err.code, err.message);
    }
  }

  /**
   * 🎵 更新媒体会话元数据
   */
  private async updateAVMetadata(): Promise<void> {
    if (!this.session || !this.state.currentSong) {
      return;
    }

    try {
      const metadata: avSession.AVMetadata = {
        assetId: this.state.currentSong.id,
        title: this.state.currentSong.name,
        artist: this.state.currentSong.artist,
        album: this.state.currentSong.album || '未知专辑',
        duration: this.state.duration * 1000,
      };

      // 如果有封面图片,添加封面
      if (this.state.currentSong.picId && this.state.currentSong.source) {
        try {
          const coverUrl = await MusicApiService.getPicUrl(
            this.state.currentSong.source,
            this.state.currentSong.picId,
            200
          );
          
          // 注意: HarmonyOS需要PixelMap格式的图片
          // 这里简化处理,实际项目中需要将URL转换为PixelMap
          metadata.mediaImage = coverUrl;
        } catch (error) {
          console.error('[AVSession] 获取封面失败:', error);
        }
      }

      await this.session.setAVMetadata(metadata);
      console.info('[AVSession] 元数据已更新');
    } catch (error) {
      const err = error as BusinessError;
      console.error('[AVSession] 更新元数据失败:', err.code, err.message);
    }
  }

  /**
   * 🎵 更新播放状态
   */
  private async updateAVPlaybackState(): Promise<void> {
    if (!this.session) {
      return;
    }

    try {
      const playbackState: avSession.AVPlaybackState = {
        state: this.convertPlayState(this.state.playState),
        position: {
          elapsedTime: this.state.currentTime * 1000,
          updateTime: Date.now()
        },
        speed: this.state.playState === PlayState.PLAYING ? 1.0 : 0.0,
        loopMode: avSession.LoopMode.LOOP_MODE_SEQUENCE,
      };

      await this.session.setAVPlaybackState(playbackState);
      console.info('[AVSession] 播放状态已更新');
    } catch (error) {
      const err = error as BusinessError;
      console.error('[AVSession] 更新播放状态失败:', err.code, err.message);
    }
  }

  /**
   * 🎵 转换播放状态
   */
  private convertPlayState(state: PlayState): avSession.PlaybackState {
    switch (state) {
      case PlayState.PLAYING:
        return avSession.PlaybackState.PLAYBACK_STATE_PLAY;
      case PlayState.PAUSED:
        return avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
      case PlayState.LOADING:
        return avSession.PlaybackState.PLAYBACK_STATE_PREPARE;
      case PlayState.ERROR:
        return avSession.PlaybackState.PLAYBACK_STATE_ERROR;
      default:
        return avSession.PlaybackState.PLAYBACK_STATE_STOP;
    }
  }

  /**
   * 🔥 核心修复：播放歌曲（带播放锁保护和重试机制）
   */
  async play(song: MusicItem, playlist: MusicItem[], index: number, isRetry: boolean = false): Promise<void> {
    // 🔒 检查播放锁，防止重复切歌
    if (this.isPlayingLock) {
      console.warn('[AudioPlayer] 正在切歌中，忽略重复请求');
      return;
    }

    // 🔄 如果不是重试,重置重试计数器
    if (!isRetry) {
      this.retryCount = 0;
    }

    console.info('[AudioPlayer] 开始播放:', song.name, isRetry ? `(重试 ${this.retryCount + 1}/${this.maxRetries})` : '');

    // 🔒 上锁
    this.isPlayingLock = true;

    try {
      this.state.playlist = playlist;
      this.state.currentIndex = index;
      this.state.currentSong = song;
      this.state.playState = PlayState.LOADING;
      this.notifyListeners();

      // 🔥 根据音乐来源获取播放URL
      let url: string;
      if (song.source === 'local') {
        // 本地音乐使用文件路径
        url = `file://${song.localPath}`;
        console.info('[AudioPlayer] 使用本地文件:', url);
      } else {
        // 网络音乐获取URL
        url = await MusicApiService.getMusicUrl(song.source, song.id, this.quality);
        console.info('[AudioPlayer] 获取网络音频URL成功');
      }

      await this.initPlayer(url);

      this.state.playState = PlayState.PLAYING;
      this.notifyListeners();
      
      // 🎵 更新媒体会话
      await this.updateAVMetadata();
      await this.updateAVPlaybackState();
      
      // 🔄 播放成功,重置重试计数器
      this.retryCount = 0;

    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('[AudioPlayer] 播放失败:', error.message);
      this.state.playState = PlayState.ERROR;
      this.notifyListeners();
      
      // 🔄 处理播放失败
      await this.handlePlayError(song, playlist, index);
    } finally {
      // 🔓 解锁
      this.isPlayingLock = false;
    }
  }

  /**
   * 🔄 处理播放失败：重试或跳过
   */
  private async handlePlayError(song: MusicItem, playlist: MusicItem[], index: number): Promise<void> {
    // 🔄 检查是否可以重试
    if (this.retryCount < this.maxRetries) {
      this.retryCount++;
      console.warn(`[AudioPlayer] 播放失败，准备重试 (${this.retryCount}/${this.maxRetries})`);
      
      // 延迟1秒后重试
      await new Promise<void>((resolve: (value: void) => void) => setTimeout(resolve, 1000));
      
      try {
        await this.play(song, playlist, index, true);
      } catch (error) {
        console.error('[AudioPlayer] 重试失败:', error);
      }
    } else {
      // 🔄 重试次数用完,自动播放下一曲
      console.warn('[AudioPlayer] 重试次数已用完，自动播放下一曲');
      this.retryCount = 0; // 重置计数器
      
      // 延迟1秒后播放下一曲
      setTimeout(() => {
        this.next().catch((error: Error) => {
          console.error('[AudioPlayer] 自动播放下一曲失败:', error);
        });
      }, 1000);
    }
  }

  /**
   * 🔥 核心修复：初始化播放器（等待状态机完成）
   */
  private async initPlayer(url: string): Promise<void> {
    // 释放旧播放器
    if (this.avPlayer) {
      try {
        // 🔥 优化：先移除所有监听器，避免旧回调干扰
        this.avPlayer.off('stateChange');
        this.avPlayer.off('durationUpdate');
        this.avPlayer.off('timeUpdate');
        this.avPlayer.off('endOfStream');
        this.avPlayer.off('error');

        await this.avPlayer.release();
      } catch (error) {
        console.error('[AudioPlayer] 释放旧播放器失败:', error);
      } finally {
        this.avPlayer = null;
      }
    }

    // 创建新播放器
    this.avPlayer = await media.createAVPlayer();

    // 🔥 关键：使用Promise等待状态变化
    return new Promise((resolve, reject) => {
      let isPrepared = false;

      // 监听状态变化
      this.avPlayer!.on('stateChange', async (state) => {
        console.info('[AudioPlayer] 状态变化:', state);

        try {
          switch (state) {
            case 'initialized':
              // 状态2：已初始化，调用prepare
              console.info('[AudioPlayer] 调用 prepare()');
              await this.avPlayer!.prepare();
              break;

            case 'prepared':
              // 状态3：准备完成，可以播放
              console.info('[AudioPlayer] 调用 play()');
              isPrepared = true;
              await this.avPlayer!.play();
              this.startUpdateTimer();
              resolve(); // ✅ 成功
              break;

            case 'playing':
              console.info('[AudioPlayer] 正在播放');
              break;

            case 'error':
              if (!isPrepared) {
                reject(new Error('播放器进入错误状态'));
              }
              break;
          }
        } catch (error) {
          console.error('[AudioPlayer] 状态处理失败:', error);
          if (!isPrepared) {
            reject(error);
          }
        }
      });

      // 监听时长更新
      this.avPlayer!.on('durationUpdate', (duration) => {
        this.state.duration = duration / 1000;
        this.notifyListeners();
      });

      // 监听时间更新
      this.avPlayer!.on('timeUpdate', (time) => {
        this.state.currentTime = time / 1000;
        this.notifyListeners();
      });

      // 监听播放完成
      this.avPlayer!.on('endOfStream', () => {
        console.info('[AudioPlayer] 播放完成');
        this.next();
      });

      // 监听错误
      this.avPlayer!.on('error', (error) => {
        console.error('[AudioPlayer] 错误:', error);
        this.state.playState = PlayState.ERROR;
        this.notifyListeners();
        if (!isPrepared) {
          reject(error);
        }
      });

      // 设置URL（触发状态机：idle → initialized）
      try {
        this.avPlayer!.url = url;
        console.info('[AudioPlayer] URL已设置，等待初始化');
      } catch (error) {
        reject(error);
      }

      // 超时保护（10秒）
      setTimeout(() => {
        if (!isPrepared) {
          reject(new Error('播放器初始化超时'));
        }
      }, 10000);
    });
  }

  /**
   * 切换播放/暂停
   */
  async togglePlay(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      if (this.state.playState === PlayState.PLAYING) {
        await this.avPlayer.pause();
        this.state.playState = PlayState.PAUSED;
        this.stopUpdateTimer();
      } else if (this.state.playState === PlayState.PAUSED) {
        await this.avPlayer.play();
        this.state.playState = PlayState.PLAYING;
        this.startUpdateTimer();
      }
      this.notifyListeners();
      
      // 🎵 更新播放状态
      await this.updateAVPlaybackState();
    } catch (error) {
      console.error('[AudioPlayer] 切换播放状态失败:', error);
    }
  }

  /**
   * 上一曲（异步方法，等待切歌完成）
   */
  async previous(): Promise<void> {
    if (this.state.currentIndex > 0) {
      const newIndex = this.state.currentIndex - 1;
      await this.play(this.state.playlist[newIndex], this.state.playlist, newIndex);
    } else {
      console.warn('[AudioPlayer] 已经是第一首歌');
    }
  }

  /**
   * 下一曲（异步方法，等待切歌完成）
   */
  async next(): Promise<void> {
    if (this.state.currentIndex < this.state.playlist.length - 1) {
      const newIndex = this.state.currentIndex + 1;
      await this.play(this.state.playlist[newIndex], this.state.playlist, newIndex);
    } else {
      console.warn('[AudioPlayer] 已经是最后一首歌');
    }
  }

  /**
   * 跳转到指定位置
   */
  async seek(time: number): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.seek(time * 1000);
        this.state.currentTime = time;
        this.notifyListeners();
      } catch (error) {
        console.error('[AudioPlayer] Seek失败:', error);
      }
    }
  }

  /**
   * 设置音质
   */
  setQuality(quality: number): void {
    this.quality = quality;
  }

  /**
   * 启动更新定时器
   */
  private startUpdateTimer(): void {
    this.stopUpdateTimer();
    this.updateTimer = setInterval(() => {
      if (this.avPlayer && this.state.playState === PlayState.PLAYING) {
        this.notifyListeners();
      }
    }, 500);
  }

  /**
   * 停止更新定时器
   */
  private stopUpdateTimer(): void {
    if (this.updateTimer !== -1) {
      clearInterval(this.updateTimer);
      this.updateTimer = -1;
    }
  }

  /**
   * 🔥 修复：应用关闭时释放资源
   */
  async release(): Promise<void> {
    console.info('[AudioPlayer] 释放资源');

    this.stopUpdateTimer();

    // 释放媒体会话
    if (this.session) {
      try {
        await this.session.deactivate();
        await this.session.destroy();
        console.info('[AVSession] 媒体会话已释放');
      } catch (error) {
        console.error('[AVSession] 释放媒体会话失败:', error);
      } finally {
        this.session = null;
      }
    }

    if (this.avPlayer) {
      try {
        // 先停止播放
        if (this.state.playState === PlayState.PLAYING ||
          this.state.playState === PlayState.PAUSED) {
          await this.avPlayer.stop();
        }

        // 重置状态
        await this.avPlayer.reset();

        // 释放资源
        await this.avPlayer.release();

        console.info('[AudioPlayer] 播放器已释放');
      } catch (error) {
        console.error('[AudioPlayer] 释放失败:', error);
      } finally {
        this.avPlayer = null;
      }
    }

    // 重置状态
    this.state.playState = PlayState.IDLE;
    this.state.currentSong = null;
    this.state.currentTime = 0;
    this.state.duration = 0;
    this.notifyListeners();
  }

  /**
   * 🔥 新增：重置播放器（用于重新播放）
   */
  async reset(): Promise<void> {
    console.info('[AudioPlayer] 重置播放器');
    await this.release();
  }
}

export default AudioPlayerService;
