import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Request, Response } from 'express';

const m = vi.hoisted(() => ({
  verify: vi.fn(), findUser: vi.fn(), updateUser: vi.fn(), updateMany: vi.fn(),
  deleteUser: vi.fn(), firebaseDelete: vi.fn(), firebaseUpdate: vi.fn(), revoke: vi.fn(),
  auditCreate: vi.fn(), auditFind: vi.fn(), auditList: vi.fn(), listUsers: vi.fn(),
  member: vi.fn(), conversation: vi.fn(), updateConversation: vi.fn(), deleteMessages: vi.fn(),
}));
vi.mock('../config/database', () => {
  const prisma = {
    user: { findUnique: m.findUser, update: m.updateUser, updateMany: m.updateMany,
      delete: m.deleteUser, findMany: m.listUsers },
    auditLog: { create: m.auditCreate, findFirst: m.auditFind, findMany: m.auditList },
    conversationMember: { findUnique: m.member },
    conversation: { findUnique: m.conversation, update: m.updateConversation },
    message: { deleteMany: m.deleteMessages },
  };
  return { prisma: { ...prisma, $transaction: (fn: any) => fn(prisma) } };
});
vi.mock('../config/firebase', () => ({ getFirebaseAuth: () => ({
  verifyIdToken: m.verify, deleteUser: m.firebaseDelete, updateUser: m.firebaseUpdate,
  revokeRefreshTokens: m.revoke,
}), getFirebaseMessaging: vi.fn() }));
vi.mock('../realtime', () => ({ notifyConversation: vi.fn(), notifyUserStatusChanged: vi.fn() }));
import { authenticate } from '../middleware/authenticate';
import { verifyToken } from '../modules/auth/auth.controller';
import { approveUser, rejectUser, getPendingUsers } from '../modules/users/users.controller';
import { clearConversation, deleteConversation } from '../modules/conversations/conversations.controller';

const request = (level = 1) => ({ headers: { authorization: 'Bearer token' },
  socket: { remoteAddress: '127.0.0.1' }, user: { id: 'actor', nome: 'Gestor', hierarquiaNivel: level, setorId: 'cco' },
  params: { id: 'target' }, body: { idToken: 'token' }, query: {},
} as unknown as Request);
const response = () => { const res = { status: vi.fn(), json: vi.fn() };
  res.status.mockReturnValue(res); return res as unknown as Response; };
