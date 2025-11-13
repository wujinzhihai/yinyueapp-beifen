// 歌词行接口
export interface LyricLine {
  time: number;
  text: string;
}

// 歌词解析工具类
export class LyricParser {
  /**
   * 解析LRC格式歌词
   */
  static parse(lrcText: string): LyricLine[] {
    if (!lrcText) return [];

    const lines = lrcText.split('\n');
    const lyrics: LyricLine[] = [];

    lines.forEach(line => {
      // 匹配时间标签 [00:00.00] 或 [00:00.000]
      const match = line.match(/\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/);

      if (match) {
        const minutes = parseInt(match[1]);
        const seconds = parseInt(match[2]);
        const milliseconds = parseInt(match[3].padEnd(3, '0'));
        const text = match[4].trim();

        if (text) {
          const time = minutes * 60 + seconds + milliseconds / 1000;
          lyrics.push({ time, text });
        }
      }
    });

    // 按时间排序
    lyrics.sort((a, b) => a.time - b.time);
    return lyrics;
  }

  /**
   * 获取当前时间对应的歌词索引
   */
  static getCurrentIndex(lyrics: LyricLine[], currentTime: number): number {
    let activeIndex = -1;

    for (let i = 0; i < lyrics.length; i++) {
      if (lyrics[i].time <= currentTime) {
        activeIndex = i;
      } else {
        break;
      }
    }

    return activeIndex;
  }
}
