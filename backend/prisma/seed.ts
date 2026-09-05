/**
 * Seed de desenvolvimento — Conecta Saúde
 *
 * ATENÇÃO: Usar somente em ambiente de desenvolvimento.
 * Nunca executar em produção com dados reais.
 *
 * Os UIDs Firebase são fictícios — em produção os usuários
 * devem ser criados via endpoint POST /api/users que cria
 * no Firebase Auth e no PostgreSQL simultaneamente.
 *
 * Executar com: npm run db:seed
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  console.log('🌱 Iniciando seed...\n');

  // ─── Limpar tabelas na ordem correta ──────────────────────────────────────
  console.log('🗑️  Limpando dados existentes...');
  await prisma.auditLog.deleteMany();
  await prisma.report.deleteMany();
  await prisma.announcementRead.deleteMany();
  await prisma.announcement.deleteMany();
  await prisma.channelMember.deleteMany();
  await prisma.channel.deleteMany();
  await prisma.messageRead.deleteMany();
  await prisma.message.deleteMany();
  await prisma.conversationMember.deleteMany();
  await prisma.conversation.deleteMany();
  await prisma.user.deleteMany();
  await prisma.sector.deleteMany();
  console.log('✅ Dados limpos.\n');

  // ─── Setores / Centros Oficiais ──────────────────────────────────────────
  console.log('📂 Criando centros e setores...');
  const sectors = await Promise.all([
    prisma.sector.create({
      data: {
        nome: 'Direção Geral',
        descricao: 'Administração Central e Gestão Integrada',
        ativo: true,
      },
    }),
    prisma.sector.create({
      data: {
        nome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
        descricao: 'Unidade de exames de imagem, tomografia, ressonância e diagnóstico',
        ativo: true,
      },
    }),
    prisma.sector.create({
      data: {
        nome: 'Centro Carioca do Olho (CCO)',
        descricao: 'Unidade especializada em oftalmologia e cirurgias refrativas/catarata',
        ativo: true,
      },
    }),
    prisma.sector.create({
      data: {
        nome: 'Centro Carioca de Especialidades (CCE)',
        descricao: 'Unidade de consultas médicas especializadas e regulação ambulatorial',
        ativo: true,
      },
    }),
  ]);

  const [direcaoSetor, ccdti, cco, cce] = sectors;
  console.log(`✅ ${sectors.length} setores/centros criados.\n`);

  // ─── Usuários ─────────────────────────────────────────────────────────────
  console.log('👥 Criando usuários...');

  // ADMIN GERAL / DIRETOR (nível 1 — Visão global sobre CCDTI, CCO e CCE)
  const direcao = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-direcao-001',
      nome: 'Carlos Eduardo Mendes',
      email: 'direcao@conectasaude.dev',
      cargo: 'Diretor Geral / Admin Geral',
      hierarquiaNivel: 1,
      setorId: direcaoSetor.id,
      ativo: true,
    },
  });

  // CCDTI (Centro Carioca de Diagnóstico e Tratamento por Imagem)
  const coordCCDTI = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-coord-ccdti-001',
      nome: 'Dra. Juliana Moreira',
      email: 'coord.ccdti@conectasaude.dev',
      cargo: 'Coordenadora — CCDTI',
      hierarquiaNivel: 2,
      setorId: ccdti.id,
      ativo: true,
    },
  });

  const funcCCDTI_1 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-ccdti-001',
      nome: 'Lucas Ribeiro',
      email: 'lucas.ccdti@conectasaude.dev',
      cargo: 'Técnico em Radiologia — CCDTI',
      hierarquiaNivel: 4,
      setorId: ccdti.id,
      ativo: true,
    },
  });

  const funcCCDTI_2 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-ccdti-002',
      nome: 'Mariana Lima',
      email: 'mariana.ccdti@conectasaude.dev',
      cargo: 'Enfermeira de Exames — CCDTI',
      hierarquiaNivel: 4,
      setorId: ccdti.id,
      ativo: true,
    },
  });

  // CCO (Centro Carioca do Olho)
  const coordCCO = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-coord-cco-001',
      nome: 'Dr. Roberto Vasconcelos',
      email: 'coord.cco@conectasaude.dev',
      cargo: 'Coordenador Médico — CCO',
      hierarquiaNivel: 2,
      setorId: cco.id,
      ativo: true,
    },
  });

  const funcCCO_1 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-cco-001',
      nome: 'Paula Souza',
      email: 'paula.cco@conectasaude.dev',
      cargo: 'Técnica Oftalmológica — CCO',
      hierarquiaNivel: 4,
      setorId: cco.id,
      ativo: true,
    },
  });

  const funcCCO_2 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-cco-002',
      nome: 'Thiago Duarte',
      email: 'thiago.cco@conectasaude.dev',
      cargo: 'Enfermeiro Cirúrgico — CCO',
      hierarquiaNivel: 4,
      setorId: cco.id,
      ativo: true,
    },
  });

  // CCE (Centro Carioca de Especialidades)
  const coordCCE = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-coord-cce-001',
      nome: 'Dra. Beatriz Castro',
      email: 'coord.cce@conectasaude.dev',
      cargo: 'Coordenadora Ambulatorial — CCE',
      hierarquiaNivel: 2,
      setorId: cce.id,
      ativo: true,
    },
  });

  const funcCCE_1 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-cce-001',
      nome: 'Gabriel Mendes',
      email: 'gabriel.cce@conectasaude.dev',
      cargo: 'Assistente de Regulação — CCE',
      hierarquiaNivel: 4,
      setorId: cce.id,
      ativo: true,
    },
  });

  const funcCCE_2 = await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-func-cce-002',
      nome: 'Larissa Nogueira',
      email: 'larissa.cce@conectasaude.dev',
      cargo: 'Técnica de Enfermagem — CCE',
      hierarquiaNivel: 4,
      setorId: cce.id,
      ativo: true,
    },
  });

  // Usuário inativo para testes
  await prisma.user.create({
    data: {
      firebaseUid: 'dev-uid-inativo-001',
      nome: 'Colaborador Desligado',
      email: 'inativo@conectasaude.dev',
      cargo: 'Ex-Funcionário',
      hierarquiaNivel: 4,
      setorId: cco.id,
      ativo: false,
    },
  });

  console.log('✅ Usuários criados.\n');

  // ─── Canais ───────────────────────────────────────────────────────────────
  console.log('📢 Criando canais dos centros...');

  const canalGeral = await prisma.channel.create({
    data: {
      nome: 'Avisos da Direção Geral',
      descricao: 'Canal oficial da Direção Geral para toda a rede (CCDTI, CCO, CCE)',
      tipo: 'institucional',
      criadoPor: direcao.id,
      ativo: true,
    },
  });

  const canalEmergencia = await prisma.channel.create({
    data: {
      nome: 'Alerta e Emergência Geral',
      descricao: 'Canal prioritário para acionamentos urgentes e transferências hospitalares',
      tipo: 'emergencia',
      criadoPor: direcao.id,
      ativo: true,
    },
  });

  const canalCCDTI = await prisma.channel.create({
    data: {
      nome: 'Equipe CCDTI — Tomografia e Laudos',
      descricao: 'Canal exclusivo para o corpo técnico e administrativo do CCDTI',
      tipo: 'setor',
      setorId: ccdti.id,
      criadoPor: coordCCDTI.id,
      ativo: true,
    },
  });

  const canalCCO = await prisma.channel.create({
    data: {
      nome: 'Equipe CCO — Bloco Cirúrgico e Consultórios',
      descricao: 'Canal exclusivo para o corpo técnico e administrativo do CCO',
      tipo: 'setor',
      setorId: cco.id,
      criadoPor: coordCCO.id,
      ativo: true,
    },
  });

  const canalCCE = await prisma.channel.create({
    data: {
      nome: 'Equipe CCE — Consultas e Especialidades',
      descricao: 'Canal exclusivo para o corpo técnico e administrativo do CCE',
      tipo: 'setor',
      setorId: cce.id,
      criadoPor: coordCCE.id,
      ativo: true,
    },
  });

  // Membros dos canais
  await prisma.channelMember.createMany({
    data: [
      // Geral
      { channelId: canalGeral.id, userId: direcao.id },
      { channelId: canalGeral.id, userId: coordCCDTI.id },
      { channelId: canalGeral.id, userId: funcCCDTI_1.id },
      { channelId: canalGeral.id, userId: coordCCO.id },
      { channelId: canalGeral.id, userId: funcCCO_1.id },
      { channelId: canalGeral.id, userId: coordCCE.id },
      { channelId: canalGeral.id, userId: funcCCE_1.id },
      // Emergência
      { channelId: canalEmergencia.id, userId: direcao.id },
      { channelId: canalEmergencia.id, userId: coordCCDTI.id },
      { channelId: canalEmergencia.id, userId: coordCCO.id },
      { channelId: canalEmergencia.id, userId: coordCCE.id },
      // Canal CCDTI — Exclusivo CCDTI + Direção
      { channelId: canalCCDTI.id, userId: direcao.id },
      { channelId: canalCCDTI.id, userId: coordCCDTI.id },
      { channelId: canalCCDTI.id, userId: funcCCDTI_1.id },
      { channelId: canalCCDTI.id, userId: funcCCDTI_2.id },
      // Canal CCO — Exclusivo CCO + Direção
      { channelId: canalCCO.id, userId: direcao.id },
      { channelId: canalCCO.id, userId: coordCCO.id },
      { channelId: canalCCO.id, userId: funcCCO_1.id },
      { channelId: canalCCO.id, userId: funcCCO_2.id },
      // Canal CCE — Exclusivo CCE + Direção
      { channelId: canalCCE.id, userId: direcao.id },
      { channelId: canalCCE.id, userId: coordCCE.id },
      { channelId: canalCCE.id, userId: funcCCE_1.id },
      { channelId: canalCCE.id, userId: funcCCE_2.id },
    ],
  });

  console.log(`✅ 5 canais criados.\n`);

  // ─── Conversa individual de exemplo ───────────────────────────────────────
  console.log('💬 Criando conversas de exemplo...');

  // Conversa entre Diretor Geral e Coordenadora do CCDTI
  const conversa1 = await prisma.conversation.create({
    data: {
      tipo: 'individual',
      criadoPor: direcao.id,
      setorId: direcaoSetor.id,
      ativo: true,
      members: {
        create: [
          { userId: direcao.id },
          { userId: coordCCDTI.id },
        ],
      },
    },
  });

  // Mensagens na conversa
  await prisma.message.create({
    data: {
      conversationId: conversa1.id,
      remetenteId: direcao.id,
      texto: 'Dra. Juliana, como está a fila de espera para ressonância magnética nesta semana?',
    },
  });

  await prisma.message.create({
    data: {
      conversationId: conversa1.id,
      remetenteId: coordCCDTI.id,
      texto: 'Dr. Carlos, conseguimos reduzir o tempo médio para 5 dias com os turnos extras do CCDTI.',
    },
  });

  console.log('✅ Conversas criadas.\n');

  // ─── Comunicados ──────────────────────────────────────────────────────────
  console.log('📋 Criando comunicados...');

  await prisma.announcement.create({
    data: {
      titulo: 'Reunião Geral de Integração — CCDTI, CCO e CCE',
      mensagem: 'Informamos que haverá reunião geral de planejamento integrado amanhã às 14h no auditório central. A presença de todos os coordenadores dos três centros é obrigatória.',
      prioridade: 'alta',
      criadoPor: direcao.id,
      publicadoEm: new Date(),
      ativo: true,
    },
  });

  await prisma.announcement.create({
    data: {
      titulo: 'Ampliação da Capacidade Cirúrgica no CCO',
      mensagem: 'O Centro Carioca do Olho (CCO) passa a operar com capacidade estendida aos sábados para mutirão de cirurgias de catarata.',
      prioridade: 'normal',
      criadoPor: coordCCO.id,
      publicadoEm: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 dias atrás
      ativo: true,
    },
  });

  await prisma.announcement.create({
    data: {
      titulo: 'URGENTE: Protocolo de Higienização',
      mensagem: 'Em virtude de alertas da vigilância epidemiológica, reforçamos o cumprimento rigoroso do protocolo de higienização de mãos. Todos os funcionários devem seguir o procedimento POP-HIG-001 sem exceção.',
      prioridade: 'urgente',
      criadoPor: direcao.id,
      publicadoEm: new Date(Date.now() - 60 * 60 * 1000), // 1 hora atrás
      ativo: true,
    },
  });

  console.log('✅ Comunicados criados.\n');

  // ─── Resumo ────────────────────────────────────────────────────────────────
  console.log('─'.repeat(50));
  console.log('✅ Seed concluído com sucesso!\n');
  console.log('📊 Resumo:');
  console.log(`   Setores    : ${sectors.length} (Direção Geral, CCDTI, CCO, CCE)`);
  console.log(`   Usuários   : 11 (1 Diretor Geral, 3 Coordenadores, 6 Funcionários, 1 Inativo)`);
  console.log(`   Canais     : 5 (Geral, Emergência, CCDTI, CCO, CCE)`);
  console.log(`   Conversas  : 1`);
  console.log(`   Comunicados: 3\n`);
  console.log('🔑 Contas de desenvolvimento (Firebase UIDs fictícios):');
  console.log('   Direção Geral : direcao@conectasaude.dev');
  console.log('   Coord. CCDTI  : coord.ccdti@conectasaude.dev');
  console.log('   Coord. CCO    : coord.cco@conectasaude.dev');
  console.log('   Coord. CCE    : coord.cce@conectasaude.dev');
  console.log('   Func. CCDTI   : lucas.ccdti@conectasaude.dev');
  console.log('   Func. CCO     : paula.cco@conectasaude.dev');
  console.log('   Func. CCE     : gabriel.cce@conectasaude.dev');
  console.log('─'.repeat(50));
}

main()
  .catch((e) => {
    console.error('❌ Seed falhou:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
