import { afterEach, describe, expect, it } from 'vitest';
import { createServer, Server } from 'http';
import { AddressInfo } from 'net';
import { once } from 'events';
import { WebSocket } from 'ws';
import { RealtimeHub } from '../realtime';

let http: Server;
let hub: RealtimeHub;
const clients: WebSocket[] = [];
async function setup() {
  http = createServer();
  hub = new RealtimeHub(http, async token => {
    if (token === 'invalid') throw new Error('invalid');
    return { userId: token, expiresAt: token === 'expired' ? 1 : Date.now() + 60000 };
  });
  http.listen(0, '127.0.0.1');
  await once(http, 'listening');
}
async function client(token: string) {
  const socket = new WebSocket(`ws://127.0.0.1:${(http.address() as AddressInfo).port}/api/realtime`);
  clients.push(socket);
  await once(socket, 'open');
  const event = once(socket, token === 'invalid' || token === 'expired' ? 'close' : 'message');
  socket.send(JSON.stringify({ type: 'auth', token }));
  const result = await event;
  return { socket, result };
}
afterEach(async () => {
  clients.splice(0).forEach(socket => socket.terminate());
  hub?.close();
  if (http?.listening) await new Promise<void>(resolve => http.close(() => resolve()));
});
describe('Realtime authenticated transport', () => {
  it('entrega somente aos destinatários e não permite inscrição arbitrária', async () => {
    await setup();
    const a = await client('cco');
    const b = await client('cce');
    const receivedByB: unknown[] = [];
    b.socket.on('message', data => receivedByB.push(data));
    const next = once(a.socket, 'message');
    hub.notify(['cco'], { type: 'conversation.changed', conversationId: 'conversation-cco' });
    const [data] = await next;
    expect(JSON.parse(data.toString())).toEqual({ type: 'conversation.changed', conversationId: 'conversation-cco' });
    const closed = once(b.socket, 'close');
    b.socket.send(JSON.stringify({ type: 'subscribe', conversationId: 'conversation-cco' }));
    expect((await closed)[0]).toBe(4400);
    expect(receivedByB).toHaveLength(0);
  });
  it.each(['invalid', 'expired'])('rejeita token %s antes de enviar eventos', async token => {
    await setup();
    const { result } = await client(token);
    expect(result[0]).toBe(4401);
  });
});
