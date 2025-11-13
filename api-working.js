const http = require('http');
const url = require('url');

// 本地歌曲数据库（15首测试歌曲）
const localSongs = [
  {
    id: 347230,
    name: "海阔天空",
    artists: [{ id: 11127, name: "Beyond" }],
    album: { 
      id: 34209, 
      name: "海阔天空", 
      picUrl: "http://p1.music.126.net/QHw-RuMCSF7Fdx2Ynfhniw==/1404721928072135.jpg" 
    },
    duration: 326000
  },
  {
    id: 347351,
    name: "光辉岁月",
    artists: [{ id: 11127, name: "Beyond" }],
    album: { 
      id: 34222, 
      name: "乐与怒", 
      picUrl: "http://p1.music.126.net/0EM6-SPfdxIJZDFMr1Wx6g==/19217926441269784.jpg" 
    },
    duration: 309000
  },
  {
    id: 346576,
    name: "真的爱你",
    artists: [{ id: 11127, name: "Beyond" }],
    album: { 
      id: 34209, 
      name: "Beyond IV", 
      picUrl: "http://p1.music.126.net/pCkMx9x5Pa9qYcxlU0jYBg==/109951163973587390.jpg" 
    },
    duration: 267000
  },
  {
    id: 186016,
    name: "七里香",
    artists: [{ id: 6452, name: "周杰伦" }],
    album: { 
      id: 18903, 
      name: "七里香", 
      picUrl: "http://p1.music.126.net/k72rOrjgkGFHAU4DKoZ7cg==/109951165611418670.jpg" 
    },
    duration: 300000
  },
  {
    id: 186054,
    name: "稻香",
    artists: [{ id: 6452, name: "周杰伦" }],
    album: { 
      id: 18905, 
      name: "魔杰座", 
      picUrl: "http://p1.music.126.net/wJ-Og1vKcw09cY7rE96kUQ==/109951165611395772.jpg" 
    },
    duration: 223000
  },
  {
    id: 186017,
    name: "晴天",
    artists: [{ id: 6452, name: "周杰伦" }],
    album: { 
      id: 18902, 
      name: "叶惠美", 
      picUrl: "http://p1.music.126.net/7M1ZKqONcwAGoAAXrAH93Q==/109951165611416510.jpg" 
    },
    duration: 269000
  },
  {
    id: 25906124,
    name: "十年",
    artists: [{ id: 2116, name: "陈奕迅" }],
    album: { 
      id: 2236255, 
      name: "黑·白·灰", 
      picUrl: "http://p1.music.126.net/3TN7Pk41k1tysSv8mKfV3w==/109951165611393771.jpg" 
    },
    duration: 234000
  },
  {
    id: 27867140,
    name: "浮夸",
    artists: [{ id: 2116, name: "陈奕迅" }],
    album: { 
      id: 2629018, 
      name: "U-87", 
      picUrl: "http://p1.music.126.net/8wlSaF0RK8lNfBfDmVO65w==/109951165611402907.jpg" 
    },
    duration: 259000
  },
  {
    id: 108241,
    name: "富士山下",
    artists: [{ id: 2116, name: "陈奕迅" }],
    album: { 
      id: 10671, 
      name: "What's Going On...?", 
      picUrl: "http://p1.music.126.net/oMFKA4NYZXqDqQTxNLQnDQ==/109951165611390563.jpg" 
    },
    duration: 320000
  },
  {
    id: 188304,
    name: "吻别",
    artists: [{ id: 6478, name: "张学友" }],
    album: { 
      id: 18982, 
      name: "吻别", 
      picUrl: "http://p1.music.126.net/oMFKA4NYZXqDqQTxNLQnDQ==/109951165611390563.jpg" 
    },
    duration: 304000
  },
  {
    id: 188317,
    name: "一路上有你",
    artists: [{ id: 6478, name: "张学友" }],
    album: { 
      id: 18985, 
      name: "真爱", 
      picUrl: "http://p1.music.126.net/H0FaDRMrmVhv25EK1RLJAw==/109951165611394863.jpg" 
    },
    duration: 266000
  },
  {
    id: 185809,
    name: "江南",
    artists: [{ id: 6452, name: "林俊杰" }],
    album: { 
      id: 18888, 
      name: "第二天堂", 
      picUrl: "http://p1.music.126.net/zyqbxHZE1DgxIaP4W6d1cQ==/109951165611421492.jpg" 
    },
    duration: 260000
  },
  {
    id: 185868,
    name: "曹操",
    artists: [{ id: 6452, name: "林俊杰" }],
    album: { 
      id: 18893, 
      name: "曹操", 
      picUrl: "http://p1.music.126.net/IPhXI6CzyLPNB-bvzJ3kbg==/109951165611402922.jpg" 
    },
    duration: 230000
  },
  {
    id: 4875306,
    name: "倔强",
    artists: [{ id: 13193, name: "五月天" }],
    album: { 
      id: 485238, 
      name: "神的孩子都在跳舞", 
      picUrl: "http://p1.music.126.net/Q9lC-sL01l1pUg-O9h9_xg==/109951165611394861.jpg" 
    },
    duration: 231000
  },
  {
    id: 254597,
    name: "温柔",
    artists: [{ id: 13193, name: "五月天" }],
    album: { 
      id: 25653, 
      name: "温柔", 
      picUrl: "http://p1.music.126.net/B4X7VooL6pfGgN__DxuSEA==/109951165611390561.jpg" 
    },
    duration: 269000
  }
];

