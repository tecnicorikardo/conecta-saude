import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Request, Response } from 'express';

const mocks = vi.hoisted(() => ({ find: vi.fn(), update: vi.fn(), audit: vi.fn(),
  create: vi.fn(), sector: vi.fn(), firebaseCreate: vi.fn(), verify: vi.fn(), rejected: vi.fn() }));
vi.mock('../config/database', () => ({ prisma: { user: {
  findUnique: mocks.find, update: mocks.update, create: mocks.create,
}, sector: { findUnique: mocks.sector }, auditLog: { create: mocks.audit, findFirst: mocks.rejected },
  $transaction: (fn: any) => fn({ user: { update: mocks.update }, auditLog: { findFirst: mocks.rejected } }),
} }));
vi.mock('../config/firebase', () => ({ getFirebaseAuth: () => ({
  createUser: mocks.firebaseCreate, verifyIdToken: mocks.verify,
}), getFirebaseMessaging: vi.fn() }));
vi.mock('../utils/auditLogger', () => ({ auditLog: mocks.audit }));
import { approveUser } from '../modules/users/users.controller';
import { registerUser, verifyToken } from '../modules/auth/auth.controller';

describe('Aprovação e nível do cargo solicitado', () => {
  beforeEach(() => vi.clearAllMocks());

  it('cadastra enfermeiro pendente em nível 3 e retorna esse perfil no login após aprovação', async () => {
    const sector = { id: '1c5017ec-4800-4c54-8ce4-90e44c5a1525', nome: 'UTI', unitId: null };
    mocks.sector.mockResolvedValue(sector);
    mocks.find.mockResolvedValue(null);
    mocks.firebaseCreate.mockResolvedValue({ uid: 'new-nurse' });
    mocks.create.mockImplementation(async ({ data }) => ({ ...data, id: 'nurse', setor: sector, unit: null }));
    const json = vi.fn();
    const res = { status: vi.fn().mockReturnThis(), json } as unknown as Response;
    await registerUser({ body: { nome: 'Enfermeira Teste', email: 'nurse@example.invalid',
      password: 'test-password', setorId: sector.id, cargo: 'Enfermeiro(a) Geral' },
      get: vi.fn() } as unknown as Request, res);
    const registered = await mocks.create.mock.results[0].value;
    expect(registered).toMatchObject({ hierarquiaNivel: 3, ativo: false });
    mocks.find.mockResolvedValue(registered);
    mocks.update.mockImplementation(async ({ data }) => ({ ...registered, ...data, aprovador: null }));
    await approveUser({ user: { id: 'director', hierarquiaNivel: 1 },
      params: { id: 'nurse' } } as unknown as Request, res);
    const approved = await mocks.update.mock.results[0].value;
    mocks.find.mockResolvedValue(approved);
    mocks.verify.mockResolvedValue({ uid: 'new-nurse' });
    await verifyToken({ body: { idToken: 'test-token' } } as Request, res);
    expect(json.mock.calls.at(-1)?.[0].data).toMatchObject({ cargo: 'Enfermeiro(a) Geral', hierarquiaNivel: 3, ativo: true });
  });

  it.each([
    ['Enfermeiro(a) Geral', 3], ['Enfermeiro(a) UTI', 3],
    ['Enfermeiro(a) Chefe / Coordenação', 2], ['Técnico(a) em Enfermagem', 4],
  ])('corrige cadastro pendente de %s para nível %i', async (cargo, nivel) => {
    mocks.find.mockResolvedValue({ id: 'pending', cargo, hierarquiaNivel: 4,
      ativo: false, aprovadoEm: null, setor: { nome: 'UTI' }, unit: null });
    mocks.update.mockImplementation(async ({ data }) => ({ ...data, id: 'pending',
      setor: { nome: 'UTI' }, unit: null, aprovador: { nome: 'Direção' } }));
    const json = vi.fn();
    await approveUser({ user: { id: 'director', hierarquiaNivel: 1 },
      params: { id: 'pending' } } as unknown as Request, { json } as unknown as Response);
    expect(mocks.update.mock.calls[0][0].data).toMatchObject({ ativo: true, hierarquiaNivel: nivel });
    expect(json.mock.calls[0][0].data.hierarquiaNivel).toBe(nivel);
  });

  it('preserva nível administrativo na reativação de conta já aprovada', async () => {
    mocks.find.mockResolvedValue({ id: 'disabled', cargo: 'Enfermeiro', hierarquiaNivel: 2,
      ativo: false, aprovadoEm: new Date(), setor: { nome: 'UTI' }, unit: null });
    mocks.update.mockResolvedValue({ setor: { nome: 'UTI' }, unit: null, aprovador: null });
    await approveUser({ user: { id: 'director', hierarquiaNivel: 1 },
      params: { id: 'disabled' } } as unknown as Request, { json: vi.fn() } as unknown as Response);
    expect(mocks.update.mock.calls[0][0].data).not.toHaveProperty('hierarquiaNivel');
  });
});
