import { Server } from 'http';
import { WebSocket, WebSocketServer } from 'ws';
import { prisma } from './config/database';
import { getFirebaseAuth } from './config/firebase';

type Identity = { userId: string; expiresAt: number };
type Verify = (token: string) => Promise<Identity>;

// One API instance for the free demo. Multiple instances require a shared event bus.
export class RealtimeHub {
  private sockets = new Map<WebSocket, Identity>();
  private server: WebSocketServer;
  private heartbeat: NodeJS.Timeout;

  constructor(http: Server, verify: Verify) {
    this.server = new WebSocketServer({ server: http, path: '/api/realtime', maxPayload: 8192 });
    this.server.on('connection', socket => {
      let alive = true;
      let attempted = false;
      const deadline = setTimeout(() => socket.close(4401, 'Authentication required'), 10000);
      socket.on('error', () => socket.terminate());
      socket.on('pong', () => { alive = true; });
      socket.on('close', () => { clearTimeout(deadline); this.sockets.delete(socket); });
      const ping = () => {
        if (!alive) return socket.terminate();
        alive = false;
        socket.ping();
      };
      socket.on('message', async raw => {
        if (attempted) return socket.close(4400, 'Read-only connection');
        attempted = true;
        try {
          const data = JSON.parse(raw.toString());
          if (data.type !== 'auth' || typeof data.token !== 'string') throw new Error();
          const identity = await verify(data.token);
          if (identity.expiresAt <= Date.now()) throw new Error();
          if (socket.readyState !== WebSocket.OPEN) return;
          clearTimeout(deadline);
          this.sockets.set(socket, identity);
          socket.send(JSON.stringify({ type: 'ready' }));
        } catch { socket.close(4401, 'Access denied'); }
      });
      this.server.on('heartbeat', ping);
      socket.on('close', () => this.server.removeListener('heartbeat', ping));
    });
    this.server.setMaxListeners(0);
    this.heartbeat = setInterval(() => {
      for (const [socket, identity] of this.sockets) {
        if (identity.expiresAt <= Date.now()) socket.close(4401, 'Token expired');
      }
      this.server.emit('heartbeat');
    }, 25000);
    this.heartbeat.unref();
  }

  notify(userIds: string[], event: { type: string; conversationId: string }): void {
    const allowed = new Set(userIds);
    for (const [socket, identity] of this.sockets) {
      if (!allowed.has(identity.userId) || identity.expiresAt <= Date.now()) continue;
      if (socket.readyState !== WebSocket.OPEN) continue;
      if (socket.bufferedAmount > 65536) { socket.close(1013, 'Reconnect to synchronize'); continue; }
      socket.send(JSON.stringify(event));
    }
  }

  close(): void {
    clearInterval(this.heartbeat);
    for (const socket of this.server.clients) socket.terminate();
    this.sockets.clear();
    this.server.close();
  }
}

let hub: RealtimeHub | undefined;
export function startRealtime(server: Server): RealtimeHub {
  hub = new RealtimeHub(server, async token => {
    const decoded = await getFirebaseAuth().verifyIdToken(token, true);
    const user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid }, select: { id: true, ativo: true } });
    if (!user?.ativo) throw new Error('Access denied');
    return { userId: user.id, expiresAt: decoded.exp * 1000 };
  });
  return hub;
}

export function notifyConversation(conversationId: string): void {
  if (!hub) return;
  void prisma.conversationMember.findMany({
    where: { conversationId, user: { ativo: true }, conversation: { ativo: true } },
    select: { userId: true },
  }).then(members => {
    hub?.notify(members.map(m => m.userId), { type: 'conversation.changed', conversationId });
  }).catch(() => console.warn('[Realtime] Aviso não entregue; clientes recuperarão pela sincronização.'));
}