// 创建HTTP服务器
const server = http.createServer((req, res) => {
  // 设置CORS跨域头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  // 处理OPTIONS预检请求
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);

  // 1. 搜索接口
  if (pathname === '/search') {
    const keywords = query.keywords || '';
    const filtered = localSongs.filter(song => 
      song.name.includes(keywords) || 
      song.artists.some(artist => artist.name.includes(keywords))
    );

    res.writeHead(200);
    res.end(JSON.stringify({
      code: 200,
      result: {
        songs: filtered,
        songCount: filtered.length,
        hasMore: false
      }
    }));
    return;
  }

  // 2. 获取歌曲播放URL
  if (pathname === '/song/url/v1') {
    const id = parseInt(query.id);
    const song = localSongs.find(s => s.id === id);

    res.writeHead(200);
    res.end(JSON.stringify({
      code: 200,
      data: song ? [{
        id: song.id,
        url: `https://music.163.com/song/media/outer/url?id=${song.id}.mp3`,
        type: "mp3",
        size: 0,
        br: 320000
      }] : []
    }));
    return;
  }

  // 3. 获取歌词
  if (pathname === '/lyric') {
    const id = parseInt(query.id);
    const song = localSongs.find(s => s.id === id);
    
    res.writeHead(200);
    res.end(JSON.stringify({
      code: 200,
      lrc: { 
        lyric: song ? `[00:00.00] ${song.name} - ${song.artists[0].name}\n[00:05.00] 暂无歌词\n` : "[00:00.00] 未找到歌曲\n"
      }
    }));
    return;
  }

  // 4. 热门榜单
  if (pathname === '/playlist/detail') {
    res.writeHead(200);
    res.end(JSON.stringify({
      code: 200,
      playlist: {
        id: 3778678,
        name: "飙升榜",
        coverImgUrl: "http://p1.music.126.net/drP3ACw8R-d88Dr8RLHVLA==/18696095720518487.jpg",
        tracks: localSongs.slice(0, 10),
        trackCount: 10
      }
    }));
    return;
  }

  // 5. 根路径 - 显示帮助信息
  if (pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>音乐API服务</title>
        <style>
          body { font-family: Arial; padding: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
          h1 { color: #C10C17; }
          .endpoint { background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
          code { background: #e0e0e0; padding: 2px 5px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🎵 本地音乐API服务</h1>
          <p>服务运行正常！当前提供 <strong>${localSongs.length}</strong> 首测试歌曲。</p>
          
          <h2>可用接口：</h2>
          
          <div class="endpoint">
            <strong>1. 搜索歌曲</strong><br>
            <code>GET /search?keywords=海阔天空</code><br>
            <a href="/search?keywords=海阔天空" target="_blank">点击测试</a>
          </div>
          
          <div class="endpoint">
            <strong>2. 获取歌曲URL</strong><br>
            <code>GET /song/url/v1?id=347230</code><br>
            <a href="/song/url/v1?id=347230" target="_blank">点击测试</a>
          </div>
          
          <div class="endpoint">
            <strong>3. 获取歌词</strong><br>
            <code>GET /lyric?id=347230</code><br>
            <a href="/lyric?id=347230" target="_blank">点击测试</a>
          </div>
          
          <div class="endpoint">
            <strong>4. 热门榜单</strong><br>
            <code>GET /playlist/detail?id=3778678</code><br>
            <a href="/playlist/detail?id=3778678" target="_blank">点击测试</a>
          </div>
          
          <h2>本地歌曲列表：</h2>
          <ul>
            ${localSongs.map(s => `<li>${s.name} - ${s.artists[0].name}</li>`).join('')}
          </ul>
        </div>
      </body>
      </html>
    `);
    return;
  }

  // 404 - 未找到
  res.writeHead(404);
  res.end(JSON.stringify({ 
    code: 404, 
    message: 'Not Found',
    availableEndpoints: ['/search', '/song/url/v1', '/lyric', '/playlist/detail']
  }));
});

// 启动服务器
const PORT = 3000;
server.listen(PORT, () => {
  console.log('\n' + '='.repeat(60));
  console.log('✅ 网易云音乐本地API服务已启动！');
  console.log('='.repeat(60));
  console.log(`\n🌐 服务地址: http://localhost:${PORT}`);
  console.log(`🎵 本地歌曲: ${localSongs.length} 首`);
  console.log('\n📋 可用接口:');
  console.log(`   1. 搜索: http://localhost:${PORT}/search?keywords=海阔天空`);
  console.log(`   2. 歌曲: http://localhost:${PORT}/song/url/v1?id=347230`);
  console.log(`   3. 歌词: http://localhost:${PORT}/lyric?id=347230`);
  console.log(`   4. 榜单: http://localhost:${PORT}/playlist/detail?id=3778678`);
  console.log('\n💡 提示: 在浏览器访问 http://localhost:3000 查看完整帮助');
  console.log('⏸️  按 Ctrl+C 停止服务\n');
  console.log('='.repeat(60) + '\n');
});

// 错误处理
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`\n❌ 错误: 端口 ${PORT} 已被占用！`);
    console.error('请先关闭占用该端口的程序，或修改代码中的 PORT 值。\n');
  } else {
    console.error('\n❌ 服务器错误:', err.message, '\n');
  }
  process.exit(1);
});
