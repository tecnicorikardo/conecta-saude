const http = require('http');

async function main() {
  const reqData = JSON.stringify({
    nome: 'Servidor Teste CCO',
    email: `teste.cco.${Date.now()}@conectasaude.dev`,
    password: 'password123',
    cargo: 'Técnico em Oftalmologia',
    setorId: 'e4061f34-8272-4459-be6a-047e743ff9b5',
    matricula: '123456-7'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/register',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(reqData)
    }
  };

  const req = http.request(options, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('BODY:', body);
    });
  });

  req.on('error', (e) => console.error('ERROR:', e.message));
  req.write(reqData);
  req.end();
}

main();
