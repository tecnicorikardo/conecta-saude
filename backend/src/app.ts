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

import { errorHandler, notFoundHandler } from './middleware/errorHandler';

export function createApp(): express.Application {
  const app = express();

  // ─── Segurança ────────────────────────────────────────────────────────────
  app.use(helmet());

  // ─── CORS ─────────────────────────────────────────────────────────────────
  // Em desenvolvimento aceita qualquer localhost para facilitar testes
  const allowedOrigins = (process.env.CORS_ORIGINS ?? 'http://localhost:8080')
    .split(',')
    .map((o) => o.trim());

  app.use(
    cors({
      origin: (origin, callback) => {
        // Sem origin (mobile/Postman) ou localhost sempre permitido em dev
        if (!origin) return callback(null, true);
        if (process.env.NODE_ENV === 'development' && origin.startsWith('http://localhost')) {
          return callback(null, true);
        }
        if (allowedOrigins.includes(origin)) {
          return callback(null, true);
        }
        callback(new Error(`Origem não permitida: ${origin}`));
      },
      credentials: true,
    }),
  );

  // ─── Rate limiting global ─────────────────────────────────────────────────
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: 200,
      standardHeaders: true,
      legacyHeaders: false,
      message: { success: false, error: 'Muitas requisições. Tente novamente em instantes.' },
    }),
  );

  // Rate limit mais restrito para autenticação
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    message: { success: false, error: 'Muitas tentativas de autenticação.' },
  });

  // ─── Body parsing ─────────────────────────────────────────────────────────
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  // ─── Health check ─────────────────────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
    });
  });

  // ─── Rotas da API ─────────────────────────────────────────────────────────
  app.use('/api/auth', authLimiter, authRoutes);
  app.use('/api/users', usersRoutes);
  app.use('/api/sectors', sectorsRoutes);
  app.use('/api/conversations', conversationsRoutes);
  app.use('/api/messages', messagesRoutes);
  app.use('/api/announcements', announcementsRoutes);
  app.use('/api/reports', reportsRoutes);
  app.use('/api/admin/audit-logs', auditRoutes);

  // ─── Handlers de erro ─────────────────────────────────────────────────────
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
