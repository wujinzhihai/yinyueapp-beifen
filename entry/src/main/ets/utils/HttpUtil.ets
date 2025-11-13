// entry/src/main/ets/utils/HttpUtil.ets

import http from '@ohos.net.http'

/**
 * HTTP 工具类
 * 封装网络请求，提供统一的错误处理
 */
export class HttpUtil {
  /**
   * 发送 GET 请求
   * @param url 请求地址
   * @param params 查询参数（可选）
   * @returns Promise<T> 返回指定类型的数据
   */
  static async get<T>(url: string, params?: Record<string, string | number>): Promise<T> {
    // 构建完整 URL
    let fullUrl = url  // ✅ 修正拼写错误
    if (params) {
      const queryString = Object.keys(params)
        .map((key: string): string => `${key}=${encodeURIComponent(String(params[key]))}`)
        .join('&')
      fullUrl = `${url}?${queryString}`  // ✅ 使用正确的变量名
    }

    // 创建 HTTP 请求对象
    const httpRequest = http.createHttp()

    try {
      console.info(`[HttpUtil] 请求: ${fullUrl}`)  // ✅ 使用正确的变量名

      // 发送请求
      const response = await httpRequest.request(fullUrl, {  // ✅ 使用正确的变量名
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 10000,
        connectTimeout: 10000
      })

      // 检查 HTTP 状态码
      if (response.responseCode !== 200) {
        throw new Error(`HTTP错误: ${response.responseCode}`)
      }

      // 解析响应数据
      const result = JSON.parse(response.result as string) as T

      console.info(`[HttpUtil] 响应成功`)

      return result

    } catch (err) {
      // 统一转换为 Error 类型
      const error = err instanceof Error ? err : new Error(String(err))
      console.error(`[HttpUtil] 请求失败: ${error.message}`)
      throw error
    } finally {
      // 销毁请求对象
      httpRequest.destroy()
    }
  }

  /**
   * 发送 POST 请求
   * @param url 请求地址
   * @param data 请求体数据
   * @returns Promise<T>
   */
  static async post<T>(url: string, data: object): Promise<T> {
    const httpRequest = http.createHttp()

    try {
      console.info(`[HttpUtil] POST请求: ${url}`)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(data),
        readTimeout: 10000,
        connectTimeout: 10000
      })

      if (response.responseCode !== 200) {
        throw new Error(`HTTP错误: ${response.responseCode}`)
      }

      const result = JSON.parse(response.result as string) as T

      console.info(`[HttpUtil] POST响应成功`)

      return result

    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err))
      console.error(`[HttpUtil] POST请求失败: ${error.message}`)
      throw error
    } finally {
      httpRequest.destroy()
    }
  }
}
