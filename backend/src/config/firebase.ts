import * as admin from 'firebase-admin';

let app: admin.app.App | null = null;

/**
 * Inicializa o Firebase Admin SDK.
 * As credenciais NUNCA ficam no código — vêm de variáveis de ambiente.
 */
export function initializeFirebase(): void {
  if (app) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Variáveis de ambiente do Firebase não configuradas: ' +
        'FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY',
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
