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

  const trustedOrigins = [
    'https://conecta-hospital.web.app',
    'https://conecta-hospital.firebaseapp.com',
    'https://slide-conecta-hospital.web.app',
    'https://slide-conecta-hospital.firebaseapp.com',
    ...allowedOrigins,
  ];

  app.use(
    cors({
      origin: (origin, callback) => {
        // Sem origin (mobile apps nativos com Dio, Postman, server-side)
        if (!origin) return callback(null, true);
        if (
          origin.startsWith('http://localhost:') ||
          origin.startsWith('http://127.0.0.1:') ||
          origin.startsWith('http://192.168.') ||
          trustedOrigins.includes(origin)
        ) {
          return callback(null, true);
        }
        return callback(new Error('Origem não autorizada pela política de CORS institucional.'));
      },
      credentials: true,
    }),
  );

  // ─── Rate limiting global ─────────────────────────────────────────────────
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: process.env.NODE_ENV === 'development' ? 50000 : 1000,
      skip: () => process.env.NODE_ENV === 'development',
      standardHeaders: true,
      legacyHeaders: false,
      message: { success: false, error: 'Muitas requisições. Tente novamente em instantes.' },
    }),
  );

  // Rate limit para autenticação (máximo 30 tentativas a cada 15 minutos em produção)
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: process.env.NODE_ENV === 'development' ? 5000 : 30,
    skip: () => process.env.NODE_ENV === 'development',
    message: { success: false, error: 'Muitas tentativas de autenticação. Tente novamente em instantes.' },
  });

  // ─── Body parsing ─────────────────────────────────────────────────────────
  app.use(express.json({ limit: '15mb' }));
  app.use(express.urlencoded({ extended: true, limit: '15mb' }));

  // ─── Health check ─────────────────────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  });

  app.get('/ready', async (_req, res) => {
    try {
      getFirebaseAdmin();
      await prisma.$queryRaw`SELECT 1`;
      res.json({ status: 'ready' });
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
