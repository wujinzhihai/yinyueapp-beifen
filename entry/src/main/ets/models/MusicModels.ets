/**
 * 音乐项目接口
 */
export interface MusicItem {
  id: string;
  name: string;
  artist: string;
  album?: string;
  cover?: string;
  duration?: number;
  source: string;
  picId?: string;
  lyricId?: string;
}

export interface ISong {
  id: string;
  name: string;
  artist: string;
  album?: string;
  cover?: string;
  duration?: number;
  source: string;
}

export type Song = MusicItem;

export enum PlayState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  ERROR = 'error'
}

export enum PlayMode {
  SINGLE = 'single',
  LOOP = 'loop',
  RANDOM = 'random'
}

// 歌词数据接口
export interface LyricData {
  lyric: string;
  tlyric: string;
}
