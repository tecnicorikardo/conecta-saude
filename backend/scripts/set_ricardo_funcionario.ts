import { PrismaClient } from '@prisma/client';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const prisma = new PrismaClient();

async function run() {
  const email = 'tecnicorikardo@gmail.com';

  // Buscar setor CCO (Centro Carioca do Olho) ou primeiro setor operacional
  const ccoSector = await prisma.sector.findFirst({
    where: { nome: { contains: 'Olho', mode: 'insensitive' } },
  });

  if (!ccoSector) {
    throw new Error('Setor CCO não encontrado');
  }

  // 1. Atualizar ou criar o usuário como FUNCIONÁRIO (Nível 4)
  const user = await prisma.user.upsert({
    where: { email },
    update: {
      nome: 'Ricardo Martins Santos',
      cargo: 'Funcionário / Técnico de Saúde',
      hierarquiaNivel: 4, // Nível 4 = Funcionário
      setorId: ccoSector.id,
      ativo: true,
      aprovadoEm: new Date(),
    },
    create: {
      firebaseUid: 'h0pit2BfGQTvqNlWpKiO9GlZnqn1',
      nome: 'Ricardo Martins Santos',
      email,
      cargo: 'Funcionário / Técnico de Saúde',
      hierarquiaNivel: 4, // Nível 4 = Funcionário
      setorId: ccoSector.id,
      ativo: true,
      aprovadoEm: new Date(),
    },
    include: { setor: true },
  });

  console.log('✅ Usuário configurado como Funcionário:');
  console.log(`   Nome: ${user.nome}`);
  console.log(`   Email: ${user.email}`);
  console.log(`   Cargo: ${user.cargo}`);
  console.log(`   Nível Hierárquico: ${user.hierarquiaNivel} (Funcionário)`);
  console.log(`   Setor: ${user.setor.nome} (${user.setorId})`);
  console.log(`   Ativo: ${user.ativo}`);

  // 2. Adicionar aos canais relevantes: Geral, Emergência e Canal do Setor (CCO)
  const channels = await prisma.channel.findMany({
    where: {
      OR: [
        { tipo: 'institucional' },
        { tipo: 'emergencia' },
        { setorId: ccoSector.id },
      ],
    },
  });

  for (const ch of channels) {
    await prisma.channelMember.upsert({
      where: { channelId_userId: { channelId: ch.id, userId: user.id } },
      create: { channelId: ch.id, userId: user.id },
      update: {},
    });
    console.log(`   📢 Membro do canal: ${ch.nome} (${ch.tipo})`);
  }

  // 3. Criar conversas de exemplo para o funcionário Ricardo
  // A) Conversa com o Coordenador do CCO (Dr. Roberto Vasconcelos)
  const coordCCO = await prisma.user.findFirst({
    where: { email: 'coord.cco@conectasaude.dev' },
  });

  if (coordCCO) {
    let convCCO = await prisma.conversation.findFirst({
      where: {
        tipo: 'individual',
        AND: [
          { members: { some: { userId: user.id } } },
          { members: { some: { userId: coordCCO.id } } },
        ],
      },
    });

    if (!convCCO) {
      convCCO = await prisma.conversation.create({
        data: {
          tipo: 'individual',
          criadoPor: coordCCO.id,
          setorId: ccoSector.id,
          ativo: true,
          members: {
            create: [{ userId: user.id }, { userId: coordCCO.id }],
          },
        },
      });

      await prisma.message.create({
        data: {
          conversationId: convCCO.id,
          remetenteId: coordCCO.id,
          texto: 'Olá Ricardo, seja bem-vindo ao turno do Centro Carioca do Olho (CCO)! Qualquer dúvida sobre a escala ou procedimentos cirúrgicos, pode me acionar por aqui.',
        },
      });
      console.log('   💬 Conversa criada com Coord. CCO');
    }
  }

  // B) Conversa com a Direção Geral
  const direcao = await prisma.user.findFirst({
    where: { email: 'direcao@conectasaude.dev' },
  });

  if (direcao) {
    let convDir = await prisma.conversation.findFirst({
      where: {
        tipo: 'individual',
        AND: [
          { members: { some: { userId: user.id } } },
          { members: { some: { userId: direcao.id } } },
        ],
      },
    });

    if (!convDir) {
      convDir = await prisma.conversation.create({
        data: {
          tipo: 'individual',
          criadoPor: direcao.id,
          setorId: ccoSector.id,
          ativo: true,
          members: {
            create: [{ userId: user.id }, { userId: direcao.id }],
          },
        },
      });

      await prisma.message.create({
        data: {
          conversationId: convDir.id,
          remetenteId: direcao.id,
          texto: 'Prezado colaborador Ricardo, seu cadastro institucional está confirmado e liberado. Bom trabalho!',
        },
      });
      console.log('   💬 Conversa criada com Direção Geral');
    }
  }
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
