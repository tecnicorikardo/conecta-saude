import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Request, Response } from 'express';

const mocks = vi.hoisted(() => ({ list: vi.fn(), count: vi.fn() }));
vi.mock('../config/database', () => ({ prisma: { user: {
  findMany: mocks.list, count: mocks.count,
} } }));
vi.mock('../config/firebase', () => ({ getFirebaseAuth: vi.fn(), getFirebaseMessaging: vi.fn() }));
vi.mock('../utils/auditLogger', () => ({ auditLog: vi.fn() }));
import { listUsers } from '../modules/users/users.controller';

describe('Contatos seguem regras de comunicação', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.list.mockResolvedValue([]);
    mocks.count.mockResolvedValue(0);
  });
  async function query(level: number, filters: Record<string, string>) {
    await listUsers({ user: { id: 'self', setorId: 'cco', hierarquiaNivel: level },
      query: filters } as unknown as Request, { json: vi.fn() } as unknown as Response);
    return mocks.list.mock.calls[0][0].where;
  }
  it.each([2, 3, 4])('NV%i encontra colegas e Direção Geral, sem incluir a si próprio', async level => {
    const where = await query(level, { contactable: 'true', excludeSelf: 'true', ativo: 'true' });
    expect(where).toEqual({ AND: [{ OR: [{ setorId: 'cco' }, { hierarquiaNivel: 1 }] }],
      id: { not: 'self' }, ativo: true });
    expect(mocks.count.mock.calls[0][0].where).toEqual(where);
  });
  it('busca por nome preserva o isolamento entre centros', async () => {
    const where = await query(4, { contactable: 'true', search: 'Direção' });
    expect(where.AND).toEqual([{ OR: [{ setorId: 'cco' }, { hierarquiaNivel: 1 }] }]);
    expect(where.OR).toHaveLength(3);
  });
  it('listagem administrativa mantém o filtro do próprio centro', async () => {
    expect(await query(3, {})).toEqual({ setorId: 'cco' });
  });
  it('Direção Geral encontra contatos de todos os centros', async () => {
    expect(await query(1, { contactable: 'true', excludeSelf: 'true' })).toEqual({ id: { not: 'self' } });
  });
});
