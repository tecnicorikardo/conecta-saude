import express from 'express';
import type { Server } from 'http';
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({ create: vi.fn(), audit: vi.fn() }));
vi.mock('../config/database', () => ({ prisma: {
  report: { create: mocks.create }, auditLog: { create: mocks.audit },
} }));
vi.mock('../middleware/authenticate', () => ({
  authenticate: (req: express.Request, _res: express.Response, next: express.NextFunction) => {
    req.user = { id: 'actor', firebaseUid: 'uid', nome: 'Teste', email: 'test@example.invalid',
      cargo: 'Enfermeiro', hierarquiaNivel: 3, setorId: 'sector', ativo: true };
    next();
  },
  requireHierarquia: () => (_req: express.Request, _res: express.Response, next: express.NextFunction) => next(),
}));
import routes from '../modules/reports/reports.routes';
import { errorHandler } from '../middleware/errorHandler';

let server: Server;
let base: string;
beforeAll(async () => {
  const app = express();
  app.use(express.json()); app.use('/reports', routes); app.use(errorHandler);
  server = app.listen(0, '127.0.0.1');
  await new Promise<void>(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${(server.address() as { port: number }).port}`;
});
afterAll(() => new Promise<void>((resolve, reject) => {
  server.close(error => error ? reject(error) : resolve()); server.closeAllConnections();
}));
beforeEach(() => {
  vi.clearAllMocks();
  mocks.create.mockResolvedValue({ id: '1c5017ec-4800-4c54-8ce4-90e44c5a1525' });
});
async function post(body: unknown) {
  return fetch(`${base}/reports`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
}
describe('Envio de denúncias do formulário', () => {
  it.each(['linguagem_ofensiva', 'assedio', 'ameaca_intimidacao', 'discriminacao',
    'desvio_conduta', 'infraestrutura_risco', 'fraude_recursos', 'outro'])('aceita %s e retorna protocolo', async motivo => {
    const response = await post({ motivo, descricao: 'Relato de teste sem dados pessoais.', anonimo: true });
    expect(response.status).toBe(201);
    expect((await response.json()).data.id).toBeTruthy();
    expect(mocks.create.mock.calls[0][0].data).toMatchObject({ motivo, reporterId: null, anonimo: true });
    expect(mocks.audit).not.toHaveBeenCalled();
  });
  it('identifica o autor somente no envio identificado', async () => {
    expect((await post({ motivo: 'assedio', descricao: 'Relato de teste.', anonimo: false })).status).toBe(201);
    expect(mocks.create.mock.calls[0][0].data.reporterId).toBe('actor');
    expect(mocks.audit).toHaveBeenCalledOnce();
  });
  it.each(['curt', ' '.repeat(10), 'x'.repeat(2001)])('rejeita descrição inválida sem gravar', async descricao => {
    const response = await post({ motivo: 'assedio', descricao });
    expect(response.status).toBe(422);
    expect((await response.json()).details[0].field).toBe('descricao');
    expect(mocks.create).not.toHaveBeenCalled();
  });
});
