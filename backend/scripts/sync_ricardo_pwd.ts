import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

import { initializeFirebase, getFirebaseAuth } from '../src/config/firebase';

initializeFirebase();
const auth = getFirebaseAuth();
const prisma = new PrismaClient();

async function run() {
  const email = 'tecnicorikardo@gmail.com';
  const fbUser = await auth.getUserByEmail(email);
  console.log('Firebase user found:', fbUser.uid, fbUser.email);

  await auth.updateUser(fbUser.uid, {
    password: 'ConectaSUS@2026',
  });
  console.log('✅ Senha do Firebase Auth atualizada para ConectaSUS@2026');
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
