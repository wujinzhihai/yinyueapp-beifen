import promptAction from '@ohos.promptAction';

/**
 * 错误码枚举
 */
export enum ErrorCode {
  // 网络相关错误 1xxx
  NETWORK_ERROR = 1001,
  NETWORK_TIMEOUT = 1002,
  API_ERROR = 1003,
  
  // 音频相关错误 2xxx
  AUDIO_LOAD_FAILED = 2001,
  AUDIO_PLAY_FAILED = 2002,
  AUDIO_SEEK_FAILED = 2003,
  
  // 数据相关错误 3xxx
  INVALID_PARAMS = 3001,
  DATA_PARSE_ERROR = 3002,
  CACHE_ERROR = 3003,
  
  // 其他错误 9xxx
  UNKNOWN_ERROR = 9999
}

/**
 * 应用错误类
 */
export class AppError extends Error {
  code: ErrorCode;
  context?: Record<string, Object>;

  constructor(
    code: ErrorCode,
    message: string,
    context?: Record<string, Object>
  ) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.context = context;
  }
}

/**
 * 统一错误处理器
 */
export class ErrorHandler {
  private static readonly TAG: string = 'ErrorHandler';
  
  /**
   * 处理错误
   * @param error 错误对象
   * @param showToast 是否显示Toast提示,默认true
   */
  static handle(error: Error | AppError, showToast: boolean = true): void {
    let errorCode: ErrorCode;
    let errorMessage: string;
    let context: Record<string, Object> | undefined;
    
    if (error instanceof AppError) {
      errorCode = error.code;
      errorMessage = error.message;
      context = error.context;
    } else {
      errorCode = ErrorCode.UNKNOWN_ERROR;
      errorMessage = error.message;
    }
    
    // 记录错误日志
    ErrorHandler.logError(errorCode, errorMessage, context);
    
    // 显示用户友好提示
    if (showToast) {
      const userMessage = ErrorHandler.getUserMessage(errorCode);
      promptAction.showToast({ 
        message: userMessage,
        duration: 2000
      });
    }
  }
  
  /**
   * 记录错误日志
   */
  private static logError(
    code: ErrorCode, 
    message: string, 
    context?: Record<string, Object>
  ): void {
    const logMessage = `[${ErrorHandler.TAG}] Error ${code}: ${message}`;
    if (context) {
      console.error(logMessage, JSON.stringify(context));
    } else {
      console.error(logMessage);
    }
  }
  
  /**
   * 获取用户友好的错误提示
   */
  private static getUserMessage(code: ErrorCode): string {
    // 使用switch语句替代对象字面量
    switch (code) {
      // 网络错误
      case ErrorCode.NETWORK_ERROR:
        return '网络连接失败,请检查网络设置';
      case ErrorCode.NETWORK_TIMEOUT:
        return '网络请求超时,请稍后重试';
      case ErrorCode.API_ERROR:
        return 'API请求失败,请稍后重试';
      
      // 音频错误
      case ErrorCode.AUDIO_LOAD_FAILED:
        return '音频加载失败,请稍后重试';
      case ErrorCode.AUDIO_PLAY_FAILED:
        return '播放失败,请重新尝试';
      case ErrorCode.AUDIO_SEEK_FAILED:
        return '跳转失败,请重新尝试';
      
      // 数据错误
      case ErrorCode.INVALID_PARAMS:
        return '参数错误,请重新操作';
      case ErrorCode.DATA_PARSE_ERROR:
        return '数据解析失败';
      case ErrorCode.CACHE_ERROR:
        return '缓存操作失败';
      
      // 未知错误
      case ErrorCode.UNKNOWN_ERROR:
      default:
        return '操作失败,请重试';
    }
  }
  
  /**
   * 创建网络错误
   */
  static createNetworkError(message: string, context?: Record<string, Object>): AppError {
    return new AppError(ErrorCode.NETWORK_ERROR, message, context);
  }
  
  /**
   * 创建音频错误
   */
  static createAudioError(message: string, context?: Record<string, Object>): AppError {
    return new AppError(ErrorCode.AUDIO_LOAD_FAILED, message, context);
  }
  
  /**
   * 创建数据错误
   */
  static createDataError(message: string, context?: Record<string, Object>): AppError {
    return new AppError(ErrorCode.DATA_PARSE_ERROR, message, context);
  }
}