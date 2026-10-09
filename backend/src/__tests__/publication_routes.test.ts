import express from 'express';
import type { Server } from 'http';
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

// Substituímos apenas serviços externos. Rotas, autenticação, autorização e
// validação continuam reais: assim o teste detecta um limite incorreto na rota.
const mocks = vi.hoisted(() => ({
  user: vi.fn(), sector: vi.fn(), channel: vi.fn(), announcement: vi.fn(),
  verify: vi.fn(), audit: vi.fn(), read: vi.fn(),
  findChannel: vi.fn(), findAnnouncement: vi.fn(), deleteChannel: vi.fn(), deleteAnnouncement: vi.fn(),
  listChannels: vi.fn(), listAnnouncements: vi.fn(),
}));
vi.mock('../config/database', () => ({ prisma: {
  user: { findUnique: mocks.user, findMany: vi.fn().mockResolvedValue([]),
    count: vi.fn().mockResolvedValue(1) },
  sector: { findUnique: mocks.sector },
  channel: { create: mocks.channel, findUnique: mocks.findChannel, updateMany: mocks.deleteChannel, findMany: mocks.listChannels },
  announcement: { create: mocks.announcement, findUnique: mocks.findAnnouncement, updateMany: mocks.deleteAnnouncement,
    findMany: mocks.listAnnouncements, count: vi.fn().mockResolvedValue(0) },
  announcementRead: { upsert: mocks.read },
} }));
vi.mock('../config/firebase', () => ({
  getFirebaseAuth: () => ({ verifyIdToken: mocks.verify }),
  getFirebaseMessaging: vi.fn(),
}));
vi.mock('../utils/auditLogger', () => ({ auditLog: mocks.audit }));

import channels from '../modules/channels/channels.routes';
import announcements from '../modules/announcements/announcements.routes';
import { errorHandler } from '../middleware/errorHandler';

const setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
const actor = { id: 'supervisor-test', firebaseUid: 'firebase-test',
  nome: 'Supervisão de teste', email: 'test@example.invalid', cargo: 'Supervisor',
  hierarquiaNivel: 3, setorId, unitId: null, ativo: true };
let server: Server;
let base: string;

