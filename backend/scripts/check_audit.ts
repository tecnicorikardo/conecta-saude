import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const prisma = new PrismaClient();

async function run() {
  const auditLogs = await prisma.auditLog.findMany({
    orderBy: { criadoEm: 'desc' },
    take: 20,
  });
  console.log('--- RECENT AUDIT LOGS ---');
  for (const a of auditLogs) {
    console.log(a.acao, '|', a.entidade, '|', a.detalhes);
  }
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
