/**
 * Script para criar usuário de teste no Firebase Auth
 * e vincular ao usuário existente no banco.
 *
 * Executar: npx tsx scripts/create-test-user.ts
 */
import 'dotenv/config';
import * as admin from 'firebase-admin';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Inicializar Firebase Admin
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID!,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
      privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n'),
    }),
  });

  const auth = admin.auth();

  const testUsers = [
    { email: 'direcao@conectasaude.dev',    password: 'ConectaSUS@2026', displayName: 'Carlos Eduardo Mendes' },
    { email: 'coord.ccdti@conectasaude.dev', password: 'ConectaSUS@2026', displayName: 'Dra. Juliana Moreira' },
    { email: 'lucas.ccdti@conectasaude.dev', password: 'ConectaSUS@2026', displayName: 'Lucas Ribeiro' },
    { email: 'mariana.ccdti@conectasaude.dev', password: 'ConectaSUS@2026', displayName: 'Mariana Lima' },
    { email: 'coord.cco@conectasaude.dev',   password: 'ConectaSUS@2026', displayName: 'Dr. Roberto Vasconcelos' },
    { email: 'paula.cco@conectasaude.dev',   password: 'ConectaSUS@2026', displayName: 'Paula Souza' },
    { email: 'thiago.cco@conectasaude.dev',  password: 'ConectaSUS@2026', displayName: 'Thiago Duarte' },
    { email: 'coord.cce@conectasaude.dev',   password: 'ConectaSUS@2026', displayName: 'Dra. Beatriz Castro' },
    { email: 'gabriel.cce@conectasaude.dev', password: 'ConectaSUS@2026', displayName: 'Gabriel Mendes' },
    { email: 'larissa.cce@conectasaude.dev', password: 'ConectaSUS@2026', displayName: 'Larissa Nogueira' },
    { email: 'inativo@conectasaude.dev',     password: 'ConectaSUS@2026', displayName: 'Colaborador Desligado' },
  ];

  console.log('🔑 Criando usuários no Firebase Auth...\n');

  for (const u of testUsers) {
    try {
      // Criar ou buscar no Firebase
      let firebaseUser: admin.auth.UserRecord;
      try {
        firebaseUser = await auth.getUserByEmail(u.email);
        await auth.updateUser(firebaseUser.uid, {
          password: u.password,
          displayName: u.displayName,
          emailVerified: true,
        });
        console.log(`🔄 Atualizado: ${u.email}`);
      } catch {
        firebaseUser = await auth.createUser({
          email: u.email,
          password: u.password,
          displayName: u.displayName,
          emailVerified: true,
        });
        console.log(`✅ Criado: ${u.email}`);
      }

      // Atualizar firebaseUid no banco
      const updated = await prisma.user.updateMany({
        where: { email: u.email },
        data: { firebaseUid: firebaseUser.uid },
      });

      if (updated.count > 0) {
        console.log(`   🔗 Vinculado ao banco (uid: ${firebaseUser.uid.substring(0, 12)}...)`);
      } else {
        console.log(`   ⚠️  Usuário não encontrado no banco: ${u.email}`);
      }
    } catch (err) {
      console.error(`❌ Erro em ${u.email}:`, err);
    }
  }

  // Sincronizar usuário real do proprietário (se existir no Firebase)
  try {
    const ownerEmail = 'tecnicorikardo@gmail.com';
    try {
      const ownerRecord = await auth.getUserByEmail(ownerEmail);
      const sector = await prisma.sector.findFirst();
      const existingOwner = await prisma.user.findUnique({ where: { email: ownerEmail } });
      if (!existingOwner && sector) {
        await prisma.user.create({
          data: {
            firebaseUid: ownerRecord.uid,
            nome: ownerRecord.displayName || 'Ricardo (Direção)',
            email: ownerEmail,
            cargo: 'Diretor Geral',
            hierarquiaNivel: 1,
            setorId: sector.id,
            ativo: true,
          },
        });
        console.log(`✨ Usuário real criado no banco: ${ownerEmail}`);
      } else if (existingOwner) {
        await prisma.user.update({
          where: { email: ownerEmail },
          data: { firebaseUid: ownerRecord.uid, ativo: true, hierarquiaNivel: 1 },
        });
        console.log(`🔗 Usuário real sincronizado no banco: ${ownerEmail}`);
      }
    } catch (e) {
      console.log(`ℹ️ Usuário real ${ownerEmail} não encontrado no Firebase Auth ainda.`);
    }
  } catch (err) {
    console.error('Erro ao verificar usuário real:', err);
  }

  console.log('\n──────────────────────────────────────────────────');
  console.log('✅ Configuração concluída!\n');
  console.log('📋 Credenciais para teste:');
  console.log('   Senha padrão: ConectaSUS@2026\n');
  testUsers.forEach(u => console.log(`   ${u.email}`));
  console.log('──────────────────────────────────────────────────\n');

  await prisma.$disconnect();
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
