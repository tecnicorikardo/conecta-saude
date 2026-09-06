import 'dotenv/config';
import { prisma } from '../config/database';

async function check() {
  const dbUsers = await prisma.user.findMany({
    select: { id: true, email: true, nome: true, firebaseUid: true, hierarquiaNivel: true, cargo: true, ativo: true }
  });
  console.log('=== PostgreSQL DB Users ===');
  for (const u of dbUsers) {
    console.log(`${u.email} | ativo: ${u.ativo} | nivel: ${u.hierarquiaNivel} | fbUid: ${u.firebaseUid}`);
  }
}
check().catch(console.error).finally(() => process.exit(0));
