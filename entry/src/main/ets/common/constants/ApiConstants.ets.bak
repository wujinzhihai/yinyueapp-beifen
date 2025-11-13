import { Song } from '../../models/Song';

/**
 * Mock歌曲数据（用于开发测试）
 */
export const MOCK_SONGS: Song[] = [
  createSong(1, '晴天', '周杰伦', '叶惠美', 269000,
    'https://p2.music.126.net/MJI34QXRrfZmVJQjoAP4Ag==/109951168991992347.jpg',
    'https://music.163.com/song/media/outer/url?id=186016.mp3'),

  createSong(2, '七里香', '周杰伦', '七里香', 301000,
    'https://p1.music.126.net/P1ciTHY_zDMEAvRVW0bcCw==/109951168989615171.jpg',
    'https://music.163.com/song/media/outer/url?id=186017.mp3'),

  createSong(3, '稻香', '周杰伦', '魔杰座', 223000,
    'https://p1.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg',
    'https://music.163.com/song/media/outer/url?id=186015.mp3'),

  createSong(4, '夜曲', '周杰伦', '十一月的萧邦', 236000,
    'https://p2.music.126.net/XRglfi6bloLXPeZ4dMI_6Q==/109951165706196977.jpg',
    'https://music.163.com/song/media/outer/url?id=186014.mp3'),

  createSong(5, '简单爱', '周杰伦', '范特西', 270000,
    'https://p2.music.126.net/UeTuwE7pvjBpypWLudqukA==/3440371884651770.jpg',
    'https://music.163.com/song/media/outer/url?id=186013.mp3')
];

/**
 * 创建歌曲对象的辅助函数
 */
function createSong(
  id: number,
  name: string,
  artist: string,
  album: string,
  duration: number,
  coverUrl: string,
  playUrl: string
): Song {
  const song = new Song();
  song.id = id;
  song.name = name;
  song.artist = artist;
  song.album = album;
  song.duration = duration;
  song.coverUrl = coverUrl;
  song.playUrl = playUrl;
  return song;
}
