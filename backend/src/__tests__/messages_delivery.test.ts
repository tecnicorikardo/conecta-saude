import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Request, Response } from 'express';
const mocks = vi.hoisted(() => ({
  member: vi.fn(), upsert: vi.fn(), update: vi.fn(), recipients: vi.fn(),
}));
vi.mock('../config/database', () => ({ prisma: {
  conversationMember: { findUnique: mocks.member, findMany: mocks.recipients },
  message: { upsert: mocks.upsert }, conversation: { update: mocks.update },
} }));
vi.mock('../realtime', () => ({ notifyConversation: vi.fn() }));
import { sendMessage } from '../modules/messages/messages.controller';

const id = 'ad7956a5-f728-43e3-b097-b8e3e12e03af';
const req = () => ({ user: { id: 'sender', nome: 'Demo' }, params: { id: 'conversation' }, body: { texto: 'Olá', clientMessageId: id } } as unknown as Request);
const response = () => { const res = { status: vi.fn(), json: vi.fn() }; res.status.mockReturnValue(res); return res as unknown as Response; };
beforeEach(() => {
  vi.clearAllMocks();
  mocks.member.mockResolvedValue({ userId: 'sender' });
  mocks.update.mockResolvedValue({});
  mocks.recipients.mockResolvedValue([]);
});
describe('Message delivery', () => {
  it('reutiliza o mesmo ID em uma tentativa repetida', async () => {
    const rows = new Map<string, any>();
    mocks.upsert.mockImplementation(async ({ where, create }) => {
      if (!rows.has(where.id)) rows.set(where.id, { ...create, criadoEm: new Date(), remetente: { id: 'sender' } });
      return rows.get(where.id);
    });
    const first = response(); const second = response();
    await sendMessage(req(), first); await sendMessage(req(), second);
    expect(rows.size).toBe(1);
    expect(second.json).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ id }) }));
  });
  it('nega envio para uma conversa da qual o usuário não participa', async () => {
    mocks.member.mockResolvedValue(null);
    await expect(sendMessage(req(), response())).rejects.toThrow('Você não participa');
    expect(mocks.upsert).not.toHaveBeenCalled();
  });
  it('não devolve uma mensagem de outro autor com o mesmo ID', async () => {
    mocks.upsert.mockResolvedValue({ id, remetenteId: 'other', conversationId: 'conversation', texto: 'Olá' });
    const res = response();
    await expect(sendMessage(req(), res)).rejects.toThrow('Identificador de mensagem');
    expect(res.json).not.toHaveBeenCalled();
  });
});
