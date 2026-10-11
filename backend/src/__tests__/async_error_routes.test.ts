import type { Server } from 'http';
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

const m = vi.hoisted(() => ({ user: vi.fn(), me: vi.fn(), units: vi.fn(), unit: vi.fn(),
  active: vi.fn(), emergency: vi.fn(), history: vi.fn(), count: vi.fn(), verify: vi.fn() }));
vi.mock('../config/database', () => ({ prisma: {
  user: { findUnique: m.user, findUniqueOrThrow: m.me },
  hospitalUnit: { findMany: m.units, findUnique: m.unit },
  emergencyAlert: { findFirst: m.active, findUnique: m.emergency, findMany: m.history, count: m.count },
} }));
vi.mock('../config/firebase', () => ({ getFirebaseAuth: () => ({ verifyIdToken: m.verify }),
  getFirebaseAdmin: vi.fn(), getFirebaseMessaging: vi.fn() }));
import { createApp } from '../app';

let server: Server; let base: string;
beforeAll(async () => {
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}`;
});
afterAll(() => new Promise<void>(resolve => { server.close(() => resolve()); server.closeAllConnections(); }));
beforeEach(() => {
  vi.resetAllMocks();
  m.verify.mockResolvedValue({ uid: 'uid' });
  m.user.mockResolvedValue({ id: 'user', firebaseUid: 'uid', hierarquiaNivel: 4, setorId: 'cco', ativo: true });
  m.units.mockResolvedValue([]); m.unit.mockResolvedValue(null); m.active.mockResolvedValue(null);
  m.emergency.mockResolvedValue(null); m.history.mockResolvedValue([]); m.count.mockResolvedValue(0);
});
async function call(path: string, method = 'GET', body?: object) {
  return fetch(`${base}/api${path}`, { method, headers: {
    Authorization: 'Bearer test', 'Content-Type': 'application/json',
  }, body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(3000) });
}
describe('Rejeições async chegam ao errorHandler sem timeout', () => {
  it('unidade inexistente retorna 404', async () => {
    const res = await call('/units/missing'); expect(res.status).toBe(404);
    expect(await res.json()).toMatchObject({ success: false, error: 'Unidade hospitalar não encontrada.' });
  });
  it.each(['POST', 'PUT'])('gestão de unidades por funcionário retorna 403 (%s)', async method => {
    expect((await call(method === 'POST' ? '/units' : '/units/missing', method, {})).status).toBe(403);
  });
  it('consulta válida de unidades preserva resposta existente', async () => {
    const res = await call('/units'); expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, data: [] });
  });
  it('alerta inválido retorna detalhes 422', async () => {
    const res = await call('/emergency', 'POST', {}); expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ success: false, details: expect.any(Array) });
  });
  it('encerramento de alerta inexistente retorna 404', async () => {
    expect((await call('/emergency/missing/resolve', 'PATCH', {})).status).toBe(404);
  });
  it.each([
    ['/units', m.units], ['/emergency/active', m.active], ['/emergency/history', m.history], ['/me', m.me],
  ])('falha de banco em %s retorna 500', async (path, lookup) => {
    lookup.mockRejectedValue(new Error('mock database unavailable'));
    const log = vi.spyOn(console, 'error').mockImplementation(() => {});
    try { const res = await call(path); expect(res.status).toBe(500);
      expect(await res.json()).toMatchObject({ success: false });
    } finally { log.mockRestore(); }
  });
});
