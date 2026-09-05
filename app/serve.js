const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const BASE_DIR = path.join(__dirname, 'build', 'web');

const mimeTypes = {
  '.html': 'text/html',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.map':  'application/json',
  '.ttf':  'font/ttf',
  '.otf':  'font/otf',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
};

const server = http.createServer((req, res) => {
  // CORS para dev
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');

  let urlPath = req.url.split('?')[0];

  // Flutter web usa hash routing — sempre servir index.html para rotas desconhecidas
  let filePath = path.join(BASE_DIR, urlPath);

  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(BASE_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log('');
  console.log('  ✅ Conecta Saúde — Web Server');
  console.log(`  🌐 http://localhost:${PORT}`);
  console.log('');
  console.log('  Telas disponíveis:');
  console.log(`  → Splash/Login  : http://localhost:${PORT}`);
  console.log(`  → Home          : http://localhost:${PORT}/#/home`);
  console.log(`  → Conversas     : http://localhost:${PORT}/#/conversations`);
  console.log(`  → Chat          : http://localhost:${PORT}/#/chat/conv-1`);
  console.log(`  → Perfil        : http://localhost:${PORT}/#/profile`);
  console.log('');
});
