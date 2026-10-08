import 'dotenv/config';
import { prisma } from '../config/database';

async function listSectorsUnits() {
  const units = await prisma.hospitalUnit.findMany();
  console.log('=== Unidades ===');
  for (const u of units) {
    console.log(`ID: ${u.id} | Nome: ${u.nome} | Sigla: ${u.sigla}`);
  }

  const sectors = await prisma.sector.findMany({
    include: { unit: true }
  });
  console.log('\n=== Setores ===');
  for (const s of sectors) {
    console.log(`ID: ${s.id} | Nome: ${s.nome} | Descrição: ${s.descricao} | Unidade: ${s.unit?.nome || 'N/A'}`);
  }
}

listSectorsUnits()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
