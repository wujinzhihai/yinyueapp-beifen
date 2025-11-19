# 🎵 后台播放功能说明

## 📋 功能概述

HarmonyOS音乐应用现已支持后台播放功能,包括:
- ✅ 应用切换到后台时继续播放音乐
- ✅ 通知栏显示音乐播放控制器
- ✅ 通知栏控制播放/暂停/上一曲/下一曲
- ✅ 锁屏界面显示音乐信息和控制
- ✅ 媒体会话(AVSession)支持

---

## 🔧 技术实现

### 1. 权限配置

已在 [`module.json5`](entry/src/main/module.json5:25) 中配置:

```json5
{
  "abilities": [
    {
      "name": "EntryAbility",
      "backgroundModes": [
        "audioPlayback"  // 音频播放后台模式
      ]
    }
  ],
  "requestPermissions": [
    {
      "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",
      "reason": "$string:keep_background_running_reason"
    }
  ]
}
```

### 2. AVSession媒体会话

在 [`AudioPlayerService.ets`](entry/src/main/ets/services/AudioPlayerService.ets:1) 中实现:

#### 初始化媒体会话
```typescript
private async initAVSession(): Promise<void> {
  // 创建媒体会话
  this.session = await avSession.createAVSession(
    globalThis.abilityContext,
    'MusicPlayer',
    'audio'
  );
  
  // 激活会话
  await this.session.activate();
  
  // 监听控制命令
  this.session.on('play', () => this.togglePlay());
  this.session.on('pause', () => this.togglePlay());
  this.session.on('playNext', () => this.next());
  this.session.on('playPrevious', () => this.previous());
}
```

#### 更新媒体信息
```typescript
private async updateAVMetadata(): Promise<void> {
  const metadata: avSession.AVMetadata = {
    assetId: this.state.currentSong.id,
    title: this.state.currentSong.name,
    artist: this.state.currentSong.artist,
    album: this.state.currentSong.album,
    duration: this.state.duration * 1000,
    mediaImage: coverUrl  // 封面图片
  };
  
  await this.session.setAVMetadata(metadata);
}
```

#### 更新播放状态
```typescript
private async updateAVPlaybackState(): Promise<void> {
  const playbackState: avSession.AVPlaybackState = {
    state: this.convertPlayState(this.state.playState),
    position: {
      elapsedTime: this.state.currentTime * 1000,
      updateTime: Date.now()
    },
    speed: this.state.playState === PlayState.PLAYING ? 1.0 : 0.0
  };
  
  await this.session.setAVPlaybackState(playbackState);
}
```

### 3. 全局上下文设置

在 [`EntryAbility.ets`](entry/src/main/ets/entryability/EntryAbility.ets:1) 中:

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  // 设置全局上下文,供AVSession使用
  globalThis.abilityContext = this.context;
}

