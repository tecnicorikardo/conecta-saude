import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

import { initializeFirebase, getFirebaseAuth } from '../src/config/firebase';

initializeFirebase();
const auth = getFirebaseAuth();
const prisma = new PrismaClient();

async function run() {
  const users = await prisma.user.findMany({ include: { setor: true } });
  console.log('--- ALL USERS IN DB ---');
  for (const u of users) {
    console.log(`${u.email} | ${u.nome} | Cargo: ${u.cargo} | Nivel: ${u.hierarquiaNivel} | Setor: ${u.setor?.nome} (${u.setorId}) | Ativo: ${u.ativo}`);
  }

  const sectors = await prisma.sector.findMany();
  console.log('\n--- ALL SECTORS ---');
  for (const s of sectors) {
    console.log(`${s.id} | ${s.nome}`);
  }

  const channels = await prisma.channel.findMany({ include: { members: true } });
  console.log('\n--- ALL CHANNELS ---');
  for (const c of channels) {
    console.log(`${c.id} | ${c.nome} | Tipo: ${c.tipo} | Membros: ${c.members.length}`);
  }

  try {
    const ricardo = await prisma.user.findUnique({
      where: { email: 'tecnicorikardo@gmail.com' },
      include: {
        channelMemberships: { include: { channel: true } },
        conversationMemberships: { include: { conversation: true } },
      },
    });
    try {
      const fbUser = await auth.getUserByEmail('tecnicorikardo@gmail.com');
      console.log('Firebase Auth UID:', fbUser.uid, '| DB firebaseUid:', ricardo?.firebaseUid);
      console.log('UIDs match?', fbUser.uid === ricardo?.firebaseUid);
    } catch (fbErr) {
      console.log('Error fetching from Firebase Auth:', fbErr);
    }
  } catch (e) {
    console.log('Error checking ricardo:', e);
  }
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
