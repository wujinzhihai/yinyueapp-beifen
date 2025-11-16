/**
 * 防抖工具类
 * 用于限制函数执行频率,避免频繁触发
 */
export class Debounce {
  private static timers: Map<string, number> = new Map();

  /**
   * 执行防抖函数
   * @param key 唯一标识符
   * @param fn 要执行的函数
   * @param delay 延迟时间(毫秒),默认300ms
   */
  static execute(key: string, fn: Function, delay: number = 300): void {
    const timer = Debounce.timers.get(key);
    if (timer !== undefined) {
      clearTimeout(timer);
    }

    const newTimer = setTimeout(() => {
      fn();
      Debounce.timers.delete(key);
    }, delay);

    Debounce.timers.set(key, newTimer);
  }

  /**
   * 取消指定key的防抖
   * @param key 唯一标识符
   */
  static cancel(key: string): void {
    const timer = Debounce.timers.get(key);
    if (timer !== undefined) {
      clearTimeout(timer);
      Debounce.timers.delete(key);
    }
  }

  /**
   * 清除所有防抖定时器
   */
  static clearAll(): void {
    Debounce.timers.forEach((timer) => clearTimeout(timer));
    Debounce.timers.clear();
  }
}