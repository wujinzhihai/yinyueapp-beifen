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

// 5个精选推荐歌单
export const LOCAL_PLAYLISTS: PlaylistItem[] = [
  {
    id: 'hot-chinese',
    name: '🔥 热门华语',
    cover: 'https://p1.music.126.net/w2x5RbYlNPkVY1QWZJ7KxQ==/109951168514985584.jpg',
    description: '最受欢迎的华语金曲',
    keywords: ['周杰伦', '林俊杰', '邓紫棋', '薛之谦']
  },
  {
    id: 'classic-old',
    name: '🎸 经典老歌',
    cover: 'https://p1.music.126.net/3FfO6wEk3NjSlZjpYT7UhA==/109951168143498187.jpg',
    description: '经典永不过时',
    keywords: ['Beyond', '张学友', '邓丽君', '齐秦']
  },
  {
    id: 'western-pop',
    name: '🌍 欧美金曲',
    cover: 'https://p1.music.126.net/0aVjMHbCTGq5g8N7oJ8aEg==/109951168480037069.jpg',
    description: '欧美流行经典',
    keywords: ['Taylor Swift', 'Ed Sheeran', 'Adele']
  },
  {
    id: 'light-music',
    name: '🎹 轻音纯音',
    cover: 'https://p1.music.126.net/ya9I4ex96CECmiYLiEVfCQ==/109951165474966569.jpg',
    description: '放松心情的纯音乐',
    keywords: ['轻音乐', '钢琴曲', '纯音乐', '班得瑞']
  },
  {
    id: 'cantonese',
    name: '🎤 粤语精选',
    cover: 'https://p1.music.126.net/ZJ6wIu6Op-xIwJqPaNCR4A==/109951163245296915.jpg',
    description: '经典粤语歌曲',
    keywords: ['陈奕迅', '容祖儿', '张国荣', '陈慧娴']
  }
];
