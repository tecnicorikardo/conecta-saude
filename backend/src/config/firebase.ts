import * as admin from 'firebase-admin';

let app: admin.app.App | null = null;

/**
 * Inicializa o Firebase Admin SDK.
 * As credenciais NUNCA ficam no código — vêm de variáveis de ambiente.
 */
function getEnvCaseInsensitive(key: string): string | undefined {
  if (process.env[key]) return process.env[key];
  const found = Object.entries(process.env).find(
    ([k]) => k.toLowerCase() === key.toLowerCase(),
  );
  return found ? found[1] : undefined;
}

export function initializeFirebase(): void {
  if (app) return;

  const projectId = getEnvCaseInsensitive('FIREBASE_PROJECT_ID')?.trim();
  const clientEmail = getEnvCaseInsensitive('FIREBASE_CLIENT_EMAIL')?.trim();
  let rawKey = getEnvCaseInsensitive('FIREBASE_PRIVATE_KEY')?.trim() ?? '';

  // Remove aspas caso o usuário tenha colado com aspas duplas no painel
  if (rawKey.startsWith('"') && rawKey.endsWith('"')) {
    rawKey = rawKey.substring(1, rawKey.length - 1);
  }

  const privateKey = rawKey.replace(/\\n/g, '\n');

  const missing: string[] = [];
  if (!projectId) missing.push('FIREBASE_PROJECT_ID');
  if (!clientEmail) missing.push('FIREBASE_CLIENT_EMAIL');
  if (!privateKey) missing.push('FIREBASE_PRIVATE_KEY');

  if (missing.length > 0) {
    throw new Error(
      `Variáveis de ambiente do Firebase ausentes no Render/Ambiente: ${missing.join(', ')}`,
    );
  }

  app = admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });

  console.log('[Firebase] Admin SDK inicializado com sucesso.');
}

export function getFirebaseAdmin(): admin.app.App {
  if (!app) {
    throw new Error('Firebase Admin SDK não foi inicializado. Chame initializeFirebase() primeiro.');
  }
  return app;
}

export function getFirebaseAuth(): admin.auth.Auth {
  return getFirebaseAdmin().auth();
}

export function getFirebaseMessaging(): admin.messaging.Messaging {
  return getFirebaseAdmin().messaging();
}
