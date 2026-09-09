import 'dotenv/config';
import { createApp } from './app';
import { initializeFirebase } from './config/firebase';
import { connectDatabase, disconnectDatabase } from './config/database';
import { startRealtime } from './realtime';

const PORT = Number(process.env.PORT ?? 3000);

async function bootstrap(): Promise<void> {
  // 1. Servidor HTTP (inicia imediatamente para atender /health e binding do Render)
  const app = createApp();

  const server = app.listen(PORT, () => {
    console.log(`\n🚀 Conecta Saúde API`);
    console.log(`   Ambiente : ${process.env.NODE_ENV ?? 'development'}`);
    console.log(`   Porta    : ${PORT}`);
    console.log(`   Health   : http://localhost:${PORT}/health\n`);
  });
  const realtime = startRealtime(server);

  // 2. Firebase Admin SDK
  try {
    initializeFirebase();
  } catch (fbErr) {
    console.error('[Firebase] Alerta ao inicializar Admin SDK:', fbErr);
  }

  // 3. Conexão ao banco de dados PostgreSQL
  try {
    await connectDatabase();
  } catch (dbErr) {
    console.error('[Database] Alerta ao conectar:', dbErr);
  }

  // ─── Graceful shutdown ─────────────────────────────────────────────────
  const shutdown = async (signal: string): Promise<void> => {
    console.log(`\n[Server] Recebido ${signal}. Encerrando...`);
    realtime.close();
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
