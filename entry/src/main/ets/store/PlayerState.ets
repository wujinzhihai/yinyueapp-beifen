import { Song } from '../models/Song'
import { PlayMode } from '../common/constants/PlayMode'

/**
 * 播放器状态接口
 */
export interface PlayerState {
  currentSong: Song | null
  playList: Song[]
  currentIndex: number
  isPlaying: boolean
  isLoading: boolean
  playMode: PlayMode
  currentTime: number
  duration: number
  volume: number
}

/**
 * 全局播放器状态
 */
let globalPlayerState: PlayerState = {
  currentSong: null,
  playList: [],
  currentIndex: 0,
  isPlaying: false,
  isLoading: false,
  playMode: PlayMode.LOOP,
  currentTime: 0,
  duration: 0,
  volume: 1.0
}

/**
 * 获取播放器状态
 */
export function getPlayerState(): PlayerState {
  return globalPlayerState
}

/**
 * 更新播放器状态（手动合并属性，避免使用展开运算符）
 */
export function updatePlayerState(updates: Partial<PlayerState>): void {
  // ✅ 手动合并对象属性（ArkTS不支持对象展开）
  if (updates.currentSong !== undefined) {
    globalPlayerState.currentSong = updates.currentSong
  }
  if (updates.playList !== undefined) {
    globalPlayerState.playList = updates.playList
  }
  if (updates.currentIndex !== undefined) {
    globalPlayerState.currentIndex = updates.currentIndex
  }
  if (updates.isPlaying !== undefined) {
    globalPlayerState.isPlaying = updates.isPlaying
  }
  if (updates.isLoading !== undefined) {
    globalPlayerState.isLoading = updates.isLoading
  }
  if (updates.playMode !== undefined) {
    globalPlayerState.playMode = updates.playMode
  }
  if (updates.currentTime !== undefined) {
    globalPlayerState.currentTime = updates.currentTime
  }
  if (updates.duration !== undefined) {
    globalPlayerState.duration = updates.duration
  }
  if (updates.volume !== undefined) {
    globalPlayerState.volume = updates.volume
  }

  console.info('[PlayerState] Updated:', JSON.stringify(updates))
}

/**
 * 重置播放器状态
 */
export function resetPlayerState(): void {
  globalPlayerState.currentSong = null
  globalPlayerState.playList = []
  globalPlayerState.currentIndex = 0
  globalPlayerState.isPlaying = false
  globalPlayerState.isLoading = false
  globalPlayerState.playMode = PlayMode.LOOP
  globalPlayerState.currentTime = 0
  globalPlayerState.duration = 0
  globalPlayerState.volume = 1.0

  console.info('[PlayerState] Reset')
}
