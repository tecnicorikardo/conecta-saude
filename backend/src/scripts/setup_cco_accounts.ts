import * as path from 'path';
import * as dotenv from 'dotenv';
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

import { PrismaClient } from '@prisma/client';
import { initializeFirebase, getFirebaseAuth } from '../config/firebase';

initializeFirebase();
const auth = getFirebaseAuth();
const prisma = new PrismaClient();

const DEFAULT_PASSWORD = 'ConectaSUS@2026';

async function main() {
  console.log('🚀 Iniciando reestruturação das contas do Conecta Saúde (Foco CCO)...');

  // 1. Localizar Unidade e Setores
  const unitSccs = await prisma.hospitalUnit.findFirst({
    where: { nome: { contains: 'Super Centro', mode: 'insensitive' } },
  });

  const setorCco = await prisma.sector.findFirst({
    where: { nome: { contains: 'Olho', mode: 'insensitive' } },
  });

  const setorDirecao = await prisma.sector.findFirst({
    where: { nome: { contains: 'Direção Geral', mode: 'insensitive' } },
  });

  if (!setorCco || !setorDirecao) {
    throw new Error('Setores essenciais (CCO ou Direção Geral) não encontrados no banco!');
  }

  console.log(`🏥 Unidade SCCS: ${unitSccs?.id} (${unitSccs?.nome})`);
  console.log(`📂 Setor CCO: ${setorCco.id} (${setorCco.nome})`);
  console.log(`📂 Setor Direção Geral: ${setorDirecao.id} (${setorDirecao.nome})`);

  // 2. Definir contas oficiais do projeto
  const officialAccounts = [
    {
      email: 'direcao@conectasaude.dev',
      nome: 'Direção Geral',
      cargo: 'Diretor(a) Geral',
      hierarquiaNivel: 1, // NV 1
      setorId: setorDirecao.id,
      unitId: unitSccs?.id,
    },
    {
      email: 'direcao.cco@conectasaude.dev',
      nome: 'Direção CCO',
      cargo: 'Direção / Chefia de Enfermagem CCO',
      hierarquiaNivel: 2, // NV 2
      setorId: setorCco.id,
      unitId: unitSccs?.id,
    },
    {
      email: 'supervisao.cco@conectasaude.dev',
      nome: 'Supervisão de Enfermagem CCO',
      cargo: 'Supervisão e Enfermagem CCO',
      hierarquiaNivel: 3, // NV 3
      setorId: setorCco.id,
      unitId: unitSccs?.id,
    },
    {
      email: 'tecnicorikardo@gmail.com',
      nome: 'Ricardo Martins Santos',
      cargo: 'Funcionário / Apoio Técnico',
      hierarquiaNivel: 4, // NV 4 (Funcionário Comum)
      setorId: setorCco.id,
      unitId: unitSccs?.id,
    },
  ];

  const allowedEmails = officialAccounts.map((a) => a.email.toLowerCase());

  // 3. Criar ou sincronizar as contas oficiais no Firebase Auth e no PostgreSQL
  const savedUsers: Record<string, string> = {};

  for (const acc of officialAccounts) {
    console.log(`\n⚙️ Configurando conta: ${acc.email} (NV ${acc.hierarquiaNivel})...`);
    let fbUid = '';

    try {
      const fbUser = await auth.getUserByEmail(acc.email);
      fbUid = fbUser.uid;
      await auth.updateUser(fbUid, {
        password: DEFAULT_PASSWORD,
        displayName: acc.nome,
        disabled: false,
      });
      console.log(`   [Firebase Auth] Atualizado: UID ${fbUid}`);
    } catch (err: any) {
      if (err.code === 'auth/user-not-found') {
        const newFbUser = await auth.createUser({
          email: acc.email,
          password: DEFAULT_PASSWORD,
          displayName: acc.nome,
          disabled: false,
        });
        fbUid = newFbUser.uid;
        console.log(`   [Firebase Auth] Criado: UID ${fbUid}`);
      } else {
        throw err;
      }
    }

    const dbUser = await prisma.user.upsert({
      where: { email: acc.email },
      update: {
        firebaseUid: fbUid,
        nome: acc.nome,
        cargo: acc.cargo,
        hierarquiaNivel: acc.hierarquiaNivel,
        setorId: acc.setorId,
        unitId: acc.unitId,
        ativo: true,
        aprovadoEm: new Date(),
        emServico: true,
      },
      create: {
        firebaseUid: fbUid,
        nome: acc.nome,
        email: acc.email,
        cargo: acc.cargo,
        hierarquiaNivel: acc.hierarquiaNivel,
        setorId: acc.setorId,
        unitId: acc.unitId,
        ativo: true,
        aprovadoEm: new Date(),
        emServico: true,
      },
    });

    savedUsers[acc.email] = dbUser.id;
    console.log(`   [PostgreSQL] Upsert concluído: ID ${dbUser.id} | Nível ${dbUser.hierarquiaNivel}`);
  }

  // 4. Vincular as contas aos Canais Institucionais e do CCO
  const channels = await prisma.channel.findMany({
    where: {
      OR: [
        { tipo: 'institucional' },
        { tipo: 'emergencia' },
        { setorId: setorCco.id },
      ],
    },
  });

  for (const channel of channels) {
    for (const userId of Object.values(savedUsers)) {
      await prisma.channelMember.upsert({
        where: {
          channelId_userId: {
            channelId: channel.id,
            userId,
          },
        },
        update: {},
        create: {
          channelId: channel.id,
          userId,
        },
      });
    }
  }
  console.log(`✅ Canais vinculados aos servidores oficiais.`);

  // 5. Identificar e expurgar todas as contas não permitidas
  const allDbUsers = await prisma.user.findMany({
    select: { id: true, email: true, firebaseUid: true },
  });

  const usersToDelete = allDbUsers.filter(
    (u) => !allowedEmails.includes(u.email.toLowerCase())
  );

  console.log(`\n🗑️ Encontrados ${usersToDelete.length} usuários para expurgo.`);

  const direcaoGeralId = savedUsers['direcao@conectasaude.dev'];

  for (const u of usersToDelete) {
    console.log(`   Removendo: ${u.email} (ID: ${u.id})...`);

    // Limpeza de tabelas filhas / relacionamentos
    await prisma.announcementRead.deleteMany({ where: { userId: u.id } });
    await prisma.messageRead.deleteMany({ where: { userId: u.id } });
    await prisma.channelMessageRead.deleteMany({ where: { userId: u.id } });
    await prisma.channelMember.deleteMany({ where: { userId: u.id } });
    await prisma.conversationMember.deleteMany({ where: { userId: u.id } });

    // Mensagens em canais e conversas
    await prisma.channelMessage.deleteMany({ where: { remetenteId: u.id } });
    await prisma.message.deleteMany({ where: { remetenteId: u.id } });

    // Se criou conversas ou canais, reatribuir para a Direção Geral
    await prisma.conversation.updateMany({
      where: { criadoPor: u.id },
      data: { criadoPor: direcaoGeralId },
    });
    await prisma.channel.updateMany({
      where: { criadoPor: u.id },
      data: { criadoPor: direcaoGeralId },
    });
    await prisma.announcement.updateMany({
      where: { criadoPor: u.id },
      data: { criadoPor: direcaoGeralId },
    });
    await prisma.emergencyAlert.updateMany({
      where: { criadoPor: u.id },
      data: { criadoPor: direcaoGeralId },
    });
    await prisma.emergencyAlert.updateMany({
      where: { resolvidoPor: u.id },
      data: { resolvidoPor: direcaoGeralId },
    });

    // Relatos e denúncias
    await prisma.report.deleteMany({
      where: {
        OR: [
          { reporterId: u.id },
          { reportedUserId: u.id },
          { resolvidoPor: u.id },
        ],
      },
    });

    // AuditLogs
    await prisma.auditLog.deleteMany({ where: { userId: u.id } });

    // Excluir usuário do PostgreSQL
    await prisma.user.delete({ where: { id: u.id } });
    console.log(`   [PostgreSQL] Excluído: ${u.email}`);

    // Excluir do Firebase Auth
    if (u.firebaseUid) {
      try {
        await auth.deleteUser(u.firebaseUid);
        console.log(`   [Firebase Auth] Excluído UID: ${u.firebaseUid}`);
      } catch (fbErr: any) {
        if (fbErr.code !== 'auth/user-not-found') {
          console.warn(`   [Firebase Auth] Alerta ao excluir UID ${u.firebaseUid}: ${fbErr.message}`);
        }
      }
    }
  }

  console.log('\n======================================================');
  console.log('🎉 REESTRUTURAÇÃO CONCLUÍDA COM SUCESSO!');
  console.log('======================================================');
  console.log('Contas ativas e operacionais no Conecta Saúde:');
  for (const acc of officialAccounts) {
    console.log(`- Nível ${acc.hierarquiaNivel}: ${acc.email} | ${acc.cargo} (${acc.nome}) | Senha: ${DEFAULT_PASSWORD}`);
  }
  console.log('======================================================\n');
}

main()
  .catch((err) => {
    console.error('❌ Erro durante a execução:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
