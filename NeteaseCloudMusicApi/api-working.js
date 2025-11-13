const express = require('express');
const app = express();
const PORT = 3000;

// CORS配置
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 歌曲URL - 外链模式
app.get('/song/url/v1', (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ code: 400, msg: '缺少ID' });
  
  console.log(`[歌曲URL] ID: ${id}`);
  res.json({
    code: 200,
    data: [{
      id: parseInt(id),
      url: `https://music.163.com/song/media/outer/url?id=${id}.mp3`,
      br: 320000,
      type: 'mp3'
    }]
  });
});

// 搜索功能
app.get('/search', (req, res) => {
  const { keywords = '' } = req.query;
  console.log(`[搜索] ${keywords}`);
  
  const songs = [
    // 周杰伦
    { id: 287355, name: '夜曲', artists: [{ name: '周杰伦' }], album: { name: '十一月的萧邦', picUrl: 'https://p1.music.126.net/yGsp6FvvAb65JmGWhLjq7Q==/109951166570134708.jpg' }},
    { id: 25906124, name: '告白气球', artists: [{ name: '周杰伦' }], album: { name: '周杰伦的床边故事', picUrl: 'https://p1.music.126.net/6y-UleORITEDbvrOLV0Q8A==/2946691234868155.jpg' }},
    { id: 186451, name: '晴天', artists: [{ name: '周杰伦' }], album: { name: '叶惠美', picUrl: 'https://p1.music.126.net/Md3RLH0fe2a_3dMDnfqoQg==/18590542604286213.jpg' }},
    { id: 186007, name: '稻香', artists: [{ name: '周杰伦' }], album: { name: '魔杰座', picUrl: 'https://p1.music.126.net/7R7YQ01wkwEJT2MJCJZvIA==/109951169289116527.jpg' }},
    { id: 186017, name: '简单爱', artists: [{ name: '周杰伦' }], album: { name: '范特西', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    // Beyond
    { id: 347230, name: '海阔天空', artists: [{ name: 'Beyond' }], album: { name: '海阔天空', picUrl: 'https://p1.music.126.net/ooMt0KEB0X-6bPPtdWBdIg==/109951168143912450.jpg' }},
    { id: 186016, name: '光辉岁月', artists: [{ name: 'Beyond' }], album: { name: '命运派对', picUrl: 'https://p1.music.126.net/9p7VVhlLEqhh6VQbLMRK9A==/19144735486692390.jpg' }},
    { id: 346576, name: '真的爱你', artists: [{ name: 'Beyond' }], album: { name: 'Beyond IV', picUrl: 'https://p1.music.126.net/xYRwVZEqsLfKSmhAsZKSTw==/109951169289212861.jpg' }},
    { id: 346572, name: '喜欢你', artists: [{ name: 'Beyond' }], album: { name: '秘密警察', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    // 林俊杰
    { id: 185668, name: '江南', artists: [{ name: '林俊杰' }], album: { name: '第二天堂', picUrl: 'https://p1.music.126.net/Md3RLH0fe2a_3dMDnfqoQg==/18590542604286213.jpg' }},
    { id: 185809, name: '曹操', artists: [{ name: '林俊杰' }], album: { name: '曹操', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    { id: 185857, name: '美人鱼', artists: [{ name: '林俊杰' }], album: { name: '编号89757', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    // 陈奕迅
    { id: 25906140, name: '十年', artists: [{ name: '陈奕迅' }], album: { name: 'Black White Grey', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    { id: 254571, name: '浮夸', artists: [{ name: '陈奕迅' }], album: { name: 'U-87', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }},
    { id: 65538, name: '爱情转移', artists: [{ name: '陈奕迅' }], album: { name: '认了吧', picUrl: 'https://p1.music.126.net/imgurl=000.jpg' }}
  ];
  
  const result = keywords ? songs.filter(s => 
    s.name.includes(keywords) || s.artists[0].name.includes(keywords)
  ) : songs.slice(0, 10);
  
  console.log(`[成功] 找到 ${result.length} 首`);
  res.json({
    result: { songs: result, songCount: result.length }
  });
});

// 歌词
app.get('/lyric', (req, res) => {
  const { id } = req.query;
  console.log(`[歌词] ID: ${id}`);
  
  const lyrics = {
    '347230': '[00:00.00] 海阔天空 - Beyond\n[00:20.00] 今天我 寒夜里看雪飘过\n[00:27.00] 怀着冷却了的心窝飘远方\n[00:34.00] 风雨里追赶 雾里分不清影踪\n[00:41.00] 天空海阔你与我 可会变\n',
    '287355': '[00:00.00] 夜曲 - 周杰伦\n[00:15.00] 一群嗜血的蚂蚁 被腐肉所吸引\n[00:22.00] 我面无表情 看孤独的风景\n[00:29.00] 失去你 爱恨开始分明\n',
    '186451': '[00:00.00] 晴天 - 周杰伦\n[00:10.00] 故事的小黄花 从出生那年就飘着\n[00:17.00] 童年的荡秋千 随记忆一直晃到现在\n',
    '25906124': '[00:00.00] 告白气球 - 周杰伦\n[00:08.00] 塞纳河畔 左岸的咖啡\n[00:12.00] 我手一杯 品尝你的美\n'
  };
  
  console.log(`[成功] 获取歌词`);
  res.json({
    lrc: { lyric: lyrics[id] || '[00:00.00] 暂无歌词\n' },
    klyric: { lyric: '' }
  });
});

// 热门歌单
app.get('/top/playlist', (req, res) => {
  console.log(`[热门歌单]`);
  const playlists = [
    { id: 1, name: '华语流行Top100', playCount: 10000000, coverImgUrl: 'https://p1.music.126.net/example1.jpg', creator: { nickname: '网易云音乐' }},
    { id: 2, name: '欧美热歌榜', playCount: 8000000, coverImgUrl: 'https://p2.music.126.net/example2.jpg', creator: { nickname: '音乐精选' }},
    { id: 3, name: '粤语经典', playCount: 5000000, coverImgUrl: 'https://p3.music.126.net/example3.jpg', creator: { nickname: '怀旧金曲' }}
  ];
  console.log(`[成功] ${playlists.length} 个歌单`);
  res.json({ playlists });
});

// 推荐歌曲
app.get('/recommend/songs', (req, res) => {
  console.log(`[推荐歌曲]`);
  res.json({ 
    code: 200, 
    data: { dailySongs: [
      { id: 347230, name: '海阔天空', ar: [{ name: 'Beyond' }], al: { picUrl: 'https://p1.music.126.net/ooMt0KEB0X-6bPPtdWBdIg==/109951168143912450.jpg' }},
      { id: 186016, name: '光辉岁月', ar: [{ name: 'Beyond' }], al: { picUrl: 'https://p1.music.126.net/9p7VVhlLEqhh6VQbLMRK9A==/19144735486692390.jpg' }},
      { id: 287355, name: '夜曲', ar: [{ name: '周杰伦' }], al: { picUrl: 'https://p1.music.126.net/yGsp6FvvAb65JmGWhLjq7Q==/109951166570134708.jpg' }}
    ]}
  });
});

app.listen(PORT, () => {
  console.log('\n' + '='.repeat(70));
  console.log('🎉 网易云音乐API服务启动成功！');
  console.log('='.repeat(70));
  console.log(`🌐 服务地址：http://localhost:${PORT}`);
  console.log(`🎵 音乐播放：外链模式 (完全可用)`);
  console.log(`🔍 搜索功能：15首热门歌曲 (周杰伦/Beyond/林俊杰/陈奕迅)`);
  console.log(`📝 歌词支持：部分歌曲`);
  console.log(`📋 歌单列表：3个热门歌单`);
  console.log('='.repeat(70));
  console.log('\n💡 测试接口：');
  console.log(`   http://localhost:${PORT}/search?keywords=周杰伦`);
  console.log(`   http://localhost:${PORT}/song/url/v1?id=347230`);
  console.log(`   http://localhost:${PORT}/lyric?id=347230`);
  console.log('='.repeat(70) + '\n');
});
