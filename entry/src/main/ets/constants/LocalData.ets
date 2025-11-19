/**
 * 本地推荐数据配置
 */

// 本地歌曲数据接口
export interface LocalSongItem {
  name: string;
  artist: string;
  album: string;
  duration: number; // 秒
}

// 推荐歌单接口
export interface PlaylistItem {
  id: string;
  name: string;
  cover: string;
  description: string;
  keywords: string[];
  songs: LocalSongItem[]; // 本地歌曲列表
}

// 5个精选推荐歌单 - 使用本地数据
export const LOCAL_PLAYLISTS: PlaylistItem[] = [
  {
    id: 'hot-chinese',
    name: '🔥 热门华语',
    cover: 'pexels_michael_morse',
    description: '最受欢迎的华语金曲',
    keywords: ['周杰伦', '林俊杰', '邓紫棋', '薛之谦'],
    songs: [
      { name: '晴天', artist: '周杰伦', album: '叶惠美', duration: 269 },
      { name: '七里香', artist: '周杰伦', album: '七里香', duration: 300 },
      { name: '稻香', artist: '周杰伦', album: '魔杰座', duration: 223 },
      { name: '江南', artist: '林俊杰', album: '江南', duration: 260 },
      { name: '曹操', artist: '林俊杰', album: '曹操', duration: 245 },
      { name: '修炼爱情', artist: '林俊杰', album: '因你而在', duration: 267 },
      { name: '泡沫', artist: '邓紫棋', album: 'Xposed', duration: 243 },
      { name: '光年之外', artist: '邓紫棋', album: '光年之外', duration: 245 },
      { name: '演员', artist: '薛之谦', album: '绅士', duration: 263 },
      { name: '丑八怪', artist: '薛之谦', album: '意外', duration: 280 }
    ]
  },
  {
    id: 'classic-old',
    name: '🎸 经典老歌',
    cover: 'pexels_pavel_danilyuk',
    description: '经典永不过时',
    keywords: ['Beyond', '张学友', '邓丽君', '齐秦'],
    songs: [
      { name: '海阔天空', artist: 'Beyond', album: '乐与怒', duration: 326 },
      { name: '光辉岁月', artist: 'Beyond', album: '命运派对', duration: 310 },
      { name: '真的爱你', artist: 'Beyond', album: 'Beyond IV', duration: 267 },
      { name: '吻别', artist: '张学友', album: '吻别', duration: 298 },
      { name: '一路上有你', artist: '张学友', album: '真爱', duration: 267 },
      { name: '月亮代表我的心', artist: '邓丽君', album: '岛国之情歌第六集', duration: 156 },
      { name: '甜蜜蜜', artist: '邓丽君', album: '甜蜜蜜', duration: 189 },
      { name: '大约在冬季', artist: '齐秦', album: '冬雨', duration: 267 },
      { name: '外面的世界', artist: '齐秦', album: '狼的专辑', duration: 289 }
    ]
  },
  {
    id: 'western-pop',
    name: '🌍 欧美金曲',
    cover: 'pexels_yankrukov',
    description: '欧美流行经典',
    keywords: ['Taylor Swift', 'Ed Sheeran', 'Adele'],
    songs: [
      { name: 'Shake It Off', artist: 'Taylor Swift', album: '1989', duration: 219 },
      { name: 'Love Story', artist: 'Taylor Swift', album: 'Fearless', duration: 235 },
      { name: 'Blank Space', artist: 'Taylor Swift', album: '1989', duration: 231 },
      { name: 'Shape of You', artist: 'Ed Sheeran', album: '÷', duration: 233 },
      { name: 'Perfect', artist: 'Ed Sheeran', album: '÷', duration: 263 },
      { name: 'Thinking Out Loud', artist: 'Ed Sheeran', album: 'x', duration: 281 },
      { name: 'Hello', artist: 'Adele', album: '25', duration: 295 },
      { name: 'Someone Like You', artist: 'Adele', album: '21', duration: 285 },
      { name: 'Rolling in the Deep', artist: 'Adele', album: '21', duration: 228 }
    ]
  },
  {
    id: 'light-music',
    name: '🎹 轻音纯音',
    cover: 'pexels_artempodrez',
    description: '放松心情的纯音乐',
    keywords: ['轻音乐', '钢琴曲', '纯音乐', '班得瑞'],
    songs: [
      { name: '雨的印记', artist: 'Yiruma', album: 'First Love', duration: 240 },
      { name: 'River Flows in You', artist: 'Yiruma', album: 'First Love', duration: 210 },
      { name: '天空之城', artist: '久石让', album: '天空之城', duration: 256 },
      { name: '菊次郎的夏天', artist: '久石让', album: '菊次郎的夏天', duration: 234 },
      { name: '初雪', artist: '班得瑞', album: '春野', duration: 198 },
      { name: '安妮的仙境', artist: '班得瑞', album: '仙境', duration: 212 },
      { name: '梦中的婚礼', artist: 'Richard Clayderman', album: '水边的阿狄丽娜', duration: 167 },
      { name: 'Canon in D', artist: 'Pachelbel', album: 'Classical Music', duration: 300 }
    ]
  },
  {
    id: 'cantonese',
    name: '🎤 粤语精选',
    cover: 'pexels_budgeron_bach',
    description: '经典粤语歌曲',
    keywords: ['陈奕迅', '容祖儿', '张国荣', '陈慧娴'],
    songs: [
      { name: '十年', artist: '陈奕迅', album: 'Black White Grey', duration: 225 },
      { name: '富士山下', artist: '陈奕迅', album: 'What\'s Going On...?', duration: 309 },
      { name: '浮夸', artist: '陈奕迅', album: 'U87', duration: 320 },
      { name: '挥着翅膀的女孩', artist: '容祖儿', album: '挥着翅膀的女孩', duration: 245 },
      { name: '我的骄傲', artist: '容祖儿', album: '我的骄傲', duration: 267 },
      { name: '沉默是金', artist: '张国荣', album: '沉默是金', duration: 189 },
      { name: '风继续吹', artist: '张国荣', album: '风继续吹', duration: 234 },
      { name: '千千阙歌', artist: '陈慧娴', album: '永远是你的朋友', duration: 267 },
      { name: '飘雪', artist: '陈慧娴', album: '归来吧', duration: 245 }
    ]
  }
];
