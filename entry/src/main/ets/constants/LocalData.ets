/**
 * 本地推荐数据配置
 */

// 推荐歌单接口
export interface PlaylistItem {
  id: string;
  name: string;
  cover: string;
  description: string;
  keywords: string[];
}

// 5个精选推荐歌单 - 使用本地图片
export const LOCAL_PLAYLISTS: PlaylistItem[] = [
  {
    id: 'hot-chinese',
    name: '🔥 热门华语',
    cover: 'pexels_michael_morse',
    description: '最受欢迎的华语金曲',
    keywords: ['周杰伦', '林俊杰', '邓紫棋', '薛之谦']
  },
  {
    id: 'classic-old',
    name: '🎸 经典老歌',
    cover: 'pexels_pavel_danilyuk',
    description: '经典永不过时',
    keywords: ['Beyond', '张学友', '邓丽君', '齐秦']
  },
  {
    id: 'western-pop',
    name: '🌍 欧美金曲',
    cover: 'pexels_yankrukov',
    description: '欧美流行经典',
    keywords: ['Taylor Swift', 'Ed Sheeran', 'Adele']
  },
  {
    id: 'light-music',
    name: '🎹 轻音纯音',
    cover: 'pexels_artempodrez',
    description: '放松心情的纯音乐',
    keywords: ['轻音乐', '钢琴曲', '纯音乐', '班得瑞']
  },
  {
    id: 'cantonese',
    name: '🎤 粤语精选',
    cover: 'pexels_budgeron_bach',
    description: '经典粤语歌曲',
    keywords: ['陈奕迅', '容祖儿', '张国荣', '陈慧娴']
  }
];
