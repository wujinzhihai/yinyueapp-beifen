import { MusicItem } from '../services/MusicApiService';
import { PlayState } from '../services/AudioPlayerService';

// 全局播放器状态（使用AppStorage）
export class PlayerStore {
  static initStorage() {
    AppStorage.SetOrCreate('currentSong', null as MusicItem | null);
    AppStorage.SetOrCreate('playState', PlayState.IDLE as PlayState);
    AppStorage.SetOrCreate('currentTime', 0);
    AppStorage.SetOrCreate('duration', 0);
    AppStorage.SetOrCreate('playlist', [] as MusicItem[]);
    AppStorage.SetOrCreate('currentIndex', -1);
  }

  static setCurrentSong(song: MusicItem | null) {
    AppStorage.Set('currentSong', song);
  }

  static setPlayState(state: PlayState) {
    AppStorage.Set('playState', state);
  }

  static setCurrentTime(time: number) {
    AppStorage.Set('currentTime', time);
  }

  static setDuration(duration: number) {
    AppStorage.Set('duration', duration);
  }

  static setPlaylist(playlist: MusicItem[]) {
    AppStorage.Set('playlist', playlist);
  }

  static setCurrentIndex(index: number) {
    AppStorage.Set('currentIndex', index);
  }
}