onBackground(): void {
  // 后台播放:不暂停音乐,继续播放
  hilog.info(0x0000, 'testTag', 'App moved to background, music continues playing');
}
```

---

## 🎯 功能特性

### 1. 通知栏控制

当音乐播放时,通知栏会显示:
- 🎵 歌曲名称
- 👤 歌手名字
- 💿 专辑名称
- 🖼️ 专辑封面
- ⏮️ 上一曲按钮
- ⏯️ 播放/暂停按钮
- ⏭️ 下一曲按钮

### 2. 锁屏控制

锁屏界面显示:
- 🎵 当前播放歌曲信息
- 🖼️ 专辑封面
- ⏯️ 播放控制按钮
- ⏮️⏭️ 切歌按钮

### 3. 后台播放

- ✅ 应用切换到后台继续播放
- ✅ 锁屏状态继续播放
- ✅ 其他应用使用时继续播放
- ✅ 播放完成自动播放下一曲

---

## 📱 使用场景

### 场景1: 切换应用
```
1. 在音乐应用播放音乐
2. 按Home键返回桌面
3. 音乐继续播放
4. 通知栏显示播放控制
5. 可以在通知栏控制播放
```

### 场景2: 锁屏播放
```
1. 播放音乐
2. 按电源键锁屏
3. 音乐继续播放
4. 锁屏界面显示音乐信息
5. 可以在锁屏界面控制播放
```

### 场景3: 多任务切换
```
1. 播放音乐
2. 切换到其他应用(浏览器/微信等)
3. 音乐继续播放
4. 下拉通知栏可以控制播放
5. 点击通知可以返回音乐应用
```

---

## 🔍 调试信息

### 日志标签
- `[AVSession]` - 媒体会话相关日志
- `[AudioPlayer]` - 播放器相关日志

### 关键日志
```
[AVSession] 媒体会话创建成功
[AVSession] 媒体会话已激活
[AVSession] 元数据已更新
[AVSession] 播放状态已更新
[AVSession] 收到播放命令
[AVSession] 收到暂停命令
[AVSession] 收到下一曲命令
[AVSession] 收到上一曲命令
```

---

## ⚠️ 注意事项

### 1. 权限申请
- 应用首次运行时会请求后台运行权限
- 用户需要授予权限才能使用后台播放功能

### 2. 系统限制
- 后台播放受系统电池优化策略影响
- 低电量模式可能限制后台播放
- 系统可能在内存不足时终止后台播放

### 3. 网络音乐
- 后台播放网络音乐需要保持网络连接
- 建议在WiFi环境下使用
- 移动网络可能产生流量费用

### 4. 本地音乐
- 本地音乐后台播放不受网络影响
- 推荐使用本地音乐以获得最佳体验

---

## 🐛 故障排除

### 问题1: 后台播放自动停止
**原因**: 
- 系统电池优化
- 内存不足
- 权限未授予

**解决方案**:
1. 检查后台运行权限
2. 在系统设置中关闭电池优化
3. 清理后台应用释放内存

### 问题2: 通知栏不显示控制器
**原因**:
- AVSession未正确初始化
- 通知权限未授予

**解决方案**:
1. 检查日志确认AVSession初始化成功
2. 授予通知权限
3. 重启应用

### 问题3: 锁屏不显示音乐信息
**原因**:
- 媒体元数据未更新
- 系统锁屏设置

**解决方案**:
1. 确认播放时元数据已更新
2. 检查系统锁屏设置
3. 查看日志确认元数据更新成功

---

## 📊 性能优化

### 1. 内存管理
- 及时释放不用的资源
- 避免内存泄漏
- 合理使用缓存

### 2. 电量优化
- 减少不必要的网络请求
- 优化定时器使用
- 合理设置更新频率

### 3. 网络优化
- 使用缓存减少重复请求
- 预加载下一曲
- 断网自动切换本地音乐

---

## 🎉 功能亮点

### 1. 无缝体验
- ✅ 应用切换不中断播放
- ✅ 锁屏继续播放
- ✅ 通知栏快速控制

### 2. 智能控制
- ✅ 通知栏完整控制
- ✅ 锁屏界面控制
- ✅ 媒体按键支持

### 3. 稳定可靠
- ✅ 自动重试机制
- ✅ 错误自动恢复
- ✅ 资源自动释放

---

## 📚 相关文档

- [HarmonyOS AVSession开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/avsession-overview-0000001427902093)
- [后台任务管理](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/background-task-overview-0000001428061796)
- [音频播放开发](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/audio-playback-overview-0000001427902089)

---

## 🔄 更新日志

### v1.0.0 (2025-01-19)
- ✅ 添加AVSession媒体会话支持
- ✅ 实现通知栏音乐控制
- ✅ 支持后台播放功能
- ✅ 支持锁屏控制
- ✅ 优化播放稳定性

---

## 💡 使用建议

### 最佳实践
1. **WiFi环境**: 播放网络音乐时使用WiFi
2. **本地音乐**: 经常听的歌曲下载到本地
3. **权限管理**: 及时授予必要权限
4. **电池优化**: 关闭应用的电池优化限制

### 用户体验
1. **快速控制**: 使用通知栏快速控制播放
2. **锁屏播放**: 锁屏时也能控制音乐
3. **多任务**: 边听音乐边使用其他应用
4. **省电模式**: 使用本地音乐节省电量

---

## 🎵 享受音乐!

现在你可以:
- 🎧 随时随地听音乐
- 📱 多任务无缝切换
- 🔒 锁屏继续播放
- 🎛️ 通知栏快速控制

**让音乐陪伴你的每一刻!** 🎶