import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';

import authRoutes from './modules/auth/auth.routes';
import usersRoutes from './modules/users/users.routes';
import sectorsRoutes from './modules/sectors/sectors.routes';
import conversationsRoutes from './modules/conversations/conversations.routes';
import messagesRoutes from './modules/messages/messages.routes';
import announcementsRoutes from './modules/announcements/announcements.routes';
import reportsRoutes from './modules/reports/reports.routes';
import auditRoutes from './modules/audit/audit.routes';
import channelsRoutes from './modules/channels/channels.routes';
import { emergencyRouter } from './modules/emergency/emergency.routes';
import { unitsRouter } from './modules/units/units.routes';

import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { authenticate } from './middleware/authenticate';
import { getMe } from './modules/auth/auth.controller';
import { prisma } from './config/database';
import { getFirebaseAdmin } from './config/firebase';

export function createApp(): express.Application {
  const app = express();

  // ─── Segurança ────────────────────────────────────────────────────────────
  app.use(helmet());

  // ─── CORS ─────────────────────────────────────────────────────────────────
  const allowedOrigins = (process.env.CORS_ORIGINS ?? 'http://localhost:8080')
    .split(',')
    .map((o) => o.trim());

  app.use(
    cors({
      origin: (origin, callback) => {
        // Sem origin (mobile/Postman) ou origens confiáveis
        if (!origin) return callback(null, true);
        if (
          origin.startsWith('http://localhost') ||
          origin.startsWith('http://127.0.0.1') ||
          origin.startsWith('http://192.168.') ||
          origin.startsWith('http://10.') ||
          origin.startsWith('http://172.') ||
          origin.includes('web.app') ||
          origin.includes('firebaseapp.com') ||
          origin.includes('onrender.com') ||
          origin.includes('loca.lt') ||
          allowedOrigins.includes(origin)
        ) {
          return callback(null, true);
        }
        // Permitir qualquer origem web por padrão para evitar bloqueios no Flutter Web
        return callback(null, true);
      },
      credentials: true,
    }),
  );

  // ─── Rate limiting global ─────────────────────────────────────────────────
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: process.env.NODE_ENV === 'development' ? 50000 : 10000,
      skip: () => process.env.NODE_ENV === 'development',
      standardHeaders: true,
      legacyHeaders: false,
      message: { success: false, error: 'Muitas requisições. Tente novamente em instantes.' },
    }),
  );

  // Rate limit para autenticação
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 5000 : 500,
    skip: () => process.env.NODE_ENV === 'development',
    message: { success: false, error: 'Muitas tentativas de autenticação.' },
  });

  // ─── Body parsing ─────────────────────────────────────────────────────────
  app.use(express.json({ limit: '15mb' }));
  app.use(express.urlencoded({ extended: true, limit: '15mb' }));

  // ─── Health check ─────────────────────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
      revision: process.env.RENDER_GIT_COMMIT?.slice(0, 12) ?? 'local',
    });
  });

  app.get('/ready', async (_req, res) => {
    try {
      getFirebaseAdmin();
      await prisma.$queryRaw`SELECT 1`;
      const hostname = new URL(process.env.DATABASE_URL ?? '').hostname;
      const database = hostname.endsWith('.supabase.com') || hostname.endsWith('.supabase.co')
        ? 'supabase' : 'postgresql';
      res.json({ status: 'ready', database, revision: process.env.RENDER_GIT_COMMIT?.slice(0, 12) ?? 'local' });
    } catch {
      res.status(503).json({ status: 'unavailable' });
    }
  });

  // ─── Rotas da API ─────────────────────────────────────────────────────────
  app.use('/api/auth', authLimiter, authRoutes);
  app.get('/api/me', authenticate, getMe);
  app.use('/api/units', unitsRouter);
  app.use('/api/users', usersRoutes);
  app.use('/api/sectors', sectorsRoutes);
  app.use('/api/conversations', conversationsRoutes);
  app.use('/api/messages', messagesRoutes);
  app.use('/api/announcements', announcementsRoutes);
  app.use('/api/channels', channelsRoutes);
  app.use('/api/emergency', emergencyRouter);
  app.use('/api/reports', reportsRoutes);
  app.use('/api/admin/audit-logs', auditRoutes);

  // ─── Handlers de erro ─────────────────────────────────────────────────────
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