beforeEach(() => {
  vi.resetAllMocks();
  m.verify.mockResolvedValue({ uid: 'unlinked', email: 'someone@example.invalid', email_verified: true });
  m.auditFind.mockResolvedValue(null);
  m.auditList.mockResolvedValue([]);
  m.updateMany.mockResolvedValue({ count: 1 });
  m.findUser.mockResolvedValue({ id: 'target', firebaseUid: 'linked', nome: 'Cadastro',
    cargo: 'Enfermeiro', setorId: 'cco', setor: { nome: 'CCO' }, unit: null, ativo: false, aprovadoEm: null });
});
describe('Autenticação exige UID vinculado', () => {
  it.each([true, false])('não vincula automaticamente por email (verificado: %s)', async verified => {
    m.verify.mockResolvedValue({ uid: 'unlinked', email: 'someone@example.invalid', email_verified: verified });
    m.findUser.mockResolvedValue(null);
    const res = response(); const next = vi.fn();
    await authenticate(request(), res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
    expect(m.findUser).toHaveBeenCalledTimes(1);
    expect(m.updateUser).not.toHaveBeenCalled();
    await expect(verifyToken(request(), response())).rejects.toThrow('Usuário não cadastrado');
    expect(m.findUser).toHaveBeenCalledTimes(2);
    expect(m.updateUser).not.toHaveBeenCalled();
  });
  it('permite conta ativa já vinculada ao UID', async () => {
    m.findUser.mockResolvedValue({ id: 'target', firebaseUid: 'linked', ativo: true, hierarquiaNivel: 3 });
    const next = vi.fn(); await authenticate(request(), response(), next);
    expect(next).toHaveBeenCalledOnce();
  });
  it('informa rejeição em vez de aprovação pendente', async () => {
    m.auditFind.mockResolvedValue({ id: 'rejection' });
    await expect(verifyToken(request(), response())).rejects.toThrow('Cadastro rejeitado');
  });
});
describe('Histórico compartilhado protegido', () => {
  it('limpeza por membro operacional não apaga nenhuma mensagem do servidor', async () => {
    m.member.mockResolvedValue({ userId: 'actor', isAdmin: false });
    await clearConversation(request(4), response());
    expect(m.deleteMessages).not.toHaveBeenCalled();
    expect(m.auditCreate).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({
      acao: 'limpar_conversa_local', userId: 'actor', entidadeId: 'target',
    }) }));
  });
  it('nega limpeza a quem não participa', async () => {
    m.member.mockResolvedValue(null);
    await expect(clearConversation(request(), response())).rejects.toThrow('Você não participa');
    expect(m.deleteMessages).not.toHaveBeenCalled();
  });
  it.each(['individual', 'grupo'])('nega exclusão de conversa %s de terceiros', async tipo => {
    m.conversation.mockResolvedValue({ ativo: true, tipo, members: [{ userId: 'other' }] });
    await expect(deleteConversation(request(), response())).rejects.toThrow('Você não participa');
    expect(m.updateConversation).not.toHaveBeenCalled();
  });
});
describe('Rejeição preserva cadastro e auditoria', () => {
  it('arquiva a decisão e desativa o Firebase após salvar no banco', async () => {
    const res = response(); await rejectUser(request(), res);
    expect(m.deleteUser).not.toHaveBeenCalled(); expect(m.firebaseDelete).not.toHaveBeenCalled();
    expect(m.auditCreate).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({
      acao: 'rejeitar_cadastro', entidadeId: 'target', userId: 'actor',
    }) }));
    expect(m.firebaseUpdate).toHaveBeenCalledWith('linked', { disabled: true });
    expect(m.auditCreate.mock.invocationCallOrder[0]).toBeLessThan(m.firebaseUpdate.mock.invocationCallOrder[0]);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
  it('falha de banco não altera a conta Firebase', async () => {
    m.auditCreate.mockRejectedValue(new Error('storage failed'));
    await expect(rejectUser(request(), response())).rejects.toThrow('storage failed');
    expect(m.firebaseUpdate).not.toHaveBeenCalled(); expect(m.firebaseDelete).not.toHaveBeenCalled();
  });
  it('falha no Firebase não desfaz o bloqueio na API', async () => {
    m.firebaseUpdate.mockRejectedValue(new Error('offline'));
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => {});
    const res = response(); await rejectUser(request(), res);
    expect(m.updateMany).toHaveBeenCalledWith(expect.objectContaining({ data: { ativo: false, fcmToken: null } }));
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true })); warning.mockRestore();
  });
  it('cadastro rejeitado não volta à lista pendente', async () => {
    m.auditList.mockResolvedValue([{ entidadeId: 'target' }]); m.listUsers.mockResolvedValue([]);
    await getPendingUsers(request(), response());
    expect(m.listUsers).toHaveBeenCalledWith(expect.objectContaining({ where: expect.objectContaining({
      id: { notIn: ['target'] }, ativo: false, aprovadoEm: null,
    }) }));
  });
  it('nega aprovação de solicitação já rejeitada', async () => {
    m.auditFind.mockResolvedValue({ id: 'rejection' });
    await expect(approveUser(request(), response())).rejects.toThrow('Cadastro rejeitado');
  });
  it('Coordenação não rejeita cadastro de outro centro', async () => {
    m.findUser.mockResolvedValue({ ativo: false, setorId: 'cce' });
    await expect(rejectUser(request(2), response())).rejects.toThrow('própria unidade');
    expect(m.updateMany).not.toHaveBeenCalled();
  });
});
