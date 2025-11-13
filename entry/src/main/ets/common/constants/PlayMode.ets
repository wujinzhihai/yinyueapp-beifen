/** 
  * 播放模式枚举 
  * 定义音乐播放器支持的播放模式 
  */ 
export enum PlayMode { 
  /** 顺序播放 */ 
  SEQUENCE = 'sequence', 
  
  /** 列表循环 */ 
  LOOP = 'loop', 
  
  /** 单曲循环 */ 
  SINGLE_LOOP = 'single_loop', 
  
  /** 随机播放 */ 
  RANDOM = 'random' 
} 

/** 
  * 播放模式显示名称映射 
  */ 
export const PlayModeNames: Record<PlayMode, string> = { 
  [PlayMode.SEQUENCE]: '顺序播放', 
  [PlayMode.LOOP]: '列表循环', 
  [PlayMode.SINGLE_LOOP]: '单曲循环', 
  [PlayMode.RANDOM]: '随机播放' 
} 

/** 
  * 播放模式图标映射（使用系统图标名称） 
  */ 
export const PlayModeIcons: Record<PlayMode, string> = { 
  [PlayMode.SEQUENCE]: 'ic_public_sequence', 
  [PlayMode.LOOP]: 'ic_public_loop', 
  [PlayMode.SINGLE_LOOP]: 'ic_public_single_loop', 
  [PlayMode.RANDOM]: 'ic_public_random' 
}