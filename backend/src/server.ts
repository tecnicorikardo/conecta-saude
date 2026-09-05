import 'dotenv/config';
import { createApp } from './app';
import { initializeFirebase } from './config/firebase';
import { connectDatabase, disconnectDatabase } from './config/database';

const PORT = Number(process.env.PORT ?? 3000);

async function bootstrap(): Promise<void> {
  // 1. Firebase Admin SDK
  initializeFirebase();

  // 2. Banco de dados
  await connectDatabase();

  // 3. Servidor HTTP
  const app = createApp();

  const server = app.listen(PORT, () => {
    console.log(`\n🚀 Conecta Saúde API`);
    console.log(`   Ambiente : ${process.env.NODE_ENV ?? 'development'}`);
    console.log(`   Porta    : ${PORT}`);
    console.log(`   Health   : http://localhost:${PORT}/health\n`);
  });

  // ─── Graceful shutdown ─────────────────────────────────────────────────
  const shutdown = async (signal: string): Promise<void> => {
    console.log(`\n[Server] Recebido ${signal}. Encerrando...`);
    server.close(async () => {
      await disconnectDatabase();
      console.log('[Server] Encerrado com sucesso.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('unhandledRejection', (reason) => {
    console.error('[Server] UnhandledRejection:', reason);
  });
}

bootstrap().catch((err) => {
  console.error('[Server] Falha ao inicializar:', err);
  process.exit(1);
});
