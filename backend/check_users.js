const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: {
      id: true,
      nome: true,
      email: true,
      cargo: true,
      ativo: true,
      aprovadoPor: true,
      aprovadoEm: true,
      criadoEm: true,
      setor: { select: { nome: true } },
    },
    orderBy: { criadoEm: 'desc' },
  });
  console.log(JSON.stringify(users, null, 2));
  await prisma.$disconnect();
}

main().catch(console.error);
