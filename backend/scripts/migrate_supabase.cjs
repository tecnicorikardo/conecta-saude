// One-time copy into an EMPTY Supabase public schema. Source is read-only.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { PrismaClient, Prisma } = require('@prisma/client');
const models = Prisma.dmmf.datamodel.models;
const key = m => m.name[0].toLowerCase() + m.name.slice(1);
const digest = rows => crypto.createHash('sha256').update(JSON.stringify(rows)).digest('hex');
const quote = s => '"' + s.replaceAll('"', '""') + '"';
async function snapshot(client) {
  const data = {};
  for (const m of models) data[key(m)] = await client[key(m)].findMany({ orderBy: { id: 'asc' } });
  return data;
}
async function main() {
  if (!process.argv.includes('--copy')) throw new Error('Use --copy para copiar para um destino vazio.');
  const origin = process.env.DATABASE_URL;
  const target = process.env.SUPABASE_DATABASE_URL;
  if (!origin || !target || origin === target) throw new Error('Origem e destino distintos são obrigatórios.');
  const url = new URL(target);
  if (url.hostname !== 'aws-0-us-west-2.pooler.supabase.com' || decodeURIComponent(url.username) !== 'postgres.sxviipihvpkggukyfcfj') {
    throw new Error('Destino diferente do projeto autorizado.');
  }
  const source = new PrismaClient({ datasources: { db: { url: origin } } });
  const dest = new PrismaClient({ datasources: { db: { url: target } } });
  try {
    const existing = await dest.$queryRaw`SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'`;
    if (existing.length) throw new Error('Destino não vazio: operação interrompida sem sobrescrever dados.');
    const data = await source.$transaction(tx => snapshot(tx), { isolationLevel: 'RepeatableRead', timeout: 120000 });
    const folder = path.join(__dirname, '..', '.local-migration');
    fs.mkdirSync(folder, { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    fs.writeFileSync(path.join(folder, `source-${stamp}.json`), JSON.stringify(data), { flag: 'wx' });
    const ddl = fs.readFileSync(path.join(__dirname, '..', 'prisma', 'supabase-baseline.sql'), 'utf8');
    await dest.$transaction(async tx => {
      for (const statement of ddl.split(';').map(s => s.trim()).filter(Boolean)) await tx.$executeRawUnsafe(statement);
      // Block Data API access: the existing backend owns authorization.
      for (const m of models) {
        const table = quote(m.dbName || m.name);
        await tx.$executeRawUnsafe(`ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY`);
        await tx.$executeRawUnsafe(`REVOKE ALL ON TABLE public.${table} FROM anon, authenticated`);
      }
      for (const m of models) {
        const rows = data[key(m)];
        if (!rows.length) continue;
        // Self-referencing approval links are restored after all users exist.
        const insert = m.name === 'User' ? rows.map(r => ({ ...r, aprovadoPor: null })) : rows;
        await tx[key(m)].createMany({ data: insert });
        if (m.name === 'User') {
          for (const row of rows.filter(r => r.aprovadoPor)) {
            await tx.user.update({ where: { id: row.id }, data: { aprovadoPor: row.aprovadoPor, atualizadoEm: row.atualizadoEm } });
          }
        }
      }
      const copied = await snapshot(tx);
      for (const m of models) {
        if (digest(data[key(m)]) !== digest(copied[key(m)])) throw new Error(`Verificação falhou em ${m.dbName}.`);
      }
    }, { timeout: 120000, maxWait: 15000 });
    const latest = await source.$transaction(tx => snapshot(tx), { isolationLevel: 'RepeatableRead', timeout: 120000 });
    const changed = models.filter(m => digest(latest[key(m)]) !== digest(data[key(m)])).map(m => m.dbName);
    const report = { copiedAt: new Date().toISOString(), tables: models.map(m => ({ table: m.dbName, rows: data[key(m)].length })), sourceChangedDuringCopy: changed };
    fs.writeFileSync(path.join(folder, `report-${stamp}.json`), JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report));
    if (changed.length) throw new Error('Origem mudou durante a cópia. Não trocar a conexão sem reconciliar os dados.');
  } finally {
    await source.$disconnect();
    await dest.$disconnect();
  }
}
main().catch(e => { console.error(e.code || e.errorCode || (e.constructor.name === 'Error' ? e.message : 'Falha de migração; detalhes sensíveis omitidos.')); process.exitCode = 1; });
