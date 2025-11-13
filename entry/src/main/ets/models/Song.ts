// entry/src/main/ets/models/Song.ets

/**
 * 歌曲数据接口
 */
export interface ISong {
  id: number
  name: string
  artist: string
  album: string
  duration: number
  audioUrl: string
  coverUrl: string
}

/**
 * 歌曲数据模型
 */
export class Song implements ISong {
  id: number
  name: string
  artist: string
  album: string
  duration: number
  audioUrl: string
  coverUrl: string

  constructor(
    id: number,
    name: string,
    artist: string,
    album: string,
    duration: number,
    audioUrl: string,
    coverUrl: string
  ) {
    this.id = id
    this.name = name
    this.artist = artist
    this.album = album
    this.duration = duration
    this.audioUrl = audioUrl
    this.coverUrl = coverUrl
  }

  /**
   * 从API响应创建Song对象
   */
  static fromJson(json: Record<string, Object>): Song {
    return new Song(
      json['id'] as number,
      json['name'] as string,
      json['artist'] as string,
      json['album'] as string,
      json['duration'] as number,
      json['audioUrl'] as string,
      json['coverUrl'] as string
    )
  }

  /**
   * 格式化时长为 mm:ss
   */
  getFormattedDuration(): string {
    const minutes = Math.floor(this.duration / 60)
    const seconds = this.duration % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 转为 JSON 对象
   */
  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'artist': this.artist,
      'album': this.album,
      'duration': this.duration,
      'audioUrl': this.audioUrl,
      'coverUrl': this.coverUrl
    }
  }
}
