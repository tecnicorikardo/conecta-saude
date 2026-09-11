/**
 * Job de limpeza: apaga fisicamente do banco mensagens com mais de 24h
 * de conversas que têm autoExcluir24h = true.
 *
 * Roda a cada 1 hora em background via setInterval.
 * Isso libera espaço real no banco — especialmente importante para
 * ambientes com 1000+ funcionários gerando alto volume de mensagens.
 */
import { prisma } from '../config/database';

const INTERVAL_MS = 60 * 60 * 1000; // 1 hora
const RETENTION_MS = 24 * 60 * 60 * 1000; // 24 horas

async function runCleanup(): Promise<void> {
  try {
    const cutoff = new Date(Date.now() - RETENTION_MS);

    // Deleta mensagens antigas (incluindo reads em cascata) somente de conversas
    // com auto-exclusão habilitada.
    const result = await prisma.message.deleteMany({
      where: {
        criadoEm: { lt: cutoff },
        conversation: {
          autoExcluir24h: true,
        },
      },
    });

    if (result.count > 0) {
      console.log(`[Cleanup] 🗑️  ${result.count} mensagem(ns) com >24h apagada(s) do banco.`);
    }
  } catch (err) {
    console.error('[Cleanup] Erro ao limpar mensagens antigas:', err);
  }
}

/**
 * Inicia o job de limpeza periódica.
 * Deve ser chamado uma vez na inicialização do servidor.
 */
export function startCleanupJob(): void {
  // Executa imediatamente na inicialização e depois a cada hora
  runCleanup();
  setInterval(runCleanup, INTERVAL_MS);
  console.log('[Cleanup] Job de auto-limpeza de mensagens iniciado (intervalo: 1h).');
}
