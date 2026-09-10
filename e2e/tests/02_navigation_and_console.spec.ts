import { test, expect } from '@playwright/test';
import { loginAs } from '../helpers/flutter';

test.describe('02 - Navegação e Varredura de Erros de Console (Pente Fino)', () => {
  test('deve navegar pelas rotas principais sem disparar exceções de runtime, CORS ou erros 422/500', async ({ page }) => {
    const consoleErrors: string[] = [];
    const failedApiRequests: string[] = [];

    // Capturar logs de erro no console do navegador
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        const txt = msg.text();
        // Ignora avisos esperados de ambiente como Noto fonts, ServiceWorker ou navigator.vibrate em headless
        if (
          !txt.includes('Noto fonts') &&
          !txt.includes('ServiceWorker') &&
          !txt.includes('permission-blocked') &&
          !txt.includes('navigator.vibrate')
        ) {
          consoleErrors.push(txt);
        }
      }
    });

    // Capturar falhas em APIs do backend
    page.on('response', (res) => {
      if (res.status() >= 400 && res.url().includes('conecta-saude-backende.onrender.com')) {
        failedApiRequests.push(`${res.status()} ${res.url()}`);
      }
    });

    // 1. Realizar Login
    await loginAs(page);

    // 2. Navegar para /conversations
    await page.goto('/conversations');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/conversations');

    // 3. Navegar para /channels
    await page.goto('/channels');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/channels');

    // 4. Navegar para /announcements
    await page.goto('/announcements');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/announcements');

    // 5. Retornar para /home
    await page.goto('/home');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/home');

    // 6. Verificação de Pente Fino: Nenhuma falha de backend crítica
    console.log('Falhas de API backend detectadas:', failedApiRequests);
    console.log('Erros de console filtrados:', consoleErrors);

    expect(failedApiRequests).toEqual([]);
    expect(consoleErrors).toEqual([]);
  });
});
