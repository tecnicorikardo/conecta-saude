// Read-only connection check. Never prints a connection string or database rows.
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { PrismaClient } = require('@prisma/client');

async function main() {
  const connection = process.env.SUPABASE_DATABASE_URL;
  if (!connection) {
    throw new Error('Configure SUPABASE_DATABASE_URL no backend/.env com a conexão Session pooler do Supabase.');
  }
  let url;
  try { url = new URL(connection); } catch { throw new Error('Conexão PostgreSQL inválida.'); }
  if (!['postgres:', 'postgresql:'].includes(url.protocol) ||
      !(url.hostname.endsWith('.supabase.com') || url.hostname.endsWith('.supabase.co'))) {
    throw new Error('O destino deve ser uma conexão PostgreSQL do Supabase.');
  }
  const project = 'sxviipihvpkggukyfcfj';
  if (url.hostname !== `db.${project}.supabase.co` &&
      !decodeURIComponent(url.username).endsWith(`.${project}`)) {
    throw new Error('A conexão não corresponde ao projeto Supabase informado.');
  }
  if (!url.password) throw new Error('A conexão precisa da senha do banco, não de uma chave de API.');
  url.searchParams.set('connect_timeout', '10');
  url.searchParams.set('connection_limit', '1');
  const db = new PrismaClient({ datasources: { db: { url: url.toString() } } });
  try {
    await db.$queryRaw`SELECT 1`;
    console.log('Conexão Supabase validada. Nenhum dado foi alterado.');
  } catch (error) {
    if (/Can't reach database server/i.test(String(error.message))) {
      throw new Error('Servidor inacessível. Se estiver usando db.<projeto>.supabase.co, obtenha a conexão Session pooler no painel (compatível com IPv4).');
    }
    const candidate = error.code ?? error.errorCode;
    const code = typeof candidate === 'string' && /^P\d{4}$/.test(candidate) ? candidate : 'CONNECTION_ERROR';
    throw new Error(`Não foi possível conectar ao Supabase (${code}). Confira host, senha e disponibilidade.`);
  } finally {
    await db.$disconnect();
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
