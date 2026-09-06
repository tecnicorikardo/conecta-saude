const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- TESTE COMPLETO DA ESTEIRA DE AUTO-CADASTRO E APROVAÇÃO ---');

  // 1. Localizar o usuário pendente recém-criado
  const pendingUser = await prisma.user.findFirst({
    where: { ativo: false, aprovadoEm: null },
    include: { setor: true }
  });

  console.log('1. Usuário Pendente Encontrado:');
  console.log(`- Nome: ${pendingUser?.nome}`);
  console.log(`- Setor: ${pendingUser?.setor.nome}`);
  console.log(`- Ativo: ${pendingUser?.ativo}`);
  console.log(`- Aprovado Por: ${pendingUser?.aprovadoPor}`);
  console.log(`- Aprovado Em: ${pendingUser?.aprovadoEm}`);

  if (!pendingUser) {
    console.error('Nenhum usuário pendente encontrado.');
    return;
  }

  // 2. Localizar Coordenador do CCO (Dr. Roberto Vasconcelos)
  const drRoberto = await prisma.user.findFirst({
    where: { email: 'coord.cco@conectasaude.dev' }
  });

  console.log('\n2. Coordenador da Unidade:');
  console.log(`- Nome: ${drRoberto?.nome} (${drRoberto?.cargo})`);

  // 3. Simular Aprovação em 1 clique pelo Dr. Roberto
  const approvedUser = await prisma.user.update({
    where: { id: pendingUser.id },
    data: {
      ativo: true,
      aprovadoPor: drRoberto.id,
      aprovadoEm: new Date(),
    },
    include: {
      setor: true,
      aprovador: true,
    }
  });

  console.log('\n3. Status após 1-Clique de Aprovação:');
  console.log(`- Nome: ${approvedUser.nome}`);
  console.log(`- Ativo: ${approvedUser.ativo} (ACESSO LIBERADO)`);
  console.log(`- Aprovador: ${approvedUser.aprovador?.nome} (${approvedUser.aprovador?.cargo})`);
  console.log(`- Data de Aprovação: ${approvedUser.aprovadoEm.toISOString()}`);

  // 4. Limpar o registro de teste
  await prisma.auditLog.deleteMany({ where: { userId: pendingUser.id } });
  await prisma.user.delete({ where: { id: pendingUser.id } });
  console.log('\n4. Limpeza do usuário de teste concluída com sucesso.');

  await prisma.$disconnect();
}

main().catch(console.error);
