import media from '@ohos.multimedia.media';
import MusicApiService from './MusicApiService';
import { MusicItem, PlayState, PlayMode } from '../models/MusicModels';

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

  private constructor() {}

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
   * 🔥 核心修复：播放歌曲（带播放锁保护）
   */
  async play(song: MusicItem, playlist: MusicItem[], index: number): Promise<void> {
    // 🔒 检查播放锁，防止重复切歌
    if (this.isPlayingLock) {
      console.warn('[AudioPlayer] 正在切歌中，忽略重复请求');
      return;
    }

    console.info('[AudioPlayer] 开始播放:', song.name);

    // 🔒 上锁
    this.isPlayingLock = true;

    try {
      this.state.playlist = playlist;
      this.state.currentIndex = index;
      this.state.currentSong = song;
      this.state.playState = PlayState.LOADING;
      this.notifyListeners();

      const url = await MusicApiService.getMusicUrl(song.source, song.id, this.quality);
      console.info('[AudioPlayer] 获取音频URL成功');

      await this.initPlayer(url);

      this.state.playState = PlayState.PLAYING;
      this.notifyListeners();

    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('[AudioPlayer] 播放失败:', error.message);
      this.state.playState = PlayState.ERROR;
      this.notifyListeners();
      throw error;
    } finally {
      // 🔓 解锁
      this.isPlayingLock = false;
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
