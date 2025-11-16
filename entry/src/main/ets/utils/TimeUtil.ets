/**
 * 时间格式化工具类
 */
export class TimeUtil {
  /**
   * 格式化时间为 mm:ss
   * @param seconds 秒数
   * @returns 格式化后的时间字符串
   */
  static formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * 格式化时间为 hh:mm:ss
   * @param seconds 秒数
   * @returns 格式化后的时间字符串
   */
  static formatLongTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * 解析时间字符串为秒数
   * @param timeStr 时间字符串 (mm:ss 或 hh:mm:ss)
   * @returns 秒数
   */
  static parseTime(timeStr: string): number {
    const parts = timeStr.split(':').map(p => parseInt(p));
    if (parts.length === 2) {
      return parts[0] * 60 + parts[1];
    } else if (parts.length === 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    }
    return 0;
  }
}