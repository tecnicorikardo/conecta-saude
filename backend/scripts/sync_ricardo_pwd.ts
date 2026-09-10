import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

import { initializeFirebase, getFirebaseAuth } from '../src/config/firebase';

initializeFirebase();
const auth = getFirebaseAuth();
const prisma = new PrismaClient();

const DEFAULT_PASSWORD = 'ConectaSUS@2026';

async function run() {
  const ccoSetorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';

  const users = await prisma.user.findMany({
    where: {
      OR: [
        { setorId: ccoSetorId },
        { email: 'direcao@conectasaude.dev' }
      ]
    },
    include: { setor: true },
    orderBy: { hierarquiaNivel: 'asc' }
  });

  console.log('=== SINCRONIZANDO LOGINS COM O FIREBASE AUTH ===');
  const results: any[] = [];

  for (const user of users) {
    let fbUid = '';
    try {
      const existingFbUser = await auth.getUserByEmail(user.email);
      fbUid = existingFbUser.uid;
      await auth.updateUser(fbUid, {
        password: DEFAULT_PASSWORD,
        displayName: user.nome,
        disabled: !user.ativo
      });
      console.log(`[Firebase Auth] Usuário existente atualizado: ${user.email} (UID: ${fbUid})`);
    } catch (err: any) {
      if (err.code === 'auth/user-not-found') {
        const newFbUser = await auth.createUser({
          email: user.email,
          password: DEFAULT_PASSWORD,
          displayName: user.nome,
          disabled: !user.ativo
        });
        fbUid = newFbUser.uid;
        console.log(`[Firebase Auth] Novo usuário criado: ${user.email} (UID: ${fbUid})`);
      } else {
        console.error(`Erro no Firebase para ${user.email}:`, err);
        continue;
      }
    }

    if (user.firebaseUid !== fbUid) {
      await prisma.user.update({
        where: { id: user.id },
        data: { firebaseUid: fbUid }
      });
      console.log(`[DB Sync] UID sincronizado no banco para ${user.email}: ${fbUid}`);
    }

    results.push({
      nome: user.nome,
      email: user.email,
      senha: DEFAULT_PASSWORD,
      cargo: user.cargo,
      nivel: user.hierarquiaNivel,
      setor: user.setor?.nome || 'Geral',
      status: user.ativo ? 'Ativo' : 'Inativo'
    });
  }

  console.log('\n=== LOGINS DISPONÍVEIS PARA TESTES (CCO E DIREÇÃO) ===');
  console.table(results);
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

