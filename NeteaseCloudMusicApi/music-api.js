const express = require('express');
const axios = require('axios');
const CryptoJS = require('crypto-js');

const app = express();
const PORT = 3000;

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.use(express.json());
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

function encrypt(text) {
  const key = CryptoJS.enc.Utf8.parse('0CoJUm6Qyw8W8jud');
  const iv = CryptoJS.enc.Utf8.parse('0102030405060708');
  return CryptoJS.AES.encrypt(text, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  }).toString();
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: '网易云音乐API服务运行中', timestamp: new Date().toISOString() });
});

app.get('/song/url/v1', async (req, res) => {
  try {
    const { id, level = 'standard' } = req.query;
    if (!id) return res.status(400).json({ code: 400, message: '缺少歌曲ID' });
    console.log(`[歌曲URL] ID: ${id}`);
    const params = { ids: `[${id}]`, level: level, encodeType: 'flac' };
    const response = await axios.post('https://music.163.com/weapi/song/enhance/player/url/v1',
      new URLSearchParams({ params: encrypt(JSON.stringify(params)), encSecKey: '' }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Mozilla/5.0', 'Referer': 'https://music.163.com' } }
    );
    console.log(`[成功] 获取歌曲URL`);
    res.json(response.data);
  } catch (error) {
    console.error('[错误]', error.message);
    res.status(500).json({ code: 500, message: '服务器错误', error: error.message });
  }
});

app.get('/search', async (req, res) => {
  try {
    const { keywords, limit = 30, offset = 0 } = req.query;
    if (!keywords) return res.status(400).json({ code: 400, message: '缺少关键词' });
    console.log(`[搜索] ${keywords}`);
    const params = { s: keywords, type: 1, limit, offset };
    const response = await axios.post('https://music.163.com/weapi/search/get',
      new URLSearchParams({ params: encrypt(JSON.stringify(params)), encSecKey: '' }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Mozilla/5.0', 'Referer': 'https://music.163.com' } }
    );
    console.log(`[成功] 找到 ${response.data.result?.songs?.length || 0} 首`);
    console.log('[搜索响应]', JSON.stringify(response.data).substring(0, 500));
    res.json(response.data);
  } catch (error) {
    console.error('[错误]', error.message);
    res.status(500).json({ code: 500, message: '搜索失败', error: error.message });
  }
});

app.get('/lyric', async (req, res) => {
  try {
    const { id } = req.query;
    if (!id) return res.status(400).json({ code: 400, message: '缺少ID' });
    console.log(`[歌词] ${id}`);
    const params = { id, lv: -1, tv: -1 };
    const response = await axios.post('https://music.163.com/weapi/song/lyric',
      new URLSearchParams({ params: encrypt(JSON.stringify(params)), encSecKey: '' }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Mozilla/5.0', 'Referer': 'https://music.163.com' } }
    );
    console.log(`[成功] 获取歌词`);
    res.json(response.data);
  } catch (error) {
    console.error('[错误]', error.message);
    res.status(500).json({ code: 500, message: '获取歌词失败', error: error.message });
  }
});

app.get('/top/playlist', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    console.log(`[热门歌单]`);
    const params = { cat: '全部', order: 'hot', limit, offset, total: true };
    const response = await axios.post('https://music.163.com/weapi/playlist/list',
      new URLSearchParams({ params: encrypt(JSON.stringify(params)), encSecKey: '' }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Mozilla/5.0', 'Referer': 'https://music.163.com' } }
    );
    console.log(`[成功] ${response.data.playlists?.length || 0} 个歌单`);
    res.json(response.data);
  } catch (error) {
    console.error('[错误]', error.message);
    res.status(500).json({ code: 500, message: '获取歌单失败', error: error.message });
  }
});

app.get('/recommend/songs', (req, res) => {
  console.log(`[推荐歌曲]`);
  res.json({ code: 200, data: { dailySongs: [
    { id: 347230, name: '海阔天空', ar: [{ name: 'Beyond' }] },
    { id: 186016, name: '光辉岁月', ar: [{ name: 'Beyond' }] }
  ]}});
});

app.use((req, res) => {
  res.status(404).json({ code: 404, message: `未找到: ${req.url}` });
});

app.listen(PORT, () => {
  console.log('\n' + '='.repeat(60));
  console.log('✅  网易云音乐API服务已启动！');
  console.log('='.repeat(60));
  console.log(`🌐  http://localhost:${PORT}`);
  console.log(`💚  /health /search?keywords=xxx /song/url/v1?id=xxx`);
  console.log('='.repeat(60) + '\n');
});

