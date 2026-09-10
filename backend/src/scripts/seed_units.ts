import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🏥 Inicializando Unidades Hospitalares...');

  const unitCentral = await prisma.hospitalUnit.upsert({
    where: { nome: 'Complexo Hospitalar Carioca (Central)' },
    update: {},
    create: {
      nome: 'Complexo Hospitalar Carioca (Central)',
      sigla: 'CHC-Centro',
      endereco: 'Av. Presidente Vargas, 1000 - Centro',
      cidade: 'Rio de Janeiro',
      ativo: true,
    },
  });

  const unitZonaSul = await prisma.hospitalUnit.upsert({
    where: { nome: 'Hospital Municipal Zona Sul' },
    update: {},
    create: {
      nome: 'Hospital Municipal Zona Sul',
      sigla: 'HMZS',
      endereco: 'Rua das Laranjeiras, 500 - Zona Sul',
      cidade: 'Rio de Janeiro',
      ativo: true,
    },
  });

  const unitUpa = await prisma.hospitalUnit.upsert({
    where: { nome: 'UPA 24h Regional' },
    update: {},
    create: {
      nome: 'UPA 24h Regional',
      sigla: 'UPA-24H',
      endereco: 'Estrada do Galeão, 300',
      cidade: 'Rio de Janeiro',
      ativo: true,
    },
  });

  console.log(`✅ Unidades prontas: ${unitCentral.nome}, ${unitZonaSul.nome}, ${unitUpa.nome}`);

  // Vincular setores sem unitId à unidade central
  const updatedSectors = await prisma.sector.updateMany({
    where: { unitId: null },
    data: { unitId: unitCentral.id },
  });
  console.log(`🔗 Setores vinculados à unidade central: ${updatedSectors.count}`);

  // Vincular usuários sem unitId à unidade central
  const updatedUsers = await prisma.user.updateMany({
    where: { unitId: null },
    data: { unitId: unitCentral.id },
  });
  console.log(`🔗 Usuários vinculados à unidade central: ${updatedUsers.count}`);
}

main()
  .catch((e) => {
    console.error('❌ Erro no seed de unidades:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
