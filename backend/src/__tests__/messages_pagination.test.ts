import { beforeEach, expect, it, vi } from 'vitest';
import type { Request, Response } from 'express';
const m = vi.hoisted(() => ({ member: vi.fn(), anchor: vi.fn(), rows: vi.fn() }));
vi.mock('../config/database', () => ({ prisma: { conversationMember: { findUnique: m.member }, message: { findFirst: m.anchor, findMany: m.rows } } }));
import { listMessages } from '../modules/messages/messages.controller';
const req = (cursor?: string) => ({ user: { id: 'actor' }, params: { id: 'chat' }, query: { limit: 2, ...(cursor ? {cursor} : {}) } } as unknown as Request);
const res = () => ({ json: vi.fn() } as unknown as Response);
beforeEach(() => { vi.resetAllMocks(); m.member.mockResolvedValue({conversation: {autoExcluir24h: false}}); m.rows.mockResolvedValue([]); });
it('pagina por data com desempate por ID e cursor restrito à conversa', async () => {
  const date = new Date(); m.anchor.mockResolvedValue({id:'a',criadoEm:date});
  await listMessages(req('a'),res());
  expect(m.anchor).toHaveBeenCalledWith({where:{id:'a',conversationId:'chat'},select:{id:true,criadoEm:true}});
  expect(m.rows).toHaveBeenCalledWith(expect.objectContaining({where:{conversationId:'chat',OR:[{criadoEm:{lt:date}},{criadoEm:date,id:{lt:'a'}}]},orderBy:[{criadoEm:'desc'},{id:'desc'}]}));
});
it('recusa cursor inexistente ou de outra conversa', async () => {
  m.anchor.mockResolvedValue(null);
  await expect(listMessages(req('foreign'),res())).rejects.toMatchObject({statusCode:400});
  expect(m.rows).not.toHaveBeenCalled();
});
it('preserva ordem de exibição e cursor mais antigo', async () => {
  m.rows.mockResolvedValue(['new','old'].map(id=>({id,remetenteId:'actor',reads:[],criadoEm:new Date()})));
  const output=res(); await listMessages(req(),output);
  expect(output.json).toHaveBeenCalledWith(expect.objectContaining({data:expect.objectContaining({items:[expect.objectContaining({id:'old'}),expect.objectContaining({id:'new'})],nextCursor:'old',hasMore:true})}));
});
it('preserva autoexclusão e recusa não participante', async () => {
  m.member.mockResolvedValue({conversation:{autoExcluir24h:true}});
  await listMessages(req(),res());
  expect(m.rows).toHaveBeenCalledWith(expect.objectContaining({where:expect.objectContaining({criadoEm:{gte:expect.any(Date)}})}));
  m.member.mockResolvedValue(null);
  await expect(listMessages(req('a'),res())).rejects.toMatchObject({statusCode:403});
  expect(m.anchor).not.toHaveBeenCalled();
});
