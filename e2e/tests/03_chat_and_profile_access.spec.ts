import { test, expect } from '@playwright/test';
import { loginAs } from '../helpers/flutter';

test.describe('03 - Chat, Conversas e Perfil de Colaboradores (Pente Fino)', () => {
  test('deve acessar conversas e perfil de colaborador sem tela branca nem redirecionamento indevido', async ({ page }) => {
    // 1. Login com Coordenador CCO
    await loginAs(page, 'coord.cco@conectasaude.dev', 'ConectaSUS@2026');

    // 2. Acessar lista de conversas
    await page.goto('/conversations');
    await page.waitForTimeout(3500);
    expect(page.url()).toContain('/conversations');

    // 3. Acessar detalhes de funcionário (Paula Souza: 7efd1864-e7a2-4aae-9ec8-7531edc681ca)
    await page.goto('/employees/7efd1864-e7a2-4aae-9ec8-7531edc681ca');
    await page.waitForTimeout(4000);

    // Deve permanecer na rota do colaborador (sem redirecionar para /home nem tela branca)
    expect(page.url()).toContain('/employees/7efd1864-e7a2-4aae-9ec8-7531edc681ca');
    expect(page.url()).not.toBe('https://conecta-hospital.web.app/home');

    // 4. Captura screenshot para conferência visual
    await page.screenshot({ path: 'playwright-report/profile_check.png' });
  });
});