beforeAll(async () => {
  const app = express();
  app.use(express.json());
  app.use('/channels', channels);
  app.use('/announcements', announcements);
  app.use(errorHandler);
  // Porta escolhida pelo sistema; nenhum acesso ao servidor de produção.
  server = app.listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}`;
});
afterAll(() => new Promise<void>((resolve, reject) => {
  server.close((error) => error ? reject(error) : resolve());
  server.closeAllConnections();
}));
beforeEach(() => {
  vi.clearAllMocks();
  mocks.verify.mockResolvedValue({ uid: actor.firebaseUid });
  mocks.user.mockResolvedValue({ ...actor });
  mocks.sector.mockResolvedValue({ id: setorId });
  mocks.channel.mockResolvedValue({ id: 'channel-test' });
  mocks.announcement.mockResolvedValue({ id: 'announcement-test' });
  mocks.findChannel.mockResolvedValue({ id: 'item', criadoPor: actor.id, ativo: true });
  mocks.findAnnouncement.mockResolvedValue({ id: 'item', criadoPor: actor.id, ativo: true });
  mocks.deleteChannel.mockResolvedValue({ count: 1 });
  mocks.deleteAnnouncement.mockResolvedValue({ count: 1 });
  mocks.listChannels.mockResolvedValue([]);
  mocks.listAnnouncements.mockResolvedValue([]);
});

describe('Exclusão lógica: autor em qualquer nível ou Direção', () => {
  for (const [route, find, update, action] of [
    ['/channels', mocks.findChannel, mocks.deleteChannel, 'excluir_canal'],
    ['/announcements', mocks.findAnnouncement, mocks.deleteAnnouncement, 'excluir_comunicado'],
  ] as const) {
    const remove = (authenticated = true) => fetch(`${base}${route}/item`, {
      method: 'DELETE', headers: authenticated ? { Authorization: 'Bearer test-token' } : {},
    });
    for (const nivel of [1, 2, 3, 4]) {
      it(`${route}: autor NV${nivel} exclui e gera auditoria`, async () => {
        mocks.user.mockResolvedValue({ ...actor, hierarquiaNivel: nivel });
        expect((await remove()).status).toBe(200);
        expect(update).toHaveBeenCalledWith({ where: { id: 'item', ativo: true }, data: { ativo: false } });
        expect(mocks.audit).toHaveBeenCalledWith(expect.objectContaining({ userId: actor.id, acao: action, entidadeId: 'item' }));
      });
    }
    for (const nivel of [2, 3, 4]) {
      it(`${route}: NV${nivel} não exclui conteúdo de outra pessoa`, async () => {
        mocks.user.mockResolvedValue({ ...actor, hierarquiaNivel: nivel });
        find.mockResolvedValue({ id: 'item', criadoPor: 'outro-autor', ativo: true });
        expect((await remove()).status).toBe(403);
        expect(update).not.toHaveBeenCalled();
        expect(mocks.audit).not.toHaveBeenCalled();
      });
    }
    it(`${route}: Direção pode excluir conteúdo de outro autor (apenas simulação local)`, async () => {
      mocks.user.mockResolvedValue({ ...actor, hierarquiaNivel: 1 });
      find.mockResolvedValue({ id: 'item', criadoPor: 'outro-autor', ativo: true });
      expect((await remove()).status).toBe(200);
    });
    it(`${route}: ausente ou já excluído retorna 404`, async () => {
      find.mockResolvedValue(null);
      expect((await remove()).status).toBe(404);
      find.mockResolvedValue({ id: 'item', criadoPor: actor.id, ativo: false });
      expect((await remove()).status).toBe(404);
      expect(update).not.toHaveBeenCalled();
    });
    it(`${route}: sem sessão ou conta inativa não exclui`, async () => {
      expect((await remove(false)).status).toBe(401);
      mocks.user.mockResolvedValue({ ...actor, ativo: false });
      expect((await remove()).status).toBe(403);
      expect(update).not.toHaveBeenCalled();
    });
    it(`${route}: exclusões concorrentes geram apenas uma alteração`, async () => {
      update.mockResolvedValue({ count: 0 });
      expect((await remove()).status).toBe(404);
      expect(mocks.audit).not.toHaveBeenCalled();
    });
  }
  it('canal excluído não permite acesso direto ou novas mensagens', async () => {
    mocks.findChannel.mockResolvedValue({ id: 'item', ativo: false });
    const headers = { Authorization: 'Bearer test-token' };
    expect((await fetch(`${base}/channels/item`, { headers })).status).toBe(404);
    expect((await fetch(`${base}/channels/item/messages`, { headers })).status).toBe(404);
    expect((await post('/channels/item/messages', { texto: 'Teste' })).status).toBe(404);
  });
  it('comunicado excluído não permite novas leituras ou estatísticas', async () => {
    mocks.findAnnouncement.mockResolvedValue({ id: 'item', ativo: false });
    expect((await post('/announcements/item/read', {})).status).toBe(404);
    expect((await fetch(`${base}/announcements/item/stats`, { headers: { Authorization: 'Bearer test-token' } })).status).toBe(404);
    expect(mocks.read).not.toHaveBeenCalled();
  });
  it('listagens filtram conteúdos inativos no banco', async () => {
    for (const route of ['/channels', '/channels/all', '/announcements']) {
      expect((await fetch(`${base}${route}`, { headers: { Authorization: 'Bearer test-token' } })).status).toBe(200);
    }
    for (const mock of [mocks.listChannels, mocks.listAnnouncements]) {
      expect(mock).toHaveBeenCalledWith(expect.objectContaining({ where: expect.objectContaining({ ativo: true }) }));
    }
  });
});

function post(route: string, body: object, authenticated = true) {
  return fetch(base + route, { method: 'POST',
    headers: { 'Content-Type': 'application/json',
      ...(authenticated ? { Authorization: 'Bearer test-token' } : {}) },
    body: JSON.stringify(body),
  });
}

describe('Publicação pelas rotas reais', () => {
  for (const route of ['/channels', '/announcements']) {
    it(`${route}: liderança passa pela autorização e chega à validação`, async () => {
      for (const nivel of [1, 2, 3]) {
        mocks.user.mockResolvedValue({ ...actor, hierarquiaNivel: nivel });
        // 422 confirma que a permissão passou, mas o formulário está incompleto.
        expect((await post(route, {})).status).toBe(422);
      }
      expect(mocks.channel).not.toHaveBeenCalled();
      expect(mocks.announcement).not.toHaveBeenCalled();
    });
    it(`${route}: funcionário continua bloqueado`, async () => {
      mocks.user.mockResolvedValue({ ...actor, hierarquiaNivel: 4 });
      expect((await post(route, {})).status).toBe(403);
    });
    it(`${route}: conta inativa e sessão ausente não publicam`, async () => {
      mocks.user.mockResolvedValue({ ...actor, ativo: false });
      expect((await post(route, {})).status).toBe(403);
      expect((await post(route, {}, false)).status).toBe(401);
    });
  }
  it('supervisão cria canal com seu setor quando o formulário omite setorId', async () => {
    expect((await post('/channels', { nome: 'Equipe', tipo: 'setor' })).status).toBe(201);
    expect(mocks.channel).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ setorId, criadoPor: actor.id }),
    }));
  });
  it('supervisão não pode escolher outro setor', async () => {
    expect((await post('/channels', { nome: 'Equipe', tipo: 'setor',
      setorId: '2c5017ec-4800-4c54-8ce4-90e44c5a1525' })).status).toBe(403);
    expect(mocks.channel).not.toHaveBeenCalled();
  });
  it('supervisão cria comunicado sem depender de token de notificação', async () => {
    expect((await post('/announcements', {
      titulo: 'Aviso', mensagem: 'Mensagem de teste', prioridade: 'normal',
    })).status).toBe(201);
    expect(mocks.announcement).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ criadoPor: actor.id }),
    }));
  });
});
